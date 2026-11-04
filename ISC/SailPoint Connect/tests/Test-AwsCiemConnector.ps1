param(
    [string]$ConnectorPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AwsConnector.psm1'),
    [string]$CiemPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AwsCiemConnector.psm1'),
    [string]$ConsolePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorConsole.psm1')
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

# AWS.Tools cmdlets are absent here, so these globals stand in for the CloudTrail scan.
function Mock-CiemTrailScan {
    param([object[]]$Trails)

    $script:MockCiemTrails = @($Trails)
    Set-Item -Path function:global:Get-EC2Region -Value {
        [CmdletBinding()] param([string]$Region)
        throw 'EC2 region enumeration is unavailable in tests'
    }
    Set-Item -Path function:global:Get-CTTrail -Value {
        [CmdletBinding()] param([string]$Region)
        $script:MockCiemTrails
    }
}

function Clear-CiemTrailScanMock {
    Remove-Item -Path function:global:Get-CTTrail -ErrorAction SilentlyContinue
    Remove-Item -Path function:global:Get-EC2Region -ErrorAction SilentlyContinue
    $script:MockCiemTrails = @()
}

function Mock-S3BucketList {
    param([string[]]$BucketNames)

    $script:MockS3Buckets = @($BucketNames | ForEach-Object { [PSCustomObject]@{ BucketName = $_ } })
    Set-Item -Path function:global:Get-S3Bucket -Value {
        [CmdletBinding()] param([string]$BucketName, [string]$Region)
        $script:MockS3Buckets
    }
}

function Clear-S3BucketListMock {
    Remove-Item -Path function:global:Get-S3Bucket -ErrorAction SilentlyContinue
    $script:MockS3Buckets = @()
}

Import-Module $ConsolePath -Force -WarningAction SilentlyContinue
Import-Module $ConnectorPath -Force -WarningAction SilentlyContinue
Import-Module $CiemPath -Force -WarningAction SilentlyContinue
Initialize-AwsConnectorData
Initialize-AwsCiemConnectorData

Assert-True (-not (Test-EmbeddedCiemSelected -FeatureNames @('ActivityInsights'))) 'Ciem not selected without Ciem pack'
Assert-True (Test-EmbeddedCiemSelected -FeatureNames @('Ciem', 'ActivityInsights')) 'Ciem selected with Ciem pack'
Assert-True (Test-AwsSaasCiemFeature -FeatureNames @('Ciem')) 'Test-AwsSaasCiemFeature alias'

$pack = Get-EmbeddedCiemFeaturePack
Assert-True ($pack.Label -like '*CIEM*') 'embedded CIEM feature pack label'

$empty = Build-EmbeddedCiemConnectionSettings -Context @{ FeatureNames = @() }
Assert-True ($empty.Count -eq 0) 'no CIEM settings when Ciem not selected'

$arns = @(Get-NormalizedCloudTrailArnList -Value @(' arn:a , arn:b '))
Assert-True ($arns.Count -eq 2) 'normalized CloudTrail ARN list'

# A trail this run created is authoritative: no scan, so unrelated trails cannot leak in.
$createdArn = 'arn:aws:cloudtrail:us-east-1:123456789012:trail/sailpoint-ciem-cloud-trail'
$kept = @(Get-SaasCiemCloudTrailArns -HomeRegion 'us-east-1' -BucketName 'bucket' -ExtraArn @($createdArn) -SkipDiscovery)
Assert-Equal 1 $kept.Count 'SkipDiscovery keeps only the ARNs passed in'
Assert-Equal $createdArn $kept[0] 'SkipDiscovery preserves the created trail ARN'

foreach ($ctx in @(
    @{ FeatureNames = @('Ciem'); Region = 'us-east-1'; CloudTrailBucket = 'bucket'
       CloudTrailBucketAccountId = '123456789012'; CloudTrailArn = @($createdArn); SkipCloudTrailDiscovery = $true }
    [PSCustomObject]@{ FeatureNames = @('Ciem'); Region = 'us-east-1'; CloudTrailBucket = 'bucket'
       CloudTrailBucketAccountId = '123456789012'; CloudTrailArn = @($createdArn); SkipCloudTrailDiscovery = $true }
)) {
    $settings = Build-EmbeddedCiemConnectionSettings -Context $ctx
    Assert-Equal $createdArn $settings['CloudTrail ARN(s)'] 'created trail is the only ARN in CIEM settings'
}

try {
    Get-CiemCloudTrailArns -HomeRegion 'us-east-1' -BucketOnly | Out-Null
    throw 'BucketOnly without a bucket name should fail'
}
catch {
    Assert-True ($_.Exception.Message -like '*requires -BucketName*') 'BucketOnly requires a bucket name'
}

# Discovery for CIEM settings stays scoped to the chosen bucket: ISC can only read that bucket.
$bucketTrail = 'arn:aws:cloudtrail:us-east-1:123456789012:trail/picked'
$otherTrail = 'arn:aws:cloudtrail:eu-west-1:123456789012:trail/unrelated'
Mock-CiemTrailScan -Trails @(
    [PSCustomObject]@{ TrailARN = $bucketTrail; S3BucketName = 'picked-bucket' }
    [PSCustomObject]@{ TrailARN = $otherTrail; S3BucketName = 'some-other-bucket' }
)
try {
    $scoped = @(Get-SaasCiemCloudTrailArns -HomeRegion 'us-east-1' -BucketName 'picked-bucket')
    Assert-Equal 1 $scoped.Count 'discovery keeps only trails for the chosen bucket'
    Assert-Equal $bucketTrail $scoped[0] 'unrelated trails stay out of CIEM settings'

    $options = @(Get-CloudTrailLogBucketOptions -HomeRegion 'us-east-1' -ScanScope HomeRegion)
    Assert-Equal 2 $options.Count 'discovery lists each CloudTrail log bucket'
    $picked = @($options | Where-Object { $_.BucketName -eq 'picked-bucket' })[0]
    Assert-Equal $bucketTrail (@($picked.TrailArns)[0]) 'discovered bucket keeps its trail ARN'
    $auto = Select-CloudTrailLogBucketOption -Options @($picked)
    Assert-Equal 'picked-bucket' $auto.BucketName 'a single discovered bucket is selected without a prompt'
    $many = Select-CloudTrailLogBucketOption -Options $options
    Assert-True ($null -eq $many) 'multiple buckets stay unselected so the wizard can prompt'
    $preferred = Select-CloudTrailLogBucketOption -Options $options -PreferredBucket 'picked-bucket'
    Assert-Equal 'picked-bucket' $preferred.BucketName 'an explicit bucket name matches among discovered trails'
}
finally {
    Clear-CiemTrailScanMock
}

# NewCloudTrailExistingBucket needs a bucket that exists, with or without a trail, so that mode picks
# from S3 rather than from CloudTrail.
Mock-S3BucketList -BucketNames @('zeta-logs', 'alpha-logs')
try {
    $buckets = @(Get-AwsS3BucketNames -RegionName 'us-east-1')
    Assert-Equal 2 $buckets.Count 'S3 discovery lists buckets in the account'
    Assert-Equal 'alpha-logs' $buckets[0] 'S3 bucket names are sorted for the picker'
}
finally {
    Clear-S3BucketListMock
}

$bucketPolicy = New-CloudTrailBucketPolicyDocument -BucketName 'my-bucket' -Partition 'aws'
Assert-True ($bucketPolicy -like '*my-bucket*') 'bucket policy references bucket name'

# SailPoint's existing-bucket template creates the trail but does not attach an S3 resource policy.
# CloudTrail then fails with "Incorrect S3 bucket policy is detected".
$delivery = New-CloudTrailDeliveryBucketPolicyDocument -BucketName 'sailpoint-ciem-063085096017' `
    -AccountId '063085096017' -Partition 'aws'
$deliveryDoc = $delivery | ConvertFrom-Json
$deliverySids = @($deliveryDoc.Statement | ForEach-Object { [string]$_.Sid })
Assert-True ($deliverySids -contains 'AWSCloudTrailAclCheck') 'delivery policy allows CloudTrail ACL check'
Assert-True ($deliverySids -contains 'AWSCloudTrailWrite') 'delivery policy allows CloudTrail PutObject'
Assert-True (($delivery | ConvertFrom-Json).Statement[1].Resource -eq 'arn:aws:s3:::sailpoint-ciem-063085096017/AWSLogs/063085096017/*') `
    'delivery PutObject is scoped to this account prefix'

# Get-S3BucketPolicy (AWS.Tools v5 / S3 rest-xml) can return the XML envelope instead of JSON.
# Feeding that to ConvertFrom-Json is: Unexpected character encountered while parsing value: <.
$xmlWrapped = @'
<GetBucketPolicyOutput>
  <Policy>{"Version":"2012-10-17","Statement":[{"Sid":"KeepMe","Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::other/*"}]}</Policy>
</GetBucketPolicyOutput>
'@
$fromXml = ConvertTo-NormalizedS3BucketPolicyDocument -Document $xmlWrapped
Assert-True ($fromXml.TrimStart().StartsWith('{')) 'XML-wrapped bucket policy extracts JSON'
$xmlMerged = Merge-CloudTrailDeliveryBucketPolicy -ExistingDocument $fromXml -DeliveryDocument $delivery | ConvertFrom-Json
Assert-True (@($xmlMerged.Statement | ForEach-Object { [string]$_.Sid }) -contains 'KeepMe') 'XML-wrapped existing policy still merges'

$noPolicyXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>NoSuchBucketPolicy</Code><Message>The bucket policy does not exist</Message></Error>
'@
Assert-Equal '' (ConvertTo-NormalizedS3BucketPolicyDocument -Document $noPolicyXml) 'NoSuchBucketPolicy XML is treated as no policy'

try {
    ConvertTo-NormalizedS3BucketPolicyDocument -Document '<html><body>Access Denied</body></html>' | Out-Null
    throw 'should have rejected the document'
}
catch {
    Assert-True ($_.Exception.Message -like '*HTML*not JSON*') 'HTML GetBucketPolicy body is rejected with a clear error'
}

try {
    ConvertTo-NormalizedS3BucketPolicyDocument -Document @'
<Error><Code>PermanentRedirect</Code><Message>The bucket you are attempting to access must be addressed using the specified endpoint.</Message><Endpoint>s3.eu-west-1.amazonaws.com</Endpoint></Error>
'@ | Out-Null
    throw 'should have rejected the document'
}
catch {
    Assert-True ($_.Exception.Message -like '*PermanentRedirect*') 'S3 error XML surfaces the error code'
}

Assert-Equal 'us-east-1' (ConvertTo-AwsRegionNameFromS3Location -Location $null -FallbackRegion 'eu-west-1') 'empty LocationConstraint is us-east-1'
Assert-Equal 'eu-west-1' (ConvertTo-AwsRegionNameFromS3Location -Location 'EU' -FallbackRegion 'us-east-1') 'legacy EU constraint is eu-west-1'
Assert-Equal 'eu-west-1' (ConvertTo-AwsRegionNameFromS3Location -Location 'eu-west-1' -FallbackRegion 'us-east-1') 'region-name constraint is kept'
Assert-Equal 'us-gov-west-1' (ConvertTo-AwsRegionNameFromS3Location -Location '' -FallbackRegion 'us-gov-west-1') 'empty GovCloud location keeps a gov fallback'

$existingWithOther = ConvertTo-IamJson @{
    Version   = '2012-10-17'
    Statement = @(
        @{ Sid = 'KeepMe'; Effect = 'Allow'; Principal = '*'; Action = 's3:GetObject'; Resource = 'arn:aws:s3:::other/*' }
        @{ Sid = 'AWSCloudTrailWrite'; Effect = 'Deny'; Principal = '*'; Action = 's3:PutObject'; Resource = '*' }
    )
}
$merged = Merge-CloudTrailDeliveryBucketPolicy -ExistingDocument $existingWithOther -DeliveryDocument $delivery |
    ConvertFrom-Json
$mergedSids = @($merged.Statement | ForEach-Object { [string]$_.Sid })
Assert-True ($mergedSids -contains 'KeepMe') 'merge keeps unrelated bucket-policy statements'
Assert-Equal 1 @($mergedSids | Where-Object { $_ -eq 'AWSCloudTrailWrite' }).Count 'merge replaces stale CloudTrail write statement'
Assert-True (@($merged.Statement | Where-Object { $_.Sid -eq 'AWSCloudTrailWrite' })[0].Effect -eq 'Allow') `
    'replaced CloudTrail write statement is Allow'

Assert-True (Test-CiemCfnStackNeedsDeleteBeforeRedeploy -StackStatus 'ROLLBACK_COMPLETE') 'ROLLBACK_COMPLETE needs delete'
Assert-True (-not (Test-CiemCfnStackNeedsDeleteBeforeRedeploy -StackStatus 'CREATE_COMPLETE')) 'CREATE_COMPLETE does not need delete'

$cfnLines = @(Select-CiemCfnStackFailureLines -Events @(
    [PSCustomObject]@{ LogicalResourceId = 'SailPointSaasCiemCloudTrail'; ResourceStatus = 'ROLLBACK_COMPLETE'; ResourceStatusReason = 'Validation failed with 1 error(s). Call DescribeEvents to retrieve the full list of issues with resource and property details, resolve each error, then retry the operation.' }
    [PSCustomObject]@{ LogicalResourceId = 'CloudTrailBucket'; ResourceStatus = 'CREATE_FAILED'; ResourceStatusReason = 'example-trail-bucket already exists' }
))
Assert-Equal 1 $cfnLines.Count 'generic DescribeEvents stack reason is dropped when a resource failure exists'
Assert-True ($cfnLines[0] -like '*already exists*') 'resource CREATE_FAILED reason is kept'

$deployResult = [PSCustomObject]@{
    RoleArn              = 'arn:aws:iam::123456789012:role/SailPointCIEMAuditRole'
    ExternalId           = 'ext-id'
    CloudTrailArns       = @('arn:aws:cloudtrail:us-east-1:123456789012:trail/t1')
    BucketName           = 'bucket'
    SingleAccount        = $false
    ProvisionIdentityCenter = $true
    ReadIdentityCenter   = $true
}
$dedicated = Build-DedicatedCiemConnectionSettings -DeploymentResult $deployResult -SessionAccountId '123456789012'
Assert-Equal $deployResult.RoleArn $dedicated.Fields['Role ARN'] 'dedicated settings role ARN'

Write-Host "PASS ($script:AssertionCount assertions)"
