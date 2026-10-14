#Requires -Version 7.0
<#
.SYNOPSIS
    Imports the EMEA TES Team email templates into an Identity Security Cloud tenant.

.DESCRIPTION
    Creates or updates one custom email template per JSON file in -Path (default: ./templates) with
    POST /v2026/notification-templates. A template that already has a custom version in the tenant is
    updated in place; any other becomes the custom version of the SailPoint default with the same key.

    The script talks to the tenant through the sail CLI. Run without parameters and it guides you:

      1. Ensures sail is installed (install steps if it is missing), then asks which sail environment to use
         or creates one. Credentials are stored with `sail set pat`, not typed into this script.
      2. Checks that the environment can reach the tenant and read email templates.
      3. Asks for each template setting (organisation name, banner tagline, brand colours, support email
         and default language). Press Enter to keep the value shown in brackets.
      4. Shows the templates to import. Space selects or clears the highlighted one; the first line selects
         or clears them all. Enter continues.
      5. Prints the changes (templates created and updated, settings, backup) and asks for confirmation.

    Values passed as parameters are not asked for. -NonInteractive skips every prompt, the list and the
    confirmation, for use in pipelines; input redirection does the same. Pass -SailEnvironment (or rely on
    sail's active environment) when running non-interactively.

    Before changing anything, the current custom versions of the selected templates are saved to
    -BackupPath in the same format as ./templates, so importing that folder with -Path rolls them back.
    Templates that were not customized are listed in the backup's _not-customized.json; to roll those
    back, delete their custom version in the ISC admin UI (Global > Email Templates).

    After the import, every template is read back and its subject compared with what was sent.

    The personal access token stored in sail must belong to an admin who can manage email templates
    (Global > Email Templates in the admin UI).

.PARAMETER SailEnvironment
    sail CLI environment to use (see `~/.sailpoint/config.yaml`, or create one when the script asks).
    Default: sail's active environment.

.PARAMETER Path
    Folder of template JSON files to import. Default: the templates folder next to this script.

.PARAMETER Scope
    Templates selected initially: all (default), rewritten (translated end-user templates) or wrapped
    (admin alerts that keep their English wording). Read from manifest.json in -Path; ignored for folders
    without one, such as backups.

.PARAMETER Key
    Templates selected initially, by key. Wildcards are allowed, for example 'access_request_*'.

.PARAMETER OrganizationName
    Name shown in the banner, the sign-off and the footer ("This is an automated message from the ...
    identity platform"). Default in the templates: EMEA TES Team.

.PARAMETER BannerTagline
    Small capitalised text above the organisation name in the banner. Default: Identity & Access.

.PARAMETER PrimaryColor
    Banner, headings and buttons, as #RRGGBB. Default: #0033A1 (SailPoint navy).

.PARAMETER DarkColor
    Start of the banner gradient. Default: #011E69.

.PARAMETER AccentColor
    Links, section titles and information boxes. Default: #0071CE.

.PARAMETER HighlightColor
    Banner stripe and warning boxes. Default: #CC27B0.

.PARAMETER UseTenantBranding
    Take -PrimaryColor and -AccentColor from the tenant's branding (navigation and action button colours,
    Global > Branding in the admin UI) unless they are passed explicitly. Asked for when not passed.

.PARAMETER SupportEmail
    Support address added to every footer ("Need help? Contact ..."). Default: none.

.PARAMETER DefaultLanguage
    Language for recipients whose preferredLanguage is missing or unsupported. Must be one of the
    languages in manifest.json. Default: en.

.PARAMETER OutputPath
    Write the configured templates to this folder instead of importing them. The tenant is not contacted
    unless -UseTenantBranding is set. Import the folder later with -Path.

.PARAMETER BackupPath
    Folder for backups. Each run writes a time-stamped subfolder. Default: ./backups next to this script.

.PARAMETER NoBackup
    Skip the backup.

.PARAMETER NonInteractive
    Do not prompt: use parameters, environment variables and template defaults, import the -Scope and
    -Key selection, and do not ask for confirmation.

.EXAMPLE
    ./Import-EmailTemplates.ps1

    Ensures sail is ready, asks which environment (or creates one), then the settings and the templates,
    shows the changes and imports them after confirmation.

.EXAMPLE
    ./Import-EmailTemplates.ps1 -SailEnvironment acme -OrganizationName 'Acme Corp' -WhatIf

    Uses the acme sail environment, asks for the remaining values and shows the changes, without changing
    the tenant.

.EXAMPLE
    ./Import-EmailTemplates.ps1 -NonInteractive -SailEnvironment acme -OrganizationName 'Acme Corp' `
        -UseTenantBranding -SupportEmail it-help@acme.com -DefaultLanguage es

    Imports every template branded for Acme Corp without prompting (sail environment acme must already work).

.EXAMPLE
    ./Import-EmailTemplates.ps1 -OrganizationName 'Acme Corp' -PrimaryColor '#1B365D' -OutputPath ./out/acme

    Writes the configured templates to ./out/acme for review, without contacting a tenant.

.EXAMPLE
    ./Import-EmailTemplates.ps1 -Path ./backups/20261014-103000

    Rolls back to the custom versions saved by an earlier run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SailEnvironment,

    [string]$Path = (Join-Path $PSScriptRoot 'templates'),

    [ValidateSet('all', 'rewritten', 'wrapped')]
    [string]$Scope = 'all',

    [string[]]$Key,

    [ValidateNotNullOrEmpty()]
    [string]$OrganizationName,

    [string]$BannerTagline,

    [ValidatePattern('^#[0-9A-Fa-f]{6}$')]
    [string]$PrimaryColor,

    [ValidatePattern('^#[0-9A-Fa-f]{6}$')]
    [string]$DarkColor,

    [ValidatePattern('^#[0-9A-Fa-f]{6}$')]
    [string]$AccentColor,

    [ValidatePattern('^#[0-9A-Fa-f]{6}$')]
    [string]$HighlightColor,

    [switch]$UseTenantBranding,

    [ValidatePattern('^$|^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string]$SupportEmail,

    [ValidatePattern('^[a-z]{2}$')]
    [string]$DefaultLanguage,

    [string]$OutputPath,

    [string]$BackupPath = (Join-Path $PSScriptRoot 'backups'),

    [switch]$NoBackup,

    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$Interactive = -not $NonInteractive -and -not [Console]::IsInputRedirected
$SailConfigPath = Join-Path $HOME '.sailpoint/config.yaml'

$TemplatesApi = '/v2026/notification-templates'
$PayloadFields = 'key', 'name', 'description', 'medium', 'locale', 'from', 'replyTo', 'header', 'footer', 'subject', 'body'
$Esc = [char]27

# Template settings (#set lines at the top of every template): the parameter that sets each one, the
# prompt label and the accepted values (a regex, or the manifest languages for the default language).
$Settings = [ordered]@{
    emeaDefaultLanguage = @{ Parameter = 'DefaultLanguage'; Label = 'Default language' }
    emeaOrgName         = @{ Parameter = 'OrganizationName'; Label = 'Organisation name'; Pattern = '\S'; Problem = 'Enter a name.' }
    emeaBannerTagline   = @{ Parameter = 'BannerTagline'; Label = 'Banner tagline' }
    emeaColorPrimary    = @{ Parameter = 'PrimaryColor'; Label = 'Primary colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    emeaColorDark       = @{ Parameter = 'DarkColor'; Label = 'Dark colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    emeaColorAccent     = @{ Parameter = 'AccentColor'; Label = 'Accent colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    emeaColorHighlight  = @{ Parameter = 'HighlightColor'; Label = 'Highlight colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    emeaSupportEmail    = @{ Parameter = 'SupportEmail'; Label = 'Support email'; Pattern = '^$|^[^@\s]+@[^@\s]+\.[^@\s]+$'; Problem = 'Enter an email address, or - for none.'; Optional = $true }
}

function Set-TemplateSetting {
    <# Replaces the value of `#set($<Variable> = '...')`; Velocity single-quoted strings escape ' as ''. #>
    param([string]$Text, [string]$Variable, [string]$Value)
    if (-not $Text) { return $Text }
    $literal = $Value.Replace("'", "''").Replace('$', '$$')
    return [regex]::Replace($Text, "#set\(\`$$Variable = '(?:[^']|'')*'\)", "#set(`$$Variable = '$literal')")
}

# --- Prompts ------------------------------------------------------------------------------------

function Read-Value {
    <# Asks for a value; Enter keeps the default, '-' clears an optional value. Re-asks until $Validate returns nothing. #>
    param([string]$Label, [string]$Default, [scriptblock]$Validate, [string]$Hint, [switch]$Optional)
    if ($Hint) { Write-Host "  $Hint" -ForegroundColor DarkGray }
    while ($true) {
        $shown = if ($Default) { " [$Default]" } elseif ($Optional) { ' [none]' } else { '' }
        $answer = (Read-Host "$Label$shown").Trim()
        $value = if (-not $answer) { $Default } elseif ($Optional -and $answer -eq '-') { '' } else { $answer }
        $problem = if ($Validate) { & $Validate $value }
        if (-not $problem) { return $value }
        Write-Host "  $problem" -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param([string]$Prompt, [bool]$Default)
    $choices = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = (Read-Host "$Prompt $choices").Trim()
        if (-not $answer) { return $Default }
        if ($answer -match '^(y|yes)$') { return $true }
        if ($answer -match '^(n|no)$') { return $false }
    }
}

function Format-Swatch {
    param([string]$Color)
    if ($Color -notmatch '^#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$') { return $Color }
    $r, $g, $b = $Matches[1..3] | ForEach-Object { [Convert]::ToInt32($_, 16) }
    return "$Esc[48;2;${r};${g};${b}m    $Esc[0m $Color"
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
}

function Select-Templates {
    <# Full-screen checklist. Rows have Selected (bool), Key, Kind and Action; Selected is updated in place.
       Returns $false when cancelled. #>
    param([object[]]$Rows)
    $cursor = 0
    $top = 0
    $message = ''
    $keyWidth = [Math]::Min(60, ($Rows | ForEach-Object { $_.Key.Length } | Measure-Object -Maximum).Maximum)
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            $size = $Host.UI.RawUI.WindowSize
            $height = [Math]::Max(3, $size.Height - 6)
            $lines = $Rows.Count + 1
            if ($cursor -lt $top) { $top = $cursor }
            elseif ($cursor -ge $top + $height) { $top = $cursor - $height + 1 }
            $count = @($Rows | Where-Object Selected).Count

            $frame = [Text.StringBuilder]::new("$Esc[H$Esc[2J")
            [void]$frame.AppendLine("$Esc[1mSelect the templates to import$Esc[0m")
            [void]$frame.AppendLine("$Esc[2m↑/↓ move   PgUp/PgDn page   Space select   A all   Enter continue   Esc cancel$Esc[0m")
            [void]$frame.AppendLine('')
            for ($line = $top; $line -lt [Math]::Min($lines, $top + $height); $line++) {
                if ($line -eq 0) {
                    $mark = if ($count -eq $Rows.Count) { 'x' } elseif ($count) { '-' } else { ' ' }
                    $text = "[$mark] Select/deselect all".PadRight($keyWidth + 4) + "   $count of $($Rows.Count) selected"
                }
                else {
                    $row = $Rows[$line - 1]
                    $mark = if ($row.Selected) { 'x' } else { ' ' }
                    $text = "[$mark] " + $row.Key.PadRight($keyWidth) + '   ' + $row.Kind.PadRight(10) + $row.Action
                }
                if ($text.Length -gt $size.Width - 3) { $text = $text.Substring(0, $size.Width - 3) }
                $text = if ($line -eq $cursor) { "$Esc[7m> $text$Esc[0m" } else { "  $text" }
                [void]$frame.AppendLine($text)
            }
            [void]$frame.Append("$Esc[2m  rows $($top + 1)-$([Math]::Min($lines, $top + $height)) of $lines$Esc[0m")
            if ($message) { [void]$frame.Append("   $Esc[33m$message$Esc[0m") }
            [Console]::Write($frame.ToString())
            $message = ''

            $pressed = [Console]::ReadKey($true)
            switch ($pressed.Key) {
                'UpArrow' { $cursor = [Math]::Max(0, $cursor - 1) }
                'DownArrow' { $cursor = [Math]::Min($lines - 1, $cursor + 1) }
                'PageUp' { $cursor = [Math]::Max(0, $cursor - $height) }
                'PageDown' { $cursor = [Math]::Min($lines - 1, $cursor + $height) }
                'Home' { $cursor = 0 }
                'End' { $cursor = $lines - 1 }
                'Spacebar' {
                    if ($cursor -eq 0) {
                        $all = $count -ne $Rows.Count
                        foreach ($row in $Rows) { $row.Selected = $all }
                    }
                    else {
                        $Rows[$cursor - 1].Selected = -not $Rows[$cursor - 1].Selected
                    }
                }
                'A' {
                    $all = $count -ne $Rows.Count
                    foreach ($row in $Rows) { $row.Selected = $all }
                }
                'Enter' {
                    if ($count) { return $true }
                    $message = 'Select at least one template.'
                }
                'Escape' { return $false }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
        [Console]::Write("$Esc[H$Esc[2J")
    }
}

# --- Connection (sail CLI) ----------------------------------------------------------------------

function Install-SailCli {
    if (Get-Command sail -ErrorAction SilentlyContinue) { return }
    Write-Host 'The sail CLI is required to talk to the tenant.' -ForegroundColor Yellow
    Write-Host '  macOS:  brew tap sailpoint-oss/tap && brew install sailpoint-cli'
    Write-Host '  Other:  https://developer.sailpoint.com/docs/tools/cli'
    if (-not $Interactive) {
        throw 'The sail CLI is not installed. Install it, configure an environment (`sail env create`, `sail set pat`), then re-run with -SailEnvironment.'
    }
    while (-not (Get-Command sail -ErrorAction SilentlyContinue)) {
        Read-Host 'Press Enter after installing sail (Ctrl+C to stop)' | Out-Null
    }
    Write-Host "  ✓ sail found: $((Get-Command sail).Source)" -ForegroundColor Green
}

function Get-SailEnvironments {
    <# Environments from ~/.sailpoint/config.yaml. `sail env list` asks for Enter, so it is not used here. #>
    $result = [ordered]@{ Active = $null; Environments = [ordered]@{} }
    if (-not (Test-Path $SailConfigPath)) { return [pscustomobject]$result }
    $current = $null
    foreach ($line in Get-Content $SailConfigPath) {
        if ($line -match '^activeenvironment:\s*(\S+)\s*$') { $result.Active = $Matches[1]; continue }
        if ($line -match '^\s{4}([A-Za-z0-9_.-]+):\s*$') {
            $current = $Matches[1]
            $result.Environments[$current] = [ordered]@{ Name = $current; TenantUrl = ''; ApiUrl = ''; AuthType = '' }
            continue
        }
        if (-not $current) { continue }
        if ($line -match '^\s{8}tenanturl:\s*(.+?)\s*$') { $result.Environments[$current].TenantUrl = $Matches[1].TrimEnd('/') }
        elseif ($line -match '^\s{8}baseurl:\s*(.+?)\s*$') { $result.Environments[$current].ApiUrl = $Matches[1].TrimEnd('/') }
        elseif ($line -match '^\s{8}authtype:\s*(.+?)\s*$') { $result.Environments[$current].AuthType = $Matches[1] }
    }
    return [pscustomobject]$result
}

function Initialize-SailEnvironment {
    <# Runs sail env create and sail set pat so credentials stay in sail's keyring. #>
    param([string]$SuggestedName)
    $name = Read-Value 'Environment name' $SuggestedName -Hint 'A short label for this tenant in sail, for example acme or emea-tes-team.' -Validate {
        param($v) if ($v -notmatch '^[A-Za-z0-9_.-]+$') { 'Use letters, digits, dots, hyphens or underscores.' }
    }
    Write-Host ''
    Write-Host "Creating sail environment '$name'." -ForegroundColor Cyan
    Write-Host 'sail will ask for two URLs:'
    Write-Host '  Tenant URL  https://acme.identitynow.com'
    Write-Host '  API URL     https://acme.api.identitynow.com'
    Write-Host 'For demo tenants, use identitynow-demo.com instead of identitynow.com.'
    Write-Host ''
    & sail env create $name
    if ($LASTEXITCODE) { throw "sail env create $name failed (exit $LASTEXITCODE)." }
    Write-Host ''
    Write-Host "Store a personal access token for '$name'." -ForegroundColor Cyan
    Write-Host 'Create one in the admin UI under Admin > Global > Security Settings > Personal Access Tokens'
    Write-Host '(needs a role that can manage email templates, for example Admin). sail will ask for the'
    Write-Host 'client ID and secret; they are saved in your OS keyring, not in this script.'
    Write-Host ''
    & sail set auth pat --env $name
    if ($LASTEXITCODE) { throw "sail set auth pat --env $name failed (exit $LASTEXITCODE)." }
    & sail set pat --env $name
    if ($LASTEXITCODE) { throw "sail set pat --env $name failed (exit $LASTEXITCODE)." }
    return $name
}

function Select-SailEnvironment {
    $config = Get-SailEnvironments
    $names = @($config.Environments.Keys)
    if ($SailEnvironment) {
        if ($SailEnvironment -notin $names) {
            throw "sail environment '$SailEnvironment' is not in $SailConfigPath. Create it with: sail env create $SailEnvironment && sail set pat --env $SailEnvironment"
        }
        return $SailEnvironment
    }
    if (-not $Interactive) {
        if ($config.Active) { return $config.Active }
        throw 'Pass -SailEnvironment, or set an active environment with `sail env use`.'
    }
    if (-not $names) {
        Write-Host 'No sail environments are configured yet.'
        return Initialize-SailEnvironment -SuggestedName 'acme'
    }
    Write-Host 'Configured sail environments:'
    for ($i = 0; $i -lt $names.Count; $i++) {
        $env = $config.Environments[$names[$i]]
        $mark = if ($names[$i] -eq $config.Active) { ' (active)' } else { '' }
        Write-Host ("  {0,2}) {1,-24} {2}{3}" -f ($i + 1), $names[$i], $env.TenantUrl, $mark)
    }
    Write-Host ("  {0,2}) Create a new environment" -f ($names.Count + 1))
    $default = if ($config.Active) { "$([array]::IndexOf($names, $config.Active) + 1)" } else { '1' }
    $choice = Read-Value 'Environment' $default -Validate {
        param($v)
        $n = 0
        if (-not [int]::TryParse($v, [ref]$n) -or $n -lt 1 -or $n -gt $names.Count + 1) {
            "Enter a number between 1 and $($names.Count + 1)."
        }
    }
    $index = [int]$choice
    if ($index -gt $names.Count) { return Initialize-SailEnvironment -SuggestedName '' }
    return $names[$index - 1]
}

function Set-SailPat {
    param([string]$Name)
    Write-Host "Update the personal access token for sail environment '$Name'." -ForegroundColor Cyan
    Write-Host 'sail will ask for the client ID and secret.'
    & sail set auth pat --env $Name
    & sail set pat --env $Name
    if ($LASTEXITCODE) { throw "sail set pat --env $Name failed (exit $LASTEXITCODE)." }
}

function ConvertFrom-SailOutput {
    <# sail mixes log lines, and with debug on the whole HTTP exchange, around the response.
       Keep the status and the JSON body. Header lines (including the bearer token) are dropped. #>
    param([string[]]$Lines, [string]$Method, [string]$Uri)
    $status = 0
    $body = foreach ($line in $Lines) {
        if ($line -match '^\d{4}/\d{2}/\d{2} ') { continue }
        if ($line -match '^Status:\s*(\d+)') { $status = [int]$Matches[1]; continue }
        if ($line -match '^(GET|POST|PUT|PATCH|DELETE|HEAD) ') { continue }
        if ($line -match '^HTTP/') { continue }
        if ($line -match '^[A-Za-z0-9-]+: ') { continue }
        if (-not [string]::IsNullOrWhiteSpace($line)) { $line }
    }
    $parsed = $null
    $body = @($body)
    foreach ($candidate in @($body | Select-Object -Last 1), (($body -join "`n").Trim())) {
        if (-not $candidate) { continue }
        try { $parsed = $candidate | ConvertFrom-Json -Depth 20; break } catch { $parsed = $null }
    }
    if ($status -lt 200 -or $status -ge 300) {
        $detail = if ($parsed) { ($parsed | ConvertTo-Json -Depth 4 -Compress) } elseif ($body) { ($body -join ' ').Trim() } else { 'no response' }
        if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) }
        $exception = [Exception]::new("sail api $($Method.ToLower()) $Uri failed (${status}): $detail")
        $exception.Data['Status'] = $status
        throw $exception
    }
    return $parsed
}

function Invoke-Isc {
    param(
        [Parameter(Mandatory)][ValidateSet('Get', 'Post')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [object]$Body
    )
    $json = if ($null -ne $Body) { $Body | ConvertTo-Json -Depth 10 } else { $null }
    $arguments = @('api', $Method.ToLower(), $Uri, '-H', 'X-SailPoint-Experimental: true', '--env', $SailEnvironment)
    $bodyFile = $null
    try {
        if ($json) {
            # A file keeps large bodies clear of the Windows command-line length limit.
            $bodyFile = New-TemporaryFile
            [IO.File]::WriteAllText($bodyFile.FullName, $json, [Text.UTF8Encoding]::new($false))
            $arguments += @('-f', $bodyFile.FullName)
        }
        # sail prints the status and response body on stderr. Empty stdin avoids prompts that wait for Enter.
        $lines = @($null | & sail @arguments 2>&1 | ForEach-Object { "$_" })
    }
    finally {
        if ($bodyFile) { Remove-Item $bodyFile.FullName -Force }
    }
    return ConvertFrom-SailOutput -Lines $lines -Method $Method -Uri $Uri
}

function Get-CustomEmailTemplates {
    $found = @{}
    for ($offset = 0; ; $offset += 250) {
        $page = @(Invoke-Isc -Method Get -Uri "$($TemplatesApi)?limit=250&offset=$offset")
        foreach ($template in $page) {
            if ($template.medium -eq 'EMAIL' -and $template.locale -eq 'en') { $found[$template.key] = $template }
        }
        if ($page.Count -lt 250) { return $found }
    }
}

function Test-TenantConnection {
    <# Health check: tenant reachable and email templates readable. Returns the tenant's custom templates. #>
    try {
        $tenant = Invoke-Isc -Method Get -Uri '/v2026/tenant'
        $script:TenantName = $tenant.name
        Write-Host "  ✓ Tenant $($tenant.name) ($($tenant.pod))" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Data['Status'] -in 401, 403) { throw }
        Write-Host '  ! Tenant details unavailable; continuing.' -ForegroundColor Yellow
    }
    try {
        $found = Get-CustomEmailTemplates
    }
    catch {
        if ($_.Exception.Data['Status'] -in 401, 403) {
            throw 'Cannot read email templates. The token in sail needs an admin role that manages email templates (for example Admin).'
        }
        throw
    }
    Write-Host "  ✓ Email templates readable ($($found.Count) customized)" -ForegroundColor Green
    return $found
}

function ConvertTo-Payload {
    param([Parameter(Mandatory)][object]$Template)
    $payload = [ordered]@{}
    foreach ($field in $PayloadFields) { $payload[$field] = $Template.$field }
    return [pscustomobject]$payload
}

# --- Load templates -----------------------------------------------------------------------------

$Path = (Resolve-Path $Path).Path
$manifestFile = Join-Path $Path 'manifest.json'
$manifest = if (Test-Path $manifestFile) { Get-Content $manifestFile -Raw | ConvertFrom-Json } else { $null }
$files = @(Get-ChildItem -Path $Path -Filter '*.json' -File | Where-Object { $_.Name -notin 'manifest.json', '_not-customized.json' })
if (-not $files) { throw "No template files in $Path." }
if ($DefaultLanguage -and $manifest -and $DefaultLanguage -notin $manifest.languages) {
    throw "-DefaultLanguage must be one of: $($manifest.languages -join ', ')."
}

# --- Connect and check --------------------------------------------------------------------------

$Connection = $null
$TenantName = $null
$existing = @{}
$connect = -not $OutputPath -or $UseTenantBranding

if ($connect) {
    Write-Section 'Tenant'
    Install-SailCli
    $SailEnvironment = Select-SailEnvironment
    $Connection = @{ Transport = 'Sail' }
    $envInfo = (Get-SailEnvironments).Environments[$SailEnvironment]
    $Target = if ($envInfo.TenantUrl) { "$SailEnvironment ($($envInfo.TenantUrl))" } else { "sail environment $SailEnvironment" }
    while ($true) {
        Write-Host "Checking $Target"
        try {
            $existing = Test-TenantConnection
            break
        }
        catch {
            Write-Host "  ✗ $($_.Exception.Message)" -ForegroundColor Red
            $rejected = $_.Exception.Data['Status'] -in 401, 403
            if (-not $Interactive) {
                if ($rejected) { throw "sail environment '$SailEnvironment' was rejected. Fix it with: sail set pat --env $SailEnvironment" }
                throw
            }
            if ($rejected -and (Read-YesNo "Run ``sail set pat --env $SailEnvironment`` and try again?" $true)) {
                Set-SailPat -Name $SailEnvironment
                continue
            }
            if (-not $rejected -and (Read-YesNo 'Try the health check again?' $true)) { continue }
            Write-Host 'Cancelled; nothing was changed.'
            return
        }
    }
    if ($TenantName) { $Target = "$TenantName · $Target" }
}

# --- Settings -----------------------------------------------------------------------------------

$branding = $null
if ($Connection -and $manifest -and ($UseTenantBranding -or $Interactive)) {
    try { $branding = @(Invoke-Isc -Method Get -Uri '/v2026/brandings') | Select-Object -First 1 } catch { $branding = $null }
}
$tenantColors = @{}
if ($branding) {
    if ($branding.navigationColor) { $tenantColors.PrimaryColor = "#$($branding.navigationColor.TrimStart('#'))" }
    if ($branding.actionButtonColor) { $tenantColors.AccentColor = "#$($branding.actionButtonColor.TrimStart('#'))" }
}

$defaults = [ordered]@{}
if ($manifest) {
    foreach ($setting in $manifest.settings) { $defaults[$setting.variable] = $setting.default }
}

if ($manifest -and $Interactive) {
    Write-Section 'Settings'
    Write-Host 'Press Enter to keep the value in brackets.' -ForegroundColor DarkGray

    if (-not $PSBoundParameters.ContainsKey('UseTenantBranding') -and $tenantColors.Count) {
        $shown = ($tenantColors.GetEnumerator() | Sort-Object Key -Descending | ForEach-Object { Format-Swatch $_.Value }) -join '  '
        Write-Host "Tenant branding colours: $shown"
        $UseTenantBranding = Read-YesNo 'Start from the tenant branding colours?' $true
    }

    $descriptions = @{}
    foreach ($setting in $manifest.settings) { $descriptions[$setting.variable] = $setting.description }
    foreach ($variable in $Settings.Keys) {
        $setting = $Settings[$variable]
        if (-not $defaults.Contains($variable) -or $PSBoundParameters.ContainsKey($setting.Parameter)) { continue }
        $default = if ($UseTenantBranding -and $tenantColors.ContainsKey($setting.Parameter)) { $tenantColors[$setting.Parameter] } else { $defaults[$variable] }
        $validate = if ($variable -eq 'emeaDefaultLanguage') {
            { param($v) if ($v -notin $manifest.languages) { "Use one of: $($manifest.languages -join ', ')." } }
        }
        elseif ($setting.ContainsKey('Pattern')) {
            $pattern = $setting.Pattern; $problem = $setting.Problem
            { param($v) if ($v -notmatch $pattern) { $problem } }.GetNewClosure()
        }
        $value = Read-Value $setting.Label $default -Hint $descriptions[$variable] -Validate $validate -Optional:([bool]$setting['Optional'])
        if ($variable -like 'emeaColor*') { Write-Host "  $(Format-Swatch $value)" }
        $PSBoundParameters[$setting.Parameter] = $value
    }
}
elseif ($UseTenantBranding) {
    foreach ($parameter in $tenantColors.Keys) {
        if (-not $PSBoundParameters.ContainsKey($parameter)) { $PSBoundParameters[$parameter] = $tenantColors[$parameter] }
    }
}

$applied = [ordered]@{}
foreach ($variable in $Settings.Keys) {
    $parameter = $Settings[$variable].Parameter
    if ($PSBoundParameters.ContainsKey($parameter)) { $applied[$variable] = [string]$PSBoundParameters[$parameter] }
}
if ($manifest) {
    foreach ($property in $manifest.subjectFallback.PSObject.Properties) {
        foreach ($variable in $applied.Keys) { $property.Value = Set-TemplateSetting $property.Value $variable $applied[$variable] }
    }
}

$templates = foreach ($file in $files) {
    $template = Get-Content $file.FullName -Raw -Encoding utf8 | ConvertFrom-Json
    foreach ($variable in $applied.Keys) {
        $template.body = Set-TemplateSetting $template.body $variable $applied[$variable]
        $template.subject = Set-TemplateSetting $template.subject $variable $applied[$variable]
    }
    $kind = if (-not $manifest) { '' } elseif ($template.key -in $manifest.rewritten) { 'Rewritten' } else { 'Wrapped' }
    $template | Add-Member -NotePropertyMembers @{
        FileName = $file.BaseName
        Kind     = $kind
        Action   = if ($OutputPath) { 'Write' } elseif ($existing.ContainsKey($template.key)) { 'Update' } else { 'Create' }
    } -PassThru
}
$templates = @($templates | Sort-Object key)

# --- Select templates ---------------------------------------------------------------------------

$inScope = if ($manifest -and $Scope -ne 'all') { @($manifest.$Scope) } else { $null }
$rows = foreach ($template in $templates) {
    $templateKey = $template.key
    $selected = (-not $inScope -or $templateKey -in $inScope) -and (-not $Key -or ($Key | Where-Object { $templateKey -like $_ }))
    [pscustomobject]@{ Selected = [bool]$selected; Key = $templateKey; Kind = $template.Kind; Action = $template.Action; Template = $template }
}
if ($Interactive -and -not (Select-Templates -Rows $rows)) {
    Write-Host 'Cancelled; nothing was changed.'
    return
}
$templates = @($rows | Where-Object Selected | ForEach-Object { $_.Template })
if (-not $templates) { throw "No templates in $Path match the selection." }

foreach ($template in $templates) {
    $template | Add-Member -NotePropertyName Fallback -NotePropertyValue $null
    if ($template.Action -eq 'Create' -and $manifest -and $template.subject.Length -gt $manifest.subjectLimit) {
        # New custom versions of default templates store at most subjectLimit subject characters;
        # only records that already exist accept the longer multilingual subject.
        $template.Fallback = $manifest.subjectFallback.($template.FileName)
    }
}

# --- Report and confirm -------------------------------------------------------------------------

$backupFolder = if (-not $OutputPath -and -not $NoBackup) { Join-Path $BackupPath (Get-Date -Format 'yyyyMMdd-HHmmss') } else { $null }
$updates = @($templates | Where-Object Action -eq 'Update')
$creates = @($templates | Where-Object Action -eq 'Create')

Write-Section 'Changes'
if ($OutputPath) {
    Write-Host "Write $($templates.Count) configured template(s) to $OutputPath; the tenant is not changed."
}
else {
    Write-Host "Tenant:          $Target"
    Write-Host "Templates:       $($templates.Count) selected; $($updates.Count) custom version(s) replaced, $($creates.Count) created"
    Write-Host "Backup:          $(if ($backupFolder) { "current custom versions of $($updates.Count) template(s) to $backupFolder" } else { 'none (-NoBackup)' })"
}
if ($manifest) {
    Write-Host 'Settings:'
    foreach ($variable in $Settings.Keys) {
        if (-not $defaults.Contains($variable)) { continue }
        $value = if ($applied.Contains($variable)) { $applied[$variable] } else { $defaults[$variable] }
        $shown = if ($variable -like 'emeaColor*') { Format-Swatch $value } elseif ($value) { $value } else { '(none)' }
        $note = if ($value -ne $defaults[$variable]) { '' } else { "$Esc[2m  template default$Esc[0m" }
        Write-Host ("  {0,-18} {1}{2}" -f $Settings[$variable].Label, $shown, $note)
    }
}
Write-Host ''
foreach ($template in $templates) {
    $color = switch ($template.Action) { 'Update' { 'Yellow' } 'Create' { 'Green' } default { 'Gray' } }
    Write-Host ("  {0,-7}" -f $template.Action) -ForegroundColor $color -NoNewline
    Write-Host (" {0,-58} {1}" -f $template.key, $template.name)
    if ($template.Fallback) {
        Write-Host '          English subject: the multilingual subject is too long for a new custom version.' -ForegroundColor DarkGray
    }
}

if ($WhatIfPreference) {
    Write-Host ''
    Write-Host 'WhatIf: nothing was changed.'
    return
}
if ($Interactive) {
    Write-Host ''
    $question = if ($OutputPath) { "Write $($templates.Count) template(s)?" } else { "Import $($templates.Count) template(s) into $(if ($TenantName) { $TenantName } else { $Target })?" }
    if (-not (Read-YesNo $question $false)) {
        Write-Host 'Cancelled; nothing was changed.'
        return
    }
}

# --- Write or import ----------------------------------------------------------------------------

if ($OutputPath) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    foreach ($template in $templates) {
        ConvertTo-Payload $template | ConvertTo-Json -Depth 10 |
            Set-Content -Path (Join-Path $OutputPath "$($template.key).json") -Encoding utf8NoBOM
    }
    Write-Host "Wrote $($templates.Count) configured template(s) to $((Resolve-Path $OutputPath).Path); the tenant was not changed."
    return
}

if ($backupFolder) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    foreach ($template in $updates) {
        ConvertTo-Payload $existing[$template.key] | ConvertTo-Json -Depth 10 |
            Set-Content -Path (Join-Path $backupFolder "$($template.key).json") -Encoding utf8NoBOM
    }
    ConvertTo-Json -InputObject @($creates | ForEach-Object { $_.key }) | Set-Content -Path (Join-Path $backupFolder '_not-customized.json') -Encoding utf8NoBOM
    Write-Host "Backed up $($updates.Count) custom template(s) to $backupFolder"
}

$results = [Collections.Generic.List[object]]::new()
$index = 0
foreach ($template in $templates) {
    $index++
    Write-Progress -Activity 'Importing email templates' -Status $template.key -PercentComplete (100 * $index / $templates.Count)
    $payload = ConvertTo-Payload $template
    if ($template.Action -eq 'Update') {
        $payload | Add-Member -NotePropertyName id -NotePropertyValue $existing[$template.key].id
    }
    elseif ($template.Fallback) {
        $payload.subject = $template.Fallback
    }
    try {
        Invoke-Isc -Method Post -Uri $TemplatesApi -Body $payload | Out-Null
        $results.Add([pscustomobject]@{ Key = $template.key; Action = "$($template.Action)d"; Subject = $payload.subject; Error = $null })
    }
    catch {
        $results.Add([pscustomobject]@{ Key = $template.key; Action = 'Failed'; Subject = $payload.subject; Error = "$_" })
        Write-Warning "$($template.key): $_"
    }
}
Write-Progress -Activity 'Importing email templates' -Completed

# --- Verify -------------------------------------------------------------------------------------

$stored = Get-CustomEmailTemplates
foreach ($result in $results | Where-Object Action -ne 'Failed') {
    $copy = $stored[$result.Key]
    if (-not $copy) {
        $result.Action = 'Failed'; $result.Error = 'Not found in the tenant after import.'
    }
    elseif ($copy.subject -ne $result.Subject) {
        $result.Action = 'Failed'; $result.Error = 'The stored subject differs from the imported one.'
    }
}

$results | Select-Object Key, Action, Error | Format-Table -AutoSize | Out-Host
$failed = @($results | Where-Object Action -eq 'Failed')
$summary = ($results | Group-Object Action | ForEach-Object { "$($_.Count) $($_.Name.ToLower())" }) -join ', '
if ($failed) {
    Write-Error "Import finished with failures: $summary." -ErrorAction Continue
    exit 1
}
Write-Host "Import complete and verified: $summary."
