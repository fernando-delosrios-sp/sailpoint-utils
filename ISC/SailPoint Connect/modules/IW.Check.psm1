# Read-only comparison of an existing identity against the integration's requirements.
# Check never creates or updates a tenant object. A missing CLI session produces a
# hand-comparison list instead of a guess.

Set-StrictMode -Version Latest

$script:IntegrationCheckInvoker = $null

function Set-IntegrationCheckInvoker {
    param($Invoker)
    $script:IntegrationCheckInvoker = $Invoker
}

function Get-CheckContextValue {
    param(
        [hashtable]$Context,
        [Parameter(Mandatory)][string]$Name,
        [string]$Default = ''
    )
    if ($Context -and $Context.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace([string]$Context[$Name])) {
        return [string]$Context[$Name]
    }
    return $Default
}

function Get-CheckObjectProperty {
    param($Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [hashtable]) {
        if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        return $null
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    return $null
}

function ConvertFrom-CliJson {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $startObj = $Text.IndexOf('{')
    $startArr = $Text.IndexOf('[')
    $start = -1
    if ($startObj -ge 0 -and ($startArr -lt 0 -or $startObj -lt $startArr)) { $start = $startObj }
    elseif ($startArr -ge 0) { $start = $startArr }
    if ($start -lt 0) { return $null }
    try { return ($Text.Substring($start) | ConvertFrom-Json) }
    catch { return $null }
}

function Invoke-IntegrationCheckCli {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @()
    )
    if ($script:IntegrationCheckInvoker -is [scriptblock]) {
        return & $script:IntegrationCheckInvoker $Command @($Arguments)
    }
    try {
        $output = & $Command @Arguments 2>&1 | Out-String
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 0 }
        return @{ ExitCode = [int]$code; Output = [string]$output }
    }
    catch {
        return @{ ExitCode = 1; Output = $_.Exception.Message }
    }
}

function Test-CliNotFound {
    param($Result)
    if ($null -eq $Result) { return $false }
    if ([int]$Result.ExitCode -eq 0) { return $false }
    return [string]$Result.Output -match 'NoSuchEntity|NotFound|NOT_FOUND|does not exist|ResourceNotFound|was not found|Cannot find'
}

function Get-RequirementToken {
    param([Parameter(Mandatory)][string]$Line)
    $line = $Line.Trim()
    if ($line -eq '*') {
        return @{ Comparable = $true; Family = 'Aws'; Key = '*' }
    }
    if ($line -match '^(repo|read:org|admin:org|manage_billing:copilot|read:audit_log|gist|workflow|user|write:org|read:user|user:email)$' -or $line -match '^gh:[a-z_:]+$') {
        return @{ Comparable = $true; Family = 'GitHub'; Key = $line }
    }
    # Service prefixes such as bedrock-agentcore contain hyphens. Dots stay out of
    # this pattern so a Google IAM permission is not classified as an AWS action.
    if ($line -match '^[A-Za-z0-9*][A-Za-z0-9*-]*:[A-Za-z0-9*][A-Za-z0-9*]*$') {
        return @{ Comparable = $true; Family = 'Aws'; Key = $line }
    }
    if ($line -match '^https://\S+$') {
        return @{ Comparable = $true; Family = 'Scope'; Key = $line }
    }
    if ($line -match '^[a-z][a-z0-9]*(\.[A-Za-z0-9*]+)+$') {
        return @{ Comparable = $true; Family = 'Iam'; Key = $line }
    }
    if ($line -match '^.+:\s+(?<perm>\S+)$') {
        return @{ Comparable = $true; Family = 'Named'; Key = $Matches['perm'] }
    }
    return @{ Comparable = $false; Family = 'Manual'; Key = $line }
}

function Test-AwsActionCoveredBy {
    param(
        [Parameter(Mandatory)][string]$Granted,
        [Parameter(Mandatory)][string]$Required
    )
    if ($Granted -eq '*' -or $Granted -eq $Required) { return $true }
    if ($Granted.EndsWith('*') -and $Granted.Length -gt 1) {
        $prefix = $Granted.Substring(0, $Granted.Length - 1)
        return $Required.StartsWith($prefix)
    }
    return $false
}

function Test-GitHubScopeCoveredBy {
    param(
        [Parameter(Mandatory)][string]$Granted,
        [Parameter(Mandatory)][string]$Required
    )
    if ($Granted -eq $Required) { return $true }
    if ($Granted -eq 'admin:org' -and $Required -in @('read:org', 'write:org', 'admin:org')) { return $true }
    if ($Granted -eq 'repo' -and $Required -in @('repo:status', 'repo_deployment', 'public_repo', 'repo:invite', 'security_events')) { return $true }
    return $false
}

function Test-GrantCoversRequirement {
    param($Grant, $Required)
    if ($Grant.Key -eq $Required.Key) { return $true }
    if ($Required.Family -eq 'Aws' -and $Grant.Family -eq 'Aws') {
        return (Test-AwsActionCoveredBy -Granted $Grant.Key -Required $Required.Key)
    }
    if ($Required.Family -eq 'GitHub' -and $Grant.Family -eq 'GitHub') {
        return (Test-GitHubScopeCoveredBy -Granted $Grant.Key -Required $Required.Key)
    }
    return $false
}

function Get-CheckLinesForAccess {
    param(
        $Lists,
        [string]$Access
    )
    $required = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($Lists.ReadOnly)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$line)) { $required.Add([string]$line) }
    }
    $planning = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($Lists.ReadWrite)) {
        if ([string]::IsNullOrWhiteSpace([string]$line)) { continue }
        if ($Access -eq 'ReadOnly') { $planning.Add([string]$line) }
        else { $required.Add([string]$line) }
    }
    return @{ Required = @($required.ToArray()); PlanningOnly = @($planning.ToArray()) }
}

function Compare-IntegrationRequirementCoverage {
    param(
        [string[]]$Required = @(),
        [string[]]$Granted = @(),
        [string[]]$Denied = @(),
        [string[]]$ReadableFamilies = @()
    )
    # A hashtable written to the pipeline is enumerated into entries, so tokens are
    # collected in a list instead of piped. Loop variables are not named $grant or
    # $denied: those are the same variables as the [string[]] parameters, and
    # assigning $false to a [string[]] becomes the truthy string 'False'.
    $grantTokens = [System.Collections.Generic.List[object]]::new()
    foreach ($grantedAction in @($Granted)) {
        if ([string]::IsNullOrWhiteSpace([string]$grantedAction)) { continue }
        $grantedToken = Get-RequirementToken -Line ([string]$grantedAction)
        if ($grantedToken.Comparable) { $grantTokens.Add($grantedToken) }
    }
    $denyTokens = [System.Collections.Generic.List[object]]::new()
    foreach ($deniedAction in @($Denied)) {
        if ([string]::IsNullOrWhiteSpace([string]$deniedAction)) { continue }
        $deniedToken = Get-RequirementToken -Line ([string]$deniedAction)
        if ($deniedToken.Comparable) { $denyTokens.Add($deniedToken) }
    }
    $met = [System.Collections.Generic.List[string]]::new()
    $missing = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($Required)) {
        if ([string]::IsNullOrWhiteSpace([string]$line)) { continue }
        $requiredToken = Get-RequirementToken -Line ([string]$line)
        if (-not $requiredToken.Comparable -or @($ReadableFamilies) -notcontains $requiredToken.Family) {
            $manual.Add([string]$line)
            continue
        }
        $isDenied = $false
        foreach ($denyToken in $denyTokens) {
            if (Test-GrantCoversRequirement -Grant $denyToken -Required $requiredToken) { $isDenied = $true; break }
        }
        if ($isDenied) {
            $missing.Add("$line (denied by the identity's policy)")
            continue
        }
        $isCovered = $false
        foreach ($grantToken in $grantTokens) {
            if (Test-GrantCoversRequirement -Grant $grantToken -Required $requiredToken) { $isCovered = $true; break }
        }
        if ($isCovered) { $met.Add([string]$line) } else { $missing.Add([string]$line) }
    }
    return @{
        Met     = @($met.ToArray())
        Missing = @($missing.ToArray())
        Manual  = @($manual.ToArray())
    }
}

function Get-IamStatementList {
    param($Document)
    if ($null -eq $Document) { return @() }
    if ($Document -is [string]) {
        $text = [string]$Document
        if ($text.Contains('%')) {
            try { $text = [uri]::UnescapeDataString($text) } catch { }
        }
        $Document = ConvertFrom-CliJson -Text $text
    }
    $statements = Get-CheckObjectProperty -Object $Document -Name 'Statement'
    if ($null -eq $statements) { return @() }
    return @($statements)
}

function Get-IamPolicyGrantSet {
    param($Document)
    $allow = [System.Collections.Generic.List[string]]::new()
    $deny = [System.Collections.Generic.List[string]]::new()
    $notAction = $false
    foreach ($stmt in @(Get-IamStatementList -Document $Document)) {
        if ($null -ne (Get-CheckObjectProperty -Object $stmt -Name 'NotAction')) { $notAction = $true }
        $actions = @(Get-CheckObjectProperty -Object $stmt -Name 'Action')
        $effect = [string](Get-CheckObjectProperty -Object $stmt -Name 'Effect')
        # Assign the list directly. An if-expression would write the list to the
        # pipeline and enumerate it, so an empty list arrives as $null.
        $bucket = $allow
        if ($effect -eq 'Deny') { $bucket = $deny }
        foreach ($action in @($actions)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$action)) { $bucket.Add([string]$action) }
        }
    }
    return @{
        Allow     = @($allow.ToArray())
        Deny      = @($deny.ToArray())
        NotAction = [bool]$notAction
    }
}

function New-CheckSubject {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Label,
        [string]$Name = '',
        [string]$Note = '',
        [string[]]$ReadableFamilies = @(),
        [bool]$Readable = $false
    )
    return @{
        Kind              = $Kind
        Label             = $Label
        Name              = $Name
        Note              = $Note
        Readable          = $Readable
        ReadableFamilies  = @($ReadableFamilies)
    }
}

function Get-IntegrationCheckSubject {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [hashtable]$Context = @{}
    )
    $id = [string]$Definition.Id
    switch -Regex ($id) {
        '^aws-saas-connector$' {
            return New-CheckSubject -Kind 'IamRole' -Label 'IAM role' -Readable $true -ReadableFamilies @('Aws') `
                -Name (Get-CheckContextValue -Context $Context -Name 'RoleName' -Default 'SailPointAWSRole') `
                -Note 'Reads the role policy. Does not create the role or attach anything.'
        }
        '^aws-ciem-connector$' {
            return New-CheckSubject -Kind 'IamRole' -Label 'IAM role' -Readable $true -ReadableFamilies @('Aws') `
                -Name (Get-CheckContextValue -Context $Context -Name 'RoleName' -Default 'SailPointCIEMAuditRole') `
                -Note 'Reads the role policy. Does not create the role or change CloudFormation.'
        }
        '^aws-entro$' {
            return New-CheckSubject -Kind 'IamRole' -Label 'IAM role' -Readable $true -ReadableFamilies @('Aws') `
                -Name (Get-CheckContextValue -Context $Context -Name 'EntroRoleName' -Default 'EntroReadOnly') `
                -Note 'Reads the Entro role policy. Does not create the role.'
        }
        '^azure-connector$' {
            return New-CheckSubject -Kind 'EntraApplication' -Label 'Entra app registration' -Readable $true -ReadableFamilies @('Named') `
                -Name (Get-CheckContextValue -Context $Context -Name 'ApplicationName') `
                -Note 'Reads admin-consented application permissions on the existing service principal. Does not create the app or grant consent.'
        }
        '^azure-entro$' {
            return New-CheckSubject -Kind 'EntraApplication' -Label 'Entra app registration' -Readable $true -ReadableFamilies @('Named') `
                -Name (Get-CheckContextValue -Context $Context -Name 'DisplayName' -Default 'EntroSecurityApp') `
                -Note 'Reads admin-consented application permissions. Does not run Entro onboarding.'
        }
        '^google-(saas|ciem)-connector$' {
            $project = Get-CheckContextValue -Context $Context -Name 'ProjectId'
            $account = Get-CheckContextValue -Context $Context -Name 'ServiceAccountId' -Default 'sailpoint-isc-gws'
            $email = if ($account -match '@') { $account } elseif ($project -and $account) { "$account@$project.iam.gserviceaccount.com" } else { '' }
            return New-CheckSubject -Kind 'GcpServiceAccount' -Label 'Google service account' -Readable $true -ReadableFamilies @('Iam') `
                -Name $email `
                -Note 'Reads IAM permissions granted to the service account. Domain-wide delegation and OAuth scopes are set in the Admin console and are listed for you to compare. Nothing is created.'
        }
        '^google-gcp-entro$' {
            $project = Get-CheckContextValue -Context $Context -Name 'ProjectId'
            $account = Get-CheckContextValue -Context $Context -Name 'ServiceAccountName' -Default 'entro-automatic-onboard'
            $email = if ($account -match '@') { $account } elseif ($project -and $account) { "$account@$project.iam.gserviceaccount.com" } else { '' }
            return New-CheckSubject -Kind 'GcpServiceAccount' -Label 'Google service account' -Readable $true -ReadableFamilies @('Iam') `
                -Name $email `
                -Note 'Reads IAM permissions granted to the Entro service account. Does not create the account or grant roles.'
        }
        '^google-workspace-entro$' {
            return New-CheckSubject -Kind 'Manual' -Label 'Domain-wide delegation' `
                -Name (Get-CheckContextValue -Context $Context -Name 'ClientId') `
                -Note 'Domain-wide delegation is authorized in the Google Workspace Admin console. This check cannot read it. Nothing was changed.'
        }
        '^databricks-connector$' {
            $name = Get-CheckContextValue -Context $Context -Name 'ServicePrincipalName' -Default 'SailPoint-source'
            $account = Get-CheckContextValue -Context $Context -Name 'AccountId'
            return New-CheckSubject -Kind 'Manual' -Label 'Databricks account service principal' -Name $name `
                -Note "Open account service principal '$name'$(if ($account) { " on account $account" }) and confirm it is an Account Admin. This check does not call Databricks and does not create the principal."
        }
        '^salesforce-connector$' {
            $url = Get-CheckContextValue -Context $Context -Name 'InstanceUrl'
            return New-CheckSubject -Kind 'Manual' -Label 'Salesforce Connected App' `
                -Name (Get-CheckContextValue -Context $Context -Name 'ConsumerKey') `
                -Note "Compare the Connected App$(if ($url) { " on $url" }) and the integration user's permissions with the requirements checklist. This check does not call Salesforce."
        }
        '^github-(connector|entro)$' {
            $token = Get-CheckContextValue -Context $Context -Name 'Token'
            $maskedToken = if ($token) {
                if ($token.Length -gt 8) { $token.Substring(0, 4) + '...' + $token.Substring($token.Length - 4) } else { '***' }
            } else { '' }
            $name = if ($maskedToken) { "PAT ($maskedToken)" } else { 'GitHub PAT (CLI session / token)' }
            return New-CheckSubject -Kind 'GitHubToken' -Label 'GitHub Personal Access Token' -Readable $true -ReadableFamilies @('GitHub') `
                -Name $name `
                -Note 'Reads granted OAuth / PAT scopes via GitHub API (/user). Does not change any repository, org, or token.'
        }
        '^crowdstrike-connector$' {
            return New-CheckSubject -Kind 'Manual' -Label 'CrowdStrike API client' `
                -Name (Get-CheckContextValue -Context $Context -Name 'ClientId') `
                -Note 'Compare the API client scopes with the requirements checklist. This check does not call CrowdStrike.'
        }
        default {
            $title = if ($Definition['Title']) { [string]$Definition.Title } else { $id }
            return New-CheckSubject -Kind 'Manual' -Label $title `
                -Note 'This integration does not expose one role or application this check can read. Use BuildRequirements for the checklist. Nothing was changed.'
        }
    }
}

function Read-AwsIamRoleGrants {
    param(
        [Parameter(Mandatory)][string]$RoleName,
        [hashtable]$Context = @{}
    )
    $prefix = @()
    $profileName = Get-CheckContextValue -Context $Context -Name 'ProfileName'
    if ($profileName) { $prefix = @('--profile', $profileName) }
    $role = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'get-role', '--role-name', $RoleName, '--output', 'json'))
    if (Test-CliNotFound -Result $role) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $false; Note = "No IAM role named $RoleName was found. Nothing was changed." }
    }
    if ([int]$role.ExitCode -ne 0) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $true; Note = "Could not read IAM role $RoleName. $([string]$role.Output)".Trim() + ' Nothing was changed.' }
    }
    $allow = [System.Collections.Generic.List[string]]::new()
    $deny = [System.Collections.Generic.List[string]]::new()
    $notes = [System.Collections.Generic.List[string]]::new()
    $incomplete = $false

    $attached = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'list-attached-role-policies', '--role-name', $RoleName, '--output', 'json'))
    if ([int]$attached.ExitCode -ne 0) {
        $incomplete = $true
        $notes.Add('Could not list attached policies.')
    }
    else {
        foreach ($policy in @(Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$attached.Output)) -Name 'AttachedPolicies')) {
            $arn = [string](Get-CheckObjectProperty -Object $policy -Name 'PolicyArn')
            if (-not $arn) { continue }
            $meta = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'get-policy', '--policy-arn', $arn, '--output', 'json'))
            $versionId = [string](Get-CheckObjectProperty -Object (Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$meta.Output)) -Name 'Policy') -Name 'DefaultVersionId')
            if ([int]$meta.ExitCode -ne 0 -or -not $versionId) {
                $incomplete = $true
                $notes.Add("Could not read policy $arn.")
                continue
            }
            $version = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'get-policy-version', '--policy-arn', $arn, '--version-id', $versionId, '--output', 'json'))
            $document = Get-CheckObjectProperty -Object (Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$version.Output)) -Name 'PolicyVersion') -Name 'Document'
            if ([int]$version.ExitCode -ne 0 -or $null -eq $document) {
                $incomplete = $true
                $notes.Add("Could not read the default version of $arn.")
                continue
            }
            $set = Get-IamPolicyGrantSet -Document $document
            foreach ($item in @($set.Allow)) { $allow.Add($item) }
            foreach ($item in @($set.Deny)) { $deny.Add($item) }
            if ($set.NotAction) { $notes.Add("Policy $arn uses NotAction. Those statements were not expanded.") ; $incomplete = $true }
        }
    }

    $inline = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'list-role-policies', '--role-name', $RoleName, '--output', 'json'))
    if ([int]$inline.ExitCode -ne 0) {
        $incomplete = $true
        $notes.Add('Could not list inline policies.')
    }
    else {
        foreach ($policyName in @(Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$inline.Output)) -Name 'PolicyNames')) {
            $name = [string]$policyName
            if (-not $name) { continue }
            $docResult = Invoke-IntegrationCheckCli -Command 'aws' -Arguments ($prefix + @('iam', 'get-role-policy', '--role-name', $RoleName, '--policy-name', $name, '--output', 'json'))
            $document = Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$docResult.Output)) -Name 'PolicyDocument'
            if ([int]$docResult.ExitCode -ne 0 -or $null -eq $document) {
                $incomplete = $true
                $notes.Add("Could not read inline policy $name.")
                continue
            }
            $set = Get-IamPolicyGrantSet -Document $document
            foreach ($item in @($set.Allow)) { $allow.Add($item) }
            foreach ($item in @($set.Deny)) { $deny.Add($item) }
            if ($set.NotAction) { $notes.Add("Inline policy $name uses NotAction. Those statements were not expanded.") ; $incomplete = $true }
        }
    }

    return @{
        Found      = $true
        Grants     = @($allow.ToArray())
        Denied     = @($deny.ToArray())
        Incomplete = [bool]$incomplete
        Note       = ($notes -join ' ')
    }
}

function Read-EntraApplicationGrants {
    param([Parameter(Mandatory)][string]$DisplayName)
    $appsResult = Invoke-IntegrationCheckCli -Command 'az' -Arguments @('ad', 'app', 'list', '--display-name', $DisplayName, '-o', 'json')
    if ([int]$appsResult.ExitCode -ne 0) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $true; Note = "Could not list app registrations. $([string]$appsResult.Output)".Trim() + ' Nothing was changed.' }
    }
    $matchedApps = @(@(ConvertFrom-CliJson -Text ([string]$appsResult.Output)) | Where-Object {
            [string](Get-CheckObjectProperty -Object $_ -Name 'displayName') -eq $DisplayName
        })
    if ($matchedApps.Count -eq 0) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $false; Note = "No app registration named $DisplayName was found. Nothing was changed." }
    }
    if ($matchedApps.Count -gt 1) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $true; Note = "More than one app registration is named $DisplayName. Nothing was changed." }
    }
    $appId = [string](Get-CheckObjectProperty -Object $matchedApps[0] -Name 'appId')
    $spResult = Invoke-IntegrationCheckCli -Command 'az' -Arguments @('ad', 'sp', 'list', '--filter', "appId eq '$appId'", '-o', 'json')
    $servicePrincipals = @()
    if ([int]$spResult.ExitCode -eq 0) {
        $servicePrincipals = @(@(ConvertFrom-CliJson -Text ([string]$spResult.Output)) | Where-Object {
                [string](Get-CheckObjectProperty -Object $_ -Name 'appId') -eq $appId
            })
    }
    if ($servicePrincipals.Count -eq 0) {
        return @{ Found = $true; Grants = @(); Denied = @(); Incomplete = $false; Note = "App registration $DisplayName exists but has no service principal, so it cannot sign in and has no granted permissions. Nothing was changed." }
    }
    $spId = [string](Get-CheckObjectProperty -Object $servicePrincipals[0] -Name 'id')
    $assignUri = "https://graph.microsoft.com/v1.0/servicePrincipals/$spId/appRoleAssignments"
    $assigned = Invoke-IntegrationCheckCli -Command 'az' -Arguments @('rest', '--method', 'GET', '--uri', $assignUri)
    if ([int]$assigned.ExitCode -ne 0) {
        return @{ Found = $true; Grants = @(); Denied = @(); Incomplete = $true; Note = "Could not read granted app roles for $DisplayName. Nothing was changed." }
    }
    $assignmentObject = ConvertFrom-CliJson -Text ([string]$assigned.Output)
    $assignments = @(Get-CheckObjectProperty -Object $assignmentObject -Name 'value')
    $byResource = @{}
    foreach ($assignment in @($assignments)) {
        $resourceId = [string](Get-CheckObjectProperty -Object $assignment -Name 'resourceId')
        $roleId = [string](Get-CheckObjectProperty -Object $assignment -Name 'appRoleId')
        if (-not $resourceId -or -not $roleId) { continue }
        if (-not $byResource.ContainsKey($resourceId)) { $byResource[$resourceId] = [System.Collections.Generic.List[string]]::new() }
        $byResource[$resourceId].Add($roleId)
    }
    $grants = [System.Collections.Generic.List[string]]::new()
    $incomplete = $false
    $notes = [System.Collections.Generic.List[string]]::new()
    foreach ($resourceId in @($byResource.Keys)) {
        $uri = 'https://graph.microsoft.com/v1.0/servicePrincipals/' + $resourceId + '?$select=appRoles,displayName'
        $resource = Invoke-IntegrationCheckCli -Command 'az' -Arguments @('rest', '--method', 'GET', '--uri', $uri)
        $resourceObject = ConvertFrom-CliJson -Text ([string]$resource.Output)
        if ([int]$resource.ExitCode -ne 0 -or $null -eq $resourceObject) {
            $incomplete = $true
            $notes.Add("Could not resolve app roles for resource $resourceId.")
            continue
        }
        $roles = @(Get-CheckObjectProperty -Object $resourceObject -Name 'appRoles')
        foreach ($roleId in @($byResource[$resourceId])) {
            $matchedRole = @($roles | Where-Object { [string](Get-CheckObjectProperty -Object $_ -Name 'id') -eq $roleId } | Select-Object -First 1)
            $value = if ($matchedRole) { [string](Get-CheckObjectProperty -Object $matchedRole[0] -Name 'value') } else { '' }
            if ($value) { $grants.Add($value) }
            else {
                $incomplete = $true
                $notes.Add("Granted role id $roleId has no permission name.")
            }
        }
    }
    return @{
        Found      = $true
        Grants     = @($grants.ToArray())
        Denied     = @()
        Incomplete = [bool]$incomplete
        Note       = $(if ($notes.Count) { $notes -join ' ' } else { 'Compared granted application permissions (admin consent), not permissions that are only requested.' })
    }
}

function Add-GcpBindingRoles {
    param(
        $Policy,
        [Parameter(Mandatory)][string]$Member,
        $Roles
    )
    foreach ($binding in @(Get-CheckObjectProperty -Object $Policy -Name 'bindings')) {
        $role = [string](Get-CheckObjectProperty -Object $binding -Name 'role')
        if (-not $role) { continue }
        $members = @((Get-CheckObjectProperty -Object $binding -Name 'members') | ForEach-Object { [string]$_ })
        if ($members -contains $Member -or $members -contains ($Member -replace '^serviceAccount:', '')) {
            if (-not $Roles.Contains($role)) { [void]$Roles.Add($role) }
        }
    }
}

function Read-GcpServiceAccountGrants {
    param(
        [Parameter(Mandatory)][string]$Email,
        [Parameter(Mandatory)][string]$ProjectId,
        [string]$OrganizationId = ''
    )
    $describe = Invoke-IntegrationCheckCli -Command 'gcloud' -Arguments @('iam', 'service-accounts', 'describe', $Email, "--project=$ProjectId", '--format=json')
    if (Test-CliNotFound -Result $describe) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $false; Note = "No service account $Email was found. Nothing was changed." }
    }
    if ([int]$describe.ExitCode -ne 0) {
        return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $true; Note = "Could not read service account $Email. Nothing was changed." }
    }
    $roles = [System.Collections.Generic.List[string]]::new()
    $member = "serviceAccount:$Email"
    $projectPolicy = Invoke-IntegrationCheckCli -Command 'gcloud' -Arguments @('projects', 'get-iam-policy', $ProjectId, '--format=json')
    if ([int]$projectPolicy.ExitCode -eq 0) {
        Add-GcpBindingRoles -Policy (ConvertFrom-CliJson -Text ([string]$projectPolicy.Output)) -Member $member -Roles $roles
    }
    if ($OrganizationId) {
        $orgPolicy = Invoke-IntegrationCheckCli -Command 'gcloud' -Arguments @('organizations', 'get-iam-policy', $OrganizationId, '--format=json')
        if ([int]$orgPolicy.ExitCode -eq 0) {
            Add-GcpBindingRoles -Policy (ConvertFrom-CliJson -Text ([string]$orgPolicy.Output)) -Member $member -Roles $roles
        }
    }
    $grants = [System.Collections.Generic.List[string]]::new()
    $notes = [System.Collections.Generic.List[string]]::new()
    $incomplete = $false
    foreach ($role in @($roles)) {
        $described = Invoke-IntegrationCheckCli -Command 'gcloud' -Arguments @('iam', 'roles', 'describe', $role, '--format=json')
        if ([int]$described.ExitCode -ne 0 -and $OrganizationId -and $role -notmatch '/') {
            $described = Invoke-IntegrationCheckCli -Command 'gcloud' -Arguments @('iam', 'roles', 'describe', $role, "--organization=$OrganizationId", '--format=json')
        }
        $permissions = @(Get-CheckObjectProperty -Object (ConvertFrom-CliJson -Text ([string]$described.Output)) -Name 'includedPermissions')
        if ([int]$described.ExitCode -ne 0 -or $permissions.Count -eq 0) {
            $incomplete = $true
            $notes.Add("Could not expand role $role.")
            continue
        }
        foreach ($permission in @($permissions)) {
            if ($permission) { $grants.Add([string]$permission) }
        }
    }
    if ($roles.Count -eq 0) {
        $notes.Add('The service account has no project or organization IAM bindings in the policies that were read.')
    }
    return @{
        Found      = $true
        Grants     = @($grants.ToArray())
        Denied     = @()
        Incomplete = [bool]$incomplete
        Note       = ($notes -join ' ')
    }
}

function Invoke-GitHubApiProbe {
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [string]$Token,
        [string]$ApiUrl = 'https://api.github.com'
    )
    $statusCode = 0
    $headers = @{}
    $output = ''

    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $res = Invoke-IntegrationCheckCli -Command 'gh' -Arguments @('api', $Endpoint, '--include', '-H', "Authorization: Bearer $Token")
        if (Test-CliNotFound -Result $res) {
            try {
                $reqHeaders = @{
                    'Authorization' = "Bearer $Token"
                    'User-Agent'    = 'SailPoint-Connect'
                    'Accept'        = 'application/vnd.github+json'
                }
                $uri = "$($ApiUrl.TrimEnd('/'))$Endpoint"
                $webRes = Invoke-WebRequest -Uri $uri -Headers $reqHeaders -TimeoutSec 10 -ErrorAction Stop
                $statusCode = [int]$webRes.StatusCode
                foreach ($k in $webRes.Headers.Keys) {
                    $val = $webRes.Headers[$k]
                    $headers[[string]$k.ToLower()] = if ($val -is [array]) { $val -join ',' } else { [string]$val }
                }
                $output = "HTTP/2.0 $($statusCode) OK`r`n`r`n$($webRes.Content)"
            }
            catch {
                if ($_.Exception.Response) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                    if ($_.Exception.Response.Headers) {
                        foreach ($k in $_.Exception.Response.Headers.Keys) {
                            $val = $_.Exception.Response.Headers[$k]
                            $headers[[string]$k.ToLower()] = if ($val -is [array]) { $val -join ',' } else { [string]$val }
                        }
                    }
                }
                else {
                    $statusCode = 0
                }
                $output = [string]$_.Exception.Message
            }
        }
        else {
            $output = [string]$res.Output
            if ([int]$res.ExitCode -eq 0 -and $statusCode -eq 0) {
                $statusCode = 200
            }
        }
    }
    else {
        $res = Invoke-IntegrationCheckCli -Command 'gh' -Arguments @('api', $Endpoint, '--include')
        $output = [string]$res.Output
        if ([int]$res.ExitCode -eq 0 -and $statusCode -eq 0) {
            $statusCode = 200
        }
    }

    if ($output) {
        if ($output -match '(?i)^HTTP/\S+\s+(?<status>\d{3})') {
            $statusCode = [int]$Matches['status']
        }
        elseif ($output -match '(?i)\(HTTP\s+(?<status>\d{3})\)') {
            $statusCode = [int]$Matches['status']
        }
        elseif ($output -match '(?i)401\s+Unauthorized|Bad credentials') {
            $statusCode = 401
        }
        elseif ($output -match '(?i)403\s+Forbidden') {
            $statusCode = 403
        }
        elseif ($output -match '(?i)404\s+Not Found') {
            $statusCode = 404
        }
    }

    foreach ($line in ($output -split "`r?`n")) {
        if ($line -match '^(?<name>[A-Za-z0-9_-]+):\s*(?<val>.*)$') {
            $hName = $Matches['name'].ToLower()
            if (-not $headers.ContainsKey($hName)) {
                $headers[$hName] = $Matches['val'].Trim()
            }
        }
    }

    $ssoRequired = ($headers.ContainsKey('x-github-sso') -and $headers['x-github-sso'] -match '(?i)required')
    if (-not $ssoRequired -and $output -match '(?i)x-github-sso:\s*required') {
        $ssoRequired = $true
    }

    return @{
        StatusCode  = $statusCode
        Headers     = $headers
        Output      = $output
        Success     = ($statusCode -ge 200 -and $statusCode -lt 300)
        SsoRequired = $ssoRequired
    }
}

function Read-GitHubTokenGrants {
    param(
        [hashtable]$Context = @{}
    )
    $token = Get-CheckContextValue -Context $Context -Name 'Token'
    $org = Get-CheckContextValue -Context $Context -Name 'Organization'
    $project = Get-CheckContextValue -Context $Context -Name 'Project'
    $apiUrl = Get-CheckContextValue -Context $Context -Name 'ApiUrl' -Default 'https://api.github.com'

    $scopes = [System.Collections.Generic.List[string]]::new()
    $notes = [System.Collections.Generic.List[string]]::new()
    $userLogin = ''

    # Step 1: Probe /user to validate credential & identity
    $userProbe = Invoke-GitHubApiProbe -Endpoint '/user' -Token $token -ApiUrl $apiUrl
    if ($userProbe.StatusCode -eq 401 -or $userProbe.Output -match '(?i)401\s+Unauthorized|Bad credentials') {
        return @{
            Found      = $false
            Grants     = @()
            Denied     = @()
            Incomplete = $true
            Note       = 'GitHub token authentication failed: Bad credentials (token may be expired or invalid).'
        }
    }
    if ($userProbe.StatusCode -ne 0 -and -not $userProbe.Success) {
        return @{
            Found      = $false
            Grants     = @()
            Denied     = @()
            Incomplete = $true
            Note       = "GitHub authentication failed (HTTP $($userProbe.StatusCode)). Provide a valid token or run: gh auth login"
        }
    }

    # Extract user login
    $json = ConvertFrom-CliJson -Text $userProbe.Output
    if ($json) {
        $login = Get-CheckObjectProperty -Object $json -Name 'login'
        if ($login) { $userLogin = [string]$login }
    }
    if ($userLogin) {
        $notes.Add("Verified token for GitHub user '$userLogin'.")
    }

    # Step 2: Check for OAuth scopes header (Classic PAT or OAuth token)
    $hasOAuthScopes = $false
    $rawScopes = ''
    if ($userProbe.Headers.ContainsKey('x-oauth-scopes')) {
        $rawScopes = $userProbe.Headers['x-oauth-scopes']
        $hasOAuthScopes = $true
    }
    else {
        foreach ($line in ($userProbe.Output -split "`r?`n")) {
            if ($line -match '(?i)^x-oauth-scopes:\s*(?<scopes>.*)$') {
                $rawScopes = $Matches['scopes']
                $hasOAuthScopes = $true
                break
            }
        }
    }

    if ($hasOAuthScopes) {
        foreach ($s in ($rawScopes -split ',')) {
            $trimmed = $s.Trim()
            if ($trimmed) { $scopes.Add($trimmed) }
        }
        $notes.Add("Classic PAT / OAuth scopes: $(if ($scopes.Count -gt 0) { $scopes -join ', ' } else { '(none)' }).")

        # Even with classic scopes, if an organization is specified, verify SSO isn't blocking it
        if (-not [string]::IsNullOrWhiteSpace($org) -and $scopes.Contains('read:org')) {
            $orgSsoProbe = Invoke-GitHubApiProbe -Endpoint "/orgs/$org" -Token $token -ApiUrl $apiUrl
            if ($orgSsoProbe.SsoRequired -or ($orgSsoProbe.StatusCode -eq 403 -and $orgSsoProbe.Output -match '(?i)sso')) {
                $scopes.Remove('read:org') | Out-Null
                $notes.Add("Organization '$org' enforces SAML SSO. The token has not been authorized for SSO (read:org suspended until authorized).")
            }
        }
    }
    else {
        # Fine-grained PAT: no X-OAuth-Scopes header returned by GitHub.
        # Must actively probe endpoints to verify granted permissions.
        $notes.Add('Fine-grained PAT detected (probing API endpoints for granted access).')

        # Determine target organization if specified or inferable from project
        $targetOrg = $org
        if ([string]::IsNullOrWhiteSpace($targetOrg) -and -not [string]::IsNullOrWhiteSpace($project)) {
            $checkProjectOrg = Invoke-GitHubApiProbe -Endpoint "/orgs/$project" -Token $token -ApiUrl $apiUrl
            if ($checkProjectOrg.Success) {
                $targetOrg = $project
            }
        }

        # Probe 1: Organization access (read:org equivalent)
        if (-not [string]::IsNullOrWhiteSpace($targetOrg)) {
            $orgProbe = Invoke-GitHubApiProbe -Endpoint "/orgs/$targetOrg" -Token $token -ApiUrl $apiUrl
            if ($orgProbe.Success) {
                $scopes.Add('read:org')
                $notes.Add("Verified read access to organization '$targetOrg'.")
            }
            elseif ($orgProbe.SsoRequired) {
                $notes.Add("Organization access to '$targetOrg' requires SAML SSO authorization (token is not authorized for SSO).")
            }
            else {
                $notes.Add("Organization access check for '$targetOrg' failed (HTTP $($orgProbe.StatusCode)).")
            }
        }
        else {
            $orgProbe = Invoke-GitHubApiProbe -Endpoint '/user/orgs?per_page=1' -Token $token -ApiUrl $apiUrl
            if ($orgProbe.Success) {
                $orgJson = ConvertFrom-CliJson -Text $orgProbe.Output
                $orgCount = if ($orgJson -is [array]) { $orgJson.Count } elseif ($orgJson) { 1 } else { 0 }
                if ($orgCount -gt 0) {
                    $scopes.Add('read:org')
                    $notes.Add('Verified organization membership read access (/user/orgs returned accessible organizations).')
                }
                else {
                    $notes.Add('Token has no accessible organizations (/user/orgs returned 0 organizations).')
                }
            }
            elseif ($orgProbe.SsoRequired) {
                $notes.Add('Organization access requires SAML SSO authorization.')
            }
            else {
                $notes.Add("Token lacks organization read permissions (/user/orgs returned HTTP $($orgProbe.StatusCode)).")
            }
        }

        # Probe 2: Repository access (repo equivalent)
        $repoEndpoint = if (-not [string]::IsNullOrWhiteSpace($targetOrg)) { "/orgs/$targetOrg/repos?per_page=1" } else { '/user/repos?per_page=1' }
        $repoProbe = Invoke-GitHubApiProbe -Endpoint $repoEndpoint -Token $token -ApiUrl $apiUrl
        if ($repoProbe.Success) {
            $repoJson = ConvertFrom-CliJson -Text $repoProbe.Output
            $repoCount = if ($repoJson -is [array]) { $repoJson.Count } elseif ($repoJson) { 1 } else { 0 }
            if ($repoCount -gt 0) {
                $scopes.Add('repo')
                $notes.Add("Verified repository read access ($repoEndpoint returned accessible repositories).")
            }
            else {
                $notes.Add("Token has no accessible repositories ($repoEndpoint returned 0 repositories).")
            }
        }
        elseif ($repoProbe.SsoRequired) {
            $notes.Add('Repository access requires SAML SSO authorization.')
        }
        else {
            $notes.Add("Token lacks repository read access ($repoEndpoint returned HTTP $($repoProbe.StatusCode)).")
        }

        # Probe 3: Audit log access (read:audit_log equivalent) if org is known
        if (-not [string]::IsNullOrWhiteSpace($targetOrg)) {
            $auditProbe = Invoke-GitHubApiProbe -Endpoint "/orgs/$targetOrg/audit-log?per_page=1" -Token $token -ApiUrl $apiUrl
            if ($auditProbe.Success) {
                $scopes.Add('read:audit_log')
            }
        }

        # Probe 4: Admin org / teams access (admin:org equivalent) if org is known
        if (-not [string]::IsNullOrWhiteSpace($targetOrg)) {
            $teamsProbe = Invoke-GitHubApiProbe -Endpoint "/orgs/$targetOrg/teams?per_page=1" -Token $token -ApiUrl $apiUrl
            if ($teamsProbe.Success) {
                $scopes.Add('admin:org')
            }
        }
    }

    return @{
        Found      = $true
        Grants     = @($scopes.ToArray())
        Denied     = @()
        Incomplete = $false
        Note       = ($notes -join ' ')
    }
}

function Read-IntegrationIdentityGrants {
    param(
        [Parameter(Mandatory)][hashtable]$Subject,
        [hashtable]$Context = @{}
    )
    switch ($Subject.Kind) {
        'IamRole' { return Read-AwsIamRoleGrants -RoleName $Subject.Name -Context $Context }
        'EntraApplication' { return Read-EntraApplicationGrants -DisplayName $Subject.Name }
        'GcpServiceAccount' {
            $project = Get-CheckContextValue -Context $Context -Name 'ProjectId'
            $org = Get-CheckContextValue -Context $Context -Name 'OrganizationId'
            return Read-GcpServiceAccountGrants -Email $Subject.Name -ProjectId $project -OrganizationId $org
        }
        'GitHubToken' {
            return Read-GitHubTokenGrants -Context $Context
        }
        default {
            return @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $false; Note = $Subject.Note }
        }
    }
}

function Get-IntegrationCheckVerdict {
    param(
        [bool]$AttemptedRead,
        [bool]$Found,
        [bool]$Incomplete,
        [int]$RequiredCount,
        [int]$MissingCount,
        [int]$ManualCount
    )
    if ($RequiredCount -eq 0) { return 'Review' }
    if (-not $AttemptedRead) { return 'Review' }
    if (-not $Found) { return 'Fail' }
    if ($MissingCount -gt 0) { return 'Fail' }
    if ($Incomplete -or $ManualCount -gt 0) { return 'Review' }
    return 'Pass'
}

function Get-IntegrationCheckVerdictText {
    param([Parameter(Mandatory)][string]$Verdict)
    switch ($Verdict) {
        'Pass' { return 'Meets the requirements' }
        'Fail' { return 'Does not meet the requirements' }
        default { return 'Needs a person to finish the comparison' }
    }
}

function Get-WorstCheckVerdict {
    param([string[]]$Verdicts)
    if (@($Verdicts) -contains 'Fail') { return 'Fail' }
    if (@($Verdicts) -contains 'Review') { return 'Review' }
    if (@($Verdicts) -contains 'Pass') { return 'Pass' }
    return 'Review'
}

function Add-CheckBulletList {
    param($Builder, [string]$Heading, [string[]]$Items)
    if (@($Items).Count -eq 0) { return }
    [void]$Builder.AppendLine("#### $Heading")
    [void]$Builder.AppendLine('')
    foreach ($item in @($Items)) { [void]$Builder.AppendLine("- ``$item``") }
    [void]$Builder.AppendLine('')
}

function Get-RequirementDescription {
    param([Parameter(Mandatory)][string]$Line)
    switch -Regex ($Line.Trim()) {
        '^repo$' { return 'Repository read access (contents, metadata, branches)' }
        '^read:org$' { return 'Organization read access (profile and membership)' }
        '^admin:org$' { return 'Organization administration (teams, installed apps, bot discovery)' }
        '^manage_billing:copilot$' { return 'GitHub Copilot billing and seat discovery' }
        '^read:audit_log$' { return 'Organization audit log read access' }
        default { return '' }
    }
}

function Format-IntegrationCheckSection {
    param([Parameter(Mandatory)][hashtable]$Result)
    $sb = [System.Text.StringBuilder]::new()
    $identity = if ($Result.Subject.Name) { "$($Result.Subject.Label) ``$($Result.Subject.Name)``" } else { $Result.Subject.Label }
    [void]$sb.AppendLine("## $identity")
    [void]$sb.AppendLine('')
    $verdictText = Get-IntegrationCheckVerdictText -Verdict $Result.Verdict
    [void]$sb.AppendLine("**$verdictText.**")
    [void]$sb.AppendLine('')
    if ($Result.Subject.Note) { [void]$sb.AppendLine($Result.Subject.Note); [void]$sb.AppendLine('') }
    if ($Result.ReadNote) { [void]$sb.AppendLine($Result.ReadNote); [void]$sb.AppendLine('') }
    if (-not $Result.AttemptedRead) {
        [void]$sb.AppendLine('The live identity was not read. The list below is what to compare. Nothing was changed.')
        [void]$sb.AppendLine('')
    }

    # Explicit Requirements Table: clearly stating what the requirements are and how each was evaluated
    $requiredList = @($Result.Required)
    if ($requiredList.Count -gt 0) {
        [void]$sb.AppendLine('### Required Permissions & Evaluation')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| Requirement | Purpose | Status |')
        [void]$sb.AppendLine('| :--- | :--- | :--- |')
        foreach ($req in $requiredList) {
            $desc = Get-RequirementDescription -Line $req
            if (-not $desc) { $desc = 'Integration access requirement' }
            $status = if (@($Result.Met) -contains $req) {
                '**Present**'
            }
            elseif (@($Result.Missing) -contains $req -or (@($Result.Missing) | Where-Object { $_ -like "$req *" })) {
                '**MISSING**'
            }
            elseif (@($Result.Manual) -contains $req) {
                'Manual comparison'
            }
            else {
                'Not evaluated'
            }
            [void]$sb.AppendLine("| ``$req`` | $desc | $status |")
        }
        [void]$sb.AppendLine('')
    }

    Add-CheckBulletList -Builder $sb -Heading 'Missing' -Items $Result.Missing
    Add-CheckBulletList -Builder $sb -Heading 'Already present' -Items $Result.Met
    Add-CheckBulletList -Builder $sb -Heading 'Compare these yourself' -Items $Result.Manual
    Add-CheckBulletList -Builder $sb -Heading 'Not required for ReadOnly' -Items $Result.PlanningOnly
    return $sb.ToString()
}

function Get-IntegrationMemberCheckResult {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [hashtable]$Context = @{},
        [switch]$WhatIf
    )
    if (-not (Get-Command Get-IntegrationWizardAccessRequirementLists -ErrorAction SilentlyContinue)) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Access.psm1') -Force -WarningAction SilentlyContinue
    }
    $subject = Get-IntegrationCheckSubject -Definition $Definition -Context $Context
    $lists = Get-IntegrationWizardAccessRequirementLists -Definition $Definition -Context $Context
    $access = Get-CheckContextValue -Context $Context -Name 'Access'
    $lines = Get-CheckLinesForAccess -Lists $lists -Access $access
    $attempted = $false
    $read = @{ Found = $false; Grants = @(); Denied = @(); Incomplete = $false; Note = '' }
    $skipReason = ''
    if ($subject.Kind -eq 'GcpServiceAccount' -and [string]::IsNullOrWhiteSpace([string]$subject.Name)) {
        $skipReason = 'Check needs -ProjectId and the service account id of an account that already exists. Nothing was changed.'
    }
    elseif ($subject.Kind -eq 'EntraApplication' -and [string]::IsNullOrWhiteSpace([string]$subject.Name)) {
        $skipReason = 'Check needs -ApplicationName, the display name of an app registration that already exists. Nothing was changed.'
    }
    elseif ($WhatIf) {
        $skipReason = "WhatIf: would read $($subject.Label) $($subject.Name). No tenant call was made."
    }
    elseif ($subject.Kind -eq 'GitHubToken' -and [string]::IsNullOrWhiteSpace((Get-CheckContextValue -Context $Context -Name 'Token')) -and $Context['ConnectionMode'] -eq 'NoSession') {
        $skipReason = 'No GitHub token was provided and NoSession mode was selected. Provide a PAT in the token prompt or sign in with gh. Nothing was changed.'
    }
    elseif ($subject.Kind -ne 'GitHubToken' -and $Context -and $Context['ConnectionMode'] -eq 'NoSession') {
        $skipReason = 'No CLI session was used. Sign in and run Check again to read the existing identity, or compare the list yourself. Nothing was changed.'
    }
    elseif (-not $subject.Readable) {
        $skipReason = $subject.Note
    }
    else {
        $attempted = $true
        $read = Read-IntegrationIdentityGrants -Subject $subject -Context $Context
    }
    # A missing identity is not a list of gaps. Listing every requirement as missing
    # would read as if the role existed and lacked those permissions.
    if ($attempted -and -not $read.Found) {
        $coverage = @{ Met = @(); Missing = @(); Manual = @() }
    }
    elseif ($attempted) {
        $coverage = Compare-IntegrationRequirementCoverage -Required $lines.Required -Granted @($read.Grants) -Denied @($read.Denied) -ReadableFamilies @($subject.ReadableFamilies)
    }
    else {
        $coverage = @{ Met = @(); Missing = @(); Manual = @($lines.Required) }
    }
    $verdict = Get-IntegrationCheckVerdict -AttemptedRead $attempted -Found ([bool]$read.Found) -Incomplete ([bool]$read.Incomplete) `
        -RequiredCount @($lines.Required).Count -MissingCount @($coverage.Missing).Count -ManualCount @($coverage.Manual).Count
    $readNote = $skipReason
    if ($attempted -and $read.Note) { $readNote = [string]$read.Note }
    return @{
        Title         = [string]$Definition.Title
        Subject       = $subject
        Verdict       = $verdict
        AttemptedRead = $attempted
        Found         = [bool]$read.Found
        Required      = @($lines.Required)
        Missing       = @($coverage.Missing)
        Met           = @($coverage.Met)
        Manual        = @($coverage.Manual)
        PlanningOnly  = @($lines.PlanningOnly)
        ReadNote      = $readNote
        SubjectNote   = $subject.Note
    }
}

function Write-IntegrationCheckReport {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$Verdict,
        [string]$Access,
        [string[]]$Sections
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Check: $($Definition.Title)")
    [void]$sb.AppendLine('')

    $verdictBanner = switch ($Verdict) {
        'Pass'   { "> ### Verdict: PASS — Meets the requirements`r`n>`r`n> All required permissions for **$($Definition.Title)** are verified and satisfied by the checked credential/identity." }
        'Fail'   { "> ### Verdict: FAIL — Does not meet the requirements`r`n>`r`n> The checked credential/identity is missing required permissions for **$($Definition.Title)**. Review the missing items below." }
        default  { "> ### Verdict: REVIEW — Manual comparison needed`r`n>`r`n> Some requirements cannot be automatically verified via CLI/API. Compare the listed requirements manually." }
    }
    [void]$sb.AppendLine($verdictBanner)
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Nothing in the tenant was created or changed. This report is a local file.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("**$(Get-IntegrationCheckVerdictText -Verdict $Verdict).**")
    [void]$sb.AppendLine('')
    if ($Access) {
        [void]$sb.AppendLine("Access level: $Access")
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('`BuildRequirements` is the checklist. `Check` reads an identity you already have. `Run` is the only action that changes the tenant, and only after you confirm.')
    [void]$sb.AppendLine('')
    foreach ($section in @($Sections)) { [void]$sb.AppendLine($section) }
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -LiteralPath $OutputPath -Value $sb.ToString() -Encoding utf8
}

function Invoke-IntegrationRequirementCheck {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$OutputPath,
        [switch]$WhatIf
    )
    $members = if ($Definition['IsComposite']) { @($Definition.Members) } else { @($Definition) }
    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($member in @($members)) {
        $results.Add((Get-IntegrationMemberCheckResult -Definition $member -Context $Context -WhatIf:$WhatIf))
    }
    $verdicts = [System.Collections.Generic.List[string]]::new()
    $sections = [System.Collections.Generic.List[string]]::new()
    foreach ($result in $results) {
        $verdicts.Add([string]$result.Verdict)
        $sections.Add((Format-IntegrationCheckSection -Result $result))
    }
    $verdict = Get-WorstCheckVerdict -Verdicts $verdicts.ToArray()
    $access = Get-CheckContextValue -Context $Context -Name 'Access'
    Write-IntegrationCheckReport -Definition $Definition -OutputPath $OutputPath -Verdict $verdict -Access $access -Sections $sections
    $phrase = Get-IntegrationCheckVerdictText -Verdict $verdict
    $color = switch ($verdict) { 'Pass' { 'Green' } 'Fail' { 'Red' } default { 'Yellow' } }
    Write-Host ''
    Write-Host $phrase -ForegroundColor $color
    Write-Host 'Nothing in the tenant was changed.'
    Write-Host "Wrote $OutputPath"
    foreach ($result in @($results)) {
        if (@($result.Missing).Count -eq 0) { continue }
        Write-Host "$($result.Title) is missing:" -ForegroundColor $color
        $shown = 0
        foreach ($item in @($result.Missing)) {
            $shown++
            if ($shown -gt 20) { break }
            Write-Host "  $item"
        }
        $rest = @($result.Missing).Count - $shown
        if ($rest -gt 0) { Write-Host "  and $rest more in the report" }
    }
    if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Check verdict ${verdict}: $OutputPath"
    }
    if ($verdict -eq 'Fail' -and $Context['NonInteractive']) {
        throw "Existing identity does not meet the requirements. Report: $OutputPath. Nothing was changed."
    }
    return @{ Verdict = $verdict; Path = $OutputPath }
}

Export-ModuleMember -Function @(
    'Set-IntegrationCheckInvoker'
    'Get-RequirementToken'
    'Get-IamPolicyGrantSet'
    'Compare-IntegrationRequirementCoverage'
    'Get-CheckLinesForAccess'
    'Get-IntegrationCheckSubject'
    'Get-IntegrationCheckVerdict'
    'Read-AwsIamRoleGrants'
    'Read-EntraApplicationGrants'
    'Read-GcpServiceAccountGrants'
    'Invoke-GitHubApiProbe'
    'Read-GitHubTokenGrants'
    'Invoke-IntegrationRequirementCheck'
)
