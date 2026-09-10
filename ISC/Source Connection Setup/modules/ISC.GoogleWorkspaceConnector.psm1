#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:OpenSslPath = $null

function Initialize-GoogleWorkspaceConnectorData {
    param([string]$OpenSslPath)
    $script:OpenSslPath = $OpenSslPath
$script:CreatedServiceAccount = $null

# -----------------------------------------------------------------------------
# Scopes - SailPoint Google Workspace SaaS service-account table
# https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prereqs_for_oauth_2_0.html
# -----------------------------------------------------------------------------

$script:CoreScopes = @(
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.group';                 Purpose = 'Group aggregation and provisioning' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.user';                  Purpose = 'User aggregation and provisioning' }
    @{ Value = 'https://www.googleapis.com/auth/apps.groups.settings';                  Purpose = 'Group Settings API' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.rolemanagement';        Purpose = 'Role create / assign' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly'; Purpose = 'Role aggregation' }
)

$script:FeaturePacks = [ordered]@{
    GmailDelegates = @{
        Label  = 'Gmail delegates'
        Apis   = @('gmail.googleapis.com')
        Scopes = @(
            'https://www.googleapis.com/auth/gmail.settings.sharing'
            'https://www.googleapis.com/auth/gmail.settings.basic'
            'https://mail.google.com/'
            'https://www.googleapis.com/auth/gmail.modify'
            'https://www.googleapis.com/auth/gmail.readonly'
        )
    }
    DeltaAggregation = @{
        Label  = 'Delta aggregation (Reports audit)'
        Apis   = @()
        Scopes = @('https://www.googleapis.com/auth/admin.reports.audit.readonly')
    }
    DomainManagement = @{
        Label  = 'Manage domain as a GCP account type'
        Apis   = @()
        Scopes = @('https://www.googleapis.com/auth/admin.directory.domain')
    }
    ActivityInsights = @{
        Label  = 'Activity Insights (audit and usage reports)'
        Apis   = @()
        Scopes = @(
            'https://www.googleapis.com/auth/admin.reports.audit.readonly'
            'https://www.googleapis.com/auth/admin.reports.usage.readonly'
        )
    }
}

$script:CoreApis = @(
    'admin.googleapis.com'
    'groupssettings.googleapis.com'
)

}

function Invoke-GCloud {
    param(
        [Parameter(Mandatory)][string[]]$GcloudArgs,
        [switch]$ExpectJson
    )

    $gcloud = Ensure-GCloudCommand
    $errorFile = [System.IO.Path]::GetTempFileName()
    $previousPrompt = $env:CLOUDSDK_CORE_DISABLE_PROMPTS
    $env:CLOUDSDK_CORE_DISABLE_PROMPTS = '1'
    try {
        $stdout = & $gcloud @GcloudArgs 2>$errorFile
        $code = $LASTEXITCODE
        $stderr = ''
        if (Test-Path $errorFile) {
            $stderr = [System.IO.File]::ReadAllText($errorFile)
        }
        if ($code -ne 0) {
            $detail = (@($stderr, $stdout) | Where-Object { $_ } ) -join ' '
            throw ("gcloud {0} failed: {1}" -f ($GcloudArgs -join ' '), $detail.Trim())
        }
        if (-not $ExpectJson) {
            if ($null -eq $stdout) { return '' }
            return ($stdout | Out-String).Trim()
        }
        $text = if ($stdout -is [array]) { $stdout -join "`n" } else { [string]$stdout }
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }
        return $text | ConvertFrom-Json
    }
    finally {
        if ($null -eq $previousPrompt) {
            Remove-Item Env:CLOUDSDK_CORE_DISABLE_PROMPTS -ErrorAction SilentlyContinue
        }
        else {
            $env:CLOUDSDK_CORE_DISABLE_PROMPTS = $previousPrompt
        }
        Remove-Item -LiteralPath $errorFile -Force -ErrorAction SilentlyContinue
    }
}

function Test-GCloudAuth {
    $account = Invoke-GCloud -GcloudArgs @('config', 'get-value', 'account', '--quiet')
    if ([string]::IsNullOrWhiteSpace($account) -or $account -eq '(unset)') {
        return $null
    }
    return $account
}

function Connect-GoogleCloud {
    Write-Step 'Google Cloud SDK'
    $null = Ensure-GCloudCommand
    Write-Ok 'gcloud is on PATH'

    $account = Test-GCloudAuth
    if ($account) {
        $reuse = Read-YesNo -Prompt "Already signed in as $account. Reuse this session?" -Default $true
        if ($reuse) {
            Write-Ok "Using $account"
            return $account
        }
    }

    Write-Info 'Opening the Google sign-in flow...'
    Invoke-GCloud -GcloudArgs @('auth', 'login', '--brief', '--quiet') | Out-Null
    $account = Test-GCloudAuth
    if (-not $account) {
        throw 'gcloud auth login did not produce an active account.'
    }
    Write-Ok "Signed in as $account"
    return $account
}


# Set-StrictMode turns a missing property into a terminating error, so optional JSON fields are
# read through the property bag instead.
function Get-JsonProperty {
    param(
        [Parameter(Mandatory)][AllowNull()]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if (-not $property) { return $null }
    return $property.Value
}

function Test-OpenSslTraditionalFlag {
    param([Parameter(Mandatory)][string]$OpenSsl)

    # LibreSSL (macOS /usr/bin/openssl) treats unknown flags as cipher names:
    # "Invalid cipher 'traditional'". OpenSSL 3 documents -traditional as a real flag.
    $help = & $OpenSsl rsa -help 2>&1 | Out-String
    return [bool]($help -match '(?m)^\s*-traditional\b')
}

function ConvertTo-EncryptedRsaPem {
    param(
        [Parameter(Mandatory)][string]$JsonKeyPath,
        [Parameter(Mandatory)][string]$PemPath,
        [Parameter(Mandatory)][string]$Passphrase
    )

    $openssl = Ensure-OpenSslCommand -OpenSslPath $script:OpenSslPath
    $json = Get-Content -LiteralPath $JsonKeyPath -Raw | ConvertFrom-Json
    $privateKey = Get-JsonProperty -InputObject $json -Name 'private_key'
    if (-not $privateKey) {
        throw "JSON key $JsonKeyPath does not contain private_key."
    }

    $pkcs8Path = [System.IO.Path]::ChangeExtension($PemPath, '.pkcs8.pem')
    $pkcs8 = $privateKey -replace '\\n', "`n"
    [System.IO.File]::WriteAllText($pkcs8Path, $pkcs8.Trim() + "`n")

    $previous = $env:SP_GWS_PEM_PASS
    $env:SP_GWS_PEM_PASS = $Passphrase
    try {
        $rsaArgs = @(
            'rsa'
            '-aes-256-cbc'
            '-in', $pkcs8Path
            '-out', $PemPath
            '-passout', 'env:SP_GWS_PEM_PASS'
        )
        if (Test-OpenSslTraditionalFlag -OpenSsl $openssl) {
            $rsaArgs += '-traditional'
        }

        $errorFile = [System.IO.Path]::GetTempFileName()
        $null = & $openssl @rsaArgs 2>$errorFile
        $code = $LASTEXITCODE
        $stderr = if (Test-Path $errorFile) { [System.IO.File]::ReadAllText($errorFile) } else { '' }
        Remove-Item -LiteralPath $errorFile -Force -ErrorAction SilentlyContinue
        if ($code -ne 0 -or -not (Test-Path -LiteralPath $PemPath)) {
            throw "openssl failed to convert the key to traditional RSA PEM: $stderr"
        }

        $pemText = [System.IO.File]::ReadAllText($PemPath)
        if ($pemText -notmatch 'BEGIN RSA PRIVATE KEY') {
            throw "openssl wrote a key that is not traditional RSA PEM (expected BEGIN RSA PRIVATE KEY). Install OpenSSL 3+ or pass -OpenSslPath. Output started with: $($pemText.Substring(0, [Math]::Min(40, $pemText.Length)))"
        }
    }
    finally {
        if ($null -eq $previous) {
            Remove-Item Env:SP_GWS_PEM_PASS -ErrorAction SilentlyContinue
        }
        else {
            $env:SP_GWS_PEM_PASS = $previous
        }
        Remove-Item -LiteralPath $pkcs8Path -Force -ErrorAction SilentlyContinue
    }

    return $json
}

function New-KeyPassword {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return [Convert]::ToBase64String($bytes)
}

function Get-SelectedScopes {
    param([string[]]$FeatureNames)

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $script:CoreScopes) {
        if (-not $values.Contains($item.Value)) { $values.Add($item.Value) }
    }
    foreach ($scope in @(Get-GoogleCiemScopes -FeatureNames $FeatureNames)) {
        if (-not $values.Contains($scope)) { $values.Add($scope) }
    }
    foreach ($name in @($FeatureNames)) {
        if (-not $script:FeaturePacks.Contains($name)) { continue }
        $pack = $script:FeaturePacks[$name]
        if ($pack.ContainsKey('Scopes')) {
            foreach ($scope in @($pack.Scopes)) {
                if (-not $values.Contains($scope)) { $values.Add($scope) }
            }
        }
    }
    return $values.ToArray()
}

function Get-SelectedApis {
    param([string[]]$FeatureNames)

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($api in $script:CoreApis) { $values.Add($api) }
    foreach ($api in @(Get-GoogleCiemApis -FeatureNames $FeatureNames)) {
        if ($api -and -not $values.Contains($api)) { $values.Add($api) }
    }
    foreach ($name in @($FeatureNames)) {
        if (-not $script:FeaturePacks.Contains($name)) { continue }
        foreach ($api in @($script:FeaturePacks[$name].Apis)) {
            if ($api -and -not $values.Contains($api)) { $values.Add($api) }
        }
    }
    return $values.ToArray()
}

function Get-CustomRolePermissions {
    param(
        [string[]]$FeatureNames,
        [switch]$SkipGcpWrite
    )
    return @(Get-GoogleCustomRolePermissions -FeatureNames $FeatureNames -SkipGcpWrite:$SkipGcpWrite)
}

function ConvertTo-RoleYaml {
    param(
        [Parameter(Mandatory)][string[]]$Permissions,
        [Parameter(Mandatory)][string]$Title
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("title: $Title")
    $lines.Add('description: SailPoint Identity Security Cloud Google Workspace SaaS connector')
    $lines.Add('stage: GA')
    $lines.Add('includedPermissions:')
    foreach ($p in $Permissions) {
        $lines.Add("- $p")
    }
    return ($lines -join "`n") + "`n"
}

function Get-ServiceAccountEmail {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Project
    )
    return "$AccountId@$Project.iam.gserviceaccount.com"
}

function Get-ExistingServiceAccount {
    param(
        [Parameter(Mandatory)][string]$Email,
        [Parameter(Mandatory)][string]$Project
    )
    try {
        return Invoke-GCloud -ExpectJson -GcloudArgs @(
            'iam', 'service-accounts', 'describe', $Email,
            "--project=$Project", '--format=json', '--quiet'
        )
    }
    catch {
        return $null
    }
}

function Set-OrganizationCustomRole {
    param(
        [Parameter(Mandatory)][string]$OrgId,
        [Parameter(Mandatory)][string[]]$Permissions
    )

    $yamlPath = Join-Path ([System.IO.Path]::GetTempPath()) "sailpoint-gws-role-$OrgId.yaml"
    [System.IO.File]::WriteAllText($yamlPath, (ConvertTo-RoleYaml -Permissions $Permissions -Title 'SailPoint ISC Google Workspace'))
    $customRoleId = (Get-GoogleCiemCatalog).CustomRoleId
    $roleName = "organizations/$OrgId/roles/$customRoleId"
    try {
        $exists = $false
        try {
            Invoke-GCloud -GcloudArgs @('iam', 'roles', 'describe', $customRoleId, "--organization=$OrgId", '--quiet') | Out-Null
            $exists = $true
        }
        catch { }

        if ($exists) {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'roles', 'update', $customRoleId,
                "--organization=$OrgId", "--file=$yamlPath", '--quiet'
            ) | Out-Null
            Write-Ok "Updated organization role $roleName"
        }
        else {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'roles', 'create', $customRoleId,
                "--organization=$OrgId", "--file=$yamlPath", '--quiet'
            ) | Out-Null
            Write-Ok "Created organization role $roleName"
        }
        return $roleName
    }
    finally {
        Remove-Item -LiteralPath $yamlPath -Force -ErrorAction SilentlyContinue
    }
}

function Add-IamPolicyBinding {
    param(
        [Parameter(Mandatory)][ValidateSet('organizations', 'projects')][string]$ResourceKind,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Role
    )

    $bindArgs = @(
        $ResourceKind, 'add-iam-policy-binding', $ResourceId,
        "--member=$Member",
        "--role=$Role",
        '--condition=None',
        '--quiet'
    )
    try {
        Invoke-GCloud -GcloudArgs $bindArgs | Out-Null
    }
    catch {
        Invoke-GCloud -GcloudArgs @(
            $ResourceKind, 'add-iam-policy-binding', $ResourceId,
            "--member=$Member",
            "--role=$Role",
            '--quiet'
        ) | Out-Null
    }
}

# -----------------------------------------------------------------------------
# OAuth 2.0 authorization-code flow (Client Credentials grant type)
# -----------------------------------------------------------------------------

$script:GoogleAuthUri = 'https://accounts.google.com/o/oauth2/v2/auth'
$script:GoogleTokenUri = 'https://oauth2.googleapis.com/token'
$script:PlaygroundRedirect = 'https://developers.google.com/oauthplayground'
$script:AuthCodeTimeoutSeconds = 300

function Get-GoogleAuthorizationUrl {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes
    )

    $query = @(
        "client_id=$([uri]::EscapeDataString($OAuthClientId))"
        "redirect_uri=$([uri]::EscapeDataString($Redirect))"
        'response_type=code'
        'access_type=offline'
        'prompt=consent'
        'include_granted_scopes=true'
        "scope=$([uri]::EscapeDataString(($Scopes -join ' ')))"
    ) -join '&'

    return "$script:GoogleAuthUri`?$query"
}


# Blocks on the loopback redirect until Google sends the code back, so the operator never has to
# copy anything out of the address bar.
function Wait-GoogleAuthorizationCode {
    param([Parameter(Mandatory)][string]$Redirect)

    $prefix = $Redirect.TrimEnd('/') + '/'
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($prefix)
    try {
        $listener.Start()
    }
    catch {
        throw "Could not listen on $prefix. Choose a free port with -RedirectUri, or use the OAuth Playground redirect. $($_.Exception.Message)"
    }

    try {
        Write-Info "Waiting for the Google redirect on $prefix (Ctrl+C to cancel) ..."
        # A consent screen that blocks the sign-in never redirects here, so the wait is bounded
        # rather than hanging until Ctrl+C. Polling also keeps Ctrl+C responsive.
        $pending = $listener.GetContextAsync()
        $deadline = (Get-Date).AddSeconds($script:AuthCodeTimeoutSeconds)
        while (-not $pending.Wait(500)) {
            if ((Get-Date) -gt $deadline) {
                $waited = if ($script:AuthCodeTimeoutSeconds -ge 120) { "$([int]($script:AuthCodeTimeoutSeconds / 60)) minutes" } else { "$script:AuthCodeTimeoutSeconds seconds" }
                throw ("No redirect arrived on $prefix within $waited. " +
                    "If the browser showed 'Access blocked - has not completed the Google verification process', the OAuth client's audience does not allow that account: " +
                    'add it under Audience > Test users, or set User type to Internal, then retry.')
            }
        }
        $context = $pending.Result
        $code = $context.Request.QueryString['code']
        $failure = $context.Request.QueryString['error']

        $body = if ($code) {
            '<html><body style="font-family:sans-serif"><h3>Authorization complete</h3><p>Return to the PowerShell window.</p></body></html>'
        }
        else {
            "<html><body style='font-family:sans-serif'><h3>Authorization failed</h3><p>$failure</p></body></html>"
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $context.Response.ContentType = 'text/html'
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.OutputStream.Close()

        if (-not $code) {
            throw "Google returned an error instead of an authorization code: $failure"
        }
        return $code
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

function Invoke-GoogleTokenExchange {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$Code
    )

    try {
        return Invoke-RestMethod -Method Post -Uri $script:GoogleTokenUri -ErrorAction Stop -Body @{
            code          = $Code
            client_id     = $OAuthClientId
            client_secret = $OAuthClientSecret
            redirect_uri  = $Redirect
            grant_type    = 'authorization_code'
        }
    }
    catch {
        $detail = $_.ErrorDetails
        $body = if ($detail) { $detail.Message } else { $_.Exception.Message }
        throw "Google rejected the token exchange: $body"
    }
}

function Get-GoogleOAuthToken {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes,
        [Parameter(Mandatory)][string]$SignInHint
    )

    $authUrl = Get-GoogleAuthorizationUrl -OAuthClientId $OAuthClientId -Redirect $Redirect -Scopes $Scopes
    $isLoopback = $Redirect -match '^http://(localhost|127\.0\.0\.1)'

    Write-Host ''
    Write-Host 'Authorize the OAuth client at:' -ForegroundColor White
    Write-Host $authUrl -ForegroundColor Yellow
    Write-Host ''
    if (-not (Open-Url -Url $authUrl)) {
        Write-Info 'Could not open a browser automatically; copy the URL above.'
    }
    Write-Info $SignInHint

    $code = if ($isLoopback) {
        Wait-GoogleAuthorizationCode -Redirect $Redirect
    }
    else {
        Write-Info 'The OAuth Playground shows the authorization code under "Step 2 - Exchange authorization code for tokens".'
        Read-InputString -Prompt 'Authorization code' -Required
    }

    return Invoke-GoogleTokenExchange -OAuthClientId $OAuthClientId -OAuthClientSecret $OAuthClientSecret `
        -Redirect $Redirect -Code $code
}

function Get-GoogleRefreshToken {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes
    )

    $response = Get-GoogleOAuthToken -OAuthClientId $OAuthClientId -OAuthClientSecret $OAuthClientSecret `
        -Redirect $Redirect -Scopes $Scopes `
        -SignInHint 'Sign in as the Workspace user whose roles the connector should use, and accept every scope.'

    $refresh = Get-JsonProperty -InputObject $response -Name 'refresh_token'
    if (-not $refresh) {
        throw 'Google returned an access token without a refresh token. Remove the app under https://myaccount.google.com/permissions and authorize again so consent is re-prompted.'
    }
    return [string]$refresh
}

function Invoke-AdminSdk {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        $Body
    )

    $headers = @{ Authorization = "Bearer $AccessToken" }
    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $headers
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = ($Body | ConvertTo-Json -Compress -Depth 6)
    }
    try {
        return Invoke-RestMethod @params
    }
    catch {
        $detail = $_.ErrorDetails
        $message = if ($detail) { $detail.Message } else { $_.Exception.Message }
        throw "Admin SDK $Method $Uri failed: $message"
    }
}

function Get-AdminSdkRoles {
    param([Parameter(Mandatory)][string]$AccessToken)

    $roles = [System.Collections.Generic.List[object]]::new()
    $uri = 'https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roles?maxResults=100'
    while ($uri) {
        $page = Invoke-AdminSdk -AccessToken $AccessToken -Method Get -Uri $uri
        foreach ($role in @((Get-JsonProperty -InputObject $page -Name 'items'))) {
            if ($role) { $roles.Add($role) }
        }
        $token = Get-JsonProperty -InputObject $page -Name 'nextPageToken'
        if ($token) {
            $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roles?maxResults=100&pageToken=$([uri]::EscapeDataString([string]$token))"
        }
        else {
            $uri = $null
        }
    }
    return $roles.ToArray()
}

function Resolve-WorkspaceAdminRole {
    param(
        [Parameter(Mandatory)]$Roles,
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$Description
    )

    foreach ($role in @($Roles)) {
        $name = [string](Get-JsonProperty -InputObject $role -Name 'roleName')
        $desc = [string](Get-JsonProperty -InputObject $role -Name 'roleDescription')
        if ($name -eq $RoleName -or $desc -eq $Description) {
            return $role
        }
    }
    return $null
}

function Test-WorkspaceRoleAssigned {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$UserId,
        [Parameter(Mandatory)][string]$RoleId
    )

    $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments?userKey=$([uri]::EscapeDataString($UserId))&maxResults=100"
    while ($uri) {
        $page = Invoke-AdminSdk -AccessToken $AccessToken -Method Get -Uri $uri
        foreach ($assignment in @((Get-JsonProperty -InputObject $page -Name 'items'))) {
            if (-not $assignment) { continue }
            if ([string](Get-JsonProperty -InputObject $assignment -Name 'roleId') -eq $RoleId) {
                return $true
            }
        }
        $token = Get-JsonProperty -InputObject $page -Name 'nextPageToken'
        if ($token) {
            $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments?userKey=$([uri]::EscapeDataString($UserId))&maxResults=100&pageToken=$([uri]::EscapeDataString([string]$token))"
        }
        else {
            $uri = $null
        }
    }
    return $false
}

function Get-WorkspaceAdminAccounts {
    param([Parameter(Mandatory)][string]$AccessToken)

    try {
        $response = Invoke-AdminSdk -AccessToken $AccessToken -Method Get `
            -Uri 'https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&query=isAdmin%3Dtrue&maxResults=25&projection=basic'
        $users = Get-JsonProperty -InputObject $response -Name 'users'
        return @($users | ForEach-Object { [string](Get-JsonProperty -InputObject $_ -Name 'primaryEmail') } | Where-Object { $_ })
    }
    catch {
        return @()
    }
}

function Add-WorkspaceAdminRoles {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$UserEmail,
        [Parameter(Mandatory)][string[]]$WantedDescriptions,
        [hashtable]$RoleNameByDescription
    )

    Write-Step "Assigning Workspace admin roles to $UserEmail"
    # A mistyped address reaches this point looking like any other failure, so name the cause and
    # show the admins that do exist rather than returning a raw 404.
    try {
        $user = Invoke-AdminSdk -AccessToken $AccessToken -Method Get `
            -Uri "https://admin.googleapis.com/admin/directory/v1/users/$([uri]::EscapeDataString($UserEmail))"
    }
    catch {
        if ([string]$_.Exception.Message -notmatch '404|notFound|Resource Not Found') { throw }
        Write-Warning "This Workspace has no user $UserEmail. A typo in the address or the domain is the usual cause."
        $admins = @(Get-WorkspaceAdminAccounts -AccessToken $AccessToken)
        if ($admins.Count) {
            Write-Info 'Admin accounts that do exist here:'
            foreach ($admin in $admins) { Write-Host "     $admin" -ForegroundColor White }
        }
        throw "The impersonate user $UserEmail does not exist, so no roles can be assigned. Re-run with -ImpersonateUser set to the correct address; Connection Settings carry the same address and need it too."
    }
    $userId = [string](Get-JsonProperty -InputObject $user -Name 'id')
    if (-not $userId) {
        throw "Admin SDK did not return an id for $UserEmail."
    }

    $roles = @(Get-AdminSdkRoles -AccessToken $AccessToken)
    foreach ($description in $WantedDescriptions) {
        $roleName = $RoleNameByDescription[$description]
        $role = Resolve-WorkspaceAdminRole -Roles $roles -RoleName $roleName -Description $description
        if (-not $role) {
            Write-Warning "Workspace role '$description' ($roleName) was not found in this customer."
            continue
        }
        $roleId = [string](Get-JsonProperty -InputObject $role -Name 'roleId')
        if (Test-WorkspaceRoleAssigned -AccessToken $AccessToken -UserId $userId -RoleId $roleId) {
            Write-Ok "$description is already assigned"
            continue
        }
        Invoke-AdminSdk -AccessToken $AccessToken -Method Post `
            -Uri 'https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments' `
            -Body @{
                roleId    = $roleId
                assignedTo = $userId
                scopeType = 'CUSTOMER'
            } | Out-Null
        Write-Ok "Assigned $description"
    }
}

function Show-CopyPasteValue {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Instruction,
        [switch]$HideValue
    )

    if (-not $HideValue) {
        Write-Info "${Label}:"
        Write-Host "   $Value" -ForegroundColor White
    }
    if (Copy-ToClipboard -Text $Value) {
        Write-Ok "$Instruction Copied to the clipboard as well."
    }
    else {
        Write-Warning 'No clipboard tool is available. Copy from the value above.'
        Write-Ok $Instruction
    }
}

function Write-DomainWideDelegationValues {
    param(
        [Parameter(Mandatory)][string]$ClientIdValue,
        [Parameter(Mandatory)][string]$ScopesValue
    )

    Write-Info 'Client ID:'
    Write-Host "   $ClientIdValue" -ForegroundColor White
    Write-Info 'OAuth scopes to add (comma-delimited):'
    Write-Host "   $ScopesValue" -ForegroundColor White
    foreach ($scope in ($ScopesValue -split ',')) {
        if (-not [string]::IsNullOrWhiteSpace($scope)) {
            Write-Host "     $scope" -ForegroundColor DarkGray
        }
    }
}

function Wait-Continue {
    param([Parameter(Mandatory)][string]$Prompt)

    if ($script:NonInteractive) { return }
    $null = Read-TypedLine $Prompt
}

function Get-OAuthClientCreateUrl {
    param([Parameter(Mandatory)][string]$Project)

    return "https://console.cloud.google.com/auth/clients/create?project=$Project"
}

function Get-OAuthAudienceUrl {
    param([Parameter(Mandatory)][string]$Project)

    return "https://console.cloud.google.com/auth/audience?project=$Project"
}

function Write-OAuthClientSteps {
    param(
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$ClientName
    )

    Write-Host ''
    Write-Host '   1. Application type: Web application' -ForegroundColor White
    Write-Host "   2. Name: $ClientName" -ForegroundColor White
    Write-Host "   3. Authorized redirect URIs → Add URI → $Redirect" -ForegroundColor White
    Write-Host '   4. Create, then copy the Client ID and Client secret from the dialog' -ForegroundColor White
    Write-Host ''
    Write-Info 'Google shows the client secret only once, in that dialog. Copy it before closing.'
    Write-Info 'If the console asks you to configure Google Auth Platform first, do that, then come back to Clients.'
    Write-Info 'User type Internal is only offered when the project belongs to a Workspace organization. Otherwise choose External.'
}

# An External app in Testing rejects every account that is not a test user, with
# "Access blocked - has not completed the Google verification process". The account has to be
# listed before the sign-in, so this runs while the browser is still on the console.
function Invoke-OAuthAudienceWalkthrough {
    param(
        [Parameter(Mandatory)][string]$Project,
        [string]$SignInAccount
    )

    if ($script:NonInteractive) { return }

    Write-Info 'Audience: an External app in Testing only lets accounts listed as test users sign in.'
    Write-Info 'Internal apps (Workspace organization projects) allow everyone in the organization, so they need nothing here.'
    if (-not (Read-YesNo -Prompt 'Open the Audience page to add the signing-in account as a test user?' -Default $true)) {
        return
    }

    $audienceUrl = Get-OAuthAudienceUrl -Project $Project
    if (Open-Url -Url $audienceUrl) {
        Write-Ok "Opened $audienceUrl"
    }
    else {
        Write-Info "Open $audienceUrl"
    }
    Write-Info 'Under Test users: Add users → the Super Admin account you will sign in with → Save.'

    if ($SignInAccount) {
        Show-CopyPasteValue -Label 'Likely test user' -Value $SignInAccount `
            -Instruction 'Add this account if it is the one that will sign in. Otherwise add the Super Admin you use.'
    }
    Wait-Continue 'Press Enter once the account is saved as a test user'
}

# Google has no API for creating a consent-screen OAuth client: gcloud iam oauth-clients manages
# Workforce Identity Federation clients, and IAP clients are locked to IAP redirect URIs. The
# Admin SDK only accepts a user token, so the console is the only way to get one. This walkthrough
# opens the create page, copies the redirect URI, and collects the pair. Returns $null when the
# operator opts out; Esc on the client ID rethrows so the caller can re-offer.
function Invoke-OAuthClientWalkthrough {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$Reason,
        [string]$ClientName = 'SailPoint ISC setup script',
        [string]$SignInAccount
    )

    if ($script:NonInteractive) { return $null }

    Write-Step 'OAuth client (Cloud Console — Google has no API for this)'
    Write-Info $Reason
    Write-Info 'The client is only used for this sign-in. Delete it afterwards if you prefer.'

    if (-not (Read-YesNo -Prompt 'Create the OAuth client now (No assigns the roles in the Admin console instead)?' -Default $true)) {
        return $null
    }

    $createUrl = Get-OAuthClientCreateUrl -Project $Project
    if (Open-Url -Url $createUrl) {
        Write-Ok "Opened $createUrl"
    }
    else {
        Write-Info "Open $createUrl"
    }

    Write-OAuthClientSteps -Redirect $Redirect -ClientName $ClientName
    Show-CopyPasteValue -Label 'Authorized redirect URI' -Value $Redirect `
        -Instruction 'Paste under Authorized redirect URIs. It must match exactly.'

    $clientIdValue = $null
    $clientSecretValue = $null
    $phase = 0
    while ($phase -lt 2) {
        try {
            if ($phase -eq 0) {
                $clientIdValue = Read-InputString -Prompt 'Client ID from the dialog' -Required
                $phase = 1
            }
            else {
                $clientSecretValue = Read-InputString -Prompt 'Client secret from the dialog' -Required
                $phase = 2
            }
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if ($phase -eq 0) { throw }
            $phase = 0
        }
    }

    Invoke-OAuthAudienceWalkthrough -Project $Project -SignInAccount $SignInAccount

    return [PSCustomObject]@{ ClientId = $clientIdValue; ClientSecret = $clientSecretValue }
}

# Google does not publish an API for domain-wide delegation. This walkthrough opens the Admin
# console page, prints Client ID and OAuth scopes first, then copies each field so the Super
# Admin only has to click Add new. Values are not secrets; they stay on screen if the clipboard
# is overwritten. Esc on a wait returns to the previous field; Esc on Client ID returns to Yes/No.
function Invoke-DomainWideDelegationWalkthrough {
    param(
        [Parameter(Mandatory)][string]$ClientIdValue,
        [Parameter(Mandatory)][string]$ScopesValue
    )

    Write-Step 'Domain-wide delegation (Admin console — Google has no API for this)'
    Write-Info 'Only a Super Admin can authorize the service account. The console page will open; this script copies each field in order.'
    Write-Info 'Esc goes back to the previous field. Client ID and scopes stay on screen if the clipboard is overwritten.'
    $dwdUrl = 'https://admin.google.com/ac/owl/domainwidedelegation'
    if (Open-Url -Url $dwdUrl) {
        Write-Ok "Opened $dwdUrl"
    }
    else {
        Write-Info "Open $dwdUrl"
    }

    Write-DomainWideDelegationValues -ClientIdValue $ClientIdValue -ScopesValue $ScopesValue

    $phase = 0
    while ($phase -lt 2) {
        try {
            if ($phase -eq 0) {
                Show-CopyPasteValue -Label 'Client ID' -Value $ClientIdValue -HideValue `
                    -Instruction 'In the Admin console: Add new → paste into Client ID.'
                Wait-Continue 'Press Enter after the Client ID is pasted (Esc goes back)'
                $phase = 1
            }
            else {
                Show-CopyPasteValue -Label 'OAuth scopes' -Value $ScopesValue -HideValue `
                    -Instruction 'Paste into OAuth scopes (comma-delimited), then Authorize.'
                Wait-Continue 'Press Enter after Authorize succeeds (Esc goes back to Client ID)'
                $phase = 2
            }
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if ($phase -eq 0) { throw }
            $phase = 0
        }
    }
}

function Test-ConnectionSettingIsSecret {
    param([Parameter(Mandatory)][string]$Name)

    return @(
        'Private Key'
        'Private Key Password'
        'Client Secret'
        'Refresh Token'
    ) -contains $Name
}

function Add-ConnectorIamBinding {
    param(
        [Parameter(Mandatory)][string]$OrgId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Role
    )

    try {
        Add-IamPolicyBinding -ResourceKind organizations -ResourceId $OrgId -Member $Member -Role $Role
        return 'organization'
    }
    catch {
        $message = $_.Exception.Message
        if ($message -notmatch 'not supported for this resource') {
            throw
        }
        Add-IamPolicyBinding -ResourceKind projects -ResourceId $ProjectId -Member $Member -Role $Role
        return 'project'
    }
}

function Get-GoogleWorkspaceCatalog {
    $packs = [ordered]@{}
    foreach ($key in $script:FeaturePacks.Keys) { $packs[$key] = $script:FeaturePacks[$key] }
    $gcpScopes = @()
    $nhiRoles = @()
    $customRoleId = 'sailpointGoogleWorkspace'
    if (Get-Command Get-GoogleCiemFeaturePacks -ErrorAction SilentlyContinue) {
        foreach ($key in (Get-GoogleCiemFeaturePacks).Keys) {
            $packs[$key] = (Get-GoogleCiemFeaturePacks)[$key]
        }
        if (Get-Command Get-GoogleCiemCatalog -ErrorAction SilentlyContinue) {
            $ciemCatalog = Get-GoogleCiemCatalog
            $gcpScopes = @($ciemCatalog.GcpScopes)
            $nhiRoles = @($ciemCatalog.NhiBuiltInRoles)
            $customRoleId = $ciemCatalog.CustomRoleId
        }
    }
    return [PSCustomObject]@{
        FeaturePacks       = $packs
        CoreScopes         = $script:CoreScopes
        GcpScopes          = $gcpScopes
        CoreApis           = $script:CoreApis
        NhiBuiltInRoles    = $nhiRoles
        PlaygroundRedirect = $script:PlaygroundRedirect
        CustomRoleId       = $customRoleId
    }
}

function Get-GoogleCreatedServiceAccount {
    return $script:CreatedServiceAccount
}

function Set-GoogleCreatedServiceAccount {
    param([Parameter(Mandatory)][string]$Email)
    $script:CreatedServiceAccount = $Email
}

Export-ModuleMember -Function @(
    'Initialize-GoogleWorkspaceConnectorData'
    'Get-GoogleWorkspaceCatalog'
    'Get-GoogleCreatedServiceAccount'
    'Set-GoogleCreatedServiceAccount'
    'Invoke-GCloud'
    'Test-GCloudAuth'
    'Connect-GoogleCloud'
    'ConvertTo-EncryptedRsaPem'
    'New-KeyPassword'
    'Get-SelectedScopes'
    'Get-SelectedApis'
    'Get-CustomRolePermissions'
    'ConvertTo-RoleYaml'
    'Get-ServiceAccountEmail'
    'Get-ExistingServiceAccount'
    'Set-OrganizationCustomRole'
    'Add-IamPolicyBinding'
    'Get-GoogleAuthorizationUrl'
    'Wait-GoogleAuthorizationCode'
    'Invoke-GoogleTokenExchange'
    'Get-GoogleOAuthToken'
    'Get-GoogleRefreshToken'
    'Invoke-AdminSdk'
    'Get-AdminSdkRoles'
    'Resolve-WorkspaceAdminRole'
    'Test-WorkspaceRoleAssigned'
    'Get-WorkspaceAdminAccounts'
    'Add-WorkspaceAdminRoles'
    'Show-CopyPasteValue'
    'Write-DomainWideDelegationValues'
    'Wait-Continue'
    'Get-OAuthClientCreateUrl'
    'Get-OAuthAudienceUrl'
    'Write-OAuthClientSteps'
    'Invoke-OAuthAudienceWalkthrough'
    'Invoke-OAuthClientWalkthrough'
    'Invoke-DomainWideDelegationWalkthrough'
    'Test-ConnectionSettingIsSecret'
    'Add-ConnectorIamBinding'
)
