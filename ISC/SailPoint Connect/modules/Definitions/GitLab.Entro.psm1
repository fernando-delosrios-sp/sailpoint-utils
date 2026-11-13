Set-StrictMode -Version Latest

$script:ProbeModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.OnPremProbe.psm1'
Import-Module $script:ProbeModule -Force -WarningAction SilentlyContinue

function Get-EntroGitLabGroupScopes {
    @('read_api', 'read_user', 'read_repository')
}

function Get-EntroGitLabPersonalScopes {
    @('api', 'read_api', 'read_user', 'read_repository')
}

function Get-EntroGitLabApiBase {
    param([string]$Url, [string]$Default = 'https://gitlab.com')
    $text = if ([string]::IsNullOrWhiteSpace($Url)) { $Default } else { $Url.Trim() }
    if ($text -notmatch '^[a-z][a-z0-9+\.-]*://') { $text = "https://$text" }
    ([Uri]$text).GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
}

function Test-EntroGitLabHostIsCloud {
    param([string]$Url)
    $base = Get-EntroGitLabApiBase -Url $Url
    ([Uri]$base).Host -eq 'gitlab.com'
}

function Test-GitLabEntroCheck {
    param($Context, [bool]$WhatIf, [bool]$SelfManaged)
    $missing = [System.Collections.Generic.List[string]]::new()
    $met = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    $base = Get-EntroGitLabApiBase -Url ([string]$Context['GitLabUrl'])
    $cloud = Test-EntroGitLabHostIsCloud -Url $base
    if ($SelfManaged -and $cloud) { $missing.Add('GitLabUrl is gitlab.com; use the gitlab.com variant') }
    if (-not $SelfManaged -and -not $cloud) { $missing.Add('GitLabUrl is self-managed; use the self-managed variant so an Outpost is linked') }
    $ep = Get-OnPremEndpoint -Address $base
    if ($WhatIf) { $manual.Add("TCP $($ep.Host):$($ep.Port)") }
    elseif (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port) { $met.Add("TCP $($ep.Host):$($ep.Port)") }
    else { $missing.Add("TCP $($ep.Host):$($ep.Port)") }

    $token = [string]$Context['AccessToken']
    $needed = Get-EntroGitLabGroupScopes
    if ([string]::IsNullOrWhiteSpace($token)) {
        $manual.Add('Access token scopes (supply AccessToken)')
    }
    elseif (-not $WhatIf) {
        try {
            $headers = @{ 'PRIVATE-TOKEN' = $token }
            Invoke-RestMethod -Method Get -Uri "$base/api/v4/user" -Headers $headers -TimeoutSec 20 | Out-Null
            $met.Add('GET /api/v4/user')
            try {
                $self = Invoke-RestMethod -Method Get -Uri "$base/api/v4/personal_access_tokens/self" -Headers $headers -TimeoutSec 20
                $scopes = @($self.scopes)
                foreach ($scope in $needed) {
                    if ($scopes -contains $scope) { $met.Add("scope $scope") } else { $missing.Add("scope $scope") }
                }
            }
            catch {
                $manual.Add('Token scope list is not available (group access tokens hide /personal_access_tokens/self). Confirm read_api, read_user, and read_repository in GitLab.')
            }
        }
        catch {
            $missing.Add("GitLab API rejected the token: $($_.Exception.Message)")
        }
    }
    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    @{
        Subject       = @{ Kind = 'GitLab'; Label = 'GitLab'; Name = $base; Note = 'Read-only probe. Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = -not $WhatIf
        Found         = $true
        Required      = @('TCP reachability', 'GET /api/v4/user', 'read_api', 'read_user', 'read_repository')
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = @{
            'TCP reachability' = 'This host can open the GitLab HTTPS port'
            'GET /api/v4/user' = 'The token authenticates'
            'read_api'         = 'Entro can read groups and projects'
            'read_repository'  = 'Entro can read repository metadata'
        }
        ReadNote      = "Checked $base from $([Environment]::MachineName)."
    }
}

function Get-EntroGitLabProvisionScript {
    param([hashtable]$Context, [bool]$SelfManaged)
    $kind = if ($Context['TokenKind']) { [string]$Context['TokenKind'] } else { 'Group' }
    $scopes = if ($kind -eq 'Personal') { (Get-EntroGitLabPersonalScopes) -join "', '" } else { (Get-EntroGitLabGroupScopes) -join "', '" }
    @"
if ([string]::IsNullOrWhiteSpace(`$AdminToken)) { `$AdminToken = Read-Host 'GitLab admin or owner token' }
`$gitlabBase = [string]`$GitLabUrl
if ([string]::IsNullOrWhiteSpace(`$gitlabBase)) { `$gitlabBase = 'https://gitlab.com' }
if (`$gitlabBase -notmatch '^[a-z][a-z0-9+\.-]*://') { `$gitlabBase = "https://`$gitlabBase" }
`$gitlabBase = ([Uri]`$gitlabBase).GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
`$headers = @{ 'PRIVATE-TOKEN' = `$AdminToken }
`$expires = if (`$TokenExpires) { `$TokenExpires } else { (Get-Date).AddDays(90).ToString('yyyy-MM-dd') }
if ('$kind' -eq 'Personal') {
    if ([string]::IsNullOrWhiteSpace(`$Username)) { throw 'Username is required for a personal access token.' }
    `$encodedUser = [Uri]::EscapeDataString(`$Username)
    `$users = @(Invoke-RestMethod -Method Get -Uri "`$gitlabBase/api/v4/users?username=`$encodedUser" -Headers `$headers -TimeoutSec 30)
    if (`$users.Count -lt 1) { throw "GitLab user `$Username was not found." }
    `$body = @{ name = 'entro_pat'; scopes = @('$scopes'); expires_at = `$expires } | ConvertTo-Json
    `$created = Invoke-RestMethod -Method Post -Uri "`$gitlabBase/api/v4/users/`$(`$users[0].id)/personal_access_tokens" -Headers `$headers -Body `$body -ContentType 'application/json' -TimeoutSec 30
} else {
    if ([string]::IsNullOrWhiteSpace(`$GroupPath)) { throw 'GroupPath is required for a group access token.' }
    `$encodedGroup = [Uri]::EscapeDataString(`$GroupPath)
    `$group = Invoke-RestMethod -Method Get -Uri "`$gitlabBase/api/v4/groups/`$encodedGroup" -Headers `$headers -TimeoutSec 30
    `$body = @{ name = 'entro_svc'; scopes = @('$scopes'); access_level = 50; expires_at = `$expires } | ConvertTo-Json
    `$created = Invoke-RestMethod -Method Post -Uri "`$gitlabBase/api/v4/groups/`$(`$group.id)/access_tokens" -Headers `$headers -Body `$body -ContentType 'application/json' -TimeoutSec 30
}
`$token = [string]`$created.token
if ([string]::IsNullOrWhiteSpace(`$token)) { throw 'GitLab did not return a token. The caller needs Owner (group token) or admin (personal token).' }
`$outDir = if (`$OutputDirectory) { `$OutputDirectory } else { (Get-Location).Path }
`$tokenPath = Join-Path `$outDir 'entro-gitlab-token.txt'
Set-Content -LiteralPath `$tokenPath -Value `$token -Encoding ascii
if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) { try { & chmod 600 `$tokenPath } catch { } }
Write-Host "Wrote the GitLab token to `$tokenPath. Paste it into Entro. Do not commit that file."
"@
}

function Invoke-EntroGitLabProvision {
    param([hashtable]$Context)
    $kind = if ($Context['TokenKind']) { [string]$Context['TokenKind'] } else { 'Group' }
    $base = Get-EntroGitLabApiBase -Url ([string]$Context['GitLabUrl'])
    $headers = @{ 'PRIVATE-TOKEN' = [string]$Context['AdminToken'] }
    $expires = if ($Context['TokenExpires']) { [string]$Context['TokenExpires'] } else { (Get-Date).AddDays(90).ToString('yyyy-MM-dd') }
    if ($kind -eq 'Personal') {
        $scopes = Get-EntroGitLabPersonalScopes
        $encodedUser = [Uri]::EscapeDataString([string]$Context['Username'])
        $users = @(Invoke-RestMethod -Method Get -Uri "$base/api/v4/users?username=$encodedUser" -Headers $headers -TimeoutSec 30)
        if ($users.Count -lt 1) { throw "GitLab user $($Context['Username']) was not found." }
        $body = @{ name = 'entro_pat'; scopes = @($scopes); expires_at = $expires } | ConvertTo-Json
        $created = Invoke-RestMethod -Method Post -Uri "$base/api/v4/users/$($users[0].id)/personal_access_tokens" -Headers $headers -Body $body -ContentType 'application/json' -TimeoutSec 30
    }
    else {
        $scopes = Get-EntroGitLabGroupScopes
        $encodedGroup = [Uri]::EscapeDataString([string]$Context['GroupPath'])
        $group = Invoke-RestMethod -Method Get -Uri "$base/api/v4/groups/$encodedGroup" -Headers $headers -TimeoutSec 30
        $body = @{ name = 'entro_svc'; scopes = @($scopes); access_level = 50; expires_at = $expires } | ConvertTo-Json
        $created = Invoke-RestMethod -Method Post -Uri "$base/api/v4/groups/$($group.id)/access_tokens" -Headers $headers -Body $body -ContentType 'application/json' -TimeoutSec 30
    }
    $token = [string]$created.token
    if ([string]::IsNullOrWhiteSpace($token)) { throw 'GitLab did not return a token.' }
    $dir = if ($Context['OutputDirectory']) { [string]$Context['OutputDirectory'] } else { (Get-Location).Path }
    $path = Join-Path $dir 'entro-gitlab-token.txt'
    Write-OnPremSecretFile -Path $path -Value $token
    $Context['CreatedTokenPath'] = $path
    Write-Ok "Wrote the GitLab token to $path. Paste it into Entro. Do not commit that file."
}

function Add-GitLabEntroDefinition {
    param([hashtable]$Definition)
    $selfManaged = [bool]$Definition['SelfManagedVariant']
    $Definition.Remove('SelfManagedVariant')
    $checkFn = ${function:Test-GitLabEntroCheck}
    $provisionFn = ${function:Invoke-EntroGitLabProvision}
    $provisionScriptFn = ${function:Get-EntroGitLabProvisionScript}
    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }
    $groupWhen = { param($c) $c['TokenKind'] -ne 'Personal' -and [string]$c['Action'] -eq 'Run' }
    $userWhen = { param($c) $c['TokenKind'] -eq 'Personal' -and [string]$c['Action'] -eq 'Run' }
    $urlDefault = if ($selfManaged) { $null } else { 'https://gitlab.com' }
    $urlRequired = if ($selfManaged) { $true } else { $false }
    $assert = if ($selfManaged) {
        {
            param($c)
            if (Test-EntroGitLabHostIsCloud -Url ([string]$c['GitLabUrl'])) {
                throw 'GitLab self-managed is for a private GitLab. Use Entro GitLab (gitlab.com) when the host is gitlab.com.'
            }
            $ep = Get-OnPremEndpoint -Address (Get-EntroGitLabApiBase -Url ([string]$c['GitLabUrl']))
            if (-not (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port)) {
                throw "Cannot reach GitLab at $($ep.Host):$($ep.Port). Run this on a host that can reach the server, or use BuildScript."
            }
        }
    }
    else {
        {
            param($c)
            if (-not (Test-EntroGitLabHostIsCloud -Url ([string]$c['GitLabUrl']))) {
                throw 'This GitLab URL is self-managed. Use the GitLab self-managed variant so SailPoint Connect links an Entro Outpost.'
            }
        }
    }
    $role = if ($selfManaged) { 'Internal host with HTTPS reachability to self-managed GitLab' } else { 'Workstation that can reach https://gitlab.com' }
    $notes = if ($selfManaged) {
        'Self-managed GitLab is scanned by an Entro Outpost Worker Group inside your network. Run here, or copy the generated script to a host that can reach GitLab.'
    }
    else {
        'gitlab.com is reached from Entro Cloud. An Outpost is not required. A private GitLab URL belongs on the self-managed variant.'
    }
    $inputs = @(
        @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Operator-chosen label'; Required = $true }
        @{ Name = 'GitLabUrl'; Source = 'Supply'; Prompt = 'GitLab URL'; Purpose = 'https://gitlab.com or the self-managed base URL'; Required = $urlRequired; Default = $urlDefault }
        @{ Name = 'TokenKind'; Source = 'Supply'; Prompt = 'Token type'; Purpose = 'Group access token (preferred) or personal access token'; ValidateSet = @('Group', 'Personal'); Default = 'Group'; Required = $false }
        @{ Name = 'GroupPath'; Source = 'Supply'; Prompt = 'GitLab group full path'; Purpose = 'Group that will own entro_svc, for example acme/platform'; When = $groupWhen; Required = $groupWhen }
        @{ Name = 'Username'; Source = 'Supply'; Prompt = 'GitLab username'; Purpose = 'User that will own entro_pat'; When = $userWhen; Required = $userWhen }
        @{ Name = 'TokenExpires'; Source = 'Supply'; Prompt = 'Token expiry (YYYY-MM-DD)'; Purpose = 'Expiry sent to the GitLab API; default is 90 days when omitted at run time'; Required = $false }
        @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Required in Entro for self-managed GitLab; optional for gitlab.com'; Required = $false }
        @{ Name = 'AdminToken'; Source = 'Supply'; Prompt = 'GitLab owner or admin token used to create the Entro token'; Purpose = 'Not the token you paste into Entro'; Secret = $true; When = $runRequired; Required = $runRequired }
        @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
    )
    $definition = @{
        Id            = [string]$Definition['Id']
        Platform      = 'GitLab'
        Product       = 'Entro'
        CoreSwitch    = [string]$Definition['CoreSwitch']
        CliName       = 'pwsh'
        Title         = [string]$Definition['Title']
        FolderName    = [string]$Definition['FolderName']
        AccessLevels  = @()
        AdminRoles    = @('GitLab group Owner (group access token) or instance admin (personal access token)')
        OutputsHelp   = 'Paste Nickname, GitLab URL, port 443 (or your listen port), username, the token in entro-gitlab-token.txt, and for self-managed GitLab the Outpost Worker Group plus Self managed.'
        TargetHost    = @{ Role = $role; Notes = $notes; Assert = $assert; AssertScript = '' }
        Inputs        = $inputs
        CheckInputs   = @(
            @{ Name = 'GitLabUrl'; Source = 'Supply'; Prompt = 'GitLab URL'; Purpose = 'Instance to verify'; Required = $true; Default = $(if ($urlDefault) { $urlDefault } else { $null }) }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'GitLab access token'; Purpose = 'Token to verify'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe    = { param($ctx, $whatIf) & $checkFn -Context $ctx -WhatIf:$whatIf -SelfManaged:$selfManaged }.GetNewClosure()
        Steps         = {
            param($ctx)
            $runProvision = $provisionFn
            $buildProvision = $provisionScriptFn
            $kind = if ($ctx['TokenKind']) { [string]$ctx['TokenKind'] } else { 'Group' }
            @(
                @{
                    Id     = 'entro-gitlab-token'
                    Title  = "Create a GitLab $kind access token for Entro"
                    Kind   = 'Ensure'
                    Why    = 'Group tokens use Owner plus read_api, read_user, and read_repository. Personal tokens add the api scope.'
                    Probe  = { param($c) 'Create' }
                    Run    = { param($c) & $runProvision -Context $c }.GetNewClosure()
                    BuildScript = { param($c) & $buildProvision -Context $c }.GetNewClosure()
                }
            )
        }.GetNewClosure()
        OnRunComplete = {
            param($ctx)
            $base = Get-EntroGitLabApiBase -Url ([string]$ctx['GitLabUrl'])
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(none for gitlab.com; required for self-managed)' }
            $tokenPath = if ($ctx['CreatedTokenPath']) { $ctx['CreatedTokenPath'] } else { 'entro-gitlab-token.txt' }
            $self = -not (Test-EntroGitLabHostIsCloud -Url $base)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Nickname: $($ctx['Nickname'])"
            Write-Host "  GitLab URL: $base"
            Write-Host "  Self managed: $(if ($self) { 'yes' } else { 'no' })"
            Write-Host "  Worker Group: $wg"
            Write-Host "  Token file: $tokenPath"
            Write-Host ''
        }
    }
    if ($selfManaged) {
        $definition['TargetHost']['AssertScript'] = @'
if ([string]::IsNullOrWhiteSpace($GitLabUrl)) { throw 'GitLabUrl is required for self-managed GitLab.' }
$gitlabBase = if ($GitLabUrl -match '^[a-z][a-z0-9+\.-]*://') { $GitLabUrl } else { "https://$GitLabUrl" }
$gitlabUri = [Uri]$gitlabBase
if ($gitlabUri.Host -eq 'gitlab.com') { throw 'gitlab.com belongs on the Entro GitLab cloud variant.' }
$gitlabPort = if ($gitlabUri.Port -gt 0) { $gitlabUri.Port } else { 443 }
$gitlabClient = [System.Net.Sockets.TcpClient]::new()
try {
    $gitlabWait = $gitlabClient.BeginConnect($gitlabUri.Host, $gitlabPort, $null, $null)
    if (-not $gitlabWait.AsyncWaitHandle.WaitOne(4000, $false)) { throw "Cannot reach GitLab at $($gitlabUri.Host):$gitlabPort." }
    $gitlabClient.EndConnect($gitlabWait)
}
finally { $gitlabClient.Dispose() }
'@
    }
    Register-IntegrationWizardDefinition $definition
}

function Register-GitLabEntroDefinitions {
    Add-GitLabEntroDefinition @{
        Id                = 'gitlab-entro'
        CoreSwitch        = 'Entro'
        Title             = 'Entro GitLab (gitlab.com)'
        FolderName        = 'Entro-GitLab'
        SelfManagedVariant = $false
    }
    Add-GitLabEntroDefinition @{
        Id                = 'gitlab-selfmanaged-entro'
        CoreSwitch        = 'GitLabSelfManaged'
        Title             = 'Entro GitLab self-managed'
        FolderName        = 'Entro-GitLab-Self-Managed'
        SelfManagedVariant = $true
    }
}

Export-ModuleMember -Function Register-GitLabEntroDefinitions, Get-EntroGitLabGroupScopes, Get-EntroGitLabPersonalScopes, Get-EntroGitLabApiBase, Test-EntroGitLabHostIsCloud
