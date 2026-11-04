#Requires -Version 7
Set-StrictMode -Version Latest

function Get-EntroGcpHostProjectServices {
    @(
        'cloudresourcemanager.googleapis.com', 'iam.googleapis.com', 'recommender.googleapis.com'
        'policyanalyzer.googleapis.com', 'pubsub.googleapis.com', 'cloudasset.googleapis.com'
        'admin.googleapis.com', 'drive.googleapis.com'
    )
}

function Get-EntroGcpOrganizationProjectServices {
    @(
        'cloudresourcemanager.googleapis.com', 'iam.googleapis.com', 'recommender.googleapis.com'
    )
}

function Get-EntroGcpBillingDependentServices {
    @('secretmanager.googleapis.com', 'discoveryengine.googleapis.com')
}

function Get-EntroGcpPredefinedOrgRoles {
    @(
        'roles/logging.privateLogViewer', 'roles/resourcemanager.organizationViewer'
        'roles/secretmanager.viewer', 'roles/iam.supportUser', 'roles/cloudfunctions.viewer'
        'roles/recommender.iamViewer', 'roles/cloudasset.viewer'
        'roles/policyanalyzer.activityAnalysisViewer', 'roles/iam.securityReviewer'
        'roles/resourcemanager.folderViewer', 'roles/serviceusage.apiKeysViewer'
        'roles/discoveryengine.viewer'
    )
}

function Invoke-EntroGcpGcloud {
    param([Parameter(Mandatory)][string[]]$GcloudArgs)
    if (-not (Get-Command Invoke-GCloud -ErrorAction SilentlyContinue)) {
        throw 'Invoke-GCloud is not available. Import ISC.GoogleWorkspaceConnector.psm1 first.'
    }
    Invoke-GCloud -GcloudArgs $GcloudArgs
}

function New-EntroGcpRunRecord {
    @{
        Actor                 = $null
        OrganizationId        = $null
        ProjectId             = $null
        ServiceAccountEmail   = $null
        ServiceAccountResult  = $null
        KeyPath               = $null
        KeyResult             = $null
        KeyGuidance           = $null
        PolicyOverrides       = [System.Collections.Generic.List[hashtable]]::new()
        BillingLinks          = [System.Collections.Generic.List[hashtable]]::new()
        Blocked               = [System.Collections.Generic.List[hashtable]]::new()
        AuditResult           = $null
        Method                = $null
        Finished              = $false
        CustomRoleId          = $null
        CustomRoleResult      = $null
        CustomRolePermissions = @()
        Projects              = @()
        Bindings              = [System.Collections.Generic.List[hashtable]]::new()
        Apis                  = [System.Collections.Generic.List[hashtable]]::new()
        Checks                = [System.Collections.Generic.List[hashtable]]::new()
    }
}

function Get-EntroGcpRunRecord {
    param([hashtable]$Context)
    if (-not $Context) { return $null }
    if (-not $Context.ContainsKey('EntroGcpRunRecord') -or $null -eq $Context['EntroGcpRunRecord']) {
        $Context['EntroGcpRunRecord'] = New-EntroGcpRunRecord
    }
    return $Context['EntroGcpRunRecord']
}

function Format-EntroGcpMarkdownCell {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return '' }
    return (($Value -replace '\\', '\\') -replace '\|', '\|' -replace '\r?\n', ' ')
}

function Format-EntroGcpRunReport {
    param(
        [Parameter(Mandatory)][hashtable]$Record,
        [hashtable[]]$Pending = @()
    )
    $when = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' UTC'
    $org = [string]$Record.OrganizationId
    $project = [string]$Record.ProjectId
    $email = [string]$Record.ServiceAccountEmail
    $sb = [System.Text.StringBuilder]::new()
    if ($Record.Finished) {
        [void]$sb.AppendLine('# Entro GCP — what changed in your Google Cloud organization')
        [void]$sb.AppendLine('')
        if ($Record.KeyGuidance -or @($Record.Blocked).Count -gt 0) {
            [void]$sb.AppendLine('This run finished, and Google Cloud refused part of it. Each refusal and how to clear it is under "How to clear". The tables are everything it created or confirmed in your organization. Nothing else was changed.')
        }
        else {
            [void]$sb.AppendLine('This run finished successfully. The tables are everything it created or confirmed in your organization. Nothing else was changed.')
        }
    }
    else {
        [void]$sb.AppendLine('# Entro GCP — pre-onboarding check')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('The integration run has not finished. This is only the check of the signed-in user. It is not the record of changes.')
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| | |')
    [void]$sb.AppendLine('| --- | --- |')
    [void]$sb.AppendLine("| Written | $when |")
    if ($Record.Actor) { [void]$sb.AppendLine("| Signed in as | $(Format-EntroGcpMarkdownCell $Record.Actor) |") }
    if ($org) { [void]$sb.AppendLine("| Organization | ``$org`` |") }
    if ($project) { [void]$sb.AppendLine("| Host project | ``$project`` |") }
    if ($email) { [void]$sb.AppendLine("| Entro service account | ``$email`` |") }
    if ($Record.Method) {
        $methodLabel = switch ([string]$Record.Method) {
            'PrivateKey' { 'Private key' }
            'WorkloadIdentity' { 'Workload Identity' }
            default { [string]$Record.Method }
        }
        [void]$sb.AppendLine("| Auth method | $(Format-EntroGcpMarkdownCell $methodLabel) |")
    }
    [void]$sb.AppendLine('')

    $changed = [System.Collections.Generic.List[string]]::new()
    if (-not $Record.Finished) {
        # The change sections are written only after the run succeeds.
    }
    else {
    if ($Record.ServiceAccountResult -eq 'Created in this run' -and $email) {
        $changed.Add("Created the service account ``$email`` in project ``$project``.")
    }
    foreach ($api in @($Record.Apis)) {
        if ($api.Result -eq 'Enabled in this run') {
            $changed.Add("Enabled ``$($api.Service)`` on project ``$($api.Project)`` ($($api.Scope)).")
        }
    }
    if ($Record.CustomRoleResult -eq 'Created in this run' -and $Record.CustomRoleId) {
        $changed.Add("Created the custom organization role ``$($Record.CustomRoleId)`` (Entro Logging Role) and set its permissions.")
    }
    elseif ($Record.CustomRoleResult -eq 'Updated in this run' -and $Record.CustomRoleId) {
        $changed.Add("Updated the permissions on the custom organization role ``$($Record.CustomRoleId)`` (Entro Logging Role).")
    }
    foreach ($binding in @($Record.Bindings)) {
        if ($binding.Result -eq 'Granted in this run') {
            $changed.Add("Granted ``$($binding.Role)`` to ``$email`` on organization ``$org``.")
        }
    }
    if ($Record.AuditResult -eq 'Applied in this run') {
        $auditList = (Get-EntroGcpAuditServices | ForEach-Object { "``$_``" }) -join ', '
        $changed.Add("Turned on DATA_READ and DATA_WRITE audit logs for $auditList across organization ``$org``.")
    }
    foreach ($override in @($Record.PolicyOverrides)) {
        $changed.Add("Turned off ``constraints/$($override.Constraint)`` for project ``$($override.Project)`` only, so $($override.Purpose) there.")
    }
    foreach ($link in @($Record.BillingLinks)) {
        $changed.Add("Linked project ``$($link.Project)`` to billing account ``$($link.BillingAccount)``.")
    }
    if ($Record.KeyResult -eq 'Created in this run' -and $Record.KeyPath -and $email) {
        $changed.Add("Created a JSON key for ``$email`` and saved it to ``$($Record.KeyPath)``.")
    }
    [void]$sb.AppendLine('## What this run changed')
    [void]$sb.AppendLine('')
    if ($changed.Count -eq 0) {
        [void]$sb.AppendLine('This run made no changes. Everything listed below was already in place.')
    }
    else {
        foreach ($line in $changed) { [void]$sb.AppendLine("- $line") }
    }
    [void]$sb.AppendLine('')
    if ($Record.Method -eq 'WorkloadIdentity') {
        [void]$sb.AppendLine('No private key and no Workload Identity pool were created.')
    }
    elseif ($Record.KeyResult -eq 'Already on disk' -and $Record.KeyPath) {
        [void]$sb.AppendLine("The JSON key was already on disk at ``$($Record.KeyPath)``. This run did not create another key.")
    }
    elseif ($Record.KeyGuidance) {
        [void]$sb.AppendLine('Google Cloud returned FAILED_PRECONDITION and did not create a key. How to clear that is in the next section.')
    }
    elseif ($Record.Method -eq 'PrivateKey' -and $Record.KeyResult -ne 'Created in this run') {
        [void]$sb.AppendLine('No service account key was created.')
    }
    [void]$sb.AppendLine('')
    }

    if ($Record.KeyGuidance) {
        [void]$sb.AppendLine('## How to clear this precondition')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine([string]$Record.KeyGuidance)
        [void]$sb.AppendLine('')
    }
    foreach ($item in @($Record.Blocked)) {
        [void]$sb.AppendLine("## How to clear: $($item.Title)")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine([string]$item.Guidance)
        [void]$sb.AppendLine('')
    }

    if ($email -and $Record.ServiceAccountResult) {
        [void]$sb.AppendLine('## Service account')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("| Account | Result |")
        [void]$sb.AppendLine('| --- | --- |')
        [void]$sb.AppendLine("| ``$email`` | $($Record.ServiceAccountResult) |")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('This account is the identity Entro uses to read the organization. It is not the user who ran the wizard.')
        [void]$sb.AppendLine('')
    }

    if ($Record.KeyPath -and $Record.KeyResult -and $Record.KeyResult -ne 'Blocked by organization policy') {
        [void]$sb.AppendLine('## Service account key')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| File | Result |')
        [void]$sb.AppendLine('| --- | --- |')
        [void]$sb.AppendLine("| ``$(Format-EntroGcpMarkdownCell $Record.KeyPath)`` | $(Format-EntroGcpMarkdownCell $Record.KeyResult) |")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('This file is the private key for the Entro service account. Upload that file in Entro. The key itself is not written in this report.')
        [void]$sb.AppendLine('')
    }

    if (@($Record.Apis).Count -gt 0) {
        [void]$sb.AppendLine('## APIs')
        [void]$sb.AppendLine('')
        $projects = [System.Collections.Generic.List[string]]::new()
        foreach ($api in @($Record.Apis)) {
            if (-not $projects.Contains([string]$api.Project)) { $projects.Add([string]$api.Project) }
        }
        foreach ($proj in $projects) {
            [void]$sb.AppendLine("### Project ``$proj``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| API | Why it is required | Result |')
            [void]$sb.AppendLine('| --- | --- | --- |')
            foreach ($api in @($Record.Apis)) {
                if ([string]$api.Project -ne $proj) { continue }
                [void]$sb.AppendLine("| ``$($api.Service)`` | $(Format-EntroGcpMarkdownCell $api.Scope) | $($api.Result) |")
            }
            [void]$sb.AppendLine('')
        }
    }

    if ($Record.CustomRoleId -or @($Record.Bindings).Count -gt 0) {
        [void]$sb.AppendLine('## Organization IAM')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("These grants are on organization ``$org``. They apply to every folder and project in that organization, not only the host project.")
        [void]$sb.AppendLine('')
        if ($Record.CustomRoleId) {
            [void]$sb.AppendLine("### Custom role ``$($Record.CustomRoleId)``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("Title: Entro Logging Role. Result: $($Record.CustomRoleResult).")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Permission |')
            [void]$sb.AppendLine('| --- |')
            foreach ($perm in @($Record.CustomRolePermissions)) {
                [void]$sb.AppendLine("| ``$perm`` |")
            }
            [void]$sb.AppendLine('')
        }
        if (@($Record.Bindings).Count -gt 0) {
            [void]$sb.AppendLine('### Roles granted to the service account')
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Role | Result |')
            [void]$sb.AppendLine('| --- | --- |')
            foreach ($binding in @($Record.Bindings)) {
                [void]$sb.AppendLine("| ``$($binding.Role)`` | $($binding.Result) |")
            }
            [void]$sb.AppendLine('')
        }
    }

    if (@($Record.Checks).Count -gt 0) {
        [void]$sb.AppendLine('## Pre-onboarding check')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Checked before any change. The roles below belong to the signed-in user, not the Entro service account.')
        [void]$sb.AppendLine('')
        if (@($Record.Projects).Count -gt 0) {
            $names = (@($Record.Projects) | ForEach-Object { "``$_``" }) -join ', '
            [void]$sb.AppendLine("Projects directly under the organization: $names.")
            [void]$sb.AppendLine('')
        }
        $checkProjects = [System.Collections.Generic.List[string]]::new()
        foreach ($check in @($Record.Checks)) {
            if (-not $checkProjects.Contains([string]$check.Project)) { $checkProjects.Add([string]$check.Project) }
        }
        foreach ($proj in $checkProjects) {
            [void]$sb.AppendLine("### Project ``$proj``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Check | Result |')
            [void]$sb.AppendLine('| --- | --- |')
            foreach ($check in @($Record.Checks)) {
                if ([string]$check.Project -ne $proj) { continue }
                [void]$sb.AppendLine("| $(Format-EntroGcpMarkdownCell $check.Check) | $(Format-EntroGcpMarkdownCell $check.Result) |")
            }
            [void]$sb.AppendLine('')
        }
    }

    $pendingList = @($Pending | Where-Object { $_ })
    if ($pendingList.Count -gt 0) {
        [void]$sb.AppendLine('## Still for you to do')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('The run did not do these. They are still open in Google Cloud or in Entro.')
        [void]$sb.AppendLine('')
        foreach ($item in $pendingList) {
            $box = if ($item.Done) { 'x' } else { ' ' }
            [void]$sb.AppendLine("- [$box] **$(Format-EntroGcpMarkdownCell $item.Title).** $(Format-EntroGcpMarkdownCell $item.Detail)")
        }
        [void]$sb.AppendLine('')
    }
    return $sb.ToString().TrimEnd() + "`n"
}

function Write-EntroGcpRunReport {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$Path,
        [hashtable[]]$Pending = @()
    )
    $record = Get-EntroGcpRunRecord -Context $Context
    $markdown = Format-EntroGcpRunReport -Record $record -Pending $Pending
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $markdown -Encoding utf8
    $legacy = Join-Path $parent 'entro-gcp-pre-onboarding-report.txt'
    if ((Test-Path -LiteralPath $legacy) -and $legacy -ne $Path) {
        Remove-Item -LiteralPath $legacy -Force
    }
    Write-Ok "Wrote $Path"
}

function Invoke-EntroGcpPreOnboardingCheck {
    param(
        [Parameter(Mandatory)][string]$ReportPath = 'entro-gcp-report.md',
        [hashtable]$Context
    )

    $orgId = Invoke-EntroGcpGcloud -GcloudArgs @('organizations', 'list', '--format=value(name)')
    if ([string]::IsNullOrWhiteSpace($orgId)) {
        throw 'Unable to fetch organization ID. Ensure you have access to an organization.'
    }
    $orgId = ($orgId -split "`n" | Select-Object -First 1).Trim()

    $currentUser = Invoke-EntroGcpGcloud -GcloudArgs @('auth', 'list', '--filter=status:ACTIVE', '--format=value(account)')
    if ([string]::IsNullOrWhiteSpace($currentUser)) {
        throw 'Unable to determine the active user.'
    }

    $projectsRaw = Invoke-EntroGcpGcloud -GcloudArgs @(
        'projects', 'list', "--filter=parent.id=$orgId AND parent.type=organization", '--format=value(projectId)'
    )
    $projects = @($projectsRaw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($projects.Count -eq 0) {
        throw 'No projects found under the organization.'
    }

    if (-not $Context) { $Context = @{} }
    $record = Get-EntroGcpRunRecord -Context $Context
    $record.Actor = $currentUser
    $record.OrganizationId = $orgId
    $record.Projects = $projects
    $record.Checks = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($projectId in $projects) {
        $policyJson = Invoke-EntroGcpGcloud -GcloudArgs @('projects', 'get-iam-policy', $projectId, '--format=json')
        $policy = if ([string]::IsNullOrWhiteSpace($policyJson)) { @{} } else { $policyJson | ConvertFrom-Json -AsHashtable -Depth 50 }
        $userMember = "user:$currentUser"
        foreach ($role in @('roles/owner', 'roles/editor', 'roles/viewer')) {
            $assigned = @(@($policy['bindings']) | Where-Object {
                $_ -and [string]$_['role'] -eq $role -and @($_['members']) -contains $userMember
            }).Count -gt 0
            $record.Checks.Add(@{
                Project = $projectId
                Check   = "$role for $currentUser"
                Result  = $(if ($assigned) { 'Assigned' } else { 'Not assigned' })
            })
        }
        $logging = Invoke-EntroGcpGcloud -GcloudArgs @(
            'services', 'list', '--enabled', '--filter=config.name=logging.googleapis.com'
            "--project=$projectId", '--format=value(config.name)'
        )
        $logsOn = $logging -match 'logging.googleapis.com'
        $record.Checks.Add(@{
            Project = $projectId
            Check   = 'logging.googleapis.com'
            Result  = $(if ($logsOn) { 'Enabled' } else { 'Not enabled' })
        })
    }

    if ($ReportPath) {
        Write-EntroGcpRunReport -Context $Context -Path $ReportPath
    }
}

function Get-EntroGcpDiscoveredOrganizationProjects {
    param([Parameter(Mandatory)][string]$OrganizationId)

    $gsuiteFolder = Invoke-EntroGcpGcloud -GcloudArgs @(
        'asset', 'search-all-resources', "--scope=organizations/$OrganizationId"
        '--asset-types=cloudresourcemanager.googleapis.com/Folder'
        '--query=displayName:system-gsuite', '--format=value(name)'
    )
    $gsuiteFolderId = $null
    if (-not [string]::IsNullOrWhiteSpace($gsuiteFolder)) {
        $parts = ($gsuiteFolder -split "`n" | Select-Object -First 1).Trim() -split '/'
        $gsuiteFolderId = $parts[-1]
    }
    $query = 'state:ACTIVE'
    if ($gsuiteFolderId) { $query = "$query AND NOT folders:$gsuiteFolderId" }

    $resources = Invoke-EntroGcpGcloud -GcloudArgs @(
        'asset', 'search-all-resources', "--scope=organizations/$OrganizationId"
        '--asset-types=cloudresourcemanager.googleapis.com/Project'
        "--query=$query", '--format=value(name)'
    )
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($resources -split "`n")) {
        $line = $line.Trim()
        if ($line) { $list.Add(($line -split '/')[-1]) }
    }
    return $list.ToArray()
}

function Test-EntroGcpServicesEnabled {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string[]]$Services
    )
    foreach ($service in $Services) {
        $enabled = Invoke-EntroGcpGcloud -GcloudArgs @(
            'services', 'list', '--enabled', "--project=$ProjectId"
            "--filter=config.name=$service", '--format=value(config.name)'
        )
        if ($enabled.Trim() -ne $service) {
            throw "Service $service is not enabled on project $ProjectId"
        }
    }
}

function Get-EntroGcpEnabledServiceNames {
    param([Parameter(Mandatory)][string]$ProjectId)
    $raw = Invoke-EntroGcpGcloud -GcloudArgs @(
        'services', 'list', '--enabled', "--project=$ProjectId", '--format=value(config.name)'
    )
    return @($raw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Invoke-EntroGcpEnableApis {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [ValidateSet('apply', 'verify')]
        [string]$Mode = 'apply',
        [hashtable]$Context
    )

    $hostServices = @(Get-EntroGcpHostProjectServices)
    $orgServices = @(Get-EntroGcpOrganizationProjectServices)
    $billingServices = @(Get-EntroGcpBillingDependentServices)

    $plan = [ordered]@{}
    $add = {
        param($Project, [string[]]$Services, [string]$Scope)
        if (-not $plan.Contains($Project)) { $plan[$Project] = [ordered]@{} }
        foreach ($service in $Services) {
            if ($plan[$Project].Contains($service)) {
                $plan[$Project][$service] = "$($plan[$Project][$service]); $Scope"
            }
            else { $plan[$Project][$service] = $Scope }
        }
    }
    & $add $ProjectId $hostServices 'Host project'
    $orgProjects = @(Get-EntroGcpDiscoveredOrganizationProjects -OrganizationId $OrganizationId)
    foreach ($proj in $orgProjects) {
        & $add $proj $orgServices 'Every project in the organization'
        & $add $proj $billingServices 'Every project in the organization; needs billing'
    }

    $record = Get-EntroGcpRunRecord -Context $Context
    if ($record -and $Mode -eq 'apply') {
        $record.OrganizationId = $OrganizationId
        $record.ProjectId = $ProjectId
        $record.Apis = [System.Collections.Generic.List[hashtable]]::new()
    }

    foreach ($proj in @($plan.Keys)) {
        $services = @($plan[$proj].Keys)
        if ($Mode -eq 'verify') {
            $blockedHere = @()
            if ($record) {
                $blockedHere = @(@($record.Apis) | Where-Object { $_.Project -eq $proj -and $_.Result -like 'Blocked*' } | ForEach-Object { $_.Service })
            }
            $toVerify = @($services | Where-Object { $blockedHere -notcontains $_ })
            if ($toVerify.Count -gt 0) { Test-EntroGcpServicesEnabled -ProjectId $proj -Services $toVerify }
            continue
        }
        $enabled = @(Get-EntroGcpEnabledServiceNames -ProjectId $proj)
        $missingByScope = @{
            'Every project in the organization' = [System.Collections.Generic.List[string]]::new()
            'Every project in the organization; needs billing' = [System.Collections.Generic.List[string]]::new()
            'other' = [System.Collections.Generic.List[string]]::new()
        }
        foreach ($service in $services) {
            $scope = [string]$plan[$proj][$service]
            $wasEnabled = $enabled -contains $service
            if (-not $wasEnabled) {
                $bucket = if ($missingByScope.ContainsKey($scope)) { $scope } else { 'other' }
                $missingByScope[$bucket].Add($service)
            }
            if ($record) {
                $record.Apis.Add(@{
                    Project = $proj
                    Service = $service
                    Scope   = $scope
                    Result  = $(if ($wasEnabled) { 'Already enabled' } else { 'Enabled in this run' })
                })
            }
        }
        foreach ($bucket in @($missingByScope.Keys)) {
            $missing = @($missingByScope[$bucket])
            if ($missing.Count -eq 0) { continue }
            $enable = { Invoke-EntroGcpGcloud -GcloudArgs @(@('services', 'enable') + $missing + @("--project=$proj")) | Out-Null }
            try {
                & $enable
            }
            catch {
                if (-not (Test-EntroGcpBillingError -ErrorMessage $_.Exception.Message)) { throw }
                $linked = Invoke-EntroGcpLinkBillingAccount -ProjectId $proj -Services $missing -Context $Context
                if ($linked -and (Invoke-EntroGcpRetryAfterPolicyChange -Action $enable -Context $Context -What "enabling APIs on $proj")) {
                    continue
                }
                $guidance = Get-EntroGcpBillingGuidance -ProjectId $proj -Services $missing
                if ($record) {
                    foreach ($api in @($record.Apis)) {
                        if ($api.Project -eq $proj -and $missing -contains $api.Service) {
                            $api.Result = 'Blocked: project has no billing account'
                        }
                    }
                    $record.Blocked.Add(@{
                        Id       = "billing-$proj"
                        Title    = "Turn on billing for project $proj"
                        Detail   = "Google Cloud refused to enable $($missing -join ', ') on $proj because the project has no billing account. Link a billing account (see entro-gcp-report.md), then rerun the wizard."
                        Guidance = $guidance
                    })
                }
                Write-EntroGcpGuidance -Text $guidance
            }
        }
    }
    Write-Ok "Entro GCP API enablement ($Mode) completed"
}

function Test-EntroGcpBillingError {
    param([AllowEmptyString()][string]$ErrorMessage)
    return [bool]($ErrorMessage -match '(?i)UREQ_PROJECT_BILLING_NOT_FOUND|billing account for project|billing must be enabled|billing is not enabled|BILLING_DISABLED')
}

function Get-EntroGcpBillingGuidance {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string[]]$Services
    )
    $list = ($Services | ForEach-Object { "``$_``" }) -join ', '
    return @"
Google Cloud returned FAILED_PRECONDITION. Project ``$ProjectId`` has no billing account, and Google enables $list only on projects with billing. Entro reads these in every project of the organization, so they stay off in ``$ProjectId`` until billing is on.

1. List the billing accounts you can use:

``````
gcloud billing accounts list --filter=open=true
``````

2. Link one to the project. That takes Billing Account User (``roles/billing.user``) on the billing account and Owner or Project Billing Manager on the project:

``````
gcloud billing projects link $ProjectId --billing-account=BILLING_ACCOUNT_ID
``````

3. Rerun the wizard. An interactive run offers to do step 2 when exactly one open billing account is visible. Pass ``-ApplyPreconditionFix`` to do it without the question.

To keep this project without billing, leave this item open. Entro will not see those APIs in ``$ProjectId``.
"@
}

function Invoke-EntroGcpLinkBillingAccount {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string[]]$Services,
        [hashtable]$Context
    )
    try {
        $raw = Invoke-EntroGcpGcloud -GcloudArgs @('billing', 'accounts', 'list', '--filter=open=true', '--format=json')
        $accounts = @(if ([string]::IsNullOrWhiteSpace($raw)) { @() } else { $raw | ConvertFrom-Json -AsHashtable -Depth 10 })
    }
    catch {
        return $false
    }
    $accounts = @($accounts | Where-Object { $_ })
    if ($accounts.Count -ne 1) { return $false }
    $accountId = ([string]$accounts[0]['name']) -replace '^billingAccounts/', ''
    $label = if ($accounts[0]['displayName']) { "$accountId ($($accounts[0]['displayName']))" } else { $accountId }
    $prompt = "Project $ProjectId has no billing account, so Google refuses $($Services -join ', '). Link it to billing account $label and retry?"
    if (-not (Test-EntroGcpShouldApplyPreconditionFix -Context $Context -Prompt $prompt)) { return $false }
    try {
        Invoke-EntroGcpGcloud -GcloudArgs @('billing', 'projects', 'link', $ProjectId, "--billing-account=$accountId") | Out-Null
    }
    catch {
        Write-EntroGcpGuidance -Text "The wizard tried to link billing account $accountId to $ProjectId and gcloud refused: $($_.Exception.Message)"
        return $false
    }
    $record = Get-EntroGcpRunRecord -Context $Context
    if ($record) { $record.BillingLinks.Add(@{ Project = $ProjectId; BillingAccount = $accountId }) }
    Write-Ok "Linked $ProjectId to billing account $accountId"
    return $true
}

function Test-EntroGcpOrgBindingExists {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Role
    )
    $members = Invoke-EntroGcpGcloud -GcloudArgs @(
        'organizations', 'get-iam-policy', $OrganizationId
        '--flatten=bindings', "--filter=bindings.role=$Role", '--format=value(bindings.members)'
    )
    return @($members -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $Member }).Count -gt 0
}

function Get-EntroGcpIamStateFileName {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName
    )
    "entro-gcp-iam-${OrganizationId}-${ProjectId}-${ServiceAccountName}.state"
}

function Get-EntroGcpIamStatePath {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName,
        [string]$Directory
    )
    if ($env:ENTRO_GCP_IAM_STATE) { return $env:ENTRO_GCP_IAM_STATE }
    $name = Get-EntroGcpIamStateFileName -OrganizationId $OrganizationId -ProjectId $ProjectId -ServiceAccountName $ServiceAccountName
    $tmp = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
    $legacy = Join-Path $tmp $name
    if (-not $Directory) { return $legacy }
    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    $dest = Join-Path $Directory $name
    # A run that started before state lived in the integration folder left this file in temp.
    if ((Split-Path -Parent $dest) -ne (Split-Path -Parent $legacy) -and
        -not (Test-Path -LiteralPath $dest) -and (Test-Path -LiteralPath $legacy)) {
        Move-Item -LiteralPath $legacy -Destination $dest
    }
    return $dest
}

function Get-EntroGcpBoundCustomRoleIds {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$Member
    )
    $roles = Invoke-EntroGcpGcloud -GcloudArgs @(
        'organizations', 'get-iam-policy', $OrganizationId
        '--flatten=bindings', "--filter=bindings.members=$Member", '--format=value(bindings.role)'
    )
    return @($roles -split "`n" | ForEach-Object { $_.Trim() } | Where-Object {
        $_ -match "^organizations/$OrganizationId/roles/entroLoggingRole_\d+$"
    } | ForEach-Object { ($_ -split '/')[-1] })
}

function Get-EntroGcpBoundCustomRoleId {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$Member
    )
    $ids = @(Get-EntroGcpBoundCustomRoleIds -OrganizationId $OrganizationId -Member $Member)
    if ($ids.Count -ne 1) {
        throw "expected exactly one entroLoggingRole_* role bound to $Member; found $($ids.Count)"
    }
    return $ids[0]
}

function Read-EntroGcpIamState {
    param([Parameter(Mandatory)][string]$StateFile)
    $state = @{ CustomRoleId = $null; Bindings = [System.Collections.Generic.List[string]]::new() }
    if (-not (Test-Path -LiteralPath $StateFile)) { return $state }
    foreach ($line in Get-Content -LiteralPath $StateFile) {
        if (-not $line.Trim()) { continue }
        $parts = $line -split "`t", 2
        switch ($parts[0]) {
            'binding' { if (-not $state.Bindings.Contains($parts[1])) { $state.Bindings.Add($parts[1]) } }
            'custom-role' { $state.CustomRoleId = $parts[1] }
            default { throw "invalid run state entry: $($parts[0])" }
        }
    }
    return $state
}

function Write-EntroGcpIamState {
    param(
        [Parameter(Mandatory)][string]$StateFile,
        [Parameter(Mandatory)][hashtable]$State
    )
    $lines = [System.Collections.Generic.List[string]]::new()
    if ($State.CustomRoleId) { $lines.Add("custom-role`t$($State.CustomRoleId)") }
    foreach ($b in $State.Bindings) { $lines.Add("binding`t$b") }
    $parent = Split-Path -Parent $StateFile
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $StateFile -Value ($lines -join "`n") -Encoding utf8
}

function Test-EntroGcpIamGrantsComplete {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName
    )
    try {
        Invoke-EntroGcpIamGrants -OrganizationId $OrganizationId -ProjectId $ProjectId `
            -ServiceAccountName $ServiceAccountName -Mode 'verify' 6>$null | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Select-EntroGcpCustomRoleId {
    param([Parameter(Mandatory)][string]$OrganizationId)

    $span = 1000
    $start = Get-Random -Minimum 1 -Maximum ($span + 1)
    for ($offset = 0; $offset -lt $span; $offset++) {
        $suffix = 1 + (($start - 1 + $offset) % $span)
        $candidate = "entroLoggingRole_$suffix"
        try {
            Invoke-EntroGcpGcloud -GcloudArgs @('iam', 'roles', 'describe', $candidate, "--organization=$OrganizationId") | Out-Null
        }
        catch {
            return $candidate
        }
    }
    throw 'all Terraform-compatible Entro custom role IDs already exist'
}

function Sync-EntroGcpIamReport {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName,
        [string]$StateDirectory,
        [hashtable]$Context,
        [string]$CustomRoleId,
        [string]$CustomRoleResult,
        [string[]]$GrantedThisRun = @()
    )
    $record = Get-EntroGcpRunRecord -Context $Context
    if (-not $record) { return }
    if (-not (Get-Module -Name 'IW.Access')) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Access.psm1') -Force -WarningAction SilentlyContinue
    }
    $member = "serviceAccount:${ServiceAccountName}@${ProjectId}.iam.gserviceaccount.com"
    $stateFile = Get-EntroGcpIamStatePath -OrganizationId $OrganizationId -ProjectId $ProjectId `
        -ServiceAccountName $ServiceAccountName -Directory $StateDirectory
    $state = Read-EntroGcpIamState -StateFile $stateFile
    if (-not $CustomRoleId) {
        $CustomRoleId = Get-EntroGcpBoundCustomRoleId -OrganizationId $OrganizationId -Member $member
    }
    if (-not $CustomRoleResult) {
        $CustomRoleResult = if ($state.CustomRoleId -eq $CustomRoleId) { 'Created in an earlier run' } else { 'Already present' }
    }
    $record.OrganizationId = $OrganizationId
    $record.ProjectId = $ProjectId
    $record.ServiceAccountEmail = $member.Substring('serviceAccount:'.Length)
    $record.CustomRoleId = $CustomRoleId
    $record.CustomRoleResult = $CustomRoleResult
    $record.CustomRolePermissions = @(Get-EntroGcpPinnedCustomRolePermissions | Sort-Object)
    $record.Bindings = [System.Collections.Generic.List[hashtable]]::new()
    $customRole = "organizations/$OrganizationId/roles/$CustomRoleId"
    $earlier = @($state.Bindings)
    foreach ($role in @($customRole) + @(Get-EntroGcpPredefinedOrgRoles)) {
        $result = if ($GrantedThisRun -contains $role) { 'Granted in this run' }
            elseif ($earlier -contains $role) { 'Granted in an earlier run' }
            else { 'Already granted' }
        $record.Bindings.Add(@{ Role = $role; Result = $result })
    }
}

function Invoke-EntroGcpIamGrants {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName,
        [string]$StateDirectory,
        [hashtable]$Context,
        [ValidateSet('apply', 'verify', 'rollback')]
        [string]$Mode = 'apply'
    )

    if (-not (Get-Module -Name 'IW.Access')) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Access.psm1') -Force -WarningAction SilentlyContinue
    }
    $member = "serviceAccount:${ServiceAccountName}@${ProjectId}.iam.gserviceaccount.com"
    $permissions = @(Get-EntroGcpPinnedCustomRolePermissions)
    $predefined = @(Get-EntroGcpPredefinedOrgRoles)
    $stateFile = Get-EntroGcpIamStatePath -OrganizationId $OrganizationId -ProjectId $ProjectId `
        -ServiceAccountName $ServiceAccountName -Directory $StateDirectory

    switch ($Mode) {
        'verify' {
            $customRoleId = Get-EntroGcpBoundCustomRoleId -OrganizationId $OrganizationId -Member $member
            $included = Invoke-EntroGcpGcloud -GcloudArgs @(
                'iam', 'roles', 'describe', $customRoleId, "--organization=$OrganizationId", '--format=value(includedPermissions)'
            )
            $expected = @($permissions | Sort-Object)
            $actual = @($included -split '[;,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object)
            if (($expected -join '|') -ne ($actual -join '|')) {
                throw 'custom role permissions differ from the pinned Terraform source'
            }
            $customRole = "organizations/$OrganizationId/roles/$customRoleId"
            if (-not (Test-EntroGcpOrgBindingExists -OrganizationId $OrganizationId -Member $member -Role $customRole)) {
                throw "missing binding for $customRole"
            }
            foreach ($role in $predefined) {
                if (-not (Test-EntroGcpOrgBindingExists -OrganizationId $OrganizationId -Member $member -Role $role)) {
                    throw "missing binding for $role"
                }
            }
            Write-Ok 'Entro GCP IAM grants verified'
        }
        'rollback' {
            if (-not (Test-Path -LiteralPath $stateFile)) { throw "run state not found: $stateFile" }
            $state = Read-EntroGcpIamState -StateFile $stateFile
            $bindings = $state.Bindings
            $customRoleId = $state.CustomRoleId
            for ($i = $bindings.Count - 1; $i -ge 0; $i--) {
                Invoke-EntroGcpGcloud -GcloudArgs @(
                    'organizations', 'remove-iam-policy-binding', $OrganizationId
                    "--member=$member", "--role=$($bindings[$i])"
                ) | Out-Null
            }
            if ($customRoleId) {
                Invoke-EntroGcpGcloud -GcloudArgs @(
                    'iam', 'roles', 'delete', $customRoleId, "--organization=$OrganizationId", '--quiet'
                ) | Out-Null
            }
            Remove-Item -LiteralPath $stateFile -Force
            Write-Ok 'Entro GCP IAM rollback completed'
        }
        'apply' {
            if (Test-EntroGcpIamGrantsComplete -OrganizationId $OrganizationId -ProjectId $ProjectId -ServiceAccountName $ServiceAccountName) {
                Sync-EntroGcpIamReport -OrganizationId $OrganizationId -ProjectId $ProjectId `
                    -ServiceAccountName $ServiceAccountName -StateDirectory $StateDirectory -Context $Context
                Write-Ok 'Entro GCP IAM grants already in place'
                return
            }
            # State is written after every change so an interrupted run resumes here
            # instead of minting a second entroLoggingRole_* or losing rollback data.
            $state = Read-EntroGcpIamState -StateFile $stateFile
            $earlierBindings = @($state.Bindings)
            $customRoleId = $state.CustomRoleId
            $roleResult = $null
            if (-not $customRoleId) {
                $bound = @(Get-EntroGcpBoundCustomRoleIds -OrganizationId $OrganizationId -Member $member)
                if ($bound.Count -gt 1) {
                    throw "multiple entroLoggingRole_* roles bound to $member ($($bound -join ', ')); remove the extras before applying"
                }
                if ($bound.Count -eq 1) { $customRoleId = $bound[0] }
            }
            $permCsv = ($permissions -join ',')
            if (-not $customRoleId) {
                $customRoleId = Select-EntroGcpCustomRoleId -OrganizationId $OrganizationId
                Invoke-EntroGcpGcloud -GcloudArgs @(
                    'iam', 'roles', 'create', $customRoleId, "--organization=$OrganizationId"
                    '--title=Entro Logging Role'
                    '--description=This role is used by entro to access logging resources.'
                    "--permissions=$permCsv"
                ) | Out-Null
                $state.CustomRoleId = $customRoleId
                Write-EntroGcpIamState -StateFile $stateFile -State $state
                $roleResult = 'Created in this run'
            }
            else {
                Invoke-EntroGcpGcloud -GcloudArgs @(
                    'iam', 'roles', 'update', $customRoleId, "--organization=$OrganizationId"
                    "--permissions=$permCsv", '--quiet'
                ) | Out-Null
                $roleResult = 'Updated in this run'
            }
            $customRole = "organizations/$OrganizationId/roles/$customRoleId"
            $grantedNow = [System.Collections.Generic.List[string]]::new()
            foreach ($role in @($customRole) + $predefined) {
                if (-not (Test-EntroGcpOrgBindingExists -OrganizationId $OrganizationId -Member $member -Role $role)) {
                    Invoke-EntroGcpGcloud -GcloudArgs @(
                        'organizations', 'add-iam-policy-binding', $OrganizationId
                        "--member=$member", "--role=$role"
                    ) | Out-Null
                    if (-not $state.Bindings.Contains($role)) { $state.Bindings.Add($role) }
                    if (-not $grantedNow.Contains($role)) { $grantedNow.Add($role) }
                    Write-EntroGcpIamState -StateFile $stateFile -State $state
                }
            }
            Sync-EntroGcpIamReport -OrganizationId $OrganizationId -ProjectId $ProjectId `
                -ServiceAccountName $ServiceAccountName -StateDirectory $StateDirectory -Context $Context `
                -CustomRoleId $customRoleId -CustomRoleResult $roleResult -GrantedThisRun @($grantedNow)
            Invoke-EntroGcpIamGrants -OrganizationId $OrganizationId -ProjectId $ProjectId `
                -ServiceAccountName $ServiceAccountName -Mode 'verify'
        }
    }
}

function Test-EntroGcpServiceAccountExists {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName
    )
    $email = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"
    try {
        Invoke-EntroGcpGcloud -GcloudArgs @('iam', 'service-accounts', 'describe', $email, "--project=$ProjectId") | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-EntroGcpEnsureServiceAccount {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName,
        [string]$StateDirectory,
        [hashtable]$Context
    )
    $email = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"
    $record = Get-EntroGcpRunRecord -Context $Context
    if ($record) {
        $record.ProjectId = $ProjectId
        $record.ServiceAccountEmail = $email
    }
    if (Test-EntroGcpServiceAccountExists -ProjectId $ProjectId -ServiceAccountName $ServiceAccountName) {
        if ($record -and -not $record.ServiceAccountResult) { $record.ServiceAccountResult = 'Already present' }
        Write-Ok "Service account $ServiceAccountName already exists"
        return
    }
    $create = {
        Invoke-EntroGcpGcloud -GcloudArgs @(
            'iam', 'service-accounts', 'create', $ServiceAccountName, "--project=$ProjectId"
            '--display-name=A service account for Entro Automatic Onboard'
        ) | Out-Null
    }
    $policyDir = if ($StateDirectory) { $StateDirectory } else { (Get-Location).Path }
    $outcome = Invoke-EntroGcpWithPolicyOverride -Action $create -ProjectId $ProjectId -Email $email `
        -PolicyDirectory $policyDir -What 'the service account' -Purpose 'the Entro service account can be created' -Context $Context
    if (-not $outcome.Done) {
        Write-EntroGcpGuidance -Text $outcome.Guidance
        throw "Google Cloud refused to create $email. Every later step needs this account. How to clear it is printed above."
    }
    if ($record) { $record.ServiceAccountResult = 'Created in this run' }
    Write-Ok "Created service account $ServiceAccountName"
}

function Test-EntroGcpServiceAccountKeyFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Email
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        return $false
    }
    if ($null -eq $json) { return $false }
    $client = $json.PSObject.Properties['client_email']
    $key = $json.PSObject.Properties['private_key']
    $client = if ($client) { $client.Value } else { $null }
    $key = if ($key) { $key.Value } else { $null }
    return ([string]$client -eq $Email) -and -not [string]::IsNullOrWhiteSpace([string]$key)
}

function Protect-EntroGcpSecretFile {
    param([Parameter(Mandatory)][string]$Path)
    $onWindows = $false
    if ($PSVersionTable.PSObject.Properties['Platform']) {
        $onWindows = $PSVersionTable.Platform -eq 'Win32NT'
    }
    elseif ($env:OS -like 'Windows*') {
        $onWindows = $true
    }
    if ($onWindows) { return }
    & chmod 600 $Path
}

function Get-EntroGcpPreconditionGuidance {
    param(
        [Parameter(Mandatory)][string]$ErrorMessage,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Email,
        [string]$KeyPath
    )
    $recognized = $ErrorMessage -match 'FAILED_PRECONDITION|CUSTOM_ORG_POLICY_VIOLATION|disableServiceAccount(Key)?Creation'
    if (-not $recognized) { return $null }
    $constraint = Get-EntroGcpConstraintFromError -ErrorMessage $ErrorMessage

    if (Test-EntroGcpOverridableConstraint -Constraint $constraint) {
        $policyName = "projects/$ProjectId/policies/$constraint"
        $policyFile = Get-EntroGcpPolicyOverrideFileName -Constraint $constraint
        $isKey = $constraint -match 'KeyCreation$'
        $refused = if ($isKey) { "a JSON key for ``$Email``" } else { "the service account ``$Email``" }
        $allowed = if ($isKey) { 'keys' } else { 'service account creation' }
        $retried = if ($isKey) { 'the key' } else { 'the service account' }
        $fileNote = if (-not $isKey) { 'The rerun creates the service account and continues.' }
            elseif ($KeyPath) { "The wizard will save the key to ``$KeyPath``. Upload that file and the organization domain in Entro." }
            else { 'The wizard will save the key in the integration folder. Upload that file and the organization domain in Entro.' }
        $alternative = if ($isKey) { "`n`nTo leave the policy in place, rerun with ``-Method WorkloadIdentity``. That path does not create a private key." } else { '' }
        return @"
Google Cloud returned FAILED_PRECONDITION. The account signed in to gcloud can call the API, and Google still refused $refused.

Organization policy ``constraints/$constraint`` is enforced for project ``$ProjectId``. Project Owner cannot change an organization policy. This takes Organization Policy Administrator (``roles/orgpolicy.policyAdmin``) on the organization or on this project.

Allow $allowed in this project only. Other projects keep the current policy.

1. Enable the Organization Policy API on this project if ``gcloud org-policies`` says it is disabled:

``````
gcloud services enable orgpolicy.googleapis.com --project=$ProjectId
``````

2. See the policy that is in effect:

``````
gcloud org-policies describe $constraint --effective --project=$ProjectId
``````

3. Save the following as ``$policyFile``. ``enforce: false`` overrides the policy inherited by this project.

``````yaml
name: $policyName
spec:
  rules:
  - enforce: false
``````

4. Apply that file. An interactive run asks to do steps 1 and 4, and to retry $retried, with the signed-in gcloud session. Pass ``-ApplyPreconditionFix`` to do that without the question.

``````
gcloud org-policies set-policy $policyFile
``````

If that command returns PERMISSION_DENIED, the signed-in account does not have ``roles/orgpolicy.policyAdmin``.

5. After the wizard applies the file, it retries $retried for up to 5 minutes. Google can take up to 15 minutes to apply a policy. If the run stops before then, rerun the wizard. $fileNote$alternative
"@
    }

    $named = if ($constraint) {
        "The constraint is ``constraints/$constraint``."
    }
    else {
        'The error did not name a constraint. Use the gcloud message as the reason Google refused the call.'
    }
    $describe = if ($constraint) {
        @"

See the policy that is in effect:

``````
gcloud org-policies describe $constraint --effective --project=$ProjectId
``````
"@
    }
    else { '' }
    return @"
Google Cloud returned FAILED_PRECONDITION. The command was refused before it changed anything. A signed-in session does not override this.

$named An Organization Policy Administrator (``roles/orgpolicy.policyAdmin``) has to change that constraint for project ``$ProjectId``. Project Owner is not that role. After the policy changes, wait up to 15 minutes and rerun the wizard.$describe
"@
}

function Write-EntroGcpGuidance {
    param([Parameter(Mandatory)][string]$Text)
    foreach ($line in ($Text -split "`r?`n")) {
        Write-Host "   $line" -ForegroundColor Yellow
        if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-IntegrationProjectLogLine -Level 'WARN' -Message $line
            }
        }
    }
}

function Get-EntroGcpConstraintFromError {
    param([AllowEmptyString()][string]$ErrorMessage)
    if ($ErrorMessage -match 'constraints/([A-Za-z0-9._-]+)') { return $Matches[1] }
    return $null
}

function Test-EntroGcpOverridableConstraint {
    param([AllowNull()][string]$Constraint)
    return [bool]($Constraint -match '^iam\.(managed\.)?disableServiceAccount(Key)?Creation$')
}

function Get-EntroGcpPolicyOverrideFileName {
    param([Parameter(Mandatory)][string]$Constraint)
    if ($Constraint -match 'KeyCreation$') { return 'allow-service-account-keys.yaml' }
    return 'allow-service-account-creation.yaml'
}

function Test-EntroGcpShouldApplyPreconditionFix {
    param(
        [hashtable]$Context,
        [Parameter(Mandatory)][string]$Prompt
    )
    if ($Context -and $Context.ContainsKey('ApplyPreconditionFix')) {
        return [bool]$Context['ApplyPreconditionFix']
    }
    $nonInteractive = $false
    if (Get-Command Test-OperatorNonInteractive -ErrorAction SilentlyContinue) {
        $nonInteractive = [bool](Test-OperatorNonInteractive)
    }
    if ($nonInteractive) { return $false }
    if (-not (Get-Command Read-YesNo -ErrorAction SilentlyContinue)) { return $false }
    return Read-YesNo -Prompt $Prompt -Default $true
}

function Get-EntroGcpPreconditionWaitSeconds {
    param([hashtable]$Context)
    # Org policy and billing changes take minutes to reach the API that enforces them.
    if ($Context -and $Context.ContainsKey('PreconditionWaitSeconds')) { return [int]$Context['PreconditionWaitSeconds'] }
    return 300
}

function Invoke-EntroGcpRetryAfterPolicyChange {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [hashtable]$Context,
        [Parameter(Mandatory)][string]$What
    )
    $deadline = (Get-Date).AddSeconds((Get-EntroGcpPreconditionWaitSeconds -Context $Context))
    while ($true) {
        try {
            & $Action
            return $true
        }
        catch {
            $message = $_.Exception.Message
            if ($message -notmatch 'FAILED_PRECONDITION|CUSTOM_ORG_POLICY_VIOLATION|constraints/' -and -not (Test-EntroGcpBillingError -ErrorMessage $message)) { throw }
            $left = ($deadline - (Get-Date)).TotalSeconds
            if ($left -le 0) { return $false }
            $pause = [int][Math]::Max(1, [Math]::Min(30, [Math]::Ceiling($left)))
            Write-Info "Google has not applied the change yet. Retrying $What in $pause seconds."
            Start-Sleep -Seconds $pause
        }
    }
}

function Invoke-EntroGcpProjectPolicyOverride {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Constraint,
        [Parameter(Mandatory)][string]$PolicyPath
    )
    $yaml = @"
name: projects/$ProjectId/policies/$Constraint
spec:
  rules:
  - enforce: false
"@
    $dir = Split-Path -Parent $PolicyPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -LiteralPath $PolicyPath -Value ($yaml.TrimEnd() + "`n") -Encoding utf8
    Invoke-EntroGcpGcloud -GcloudArgs @('services', 'enable', 'orgpolicy.googleapis.com', "--project=$ProjectId") | Out-Null
    Invoke-EntroGcpGcloud -GcloudArgs @('org-policies', 'set-policy', $PolicyPath) | Out-Null
}

function Invoke-EntroGcpWithPolicyOverride {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Email,
        [Parameter(Mandatory)][string]$PolicyDirectory,
        [Parameter(Mandatory)][string]$What,
        [Parameter(Mandatory)][string]$Purpose,
        [string]$KeyPath,
        [hashtable]$Context
    )
    $wait = Get-EntroGcpPreconditionWaitSeconds -Context $Context
    $record = Get-EntroGcpRunRecord -Context $Context
    $applied = [System.Collections.Generic.List[string]]::new()
    $guidance = $null
    $deadline = Get-Date
    while ($true) {
        try {
            & $Action
            return @{ Done = $true; Guidance = $null }
        }
        catch {
            $message = $_.Exception.Message
            $current = Get-EntroGcpPreconditionGuidance -ErrorMessage $message -ProjectId $ProjectId -Email $Email -KeyPath $KeyPath
            if (-not $current) { throw }
            if (-not $guidance) { $guidance = $current }
            $constraint = Get-EntroGcpConstraintFromError -ErrorMessage $message
            # Organizations often enforce the legacy and the managed constraint together, so clearing one exposes the other.
            if ((Test-EntroGcpOverridableConstraint -Constraint $constraint) -and -not $applied.Contains($constraint)) {
                if ($applied.Count -eq 0 -and -not (Test-EntroGcpShouldApplyPreconditionFix -Context $Context -Prompt "Apply this project override with the signed-in gcloud session and retry ${What}?")) {
                    return @{ Done = $false; Guidance = "$guidance`n`nThis run did not change the policy. Answer yes when the wizard asks, or pass -ApplyPreconditionFix." }
                }
                $fileName = Get-EntroGcpPolicyOverrideFileName -Constraint $constraint
                if (@($applied | Where-Object { (Get-EntroGcpPolicyOverrideFileName -Constraint $_) -eq $fileName }).Count -gt 0) {
                    $fileName = "allow-$($constraint -replace '[^A-Za-z0-9]+', '-').yaml"
                }
                $policyPath = Join-Path $PolicyDirectory $fileName
                try {
                    Invoke-EntroGcpProjectPolicyOverride -ProjectId $ProjectId -Constraint $constraint -PolicyPath $policyPath
                }
                catch {
                    return @{ Done = $false; Guidance = "$guidance`n`nThe wizard tried to apply the project override and gcloud refused: $($_.Exception.Message)" }
                }
                $applied.Add($constraint)
                if ($record) {
                    $record.PolicyOverrides.Add(@{ Constraint = $constraint; Project = $ProjectId; Path = $policyPath; Purpose = $Purpose })
                }
                Write-Ok "Applied project override for constraints/$constraint"
                $deadline = (Get-Date).AddSeconds($wait)
                continue
            }
            if ($applied.Count -eq 0) { return @{ Done = $false; Guidance = $guidance } }
            $left = ($deadline - (Get-Date)).TotalSeconds
            if ($left -le 0) {
                $names = ($applied | ForEach-Object { "``constraints/$_``" }) -join ' and '
                return @{ Done = $false; Guidance = "$guidance`n`nThe wizard applied the project override for $names, and Google still refused $What after waiting. Wait up to 15 minutes, then rerun the wizard." }
            }
            $pause = [int][Math]::Max(1, [Math]::Min(30, [Math]::Ceiling($left)))
            Write-Info "Google has not applied the policy change yet. Retrying $What in $pause seconds."
            Start-Sleep -Seconds $pause
        }
    }
}

function Invoke-EntroGcpCreateServiceAccountKey {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Email,
        [Parameter(Mandatory)][string]$KeyPath
    )
    Invoke-EntroGcpGcloud -GcloudArgs @(
        'iam', 'service-accounts', 'keys', 'create', $KeyPath
        "--iam-account=$Email", "--project=$ProjectId"
    ) | Out-Null
}

function Invoke-EntroGcpEnsureServiceAccountKey {
    param(
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceAccountName,
        [Parameter(Mandatory)][string]$KeyPath,
        [hashtable]$Context
    )
    $email = "$ServiceAccountName@$ProjectId.iam.gserviceaccount.com"
    $record = Get-EntroGcpRunRecord -Context $Context
    if ($record) {
        $record.ProjectId = $ProjectId
        $record.ServiceAccountEmail = $email
        $record.Method = 'PrivateKey'
        $record.KeyPath = $KeyPath
    }
    if (Test-EntroGcpServiceAccountKeyFile -Path $KeyPath -Email $email) {
        Protect-EntroGcpSecretFile -Path $KeyPath
        if ($record -and -not $record.KeyResult) { $record.KeyResult = 'Already on disk' }
        Write-Ok "Service account key already on disk: $KeyPath"
        return
    }
    if (Test-Path -LiteralPath $KeyPath) {
        $existing = Get-Item -LiteralPath $KeyPath
        $empty = $existing.Length -eq 0
        if (-not $empty) {
            throw "Refusing to replace $KeyPath because it is not a private key for $email."
        }
        Remove-Item -LiteralPath $KeyPath -Force
    }
    $parent = Split-Path -Parent $KeyPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $create = {
        try {
            Invoke-EntroGcpCreateServiceAccountKey -ProjectId $ProjectId -Email $email -KeyPath $KeyPath
        }
        catch {
            if ((Test-Path -LiteralPath $KeyPath) -and -not (Test-EntroGcpServiceAccountKeyFile -Path $KeyPath -Email $email)) {
                Remove-Item -LiteralPath $KeyPath -Force
            }
            throw
        }
    }
    $policyDir = if ($parent) { $parent } else { (Get-Location).Path }
    $outcome = Invoke-EntroGcpWithPolicyOverride -Action $create -ProjectId $ProjectId -Email $email -KeyPath $KeyPath `
        -PolicyDirectory $policyDir -What 'the key' -Purpose 'a service account key can be created' -Context $Context
    if (-not $outcome.Done) {
        if ($record) {
            $record.KeyResult = 'Blocked by organization policy'
            $record.KeyGuidance = $outcome.Guidance
        }
        Write-EntroGcpGuidance -Text $outcome.Guidance
        return 'blocked'
    }
    if ($record) { $record.KeyGuidance = $null }
    if (-not (Test-EntroGcpServiceAccountKeyFile -Path $KeyPath -Email $email)) {
        if (Test-Path -LiteralPath $KeyPath) { Remove-Item -LiteralPath $KeyPath -Force }
        throw "gcloud did not write a private key for $email to $KeyPath."
    }
    Protect-EntroGcpSecretFile -Path $KeyPath
    if ($record) { $record.KeyResult = 'Created in this run' }
    Write-Ok "Created service account key: $KeyPath"
}

function Get-EntroGcpAuditServices {
    @('secretmanager.googleapis.com', 'cloudfunctions.googleapis.com', 'iam.googleapis.com')
}

function Get-EntroGcpOrganizationPolicy {
    param([Parameter(Mandatory)][string]$OrganizationId)
    $json = Invoke-EntroGcpGcloud -GcloudArgs @('organizations', 'get-iam-policy', $OrganizationId, '--format=json')
    return ($json | ConvertFrom-Json -AsHashtable -Depth 50)
}

function Get-EntroGcpMissingAuditServices {
    param([Parameter(Mandatory)][hashtable]$Policy)
    $configs = @{}
    foreach ($cfg in @($Policy['auditConfigs'])) {
        if ($cfg) { $configs[[string]$cfg['service']] = $cfg }
    }
    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($svc in Get-EntroGcpAuditServices) {
        $types = @()
        if ($configs.ContainsKey($svc)) {
            $types = @(@($configs[$svc]['auditLogConfigs']) | ForEach-Object { [string]$_['logType'] })
        }
        if (($types -notcontains 'DATA_READ') -or ($types -notcontains 'DATA_WRITE')) { $missing.Add($svc) }
    }
    return @($missing)
}

function Test-EntroGcpAuditConfigsComplete {
    param([Parameter(Mandatory)][string]$OrganizationId)
    $policy = Get-EntroGcpOrganizationPolicy -OrganizationId $OrganizationId
    return @(Get-EntroGcpMissingAuditServices -Policy $policy).Count -eq 0
}

function Invoke-EntroGcpAuditConfigs {
    param(
        [Parameter(Mandatory)][string]$OrganizationId,
        [hashtable]$Context
    )
    $record = Get-EntroGcpRunRecord -Context $Context
    $policy = Get-EntroGcpOrganizationPolicy -OrganizationId $OrganizationId
    if (@(Get-EntroGcpMissingAuditServices -Policy $policy).Count -eq 0) {
        if ($record) { $record.AuditResult = 'Already in place' }
        Write-Ok 'Organization audit logs already enabled'
        return
    }

    $managed = Get-EntroGcpAuditServices
    $kept = [System.Collections.Generic.List[object]]::new()
    $byService = @{}
    foreach ($cfg in @($policy['auditConfigs'])) {
        if (-not $cfg) { continue }
        $svc = [string]$cfg['service']
        if ($managed -contains $svc) { $byService[$svc] = $cfg }
        else { $kept.Add($cfg) }
    }
    foreach ($svc in $managed) {
        $logs = [System.Collections.Generic.List[object]]::new()
        $types = @()
        if ($byService.ContainsKey($svc)) {
            foreach ($log in @($byService[$svc]['auditLogConfigs'])) {
                if (-not $log) { continue }
                $logs.Add($log)
                $types += [string]$log['logType']
            }
        }
        foreach ($needed in @('DATA_READ', 'DATA_WRITE')) {
            if ($types -notcontains $needed) { $logs.Add(@{ logType = $needed }) }
        }
        $kept.Add(@{ service = $svc; auditLogConfigs = @($logs) })
    }
    $policy['auditConfigs'] = @($kept)
    $version = [int]$policy['version']
    $policy['version'] = [Math]::Max(1, $version)

    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -LiteralPath $tmp -Value ($policy | ConvertTo-Json -Depth 50) -Encoding utf8
        try {
            Invoke-EntroGcpGcloud -GcloudArgs @('organizations', 'set-iam-policy', $OrganizationId, $tmp) | Out-Null
        }
        catch {
            throw "Could not write audit logs to organization ${OrganizationId}: $($_.Exception.Message). The signed-in account needs permission to set the organization IAM policy, for example roles/resourcemanager.organizationAdmin."
        }
    }
    finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }

    $after = Get-EntroGcpOrganizationPolicy -OrganizationId $OrganizationId
    $stillMissing = @(Get-EntroGcpMissingAuditServices -Policy $after)
    if ($stillMissing.Count -gt 0) {
        throw "Organization audit logs are still missing for: $($stillMissing -join ', ')."
    }
    if ($record) { $record.AuditResult = 'Applied in this run' }
    Write-Ok "Enabled DATA_READ and DATA_WRITE audit logs for $($managed -join ', ')"
}

Export-ModuleMember -Function @(
    'Invoke-EntroGcpPreOnboardingCheck'
    'Invoke-EntroGcpEnableApis'
    'Invoke-EntroGcpIamGrants'
    'Sync-EntroGcpIamReport'
    'Test-EntroGcpIamGrantsComplete'
    'Invoke-EntroGcpEnsureServiceAccount'
    'Test-EntroGcpServiceAccountExists'
    'Invoke-EntroGcpEnsureServiceAccountKey'
    'Test-EntroGcpServiceAccountKeyFile'
    'Get-EntroGcpPreconditionGuidance'
    'Get-EntroGcpBillingGuidance'
    'Get-EntroGcpAuditServices'
    'Test-EntroGcpAuditConfigsComplete'
    'Invoke-EntroGcpAuditConfigs'
    'Format-EntroGcpRunReport'
    'Write-EntroGcpRunReport'
    'Get-EntroGcpRunRecord'
)
