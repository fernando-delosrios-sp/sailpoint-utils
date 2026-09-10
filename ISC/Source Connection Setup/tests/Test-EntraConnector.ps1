param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.EntraConnector.psm1')
)

$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:AssertionCount++
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    $script:AssertionCount++
    if ($Expected -ne $Actual) {
        throw "Assertion failed: $Message. Expected '$Expected', got '$Actual'."
    }
}

Import-Module $ModulePath -Force -WarningAction SilentlyContinue
Initialize-EntraConnectorData
$catalog = Get-EntraConnectorCatalog

Assert-True ($catalog.CorePermissions.Count -gt 0) 'core permissions load'
Assert-True ($catalog.FeaturePacks.Contains('AccessPackages')) 'feature packs include AccessPackages'

$perms = @(Get-SelectedPermissions -Mode 'Granular' -FeatureNames @('MfaManagement'))
Assert-True ($perms.Count -gt $catalog.CorePermissions.Count) 'feature pack expands permissions'

$directory = @(Get-SelectedPermissions -Mode 'Directory' -FeatureNames @())
Assert-True ($directory.Count -lt $perms.Count) 'directory mode is coarser than granular plus features'

Write-Host "PASS ($script:AssertionCount assertions)"
