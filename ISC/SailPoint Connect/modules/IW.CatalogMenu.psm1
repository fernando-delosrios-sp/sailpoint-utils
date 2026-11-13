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
                'docker-compose' { $pass['DockerCompose'] = $true }
                'kubernetes-helm' { $pass['KubernetesHelm'] = $true }
                'ghes' { $pass['GhesEntro'] = $true }
                'self-managed' { $pass['GitLabSelfManaged'] = $true }
                'smb' { $pass['Smb'] = $true }
                'sftp' { $pass['Sftp'] = $true }
                'winrm' { $pass['WinRm'] = $true }
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
            elseif ($Product -eq 'entro' -and [string]$Binding.VariantId -ne 'ghes' -and $kind -ne 'github.ghesPat') {
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

function Set-IntegrationCatalogOutpostContext {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Outpost
    )
    if ($Outpost['id']) { $Context['OutpostId'] = [string]$Outpost['id'] }
    if ($Outpost['workerGroupName']) { $Context['WorkerGroup'] = [string]$Outpost['workerGroupName'] }
    if ($Outpost['deploymentMode']) { $Context['OutpostDeploymentMode'] = [string]$Outpost['deploymentMode'] }
    if ($Outpost['publicKeyPath']) { $Context['OutpostPublicKeyPath'] = [string]$Outpost['publicKeyPath'] }
}

function Invoke-IntegrationCatalogInlineOutpostSetup {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][string]$WizardRoot,
        [string]$ProjectName
    )
    $launcherPath = Join-Path $WizardRoot 'Entro Outpost.ps1'
    if (-not (Test-Path -LiteralPath $launcherPath)) {
        $alt = Join-Path $WizardRoot 'Entro-Outpost.ps1'
        if (Test-Path -LiteralPath $alt) { $launcherPath = $alt }
        else { throw "Entro Outpost launcher not found: $launcherPath" }
    }
    $mode = Invoke-IntegrationCatalogReadChoice -Prompt 'Select Entro Outpost deployment mode' `
        -Options @('DockerCompose', 'KubernetesHelm') `
        -Labels @('Docker Compose (Linux AMD64 host)', 'Kubernetes Helm (Linux AMD64 nodes)') `
        -Default 'DockerCompose'
    $outAction = Invoke-IntegrationCatalogReadChoice -Prompt 'What should the Entro Outpost setup produce?' `
        -Options @('Run', 'BuildScript', 'BuildRequirements', 'Check') `
        -Labels @(
            'Run (deploy on this target host now)'
            'Build script (generate .ps1 to run on the target Linux host)'
            'Build requirements (checklist of host, network, and registry prerequisites)'
            'Check (verify target host prerequisites)'
        ) `
        -Default 'Run'

    $outParams = @{
        Wizard = $true
        Action = $outAction
    }
    $outParams[$mode] = $true
    if ($ProjectName -and $ProjectName -ne 'ephemeral') {
        $outParams['Project'] = $ProjectName
    }

    & $launcherPath @outParams

    if ((Get-Command Test-IntegrationWizardCancelled -ErrorAction SilentlyContinue) -and (Test-IntegrationWizardCancelled)) {
        return $null
    }
    if ($ProjectName -and $ProjectName -ne 'ephemeral') {
        $latest = @(Find-IntegrationProjectOutpost -ProjectName $ProjectName -DeploymentMode $mode)
        if ($latest.Count -eq 0) {
            $latest = @(Find-IntegrationProjectOutpost -ProjectName $ProjectName)
        }
        if ($latest.Count -gt 0) {
            return $latest[0]
        }
    }
    return $null
}

function Resolve-IntegrationCatalogOutpostDependency {
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [Parameter(Mandatory)][hashtable]$Binding,
        [string]$WizardRoot = (Split-Path $PSScriptRoot -Parent),
        [switch]$NonInteractive
    )
    if (-not $Binding.ContainsKey('RequiresOutpost') -or -not [bool]$Binding['RequiresOutpost']) {
        return $null
    }
    if (-not (Get-Module -Name 'IW.Project')) {
        Import-Module (Join-Path $PSScriptRoot 'IW.Project.psm1') -WarningAction SilentlyContinue | Out-Null
    }
    if (-not (Get-Module -Name 'ISC.OperatorConsole')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue | Out-Null
    }

    $projectName = if ($Context['IntegrationProjectName']) { [string]$Context['IntegrationProjectName'] } else { [string]$Context['Project'] }
    $entries = @(
        if ($projectName -and $projectName -ne 'ephemeral') {
            Find-IntegrationProjectOutpost -ProjectName $projectName
        }
    )

    if (-not [string]::IsNullOrWhiteSpace([string]$Context['OutpostId'])) {
        $matchedById = @($entries | Where-Object { [string]$_['id'] -eq [string]$Context['OutpostId'] })
        if ($matchedById.Count -eq 1) {
            Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $matchedById[0]
            return $matchedById[0]
        }
        if ($entries.Count -gt 0 -and $matchedById.Count -eq 0) {
            throw "Saved Entro Outpost '$($Context['OutpostId'])' was not found in project '$projectName'."
        }
        return $null
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Context['WorkerGroup'])) {
        $matchedByWg = @($entries | Where-Object {
            [string]::Equals([string]$_['workerGroupName'], [string]$Context['WorkerGroup'], [System.StringComparison]::OrdinalIgnoreCase)
        })
        if ($matchedByWg.Count -eq 1) {
            Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $matchedByWg[0]
            return $matchedByWg[0]
        }
        return $null
    }

    if ($NonInteractive) {
        if ($entries.Count -eq 1) {
            Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $entries[0]
            return $entries[0]
        }
        if ($entries.Count -gt 1) {
            throw "Multiple Entro Outposts exist in project '$projectName'. Specify -WorkerGroup or -OutpostId."
        }
        if ([string]$Context['Action'] -eq 'Run') {
            throw "$($Binding.IntegrationTitle) requires an Entro Outpost. Deploy one first via -Platform EntroOutpost or pass -WorkerGroup."
        }
        return $null
    }

    if ($entries.Count -gt 0) {
        Write-Info "$($Binding.IntegrationTitle) requires an Entro Outpost (Worker Group)."
        while ($true) {
            $options = [System.Collections.Generic.List[string]]::new()
            $labels = [System.Collections.Generic.List[string]]::new()
            foreach ($entry in $entries) {
                $options.Add("use:$($entry['id'])")
                $labels.Add("Use existing Outpost '$($entry['workerGroupName'])' [$($entry['deploymentMode']), $($entry['status'])]")
            }
            $options.Add('deploy')
            $labels.Add('Deploy a new Entro Outpost now (Docker Compose or Kubernetes Helm)')
            $options.Add('manual')
            $labels.Add('Continue without linking (type Worker Group name manually)')

            $choice = Invoke-IntegrationCatalogReadChoice -Prompt 'Select Entro Outpost for this integration' `
                -Options @($options) -Labels @($labels) -Default $options[0]

            if ($choice -like 'use:*') {
                $pickedId = $choice.Substring(4)
                $selected = @($entries | Where-Object { [string]$_['id'] -eq $pickedId })[0]
                Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $selected
                Write-Ok "Linked Entro Outpost: $($selected['workerGroupName']) ($($selected['deploymentMode']))"
                return $selected
            }
            if ($choice -eq 'deploy') {
                try {
                    $deployed = Invoke-IntegrationCatalogInlineOutpostSetup -Context $Context -WizardRoot $WizardRoot -ProjectName $projectName
                    if ($deployed) {
                        Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $deployed
                        Write-Ok "Linked new Entro Outpost: $($deployed['workerGroupName']) ($($deployed['deploymentMode']))"
                        return $deployed
                    }
                    $entries = @(if ($projectName -and $projectName -ne 'ephemeral') { Find-IntegrationProjectOutpost -ProjectName $projectName })
                    continue
                }
                catch {
                    if (Test-PromptBack $_) { continue }
                    throw
                }
            }
            if ($choice -eq 'manual') {
                try {
                    $wg = Read-InputString -Prompt 'Worker Group name (leave blank if not yet created)' -Default 'default-outpost'
                    if (-not [string]::IsNullOrWhiteSpace($wg)) { $Context['WorkerGroup'] = $wg }
                    return $null
                }
                catch {
                    if (Test-PromptBack $_) { continue }
                    throw
                }
            }
        }
    }
    else {
        Write-Info "$($Binding.IntegrationTitle) is on-premise/self-hosted and requires an Entro Outpost (Worker Group)."
        while ($true) {
            $choice = Invoke-IntegrationCatalogReadChoice -Prompt 'No Entro Outpost is registered in this project yet. What do you want to do?' `
                -Options @('deploy', 'register', 'skip') `
                -Labels @(
                    'Deploy an Entro Outpost now (Docker Compose or Kubernetes Helm)'
                    'I already have an Outpost deployed elsewhere — register its Worker Group name'
                    'Skip for now (continue with planning / requirements / script generation)'
                ) `
                -Default 'deploy'

            if ($choice -eq 'deploy') {
                try {
                    $deployed = Invoke-IntegrationCatalogInlineOutpostSetup -Context $Context -WizardRoot $WizardRoot -ProjectName $projectName
                    if ($deployed) {
                        Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $deployed
                        Write-Ok "Linked Entro Outpost: $($deployed['workerGroupName']) ($($deployed['deploymentMode']))"
                        return $deployed
                    }
                    $entries = @(if ($projectName -and $projectName -ne 'ephemeral') { Find-IntegrationProjectOutpost -ProjectName $projectName })
                    if ($entries.Count -gt 0) {
                        Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $entries[0]
                        return $entries[0]
                    }
                    continue
                }
                catch {
                    if (Test-PromptBack $_) { continue }
                    throw
                }
            }
            if ($choice -eq 'register') {
                try {
                    $wg = Read-InputString -Prompt 'Existing Worker Group name' -Default 'default-outpost' -Required
                    $depMode = Invoke-IntegrationCatalogReadChoice -Prompt 'Existing Outpost deployment type' `
                        -Options @('DockerCompose', 'KubernetesHelm', 'Unknown') `
                        -Labels @('Docker Compose', 'Kubernetes Helm', 'Other / Unknown') `
                        -Default 'DockerCompose'
                    $pubKey = Read-InputString -Prompt 'Outpost RSA public key path (optional, for encrypted secrets)' -Default ''
                    $Context['WorkerGroup'] = $wg
                    $Context['OutpostDeploymentMode'] = $depMode
                    if (-not [string]::IsNullOrWhiteSpace($pubKey)) { $Context['OutpostPublicKeyPath'] = $pubKey }
                    if ($projectName -and $projectName -ne 'ephemeral') {
                        $regCtx = @{
                            WorkerGroup          = $wg
                            DeploymentMode       = $depMode
                            OutpostPublicKeyPath = $pubKey
                            Action               = 'Run'
                        }
                        $saved = Save-IntegrationProjectOutpost -ProjectName $projectName -Context $regCtx -Status 'External'
                        if ($saved) {
                            Set-IntegrationCatalogOutpostContext -Context $Context -Outpost $saved
                            Write-Ok "Registered existing Entro Outpost: $wg"
                            return $saved
                        }
                    }
                    return $null
                }
                catch {
                    if (Test-PromptBack $_) { continue }
                    throw
                }
            }
            if ($choice -eq 'skip') {
                Write-Info 'Continuing without a linked Entro Outpost.'
                return $null
            }
        }
    }
}

function Resolve-IntegrationCatalogInteractiveSelection {
    param(
        [hashtable]$Context = @{},
        [string]$WizardRoot = (Split-Path $PSScriptRoot -Parent),
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
        $productNames = @(Get-IntegrationCatalogIntegrationProductIds -Integration $integration)
        if ($productNames.Count -eq 1) {
            $Context['CatalogProduct'] = $productNames[0]
        }
        else {
            if ($NonInteractive) {
                throw 'Non-interactive catalog flow requires CatalogProduct (fabric, entro, ciem).'
            }
            $productLabels = @($productNames | ForEach-Object {
                $meta = $catalog.products.$_
                if ($meta -and $meta.label) { [string]$meta.label } else { $_ }
            })
            $pickedProduct = Invoke-IntegrationCatalogReadChoice -Prompt 'Select product' -Options $productNames -Labels $productLabels -Default $productNames[0]
            $Context['CatalogProduct'] = $pickedProduct
        }
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

    $credential = $null
    if ([string]$integration.id -ne 'entro-outpost') {
        $credential = Resolve-IntegrationCatalogCredentialReuse -Context $Context -Binding $binding -NonInteractive:$NonInteractive
    }
    $outpost = Resolve-IntegrationCatalogOutpostDependency -Context $Context -Binding $binding -WizardRoot $WizardRoot -NonInteractive:$NonInteractive

    return @{
        Integration = $integration
        Binding     = $binding
        Product     = $product
        Context     = $Context
        Credential  = $credential
        Outpost     = $outpost
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
        [hashtable]$OutpostParameters = @{},
        [hashtable]$Credential
    )
    $launcherName = [string]$Integration.launcher
    $launcherPath = Join-Path $WizardRoot $launcherName
    if (-not (Test-Path -LiteralPath $launcherPath)) {
        $alt = Join-Path $WizardRoot ($launcherName -replace ' ', '-')
        if (Test-Path -LiteralPath $alt) { $launcherPath = $alt }
        else { throw "Launcher not found: $launcherPath" }
    }
    $outpostParamNames = @('WorkerGroup', 'OutpostId', 'OutpostPublicKeyPath', 'OutpostDeploymentMode')
    $candidateOutpost = @{}
    foreach ($k in @($OutpostParameters.Keys)) {
        if ($null -ne $OutpostParameters[$k] -and -not [string]::IsNullOrWhiteSpace([string]$OutpostParameters[$k])) {
            $candidateOutpost[$k] = $OutpostParameters[$k]
        }
    }

    $pass = @{}
    foreach ($k in $BaseParameters.Keys) {
        if ($outpostParamNames -contains $k) {
            if ($null -ne $BaseParameters[$k] -and -not [string]::IsNullOrWhiteSpace([string]$BaseParameters[$k])) {
                $candidateOutpost[$k] = $BaseParameters[$k]
            }
            continue
        }
        $pass[$k] = $BaseParameters[$k]
    }
    $pass['Wizard'] = $true
    foreach ($entry in (Get-IntegrationCatalogLegacyLaunchParameters -Binding $Binding -Product $Product).GetEnumerator()) {
        $pass[$entry.Key] = $entry.Value
    }

    $command = Get-Command -Name $launcherPath -ErrorAction Stop
    $compatibleSets = @(Get-IntegrationCatalogCompatibleParameterSets -Command $command -Parameters $pass)
    foreach ($ok in @($candidateOutpost.Keys)) {
        if (Test-IntegrationCatalogLauncherParameter -Name $ok -Command $command -CompatibleSets $compatibleSets) {
            $pass[$ok] = $candidateOutpost[$ok]
            $candidateSets = @($compatibleSets | Where-Object { @($_.Parameters.Name) -contains $ok })
            if ($candidateSets.Count -gt 0) { $compatibleSets = $candidateSets }
        }
    }
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
        $sel = Resolve-IntegrationCatalogInteractiveSelection -Context $ctx -WizardRoot $WizardRoot -NonInteractive:$NonInteractive
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

    $outpostPass = @{}
    foreach ($ok in @('WorkerGroup', 'OutpostId', 'OutpostPublicKeyPath', 'OutpostDeploymentMode')) {
        if ($ctx.ContainsKey($ok) -and -not [string]::IsNullOrWhiteSpace([string]$ctx[$ok])) {
            $outpostPass[$ok] = [string]$ctx[$ok]
        }
    }

    try {
        Invoke-IntegrationCatalogLauncher -WizardRoot $WizardRoot -Integration $sel['Integration'] `
            -Binding $sel['Binding'] -Product $sel['Product'] -BaseParameters $basePass `
            -OutpostParameters $outpostPass -Credential $sel['Credential']
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
    'Resolve-IntegrationCatalogOutpostDependency'
    'Resolve-IntegrationCatalogInteractiveSelection'
    'Invoke-IntegrationCatalogLauncher'
    'Start-IntegrationCatalogRootMenu'
    'Get-IntegrationCatalogRootMenuExtras'
)
