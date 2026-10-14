#Requires -Version 7.0
<#
.SYNOPSIS
    Imports the branded email templates into an Identity Security Cloud tenant.

.DESCRIPTION
    Creates or updates one custom email template per JSON file in -Path (default: ./templates) with
    POST /v2026/notification-templates. A template that already has a custom version in the tenant is
    updated in place; any other becomes the custom version of the SailPoint default with the same key.

    The script talks to the tenant through the sail CLI. Run without parameters and it guides you:

      1. Ensures sail is installed (install steps if it is missing), then asks which sail environment to use
         or creates one. The tenant and API URLs are edited here, so the arrow keys move through a pasted
         value. The script asks for the personal access token and passes it to sail, which stores it in the
         OS keyring. A wrong URL or token can be entered again.
      2. Checks the saved sail configuration, then that the environment can reach the tenant and read email
         templates. A wrong URL, authentication type, or missing token can be corrected and checked again.
      3. Asks for each template setting (tenant owner, banner tagline, brand colours, support email
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
    Tenant owner or team name shown in the banner, the sign-off and the footer ("This is an automated
    message from the ... identity platform"). Default in the templates: EMEA TES Team.

.PARAMETER BannerTagline
    Small capitalised text above the tenant owner name in the banner. Default: Identity & Access.

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
$PromptBackToken = 'PROMPT_BACK'
$PromptCount = 0
$WizardCursor = 0
$WizardResume = 0
$WizardStep = -1
$WizardStepPromptCount = 0
$WizardAskedSteps = @{}
$InWizardPrompt = $false
$WizardActive = $false
$TypedLineFallback = $false

# Template settings (#set lines at the top of every template): the parameter that sets each one, the
# prompt label and the accepted values (a regex, or the manifest languages for the default language).
$Settings = [ordered]@{
    mailDefaultLanguage = @{ Parameter = 'DefaultLanguage'; Label = 'Default language' }
    mailOrgName         = @{ Parameter = 'OrganizationName'; Label = 'Tenant owner'; Pattern = '\S'; Problem = 'Enter a name.' }
    mailBannerTagline   = @{ Parameter = 'BannerTagline'; Label = 'Banner tagline' }
    mailColorPrimary    = @{ Parameter = 'PrimaryColor'; Label = 'Primary colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    mailColorDark       = @{ Parameter = 'DarkColor'; Label = 'Dark colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    mailColorAccent     = @{ Parameter = 'AccentColor'; Label = 'Accent colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    mailColorHighlight  = @{ Parameter = 'HighlightColor'; Label = 'Highlight colour'; Pattern = '^#[0-9A-Fa-f]{6}$'; Problem = 'Use #RRGGBB.' }
    mailSupportEmail    = @{ Parameter = 'SupportEmail'; Label = 'Support email'; Pattern = '^$|^[^@\s]+@[^@\s]+\.[^@\s]+$'; Problem = 'Enter an email address, or - for none.'; Optional = $true }
}

function Set-TemplateSetting {
    <# Replaces the value of `#set($<Variable> = '...')`; Velocity single-quoted strings escape ' as ''. #>
    param([string]$Text, [string]$Variable, [string]$Value)
    if (-not $Text) { return $Text }
    $literal = $Value.Replace("'", "''").Replace('$', '$$')
    return [regex]::Replace($Text, "#set\(\`$$Variable = '(?:[^']|'')*'\)", "#set(`$$Variable = '$literal')")
}

# --- Prompts ------------------------------------------------------------------------------------

function Test-PromptBack {
    param($ErrorRecord)
    return [string]$ErrorRecord.Exception.Message -eq $PromptBackToken
}

function Invoke-PromptBack {
    if (-not $script:WizardActive) {
        Write-Host ''
        Write-Host 'Cancelled; nothing was changed.' -ForegroundColor Yellow
        exit 0
    }
    throw $PromptBackToken
}

function Start-WizardPass {
    $script:WizardCursor = 0
    $script:InWizardPrompt = $false
}

function Enter-WizardPrompt {
    $step = $script:WizardCursor
    $script:WizardCursor++
    if ($step -lt $script:WizardResume) { return $false }
    $script:WizardStep = $step
    $script:WizardStepPromptCount = $script:PromptCount
    $script:InWizardPrompt = $true
    return $true
}

function Complete-WizardPrompt {
    if (-not $script:InWizardPrompt) { return }
    $script:InWizardPrompt = $false
    if ($script:PromptCount -gt $script:WizardStepPromptCount) {
        $script:WizardAskedSteps[$script:WizardStep] = $true
    }
    $script:WizardResume = $script:WizardCursor
}

function Move-WizardBack {
    $before = if ($script:InWizardPrompt) { $script:WizardStep } else { $script:WizardStep + 1 }
    $target = -1
    foreach ($step in $script:WizardAskedSteps.Keys) {
        if ($step -lt $before -and $step -gt $target) { $target = $step }
    }
    if ($target -lt 0) { return $false }

    foreach ($step in @($script:WizardAskedSteps.Keys)) {
        if ($step -gt $target) { $script:WizardAskedSteps.Remove($step) }
    }
    $script:WizardResume = $target
    return $true
}

function Reset-TerminalInput {
    <# .NET ReadKey turns on application cursor keys and leaves them on. The next program then
       prints a left arrow as ^[OD instead of moving the cursor. This turns that mode off. #>
    if ([Console]::IsOutputRedirected) { return }
    [Console]::Out.Write("$([char]27)[?1l$([char]27)>")
    [Console]::Out.Flush()
}

function Update-TypedLine {
    <# Redraws the input from the cursor saved at its start, then parks the cursor at the edit point. #>
    param(
        [System.Collections.Generic.List[char]]$Chars,
        [int]$Cursor,
        [ref]$Drawn,
        [switch]$Mask
    )
    $text = -join $Chars.ToArray()
    $shown = if ($Mask) { '*' * $text.Length } else { $text }
    $clear = [Math]::Max(0, $Drawn.Value - $shown.Length)
    $prefix = if ($Cursor -gt 0) { $shown.Substring(0, $Cursor) } else { '' }
    $restore = "$Esc" + '8'
    Write-Host ($restore + $shown + (' ' * $clear) + $restore + $prefix) -NoNewline
    $Drawn.Value = $shown.Length
}

function Read-TypedLine {
    param([string]$Prompt, [switch]$Mask)

    $script:TypedLineFallback = $false
    try {
        Write-Host "${Prompt}: " -NoNewline
        Write-Host ("$Esc" + '7') -NoNewline
        $chars = [System.Collections.Generic.List[char]]::new()
        $cursor = 0
        $drawn = 0
        while ($true) {
            $pressed = [Console]::ReadKey($true)
            if (($pressed.Modifiers -band [ConsoleModifiers]::Control) -and $pressed.Key -eq 'C') {
                Write-Host ''
                Write-Host 'Cancelled; nothing was changed.' -ForegroundColor Yellow
                exit 0
            }
            if ($pressed.Key -eq 'Escape') {
                Write-Host ''
                Invoke-PromptBack
            }
            if ($pressed.Key -eq 'Enter') {
                Write-Host ''
                return (-join $chars.ToArray())
            }
            $changed = $true
            switch ($pressed.Key) {
                'LeftArrow' { if ($cursor -gt 0) { $cursor-- } else { $changed = $false } }
                'RightArrow' { if ($cursor -lt $chars.Count) { $cursor++ } else { $changed = $false } }
                'Home' { $cursor = 0 }
                'End' { $cursor = $chars.Count }
                'Backspace' {
                    if ($cursor -gt 0) { $cursor--; $chars.RemoveAt($cursor) } else { $changed = $false }
                }
                'Delete' {
                    if ($cursor -lt $chars.Count) { $chars.RemoveAt($cursor) } else { $changed = $false }
                }
                default { $changed = $false }
            }
            if (-not $changed -and -not [char]::IsControl($pressed.KeyChar)) {
                $chars.Insert($cursor, $pressed.KeyChar)
                $cursor++
                $changed = $true
            }
            if ($changed) { Update-TypedLine -Chars $chars -Cursor $cursor -Drawn ([ref]$drawn) -Mask:$Mask }
        }
    }
    catch {
        if (Test-PromptBack $_) { throw }
        $script:TypedLineFallback = $true
        if ($Mask) { return Read-Host -MaskInput $Prompt }
        return Read-Host $Prompt
    }
    finally {
        Reset-TerminalInput
    }
}

function Read-Value {
    <# Asks for a value; Enter keeps the default, '-' clears an optional value and Esc goes back. #>
    param([string]$Label, [string]$Default, [scriptblock]$Validate, [string]$Hint, [switch]$Optional)
    $script:PromptCount++
    if ($Hint) { Write-Host "  $Hint" -ForegroundColor DarkGray }
    while ($true) {
        $shown = if ($Default) { " [$Default]" } elseif ($Optional) { ' [none]' } else { '' }
        $answer = (Read-TypedLine "$Label$shown").Trim()
        if ($script:TypedLineFallback -and $answer -match '^(b|back)$') { Invoke-PromptBack }
        $value = if (-not $answer) { $Default } elseif ($Optional -and $answer -eq '-') { '' } else { $answer }
        $problem = if ($Validate) { & $Validate $value }
        if (-not $problem) { return $value }
        Write-Host "  $problem" -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param([string]$Prompt, [bool]$Default)
    $script:PromptCount++
    $choices = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = (Read-TypedLine "$Prompt $choices").Trim()
        if ($script:TypedLineFallback -and $answer -match '^(b|back)$') { Invoke-PromptBack }
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
       Esc returns to the previous question. #>
    param([object[]]$Rows)
    $script:PromptCount++
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
            [void]$frame.AppendLine("$Esc[2m↑/↓ move   PgUp/PgDn page   Space select   A all   Enter continue   Esc back$Esc[0m")
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
            if (($pressed.Modifiers -band [ConsoleModifiers]::Control) -and $pressed.Key -eq 'C') {
                Write-Host ''
                Write-Host 'Cancelled; nothing was changed.' -ForegroundColor Yellow
                exit 0
            }
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
                'Escape' { Invoke-PromptBack }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $true
        [Console]::Write("$Esc[H$Esc[2J")
        Reset-TerminalInput
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
    $result = [ordered]@{ Active = $null; AuthType = ''; Environments = [ordered]@{} }
    if (-not (Test-Path $SailConfigPath)) { return [pscustomobject]$result }
    $current = $null
    foreach ($line in Get-Content $SailConfigPath) {
        if ($line -match '^activeenvironment:\s*(\S+)\s*$') { $result.Active = $Matches[1]; continue }
        if (-not $current -and $line -match '^authtype:\s*(\S+)\s*$') { $result.AuthType = $Matches[1].ToLower(); continue }
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

function ConvertTo-SailTenantUrl {
    <# A bare name becomes https://name.identitynow.com. A pasted URL is kept and a trailing slash is removed. #>
    param([string]$Value)
    $Value = $Value.Trim().TrimEnd('/')
    if ($Value -match '^https?://') { return $Value }
    if ($Value -match '^[A-Za-z0-9-]+$') { return "https://$Value.identitynow.com" }
    return $Value
}

function Save-SailEnvironment {
    <# Writes one environment into ~/.sailpoint/config.yaml without changing the others or the active one. #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$TenantUrl,
        [Parameter(Mandatory)][string]$ApiUrl
    )
    $TenantUrl = $TenantUrl.Trim().TrimEnd('/')
    $ApiUrl = $ApiUrl.Trim().TrimEnd('/')
    $directory = Split-Path $SailConfigPath
    if (-not (Test-Path $directory)) { New-Item -ItemType Directory -Path $directory | Out-Null }
    $lines = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $SailConfigPath) {
        foreach ($line in Get-Content $SailConfigPath) { $lines.Add($line) }
    }
    $envAt = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^environments:\s*$') { $envAt = $i; break }
    }
    if ($envAt -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') { $lines.Add('') }
        $lines.Add('environments:')
        $envAt = $lines.Count - 1
    }
    $header = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s{4}$([regex]::Escape($Name)):\s*$") { $header = $i; break }
    }
    if ($header -lt 0) {
        $insertAt = $lines.Count
        for ($i = $envAt + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\S') { $insertAt = $i; break }
        }
        foreach ($line in @(
                "    ${Name}:"
                '        authtype: pat'
                "        baseurl: $ApiUrl"
                "        tenanturl: $TenantUrl"
            )) {
            $lines.Insert($insertAt, $line)
            $insertAt++
        }
    }
    else {
        $end = $header + 1
        while ($end -lt $lines.Count -and $lines[$end] -match '^\s{8}\S') { $end++ }
        $body = [System.Collections.Generic.List[string]]::new()
        $seen = @{}
        for ($i = $header + 1; $i -lt $end; $i++) {
            if ($lines[$i] -match '^\s{8}(authtype|baseurl|tenanturl):\s*(.*?)\s*$') {
                $seen[$Matches[1]] = $true
                $value = switch ($Matches[1]) {
                    'baseurl' { $ApiUrl }
                    'tenanturl' { $TenantUrl }
                    'authtype' { if ($Matches[2] -in 'pat', 'oauth') { $Matches[2] } else { 'pat' } }
                }
                $body.Add("        $($Matches[1]): $value")
            }
            else { $body.Add($lines[$i]) }
        }
        if (-not $seen.authtype) { $body.Insert(0, '        authtype: pat') }
        if (-not $seen.baseurl) { $body.Add("        baseurl: $ApiUrl") }
        if (-not $seen.tenanturl) { $body.Add("        tenanturl: $TenantUrl") }
        for ($i = $end - 1; $i -gt $header; $i--) { $lines.RemoveAt($i) }
        $at = $header + 1
        foreach ($line in $body) { $lines.Insert($at, $line); $at++ }
    }
    Set-Content -LiteralPath $SailConfigPath -Value $lines -Encoding utf8
}

function Invoke-SailRegistration {
    <# Asks for the tenant and API URLs and saves them. Arrow keys edit a pasted value.
       Returns $false when the user stops. #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('create', 'update')][string]$Action
    )
    $existing = (Get-SailEnvironments).Environments[$Name]
    $tenantDefault = if ($existing -and $existing.TenantUrl) { $existing.TenantUrl } else { "https://$Name.identitynow.com" }
    Write-Host 'Left and right arrows move through a pasted value. Home and End jump to either end.'
    $tenant = Read-Value 'Tenant URL' $tenantDefault -Hint 'The address in the browser, such as https://acme.identitynow.com or https://acme.identitynow-demo.com.' -Validate {
        param($v)
        $url = ConvertTo-SailTenantUrl $v
        if (-not (Test-SailHttpsUrl $url)) { return 'Enter an https URL, such as https://acme.identitynow.com or https://acme.identitynow-demo.com.' }
        if (-not (Get-SailApiUrl $url)) { return 'That address is an API URL. Use the tenant address, such as https://acme.identitynow.com.' }
    }
    $tenant = ConvertTo-SailTenantUrl $tenant
    $apiDefault = Get-SailApiUrl $tenant
    $api = Read-Value 'API URL' $apiDefault -Validate {
        param($v)
        $url = $v.Trim().TrimEnd('/')
        if (-not (Test-SailHttpsUrl $url)) { return 'Enter an https URL.' }
        $expected = Get-SailApiUrl $tenant
        if (([Uri]$url).Host -ne ([Uri]$expected).Host) { return "This API URL does not match the tenant URL. Expected $expected." }
    }
    $api = $api.Trim().TrimEnd('/')
    Save-SailEnvironment -Name $Name -TenantUrl $tenant -ApiUrl $api
    return $true
}

function Initialize-SailEnvironment {
    <# Registers a sail environment. The token stays in sail's keyring. #>
    param([string]$SuggestedName)
    while ($true) {
        $name = Read-Value 'Environment name' $SuggestedName -Hint 'A short label for this tenant in sail, for example acme or emea-tes-team.' -Validate {
            param($v) if ($v -notmatch '^[A-Za-z0-9_.-]+$') { 'Use letters, digits, dots, hyphens or underscores.' }
        }
        $registered = $name -in @((Get-SailEnvironments).Environments.Keys)
        Write-Host ''
        $action = if ($registered) { 'update' } else { 'create' }
        if ($registered) {
            Write-Host "sail environment '$name' is already registered." -ForegroundColor Yellow
            if (-not (Read-YesNo 'Update its tenant and API URLs?' $true)) {
                $SuggestedName = ''
                continue
            }
        }
        else {
            Write-Host "Creating sail environment '$name'." -ForegroundColor Cyan
        }
        Write-Host ''
        if (-not (Invoke-SailRegistration -Name $name -Action $action)) {
            Write-Host 'Cancelled; nothing was changed.'
            exit 0
        }
        $stored = Test-SailPatStored -Name $name
        if ($stored -eq $false -or ($action -eq 'create' -and $null -eq $stored)) {
            Write-Host ''
            Write-Host 'Create the personal access token under Admin > Global > Security Settings > Personal Access Tokens'
            Write-Host '(it needs a role that can manage email templates, for example Admin). sail stores it in your OS keyring.'
            Write-Host ''
            if (-not (Set-SailPat -Name $name)) {
                Write-Host 'Cancelled; nothing was changed.'
                exit 0
            }
        }
        return $name
    }
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

function Get-SailApiUrl {
    <# API URL sail derives from a tenant URL: https://acme.identitynow.com -> https://acme.api.identitynow.com. #>
    param([string]$TenantUrl)
    try { $uri = [Uri]$TenantUrl } catch { return $null }
    $labels = @($uri.Host.ToLowerInvariant().Split('.') | Where-Object { $_ })
    if ($uri.Scheme -ne 'https' -or $labels.Count -lt 2) { return $null }
    if ($labels.Count -gt 2 -and $labels[1] -eq 'api') { return $null }
    $domain = $labels[1..($labels.Count - 1)] -join '.'
    return "https://$($labels[0]).api.$domain"
}

function Test-SailHttpsUrl {
    param([string]$Url)
    try {
        $uri = [Uri]$Url
        return $uri.Scheme -eq 'https' -and $uri.IsAbsoluteUri -and $uri.Host
    }
    catch { return $false }
}

function Test-SailPatStored {
    <# $true/$false when the keyring can be read. $null when this platform has no readable keyring tool. #>
    param([Parameter(Mandatory)][string]$Name)
    $services = 'environments.pat.clientid', 'environments.pat.clientsecret'
    if (Get-Command security -ErrorAction SilentlyContinue) {
        foreach ($service in $services) {
            & security find-generic-password -s $service -a $Name *> $null
            if ($LASTEXITCODE) { return $false }
        }
        return $true
    }
    if (Get-Command secret-tool -ErrorAction SilentlyContinue) {
        foreach ($service in $services) {
            & secret-tool lookup service $service username $Name *> $null
            if ($LASTEXITCODE) { return $false }
        }
        return $true
    }
    return $null
}

function Test-SailEnvironmentConfiguration {
    <# Problems in the saved sail config. Empty means the environment can be used. #>
    param([Parameter(Mandatory)][string]$Name)
    $config = Get-SailEnvironments
    $problems = [System.Collections.Generic.List[string]]::new()
    if ($Name -notin @($config.Environments.Keys)) {
        $problems.Add("'$Name' is not in $SailConfigPath.")
        return $problems.ToArray()
    }
    $env = $config.Environments[$Name]
    $tenantUrl = [string]$env.TenantUrl
    $apiUrl = [string]$env.ApiUrl
    if (-not (Test-SailHttpsUrl $tenantUrl)) {
        $problems.Add('Tenant URL is missing or is not an https URL.')
    }
    elseif (-not (Get-SailApiUrl $tenantUrl)) {
        $problems.Add('Tenant URL is an API URL. Use the tenant address, such as https://acme.identitynow.com.')
    }
    if (-not (Test-SailHttpsUrl $apiUrl)) {
        $problems.Add('API URL is missing or is not an https URL.')
    }
    elseif ((Test-SailHttpsUrl $tenantUrl) -and (Get-SailApiUrl $tenantUrl)) {
        $expected = Get-SailApiUrl $tenantUrl
        if (([Uri]$apiUrl).Host -ne ([Uri]$expected).Host) {
            $problems.Add("API URL does not match the tenant URL. Expected $expected.")
        }
    }
    $auth = if ($env.AuthType) { [string]$env.AuthType } else { [string]$config.AuthType }
    $auth = $auth.ToLowerInvariant()
    if ($auth -notin 'pat', 'oauth') {
        $shown = if ($auth) { "'$auth'" } else { 'blank' }
        $problems.Add("Authentication type must be pat or oauth (it is $shown).")
    }
    elseif ($auth -eq 'pat') {
        $stored = Test-SailPatStored -Name $Name
        if ($stored -eq $false) {
            $problems.Add('The personal access token client ID or secret is not in the keyring.')
        }
    }
    return $problems.ToArray()
}

function Confirm-SailEnvironment {
    <# Checks the saved configuration before the environment is used. Returns $false when the user stops. #>
    param([Parameter(Mandatory)][string]$Name)
    while ($true) {
        $problems = @(Test-SailEnvironmentConfiguration -Name $Name)
        if (-not $problems) {
            $env = (Get-SailEnvironments).Environments[$Name]
            Write-Host "  ✓ $($env.TenantUrl)" -ForegroundColor Green
            return $true
        }
        Write-Host "sail environment '$Name' is not ready to use:" -ForegroundColor Yellow
        foreach ($problem in $problems) { Write-Host "  - $problem" }
        if (-not $Interactive) {
            throw "sail environment '$Name' is not configured: $($problems -join ' ')"
        }
        $tokenOnly = @($problems | Where-Object { $_ -notlike '*keyring*' }).Count -eq 0
        $question = if ($tokenOnly) { 'Store the personal access token and check again?' } else { 'Correct the registration and check again?' }
        if (-not (Read-YesNo $question $true)) { return $false }
        Write-Host ''
        $corrected = if ($tokenOnly) { Set-SailPat -Name $Name } else { Invoke-SailRegistration -Name $Name -Action update }
        if (-not $corrected) { return $false }
    }
}

function Read-PatCredential {
    <# Reads one PAT value and checks its length before sail sees it. A secret is shown as asterisks. #>
    param([string]$Label, [int[]]$Lengths, [switch]$Mask)
    $expected = $Lengths -join ' or '
    while ($true) {
        $value = (Read-TypedLine $Label -Mask:$Mask).Trim()
        if ($value.Length -in $Lengths) { return $value }
        Write-Host "  $Label must be $expected characters (entered $($value.Length))." -ForegroundColor Yellow
    }
}

function Set-SailPat {
    <# Asks for the token, then passes it to sail. Returns $false when the user stops retrying a rejected entry. #>
    param([string]$Name)
    while ($true) {
        Write-Host "Personal access token for sail environment '$Name'." -ForegroundColor Cyan
        Write-Host 'Paste each value. Arrows, Home, End and Backspace edit it. The secret is shown as asterisks.'
        $clientId = Read-PatCredential -Label 'Client ID' -Lengths 32, 36
        $clientSecret = Read-PatCredential -Label 'Client secret' -Lengths 64 -Mask
        Reset-TerminalInput
        & sail set auth pat --env $Name
        if (-not $LASTEXITCODE) {
            & sail set pat --env $Name --ClientID $clientId --ClientSecret $clientSecret
        }
        if (-not $LASTEXITCODE) { return $true }
        Write-Host ''
        Write-Host "sail did not store the token for '$Name'." -ForegroundColor Yellow
        if (-not (Read-YesNo 'Try the token again?' $true)) { return $false }
        Write-Host ''
    }
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
    if (-not (Confirm-SailEnvironment -Name $SailEnvironment)) {
        Write-Host 'Cancelled; nothing was changed.'
        return
    }
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
            if ($rejected) {
                if (-not (Read-YesNo 'Store the personal access token again and try again?' $true)) {
                    Write-Host 'Cancelled; nothing was changed.'
                    return
                }
                if (-not (Set-SailPat -Name $SailEnvironment)) {
                    Write-Host 'Cancelled; nothing was changed.'
                    return
                }
                continue
            }
            Write-Host '  The tenant did not respond. The registered name or URL may be wrong.' -ForegroundColor Yellow
            if (Read-YesNo 'Correct the registration and try again?' $true) {
                if (-not (Invoke-SailRegistration -Name $SailEnvironment -Action update)) {
                    Write-Host 'Cancelled; nothing was changed.'
                    return
                }
                if (-not (Confirm-SailEnvironment -Name $SailEnvironment)) {
                    Write-Host 'Cancelled; nothing was changed.'
                    return
                }
                $envInfo = (Get-SailEnvironments).Environments[$SailEnvironment]
                $Target = if ($envInfo.TenantUrl) { "$SailEnvironment ($($envInfo.TenantUrl))" } else { "sail environment $SailEnvironment" }
                continue
            }
            if (Read-YesNo 'Try the health check again?' $true) { continue }
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

$providedParameters = @{}
foreach ($name in $PSBoundParameters.Keys) { $providedParameters[$name] = $true }
$descriptions = @{}
if ($manifest) {
    foreach ($setting in $manifest.settings) { $descriptions[$setting.variable] = $setting.description }
}
$selectedKeys = $null
$brandingAnswered = $false
$wizardComplete = $false
$WizardActive = $true

while (-not $wizardComplete) {
    Start-WizardPass
    try {
        if ($manifest -and $Interactive) {
            Write-Section 'Settings'
            Write-Host 'Press Enter to keep the value in brackets. Esc returns to the previous question.' -ForegroundColor DarkGray

            if (Enter-WizardPrompt) {
                if (-not $providedParameters.ContainsKey('UseTenantBranding') -and $tenantColors.Count) {
                    $shown = ($tenantColors.GetEnumerator() | Sort-Object Key -Descending | ForEach-Object { Format-Swatch $_.Value }) -join '  '
                    Write-Host "Tenant branding colours: $shown"
                    $UseTenantBranding = Read-YesNo 'Start from the tenant branding colours?' $(if ($brandingAnswered) { [bool]$UseTenantBranding } else { $true })
                    $brandingAnswered = $true
                }
                Complete-WizardPrompt
            }

            foreach ($variable in $Settings.Keys) {
                $setting = $Settings[$variable]
                if (Enter-WizardPrompt) {
                    if ($defaults.Contains($variable) -and -not $providedParameters.ContainsKey($setting.Parameter)) {
                        $default = if ($PSBoundParameters.ContainsKey($setting.Parameter)) {
                            [string]$PSBoundParameters[$setting.Parameter]
                        }
                        elseif ($UseTenantBranding -and $tenantColors.ContainsKey($setting.Parameter)) {
                            $tenantColors[$setting.Parameter]
                        }
                        else {
                            $defaults[$variable]
                        }
                        $validate = if ($variable -eq 'mailDefaultLanguage') {
                            { param($v) if ($v -notin $manifest.languages) { "Use one of: $($manifest.languages -join ', ')." } }
                        }
                        elseif ($setting.ContainsKey('Pattern')) {
                            $pattern = $setting.Pattern; $problem = $setting.Problem
                            { param($v) if ($v -notmatch $pattern) { $problem } }.GetNewClosure()
                        }
                        $value = Read-Value $setting.Label $default -Hint $descriptions[$variable] -Validate $validate -Optional:([bool]$setting['Optional'])
                        if ($variable -like 'mailColor*') { Write-Host "  $(Format-Swatch $value)" }
                        $PSBoundParameters[$setting.Parameter] = $value
                    }
                    Complete-WizardPrompt
                }
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

        $inScope = if ($manifest -and $Scope -ne 'all') { @($manifest.$Scope) } else { $null }
        $rows = foreach ($template in $templates) {
            $templateKey = $template.key
            $selected = if ($null -ne $selectedKeys) {
                $templateKey -in $selectedKeys
            }
            else {
                (-not $inScope -or $templateKey -in $inScope) -and (-not $Key -or ($Key | Where-Object { $templateKey -like $_ }))
            }
            [pscustomobject]@{ Selected = [bool]$selected; Key = $templateKey; Kind = $template.Kind; Action = $template.Action; Template = $template }
        }
        if (Enter-WizardPrompt) {
            if ($Interactive) { Select-Templates -Rows $rows | Out-Null }
            Complete-WizardPrompt
        }
        $selectedKeys = @($rows | Where-Object Selected | ForEach-Object { $_.Key })
        $templates = @($rows | Where-Object Selected | ForEach-Object { $_.Template })
        if (-not $templates) { throw "No templates in $Path match the selection." }

        foreach ($template in $templates) {
            $template | Add-Member -NotePropertyName Fallback -NotePropertyValue $null
            if ($template.Action -eq 'Create' -and $manifest -and $template.subject.Length -gt $manifest.subjectLimit) {
                $fallback = [string]$manifest.subjectFallback.($template.FileName)
                foreach ($variable in $applied.Keys) {
                    $fallback = Set-TemplateSetting $fallback $variable $applied[$variable]
                }
                $template.Fallback = $fallback
            }
        }

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
                $shown = if ($variable -like 'mailColor*') { Format-Swatch $value } elseif ($value) { $value } else { '(none)' }
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
        if (Enter-WizardPrompt) {
            if ($Interactive) {
                Write-Host ''
                $question = if ($OutputPath) { "Write $($templates.Count) template(s)?" } else { "Import $($templates.Count) template(s) into $(if ($TenantName) { $TenantName } else { $Target })?" }
                if (-not (Read-YesNo $question $false)) {
                    Write-Host 'Cancelled; nothing was changed.'
                    return
                }
            }
            Complete-WizardPrompt
        }
        $wizardComplete = $true
    }
    catch {
        if (-not (Test-PromptBack $_)) { throw }
        if (-not (Move-WizardBack)) {
            Write-Host ''
            Write-Host 'Cancelled; nothing was changed.' -ForegroundColor Yellow
            return
        }
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
