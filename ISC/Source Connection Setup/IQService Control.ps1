#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads, installs, updates, and manages SailPoint IQService on a Windows host.

.DESCRIPTION
    Operator script for IQService hosts that need the Integration Service for Active Directory,
    Azure AD, Windows Local, SharePoint, or Domino connectors.

    Supports downloading IQService from a pasted ISC pre-signed ZIP URL, extracting and
    unblocking binaries (including Utils.dll),     registering or upgrading the Windows service,
    start/stop/restart, log-level configuration, colored log streaming, and status reporting.

    Pre-signed download URLs expire (typically within an hour). Obtain a fresh link from
    Connections > Sources > [source requiring IQService] > IQService / Integration Service > Download.

.PARAMETER Action
    Download, Install, Update, Uninstall, Start, Stop, Restart, SetLogLevel, StreamLogs, Status, or Unblock.
    When omitted, an interactive menu is shown.

.PARAMETER InstallPath
    IQService installation directory. Default: C:\SailPoint\IQService, or the path discovered
    from an existing Windows service.

.PARAMETER DownloadUri
    Pre-signed ISC VA-image URL for IQService.zip. Never commit or share these URLs; they expire.

.PARAMETER ZipPath
    Local path to an IQService.zip file instead of downloading.

.PARAMETER Port
    Non-TLS port passed to IQService.exe -p during install or update.

.PARAMETER TlsPort
    TLS port passed to IQService.exe -o during install or update.

.PARAMETER SkipSecondary
    Pass -b to IQService.exe -i to skip installing the secondary fallback instance.

.PARAMETER LogLevel
    Off, Error, Info, or Debug (maps to IQService trace levels 0-3).

.PARAMETER TraceFile
    Trace log file path for -l / -f and StreamLogs. Default: registry tracefile, else {InstallPath}\iqtrace.log

.PARAMETER Tail
    Number of existing log lines to print before following. StreamLogs only. Default: 50.

.PARAMETER StartAfterInstall
    Start the service after install or update.

.PARAMETER NonInteractive
    Do not prompt; required parameters must be supplied.

.EXAMPLE
    .\IQService Control.ps1

.EXAMPLE
    .\IQService Control.ps1 -Action Status

.EXAMPLE
    .\IQService Control.ps1 -Action Download -DownloadUri 'https://va-access.infra.identitynow.com/...'

.EXAMPLE
    .\IQService Control.ps1 -Action Update -ZipPath 'D:\Downloads\IQService-914.zip' -StartAfterInstall

.EXAMPLE
    .\IQService Control.ps1 -Action StreamLogs -Tail 100

.NOTES
    Install, update, uninstall, and service control require an elevated PowerShell session.
    Reference: https://documentation.sailpoint.com/connectors/iqservice/help/integrating_iqservice_admin/
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('Download', 'Install', 'Update', 'Uninstall', 'Start', 'Stop', 'Restart', 'SetLogLevel', 'StreamLogs', 'Status', 'Unblock')]
    [string]$Action,

    [Parameter()]
    [string]$InstallPath,

    [Parameter()]
    [string]$DownloadUri,

    [Parameter()]
    [string]$ZipPath,

    [Parameter()]
    [int]$Port,

    [Parameter()]
    [int]$TlsPort,

    [Parameter()]
    [switch]$SkipSecondary,

    [Parameter()]
    [ValidateSet('Off', 'Error', 'Info', 'Debug')]
    [string]$LogLevel,

    [Parameter()]
    [string]$TraceFile,

    [Parameter()]
    [ValidateRange(0, 100000)]
    [int]$Tail = 50,

    [Parameter()]
    [switch]$StartAfterInstall,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:DefaultInstallPath = 'C:\SailPoint\IQService'
$script:LogLevelMap = [ordered]@{
    Off   = 0
    Error = 1
    Info  = 2
    Debug = 3
}

# -----------------------------------------------------------------------------
# Platform and console helpers
# -----------------------------------------------------------------------------

function Assert-WindowsHost {
    if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
        throw 'IQService Control must run on Windows.'
    }
    if ($env:OS -notlike 'Windows*') {
        throw 'IQService Control must run on Windows.'
    }
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Elevated {
    param([string]$Operation)

    if (-not (Test-IsElevated)) {
        throw "Administrator privileges are required for: $Operation. Re-run PowerShell as Administrator."
    }
}

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  IQService Control' -ForegroundColor Cyan
    Write-Host '  Download, install, update, and manage IQService on this host.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor DarkGray
}

$script:Esc = [char]27
$script:AnsiEraseLine = "$([char]27)[K"
$script:PromptBackToken = 'PROMPT_BACK'
$script:MenuFallbackReported = $false
$script:MenuBlockerDetail = 'the console window is too short'

function Test-PromptBack {
    param($ErrorRecord)
    return [string]$ErrorRecord.Exception.Message -eq $script:PromptBackToken
}

function Invoke-PromptBack {
    throw $script:PromptBackToken
}

function Invoke-PromptExit {
    Write-Host ''
    Write-Host 'Cancelled.' -ForegroundColor Yellow
    exit 0
}

function Test-CancelledNavigation {
    param($ErrorRecord)
    if (Test-PromptBack $ErrorRecord) { return $true }
    return $ErrorRecord.Exception -is [System.Management.Automation.PipelineStoppedException]
}

# Arrow-key menus need a host that reads single keys and a terminal that understands ANSI cursor
# movement. Returns $null when menus work, otherwise the reason they do not.
function Get-ConsoleMenuBlocker {
    if ($NonInteractive) { return 'non-interactive mode' }
    # The ISE draws its own command pane and implements neither key reading nor cursor movement.
    if ($Host.Name -eq 'Windows PowerShell ISE Host') { return 'the ISE cannot read single keystrokes' }

    # Only a real console host is checked through [Console]: editor hosts such as the VS Code /
    # Cursor PowerShell extension throw there yet still read keys through RawUI, so they are tried
    # optimistically and fall back if the first read fails.
    if ($Host.Name -eq 'ConsoleHost') {
        # KeyAvailable throws when stdin is not a console. Unlike a cursor-position request it asks
        # the terminal nothing and consumes no input, so it is safe to call before every menu.
        try { $null = [Console]::KeyAvailable }
        catch { return 'this console cannot read single keystrokes' }

        try { if ([Console]::IsOutputRedirected) { return 'console output is redirected' } } catch { }
    }

    # Only Windows consoles are ever without virtual terminal support; every terminal PowerShell
    # runs in on Unix renders these sequences regardless of what TERM advertises.
    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -ne 'Unix') {
        $vt = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
        if ($vt -and -not $vt.Value) { return 'this console does not support virtual terminal sequences' }
    }

    return $null
}

# RawUI.ReadKey is used rather than [Console]::ReadKey because the editor hosts implement it while
# [Console] throws; in a console host it is a thin wrapper over [Console]::ReadKey anyway.
# ConsoleKey values and Windows virtual key codes agree on the keys below.
function Read-MenuKey {
    $info = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $code = [int]$info.VirtualKeyCode
    $character = $info.Character
    $ctrl = $false
    try { $ctrl = ([int]$info.ControlKeyState -band 0x0C) -ne 0 } catch { }

    if ([int][char]$character -eq 3 -or $code -eq 3 -or ($ctrl -and $code -eq 67)) {
        return [PSCustomObject]@{ Name = 'CtrlC'; Char = [char]0; Character = $character }
    }

    $name = switch ($code) {
        8       { 'Backspace' }
        38      { 'Up' }
        40      { 'Down' }
        36      { 'Home' }
        35      { 'End' }
        32      { 'Space' }
        13      { 'Enter' }
        27      { 'Escape' }
        default { 'Other' }
    }
    return [PSCustomObject]@{
        Name      = $name
        Char      = [char]::ToLowerInvariant($character)
        Character = $character
    }
}

function Write-MenuFallbackNotice {
    param([string]$Reason)

    if ($NonInteractive -or -not $Reason -or $script:MenuFallbackReported) { return }
    $script:MenuFallbackReported = $true
    Write-Info "Arrow-key menus are unavailable here ($Reason); using numbered prompts."
}

# Editor hosts throw on [Console] size members but answer through RawUI, so both are tried.
function Get-MenuWindowSize {
    try { return @{ Width = [Console]::WindowWidth; Height = [Console]::WindowHeight } } catch { }
    try {
        $size = $Host.UI.RawUI.WindowSize
        return @{ Width = $size.Width; Height = $size.Height }
    }
    catch { }
    return @{ Width = 0; Height = 0 }
}

function Get-MenuWidth {
    $width = (Get-MenuWindowSize).Width
    if ($width -le 20) { return 80 }
    return $width - 1
}

# Returns the picked indices, an empty array when the user pressed Escape, or $null when the
# console is too small to host the menu and the caller should prompt for numbers instead.
function Invoke-ConsoleMenu {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Labels,
        [switch]$MultiSelect,
        [switch]$EscapeMeansDefault,
        [int]$InitialIndex = 0
    )

    $count = $Labels.Count
    if ($count -eq 0) { return , @() }

    $selected = New-Object 'bool[]' $count
    $cursor = [Math]::Min([Math]::Max($InitialIndex, 0), $count - 1)
    $hint = if ($MultiSelect) {
        'Up/Down move   Space select   A all   N none   Enter confirm   Esc back   Ctrl+C exit'
    }
    elseif ($EscapeMeansDefault) {
        'Up/Down move   Enter select   Esc done   Ctrl+C exit'
    }
    else {
        'Up/Down move   Enter select   Esc back   Ctrl+C exit'
    }

    $rows = $count + 2
    $windowHeight = (Get-MenuWindowSize).Height
    # A console that will not report its height still gets the menu; only a known-too-short one
    # falls back, because the block has to fit on screen for the in-place redraw to line up.
    if ($windowHeight -gt 0 -and $windowHeight -le $rows) {
        $script:MenuBlockerDetail = "the console is $windowHeight rows tall and this menu needs $($rows + 1)"
        return $null
    }

    # Every frame is redrawn in place by moving the cursor up over the block just written, so the
    # menu never needs to know its absolute row and survives the console scrolling underneath it.
    $drawn = $false
    $draw = {
        $width = Get-MenuWidth
        if ($drawn) { Write-Host ("{0}[{1}A" -f $script:Esc, $rows) -NoNewline }
        $drawn = $true

        $lines = @(, @($Prompt, [System.ConsoleColor]::White))
        $lines += , @("   $hint", [System.ConsoleColor]::DarkGray)
        for ($i = 0; $i -lt $count; $i++) {
            $marker = if ($i -eq $cursor) { '>' } else { ' ' }
            $box = if ($MultiSelect) { if ($selected[$i]) { '[x] ' } else { '[ ] ' } } else { '' }
            $color = if ($i -eq $cursor) { [System.ConsoleColor]::Cyan }
                elseif ($MultiSelect -and $selected[$i]) { [System.ConsoleColor]::Green }
                else { [System.ConsoleColor]::Gray }
            $lines += , @(("  {0} {1}{2}" -f $marker, $box, $Labels[$i]), $color)
        }

        foreach ($line in $lines) {
            # Truncating keeps a long label from wrapping, which would desynchronize the cursor
            # from the row count the next frame moves up by.
            $text = $line[0]
            if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
            Write-Host ($text + $script:AnsiEraseLine) -ForegroundColor $line[1]
        }
    }

    try {
        try { [Console]::CursorVisible = $false } catch { }

        while ($true) {
            # Dot-sourced so the frame counter it flips stays visible to the next iteration.
            . $draw

            try { $key = Read-MenuKey }
            catch {
                $script:MenuBlockerDetail = 'this host cannot read single keystrokes'
                return $null
            }

            if ($key.Name -eq 'CtrlC') { Invoke-PromptExit }

            if ($key.Name -eq 'Up' -or $key.Char -eq 'k') {
                $cursor = ($cursor - 1 + $count) % $count
            }
            elseif ($key.Name -eq 'Down' -or $key.Char -eq 'j') {
                $cursor = ($cursor + 1) % $count
            }
            elseif ($key.Name -eq 'Home') {
                $cursor = 0
            }
            elseif ($key.Name -eq 'End') {
                $cursor = $count - 1
            }
            elseif ($key.Name -eq 'Space') {
                if ($MultiSelect) { $selected[$cursor] = -not $selected[$cursor] } else { return , @($cursor) }
            }
            elseif ($key.Name -eq 'Enter') {
                if (-not $MultiSelect) { return , @($cursor) }
                return , @(for ($i = 0; $i -lt $count; $i++) { if ($selected[$i]) { $i } })
            }
            elseif ($key.Name -eq 'Escape') {
                if ($EscapeMeansDefault) { return , @() }
                Invoke-PromptBack
            }
            elseif ($MultiSelect -and $key.Char -eq 'a') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $true }
            }
            elseif ($MultiSelect -and $key.Char -eq 'n') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $false }
            }
        }
    }
    finally {
        try { . $draw } catch { }
        try { [Console]::CursorVisible = $true } catch { }
    }
}

function Read-TypedLine {
    param([string]$PromptText)

    if (Get-ConsoleMenuBlocker) {
        return Read-Host $PromptText
    }

    Write-Host "${PromptText}: " -NoNewline
    $buffer = [System.Text.StringBuilder]::new()
    while ($true) {
        try { $key = Read-MenuKey }
        catch {
            Write-Host ''
            return Read-Host $PromptText
        }

        switch ($key.Name) {
            'CtrlC' { Invoke-PromptExit }
            'Escape' {
                Write-Host ''
                Invoke-PromptBack
            }
            'Enter' {
                Write-Host ''
                return $buffer.ToString()
            }
            'Backspace' {
                if ($buffer.Length -gt 0) {
                    $null = $buffer.Remove($buffer.Length - 1, 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            default {
                $ch = $key.Character
                if ($ch -and [int][char]$ch -ge 32) {
                    $null = $buffer.Append($ch)
                    Write-Host $ch -NoNewline
                }
            }
        }
    }
}

function Read-InputString {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [switch]$Required,
        [scriptblock]$Validate
    )

    if ($NonInteractive) {
        if ($Required -and [string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a value for: $Prompt"
        }
        return $Default
    }

    $suffix = if ($Default) { " [$Default]" } else { '' }
    while ($true) {
        $value = Read-TypedLine "$Prompt$suffix"
        if ([string]::IsNullOrWhiteSpace($value)) { $value = $Default }
        $value = if ($null -eq $value) { '' } else { $value.Trim() }

        if ($Required -and [string]::IsNullOrWhiteSpace($value)) {
            Write-Host '   A value is required.' -ForegroundColor Yellow
            continue
        }
        if ($Validate -and -not [string]::IsNullOrWhiteSpace($value)) {
            $failure = & $Validate $value
            if ($failure) {
                Write-Host "   $failure" -ForegroundColor Yellow
                continue
            }
        }
        return $value
    }
}

function Read-Choice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels,
        [string]$Default,
        [switch]$EscapeMeansDefault
    )

    if (-not $Labels) { $Labels = $Options }
    if ($NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a choice for: $Prompt"
        }
        return $Default
    }

    $defaultIndex = if ($Default) { [array]::IndexOf($Options, $Default) } else { 0 }
    if ($defaultIndex -lt 0) { $defaultIndex = 0 }

    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $menuLabels = @(
            for ($i = 0; $i -lt $Options.Count; $i++) {
                if ($Options[$i] -eq $Default) { "$($Labels[$i])  (default)" } else { $Labels[$i] }
            }
        )
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $menuLabels -InitialIndex $defaultIndex `
            -EscapeMeansDefault:$EscapeMeansDefault
        if ($null -ne $picked) {
            if (@($picked).Count -gt 0) { return $Options[@($picked)[0]] }
            return $Options[$defaultIndex]
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $marker = if ($Options[$i] -eq $Default) { '*' } else { ' ' }
        Write-Host ("  {0} {1}) {2}" -f $marker, ($i + 1), $Labels[$i])
    }

    $defaultNumber = if ($Default) { $defaultIndex + 1 } else { 0 }
    while ($true) {
        $label = if ($EscapeMeansDefault) {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber]" } else { "Select 1-$($Options.Count)" }
        }
        else {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber], or b to go back" } else { "Select 1-$($Options.Count), or b to go back" }
        }
        $raw = Read-Host $label
        if (-not $EscapeMeansDefault -and $raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw) -and $defaultNumber -gt 0) {
            return $Options[$defaultNumber - 1]
        }
        $n = 0
        if ([int]::TryParse($raw, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
            return $Options[$n - 1]
        }
        Write-Host '   Enter a number from the list.' -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [bool]$Default = $true
    )

    if ($NonInteractive) { return $Default }

    $defaultOption = if ($Default) { 'Yes' } else { 'No' }
    return (Read-Choice -Prompt $Prompt -Options @('Yes', 'No') -Default $defaultOption) -eq 'Yes'
}

function Copy-ToClipboard {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $setClipboard = Get-Command Set-Clipboard -ErrorAction SilentlyContinue
    if ($setClipboard) {
        try {
            Set-Clipboard -Value $Text -ErrorAction Stop
            return $true
        }
        catch { }
    }

    foreach ($tool in @('pbcopy', 'wl-copy', 'xclip')) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        try {
            $toolArgs = if ($tool -eq 'xclip') { @('-selection', 'clipboard') } else { @() }
            $Text | & $cmd.Source @toolArgs
            return $true
        }
        catch { }
    }

    return $false
}

function Open-Url {
    param([Parameter(Mandatory)][string]$Url)

    try {
        if ($Url -match '\.(msc|exe)$' -or $Url -eq 'services.msc') {
            Start-Process $Url -ErrorAction Stop | Out-Null
            return $true
        }
        Start-Process $Url -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-MaskedSecretDisplay {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 4) { return '***' }
    return ('***' + $Value.Substring($Value.Length - 4))
}

function Get-CompletionPreview {
    param(
        [AllowNull()][string]$Value,
        [switch]$Mask
    )

    if ($Mask) { return Get-MaskedSecretDisplay -Value $Value }
    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 72) { return $Value }
    return ($Value.Substring(0, 69) + '...')
}

function Invoke-CompletionActionMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string[]]$Situation,
        [Parameter(Mandatory)][object[]]$Items
    )

    Write-Host ''
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * [Math]::Min($Title.Length, 60))) -ForegroundColor Cyan
    foreach ($line in $Situation) {
        Write-Host "  $line" -ForegroundColor White
    }
    Write-Host ''
    Write-Host '  Copy host and port values into the ISC source IQService panel, or open a link to finish pending manual steps.' -ForegroundColor Yellow

    if ($Items.Count -eq 0) { return }

    if ($NonInteractive) {
        Write-Host ''
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            Write-Host "  $($item.Label): $preview ($verb)" -ForegroundColor Yellow
        }
        return
    }

    $doneLabel = 'Done'
    while ($true) {
        $labels = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            $labels.Add(('{0}: {1} ({2})' -f $item.Label, $preview, $verb))
        }
        $labels.Add($doneLabel)

        $picked = Read-Choice -Prompt 'Select a value to copy or a link to open:' `
            -Options $labels.ToArray() `
            -Default $doneLabel `
            -EscapeMeansDefault
        if ($picked -eq $doneLabel) { return }

        $index = [array]::IndexOf($labels.ToArray(), $picked)
        if ($index -lt 0 -or $index -ge $Items.Count) { continue }

        $selected = $Items[$index]
        if ($selected.Kind -eq 'Open') {
            if (Open-Url -Url ([string]$selected.Value)) {
                Write-Ok "Opened $($selected.Label)"
            }
            else {
                Write-Warning "Could not open $($selected.Label). Target: $($selected.Value)"
            }
        }
        else {
            if (Copy-ToClipboard -Text ([string]$selected.Value)) {
                Write-Ok "$($selected.Label) copied to the clipboard"
            }
            else {
                Write-Warning 'No clipboard tool is available (Set-Clipboard). Copy from the list above.'
            }
        }
    }
}

function Show-IQServiceCompletion {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$CompletedAction,
        [switch]$ServiceStoppedAfterUpdate,
        [switch]$RestartPendingForLogLevel,
        [int]$BlockedFilesRemaining = -1
    )

    $exePath = Join-Path -Path $InstallPath -ChildPath 'IQService.exe'
    $hasExe = Test-Path -LiteralPath $exePath
    $snapshot = Get-IQServiceConfigurationSnapshot -InstallPath $InstallPath -ExecutablePath:$(if ($hasExe) { $exePath } else { $null })
    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    $build = Get-IQServiceBuildFromPath -Path $zipPath
    $utilsDll = Join-Path -Path $InstallPath -ChildPath 'Utils.dll'
    $utilsBlocked = $false
    if (Test-Path -LiteralPath $utilsDll) {
        $utilsBlocked = Test-FileBlocked -Path $utilsDll
    }
    if ($BlockedFilesRemaining -lt 0) {
        $blockedCount = 0
        if ($utilsBlocked) { $blockedCount++ }
        $BlockedFilesRemaining = $blockedCount
    }

    $primaryService = $snapshot.Services | Select-Object -First 1
    $primaryRegistry = $snapshot.Registry | Select-Object -First 1
    $hostName = $env:COMPUTERNAME
    try {
        $fqdn = [System.Net.Dns]::GetHostEntry('localhost').HostName
        if ($fqdn) { $hostName = $fqdn }
    }
    catch { }

    $port = if ($primaryRegistry -and $primaryRegistry.Port) { [string]$primaryRegistry.Port } else { '' }
    $tlsPort = if ($primaryRegistry -and $primaryRegistry.TlsPort) { [string]$primaryRegistry.TlsPort } else { '' }
    $traceFile = if ($primaryRegistry -and $primaryRegistry.TraceFile) { [string]$primaryRegistry.TraceFile } else { (Join-Path $InstallPath 'iqtrace.log') }
    $serviceStatus = if ($primaryService) { $primaryService.Status } else { 'Not registered' }

    $situation = [System.Collections.Generic.List[string]]::new()
    switch ($CompletedAction) {
        'Download' {
            $situation.Add('IQService.zip is on this host. Next: run Install or Update (Unblock first if Utils.dll is blocked).')
        }
        'Install' {
            $situation.Add('IQService is registered on this host. Confirm TLS certificates and client authentication if required, verify the Windows Log On account, then paste host and ports into ISC.')
        }
        'Update' {
            $situation.Add('IQService was updated on this host. Confirm the Log On account in Services after uninstall/reinstall cleared registry entries.')
            if ($ServiceStoppedAfterUpdate) {
                $situation.Add('Pending: start IQService before testing the ISC source connection.')
            }
        }
        'Start' {
            $situation.Add("IQService service status: $serviceStatus. Paste host and ports into the ISC source IQService panel when the service is running.")
        }
        'Stop' {
            $situation.Add("IQService is stopped ($serviceStatus). Start it again before ISC provisioning or aggregation tests.")
        }
        'Restart' {
            $situation.Add("IQService was restarted. Current status: $serviceStatus.")
        }
        'SetLogLevel' {
            $situation.Add('Trace level was updated on this host.')
            if ($RestartPendingForLogLevel) {
                $situation.Add('Pending: restart IQService for the new trace level to take effect.')
            }
        }
        'Unblock' {
            $situation.Add('File unblock completed.')
            if ($utilsBlocked -or $BlockedFilesRemaining -gt 0) {
                $situation.Add('Pending: some binaries may still be blocked. Re-run Unblock or unblock IQService.zip before extracting.')
            }
        }
        'Uninstall' {
            $situation.Add('IQService registration was removed. Reinstall from the menu or -Action Install when you are ready.')
            $situation.Add('Pending: if the Log On account changed during uninstall, set it again in Services (services.msc).')
        }
        default {
            $situation.Add("IQService on this host — status: $serviceStatus.")
        }
    }

    if ($utilsBlocked) {
        $situation.Add('Pending: Utils.dll is blocked. Run Unblock before install or service start.')
    }
    if (-not $hasExe) {
        $situation.Add('Pending: IQService.exe is missing. Download and install before configuring ISC.')
    }
    elseif ($serviceStatus -ne 'Running' -and $CompletedAction -notin @('Stop', 'Uninstall', 'Download')) {
        $situation.Add('Pending: IQService is not running. Start the service before testing from ISC.')
    }
    $situation.Add('In ISC: Connections > Sources > [source requiring IQService] > IQService / Integration Service.')

    $items = [System.Collections.Generic.List[object]]::new()
    $items.Add([PSCustomObject]@{ Label = 'Host name'; Value = $hostName; Kind = 'Copy'; Mask = $false })
    if ($port) { $items.Add([PSCustomObject]@{ Label = 'Port (non-TLS)'; Value = $port; Kind = 'Copy'; Mask = $false }) }
    if ($tlsPort) { $items.Add([PSCustomObject]@{ Label = 'TLS port'; Value = $tlsPort; Kind = 'Copy'; Mask = $false }) }
    $items.Add([PSCustomObject]@{ Label = 'Install path'; Value = $InstallPath; Kind = 'Copy'; Mask = $false })
    if ($hasExe) {
        $items.Add([PSCustomObject]@{ Label = 'IQService.exe path'; Value = $exePath; Kind = 'Copy'; Mask = $false })
    }
    if ($snapshot.Version -and $snapshot.Version -ne 'Not installed') {
        $items.Add([PSCustomObject]@{ Label = 'Version'; Value = $snapshot.Version; Kind = 'Copy'; Mask = $false })
    }
    if ($build) {
        $items.Add([PSCustomObject]@{ Label = 'ZIP build'; Value = $build; Kind = 'Copy'; Mask = $false })
    }
    if ($primaryService) {
        $items.Add([PSCustomObject]@{ Label = 'Windows service name'; Value = $primaryService.Name; Kind = 'Copy'; Mask = $false })
        if ($primaryService.StartName) {
            $items.Add([PSCustomObject]@{ Label = 'Log On account'; Value = $primaryService.StartName; Kind = 'Copy'; Mask = $false })
        }
    }
    if ($traceFile) {
        $items.Add([PSCustomObject]@{ Label = 'Trace log file'; Value = $traceFile; Kind = 'Copy'; Mask = $false })
    }
    if (Test-Path -LiteralPath $zipPath) {
        $items.Add([PSCustomObject]@{ Label = 'IQService.zip path'; Value = $zipPath; Kind = 'Copy'; Mask = $false })
    }

    $items.Add([PSCustomObject]@{
        Label = 'IQService install documentation'
        Value = 'https://documentation.sailpoint.com/connectors/iqservice/help/integrating_iqservice_admin/install_register.html'
        Kind  = 'Open'
        Mask  = $false
    })
    $items.Add([PSCustomObject]@{ Label = 'Windows Services (services.msc)'; Value = 'services.msc'; Kind = 'Open'; Mask = $false })

    Invoke-CompletionActionMenu -Title 'Next: configure ISC IQService connection' `
        -Situation $situation.ToArray() `
        -Items $items.ToArray()
}

# -----------------------------------------------------------------------------
# IQService discovery
# -----------------------------------------------------------------------------

function Test-LooksLikeIQServiceDirectory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    foreach ($marker in @('IQService.exe', 'Utils.dll')) {
        if (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $marker)) {
            return $true
        }
    }

    return $false
}

function Get-IQServiceWindowsServices {
    $services = @()
    try {
        $serviceKeys = Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop |
            Where-Object { $_.PSChildName -like '*IQService*' }

        foreach ($serviceKey in $serviceKeys) {
            $name = $serviceKey.PSChildName
            $imagePath = [string](Get-ItemProperty -Path $serviceKey.PSPath -Name ImagePath -ErrorAction SilentlyContinue).ImagePath
            if ([string]::IsNullOrWhiteSpace($imagePath)) {
                continue
            }

            if ($imagePath -match '^\s*"([^"]+)"') {
                $exePath = $matches[1]
            }
            elseif ($imagePath -match '^\s*(\S+)') {
                $exePath = $matches[1]
            }
            else {
                continue
            }

            $installDir = Split-Path -Path $exePath -Parent
            $winService = Get-Service -Name $name -ErrorAction SilentlyContinue
            $startName = $null
            try {
                $cim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
                $startName = $cim.StartName
            }
            catch {
                # Ignore.
            }

            $services += [PSCustomObject]@{
                Name        = $name
                DisplayName = if ($winService) { $winService.DisplayName } else { $name }
                Status      = if ($winService) { $winService.Status.ToString() } else { 'Unknown' }
                StartType   = if ($winService) { $winService.StartType.ToString() } else { 'Unknown' }
                ImagePath   = $exePath
                InstallPath = $installDir
                StartName   = $startName
            }
        }
    }
    catch {
        Write-Verbose "Could not enumerate IQService Windows services: $($_.Exception.Message)"
    }

    return $services
}

function Resolve-IQServiceInstallPath {
    param([string]$PreferredPath)

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (-not (Test-Path -LiteralPath $PreferredPath)) {
            New-Item -ItemType Directory -Path $PreferredPath -Force | Out-Null
        }
        return (Resolve-Path -LiteralPath $PreferredPath).Path
    }

    $services = @(Get-IQServiceWindowsServices)
    foreach ($service in $services) {
        if (Test-LooksLikeIQServiceDirectory -Path $service.InstallPath) {
            return $service.InstallPath
        }
    }

    if (Test-LooksLikeIQServiceDirectory -Path $script:DefaultInstallPath) {
        return (Resolve-Path -LiteralPath $script:DefaultInstallPath).Path
    }

    if (-not (Test-Path -LiteralPath $script:DefaultInstallPath)) {
        New-Item -ItemType Directory -Path $script:DefaultInstallPath -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $script:DefaultInstallPath).Path
}

function Get-IQServiceExecutable {
    param([Parameter(Mandatory)][string]$InstallPath)

    $exePath = Join-Path -Path $InstallPath -ChildPath 'IQService.exe'
    if (-not (Test-Path -LiteralPath $exePath)) {
        throw "IQService.exe was not found in '$InstallPath'. Download and extract IQService first."
    }

    return $exePath
}

function Get-IQServiceRegistryInstances {
    $instances = @()
    $root = 'HKLM:\SOFTWARE\SailPoint\IQService Instances'

    if (-not (Test-Path -LiteralPath $root)) {
        return $instances
    }

    foreach ($key in Get-ChildItem -Path $root -ErrorAction SilentlyContinue) {
        $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
        if (-not $props) { continue }

        $instances += [PSCustomObject]@{
            InstanceName    = $key.PSChildName
            Port            = $props.port
            TlsPort         = $props.tlsPort
            TraceFile       = $props.tracefile
            TraceLevel      = $props.tracelevel
            MaxTraceFiles   = $props.maxTraceFiles
            TraceFileSize   = $props.traceFileSize
            ClientAuthUsers = $props.clientAuthUsers
        }
    }

    return $instances
}

function Get-IQServiceZipPath {
    param([Parameter(Mandatory)][string]$InstallPath)
    return Join-Path -Path $InstallPath -ChildPath 'IQService.zip'
}

function Get-IQServiceBuildFromPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $leaf = Split-Path -Path $Path -Leaf
    if ($leaf -match 'IQService-(\d+)\.zip$') {
        return $matches[1]
    }
    return $null
}

# -----------------------------------------------------------------------------
# IQService command wrapper
# -----------------------------------------------------------------------------

function Invoke-IQServiceCommand {
    param(
        [Parameter(Mandatory)][string]$ExecutablePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowNonZeroExit
    )

    $displayArgs = ($Arguments | ForEach-Object {
        if ($_ -match '\s') { """$_""" } else { $_ }
    }) -join ' '

    Write-Verbose "Running: $ExecutablePath $displayArgs"

    $output = & $ExecutablePath @Arguments 2>&1
    $text = if ($null -eq $output) { '' } else { ($output | Out-String).Trim() }
    $exitCode = $LASTEXITCODE

    if ($text) {
        foreach ($line in ($text -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Info $line
            }
        }
    }

    if (-not $AllowNonZeroExit -and $exitCode -ne 0) {
        throw "IQService.exe exited with code $exitCode. Arguments: $displayArgs"
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = $text
    }
}

function Get-IQServiceVersion {
    param([Parameter(Mandatory)][string]$ExecutablePath)

    $result = Invoke-IQServiceCommand -ExecutablePath $ExecutablePath -Arguments @('-v') -AllowNonZeroExit
    if ($result.Output) {
        return $result.Output.Trim()
    }
    return 'Unknown'
}

# -----------------------------------------------------------------------------
# File unblock helpers
# -----------------------------------------------------------------------------

function Test-FileBlocked {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        $zoneStream = Get-Item -LiteralPath $Path -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue
        return [bool]$zoneStream
    }
    catch {
        return $false
    }
}

function Unblock-IQServiceFiles {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string[]]$AdditionalPaths
    )

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @($AdditionalPaths)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            $paths.Add($path)
        }
    }

    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    if (Test-Path -LiteralPath $zipPath) {
        $paths.Add($zipPath)
    }

    $utilsDll = Join-Path -Path $InstallPath -ChildPath 'Utils.dll'
    if (Test-Path -LiteralPath $utilsDll) {
        $paths.Add($utilsDll)
    }

    if (Test-Path -LiteralPath $InstallPath) {
        foreach ($file in Get-ChildItem -LiteralPath $InstallPath -Recurse -File -Include '*.dll', '*.exe' -ErrorAction SilentlyContinue) {
            $paths.Add($file.FullName)
        }
    }

    $unique = @($paths | Select-Object -Unique)
    $unblocked = 0
    foreach ($path in $unique) {
        if (Test-FileBlocked -Path $path) {
            Unblock-File -LiteralPath $path
            $unblocked++
        }
    }

    return [PSCustomObject]@{
        Checked   = $unique.Count
        Unblocked = $unblocked
    }
}

# -----------------------------------------------------------------------------
# Download and extract
# -----------------------------------------------------------------------------

function Save-IQServiceZip {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$DownloadUri,
        [string]$ZipPath
    )

    $destination = Get-IQServiceZipPath -InstallPath $InstallPath
    $sourcePath = $null

    if (-not [string]::IsNullOrWhiteSpace($ZipPath)) {
        if (-not (Test-Path -LiteralPath $ZipPath)) {
            throw "ZIP file not found: $ZipPath"
        }
        $sourcePath = (Resolve-Path -LiteralPath $ZipPath).Path
        if ($sourcePath -ne $destination) {
            Copy-Item -LiteralPath $sourcePath -Destination $destination -Force
            Write-Ok "Copied $sourcePath to $destination"
        }
        else {
            Write-Ok "Using ZIP at $destination"
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($DownloadUri)) {
        Write-Step 'Downloading IQService.zip'
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $DownloadUri -OutFile $destination -UseBasicParsing
        }
        catch {
            $message = $_.Exception.Message
            if ($message -match '403|401|expired|Forbidden') {
                throw "Download failed. Pre-signed ISC download URLs expire quickly. Copy a fresh link from Connections > Sources > IQService Download. Details: $message"
            }
            throw "Download failed: $message"
        }
        Write-Ok "Saved to $destination"
        $sourcePath = $destination
    }
    else {
        throw 'Provide -DownloadUri or -ZipPath, or choose Download from the interactive menu.'
    }

    $build = Get-IQServiceBuildFromPath -Path $destination
    if ($build) {
        Write-Ok "Detected build $build"
    }

    $unblock = Unblock-IQServiceFiles -InstallPath $InstallPath -AdditionalPaths @($destination)
    if ($unblock.Unblocked -gt 0) {
        Write-Ok "Unblocked $($unblock.Unblocked) file(s) before extraction"
    }

    return [PSCustomObject]@{
        ZipPath = $destination
        Build   = $build
    }
}

function Expand-IQServiceZip {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$ZipPath
    )

    if ([string]::IsNullOrWhiteSpace($ZipPath)) {
        $ZipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    }

    if (-not (Test-Path -LiteralPath $ZipPath)) {
        throw "ZIP file not found: $ZipPath. Run Download first or pass -ZipPath."
    }

    if (-not (Test-Path -LiteralPath $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    Write-Step "Extracting $ZipPath"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $InstallPath -Force
    Write-Ok "Extracted to $InstallPath"

    $unblock = Unblock-IQServiceFiles -InstallPath $InstallPath
    Write-Ok "Unblocked $($unblock.Unblocked) of $($unblock.Checked) executable file(s)"
}

# -----------------------------------------------------------------------------
# Install / update / service configuration
# -----------------------------------------------------------------------------

function Get-IQServiceConfigurationSnapshot {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$ExecutablePath
    )

    $services = @(Get-IQServiceWindowsServices | Where-Object { $_.InstallPath -eq $InstallPath })
    $registry = @(Get-IQServiceRegistryInstances)
    $version = 'Not installed'

    if ($ExecutablePath -and (Test-Path -LiteralPath $ExecutablePath)) {
        try {
            $version = Get-IQServiceVersion -ExecutablePath $ExecutablePath
        }
        catch {
            $version = "Unavailable: $($_.Exception.Message)"
        }
    }

    return [PSCustomObject]@{
        Version  = $version
        Services = $services
        Registry = $registry
    }
}

function Build-IQServiceInstallArguments {
    param(
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary
    )

    $installArgs = @('-i')
    if ($PSBoundParameters.ContainsKey('Port') -and $Port -gt 0) {
        $installArgs += @('-p', [string]$Port)
    }
    if ($PSBoundParameters.ContainsKey('TlsPort') -and $TlsPort -gt 0) {
        $installArgs += @('-o', [string]$TlsPort)
    }
    if ($SkipSecondary) {
        $installArgs += '-b'
    }
    return $installArgs
}

function Restore-IQServiceServiceAccount {
    param(
        [Parameter(Mandatory)][array]$Services
    )

    foreach ($service in $Services) {
        if ([string]::IsNullOrWhiteSpace($service.StartName)) {
            continue
        }

        if ($service.StartName -match 'LocalSystem|NT AUTHORITY\\LocalService|NT AUTHORITY\\NetworkService') {
            Write-Info "Service $($service.Name) uses built-in account $($service.StartName); no restore needed."
            continue
        }

        Write-Warning "Service $($service.Name) was configured to run as '$($service.StartName)'. IQService uninstall clears registry but not the service Log On account."
        Write-Warning 'If the account changed, open Services (services.msc), set Log On to the domain service account, and restart IQService.'
    }
}

function Install-IQServiceInstance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary,
        [switch]$StartAfterInstall
    )

    Assert-Elevated -Operation 'install IQService'

    $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    if (-not (Test-Path -LiteralPath $exe)) {
        Expand-IQServiceZip -InstallPath $InstallPath -ZipPath $zipPath
        $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    }

    $installArgs = Build-IQServiceInstallArguments -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary
    Write-Step 'Registering IQService Windows service'
    if (-not $PSCmdlet.ShouldProcess($InstallPath, 'Install IQService')) { return }

    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $installArgs
    Write-Ok 'IQService registered'

    if ($StartAfterInstall) {
        Write-Step 'Starting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-s')
        Write-Ok 'IQService started'
    }
}

function Update-IQServiceInstance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$DownloadUri,
        [string]$ZipPath,
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary,
        [switch]$StartAfterInstall
    )

    Assert-Elevated -Operation 'update IQService'

    $exe = $null
    if (Test-Path -LiteralPath (Join-Path $InstallPath 'IQService.exe')) {
        $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    }

    Write-Step 'Capturing current IQService configuration'
    $snapshot = Get-IQServiceConfigurationSnapshot -InstallPath $InstallPath -ExecutablePath $exe
    Write-Info "Current version: $($snapshot.Version)"

    $primaryRegistry = $snapshot.Registry | Select-Object -First 1
    $savedPort = if ($PSBoundParameters.ContainsKey('Port') -and $Port -gt 0) { $Port } elseif ($primaryRegistry.Port) { [int]$primaryRegistry.Port } else { 0 }
    $savedTlsPort = if ($PSBoundParameters.ContainsKey('TlsPort') -and $TlsPort -gt 0) { $TlsPort } elseif ($primaryRegistry.TlsPort) { [int]$primaryRegistry.TlsPort } else { 0 }
    $savedTraceLevel = if ($null -ne $primaryRegistry.TraceLevel) { [int]$primaryRegistry.TraceLevel } else { $null }
    $savedTraceFile = [string]$primaryRegistry.TraceFile
    if ([string]::IsNullOrWhiteSpace($savedTraceFile)) {
        $savedTraceFile = Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = "$InstallPath.backup.$timestamp"

    if (Test-Path -LiteralPath $InstallPath) {
        Write-Step "Backing up $InstallPath to $backupPath"
        if (-not $PSCmdlet.ShouldProcess($InstallPath, "Back up to $backupPath")) { return }
        Copy-Item -LiteralPath $InstallPath -Destination $backupPath -Recurse -Force
        Write-Ok "Backup created at $backupPath"
    }

    if ($exe) {
        Write-Step 'Stopping IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-k') -AllowNonZeroExit
        Write-Step 'Uninstalling IQService registration'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-u') -AllowNonZeroExit
    }

    if (-not [string]::IsNullOrWhiteSpace($DownloadUri) -or -not [string]::IsNullOrWhiteSpace($ZipPath)) {
        Save-IQServiceZip -InstallPath $InstallPath -DownloadUri $DownloadUri -ZipPath $ZipPath | Out-Null
    }

    Expand-IQServiceZip -InstallPath $InstallPath
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath

    $installArgs = Build-IQServiceInstallArguments
    if ($savedPort -gt 0) { $installArgs += @('-p', [string]$savedPort) }
    if ($savedTlsPort -gt 0) { $installArgs += @('-o', [string]$savedTlsPort) }
    if ($SkipSecondary) { $installArgs += '-b' }

    Write-Step 'Re-registering IQService'
    if (-not $PSCmdlet.ShouldProcess($InstallPath, 'Reinstall IQService')) { return }
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $installArgs
    Write-Ok 'IQService re-registered'

    if ($null -ne $savedTraceLevel) {
        $logName = ($script:LogLevelMap.GetEnumerator() | Where-Object { $_.Value -eq $savedTraceLevel } | Select-Object -First 1).Name
        if ($logName) {
            Write-Step "Restoring trace level $logName ($savedTraceLevel)"
            Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-l', [string]$savedTraceLevel, '-f', $savedTraceFile)
        }
    }

    Restore-IQServiceServiceAccount -Services $snapshot.Services

    if ($StartAfterInstall) {
        Write-Step 'Starting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-s')
        Write-Ok 'IQService started'
    }
    else {
        Write-Info 'Service was stopped for the update. Start it with -Action Start or IQService.exe -s.'
    }

    Write-Ok "Update complete. Backup retained at $backupPath"
}

function Invoke-IQServiceServiceAction {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][ValidateSet('Start', 'Stop', 'Restart', 'Uninstall')]
        [string]$ServiceAction,
        [Parameter(Mandatory)][string]$InstallPath
    )

    Assert-Elevated -Operation "$($ServiceAction.ToLowerInvariant()) IQService"
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath

    $argMap = @{
        Start     = @('-s')
        Stop      = @('-k')
        Restart   = @('-t')
        Uninstall = @('-u')
    }

    if ($ServiceAction -eq 'Uninstall') {
        if (-not $NonInteractive -and -not (Read-YesNo -Prompt 'Uninstall IQService registration and clear registry entries?' -Default $false)) {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
    }

    if (-not $PSCmdlet.ShouldProcess($InstallPath, "$ServiceAction IQService")) { return }

    Write-Step "$ServiceAction IQService"
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $argMap[$ServiceAction] -AllowNonZeroExit:($ServiceAction -in @('Stop', 'Uninstall'))
    Write-Ok "$ServiceAction completed"
}

function Set-IQServiceTraceLevel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][ValidateSet('Off', 'Error', 'Info', 'Debug')]
        [string]$Level,
        [string]$TraceFile,
        [switch]$RestartIfRunning
    )

    Assert-Elevated -Operation 'set IQService log level'
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    $numeric = $script:LogLevelMap[$Level]

    if ([string]::IsNullOrWhiteSpace($TraceFile)) {
        $TraceFile = Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
    }

    $services = @(Get-IQServiceWindowsServices | Where-Object { $_.InstallPath -eq $InstallPath })
    $wasRunning = @($services | Where-Object { $_.Status -eq 'Running' }).Count -gt 0
    $doRestart = $RestartIfRunning -or ($wasRunning -and -not $NonInteractive -and (Read-YesNo -Prompt 'Restart IQService to apply the new log level?' -Default $true))

    if (-not $PSCmdlet.ShouldProcess($InstallPath, "Set log level to $Level ($numeric)")) {
        return [PSCustomObject]@{ RestartPending = $false }
    }

    Write-Step "Setting trace level to $Level ($numeric)"
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-l', [string]$numeric, '-f', $TraceFile)
    Write-Ok "Trace file: $TraceFile"

    if ($doRestart) {
        Write-Step 'Restarting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-t') -AllowNonZeroExit
        Write-Ok 'IQService restarted'
        return [PSCustomObject]@{ RestartPending = $false }
    }
    if ($wasRunning) {
        Write-Info 'Service is running. Restart IQService for the new log level to take effect.'
        return [PSCustomObject]@{ RestartPending = $true }
    }
    return [PSCustomObject]@{ RestartPending = $false }
}

function Show-IQServiceStatus {
    param([Parameter(Mandatory)][string]$InstallPath)

    Show-IQServiceCompletion -InstallPath $InstallPath -CompletedAction 'Status'
}

# -----------------------------------------------------------------------------
# Trace log streaming
# -----------------------------------------------------------------------------

function Resolve-IQServiceTraceFile {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$TraceFile
    )

    if (-not [string]::IsNullOrWhiteSpace($TraceFile)) {
        return $TraceFile
    }

    foreach ($instance in @(Get-IQServiceRegistryInstances)) {
        $candidate = [string]$instance.TraceFile
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    foreach ($name in @('iqtrace.log', 'IQTrace.log')) {
        $candidate = Join-Path -Path $InstallPath -ChildPath $name
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
}

function Get-IQServiceLogLevelColor {
    param([string]$Level)

    switch -Regex ($Level) {
        '^ERR'          { return [System.ConsoleColor]::Red }
        '^WARN'         { return [System.ConsoleColor]::Yellow }
        '^INFO'         { return [System.ConsoleColor]::Cyan }
        '^DEBUG|^TRACE' { return [System.ConsoleColor]::DarkGray }
        default         { return [System.ConsoleColor]::Gray }
    }
}

function ConvertTo-CompleteLogLines {
    param(
        [string]$Chunk,
        [Parameter(Mandatory)][ref]$Carry
    )

    $text = $Carry.Value + $Chunk
    if ([string]::IsNullOrEmpty($text)) {
        return @()
    }

    $parts = [regex]::Split($text, '\r?\n')
    $endsWithNewline = $text.EndsWith("`n") -or $text.EndsWith("`r")
    if ($endsWithNewline) {
        $Carry.Value = ''
        if ($parts.Count -gt 0 -and $parts[-1] -eq '') {
            if ($parts.Count -eq 1) { return @() }
            return @($parts[0..($parts.Count - 2)])
        }
        return @($parts)
    }

    $Carry.Value = $parts[-1]
    if ($parts.Count -le 1) {
        return @()
    }
    return @($parts[0..($parts.Count - 2)])
}

function Write-IQServiceLogLine {
    param(
        [string]$Line,
        [Parameter(Mandatory)][ref]$LastLevel
    )

    if ($null -eq $Line) { return }

    $header = [regex]::Match(
        $Line,
        '^(?<ts>\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}:\d{2})\s*:\s*(?<comp>\S+)\s*\[\s*(?<thread>[^\]]+)\]\s*(?<level>ERROR|WARN(?:ING)?|INFO|DEBUG|TRACE)\s*:\s*(?<msg>.*)$'
    )

    if ($header.Success) {
        $level = $header.Groups['level'].Value.ToUpperInvariant()
        if ($level -eq 'WARNING') { $level = 'WARN' }
        $LastLevel.Value = $level
        $levelColor = Get-IQServiceLogLevelColor -Level $level
        $messageColor = if ($level -match '^(ERR|WARN)') { $levelColor } else { [System.ConsoleColor]::Gray }

        Write-Host $header.Groups['ts'].Value -ForegroundColor DarkGray -NoNewline
        Write-Host ' : ' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['comp'].Value -ForegroundColor White -NoNewline
        Write-Host ' [' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['thread'].Value.Trim() -ForegroundColor DarkCyan -NoNewline
        Write-Host '] ' -ForegroundColor DarkGray -NoNewline
        Write-Host $level -ForegroundColor $levelColor -NoNewline
        Write-Host ' : ' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['msg'].Value -ForegroundColor $messageColor
        return
    }

    $color = Get-IQServiceLogLevelColor -Level $LastLevel.Value
    if ($Line -match '\bERROR\b') {
        $color = [System.ConsoleColor]::Red
        $LastLevel.Value = 'ERROR'
    }
    elseif ($Line -match '\bWARN(?:ING)?\b') {
        $color = [System.ConsoleColor]::Yellow
        $LastLevel.Value = 'WARN'
    }
    Write-Host $Line -ForegroundColor $color
}

function Test-LogStreamCancel {
    try {
        if (-not [Console]::KeyAvailable) { return $false }
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::C -and $key.Modifiers -eq [ConsoleModifiers]::Control) { return $true }
        if ($key.Key -eq [ConsoleKey]::Q -or $key.Key -eq [ConsoleKey]::Escape) { return $true }
    }
    catch {
        # Host cannot poll keys (ISE, redirected stdin); Ctrl+C still stops the loop via the runtime.
    }
    return $false
}

function Get-IQServiceLogFileIdentity {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $item = Get-Item -LiteralPath $Path
    return [PSCustomObject]@{
        Length           = $item.Length
        CreationTimeUtc  = $item.CreationTimeUtc
        LastWriteTimeUtc = $item.LastWriteTimeUtc
    }
}

function Read-IQServiceLogDelta {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ref]$Position,
        [Parameter(Mandatory)][ref]$Carry,
        [Parameter(Mandatory)]$Encoding
    )

    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        if ($stream.Length -lt $Position.Value) {
            $Position.Value = [int64]0
            $Carry.Value = ''
        }

        if ($stream.Length -le $Position.Value) {
            return @()
        }

        $null = $stream.Seek($Position.Value, [System.IO.SeekOrigin]::Begin)
        $toRead = [int]($stream.Length - $Position.Value)
        $buffer = New-Object byte[] $toRead
        $read = $stream.Read($buffer, 0, $toRead)
        $Position.Value += $read
        $chunk = $Encoding.GetString($buffer, 0, $read)
        return @(ConvertTo-CompleteLogLines -Chunk $chunk -Carry $Carry)
    }
    finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Show-IQServiceLogStream {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$TraceFile,
        [int]$TailLines = 50
    )

    $path = Resolve-IQServiceTraceFile -InstallPath $InstallPath -TraceFile $TraceFile
    $encoding = [System.Text.Encoding]::Default

    Write-Step "Streaming $path"
    Write-Info 'Ctrl+C, Q, or Esc to stop.'

    $traceLevel = $null
    foreach ($instance in @(Get-IQServiceRegistryInstances)) {
        if ($null -ne $instance.TraceLevel) {
            $traceLevel = [int]$instance.TraceLevel
            break
        }
    }
    if ($traceLevel -eq 0) {
        Write-Host '   Trace level is Off; the file may stay empty until you set Error, Info, or Debug.' -ForegroundColor Yellow
    }

    $treatCtrlC = $null
    try {
        $treatCtrlC = [Console]::TreatControlCAsInput
        [Console]::TreatControlCAsInput = $true
    }
    catch {
        $treatCtrlC = $null
    }

    $lastLevel = 'INFO'
    $position = [int64]0
    $carry = ''
    $identity = $null

    try {
        $waitingNotice = $false
        while (-not (Test-Path -LiteralPath $path)) {
            if (-not $waitingNotice) {
                Write-Host '   Waiting for the log file to appear...' -ForegroundColor Yellow
                $waitingNotice = $true
            }
            if (Test-LogStreamCancel) { return }
            Start-Sleep -Milliseconds 500
        }
        if ($waitingNotice) {
            Write-Ok "Log file appeared: $path"
        }

        $identity = Get-IQServiceLogFileIdentity -Path $path
        $fileLength = $identity.Length
        $bootstrapCarry = ''
        $bootstrapPosition = [int64]0

        if ($TailLines -le 0) {
            $position = $fileLength
            $carry = ''
            Write-Info 'Following new lines only.'
        }
        else {
            $window = [Math]::Max([int64]524288, [int64]$TailLines * 512)
            if ($fileLength -gt $window) {
                $bootstrapPosition = $fileLength - $window
            }
            $existing = @(Read-IQServiceLogDelta -Path $path -Position ([ref]$bootstrapPosition) -Carry ([ref]$bootstrapCarry) -Encoding $encoding)
            if ($fileLength -gt $window -and $existing.Count -gt 0) {
                $existing = @($existing | Select-Object -Skip 1)
            }
            $position = $bootstrapPosition
            $carry = $bootstrapCarry

            if ($existing.Count -gt 0) {
                $start = [Math]::Max(0, $existing.Count - $TailLines)
                for ($i = $start; $i -lt $existing.Count; $i++) {
                    Write-IQServiceLogLine -Line $existing[$i] -LastLevel ([ref]$lastLevel)
                }
            }
            else {
                Write-Info 'Log file is empty; waiting for new lines.'
            }
        }

        while ($true) {
            if (Test-LogStreamCancel) { break }

            if (-not (Test-Path -LiteralPath $path)) {
                $position = [int64]0
                $carry = ''
                $identity = $null
                Start-Sleep -Milliseconds 400
                continue
            }

            $current = Get-IQServiceLogFileIdentity -Path $path
            if (-not $current) {
                $position = [int64]0
                $carry = ''
                $identity = $null
                Start-Sleep -Milliseconds 400
                continue
            }
            if ($identity -and $current.CreationTimeUtc -ne $identity.CreationTimeUtc) {
                $position = [int64]0
                $carry = ''
            }
            $identity = $current

            $lines = @(Read-IQServiceLogDelta -Path $path -Position ([ref]$position) -Carry ([ref]$carry) -Encoding $encoding)
            foreach ($line in $lines) {
                Write-IQServiceLogLine -Line $line -LastLevel ([ref]$lastLevel)
            }

            Start-Sleep -Milliseconds 250
        }
    }
    catch [System.OperationCanceledException] {
        # Ctrl+C when TreatControlCAsInput could not be set.
    }
    finally {
        if ($null -ne $treatCtrlC) {
            try { [Console]::TreatControlCAsInput = $treatCtrlC } catch { }
        }
        Write-Host ''
        Write-Ok 'Stopped streaming.'
    }
}

# -----------------------------------------------------------------------------
# Interactive menu
# -----------------------------------------------------------------------------

function Show-InteractiveMenu {
    param([string]$ResolvedInstallPath)

    while ($true) {
        Write-Banner
        Write-Info "Install path: $ResolvedInstallPath"
        Write-Host ''

        try {
            $choice = Read-Choice -Prompt 'Select an action:' -Options @(
                'Status', 'Download', 'Install', 'Update', 'Service', 'SetLogLevel', 'StreamLogs', 'Unblock', 'Exit'
            ) -Labels @(
                'Status'
                'Download ZIP'
                'Install / register'
                'Update (backup, replace, reinstall)'
                'Start / Stop / Restart'
                'Set log level'
                'Stream logs'
                'Unblock Utils.dll and other binaries'
                'Exit'
            ) -Default 'Status'
        }
        catch {
            if (Test-PromptBack $_) { return }
            throw
        }

        try {
            switch ($choice) {
            'Status' {
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Status'
            }
            'Download' {
                $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                    'Paste a pre-signed ISC download URL'
                    'Use a local ZIP file path'
                ) -Default 'Url'
                if ($source -eq 'Url') {
                    $uri = Read-InputString -Prompt 'Download URL' -Required
                    Save-IQServiceZip -InstallPath $ResolvedInstallPath -DownloadUri $uri | Out-Null
                }
                else {
                    $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                    Save-IQServiceZip -InstallPath $ResolvedInstallPath -ZipPath $localZip | Out-Null
                }
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Download'
            }
            'Install' {
                if (-not (Test-Path -LiteralPath (Get-IQServiceZipPath -InstallPath $ResolvedInstallPath))) {
                    $getZip = Read-YesNo -Prompt 'IQService.zip is not in the install path. Download or copy it first?' -Default $true
                    if ($getZip) {
                        $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                            'Paste a pre-signed ISC download URL'
                            'Use a local ZIP file path'
                        ) -Default 'Url'
                        if ($source -eq 'Url') {
                            $uri = Read-InputString -Prompt 'Download URL' -Required
                            Save-IQServiceZip -InstallPath $ResolvedInstallPath -DownloadUri $uri | Out-Null
                        }
                        else {
                            $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                            Save-IQServiceZip -InstallPath $ResolvedInstallPath -ZipPath $localZip | Out-Null
                        }
                    }
                }
                $start = Read-YesNo -Prompt 'Start IQService after install?' -Default $false
                Install-IQServiceInstance -InstallPath $ResolvedInstallPath -StartAfterInstall:$start
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Install'
            }
            'Update' {
                $uri = $null
                $localZip = $null
                if (Read-YesNo -Prompt 'Download or supply a new ZIP for this update?' -Default $true) {
                    $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                        'Paste a pre-signed ISC download URL'
                        'Use a local ZIP file path'
                    ) -Default 'Url'
                    if ($source -eq 'Url') {
                        $uri = Read-InputString -Prompt 'Download URL' -Required
                    }
                    else {
                        $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                    }
                }
                $start = Read-YesNo -Prompt 'Start IQService after update?' -Default $true
                Update-IQServiceInstance -InstallPath $ResolvedInstallPath -DownloadUri $uri -ZipPath $localZip -StartAfterInstall:$start
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Update' -ServiceStoppedAfterUpdate:(-not $start)
            }
            'Service' {
                $svcAction = Read-Choice -Prompt 'Service action:' -Options @('Start', 'Stop', 'Restart', 'Uninstall') -Default 'Restart'
                Invoke-IQServiceServiceAction -ServiceAction $svcAction -InstallPath $ResolvedInstallPath
                $completionAction = switch ($svcAction) {
                    'Start' { 'Start' }
                    'Stop' { 'Stop' }
                    'Restart' { 'Restart' }
                    'Uninstall' { 'Uninstall' }
                }
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction $completionAction
            }
            'SetLogLevel' {
                $level = Read-Choice -Prompt 'Trace level:' -Options @('Off', 'Error', 'Info', 'Debug') -Default 'Info'
                $logResult = Set-IQServiceTraceLevel -InstallPath $ResolvedInstallPath -Level $level -RestartIfRunning
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'SetLogLevel' `
                    -RestartPendingForLogLevel:([bool]$logResult.RestartPending)
            }
            'StreamLogs' {
                Show-IQServiceLogStream -InstallPath $ResolvedInstallPath -TraceFile $TraceFile -TailLines $Tail
            }
            'Unblock' {
                Write-Step 'Unblocking IQService files'
                $result = Unblock-IQServiceFiles -InstallPath $ResolvedInstallPath
                Write-Ok "Unblocked $($result.Unblocked) of $($result.Checked) file(s)"
                $remaining = [Math]::Max(0, $result.Checked - $result.Unblocked)
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Unblock' -BlockedFilesRemaining $remaining
            }
            'Exit' {
                return
            }
        }
        }
        catch {
            if (Test-PromptBack $_) { continue }
            throw
        }
    }
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

try {
    Assert-WindowsHost
    Write-Banner

    $resolvedPath = Resolve-IQServiceInstallPath -PreferredPath $InstallPath
    if (-not $Action) {
        Show-InteractiveMenu -ResolvedInstallPath $resolvedPath
        return
    }

    switch ($Action) {
        'Status' {
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Status'
        }
        'Download' {
            if ([string]::IsNullOrWhiteSpace($DownloadUri) -and [string]::IsNullOrWhiteSpace($ZipPath)) {
                throw 'Download requires -DownloadUri or -ZipPath in non-interactive mode.'
            }
            Save-IQServiceZip -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Download'
        }
        'Install' {
            if (-not [string]::IsNullOrWhiteSpace($DownloadUri) -or -not [string]::IsNullOrWhiteSpace($ZipPath)) {
                Save-IQServiceZip -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath | Out-Null
            }
            Install-IQServiceInstance -InstallPath $resolvedPath -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary -StartAfterInstall:$StartAfterInstall
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Install'
        }
        'Update' {
            Update-IQServiceInstance -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary -StartAfterInstall:$StartAfterInstall
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Update' -ServiceStoppedAfterUpdate:(-not $StartAfterInstall)
        }
        'Uninstall' {
            Invoke-IQServiceServiceAction -ServiceAction Uninstall -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Uninstall'
        }
        'Start' {
            Invoke-IQServiceServiceAction -ServiceAction Start -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Start'
        }
        'Stop' {
            Invoke-IQServiceServiceAction -ServiceAction Stop -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Stop'
        }
        'Restart' {
            Invoke-IQServiceServiceAction -ServiceAction Restart -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Restart'
        }
        'SetLogLevel' {
            if (-not $LogLevel) {
                throw 'SetLogLevel requires -LogLevel (Off, Error, Info, or Debug) in non-interactive mode.'
            }
            $logResult = Set-IQServiceTraceLevel -InstallPath $resolvedPath -Level $LogLevel -TraceFile $TraceFile -RestartIfRunning
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'SetLogLevel' `
                -RestartPendingForLogLevel:([bool]$logResult.RestartPending)
        }
        'StreamLogs' {
            Show-IQServiceLogStream -InstallPath $resolvedPath -TraceFile $TraceFile -TailLines $Tail
        }
        'Unblock' {
            Write-Step 'Unblocking IQService files'
            $result = Unblock-IQServiceFiles -InstallPath $resolvedPath
            Write-Ok "Unblocked $($result.Unblocked) of $($result.Checked) file(s)"
            $remaining = [Math]::Max(0, $result.Checked - $result.Unblocked)
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Unblock' -BlockedFilesRemaining $remaining
        }
    }
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    Write-Error $_
    exit 1
}
