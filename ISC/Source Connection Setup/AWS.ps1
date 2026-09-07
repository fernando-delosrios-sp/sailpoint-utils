#Requires -Version 5.1
<#
.SYNOPSIS
    Creates or updates the IAM role used by the SailPoint Identity Security Cloud Amazon Web Services SaaS connector.

.DESCRIPTION
    Registers a cross-account IAM role that trusts SailPoint's ciem_universal role, attaches the documented
    aggregation / organization / provisioning policies, and optionally adds Activity Insights, CIEM,
    Bedrock agent discovery, and Identity Center packs.

    Existing roles with the same name are updated in place rather than duplicated. The same role name and
    External ID must be used in every AWS account the connector will aggregate.

    Reference:
    https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/introduction.html
    https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/manual_configuration.html
    https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/mgo_source_policies.html

.PARAMETER ProfileName
    AWS credential profile (SSO or access keys). Uses the default credential chain when omitted.

.PARAMETER Region
    AWS region for STS and Organizations API calls. IAM itself is global. Default: us-east-1.

.PARAMETER Cloud
    Commercial (default) or GovCloud. Selects the default SailPoint trust principal(s).

.PARAMETER TrustPrincipal
    Replaces the default trust principal(s) written to the role. Accepts full role ARNs or bare
    12-digit account IDs (expanded to arn:<partition>:iam::<id>:role/ciem_universal).

    Commercial defaults trust both the documented CIEM account (874540850173) and the ISC SaaS
    runtime account (706944607044). GovCloud trusts 229634586956. If AssumeRole still fails,
    take the account ID from the assumed-role ARN in that error and pass it here (include the
    defaults you still need).

.PARAMETER RoleName
    IAM role name entered in the ISC source. Default: SailPointAWSRole.

.PARAMETER ExternalId
    External ID copied from the ISC AWS SaaS source Connection Settings. Required.

.PARAMETER PolicySet
    Mgo    - multiple group object policies (default; recommended).
    NonMgo - single entitlement type (IAM groups only).

.PARAMETER Feature
    Optional documented feature packs: ActivityInsights, Ciem, AgentDiscovery, IdentityCenter,
    IdentityCenterProvisioning.

.PARAMETER AggregationOnly
    Skip SPProvisioningPolicy (and Identity Center provisioning even if that feature is selected).

.PARAMETER CloudTrailBucket
    Existing CloudTrail log bucket. Adds s3:GetBucketLocation, s3:ListBucket, and s3:GetObject.

.PARAMETER Scope
    CurrentAccount (default) or Organization. Organization lists member accounts and creates the same
    role in each when -MemberAssumeRole is set.

.PARAMETER MemberAssumeRole
    Existing role in member accounts that this identity can assume (for example OrganizationAccountAccessRole).
    Required for -Scope Organization beyond the management account.

.PARAMETER OutputDirectory
    Directory for the Connection Settings file. Default: ./sourceConfig/aws-isc

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\AWS.ps1

.EXAMPLE
    .\AWS.ps1 -ExternalId '11111111-2222-3333-4444-555555555555' -Feature ActivityInsights,Ciem -NonInteractive

.NOTES
    Sign in as an account that can create IAM roles and policies. For organization-wide setup, the caller
    also needs organizations:ListAccounts and permission to assume the member administration role.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$ProfileName,

    [Parameter()]
    [string]$Region = 'us-east-1',

    [Parameter()]
    [ValidateSet('Commercial', 'GovCloud')]
    [string]$Cloud = 'Commercial',

    [Parameter()]
    [string[]]$TrustPrincipal,

    [Parameter()]
    [string]$RoleName = 'SailPointAWSRole',

    [Parameter()]
    [string]$ExternalId,

    [Parameter()]
    [ValidateSet('Mgo', 'NonMgo')]
    [string]$PolicySet = 'Mgo',

    [Parameter()]
    [ValidateSet('ActivityInsights', 'Ciem', 'AgentDiscovery', 'IdentityCenter', 'IdentityCenterProvisioning')]
    [string[]]$Feature,

    [Parameter()]
    [switch]$AggregationOnly,

    [Parameter()]
    [string]$CloudTrailBucket,

    [Parameter()]
    [ValidateSet('CurrentAccount', 'Organization')]
    [string]$Scope = 'CurrentAccount',

    [Parameter()]
    [string]$MemberAssumeRole,

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

# -----------------------------------------------------------------------------
# IAM actions - SailPoint AWS SaaS connector policy tables
# -----------------------------------------------------------------------------

$script:AggregationActions = @(
    'iam:GetPolicyVersion'
    'iam:ListServiceSpecificCredentials'
    'iam:ListMFADevices'
    'iam:ListSigningCertificates'
    'iam:GetGroup'
    'iam:ListSSHPublicKeys'
    'iam:ListAttachedRolePolicies'
    'iam:ListAttachedUserPolicies'
    'iam:ListAttachedGroupPolicies'
    'iam:ListRolePolicies'
    'iam:ListAccessKeys'
    'iam:ListPolicies'
    'iam:GetRole'
    'iam:GetPolicy'
    'iam:ListGroupPolicies'
    'iam:ListRoles'
    'iam:ListUserPolicies'
    'iam:GetUserPolicy'
    'iam:ListGroupsForUser'
    'iam:ListAccountAliases'
    'iam:ListUsers'
    'iam:ListGroups'
    'iam:GetGroupPolicy'
    'iam:GetUser'
    'iam:GetRolePolicy'
    'iam:GetLoginProfile'
    'iam:ListEntitiesForPolicy'
    'iam:GetAccessKeyLastUsed'
    'iam:ListUserTags'
    'iam:ListRoleTags'
    'iam:ListPolicyTags'
)

$script:OrganizationActionsNonMgo = @(
    'organizations:ListAccounts'
)

$script:OrganizationActionsMgo = @(
    'organizations:ListPoliciesForTarget'
    'organizations:ListAccountsForParent'
    'organizations:ListRoots'
    'organizations:ListAccounts'
    'organizations:ListTargetsForPolicy'
    'organizations:DescribeOrganization'
    'organizations:DescribeOrganizationalUnit'
    'organizations:DescribeAccount'
    'organizations:ListParents'
    'organizations:ListOrganizationalUnitsForParent'
    'organizations:DescribePolicy'
    'organizations:ListPolicies'
    'organizations:ListTagsForResource'
)

$script:ProvisioningActionsNonMgo = @(
    'iam:UpdateLoginProfile'
    'iam:UpdateAccessKey'
    'iam:CreateUser'
    'iam:CreateAccessKey'
    'iam:CreateLoginProfile'
    'iam:RemoveUserFromGroup'
    'iam:AddUserToGroup'
    'iam:DeleteLoginProfile'
    'iam:AttachUserPolicy'
)

$script:ProvisioningActionsMgo = @(
    'iam:UpdateLoginProfile'
    'iam:CreateGroup'
    'iam:DeleteAccessKey'
    'iam:DeleteGroup'
    'iam:AttachUserPolicy'
    'iam:DeleteUserPolicy'
    'iam:UpdateAccessKey'
    'iam:AttachRolePolicy'
    'iam:DeleteUser'
    'iam:CreateUser'
    'iam:CreateAccessKey'
    'iam:CreatePolicy'
    'iam:CreateLoginProfile'
    'iam:RemoveUserFromGroup'
    'iam:AddUserToGroup'
    'iam:DetachRolePolicy'
    'iam:DeleteSigningCertificate'
    'iam:AttachGroupPolicy'
    'iam:DeleteRolePolicy'
    'iam:DetachGroupPolicy'
    'iam:DetachUserPolicy'
    'iam:DeleteGroupPolicy'
    'iam:DeleteLoginProfile'
)

$script:ActivityInsightsActions = @(
    'cloudtrail:Get*'
    'cloudtrail:Describe*'
    'cloudtrail:List*'
    'cloudtrail:LookupEvents'
)

$script:AgentDiscoveryActions = @(
    'bedrock:ListAgents'
    'bedrock:GetAgent'
    'bedrock:ListAgentActionGroups'
    'bedrock:GetAgentActionGroup'
    'bedrock:ListAgentKnowledgeBases'
    'bedrock:GetAgentKnowledgeBase'
    'bedrock:ListKnowledgeBases'
    'bedrock:GetKnowledgeBase'
    'bedrock:ListAgentAliases'
    'bedrock:GetAgentAlias'
    'bedrock:ListAgentVersions'
    'bedrock:GetAgentVersion'
    'bedrock:ListDataSources'
    'bedrock:GetDataSource'
    'bedrock:ListAgentCollaborators'
    'bedrock:GetAgentCollaborator'
    'kms:Decrypt'
    'kms:GenerateDataKey'
    'bedrock-agentcore:ListAgentRuntimes'
    'bedrock-agentcore:GetAgentRuntime'
    'bedrock-agentcore:ListAgentRuntimeEndpoints'
    'bedrock-agentcore:GetAgentRuntimeEndpoint'
    'bedrock-agentcore:ListAgentRuntimeVersions'
    'bedrock-agentcore:ListWorkloadIdentities'
    'bedrock-agentcore:GetWorkloadIdentity'
    'bedrock-agentcore:ListOauth2CredentialProviders'
    'bedrock-agentcore:GetApiKeyCredentialProvider'
    'bedrock-agentcore:ListApiKeyCredentialProviders'
    'bedrock-agentcore:GetOauth2CredentialProvider'
)

# SailPoint CIEM minimum read permissions (commercial / GovCloud), excluding Identity Center.
# https://documentation.sailpoint.com/saas/help/ciem/aws/config/aws_minimum_permissions.html
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
    'config:BatchGetAggregateResourceConfig'
    'config:BatchGetResourceConfig'
    'config:Deliver*'
    'config:Describe*'
    'config:Get*'
    'config:List*'
    'dynamodb:DescribeContinuousBackups'
    'dynamodb:DescribeGlobalTable'
    'dynamodb:DescribeTable'
    'dynamodb:DescribeTimeToLive'
    'dynamodb:ListBackups'
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
    'es:Describe*'
    'es:ListDomainNames'
    'es:ListElasticsearchInstanceTypeDetails'
    'es:ListElasticsearchVersions'
    'es:ListTags'
    'events:Describe*'
    'events:List*'
    'events:TestEventPattern'
    'iam:GenerateCredentialReport'
    'iam:GenerateServiceLastAccessedDetails'
    'iam:Get*'
    'iam:List*'
    'iam:SimulateCustomPolicy'
    'iam:SimulatePrincipalPolicy'
    'kms:Describe*'
    'kms:Get*'
    'kms:List*'
    'lambda:GetAccountSettings'
    'lambda:GetFunctionConfiguration'
    'lambda:GetFunctionEventInvokeConfig'
    'lambda:GetLayerVersionPolicy'
    'lambda:GetPolicy'
    'lambda:List*'
    'logs:Describe*'
    'logs:ListTagsLogGroup'
    'organizations:Describe*'
    'organizations:List*'
    'rds:Describe*'
    'rds:DownloadDBLogFilePortion'
    'rds:ListTagsForResource'
    's3:GetAccelerateConfiguration'
    's3:GetAccessPoint'
    's3:GetAccessPointPolicy'
    's3:GetAccessPointPolicyStatus'
    's3:GetAccountPublicAccessBlock'
    's3:GetAnalyticsConfiguration'
    's3:GetBucket*'
    's3:GetEncryptionConfiguration'
    's3:GetInventoryConfiguration'
    's3:GetLifecycleConfiguration'
    's3:GetMetricsConfiguration'
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

$script:IdentityCenterReadActions = @(
    'identitystore:ListUsers'
    'identitystore:ListGroupMemberships'
    'identitystore:ListGroups'
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

$script:IdentityCenterProvisioningActions = @(
    'identitystore:GetGroupMembershipId'
    'identitystore:GetUserId'
    'identitystore:CreateGroupMembership'
    'identitystore:CreateUser'
    'identitystore:DeleteGroupMembership'
    'identitystore:DeleteUser'
    'identitystore:UpdateUser'
    'sso:CreateAccountAssignment'
    'sso:DeleteAccountAssignment'
    'sso:ProvisionPermissionSet'
    'iam:CreateSAMLProvider'
    'iam:GetSAMLProvider'
    'iam:UpdateSAMLProvider'
    'iam:DeleteSAMLProvider'
    'iam:PutRolePolicy'
)

$script:FeaturePacks = [ordered]@{
    ActivityInsights = @{
        Label       = 'Activity Insights - CloudTrail event lookup'
        PolicyName  = 'SPActivityInsightsPolicy'
        Actions     = $script:ActivityInsightsActions
    }
    Ciem = @{
        Label       = 'CIEM - cloud resource inventory and effective access'
        PolicyName  = 'SPCiemPolicy'
        Actions     = $script:CiemActions
    }
    AgentDiscovery = @{
        Label       = 'Machine identity - Bedrock and AgentCore discovery'
        PolicyName  = 'SPAgentDiscoveryPolicy'
        Actions     = $script:AgentDiscoveryActions
    }
    IdentityCenter = @{
        Label       = 'IAM Identity Center - read permission sets and assignments'
        PolicyName  = 'SPIdentityCenterPolicy'
        Actions     = $script:IdentityCenterReadActions
    }
    IdentityCenterProvisioning = @{
        Label       = 'IAM Identity Center - provision users and account assignments'
        PolicyName  = 'SPIdentityCenterProvisioningPolicy'
        Actions     = $script:IdentityCenterProvisioningActions
    }
}

$script:ManagedPolicyNames = @(
    'SPAggregationPolicy'
    'SPOrganizationPolicy'
    'SPProvisioningPolicy'
    'SPActivityInsightsPolicy'
    'SPCiemPolicy'
    'SPAgentDiscoveryPolicy'
    'SPIdentityCenterPolicy'
    'SPIdentityCenterProvisioningPolicy'
    'SPCloudTrailBucketPolicy'
)

# -----------------------------------------------------------------------------
# Console helpers (same interaction model as Entra ID.ps1)
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Amazon Web Services SaaS source connection setup' -ForegroundColor Cyan
    Write-Host '  Creates or updates the IAM role used by the AWS SaaS connector.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor DarkGray
}

function Write-ConnectionSettings {
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Fields,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Path
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $Fields.Keys) {
        $lines.Add("### $name")
        $lines.Add([string]$Fields[$name])
        $lines.Add('')
    }
    Set-Content -LiteralPath $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Ok "Saved $Title to $Path"
}

$script:Esc = [char]27
$script:AnsiEraseLine = "$([char]27)[K"
$script:PromptBackToken = 'PROMPT_BACK'
$script:MenuFallbackReported = $false
$script:MenuBlockerDetail = 'the console window is too short'

# Prompts answered so far. A wizard step compares this before and after its block to tell a step
# that asked the operator something from one that resolved on its own.
$script:PromptCount = 0

$script:WizardCursor = 0
$script:WizardResume = 0
$script:WizardStep = -1
$script:WizardStepPromptCount = 0
$script:WizardAskedSteps = @{}
$script:InWizardPrompt = $false

function Test-PromptBack {
    param($ErrorRecord)
    return [string]$ErrorRecord.Exception.Message -eq $script:PromptBackToken
}

function Invoke-PromptBack {
    throw $script:PromptBackToken
}

function Invoke-PromptExit {
    Write-Host ''
    Write-Host 'Cancelled.' -ForegroundColor Yellow
    exit 0
}

# The wizard body is replayed from the top after every Esc, so each pass starts at step 0 and the
# steps before the resume point reuse the answers already given.
function Start-WizardPass {
    $script:WizardCursor = 0
    $script:InWizardPrompt = $false
}

function Enter-WizardPrompt {
    $step = $script:WizardCursor
    $script:WizardCursor++
    if ($step -lt $script:WizardResume) { return $false }
    $script:WizardStep = $step
    $script:WizardStepPromptCount = $script:PromptCount
    $script:InWizardPrompt = $true
    return $true
}

function Complete-WizardPrompt {
    if (-not $script:InWizardPrompt) { return }
    $script:InWizardPrompt = $false
    if ($script:PromptCount -gt $script:WizardStepPromptCount) {
        $script:WizardAskedSteps[$script:WizardStep] = $true
    }
    $script:WizardResume = $script:WizardCursor
}

# Esc resumes at the closest earlier step that actually asked something; steps that ran
# automatically are not return points. Returns $false when nothing was asked before this one.
function Move-WizardBack {
    # Esc on a prompt goes to the previous asked step. Esc between prompts (for example while
    # reconnecting) goes back to the last asked step, which may be the one just completed.
    $before = if ($script:InWizardPrompt) { $script:WizardStep } else { $script:WizardStep + 1 }
    $target = -1
    foreach ($step in $script:WizardAskedSteps.Keys) {
        if ($step -lt $before -and $step -gt $target) { $target = $step }
    }
    if ($target -lt 0) { return $false }

    # Everything after the target is asked again on the way forward, so let the record rebuild
    # instead of keeping steps that may no longer prompt.
    foreach ($step in @($script:WizardAskedSteps.Keys)) {
        if ($step -gt $target) { $script:WizardAskedSteps.Remove($step) }
    }
    $script:WizardResume = $target
    return $true
}

function Test-CancelledNavigation {
    param($ErrorRecord)
    if (Test-PromptBack $ErrorRecord) { return $true }
    return $ErrorRecord.Exception -is [System.Management.Automation.PipelineStoppedException]
}

function Get-ConsoleMenuBlocker {
    if ($NonInteractive) { return 'non-interactive mode' }
    if ($Host.Name -eq 'Windows PowerShell ISE Host') { return 'the ISE cannot read single keystrokes' }

    if ($Host.Name -eq 'ConsoleHost') {
        try { $null = [Console]::KeyAvailable }
        catch { return 'this console cannot read single keystrokes' }
        try { if ([Console]::IsOutputRedirected) { return 'console output is redirected' } } catch { }
    }

    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -ne 'Unix') {
        $vt = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
        if ($vt -and -not $vt.Value) { return 'this console does not support virtual terminal sequences' }
    }

    return $null
}

function Read-MenuKey {
    $info = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $code = [int]$info.VirtualKeyCode
    $character = $info.Character
    $ctrl = $false
    try { $ctrl = ([int]$info.ControlKeyState -band 0x0C) -ne 0 } catch { }

    if ([int][char]$character -eq 3 -or $code -eq 3 -or ($ctrl -and $code -eq 67)) {
        return [PSCustomObject]@{ Name = 'CtrlC'; Char = [char]0; Character = $character }
    }

    $name = switch ($code) {
        8       { 'Backspace' }
        38      { 'Up' }
        40      { 'Down' }
        36      { 'Home' }
        35      { 'End' }
        32      { 'Space' }
        13      { 'Enter' }
        27      { 'Escape' }
        default { 'Other' }
    }
    return [PSCustomObject]@{
        Name      = $name
        Char      = [char]::ToLowerInvariant($character)
        Character = $character
    }
}

function Write-MenuFallbackNotice {
    param([string]$Reason)

    if ($NonInteractive -or -not $Reason -or $script:MenuFallbackReported) { return }
    $script:MenuFallbackReported = $true
    Write-Info "Arrow-key menus are unavailable here ($Reason); using numbered prompts."
}

function Get-MenuWindowSize {
    try { return @{ Width = [Console]::WindowWidth; Height = [Console]::WindowHeight } } catch { }
    try {
        $size = $Host.UI.RawUI.WindowSize
        return @{ Width = $size.Width; Height = $size.Height }
    }
    catch { }
    return @{ Width = 0; Height = 0 }
}

function Get-MenuWidth {
    $width = (Get-MenuWindowSize).Width
    if ($width -le 20) { return 80 }
    return $width - 1
}

function Invoke-ConsoleMenu {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Labels,
        [switch]$MultiSelect,
        [switch]$EscapeMeansDefault,
        [int]$InitialIndex = 0
    )

    $count = $Labels.Count
    if ($count -eq 0) { return , @() }

    $selected = New-Object 'bool[]' $count
    $cursor = [Math]::Min([Math]::Max($InitialIndex, 0), $count - 1)
    $hint = if ($MultiSelect) {
        'Up/Down move   Space select   A all   N none   Enter confirm   Esc back   Ctrl+C exit'
    }
    elseif ($EscapeMeansDefault) {
        'Up/Down move   Enter select   Esc done   Ctrl+C exit'
    }
    else {
        'Up/Down move   Enter select   Esc back   Ctrl+C exit'
    }

    $rows = $count + 2
    $windowHeight = (Get-MenuWindowSize).Height
    if ($windowHeight -gt 0 -and $windowHeight -le $rows) {
        $script:MenuBlockerDetail = "the console is $windowHeight rows tall and this menu needs $($rows + 1)"
        return $null
    }

    $drawn = $false
    $draw = {
        $width = Get-MenuWidth
        if ($drawn) { Write-Host ("{0}[{1}A" -f $script:Esc, $rows) -NoNewline }
        $drawn = $true

        $lines = @(, @($Prompt, [System.ConsoleColor]::White))
        $lines += , @("   $hint", [System.ConsoleColor]::DarkGray)
        for ($i = 0; $i -lt $count; $i++) {
            $marker = if ($i -eq $cursor) { '>' } else { ' ' }
            $box = if ($MultiSelect) { if ($selected[$i]) { '[x] ' } else { '[ ] ' } } else { '' }
            $color = if ($i -eq $cursor) { [System.ConsoleColor]::Cyan }
                elseif ($MultiSelect -and $selected[$i]) { [System.ConsoleColor]::Green }
                else { [System.ConsoleColor]::Gray }
            $lines += , @(("  {0} {1}{2}" -f $marker, $box, $Labels[$i]), $color)
        }

        foreach ($line in $lines) {
            $text = $line[0]
            if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
            Write-Host ($text + $script:AnsiEraseLine) -ForegroundColor $line[1]
        }
    }

    try {
        try { [Console]::CursorVisible = $false } catch { }

        while ($true) {
            . $draw

            try { $key = Read-MenuKey }
            catch {
                $script:MenuBlockerDetail = 'this host cannot read single keystrokes'
                return $null
            }

            if ($key.Name -eq 'CtrlC') { Invoke-PromptExit }

            if ($key.Name -eq 'Up' -or $key.Char -eq 'k') {
                $cursor = ($cursor - 1 + $count) % $count
            }
            elseif ($key.Name -eq 'Down' -or $key.Char -eq 'j') {
                $cursor = ($cursor + 1) % $count
            }
            elseif ($key.Name -eq 'Home') {
                $cursor = 0
            }
            elseif ($key.Name -eq 'End') {
                $cursor = $count - 1
            }
            elseif ($key.Name -eq 'Space') {
                if ($MultiSelect) { $selected[$cursor] = -not $selected[$cursor] } else { return , @($cursor) }
            }
            elseif ($key.Name -eq 'Enter') {
                if (-not $MultiSelect) { return , @($cursor) }
                return , @(for ($i = 0; $i -lt $count; $i++) { if ($selected[$i]) { $i } })
            }
            elseif ($key.Name -eq 'Escape') {
                if ($EscapeMeansDefault) { return , @() }
                Invoke-PromptBack
            }
            elseif ($MultiSelect -and $key.Char -eq 'a') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $true }
            }
            elseif ($MultiSelect -and $key.Char -eq 'n') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $false }
            }
        }
    }
    finally {
        try { . $draw } catch { }
        try { [Console]::CursorVisible = $true } catch { }
    }
}

function Read-TypedLine {
    param([string]$PromptText)

    if (Get-ConsoleMenuBlocker) {
        return Read-Host $PromptText
    }

    Write-Host "${PromptText}: " -NoNewline
    $buffer = [System.Text.StringBuilder]::new()
    while ($true) {
        try { $key = Read-MenuKey }
        catch {
            Write-Host ''
            return Read-Host $PromptText
        }

        switch ($key.Name) {
            'CtrlC' { Invoke-PromptExit }
            'Escape' {
                Write-Host ''
                Invoke-PromptBack
            }
            'Enter' {
                Write-Host ''
                return $buffer.ToString()
            }
            'Backspace' {
                if ($buffer.Length -gt 0) {
                    $null = $buffer.Remove($buffer.Length - 1, 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            default {
                $ch = $key.Character
                if ($ch -and [int][char]$ch -ge 32) {
                    $null = $buffer.Append($ch)
                    Write-Host $ch -NoNewline
                }
            }
        }
    }
}

function Read-InputString {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [switch]$Required,
        [scriptblock]$Validate
    )

    if ($NonInteractive) {
        if ($Required -and [string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a value for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
    $suffix = if ($Default) { " [$Default]" } else { '' }
    while ($true) {
        $value = Read-TypedLine "$Prompt$suffix"
        if ([string]::IsNullOrWhiteSpace($value)) { $value = $Default }
        $value = if ($null -eq $value) { '' } else { $value.Trim() }

        if ($Required -and [string]::IsNullOrWhiteSpace($value)) {
            Write-Host '   A value is required.' -ForegroundColor Yellow
            continue
        }
        if ($Validate -and -not [string]::IsNullOrWhiteSpace($value)) {
            $failure = & $Validate $value
            if ($failure) {
                Write-Host "   $failure" -ForegroundColor Yellow
                continue
            }
        }
        return $value
    }
}

function Read-Choice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels,
        [string]$Default,
        [switch]$EscapeMeansDefault
    )

    if (-not $Labels) { $Labels = $Options }
    if ($NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a choice for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
    $defaultIndex = if ($Default) { [array]::IndexOf($Options, $Default) } else { 0 }
    if ($defaultIndex -lt 0) { $defaultIndex = 0 }

    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $menuLabels = @(
            for ($i = 0; $i -lt $Options.Count; $i++) {
                if ($Options[$i] -eq $Default) { "$($Labels[$i])  (default)" } else { $Labels[$i] }
            }
        )
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $menuLabels -InitialIndex $defaultIndex `
            -EscapeMeansDefault:$EscapeMeansDefault
        if ($null -ne $picked) {
            if (@($picked).Count -gt 0) { return $Options[@($picked)[0]] }
            return $Options[$defaultIndex]
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $marker = if ($Options[$i] -eq $Default) { '*' } else { ' ' }
        Write-Host ("  {0} {1}) {2}" -f $marker, ($i + 1), $Labels[$i])
    }

    $defaultNumber = if ($Default) { $defaultIndex + 1 } else { 0 }
    while ($true) {
        $label = if ($EscapeMeansDefault) {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber]" } else { "Select 1-$($Options.Count)" }
        }
        else {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber], or b to go back" } else { "Select 1-$($Options.Count), or b to go back" }
        }
        $raw = Read-Host $label
        if (-not $EscapeMeansDefault -and $raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw) -and $defaultNumber -gt 0) {
            return $Options[$defaultNumber - 1]
        }
        $n = 0
        if ([int]::TryParse($raw, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
            return $Options[$n - 1]
        }
        Write-Host '   Enter a number from the list.' -ForegroundColor Yellow
    }
}

function Read-MultiChoice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels
    )

    if (-not $Labels) { $Labels = $Options }
    if ($NonInteractive) { return @() }

    $script:PromptCount++
    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $Labels -MultiSelect
        if ($null -ne $picked) {
            return @(@($picked) | ForEach-Object { $Options[$_] })
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("    {0}) {1}" -f ($i + 1), $Labels[$i])
    }

    while ($true) {
        $raw = Read-Host "Select numbers separated by commas, Enter for none, or b to go back"
        if ($raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

        $selected = [System.Collections.Generic.List[string]]::new()
        $valid = $true
        foreach ($token in ($raw -split ',')) {
            $n = 0
            if ([int]::TryParse($token.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
                if (-not $selected.Contains($Options[$n - 1])) { $selected.Add($Options[$n - 1]) }
            }
            else {
                $valid = $false
                break
            }
        }
        if ($valid) { return $selected.ToArray() }
        Write-Host '   Enter numbers from the list, separated by commas.' -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [bool]$Default = $true
    )

    if ($NonInteractive) { return $Default }

    $defaultOption = if ($Default) { 'Yes' } else { 'No' }
    return (Read-Choice -Prompt $Prompt -Options @('Yes', 'No') -Default $defaultOption) -eq 'Yes'
}

function Copy-ToClipboard {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $setClipboard = Get-Command Set-Clipboard -ErrorAction SilentlyContinue
    if ($setClipboard) {
        try {
            Set-Clipboard -Value $Text -ErrorAction Stop
            return $true
        }
        catch { }
    }

    foreach ($tool in @('pbcopy', 'wl-copy', 'xclip')) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        try {
            $toolArgs = if ($tool -eq 'xclip') { @('-selection', 'clipboard') } else { @() }
            $Text | & $cmd.Source @toolArgs
            return $true
        }
        catch { }
    }

    return $false
}

function Open-Url {
    param([Parameter(Mandatory)][string]$Url)

    try {
        $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
        if ($platform -eq 'Unix') {
            $opener = if (Get-Command open -ErrorAction SilentlyContinue) { 'open' } else { 'xdg-open' }
            Start-Process $opener $Url -ErrorAction Stop | Out-Null
        }
        else {
            Start-Process $Url -ErrorAction Stop | Out-Null
        }
        return $true
    }
    catch {
        return $false
    }
}

function Get-MaskedSecretDisplay {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 4) { return '***' }
    return ('***' + $Value.Substring($Value.Length - 4))
}

function Get-CompletionPreview {
    param(
        [AllowNull()][string]$Value,
        [switch]$Mask
    )

    if ($Mask) { return Get-MaskedSecretDisplay -Value $Value }
    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 72) { return $Value }
    return ($Value.Substring(0, 69) + '...')
}

function Invoke-CompletionActionMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string[]]$Situation,
        [Parameter(Mandatory)][object[]]$Items
    )

    Write-Host ''
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * [Math]::Min($Title.Length, 60))) -ForegroundColor Cyan
    foreach ($line in $Situation) {
        Write-Host "  $line" -ForegroundColor White
    }
    Write-Host ''
    Write-Host '  Copy each value into the matching ISC Connection Settings field, or open a link to finish pending manual steps.' -ForegroundColor Yellow

    if ($Items.Count -eq 0) { return }

    if ($NonInteractive) {
        Write-Host ''
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            Write-Host "  $($item.Label): $preview ($verb)" -ForegroundColor Yellow
        }
        return
    }

    $doneLabel = 'Done'
    while ($true) {
        $labels = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            $labels.Add(('{0}: {1} ({2})' -f $item.Label, $preview, $verb))
        }
        $labels.Add($doneLabel)

        $picked = Read-Choice -Prompt 'Select a value to copy or a link to open:' `
            -Options $labels.ToArray() `
            -Default $doneLabel `
            -EscapeMeansDefault
        if ($picked -eq $doneLabel) { return }

        $index = [array]::IndexOf($labels.ToArray(), $picked)
        if ($index -lt 0 -or $index -ge $Items.Count) { continue }

        $selected = $Items[$index]
        if ($selected.Kind -eq 'Open') {
            if (Open-Url -Url ([string]$selected.Value)) {
                Write-Ok "Opened $($selected.Label)"
            }
            else {
                Write-Warning "Could not open a browser. URL: $($selected.Value)"
            }
        }
        else {
            if (Copy-ToClipboard -Text ([string]$selected.Value)) {
                Write-Ok "$($selected.Label) copied to the clipboard"
            }
            else {
                Write-Warning 'No clipboard tool is available (Set-Clipboard, pbcopy, wl-copy, or xclip). Copy from the list above.'
            }
        }
    }
}

# -----------------------------------------------------------------------------
# AWS session
# -----------------------------------------------------------------------------

function Initialize-AwsModules {
    $required = @(
        'AWS.Tools.Common'
        'AWS.Tools.SecurityToken'
        'AWS.Tools.IdentityManagement'
        'AWS.Tools.Organizations'
    )

    $missing = @($required | Where-Object { -not (Get-Module -ListAvailable -Name $_) })
    if ($missing.Count -gt 0) {
        Write-Step 'AWS Tools for PowerShell modules are required'
        foreach ($name in $missing) { Write-Info $name }
        if (-not (Read-YesNo -Prompt 'Install the missing modules for the current user?' -Default $true)) {
            throw "Install the modules manually: Install-Module $($missing -join ', ') -Scope CurrentUser"
        }
        if (-not (Get-Module -ListAvailable -Name 'AWS.Tools.Installer')) {
            Write-Info 'Installing AWS.Tools.Installer ...'
            Install-Module -Name 'AWS.Tools.Installer' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        Import-Module AWS.Tools.Installer -ErrorAction Stop
        $toInstall = @($missing | Where-Object { $_ -ne 'AWS.Tools.Common' })
        if ($toInstall.Count -eq 0) { $toInstall = @('AWS.Tools.SecurityToken') }
        Write-Info "Installing $($toInstall -join ', ') ..."
        Install-AWSToolsModule -Name $toInstall -Scope CurrentUser -Force -CleanUp -ErrorAction Stop
    }

    foreach ($name in $required) {
        Import-Module $name -ErrorAction Stop
    }
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

# -TrustPrincipal accepts a full role ARN or the account ID from an AssumeRole AccessDenied message.
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
        [Parameter(Mandatory)][string]$ExternalIdValue
    )

    # IAM stores a lone principal as a string; keep the single-principal document identical to the docs.
    $awsPrincipal = if ($PrincipalArn.Count -eq 1) { $PrincipalArn[0] } else { @($PrincipalArn) }

    return ConvertTo-IamJson @{
        Version   = '2012-10-17'
        Statement = @(
            @{
                Effect    = 'Allow'
                Principal = @{ AWS = $awsPrincipal }
                Action    = 'sts:AssumeRole'
                Condition = @{
                    StringEquals = @{ 'sts:ExternalId' = $ExternalIdValue }
                }
            }
        )
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

function Get-SelectedPolicyDocuments {
    param(
        [Parameter(Mandatory)][string]$Set,
        [string[]]$FeatureNames,
        [switch]$SkipProvisioning,
        [string]$BucketName,
        [string]$Partition
    )

    $docs = [ordered]@{}
    $docs['SPAggregationPolicy'] = New-StarPolicyDocument -Actions $script:AggregationActions

    $orgActions = if ($Set -eq 'NonMgo') { $script:OrganizationActionsNonMgo } else { $script:OrganizationActionsMgo }
    $docs['SPOrganizationPolicy'] = New-StarPolicyDocument -Actions $orgActions

    if (-not $SkipProvisioning) {
        $provActions = if ($Set -eq 'NonMgo') { $script:ProvisioningActionsNonMgo } else { $script:ProvisioningActionsMgo }
        $docs['SPProvisioningPolicy'] = New-StarPolicyDocument -Actions $provActions
    }

    foreach ($name in @($FeatureNames)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if ($SkipProvisioning -and $name -eq 'IdentityCenterProvisioning') { continue }
        $pack = $script:FeaturePacks[$name]
        $docs[$pack.PolicyName] = New-StarPolicyDocument -Actions $pack.Actions
    }

    if ($BucketName) {
        $docs['SPCloudTrailBucketPolicy'] = New-CloudTrailBucketPolicyDocument -BucketName $BucketName -Partition $Partition
    }

    return $docs
}

function Get-IamCmdletParams {
    param($Credential, [string]$RegionName)

    $params = @{ Region = $RegionName; ErrorAction = 'Stop' }
    if ($Credential) { $params.Credential = $Credential }
    return $params
}

function Get-LocalPolicyByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        $AwsParams
    )

    $policies = @(Get-IAMPolicyList @AwsParams -Scope Local | Where-Object { $_.PolicyName -eq $Name })
    if ($policies.Count -gt 0) { return $policies[0] }
    return $null
}

function Set-CustomerManagedPolicy {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Document,
        [Parameter(Mandatory)][string]$Description,
        $AwsParams
    )

    $existing = Get-LocalPolicyByName -Name $Name -AwsParams $AwsParams
    if (-not $existing) {
        $created = New-IAMPolicy @AwsParams -PolicyName $Name -PolicyDocument $Document -Description $Description
        Write-Ok "Created policy $Name"
        return $created.Arn
    }

    $versions = @(Get-IAMPolicyVersionList @AwsParams -PolicyArn $existing.Arn)
    if ($versions.Count -ge 5) {
        $oldest = $versions |
            Where-Object { -not $_.IsDefaultVersion } |
            Sort-Object CreateDate |
            Select-Object -First 1
        if ($oldest) {
            Remove-IAMPolicyVersion @AwsParams -PolicyArn $existing.Arn -VersionId $oldest.VersionId -Force
        }
    }

    New-IAMPolicyVersion @AwsParams -PolicyArn $existing.Arn -PolicyDocument $Document -SetAsDefault $true | Out-Null
    Write-Ok "Updated policy $Name"
    return $existing.Arn
}

function Set-SailPointIamRole {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$TrustDocument,
        [Parameter(Mandatory)]$PolicyDocuments,
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Partition,
        $AwsParams
    )

    $role = $null
    try {
        $role = Get-IAMRole @AwsParams -RoleName $Name
    }
    catch {
        if ($_.Exception.Message -notmatch 'NoSuchEntity|cannot be found') { throw }
    }

    if ($role) {
        Update-IAMAssumeRolePolicy @AwsParams -RoleName $Name -PolicyDocument $TrustDocument
        Write-Ok "Updated trust policy on $Name"
    }
    else {
        $role = New-IAMRole @AwsParams -RoleName $Name -AssumeRolePolicyDocument $TrustDocument `
            -Description 'SailPoint Identity Security Cloud - Amazon Web Services SaaS connector' `
            -MaxSessionDuration 3600
        $script:CreatedRoleArn = $role.Arn
        Write-Ok "Created role $($role.Arn)"
    }

    $desiredArns = [System.Collections.Generic.List[string]]::new()
    foreach ($policyName in $PolicyDocuments.Keys) {
        $arn = Set-CustomerManagedPolicy -Name $policyName -Document $PolicyDocuments[$policyName] `
            -Description "SailPoint ISC AWS SaaS - $policyName" -AwsParams $AwsParams
        try {
            Register-IAMRolePolicy @AwsParams -RoleName $Name -PolicyArn $arn
            Write-Ok "Attached $policyName"
        }
        catch {
            if ($_.Exception.Message -match 'already attached|Duplicate') {
                Write-Info "Already attached $policyName"
            }
            else {
                throw
            }
        }
        $desiredArns.Add($arn)
    }

    $attached = @(Get-IAMAttachedRolePolicyList @AwsParams -RoleName $Name)
    foreach ($item in $attached) {
        $shortName = $item.PolicyName
        if ($script:ManagedPolicyNames -contains $shortName -and $desiredArns -notcontains $item.PolicyArn) {
            Unregister-IAMRolePolicy @AwsParams -RoleName $Name -PolicyArn $item.PolicyArn
            Write-Info "Detached unused $shortName"
        }
    }

    return "arn:${Partition}:iam::${AccountId}:role/${Name}"
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

# organizations:ListAccounts only succeeds in the management account (or a delegated admin).
# ISC Cloud Scope (AWS Accounts) is populated by SailPoint assuming the connector role and
# calling that API, so the role and Management Account ID must be the org root.
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

# The script cannot perform SailPoint's assume-role itself: the trust policy only allows
# ciem_universal. What it can do is read back the stored role and confirm the three things the
# Cloud Scope lookup depends on - the trust principal, the External ID condition, and
# organizations:ListAccounts on an attached policy.
function Test-SailPointRoleConfiguration {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$ExpectedPrincipal,
        [Parameter(Mandatory)][string]$ExpectedExternalId,
        $AwsParams
    )

    $role = Get-IAMRole @AwsParams -RoleName $Name
    $trust = $role.AssumeRolePolicyDocument
    # IAM returns the trust document URL-encoded.
    if ($trust -notmatch '^\s*\{') { $trust = [uri]::UnescapeDataString($trust) }

    foreach ($expected in $ExpectedPrincipal) {
        if ($trust -like "*$expected*") {
            Write-Ok "Trust principal present: $expected"
        }
        else {
            Write-Warning "Trust policy on $Name does not reference $expected. SailPoint cannot assume this role."
        }
    }

    if ($trust -like "*$ExpectedExternalId*") {
        Write-Ok 'Trust policy requires the External ID you supplied'
    }
    else {
        Write-Warning "Trust policy on $Name does not contain External ID $ExpectedExternalId. Copy the exact value from the ISC source and re-run."
    }

    $hasListAccounts = $false
    foreach ($item in @(Get-IAMAttachedRolePolicyList @AwsParams -RoleName $Name)) {
        try {
            $policy = Get-IAMPolicy @AwsParams -PolicyArn $item.PolicyArn
            $version = Get-IAMPolicyVersion @AwsParams -PolicyArn $item.PolicyArn -VersionId $policy.DefaultVersionId
            $document = $version.Document
            if ($document -notmatch '^\s*\{') { $document = [uri]::UnescapeDataString($document) }
            if ($document -match 'organizations:(ListAccounts|List\*)') {
                $hasListAccounts = $true
                break
            }
        }
        catch {
            Write-Verbose "Could not read $($item.PolicyName): $($_.Exception.Message)"
        }
    }

    if ($hasListAccounts) {
        Write-Ok 'organizations:ListAccounts granted (required for the AWS Accounts / Cloud Scope list)'
    }
    else {
        Write-Warning "No attached policy on $Name grants organizations:ListAccounts. The ISC AWS Accounts dropdown will fail with 'Failed to get config options for key: cloudScope'."
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

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

try {
    Write-Banner
    Initialize-AwsModules

    $session = $null
    $connectKey = $null
    $existingRole = $null
    $isUpdate = $false

    # Whether each value still has to be asked for is decided once, from what the caller passed.
    # Testing the variables instead would stop a step from asking again when Esc returns to it.
    $askProfileName = -not $ProfileName -and -not $NonInteractive
    $askCloud = -not $PSBoundParameters.ContainsKey('Cloud') -and -not $NonInteractive
    $askRegion = -not $PSBoundParameters.ContainsKey('Region') -and -not $NonInteractive
    $askTrustPrincipal = -not $TrustPrincipal -and -not $NonInteractive
    $askRoleName = -not $PSBoundParameters.ContainsKey('RoleName')
    $askExternalId = -not $ExternalId
    $askPolicySet = -not $PSBoundParameters.ContainsKey('PolicySet') -and -not $NonInteractive
    $askFeature = -not $PSBoundParameters.ContainsKey('Feature')
    $askAggregationOnly = -not $PSBoundParameters.ContainsKey('AggregationOnly') -and -not $NonInteractive
    $askCloudTrailBucket = -not $PSBoundParameters.ContainsKey('CloudTrailBucket') -and -not $NonInteractive
    $askScope = -not $PSBoundParameters.ContainsKey('Scope') -and -not $NonInteractive
    $askMemberAssumeRole = -not $MemberAssumeRole -and -not $NonInteractive

    if (-not $askRegion -and $Cloud -eq 'GovCloud' -and $Region -eq 'us-east-1') {
        $Region = 'us-gov-west-1'
    }

    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            if (Enter-WizardPrompt) {
                if ($askProfileName) {
                    $ProfileName = Read-InputString -Prompt 'AWS profile name (blank = default credential chain)' -Default $ProfileName
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askCloud) {
                    $Cloud = Read-Choice -Prompt 'AWS cloud:' -Options @('Commercial', 'GovCloud') -Labels @(
                        'Commercial - trust CIEM (874540850173) and ISC SaaS (706944607044)'
                        'GovCloud - trust arn:aws-us-gov:iam::229634586956:role/ciem_universal'
                    ) -Default $(if ($Cloud) { $Cloud } else { 'Commercial' })
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askRegion) {
                    $defaultRegion = if ($Cloud -eq 'GovCloud') { 'us-gov-west-1' } else { 'us-east-1' }
                    $Region = Read-InputString -Prompt 'AWS region (for STS / Organizations)' -Default $(if ($Region) { $Region } else { $defaultRegion }) -Required
                }
                Complete-WizardPrompt
            }

            $nextConnectKey = "$ProfileName|$Region|$Cloud"
            if (-not $session -or $nextConnectKey -ne $connectKey) {
                $session = Connect-AwsSession -RequestedProfile $ProfileName -RequestedRegion $Region
                $connectKey = $nextConnectKey
            }
            $partition = $script:SailPointTrust[$Cloud].Partition
            $defaultPrincipals = @($script:SailPointTrust[$Cloud].Principals)

            if (Enter-WizardPrompt) {
                if ($askTrustPrincipal) {
                    Write-Info "Default $Cloud trust: $($defaultPrincipals -join ', ')"
                    Write-Info 'CIEM is the documented commercial principal; ISC SaaS is the connector runtime some tenants assume from. If AssumeRole still fails, enter the account ID from that error.'
                    $extraPrincipal = Read-InputString -Prompt 'Additional SailPoint account ID or role ARN to trust (blank = defaults only)'
                    if ($extraPrincipal) {
                        $TrustPrincipal = @($defaultPrincipals + $extraPrincipal)
                    }
                    else {
                        $TrustPrincipal = $null
                    }
                }
                Complete-WizardPrompt
            }

            $principals = Resolve-TrustPrincipal -Value $(if ($TrustPrincipal) { $TrustPrincipal } else { $defaultPrincipals }) -Partition $partition

            $awsParams = Get-IamCmdletParams -RegionName $Region

            Write-Step 'Checking AWS Organizations (Cloud Scope)'
            $orgContext = Get-AwsOrganizationContext -CurrentAccountId $session.Account -AwsParams $awsParams
            $managementAccountId = $session.Account
            if ($orgContext.Available -and $orgContext.MasterAccountId) {
                $managementAccountId = $orgContext.MasterAccountId
                if ($orgContext.IsManagement) {
                    Write-Ok "This is the organization management account ($managementAccountId)"
                    if ($orgContext.AccountIds.Count -gt 0) {
                        Write-Ok "organizations:ListAccounts returned $($orgContext.AccountIds.Count) ACTIVE account(s) for Cloud Scope"
                    }
                }
                else {
                    Write-Warning "This account $($session.Account) is a member. ISC Management Account ID and Cloud Scope require the management account $managementAccountId."
                    Write-Warning 'Create SailPointAWSRole in the management account. organizations:ListAccounts fails in member accounts, so the AWS Accounts dropdown stays empty.'
                }
                if ($orgContext.Error) {
                    Write-Warning "Could not list organization accounts: $($orgContext.Error)"
                }
            }
            elseif ($orgContext.NotInUse) {
                Write-Warning "Account $($session.Account) is not part of an AWS Organization (AWSOrganizationsNotInUseException)."
                Write-Warning 'ISC fills AWS Account Settings by calling organizations:ListAccounts, so that list stays empty and aggregation fails with "AWS Account IDs must be configured". SailPoint does not support single-account AWS SaaS sources.'
                Write-Info 'Fix: enable an organization in this account (aws organizations create-organization --feature-set ALL), which makes it the management account, then reopen AWS Account Settings.'
                Write-Info 'The role and policies below are still created correctly; only Cloud Scope is blocked.'
            }
            else {
                Write-Warning "AWS Organizations is not readable from this account: $($orgContext.Error)"
                Write-Warning 'The ISC AWS Accounts (Cloud Scope) dropdown calls organizations:ListAccounts after assuming this role. Without that permission on the management-account role, the dropdown fails with Failed to get config options for key: cloudScope.'
            }

            if (Enter-WizardPrompt) {
                if ($askRoleName) {
                    $RoleName = Read-InputString -Prompt 'IAM role name' -Default $(if ($RoleName) { $RoleName } else { 'SailPointAWSRole' }) -Required
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askExternalId) {
                    $ExternalId = Read-InputString -Prompt 'External ID from the ISC AWS SaaS source Connection Settings' -Default $ExternalId -Required
                }
                Complete-WizardPrompt
            }

            $existingRole = $null
            try { $existingRole = Get-IAMRole @awsParams -RoleName $RoleName } catch { }
            $isUpdate = [bool]$existingRole
            if (Enter-WizardPrompt) {
                if ($isUpdate) {
                    Write-Step "A role named '$RoleName' already exists in account $($session.Account)"
                    Write-Info $existingRole.Arn
                    if (-not (Read-YesNo -Prompt 'Update it instead of stopping?' -Default $true)) {
                        throw 'Cancelled. Choose a different -RoleName to create a new role.'
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askPolicySet) {
                    $PolicySet = Read-Choice -Prompt 'Policy set:' -Options @('Mgo', 'NonMgo') -Labels @(
                        'Multiple group objects - groups, managed/inline policies, roles, OUs, SCPs, accounts (recommended)'
                        'Non-MGO - IAM groups as the only entitlement type'
                    ) -Default $(if ($PolicySet) { $PolicySet } else { 'Mgo' })
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askFeature) {
                    $packNames = @($script:FeaturePacks.Keys)
                    $packLabels = @($packNames | ForEach-Object { $script:FeaturePacks[$_].Label })
                    Write-Step 'Permissions'
                    Write-Info 'SPAggregationPolicy and SPOrganizationPolicy are always attached. Provisioning is included unless you choose aggregation only.'
                    $Feature = @(Read-MultiChoice -Prompt 'Optional feature permissions to add:' -Options $packNames -Labels $packLabels)
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askAggregationOnly) {
                    $AggregationOnly = -not (Read-YesNo -Prompt 'Include provisioning permissions (create/update/delete IAM users and entitlements)?' -Default $(-not $AggregationOnly))
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askCloudTrailBucket) {
                    $CloudTrailBucket = Read-InputString -Prompt 'CloudTrail S3 bucket name (blank = skip)' -Default $CloudTrailBucket
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askScope) {
                    $Scope = Read-Choice -Prompt 'Deployment scope:' -Options @('CurrentAccount', 'Organization') -Labels @(
                        "This account only ($($session.Account))"
                        'This account plus every ACTIVE account in the AWS Organization'
                    ) -Default $(if ($Scope) { $Scope } else { 'CurrentAccount' })
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($Scope -eq 'Organization' -and $askMemberAssumeRole) {
                    $MemberAssumeRole = Read-InputString -Prompt 'Member-account role to assume (e.g. OrganizationAccountAccessRole; blank = management account only)' -Default $MemberAssumeRole
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if (-not $OutputDirectory) {
                    $OutputDirectory = Join-Path (Get-Location) (Join-Path 'sourceConfig' 'aws-isc')
                }
                $OutputDirectory = Read-InputString -Prompt 'Output directory for connection settings' -Default $OutputDirectory -Required
                Complete-WizardPrompt
            }

            $policyDocs = Get-SelectedPolicyDocuments -Set $PolicySet -FeatureNames $Feature `
                -SkipProvisioning:$AggregationOnly -BucketName $CloudTrailBucket -Partition $partition
            $trustDoc = New-TrustPolicyDocument -PrincipalArn $principals -ExternalIdValue $ExternalId

            $planAction = if ($isUpdate) { 'Update existing role' } else { 'Create role' }
            $planFeatures = if ($Feature) { $Feature -join ', ' } else { 'none' }
            $planProv = if ($AggregationOnly) { 'aggregation only' } else { 'included' }
            $planBucket = if ($CloudTrailBucket) { $CloudTrailBucket } else { 'none' }

            Write-Step 'Plan'
            Write-Host "   Action              : $planAction"
            Write-Host "   Role                : $RoleName"
            Write-Host "   Account             : $($session.Account)"
            Write-Host "   Org management      : $managementAccountId"
            Write-Host "   Cloud               : $Cloud"
            Write-Host "   Trust principal     : $($principals -join ', ')"
            Write-Host "   Policy set          : $PolicySet"
            Write-Host "   Provisioning        : $planProv"
            Write-Host "   Feature packs       : $planFeatures"
            Write-Host "   CloudTrail bucket   : $planBucket"
            Write-Host "   Scope               : $Scope"
            Write-Host "   Policies            : $($policyDocs.Keys -join ', ')"
            Write-Host ''
            Write-Info 'ISC Connection Settings need the role name (not the ARN), region, External ID, and management account ID.'

            if (Enter-WizardPrompt) {
                if (-not (Read-YesNo -Prompt 'Proceed?' -Default $true)) {
                    Write-Host 'Cancelled.' -ForegroundColor Yellow
                    return
                }
                Complete-WizardPrompt
            }

            $wizardComplete = $true
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if (-not (Move-WizardBack)) {
                Write-Host ''
                Write-Host 'Cancelled.' -ForegroundColor Yellow
                return
            }
        }
    }

    $action = if ($isUpdate) { "Update IAM role '$RoleName'" } else { "Create IAM role '$RoleName'" }
    if (-not $PSCmdlet.ShouldProcess($RoleName, $action)) { return }

    $targets = [System.Collections.Generic.List[pscustomobject]]::new()
    $targets.Add([PSCustomObject]@{ AccountId = $session.Account; Credential = $null; Label = 'management / current' })

    if ($Scope -eq 'Organization') {
        Write-Step 'Listing organization accounts'
        $orgIds = @(Get-OrganizationAccountIds -AwsParams $awsParams)
        Write-Ok "$($orgIds.Count) ACTIVE account(s)"
        foreach ($id in $orgIds) {
            if ($id -eq $session.Account) { continue }
            if (-not $MemberAssumeRole) {
                $skippedMemberAccounts.Add($id)
                Write-Info "Skipping $id (no member assume role). Re-run in that account or pass -MemberAssumeRole."
                continue
            }
            try {
                $creds = Get-MemberCredentials -AccountId $id -RoleNameToAssume $MemberAssumeRole -Partition $partition -RegionName $Region
                $targets.Add([PSCustomObject]@{ AccountId = $id; Credential = $creds; Label = 'member' })
            }
            catch {
                Write-Warning "Could not assume $MemberAssumeRole in $id : $($_.Exception.Message)"
            }
        }
    }

    $roleArns = [System.Collections.Generic.List[string]]::new()
    $skippedMemberAccounts = [System.Collections.Generic.List[string]]::new()
    foreach ($target in $targets) {
        Write-Step "Configuring $($target.Label) account $($target.AccountId)"
        $targetParams = Get-IamCmdletParams -Credential $target.Credential -RegionName $Region
        $arn = Set-SailPointIamRole -Name $RoleName -TrustDocument $trustDoc -PolicyDocuments $policyDocs `
            -AccountId $target.AccountId -Partition $partition -AwsParams $targetParams
        $roleArns.Add($arn)
        Write-Ok $arn

        Test-SailPointRoleConfiguration -Name $RoleName -ExpectedPrincipal $principals `
            -ExpectedExternalId $ExternalId -AwsParams $targetParams
    }

    $consoleHost = if ($Cloud -eq 'GovCloud') { 'https://console.amazonaws-us-gov.com' } else { 'https://console.aws.amazon.com' }
    $roleUrl = "$consoleHost/iam/home#/roles/$RoleName"
    $orgUrl = "$consoleHost/organizations/v2/home/accounts"

    $cloudScopeIds = if ($orgContext.AccountIds.Count -gt 0) { $orgContext.AccountIds -join ', ' } else { '' }

    $situation = [System.Collections.Generic.List[string]]::new()
    $situation.Add('AWS IAM setup on this account is complete. Finish any pending steps below, then paste the Connection Settings values into ISC.')
    if ($skippedMemberAccounts.Count -gt 0) {
        $situation.Add("Pending: deploy the same role name ($RoleName) and External ID in member account(s): $($skippedMemberAccounts -join ', ').")
    }
    if ($orgContext.NotInUse) {
        $situation.Add('Pending: this account is not in an AWS Organization, so ISC Cloud Scope (AWS Accounts) will stay empty until you create or join an organization.')
    }
    elseif ($orgContext.Available -and -not $orgContext.IsManagement) {
        $situation.Add("Pending: create $RoleName in the organization management account $managementAccountId (you ran this in member account $($session.Account)).")
    }
    elseif ($orgContext.Available -and $orgContext.IsManagement -and $orgContext.AccountIds.Count -eq 0) {
        $situation.Add('Pending: organizations:ListAccounts did not return accounts. Confirm SPOrganizationPolicy on the management-account role before opening AWS Account Settings in ISC.')
    }
    else {
        $situation.Add('In ISC: save Connection Settings, then open AWS Account Settings and select AWS Accounts (Cloud Scope).')
    }
    if ($PolicySet -eq 'NonMgo') {
        $situation.Add('Pending (Non-MGO): remove organization schema objects via the ISC source schema API if the source is not in an Organization.')
    }
    $situation.Add('Use the role name only in ISC (not the ARN). Authentication is IAM Role.')

    $fields = [ordered]@{
        'Role Name' = $RoleName
        'Region' = $Region
        'External ID' = $ExternalId
        'Management Account ID' = $managementAccountId
    }
    if ($cloudScopeIds) {
        $fields['AWS Accounts (Cloud Scope)'] = $cloudScopeIds
    }
    $settingsPath = Join-Path $OutputDirectory 'sailpoint-aws-connection-settings.txt'
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $completionItems = @(
        [PSCustomObject]@{ Label = 'Role Name'; Value = $RoleName; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Region'; Value = $Region; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'External ID'; Value = $ExternalId; Kind = 'Copy'; Mask = $true }
        [PSCustomObject]@{ Label = 'Management Account ID'; Value = $managementAccountId; Kind = 'Copy'; Mask = $false }
    )
    if ($cloudScopeIds) {
        $completionItems += [PSCustomObject]@{ Label = 'AWS Accounts (Cloud Scope)'; Value = $cloudScopeIds; Kind = 'Copy'; Mask = $false }
    }
    $completionItems += @(
        [PSCustomObject]@{ Label = 'IAM role in AWS console'; Value = $roleUrl; Kind = 'Open'; Mask = $false }
        [PSCustomObject]@{ Label = 'AWS Organizations console'; Value = $orgUrl; Kind = 'Open'; Mask = $false }
    )

    Invoke-CompletionActionMenu -Title 'Next: complete ISC Connection Settings' `
        -Situation $situation.ToArray() `
        -Items $completionItems
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    if ($script:CreatedRoleArn) {
        Write-Warning "Role $script:CreatedRoleArn was created before this failure. Re-run the script with the same role name to finish configuring it."
    }
    Write-Error $_
    exit 1
}
