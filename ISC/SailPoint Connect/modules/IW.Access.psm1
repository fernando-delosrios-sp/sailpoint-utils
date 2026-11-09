#Requires -Version 7
Set-StrictMode -Version Latest

function Get-RequirementAccessClass {
    param(
        [Parameter(Mandatory)]
        [string]$Kind,
        [Parameter(Mandatory)]
        [string]$Name
    )

    switch ($Kind) {
        'MicrosoftGraphPermission' { return Get-GraphPermissionAccessClass -Permission $Name }
        'GoogleOAuthScope' { return Get-GoogleOAuthScopeAccessClass -Scope $Name }
        'GoogleIamPermission' { return Get-GoogleIamPermissionAccessClass -Permission $Name }
        'AwsAction' { return Get-AwsActionAccessClass -Action $Name }
        'AwsIamRole' { return 'ReadOnly' }
        'EntroGcpCustomPermission' {
            if ($Name -match '^logging\.queries\.(create|delete|update)$') { return 'ReadWrite' }
            return Get-GoogleIamPermissionAccessClass -Permission $Name
        }
        default { throw "Unknown requirement kind: $Kind" }
    }
}

function Get-GraphPermissionAccessClass {
    param([Parameter(Mandatory)][string]$Permission)

    if ($Permission -eq 'user_impersonation') { return 'ReadWrite' }
    if ($Permission -eq 'offline_access') { return 'ReadOnly' }
    if ($Permission -eq 'User.Read') { return 'ReadOnly' }
    if ($Permission -match 'ReadWrite|\.Write\.|Invite\.|EnableDisable|ManageAsApp') { return 'ReadWrite' }
    if ($Permission -match '\.Read\.|Read\.All|Read\.Directory|AuditLog\.Read') { return 'ReadOnly' }
    return 'ReadWrite'
}

function Get-GoogleOAuthScopeAccessClass {
    param([Parameter(Mandatory)][string]$Scope)

    if ($Scope -match '\.readonly$') { return 'ReadOnly' }
    if ($Scope -match 'admin\.directory\.(user|group)(/|$)' -and $Scope -notmatch '\.readonly') { return 'ReadWrite' }
    if ($Scope -match 'admin\.directory\.rolemanagement$') { return 'ReadWrite' }
    if ($Scope -match 'apps\.groups\.settings|gmail\.settings\.|gmail\.modify|mail\.google\.com') { return 'ReadWrite' }
    if ($Scope -match 'admin\.directory\.domain') { return 'ReadWrite' }
    if ($Scope -match 'cloud-platform|/auth/iam') { return 'ReadOnly' }
    if ($Scope -match 'admin\.reports\.') { return 'ReadOnly' }
    return 'ReadWrite'
}

function Get-GoogleIamPermissionAccessClass {
    param([Parameter(Mandatory)][string]$Permission)

    $last = ($Permission -split '\.')[-1]
    switch ($last) {
        { $_ -in @('create', 'delete', 'update', 'setIamPolicy') } { return 'ReadWrite' }
        default { return 'ReadOnly' }
    }
}

function Get-AwsActionAccessClass {
    param([Parameter(Mandatory)][string]$Action)

    if ($Action -eq 'kms:GenerateDataKey') { return 'ReadWrite' }
    if ($Action -match ':Simulate|:GenerateCredentialReport|:GenerateServiceLastAccessedDetails') { return 'ReadOnly' }
    if ($Action -match ':Create|:Delete|:Update|:Put|:Attach|:Detach|:Add|:Remove|:Provision') { return 'ReadWrite' }
    if ($Action -match ':Get|:List|:Describe|:Lookup') { return 'ReadOnly' }
    return 'ReadOnly'
}

function Test-RequirementIncludedForAccess {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Name,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access
    )

    if ($Access -eq 'ReadWrite') { return $true }
    return (Get-RequirementAccessClass -Kind $Kind -Name $Name) -eq 'ReadOnly'
}

function ConvertTo-ReadOnlyGoogleOAuthScope {
    param([Parameter(Mandatory)][string]$Scope)

    switch -Regex ($Scope) {
        '^https://www\.googleapis\.com/auth/admin\.directory\.user$' {
            return 'https://www.googleapis.com/auth/admin.directory.user.readonly'
        }
        '^https://www\.googleapis\.com/auth/admin\.directory\.group$' {
            return 'https://www.googleapis.com/auth/admin.directory.group.readonly'
        }
        '^https://www\.googleapis\.com/auth/admin\.directory\.rolemanagement$' {
            return $null
        }
        default { return $Scope }
    }
}

function Filter-PermissionsForAccess {
    param(
        [Parameter(Mandatory)][object[]]$Permissions,
        [string]$Access,
        [Parameter(Mandatory)][string]$Kind
    )

    if ([string]::IsNullOrWhiteSpace($Access) -or $Access -eq 'ReadWrite') {
        return @($Permissions)
    }
    $filtered = @($Permissions | Where-Object {
        $value = if ($_.Value) { [string]$_.Value } else { [string]$_ }
        Test-RequirementIncludedForAccess -Kind $Kind -Name $value -Access 'ReadOnly'
    })
    return $filtered
}

function Get-EntroGcpPinnedCustomRolePermissions {
    return @(
        'logging.buckets.get', 'logging.buckets.list', 'logging.exclusions.get', 'logging.exclusions.list'
        'logging.links.get', 'logging.links.list', 'logging.locations.get', 'logging.locations.list'
        'logging.logEntries.download', 'logging.logEntries.list', 'logging.logMetrics.get', 'logging.logMetrics.list'
        'logging.logServiceIndexes.list', 'logging.logServices.list', 'logging.logs.list'
        'logging.operations.get', 'logging.operations.list', 'logging.privateLogEntries.list'
        'logging.queries.create', 'logging.queries.delete', 'logging.queries.get', 'logging.queries.list'
        'logging.queries.listShared', 'logging.queries.update', 'logging.sinks.get', 'logging.sinks.list'
        'logging.usage.get', 'logging.views.access', 'logging.views.get', 'logging.views.list'
        'logging.views.listLogs', 'logging.views.listResourceKeys', 'logging.views.listResourceValues'
        'resourcemanager.organizations.get', 'secretmanager.versions.access', 'secretmanager.secrets.list'
        'secretmanager.versions.list', 'secretmanager.locations.list', 'secretmanager.secrets.getIamPolicy'
        'iam.serviceAccounts.list', 'iam.serviceAccounts.get', 'iam.serviceAccounts.getIamPolicy'
        'iam.serviceAccountKeys.get', 'iam.serviceAccountKeys.list', 'iam.roles.get'
        'cloudfunctions.functions.get', 'cloudfunctions.functions.list', 'cloudbuild.builds.get'
        'cloudbuild.builds.list', 'cloudbuild.operations.get', 'cloudbuild.operations.list'
        'recommender.iamPolicyInsights.get', 'recommender.iamPolicyInsights.list'
        'recommender.iamPolicyLateralMovementInsights.get', 'recommender.iamPolicyLateralMovementInsights.list'
        'recommender.iamPolicyRecommendations.get', 'recommender.iamPolicyRecommendations.list'
        'recommender.iamPolicyRecommenderConfig.get', 'recommender.iamServiceAccountInsights.get'
        'recommender.iamServiceAccountInsights.list', 'recommender.locations.get', 'recommender.locations.list'
        'recommender.cloudAssetInsights.get', 'recommender.cloudAssetInsights.list'
        'resourcemanager.projects.get', 'resourcemanager.projects.list'
        'cloudasset.assets.listResource', 'cloudasset.assets.listIamPolicy', 'cloudasset.assets.listOrgPolicy'
        'cloudasset.assets.listAccessPolicy', 'cloudasset.assets.listOSInventories'
        'policyanalyzer.serviceAccountKeyLastAuthenticationActivities.query'
        'policyanalyzer.serviceAccountLastAuthenticationActivities.query'
        'serviceusage.quotas.get', 'serviceusage.services.get', 'serviceusage.services.list'
        'iam.roles.list', 'resourcemanager.organizations.getIamPolicy', 'resourcemanager.projects.getIamPolicy'
        'resourcemanager.folders.getIamPolicy', 'resourcemanager.folders.get'
    )
}

function Get-ContextFeatureNames {
    param([hashtable]$Context)
    if (-not $Context.ContainsKey('Feature') -or $null -eq $Context['Feature']) { return ,@() }
    $f = $Context['Feature']
    if ($f -is [array]) { return ,@($f | ForEach-Object { [string]$_ } | Where-Object { $_ }) }
    return ,@([string]$f -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Split-RequirementsByAccessClass {
    param(
        [Parameter(Mandatory)][string[]]$Names,
        [Parameter(Mandatory)][string]$Kind
    )
    $readOnly = [System.Collections.Generic.List[string]]::new()
    $readWrite = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @($Names | Sort-Object -Unique)) {
        if ((Get-RequirementAccessClass -Kind $Kind -Name $name) -eq 'ReadWrite') {
            $readWrite.Add($name)
        }
        else {
            $readOnly.Add($name)
        }
    }
    return @{ ReadOnly = $readOnly.ToArray(); ReadWrite = $readWrite.ToArray() }
}

function Get-IntegrationWizardAccessRequirementLists {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )

    $moduleRoot = $PSScriptRoot
    $access = if ($Context.ContainsKey('Access')) { [string]$Context['Access'] } else { '' }
    $readOnly = [System.Collections.Generic.List[string]]::new()
    $readWrite = [System.Collections.Generic.List[string]]::new()

    $targets = if ($Definition['IsComposite']) { @($Definition.Members) } else { @($Definition) }
    foreach ($def in $targets) {
        $id = [string]$def.Id
        switch -Regex ($id) {
            '^azure-connector$' {
                Import-Module (Join-Path $moduleRoot 'ISC.EntraConnector.psm1') -Force -WarningAction SilentlyContinue
                Import-Module (Join-Path $moduleRoot 'ISC.EntraCiemConnector.psm1') -Force -WarningAction SilentlyContinue
                Initialize-EntraConnectorData
                Initialize-EntraCiemConnectorData
                $mode = if ($access -eq 'ReadWrite' -and $Context['PermissionMode']) { $Context['PermissionMode'] } else { 'Granular' }
                $features = Get-ContextFeatureNames -Context $Context
                $app = @(Get-SelectedPermissions -Mode $mode -FeatureNames $features -Access $access)
                $deleg = @(Get-SelectedDelegatedPermissions -FeatureNames $features -Access $access)
                foreach ($p in @($app + $deleg)) {
                    $line = "$($p.Resource): $($p.Value)"
                    if ((Get-RequirementAccessClass -Kind 'MicrosoftGraphPermission' -Name $p.Value) -eq 'ReadWrite') { $readWrite.Add($line) }
                    else { $readOnly.Add($line) }
                }
            }
            '^aws-saas-connector$' {
                Import-Module (Join-Path $moduleRoot 'ISC.AwsConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                Import-Module (Join-Path $moduleRoot 'ISC.AwsSaasConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                Import-Module (Join-Path $moduleRoot 'ISC.AwsCiemConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                Initialize-AwsConnectorData
                Initialize-AwsSaasConnectorData
                $set = if ($Context['PolicySet']) { $Context['PolicySet'] } else { 'Mgo' }
                $features = Get-ContextFeatureNames -Context $Context
                $aggOnly = ($access -eq 'ReadOnly')
                $docs = Get-SelectedPolicyDocuments -Set $set -FeatureNames $features -SkipProvisioning:$aggOnly -Partition 'aws'
                foreach ($doc in $docs.Values) {
                    $obj = $doc | ConvertFrom-Json
                    foreach ($stmt in @($obj.Statement)) {
                        foreach ($act in @($stmt.Action)) {
                            $split = Split-RequirementsByAccessClass -Names @($act) -Kind 'AwsAction'
                            foreach ($a in $split.ReadOnly) { $readOnly.Add($a) }
                            foreach ($a in $split.ReadWrite) { $readWrite.Add($a) }
                        }
                    }
                }
            }
            '^aws-ciem-connector$' {
                Import-Module (Join-Path $moduleRoot 'ISC.AwsCiemConnector.psm1') -Force -WarningAction SilentlyContinue
                Initialize-AwsCiemConnectorData
                $ciemActions = @(Get-CiemPolicyActions)
                $split = Split-RequirementsByAccessClass -Names $ciemActions -Kind 'AwsAction'
                foreach ($a in $split.ReadOnly) { $readOnly.Add($a) }
                foreach ($a in $split.ReadWrite) { $readWrite.Add($a) }
                $ic = Get-CiemIdentityCenterRequirementActions
                foreach ($a in @($ic.ReadOnly)) { $readOnly.Add($a) }
                if ($access -ne 'ReadOnly') {
                    foreach ($a in @($ic.ReadWrite)) { $readWrite.Add($a) }
                }
            }
            '^google-(saas|ciem)-connector$' {
                Import-Module (Join-Path $moduleRoot 'ISC.GoogleCiemConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                Import-Module (Join-Path $moduleRoot 'ISC.GoogleWorkspaceConnector.psm1') -Force -Global -WarningAction SilentlyContinue
                Initialize-GoogleWorkspaceConnectorData
                Initialize-GoogleCiemConnectorData
                $features = Get-ContextFeatureNames -Context $Context
                $scopes = @(Get-SelectedScopes -FeatureNames $features -Access $access)
                if ($scopes.Count -gt 0) {
                    $split = Split-RequirementsByAccessClass -Names $scopes -Kind 'GoogleOAuthScope'
                    foreach ($s in $split.ReadOnly) { $readOnly.Add($s) }
                    foreach ($s in $split.ReadWrite) { $readWrite.Add($s) }
                }
                $skipGcpWrite = ($access -eq 'ReadOnly')
                $iam = @(Get-GoogleCustomRolePermissions -FeatureNames $features -SkipGcpWrite:$skipGcpWrite)
                if ($iam.Count -gt 0) {
                    $splitIam = Split-RequirementsByAccessClass -Names $iam -Kind 'GoogleIamPermission'
                    foreach ($p in $splitIam.ReadOnly) { $readOnly.Add($p) }
                    foreach ($p in $splitIam.ReadWrite) { $readWrite.Add($p) }
                }
            }
            '^google-gcp-entro$' {
                $split = Split-RequirementsByAccessClass -Names @(Get-EntroGcpPinnedCustomRolePermissions) -Kind 'EntroGcpCustomPermission'
                foreach ($p in $split.ReadOnly) { $readOnly.Add($p) }
                foreach ($p in $split.ReadWrite) { $readWrite.Add($p) }
                $readOnly.Add('Entro predefined org roles: logging.privateLogViewer, organizationViewer, secretmanager.viewer, and nine other viewer roles (see Entro GCP catalog)')
            }
            '^databricks-connector$' {
                $readWrite.Add('Databricks Account Admin (account-level service principal)')
            }
            '^github-entro$' {
                $readOnly.Add('repo')
                $readOnly.Add('read:org')
            }
            '^github-connector$' {
                $readOnly.Add('repo')
                $readOnly.Add('read:org')
                $features = Get-ContextFeatureNames -Context $Context
                if ($features -contains 'AgentDiscovery') {
                    $readOnly.Add('admin:org')
                    $readOnly.Add('manage_billing:copilot')
                }
                if ($features -contains 'ActivityInsights') {
                    $readOnly.Add('read:audit_log')
                }
            }
            '^aws-entro$|^azure-entro$|^google-workspace-entro$' {
                $readOnly.Add('Entro connected identity (read-only discovery; onboarding steps create IAM/app resources in the cloud)')
            }
        }
    }

    return @{
        ReadOnly  = @($readOnly | Sort-Object -Unique)
        ReadWrite = @($readWrite | Sort-Object -Unique)
        Access    = $access
    }
}

function Get-EntraPermissionCatalogForRequirements {
    param(
        [string]$Mode,
        [string[]]$FeatureNames,
        [string]$Access
    )

    if (-not (Get-Command Get-SelectedPermissions -ErrorAction SilentlyContinue)) {
        return @{ ReadOnly = @(); ReadWrite = @() }
    }
    $app = @(Get-SelectedPermissions -Mode $Mode -FeatureNames $FeatureNames -Access $Access)
    $deleg = @(Get-SelectedDelegatedPermissions -FeatureNames $FeatureNames -Access $Access)
    $all = @($app + $deleg)
    $readOnly = @($all | Where-Object {
        (Get-RequirementAccessClass -Kind 'MicrosoftGraphPermission' -Name $_.Value) -eq 'ReadOnly'
    })
    $readWrite = @($all | Where-Object {
        (Get-RequirementAccessClass -Kind 'MicrosoftGraphPermission' -Name $_.Value) -eq 'ReadWrite'
    })
    return @{ ReadOnly = $readOnly; ReadWrite = $readWrite; Granted = $all }
}

Export-ModuleMember -Function @(
    'Get-RequirementAccessClass'
    'Test-RequirementIncludedForAccess'
    'ConvertTo-ReadOnlyGoogleOAuthScope'
    'Filter-PermissionsForAccess'
    'Get-EntraPermissionCatalogForRequirements'
    'Get-IntegrationWizardAccessRequirementLists'
    'Get-EntroGcpPinnedCustomRolePermissions'
    'Split-RequirementsByAccessClass'
)
