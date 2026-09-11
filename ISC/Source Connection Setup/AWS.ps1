#Requires -Version 5.1
<#
.SYNOPSIS
    Configures AWS for the SailPoint ISC Amazon Web Services SaaS connector or the CIEM AWS source.

.DESCRIPTION
    AwsSaas (default): creates or updates a cross-account IAM role trusted by SailPoint's ciem_universal
    principal, attaches documented aggregation / organization / provisioning policies, and optional feature packs.
    With -Feature Ciem it also prepares CloudTrail ARN(s) and the bucket account ID so you can enable
    Cloud Infrastructure Entitlement Management on the AWS SaaS source.

    CiemAws: downloads SailPoint's CloudFormation templates and creates or updates the documented stack or
    StackSet for CIEM inventory and optional activity collection (including new CloudTrail / S3 when selected).

    Run one source type per invocation. Each type writes its own connection-settings file under a separate
    default directory so a SaaS run cannot overwrite CIEM output.

    References:
    https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/introduction.html
    https://documentation.sailpoint.com/saas/help/ciem/index.html
    https://documentation.sailpoint.com/saas/help/ciem/aws/config/index.html
    https://documentation.sailpoint.com/saas/help/ciem/aws/config/config_aws_auto.html
    https://documentation.sailpoint.com/saas/help/ciem/aws/config/aws_permission_sets.html
    https://documentation.sailpoint.com/connectors/aws/help/integrating_aws/mgo_source_policies.html
    https://documentation.sailpoint.com/connectors/aws/help/integrating_aws/non_mgo_policies.html
    https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/activity_insights.html

.PARAMETER SourceType
    AwsSaas (default) - ISC Amazon Web Services SaaS connector (native IAM policies).
    CiemAws           - SailPoint CIEM AWS source (SailPoint CloudFormation templates).

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
    IAM role name. Default: SailPointAWSRole (AwsSaas) or SailPointCIEMAuditRole (CiemAws).

.PARAMETER ExternalId
    External ID from the ISC source Connection Settings (AWS SaaS or CIEM AWS). Required.

.PARAMETER InventoryStackName
    CiemAws: CloudFormation stack or StackSet name for inventory collection. Default: SailPointCiemInventory.

.PARAMETER ActivityStackName
    CiemAws: CloudFormation stack name for activity collection. Default: SailPointCiemActivity.

.PARAMETER CiemActivity
    CiemAws activity template selection: None, OrganizationManagement (org management-account stack),
    ExistingCloudTrail, NewCloudTrailExistingBucket, or NewCloudTrailAndBucket (single account).

.PARAMETER EnableIdentityStoreReadOnly
    Identity Center read permissions (true/false). Organization scope only: org activity stack uses the
    template parameter; inventory-only org deploys attach SailPointCIEMAuditICReadOnlyPolicy. Ignored
    (and rejected if true) with Single Account / Account instance, which cannot enable Identity Center.

.PARAMETER EnableIdentityStoreProvision
    Identity Center provisioning permissions (true/false). Organization scope only. Leave unset unless
    the CIEM source has Provision Identity Center enabled. Mutually exclusive with Single Account.

.PARAMETER TrailName
    CiemAws: CloudTrail name when creating a new trail. Default: sailpoint-ciem-cloud-trail.

.PARAMETER CloudTrailArn
    Optional CloudTrail ARN(s) to include in connection settings (comma-separated). Used by CiemAws
    and by AwsSaas when -Feature Ciem (ISC Additional Settings: Enable Cloud Infrastructure
    Entitlement Management). Trails in this account are also discovered automatically.

.PARAMETER PolicySet
    Mgo    - multiple group object policies (default; recommended).
    NonMgo - single entitlement type (IAM groups only).

.PARAMETER Feature
    Optional documented feature packs: ActivityInsights, Ciem, AgentDiscovery. ActivityInsights also
    adds sts:TagSession to the role trust policy, because SailPoint passes session tags when assuming
    the role for activity collection. Identity Center is not a SaaS feature: SailPoint governs
    Identity Center users and permission sets through a CIEM AWS source (-SourceType CiemAws).

.PARAMETER AggregationOnly
    Skip SPProvisioningPolicy.

.PARAMETER CloudTrailBucket
    CloudTrail log bucket. AwsSaas: optional unless -Feature Ciem, which requires it for
    SPCloudTrailBucketPolicy and CIEM settings. CiemAws: required by SailPoint templates.
    Default for CiemAws: sailpoint-ciem-<account-id> (globally unique, valid S3 DNS name).

.PARAMETER CloudTrailBucketAccountId
    12-digit AWS account that hosts the CloudTrail S3 bucket. AwsSaas -Feature Ciem: ISC
    "AWS CloudTrail Bucket Account ID". Defaults to the signed-in account.

.PARAMETER Scope
    CurrentAccount (default) or Organization. Organization lists member accounts and creates the same
    role in each when -MemberAssumeRole is set.

.PARAMETER MemberAssumeRole
    Existing role in member accounts that this identity can assume (for example OrganizationAccountAccessRole).
    Required for -Scope Organization beyond the management account.

.PARAMETER OutputDirectory
    Directory for the connection-settings file. Default: ./sourceConfig/aws-isc (AwsSaas) or ./sourceConfig/aws-ciem (CiemAws).

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\AWS.ps1

.EXAMPLE
    .\AWS.ps1 -ExternalId '11111111-2222-3333-4444-555555555555' -Feature ActivityInsights,Ciem `
        -CloudTrailBucket 'my-org-cloudtrail-logs' -NonInteractive

.EXAMPLE
    .\AWS.ps1 -SourceType CiemAws -ExternalId '11111111-2222-3333-4444-555555555555' -Scope Organization `
        -CloudTrailBucket 'my-org-cloudtrail-logs' -CiemActivity OrganizationManagement -NonInteractive

.NOTES
    AwsSaas: sign in with permission to create IAM roles and policies; org-wide SaaS also needs member assume role.
    CiemAws: sign in with CloudFormation and (for organizations) StackSet permissions in the management account.
    Published CIEM templates trust only the documented CIEM account (874540850173 commercial). After deployment the
    script rewrites the role trust to the same defaults as AwsSaas (CIEM plus the ISC SaaS runtime account
    706944607044), because some tenants assume the role from the latter. Use -TrustPrincipal to set a different list.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('AwsSaas', 'CiemAws')]
    [string]$SourceType = 'AwsSaas',

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
    [ValidateSet('ActivityInsights', 'Ciem', 'AgentDiscovery')]
    [string[]]$Feature,

    [Parameter()]
    [switch]$AggregationOnly,

    [Parameter()]
    [string]$CloudTrailBucket,

    [Parameter()]
    [string]$CloudTrailBucketAccountId,

    [Parameter()]
    [ValidateSet('CurrentAccount', 'Organization')]
    [string]$Scope = 'CurrentAccount',

    [Parameter()]
    [string]$MemberAssumeRole,

    [Parameter()]
    [string]$InventoryStackName = 'SailPointCiemInventory',

    [Parameter()]
    [string]$ActivityStackName = 'SailPointCiemActivity',

    [Parameter()]
    [ValidateSet('None', 'OrganizationManagement', 'ExistingCloudTrail', 'NewCloudTrailExistingBucket', 'NewCloudTrailAndBucket')]
    [string]$CiemActivity = 'None',

    [Parameter()]
    [ValidateSet('true', 'false')]
    [string]$EnableIdentityStoreReadOnly = 'true',

    [Parameter()]
    [ValidateSet('true', 'false')]
    [string]$EnableIdentityStoreProvision = 'true',

    [Parameter()]
    [string]$TrailName = 'sailpoint-ciem-cloud-trail',

    [Parameter()]
    [ValidateSet('Discover', 'CreateNew', 'EnterName')]
    [string]$SaasCiemCloudTrailSetup,

    [Parameter()]
    [string]$SaasCiemCloudTrailStackName = 'SailPointSaasCiemCloudTrail',

    [Parameter()]
    [string[]]$CloudTrailArn,

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Initialize-OperatorConsole -NonInteractive:$NonInteractive
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.AwsConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.AwsCiemConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.AwsSaasConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.AwsSourceSetup.psm1') -Force
Initialize-AwsSourceSetup -ModuleRoot $script:ModuleRoot -NonInteractive:$NonInteractive


function Write-Banner {
    param(
        [ValidateSet('AwsSaas', 'CiemAws')]
        [string]$SourceType = 'AwsSaas'
    )

    Write-Host ''
    if ($SourceType -eq 'CiemAws') {
        Write-Host '  SailPoint ISC  -  CIEM AWS source connection setup' -ForegroundColor Cyan
        Write-Host '  Deploys SailPoint CloudFormation templates for CIEM inventory and activity.' -ForegroundColor DarkCyan
    }
    else {
        Write-Host '  SailPoint ISC  -  Amazon Web Services SaaS source connection setup' -ForegroundColor Cyan
        Write-Host '  Creates or updates the IAM role used by the AWS SaaS connector.' -ForegroundColor DarkCyan
    }
    Write-Host ''
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

try {
    Ensure-AwsToolsModules -ExtraModules @(
        'AWS.Tools.CloudFormation'
        'AWS.Tools.CloudTrail'
        'AWS.Tools.EC2'
        'AWS.Tools.S3'
    )

    $askSourceType = -not $PSBoundParameters.ContainsKey('SourceType') -and -not $NonInteractive
    if ($askSourceType -and -not $NonInteractive) {
        $SourceType = Read-Choice -Prompt 'ISC source type:' -Options @('AwsSaas', 'CiemAws') -Labels @(
            'Amazon Web Services SaaS connector (native IAM role and SP* policies)'
            'CIEM AWS source (SailPoint CloudFormation templates)'
        ) -Default 'AwsSaas'
    }

    Write-Banner -SourceType $SourceType
    if ($SourceType -eq 'CiemAws') {
        Ensure-AwsToolsModules -ExtraModules @(
            'AWS.Tools.CloudFormation'
            'AWS.Tools.CloudTrail'
            'AWS.Tools.EC2'
        )
    }

    if ($SourceType -eq 'CiemAws' -and $RoleName -eq (Get-DefaultSaasRoleName)) {
        $RoleName = Get-DefaultCiemRoleName
    }
    elseif ($SourceType -eq 'AwsSaas' -and $RoleName -eq (Get-DefaultCiemRoleName)) {
        $RoleName = Get-DefaultSaasRoleName
    }

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
    $askPolicySet = $SourceType -eq 'AwsSaas' -and -not $PSBoundParameters.ContainsKey('PolicySet') -and -not $NonInteractive
    $askFeature = $SourceType -eq 'AwsSaas' -and -not $PSBoundParameters.ContainsKey('Feature')
    $askAggregationOnly = $SourceType -eq 'AwsSaas' -and -not $PSBoundParameters.ContainsKey('AggregationOnly') -and -not $NonInteractive
    $askCloudTrailBucket = -not $PSBoundParameters.ContainsKey('CloudTrailBucket') -and -not $NonInteractive
    $askSaasCiemCloudTrailSetup = $SourceType -eq 'AwsSaas' -and -not $PSBoundParameters.ContainsKey('SaasCiemCloudTrailSetup') -and -not $NonInteractive
    $askSaasCiemCloudTrailStack = -not $PSBoundParameters.ContainsKey('SaasCiemCloudTrailStackName') -and -not $NonInteractive
    $askSaasCiemTrailName = $SourceType -eq 'AwsSaas' -and -not $PSBoundParameters.ContainsKey('TrailName') -and -not $NonInteractive
    $askCloudTrailBucketAccountId = -not $PSBoundParameters.ContainsKey('CloudTrailBucketAccountId') -and -not $NonInteractive
    $askCloudTrailArn = -not $PSBoundParameters.ContainsKey('CloudTrailArn') -and -not $NonInteractive
    $askScope = -not $PSBoundParameters.ContainsKey('Scope') -and -not $NonInteractive
    $askMemberAssumeRole = $SourceType -eq 'AwsSaas' -and -not $MemberAssumeRole -and -not $NonInteractive
    $askCiemActivity = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('CiemActivity') -and -not $NonInteractive
    $askEnableIcRead = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('EnableIdentityStoreReadOnly') -and -not $NonInteractive
    $askEnableIcProv = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('EnableIdentityStoreProvision') -and -not $NonInteractive
    $askTrailName = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('TrailName') -and -not $NonInteractive
    $askInventoryStack = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('InventoryStackName') -and -not $NonInteractive
    $askActivityStack = $SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('ActivityStackName') -and -not $NonInteractive

    if (-not $askRegion -and $Cloud -eq 'GovCloud' -and $Region -eq 'us-east-1') {
        $Region = 'us-gov-west-1'
    }

    # The Identity Center answers must survive Esc navigation, so adjust their defaults only once.
    $icDefaultsInitialized = $false
    # Organization activity-stack prompt defaults to Yes once; later Esc passes keep the last answer.
    $orgActivityDefaultInitialized = $false
    # Attach Identity Center policies only when the operator stated an intent, by parameter or by prompt.
    $identityCenterRequested = $askEnableIcRead -or $askEnableIcProv -or
        $PSBoundParameters.ContainsKey('EnableIdentityStoreReadOnly') -or
        $PSBoundParameters.ContainsKey('EnableIdentityStoreProvision')

    $saasCiem = $false
    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            if (Enter-WizardPrompt) {
                if ($askExternalId -and $SourceType -eq 'CiemAws') {
                    $ExternalId = Read-InputString -Prompt 'External ID from the CIEM AWS source Connection Settings' -Default $ExternalId -Required
                }
                Complete-WizardPrompt
            }

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
            if ($SourceType -eq 'CiemAws' -and -not $PSBoundParameters.ContainsKey('CloudTrailBucket') -and
                [string]::IsNullOrWhiteSpace($CloudTrailBucket) -and $session.Account) {
                $CloudTrailBucket = Get-DefaultCiemCloudTrailBucketName -AccountId $session.Account
            }
            $partition = (Get-SailPointTrustConfig -Cloud $Cloud).Partition
            $defaultPrincipals = @((Get-SailPointTrustConfig -Cloud $Cloud).Principals)

            if (Enter-WizardPrompt) {
                if ($askTrustPrincipal) {
                    if ($SourceType -eq 'CiemAws') {
                        Write-Info "CIEM templates trust only arn:aws:iam::874540850173:role/ciem_universal. After deployment the role is set to trust: $($defaultPrincipals -join ', ')"
                        Write-Info 'If Test Connection still reports "Failed to get account authorization details", enter the account ID from the AssumeRole AccessDenied entry in CloudTrail.'
                    }
                    else {
                        Write-Info "Default $Cloud trust: $($defaultPrincipals -join ', ')"
                        Write-Info 'CIEM is the documented commercial principal; ISC SaaS is the connector runtime some tenants assume from. If AssumeRole still fails, enter the account ID from that error.'
                    }
                    $extraPrincipal = Read-InputString -Prompt 'Additional SailPoint account ID or role ARN to trust (blank = template / defaults only)'
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

            Write-Step 'Checking AWS Organizations'
            $orgContext = Get-AwsOrganizationContext -CurrentAccountId $session.Account -AwsParams $awsParams
            $managementAccountId = $session.Account
            if ($orgContext.Available -and $orgContext.MasterAccountId) {
                $managementAccountId = $orgContext.MasterAccountId
                if ($orgContext.IsManagement) {
                    Write-Ok "This is the organization management account ($managementAccountId)"
                    if ($orgContext.AccountIds.Count -gt 0) {
                        Write-Ok "organizations:ListAccounts returned $($orgContext.AccountIds.Count) ACTIVE account(s)"
                    }
                }
                else {
                    if ($SourceType -eq 'AwsSaas') {
                        Write-Warning "This account $($session.Account) is a member. ISC Management Account ID and Cloud Scope require the management account $managementAccountId."
                        Write-Warning 'Create SailPointAWSRole in the management account. organizations:ListAccounts fails in member accounts, so the AWS Accounts dropdown stays empty.'
                    }
                    else {
                        Write-Warning "CIEM organization setup should run from the management account ($managementAccountId). You are signed in to member account $($session.Account)."
                    }
                }
                if ($orgContext.Error) {
                    Write-Warning "Could not list organization accounts: $($orgContext.Error)"
                }
            }
            elseif ($orgContext.NotInUse) {
                if ($SourceType -eq 'AwsSaas') {
                    Write-Warning "Account $($session.Account) is not part of an AWS Organization (AWSOrganizationsNotInUseException)."
                    Write-Warning 'ISC fills AWS Account Settings by calling organizations:ListAccounts, so that list stays empty and aggregation fails with "AWS Account IDs must be configured". SailPoint does not support single-account AWS SaaS sources.'
                    Write-Info 'Fix: enable an organization in this account (aws organizations create-organization --feature-set ALL), which makes it the management account, then reopen AWS Account Settings.'
                    Write-Info 'The role and policies below are still created correctly; only Cloud Scope is blocked.'
                }
                else {
                    Write-Info 'No AWS Organization detected. CIEM single-account mode is supported; enable Single Account in the CIEM AWS source.'
                }
            }
            else {
                if ($SourceType -eq 'AwsSaas') {
                    Write-Warning "AWS Organizations is not readable from this account: $($orgContext.Error)"
                    Write-Warning 'The ISC AWS Accounts (Cloud Scope) dropdown calls organizations:ListAccounts after assuming this role. Without that permission on the management-account role, the dropdown fails with Failed to get config options for key: cloudScope.'
                }
                else {
                    Write-Warning "AWS Organizations is not readable from this account: $($orgContext.Error)"
                }
            }

            if (Enter-WizardPrompt) {
                if ($askRoleName) {
                    $defaultRole = if ($SourceType -eq 'CiemAws') { Get-DefaultCiemRoleName } else { Get-DefaultSaasRoleName }
                    $RoleName = Read-InputString -Prompt 'IAM role name' -Default $(if ($RoleName) { $RoleName } else { $defaultRole }) -Required
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askExternalId -and $SourceType -eq 'AwsSaas') {
                    $ExternalId = Read-InputString -Prompt 'External ID from the ISC AWS SaaS source Connection Settings' -Default $ExternalId -Required
                }
                Complete-WizardPrompt
            }

            $isUpdate = $false
            if ($SourceType -eq 'AwsSaas') {
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
                        $packNames = @((Get-AwsSaasCatalog).FeaturePacks.Keys)
                        # Suffix the -Feature value so the prompt and the plan screen name packs the same way.
                        $packLabels = @($packNames | ForEach-Object { '{0} ({1})' -f (Get-AwsSaasCatalog).FeaturePacks[$_].Label, $_ })
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
            }

            if (Enter-WizardPrompt) {
                if ($askScope) {
                    $scopeLabels = if ($SourceType -eq 'CiemAws') {
                        @(
                            "Single AWS account ($($session.Account)) - enable Single Account in CIEM source"
                            'All AWS Organization accounts (recommended) - inventory StackSet plus optional management activity stack'
                        )
                    }
                    else {
                        @(
                            "This account only ($($session.Account))"
                            'This account plus every ACTIVE account in the AWS Organization'
                        )
                    }
                    $Scope = Read-Choice -Prompt 'Deployment scope:' -Options @('CurrentAccount', 'Organization') -Labels $scopeLabels `
                        -Default $(if ($Scope) { $Scope } else { 'CurrentAccount' })
                }
                Complete-WizardPrompt
            }

            if ($SourceType -eq 'CiemAws') {
                if (Enter-WizardPrompt) {
                    if ($askCiemActivity) {
                        if ($Scope -eq 'Organization') {
                            if (-not $orgActivityDefaultInitialized) {
                                $orgActivityDefaultInitialized = $true
                                if (-not $PSBoundParameters.ContainsKey('CiemActivity')) {
                                    $CiemActivity = 'OrganizationManagement'
                                }
                            }
                            $includeActivity = Read-YesNo -Prompt 'Deploy management-account activity stack (CloudTrail bucket read, Identity Center)?' -Default ($CiemActivity -ne 'None')
                            $CiemActivity = if ($includeActivity) { 'OrganizationManagement' } else { 'None' }
                        }
                        else {
                            $CiemActivity = Read-Choice -Prompt 'CIEM collection mode (single account):' -Options @(
                                'None', 'ExistingCloudTrail', 'NewCloudTrailExistingBucket', 'NewCloudTrailAndBucket'
                            ) -Labels @(
                                'Inventory only (SailPoint inventory template)'
                                'Activity - existing CloudTrail and S3 bucket'
                                'Activity - new CloudTrail with existing S3 bucket'
                                'Activity - new CloudTrail and new S3 bucket'
                            ) -Default $(if ($CiemActivity) { $CiemActivity } else { 'None' })
                        }
                    }
                    Complete-WizardPrompt
                }

                # Identity Center is Organization-only. Account instance (Single Account) cannot enable it.
                $icViaTemplate = ($Scope -eq 'Organization' -and $CiemActivity -eq 'OrganizationManagement')
                if ($Scope -eq 'CurrentAccount') {
                    $boundIcOn = (
                        ($PSBoundParameters.ContainsKey('EnableIdentityStoreReadOnly') -and $EnableIdentityStoreReadOnly -eq 'true') -or
                        ($PSBoundParameters.ContainsKey('EnableIdentityStoreProvision') -and $EnableIdentityStoreProvision -eq 'true')
                    )
                    if ($boundIcOn) {
                        throw 'CIEM Single Account (Account instance) cannot enable Identity Center. Use -Scope Organization, or omit -EnableIdentityStoreReadOnly / -EnableIdentityStoreProvision.'
                    }
                    $EnableIdentityStoreReadOnly = 'false'
                    $EnableIdentityStoreProvision = 'false'
                    if (-not $icDefaultsInitialized) { $icDefaultsInitialized = $true }
                }
                elseif (-not $icDefaultsInitialized) {
                    $icDefaultsInitialized = $true
                    if (-not $icViaTemplate) {
                        if ($askEnableIcRead) { $EnableIdentityStoreReadOnly = 'false' }
                        if ($askEnableIcProv) { $EnableIdentityStoreProvision = 'false' }
                    }
                }

                if ($Scope -eq 'Organization') {
                    # The source has one Provision Identity Center toggle, so ask once and set both
                    # template parameters. Provisioning calls the read APIs, so they always pair.
                    if (Enter-WizardPrompt) {
                        if ($askEnableIcRead -and $askEnableIcProv) {
                            $icPrompt = if ($icViaTemplate) {
                                'Enable Identity Center in the activity stack (source toggle: Provision Identity Center)?'
                            }
                            else {
                                'Grant Identity Center permissions (sso / identitystore) to the role (source toggle: Provision Identity Center)?'
                            }
                            $icAnswer = Read-Choice -Prompt $icPrompt -Options @('true', 'false') -Labels @('Yes', 'No') `
                                -Default $(if ($EnableIdentityStoreProvision -eq 'true') { 'true' } else { 'false' })
                            $EnableIdentityStoreReadOnly = $icAnswer
                            $EnableIdentityStoreProvision = $icAnswer
                        }
                        Complete-WizardPrompt
                    }

                    if ($EnableIdentityStoreProvision -eq 'true' -and $EnableIdentityStoreReadOnly -ne 'true') {
                        $EnableIdentityStoreReadOnly = 'true'
                        Write-Info 'Identity Center read permissions enabled as well; provisioning depends on them.'
                    }
                }

                if (Enter-WizardPrompt) {
                    if ($askTrailName -and $CiemActivity -in @('NewCloudTrailExistingBucket', 'NewCloudTrailAndBucket')) {
                        $TrailName = Read-InputString -Prompt 'New CloudTrail name' -Default $TrailName -Required
                    }
                    Complete-WizardPrompt
                }

                if (Enter-WizardPrompt) {
                    if ($askInventoryStack) {
                        $InventoryStackName = Read-InputString -Prompt 'Inventory stack or StackSet name' -Default $InventoryStackName -Required
                    }
                    Complete-WizardPrompt
                }

                if (Enter-WizardPrompt) {
                    if ($askActivityStack -and $CiemActivity -ne 'None') {
                        $ActivityStackName = Read-InputString -Prompt 'Activity stack name' -Default $ActivityStackName -Required
                    }
                    Complete-WizardPrompt
                }
            }

            $saasCiem = $SourceType -eq 'AwsSaas' -and (Test-EmbeddedCiemSelected -FeatureNames $Feature)

            if (Enter-WizardPrompt) {
                if ($askCloudTrailBucket -or ($askSaasCiemCloudTrailSetup -and $saasCiem)) {
                    $bucketValidate = { param($v) Test-AwsS3BucketName $v }
                    if ($SourceType -eq 'CiemAws') {
                        $bucketPrompt = 'CloudTrail S3 bucket name (required by SailPoint CIEM templates)'
                        $CloudTrailBucket = Read-InputString -Prompt $bucketPrompt -Default $CloudTrailBucket -Required -Validate $bucketValidate
                    }
                    elseif ($saasCiem) {
                        Write-Step 'CIEM CloudTrail'
                        Write-Info 'CIEM on the AWS SaaS source needs CloudTrail logs in an S3 bucket and the trail ARN(s).'

                        if ($askSaasCiemCloudTrailSetup) {
                            $SaasCiemCloudTrailSetup = Read-Choice -Prompt 'CloudTrail log bucket for CIEM:' -Options @(
                                'CreateNew', 'Discover', 'EnterName'
                            ) -Labels @(
                                'Create a new CloudTrail and S3 bucket (SailPoint CloudFormation) (recommended)'
                                'Use an existing bucket from CloudTrail in this account'
                                'Enter a bucket name manually'
                            ) -Default 'CreateNew'
                        }
                        elseif ([string]::IsNullOrWhiteSpace($SaasCiemCloudTrailSetup)) {
                            $SaasCiemCloudTrailSetup = 'EnterName'
                        }

                        switch ($SaasCiemCloudTrailSetup) {
                            'Discover' {
                                Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.CloudTrail', 'AWS.Tools.EC2')
                                $bucketOptions = @(Get-CloudTrailLogBucketOptions -HomeRegion $Region -ScanScope HomeRegion)
                                if ($bucketOptions.Count -eq 0) {
                                    $scanAll = Read-YesNo -Prompt 'No trails in the home region. Scan all AWS regions? (can take a few minutes)' -Default $false
                                    if ($scanAll) {
                                        $bucketOptions = @(Get-CloudTrailLogBucketOptions -HomeRegion $Region -ScanScope AllRegions)
                                    }
                                }
                                if ($bucketOptions.Count -eq 0) {
                                    Write-Info 'No CloudTrail trails were found. Switching to create a new CloudTrail and bucket.'
                                    $SaasCiemCloudTrailSetup = 'CreateNew'
                                }
                                else {
                                    $bucketNames = @($bucketOptions | ForEach-Object { $_.BucketName })
                                    $bucketLabels = @($bucketOptions | ForEach-Object {
                                        $trailCount = @($_.TrailArns).Count
                                        "$($_.BucketName) ($trailCount trail$(if ($trailCount -eq 1) { '' } else { 's' }))"
                                    })
                                    $pickedBucket = Read-Choice -Prompt 'Select CloudTrail log bucket:' -Options $bucketNames -Labels $bucketLabels
                                    $selected = @($bucketOptions | Where-Object { $_.BucketName -eq $pickedBucket } | Select-Object -First 1)
                                    $CloudTrailBucket = $pickedBucket
                                    $CloudTrailArn = @($selected.TrailArns)
                                    Write-Ok "Using bucket $CloudTrailBucket with $($CloudTrailArn.Count) trail ARN(s)"
                                }
                            }
                        }

                        if ($SaasCiemCloudTrailSetup -eq 'CreateNew') {
                            if ([string]::IsNullOrWhiteSpace($CloudTrailBucket) -and $session.Account) {
                                $CloudTrailBucket = Get-DefaultCiemCloudTrailBucketName -AccountId $session.Account
                            }
                            if ($askCloudTrailBucket) {
                                $CloudTrailBucket = Read-InputString -Prompt 'New S3 bucket name for CloudTrail logs' `
                                    -Default $CloudTrailBucket -Required -Validate $bucketValidate
                            }
                            elseif ([string]::IsNullOrWhiteSpace($CloudTrailBucket)) {
                                throw 'AwsSaas -SaasCiemCloudTrailSetup CreateNew requires -CloudTrailBucket (or run interactively).'
                            }
                            if ($askSaasCiemTrailName) {
                                $TrailName = Read-InputString -Prompt 'New CloudTrail name' -Default $TrailName -Required
                            }
                            if ($askSaasCiemCloudTrailStack) {
                                $SaasCiemCloudTrailStackName = Read-InputString -Prompt 'CloudFormation stack name for CloudTrail resources' `
                                    -Default $SaasCiemCloudTrailStackName -Required
                            }
                            Write-Info "At apply, stack $SaasCiemCloudTrailStackName will create bucket $CloudTrailBucket and trail $TrailName."
                        }
                        elseif ($SaasCiemCloudTrailSetup -eq 'EnterName') {
                            if ($askCloudTrailBucket) {
                                $CloudTrailBucket = Read-InputString -Prompt 'CloudTrail S3 bucket name (required to enable CIEM on the AWS SaaS source)' `
                                    -Default $CloudTrailBucket -Required -Validate $bucketValidate
                            }
                        }
                    }
                    else {
                        $CloudTrailBucket = Read-InputString -Prompt 'CloudTrail S3 bucket name (blank = skip)' -Default $CloudTrailBucket -Validate $bucketValidate
                    }
                }
                Complete-WizardPrompt
            }

            if ($saasCiem) {
                if (Enter-WizardPrompt) {
                    if ($askCloudTrailBucketAccountId) {
                        $defaultBucketAccount = if ($CloudTrailBucketAccountId) { $CloudTrailBucketAccountId } else { $session.Account }
                        $CloudTrailBucketAccountId = Read-InputString -Prompt 'AWS CloudTrail Bucket Account ID (account that hosts the S3 bucket)' `
                            -Default $defaultBucketAccount -Required -Validate { param($v) Test-AwsAccountId $v }
                    }
                    Complete-WizardPrompt
                }

                if (Enter-WizardPrompt) {
                    # CreateNew has no ARN to ask about: the trail does not exist yet, and the stack
                    # reports the ARN it creates at apply.
                    if ($askCloudTrailArn -and $SaasCiemCloudTrailSetup -ne 'CreateNew' `
                            -and (-not $CloudTrailArn -or $CloudTrailArn.Count -eq 0)) {
                        $extraArns = Read-InputString -Prompt 'CloudTrail ARN(s) to include (comma-separated; blank = discover in this account)'
                        if ($extraArns) {
                            $CloudTrailArn = @(Get-NormalizedCloudTrailArnList -Value $extraArns)
                        }
                    }
                    Complete-WizardPrompt
                }
            }

            if ($SourceType -eq 'AwsSaas') {
                if (Enter-WizardPrompt) {
                    if ($Scope -eq 'Organization' -and $askMemberAssumeRole) {
                        $MemberAssumeRole = Read-InputString -Prompt 'Member-account role to assume (e.g. OrganizationAccountAccessRole; blank = management account only)' -Default $MemberAssumeRole
                    }
                    Complete-WizardPrompt
                }
            }

            if (Enter-WizardPrompt) {
                if (-not $OutputDirectory) {
                    $OutputDirectory = (Get-ConnectionSettingsOutput -Type $SourceType).Directory
                }
                $OutputDirectory = Read-InputString -Prompt 'Output directory for connection settings' -Default $OutputDirectory -Required
                Complete-WizardPrompt
            }

            Write-Step 'Plan'
            Write-Host "   Source type           : $SourceType"
            Write-Host "   Role                  : $RoleName"
            Write-Host "   Account               : $($session.Account)"
            Write-Host "   Org management        : $managementAccountId"
            Write-Host "   Cloud                 : $Cloud"
            Write-Host "   Scope                 : $Scope"
            if ($SourceType -eq 'AwsSaas') {
                $policyDocs = Get-SelectedPolicyDocuments -Set $PolicySet -FeatureNames $Feature `
                    -SkipProvisioning:$AggregationOnly -BucketName $CloudTrailBucket -Partition $partition
                $tagSession = @($Feature) -contains 'ActivityInsights'
                $trustDoc = New-TrustPolicyDocument -PrincipalArn $principals -ExternalIdValue $ExternalId `
                    -AllowTagSession:$tagSession
                $planAction = if ($isUpdate) { 'Update existing role' } else { 'Create role' }
                $planFeatures = if ($Feature) { $Feature -join ', ' } else { 'none' }
                $planProv = if ($AggregationOnly) { 'aggregation only' } else { 'included' }
                $planTrustActions = if ($tagSession) { 'sts:AssumeRole, sts:TagSession' } else { 'sts:AssumeRole' }
                Write-Host "   Action                : $planAction"
                Write-Host "   Trust principal       : $($principals -join ', ')"
                Write-Host "   Trust actions         : $planTrustActions"
                Write-Host "   Policy set            : $PolicySet"
                Write-Host "   Provisioning          : $planProv"
                Write-Host "   Feature packs         : $planFeatures"
                Write-Host "   CloudTrail bucket     : $(if ($CloudTrailBucket) { $CloudTrailBucket } else { 'none' })"
                if ($saasCiem) {
                    $planBucketAccount = if ($CloudTrailBucketAccountId) { $CloudTrailBucketAccountId } else { $session.Account }
                    $planTrailArns = if ($CloudTrailArn) { (Get-NormalizedCloudTrailArnList -Value $CloudTrailArn) -join ', ' } else { 'discover after apply' }
                    $planCloudTrailSetup = if ($SaasCiemCloudTrailSetup -eq 'CreateNew') {
                        "create via stack $SaasCiemCloudTrailStackName"
                    }
                    elseif ($SaasCiemCloudTrailSetup) { $SaasCiemCloudTrailSetup }
                    else { 'EnterName' }
                    Write-Host "   CIEM on SaaS source   : enable (Additional Settings)"
                    Write-Host "   CloudTrail setup      : $planCloudTrailSetup"
                    Write-Host "   CloudTrail bucket acct: $planBucketAccount"
                    Write-Host "   CloudTrail ARN(s)     : $planTrailArns"
                }
                Write-Host "   Policies              : $($policyDocs.Keys -join ', ')"
                Write-Host ''
                Write-Info 'ISC Connection Settings need the role name (not the ARN), region, External ID, and management account ID.'
                if ($saasCiem) {
                    Write-Info 'Then enable Cloud Infrastructure Entitlement Management and paste CloudTrail ARN(s) plus the bucket account ID.'
                }
            }
            else {
                if ($Scope -eq 'Organization') {
                    $invTemplate = Get-CiemTemplateFileName -Purpose 'Inventory' -Cloud $Cloud
                    Write-Host "   Inventory StackSet    : $InventoryStackName ($invTemplate)"
                    if ($CiemActivity -eq 'OrganizationManagement') {
                        $actTemplate = Get-CiemTemplateFileName -Purpose 'OrganizationManagement' -Cloud $Cloud
                        Write-Host "   Activity stack        : $ActivityStackName ($actTemplate)"
                    }
                }
                else {
                    if ($CiemActivity -eq 'None') {
                        $invTemplate = Get-CiemTemplateFileName -Purpose 'Inventory' -Cloud $Cloud
                        Write-Host "   Inventory stack       : $InventoryStackName ($invTemplate)"
                    }
                    else {
                        $actTemplate = Get-CiemTemplateFileName -Purpose $CiemActivity -Cloud $Cloud
                        Write-Host "   Activity stack        : $ActivityStackName ($actTemplate)"
                    }
                }
                Write-Host "   CloudTrail bucket     : $CloudTrailBucket"
                if ($Scope -eq 'CurrentAccount') {
                    Write-Host "   Identity Center       : off (unsupported with Single Account / Account instance)"
                }
                else {
                    $icSource = if ($CiemActivity -eq 'OrganizationManagement') { 'activity template' } else { 'inline role policies' }
                    $icState = if ($EnableIdentityStoreProvision -eq 'true') { 'on' } elseif ($EnableIdentityStoreReadOnly -eq 'true') { 'read only' } else { 'off' }
                    Write-Host "   Identity Center       : $icState ($icSource)"
                }
                $trustLabel = if ($TrustPrincipal) { 'Trust override       ' } else { 'Role trust           ' }
                Write-Host "   $trustLabel : $($principals -join ', ')"
                Write-Host ''
                Write-Info 'CIEM Connection Settings need the Role ARN (management account when using Organizations), External ID, and optional CloudTrail ARNs.'
            }

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

    $consoleHost = if ($Cloud -eq 'GovCloud') { 'https://console.amazonaws-us-gov.com' } else { 'https://console.aws.amazon.com' }
    $settingsOutput = Get-ConnectionSettingsOutput -Type $SourceType -Directory $OutputDirectory

    $saasCiem = $SourceType -eq 'AwsSaas' -and (Test-EmbeddedCiemSelected -FeatureNames $Feature)
    $saasCiemTrailCreated = $false
    if ($saasCiem) {
        if ([string]::IsNullOrWhiteSpace($SaasCiemCloudTrailSetup) -and -not [string]::IsNullOrWhiteSpace($CloudTrailBucket)) {
            $SaasCiemCloudTrailSetup = 'EnterName'
        }
        if ($SaasCiemCloudTrailSetup -eq 'CreateNew') {
            if ([string]::IsNullOrWhiteSpace($ExternalId)) {
                throw 'AwsSaas CIEM CloudTrail creation requires -ExternalId from ISC Connection Settings.'
            }
            Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.CloudFormation', 'AWS.Tools.CloudTrail', 'AWS.Tools.EC2', 'AWS.Tools.S3')
            $trailDeployment = Deploy-SaasCiemCloudTrailResources -Cloud $Cloud -RegionName $Region -ExternalId $ExternalId `
                -BucketName $CloudTrailBucket -TrailName $TrailName -StackName $SaasCiemCloudTrailStackName -AwsParams $awsParams
            $CloudTrailBucket = $trailDeployment.BucketName
            if ($trailDeployment.CloudTrailArns.Count -gt 0) {
                # Use the trail this run set up, not whatever else the account happens to log.
                $CloudTrailArn = @($trailDeployment.CloudTrailArns)
                $saasCiemTrailCreated = $true
            }
        }

        $ciemCtx = [PSCustomObject]@{
            FeatureNames               = $Feature
            CloudTrailBucket           = $CloudTrailBucket
            CloudTrailBucketAccountId  = $CloudTrailBucketAccountId
            SessionAccountId           = $session.Account
            Region                     = $Region
            CloudTrailArn              = $CloudTrailArn
            SkipCloudTrailDiscovery    = $saasCiemTrailCreated
        }
        Apply-EmbeddedCiemPrerequisites -Context $ciemCtx
        $CloudTrailBucketAccountId = $ciemCtx.CloudTrailBucketAccountId
    }

    if ($SourceType -eq 'CiemAws') {
        if ([string]::IsNullOrWhiteSpace($CloudTrailBucket)) {
            throw 'CiemAws requires -CloudTrailBucket (SailPoint templates need BucketName).'
        }
        $bucketFailure = Test-AwsS3BucketName $CloudTrailBucket
        if ($bucketFailure) { throw $bucketFailure }
        if (-not $PSCmdlet.ShouldProcess($InventoryStackName, 'Deploy SailPoint CIEM CloudFormation')) { return }

        $identityCenterRequested = $Scope -eq 'Organization' -and (
            $askEnableIcRead -or $askEnableIcProv -or
            $PSBoundParameters.ContainsKey('EnableIdentityStoreReadOnly') -or
            $PSBoundParameters.ContainsKey('EnableIdentityStoreProvision')
        )

        $ciemResult = Apply-DedicatedCiemSourceDeployment -Cloud $Cloud -RegionName $Region -Scope $Scope -RoleName $RoleName `
            -ExternalId $ExternalId -BucketName $CloudTrailBucket -ActivityMode $CiemActivity `
            -InventoryStackName $InventoryStackName -ActivityStackName $ActivityStackName `
            -EnableIdentityStoreReadOnlyFlag $EnableIdentityStoreReadOnly `
            -EnableIdentityStoreProvisionFlag $EnableIdentityStoreProvision `
            -TrailNameValue $TrailName -ExtraCloudTrailArn $CloudTrailArn -TrustPrincipalList $TrustPrincipal `
            -AwsParams $awsParams -CurrentAccountId $session.Account -ManagementAccountId $managementAccountId `
            -IdentityCenterRequested:$identityCenterRequested

        $ciemSettings = Build-DedicatedCiemConnectionSettings -DeploymentResult $ciemResult -SessionAccountId $session.Account
        $roleUrl = "$consoleHost/iam/home#/roles/$($ciemResult.RoleName)"
        $cfnUrl = "$consoleHost/cloudformation/home?region=$Region#/stacks"
        $ciemDocUrl = 'https://documentation.sailpoint.com/saas/help/ciem/aws/connect_aws.html'
        $cloudTrailList = $ciemSettings.CloudTrailList

        $situation = [System.Collections.Generic.List[string]]::new()
        $situation.Add('CIEM CloudFormation deployment is complete. Paste the values below into the CIEM AWS source Connection Settings.')
        $situation.Add('Do not enable CIEM on the AWS SaaS source for the same management account when using a dedicated CIEM AWS source.')
        if ($ciemResult.SingleAccount) {
            $situation.Add('In ISC: enable the Single Account toggle on the CIEM AWS source.')
            $situation.Add('Leave Provision Identity Center off. Account instance and Identity Center are mutually exclusive on the CIEM AWS source.')
        }
        elseif ($ciemResult.ProvisionIdentityCenter) {
            $situation.Add('The role carries Identity Center provisioning permissions. Confirm the CIEM source has the PROVISIONING feature before enabling Provision Identity Center.')
        }
        else {
            $situation.Add('In ISC: turn Provision Identity Center OFF. The role has no sso / identitystore permissions, and Test Connection fails while that toggle is on.')
            $situation.Add('To use Identity Center, re-run with Organization scope and answer Yes to the Identity Center permission questions.')
        }
        $situation.Add('After a successful test connection, mark Groups and AccountPermissionSet entitlements as cloud-enabled.')
        $situation.Add('Some CloudTrail events omit the Resource attribute; last-activity detail may be incomplete in certifications.')

        Write-ConnectionSettings -Fields $ciemSettings.Fields -Title 'CIEM AWS source Connection Settings' -Path $settingsOutput.FilePath

        $completionItems = @(
            [PSCustomObject]@{ Label = 'Role ARN'; Value = $ciemResult.RoleArn; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'External ID'; Value = $ciemResult.ExternalId; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'CloudTrail ARN(s)'; Value = $cloudTrailList; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'CloudTrail bucket account ID'; Value = $session.Account; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'Single Account'; Value = $(if ($ciemResult.SingleAccount) { 'Yes' } else { 'No' }); Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'Provision Identity Center'; Value = $(if ($ciemResult.ProvisionIdentityCenter) { 'Yes' } else { 'No' }); Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'IAM role in AWS console'; Value = $roleUrl; Kind = 'Open'; Mask = $false }
            [PSCustomObject]@{ Label = 'CloudFormation console'; Value = $cfnUrl; Kind = 'Open'; Mask = $false }
            [PSCustomObject]@{ Label = 'Connecting AWS and SailPoint CIEM'; Value = $ciemDocUrl; Kind = 'Open'; Mask = $false }
        )

        Invoke-CompletionActionMenu -Title 'Next: complete CIEM AWS Connection Settings' `
            -Situation $situation.ToArray() `
            -Items $completionItems `
            -AllowSaveToDisk `
            -SavePath $settingsOutput.FilePath
        return
    }

    $action = if ($isUpdate) { "Update IAM role '$RoleName'" } else { "Create IAM role '$RoleName'" }
    if (-not $PSCmdlet.ShouldProcess($RoleName, $action)) { return }

    $targets = [System.Collections.Generic.List[pscustomobject]]::new()
    $targets.Add([PSCustomObject]@{ AccountId = $session.Account; Credential = $null; Label = 'management / current' })
    $skippedMemberAccounts = [System.Collections.Generic.List[string]]::new()

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

    $embeddedCiemFields = [ordered]@{}
    $saasCloudTrailList = ''
    if ($saasCiem) {
        $ciemCtx = [PSCustomObject]@{
            FeatureNames              = $Feature
            CloudTrailBucket          = $CloudTrailBucket
            CloudTrailBucketAccountId = $CloudTrailBucketAccountId
            SessionAccountId          = $session.Account
            Region                    = $Region
            CloudTrailArn             = $CloudTrailArn
            SkipCloudTrailDiscovery   = $saasCiemTrailCreated
        }
        $embeddedCiemFields = Build-EmbeddedCiemConnectionSettings -Context $ciemCtx
        $saasCloudTrailList = [string]$embeddedCiemFields['CloudTrail ARN(s)']
        $situation.Add('In ISC Additional Settings: enable Cloud Infrastructure Entitlement Management (CIEM), then paste CloudTrail ARN(s) and the CloudTrail Bucket Account ID.')
        $situation.Add('Do not enable CIEM on this AWS SaaS source if you also use a dedicated CIEM AWS source for the same management account.')
        $situation.Add('After a successful test connection, mark Groups, AWSManagedPolicy, CustomerManagedPolicy, and InlinePolicy entitlements as cloud-enabled.')
    }
    $situation.Add('This source governs IAM users only. To govern Identity Center users and permission sets, run this script again with -SourceType CiemAws and connect a CIEM AWS source.')

    $fields = [ordered]@{
        'Role Name' = $RoleName
        'Region' = $Region
        'External ID' = $ExternalId
        'Management Account ID' = $managementAccountId
    }
    if ($cloudScopeIds) {
        $fields['AWS Accounts (Cloud Scope)'] = $cloudScopeIds
    }
    if ($saasCiem) {
        foreach ($entry in $embeddedCiemFields.GetEnumerator()) {
            $fields[$entry.Key] = $entry.Value
        }
    }
    $settingsPath = $settingsOutput.FilePath
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $completionItems = @(
        [PSCustomObject]@{ Label = 'Role Name'; Value = $RoleName; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Region'; Value = $Region; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'External ID'; Value = $ExternalId; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Management Account ID'; Value = $managementAccountId; Kind = 'Copy'; Mask = $false }
    )
    if ($cloudScopeIds) {
        $completionItems += [PSCustomObject]@{ Label = 'AWS Accounts (Cloud Scope)'; Value = $cloudScopeIds; Kind = 'Copy'; Mask = $false }
    }
    if ($saasCiem) {
        $ciemSettingsUrl = 'https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/ciem_settings.html'
        $completionItems += @(
            [PSCustomObject]@{ Label = 'Enable CIEM'; Value = 'Yes'; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'CloudTrail ARN(s)'; Value = $saasCloudTrailList; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'CloudTrail bucket account ID'; Value = $CloudTrailBucketAccountId; Kind = 'Copy'; Mask = $false }
            [PSCustomObject]@{ Label = 'CIEM Settings (AWS SaaS)'; Value = $ciemSettingsUrl; Kind = 'Open'; Mask = $false }
        )
    }
    $completionItems += @(
        [PSCustomObject]@{ Label = 'IAM role in AWS console'; Value = $roleUrl; Kind = 'Open'; Mask = $false }
        [PSCustomObject]@{ Label = 'AWS Organizations console'; Value = $orgUrl; Kind = 'Open'; Mask = $false }
    )

    Invoke-CompletionActionMenu -Title 'Next: complete ISC Connection Settings' `
        -Situation $situation.ToArray() `
        -Items $completionItems `
        -AllowSaveToDisk `
        -SavePath $settingsPath
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    if (Get-AwsCreatedRoleArn) {
        Write-Warning "Role $(Get-AwsCreatedRoleArn) was created before this failure. Re-run the script with the same role name to finish configuring it."
    }
    Write-Error $_
    exit 1
}
