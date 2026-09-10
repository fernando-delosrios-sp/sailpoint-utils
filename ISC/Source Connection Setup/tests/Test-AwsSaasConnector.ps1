param(
    [string]$ConnectorPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AwsConnector.psm1'),
    [string]$CiemPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AwsCiemConnector.psm1'),
    [string]$SaasPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AwsSaasConnector.psm1')
)

$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:AssertionCount++
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$Message)
    $script:AssertionCount++
    if ($Haystack -notlike "*$Needle*") {
        throw "Assertion failed: $Message. Expected document to contain '$Needle'."
    }
}

Import-Module $ConnectorPath -Force -WarningAction SilentlyContinue
Import-Module $CiemPath -Force -WarningAction SilentlyContinue
Import-Module $SaasPath -Force -WarningAction SilentlyContinue
Initialize-AwsConnectorData
Initialize-AwsCiemConnectorData
Initialize-AwsSaasConnectorData

$catalog = Get-AwsSaasCatalog
Assert-True ($catalog.FeaturePacks.Contains('ActivityInsights')) 'ActivityInsights pack exists'
Assert-True ($catalog.FeaturePacks.Contains('AgentDiscovery')) 'AgentDiscovery pack exists'

# Identity Center belongs to the CIEM AWS source, so the SaaS role never grants sso: / identitystore:.
Assert-True (-not $catalog.FeaturePacks.Contains('IdentityCenter')) 'no Identity Center pack on SaaS'
Assert-True (-not $catalog.FeaturePacks.Contains('IdentityCenterProvisioning')) 'no Identity Center provisioning pack on SaaS'
Assert-True ($catalog.ManagedPolicyNames -contains 'SPIdentityCenterPolicy') 'legacy Identity Center policy still detachable'

$icDocs = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @('IdentityCenter', 'IdentityCenterProvisioning') `
    -Partition 'aws' -WarningAction SilentlyContinue
Assert-True (-not $icDocs.Contains('SPIdentityCenterPolicy')) 'Identity Center request produces no SaaS policy'
Assert-True (-not $icDocs.Contains('SPIdentityCenterProvisioningPolicy')) 'Identity Center provisioning request produces no SaaS policy'

$baseDocs = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @() -Partition 'aws'
Assert-True ($baseDocs.Contains('SPAggregationPolicy')) 'base aggregation policy'
Assert-True ($baseDocs.Contains('SPOrganizationPolicy')) 'base organization policy'
Assert-True ($baseDocs.Contains('SPProvisioningPolicy')) 'provisioning included by default'

$aggOnly = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @() -SkipProvisioning -Partition 'aws'
Assert-True (-not $aggOnly.Contains('SPProvisioningPolicy')) 'SkipProvisioning omits provisioning'

$activityDocs = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @('ActivityInsights') -Partition 'aws'
$activityJson = $activityDocs['SPActivityInsightsPolicy']
Assert-Contains $activityJson 'cloudtrail:LookupEvents' 'ActivityInsights policy actions'

$trust = New-TrustPolicyDocument -PrincipalArn @('arn:aws:iam::874540850173:role/ciem_universal') `
    -ExternalIdValue 'test-external-id' -AllowTagSession
Assert-Contains $trust 'sts:TagSession' 'Activity Insights trust includes TagSession'

# Get-IAMRole returns AssumeRolePolicyDocument percent-encoded, exactly as IAM stores it.
$encodedTrust = [System.Uri]::EscapeDataString($trust)
Assert-True ($encodedTrust.StartsWith('%7B')) 'IAM-style trust document is percent-encoded'
$decodedTrust = ConvertFrom-IamPolicyDocument -Document $encodedTrust
Assert-True ($decodedTrust.Statement[0].Condition.StringEquals.'sts:ExternalId' -eq 'test-external-id') 'percent-encoded trust policy parses'
$plainTrust = ConvertFrom-IamPolicyDocument -Document $trust
Assert-True ($plainTrust.Statement[0].Condition.StringEquals.'sts:ExternalId' -eq 'test-external-id') 'already-decoded trust policy still parses'

$agentDocs = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @('AgentDiscovery') -Partition 'aws'
$agentJson = $agentDocs['SPAgentDiscoveryPolicy']
Assert-Contains $agentJson 'bedrock:ListAgents' 'Bedrock agent discovery'
Assert-Contains $agentJson 'bedrock-agentcore:ListAgentRuntimes' 'AgentCore discovery'
Assert-Contains $agentJson 'connect:ListBots' 'Connect customer agent discovery'

$ciemDocs = Get-SelectedPolicyDocuments -Set 'Mgo' -FeatureNames @('Ciem') -BucketName 'my-trail-bucket' -Partition 'aws'
Assert-True ($ciemDocs.Contains('SPCiemPolicy')) 'CIEM policy when Ciem feature selected'
Assert-True ($ciemDocs.Contains('SPCloudTrailBucketPolicy')) 'bucket policy when bucket name supplied'
Assert-Contains $ciemDocs['SPCiemPolicy'] 'cloudtrail:LookupEvents' 'CIEM policy includes CloudTrail read'

Write-Host "PASS ($script:AssertionCount assertions)"
