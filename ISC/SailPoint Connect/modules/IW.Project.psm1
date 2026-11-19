# SailPoint Connect: projects under ~/.sailpoint-connect/

Set-StrictMode -Version Latest

$script:IntegrationProjectActivityLogPath = $null

function Get-IntegrationProjectRoot {
    if ($env:SAILPOINT_CONNECT_ROOT) {
        return $env:SAILPOINT_CONNECT_ROOT
    }
    Join-Path $HOME '.sailpoint-connect'
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
    $name = if ($Definition['IsComposite']) {
        $parts = @($Definition.Members | ForEach-Object {
            if ($_['FolderName']) { [string]$_['FolderName'] } else { [string]$_.Title }
        })
        # Folder names must stay portable and space-free: avoid '+' and whitespace.
        ($parts -join '-and-')
    }
    elseif ($Definition['FolderName']) {
        [string]$Definition['FolderName']
    }
    else {
        [string]$Definition.Title
    }
    return ($name -replace '\s+', '-')
}

function Select-IntegrationProjectName {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$Preset,
        [switch]$NonInteractive,
        [string]$OutputDirectory
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
        if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
            $ephemeral = 'ephemeral'
            $projPath = Join-Path $Root $ephemeral
            if (-not (Test-Path -LiteralPath $projPath)) {
                New-Item -ItemType Directory -Path $projPath -Force | Out-Null
                Write-IntegrationProjectLogLine -Level 'INFO' -Message "Created project folder: $projPath"
            }
            return $ephemeral
        }
        $existing = @(Get-IntegrationProjectNames -Root $Root)
        $list = if ($existing.Count -gt 0) { ($existing -join ', ') } else { '(none)' }
        throw "Non-interactive run requires -Project. Existing projects under ~/.sailpoint-connect/: $list"
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
        Write-Step 'Integration project workspace (~/.sailpoint-connect/)'
    }
    while ($true) {
        $picked = Read-Choice -Prompt 'Which integration project?' -Options $options -Labels $labels -Default $default
        if ($picked -eq $createToken) {
            try {
                $name = Read-InputString -Prompt 'New project name' -Required
                Test-IntegrationProjectName -Name $name
                $projPath = Join-Path $Root $name
                New-Item -ItemType Directory -Path $projPath -Force | Out-Null
                Write-IntegrationProjectLogLine -Level 'INFO' -Message "Created project folder: $projPath"
                return $name
            }
            catch {
                if (Test-PromptBack $_) {
                    continue
                }
                throw
            }
        }
        return $picked
    }
}

function Get-IntegrationProjectSelectionSnapshot {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ScriptName
    )
    $inputs = [ordered]@{}
    $activeInputs = if (Get-Command Get-IntegrationWizardActiveInputs -ErrorAction SilentlyContinue) {
        @(Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context)
    }
    else {
        @($Definition.Inputs)
    }
    foreach ($input in $activeInputs) {
        if (-not $input) { continue }
        if (-not (Get-Command Test-IntegrationWizardInputWhen -ErrorAction SilentlyContinue)) { continue }
        if (-not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $name = $input.Name
        if ($input['Secret'] -or ($name -match '(?i)secret|password|token|privatekey')) {
            $inputs[$name] = '***'
            continue
        }
        $val = $Context[$name]
        if ($null -eq $val) { continue }
        if ($val -is [array]) { $val = $val -join ',' }
        $inputs[$name] = [string]$val
    }
    $credentialKind = [string]$Context['CatalogCredentialKind']
    $discriminators = if ($credentialKind) {
        Get-IntegrationProjectCredentialDiscriminatorMap -Context $Context -CredentialKind $credentialKind
    }
    else {
        [ordered]@{}
    }
    [ordered]@{
        schemaVersion          = 1
        timestamp              = (Get-Date).ToUniversalTime().ToString('o')
        project                = [string]$Context['IntegrationProjectName']
        platform               = $Platform
        definitionId           = if ($Definition.ContainsKey('Id')) { [string]$Definition['Id'] } else { '' }
        integrationFolder      = Get-IntegrationWizardIntegrationFolderName -Definition $Definition
        script                 = $ScriptName
        target                 = if ($Definition.ContainsKey('Title')) { [string]$Definition['Title'] } else { '' }
        action                 = [string]$Context['Action']
        outputDirectory        = [string]$Context['OutputDirectory']
        outputOverride         = [bool]$Context['IntegrationOutputOverride']
        integrationPath        = [string]$Context['IntegrationFolderPath']
        catalogIntegrationId   = [string]$Context['CatalogIntegrationId']
        catalogProduct         = [string]$Context['CatalogProduct']
        catalogVariantId       = [string]$Context['CatalogVariantId']
        catalogCredentialKind  = $credentialKind
        catalogReuseMode       = [string]$Context['CatalogReuseMode']
        catalogCredentialId    = [string]$Context['CatalogCredentialId']
        discriminators         = $discriminators
        inputs                 = $inputs
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

function Get-IntegrationProjectCredentialIndexPath {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    Test-IntegrationProjectName -Name $ProjectName
    Join-Path (Join-Path $Root $ProjectName) 'credential-index.json'
}

function Read-IntegrationProjectCredentialIndex {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $path = Get-IntegrationProjectCredentialIndexPath -ProjectName $ProjectName -Root $Root
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    try {
        $index = Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    }
    catch {
        throw "Could not read credential index '$path': $($_.Exception.Message)"
    }
    if ($null -eq $index -or -not $index.ContainsKey('entries') -or $null -eq $index['entries']) { return @() }
    return @($index['entries'])
}

function Get-IntegrationProjectCredentialKindMetadata {
    param([Parameter(Mandatory)][string]$CredentialKind)
    if (-not (Get-Command Get-IntegrationCatalogCredentialKind -ErrorAction SilentlyContinue)) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Catalog.psm1') -WarningAction SilentlyContinue | Out-Null
    }
    Get-IntegrationCatalogCredentialKind -KindId $CredentialKind
}

function Get-IntegrationProjectCredentialDiscriminatorMap {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$CredentialKind
    )
    $kind = Get-IntegrationProjectCredentialKindMetadata -CredentialKind $CredentialKind
    $aliases = @{
        RoleName         = @('RoleName', 'EntroRoleName')
        ServiceAccountId = @('ServiceAccountId', 'ServiceAccountName')
        ServiceAccountName = @('ServiceAccountName', 'ServiceAccountId')
        VaultAddress     = @('VaultAddress', 'VaultUrl')
        BaseUrl          = @('BaseUrl', 'GitLabUrl')
    }
    $values = [ordered]@{}
    foreach ($name in @($kind.Discriminators)) {
        $candidateNames = if ($aliases.ContainsKey($name)) { @($aliases[$name]) } else { @($name) }
        foreach ($candidate in $candidateNames) {
            $value = $Context[$candidate]
            if ($null -eq $value) { continue }
            if ($value -is [array]) { $value = $value -join ',' }
            $text = ([string]$value).Trim()
            if (-not $text -or $text -eq '***') { continue }
            $values[$name] = $text
            break
        }
    }
    return $values
}

function Get-IntegrationProjectSafeInputMap {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Definition
    )
    $secretFields = @()
    if ($Context['CatalogCredentialKind']) {
        $kind = Get-IntegrationProjectCredentialKindMetadata -CredentialKind ([string]$Context['CatalogCredentialKind'])
        $secretFields = @($kind.SecretFields)
    }
    $activeInputs = if (Get-Command Get-IntegrationWizardActiveInputs -ErrorAction SilentlyContinue) {
        @(Get-IntegrationWizardActiveInputs -Definition $Definition -Context $Context)
    }
    else {
        @($Definition.Inputs)
    }
    $safe = [ordered]@{}
    foreach ($input in $activeInputs) {
        if (-not $input) { continue }
        if ((Get-Command Test-IntegrationWizardInputWhen -ErrorAction SilentlyContinue) -and
            -not (Test-IntegrationWizardInputWhen -InputDef $input -Context $Context)) { continue }
        $name = [string]$input.Name
        if ($name -in @('OutputDirectory', 'RotateSecret', 'RotateKey')) { continue }
        if ($input['Secret'] -or $secretFields -contains $name -or $name -match '(?i)secret|password|token|privatekey') { continue }
        $value = $Context[$name]
        if ($null -eq $value) { continue }
        if ($value -is [array]) { $value = $value -join ',' }
        $text = ([string]$value).Trim()
        if (-not $text -or $text -eq '***') { continue }
        $safe[$name] = $text
    }
    return $safe
}

function Test-IntegrationProjectCredentialIdentityComplete {
    param(
        [Parameter(Mandatory)][string]$CredentialKind,
        [Parameter(Mandatory)][hashtable]$Discriminators
    )
    if ($Discriminators.Count -eq 0) { return $false }
    $kind = Get-IntegrationProjectCredentialKindMetadata -CredentialKind $CredentialKind
    if ($CredentialKind -eq 'oauth.clientIdSecret') {
        return $Discriminators.ContainsKey('ClientId') -and
            ($Discriminators.ContainsKey('BaseUrl') -or $Discriminators.ContainsKey('InstanceUrl'))
    }
    foreach ($name in @($kind.Discriminators)) {
        if (-not $Discriminators.ContainsKey($name) -or [string]::IsNullOrWhiteSpace([string]$Discriminators[$name])) {
            return $false
        }
    }
    return $true
}

function Compare-IntegrationProjectCredentialDiscriminators {
    param(
        [Parameter(Mandatory)][hashtable]$Left,
        [Parameter(Mandatory)][hashtable]$Right
    )
    if ($Left.Count -ne $Right.Count) { return $false }
    foreach ($name in @($Left.Keys)) {
        if (-not $Right.ContainsKey($name)) { return $false }
        if (-not [string]::Equals(([string]$Left[$name]).Trim(), ([string]$Right[$name]).Trim(), [System.StringComparison]::OrdinalIgnoreCase)) {
            return $false
        }
    }
    return $true
}

function Find-IntegrationProjectCredential {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$IntegrationId,
        [Parameter(Mandatory)][string]$CredentialKind,
        [string]$Product,
        [string]$VariantId,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $matches = @(Read-IntegrationProjectCredentialIndex -ProjectName $ProjectName -Root $Root | Where-Object {
        [string]$_['integrationId'] -eq $IntegrationId -and [string]$_['credentialKind'] -eq $CredentialKind
    })
    if ($Product -or $VariantId) {
        $matches = @($matches | Where-Object {
            $entry = $_
            @($entry['uses'] | Where-Object {
                (-not $Product -or [string]$_['product'] -eq $Product) -and
                (-not $VariantId -or [string]$_['variantId'] -eq $VariantId)
            }).Count -gt 0
        })
    }
    return @($matches | Sort-Object { [string]$_['updatedAt'] } -Descending)
}

function Save-IntegrationProjectCredential {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Definition,
        [Parameter(Mandatory)][string]$Platform,
        [Parameter(Mandatory)][string]$ScriptName,
        [string]$Root = (Get-IntegrationProjectRoot)
    )
    $projectName = [string]$Context['IntegrationProjectName']
    $integrationId = [string]$Context['CatalogIntegrationId']
    $credentialKind = [string]$Context['CatalogCredentialKind']
    if (-not $projectName -or $projectName -eq 'ephemeral' -or -not $integrationId -or -not $credentialKind) { return $null }

    $snapshot = Get-IntegrationProjectSelectionSnapshot -Context $Context -Definition $Definition -Platform $Platform -ScriptName $ScriptName
    $newDiscriminators = @{}
    foreach ($key in @($snapshot.discriminators.Keys)) { $newDiscriminators[$key] = [string]$snapshot.discriminators[$key] }
    $newInputs = Get-IntegrationProjectSafeInputMap -Context $Context -Definition $Definition
    $entries = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($entry in @(Read-IntegrationProjectCredentialIndex -ProjectName $projectName -Root $Root)) { $entries.Add($entry) }

    $existing = $null
    $credentialId = [string]$Context['CatalogCredentialId']
    if ($credentialId) {
        $existing = @($entries | Where-Object { [string]$_['id'] -eq $credentialId })
        if ($existing.Count -ne 1) { throw "Saved credential '$credentialId' was not found in project '$projectName'." }
        $existing = $existing[0]
        if ([string]$existing['integrationId'] -ne $integrationId -or [string]$existing['credentialKind'] -ne $credentialKind) {
            throw "Saved credential '$credentialId' does not match $integrationId/$credentialKind."
        }
    }
    elseif (Test-IntegrationProjectCredentialIdentityComplete -CredentialKind $credentialKind -Discriminators $newDiscriminators) {
        $matches = @($entries | Where-Object {
            [string]$_['integrationId'] -eq $integrationId -and
            [string]$_['credentialKind'] -eq $credentialKind -and
            (Compare-IntegrationProjectCredentialDiscriminators -Left $_['discriminators'] -Right $newDiscriminators)
        })
        if ($matches.Count -eq 1) { $existing = $matches[0] }
    }

    $now = [string]$snapshot.timestamp
    if ($existing) {
        $existingDiscriminators = if ($existing['discriminators']) { $existing['discriminators'] } else { @{} }
        foreach ($name in @($newDiscriminators.Keys)) {
            if ($existingDiscriminators.ContainsKey($name) -and
                -not [string]::Equals(([string]$existingDiscriminators[$name]).Trim(), ([string]$newDiscriminators[$name]).Trim(), [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "The supplied $name does not match saved credential '$($existing['id'])'. Choose Create new instead."
            }
        }
        foreach ($name in @($newDiscriminators.Keys)) { $existingDiscriminators[$name] = $newDiscriminators[$name] }
        $existing['discriminators'] = $existingDiscriminators
        $existingInputs = if ($existing['inputs']) { $existing['inputs'] } else { @{} }
        foreach ($name in @($newInputs.Keys)) { $existingInputs[$name] = $newInputs[$name] }
        $existing['inputs'] = $existingInputs
        $existing['updatedAt'] = $now
        $existing['lastAction'] = [string]$Context['Action']
        $entry = $existing
    }
    else {
        $entry = @{
            schemaVersion   = 1
            id              = if ($credentialId) { $credentialId } else { [Guid]::NewGuid().ToString('N') }
            integrationId   = $integrationId
            credentialKind  = $credentialKind
            discriminators  = $newDiscriminators
            inputs          = $newInputs
            uses            = @()
            createdAt       = $now
            updatedAt       = $now
            lastAction      = [string]$Context['Action']
        }
        $entries.Add($entry)
    }

    $use = @{
        product      = [string]$Context['CatalogProduct']
        variantId    = [string]$Context['CatalogVariantId']
        definitionId = [string]$Definition.Id
        folderName   = [string]$snapshot.integrationFolder
        access       = [string]$Context['Access']
        lastAction   = [string]$Context['Action']
        updatedAt    = $now
    }
    $uses = [System.Collections.Generic.List[hashtable]]::new()
    $replacedUse = $false
    foreach ($currentUse in @($entry['uses'])) {
        if ([string]$currentUse['product'] -eq $use.product -and
            [string]$currentUse['variantId'] -eq $use.variantId -and
            [string]$currentUse['definitionId'] -eq $use.definitionId) {
            if (-not $replacedUse) { $uses.Add($use) }
            $replacedUse = $true
        }
        else {
            $uses.Add($currentUse)
        }
    }
    if (-not $replacedUse) { $uses.Add($use) }
    $entry['uses'] = @($uses)
    $entry['lastProduct'] = $use.product
    $entry['lastVariantId'] = $use.variantId

    $path = Get-IntegrationProjectCredentialIndexPath -ProjectName $projectName -Root $Root
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    $payload = [ordered]@{ schemaVersion = 1; entries = @($entries) }
    Set-Content -LiteralPath $path -Value ($payload | ConvertTo-Json -Depth 10) -Encoding utf8
    return $entry
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
    $outDir = if ($Context['OutputDirectory']) { [string]$Context['OutputDirectory'] } else { $null }
    $projectName = Select-IntegrationProjectName -Root $root -Preset $preset -NonInteractive:([bool]$Context['NonInteractive']) -OutputDirectory $outDir
    if ($projectName -ne 'ephemeral') {
        Set-IntegrationProjectLastSelected -ProjectName $projectName -Root $root
    }

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

    $outputOverride = -not [string]::IsNullOrWhiteSpace([string]$Context['OutputDirectory'])
    $folderName = Get-IntegrationWizardIntegrationFolderName -Definition $Plan
    $platformFolder = if ($platformTitle) { $platformTitle -replace '\s+', '-' } else { $platformTitle }
    $integrationPath = if ($projectName -eq 'ephemeral' -and $outputOverride) {
        [string]$Context['OutputDirectory']
    } else {
        Join-Path (Join-Path (Join-Path $root $projectName) $platformFolder) $folderName
    }
    if (-not (Test-Path -LiteralPath $integrationPath)) {
        New-Item -ItemType Directory -Path $integrationPath -Force | Out-Null
    }

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
        $displayPath = if (Get-Command Format-TerminalHyperlink -ErrorAction SilentlyContinue) {
            Format-TerminalHyperlink -Path $integrationPath
        } else {
            $integrationPath
        }
        Write-Info "Artifacts: $displayPath"
        if ($outputOverride) {
            $displayOverride = if (Get-Command Format-TerminalHyperlink -ErrorAction SilentlyContinue) {
                Format-TerminalHyperlink -Path $Context['OutputDirectory']
            } else {
                $Context['OutputDirectory']
            }
            Write-Info "Output override: $displayOverride"
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
    'Get-IntegrationProjectCredentialIndexPath'
    'Read-IntegrationProjectCredentialIndex'
    'Get-IntegrationProjectCredentialDiscriminatorMap'
    'Find-IntegrationProjectCredential'
    'Save-IntegrationProjectCredential'
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
