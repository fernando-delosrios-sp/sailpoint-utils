#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-AwsSaasConnectorData {
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

$script:BedrockAgentDiscoveryActions = @(
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
)

$script:AgentCoreDiscoveryActions = @(
    'bedrock-agentcore:ListAgentRuntimes'
    'bedrock-agentcore:GetAgentRuntime'
    'bedrock-agentcore:ListAgentRuntimeEndpoints'
    'bedrock-agentcore:GetAgentRuntimeEndpoint'
    'bedrock-agentcore:ListAgentRuntimeVersions'
    'bedrock-agentcore:ListGateways'
    'bedrock-agentcore:GetGateway'
    'bedrock-agentcore:ListGatewayTargets'
    'bedrock-agentcore:GetGatewayTarget'
    'bedrock-agentcore:ListWorkloadIdentities'
    'bedrock-agentcore:GetWorkloadIdentity'
    'bedrock-agentcore:ListOauth2CredentialProviders'
    'bedrock-agentcore:GetApiKeyCredentialProvider'
    'bedrock-agentcore:ListApiKeyCredentialProviders'
    'bedrock-agentcore:GetOauth2CredentialProvider'
)

$script:ConnectCustomerAgentDiscoveryActions = @(
    'connect:ListInstances'
    'connect:DescribeInstance'
    'connect:ListBots'
    'connect:ListLexBots'
    'lex:ListBots'
    'lex:GetBot'
    'lex:DescribeBotAlias'
    'lex:ListBotAliases'
)

$script:AgentDiscoveryActions = @(
    $script:BedrockAgentDiscoveryActions +
    $script:AgentCoreDiscoveryActions +
    $script:ConnectCustomerAgentDiscoveryActions
)

$script:FeaturePacks = [ordered]@{
    ActivityInsights = @{
        Label       = 'Activity Insights - CloudTrail event lookup'
        PolicyName  = 'SPActivityInsightsPolicy'
        Actions     = $script:ActivityInsightsActions
    }
    Ciem = @{
        Label      = 'CIEM - Enable Cloud Infrastructure Entitlement Management, inventory and effective access'
        PolicyName = 'SPCiemPolicy'
    }
    AgentDiscovery = @{
        Label       = 'Machine identity - Bedrock, AgentCore, and Connect Customer agents'
        PolicyName  = 'SPAgentDiscoveryPolicy'
        Actions     = $script:AgentDiscoveryActions
    }
}

# SPIdentityCenter* are no longer produced: Identity Center belongs to the CIEM AWS source, not the
# SaaS source. They stay listed so runs detach what earlier versions attached to the SaaS role.
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
        if ($name -in @('IdentityCenter', 'IdentityCenterProvisioning')) {
            Write-Warning "$name is not an AWS SaaS feature. Identity Center is governed by a CIEM AWS source (-SourceType CiemAws); ignoring it here."
            continue
        }
        if (-not $script:FeaturePacks.Contains($name)) {
            throw "Unknown AWS SaaS feature pack '$name'. Valid packs: $($script:FeaturePacks.Keys -join ', ')."
        }
        $pack = $script:FeaturePacks[$name]
        if ($name -eq 'Ciem') {
            $docs[$pack.PolicyName] = New-StarPolicyDocument -Actions (Get-CiemPolicyActions)
        }
        else {
            $docs[$pack.PolicyName] = New-StarPolicyDocument -Actions $pack.Actions
        }
    }

    if ($BucketName) {
        $docs['SPCloudTrailBucketPolicy'] = New-CloudTrailBucketPolicyDocument -BucketName $BucketName -Partition $Partition
    }

    return $docs
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
        Set-AwsCreatedRoleArn -Arn $role.Arn
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



function Get-AwsSaasCatalog {
    return [PSCustomObject]@{
        FeaturePacks       = $script:FeaturePacks
        ManagedPolicyNames = $script:ManagedPolicyNames
    }
}

function Test-SailPointRoleConfiguration {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$ExpectedPrincipal,
        [Parameter(Mandatory)][string]$ExpectedExternalId,
        $AwsParams
    )

    $role = Get-IAMRole @AwsParams -RoleName $Name
    $trust = ConvertFrom-IamPolicyDocument -Document $role.AssumeRolePolicyDocument
    $statement = @($trust.Statement | Where-Object { $_.Effect -eq 'Allow' } | Select-Object -First 1)
    if (-not $statement) {
        throw "Role $Name has no Allow statement in its trust policy."
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
            Write-Warning "Trust policy on $Name does not include principal $expected."
        }
    }

    $externalId = $statement.Condition.StringEquals.'sts:ExternalId'
    if ($externalId -ne $ExpectedExternalId) {
        throw "Role $Name trust policy ExternalId mismatch. Expected '$ExpectedExternalId', got '$externalId'."
    }

    Write-Ok "Verified trust policy on $Name (External ID and principals)."
}

Export-ModuleMember -Function @(
    'Initialize-AwsSaasConnectorData',
    'Get-SelectedPolicyDocuments',
    'Get-LocalPolicyByName',
    'Set-CustomerManagedPolicy',
    'Set-SailPointIamRole',
    'Test-SailPointRoleConfiguration',
    'Get-AwsSaasCatalog'
)
