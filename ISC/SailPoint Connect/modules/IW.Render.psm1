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
    $targetHost = if (Get-Command Resolve-IntegrationWizardTargetHost -ErrorAction SilentlyContinue) {
        Resolve-IntegrationWizardTargetHost -Definition $Definition -Context $Context
    } elseif ($Definition.ContainsKey('TargetHost')) { $Definition['TargetHost'] } else { $null }
    if ($targetHost -and $targetHost['Role']) {
        Write-Info "Target host: $($targetHost['Role'])"
        if ($targetHost['Notes']) { Write-Info ([string]$targetHost['Notes']) }
    }
    if ($targetHost -and $targetHost['Assert'] -and -not $WhatIfPreference) {
        & $targetHost['Assert'] $Context
    }
    # NoSession means the operator will type values manually. Do not install or sign in.
    $needsCliLogin = ($Definition.CliName -ne 'pwsh') -and $Context['ConnectionMode'] -ne 'NoSession' -and -not (Get-IntegrationWizardCliSession -CliName $Definition.CliName).SignedIn
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
            $cliResult = if ($step['Cli'] -is [scriptblock]) { & $step['Cli'] $Context } else { $step['Cli'] }
            $cliDisplay = if ($cliResult -is [scriptblock]) { $cliResult.ToString() } else { [string]$cliResult }
            if ($WhatIfPreference) {
                Write-Host "WhatIf: would run step $($step.Title)" -ForegroundColor Yellow
                Write-Host $cliDisplay -ForegroundColor DarkGray
                if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                    Write-IntegrationProjectLogLine -Level 'INFO' -Message "WhatIf: would run step $($step.Title)"
                }
                continue
            }
            Write-Step $step.Title
            try {
                $global:LASTEXITCODE = 0
                $cmdOutput = if ($cliResult -is [scriptblock]) {
                    & $cliResult
                }
                elseif ($cliResult -is [string]) {
                    $scriptBlock = [scriptblock]::Create($cliResult)
                    & $scriptBlock
                }
                if ($global:LASTEXITCODE -and $global:LASTEXITCODE -ne 0) {
                    $detail = if ($cmdOutput) { " Output: $($cmdOutput | Out-String)" } else { "" }
                    throw "Step failed: $($step.Title) (exit $global:LASTEXITCODE).$detail"
                }
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
    $cli = if (Get-Command Get-IntegrationWizardEffectiveCliName -ErrorAction SilentlyContinue) {
        Get-IntegrationWizardEffectiveCliName -Platform ([string]$Definition.Platform) -Definition $Definition
    } else {
        [string]$Definition.CliName
    }
    $targetHost = if (Get-Command Resolve-IntegrationWizardTargetHost -ErrorAction SilentlyContinue) {
        Resolve-IntegrationWizardTargetHost -Definition $Definition -Context $Context
    } elseif ($Definition.ContainsKey('TargetHost')) { $Definition['TargetHost'] } else { $null }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('#Requires -Version 7')
    [void]$sb.AppendLine("# Generated by SailPoint Connect — $($Definition.Title)")
    if ($Definition['OutpostDefinition']) {
        [void]$sb.AppendLine('# SailPoint Connect only wrote this file. Running it modifies the target host or cluster.')
    }
    else {
        [void]$sb.AppendLine('# SailPoint Connect only wrote this file. Running it changes the tenant.')
    }
    [void]$sb.AppendLine('# Review it, then run it under your own change process.')
    if ($targetHost -and $targetHost['Role']) {
        [void]$sb.AppendLine("# Target Host: $($targetHost['Role'])")
        if ($targetHost['Notes']) { [void]$sb.AppendLine("# Host Note: $($targetHost['Notes'])") }
    }
    [void]$sb.AppendLine('$ErrorActionPreference = ''Stop''')
    [void]$sb.AppendLine('')
    if ($cli -eq 'pwsh') {
        [void]$sb.AppendLine('# Runtime: PowerShell 7+ (pwsh) on the target host')
        if ($Definition['RequiredTools'] -and @($Definition['RequiredTools']).Count -gt 0) {
            [void]$sb.AppendLine("# Required tools: $(@($Definition['RequiredTools']) -join ', ')")
        }
    }
    else {
        $login = (Get-IntegrationWizardLoginHint -CliName $cli) -replace '^Run: ', ''
        [void]$sb.AppendLine("# Prerequisites: $cli on PATH. Sign in: $login")
        [void]$sb.AppendLine("if (-not (Get-Command $cli -ErrorAction SilentlyContinue)) { throw 'Install $cli first.' }")
    }
    [void]$sb.AppendLine('')
    $secretInputNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($inp in @($Definition.Inputs)) {
        if ($inp -and ($inp['Secret'] -or $inp.Name -match '(?i)^(CrPat|AwsSecretAccessKey|EntroPassword)$')) {
            [void]$secretInputNames.Add([string]$inp.Name)
        }
    }
    foreach ($key in ($Context.Keys | Sort-Object)) {
        if ($key -match '^(Wizard|NonInteractive|ConnectionMode|Action)$') { continue }
        if ($secretInputNames.Contains([string]$key)) {
            [void]$sb.AppendLine("# `$$key omitted from generated script; provide via `$env:$key or prompt at runtime.")
            [void]$sb.AppendLine("`$$key = `$env:$key")
            continue
        }
        $val = $Context[$key]
        if ($null -eq $val) { continue }
        if ($val -is [array]) { $val = $val -join ',' }
        $escaped = [string]$val -replace "'", "''"
        [void]$sb.AppendLine("`$$key = '$escaped'")
    }
    [void]$sb.AppendLine('')
    if ($targetHost -and $targetHost['AssertScript']) {
        $assertText = if ($targetHost['AssertScript'] -is [scriptblock]) {
            & $targetHost['AssertScript'] $Context
        } else {
            [string]$targetHost['AssertScript']
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$assertText)) {
            [void]$sb.AppendLine(([string]$assertText).TrimEnd())
            [void]$sb.AppendLine('')
        }
    }
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
    $cli = if (Get-Command Get-IntegrationWizardEffectiveCliName -ErrorAction SilentlyContinue) {
        Get-IntegrationWizardEffectiveCliName -Platform ([string]$Definition.Platform) -Definition $Definition
    } else {
        [string]$Definition.CliName
    }
    $targetHost = if (Get-Command Resolve-IntegrationWizardTargetHost -ErrorAction SilentlyContinue) {
        Resolve-IntegrationWizardTargetHost -Definition $Definition -Context $Context
    } elseif ($Definition.ContainsKey('TargetHost')) { $Definition['TargetHost'] } else { $null }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Requirements: $($Definition.Title)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Generating this checklist did not change the tenant. It is the list of what the integration needs. `Check` can later read an identity you already have and report what is missing. `Run` is the only action that applies a change, and only after you confirm.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Platform: $($Definition.Platform)")
    [void]$sb.AppendLine("Product: $($Definition.Product)")
    [void]$sb.AppendLine('')
    if ($targetHost -and $targetHost['Role']) {
        [void]$sb.AppendLine('## Target host')
        [void]$sb.AppendLine("- Role: $($targetHost['Role'])")
        if ($targetHost['Notes']) { [void]$sb.AppendLine("- Notes: $($targetHost['Notes'])") }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('## Tools')
    if ($cli -eq 'pwsh') {
        [void]$sb.AppendLine('- PowerShell 7+ (`pwsh`) on target host')
        foreach ($tool in @($Definition['RequiredTools'])) {
            if (-not [string]::IsNullOrWhiteSpace([string]$tool)) {
                [void]$sb.AppendLine("- ``$tool`` on target host")
            }
        }
    }
    else {
        [void]$sb.AppendLine("- ``$cli`` CLI installed and signed in")
        foreach ($tool in @($Definition['RequiredTools'])) {
            if (-not [string]::IsNullOrWhiteSpace([string]$tool)) {
                [void]$sb.AppendLine("- ``$tool``")
            }
        }
    }
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
    $isJson = [string]$Context['OutputFormat'] -eq 'Json'
    $result = $null

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
            $result = [PSCustomObject]@{
                Status          = 'Success'
                Action          = 'Run'
                Platform        = [string]$Definition.Platform
                Target          = [string]$Definition.Title
                OutputDirectory = [string]$Context['OutputDirectory']
                Project         = [string]$Context['IntegrationProjectName']
            }
        }
        'BuildScript' {
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '.ps1'
            $outputPath = Join-Path $outDir $name
            New-IntegrationWizardBuildScript -Definition $Definition -Context $Context -OutputPath $outputPath
            $result = [PSCustomObject]@{
                Status   = 'Success'
                Action   = 'BuildScript'
                Platform = [string]$Definition.Platform
                Target   = [string]$Definition.Title
                Path     = $outputPath
            }
        }
        'BuildRequirements' {
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-requirements.md'
            $outputPath = Join-Path $outDir $name
            New-IntegrationWizardRequirementsDoc -Definition $Definition -Context $Context -OutputPath $outputPath
            $result = [PSCustomObject]@{
                Status   = 'Success'
                Action   = 'BuildRequirements'
                Platform = [string]$Definition.Platform
                Target   = [string]$Definition.Title
                Path     = $outputPath
            }
            if ($isJson) {
                $jsonName = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-requirements.json'
                $jsonPath = Join-Path $outDir $jsonName
                $reqInputs = [System.Collections.Generic.List[object]]::new()
                foreach ($inp in @($Definition.Inputs)) {
                    if ($inp) {
                        if (Get-Command Test-IntegrationWizardInputWhen -ErrorAction SilentlyContinue) {
                            if (-not (Test-IntegrationWizardInputWhen -InputDef $inp -Context $Context)) { continue }
                        }
                        $isReq = if (Get-Command Test-IntegrationWizardInputRequired -ErrorAction SilentlyContinue) {
                            Test-IntegrationWizardInputRequired -InputDef $inp -Context $Context
                        } else {
                            [bool]$inp['Required']
                        }
                        $reqInputs.Add([ordered]@{
                            name     = [string]$inp.Name
                            purpose  = [string]$inp['Purpose']
                            required = [bool]$isReq
                            secret   = [bool]$inp['Secret']
                        })
                    }
                }
                $targetHost = if (Get-Command Resolve-IntegrationWizardTargetHost -ErrorAction SilentlyContinue) {
                    Resolve-IntegrationWizardTargetHost -Definition $Definition -Context $Context
                } elseif ($Definition.ContainsKey('TargetHost')) { $Definition['TargetHost'] } else { $null }
                $reqData = [ordered]@{
                    target      = [string]$Definition.Title
                    platform    = [string]$Definition.Platform
                    id          = [string]$Definition.Id
                    action      = 'BuildRequirements'
                    access      = [string]$Context['Access']
                    inputs      = $reqInputs.ToArray()
                    adminRoles  = @($Definition.AdminRoles)
                    outputsHelp = [string]$Definition.OutputsHelp
                }
                if ($targetHost -and $targetHost['Role']) {
                    $reqData['targetHost'] = [ordered]@{
                        role  = [string]$targetHost['Role']
                        notes = [string]$targetHost['Notes']
                    }
                }
                Set-Content -LiteralPath $jsonPath -Value ($reqData | ConvertTo-Json -Depth 5) -Encoding utf8
                $result | Add-Member -NotePropertyName JsonPath -NotePropertyValue $jsonPath
            }
        }
        'Check' {
            Import-Module (Join-Path $PSScriptRoot 'IW.Check.psm1') -Force -WarningAction SilentlyContinue
            $name = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-check.md'
            $outputPath = Join-Path $outDir $name
            $checkRes = Invoke-IntegrationRequirementCheck -Definition $Definition -Context $Context -OutputPath $outputPath -WhatIf:$WhatIfPreference
            $verdict = if ($checkRes -and $checkRes.ContainsKey('Verdict')) { [string]$checkRes['Verdict'] } else { 'Pass' }
            $reportPath = if ($checkRes -and $checkRes.ContainsKey('Path')) { [string]$checkRes['Path'] } else { $outputPath }
            $result = [PSCustomObject]@{
                Status   = if ($verdict -eq 'Pass') { 'Success' } else { $verdict }
                Verdict  = $verdict
                Action   = 'Check'
                Platform = [string]$Definition.Platform
                Target   = [string]$Definition.Title
                Path     = $reportPath
            }
            if ($isJson) {
                $jsonName = ($Definition.Id -replace '\+', '_' -replace '[^a-z0-9_-]', '-') + '-check.json'
                $jsonPath = Join-Path $outDir $jsonName
                $checkData = [ordered]@{
                    target   = [string]$Definition.Title
                    platform = [string]$Definition.Platform
                    id       = [string]$Definition.Id
                    action   = 'Check'
                    verdict  = $verdict
                    path     = $reportPath
                }
                Set-Content -LiteralPath $jsonPath -Value ($checkData | ConvertTo-Json -Depth 5) -Encoding utf8
                $result | Add-Member -NotePropertyName JsonPath -NotePropertyValue $jsonPath
            }
        }
        default { throw "Unknown Action: $($Context['Action'])" }
    }

    if ($Context['NonInteractive']) {
        return $result
    }
}

Export-ModuleMember -Function @(
    'Invoke-IntegrationWizardRun'
    'New-IntegrationWizardBuildScript'
    'New-IntegrationWizardRequirementsDoc'
    'Invoke-IntegrationWizardAction'
)
