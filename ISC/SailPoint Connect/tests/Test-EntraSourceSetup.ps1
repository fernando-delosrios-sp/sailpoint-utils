param(
    [string]$ModuleRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules')
)

. (Join-Path $PSScriptRoot '_TestHelpers.ps1')
$script:AssertionCount = 0

Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.EntraSourceSetup.psm1') -Force
Initialize-EntraSourceSetup -ModuleRoot $ModuleRoot

$catalog = Get-EntraAgentCatalog
Assert-True ($catalog.featurePacks.Count -gt 0) 'catalog exposes feature packs'
Assert-True ($catalog.directoryRoles -contains 'UserAdministrator') 'catalog exposes directory roles'
$entraPacks = (Get-EntraConnectorCatalog).FeaturePacks
$entraLabels = @($entraPacks.Keys | ForEach-Object { [string]$entraPacks[$_].Label })
Assert-Equal (($entraLabels | Sort-Object) -join '|') ($entraLabels -join '|') 'agent catalog feature packs are ordered by label'
Assert-True ($catalog.secretFields -contains 'agent365RefreshToken') 'catalog accepts a supplied Agent 365 refresh token'

$checklist = @(Get-EntraIscFeatureChecklist -FeatureNames @('Agent365'))
Assert-True ([bool]($checklist | Where-Object { $_ -like '*Machine Identity Governance*refresh token*' })) 'checklist points at Machine Identity Governance Settings'

# The connector default filter is servicePrincipalType eq 'Application', which silently drops every
# Foundry and Copilot Studio agent identity because Entra types those as ServiceIdentity.
$spnChecklist = @(Get-EntraIscFeatureChecklist -FeatureNames @('ServicePrincipalProvisioning'))
Assert-True ([bool]($spnChecklist | Where-Object { $_ -like '*ServiceIdentity*' })) 'checklist warns that the default SPN filter hides agent identities'
$copilotChecklist = @(Get-EntraIscFeatureChecklist -FeatureNames @('CopilotDiscovery'))
Assert-True ([bool]($copilotChecklist | Where-Object { $_ -like '*Cognitive Services Data Contributor*' })) 'checklist names both Azure roles Foundry discovery needs'
Assert-True ([bool]($copilotChecklist | Where-Object { $_ -like '*user_impersonation*' })) 'checklist names the Azure Service Management delegated permission'
Assert-True ([bool]($copilotChecklist | Where-Object { $_ -like '*Dataverse application user*' })) 'checklist says Copilot Studio needs a Dataverse application user'
Assert-True ([bool]($copilotChecklist | Where-Object { $_ -like '*Global Discovery Service Role*' })) 'checklist names the Power Platform roles Copilot Studio needs'

# Selecting the Copilot Studio pack has to plan the Dataverse work, because Entra permissions alone
# never reach a Power Platform environment.
Assert-True (Test-CopilotStudioSelected -FeatureNames @('CopilotDiscovery')) 'the Copilot Studio pack is recognised'
Assert-True (-not (Test-CopilotStudioSelected -FeatureNames @('Agent365'))) 'other packs do not trigger the Dataverse step'
$copilotPlan = New-EntraAgentPlan -Request @{ config = @{ applicationName = ''; features = @('CopilotDiscovery') } }
Assert-True (@($copilotPlan.mutations) -contains 'configure-copilot-studio-dataverse-access') 'the plan includes the Dataverse application user step'
Assert-True ([bool](@($copilotPlan.manualSteps) | Where-Object { $_ -like '*az login*' })) 'the plan warns that the Azure CLI must be signed in'
Assert-True (@($catalog.optionalConfig) -contains 'powerPlatformEnvironmentUrl') 'the environment URL can be supplied explicitly'

$agent365Request = [ordered]@{
    schemaVersion = 1
    connector     = 'entra-id'
    config        = [ordered]@{ applicationName = 'SailPoint ISC Entra ID'; features = @('Agent365') }
    secretRefs    = [ordered]@{ agent365RefreshToken = 'env:AGENT365_REFRESH_TOKEN' }
}
$agent365Resolved = Get-EntraResolvedConfig -Request $agent365Request
Assert-True (Test-Agent365Selected -FeatureNames $agent365Resolved.Feature) 'Agent365 feature is recognised'
Assert-Equal 'env:AGENT365_REFRESH_TOKEN' $agent365Resolved.Agent365RefreshTokenRef 'refresh token reference is carried through'
Assert-Equal 'http://localhost:8400/' $agent365Resolved.Agent365RedirectUri 'redirect URI falls back to the loopback default'

$request = [ordered]@{
    schemaVersion = 1
    connector     = 'entra-id'
    config        = [ordered]@{
        applicationName = 'SailPoint ISC Entra ID'
        directoryRole   = 'UserAdministrator'
        features        = @('MfaManagement')
    }
    decisions = [ordered]@{ createNewApplication = $true; createSecret = $false }
}

$plan = New-EntraAgentPlan -Request $request
Assert-True ($plan.status -in @('ready', 'needsInput')) 'plan returns structured status'
Assert-True ($plan.requestHash.Length -eq 64) 'plan carries request hash'

# The refresh token is not a Connection Settings value, so the result has to keep it out of the
# public settings while still handing it to the operator. The agent adapter is deliberately not
# imported here: the wizard does not load it either, so writing secrets has to work without it.
$outputDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('entra-test-' + [guid]::NewGuid().ToString('N'))
try {
    $agent365Resolved.OutputDirectory = $outputDirectory
    $applyResult = [PSCustomObject]@{
        Session              = [PSCustomObject]@{ TenantId = 'tid'; DomainName = 'contoso.onmicrosoft.com' }
        IsUpdate             = $false
        Permissions          = @()
        DelegatedPermissions = @()
        RoleNames            = @()
        ConsentFailures      = @()
        Pair                 = [PSCustomObject]@{ Application = [PSCustomObject]@{ AppId = 'app-id'; Id = 'obj' }; ServicePrincipal = [PSCustomObject]@{ Id = 'sp' } }
        SecretValue          = $null
        SecretExpires        = $null
        AssignedRoles        = @()
        Agent365RefreshToken = 'refresh-token-value'
        Agent365Pending      = $null
    }

    $result = Build-EntraSourceResult -Resolved $agent365Resolved -ApplyResult $applyResult -RunDirectory $outputDirectory
    Assert-True (-not (@($result.connectionSettings.Keys) -contains 'Agent 365 Refresh Token')) 'refresh token stays out of the public connection settings'
    Assert-Equal 1 (@($result.secretArtifacts | Where-Object { $_.label -eq 'Agent 365 Refresh Token' }).Count) 'refresh token is saved as a restricted artifact'
    Assert-True ([bool]($result.completionItems | Where-Object { $_.Label -like 'Agent 365 Refresh Token*' -and $_.Mask })) 'refresh token is offered masked'
    Assert-True ([bool]($result.situation | Where-Object { $_ -like '*Machine Identity Governance Settings*' })) 'result says where the refresh token belongs'

    $applyResult.Agent365RefreshToken = $null
    $applyResult.Agent365Pending = 'no client secret was available to mint it'
    $pendingResult = Build-EntraSourceResult -Resolved $agent365Resolved -ApplyResult $applyResult -RunDirectory $outputDirectory
    Assert-True ([bool]($pendingResult.situation | Where-Object { $_ -like 'Pending: the Agent 365 refresh token*' })) 'a missing refresh token is reported as pending'
    Assert-Equal 0 (@($pendingResult.completionItems | Where-Object { $_.Label -like 'Agent 365*' }).Count) 'nothing is offered to copy when no token was issued'

    # Writing secrets used to fail only from the wizard, because the plan path happens to load the
    # agent adapter first and hides the missing dependency. A child process with the wizard's own
    # imports is the only way to reproduce that.
    $wizardScript = Join-Path $outputDirectory 'wizard-imports.ps1'
    Set-Content -LiteralPath $wizardScript -Encoding UTF8 -Value @'
param([string]$ModuleRoot, [string]$RunDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.EntraConnector.psm1') -Force
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.EntraCiemConnector.psm1') -Force
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.EntraSourceSetup.psm1') -Force
Initialize-OperatorConsole -NonInteractive
Initialize-EntraSourceSetup -ModuleRoot $ModuleRoot -NonInteractive

$resolved = [PSCustomObject]@{ Feature = @('Agent365'); OutputDirectory = $RunDirectory }
$applyResult = [PSCustomObject]@{
    Session              = [PSCustomObject]@{ TenantId = 'tid'; DomainName = 'contoso.onmicrosoft.com' }
    ConsentFailures      = @()
    RoleNames            = @()
    AssignedRoles        = @()
    Pair                 = [PSCustomObject]@{ Application = [PSCustomObject]@{ AppId = 'app-id'; Id = 'obj' } }
    SecretValue          = 'client-secret-value'
    Agent365RefreshToken = 'refresh-token-value'
    Agent365Pending      = $null
}
$null = Build-EntraSourceResult -Resolved $resolved -ApplyResult $applyResult -RunDirectory $RunDirectory
foreach ($name in @('client-secret.txt', 'agent365-refresh-token.txt')) {
    if (-not (Test-Path -LiteralPath (Join-Path $RunDirectory $name))) { throw "$name was not written" }
}
'@
    $wizardRun = Join-Path $outputDirectory 'wizard-run'
    & pwsh -NoProfile -File $wizardScript -ModuleRoot $ModuleRoot -RunDirectory $wizardRun 2>&1 | Out-String | Write-Verbose
    Assert-Equal 0 $LASTEXITCODE 'the wizard module set can write secret artifacts without the agent adapter'

    # Native Azure Entro features (Azure.Entro.psm1 + ISC.EntraSourceSetup.psm1)
    Import-Module (Join-Path $ModuleRoot 'IW.Core.psm1') -Force -Global -WarningAction SilentlyContinue
    Import-Module (Join-Path $ModuleRoot 'Definitions/Azure.Entro.psm1') -Force -WarningAction SilentlyContinue
    Register-IntegrationWizardPlatform -Name 'Azure' -Title 'Azure' -CoreOptions @('Connector', 'Entro') -CliName 'az'
    Register-AzureEntroDefinitions
    $azureEntroDef = Get-IntegrationWizardDefinition -Id 'azure-entro'
    Assert-True ($null -ne $azureEntroDef) 'azure-entro definition is registered'
    Assert-True (@($azureEntroDef.Inputs | ForEach-Object { $_.Name }) -contains 'ApplicationName') 'azure-entro defines ApplicationName input'
    Assert-True (@($azureEntroDef.Inputs | ForEach-Object { $_.Name }) -notcontains 'DisplayName') 'azure-entro does not define duplicate DisplayName input'

    $featureInput = @($azureEntroDef.Inputs | Where-Object { $_.Name -eq 'Feature' })[0]
    Assert-True ($null -ne $featureInput -and [bool]$featureInput.MultiChoice) 'azure-entro exposes MultiChoice Feature input'
    Assert-Equal 'AzureRbacAudit,LogAnalyticsForwarding,KeyVaultScanning,KeyVaultActivityLogs' ($featureInput.Options -join ',') 'azure-entro exposes the 4 selectable Entro features'

    $graphOnlySteps = @(& $azureEntroDef.Steps @{ Feature = @() })
    Assert-Equal 'entro-entra-app' (($graphOnlySteps | ForEach-Object { $_.Id }) -join ',') 'without Azure Entro features only entro-entra-app step runs'

    $rbacSteps = @(& $azureEntroDef.Steps @{ Feature = @('AzureRbacAudit') })
    Assert-Equal 'entro-entra-app,entro-azure-rbac' (($rbacSteps | ForEach-Object { $_.Id }) -join ',') 'AzureRbacAudit adds entro-azure-rbac step'

    $lawOnlySteps = @(& $azureEntroDef.Steps @{ Feature = @('LogAnalyticsForwarding') })
    Assert-Equal 'entro-entra-app,entro-law-forwarding' (($lawOnlySteps | ForEach-Object { $_.Id }) -join ',') 'LogAnalyticsForwarding adds entro-law-forwarding step'

    $kvScanSteps = @(& $azureEntroDef.Steps @{ Feature = @('KeyVaultScanning') })
    Assert-Equal 'entro-entra-app,entro-keyvault' (($kvScanSteps | ForEach-Object { $_.Id }) -join ',') 'KeyVaultScanning adds entro-keyvault step'

    $kvLogsSteps = @(& $azureEntroDef.Steps @{ Feature = @('KeyVaultActivityLogs') })
    Assert-Equal 'entro-entra-app,entro-law-forwarding,entro-keyvault' (($kvLogsSteps | ForEach-Object { $_.Id }) -join ',') 'KeyVaultActivityLogs adds both LAW and Key Vault steps'

    $allFeatureCtx = @{
        DisplayName               = 'EntroApp'
        TenantId                  = 'tid'
        Access                    = 'ReadOnly'
        SubscriptionId            = 'sub-1'
        ResourceGroupName         = 'EntroRG'
        LogAnalyticsWorkspaceName = 'EntroLAW'
        KeyVaultName              = 'kv-1'
        Feature                   = @('AzureRbacAudit', 'LogAnalyticsForwarding', 'KeyVaultScanning', 'KeyVaultActivityLogs')
    }
    $allSteps = @(& $azureEntroDef.Steps $allFeatureCtx)
    $renderedAll = (@($allSteps | ForEach-Object { $step = $_; & ($step.BuildScript) $allFeatureCtx })) -join "`n"
    Assert-True ($renderedAll -match 'EntroSecurityRole') 'native Azure Entro BuildScript emits EntroSecurityRole'
    Assert-True ($renderedAll -match 'microsoft\.aadiam/diagnosticSettings/EntroSecurityLogForwarding') 'native Azure Entro BuildScript emits Entra log forwarding'
    Assert-True ($renderedAll -match 'Set-AzKeyVaultAccessPolicy') 'native Azure Entro BuildScript emits Key Vault scanning'
    Assert-True ($renderedAll -match 'EntroKVActivityLogs') 'native Azure Entro BuildScript emits Key Vault activity logs'
    Assert-True ($renderedAll -notmatch 'Entro-Azure-Onboarding\.ps1' -and $renderedAll -notmatch 'pwsh -File') 'native Azure Entro BuildScript never shells out to Entro-Azure-Onboarding.ps1'

    # Exercise ISC.EntraSourceSetup native Azure Entro functions under -WhatIf and mocks
    Assert-Equal 0 (@(Set-EntroAzureRbacAudit -ServicePrincipalObjectId 'sp-1' -Scopes @('/subscriptions/sub-1') -WhatIf)).Count 'Set-EntroAzureRbacAudit respects -WhatIf'
    Assert-True ($null -eq (New-EntroLogAnalyticsWorkspace -SubscriptionId 'sub-1' -WhatIf)) 'New-EntroLogAnalyticsWorkspace respects -WhatIf'
    Assert-True ($null -eq (Set-EntroSignInLogForwarding -WorkspaceResourceId '/subs/1/law' -WhatIf)) 'Set-EntroSignInLogForwarding respects -WhatIf'
    Assert-Equal 0 (@(Set-EntroKeyVaultAccess -ServicePrincipalObjectId 'sp-1' -Vaults @([PSCustomObject]@{ VaultName = 'kv-1'; ResourceId = '/subs/1/kv/kv-1'; EnableRbacAuthorization = $false }) -WhatIf)).Count 'Set-EntroKeyVaultAccess respects -WhatIf'
    Assert-Equal 0 (@(Set-EntroKeyVaultActivityLogs -WorkspaceResourceId '/subs/1/law' -Vaults @([PSCustomObject]@{ VaultName = 'kv-1'; ResourceId = '/subs/1/kv/kv-1' }) -WhatIf)).Count 'Set-EntroKeyVaultActivityLogs respects -WhatIf'

    $script:MockAzCalls = [System.Collections.Generic.List[string]]::new()
    Set-Item -Path function:global:Set-AzContext -Value { param([string]$SubscriptionId) $script:MockAzCalls.Add("Set-AzContext:$SubscriptionId") }
    Set-Item -Path function:global:Get-AzRoleDefinition -Value {
        param([string]$Scope, [string]$Name)
        [PSCustomObject]@{ Id = "role-$Name"; Name = $Name }
    }
    Set-Item -Path function:global:New-AzRoleAssignment -Value {
        param([string]$ObjectId, [string]$RoleDefinitionId, [string]$Scope)
        $script:MockAzCalls.Add("New-AzRoleAssignment:$RoleDefinitionId@$Scope")
    }
    Set-Item -Path function:global:Get-AzResourceProvider -Value {
        param([string]$ProviderNamespace)
        [PSCustomObject]@{ RegistrationState = 'Registered' }
    }
    Set-Item -Path function:global:Get-AzResourceGroup -Value {
        param([string]$Name)
        [PSCustomObject]@{ ResourceGroupName = $Name; Location = 'eastus' }
    }
    Set-Item -Path function:global:Get-AzOperationalInsightsWorkspace -Value {
        param([string]$ResourceGroupName, [string]$Name)
        [PSCustomObject]@{ Name = $Name; ResourceId = "/subscriptions/sub-1/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$Name" }
    }
    Set-Item -Path function:global:Get-AzAccessToken -Value {
        param([string]$ResourceTypeName)
        [PSCustomObject]@{ Token = 'arm-token-mock' }
    }
    Set-Item -Path function:global:Invoke-RestMethod -Value {
        param([string]$Uri, [string]$Method, [hashtable]$Headers, [string]$Body)
        $script:MockAzCalls.Add("Invoke-RestMethod:${Method}:${Uri}")
        $parsed = $Body | ConvertFrom-Json
        $enabledCats = @($parsed.properties.logs | Where-Object { $_.enabled } | ForEach-Object { $_.category })
        $script:MockAzCalls.Add("EnabledLogs:" + ($enabledCats -join ','))
        return [PSCustomObject]@{ id = $Uri }
    }
    Set-Item -Path function:global:Set-AzKeyVaultAccessPolicy -Value {
        param([string]$VaultName, [string]$ObjectId, [switch]$BypassObjectIdValidation, [string[]]$PermissionsToKeys, [string[]]$PermissionsToSecrets, [string[]]$PermissionsToCertificates)
        $script:MockAzCalls.Add("Set-AzKeyVaultAccessPolicy:$VaultName")
    }
    Set-Item -Path function:global:New-AzDiagnosticSettingLogSettingsObject -Value {
        param([bool]$Enabled, [string]$CategoryGroup)
        [PSCustomObject]@{ Enabled = $Enabled; CategoryGroup = $CategoryGroup }
    }
    Set-Item -Path function:global:New-AzDiagnosticSettingMetricSettingsObject -Value {
        param([bool]$Enabled, [string]$Category)
        [PSCustomObject]@{ Enabled = $Enabled; Category = $Category }
    }
    Set-Item -Path function:global:Remove-AzDiagnosticSetting -Value {
        param([string]$ResourceId, [string]$Name)
        $script:MockAzCalls.Add("Remove-AzDiagnosticSetting:$Name")
    }
    Set-Item -Path function:global:New-AzDiagnosticSetting -Value {
        param([string]$Name, [string]$ResourceId, [string]$WorkspaceId, $Log, $Metric, [string]$LogAnalyticsDestinationType)
        $script:MockAzCalls.Add("New-AzDiagnosticSetting:${Name}:${ResourceId}")
    }
    try {
        $rbacRes = @(Set-EntroAzureRbacAudit -ServicePrincipalObjectId 'sp-1' -Scopes @('/subscriptions/sub-1') -RegisterInsightsProvider)
        Assert-Equal 1 $rbacRes.Count 'Set-EntroAzureRbacAudit returns assignment record for scope'
        Assert-True ($script:MockAzCalls -contains 'New-AzRoleAssignment:role-EntroSecurityRole@/subscriptions/sub-1') 'Set-EntroAzureRbacAudit assigns custom EntroSecurityRole'
        Assert-True ($script:MockAzCalls -contains 'New-AzRoleAssignment:role-Key Vault Reader@/subscriptions/sub-1') 'Set-EntroAzureRbacAudit assigns Key Vault Reader'
        Assert-True ($script:MockAzCalls -contains 'New-AzRoleAssignment:role-App Configuration Data Reader@/subscriptions/sub-1') 'Set-EntroAzureRbacAudit assigns App Configuration Data Reader'

        $law = New-EntroLogAnalyticsWorkspace -SubscriptionId 'sub-1' -ResourceGroupName 'EntroRG' -WorkspaceName 'EntroLAW'
        Assert-True ($law.ResourceId -like '*EntroLAW*') 'New-EntroLogAnalyticsWorkspace returns workspace ResourceId'

        $null = Set-EntroSignInLogForwarding -WorkspaceResourceId $law.ResourceId
        Assert-True ($script:MockAzCalls -contains 'EnabledLogs:AuditLogs,ServicePrincipalSignInLogs') 'Set-EntroSignInLogForwarding enables AuditLogs and ServicePrincipalSignInLogs'

        $kvRes = @(Set-EntroKeyVaultAccess -ServicePrincipalObjectId 'sp-1' -Vaults @(
            [PSCustomObject]@{ VaultName = 'kv-policy'; ResourceId = '/subs/1/kv/kv-policy'; EnableRbacAuthorization = $false }
            [PSCustomObject]@{ VaultName = 'kv-rbac'; ResourceId = '/subs/1/kv/kv-rbac'; EnableRbacAuthorization = $true }
        ))
        Assert-Equal 'AccessPolicy' $kvRes[0].Mode 'Set-EntroKeyVaultAccess configures AccessPolicy vault'
        Assert-Equal 'RBAC' $kvRes[1].Mode 'Set-EntroKeyVaultAccess configures RBAC vault'
        Assert-True ($script:MockAzCalls -contains 'Set-AzKeyVaultAccessPolicy:kv-policy') 'Set-AzKeyVaultAccessPolicy called for non-RBAC vault'
        Assert-True ($script:MockAzCalls -contains 'New-AzRoleAssignment:role-Key Vault Reader@/subs/1/kv/kv-rbac') 'Key Vault Reader assigned for RBAC vault'

        $kvLogRes = @(Set-EntroKeyVaultActivityLogs -WorkspaceResourceId $law.ResourceId -Vaults @([PSCustomObject]@{ VaultName = 'kv-policy'; ResourceId = '/subs/1/kv/kv-policy' }))
        Assert-Equal 'EntroKVActivityLogs' $kvLogRes[0].DiagnosticSetting 'Set-EntroKeyVaultActivityLogs configures EntroKVActivityLogs'
        Assert-True ($script:MockAzCalls -contains 'New-AzDiagnosticSetting:EntroKVActivityLogs:/subs/1/kv/kv-policy') 'New-AzDiagnosticSetting called with EntroKVActivityLogs'
    }
    finally {
        foreach ($fn in @('Set-AzContext', 'Get-AzRoleDefinition', 'New-AzRoleAssignment', 'Get-AzResourceProvider', 'Get-AzResourceGroup', 'Get-AzOperationalInsightsWorkspace', 'Get-AzAccessToken', 'Invoke-RestMethod', 'Set-AzKeyVaultAccessPolicy', 'New-AzDiagnosticSettingLogSettingsObject', 'New-AzDiagnosticSettingMetricSettingsObject', 'Remove-AzDiagnosticSetting', 'New-AzDiagnosticSetting')) {
            Remove-Item -Path "function:global:$fn" -ErrorAction SilentlyContinue
        }
    }
}
finally {
    if (Test-Path -LiteralPath $outputDirectory) {
        Remove-Item -LiteralPath $outputDirectory -Recurse -Force
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
