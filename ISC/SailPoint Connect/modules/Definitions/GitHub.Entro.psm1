Set-StrictMode -Version Latest

$script:ProbeModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.OnPremProbe.psm1'
Import-Module $script:ProbeModule -Force -WarningAction SilentlyContinue

function Get-EntroGhesClassicScopes {
    @{
        Required    = @('repo', 'read:org', 'read:repo_hook', 'user', 'read:discussion')
        Recommended = @('read:packages', 'read:public_key', 'notifications', 'read:enterprise', 'read:audit_log', 'read:project', 'read:gpg_key', 'read:ssh_signing_key')
    }
}

function Get-EntroGhesApiBase {
    param([Parameter(Mandatory)][string]$Hostname)
    $text = $Hostname.Trim().TrimEnd('/')
    if ($text -match '^[a-z][a-z0-9+\.-]*://') {
        $uri = [Uri]$text
        $port = if ($uri.Port -gt 0 -and $uri.Port -ne 443) { ":$($uri.Port)" } else { '' }
        "https://$($uri.Host)$port/api/v3"
    }
    else {
        "https://$text/api/v3"
    }
}

function Test-GitHubGhesEntroCheck {
    param($Context, [bool]$WhatIf)
    $missing = [System.Collections.Generic.List[string]]::new()
    $met = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    $hostName = [string]$Context['Hostname']
    if ([string]::IsNullOrWhiteSpace($hostName)) { $missing.Add('Hostname') }
    else {
        $api = Get-EntroGhesApiBase -Hostname $hostName
        $ep = Get-OnPremEndpoint -Address $api
        if ($WhatIf) { $manual.Add("TCP $($ep.Host):$($ep.Port)") }
        elseif (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port) { $met.Add("TCP $($ep.Host):$($ep.Port)") }
        else { $missing.Add("TCP $($ep.Host):$($ep.Port)") }
        $token = [string]$Context['Token']
        if ([string]::IsNullOrWhiteSpace($token)) { $manual.Add('Classic PAT scopes (supply Token)') }
        elseif (-not $WhatIf -and $missing.Count -eq 0) {
            try {
                $response = Invoke-WebRequest -Method Get -Uri "$api/user" -Headers @{
                    Authorization = "token $token"
                    'User-Agent'  = 'SailPoint-Connect'
                    Accept        = 'application/vnd.github+json'
                } -TimeoutSec 20 -UseBasicParsing
                $met.Add('GET /api/v3/user')
                $header = [string]$response.Headers['X-OAuth-Scopes']
                $have = @($header -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                $scopes = Get-EntroGhesClassicScopes
                foreach ($scope in @($scopes.Required)) {
                    if ($have -contains $scope) { $met.Add("scope $scope") } else { $missing.Add("scope $scope") }
                }
                foreach ($scope in @($scopes.Recommended)) {
                    if ($have -contains $scope) { $met.Add("scope $scope") }
                    else { $manual.Add("recommended scope $scope (skip if this GHES version does not offer it)") }
                }
            }
            catch {
                $missing.Add("GHES API rejected the token: $($_.Exception.Message)")
            }
        }
    }
    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    @{
        Subject       = @{ Kind = 'GitHubEnterprise'; Label = 'GitHub Enterprise Server'; Name = $hostName; Note = 'Read-only probe. Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = -not $WhatIf
        Found         = $true
        Required      = @('TCP reachability', 'GET /api/v3/user', 'repo', 'read:org')
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = @{
            'TCP reachability' = 'This host can open the GHES HTTPS port'
            'GET /api/v3/user' = 'The classic PAT authenticates'
            'repo'             = 'Entro can read repository contents'
            'read:org'         = 'Entro can read organization membership'
        }
        ReadNote      = "Checked GHES from $([Environment]::MachineName)."
    }
}

function Register-GitHubEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'github-entro'
        Platform     = 'GitHub'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'gh'
        Title        = 'Entro GitHub integration'
        FolderName   = 'Entro-GitHub'
        AccessLevels = @()
        AdminRoles   = @('GitHub Organization Owner')
        OutputsHelp  = 'Install the Entro GitHub App on your organization or paste a Classic PAT into the Entro admin console.'
        Inputs       = @(
            @{ Name = 'Method'; Source = 'Supply'; Prompt = 'Integration method'; Purpose = 'GitHubApp (Entro Cloud - New) or ClassicPAT'; Required = $true; ValidateSet = @('ClassicPAT', 'GitHubApp'); Default = 'GitHubApp' }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Personal Access Token (PAT)'; Purpose = 'GitHub Personal Access Token (PAT)'; Required = $false; Secret = $true }
            @{ Name = 'Organization'; Source = 'Discover'; Prompt = 'GitHub Organization name (optional)'; Purpose = 'GitHub Organization name'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Personal Access Token (PAT)'; Purpose = 'GitHub PAT to verify'; Required = $true; Secret = $true }
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name (optional)'; Purpose = 'Organization to verify'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-github-onboard'
                    Title = 'Install Entro GitHub App or configure PAT'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        'Create'
                    }
                    Run   = {
                        param($c)
                        Write-Step 'Entro GitHub Onboarding'
                        $method = if ($c['Method']) { $c['Method'] } else { 'GitHubApp' }
                        $hasOrg = -not [string]::IsNullOrWhiteSpace([string]$c['Organization'])
                        $targetDesc = if ($hasOrg) { "organization '$($c['Organization'])'" } else { 'your GitHub account' }
                        if ($method -eq 'GitHubApp') {
                            Write-Info "Install the Entro GitHub App on $targetDesc."
                            Write-Info "In Entro UI -> Integrations -> GitHub -> install the app with permissions."
                        }
                        else {
                            Write-Info "Generate a Classic PAT with repo and read:org scopes for $targetDesc."
                            Write-Info "Paste the token into the Entro admin console."
                        }
                    }
                    BuildScript = {
                        param($c)
                        $hasOrg = -not [string]::IsNullOrWhiteSpace([string]$c['Organization'])
                        $targetDesc = if ($hasOrg) { "organization '$($c['Organization'])'" } else { 'GitHub account' }
                        @"
# Entro GitHub Integration Setup
Write-Host "Configure Entro integration for $targetDesc"
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $target = if (-not [string]::IsNullOrWhiteSpace([string]$ctx['Organization'])) { $ctx['Organization'] } else { '[Personal / All accessible repos]' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Target: $target"
            Write-Host "  Method: $($ctx['Method'])"
            Write-Host '  Registration: complete GitHub App installation or paste PAT in Entro UI'
            Write-Host ''
        }
    }

    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }
    Register-IntegrationWizardDefinition @{
        Id           = 'github-ghes-entro'
        Platform     = 'GitHub'
        Product      = 'Entro'
        CoreSwitch   = 'GhesEntro'
        CliName      = 'pwsh'
        Title        = 'Entro GitHub Enterprise Server'
        FolderName   = 'Entro-GitHub-Enterprise-Server'
        RequiredTools = @('Network path to the GHES hostname (HTTPS /api/v3)')
        AccessLevels = @()
        AdminRoles   = @('GitHub Enterprise user who can create a classic PAT')
        OutputsHelp  = @'
Paste into Entro (Management -> Accounts & Integrations -> GitHub Enterprise Server):
Display Name, Environment Type, GitHub server hostname, the classic PAT, and the Outpost Worker Group.
GHES does not offer an API to mint classic PATs. Create the token in the GHES UI, then Check or Run validates it.
'@
        TargetHost   = @{
            Role  = 'Internal host with HTTPS reachability to GitHub Enterprise Server'
            Notes = 'The Outpost Worker Group must reach the GHES hostname. Run Check or Run on a host that can open https://<hostname>/api/v3.'
            Assert = {
                param($c)
                $api = Get-EntroGhesApiBase -Hostname ([string]$c['Hostname'])
                $ep = Get-OnPremEndpoint -Address $api
                if (-not (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port)) {
                    throw "Cannot reach GHES at $($ep.Host):$($ep.Port). Run on a host that can reach the server, or use BuildScript."
                }
            }
            AssertScript = @'
if ([string]::IsNullOrWhiteSpace($Hostname)) { throw 'Hostname is required.' }
$ghesText = $Hostname.Trim()
if ($ghesText -notmatch '^[a-z][a-z0-9+\.-]*://') { $ghesText = "https://$ghesText" }
$ghesUri = [Uri]$ghesText
$ghesPort = if ($ghesUri.Port -gt 0) { $ghesUri.Port } else { 443 }
$ghesClient = [System.Net.Sockets.TcpClient]::new()
try {
    $ghesWait = $ghesClient.BeginConnect($ghesUri.Host, $ghesPort, $null, $null)
    if (-not $ghesWait.AsyncWaitHandle.WaitOne(4000, $false)) { throw "Cannot reach GHES at $($ghesUri.Host):$ghesPort." }
    $ghesClient.EndConnect($ghesWait)
}
finally { $ghesClient.Dispose() }
'@
        }
        Inputs       = @(
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'Display name in Entro'; Purpose = 'Label for this GHES account'; Required = $true }
            @{ Name = 'EnvironmentType'; Source = 'Supply'; Prompt = 'Environment type'; Purpose = 'Entro environment type'; ValidateSet = @('Production', 'Development', 'Staging'); Default = 'Development'; Required = $false }
            @{ Name = 'Hostname'; Source = 'Supply'; Prompt = 'GitHub Enterprise Server hostname'; Purpose = 'Hostname operators use in the browser, without a token'; Required = $true }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that will scan this GHES'; Required = $false }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Enterprise classic PAT'; Purpose = 'Classic PAT created in the GHES UI'; Secret = $true; When = $runRequired; Required = $runRequired }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'Hostname'; Source = 'Supply'; Prompt = 'GitHub Enterprise Server hostname'; Purpose = 'Server to verify'; Required = $true }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Enterprise classic PAT'; Purpose = 'Token to verify'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe   = { param($ctx, $whatIf) Test-GitHubGhesEntroCheck -Context $ctx -WhatIf:$whatIf }
        Steps        = {
            param($ctx)
            $hostLabel = if ($ctx['Hostname']) { [string]$ctx['Hostname'] } else { '<hostname>' }
            $scopes = Get-EntroGhesClassicScopes
            $all = @($scopes.Required) + @($scopes.Recommended)
            @(
                @{
                    Id     = 'entro-ghes-pat'
                    Title  = "Create a classic PAT on $hostLabel"
                    Kind   = 'Manual'
                    Why    = 'GitHub Enterprise Server does not provide an API for creating classic personal access tokens.'
                    Manual = "On $hostLabel open Settings -> Developer settings -> Personal access tokens -> Tokens (classic). Name it Entro, choose no expiration if policy allows, and select: $($all -join ', '). Skip a scope only when this GHES version does not show it."
                }
                @{
                    Id    = 'entro-ghes-validate'
                    Title = 'Validate the classic PAT against /api/v3/user'
                    Kind  = 'Ensure'
                    Why   = 'Entro needs the documented classic scopes. Required scopes fail the run; recommended scopes are reported when missing.'
                    Probe = { param($c) if ($c['Token']) { 'Update' } else { 'Create' } }
                    Run   = {
                        param($c)
                        $result = Test-GitHubGhesEntroCheck -Context $c -WhatIf:$false
                        foreach ($item in @($result.Met)) { Write-Ok $item }
                        foreach ($item in @($result.Manual)) { Write-Info $item }
                        if (@($result.Missing).Count -gt 0) {
                            throw "GHES token is missing: $(@($result.Missing) -join '; ')"
                        }
                        Write-Ok 'GHES classic PAT passed the required scope check.'
                    }
                    BuildScript = {
                        param($c)
                        $scopesNow = Get-EntroGhesClassicScopes
                        $required = ($scopesNow.Required | ForEach-Object { "'$_'" }) -join ', '
                        $recommended = ($scopesNow.Recommended | ForEach-Object { "'$_'" }) -join ', '
                        @"
if ([string]::IsNullOrWhiteSpace(`$Token)) { `$Token = Read-Host 'GHES classic PAT' }
`$ghesHost = [string]`$Hostname
if (`$ghesHost -match '^[a-z][a-z0-9+\.-]*://') { `$ghesHost = ([Uri]`$ghesHost).Host }
`$api = "https://`$ghesHost/api/v3"
`$response = Invoke-WebRequest -Method Get -Uri "`$api/user" -Headers @{ Authorization = "token `$Token"; 'User-Agent' = 'SailPoint-Connect'; Accept = 'application/vnd.github+json' } -UseBasicParsing -TimeoutSec 20
`$have = @([string]`$response.Headers['X-OAuth-Scopes'] -split ',' | ForEach-Object { `$_.Trim() } | Where-Object { `$_ })
`$required = @($required)
`$missing = @(`$required | Where-Object { `$have -notcontains `$_ })
if (`$missing.Count -gt 0) { throw "GHES token is missing scopes: `$(`$missing -join ', ')" }
`$recommended = @($recommended)
`$absent = @(`$recommended | Where-Object { `$have -notcontains `$_ })
if (`$absent.Count -gt 0) { Write-Host "Recommended scopes not present (skip if GHES does not offer them): `$(`$absent -join ', ')" }
Write-Host 'GHES classic PAT passed the required scope check.'
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Target host: internal host that can reach $($ctx['Hostname'])"
            Write-Host "  Display name: $($ctx['DisplayName'])"
            Write-Host "  Environment type: $($ctx['EnvironmentType'])"
            Write-Host "  Hostname: $($ctx['Hostname'])"
            Write-Host "  Worker Group: $wg"
            Write-Host '  Access token: the classic PAT from the GHES UI (not printed here)'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitHubEntroDefinitions, Get-EntroGhesClassicScopes, Get-EntroGhesApiBase
