#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-AwsConnectorData {
    $script:CreatedRoleArn = $null

$script:SailPointTrust = @{
    # CIEM = documented commercial principal. ISC SaaS = connector runtime that actually
    # calls sts:AssumeRole for some tenants (not an AWS region mapping).
    Commercial = @{
        Partition  = 'aws'
        Principals = @(
            'arn:aws:iam::874540850173:role/ciem_universal'
            'arn:aws:iam::706944607044:role/ciem_universal'
        )
    }
    GovCloud = @{
        Partition  = 'aws-us-gov'
        Principals = @(
            'arn:aws-us-gov:iam::229634586956:role/ciem_universal'
        )
    }
}
}

function Get-AwsCreatedRoleArn {
    return $script:CreatedRoleArn
}

function Set-AwsCreatedRoleArn {
    param([string]$Arn)
    $script:CreatedRoleArn = $Arn
}

function Get-SailPointTrustConfig {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Commercial', 'GovCloud')]
        [string]$Cloud
    )

    return [PSCustomObject]@{
        Partition  = $script:SailPointTrust[$Cloud].Partition
        Principals = @($script:SailPointTrust[$Cloud].Principals)
    }
}

function Get-DefaultCiemRoleName {
    return 'SailPointCIEMAuditRole'
}

function Get-DefaultCiemCloudTrailBucketName {
    param([Parameter(Mandatory)][string]$AccountId)
    return "sailpoint-ciem-$AccountId"
}

function Get-DefaultSaasRoleName {
    return 'SailPointAWSRole'
}

function Get-ConnectionSettingsOutput {
    param(
        [Parameter(Mandatory)][ValidateSet('AwsSaas', 'CiemAws')][string]$Type,
        [string]$Directory
    )

    if ([string]::IsNullOrWhiteSpace($Directory)) {
        $subDir = if ($Type -eq 'CiemAws') { 'aws-ciem' } else { 'aws-isc' }
        $Directory = Join-Path (Get-Location) (Join-Path 'sourceConfig' $subDir)
    }
    $fileName = if ($Type -eq 'CiemAws') { 'sailpoint-ciem-aws-connection-settings.txt' } else { 'sailpoint-aws-connection-settings.txt' }
    return [PSCustomObject]@{
        Directory = $Directory
        FilePath  = Join-Path $Directory $fileName
        FileName  = $fileName
    }
}

function Test-AwsS3BucketName {
    param([Parameter(Mandatory)][string]$Name)

    if ($Name.Length -lt 3 -or $Name.Length -gt 63) {
        return 'S3 bucket names must be 3-63 characters (lowercase letters, numbers, dots, and hyphens; e.g. sailpoint-ciem-123456789012).'
    }
    if ($Name -cnotmatch '^[a-z0-9][a-z0-9.-]*[a-z0-9]$') {
        return 'S3 bucket names must be lowercase DNS names (no uppercase or underscores). Example: sailpoint-ciem-123456789012.'
    }
    if ($Name -match '\.\.' -or $Name -match '^\d+\.\d+\.\d+\.\d+$') {
        return 'S3 bucket names cannot contain consecutive dots or look like an IPv4 address.'
    }
    return $null
}

function Test-AwsS3BucketExistsInAccount {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [string]$RegionName = 'us-east-1'
    )

    Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.S3')
    try {
        Get-S3Bucket -BucketName $BucketName -Region $RegionName -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        $msg = [string]$_.Exception.Message
        if ($msg -match 'NotFound|NoSuchBucket|does not exist|404') { return $false }
        throw
    }
}

function Get-AwsS3BucketNames {
    param([string]$RegionName = 'us-east-1')

    if (-not (Get-Command Get-S3Bucket -ErrorAction SilentlyContinue)) {
        Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.S3')
    }
    try {
        return @(
            Get-S3Bucket -Region $RegionName -ErrorAction Stop |
                ForEach-Object { [string]$_.BucketName } |
                Where-Object { $_ } |
                Sort-Object
        )
    }
    catch {
        Write-Verbose "Could not list S3 buckets: $($_.Exception.Message)"
        return @()
    }
}

function ConvertTo-AwsRegionNameFromS3Location {
    param(
        $Location,
        [string]$FallbackRegion = 'us-east-1'
    )

    $text = ''
    if ($null -eq $Location) {
        $text = ''
    }
    elseif ($Location -is [string]) {
        $text = $Location.Trim()
    }
    elseif ($Location.PSObject.Properties['Value'] -and $null -ne $Location.Value) {
        $text = [string]$Location.Value
    }
    elseif ($Location.PSObject.Properties['LocationConstraint'] -and $null -ne $Location.LocationConstraint) {
        $constraint = $Location.LocationConstraint
        $text = if ($constraint.PSObject.Properties['Value']) { [string]$constraint.Value } else { [string]$constraint }
    }
    else {
        $text = [string]$Location
    }
    $text = $text.Trim()
    if ($text -eq 'None' -or $text -eq 'Amazon.S3.S3Region') {
        $text = ''
    }
    if ($text.StartsWith('<')) {
        try {
            $xml = [xml]$text
            $node = $xml.SelectSingleNode('//*[local-name()="LocationConstraint"]')
            if ($node) { $text = [string]$node.InnerText }
        }
        catch {
            $text = ''
        }
        $text = $text.Trim()
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        if ($FallbackRegion -match 'gov') { return $FallbackRegion }
        return 'us-east-1'
    }
    if ($text -eq 'EU') { return 'eu-west-1' }
    return $text
}

function ConvertTo-NormalizedS3BucketPolicyDocument {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        $Document
    )

    if ($null -eq $Document) { return '' }

    $text = ''
    if ($Document -is [string]) {
        $text = $Document
    }
    elseif ($Document -is [System.Xml.XmlNode]) {
        $text = $Document.OuterXml
    }
    elseif ($Document.PSObject.Properties['Policy'] -and $null -ne $Document.Policy) {
        $policy = $Document.Policy
        $text = if ($policy -is [System.Xml.XmlNode]) { $policy.InnerText } else { [string]$policy }
    }
    else {
        $text = [string]$Document
    }
    $text = $text.Trim()
    if (-not $text -or $text -eq 'Amazon.S3.Model.GetBucketPolicyResponse') { return '' }

    if ($text -match '^[\{\[]') { return $text }
    if ($text -notmatch '^[\{\[]' -and $text -match '%7[Bb]') {
        $decoded = [System.Uri]::UnescapeDataString($text).Trim()
        if ($decoded -match '^[\{\[]') { return $decoded }
        $text = $decoded
    }

    if ($text -match '(?is)^<(?:!DOCTYPE\s+html|html)\b') {
        throw 'S3 bucket policy response was HTML, not JSON. Confirm the bucket region and that Get-S3BucketPolicy is not hitting an HTTP error page.'
    }

    if ($text.StartsWith('<')) {
        $xml = $null
        try { $xml = [xml]$text } catch { $xml = $null }
        if ($null -ne $xml) {
            $codeNode = $xml.SelectSingleNode('//*[local-name()="Code"]')
            $messageNode = $xml.SelectSingleNode('//*[local-name()="Message"]')
            $code = if ($codeNode) { [string]$codeNode.InnerText } else { '' }
            $message = if ($messageNode) { [string]$messageNode.InnerText } else { '' }
            if ($code -match 'NoSuchBucketPolicy') { return '' }
            if ($code) {
                $detail = if ($message) { "${code}: $message" } else { $code }
                throw "S3 bucket policy request failed ($detail)."
            }
            $policyNode = $xml.SelectSingleNode('//*[local-name()="Policy"]')
            if ($policyNode) {
                $inner = [string]$policyNode.InnerText
                if (-not $inner) { $inner = [string]$policyNode.InnerXml }
                $inner = $inner.Trim()
                if ($inner -match '^[\{\[]') { return $inner }
            }
        }
        $start = $text.IndexOf('{')
        $end = $text.LastIndexOf('}')
        if ($start -ge 0 -and $end -gt $start) {
            return $text.Substring($start, $end - $start + 1)
        }
        throw 'S3 bucket policy response was XML, not JSON.'
    }

    return $text
}

function Resolve-AwsS3BucketRegion {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [string]$FallbackRegion = 'us-east-1'
    )

    Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.S3')
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($region in @($FallbackRegion, 'us-east-1', 'us-gov-west-1')) {
        if ([string]::IsNullOrWhiteSpace($region)) { continue }
        if (-not $candidates.Contains($region)) { $candidates.Add($region) }
    }
    $lastError = $null
    foreach ($region in $candidates) {
        try {
            $location = Get-S3BucketLocation -BucketName $BucketName -Region $region -ErrorAction Stop
            return (ConvertTo-AwsRegionNameFromS3Location -Location $location -FallbackRegion $FallbackRegion)
        }
        catch {
            $lastError = $_
        }
    }
    if ($lastError) { throw $lastError }
    return $FallbackRegion
}

function Test-AwsAccountId {
    param([string]$Value)

    if ($Value -notmatch '^\d{12}$') {
        return 'Use a 12-digit AWS account ID.'
    }
    return $null
}

function Connect-AwsSession {
    param(
        [string]$RequestedProfile,
        [string]$RequestedRegion
    )

    if ($RequestedProfile) {
        Set-AWSCredential -ProfileName $RequestedProfile
    }

    $identity = $null
    try {
        $identity = Get-STSCallerIdentity -Region $RequestedRegion -ErrorAction Stop
    }
    catch {
        throw "AWS authentication failed. Configure a profile (aws configure / aws sso login) or pass -ProfileName. $($_.Exception.Message)"
    }

    Write-Ok "Connected as $($identity.Arn)"
    Write-Ok "Account: $($identity.Account)"
    Write-Ok "Region:  $RequestedRegion"

    return [PSCustomObject]@{
        Account = $identity.Account
        Arn     = $identity.Arn
        UserId  = $identity.UserId
        Region  = $RequestedRegion
    }
}

function ConvertTo-IamJson {
    param([Parameter(Mandatory)]$Document)
    return ($Document | ConvertTo-Json -Depth 12 -Compress)
}

function ConvertFrom-IamPolicyDocument {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Document)

    # IAM returns policy documents percent-encoded, so AssumeRolePolicyDocument arrives as '%7B...'.
    $text = "$Document".Trim()
    if (-not $text) { throw 'IAM returned an empty policy document.' }
    if ($text -notmatch '^[\{\[]') {
        $text = [System.Uri]::UnescapeDataString($text)
    }
    if ($text.StartsWith('<')) {
        throw 'Policy document is XML or HTML, not JSON.'
    }
    return ($text | ConvertFrom-Json)
}

function New-StarPolicyDocument {
    param([Parameter(Mandatory)][string[]]$Actions)

    $unique = @($Actions | Sort-Object -Unique)
    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Sid      = 'SailPointIsc'
                Effect   = 'Allow'
                Action   = $unique
                Resource = '*'
            }
        )
    }
}

function Resolve-TrustPrincipal {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Value,
        [Parameter(Mandatory)][string]$Partition
    )

    $resolved = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $Value) {
        $trimmed = "$entry".Trim()
        if (-not $trimmed) { continue }

        if ($trimmed -match '^\d{12}$') {
            $resolved.Add("arn:${Partition}:iam::${trimmed}:role/ciem_universal")
        }
        elseif ($trimmed -match '^arn:[^:]+:iam::\d{12}:(role|user)/') {
            $resolved.Add($trimmed)
        }
        else {
            throw "Invalid -TrustPrincipal '$trimmed'. Use a 12-digit AWS account ID or a full IAM role ARN."
        }
    }

    return @($resolved | Select-Object -Unique)
}

function New-TrustPolicyDocument {
    param(
        [Parameter(Mandatory)][string[]]$PrincipalArn,
        [Parameter(Mandatory)][string]$ExternalIdValue,
        [switch]$AllowTagSession
    )

    # IAM stores a lone principal as a string; keep the single-principal document identical to the docs.
    $awsPrincipal = if ($PrincipalArn.Count -eq 1) { $PrincipalArn[0] } else { @($PrincipalArn) }

    # Activity Insights assumes the role with session tags, so it needs sts:TagSession as well.
    # https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/activity_insights.html
    $action = if ($AllowTagSession) { @('sts:AssumeRole', 'sts:TagSession') } else { 'sts:AssumeRole' }

    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Effect    = 'Allow'
                Principal = @{ AWS = $awsPrincipal }
                Action    = $action
                Condition = @{
                    StringEquals = @{ 'sts:ExternalId' = $ExternalIdValue }
                }
            }
        )
    }
}

function Get-OrganizationAccountIds {
    param($AwsParams)

    $ids = [System.Collections.Generic.List[string]]::new()
    $accounts = @(Get-ORGAccountList @AwsParams)
    foreach ($account in $accounts) {
        if ($account.Status -eq 'ACTIVE') { $ids.Add($account.Id) }
    }
    return @($ids)
}

function Get-AwsOrganizationContext {
    param(
        [Parameter(Mandatory)][string]$CurrentAccountId,
        $AwsParams
    )

    try {
        $org = Get-ORGOrganization @AwsParams
    }
    catch {
        return [PSCustomObject]@{
            Available       = $false
            NotInUse        = ($_.Exception.Message -match 'AWSOrganizationsNotInUse|not a member of an organization')
            MasterAccountId = $null
            IsManagement    = $false
            AccountIds      = @()
            Error           = $_.Exception.Message
        }
    }

    $ids = @()
    try {
        $ids = @(Get-OrganizationAccountIds -AwsParams $AwsParams)
    }
    catch {
        return [PSCustomObject]@{
            Available       = $true
            NotInUse        = $false
            MasterAccountId = $org.MasterAccountId
            IsManagement    = ($org.MasterAccountId -eq $CurrentAccountId)
            AccountIds      = @()
            Error           = $_.Exception.Message
        }
    }

    return [PSCustomObject]@{
        Available       = $true
        NotInUse        = $false
        MasterAccountId = $org.MasterAccountId
        IsManagement    = ($org.MasterAccountId -eq $CurrentAccountId)
        AccountIds      = $ids
        Error           = $null
    }
}

function Get-MemberCredentials {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$RoleNameToAssume,
        [Parameter(Mandatory)][string]$Partition,
        [Parameter(Mandatory)][string]$RegionName
    )

    $arn = "arn:${Partition}:iam::${AccountId}:role/${RoleNameToAssume}"
    $assumed = Use-STSRole -RoleArn $arn -RoleSessionName 'SailPointIscAwsSetup' -Region $RegionName -ErrorAction Stop
    return $assumed.Credentials
}

function Get-IamCmdletParams {
    param($Credential, [string]$RegionName)

    $params = @{ Region = $RegionName; ErrorAction = 'Stop' }
    if ($Credential) { $params.Credential = $Credential }
    return $params
}

Export-ModuleMember -Function @(
    'Initialize-AwsConnectorData',
    'Get-DefaultCiemRoleName',
    'Get-DefaultCiemCloudTrailBucketName',
    'Get-DefaultSaasRoleName',
    'Get-ConnectionSettingsOutput',
    'Test-AwsS3BucketName',
    'Test-AwsS3BucketExistsInAccount',
    'Get-AwsS3BucketNames',
    'ConvertTo-AwsRegionNameFromS3Location',
    'ConvertTo-NormalizedS3BucketPolicyDocument',
    'Resolve-AwsS3BucketRegion',
    'Test-AwsAccountId',
    'Connect-AwsSession',
    'ConvertTo-IamJson',
    'ConvertFrom-IamPolicyDocument',
    'New-StarPolicyDocument',
    'Resolve-TrustPrincipal',
    'New-TrustPolicyDocument',
    'Get-AwsOrganizationContext',
    'Get-OrganizationAccountIds',
    'Get-MemberCredentials',
    'Get-IamCmdletParams',
    'Get-AwsCreatedRoleArn',
    'Set-AwsCreatedRoleArn',
    'Get-SailPointTrustConfig'
)
