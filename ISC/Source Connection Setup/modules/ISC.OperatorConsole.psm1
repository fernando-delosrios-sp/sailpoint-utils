#Requires -Version 5.1
Set-StrictMode -Version Latest

function Import-IscModule {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force,
        [switch]$Global = $true
    )

    $importParams = @{
        Name          = $Path
        WarningAction = 'SilentlyContinue'
        Global        = [bool]$Global
    }
    if ($Force) { $importParams['Force'] = $true }
    Import-Module @importParams
}

function Initialize-OperatorConsole {
    param([switch]$NonInteractive)

    $script:NonInteractive = [bool]$NonInteractive
    $script:MenuFallbackReported = $false
    $script:MenuBlockerDetail = 'the console window is too short'
    $script:PromptCount = 0
    $script:WizardCursor = 0
    $script:WizardResume = 0
    $script:WizardStep = -1
    $script:WizardStepPromptCount = 0
    $script:WizardAskedSteps = @{}
    $script:InWizardPrompt = $false
}

$script:Esc = [char]27
$script:AnsiEraseLine = "$([char]27)[K"
$script:PromptBackToken = 'PROMPT_BACK'

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

function Write-ConnectionSettings {
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Fields,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Path
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $Fields.Keys) {
        $lines.Add("### $name")
        $lines.Add([string]$Fields[$name])
        $lines.Add('')
    }
    Set-Content -LiteralPath $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Ok "Saved $Title to $Path"
}

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

function Test-CancelledNavigation {
    param($ErrorRecord)
    if (Test-PromptBack $ErrorRecord) { return $true }
    return $ErrorRecord.Exception -is [System.Management.Automation.PipelineStoppedException]
}

function Get-ConsoleMenuBlocker {
    if ($script:NonInteractive) { return 'non-interactive mode' }
    if ($Host.Name -eq 'Windows PowerShell ISE Host') { return 'the ISE cannot read single keystrokes' }

    if ($Host.Name -eq 'ConsoleHost') {
        try { $null = [Console]::KeyAvailable }
        catch { return 'this console cannot read single keystrokes' }

        try { if ([Console]::IsOutputRedirected) { return 'console output is redirected' } } catch { }
    }

    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -ne 'Unix') {
        $vt = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
        if ($vt -and -not $vt.Value) { return 'this console does not support virtual terminal sequences' }
    }

    return $null
}

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
        33      { 'PageUp' }
        34      { 'PageDown' }
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

    if ($script:NonInteractive -or -not $Reason -or $script:MenuFallbackReported) { return }
    $script:MenuFallbackReported = $true
    Write-Info "Arrow-key menus are unavailable here ($Reason); using numbered prompts."
}

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

# A label carrying newlines or tabs would print taller or wider than the row count the redraw
# moves back over, leaving a stale copy of the menu behind on every keystroke.
function ConvertTo-MenuLine {
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return '' }
    return ($Text -replace '[\r\n\t]+', ' ')
}

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

    $Prompt = ConvertTo-MenuLine $Prompt
    $Labels = @(foreach ($label in $Labels) { ConvertTo-MenuLine $label })

    $selected = New-Object 'bool[]' $count
    $cursor = [Math]::Min([Math]::Max($InitialIndex, 0), $count - 1)
    $hint = if ($MultiSelect) {
        'Up/Down move   Space select   A all   N none   PgUp/PgDn page   Enter confirm   Esc back   Ctrl+C exit'
    }
    elseif ($EscapeMeansDefault) {
        'Up/Down move   Enter select   Esc done   Ctrl+C exit'
    }
    else {
        'Up/Down move   Enter select   Esc back   Ctrl+C exit'
    }

    # Scroll long lists instead of falling back to numbered prompts.
    # Chrome: prompt + hint + status line; keep a usable viewport in short terminals.
    $chromeRows = 3
    $windowHeight = (Get-MenuWindowSize).Height
    $minWindow = 8
    if ($windowHeight -gt 0 -and $windowHeight -lt $minWindow) {
        $script:MenuBlockerDetail = "the console is $windowHeight rows tall (need at least $minWindow)"
        return $null
    }

    $maxBody = if ($windowHeight -gt 0) {
        [Math]::Max(3, $windowHeight - $chromeRows - 1)
    }
    else {
        $count
    }
    $pageSize = [Math]::Min($count, $maxBody)
    $rows = $chromeRows + $pageSize
    $scrollTop = [ref]0

    $ensureCursorVisible = {
        if ($cursor -lt $scrollTop.Value) {
            $scrollTop.Value = $cursor
        }
        elseif ($cursor -ge ($scrollTop.Value + $pageSize)) {
            $scrollTop.Value = $cursor - $pageSize + 1
        }
        if ($scrollTop.Value -lt 0) { $scrollTop.Value = 0 }
        $maxTop = [Math]::Max(0, $count - $pageSize)
        if ($scrollTop.Value -gt $maxTop) { $scrollTop.Value = $maxTop }
    }

    $drawn = $false
    $draw = {
        . $ensureCursorVisible
        $top = $scrollTop.Value
        $width = Get-MenuWidth
        if ($drawn) { Write-Host ("{0}[{1}A" -f $script:Esc, $rows) -NoNewline }
        $drawn = $true

        $from = $top + 1
        $to = [Math]::Min($top + $pageSize, $count)
        $status = if ($count -gt $pageSize) {
            "   showing $from-$to of $count   (scroll with Up/Down)"
        }
        else {
            "   $count option$(if ($count -eq 1) { '' } else { 's' })"
        }

        $lines = @(, @($Prompt, [System.ConsoleColor]::White))
        $lines += , @("   $hint", [System.ConsoleColor]::DarkGray)
        $lines += , @($status, [System.ConsoleColor]::DarkGray)

        for ($i = $top; $i -lt ($top + $pageSize) -and $i -lt $count; $i++) {
            $marker = if ($i -eq $cursor) { '>' } else { ' ' }
            $box = if ($MultiSelect) { if ($selected[$i]) { '[x] ' } else { '[ ] ' } } else { '' }
            $color = if ($i -eq $cursor) { [System.ConsoleColor]::Cyan }
                elseif ($MultiSelect -and $selected[$i]) { [System.ConsoleColor]::Green }
                else { [System.ConsoleColor]::Gray }
            $lines += , @(("  {0} {1}{2}" -f $marker, $box, $Labels[$i]), $color)
        }
        # Pad to fixed height when the last page is short (keeps ANSI cursor math stable).
        while ($lines.Count -lt $rows) {
            $lines += , @('', [System.ConsoleColor]::Gray)
        }

        foreach ($line in $lines) {
            $text = $line[0]
            if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
            Write-Host ($text + $script:AnsiEraseLine) -ForegroundColor $line[1]
        }
    }

    try {
        try { [Console]::CursorVisible = $false } catch { }

        while ($true) {
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
            elseif ($key.Name -eq 'PageUp') {
                $cursor = [Math]::Max(0, $cursor - $pageSize)
            }
            elseif ($key.Name -eq 'PageDown') {
                $cursor = [Math]::Min($count - 1, $cursor + $pageSize)
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

    if ($script:NonInteractive) {
        if ($Required -and [string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a value for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
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
    if ($Labels.Count -ne $Options.Count) {
        throw "Read-Choice requires Labels and Options to have the same length (Labels=$($Labels.Count), Options=$($Options.Count)). If you passed a single string as -Options, wrap it as [string[]]@(...). "
    }
    if ($script:NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a choice for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
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

function Read-MultiChoice {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Options,
        [Parameter(Mandatory)][string]$Prompt,
        [AllowEmptyCollection()][AllowEmptyString()][string[]]$Labels
    )

    $Options = [string[]]@($Options)
    if (-not $Labels) { $Labels = $Options }
    else { $Labels = [string[]]@($Labels) }
    if ($Labels.Count -ne $Options.Count) {
        throw "Read-MultiChoice requires Labels and Options to have the same length (Labels=$($Labels.Count), Options=$($Options.Count))."
    }
    if ($Options.Count -eq 0 -or ($Options | Where-Object { [string]::IsNullOrWhiteSpace($_) })) {
        throw 'Read-MultiChoice requires non-empty option values (a lone empty string often means entitlement ids failed to resolve).'
    }
    if ($script:NonInteractive) { return @() }

    $script:PromptCount++
    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $Labels -MultiSelect
        if ($null -ne $picked) {
            return @(@($picked) | ForEach-Object { $Options[$_] })
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("    {0}) {1}" -f ($i + 1), $Labels[$i])
    }

    while ($true) {
        $raw = Read-Host "Select numbers separated by commas, Enter for none, or b to go back"
        if ($raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

        $selected = [System.Collections.Generic.List[string]]::new()
        $valid = $true
        foreach ($token in ($raw -split ',')) {
            $n = 0
            if ([int]::TryParse($token.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
                if (-not $selected.Contains($Options[$n - 1])) { $selected.Add($Options[$n - 1]) }
            }
            else {
                $valid = $false
                break
            }
        }
        if ($valid) { return $selected.ToArray() }
        Write-Host '   Enter numbers from the list, separated by commas.' -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [bool]$Default = $true
    )

    if ($script:NonInteractive) { return $Default }

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
        $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
        if ($platform -eq 'Unix') {
            $opener = if (Get-Command open -ErrorAction SilentlyContinue) { 'open' } else { 'xdg-open' }
            Start-Process $opener $Url -ErrorAction Stop | Out-Null
        }
        else {
            Start-Process $Url -ErrorAction Stop | Out-Null
        }
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
    $Value = ConvertTo-MenuLine $Value
    if ($Value.Length -le 72) { return $Value }
    return ($Value.Substring(0, 69) + '...')
}

function Get-CompletionSaveToDiskLabel {
    param([string]$Path)

    $name = if ([string]::IsNullOrWhiteSpace($Path)) { 'results.txt' } else { Split-Path -Leaf $Path }
    return "Save to disk ($name)"
}

function Get-CompletionActionMenuChoices {
    param(
        [Parameter(Mandatory)][object[]]$Items,
        [switch]$AllowSaveToDisk,
        [string]$SavePath
    )

    $labels = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $Items) {
        $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
        $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
        $labels.Add(('{0}: {1} ({2})' -f $item.Label, $preview, $verb))
    }
    if ($AllowSaveToDisk) {
        $labels.Add((Get-CompletionSaveToDiskLabel -Path $SavePath))
    }
    $labels.Add('Done')
    return $labels.ToArray()
}

function Protect-CompletionResultsFile {
    param([Parameter(Mandatory)][string]$Path)

    $onWindows = $false
    if ($PSVersionTable.PSObject.Properties['Platform']) {
        $onWindows = $PSVersionTable.Platform -eq 'Win32NT'
    }
    elseif ($env:OS -like 'Windows*') {
        $onWindows = $true
    }

    if ($onWindows) {
        $acl = Get-Acl -LiteralPath $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
            'FullControl',
            'Allow'
        )
        $acl.SetAccessRule($rule)
        $acl | Set-Acl -LiteralPath $Path
    }
    else {
        & chmod 600 $Path
    }
}

function Save-CompletionResultsToDisk {
    param(
        [Parameter(Mandatory)][object[]]$Items,
        [Parameter(Mandatory)][string]$Path,
        [string]$Title,
        [string[]]$Situation
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    if ($Title) {
        $lines.Add("### $Title")
        $lines.Add('')
    }
    foreach ($line in @($Situation)) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $lines.Add($line)
        }
    }
    if ($lines.Count -gt 0) {
        $lines.Add('')
    }

    foreach ($item in $Items) {
        $lines.Add("### $($item.Label)")
        $lines.Add([string]$item.Value)
        $lines.Add('')
    }

    Set-Content -LiteralPath $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Protect-CompletionResultsFile -Path $Path
    Write-Ok "Saved results (secrets included) to $Path"
    return $Path
}

function Write-CompletionSummary {
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

    if ($Items.Count -eq 0) { return }

    Write-Host ''
    $labelWidth = ($Items | ForEach-Object { ([string]$_.Label).Length } | Measure-Object -Maximum).Maximum
    foreach ($item in $Items) {
        $valueLines = @(([string]$item.Value) -split "`r?`n")
        Write-Host ("  {0} : {1}" -f ([string]$item.Label).PadRight($labelWidth), $valueLines[0]) -ForegroundColor Yellow
        foreach ($extra in ($valueLines | Select-Object -Skip 1)) {
            Write-Host ("  {0}   {1}" -f (' ' * $labelWidth), $extra.Trim()) -ForegroundColor Yellow
        }
    }
}

function Invoke-CompletionActionMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string[]]$Situation,
        [Parameter(Mandatory)][object[]]$Items,
        [string]$Instruction = 'Copy each value into the matching ISC Connection Settings field, or open a link to finish pending manual steps.',
        [switch]$AllowSaveToDisk,
        [string]$SavePath
    )

    Write-Host ''
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * [Math]::Min($Title.Length, 60))) -ForegroundColor Cyan
    foreach ($line in $Situation) {
        Write-Host "  $line" -ForegroundColor White
    }
    Write-Host ''
    Write-Host "  $Instruction" -ForegroundColor Yellow

    if ($Items.Count -eq 0) { return }

    if ($script:NonInteractive) {
        Write-Host ''
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            Write-Host "  $($item.Label): $preview ($verb)" -ForegroundColor Yellow
        }
        return
    }

    $doneLabel = 'Done'
    $saveLabel = Get-CompletionSaveToDiskLabel -Path $SavePath
    while ($true) {
        $labels = @(Get-CompletionActionMenuChoices -Items $Items -AllowSaveToDisk:$AllowSaveToDisk -SavePath $SavePath)

        $picked = Read-Choice -Prompt 'Select a value to copy or a link to open:' `
            -Options $labels `
            -Default $doneLabel `
            -EscapeMeansDefault
        if ($picked -eq $doneLabel) { return }

        if ($AllowSaveToDisk -and $picked -eq $saveLabel) {
            $defaultPath = $SavePath
            try {
                $path = Read-InputString -Prompt 'File path for results (secrets included)' -Default $defaultPath -Required
            }
            catch {
                if (Test-PromptBack $_) { continue }
                throw
            }
            Save-CompletionResultsToDisk -Items $Items -Path $path -Title $Title -Situation $Situation | Out-Null
            continue
        }

        $index = [array]::IndexOf($labels, $picked)
        if ($index -lt 0 -or $index -ge $Items.Count) { continue }

        $selected = $Items[$index]
        if ($selected.Kind -eq 'Open') {
            if (Open-Url -Url ([string]$selected.Value)) {
                Write-Ok "Opened $($selected.Label)"
            }
            else {
                Write-Warning "Could not open a browser. URL: $($selected.Value)"
            }
        }
        else {
            if (Copy-ToClipboard -Text ([string]$selected.Value)) {
                Write-Ok "$($selected.Label) copied to the clipboard"
            }
            else {
                Write-Warning 'No clipboard tool is available (Set-Clipboard, pbcopy, wl-copy, or xclip). Copy from the list above.'
            }
        }
    }
}

Export-ModuleMember -Function @(
    'Import-IscModule'
    'Initialize-OperatorConsole'
    'Write-Step'
    'Write-Ok'
    'Write-Info'
    'Write-ConnectionSettings'
    'Test-PromptBack'
    'Invoke-PromptBack'
    'Invoke-PromptExit'
    'Start-WizardPass'
    'Enter-WizardPrompt'
    'Complete-WizardPrompt'
    'Move-WizardBack'
    'Test-CancelledNavigation'
    'Get-ConsoleMenuBlocker'
    'Invoke-ConsoleMenu'
    'Read-TypedLine'
    'Read-InputString'
    'Read-Choice'
    'Read-MultiChoice'
    'Read-YesNo'
    'Copy-ToClipboard'
    'Open-Url'
    'Get-MaskedSecretDisplay'
    'Get-CompletionPreview'
    'Get-CompletionSaveToDiskLabel'
    'Get-CompletionActionMenuChoices'
    'Save-CompletionResultsToDisk'
    'Write-CompletionSummary'
    'Invoke-CompletionActionMenu'
    'ConvertTo-MenuLine'
)
