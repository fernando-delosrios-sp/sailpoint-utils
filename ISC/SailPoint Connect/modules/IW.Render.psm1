# SailPoint Connect: Run, Build script, Build requirements.

Set-StrictMode -Version Latest

if (-not (Get-Module -Name 'IW.Access')) {
    Import-Module (Join-Path $PSScriptRoot 'IW.Access.psm1') -Force -WarningAction SilentlyContinue
}

function Import-IntegrationProjectModule {
    if (-not (Get-Module -Name 'IW.Project')) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Project.psm1') -Force -WarningAction SilentlyContinue
    }
}

function Get-IntegrationWizardOperatorSection {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $platform = if ($Context['IntegrationPlatformTitle']) { [string]$Context['IntegrationPlatformTitle'] }
        elseif ($Definition['Platform']) { [string]$Definition['Platform'] }
        else { 'Integration' }
    $folder = if ($Definition['FolderName']) { [string]$Definition['FolderName'] } else { [string]$Definition.Title }
    return "$platform / $folder"
}

function Test-IntegrationWizardPrompts {
    param([hashtable]$Context)
    if ([bool]$Context['NonInteractive']) { return $false }
    if (Get-Command Test-OperatorNonInteractive -ErrorAction SilentlyContinue) {
        try {
            if (Test-OperatorNonInteractive) { return $false }
        }
        catch { return $false }
    }
    return $null -ne (Get-Command Read-YesNo -ErrorAction SilentlyContinue)
}

function Register-IntegrationWizardOperatorAction {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Step,
        [hashtable]$PriorById = @{}
    )
    $id = if ($Step['Id']) { [string]$Step['Id'] } else { [string]$Step.Title }
    $detail = (([string]$Step['Manual']) -replace '\s+', ' ').Trim()
    $title = [string]$Step.Title
    $previous = if ($PriorById.ContainsKey($id)) { $PriorById[$id] } else { $null }
    $done = [bool]($previous -and $previous.Done -and ([string]$previous.Detail -eq $detail))
    Write-Step $title
    Write-Info $detail
    if (Test-IntegrationWizardPrompts -Context $Context) {
        if ($done) {
            $done = Read-YesNo -Prompt 'This is already marked done. Is it still done?' -Default $true
        }
        else {
            $done = Read-YesNo -Prompt 'Have you completed this?' -Default $false
        }
    }
    $action = @{
        Section = Get-IntegrationWizardOperatorSection -Definition $Definition -Context $Context
        Id      = $id
        Title   = $title
        Detail  = $detail
        Done    = [bool]$done
    }
    $project = [string]$Context['IntegrationProjectName']
    if (-not [string]::IsNullOrWhiteSpace($project)) {
        Import-IntegrationProjectModule
        Save-IntegrationProjectOperatorAction -ProjectName $project -Action $action
    }
    if ($done) { Write-Ok "${title}: marked done" }
    else { Write-Info "${title}: still to do" }
    return $action
}

function Invoke-IntegrationWizardRun {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$WhatIfPreference
    )
    # NoSession means the operator will type values manually. Do not install or sign in.
    $needsCliLogin = $Context['ConnectionMode'] -ne 'NoSession' -and -not (Get-IntegrationWizardCliSession -CliName $Definition.CliName).SignedIn
    if ($needsCliLogin) {
        Install-IntegrationWizardCli -CliName $Definition.CliName -NonInteractive:([bool]$Context['NonInteractive'])
        Invoke-IntegrationWizardCliLogin -CliName $Definition.CliName -NonInteractive:([bool]$Context['NonInteractive'])
        $postSession = Get-IntegrationWizardCliSession -CliName $Definition.CliName
        if ($postSession.SignedIn) {
            Write-Ok "$($Definition.CliName): $($postSession.Summary)"
        }
    }
    $steps = & $Definition.Steps $Context
    $projectName = [string]$Context['IntegrationProjectName']
    $operatorSection = Get-IntegrationWizardOperatorSection -Definition $Definition -Context $Context
    $priorById = @{}
    if (-not [string]::IsNullOrWhiteSpace($projectName)) {
        Import-IntegrationProjectModule
        foreach ($existing in @(Read-IntegrationProjectOperatorActions -ProjectName $projectName)) {
            if ($existing.Section -eq $operatorSection) { $priorById[$existing.Id] = $existing }
        }
    }
    $operatorActions = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($step in @($steps)) {
        if ($step['When'] -and -not (& $step['When'] $Context)) {
            if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                Write-IntegrationProjectLogLine -Level 'INFO' -Message "Step $($step.Title): not applicable to this run"
            }
            continue
        }
        if ($step.Kind -eq 'Manual') {
            $recorded = Register-IntegrationWizardOperatorAction -Definition $Definition -Context $Context -Step $step -PriorById $priorById
            $operatorActions.Add($recorded)
            continue
        }
        if ($step.Kind -eq 'Output') { continue }
        $status = 'done'
        if ($step['Probe']) {
            $probe = & $step['Probe'] $Context
            if ($probe -eq 'Skip') {
                Write-Ok "$($step.Title): unchanged"
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'INFO' -Message "Step probe $($step.Title): unchanged (Skip)"
                }
                continue
            }
            if ($probe -eq 'Create') { $status = 'created' }
            if ($probe -eq 'Update') { $status = 'updated' }
            if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                Write-IntegrationProjectLogLine -Level 'INFO' -Message "Step probe $($step.Title): $probe"
            }
        }
        if ($step['Run']) {
            if ($WhatIfPreference) {
                Write-Host "WhatIf: would run step $($step.Title)" -ForegroundColor Yellow
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'INFO' -Message "WhatIf: would run step $($step.Title)"
                }
                continue
            }
            Write-Step $step.Title
            try {
                $outcome = & $step['Run'] $Context
                if ($outcome -eq 'blocked') { $status = 'blocked by organization policy' }
                Write-Ok "$($step.Title): $status"
            }
            catch {
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'ERROR' -Message "Step failed $($step.Title): $($_.Exception.Message)"
                }
                throw
            }
            continue
        }
        if ($step['Cli']) {
            $cliText = & $step['Cli'] $Context
            if ($WhatIfPreference) {
                Write-Host "WhatIf: would run step $($step.Title)" -ForegroundColor Yellow
                Write-Host $cliText -ForegroundColor DarkGray
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'INFO' -Message "WhatIf: would run step $($step.Title)"
                }
                continue
            }
            Write-Step $step.Title
            try {
                Invoke-Expression $cliText
                if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Step failed: $($step.Title) (exit $LASTEXITCODE)" }
                Write-Ok "$($step.Title): $status"
            }
            catch {
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'ERROR' -Message "Step failed $($step.Title): $($_.Exception.Message)"
                }
                throw
            }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($projectName)) {
        Sync-IntegrationProjectOperatorSection -ProjectName $projectName -Section $operatorSection -Actions @($operatorActions)
        if ($operatorActions.Count -gt 0) {
            $actionsPath = Get-IntegrationProjectOperatorActionsPath -ProjectName $projectName
            Write-Info "Operator actions: $actionsPath"
        }
    }
    if ($Definition['OnRunComplete']) {
        & $Definition['OnRunComplete'] $Context
    }
}

function New-IntegrationWizardBuildScript {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$OutputPath
    )
    $cli = $Definition.CliName
    $login = (Get-IntegrationWizardLoginHint -CliName $cli) -replace '^Run: ', ''
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('#Requires -Version 7')
    [void]$sb.AppendLine("# Generated by SailPoint Connect — $($Definition.Title)")
    [void]$sb.AppendLine('# SailPoint Connect only wrote this file. Running it changes the tenant.')
    [void]$sb.AppendLine('# Review it, then run it under your own change process.')
    [void]$sb.AppendLine('$ErrorActionPreference = ''Stop''')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("# Prerequisites: $cli on PATH. Sign in: $login")
    [void]$sb.AppendLine("if (-not (Get-Command $cli -ErrorAction SilentlyContinue)) { throw 'Install $cli first.' }")
    [void]$sb.AppendLine('')
    foreach ($key in ($Context.Keys | Sort-Object)) {
        if ($key -match '^(Wizard|NonInteractive|ConnectionMode|Action)$') { continue }
        $val = $Context[$key]
        if ($null -eq $val) { continue }
        if ($val -is [array]) { $val = $val -join ',' }
        $escaped = [string]$val -replace "'", "''"
        [void]$sb.AppendLine("`$$key = '$escaped'")
    }
    [void]$sb.AppendLine('')
    if ($Definition['IsComposite']) {
        foreach ($member in @($Definition.Members)) {
            [void]$sb.AppendLine("# --- $($member.Title) ---")
            [void]$sb.AppendLine('')
            if ($member['BuildScript']) {
                [void]$sb.AppendLine((& $member['BuildScript'] $Context))
                [void]$sb.AppendLine('')
            }
            else {
                $steps = & $member.Steps $Context
                $n = 0
                foreach ($step in @($steps)) {
                    if ($step.Kind -in @('Manual', 'Output')) {
                        $n++
                        [void]$sb.AppendLine("# Step $n — $($step.Title) (manual)")
                        [void]$sb.AppendLine("# $($step['Manual'])")
                        [void]$sb.AppendLine('')
                        continue
                    }
                    $n++
                    [void]$sb.AppendLine("# Step $n — $($step.Title)")
                    if ($step['BuildScript']) {
                        [void]$sb.AppendLine((& $step['BuildScript'] $Context))
                    }
                    elseif ($step['ProbeScript']) { [void]$sb.AppendLine($step['ProbeScript']) }
                    if ($step['Cli']) {
                        $cliText = & $step['Cli'] $Context
                        [void]$sb.AppendLine($cliText)
                    }
                    [void]$sb.AppendLine('')
                }
            }
        }
    }
    else {
        if ($Definition['BuildScript']) {
            [void]$sb.AppendLine((& $Definition['BuildScript'] $Context))
            [void]$sb.AppendLine('')
        }
        else {
            $steps = & $Definition.Steps $Context
            $n = 0
            foreach ($step in @($steps)) {
                if ($step.Kind -in @('Manual', 'Output')) {
                    $n++
                    [void]$sb.AppendLine("# Step $n — $($step.Title) (manual)")
                    [void]$sb.AppendLine("# $($step['Manual'])")
                    [void]$sb.AppendLine('')
                    continue
                }
                $n++
                [void]$sb.AppendLine("# Step $n — $($step.Title)")
                if ($step['BuildScript']) {
                    [void]$sb.AppendLine((& $step['BuildScript'] $Context))
                }
                elseif ($step['ProbeScript']) {
                    [void]$sb.AppendLine($step['ProbeScript'])
                }
                if ($step['Cli']) {
                    $cliText = & $step['Cli'] $Context
                    [void]$sb.AppendLine($cliText)
                }
                [void]$sb.AppendLine('')
            }
        }
    }
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $OutputPath -Value $sb.ToString() -Encoding utf8
    $displayPath = if (Get-Command Format-TerminalHyperlink -ErrorAction SilentlyContinue) {
        Format-TerminalHyperlink -Path $OutputPath
    } else {
        $OutputPath
    }
    Write-Ok "Wrote $displayPath"
    if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Wrote build script: $OutputPath"
    }
}

function New-IntegrationWizardRequirementsDoc {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$OutputPath
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Requirements: $($Definition.Title)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Generating this checklist did not change the tenant. It is the list of what the integration needs. `Check` can later read an identity you already have and report what is missing. `Run` is the only action that applies a change, and only after you confirm.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Platform: $($Definition.Platform)")
    [void]$sb.AppendLine("Product: $($Definition.Product)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Tools')
    [void]$sb.AppendLine("- ``$($Definition.CliName)`` CLI installed and signed in")
    [void]$sb.AppendLine('')
    if ($Definition['AdminRoles']) {
        [void]$sb.AppendLine('## Admin roles')
        foreach ($r in @($Definition['AdminRoles'])) { [void]$sb.AppendLine("- $r") }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('## Inputs')
    foreach ($inputDef in @($Definition.Inputs)) {
        if (-not $inputDef) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) { continue }
        [void]$sb.AppendLine("- **$($inputDef.Name)** — $($inputDef.Purpose)")
    }
    [void]$sb.AppendLine('')
    if ($Context.ContainsKey('Access') -and -not [string]::IsNullOrWhiteSpace([string]$Context['Access'])) {
        [void]$sb.AppendLine("## Access level: $($Context['Access'])")
        [void]$sb.AppendLine('')
        if ($Context['Access'] -eq 'ReadOnly') {
            [void]$sb.AppendLine('This run grants **read-only** connector permissions (aggregation and discovery). Read-write requirements are listed for planning but are not applied.')
            [void]$sb.AppendLine('')
        }
        else {
            [void]$sb.AppendLine('This run grants **read and write** connector permissions where the connector supports provisioning.')
            [void]$sb.AppendLine('')
        }
    }
    $accessLists = Get-IntegrationWizardAccessRequirementLists -Definition $Definition -Context $Context
    if ($accessLists.ReadOnly.Count -gt 0) {
        [void]$sb.AppendLine('## Read-only requirements')
        foreach ($item in $accessLists.ReadOnly) { [void]$sb.AppendLine("- ``$item``") }
        [void]$sb.AppendLine('')
    }
    if ($accessLists.ReadWrite.Count -gt 0) {
        [void]$sb.AppendLine('## Read-write requirements')
        foreach ($item in $accessLists.ReadWrite) {
            $note = if ($item -match '^logging\.queries\.(create|delete|update)$') { ' (Entro GCP pin — required for verify)' } else { '' }
            [void]$sb.AppendLine("- ``$item``$note")
        }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('## Steps')
    if ($Definition['IsComposite']) {
        foreach ($member in @($Definition.Members)) {
            [void]$sb.AppendLine("### $($member.Title)")
            [void]$sb.AppendLine('')
            $steps = & $member.Steps $Context
            $n = 0
            foreach ($step in @($steps)) {
                $n++
                [void]$sb.AppendLine("#### $n. $($step.Title)")
                if ($step.ContainsKey('Why') -and $step.Why) { [void]$sb.AppendLine($step.Why) }
                if ($step.ContainsKey('Manual') -and $step.Manual) { [void]$sb.AppendLine($step.Manual) }
                [void]$sb.AppendLine('')
            }
        }
    }
    else {
        $steps = & $Definition.Steps $Context
        $n = 0
        foreach ($step in @($steps)) {
            $n++
            [void]$sb.AppendLine("### $n. $($step.Title)")
            if ($step.ContainsKey('Why') -and $step.Why) { [void]$sb.AppendLine($step.Why) }
            if ($step.ContainsKey('Manual') -and $step.Manual) { [void]$sb.AppendLine($step.Manual) }
            [void]$sb.AppendLine('')
        }
    }
    if ($Definition['OutputsHelp']) {
        [void]$sb.AppendLine('## Outputs for ISC / Entro')
        [void]$sb.AppendLine($Definition['OutputsHelp'])
    }
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $reqContent = $sb.ToString()
    Set-Content -Path $OutputPath -Value $reqContent -Encoding utf8
    if (Get-Command Write-ReportStdout -ErrorAction SilentlyContinue) {
        Write-ReportStdout -Content $reqContent
    }
    else {
        [Console]::Out.WriteLine($reqContent.TrimEnd())
        [Console]::Out.WriteLine()
    }
    $displayPath = if (Get-Command Format-TerminalHyperlink -ErrorAction SilentlyContinue) {
        Format-TerminalHyperlink -Path $OutputPath
    } else {
        $OutputPath
    }
    Write-Ok "Wrote $displayPath"
    if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Wrote requirements doc: $OutputPath"
    }
}

function Invoke-IntegrationWizardMemberRun {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][hashtable]$Member,
        [Parameter(Mandatory)][hashtable]$Context
    )
    if ($Member['LegacyRun']) {
        & $Member['LegacyRun'] $Context -WhatIf:$WhatIfPreference
    }
    else {
        Invoke-IntegrationWizardRun -Definition $Member -Context $Context -WhatIfPreference:$WhatIfPreference
    }
    if ($Member['OnRunComplete']) {
        & $Member['OnRunComplete'] $Context
    }
}

function Invoke-IntegrationWizardAction {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $outDir = if ($Context['OutputDirectory']) { $Context['OutputDirectory'] } elseif ($Context['IntegrationFolderPath']) { $Context['IntegrationFolderPath'] } else { Join-Path (Get-Location) 'wizard-output' }
    switch ($Context['Action']) {
        'Run' {
            if ($Definition['IsComposite']) {
                foreach ($member in @($Definition.Members)) {
                    Write-Host ''
                    Write-Host "--- $($member.Title) ---" -ForegroundColor Cyan
                    Invoke-IntegrationWizardMemberRun -Member $member -Context $Context -WhatIf:$WhatIfPreference
                }
            }
            elseif ($Definition['LegacyRun']) {
                & $Definition['LegacyRun'] $Context -WhatIf:$WhatIfPreference
                if ($Definition['OnRunComplete']) { & $Definition['OnRunComplete'] $Context }
            }
            else {
                Invoke-IntegrationWizardRun -Definition $Definition -Context $Context -WhatIfPreference:$WhatIfPreference
            }
        }
        'BuildScript' {
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '.ps1'
            New-IntegrationWizardBuildScript -Definition $Definition -Context $Context -OutputPath (Join-Path $outDir $name)
        }
        'BuildRequirements' {
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-requirements.md'
            New-IntegrationWizardRequirementsDoc -Definition $Definition -Context $Context -OutputPath (Join-Path $outDir $name)
        }
        'Check' {
            Import-Module (Join-Path $PSScriptRoot 'IW.Check.psm1') -Force -WarningAction SilentlyContinue
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-check.md'
            Invoke-IntegrationRequirementCheck -Definition $Definition -Context $Context -OutputPath (Join-Path $outDir $name) -WhatIf:$WhatIfPreference
        }
        default { throw "Unknown Action: $($Context['Action'])" }
    }
}

Export-ModuleMember -Function @(
    'Invoke-IntegrationWizardRun'
    'New-IntegrationWizardBuildScript'
    'New-IntegrationWizardRequirementsDoc'
    'Invoke-IntegrationWizardAction'
)
