Set-StrictMode -Version Latest

function Get-EntroAzureContextFeatureNames {
    param([hashtable]$Context)
    $names = [System.Collections.Generic.List[string]]::new()
    if (-not $Context -or -not $Context.ContainsKey('Feature') -or $null -eq $Context['Feature']) {
        return ,@()
    }
    foreach ($entry in @($Context['Feature'])) {
        foreach ($part in ([string]$entry -split ',')) {
            $trimmed = $part.Trim()
            if ($trimmed -and -not $names.Contains($trimmed)) {
                $names.Add($trimmed)
            }
        }
    }
    return ,$names.ToArray()
}

function Get-EntroAzureGraphPermissions {
    param([string]$Access = 'ReadOnly')
    $appRoles = [System.Collections.Generic.List[string]]::new()
    foreach ($perm in @('User.Read.All', 'Directory.Read.All', 'Application.Read.All', 'AuditLog.Read.All')) {
        $appRoles.Add($perm)
    }
    if ($Access -ne 'ReadOnly') {
        $appRoles.Add('Application.ReadWrite.All')
    }
    return [PSCustomObject]@{
        AppRoles        = @($appRoles.ToArray())
        DelegatedScopes = @('User.Read')
    }
}

function Resolve-EntroAzureSubscriptionScopes {
    param([hashtable]$Context)
    $scopes = [System.Collections.Generic.List[string]]::new()
    $rawSub = if ($Context.ContainsKey('SubscriptionId') -and $Context['SubscriptionId']) { [string]$Context['SubscriptionId'] } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($rawSub)) {
        foreach ($part in ($rawSub -split ',')) {
            $subId = $part.Trim()
            if ($subId) {
                if ($subId -match '^/subscriptions/|^/providers/Microsoft\.Management/managementGroups/') {
                    $scopes.Add($subId)
                }
                else {
                    $scopes.Add("/subscriptions/$subId")
                }
            }
        }
    }
    elseif (Get-Command Get-AzSubscription -ErrorAction SilentlyContinue) {
        foreach ($sub in @(Get-AzSubscription -ErrorAction SilentlyContinue)) {
            if ($sub.Id) { $scopes.Add("/subscriptions/$($sub.Id)") }
        }
    }
    return ,$scopes.ToArray()
}

function Resolve-EntroAzureKeyVaultTargets {
    param([hashtable]$Context)
    if (-not (Get-Command Get-AzKeyVault -ErrorAction SilentlyContinue)) { return ,@() }
    $requestedNames = @()
    if ($Context.ContainsKey('KeyVaultName') -and -not [string]::IsNullOrWhiteSpace([string]$Context['KeyVaultName'])) {
        $requestedNames = @([string]$Context['KeyVaultName'] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    $vaults = @(Get-AzKeyVault -ErrorAction SilentlyContinue)
    if ($requestedNames.Count -gt 0) {
        $vaults = @($vaults | Where-Object { $requestedNames -contains $_.VaultName })
    }
    return ,$vaults
}

function Register-AzureEntroDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'azure-entro'
        Platform     = 'Azure'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'az'
        Title        = 'Entro Microsoft ecosystem integration'
        FolderName   = 'Entro-Microsoft'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Global Administrator or Application Administrator + Subscription Owner/User Access Administrator (for optional Azure RBAC/LAW/Key Vault features)')
        OutputsHelp  = 'Paste Environment nickname, Tenant ID, Client ID, and Client Secret into Entro.'
        Inputs       = @(
            @{ Name = 'EnvironmentNickname'; Source = 'Supply'; Prompt = 'Environment nickname'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'App display name'; Purpose = 'Entra application name'; Required = $false; Default = 'EntroSecurityApp' }
            @{ Name = 'TenantId'; Source = 'Supply'; Prompt = 'Tenant ID or domain'; Purpose = 'Microsoft Entra tenant (optional)'; Required = $false }
            @{
                Name        = 'Feature'
                Source      = 'Supply'
                Prompt      = 'Azure Entro feature packs (Space toggles, Enter confirms, Enter for Graph only)'
                Purpose     = 'Native Azure RBAC, Log Analytics, and Key Vault onboarding steps'
                Required    = $false
                MultiChoice = $true
                Options     = @('AzureRbacAudit', 'LogAnalyticsForwarding', 'KeyVaultScanning', 'KeyVaultActivityLogs')
                Labels      = @(
                    'AzureRbacAudit (EntroSecurityRole custom role, Key Vault Reader & App Configuration Data Reader)'
                    'LogAnalyticsForwarding (Log Analytics workspace + Entra AuditLogs & ServicePrincipalSignInLogs)'
                    'KeyVaultScanning (Key Vault access policies and Key Vault Reader RBAC)'
                    'KeyVaultActivityLogs (Key Vault EntroKVActivityLogs diagnostic setting to Log Analytics)'
                )
            }
            @{
                Name    = 'SubscriptionId'
                Source  = 'Supply'
                Prompt  = 'Azure Subscription ID(s) or Management Group scope (optional)'
                Purpose = 'Target scope for Azure RBAC, Log Analytics, or Key Vault configuration'
                Required = $false
                When    = { param($c) (Get-EntroAzureContextFeatureNames -Context $c | Where-Object { $_ -in @('AzureRbacAudit', 'LogAnalyticsForwarding', 'KeyVaultScanning', 'KeyVaultActivityLogs') }).Count -gt 0 }
            }
            @{
                Name     = 'ResourceGroupName'
                Source   = 'Supply'
                Prompt   = 'Log Analytics Resource Group'
                Purpose  = 'Resource group holding the Entro Log Analytics Workspace'
                Required = $false
                Default  = 'EntroSecurityRG'
                When     = { param($c) (Get-EntroAzureContextFeatureNames -Context $c | Where-Object { $_ -in @('LogAnalyticsForwarding', 'KeyVaultActivityLogs') }).Count -gt 0 }
            }
            @{
                Name     = 'LogAnalyticsWorkspaceName'
                Source   = 'Supply'
                Prompt   = 'Log Analytics Workspace name'
                Purpose  = 'Workspace receiving Entra sign-in / audit logs and Key Vault diagnostics'
                Required = $false
                Default  = 'EntroSecurityLogAnalytics'
                When     = { param($c) (Get-EntroAzureContextFeatureNames -Context $c | Where-Object { $_ -in @('LogAnalyticsForwarding', 'KeyVaultActivityLogs') }).Count -gt 0 }
            }
            @{
                Name     = 'KeyVaultName'
                Source   = 'Supply'
                Prompt   = 'Key Vault name(s), comma-separated (blank for all accessible vaults)'
                Purpose  = 'Target Key Vaults for scanning or activity log diagnostic settings'
                Required = $false
                When     = { param($c) (Get-EntroAzureContextFeatureNames -Context $c | Where-Object { $_ -in @('KeyVaultScanning', 'KeyVaultActivityLogs') }).Count -gt 0 }
            }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'TenantId'; Source = 'Supply'; Prompt = 'Azure tenant ID'; Purpose = 'Microsoft Entra tenant ID'; Required = $true }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'Azure Client ID'; Purpose = 'Application (client) ID'; Required = $true }
            @{ Name = 'ClientSecret'; Source = 'Supply'; Prompt = 'Azure Client Secret'; Purpose = 'Client secret value'; Required = $true; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            $features = Get-EntroAzureContextFeatureNames -Context $ctx
            $steps = [System.Collections.Generic.List[object]]::new()

            $steps.Add(@{
                Id    = 'entro-entra-app'
                Title = 'Ensure Entro Microsoft Entra application & Graph permissions'
                Kind  = 'Ensure'
                Run   = {
                    param($c)
                    $modRoot = Split-Path $PSScriptRoot -Parent
                    Import-Module (Join-Path $modRoot 'ISC.EntraConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                    Import-Module (Join-Path $modRoot 'ISC.EntraSourceSetup.psm1') -Force -Global -WarningAction SilentlyContinue
                    Initialize-EntraConnectorData

                    $displayName = if ($c['DisplayName']) { [string]$c['DisplayName'] } else { 'EntroSecurityApp' }
                    $tenantReq = if ($c['TenantId']) { [string]$c['TenantId'] } else { '' }
                    $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
                    $permSpec = Get-EntroAzureGraphPermissions -Access $access

                    $session = Connect-EntraGraph -RequestedTenantId $tenantReq -AdditionalScopes @('DelegatedPermissionGrant.ReadWrite.All')
                    $appPair = Get-EntraConnectorApplication -DisplayName $displayName
                    if (-not $appPair -or -not $appPair.Application) {
                        $appPair = New-EntraConnectorApplication -DisplayName $displayName
                    }

                    $graphSp = Get-ApiServicePrincipal -AppId '00000003-0000-0000-c000-000000000000' -Name 'Microsoft Graph'
                    if (-not $graphSp) {
                        throw 'Microsoft Graph service principal could not be resolved.'
                    }
                    $roles = @(Resolve-AppRoles -ServicePrincipal $graphSp -PermissionValues $permSpec.AppRoles -ResourceName 'Microsoft Graph')
                    $scopes = @(Resolve-DelegatedScopes -ServicePrincipal $graphSp -ScopeValues $permSpec.DelegatedScopes -ResourceName 'Microsoft Graph')
                    Set-RequiredResourceAccess -Application $appPair.Application `
                        -RolesByResource @{ Graph = $roles } `
                        -ScopesByResource @{ Graph = $scopes }
                    if ($roles.Count -gt 0 -and $appPair.ServicePrincipal) {
                        $null = Grant-AppRoleConsent -ServicePrincipal $appPair.ServicePrincipal -ResourceServicePrincipal $graphSp -Roles $roles
                    }
                    if ($scopes.Count -gt 0 -and $appPair.ServicePrincipal) {
                        $null = Grant-DelegatedConsent -ServicePrincipal $appPair.ServicePrincipal -ResourceServicePrincipal $graphSp -Scopes $scopes
                    }
                    $secret = New-EntraClientSecret -Application $appPair.Application -DisplayName 'EntroSecurity' -ValidityMonths 24

                    $c['EntroTenantId'] = [string]$session.TenantId
                    $c['EntroClientId'] = [string]$appPair.Application.AppId
                    if ($appPair.ServicePrincipal) {
                        $c['EntroServicePrincipalId'] = [string]$appPair.ServicePrincipal.Id
                    }
                    if ($c['OutputDirectory']) {
                        if (-not (Test-Path -LiteralPath $c['OutputDirectory'])) {
                            New-Item -ItemType Directory -Path $c['OutputDirectory'] -Force | Out-Null
                        }
                        $outFile = Join-Path $c['OutputDirectory'] 'entro-azure-settings.txt'
                        $lines = @(
                            "Environment Nickname: $($c['EnvironmentNickname'])"
                            "Display Name:         $displayName"
                            "Tenant ID:            $($session.TenantId)"
                            "Client ID:            $($appPair.Application.AppId)"
                            "Client Secret:        $($secret.SecretText)"
                            "Access Level:         $access"
                        )
                        Set-Content -LiteralPath $outFile -Value ($lines -join [Environment]::NewLine) -Encoding utf8
                    }
                }
                BuildScript = {
                    param($c)
                    $displayName = if ($c['DisplayName']) { [string]$c['DisplayName'] } else { 'EntroSecurityApp' }
                    $tenantReq = if ($c['TenantId']) { [string]$c['TenantId'] } else { '' }
                    $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
                    $permSpec = Get-EntroAzureGraphPermissions -Access $access
                    $rolesList = ($permSpec.AppRoles | ForEach-Object { "'$_'" }) -join ', '
                    @"
# -----------------------------------------------------------------------------
# Native Entro Microsoft Entra Application & Graph Permissions ($access)
# -----------------------------------------------------------------------------
`$displayName = '$displayName'
`$tenantId = '$tenantReq'
`$requiredGraphRoles = @($rolesList)
`$requiredGraphScopes = @('User.Read')

Connect-MgGraph -Scopes @('Application.ReadWrite.All', 'AppRoleAssignment.ReadWrite.All', 'DelegatedPermissionGrant.ReadWrite.All', 'Directory.Read.All') `$(if (`$tenantId) { @{ TenantId = `$tenantId } } else { @{} }) -NoWelcome
`$ctx = Get-MgContext
if (-not `$tenantId) { `$tenantId = `$ctx.TenantId }

`$app = Get-MgApplication -Filter "displayName eq '`$displayName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not `$app) {
    `$app = New-MgApplication -DisplayName `$displayName -SignInAudience 'AzureADMyOrg'
}
`$sp = Get-MgServicePrincipal -Filter "appId eq '`$(`$app.AppId)'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not `$sp) {
    `$sp = New-MgServicePrincipal -AppId `$app.AppId
}

`$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
`$resourceAccess = @()
foreach (`$roleName in `$requiredGraphRoles) {
    `$role = `$graphSp.AppRoles | Where-Object { `$_.Value -eq `$roleName } | Select-Object -First 1
    if (`$role) {
        `$resourceAccess += @{ Id = `$role.Id; Type = 'Role' }
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId `$sp.Id -PrincipalId `$sp.Id -ResourceId `$graphSp.Id -AppRoleId `$role.Id -ErrorAction SilentlyContinue | Out-Null
    }
}
foreach (`$scopeName in `$requiredGraphScopes) {
    `$scope = `$graphSp.OAuth2PermissionScopes | Where-Object { `$_.Value -eq `$scopeName } | Select-Object -First 1
    if (`$scope) { `$resourceAccess += @{ Id = `$scope.Id; Type = 'Scope' } }
}
Update-MgApplication -ApplicationId `$app.Id -RequiredResourceAccess @(@{ ResourceAppId = `$graphSp.AppId; ResourceAccess = `$resourceAccess })
`$secret = Add-MgApplicationPassword -ApplicationId `$app.Id -PasswordCredential @{ DisplayName = 'EntroSecurity'; EndDateTime = (Get-Date).ToUniversalTime().AddMonths(24) }
Write-Host "Entro App Ready - Tenant: `$tenantId | Client ID: `$(`$app.AppId) | Secret: `$(`$secret.SecretText)" -ForegroundColor Green
"@
                }
            })

            if ($features -contains 'AzureRbacAudit') {
                $steps.Add(@{
                    Id    = 'entro-azure-rbac'
                    Title = 'Configure Entro Azure RBAC custom role & built-in readers'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        $modRoot = Split-Path $PSScriptRoot -Parent
                        Import-Module (Join-Path $modRoot 'ISC.EntraSourceSetup.psm1') -Force -Global -WarningAction SilentlyContinue
                        $spId = [string]$c['EntroServicePrincipalId']
                        if (-not $spId) { throw 'EntroServicePrincipalId is missing; run entro-entra-app first.' }
                        $scopes = @(Resolve-EntroAzureSubscriptionScopes -Context $c)
                        if ($scopes.Count -eq 0) { throw 'No Azure subscription scopes resolved. Supply -SubscriptionId or sign in with Connect-AzAccount.' }
                        $roleName = if ($c['AzureRoleName']) { [string]$c['AzureRoleName'] } else { 'EntroSecurityRole' }
                        $null = Set-EntroAzureRbacAudit -ServicePrincipalObjectId $spId -Scopes $scopes -RoleName $roleName -RegisterInsightsProvider
                    }
                    BuildScript = {
                        param($c)
                        $subScope = if ($c['SubscriptionId']) { "/subscriptions/$($c['SubscriptionId'])" } else { '/subscriptions/<SUBSCRIPTION_ID>' }
                        @"
# -----------------------------------------------------------------------------
# Native Entro Azure RBAC: EntroSecurityRole + Key Vault Reader + App Config Data Reader
# -----------------------------------------------------------------------------
`$scope = '$subScope'
`$role = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
`$role.Name = 'EntroSecurityRole'
`$role.Description = 'Entro Security requires permissions to manage and monitor tokens, secrets, and vaults.'
`$role.IsCustom = `$true
`$role.Actions = @(
    '*/read',
    'Microsoft.OperationalInsights/workspaces/analytics/query/action',
    'Microsoft.OperationalInsights/workspaces/search/action',
    'Microsoft.Insights/alertRules/*',
    'Microsoft.Support/*',
    'Microsoft.Web/sites/config/list/Action'
)
`$role.NotActions = @('Microsoft.OperationalInsights/workspaces/sharedKeys/read')
`$role.AssignableScopes = @(`$scope)
if (-not (Get-AzRoleDefinition -Scope `$scope -Name `$role.Name -ErrorAction SilentlyContinue)) {
    New-AzRoleDefinition -SkipClientSideScopeValidation -Role `$role | Out-Null
}
`$customRole = Get-AzRoleDefinition -Scope `$scope -Name `$role.Name
if (`$customRole) {
    New-AzRoleAssignment -ObjectId `$sp.Id -RoleDefinitionId `$customRole.Id -Scope `$scope -ErrorAction SilentlyContinue | Out-Null
}
foreach (`$builtIn in @('Key Vault Reader', 'App Configuration Data Reader')) {
    `$def = Get-AzRoleDefinition -Name `$builtIn -ErrorAction SilentlyContinue
    if (`$def) { New-AzRoleAssignment -ObjectId `$sp.Id -RoleDefinitionId `$def.Id -Scope `$scope -ErrorAction SilentlyContinue | Out-Null }
}
Register-AzResourceProvider -ProviderNamespace 'Microsoft.Insights' | Out-Null
"@
                    }
                })
            }

            if (($features -contains 'LogAnalyticsForwarding') -or ($features -contains 'KeyVaultActivityLogs')) {
                $steps.Add(@{
                    Id    = 'entro-law-forwarding'
                    Title = 'Ensure Log Analytics Workspace & Entra log forwarding'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        $modRoot = Split-Path $PSScriptRoot -Parent
                        Import-Module (Join-Path $modRoot 'ISC.EntraSourceSetup.psm1') -Force -Global -WarningAction SilentlyContinue
                        $rgName = if ($c['ResourceGroupName']) { [string]$c['ResourceGroupName'] } else { 'EntroSecurityRG' }
                        $lawName = if ($c['LogAnalyticsWorkspaceName']) { [string]$c['LogAnalyticsWorkspaceName'] } else { 'EntroSecurityLogAnalytics' }
                        $loc = if ($c['AzureLocation']) { [string]$c['AzureLocation'] } else { 'eastus' }
                        $subId = if ($c['SubscriptionId']) { ([string]$c['SubscriptionId'] -split ',')[0].Trim() } else { '' }
                        $law = New-EntroLogAnalyticsWorkspace -SubscriptionId $subId -ResourceGroupName $rgName -WorkspaceName $lawName -Location $loc
                        if ($law -and $law.ResourceId) {
                            $c['EntroLawResourceId'] = [string]$law.ResourceId
                            $f = Get-EntroAzureContextFeatureNames -Context $c
                            if ($f -contains 'LogAnalyticsForwarding') {
                                $null = Set-EntroSignInLogForwarding -WorkspaceResourceId ([string]$law.ResourceId)
                            }
                        }
                    }
                    BuildScript = {
                        param($c)
                        $rgName = if ($c['ResourceGroupName']) { [string]$c['ResourceGroupName'] } else { 'EntroSecurityRG' }
                        $lawName = if ($c['LogAnalyticsWorkspaceName']) { [string]$c['LogAnalyticsWorkspaceName'] } else { 'EntroSecurityLogAnalytics' }
                        $f = Get-EntroAzureContextFeatureNames -Context $c
                        $forwardBlock = if ($f -contains 'LogAnalyticsForwarding') {
                            @"
# Forward Entra AuditLogs & ServicePrincipalSignInLogs via ARM REST PUT
`$token = (Get-AzAccessToken -ResourceTypeName Arm).Token
if (`$token -is [System.Security.SecureString]) { `$token = [System.Net.NetworkCredential]::new('', `$token).Password }
`$headers = @{ Authorization = "Bearer `$token"; 'Content-Type' = 'application/json' }
`$diagBody = @{
    properties = @{
        workspaceId = `$law.ResourceId
        metrics = @()
        logs = @(
            @{ category = 'AuditLogs'; enabled = `$true; retentionPolicy = @{ days = 0; enabled = `$false } }
            @{ category = 'ServicePrincipalSignInLogs'; enabled = `$true; retentionPolicy = @{ days = 0; enabled = `$false } }
        )
    }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod -Uri 'https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/EntroSecurityLogForwarding?api-version=2017-04-01' -Method Put -Headers `$headers -Body `$diagBody | Out-Null
"@
                        } else { '' }
                        @"
# -----------------------------------------------------------------------------
# Native Entro Log Analytics Workspace & Entra Log Forwarding
# -----------------------------------------------------------------------------
`$rgName = '$rgName'
`$lawName = '$lawName'
if (-not (Get-AzResourceGroup -Name `$rgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name `$rgName -Location 'eastus' | Out-Null
}
`$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName `$rgName -Name `$lawName -ErrorAction SilentlyContinue
if (-not `$law) {
    `$law = New-AzOperationalInsightsWorkspace -ResourceGroupName `$rgName -Name `$lawName -Location 'eastus' -Sku 'PerGB2018' -RetentionInDays 30 -Force
}
$forwardBlock
"@
                    }
                })
            }

            if (($features -contains 'KeyVaultScanning') -or ($features -contains 'KeyVaultActivityLogs')) {
                $steps.Add(@{
                    Id    = 'entro-keyvault'
                    Title = 'Configure Azure Key Vault scanning & activity logs for Entro'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        $modRoot = Split-Path $PSScriptRoot -Parent
                        Import-Module (Join-Path $modRoot 'ISC.EntraSourceSetup.psm1') -Force -Global -WarningAction SilentlyContinue
                        $vaults = @(Resolve-EntroAzureKeyVaultTargets -Context $c)
                        $f = Get-EntroAzureContextFeatureNames -Context $c
                        if ($f -contains 'KeyVaultScanning') {
                            $spId = [string]$c['EntroServicePrincipalId']
                            if (-not $spId) { throw 'EntroServicePrincipalId is missing; run entro-entra-app first.' }
                            $null = Set-EntroKeyVaultAccess -ServicePrincipalObjectId $spId -Vaults $vaults
                        }
                        if ($f -contains 'KeyVaultActivityLogs') {
                            $lawId = [string]$c['EntroLawResourceId']
                            if (-not $lawId) { throw 'EntroLawResourceId is missing; ensure Log Analytics Workspace first.' }
                            $null = Set-EntroKeyVaultActivityLogs -WorkspaceResourceId $lawId -Vaults $vaults
                        }
                    }
                    BuildScript = {
                        param($c)
                        $kvFilter = if ($c['KeyVaultName']) { [string]$c['KeyVaultName'] } else { '' }
                        $f = Get-EntroAzureContextFeatureNames -Context $c
                        $scanSnippet = if ($f -contains 'KeyVaultScanning') {
                            @"
    if (-not `$vault.EnableRbacAuthorization) {
        Set-AzKeyVaultAccessPolicy -VaultName `$vault.VaultName -ObjectId `$sp.Id -BypassObjectIdValidation ``
            -PermissionsToKeys @('get', 'list', 'decrypt', 'unwrapKey') ``
            -PermissionsToSecrets @('get', 'list') ``
            -PermissionsToCertificates @('get', 'list', 'getissuers', 'listissuers')
    } else {
        `$kvReader = Get-AzRoleDefinition -Name 'Key Vault Reader'
        New-AzRoleAssignment -ObjectId `$sp.Id -RoleDefinitionId `$kvReader.Id -Scope `$vault.ResourceId -ErrorAction SilentlyContinue | Out-Null
    }
"@
                        } else { '' }
                        $actSnippet = if ($f -contains 'KeyVaultActivityLogs') {
                            @"
    `$kvLogs = @(
        (New-AzDiagnosticSettingLogSettingsObject -Enabled `$true -CategoryGroup 'audit')
        (New-AzDiagnosticSettingLogSettingsObject -Enabled `$true -CategoryGroup 'allLogs')
    )
    `$kvMetrics = New-AzDiagnosticSettingMetricSettingsObject -Enabled `$false -Category 'AllMetrics'
    New-AzDiagnosticSetting -Name 'EntroKVActivityLogs' -ResourceId `$vault.ResourceId -WorkspaceId `$law.ResourceId ``
        -Log `$kvLogs -Metric `$kvMetrics -LogAnalyticsDestinationType 'AzureDiagnostics' | Out-Null
"@
                        } else { '' }
                        @"
# -----------------------------------------------------------------------------
# Native Entro Key Vault Scanning & Activity Logs
# -----------------------------------------------------------------------------
`$targetVaultFilter = '$kvFilter'
`$vaults = @(Get-AzKeyVault)
if (`$targetVaultFilter) {
    `$names = @(`$targetVaultFilter -split ',' | ForEach-Object { `$_.Trim() } | Where-Object { `$_ })
    `$vaults = @(`$vaults | Where-Object { `$names -contains `$_.VaultName })
}
foreach (`$vault in `$vaults) {
$scanSnippet$actSnippet}
"@
                    }
                })
            }

            return @($steps.ToArray())
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Environment: $($ctx['EnvironmentNickname'])"
            if ($ctx['EntroTenantId']) { Write-Host "  Tenant ID:   $($ctx['EntroTenantId'])" }
            if ($ctx['EntroClientId']) { Write-Host "  Client ID:   $($ctx['EntroClientId'])" }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-AzureEntroDefinitions, Get-EntroAzureGraphPermissions
