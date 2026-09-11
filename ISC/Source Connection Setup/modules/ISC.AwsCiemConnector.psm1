#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-AwsCiemConnectorData {
$script:CiemActions = @(
    'bedrock-agentcore:GetAgentRuntime'
    'bedrock-agentcore:GetGateway'
    'bedrock-agentcore:GetGatewayTarget'
    'bedrock-agentcore:ListAgentRuntimeEndpoints'
    'bedrock-agentcore:ListAgentRuntimes'
    'bedrock-agentcore:ListAgentRuntimeVersions'
    'bedrock-agentcore:ListGateways'
    'bedrock-agentcore:ListGatewayTargets'
    'bedrock:GetAgent'
    'bedrock:GetAgentAlias'
    'bedrock:GetKnowledgeBase'
    'bedrock:ListAgentActionGroups'
    'bedrock:ListAgentAliases'
    'bedrock:ListAgentKnowledgeBases'
    'bedrock:ListAgents'
    'bedrock:ListAgentVersions'
    'cloudtrail:DescribeTrails'
    'cloudtrail:GetEventSelectors'
    'cloudtrail:GetTrailStatus'
    'cloudtrail:ListTags'
    'cloudtrail:LookupEvents'
    'cloudwatch:Describe*'
    'cloudwatch:ListTagsForResource'
    'dynamodb:DescribeGlobalTable'
    'dynamodb:DescribeTable'
    'dynamodb:DescribeTimeToLive'
    'dynamodb:ListGlobalTables'
    'dynamodb:ListStreams'
    'dynamodb:ListTables'
    'dynamodb:ListTagsOfResource'
    'ec2:Describe*'
    'ec2:GetManagedPrefixListAssociations'
    'ec2:GetManagedPrefixListEntries'
    'ec2:GetTransitGatewayAttachmentPropagations'
    'ec2:GetTransitGatewayMulticastDomainAssociations'
    'ec2:GetTransitGatewayPrefixListReferences'
    'ec2:GetTransitGatewayRouteTableAssociations'
    'ec2:GetTransitGatewayRouteTablePropagations'
    'elasticloadbalancing:Describe*'
    'iam:GenerateCredentialReport'
    'iam:GenerateServiceLastAccessedDetails'
    'iam:Get*'
    'iam:List*'
    'iam:SimulateCustomPolicy'
    'iam:SimulatePrincipalPolicy'
    'kms:Describe*'
    'kms:Get*'
    'kms:List*'
    'lambda:GetFunctionConfiguration'
    'lambda:GetFunctionEventInvokeConfig'
    'lambda:GetLayerVersionPolicy'
    'lambda:GetPolicy'
    'lambda:List*'
    'organizations:Describe*'
    'organizations:List*'
    'rds:Describe*'
    'rds:ListTagsForResource'
    's3:GetAccessPoint'
    's3:GetAccessPointPolicy'
    's3:GetAccessPointPolicyStatus'
    's3:GetAccountPublicAccessBlock'
    's3:GetAnalyticsConfiguration'
    's3:GetBucket*'
    's3:GetEncryptionConfiguration'
    's3:GetInventoryConfiguration'
    's3:GetObjectAcl'
    's3:GetObjectVersionAcl'
    's3:GetReplicationConfiguration'
    's3:ListAccessPoints'
    's3:ListAllMyBuckets'
    'sns:GetTopicAttributes'
    'sns:ListSubscriptions'
    'sns:ListSubscriptionsByTopic'
    'sns:ListTagsForResource'
    'sns:ListTopics'
    'sqs:GetQueueAttributes'
    'sqs:ListDeadLetterSourceQueues'
    'sqs:ListQueueTags'
    'sqs:ListQueues'
    'tag:GetResources'
    'tag:GetTagKeys'
)
$script:CiemIdentityCenterPolicies = [ordered]@{
    SailPointCIEMAuditICReadOnlyPolicy = @(
        'identitystore:ListUsers'
        'identitystore:ListGroupMemberships'
        'identitystore:ListGroups'
        'identitystore:GetGroupMembershipId'
        'identitystore:GetUserId'
        'sso:DescribePermissionSet'
        'sso:GetInlinePolicyForPermissionSet'
        'sso:GetPermissionsBoundaryForPermissionSet'
        'sso:ListAccountAssignments'
        'sso:ListAccountsForProvisionedPermissionSet'
        'sso:ListCustomerManagedPolicyReferencesInPermissionSet'
        'sso:ListInstances'
        'sso:ListManagedPoliciesInPermissionSet'
        'sso:ListPermissionSets'
    )
    SailPointCIEMAuditICProvisionPolicy = @(
        'identitystore:CreateGroupMembership'
        'identitystore:CreateUser'
        'identitystore:DeleteGroupMembership'
        'identitystore:DeleteUser'
        'identitystore:UpdateUser'
        'sso:CreateAccountAssignment'
        'sso:DeleteAccountAssignment'
    )
}

# Identity Center provisioning actions the documented policy requires but no SailPoint template grants,
# so both the org activity stack and the inventory-only inline path need them added separately.
# https://documentation.sailpoint.com/saas/help/ciem/aws/config/aws_permission_sets.html
$script:CiemIdentityCenterProvisionSupplementName = 'SailPointCIEMAuditICProvisionSupplementPolicy'
$script:CiemIdentityCenterProvisionSupplement = @(
    'sso:ProvisionPermissionSet'
    'iam:CreateSAMLProvider'
    'iam:GetSAMLProvider'
    'iam:UpdateSAMLProvider'
    'iam:DeleteSAMLProvider'
    'iam:PutRolePolicy'
)

    $script:EmbeddedCiemFeaturePack = @{
        Label      = 'CIEM - Enable Cloud Infrastructure Entitlement Management, inventory and effective access'
        PolicyName = 'SPCiemPolicy'
    }
}

function Get-CiemTemplateFileName {
    param(
        [Parameter(Mandatory)][string]$Purpose,
        [Parameter(Mandatory)][ValidateSet('Commercial', 'GovCloud')][string]$Cloud
    )

    $prefix = if ($Cloud -eq 'GovCloud') { 'gov' } else { 'commercial' }
    switch ($Purpose) {
        'Inventory' { return "${prefix}-inventory-collection.json" }
        'OrganizationManagement' { return "${prefix}-activity-collection.json" }
        'ExistingCloudTrail' { return "${prefix}-activity-collection-existing-cloudtrail.json" }
        'NewCloudTrailExistingBucket' { return "${prefix}-activity-collection-new-cloudtrail-and-existing-bucket.json" }
        'NewCloudTrailAndBucket' { return "${prefix}-activity-collection-new-cloudtrail-and-bucket.json" }
        default { throw "Unknown CIEM template purpose: $Purpose" }
    }
}

function Get-CiemTemplateUrl {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][ValidateSet('Commercial', 'GovCloud')][string]$Cloud
    )

    $folder = if ($Cloud -eq 'GovCloud') { 'gov_cloud' } else { 'commercial' }
    return "https://documentation.sailpoint.com/saas/help/ciem/aws/config/assets/$folder/$FileName"
}

function Get-CiemTemplateDocument {
    param(
        [Parameter(Mandatory)][string]$Purpose,
        [Parameter(Mandatory)][ValidateSet('Commercial', 'GovCloud')][string]$Cloud
    )

    $fileName = Get-CiemTemplateFileName -Purpose $Purpose -Cloud $Cloud
    $url = Get-CiemTemplateUrl -FileName $fileName -Cloud $Cloud
    Write-Info "Downloading $fileName"
    try {
        return (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        throw "Could not download SailPoint template from $url. Configure manually: https://documentation.sailpoint.com/saas/help/ciem/aws/config/config_aws_auto.html. $($_.Exception.Message)"
    }
}

function ConvertTo-CfnParameterList {
    param(
        [Parameter(Mandatory)]$TemplateObject,
        [Parameter(Mandatory)][hashtable]$Values
    )

    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($name in $TemplateObject.Parameters.PSObject.Properties.Name) {
        if (-not $Values.ContainsKey($name)) { continue }
        $value = $Values[$name]
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) { continue }
        $list.Add([PSCustomObject]@{ ParameterKey = $name; ParameterValue = [string]$value })
    }
    return @($list)
}

function Get-CiemCfnStackIfExists {
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    try {
        $stack = @(Get-CFNStack -StackName $StackName -Region $RegionName -ErrorAction Stop | Select-Object -First 1)
        if ($stack.Count -eq 0) { return $null }
        return $stack[0]
    }
    catch {
        $msg = [string]$_
        if ($msg -match 'does not exist') { return $null }
        throw
    }
}

function Test-CiemCfnStackNeedsDeleteBeforeRedeploy {
    param([string]$StackStatus)

    if ([string]::IsNullOrWhiteSpace($StackStatus)) { return $false }
    return $StackStatus -in @(
        'ROLLBACK_COMPLETE'
        'ROLLBACK_FAILED'
        'CREATE_FAILED'
        'DELETE_FAILED'
        'UPDATE_ROLLBACK_COMPLETE'
        'UPDATE_ROLLBACK_FAILED'
    )
}

function Select-CiemCfnStackFailureLines {
    param(
        [object[]]$Events,
        [int]$MaxLines = 8
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($event in @($Events)) {
        $st = [string]$event.ResourceStatus
        $reason = [string]$event.ResourceStatusReason
        if ([string]::IsNullOrWhiteSpace($reason)) { continue }
        if ($st -notmatch 'FAILED|ROLLBACK') { continue }
        $candidates.Add("$($event.LogicalResourceId) ($st): $reason")
    }
    if ($candidates.Count -eq 0) { return @('No detailed stack failure events were returned.') }

    $specific = @($candidates | Where-Object { $_ -notmatch 'Call DescribeEvents' })
    $use = if ($specific.Count -gt 0) { $specific } else { @($candidates) }
    return @($use | Select-Object -First $MaxLines)
}

function Get-CiemCfnStackFailureLines {
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    try {
        $events = @(Get-CFNStackEvent -StackName $StackName -Region $RegionName -ErrorAction Stop |
            Sort-Object -Property Timestamp)
    }
    catch {
        return @("Could not read stack events: $($_.Exception.Message)")
    }

    return @(Select-CiemCfnStackFailureLines -Events $events)
}

function Wait-CiemCfnStackDeleted {
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    $deadline = (Get-Date).AddMinutes(15)
    while ((Get-Date) -lt $deadline) {
        $stack = Get-CiemCfnStackIfExists -StackName $StackName -RegionName $RegionName
        if (-not $stack) { return }
        $status = [string]$stack.StackStatus
        if ($status -match 'DELETE_IN_PROGRESS') {
            Start-Sleep -Seconds 10
            continue
        }
        if ($status -eq 'DELETE_COMPLETE') { return }
        throw "CloudFormation stack $StackName could not be deleted (status $status)."
    }
    throw "Timed out waiting for CloudFormation stack $StackName to delete."
}

function Clear-CiemCfnStackForRedeploy {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    $stack = Get-CiemCfnStackIfExists -StackName $StackName -RegionName $RegionName
    if (-not $stack) { return }
    if (-not (Test-CiemCfnStackNeedsDeleteBeforeRedeploy -StackStatus ([string]$stack.StackStatus))) { return }

    Write-Info "Removing failed CloudFormation stack $StackName ($($stack.StackStatus)) before redeploy."
    if (-not $PSCmdlet.ShouldProcess($StackName, 'Delete failed CloudFormation stack')) { return }
    Remove-CFNStack -StackName $StackName -Region $RegionName -Force -ErrorAction Stop | Out-Null
    Wait-CiemCfnStackDeleted -StackName $StackName -RegionName $RegionName
    Write-Ok "Deleted failed stack $StackName"
}

function Wait-CiemCfnStack {
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    $deadline = (Get-Date).AddMinutes(30)
    while ((Get-Date) -lt $deadline) {
        $stack = Get-CiemCfnStackIfExists -StackName $StackName -RegionName $RegionName
        if (-not $stack) {
            Start-Sleep -Seconds 5
            continue
        }
        $status = [string]$stack.StackStatus
        if ($status -match 'IN_PROGRESS') {
            Start-Sleep -Seconds 10
            continue
        }
        if ($status -in @('CREATE_COMPLETE', 'UPDATE_COMPLETE', 'IMPORT_COMPLETE')) {
            return $stack
        }
        $detail = (Get-CiemCfnStackFailureLines -StackName $StackName -RegionName $RegionName) -join '; '
        throw "CloudFormation stack $StackName failed with status $status. $detail"
    }
    throw "Timed out waiting for CloudFormation stack $StackName"
}

function Get-CiemStackSetOperationId {
    param($Response)

    # AWS Tools for PowerShell returns the operation ID as a string (not { OperationId = ... }).
    if ($null -eq $Response) { return $null }
    if ($Response -is [string]) { return [string]$Response }
    if ($Response.PSObject.Properties.Name -contains 'OperationId' -and $Response.OperationId) {
        return [string]$Response.OperationId
    }
    return [string]$Response
}

function Wait-CiemStackSetOperation {
    param(
        [Parameter(Mandatory)][string]$StackSetName,
        [Parameter(Mandatory)][string]$OperationId,
        [Parameter(Mandatory)][string]$RegionName
    )

    $deadline = (Get-Date).AddMinutes(45)
    while ((Get-Date) -lt $deadline) {
        $op = Get-CFNStackSetOperation -StackSetName $StackSetName -OperationId $OperationId -Region $RegionName -ErrorAction Stop
        $status = [string]$op.Status
        if ($status -eq 'SUCCEEDED') { return $op }
        if ($status -in @('FAILED', 'STOPPED', 'STOPPING')) {
            throw "StackSet operation $OperationId on $StackSetName failed with status $status"
        }
        Start-Sleep -Seconds 15
    }
    throw "Timed out waiting for StackSet operation $OperationId on $StackSetName"
}

function Get-CiemStackOutputs {
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$RegionName
    )

    $stack = @(Get-CFNStack -StackName $StackName -Region $RegionName -ErrorAction Stop | Select-Object -First 1)
    if ($stack.Count -eq 0) { return @{} }
    $map = @{}
    foreach ($output in @($stack.Outputs)) {
        if ($output.OutputKey) { $map[$output.OutputKey] = [string]$output.OutputValue }
    }
    return $map
}

function Deploy-CiemCloudFormationStack {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$StackName,
        [Parameter(Mandatory)][string]$TemplateBody,
        [Parameter(Mandatory)][object[]]$Parameters,
        [Parameter(Mandatory)][string]$RegionName,
        [Parameter(Mandatory)][string]$ActionLabel
    )

    $caps = @('CAPABILITY_NAMED_IAM')
    Clear-CiemCfnStackForRedeploy -StackName $StackName -RegionName $RegionName
    $existing = Get-CiemCfnStackIfExists -StackName $StackName -RegionName $RegionName
    $canUpdate = $existing -and ([string]$existing.StackStatus -notmatch '^DELETE')

    if ($canUpdate) {
        if (-not $PSCmdlet.ShouldProcess($StackName, "Update CloudFormation stack ($ActionLabel)")) { return }
        try {
            Update-CFNStack -StackName $StackName -TemplateBody $TemplateBody -Parameter $Parameters `
                -Capabilities $caps -Region $RegionName | Out-Null
        }
        catch {
            # Re-running with identical template and parameters is a valid no-op, not a failure.
            if ([string]$_ -notmatch 'No updates are to be performed') { throw }
            Write-Ok "Stack $StackName already matches the template"
            return Get-CiemStackOutputs -StackName $StackName -RegionName $RegionName
        }
    }
    else {
        if (-not $PSCmdlet.ShouldProcess($StackName, "Create CloudFormation stack ($ActionLabel)")) { return }
        New-CFNStack -StackName $StackName -TemplateBody $TemplateBody -Parameter $Parameters `
            -Capabilities $caps -Region $RegionName -OnFailure ROLLBACK | Out-Null
    }

    Wait-CiemCfnStack -StackName $StackName -RegionName $RegionName | Out-Null
    Write-Ok "Stack $StackName is ready"
    return Get-CiemStackOutputs -StackName $StackName -RegionName $RegionName
}

function Enable-CiemStackSetOrganizationsAccess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$RegionName,
        $AwsParams
    )

    # A SERVICE_MANAGED StackSet fails with "You must enable organizations access to operate a service
    # managed stack set" until CloudFormation trusted access is active in the management account.
    $status = $null
    try { $status = [string](Get-CFNOrganizationsAccess -CallAs SELF -Region $RegionName -ErrorAction Stop) }
    catch { Write-Verbose "Could not read CloudFormation Organizations access: $($_.Exception.Message)" }

    if ($status -eq 'ENABLED') {
        Write-Ok 'CloudFormation StackSets trusted access for AWS Organizations is active'
        return $true
    }

    if (-not $PSCmdlet.ShouldProcess('AWS Organizations', 'Activate CloudFormation StackSets trusted access')) { return $false }

    try {
        Enable-CFNOrganizationsAccess -Region $RegionName -Force -ErrorAction Stop | Out-Null
        Write-Ok 'Activated CloudFormation StackSets trusted access for AWS Organizations'
        return $true
    }
    catch {
        Write-Verbose "ActivateOrganizationsAccess failed: $($_.Exception.Message)"
    }

    try {
        Enable-ORGAWSServiceAccess -ServicePrincipal 'stacksets.cloudformation.amazonaws.com' -Region $RegionName -ErrorAction Stop | Out-Null
        Write-Ok 'Enabled Organizations trusted access for stacksets.cloudformation.amazonaws.com'
        return $true
    }
    catch {
        Write-Warning "Could not enable Organizations trusted access for CloudFormation StackSets: $($_.Exception.Message)"
        Write-Warning 'Run this in the management account with Organizations admin permissions, or enable it in the CloudFormation console under StackSets > Activate trusted access.'
        return $false
    }
}

function Deploy-CiemInventoryStackSet {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$StackSetName,
        [Parameter(Mandatory)][string]$TemplateBody,
        [Parameter(Mandatory)][object[]]$Parameters,
        [Parameter(Mandatory)][string]$RegionName,
        [Parameter(Mandatory)][string]$RootOrganizationalUnitId,
        $AwsParams
    )

    $caps = @('CAPABILITY_NAMED_IAM')
    $opPrefs = @{ FailureToleranceCount = 10; MaxConcurrentCount = 10 }
    $existing = $null
    try { $existing = Get-CFNStackSet -StackSetName $StackSetName -Region $RegionName -ErrorAction Stop } catch { }

    if ($existing) {
        if (-not $PSCmdlet.ShouldProcess($StackSetName, 'Update CloudFormation StackSet (CIEM inventory)')) { return }
        try {
            $updateId = Get-CiemStackSetOperationId -Response (
                Update-CFNStackSet -StackSetName $StackSetName -TemplateBody $TemplateBody -Parameter $Parameters `
                    -Capability $caps -PermissionModel SERVICE_MANAGED `
                    -AutoDeployment_Enabled $true -AutoDeployment_RetainStacksOnAccountRemoval $true `
                    -OperationPreference $opPrefs -Region $RegionName -ErrorAction Stop
            )
            if ($updateId) {
                Wait-CiemStackSetOperation -StackSetName $StackSetName -OperationId $updateId -RegionName $RegionName | Out-Null
            }
        }
        catch {
            if ([string]$_ -notmatch 'No updates are to be performed') { throw }
            Write-Ok "StackSet $StackSetName already matches the template"
        }
    }
    else {
        if (-not $PSCmdlet.ShouldProcess($StackSetName, 'Create CloudFormation StackSet (CIEM inventory)')) { return }
        New-CFNStackSet -StackSetName $StackSetName -TemplateBody $TemplateBody -Parameter $Parameters `
            -Capability $caps -PermissionModel SERVICE_MANAGED `
            -AutoDeployment_Enabled $true -AutoDeployment_RetainStacksOnAccountRemoval $true `
            -Region $RegionName -ErrorAction Stop | Out-Null
    }

    $instances = @()
    try { $instances = @(Get-CFNStackInstanceList -StackSetName $StackSetName -Region $RegionName -ErrorAction Stop) } catch { }
    if ($instances.Count -eq 0) {
        if (-not $PSCmdlet.ShouldProcess($StackSetName, 'Create CloudFormation StackSet instances (CIEM inventory)')) { return }
        $createId = Get-CiemStackSetOperationId -Response (
            New-CFNStackInstance -StackSetName $StackSetName -StackInstanceRegion @($RegionName) `
                -DeploymentTargets_OrganizationalUnitId @($RootOrganizationalUnitId) `
                -OperationPreference $opPrefs -Region $RegionName -ErrorAction Stop
        )
        if (-not $createId) {
            throw "New-CFNStackInstance did not return an operation ID for $StackSetName"
        }
        Wait-CiemStackSetOperation -StackSetName $StackSetName -OperationId $createId -RegionName $RegionName | Out-Null
    }

    Write-Ok "StackSet $StackSetName deployed to organization accounts"
}

function Get-CiemStackInstanceStackName {
    param([Parameter(Mandatory)][string]$StackId)

    # arn:aws:cloudformation:us-east-1:123456789012:stack/StackSetName-guid/abc-def
    if ($StackId -notmatch ':stack/') { return $null }
    $afterStack = ($StackId -split ':stack/', 2)[1]
    if (-not $afterStack) { return $null }
    return ($afterStack -split '/')[0]
}

function Get-CiemStackSetRoleArn {
    param(
        [Parameter(Mandatory)][string]$StackSetName,
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$RegionName
    )

    $instances = @()
    try {
        $instances = @(
            Get-CFNStackInstanceList -StackSetName $StackSetName -Region $RegionName `
                -StackInstanceAccount $AccountId -StackInstanceRegion $RegionName -ErrorAction Stop
        )
    }
    catch {
        Write-Verbose "Could not list StackSet instances for ${StackSetName}: $($_.Exception.Message)"
        return $null
    }

    $match = @(
        $instances |
            Where-Object {
                $_.Account -eq $AccountId -and
                $_.Region -eq $RegionName -and
                $_.StackInstanceStatus -notin @('CANCELLED', 'INOPERABLE', 'FAILED')
            } |
            Select-Object -First 1
    )
    if ($match.Count -eq 0) { return $null }

    $physicalName = Get-CiemStackInstanceStackName -StackId $match.StackId
    if (-not $physicalName) { return $null }

    $outputs = Get-CiemStackOutputs -StackName $physicalName -RegionName $RegionName
    if ($outputs['SailPointCIEMRoleARN']) {
        return [string]$outputs['SailPointCIEMRoleARN']
    }
    return $null
}

function Get-CiemCloudTrailArns {
    param(
        [Parameter(Mandatory)][string]$HomeRegion,
        [string]$BucketName,
        [int]$MaxCount = 150,
        # Return only trails that log to $BucketName, instead of every trail in the account.
        [switch]$BucketOnly
    )

    if ($BucketOnly -and [string]::IsNullOrWhiteSpace($BucketName)) {
        throw 'Get-CiemCloudTrailArns -BucketOnly requires -BucketName.'
    }

    $arns = [System.Collections.Generic.List[string]]::new()
    $bucketMatches = [System.Collections.Generic.List[string]]::new()
    $regions = @($HomeRegion)

    try {
        $regions = @(
            Get-EC2Region -Region $HomeRegion -ErrorAction Stop |
                ForEach-Object { [string]$_.RegionName } |
                Sort-Object -Unique
        )
    }
    catch {
        Write-Verbose "Could not enumerate EC2 regions; scanning CloudTrail in ${HomeRegion} only."
    }

    $scopeNote = if ($BucketOnly) { " for bucket $BucketName" } else { '' }
    Write-Info "Scanning CloudTrail in $($regions.Count) region(s)$scopeNote (max $MaxCount ARN(s))"

    foreach ($region in $regions) {
        if ($arns.Count -ge $MaxCount) { break }
        try {
            foreach ($trail in @(Get-CTTrail -Region $region -ErrorAction Stop)) {
                $trailArn = [string]$trail.TrailARN
                if (-not $trailArn) { continue }

                $matchesBucket = $BucketName -and [string]$trail.S3BucketName -eq $BucketName
                if ($matchesBucket) {
                    if (-not $bucketMatches.Contains($trailArn)) { $bucketMatches.Add($trailArn) }
                }
                elseif (-not $BucketOnly -and -not $arns.Contains($trailArn)) {
                    $arns.Add($trailArn)
                }
                if (($arns.Count + $bucketMatches.Count) -ge $MaxCount) { break }
            }
        }
        catch {
            Write-Verbose "Could not list CloudTrail trails in ${region}: $($_.Exception.Message)"
        }
    }

    $ordered = [System.Collections.Generic.List[string]]::new()
    foreach ($arn in $bucketMatches) {
        if (-not $ordered.Contains($arn)) { $ordered.Add($arn) }
    }
    foreach ($arn in $arns) {
        if (-not $ordered.Contains($arn)) { $ordered.Add($arn) }
    }
    if ($ordered.Count -gt $MaxCount) {
        return @($ordered | Select-Object -First $MaxCount)
    }
    return @($ordered)
}

function Get-NormalizedCloudTrailArnList {
    param([string[]]$Value)

    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in @($Value)) {
        foreach ($part in @("$entry".Split(@(','), [System.StringSplitOptions]::RemoveEmptyEntries))) {
            $trimmed = $part.Trim()
            if ($trimmed -and -not $list.Contains($trimmed)) { $list.Add($trimmed) }
        }
    }
    return @($list)
}

function Select-CloudTrailLogBucketOption {
    param(
        [object[]]$Options,
        [string]$PreferredBucket
    )

    $list = @($Options)
    if ($list.Count -eq 0) { return $null }

    if (-not [string]::IsNullOrWhiteSpace($PreferredBucket)) {
        $match = @($list | Where-Object { $_.BucketName -eq $PreferredBucket } | Select-Object -First 1)
        if ($match.Count -eq 1) { return $match[0] }
    }

    if ($list.Count -eq 1) { return $list[0] }
    return $null
}

function Get-CloudTrailLogBucketOptions {
    param(
        [Parameter(Mandatory)][string]$HomeRegion,
        [ValidateSet('HomeRegion', 'AllRegions')]
        [string]$ScanScope = 'HomeRegion'
    )

    if (-not (Get-Command Get-CTTrail -ErrorAction SilentlyContinue)) {
        Ensure-AwsToolsModules -ExtraModules @(
            'AWS.Tools.CloudTrail'
            'AWS.Tools.EC2'
        )
    }

    $byBucket = @{}
    $regions = @($HomeRegion)
    if ($ScanScope -eq 'AllRegions') {
        try {
            $regions = @(
                Get-EC2Region -Region $HomeRegion -ErrorAction Stop |
                    ForEach-Object { [string]$_.RegionName } |
                    Sort-Object -Unique
            )
        }
        catch {
            Write-Verbose "Could not enumerate EC2 regions; scanning CloudTrail in ${HomeRegion} only."
        }
        Write-Info "Scanning CloudTrail in $($regions.Count) region(s)..."
    }
    else {
        Write-Info "Scanning CloudTrail in $HomeRegion..."
    }

    foreach ($region in $regions) {
        try {
            foreach ($trail in @(Get-CTTrail -Region $region -ErrorAction Stop)) {
                $bucketName = [string]$trail.S3BucketName
                if ([string]::IsNullOrWhiteSpace($bucketName)) { continue }

                if (-not $byBucket.ContainsKey($bucketName)) {
                    $byBucket[$bucketName] = [System.Collections.Generic.List[string]]::new()
                }
                $trailArn = [string]$trail.TrailARN
                if ($trailArn -and -not $byBucket[$bucketName].Contains($trailArn)) {
                    $byBucket[$bucketName].Add($trailArn)
                }
            }
        }
        catch {
            Write-Verbose "Could not list CloudTrail trails in ${region}: $($_.Exception.Message)"
        }
    }

    $options = [System.Collections.Generic.List[object]]::new()
    foreach ($bucketName in @($byBucket.Keys | Sort-Object)) {
        $options.Add([PSCustomObject]@{
            BucketName = $bucketName
            TrailArns  = @($byBucket[$bucketName])
        })
    }
    return @($options)
}

function Get-SaasCiemCloudTrailDeployPlan {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [Parameter(Mandatory)][string]$TrailName,
        [Parameter(Mandatory)][string]$RegionName
    )

    Ensure-AwsToolsModules -ExtraModules @(
        'AWS.Tools.S3'
        'AWS.Tools.CloudTrail'
    )

    $bucketExists = Test-AwsS3BucketExistsInAccount -BucketName $BucketName -RegionName $RegionName
    if (-not $bucketExists) {
        return [PSCustomObject]@{
            Purpose = 'NewCloudTrailAndBucket'
            Message = 'Create a new S3 bucket and CloudTrail trail.'
        }
    }

    $trailArns = @(Get-CiemCloudTrailArns -HomeRegion $RegionName -BucketName $BucketName -MaxCount 5 -BucketOnly)
    if ($trailArns.Count -gt 0) {
        return [PSCustomObject]@{
            Purpose    = 'UseExisting'
            Message    = "Reuse existing bucket $BucketName and $($trailArns.Count) CloudTrail trail(s)."
            TrailArns  = $trailArns
        }
    }

    return [PSCustomObject]@{
        Purpose = 'NewCloudTrailExistingBucket'
        Message = "Bucket $BucketName already exists; create a new CloudTrail trail in that bucket."
    }
}

function Deploy-SaasCiemCloudTrailResources {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][ValidateSet('Commercial', 'GovCloud')][string]$Cloud,
        [Parameter(Mandatory)][string]$RegionName,
        [Parameter(Mandatory)][string]$ExternalId,
        [Parameter(Mandatory)][string]$BucketName,
        [string]$TrailName = 'sailpoint-ciem-cloud-trail',
        [string]$StackName = 'SailPointSaasCiemCloudTrail',
        [string]$ActivityRoleName = 'SailPointSaasCiemTrailRole',
        $AwsParams
    )

    $bucketFailure = Test-AwsS3BucketName $BucketName
    if ($bucketFailure) { throw $bucketFailure }

    Ensure-AwsToolsModules -ExtraModules @(
        'AWS.Tools.CloudFormation'
        'AWS.Tools.CloudTrail'
        'AWS.Tools.EC2'
        'AWS.Tools.S3'
    )

    Write-Step 'Creating CloudTrail and S3 bucket for AWS SaaS CIEM'
    Write-Info 'ISC still uses your SailPointAWSRole. SailPoint CloudFormation may create an auxiliary activity role that the SaaS source does not use.'

    $deployPlan = Get-SaasCiemCloudTrailDeployPlan -BucketName $BucketName -TrailName $TrailName -RegionName $RegionName
    Write-Info $deployPlan.Message

    $cloudTrailArns = [System.Collections.Generic.List[string]]::new()
    if ($deployPlan.Purpose -eq 'UseExisting') {
        foreach ($arn in @($deployPlan.TrailArns)) {
            if ($arn -and -not $cloudTrailArns.Contains($arn)) { $cloudTrailArns.Add($arn) }
        }
        Write-Ok "Using existing CloudTrail resources in bucket $BucketName"
    }
    else {
        if ($deployPlan.Purpose -eq 'NewCloudTrailExistingBucket') {
            $partition = (Get-SailPointTrustConfig -Cloud $Cloud).Partition
            $accountId = (Get-STSCallerIdentity -Region $RegionName -ErrorAction Stop).Account
            Write-Info "Applying CloudTrail write permissions on existing bucket $BucketName (SailPoint existing-bucket template does not)."
            Set-CloudTrailDeliveryBucketPolicy -BucketName $BucketName -AccountId $accountId `
                -Partition $partition -RegionName $RegionName
        }
        $activityBody = Get-CiemTemplateDocument -Purpose $deployPlan.Purpose -Cloud $Cloud
        $activityTemplate = $activityBody | ConvertFrom-Json
        $activityValues = @{
            RoleName       = $ActivityRoleName
            ExternalId     = $ExternalId
            RolePolicyName = 'SailPointSaasCiemTrailPolicy'
            BucketName     = $BucketName
        }
        if ($activityTemplate.Parameters.PSObject.Properties.Name -contains 'TrailName') {
            $activityValues['TrailName'] = $TrailName
        }
        $activityParams = ConvertTo-CfnParameterList -TemplateObject $activityTemplate -Values $activityValues
        $outputs = Deploy-CiemCloudFormationStack -StackName $StackName -TemplateBody $activityBody `
            -Parameters $activityParams -RegionName $RegionName -ActionLabel 'SaaS CIEM CloudTrail'
        if ($outputs['SailPointCIEMCloudTrailARN']) {
            $cloudTrailArns.Add([string]$outputs['SailPointCIEMCloudTrailARN'])
        }
    }

    # The stack output already names the trail it just created. Only fall back to a scan when the
    # template returned nothing, and even then keep it to trails that log to this bucket: unrelated
    # trails elsewhere in the account are not what CIEM should read.
    if ($cloudTrailArns.Count -eq 0) {
        foreach ($discovered in @(Get-CiemCloudTrailArns -HomeRegion $RegionName -BucketName $BucketName -BucketOnly)) {
            if (-not $cloudTrailArns.Contains($discovered)) { $cloudTrailArns.Add($discovered) }
        }
    }
    Write-Ok "CIEM will read $($cloudTrailArns.Count) CloudTrail ARN(s) from bucket $BucketName"

    return [PSCustomObject]@{
        BucketName       = $BucketName
        CloudTrailArns   = @($cloudTrailArns)
        StackName        = $StackName
        ActivityRoleName = $ActivityRoleName
        DeployPurpose    = $deployPlan.Purpose
    }
}

function Get-SaasCiemCloudTrailArns {
    param(
        [Parameter(Mandatory)][string]$HomeRegion,
        [string]$BucketName,
        [string[]]$ExtraArn,
        [int]$MaxCount = 150,
        # Set when $ExtraArn is already authoritative, e.g. the trail this run just created.
        [switch]$SkipDiscovery
    )

    $cloudTrailArns = [System.Collections.Generic.List[string]]::new()
    foreach ($arn in @(Get-NormalizedCloudTrailArnList -Value $ExtraArn)) {
        $cloudTrailArns.Add($arn)
    }

    if ($SkipDiscovery) {
        Write-Ok "Using $($cloudTrailArns.Count) CloudTrail ARN(s) from this run for Enable Cloud Infrastructure Entitlement Management"
        return @($cloudTrailArns)
    }

    # SPCloudTrailBucketPolicy grants s3 read on $BucketName only, so a trail logging anywhere else
    # is unreadable by ISC. Scope the scan to this bucket rather than listing the whole account.
    $bucketScoped = -not [string]::IsNullOrWhiteSpace($BucketName)
    Write-Step 'Discovering CloudTrail ARNs for AWS SaaS CIEM settings'
    foreach ($discovered in @(Get-CiemCloudTrailArns -HomeRegion $HomeRegion -BucketName $BucketName `
            -MaxCount $MaxCount -BucketOnly:$bucketScoped)) {
        if (-not $cloudTrailArns.Contains($discovered)) { $cloudTrailArns.Add($discovered) }
    }

    if ($cloudTrailArns.Count -gt $MaxCount) {
        Write-Warning "More than $MaxCount CloudTrail ARNs were found; only the first $MaxCount are included in the output."
        return @($cloudTrailArns | Select-Object -First $MaxCount)
    }
    if ($cloudTrailArns.Count -eq 0) {
        Write-Warning "No CloudTrail trail logs into $BucketName. Paste the ARN from the CloudTrail console into ISC Additional Settings, or re-run with -CloudTrailArn."
    }
    else {
        Write-Ok "Included $($cloudTrailArns.Count) CloudTrail ARN(s) for Enable Cloud Infrastructure Entitlement Management"
    }
    return @($cloudTrailArns)
}

function Clear-CiemUnmanagedIdentityCenterPolicy {
    param(
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$RegionName,
        [string]$StackName
    )

    # CloudFormation cannot create AWS::IAM::Policy resources whose names already exist as
    # unmanaged inline policies (from an earlier Set-CiemIdentityCenterPolicy run).
    $owned = @()
    if ($StackName) {
        try {
            $owned = @(
                Get-CFNStackResourceList -StackName $StackName -Region $RegionName -ErrorAction Stop |
                    ForEach-Object { [string]$_.LogicalResourceId }
            )
        }
        catch { }
    }

    $params = Get-IamCmdletParams -RegionName $RegionName
    foreach ($policyName in $script:CiemIdentityCenterPolicies.Keys) {
        if ($owned -contains $policyName) { continue }
        try {
            Remove-IAMRolePolicy @params -RoleName $RoleName -PolicyName $policyName -Force -ErrorAction Stop
            Write-Info "Removed unmanaged $policyName from $RoleName so the activity stack can create it"
        }
        catch {
            Write-Verbose "No unmanaged $policyName on ${RoleName}: $($_.Exception.Message)"
        }
    }
}

function Set-CiemIdentityCenterPolicy {
    param(
        [Parameter(Mandatory)][string]$RoleArn,
        [Parameter(Mandatory)][string]$RegionName,
        [switch]$IncludeReadOnly,
        [switch]$IncludeProvision,
        # The org activity stack owns the two template policies; only the supplement is ours to set.
        [switch]$SupplementOnly
    )

    $roleName = ($RoleArn -split '/')[-1]
    $params = Get-IamCmdletParams -RegionName $RegionName
    $supplementName = $script:CiemIdentityCenterProvisionSupplementName
    $actions = [ordered]@{}
    $wanted = @{}
    if (-not $SupplementOnly) {
        foreach ($policyName in $script:CiemIdentityCenterPolicies.Keys) {
            $actions[$policyName] = $script:CiemIdentityCenterPolicies[$policyName]
        }
        $wanted['SailPointCIEMAuditICReadOnlyPolicy'] = [bool]$IncludeReadOnly
        $wanted['SailPointCIEMAuditICProvisionPolicy'] = [bool]$IncludeProvision
    }
    $actions[$supplementName] = $script:CiemIdentityCenterProvisionSupplement
    $wanted[$supplementName] = [bool]$IncludeProvision

    foreach ($policyName in $actions.Keys) {
        try {
            if ($wanted[$policyName]) {
                $document = New-StarPolicyDocument -Actions $actions[$policyName]
                Write-IAMRolePolicy @params -RoleName $roleName -PolicyName $policyName -PolicyDocument $document
                Write-Ok "Attached $policyName to $roleName"
            }
            else {
                Remove-IAMRolePolicy @params -RoleName $roleName -PolicyName $policyName -Force
                Write-Info "Removed $policyName from $roleName"
            }
        }
        catch {
            if ($wanted[$policyName]) {
                Write-Warning "Could not attach $policyName to ${roleName}: $($_.Exception.Message)"
            }
            else {
                Write-Verbose "No $policyName to remove from ${roleName}: $($_.Exception.Message)"
            }
        }
    }
}

function Test-CiemRoleTrust {
    param(
        [Parameter(Mandatory)][string]$RoleArn,
        [Parameter(Mandatory)][string[]]$ExpectedPrincipal,
        [Parameter(Mandatory)][string]$ExpectedExternalId,
        [Parameter(Mandatory)][string]$RegionName
    )

    $roleName = ($RoleArn -split '/')[-1]
    $params = Get-IamCmdletParams -RegionName $RegionName
    $role = Get-IAMRole @params -RoleName $roleName
    $trust = ConvertFrom-IamPolicyDocument -Document $role.AssumeRolePolicyDocument
    $statement = @($trust.Statement | Where-Object { $_.Effect -eq 'Allow' } | Select-Object -First 1)
    if (-not $statement) {
        throw "CIEM role $roleName has no Allow statement in its trust policy."
    }

    $principal = $statement.Principal.AWS
    $actualPrincipals = @()
    if ($principal -is [System.Collections.IEnumerable] -and $principal -isnot [string]) {
        $actualPrincipals = @($principal)
    }
    elseif ($principal) {
        $actualPrincipals = @([string]$principal)
    }

    foreach ($expected in $ExpectedPrincipal) {
        if ($actualPrincipals -notcontains $expected) {
            Write-Warning "CIEM role trust policy does not include principal $expected."
        }
    }

    $externalId = $statement.Condition.StringEquals.'sts:ExternalId'
    if ($externalId -ne $ExpectedExternalId) {
        throw "CIEM role trust policy ExternalId mismatch. Expected '$ExpectedExternalId', got '$externalId'."
    }

    Write-Ok "Verified CIEM role trust policy on $roleName."
}

function Sync-CiemRoleTrust {
    param(
        [Parameter(Mandatory)][string]$RoleArn,
        [Parameter(Mandatory)][string[]]$PrincipalArn,
        [Parameter(Mandatory)][string]$ExternalIdValue,
        [Parameter(Mandatory)][string]$RegionName
    )

    # The published templates trust one CIEM principal. Tenants whose connector runtime assumes from
    # another SailPoint account fail Test Connection with "Failed to get account authorization details".
    if (-not $PrincipalArn -or $PrincipalArn.Count -eq 0) { return }
    $roleName = ($RoleArn -split '/')[-1]
    $trustDoc = New-TrustPolicyDocument -PrincipalArn $PrincipalArn -ExternalIdValue $ExternalIdValue
    $params = Get-IamCmdletParams -RegionName $RegionName
    try {
        Update-IAMAssumeRolePolicy @params -RoleName $roleName -PolicyDocument $trustDoc
        Write-Ok "Trust policy on $roleName allows: $($PrincipalArn -join ', ')"
    }
    catch {
        Write-Warning "Could not update the trust policy on ${roleName}: $($_.Exception.Message)"
        Write-Warning "The role keeps the template trust (CIEM only). Add the missing principal manually if Test Connection fails."
    }
}



function New-CloudTrailBucketPolicyDocument {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [Parameter(Mandatory)][string]$Partition
    )

    $bucketArn = "arn:${Partition}:s3:::$BucketName"
    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Sid      = 'CloudTrailBucket'
                Effect   = 'Allow'
                Action   = @('s3:GetBucketLocation', 's3:ListBucket')
                Resource = $bucketArn
            }
            @{
                Sid      = 'CloudTrailObjects'
                Effect   = 'Allow'
                Action   = 's3:GetObject'
                Resource = "$bucketArn/*"
            }
        )
    }
}

function New-CloudTrailDeliveryBucketPolicyDocument {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Partition
    )

    # Same statements as SailPoint commercial-activity-collection-new-cloudtrail-and-bucket.json.
    # The existing-bucket template creates the trail but does not attach this S3 resource policy.
    $bucketArn = "arn:${Partition}:s3:::$BucketName"
    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Sid       = 'AWSCloudTrailAclCheck'
                Effect    = 'Allow'
                Principal = @{ Service = 'cloudtrail.amazonaws.com' }
                Action    = 's3:GetBucketAcl'
                Resource  = $bucketArn
            }
            @{
                Sid       = 'AWSCloudTrailWrite'
                Effect    = 'Allow'
                Principal = @{ Service = 'cloudtrail.amazonaws.com' }
                Action    = 's3:PutObject'
                Resource  = "$bucketArn/AWSLogs/$AccountId/*"
                Condition = @{
                    StringEquals = @{
                        's3:x-amz-acl' = 'bucket-owner-full-control'
                    }
                }
            }
        )
    }
}

function Merge-CloudTrailDeliveryBucketPolicy {
    param(
        [AllowEmptyString()][string]$ExistingDocument,
        [Parameter(Mandatory)][string]$DeliveryDocument
    )

    $replaceSids = @(
        'AWSCloudTrailAclCheck'
        'AWSCloudTrailWrite'
        'AWSCloudTrailAclCheck20150319'
        'AWSCloudTrailWrite20150319'
    )
    $kept = [System.Collections.Generic.List[object]]::new()
    if (-not [string]::IsNullOrWhiteSpace($ExistingDocument)) {
        $existingText = ConvertTo-NormalizedS3BucketPolicyDocument -Document $ExistingDocument
        if (-not [string]::IsNullOrWhiteSpace($existingText)) {
            $existing = ConvertFrom-IamPolicyDocument -Document $existingText
            foreach ($stmt in @($existing.Statement)) {
                if ($replaceSids -contains [string]$stmt.Sid) { continue }
                $kept.Add($stmt)
            }
        }
    }
    $delivery = $DeliveryDocument | ConvertFrom-Json
    foreach ($stmt in @($delivery.Statement)) {
        $kept.Add($stmt)
    }
    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @($kept)
    }
}

function Set-CloudTrailDeliveryBucketPolicy {
    param(
        [Parameter(Mandatory)][string]$BucketName,
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Partition,
        [Parameter(Mandatory)][string]$RegionName
    )

    Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.S3')
    $bucketRegion = Resolve-AwsS3BucketRegion -BucketName $BucketName -FallbackRegion $RegionName
    if ($bucketRegion -ne $RegionName) {
        Write-Info "Bucket $BucketName is in $bucketRegion (session region is $RegionName)."
    }
    $delivery = New-CloudTrailDeliveryBucketPolicyDocument -BucketName $BucketName `
        -AccountId $AccountId -Partition $Partition
    $existing = $null
    try {
        $existing = Get-S3BucketPolicy -BucketName $BucketName -Region $bucketRegion -Select Policy -ErrorAction Stop
    }
    catch {
        $msg = [string]$_.Exception.Message
        if ($msg -notmatch 'NoSuchBucketPolicy|does not exist|The bucket policy does not exist') {
            throw
        }
    }
    $existingText = ConvertTo-NormalizedS3BucketPolicyDocument -Document $existing
    $merged = Merge-CloudTrailDeliveryBucketPolicy -ExistingDocument $existingText -DeliveryDocument $delivery
    Write-S3BucketPolicy -BucketName $BucketName -Policy $merged -Region $bucketRegion -ErrorAction Stop
    Write-Ok "CloudTrail delivery policy applied on bucket $BucketName"
}

function Apply-DedicatedCiemSourceDeployment {
    param(
        [Parameter(Mandatory)][ValidateSet('Commercial', 'GovCloud')][string]$Cloud,
        [Parameter(Mandatory)][string]$RegionName,
        [Parameter(Mandatory)][ValidateSet('CurrentAccount', 'Organization')][string]$Scope,
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$ExternalId,
        [Parameter(Mandatory)][string]$BucketName,
        [Parameter(Mandatory)][ValidateSet('None', 'OrganizationManagement', 'ExistingCloudTrail', 'NewCloudTrailExistingBucket', 'NewCloudTrailAndBucket')][string]$ActivityMode,
        [Parameter(Mandatory)][string]$InventoryStackName,
        [Parameter(Mandatory)][string]$ActivityStackName,
        [Parameter(Mandatory)][string]$EnableIdentityStoreReadOnlyFlag,
        [Parameter(Mandatory)][string]$EnableIdentityStoreProvisionFlag,
        [Parameter(Mandatory)][string]$TrailNameValue,
        [string[]]$ExtraCloudTrailArn,
        [string[]]$TrustPrincipalList,
        $AwsParams,
        [Parameter(Mandatory)][string]$CurrentAccountId,
        [Parameter(Mandatory)][string]$ManagementAccountId,
        [switch]$IdentityCenterRequested
    )

    $trustConfig = Get-SailPointTrustConfig -Cloud $Cloud
    $partition = $trustConfig.Partition
    $defaultPrincipals = @($trustConfig.Principals)
    $principals = Resolve-TrustPrincipal -Value $(if ($TrustPrincipalList) { $TrustPrincipalList } else { $defaultPrincipals }) -Partition $partition

    $baseValues = @{
        RoleName         = $RoleName
        ExternalId       = $ExternalId
        RolePolicyName   = 'SailPointCIEMAuditPolicy'
        BucketName       = $BucketName
    }

    $roleArn = $null
    $trailFromStack = $false
    $cloudTrailArns = [System.Collections.Generic.List[string]]::new()
    foreach ($arn in @($ExtraCloudTrailArn)) {
        if ($arn -and -not $cloudTrailArns.Contains($arn)) { $cloudTrailArns.Add($arn) }
    }

    if ($Scope -eq 'Organization') {
        Write-Step 'Checking CloudFormation StackSets trusted access'
        Enable-CiemStackSetOrganizationsAccess -RegionName $RegionName -AwsParams $AwsParams | Out-Null

        Write-Step 'Deploying CIEM inventory StackSet (all organization accounts)'
        $inventoryBody = Get-CiemTemplateDocument -Purpose 'Inventory' -Cloud $Cloud
        $inventoryTemplate = $inventoryBody | ConvertFrom-Json
        $inventoryParams = ConvertTo-CfnParameterList -TemplateObject $inventoryTemplate -Values $baseValues
        $root = Get-ORGRoot @AwsParams
        try {
            Deploy-CiemInventoryStackSet -StackSetName $InventoryStackName -TemplateBody $inventoryBody `
                -Parameters $inventoryParams -RegionName $RegionName -RootOrganizationalUnitId $root.Id -AwsParams $AwsParams
        }
        catch {
            Write-Warning $_.Exception.Message
            Write-Warning 'StackSet deployment requires CloudFormation StackSets trusted access for AWS Organizations in the management account.'
            throw
        }

        if ($ActivityMode -eq 'OrganizationManagement') {
            Write-Step 'Deploying CIEM activity stack (management account)'
            Clear-CiemUnmanagedIdentityCenterPolicy -RoleName $RoleName -RegionName $RegionName -StackName $ActivityStackName
            $activityBody = Get-CiemTemplateDocument -Purpose 'OrganizationManagement' -Cloud $Cloud
            $activityTemplate = $activityBody | ConvertFrom-Json
            $activityValues = $baseValues.Clone()
            $activityValues['EnableIdentityStoreReadOnly'] = $EnableIdentityStoreReadOnlyFlag
            $activityValues['EnableIdentityStoreProvision'] = $EnableIdentityStoreProvisionFlag
            $activityParams = ConvertTo-CfnParameterList -TemplateObject $activityTemplate -Values $activityValues
            $outputs = Deploy-CiemCloudFormationStack -StackName $ActivityStackName -TemplateBody $activityBody `
                -Parameters $activityParams -RegionName $RegionName -ActionLabel 'CIEM activity'
            if ($outputs['SailPointCIEMRoleARN']) { $roleArn = $outputs['SailPointCIEMRoleARN'] }
            if ($outputs['SailPointCIEMCloudTrailARN']) {
                $cloudTrailArns.Add($outputs['SailPointCIEMCloudTrailARN'])
                $trailFromStack = $true
            }
        }
        else {
            $resolvedArn = Get-CiemStackSetRoleArn -StackSetName $InventoryStackName `
                -AccountId $ManagementAccountId -RegionName $RegionName
            if ($resolvedArn) {
                $roleArn = $resolvedArn
                Write-Ok "Role ARN from management-account StackSet instance: $roleArn"
            }
            else {
                $roleArn = "arn:${partition}:iam::${ManagementAccountId}:role/${RoleName}"
                Write-Warning "Could not read SailPointCIEMRoleARN from the StackSet instance in $ManagementAccountId; using constructed Role ARN."
            }
        }
    }
    else {
        if ($ActivityMode -eq 'None') {
            Write-Step 'Deploying CIEM inventory stack (single account)'
            $inventoryBody = Get-CiemTemplateDocument -Purpose 'Inventory' -Cloud $Cloud
            $inventoryTemplate = $inventoryBody | ConvertFrom-Json
            $inventoryParams = ConvertTo-CfnParameterList -TemplateObject $inventoryTemplate -Values $baseValues
            $outputs = Deploy-CiemCloudFormationStack -StackName $InventoryStackName -TemplateBody $inventoryBody `
                -Parameters $inventoryParams -RegionName $RegionName -ActionLabel 'CIEM inventory'
            if ($outputs['SailPointCIEMRoleARN']) { $roleArn = $outputs['SailPointCIEMRoleARN'] }
        }
        else {
            Write-Step "Deploying CIEM activity stack ($ActivityMode)"
            $activityBody = Get-CiemTemplateDocument -Purpose $ActivityMode -Cloud $Cloud
            $activityTemplate = $activityBody | ConvertFrom-Json
            $activityValues = $baseValues.Clone()
            if ($activityTemplate.Parameters.PSObject.Properties.Name -contains 'TrailName') {
                $activityValues['TrailName'] = $TrailNameValue
            }
            if ($ActivityMode -eq 'NewCloudTrailExistingBucket') {
                Write-Info "Applying CloudTrail write permissions on existing bucket $BucketName (SailPoint existing-bucket template does not)."
                Set-CloudTrailDeliveryBucketPolicy -BucketName $BucketName -AccountId $CurrentAccountId `
                    -Partition $partition -RegionName $RegionName
            }
            $activityParams = ConvertTo-CfnParameterList -TemplateObject $activityTemplate -Values $activityValues
            $outputs = Deploy-CiemCloudFormationStack -StackName $ActivityStackName -TemplateBody $activityBody `
                -Parameters $activityParams -RegionName $RegionName -ActionLabel "CIEM $ActivityMode"
            if ($outputs['SailPointCIEMRoleARN']) { $roleArn = $outputs['SailPointCIEMRoleARN'] }
            if ($outputs['SailPointCIEMCloudTrailARN']) {
                $cloudTrailArns.Add($outputs['SailPointCIEMCloudTrailARN'])
                $trailFromStack = $true
            }
        }
    }

    if (-not $roleArn) {
        $roleArn = "arn:${partition}:iam::${CurrentAccountId}:role/${RoleName}"
    }

    Write-Step 'Reconciling CIEM role trust policy'
    if ($Scope -eq 'Organization' -and -not $TrustPrincipalList) {
        Write-Info "Only the role in $CurrentAccountId is updated here; StackSet member accounts keep the template trust."
    }
    Sync-CiemRoleTrust -RoleArn $roleArn -PrincipalArn $principals -ExternalIdValue $ExternalId -RegionName $RegionName
    Test-CiemRoleTrust -RoleArn $roleArn -ExpectedPrincipal $principals -ExpectedExternalId $ExternalId -RegionName $RegionName

    # Identity Center is Organization-only. Single Account (Account instance) on the CIEM AWS source
    # cannot enable it. Only the org activity template has Identity Store parameters; other org paths
    # attach the equivalent inline policies when the operator asked for Identity Center.
    $templateAppliesIdentityCenter = ($Scope -eq 'Organization' -and $ActivityMode -eq 'OrganizationManagement')
    $icReadOnly = $false
    $icProvision = $false
    if ($Scope -eq 'Organization') {
        $icReadOnly = ($EnableIdentityStoreReadOnlyFlag -eq 'true')
        $icProvision = ($EnableIdentityStoreProvisionFlag -eq 'true')
        if ($templateAppliesIdentityCenter) {
            # The stack creates the two template policies, which are short of the documented
            # provisioning permissions, so the supplement is attached on top of them.
            Write-Step 'Applying Identity Center provisioning supplement'
            Set-CiemIdentityCenterPolicy -RoleArn $roleArn -RegionName $RegionName `
                -IncludeProvision:$icProvision -SupplementOnly
        }
        else {
            $icReadOnly = $icReadOnly -and $IdentityCenterRequested
            $icProvision = $icProvision -and $IdentityCenterRequested
            Write-Step 'Applying Identity Center permissions'
            if (-not ($icReadOnly -or $icProvision)) {
                Write-Info 'Identity Center is off for this deployment. Leave Provision Identity Center disabled on the CIEM source.'
            }
            Set-CiemIdentityCenterPolicy -RoleArn $roleArn -RegionName $RegionName `
                -IncludeReadOnly:$icReadOnly -IncludeProvision:$icProvision
        }
    }
    else {
        Write-Info 'Identity Center is off: the CIEM AWS source does not support it with Single Account (Account instance).'
        Set-CiemIdentityCenterPolicy -RoleArn $roleArn -RegionName $RegionName
    }

    # The trail the activity stack reported is the one CIEM reads. Scan only when no stack named one,
    # and keep the scan to trails logging into this bucket.
    if (-not $trailFromStack) {
        foreach ($discovered in @(Get-CiemCloudTrailArns -HomeRegion $RegionName -BucketName $BucketName -BucketOnly)) {
            if (-not $cloudTrailArns.Contains($discovered)) { $cloudTrailArns.Add($discovered) }
        }
    }
    if ($cloudTrailArns.Count -gt 150) {
        Write-Warning "More than 150 CloudTrail ARNs were found; only the first 150 are included in the output."
        $cloudTrailArns = @($cloudTrailArns | Select-Object -First 150)
    }
    if ($cloudTrailArns.Count -eq 0) {
        Write-Warning "No CloudTrail trail logs into $BucketName. Paste the ARN from the CloudTrail console into the CIEM AWS source, or re-run with -CloudTrailArn."
    }

    return [PSCustomObject]@{
        RoleArn              = $roleArn
        RoleName             = $RoleName
        ExternalId           = $ExternalId
        CloudTrailArns       = @($cloudTrailArns)
        BucketName           = $BucketName
        SingleAccount        = ($Scope -eq 'CurrentAccount')
        ProvisionIdentityCenter = $icProvision
        ReadIdentityCenter   = $icReadOnly
        InventoryStackName   = $InventoryStackName
        ActivityStackName    = if ($ActivityMode -ne 'None') { $ActivityStackName } else { '' }
    }
}


function Get-CiemPolicyActions {
    return @($script:CiemActions)
}

function Test-EmbeddedCiemSelected {
    param([string[]]$FeatureNames)
    return @($FeatureNames) -contains 'Ciem'
}

function Test-AwsSaasCiemFeature {
    param([string[]]$FeatureNames)
    return Test-EmbeddedCiemSelected -FeatureNames $FeatureNames
}

function Get-EmbeddedCiemFeaturePack {
    return $script:EmbeddedCiemFeaturePack
}

function Apply-EmbeddedCiemPrerequisites {
    param($Context)

    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) { return }
    if ([string]::IsNullOrWhiteSpace($Context.CloudTrailBucket)) {
        throw 'AwsSaas -Feature Ciem requires -CloudTrailBucket so SPCloudTrailBucketPolicy and CIEM Additional Settings can be filled.'
    }
    $bucketFailure = Test-AwsS3BucketName $Context.CloudTrailBucket
    if ($bucketFailure) { throw $bucketFailure }
    if ([string]::IsNullOrWhiteSpace($Context.CloudTrailBucketAccountId)) {
        $Context.CloudTrailBucketAccountId = $Context.SessionAccountId
    }
    $bucketAccountFailure = Test-AwsAccountId $Context.CloudTrailBucketAccountId
    if ($bucketAccountFailure) { throw $bucketAccountFailure }
    Ensure-AwsToolsModules -ExtraModules @(
        'AWS.Tools.CloudTrail'
        'AWS.Tools.EC2'
    )
}

function Get-CiemContextFlag {
    param(
        $Context,
        [Parameter(Mandatory)][string]$Name
    )

    if ($Context -is [System.Collections.IDictionary]) { return [bool]$Context[$Name] }
    if ($Context.PSObject.Properties.Name -contains $Name) { return [bool]$Context.$Name }
    return $false
}

function Build-EmbeddedCiemConnectionSettings {
    param($Context)

    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) {
        return [ordered]@{}
    }

    $skipDiscovery = Get-CiemContextFlag -Context $Context -Name 'SkipCloudTrailDiscovery'
    $saasCloudTrailArns = @(Get-SaasCiemCloudTrailArns -HomeRegion $Context.Region -BucketName $Context.CloudTrailBucket `
        -ExtraArn $Context.CloudTrailArn -SkipDiscovery:$skipDiscovery)
    $saasCloudTrailList = if ($saasCloudTrailArns.Count -gt 0) { $saasCloudTrailArns -join ', ' } else { '' }

    return [ordered]@{
        'Enable Cloud Infrastructure Entitlement Management' = 'Yes'
        'CloudTrail ARN(s)'                                  = $saasCloudTrailList
        'CloudTrail bucket account ID'                       = $Context.CloudTrailBucketAccountId
        'CloudTrail bucket'                                  = $Context.CloudTrailBucket
    }
}

function Build-DedicatedCiemConnectionSettings {
    param(
        [Parameter(Mandatory)]$DeploymentResult,
        [Parameter(Mandatory)][string]$SessionAccountId
    )

    $cloudTrailList = if ($DeploymentResult.CloudTrailArns.Count -gt 0) { $DeploymentResult.CloudTrailArns -join ', ' } else { '' }
    return [PSCustomObject]@{
        Fields         = [ordered]@{
            'Role ARN'                         = $DeploymentResult.RoleArn
            'External ID'                      = $DeploymentResult.ExternalId
            'CloudTrail ARN(s)'                = $cloudTrailList
            'CloudTrail bucket account ID'     = $SessionAccountId
            'Single Account'                   = if ($DeploymentResult.SingleAccount) { 'Yes' } else { 'No' }
            'Provision Identity Center'        = if ($DeploymentResult.ProvisionIdentityCenter) { 'Yes' } else { 'No' }
            'Identity Center read permissions' = if ($DeploymentResult.ReadIdentityCenter) { 'Yes' } else { 'No' }
            'CloudTrail bucket'                = $DeploymentResult.BucketName
        }
        CloudTrailList = $cloudTrailList
    }
}

Export-ModuleMember -Function @(
    'Initialize-AwsCiemConnectorData',
    'Test-EmbeddedCiemSelected',
    'Test-AwsSaasCiemFeature',
    'Get-EmbeddedCiemFeaturePack',
    'Apply-EmbeddedCiemPrerequisites',
    'Build-EmbeddedCiemConnectionSettings',
    'Get-NormalizedCloudTrailArnList',
    'Get-CiemCloudTrailArns',
    'Get-CloudTrailLogBucketOptions',
    'Select-CloudTrailLogBucketOption',
    'Deploy-SaasCiemCloudTrailResources',
    'Get-SaasCiemCloudTrailArns',
    'Get-CiemTemplateFileName',
    'Get-CiemTemplateUrl',
    'Get-CiemTemplateDocument',
    'ConvertTo-CfnParameterList',
    'Get-CiemCfnStackIfExists',
    'Test-CiemCfnStackNeedsDeleteBeforeRedeploy',
    'Select-CiemCfnStackFailureLines',
    'Get-CiemCfnStackFailureLines',
    'Wait-CiemCfnStackDeleted',
    'Clear-CiemCfnStackForRedeploy',
    'Wait-CiemCfnStack',
    'Get-SaasCiemCloudTrailDeployPlan',
    'Get-CiemStackSetOperationId',
    'Wait-CiemStackSetOperation',
    'Get-CiemStackOutputs',
    'Deploy-CiemCloudFormationStack',
    'Enable-CiemStackSetOrganizationsAccess',
    'Deploy-CiemInventoryStackSet',
    'Get-CiemStackInstanceStackName',
    'Get-CiemStackSetRoleArn',
    'Apply-DedicatedCiemSourceDeployment',
    'Build-DedicatedCiemConnectionSettings',
    'New-CloudTrailBucketPolicyDocument',
    'New-CloudTrailDeliveryBucketPolicyDocument',
    'Merge-CloudTrailDeliveryBucketPolicy',
    'Set-CloudTrailDeliveryBucketPolicy',
    'Sync-CiemRoleTrust',
    'Test-CiemRoleTrust',
    'Set-CiemIdentityCenterPolicy',
    'Clear-CiemUnmanagedIdentityCenterPolicy',
    'Get-CiemPolicyActions'
)
