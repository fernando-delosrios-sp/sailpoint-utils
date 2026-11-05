Set-StrictMode -Version Latest

function Get-AwsLegacyImplementationPath {
    Join-Path $PSScriptRoot '../Legacy/AWS.Implementation.ps1'
}

function Get-AwsContextFeatureNames {
    param([hashtable]$Context)
    # $null means "not specified" so the legacy script can still prompt. An empty
    # string means the operator was asked and chose no packs.
    if (-not $Context.ContainsKey('Feature') -or $null -eq $Context['Feature']) { return $null }
    $items = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in @($Context['Feature'])) {
        foreach ($part in ([string]$entry -split ',')) {
            $name = $part.Trim()
            if ($name) { $items.Add($name) }
        }
    }
    return ,$items.ToArray()
}

function Get-AwsLegacyArguments {
    param(
        [Parameter(Mandatory)][string]$SourceType,
        [Parameter(Mandatory)][hashtable]$Context
    )
    # Context is a hashtable of optional keys: use indexer access, not dot access.
    # Under Set-StrictMode -Version Latest, dot access to a missing key throws.
    $splat = @{
        SourceType      = $SourceType
        ExternalId      = if ($Context['IscExternalId']) { $Context['IscExternalId'] } else { $Context['ExternalId'] }
        ProfileName     = $Context['ProfileName']
        Region          = if ($Context['Region']) { $Context['Region'] } else { 'us-east-1' }
        RoleName        = if ($Context['RoleName']) { $Context['RoleName'] } else { 'SailPointAWSRole' }
        PolicySet       = if ($Context['PolicySet']) { $Context['PolicySet'] } else { 'Mgo' }
        Scope           = if ($Context['Scope']) { $Context['Scope'] } else { 'CurrentAccount' }
        OutputDirectory = $Context['OutputDirectory']
        NonInteractive  = [bool]$Context['NonInteractive']
    }
    # Leave Cloud unbound when the operator did not choose one. The legacy script
    # prompts for Commercial vs GovCloud, and only defaults to Commercial when
    # -NonInteractive is set. Passing Commercial here would skip that prompt.
    if ($Context['Cloud']) { $splat.Cloud = [string]$Context['Cloud'] }
    $featureNames = Get-AwsContextFeatureNames -Context $Context
    if ($null -ne $featureNames) { $splat.Feature = $featureNames }
    return $splat
}

function Invoke-AwsLegacyFromContext {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$SourceType,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $impl = Get-AwsLegacyImplementationPath
    $splat = Get-AwsLegacyArguments -SourceType $SourceType -Context $Context
    if ($Context['Access'] -eq 'ReadOnly') { $splat.AggregationOnly = $true }
    if ($Context['TrustPrincipal']) { $splat.TrustPrincipal = $Context['TrustPrincipal'] }
    if ($Context['CloudTrailBucket']) { $splat.CloudTrailBucket = $Context['CloudTrailBucket'] }
    if ($Context['MemberAssumeRole']) { $splat.MemberAssumeRole = $Context['MemberAssumeRole'] }
    if ($SourceType -eq 'CiemAws') {
        $splat.RoleName = if ($Context['RoleName']) { $Context['RoleName'] } else { 'SailPointCIEMAuditRole' }
        foreach ($k in @('InventoryStackName', 'ActivityStackName', 'CiemActivity', 'EnableIdentityStoreReadOnly', 'EnableIdentityStoreProvision', 'TrailName', 'CloudTrailArn', 'CloudTrailBucketAccountId')) {
            if ($Context[$k]) { $splat[$k] = $Context[$k] }
        }
        if ($splat['Scope'] -eq 'Organization') {
            if ($Context['Access'] -eq 'ReadOnly') {
                $splat['EnableIdentityStoreReadOnly'] = 'true'
                $splat['EnableIdentityStoreProvision'] = 'false'
            }
        }
    }
    else {
        foreach ($k in @('SaasCiemCloudTrailSetup', 'SaasCiemCloudTrailStackName', 'CloudTrailArn', 'CloudTrailBucketAccountId')) {
            if ($Context[$k]) { $splat[$k] = $Context[$k] }
        }
    }
    & $impl @splat -WhatIf:$WhatIfPreference
}

function Register-AwsConnectorDefinitions {
    $commonInputs = @(
        @{ Name = 'IscExternalId'; Source = 'Supply'; Prompt = 'ISC External ID from Connection Settings'; Purpose = 'Trust condition on the ISC IAM role'; Required = $true }
        @{ Name = 'ProfileName'; Source = 'Supply'; Prompt = 'AWS profile name (optional)'; Purpose = 'Credential profile for aws CLI'; Required = $false }
        @{ Name = 'Cloud'; Source = 'Supply'; Prompt = 'AWS cloud'; Purpose = 'Commercial or GovCloud trust principal'; Required = $false; ValidateSet = @('Commercial', 'GovCloud'); Default = 'Commercial' }
        @{ Name = 'Region'; Source = 'Supply'; Prompt = 'AWS region'; Purpose = 'Region for STS and Organizations API'; Required = $false; Default = 'us-east-1' }
        @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
    )
    Register-IntegrationWizardDefinition @{
        Id           = 'aws-saas-connector'
        Platform     = 'AWS'
        Product      = 'ISC'
        CoreSwitch   = 'SaaSConnector'
        CliName      = 'aws'
        Title        = 'Amazon Web Services SaaS connector IAM role'
        FolderName   = 'Amazon Web Services SaaS'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('IAM role and policy management in target account(s)')
        OutputsHelp  = 'Paste role name, region, External ID, and management account ID into ISC Connection Settings.'
        Inputs       = $commonInputs + @(
            @{ Name = 'RoleName'; Source = 'Discover'; Prompt = 'IAM role name'; Purpose = 'Role SailPoint assumes'; Required = $false; Default = 'SailPointAWSRole' }
            @{ Name = 'PolicySet'; Source = 'Supply'; Prompt = 'Policy set'; Purpose = 'Mgo vs NonMgo entitlement model'; Required = $false; ValidateSet = @('Mgo', 'NonMgo'); Default = 'Mgo' }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: ActivityInsights, AgentDiscovery, Ciem)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        BuildScript  = {
            param($c)
            $featureStr = if ($c['Feature']) { [string]$c['Feature'] } else { '' }
            $policySet = if ($c['PolicySet']) { [string]$c['PolicySet'] } else { 'Mgo' }
            $roleName = if ($c['RoleName']) { [string]$c['RoleName'] } else { 'SailPointAWSRole' }
            $region = if ($c['Region']) { [string]$c['Region'] } else { 'us-east-1' }
            $cloud = if ($c['Cloud']) { [string]$c['Cloud'] } else { 'Commercial' }
            $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
            $extId = if ($c['IscExternalId']) { [string]$c['IscExternalId'] } else { [string]$c['ExternalId'] }
            @"
# Ensure SailPoint.Connect module or platform runner is available
`$setupScript = Join-Path `$PSScriptRoot 'AWS.ps1'
if (-not (Test-Path -LiteralPath `$setupScript)) {
    `$mod = Get-Module -ListAvailable SailPoint.Connect | Select-Object -First 1
    if (`$mod) { `$setupScript = Join-Path (Split-Path `$mod.Path) 'AWS.ps1' }
}
if (Test-Path -LiteralPath `$setupScript) {
    & `$setupScript -SaaSConnector -Access '$access' -IscExternalId '$extId' -RoleName '$roleName' -Region '$region' -Cloud '$cloud' -PolicySet '$policySet'$(if ($featureStr) { " -Feature '$featureStr'" }) -Action Run -NonInteractive
} else {
    throw 'Could not locate AWS.ps1 or SailPoint.Connect module.'
}
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-AwsLegacyFromContext -SourceType 'AwsSaas' -Context $ctx -WhatIf:$WhatIfPreference }
    }
    Register-IntegrationWizardDefinition @{
        Id           = 'aws-ciem-connector'
        Platform     = 'AWS'
        Product      = 'ISC'
        CoreSwitch   = 'CiemConnector'
        CliName      = 'aws'
        Title        = 'AWS CIEM connector (CloudFormation)'
        FolderName   = 'AWS CIEM'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('CloudFormation in management account; StackSet for organizations')
        OutputsHelp  = 'Paste Role ARN, External ID, and CloudTrail ARNs into CIEM Connection Settings.'
        Inputs       = $commonInputs + @(
            @{ Name = 'CloudTrailBucket'; Source = 'Discover'; Prompt = 'CloudTrail S3 bucket'; Purpose = 'Required by SailPoint CIEM templates'; Required = $true }
            @{ Name = 'Scope'; Source = 'Supply'; Prompt = 'Scope'; Purpose = 'Single account or organization'; Required = $false; ValidateSet = @('CurrentAccount', 'Organization'); Default = 'CurrentAccount' }
        )
        Steps        = { param($ctx) @() }
        BuildScript  = {
            param($c)
            $cloudTrail = if ($c['CloudTrailBucket']) { [string]$c['CloudTrailBucket'] } else { '' }
            $scope = if ($c['Scope']) { [string]$c['Scope'] } else { 'CurrentAccount' }
            $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
            $extId = if ($c['IscExternalId']) { [string]$c['IscExternalId'] } else { [string]$c['ExternalId'] }
            @"
# Ensure SailPoint.Connect module or platform runner is available
`$setupScript = Join-Path `$PSScriptRoot 'AWS.ps1'
if (-not (Test-Path -LiteralPath `$setupScript)) {
    `$mod = Get-Module -ListAvailable SailPoint.Connect | Select-Object -First 1
    if (`$mod) { `$setupScript = Join-Path (Split-Path `$mod.Path) 'AWS.ps1' }
}
if (Test-Path -LiteralPath `$setupScript) {
    & `$setupScript -CiemConnector -Access '$access' -IscExternalId '$extId' -CloudTrailBucket '$cloudTrail' -Scope '$scope' -Action Run -NonInteractive
} else {
    throw 'Could not locate AWS.ps1 or SailPoint.Connect module.'
}
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-AwsLegacyFromContext -SourceType 'CiemAws' -Context $ctx -WhatIf:$WhatIfPreference }
    }
}

Export-ModuleMember -Function Register-AwsConnectorDefinitions, Invoke-AwsLegacyFromContext
