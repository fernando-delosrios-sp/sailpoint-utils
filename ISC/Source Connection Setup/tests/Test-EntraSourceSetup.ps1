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

Write-Host "PASS ($script:AssertionCount assertions)"
