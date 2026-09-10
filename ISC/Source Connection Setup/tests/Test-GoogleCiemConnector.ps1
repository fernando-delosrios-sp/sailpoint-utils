param(
    [string]$CiemPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.GoogleCiemConnector.psm1')
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
Initialize-GoogleCiemConnectorData

Assert-True (-not (Test-EmbeddedCiemSelected -FeatureNames @('Gcp'))) 'Ciem toggle is separate from Gcp pack'
Assert-True (Test-EmbeddedCiemSelected -FeatureNames @('Ciem')) 'Ciem selected'
Assert-True (Test-NeedsGcp -FeatureNames @('NhiDiscovery')) 'NhiDiscovery needs GCP'

$scopes = @(Get-GoogleCiemScopes -FeatureNames @('GmailDelegates'))
Assert-Equal 0 $scopes.Count 'non-GCP features do not add GCP scopes'

$gcpScopes = @(Get-GoogleCiemScopes -FeatureNames @('Gcp'))
Assert-True ($gcpScopes.Count -ge 2) 'Gcp pack adds cloud-platform scopes'

$perms = @(Get-GoogleCustomRolePermissions -FeatureNames @('Gcp', 'AgentDiscovery'))
Assert-True ($perms -contains 'aiplatform.agents.list') 'AgentDiscovery adds Vertex agent permissions'

try {
    Apply-EmbeddedCiemPrerequisites -Context @{ FeatureNames = @('Ciem') }
    throw 'Apply-EmbeddedCiemPrerequisites should require organization ID'
}
catch {
    Assert-True ($_.Exception.Message -like '*organization*') 'CIEM prerequisites require organization ID'
}

$settings = Build-EmbeddedCiemConnectionSettings -Context @{
    FeatureNames   = @('Ciem')
    OrganizationId = '123456789'
}
Assert-True ($settings.Contains('Google Organization ID (CIEM)')) 'org id in CIEM settings'

$checklist = @(Get-GoogleIscFeatureChecklist -FeatureNames @('AgentDiscovery') `
    -OrganizationId '123456789' -GcpRegions @('us-central1') -GrantType 'ServiceAccount')
Assert-True (($checklist -join ' ') -like '*Vertex*') 'AgentDiscovery checklist mentions Vertex'
Assert-True (($checklist -join ' ') -like '*us-central1*') 'regions in checklist'

Write-Host "PASS ($script:AssertionCount assertions)"
