Set-StrictMode -Version Latest

function Invoke-IntegrationCatalogReadChoice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels,
        [string]$Default,
        [switch]$EscapeMeansDefault
    )
    if ($env:SAILPOINT_CONNECT_TEST_CATALOG_PROMPT_BACK -in @('1', 'true', '$true', 'True')) {
        if (-not (Get-Command Invoke-PromptBack -ErrorAction SilentlyContinue)) {
            Import-Module (Join-Path $PSScriptRoot 'IW.Core.psm1') -Force -WarningAction SilentlyContinue | Out-Null
        }
        Invoke-PromptBack
    }
    if (-not (Get-Module -Name 'ISC.OperatorConsole')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue | Out-Null
    }
    $readChoice = Get-Command -Name 'Read-Choice' -Module 'ISC.OperatorConsole' -ErrorAction Stop
    & $readChoice @PSBoundParameters
}

function Get-IntegrationCatalogIntegrationProductIds {
    param([Parameter(Mandatory)]$Integration)
    $products = $Integration.products
    if ($null -eq $products) { return @() }
    if ($products -is [System.Collections.IDictionary]) {
        return @($products.Keys | ForEach-Object { [string]$_ })
    }
    if (@($products.PSObject.Properties).Count -gt 0) {
        return @($products.PSObject.Properties | ForEach-Object { [string]$_.Name })
    }
    return @()
}

function Get-IntegrationCatalogLegacyLaunchParameters {
    param(
        [Parameter(Mandatory)][hashtable]$Binding,
        [Parameter(Mandatory)][string]$Product
    )
    $pass = [ordered]@{}
    $integrationId = [string]$Binding.IntegrationId
    switch ($Product) {
        'fabric' {
            switch ($integrationId) {
                'aws' { $pass['SaaSConnector'] = $true }
                'google-cloud' { $pass['SaaSConnector'] = $true }
                default { $pass['Connector'] = $true }
            }
        }
        'ciem' {
            if ($integrationId -eq 'azure') {
                $pass['Connector'] = $true
                $pass['Feature'] = @('Ciem')
            }
            else {
                $pass['CiemConnector'] = $true
            }
        }
        'entro' {
            switch ([string]$Binding.VariantId) {
                'gcp-org' { $pass['GcpEntro'] = $true }
                'workspace' { $pass['WorkspaceEntro'] = $true }
                default { $pass['Entro'] = $true }
            }
        }
        default { throw "Unknown catalog product: $Product" }
    }
    $defaults = $Binding.ContextDefaults
    if ($defaults -and $defaults.Count -gt 0) {
        foreach ($key in @($defaults.Keys)) {
            if ($key -eq 'Feature' -and $pass.Contains('Feature')) {
                $merged = [System.Collections.Generic.List[string]]::new()
                foreach ($f in @($pass['Feature'])) { $merged.Add([string]$f) }
                foreach ($f in @($defaults['Feature'] -split ',')) {
                    $t = $f.Trim()
                    if ($t -and -not $merged.Contains($t)) { $merged.Add($t) }
                }
                $pass['Feature'] = $merged.ToArray()
            }
            else {
                $pass[$key] = $defaults[$key]
            }
        }
    }
    if ($Binding.ContainsKey('SelectedCredentialKind') -and $Binding['SelectedCredentialKind']) {
        $kind = [string]$Binding['SelectedCredentialKind']
        $pass['CatalogCredentialKind'] = $kind
        if ($integrationId -eq 'github') {
            if ($Product -eq 'fabric') {
                $pass['AuthMethod'] = if ($kind -eq 'github.pat') { 'PersonalAccessToken' } else { 'GitHubApp' }
            }
            elseif ($Product -eq 'entro') {
                $pass['Method'] = if ($kind -eq 'github.pat') { 'ClassicPAT' } else { 'GitHubApp' }
            }
        }
        elseif ($integrationId -eq 'google-cloud' -and [string]$Binding.VariantId -eq 'gcp-org') {
            if ($kind -eq 'gcp.workloadIdentity') { $pass['Method'] = 'WorkloadIdentity' }
            elseif ($kind -eq 'gcp.serviceAccountKey') { $pass['Method'] = 'PrivateKey' }
        }
        elseif ($integrationId -eq 'databricks' -and $kind -eq 'entra.appClientSecret') {
            $pass['Auth'] = 'Entra'
        }
    }
    $pass['CatalogIntegrationId'] = $integrationId
    $pass['CatalogProduct'] = $Product
    $pass['CatalogVariantId'] = [string]$Binding.VariantId
    return $pass
}

function Format-IntegrationCatalogCredentialLabel {
    param([Parameter(Mandatory)][hashtable]$Entry)
    $identity = @($Entry['discriminators'].Keys | Sort-Object | ForEach-Object { "$_=$($Entry['discriminators'][$_])" })
    $identityText = if ($identity.Count -gt 0) { $identity -join ', ' } else { 'no recorded discriminators' }
    $products = @($Entry['uses'] | ForEach-Object { [string]$_['product'] } | Where-Object { $_ } | Sort-Object -Unique)
    $productText = if ($products.Count -gt 0) { $products -join '/' } else { 'saved' }
    return "$identityText [$productText; last: $($Entry['lastAction']) $($Entry['updatedAt'])]"
}

function Resolve-IntegrationCatalogCredentialReuse {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Binding,
        [switch]$NonInteractive
    )
    $projectName = if ($Context['IntegrationProjectName']) { [string]$Context['IntegrationProjectName'] } else { [string]$Context['Project'] }
    $integrationId = [string]$Binding.IntegrationId
    $credentialKind = [string]$Binding['SelectedCredentialKind']
    $mode = if ($Context['CatalogReuseMode']) { [string]$Context['CatalogReuseMode'] } else { $null }
    if (-not $mode -and $NonInteractive) { $mode = 'CreateNew' }
    if ($mode -and $mode -notin @('CreateNew', 'UpdateExisting')) { throw "Unknown catalog reuse mode: $mode" }
    if (-not $projectName -or $projectName -eq 'ephemeral' -or $mode -eq 'CreateNew') {
        $Context['CatalogReuseMode'] = 'CreateNew'
        $Context.Remove('CatalogCredentialId')
        return $null
    }

    if (-not (Get-Module -Name 'IW.Project')) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Project.psm1') -WarningAction SilentlyContinue | Out-Null
    }
    $entries = @(Find-IntegrationProjectCredential -ProjectName $projectName -IntegrationId $integrationId -CredentialKind $credentialKind)
    $credentialId = [string]$Context['CatalogCredentialId']
    if ($credentialId) {
        $matched = @($entries | Where-Object { [string]$_['id'] -eq $credentialId })
        if ($matched.Count -ne 1) {
            throw "Saved credential '$credentialId' was not found for $integrationId/$credentialKind in project '$projectName'."
        }
        $Context['CatalogReuseMode'] = 'UpdateExisting'
        return $matched[0]
    }
    if ($NonInteractive) {
        if ($mode -eq 'UpdateExisting') {
            throw 'Non-interactive update requires CatalogCredentialId. Saved credentials are never selected implicitly.'
        }
        $Context['CatalogReuseMode'] = 'CreateNew'
        return $null
    }
    if ($entries.Count -eq 0) {
        $Context['CatalogReuseMode'] = 'CreateNew'
        return $null
    }

    while ($true) {
        $choice = Invoke-IntegrationCatalogReadChoice -Prompt 'A saved credential of this kind exists. What do you want to do?' `
            -Options @('UpdateExisting', 'CreateNew') `
            -Labels @('Update a saved credential (add configuration only; no secret rotation)', 'Create a new credential') `
            -Default 'UpdateExisting'
        if ($choice -eq 'CreateNew') {
            $Context['CatalogReuseMode'] = 'CreateNew'
            $Context.Remove('CatalogCredentialId')
            return $null
        }
        $selected = $null
        if ($entries.Count -eq 1) {
            $selected = $entries[0]
        }
        else {
            try {
                $ids = @($entries | ForEach-Object { [string]$_['id'] })
                $labels = @($entries | ForEach-Object { Format-IntegrationCatalogCredentialLabel -Entry $_ })
                $pickedId = Invoke-IntegrationCatalogReadChoice -Prompt 'Which saved credential should be updated?' `
                    -Options $ids -Labels $labels -Default $ids[0]
                $selected = @($entries | Where-Object { [string]$_['id'] -eq $pickedId })[0]
            }
            catch {
                if (Test-PromptBack $_) { continue }
                throw
            }
        }
        $Context['CatalogReuseMode'] = 'UpdateExisting'
        $Context['CatalogCredentialId'] = [string]$selected['id']
        return $selected
    }
}

function Resolve-IntegrationCatalogInteractiveSelection {
    param(
        [hashtable]$Context = @{},
        [switch]$NonInteractive
    )
    Import-Module (Join-Path $PSScriptRoot 'IW.Catalog.psm1') -Force -WarningAction SilentlyContinue | Out-Null
    $catalog = Get-IntegrationWizardCatalog

    if (-not $Context['IntegrationProjectName'] -and -not $Context['Project']) {
        if (-not (Get-Module -Name 'IW.Project')) {
            Import-Module (Join-Path $PSScriptRoot 'IW.Project.psm1') -Force -WarningAction SilentlyContinue | Out-Null
        }
        Select-IntegrationProjectWorkspace -Context $Context
    }
    elseif ($Context['Project'] -and -not $Context['IntegrationProjectName']) {
        $Context['IntegrationProjectName'] = [string]$Context['Project']
    }

    if (-not $Context['Action']) {
        if ($NonInteractive) {
            throw 'Non-interactive catalog flow requires -Action.'
        }
        Import-Module (Join-Path $PSScriptRoot 'IW.Core.psm1') -Force -WarningAction SilentlyContinue | Out-Null
        Resolve-IntegrationWizardAction -Context $Context -Wizard
    }

    if (-not $Context['CatalogIntegrationId']) {
        if ($NonInteractive) {
            throw 'Non-interactive catalog flow requires catalog integration id (CatalogIntegrationId).'
        }
        $integrations = @(Get-IntegrationCatalogIntegrations)
        $options = [System.Collections.Generic.List[string]]::new()
        $labels = [System.Collections.Generic.List[string]]::new()
        foreach ($row in $integrations) {
            $options.Add([string]$row.id)
            $labels.Add([string]$row.title)
        }
        foreach ($extra in @(Get-IntegrationCatalogRootMenuExtras)) {
            $options.Add([string]$extra.Id)
            $labels.Add([string]$extra.Label)
        }
        $picked = Invoke-IntegrationCatalogReadChoice -Prompt 'Select integration' -Options @($options) -Labels @($labels) -Default $options[0]
        if ($picked -in @('IQService', 'M365AccessProfiles', 'Update')) {
            return @{ Special = $picked; Context = $Context }
        }
        $Context['CatalogIntegrationId'] = $picked
    }

    $integration = Get-IntegrationCatalogIntegration -IntegrationId ([string]$Context['CatalogIntegrationId'])
    if (-not $Context['CatalogProduct']) {
        if ($NonInteractive) {
            throw 'Non-interactive catalog flow requires CatalogProduct (fabric, entro, ciem).'
        }
        $productNames = @(Get-IntegrationCatalogIntegrationProductIds -Integration $integration)
        $productLabels = @($productNames | ForEach-Object {
            $meta = $catalog.products.$_
            if ($meta -and $meta.label) { [string]$meta.label } else { $_ }
        })
        $pickedProduct = Invoke-IntegrationCatalogReadChoice -Prompt 'Select product' -Options $productNames -Labels $productLabels -Default $productNames[0]
        $Context['CatalogProduct'] = $pickedProduct
    }

    $product = [string]$Context['CatalogProduct']
    $bindings = @(Get-IntegrationCatalogFlatBindings -IntegrationId ([string]$integration.id) -Product $product)
    $binding = $null
    if ($Context['CatalogVariantId']) {
        $binding = Resolve-IntegrationCatalogBinding -IntegrationId ([string]$integration.id) -Product $product `
            -VariantId ([string]$Context['CatalogVariantId'])
    }
    elseif ($bindings.Count -eq 1) {
        $binding = $bindings[0]
    }
    else {
        if ($NonInteractive) {
            throw "Non-interactive catalog flow requires CatalogVariantId for $product on $($integration.id)."
        }
        $vOptions = @($bindings | ForEach-Object { [string]$_.VariantId })
        $vLabels = @($bindings | ForEach-Object { [string]$_.Label })
        $pickedVariant = Invoke-IntegrationCatalogReadChoice -Prompt 'Select variant' -Options $vOptions -Labels $vLabels -Default $vOptions[0]
        $binding = Resolve-IntegrationCatalogBinding -IntegrationId ([string]$integration.id) -Product $product -VariantId $pickedVariant
    }

    $kinds = @($binding.CredentialKinds)
    if ($kinds.Count -gt 1 -and -not $Context['CatalogCredentialKind']) {
        if ($NonInteractive) {
            throw 'Non-interactive catalog flow requires CatalogCredentialKind when multiple kinds are available.'
        }
        $kindLabels = @($kinds | ForEach-Object {
            (Get-IntegrationCatalogCredentialKind -KindId $_).Label
        })
        $pickedKind = Invoke-IntegrationCatalogReadChoice -Prompt 'Select credential kind' -Options $kinds -Labels $kindLabels -Default $kinds[0]
        $binding = Resolve-IntegrationCatalogBinding -IntegrationId ([string]$integration.id) -Product $product `
            -VariantId ([string]$binding.VariantId) -CredentialKind $pickedKind
    }
    elseif ($kinds.Count -eq 1) {
        $binding['SelectedCredentialKind'] = $kinds[0]
    }
  elseif ($Context['CatalogCredentialKind']) {
        $binding = Resolve-IntegrationCatalogBinding -IntegrationId ([string]$integration.id) -Product $product `
            -VariantId ([string]$binding.VariantId) -CredentialKind ([string]$Context['CatalogCredentialKind'])
    }

    $Context['CatalogCredentialKind'] = [string]$binding['SelectedCredentialKind']
    $Context['CatalogVariantId'] = [string]$binding.VariantId
    $credential = Resolve-IntegrationCatalogCredentialReuse -Context $Context -Binding $binding -NonInteractive:$NonInteractive

    return @{
        Integration = $integration
        Binding     = $binding
        Product     = $product
        Context     = $Context
        Credential  = $credential
    }
}

function Get-IntegrationCatalogCompatibleParameterSets {
    param(
        [Parameter(Mandatory)]$Command,
        [Parameter(Mandatory)][hashtable]$Parameters
    )
    $compatible = [System.Collections.Generic.List[object]]::new()
    foreach ($set in @($Command.ParameterSets)) {
        $names = @($set.Parameters | ForEach-Object { [string]$_.Name })
        $matches = $true
        foreach ($name in @($Parameters.Keys)) {
            if ($names -notcontains [string]$name) { $matches = $false; break }
        }
        if (-not $matches) { continue }
        $hasMissingMandatorySwitch = $false
        foreach ($param in @($set.Parameters)) {
            if ($param.IsMandatory -and ($param.ParameterType -eq [switch] -or $param.ParameterType -eq [System.Management.Automation.SwitchParameter])) {
                if (-not $Parameters.ContainsKey($param.Name) -or -not [bool]$Parameters[$param.Name]) {
                    $hasMissingMandatorySwitch = $true
                    break
                }
            }
        }
        if ($hasMissingMandatorySwitch) { continue }
        $compatible.Add($set)
    }
    return @($compatible)
}

function Test-IntegrationCatalogLauncherParameter {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Command,
        [object[]]$CompatibleSets = @()
    )
    if (-not $Command.Parameters.ContainsKey($Name)) { return $false }
    if ($CompatibleSets.Count -eq 0) { return $true }
    return @($CompatibleSets | Where-Object { @($_.Parameters.Name) -contains $Name }).Count -gt 0
}

function Invoke-IntegrationCatalogLauncher {
    param(
        [Parameter(Mandatory)][string]$WizardRoot,
        [Parameter(Mandatory)]$Integration,
        [Parameter(Mandatory)][hashtable]$Binding,
        [Parameter(Mandatory)][string]$Product,
        [hashtable]$BaseParameters = @{},
        [hashtable]$Credential
    )
    $launcherName = [string]$Integration.launcher
    $launcherPath = Join-Path $WizardRoot $launcherName
    if (-not (Test-Path -LiteralPath $launcherPath)) {
        $alt = Join-Path $WizardRoot ($launcherName -replace ' ', '-')
        if (Test-Path -LiteralPath $alt) { $launcherPath = $alt }
        else { throw "Launcher not found: $launcherPath" }
    }
    $pass = @{}
    foreach ($k in $BaseParameters.Keys) { $pass[$k] = $BaseParameters[$k] }
    $pass['Wizard'] = $true
    foreach ($entry in (Get-IntegrationCatalogLegacyLaunchParameters -Binding $Binding -Product $Product).GetEnumerator()) {
        $pass[$entry.Key] = $entry.Value
    }

    $command = Get-Command -Name $launcherPath -ErrorAction Stop
    $compatibleSets = @(Get-IntegrationCatalogCompatibleParameterSets -Command $command -Parameters $pass)
    if ($Credential) {
        $pass['CatalogReuseMode'] = 'UpdateExisting'
        $pass['CatalogCredentialId'] = [string]$Credential['id']
        $secretFields = @()
        if ($Binding['SelectedCredentialKind']) {
            if (-not (Get-Command Get-IntegrationCatalogCredentialKind -ErrorAction SilentlyContinue)) {
                Import-Module (Join-Path $PSScriptRoot 'IW.Catalog.psm1') -WarningAction SilentlyContinue | Out-Null
            }
            $secretFields = @((Get-IntegrationCatalogCredentialKind -KindId ([string]$Binding['SelectedCredentialKind'])).SecretFields)
        }
        foreach ($name in @($Credential['inputs'].Keys)) {
            if ($pass.ContainsKey($name)) { continue }
            if ($name -in @('OutputDirectory', 'RotateSecret', 'RotateKey', 'Project', 'Action', 'NonInteractive', 'Wizard')) { continue }
            if ($secretFields -contains $name -or $name -match '(?i)secret|password|token|privatekey') { continue }
            $value = $Credential['inputs'][$name]
            if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value) -or [string]$value -eq '***') { continue }
            $candidateSets = @($compatibleSets | Where-Object { @($_.Parameters.Name) -contains $name })
            if (-not (Test-IntegrationCatalogLauncherParameter -Name $name -Command $command -CompatibleSets $compatibleSets)) { continue }
            $pass[$name] = $value
            if ($candidateSets.Count -gt 0) { $compatibleSets = $candidateSets }
        }
        foreach ($rotationName in @('RotateSecret', 'RotateKey')) {
            if (Test-IntegrationCatalogLauncherParameter -Name $rotationName -Command $command -CompatibleSets $compatibleSets) {
                $pass[$rotationName] = $false
            }
        }
    }
    & $launcherPath @pass
}

function Start-IntegrationCatalogRootMenu {
    param(
        [Parameter(Mandatory)][string]$WizardRoot,
        [string]$Project,
        [string]$Action,
        [string]$OutputDirectory,
        [string]$OutputFormat,
        [switch]$NonInteractive
    )
    Import-Module (Join-Path $WizardRoot 'modules/IW.Catalog.psm1') -Force -WarningAction SilentlyContinue | Out-Null
    Import-Module (Join-Path $WizardRoot 'modules/IW.Project.psm1') -Force -WarningAction SilentlyContinue | Out-Null
    $operatorConsolePath = Join-Path $WizardRoot 'modules/ISC.OperatorConsole.psm1'
    if (-not (Get-Module -Name 'ISC.OperatorConsole')) {
        Import-Module $operatorConsolePath -Force -WarningAction SilentlyContinue | Out-Null
    }

    $ctx = @{
        Project          = $Project
        Action           = $Action
        NonInteractive   = [bool]$NonInteractive
    }
    if ($OutputDirectory) { $ctx['OutputDirectory'] = $OutputDirectory }

    try {
        $sel = Resolve-IntegrationCatalogInteractiveSelection -Context $ctx -NonInteractive:$NonInteractive
    }
    catch {
        if (Test-CancelledNavigation $_) {
            Write-Host ''
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return @{ Cancelled = $true }
        }
        throw
    }

    if ($sel.ContainsKey('Special') -and $sel['Special']) {
        return @{ Platform = [string]$sel['Special']; Context = $sel['Context'] }
    }

    $basePass = @{}
    if ($Project) { $basePass['Project'] = $Project }
    if ($ctx['IntegrationProjectName']) { $basePass['Project'] = [string]$ctx['IntegrationProjectName'] }
    if ($ctx['Action']) { $basePass['Action'] = [string]$ctx['Action'] }
    if ($OutputDirectory) { $basePass['OutputDirectory'] = $OutputDirectory }
    if ($OutputFormat) { $basePass['OutputFormat'] = $OutputFormat }
    if ($NonInteractive) { $basePass['NonInteractive'] = $true }
    if ($ctx['CatalogReuseMode']) { $basePass['CatalogReuseMode'] = [string]$ctx['CatalogReuseMode'] }
    if ($ctx['CatalogCredentialId']) { $basePass['CatalogCredentialId'] = [string]$ctx['CatalogCredentialId'] }

    try {
        Invoke-IntegrationCatalogLauncher -WizardRoot $WizardRoot -Integration $sel['Integration'] `
            -Binding $sel['Binding'] -Product $sel['Product'] -BaseParameters $basePass -Credential $sel['Credential']
    }
    catch {
        if (Test-CancelledNavigation $_) {
            Write-Host ''
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return @{ Cancelled = $true }
        }
        throw
    }
    return @{ Launched = $true }
}

function Get-IntegrationCatalogRootMenuExtras {
    @(
        @{ Id = 'IQService'; Label = 'IQService Control (host lifecycle & AD LDAPS)'; Platform = 'IQService' }
        @{ Id = 'M365AccessProfiles'; Label = 'Microsoft 365 Access Profiles (Entra service plans)'; Platform = 'M365AccessProfiles' }
        @{ Id = 'Update'; Label = 'Update SailPoint Connect'; Platform = 'Update' }
    )
}

Export-ModuleMember -Function @(
    'Get-IntegrationCatalogLegacyLaunchParameters'
    'Resolve-IntegrationCatalogInteractiveSelection'
    'Invoke-IntegrationCatalogLauncher'
    'Start-IntegrationCatalogRootMenu'
    'Get-IntegrationCatalogRootMenuExtras'
)
