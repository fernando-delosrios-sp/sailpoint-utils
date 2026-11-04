#Requires -Version 5.1
Set-StrictMode -Version Latest

function Import-SourceSetupModule {
    param(
        [Parameter(Mandatory)][string]$ModuleRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FileName
    )

    if (-not (Get-Module -Name $Name)) {
        Import-Module (Join-Path $ModuleRoot $FileName) -Force -Global -WarningAction SilentlyContinue
    }
}

function Import-AgentAdapterModule {
    if (-not (Get-Module -Name 'ISC.AgentAdapter')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.AgentAdapter.psm1') -Force -WarningAction SilentlyContinue
    }
}

function Initialize-AwsSourceSetup {
    param(
        [string]$ModuleRoot,
        [switch]$NonInteractive
    )

    if (-not $ModuleRoot) { $ModuleRoot = $PSScriptRoot }
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorConsole' -FileName 'ISC.OperatorConsole.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorToolchain' -FileName 'ISC.OperatorToolchain.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.AwsConnector' -FileName 'ISC.AwsConnector.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.AwsCiemConnector' -FileName 'ISC.AwsCiemConnector.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.AwsSaasConnector' -FileName 'ISC.AwsSaasConnector.psm1'
    Initialize-OperatorConsole -NonInteractive:$NonInteractive
    Initialize-AwsConnectorData
    Initialize-AwsCiemConnectorData
    Initialize-AwsSaasConnectorData
}

function Get-AwsAgentCatalog {
    param([Parameter(Mandatory)][ValidateSet('aws-saas', 'aws-ciem')][string]$Variant)

    Initialize-AwsSourceSetup
    if ($Variant -eq 'aws-saas') {
        $catalog = Get-AwsSaasCatalog
        return [ordered]@{
            variant        = $Variant
            featurePacks   = @($catalog.FeaturePacks.Keys)
            policySets     = @('Mgo', 'NonMgo')
            scopes         = @('CurrentAccount', 'Organization')
            requiredConfig = @('externalId')
            optionalConfig = @('profileName', 'region', 'cloud', 'roleName', 'features', 'scope', 'cloudTrailBucket')
        }
    }

    return [ordered]@{
        variant        = $Variant
        ciemActivities = @('None', 'OrganizationManagement', 'ExistingCloudTrail', 'NewCloudTrailExistingBucket', 'NewCloudTrailAndBucket')
        scopes         = @('CurrentAccount', 'Organization')
        requiredConfig = @('externalId', 'cloudTrailBucket')
        optionalConfig = @('profileName', 'region', 'cloud', 'roleName', 'ciemActivity', 'scope')
    }
}

function Get-AwsResolvedConfig {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)][string]$Variant
    )

    Import-AgentAdapterModule
    $config = Get-AgentRequestValue -Object $Request -Name 'config' -Default @{}
    $decisions = Get-AgentRequestValue -Object $Request -Name 'decisions' -Default @{}
    $sourceType = if ($Variant -eq 'aws-ciem') { 'CiemAws' } else { 'AwsSaas' }
    $roleDefault = if ($sourceType -eq 'CiemAws') { Get-DefaultCiemRoleName } else { Get-DefaultSaasRoleName }
    $outputDir = Get-AgentRequestValue -Object $config -Name 'outputDirectory'
    $output = Get-ConnectionSettingsOutput -Type $sourceType -Directory $outputDir

    return [PSCustomObject]@{
        SourceType                = $sourceType
        ProfileName               = $(if (Get-AgentRequestValue -Object $config -Name 'profileName') { [string](Get-AgentRequestValue -Object $config -Name 'profileName') } else { $null })
        Region                    = if (Get-AgentRequestValue -Object $config -Name 'region') { [string](Get-AgentRequestValue -Object $config -Name 'region') } else { 'us-east-1' }
        Cloud                     = if (Get-AgentRequestValue -Object $config -Name 'cloud') { [string](Get-AgentRequestValue -Object $config -Name 'cloud') } else { 'Commercial' }
        TrustPrincipal            = @($(Get-AgentRequestValue -Object $config -Name 'trustPrincipal' -Default @()))
        RoleName                  = if (Get-AgentRequestValue -Object $config -Name 'roleName') { [string](Get-AgentRequestValue -Object $config -Name 'roleName') } else { $roleDefault }
        ExternalId                = [string](Get-AgentRequestValue -Object $config -Name 'externalId')
        PolicySet                 = if (Get-AgentRequestValue -Object $config -Name 'policySet') { [string](Get-AgentRequestValue -Object $config -Name 'policySet') } else { 'Mgo' }
        Feature                   = @($(Get-AgentRequestValue -Object $config -Name 'features' -Default @()))
        AggregationOnly           = [bool](Get-AgentRequestValue -Object $config -Name 'aggregationOnly' -Default $false)
        CloudTrailBucket          = $(if (Get-AgentRequestValue -Object $config -Name 'cloudTrailBucket') { [string](Get-AgentRequestValue -Object $config -Name 'cloudTrailBucket') } else { $null })
        CloudTrailBucketAccountId = $(if (Get-AgentRequestValue -Object $config -Name 'cloudTrailBucketAccountId') { [string](Get-AgentRequestValue -Object $config -Name 'cloudTrailBucketAccountId') } else { $null })
        CloudTrailArn             = @($(Get-AgentRequestValue -Object $config -Name 'cloudTrailArn' -Default @()))
        Scope                     = if (Get-AgentRequestValue -Object $config -Name 'scope') { [string](Get-AgentRequestValue -Object $config -Name 'scope') } else { 'CurrentAccount' }
        MemberAssumeRole          = $(if (Get-AgentRequestValue -Object $config -Name 'memberAssumeRole') { [string](Get-AgentRequestValue -Object $config -Name 'memberAssumeRole') } else { $null })
        CiemActivity              = if (Get-AgentRequestValue -Object $config -Name 'ciemActivity') { [string](Get-AgentRequestValue -Object $config -Name 'ciemActivity') } else { 'None' }
        EnableIdentityStoreReadOnly = if (Get-AgentRequestValue -Object $config -Name 'enableIdentityStoreReadOnly') { [string](Get-AgentRequestValue -Object $config -Name 'enableIdentityStoreReadOnly') } else { 'true' }
        EnableIdentityStoreProvision = if (Get-AgentRequestValue -Object $config -Name 'enableIdentityStoreProvision') { [string](Get-AgentRequestValue -Object $config -Name 'enableIdentityStoreProvision') } else { 'true' }
        TrailName                 = if (Get-AgentRequestValue -Object $config -Name 'trailName') { [string](Get-AgentRequestValue -Object $config -Name 'trailName') } else { 'sailpoint-ciem-cloud-trail' }
        InventoryStackName        = if (Get-AgentRequestValue -Object $config -Name 'inventoryStackName') { [string](Get-AgentRequestValue -Object $config -Name 'inventoryStackName') } else { 'SailPointCiemInventory' }
        ActivityStackName         = if (Get-AgentRequestValue -Object $config -Name 'activityStackName') { [string](Get-AgentRequestValue -Object $config -Name 'activityStackName') } else { 'SailPointCiemActivity' }
        OutputDirectory           = $output.Directory
        SettingsPath              = $output.FilePath
        UpdateExistingRole        = $(if ($null -ne (Get-AgentRequestValue -Object $decisions -Name 'updateExistingRole')) { [bool](Get-AgentRequestValue -Object $decisions -Name 'updateExistingRole') } else { $null })
        ApproveOrganizationScope  = [bool](Get-AgentRequestValue -Object $decisions -Name 'approveOrganizationScope' -Default $false)
    }
}

function New-AwsAgentPlan {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)][ValidateSet('aws-saas', 'aws-ciem')][string]$Variant
    )

    Initialize-AwsSourceSetup
    $resolved = Get-AwsResolvedConfig -Request $Request -Variant $Variant
    $needsInput = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $discoveries = [ordered]@{}

    if ([string]::IsNullOrWhiteSpace($resolved.ExternalId)) {
        $needsInput.Add([ordered]@{ field = 'externalId'; reason = 'External ID from ISC Connection Settings is required.' })
    }
    if ($Variant -eq 'aws-ciem' -and [string]::IsNullOrWhiteSpace($resolved.CloudTrailBucket)) {
        $needsInput.Add([ordered]@{ field = 'cloudTrailBucket'; reason = 'CIEM AWS source requires a CloudTrail bucket name.' })
    }
    if ($resolved.Scope -eq 'Organization' -and -not $resolved.ApproveOrganizationScope) {
        $needsInput.Add([ordered]@{ field = 'decisions.approveOrganizationScope'; reason = 'Organization-wide deployment requires explicit approval.' })
    }
    if ($Variant -eq 'aws-saas' -and @($resolved.Feature) -contains 'Ciem' -and [string]::IsNullOrWhiteSpace($resolved.CloudTrailBucket)) {
        $needsInput.Add([ordered]@{ field = 'cloudTrailBucket'; reason = 'AWS SaaS CIEM feature requires CloudTrail bucket name.' })
    }
    $identityCenterFeatures = @(@($resolved.Feature) | Where-Object { $_ -in @('IdentityCenter', 'IdentityCenterProvisioning') })
    if ($Variant -eq 'aws-saas' -and $identityCenterFeatures.Count -gt 0) {
        $warnings.Add("Ignoring $($identityCenterFeatures -join ', '): Identity Center is governed by a CIEM AWS source (variant aws-ciem), not the AWS SaaS source.")
    }

    try {
        Ensure-AwsToolsModules
        if ($Variant -eq 'aws-ciem') {
            Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.CloudFormation', 'AWS.Tools.CloudTrail', 'AWS.Tools.EC2', 'AWS.Tools.S3')
        }
        $session = Connect-AwsSession -RequestedProfile $resolved.ProfileName -RequestedRegion $resolved.Region
        $discoveries.accountId = $session.Account
        $discoveries.arn = $session.Arn
        $awsParams = Get-IamCmdletParams -RegionName $resolved.Region
        try {
            $existingRole = Get-IAMRole @awsParams -RoleName $resolved.RoleName
            $discoveries.existingRoleArn = $existingRole.Arn
            if ($null -eq $resolved.UpdateExistingRole) {
                $needsInput.Add([ordered]@{
                    field  = 'decisions.updateExistingRole'
                    reason = "IAM role '$($resolved.RoleName)' already exists."
                    options = @(
                        [ordered]@{ value = $true; label = 'Update existing role' }
                        [ordered]@{ value = $false; label = 'Abort and choose a different role name' }
                    )
                })
            }
        }
        catch {
            if ($_.Exception.Message -notmatch 'NoSuchEntity|cannot be found') {
                $warnings.Add("Role discovery failed: $($_.Exception.Message)")
            }
        }
        $orgContext = Get-AwsOrganizationContext -CurrentAccountId $session.Account -AwsParams $awsParams
        $discoveries.organization = $orgContext
    }
    catch {
        $warnings.Add("Live discovery skipped: $($_.Exception.Message)")
    }

    $mutations = if ($Variant -eq 'aws-ciem') {
        @('connect-aws', 'deploy-ciem-cloudformation', 'sync-ciem-trust')
    } else {
        @('connect-aws', 'deploy-iam-role', 'verify-role-trust')
    }

    return [ordered]@{
        status      = if ($needsInput.Count -gt 0) { 'needsInput' } else { 'ready' }
        requestHash = (Get-AgentRequestHash -Request $Request)
        resolved    = $resolved
        discoveries = $discoveries
        mutations   = $mutations
        prerequisites = @('AWS Tools for PowerShell', 'IAM permissions in target account')
        warnings    = @($warnings)
        manualSteps = @('Paste connection settings into ISC after Apply.')
        needsInput  = @($needsInput)
    }
}

function Invoke-AwsSaasSourceApply {
    param(
        [Parameter(Mandatory)]$Resolved,
        [switch]$WhatIf
    )

    $trustConfig = Get-SailPointTrustConfig -Cloud $Resolved.Cloud
    $partition = $trustConfig.Partition
    $principals = if ($Resolved.TrustPrincipal.Count -gt 0) {
        @(Resolve-TrustPrincipal -Value $Resolved.TrustPrincipal -Partition $partition)
    } else {
        @($trustConfig.Principals)
    }
    $allowTagSession = @($Resolved.Feature) -contains 'ActivityInsights'
    $trustDoc = New-TrustPolicyDocument -PrincipalArn $principals -ExternalIdValue $Resolved.ExternalId -AllowTagSession:$allowTagSession
    $policyDocs = Get-SelectedPolicyDocuments -Set $Resolved.PolicySet -FeatureNames $Resolved.Feature `
        -SkipProvisioning:$Resolved.AggregationOnly -BucketName $Resolved.CloudTrailBucket -Partition $partition
    $session = Connect-AwsSession -RequestedProfile $Resolved.ProfileName -RequestedRegion $Resolved.Region
    $awsParams = Get-IamCmdletParams -RegionName $Resolved.Region

    if ($WhatIf) {
        return [ordered]@{ status = 'whatIf'; roleName = $Resolved.RoleName; accountId = $session.Account }
    }

    $arn = Set-SailPointIamRole -Name $Resolved.RoleName -TrustDocument $trustDoc -PolicyDocuments $policyDocs `
        -AccountId $session.Account -Partition $partition -AwsParams $awsParams
    Test-SailPointRoleConfiguration -Name $Resolved.RoleName -ExpectedPrincipal $principals `
        -ExpectedExternalId $Resolved.ExternalId -AwsParams $awsParams

    $orgContext = Get-AwsOrganizationContext -CurrentAccountId $session.Account -AwsParams $awsParams
    $managementAccountId = if ($orgContext.MasterAccountId) { $orgContext.MasterAccountId } else { $session.Account }
    $fields = [ordered]@{
        'Role Name'             = $Resolved.RoleName
        'Region'                = $Resolved.Region
        'External ID'           = $Resolved.ExternalId
        'Management Account ID' = $managementAccountId
    }
    if ($orgContext.AccountIds.Count -gt 0) {
        $fields['AWS Accounts (Cloud Scope)'] = ($orgContext.AccountIds -join ', ')
    }

    if (-not (Test-Path -LiteralPath $Resolved.OutputDirectory)) {
        New-Item -ItemType Directory -Path $Resolved.OutputDirectory -Force | Out-Null
    }
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $Resolved.SettingsPath

    return [ordered]@{
        status             = 'ok'
        connectionSettings = $fields
        artifacts          = @([ordered]@{ label = 'Connection settings'; path = $Resolved.SettingsPath })
        secretArtifacts    = @()
        verification       = [ordered]@{ roleArn = $arn; externalId = $Resolved.ExternalId }
        situation          = @('AWS IAM setup is complete. Paste Connection Settings into ISC.')
    }
}

function Invoke-AwsCiemSourceApply {
    param(
        [Parameter(Mandatory)]$Resolved,
        [switch]$WhatIf
    )

    if ($WhatIf) {
        return [ordered]@{ status = 'whatIf'; roleName = $Resolved.RoleName; bucket = $Resolved.CloudTrailBucket }
    }

    $session = Connect-AwsSession -RequestedProfile $Resolved.ProfileName -RequestedRegion $Resolved.Region
    $awsParams = Get-IamCmdletParams -RegionName $Resolved.Region
    $orgContext = Get-AwsOrganizationContext -CurrentAccountId $session.Account -AwsParams $awsParams
    $managementAccountId = if ($orgContext.MasterAccountId) { $orgContext.MasterAccountId } else { $session.Account }
    $identityCenterRequested = $Resolved.Scope -eq 'Organization'
    $deployment = Apply-DedicatedCiemSourceDeployment -Cloud $Resolved.Cloud -RegionName $Resolved.Region -Scope $Resolved.Scope `
        -RoleName $Resolved.RoleName -ExternalId $Resolved.ExternalId -BucketName $Resolved.CloudTrailBucket `
        -ActivityMode $Resolved.CiemActivity -InventoryStackName $Resolved.InventoryStackName `
        -ActivityStackName $Resolved.ActivityStackName -TrailNameValue $Resolved.TrailName `
        -EnableIdentityStoreReadOnlyFlag $Resolved.EnableIdentityStoreReadOnly `
        -EnableIdentityStoreProvisionFlag $Resolved.EnableIdentityStoreProvision `
        -ExtraCloudTrailArn $Resolved.CloudTrailArn -TrustPrincipalList $Resolved.TrustPrincipal `
        -AwsParams $awsParams -CurrentAccountId $session.Account -ManagementAccountId $managementAccountId `
        -IdentityCenterRequested:$identityCenterRequested

    $settings = Build-DedicatedCiemConnectionSettings -DeploymentResult $deployment -SessionAccountId $session.Account
    if (-not (Test-Path -LiteralPath $Resolved.OutputDirectory)) {
        New-Item -ItemType Directory -Path $Resolved.OutputDirectory -Force | Out-Null
    }
    Write-ConnectionSettings -Fields $settings.Fields -Title 'CIEM AWS source Connection Settings' -Path $Resolved.SettingsPath

    return [ordered]@{
        status             = 'ok'
        connectionSettings = $settings.Fields
        artifacts          = @([ordered]@{ label = 'Connection settings'; path = $Resolved.SettingsPath })
        secretArtifacts    = @()
        verification       = [ordered]@{ roleArn = $deployment.RoleArn; externalId = $deployment.ExternalId }
        situation          = @('CIEM AWS deployment is complete. Paste Connection Settings into ISC.')
    }
}

function Invoke-AwsAgentApply {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][ValidateSet('aws-saas', 'aws-ciem')][string]$Variant,
        [switch]$WhatIf
    )

    Initialize-AwsSourceSetup
    Ensure-AwsToolsModules
    if ($Variant -eq 'aws-ciem') {
        Ensure-AwsToolsModules -ExtraModules @('AWS.Tools.CloudFormation', 'AWS.Tools.CloudTrail', 'AWS.Tools.EC2', 'AWS.Tools.S3')
    }

    $resolved = Get-AwsResolvedConfig -Request $Request -Variant $Variant
    if ($Plan.resolved) {
        foreach ($prop in $Plan.resolved.PSObject.Properties) {
            $resolved.$($prop.Name) = $prop.Value
        }
    }

    if ($Variant -eq 'aws-ciem') {
        return Invoke-AwsCiemSourceApply -Resolved $resolved -WhatIf:$WhatIf
    }
    return Invoke-AwsSaasSourceApply -Resolved $resolved -WhatIf:$WhatIf
}

Export-ModuleMember -Function @(
    'Initialize-AwsSourceSetup'
    'Get-AwsAgentCatalog'
    'Get-AwsResolvedConfig'
    'New-AwsAgentPlan'
    'Invoke-AwsSaasSourceApply'
    'Invoke-AwsCiemSourceApply'
    'Invoke-AwsAgentApply'
)
