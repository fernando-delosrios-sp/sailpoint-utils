param(
    [string]$CiemPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.EntraCiemConnector.psm1')
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

Import-Module $CiemPath -Force -WarningAction SilentlyContinue
Initialize-EntraCiemConnectorData

Assert-True (-not (Test-EmbeddedCiemSelected -FeatureNames @('MfaManagement'))) 'Ciem not selected without Ciem'
Assert-True (Test-EmbeddedCiemSelected -FeatureNames @('Ciem')) 'Ciem selected'

$empty = @(Merge-EntraCiemPermissions -FeatureNames @('MfaManagement'))
Assert-Equal 0 $empty.Count 'no CIEM permissions without Ciem pack'

$ciemPerms = @(Merge-EntraCiemPermissions -FeatureNames @('Ciem'))
Assert-True ($ciemPerms.Count -ge 3) 'CIEM permissions merged when Ciem selected'
Assert-True (@($ciemPerms | ForEach-Object { $_.Pack }) -contains 'Ciem') 'permissions tagged with Ciem pack'

$settings = Build-EmbeddedCiemConnectionSettings -Context @{ FeatureNames = @('Ciem') }
Assert-True ($settings.Contains('Enable CIEM on SaaS source')) 'embedded CIEM connection hint'

Write-Host "PASS ($script:AssertionCount assertions)"
