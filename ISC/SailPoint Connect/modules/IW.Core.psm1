# SailPoint Connect core: definition registry, progressive disclosure, wizard driver.

Set-StrictMode -Version Latest

$script:IntegrationWizardDefinitions = @{}
$script:IntegrationWizardPlatforms = @{}

function Register-IntegrationWizardPlatform {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string[]]$CoreOptions,
        [string]$CliName = 'aws',
        [hashtable]$EntroCompanions = @{}
    )
    $script:IntegrationWizardPlatforms[$Name] = [ordered]@{
        Name             = $Name
        Title            = $Title
        CoreOptions      = $CoreOptions
        CliName          = $CliName
        EntroCompanions  = $EntroCompanions
    }
}

function Register-IntegrationWizardDefinition {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Definition
    )
    if (-not $Definition.Id) { throw 'Definition requires Id.' }
    $script:IntegrationWizardDefinitions[$Definition.Id] = $Definition
}

function Get-IntegrationWizardDefinition {
    param([Parameter(Mandatory)][string]$Id)
    $script:IntegrationWizardDefinitions[$Id]
}

function Get-IntegrationWizardDefinitionsForPlatform {
    param([Parameter(Mandatory)][string]$Platform)
    $script:IntegrationWizardDefinitions.Values | Where-Object { $_.Platform -eq $Platform }
}

function Get-IntegrationWizardWizardRoot {
    param([Parameter(Mandatory)][string]$Platform)
    Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

function Import-IntegrationWizardConsole {
    param(
        [string]$WizardRoot,
        [switch]$NonInteractive
    )
    $mod = Join-Path $WizardRoot 'modules/ISC.OperatorConsole.psm1'
    Import-Module $mod -Force -Global -WarningAction SilentlyContinue
    Import-Module (Join-Path $WizardRoot 'modules/ISC.OperatorToolchain.psm1') -Force -Global -WarningAction SilentlyContinue
    Initialize-OperatorConsole -NonInteractive:$NonInteractive
}

function Show-IntegrationWizardPlatformHelp {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ScriptName,
        [Parameter(Mandatory)][hashtable]$CoreOptionHelp
    )
    $meta = $script:IntegrationWizardPlatforms[$Platform]
    Write-Host ''
    Write-Host "$($meta.Title) integration wizard" -ForegroundColor Cyan
    Write-Host "  ./$ScriptName -Wizard              Guided setup, asks every question"
    foreach ($key in $CoreOptionHelp.Keys) {
        Write-Host "  ./$ScriptName -Wizard -$key     Guided setup, $($CoreOptionHelp[$key].Short) already chosen"
    }
    foreach ($key in $CoreOptionHelp.Keys) {
        Write-Host "  ./$ScriptName -$key         [...]  $($CoreOptionHelp[$key].Long)"
    }
    Write-Host 'Then choose what to do: -Action Run | BuildScript | BuildRequirements'
    Write-Host '  Artifacts go under ~/.sailpoint-connect/<project>/<platform>/<integration>/ (-Project to skip the project menu)'
    Write-Host '  Combine ISC connector + Entro: pass both switches (e.g. -SaaSConnector -Entro on AWS)'
    $first = ($CoreOptionHelp.Keys | Select-Object -First 1)
    if ($first) {
        Write-Host "Next: ./$ScriptName -$first   (lists its options)"
    }
    Write-Host ''
}

function Test-IntegrationWizardContextSwitch {
    param([hashtable]$Context, [string]$Name)
    return $Context.ContainsKey($Name) -and [bool]$Context[$Name]
}

function Get-IntegrationWizardEntroCompanionConfig {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ConnectorCoreSwitch
    )
    $meta = $script:IntegrationWizardPlatforms[$Platform]
    if (-not $meta -or -not $meta.EntroCompanions) { return $null }
    $meta.EntroCompanions[$ConnectorCoreSwitch]
}

function Resolve-IntegrationWizardEntroAddon {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$ConnectorDefinition,
        [switch]$Wizard,
        [switch]$NonInteractive
    )
    $companion = Get-IntegrationWizardEntroCompanionConfig -Platform $Platform -ConnectorCoreSwitch $ConnectorDefinition.CoreSwitch
    if (-not $companion) { return }

    if ($companion['EntroSwitch'] -and (Test-IntegrationWizardContextSwitch -Context $Context -Name $companion['EntroSwitch'])) {
        $Context[$companion['EntroSwitch']] = $true
        return
    }
    if ($companion['Variants']) {
        foreach ($v in @($companion['Variants'])) {
            if (Test-IntegrationWizardContextSwitch -Context $Context -Name $v) { return }
        }
    }

    if (-not $Wizard) { return }

    while ($true) {
        $configureEntro = Read-YesNo -Prompt 'Also configure Entro for this platform?' -Default $false
        if (-not $configureEntro) {
            if ($companion['EntroSwitch']) { $Context[$companion['EntroSwitch']] = $false }
            if ($companion['Variants']) {
                foreach ($v in @($companion['Variants'])) { $Context[$v] = $false }
            }
            return
        }

        if ($companion['EntroSwitch']) {
            $Context[$companion['EntroSwitch']] = $true
            return
        }
        if ($companion['Variants']) {
            try {
                $picked = Read-Choice -Prompt 'Which Entro integration?' -Options $companion['Variants'] `
                    -Labels @($companion['Variants'] | ForEach-Object {
                        switch ($_) {
                            'GcpEntro' { 'Entro Google GCP organization' }
                            'WorkspaceEntro' { 'Entro Google Workspace' }
                            default { $_ }
                        }
                    }) -Default $companion['Variants'][0]
                $Context[$picked] = $true
                return
            }
            catch {
                if (Test-PromptBack $_) {
                    continue
                }
                throw
            }
        }
    }
}

function Get-IntegrationWizardTargets {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $all = @(Get-IntegrationWizardDefinitionsForPlatform -Platform $Platform)
    $active = @($all | Where-Object { Test-IntegrationWizardContextSwitch -Context $Context -Name $_.CoreSwitch })

    $isc = @($active | Where-Object { $_.Product -eq 'ISC' })
    $entro = @($active | Where-Object { $_.Product -eq 'Entro' })

    if ($isc.Count -gt 1) {
        throw 'Only one ISC connector target can be selected per run.'
    }
    if ($isc.Count -eq 1 -and $isc[0]['CoreSwitch'] -eq 'CiemConnector' -and $entro.Count -gt 0) {
        throw 'CIEM connector cannot be combined with Entro in the same run.'
    }
    if ($entro.Count -gt 1) {
        throw 'Only one Entro target can be selected per run.'
    }

    if ($isc.Count -eq 0 -and $entro.Count -eq 0) { return @() }
    if ($isc.Count -eq 0) { return @($entro[0]) }
    if ($entro.Count -eq 0) { return @($isc[0]) }
    return @($isc[0], $entro[0])
}

function Merge-IntegrationWizardDefinitions {
    param(
        [Parameter(Mandatory)][object[]]$Members
    )
    if ($Members.Count -eq 1) { return $Members[0] }

    $cli = $Members[0].CliName
    foreach ($m in $Members) {
        if ($m.CliName -ne $cli) { throw 'Combined definitions must use the same CLI.' }
    }

    $mergedInputs = @{}
    foreach ($m in $Members) {
        foreach ($input in @($m.Inputs)) {
            if (-not $input) { continue }
            $name = $input.Name
            if ($mergedInputs.ContainsKey($name)) {
                $existing = $mergedInputs[$name]
                if ($existing.Purpose -ne $input.Purpose) {
                    throw "Input name collision '$name' with different purpose; use distinct names (e.g. IscExternalId vs EntroExternalId)."
                }
                continue
            }
            $mergedInputs[$name] = $input
        }
    }

    $titles = @($Members | ForEach-Object { $_.Title })
    $ids = @($Members | ForEach-Object { $_.Id }) -join '+'

    $access = @()
    foreach ($m in $Members) {
        if ($m['AccessLevels'] -and @($m['AccessLevels']).Count -gt 0) { $access = @($m['AccessLevels']); break }
    }

    $membersCopy = @($Members)
    $folderNames = @($Members | ForEach-Object {
        if ($_['FolderName']) { [string]$_['FolderName'] } else { [string]$_.Title }
    })

    return @{
        IsComposite  = $true
        Id           = $ids
        Platform     = $Members[0].Platform
        Product      = 'Combined'
        CliName      = $cli
        Title        = ($titles -join ' + ')
        FolderName   = ($folderNames -join ' and ')
        AccessLevels = $access
        Inputs       = @($mergedInputs.Values)
        Members      = $membersCopy
        AdminRoles   = @($Members | ForEach-Object { @($_['AdminRoles']) } | ForEach-Object { $_ })
        OutputsHelp  = ($Members | ForEach-Object { if ($_['OutputsHelp']) { $_['OutputsHelp'] } }) -join "`n`n"
        Steps        = {
            param($ctx)
            $allSteps = @()
            foreach ($member in $membersCopy) {
                $allSteps += & $member.Steps $ctx
            }
            $allSteps
        }
    }
}

function Resolve-IntegrationWizardPlan {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $members = @(Get-IntegrationWizardTargets -Platform $Platform -Context $Context)
    if ($members.Count -eq 0) { return $null }
    if ($members.Count -eq 1) { return $members[0] }
    Merge-IntegrationWizardDefinitions -Members $members
}

function Get-IntegrationWizardDefinitionByCoreSwitch {
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )
    foreach ($def in (Get-IntegrationWizardDefinitionsForPlatform -Platform $Platform)) {
        if ($def.CoreSwitch -and $BoundParameters.ContainsKey($def.CoreSwitch)) {
            return $def
        }
    }
    $null
}

function Test-IntegrationWizardInputWhen {
    param($InputDef, [hashtable]$Context)
    if (-not $InputDef) { return $false }
    if (-not ($InputDef.ContainsKey('When') -or ($InputDef.PSObject.Properties.Name -contains 'When'))) { return $true }
    $when = if ($InputDef -is [hashtable]) { $InputDef['When'] } else { $InputDef.When }
    if (-not $when) { return $true }
    & $when $Context
}

function Test-IntegrationWizardRequiredInputs {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $missing = @()
    foreach ($input in @($Definition.Inputs)) {
        if (-not $input) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $name = $input.Name
        if ($input['Required'] -and [string]::IsNullOrWhiteSpace([string]$Context[$name])) {
            $missing += $name
        }
    }
    ,$missing
}

function Show-IntegrationWizardDefinitionHelp {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][string]$ScriptName,
        [Parameter(Mandatory)][hashtable]$Context,
        [string[]]$Missing
    )
    Write-Host ''
    Write-Host "$($Definition.Title)" -ForegroundColor Cyan
    if ($Definition['IsComposite']) {
        Write-Host '  Combined targets:'
        foreach ($m in @($Definition.Members)) { Write-Host "    -$($m['CoreSwitch'])  $($m['Title'])" }
    }
    elseif ($Definition['CoreSwitch']) {
        Write-Host "  Core switch: -$($Definition['CoreSwitch'])"
    }
    if ($Definition['AccessLevels'] -and @($Definition['AccessLevels']).Count -gt 1) {
        Write-Host '  -Access ReadOnly|ReadWrite'
    }
    Write-Host '  -Action Run|BuildScript|BuildRequirements'
    Write-Host '  -OutputDirectory'
    Write-Host '  -NonInteractive   -OutputFormat Text|Json'
    Write-Host ''
    Write-Host 'Inputs:'
    foreach ($input in @($Definition.Inputs)) {
        if (-not $input) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $req = if ($input['Required']) { ' (required)' } else { '' }
        $src = if ($input['Source'] -eq 'Discover') { ' [discover]' } else { '' }
        Write-Host "  -$($input.Name)$req$src — $($input['Purpose'])"
    }
    if ($Missing -and $Missing.Count -gt 0) {
        Write-Host ''
        Write-Host 'Missing:' -ForegroundColor Yellow
        foreach ($m in $Missing) { Write-Host "  -$m" -ForegroundColor Yellow }
    }
    Write-Host ''
}

function Resolve-IntegrationWizardAccessLevel {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$Wizard,
        [switch]$NonInteractive
    )
    $levels = @($Definition['AccessLevels'])
    if ($levels.Count -le 1) {
        if ($levels.Count -eq 1) {
            $Context['Access'] = $levels[0]
        }
        return
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$Context['Access'])) { return }
    if (-not $Wizard) {
        if ($NonInteractive) { throw "Missing required -Access ($($levels -join '|'))." }
        return
    }
    $Context['Access'] = Read-Choice -Prompt 'Access level for this connector:' `
        -Options $levels `
        -Labels @($levels | ForEach-Object {
            if ($_ -eq 'ReadOnly') { 'Read only (aggregation, no provisioning writes)' }
            else { 'Read and write (includes provisioning permissions)' }
        }) -Default 'ReadOnly'
}

function Show-IntegrationWizardConnectionCheck {
    param(
        [Parameter(Mandatory)][string]$CliName,
        [Parameter(Mandatory)][hashtable]$SessionState
    )
    Write-Step 'Current CLI session'
    if ($SessionState.Installed -and $SessionState.SignedIn) {
        Write-Ok "${CliName}: $($SessionState.Summary)"
    }
    elseif ($SessionState.Installed) {
        $detail = if ($SessionState['Summary']) { " ($($SessionState['Summary']))" } else { '' }
        Write-Info "$CliName is installed but not signed in.$detail"
    }
    else {
        Write-Info "$CliName was not found on PATH."
    }
}

function Resolve-IntegrationWizardConnectionChoice {
    param(
        [Parameter(Mandatory)][string]$CliName,
        [Parameter(Mandatory)][hashtable]$SessionState,
        [switch]$Wizard,
        [switch]$NonInteractive
    )
    if (-not $Wizard) {
        if ($SessionState['Mode']) { return $SessionState['Mode'] }
        return 'UseSession'
    }
    Show-IntegrationWizardConnectionCheck -CliName $CliName -SessionState $SessionState
    # "Use this session" is only offered when a usable session exists. An installed CLI with
    # expired or missing credentials cannot introspect, so that choice is omitted.
    $options = @('SignIn', 'NoSession')
    $labels = @(
        'Install or sign in / switch account'
        'Continue without a session (type values manually)'
    )
    $default = 'SignIn'
    if ($SessionState.SignedIn) {
        $options = @('UseSession') + $options
        $labels = @('Use this session (introspect and pick lists)') + $labels
        $default = 'UseSession'
    }
    $pick = Read-Choice -Prompt 'How do you want to connect?' -Options $options -Labels $labels -Default $default
    $SessionState['Mode'] = $pick
    return $pick
}

function Collect-IntegrationWizardInputs {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$Wizard,
        [switch]$NonInteractive,
        [scriptblock]$Discover
    )
    $inputList = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($inp in @($Definition.Inputs)) {
        if (-not $inp) { continue }
        $inputList.Add($inp)
    }

    $idx = 0
    $prompted = [System.Collections.Generic.HashSet[string]]::new()
    while ($idx -ge 0 -and $idx -lt $inputList.Count) {
        $input = $inputList[$idx]
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) {
            $idx++
            continue
        }
        $name = $input.Name
        if ($Context.ContainsKey($name) -and -not [string]::IsNullOrWhiteSpace([string]$Context[$name]) -and (-not $prompted.Contains($name))) {
            $idx++
            continue
        }
        if (-not $Wizard) {
            $idx++
            continue
        }
        $discoverValues = $null
        if ($Context['ConnectionMode'] -ne 'NoSession' -and $input['Source'] -eq 'Discover' -and $Discover) {
            $discoverValues = & $Discover $name $Context
        }
        try {
            if ($discoverValues -and @($discoverValues).Count -gt 0) {
                $typed = 'Type a different value'
                $options = @($discoverValues) + @($typed)
                $picked = Read-Choice -Prompt $input['Prompt'] -Options $options -Default $discoverValues[0]
                if ($picked -ne $typed) {
                    $Context[$name] = $picked
                    [void]$prompted.Add($name)
                    $idx++
                    continue
                }
            }
            if ($input['ValidateSet']) {
                $Context[$name] = Read-Choice -Prompt $input['Prompt'] -Options $input['ValidateSet'] -Default $input['Default']
            }
            else {
                $Context[$name] = Read-InputString -Prompt $input['Prompt'] -Default $input['Default'] -Required:([bool]$input['Required'])
            }
            [void]$prompted.Add($name)
            $idx++
        }
        catch {
            if (Test-PromptBack $_) {
                $Context.Remove($name)
                [void]$prompted.Remove($name)
                $idx--
                if ($idx -ge 0) {
                    $prevName = $inputList[$idx].Name
                    $Context.Remove($prevName)
                    [void]$prompted.Remove($prevName)
                }
                continue
            }
            throw
        }
    }
    if ($idx -lt 0) {
        Invoke-PromptBack
    }
}

function Show-IntegrationWizardSummary {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    Write-Host ''
    Write-Host 'Plan summary' -ForegroundColor Cyan
    if ($Context['IntegrationProjectName']) {
        Write-Host "  Project: $($Context['IntegrationProjectName'])"
        Write-Host "  Folder:  $($Context['IntegrationFolderPath'])"
    }
    Write-Host "  Target:  $($Definition.Title)"
    if ($Context['Access']) { Write-Host "  Access:  $($Context['Access'])" }
    if ($Context['Action']) { Write-Host "  Action:  $($Context['Action'])" }
    foreach ($input in @($Definition.Inputs)) {
        if (-not $input) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $val = $Context[$input.Name]
        if ($input['Secret']) { $val = if ($val) { '***' } else { '(created at run)' } }
        Write-Host "  $($input.Name): $val"
    }
    Write-Host ''
}

function Resolve-IntegrationWizardAction {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$Wizard
    )
    if (-not [string]::IsNullOrWhiteSpace([string]$Context['Action'])) { return }
    if (-not $Wizard) { throw 'Missing required -Action (Run|BuildScript|BuildRequirements).' }
    $Context['Action'] = Read-Choice -Prompt 'What should happen next?' `
        -Options @('Run', 'BuildScript', 'BuildRequirements') `
        -Labels @(
            'Run changes (apply on the target now)'
            'Build script (PowerShell 7 + platform CLI, review before running)'
            'Build requirements (Markdown document)'
        ) -Default 'Run'
}

function Start-IntegrationWizardFlow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ScriptName,
        [Parameter(Mandatory)][hashtable]$CoreOptionHelp,
        [Parameter(Mandatory)][hashtable]$Context,
        [scriptblock]$PickTarget,
        [scriptblock]$Discover,
        [scriptblock]$Execute
    )
    $wizard = [bool]$Context['Wizard']
    $nonInteractive = [bool]$Context['NonInteractive']

    $plan = $null
    try {
        $plan = Resolve-IntegrationWizardPlan -Platform $Platform -Context $Context
    }
    catch {
        Write-Error $_.Exception.Message
        return
    }

    if (-not $plan -and -not $wizard) {
        Show-IntegrationWizardPlatformHelp -Platform $Platform -ScriptName $ScriptName -CoreOptionHelp $CoreOptionHelp
        return
    }

    $projectMod = Join-Path $PSScriptRoot 'IW.Project.psm1'
    if (-not (Get-Module -Name 'IW.Project')) {
        Import-Module $projectMod -Force -WarningAction SilentlyContinue
    }
    if ($wizard) {
        $stage = 0
        $needWorkspace = Test-IntegrationWizardNeedsProjectContext -Wizard:$wizard -Context $Context
        $pickedTarget = $false

        $wizardComplete = $false
        :wizardLoop while (-not $wizardComplete) {
            try {
                switch ($stage) {
                    0 {
                        if ($needWorkspace -and [string]::IsNullOrWhiteSpace([string]$Context['IntegrationProjectName'])) {
                            Select-IntegrationProjectWorkspace -Context $Context
                        }
                        $stage = 1
                    }
                    1 {
                        if (-not $plan -or $pickedTarget) {
                            if ($PickTarget) {
                                :pickLoop while ($true) {
                                    $connectorDef = & $PickTarget
                                    if (-not $connectorDef) { break :pickLoop }
                                    $pickedTarget = $true
                                    if ($connectorDef.Product -eq 'ISC') {
                                        try {
                                            Resolve-IntegrationWizardEntroAddon -Platform $Platform -Context $Context -ConnectorDefinition $connectorDef `
                                                -Wizard:$wizard -NonInteractive:$nonInteractive
                                            break :pickLoop
                                        }
                                        catch {
                                            if (Test-PromptBack $_) {
                                                continue
                                            }
                                            throw
                                        }
                                    }
                                    else {
                                        break :pickLoop
                                    }
                                }
                                if ($connectorDef) {
                                    $plan = Resolve-IntegrationWizardPlan -Platform $Platform -Context $Context
                                }
                            }
                        }
                        elseif ($plan -and -not $plan['IsComposite'] -and $plan.Product -eq 'ISC') {
                            Resolve-IntegrationWizardEntroAddon -Platform $Platform -Context $Context -ConnectorDefinition $plan `
                                -Wizard:$wizard -NonInteractive:$nonInteractive
                            try {
                                $plan = Resolve-IntegrationWizardPlan -Platform $Platform -Context $Context
                            }
                            catch {
                                Write-Error $_.Exception.Message
                                return
                            }
                        }

                        if (-not $plan) {
                            Show-IntegrationWizardPlatformHelp -Platform $Platform -ScriptName $ScriptName -CoreOptionHelp $CoreOptionHelp
                            return
                        }
                        $stage = 2
                    }
                    2 {
                        Resolve-IntegrationWizardAccessLevel -Definition $plan -Context $Context -Wizard:$wizard -NonInteractive:$nonInteractive
                        $meta = $script:IntegrationWizardPlatforms[$Platform]
                        if ($needWorkspace) {
                            Initialize-IntegrationProjectContext -Platform $Platform -PlatformTitle $meta.Title -Plan $plan -Context $Context -ScriptName $ScriptName
                        }
                        $stage = 3
                    }
                    3 {
                        $meta = $script:IntegrationWizardPlatforms[$Platform]
                        $session = Get-IntegrationWizardCliSession -CliName $meta.CliName
                        $mode = Resolve-IntegrationWizardConnectionChoice -CliName $meta.CliName -SessionState $session -Wizard:$wizard -NonInteractive:$nonInteractive
                        $Context['ConnectionMode'] = $mode
                        if ($mode -eq 'SignIn') {
                            Install-IntegrationWizardCli -CliName $meta.CliName -NonInteractive:$nonInteractive
                            Invoke-IntegrationWizardCliLogin -CliName $meta.CliName -NonInteractive:$nonInteractive
                        }
                        $stage = 4
                    }
                    4 {
                        Collect-IntegrationWizardInputs -Definition $plan -Context $Context -Wizard:$wizard -NonInteractive:$nonInteractive -Discover $Discover
                        $stage = 5
                    }
                    5 {
                        Resolve-IntegrationWizardAction -Context $Context -Wizard:$wizard
                        $stage = 6
                    }
                    6 {
                        Show-IntegrationWizardSummary -Definition $plan -Context $Context
                        if (-not (Read-YesNo -Prompt 'Proceed?' -Default $true)) {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                            if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                                Close-IntegrationProjectActivityLog
                            }
                            return
                        }
                        $wizardComplete = $true
                        break :wizardLoop
                    }
                }
            }
            catch {
                if (Test-PromptBack $_) {
                    if ($stage -eq 6) {
                        $Context.Remove('Action')
                        $stage = 5
                        continue
                    }
                    elseif ($stage -eq 5) {
                        $stage = 4
                        continue
                    }
                    elseif ($stage -eq 4) {
                        $Context.Remove('ConnectionMode')
                        $stage = 3
                        continue
                    }
                    elseif ($stage -eq 3) {
                        if ($plan['AccessLevels'] -and @($plan['AccessLevels']).Count -gt 1) {
                            $Context.Remove('Access')
                            $stage = 2
                        }
                        else {
                            $stage = 1
                        }
                        continue
                    }
                    elseif ($stage -eq 2) {
                        $Context.Remove('Access')
                        $stage = 1
                        continue
                    }
                    elseif ($stage -le 1) {
                        Write-Host ''
                        Write-Host 'Cancelled.' -ForegroundColor Yellow
                        if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                            Close-IntegrationProjectActivityLog
                        }
                        return
                    }
                }
                throw
            }
        }
    }
    else {
        if (-not $plan) {
            Show-IntegrationWizardPlatformHelp -Platform $Platform -ScriptName $ScriptName -CoreOptionHelp $CoreOptionHelp
            return
        }
        Resolve-IntegrationWizardAccessLevel -Definition $plan -Context $Context -Wizard:$false -NonInteractive:$nonInteractive
        if (Test-IntegrationWizardNeedsProjectContext -Wizard:$false -Context $Context) {
            $meta = $script:IntegrationWizardPlatforms[$Platform]
            Initialize-IntegrationProjectContext -Platform $Platform -PlatformTitle $meta.Title -Plan $plan -Context $Context -ScriptName $ScriptName
        }
        if ([string]::IsNullOrWhiteSpace([string]$Context['Action'])) {
            Show-IntegrationWizardDefinitionHelp -Definition $plan -ScriptName $ScriptName -Context $Context -Missing @('Action')
            return
        }
    }
    if ($Context['IntegrationProjectName']) {
        $record = Get-IntegrationProjectSelectionSnapshot -Context $Context -Definition $plan -Platform $Platform -ScriptName $ScriptName
        Write-IntegrationProjectSelection -Record $record
        Write-IntegrationProjectLogLine -Level 'INFO' -Message "Recorded selection for project $($Context['IntegrationProjectName'])"
    }
    try {
        & $Execute $plan $Context
    }
    finally {
        if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
            Close-IntegrationProjectActivityLog
        }
    }
}

function Get-IntegrationWizardCliSession {
    param([Parameter(Mandatory)][string]$CliName)
    $state = @{
        Installed = $false
        SignedIn  = $false
        Summary   = ''
    }
    $cmd = Get-Command $CliName -ErrorAction SilentlyContinue
    if (-not $cmd) { return $state }
    $state.Installed = $true
    try {
        switch ($CliName) {
            'aws' {
                $json = aws sts get-caller-identity --output json 2>$null
                if ($LASTEXITCODE -eq 0 -and $json) {
                    $o = $json | ConvertFrom-Json
                    $state.SignedIn = $true
                    $state.Summary = "account $($o.Account) ($($o.Arn))"
                }
            }
            'az' {
                $json = az account show --output json 2>$null
                if ($LASTEXITCODE -eq 0 -and $json) {
                    $o = $json | ConvertFrom-Json
                    $state.SignedIn = $true
                    $state.Summary = "subscription $($o.name) ($($o.id))"
                }
            }
            'gcloud' {
                $acct = gcloud config get-value account 2>$null
                $proj = gcloud config get-value project 2>$null
                if ($acct) {
                    # A configured account is not enough: its token may have expired. Only a token
                    # that can be minted counts as signed in.
                    gcloud auth print-access-token --quiet 2>$null | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        $state.SignedIn = $true
                        $state.Summary = "account $acct project $proj"
                    }
                    else {
                        $state.Summary = "credentials for $acct have expired"
                    }
                }
            }
            'databricks' {
                $out = databricks auth describe --output json 2>$null
                if ($LASTEXITCODE -eq 0 -and $out) {
                    $state.SignedIn = $true
                    $state.Summary = 'Databricks CLI authenticated'
                }
            }
        }
    }
    catch { }
    return $state
}

function Install-IntegrationWizardCli {
    param(
        [Parameter(Mandatory)][string]$CliName,
        [switch]$NonInteractive
    )
    switch ($CliName) {
        'aws' {
            Ensure-CliCommand -CommandNames @('aws', 'aws.exe') `
                -WingetPackageId 'Amazon.AWSCLI' -BrewPackage 'awscli' `
                -ManualHint 'Install AWS CLI v2 from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html' | Out-Null
        }
        'az' { Ensure-AzCliCommand -ErrorAction Stop }
        'gcloud' { Ensure-GCloudCommand -ErrorAction Stop }
        'databricks' {
            if (-not (Get-Command databricks -ErrorAction SilentlyContinue)) {
                if ($NonInteractive) { throw 'Install the Databricks CLI: https://docs.databricks.com/dev-tools/cli/install.html' }
                Write-Info 'Install the Databricks CLI, then press Enter.'
                Read-Host | Out-Null
            }
        }
    }
}

function Invoke-IntegrationWizardCliLogin {
    param(
        [Parameter(Mandatory)][string]$CliName,
        [switch]$NonInteractive
    )
    if ($NonInteractive) {
        throw "Sign in with: $(Get-IntegrationWizardLoginHint -CliName $CliName)"
    }
    Write-Info (Get-IntegrationWizardLoginHint -CliName $CliName)
    switch ($CliName) {
        'aws' { aws sso login 2>$null; if ($LASTEXITCODE -ne 0) { aws configure } }
        'az' { az login | Out-Null }
        'gcloud' { gcloud auth login }
        'databricks' { databricks auth login | Out-Null }
    }
}

function Get-IntegrationWizardLoginHint {
    param([string]$CliName)
    switch ($CliName) {
        'aws' { return 'Run: aws sso login  (or aws configure)' }
        'az' { return 'Run: az login' }
        'gcloud' { return 'Run: gcloud auth login' }
        'databricks' { return 'Run: databricks auth login' }
        default { return "Sign in to $CliName" }
    }
}

Export-ModuleMember -Function @(
    'Register-IntegrationWizardPlatform'
    'Register-IntegrationWizardDefinition'
    'Get-IntegrationWizardDefinition'
    'Get-IntegrationWizardDefinitionsForPlatform'
    'Get-IntegrationWizardWizardRoot'
    'Import-IntegrationWizardConsole'
    'Show-IntegrationWizardPlatformHelp'
    'Show-IntegrationWizardDefinitionHelp'
    'Get-IntegrationWizardDefinitionByCoreSwitch'
    'Get-IntegrationWizardTargets'
    'Merge-IntegrationWizardDefinitions'
    'Resolve-IntegrationWizardPlan'
    'Resolve-IntegrationWizardEntroAddon'
    'Resolve-IntegrationWizardConnectionChoice'
    'Test-IntegrationWizardRequiredInputs'
    'Test-IntegrationWizardInputWhen'
    'Start-IntegrationWizardFlow'
    'Get-IntegrationWizardCliSession'
    'Install-IntegrationWizardCli'
    'Invoke-IntegrationWizardCliLogin'
    'Get-IntegrationWizardLoginHint'
)
