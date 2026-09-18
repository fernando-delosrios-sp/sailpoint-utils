param(
    [string]$CiemPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.GoogleCiemConnector.psm1'),
    [string]$ConnectorPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.GoogleWorkspaceConnector.psm1')
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

$connector = Import-Module $ConnectorPath -Force -PassThru -WarningAction SilentlyContinue
Initialize-GoogleWorkspaceConnectorData
Set-StrictMode -Version Latest
$keyMeta = [pscustomobject]@{ client_id = '123456789.apps.googleusercontent.com' }
Assert-Equal '123456789.apps.googleusercontent.com' (Get-JsonProperty -InputObject $keyMeta -Name 'client_id') 'exported Get-JsonProperty reads client_id for the setup script'
Assert-True ($null -eq (Get-JsonProperty -InputObject $keyMeta -Name 'missing')) 'exported Get-JsonProperty returns null for missing JSON fields under StrictMode'

# The console owns NonInteractive; a module-local copy is never set and StrictMode makes reading
# it terminate. Each prompt gate below has to return instead of prompting or throwing.
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole -NonInteractive
Assert-True ($null -eq (Wait-Continue -Prompt 'Press Enter')) 'Wait-Continue skips the prompt when non-interactive'
Assert-True ($null -eq (Invoke-OAuthClientWalkthrough -Project 'p' -Redirect 'http://localhost:8088' -Reason 'r')) 'OAuth client walkthrough is skipped when non-interactive'
Assert-True ($null -eq (Invoke-OAuthAudienceWalkthrough -Project 'p')) 'Audience walkthrough is skipped when non-interactive'
$gwsCatalog = Get-GoogleWorkspaceCatalog
$gwsLabels = @($gwsCatalog.FeaturePacks.Keys | ForEach-Object { [string]$gwsCatalog.FeaturePacks[$_].Label })
Assert-Equal (($gwsLabels | Sort-Object) -join '|') ($gwsLabels -join '|') 'Google feature packs are ordered by label'
& $connector {
    Set-Item -Path 'function:script:Invoke-GCloud' -Value {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        return @(
            '//aiplatform.googleapis.com/projects/309622998400/locations/europe-west1/reasoningEngines/7596648981606694912'
            '//aiplatform.googleapis.com/projects/309622998400/locations/us-central1/reasoningEngines/4035427576263475200'
            '//aiplatform.googleapis.com/projects/309622998400/locations/europe-west1/reasoningEngines/8471473209223413760'
        )
    }
}
$agentRegions = @(Get-GoogleVertexAgentRegions -OrgId '123456789')
Assert-Equal 2 $agentRegions.Count 'agent regions are de-duplicated'
Assert-Equal 'europe-west1' $agentRegions[0] 'agent regions are sorted'
Assert-True ($agentRegions -contains 'us-central1') 'every agent region is reported'

& $connector {
    Set-Item -Path 'function:script:Invoke-GCloud' -Value {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        throw 'Cloud Asset API has not been used in project'
    }
}
Assert-Equal 0 @(Get-GoogleVertexAgentRegions -OrgId '123456789').Count 'region discovery failure returns empty rather than throwing'

Write-Host "PASS ($script:AssertionCount assertions)"
