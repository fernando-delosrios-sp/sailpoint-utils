param(
    [string]$ModuleRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules')
)

. (Join-Path $PSScriptRoot '_TestHelpers.ps1')
$script:AssertionCount = 0

Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.AwsSourceSetup.psm1') -Force
Initialize-AwsSourceSetup -ModuleRoot $ModuleRoot

$saasCatalog = Get-AwsAgentCatalog -Variant 'aws-saas'
Assert-True ($saasCatalog.featurePacks -contains 'Ciem') 'saas catalog lists CIEM pack'

$ciemCatalog = Get-AwsAgentCatalog -Variant 'aws-ciem'
Assert-True ($ciemCatalog.requiredConfig -contains 'cloudTrailBucket') 'ciem catalog requires bucket'

$request = [ordered]@{
    schemaVersion = 1
    connector     = 'aws-saas'
    config        = [ordered]@{ externalId = '11111111-2222-3333-4444-555555555555' }
    decisions     = [ordered]@{ updateExistingRole = $true }
}

$plan = New-AwsAgentPlan -Request $request -Variant 'aws-saas'
Assert-True ($plan.status -in @('ready', 'needsInput')) 'saas plan returns structured status'

$orgRequest = [ordered]@{
    schemaVersion = 1
    connector     = 'aws-saas'
    config        = [ordered]@{
        externalId = '11111111-2222-3333-4444-555555555555'
        scope      = 'Organization'
    }
    decisions     = [ordered]@{ updateExistingRole = $true }
}
$orgPlan = New-AwsAgentPlan -Request $orgRequest -Variant 'aws-saas'
Assert-Equal 'needsInput' $orgPlan.status 'organization scope requires explicit approval'

Write-Host "PASS ($script:AssertionCount assertions)"
