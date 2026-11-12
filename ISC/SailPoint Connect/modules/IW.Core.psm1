# SailPoint Connect core: definition registry, progressive disclosure, wizard driver.

Set-StrictMode -Version Latest

if (-not ('PromptBackException' -as [type])) {
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Management.Automation;

public class PromptBackException : RuntimeException {
    public PromptBackException() : base("PROMPT_BACK") {}
    public PromptBackException(string message) : base(message) {}
    public PromptBackException(string message, Exception innerException) : base(message, innerException) {}
}
'@ -ErrorAction Stop
    }
    catch {
        # Fallback if Add-Type is unavailable
    }
}

if (-not (Get-Command Test-PromptBack -ErrorAction SilentlyContinue)) {
    function Test-PromptBack {
        param($ErrorRecord)
        if ($null -eq $ErrorRecord) { return $false }
        $ex = if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
            $ErrorRecord.Exception
        }
        elseif ($ErrorRecord -is [System.Exception]) {
            $ErrorRecord
        }
        else {
            return ([string]$ErrorRecord -eq 'PROMPT_BACK')
        }

        while ($ex) {
            if ($ex -is [PromptBackException] -or
                $ex.GetType().Name -eq 'PromptBackException' -or
                $ex.Message -eq 'PROMPT_BACK') {
                return $true
            }
            $ex = $ex.InnerException
        }
        return $false
    }
}

if (-not (Get-Command Invoke-PromptBack -ErrorAction SilentlyContinue)) {
    function Invoke-PromptBack {
        if ('PromptBackException' -as [type]) {
            throw [PromptBackException]::new()
        }
        throw 'PROMPT_BACK'
    }
}

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

function Show-IntegrationWizardSafetyNote {
    Write-Host 'Nothing is changed until you choose Run and answer yes.' -ForegroundColor Cyan
    Write-Host '  -Action BuildRequirements   Checklist of what this integration needs. Nothing is created.'
    Write-Host '  -Action Check               Check existing connection details, credentials, or identities for gaps. Nothing is created.'
    Write-Host '  -Action BuildScript         Script to review and run later, under your own change process. Nothing is created.'
    Write-Host '  -Action Run                 The only action that creates or updates anything, and only after you confirm.'
    Write-Host 'Discovery is optional. A signed-in CLI can offer names that already exist. You can type every value yourself.'
    Write-Host ''
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
    Show-IntegrationWizardSafetyNote
    Write-Host "  ./$ScriptName -Wizard              Guided setup, asks every question"
    foreach ($key in $CoreOptionHelp.Keys) {
        Write-Host "  ./$ScriptName -Wizard -$key     Guided setup, $($CoreOptionHelp[$key].Short) already chosen"
    }
    foreach ($key in $CoreOptionHelp.Keys) {
        Write-Host "  ./$ScriptName -$key         [...]  $($CoreOptionHelp[$key].Long)"
    }
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

    $mergedInputs = [ordered]@{}
    foreach ($m in $Members) {
        foreach ($inputDef in @($m.Inputs)) {
            if (-not $inputDef) { continue }
            $name = $inputDef.Name
            if ($mergedInputs.Contains($name)) {
                $existing = $mergedInputs[$name]
                if ($existing.Purpose -ne $inputDef.Purpose) {
                    throw "Input name collision '$name' with different purpose; use distinct names (e.g. IscExternalId vs EntroExternalId)."
                }
                continue
            }
            $mergedInputs[$name] = $inputDef
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
        FolderName   = (($folderNames -join '-and-') -replace '\s+', '-')
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

function Get-IntegrationWizardActiveInputs {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    if ($Context['Action'] -eq 'Check' -and $Definition.ContainsKey('CheckInputs') -and $Definition['CheckInputs']) {
        return @($Definition['CheckInputs'])
    }
    return @($Definition.Inputs)
}

function Test-IntegrationWizardRequiredInputs {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $missing = @()
    $inputs = Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context
    foreach ($inputDef in $inputs) {
        if (-not $inputDef) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) { continue }
        $name = $inputDef.Name
        if ($inputDef['Required'] -and [string]::IsNullOrWhiteSpace([string]$Context[$name])) {
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
    Write-Host '  -Action BuildRequirements|Check|BuildScript|Run'
    Write-Host '  BuildRequirements, Check, and BuildScript do not change the tenant. Run is the only action that does.'
    Write-Host '  -OutputDirectory'
    Write-Host '  -NonInteractive   -OutputFormat Text|Json'
    Write-Host ''
    Write-Host 'Inputs:'
    $helpInputs = Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context
    foreach ($inputDef in $helpInputs) {
        if (-not $inputDef) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) { continue }
        $req = if ($inputDef['Required']) { ' (required)' } else { '' }
        $src = if ($inputDef['Source'] -eq 'Discover') { ' [pick-list if signed in, or type it]' } else { '' }
        Write-Host "  -$($inputDef.Name)$req$src — $($inputDef['Purpose'])"
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
    Write-Info 'A session is only used to list names that already exist, or to read an identity when you choose Check. You can type every value instead. Nothing is created here.'
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
    # expired or missing credentials cannot list existing names, so that choice is omitted.
    # The default when nothing is signed in is to type values. Signing in is optional and
    # only used to offer pick-lists, or to read an identity when the action is Check.
    $options = @('NoSession', 'SignIn')
    $labels = @(
        'Type every value yourself (complete; no CLI calls)'
        'Sign in so the CLI can offer existing names (reads only; creates nothing)'
    )
    $default = 'NoSession'
    if ($SessionState.SignedIn) {
        $options = @('UseSession') + $options
        $labels = @('Use this session to offer existing names (reads only; creates nothing)') + $labels
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
    $inputs = Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context
    $inputList = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($inp in $inputs) {
        if (-not $inp) { continue }
        $inputList.Add($inp)
    }

    $idx = 0
    $prompted = [System.Collections.Generic.HashSet[string]]::new()
    while ($idx -ge 0 -and $idx -lt $inputList.Count) {
        $inputDef = $inputList[$idx]
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) {
            $idx++
            continue
        }
        $name = $inputDef.Name
        if ($Context.ContainsKey($name) -and -not [string]::IsNullOrWhiteSpace([string]$Context[$name]) -and (-not $prompted.Contains($name))) {
            $idx++
            continue
        }
        if (-not $Wizard) {
            $idx++
            continue
        }
        $discoverValues = $null
        if ($Context['ConnectionMode'] -ne 'NoSession' -and $inputDef['Source'] -eq 'Discover' -and $Discover) {
            $discoverValues = & $Discover $name $Context
        }
        try {
            if ($discoverValues -and @($discoverValues).Count -gt 0) {
                $typed = 'Type a different value'
                $options = @($discoverValues) + @($typed)
                $picked = Read-Choice -Prompt $inputDef['Prompt'] -Options $options -Default $discoverValues[0]
                if ($picked -ne $typed) {
                    $Context[$name] = $picked
                    [void]$prompted.Add($name)
                    $idx++
                    continue
                }
            }
            if ($inputDef['ValidateSet']) {
                $Context[$name] = Read-Choice -Prompt $inputDef['Prompt'] -Options $inputDef['ValidateSet'] -Default $inputDef['Default']
            }
            else {
                $isSecret = [bool]($inputDef['Secret'] -or ($name -match '(?i)secret|password|token|privatekey'))
                $Context[$name] = Read-InputString -Prompt $inputDef['Prompt'] -Default $inputDef['Default'] -Required:([bool]$inputDef['Required']) -Mask:$isSecret
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
    if ($Context['Action'] -eq 'Run') {
        Write-Host '  Run changes the tenant. The next question is the confirmation.' -ForegroundColor Yellow
    }
    elseif ($Context['Action']) {
        Write-Host '  This action does not change the tenant.'
    }
    $summaryInputs = Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context
    foreach ($inputDef in $summaryInputs) {
        if (-not $inputDef) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) { continue }
        $val = $Context[$inputDef.Name]
        $isSecret = [bool]($inputDef['Secret'] -or ($inputDef.Name -match '(?i)secret|password|token|privatekey'))
        if ($isSecret) { $val = if ($val) { '***' } else { '(created at run)' } }
        Write-Host "  $($inputDef.Name): $val"
    }
    Write-Host ''
}

function Show-IntegrationWizardActionPurpose {
    param([Parameter(Mandatory)][string]$Action)
    switch ($Action) {
        'BuildRequirements' { Write-Host 'This session writes a checklist. The tenant will not be changed.' }
        'Check' { Write-Host 'This session reads existing connection details and reports gaps. The tenant will not be changed.' }
        'BuildScript' { Write-Host 'This session writes a script for you to review. The tenant will not be changed.' }
        'Run' { Write-Host 'This session can change the tenant. You confirm again before anything is written.' }
    }
}

function Resolve-IntegrationWizardAction {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$Wizard
    )
    if (-not [string]::IsNullOrWhiteSpace([string]$Context['Action'])) {
        if ($Wizard) { Show-IntegrationWizardActionPurpose -Action $Context['Action'] }
        return
    }
    if (-not $Wizard) { throw 'Missing required -Action (BuildRequirements|Check|BuildScript|Run).' }
    Show-IntegrationWizardSafetyNote
    $Context['Action'] = Read-Choice -Prompt 'What should this session produce?' `
        -Options @('BuildRequirements', 'Check', 'BuildScript', 'Run') `
        -Labels @(
            'Build requirements (a checklist; nothing is created)'
            'Check existing connection details (read-only; verifies credentials and permissions)'
            'Build script (review it, then run it yourself)'
            'Run (the only choice that changes the tenant, after you confirm)'
        ) -Default 'BuildRequirements'
    Show-IntegrationWizardActionPurpose -Action $Context['Action']
}

function Remove-LastIntegrationWizardInput {
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $last = $null
    foreach ($inputDef in @($Definition.Inputs)) {
        if (-not $inputDef) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $inputDef -Context $Context)) { continue }
        $name = $inputDef.Name
        if ($Context.ContainsKey($name) -and -not [string]::IsNullOrWhiteSpace([string]$Context[$name])) {
            $last = $name
        }
    }
    if (-not $last) { return $false }
    $Context.Remove($last)
    return $true
}

$script:LastWizardCancelled = $false

function Test-IntegrationWizardCancelled {
    return [bool]$script:LastWizardCancelled
}

function Copy-IntegrationWizardCatalogContext {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)]$BoundParameters
    )
    foreach ($name in @(
        'CatalogIntegrationId', 'CatalogProduct', 'CatalogVariantId', 'CatalogCredentialKind',
        'CatalogReuseMode', 'CatalogCredentialId'
    )) {
        $hasKey = if ($BoundParameters.PSObject.Methods.Name -contains 'ContainsKey') {
            $BoundParameters.ContainsKey($name)
        }
        elseif ($BoundParameters.PSObject.Methods.Name -contains 'Contains') {
            $BoundParameters.Contains($name)
        }
        else {
            $null -ne $BoundParameters[$name]
        }
        if ($hasKey) { $Context[$name] = $BoundParameters[$name] }
    }
    if ($Context['CatalogIntegrationId'] -and -not $Context['CatalogReuseMode']) {
        $Context['CatalogReuseMode'] = 'CreateNew'
    }
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
    $script:LastWizardCancelled = $false
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
        if (-not $nonInteractive) {
            $bannerProj = if ($Context.ContainsKey('Project') -and $Context['Project']) { [string]$Context['Project'] }
                          elseif ($Context.ContainsKey('IntegrationProjectName') -and $Context['IntegrationProjectName']) { [string]$Context['IntegrationProjectName'] }
                          else { $null }
            Write-SailPointConnectBanner -ProjectName $bannerProj
            if (Get-Command Confirm-SailPointConnectUpdate -ErrorAction SilentlyContinue) {
                if (Confirm-SailPointConnectUpdate -Wizard) { return }
            }
        }
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
                        Resolve-IntegrationWizardAction -Context $Context -Wizard:$wizard
                        $stage = 2
                    }
                    2 {
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
                        elseif ($plan -and -not $plan['IsComposite'] -and $plan.Product -eq 'ISC' -and -not $Context['CatalogIntegrationId']) {
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
                        $stage = 3
                    }
                    3 {
                        Resolve-IntegrationWizardAccessLevel -Definition $plan -Context $Context -Wizard:$wizard -NonInteractive:$nonInteractive
                        $meta = $script:IntegrationWizardPlatforms[$Platform]
                        if ($needWorkspace) {
                            Initialize-IntegrationProjectContext -Platform $Platform -PlatformTitle $meta.Title -Plan $plan -Context $Context -ScriptName $ScriptName
                        }
                        $stage = 4
                    }
                    4 {
                        if ($Context['Action'] -eq 'Check') {
                            $Context['ConnectionMode'] = 'NoSession'
                            $stage = 5
                            continue
                        }
                        $meta = $script:IntegrationWizardPlatforms[$Platform]
                        $session = Get-IntegrationWizardCliSession -CliName $meta.CliName
                        $mode = Resolve-IntegrationWizardConnectionChoice -CliName $meta.CliName -SessionState $session -Wizard:$wizard -NonInteractive:$nonInteractive
                        $Context['ConnectionMode'] = $mode
                        if ($mode -eq 'SignIn') {
                            while ($true) {
                                Install-IntegrationWizardCli -CliName $meta.CliName -NonInteractive:$nonInteractive
                                Invoke-IntegrationWizardCliLogin -CliName $meta.CliName -NonInteractive:$nonInteractive

                                Write-Step 'Testing CLI session'
                                $session = Get-IntegrationWizardCliSession -CliName $meta.CliName
                                if ($session.SignedIn) {
                                    Write-Ok "$($meta.CliName): $($session.Summary)"
                                    if (Get-Command Write-IntegrationProjectLogLine -ErrorAction SilentlyContinue) {
                                        Write-IntegrationProjectLogLine -Level 'OK' -Message "CLI session verified for $($meta.CliName): $($session.Summary)"
                                    }
                                    break
                                }
                                else {
                                    Write-Warning "Could not verify an active session for $($meta.CliName)."
                                    if ($nonInteractive) {
                                        throw "Failed to verify an active CLI session for $($meta.CliName)."
                                    }
                                    $failChoice = Read-Choice -Prompt 'What would you like to do?' `
                                        -Options @('Retry', 'NoSession', 'Cancel') `
                                        -Labels @(
                                            'Retry signing in'
                                            'Continue without a session (type values manually)'
                                            'Cancel'
                                        ) -Default 'Retry'
                                    if ($failChoice -eq 'Retry') {
                                        continue
                                    }
                                    elseif ($failChoice -eq 'NoSession') {
                                        $Context['ConnectionMode'] = 'NoSession'
                                        break
                                    }
                                    else {
                                        Write-Host 'Cancelled.' -ForegroundColor Yellow
                                        if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                                            Close-IntegrationProjectActivityLog
                                        }
                                        $script:LastWizardCancelled = $true
                                        return
                                    }
                                }
                            }
                        }
                        $stage = 5
                    }
                    5 {
                        Write-Step "Integration settings: $($plan.Title)"
                        Collect-IntegrationWizardInputs -Definition $plan -Context $Context -Wizard:$wizard -NonInteractive:$nonInteractive -Discover $Discover
                        $stage = 6
                    }
                    6 {
                        Show-IntegrationWizardSummary -Definition $plan -Context $Context
                        $proceed = if ($Context['Action'] -eq 'Run') {
                            'Run will change the tenant. Proceed?'
                        }
                        else {
                            'Write the local result? The tenant will not be changed.'
                        }
                        if (-not (Read-YesNo -Prompt $proceed -Default $true)) {
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                            if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                                Close-IntegrationProjectActivityLog
                            }
                            $script:LastWizardCancelled = $true
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
                        if (Remove-LastIntegrationWizardInput -Definition $plan -Context $Context) {
                            $stage = 5
                        }
                        elseif ($Context['Action'] -eq 'Check') {
                            if ($plan['AccessLevels'] -and @($plan['AccessLevels']).Count -gt 1) {
                                $Context.Remove('Access')
                                $stage = 3
                            }
                            else {
                                $stage = 2
                            }
                        }
                        else {
                            $Context.Remove('ConnectionMode')
                            $stage = 4
                        }
                        continue
                    }
                    elseif ($stage -eq 5) {
                        if ($Context['Action'] -eq 'Check') {
                            if ($plan['AccessLevels'] -and @($plan['AccessLevels']).Count -gt 1) {
                                $Context.Remove('Access')
                                $stage = 3
                            }
                            else {
                                $stage = 2
                            }
                            continue
                        }
                        $Context.Remove('ConnectionMode')
                        $stage = 4
                        continue
                    }
                    elseif ($stage -eq 4) {
                        if ($plan['AccessLevels'] -and @($plan['AccessLevels']).Count -gt 1) {
                            $Context.Remove('Access')
                            $stage = 3
                        }
                        else {
                            $stage = 2
                        }
                        continue
                    }
                    elseif ($stage -eq 3) {
                        $Context.Remove('Access')
                        $stage = 2
                        continue
                    }
                    elseif ($stage -eq 2) {
                        $meta = $script:IntegrationWizardPlatforms[$Platform]
                        if ($meta -and $meta['CoreOptions']) {
                            foreach ($opt in @($meta['CoreOptions'])) {
                                $Context.Remove($opt)
                            }
                        }
                        $Context.Remove('Connector')
                        $Context.Remove('Entro')
                        $pickedTarget = $false
                        $plan = $null
                        $stage = 1
                        continue
                    }
                    elseif ($stage -eq 1) {
                        $Context.Remove('Action')
                        if (-not [string]::IsNullOrWhiteSpace([string]$Context['Project'])) {
                            Write-Host ''
                            Write-Host 'Cancelled.' -ForegroundColor Yellow
                            if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                                Close-IntegrationProjectActivityLog
                            }
                            $script:LastWizardCancelled = $true
                            return
                        }
                        $Context.Remove('IntegrationProjectName')
                        $stage = 0
                        continue
                    }
                    elseif ($stage -eq 0) {
                        Write-Host ''
                        Write-Host 'Cancelled.' -ForegroundColor Yellow
                        if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                            Close-IntegrationProjectActivityLog
                        }
                        $script:LastWizardCancelled = $true
                        return
                    }
                    else {
                        Write-Host ''
                        Write-Host 'Cancelled.' -ForegroundColor Yellow
                        if (Get-Command Close-IntegrationProjectActivityLog -ErrorAction SilentlyContinue) {
                            Close-IntegrationProjectActivityLog
                        }
                        $script:LastWizardCancelled = $true
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
        if (-not $WhatIfPreference -and $Context['IntegrationProjectName'] -and
            $Context['CatalogIntegrationId'] -and $Context['CatalogCredentialKind']) {
            Save-IntegrationProjectCredential -Context $Context -Definition $plan -Platform $Platform -ScriptName $ScriptName | Out-Null
            Write-IntegrationProjectLogLine -Level 'INFO' -Message "Updated credential index for project $($Context['IntegrationProjectName'])"
        }
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
            'gh' {
                $user = gh api user --jq .login 2>$null
                if ($LASTEXITCODE -eq 0 -and $user) {
                    $state.SignedIn = $true
                    $state.Summary = "user $user"
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
        'aws' {
            $method = Read-Choice -Prompt 'AWS login method:' `
                -Options @('Login', 'Sso', 'Configure') `
                -Labels @(
                    'Direct browser login (aws login)'
                    'IAM Identity Center / SSO (aws sso login)'
                    'Access keys / credentials file (aws configure)'
                ) -Default 'Login'
            switch ($method) {
                'Login' { aws login }
                'Sso' {
                    aws sso login
                    if ($LASTEXITCODE -ne 0) {
                        Write-Info 'SSO is not yet configured. Starting SSO setup (aws configure sso)...'
                        aws configure sso
                    }
                }
                'Configure' { aws configure }
            }
        }
        'az' { az login | Out-Null }
        'gcloud' { gcloud auth login }
        'databricks' { databricks auth login | Out-Null }
    }
}

function Get-IntegrationWizardLoginHint {
    param([string]$CliName)
    switch ($CliName) {
        'aws' { return 'Run: aws login  (or aws sso login / aws configure)' }
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
    'Resolve-IntegrationWizardAction'
    'Test-IntegrationWizardRequiredInputs'
    'Get-IntegrationWizardActiveInputs'
    'Test-IntegrationWizardInputWhen'
    'Copy-IntegrationWizardCatalogContext'
    'Start-IntegrationWizardFlow'
    'Get-IntegrationWizardCliSession'
    'Install-IntegrationWizardCli'
    'Invoke-IntegrationWizardCliLogin'
    'Get-IntegrationWizardLoginHint'
    'Test-IntegrationWizardCancelled'
    'Test-PromptBack'
    'Invoke-PromptBack'
)
