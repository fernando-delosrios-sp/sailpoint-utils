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
}
finally {
    if (Test-Path -LiteralPath $outputDirectory) {
        Remove-Item -LiteralPath $outputDirectory -Recurse -Force
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
