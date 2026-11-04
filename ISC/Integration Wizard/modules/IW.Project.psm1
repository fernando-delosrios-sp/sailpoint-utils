# Integration Wizard: working-directory projects under .integrations/

Set-StrictMode -Version Latest

$script:IntegrationProjectActivityLogPath = $null

function Get-IntegrationProjectRoot {
    Join-Path (Get-Location).Path '.integrations'
}

function Test-IntegrationProjectName {
    param([Parameter(Mandatory)][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Project name cannot be empty.' }
    if ($Name -match '[/\\]') { throw "Project name must be a single folder name (no path separators): $Name" }
    if ($Name -eq '.' -or $Name -eq '..') { throw "Invalid project name: $Name" }
}

function Get-IntegrationProjectNames {
    param([string]$Root = (Get-IntegrationProjectRoot))
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
}

function Get-IntegrationProjectLastSelected {
    param([string]$Root = (Get-IntegrationProjectRoot))
    $path = Join-Path $Root 'current.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $o = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        return [string]$o.project
    }
    catch {
        return $null
    }
}

function Set-IntegrationProjectLastSelected {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    if (-not (Test-Path -LiteralPath $Root)) {
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
    }
    $payload = [ordered]@{
        project   = $ProjectName
        updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    Set-Content -LiteralPath (Join-Path $Root 'current.json') -Value ($payload | ConvertTo-Json -Compress) -Encoding utf8
}

function Get-IntegrationWizardIntegrationFolderName {
    param([Parameter(Mandatory)][hashtable]$Definition)
    if ($Definition['IsComposite']) {
        $parts = @($Definition.Members | ForEach-Object {
            if ($_['FolderName']) { [string]$_['FolderName'] } else { [string]$_.Title }
        })
        # Folder names must stay portable: avoid '+' (not supported on every filesystem).
        return ($parts -join ' and ')
    }
    if ($Definition['FolderName']) { return [string]$Definition['FolderName'] }
    return [string]$Definition.Title
}

function Select-IntegrationProjectName {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$Preset,
        [switch]$NonInteractive
    )
    if ($Preset) {
        Test-IntegrationProjectName -Name $Preset
        $projPath = Join-Path $Root $Preset
        if (-not (Test-Path -LiteralPath $projPath)) {
            New-Item -ItemType Directory -Path $projPath -Force | Out-Null
            Write-IntegrationProjectLogLine -Level 'INFO' -Message "Created project folder: $projPath"
        }
        return $Preset
    }
    if ($NonInteractive) {
        $existing = @(Get-IntegrationProjectNames -Root $Root)
        $list = if ($existing.Count -gt 0) { ($existing -join ', ') } else { '(none)' }
        throw "Non-interactive run requires -Project. Existing projects under .integrations/: $list"
    }
    $existing = @(Get-IntegrationProjectNames -Root $Root)
    $last = Get-IntegrationProjectLastSelected -Root $Root
    $createToken = '__create_new__'
    $options = @($existing) + @($createToken)
    $labels = @($existing) + @('Create a new project')
    $default = $createToken
    if ($last -and ($existing -contains $last)) { $default = $last }
    elseif ($existing.Count -gt 0) { $default = $existing[0] }
    if (Get-Command Write-Step -ErrorAction SilentlyContinue) {
        Write-Step 'Integration project workspace (.integrations/)'
    }
    $picked = Read-Choice -Prompt 'Which integration project?' -Options $options -Labels $labels -Default $default
    if ($picked -eq $createToken) {
        $name = Read-InputString -Prompt 'New project name' -Required
        Test-IntegrationProjectName -Name $name
        $projPath = Join-Path $Root $name
        New-Item -ItemType Directory -Path $projPath -Force | Out-Null
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Created project folder: $projPath"
        return $name
    }
    return $picked
}

function Get-IntegrationProjectSelectionSnapshot {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ScriptName
    )
    $inputs = [ordered]@{}
    foreach ($input in @($Definition.Inputs)) {
        if (-not $input) { continue }
        if (-not (Get-Command Test-IntegrationWizardInputWhen -ErrorAction SilentlyContinue)) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $name = $input.Name
        if ($input['Secret']) {
            $inputs[$name] = '***'
            continue
        }
        $val = $Context[$name]
        if ($null -eq $val) { continue }
        if ($val -is [array]) { $val = $val -join ',' }
        $inputs[$name] = [string]$val
    }
    [ordered]@{
        timestamp         = (Get-Date).ToUniversalTime().ToString('o')
        project           = [string]$Context['IntegrationProjectName']
        platform          = $Platform
        integrationFolder = Get-IntegrationWizardIntegrationFolderName -Definition $Definition
        script            = $ScriptName
        target            = [string]$Definition.Title
        action            = [string]$Context['Action']
        outputDirectory   = [string]$Context['OutputDirectory']
        outputOverride    = [bool]$Context['IntegrationOutputOverride']
        integrationPath   = [string]$Context['IntegrationFolderPath']
        inputs            = $inputs
    }
}

function Write-IntegrationProjectSelection {
    param(
        [Parameter(Mandatory)][hashtable]$Record,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $project = [string]$Record.project
    if ([string]::IsNullOrWhiteSpace($project)) { return }
    $projRoot = Join-Path $Root $project
    if (-not (Test-Path -LiteralPath $projRoot)) {
        New-Item -ItemType Directory -Path $projRoot -Force | Out-Null
    }
    $json = $Record | ConvertTo-Json -Depth 8 -Compress:$false
    Set-Content -LiteralPath (Join-Path $projRoot 'selection.json') -Value $json -Encoding utf8
    Add-Content -LiteralPath (Join-Path $projRoot 'selections.jsonl') -Value ($Record | ConvertTo-Json -Depth 8 -Compress) -Encoding utf8
}

function Initialize-IntegrationProjectActivityLog {
    param([Parameter(Mandatory)][string]$LogPath)
    $dir = Split-Path -Parent $LogPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $script:IntegrationProjectActivityLogPath = $LogPath
    Write-IntegrationProjectLogLine -Level 'INFO' -Message "Activity log opened: $LogPath"
}

function Close-IntegrationProjectActivityLog {
    if ($script:IntegrationProjectActivityLogPath) {
        Write-IntegrationProjectLogLine -Level 'INFO' -Message 'Activity log closed.'
    }
    $script:IntegrationProjectActivityLogPath = $null
}

function Write-IntegrationProjectLogLine {
    param(
        [ValidateSet('STEP', 'OK', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',
        [Parameter(Mandatory)][string]$Message
    )
    $path = $script:IntegrationProjectActivityLogPath
    if (-not $path) { return }
    $line = '{0} [{1}] {2}' -f (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'), $Level, $Message
    Add-Content -LiteralPath $path -Value $line -Encoding utf8
}

function Select-IntegrationProjectWorkspace {
    param([Parameter(Mandatory)][hashtable]$Context)
    if (-not [string]::IsNullOrWhiteSpace([string]$Context['IntegrationProjectName'])) { return }

    $root = Get-IntegrationProjectRoot
    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    $preset = if ($Context['Project']) { [string]$Context['Project'] } else { $null }
    $projectName = Select-IntegrationProjectName -Root $root -Preset $preset -NonInteractive:([bool]$Context['NonInteractive'])
    Set-IntegrationProjectLastSelected -ProjectName $projectName -Root $root

    $projPath = Join-Path $root $projectName
    if (-not (Test-Path -LiteralPath $projPath)) {
        New-Item -ItemType Directory -Path $projPath -Force | Out-Null
    }

    $Context['IntegrationProjectName'] = $projectName
    if (Get-Command Write-Ok -ErrorAction SilentlyContinue) {
        Write-Ok "Using project: $projectName ($projPath)"
    }
}

function Initialize-IntegrationProjectContext {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$PlatformTitle,
        [Parameter(Mandatory)][hashtable]$Plan,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$ScriptName
    )
    $platformTitle = $PlatformTitle

    $root = Get-IntegrationProjectRoot
    if (-not (Test-Path -LiteralPath $root)) {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace([string]$Context['IntegrationProjectName'])) {
        Select-IntegrationProjectWorkspace -Context $Context
    }
    $projectName = [string]$Context['IntegrationProjectName']

    $folderName = Get-IntegrationWizardIntegrationFolderName -Definition $Plan
    $integrationPath = Join-Path (Join-Path (Join-Path $root $projectName) $platformTitle) $folderName
    if (-not (Test-Path -LiteralPath $integrationPath)) {
        New-Item -ItemType Directory -Path $integrationPath -Force | Out-Null
    }

    $outputOverride = -not [string]::IsNullOrWhiteSpace([string]$Context['OutputDirectory'])
    if (-not $outputOverride) {
        $Context['OutputDirectory'] = $integrationPath
    }

    $Context['IntegrationProjectName'] = $projectName
    $Context['IntegrationFolderPath'] = $integrationPath
    $Context['IntegrationOutputOverride'] = $outputOverride
    $Context['IntegrationPlatformTitle'] = $platformTitle
    $Context['IntegrationFolderName'] = $folderName

    $logPath = Join-Path $integrationPath 'activity.log'
    Initialize-IntegrationProjectActivityLog -LogPath $logPath

    Write-IntegrationProjectLogLine -Level 'INFO' -Message "Project: $projectName"
    Write-IntegrationProjectLogLine -Level 'INFO' -Message "Integration folder: $integrationPath"
    Write-IntegrationProjectLogLine -Level 'INFO' -Message "Target: $($Plan.Title)"
    if ($outputOverride) {
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Output directory override: $($Context['OutputDirectory'])"
    }

    if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
        Write-Info "Project: $projectName"
        Write-Info "Artifacts: $integrationPath"
        if ($outputOverride) {
            Write-Info "Output override: $($Context['OutputDirectory'])"
        }
    }
}

function Get-IntegrationProjectOperatorActionsPath {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    Join-Path (Join-Path $Root $ProjectName) 'operator-actions.md'
}

function Read-IntegrationProjectOperatorActions {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $path = Get-IntegrationProjectOperatorActionsPath -ProjectName $ProjectName -Root $Root
    $actions = [System.Collections.Generic.List[hashtable]]::new()
    if (-not (Test-Path -LiteralPath $path)) { return @($actions) }
    $section = $null
    foreach ($line in Get-Content -LiteralPath $path) {
        if ($line -match '^## (.+)$') {
            $section = $Matches[1].Trim()
            continue
        }
        if (-not $section) { continue }
        if ($line -match '^- \[(?<mark>[ xX])\] \*\*(?<title>.*?)\*\* \(`(?<id>[^`]+)`\) - (?<detail>.*)$') {
            $actions.Add(@{
                Section = $section
                Id      = $Matches['id']
                Title   = $Matches['title']
                Detail  = $Matches['detail']
                Done    = $Matches['mark'] -eq 'x' -or $Matches['mark'] -eq 'X'
            })
        }
    }
    return @($actions)
}

function Write-IntegrationProjectOperatorActions {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [AllowEmptyCollection()][hashtable[]]$Actions = @(),
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $path = Get-IntegrationProjectOperatorActionsPath -ProjectName $ProjectName -Root $Root
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Operator actions')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Actions the wizard cannot finish for you. A run updates its own section and leaves the others in place.')
    [void]$sb.AppendLine('')
    $order = [System.Collections.Generic.List[string]]::new()
    $bySection = @{}
    foreach ($action in @($Actions)) {
        if (-not $action) { continue }
        $name = [string]$action.Section
        if (-not $bySection.ContainsKey($name)) {
            $order.Add($name)
            $bySection[$name] = [System.Collections.Generic.List[hashtable]]::new()
        }
        $bySection[$name].Add($action)
    }
    foreach ($name in $order) {
        [void]$sb.AppendLine("## $name")
        [void]$sb.AppendLine('')
        foreach ($action in $bySection[$name]) {
            $mark = if ($action.Done) { 'x' } else { ' ' }
            $detail = ([string]$action.Detail) -replace '\s+', ' '
            [void]$sb.AppendLine("- [$mark] **$($action.Title)** (``$($action.Id)``) - $($detail.Trim())")
        }
        [void]$sb.AppendLine('')
    }
    Set-Content -LiteralPath $path -Value $sb.ToString().TrimEnd() -Encoding utf8
    Add-Content -LiteralPath $path -Value '' -Encoding utf8
}

function Save-IntegrationProjectOperatorAction {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][hashtable]$Action,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $all = [System.Collections.Generic.List[hashtable]]::new()
    $replaced = $false
    foreach ($existing in @(Read-IntegrationProjectOperatorActions -ProjectName $ProjectName -Root $Root)) {
        if ($existing.Section -eq $Action.Section -and $existing.Id -eq $Action.Id) {
            $all.Add($Action)
            $replaced = $true
        }
        else { $all.Add($existing) }
    }
    if (-not $replaced) { $all.Add($Action) }
    Write-IntegrationProjectOperatorActions -ProjectName $ProjectName -Actions @($all) -Root $Root
}

function Sync-IntegrationProjectOperatorSection {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$Section,
        [AllowEmptyCollection()][hashtable[]]$Actions = @(),
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $kept = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($existing in @(Read-IntegrationProjectOperatorActions -ProjectName $ProjectName -Root $Root)) {
        if ($existing.Section -ne $Section) { $kept.Add($existing) }
    }
    foreach ($action in @($Actions)) {
        if (-not $action) { continue }
        $action.Section = $Section
        $kept.Add($action)
    }
    $path = Get-IntegrationProjectOperatorActionsPath -ProjectName $ProjectName -Root $Root
    if ($kept.Count -eq 0 -and -not (Test-Path -LiteralPath $path)) { return }
    Write-IntegrationProjectOperatorActions -ProjectName $ProjectName -Actions @($kept) -Root $Root
}

function Test-IntegrationWizardNeedsProjectContext {
    param(
        [switch]$Wizard,
        [hashtable]$Context
    )
    if ($Wizard) { return $true }
    return -not [string]::IsNullOrWhiteSpace([string]$Context['Action'])
}

Export-ModuleMember -Function @(
    'Get-IntegrationProjectRoot'
    'Test-IntegrationProjectName'
    'Get-IntegrationProjectNames'
    'Get-IntegrationProjectLastSelected'
    'Set-IntegrationProjectLastSelected'
    'Get-IntegrationWizardIntegrationFolderName'
    'Select-IntegrationProjectName'
    'Select-IntegrationProjectWorkspace'
    'Get-IntegrationProjectSelectionSnapshot'
    'Write-IntegrationProjectSelection'
    'Initialize-IntegrationProjectActivityLog'
    'Close-IntegrationProjectActivityLog'
    'Write-IntegrationProjectLogLine'
    'Initialize-IntegrationProjectContext'
    'Test-IntegrationWizardNeedsProjectContext'
    'Get-IntegrationProjectOperatorActionsPath'
    'Read-IntegrationProjectOperatorActions'
    'Write-IntegrationProjectOperatorActions'
    'Save-IntegrationProjectOperatorAction'
    'Sync-IntegrationProjectOperatorSection'
)
