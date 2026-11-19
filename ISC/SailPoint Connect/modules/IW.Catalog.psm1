Set-StrictMode -Version Latest

$script:IntegrationWizardCatalog = $null
$script:IntegrationWizardCatalogPath = $null

function Get-IntegrationWizardRootFromCatalogModule {
    Split-Path $PSScriptRoot -Parent
}

function Get-IntegrationWizardCatalogPath {
    param([string]$WizardRoot = (Get-IntegrationWizardRootFromCatalogModule))
    Join-Path $WizardRoot 'catalog/wizard-catalog.json'
}

function Import-IntegrationWizardCatalog {
    param(
        [string]$Path,
        [switch]$Force
    )
    if (-not $Force -and $null -ne $script:IntegrationWizardCatalog) {
        return $script:IntegrationWizardCatalog
    }
    if (-not $Path) {
        $Path = Get-IntegrationWizardCatalogPath
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Integration wizard catalog not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    $catalog = $raw | ConvertFrom-Json
    if (-not $catalog) {
        throw "Integration wizard catalog is empty or invalid: $Path"
    }
    $null = Test-IntegrationWizardCatalog -Catalog $catalog -WizardRoot (Split-Path $Path -Parent | Split-Path -Parent)
    $script:IntegrationWizardCatalog = $catalog
    $script:IntegrationWizardCatalogPath = $Path
    return $catalog
}

function Get-IntegrationWizardCatalog {
    param([switch]$Force)
    if ($Force -or $null -eq $script:IntegrationWizardCatalog) {
        return (Import-IntegrationWizardCatalog -Force:$Force)
    }
    $script:IntegrationWizardCatalog
}

function Get-IntegrationCatalogIntegrations {
    param($Catalog = (Get-IntegrationWizardCatalog))
    @($Catalog.integrations)
}

function Get-IntegrationCatalogIntegration {
    param(
        [Parameter(Mandatory)][string]$IntegrationId,
        $Catalog = (Get-IntegrationWizardCatalog)
    )
    $match = @($Catalog.integrations | Where-Object { [string]$_.id -eq $IntegrationId })
    if ($match.Count -eq 0) {
        throw "Unknown integration id: $IntegrationId"
    }
    if ($match.Count -gt 1) {
        throw "Duplicate integration id in catalog: $IntegrationId"
    }
    $match[0]
}

function Get-IntegrationCatalogCoverageValues {
    @('SailPoint Fabric', 'SailPoint Fabric (ISC)', 'Entro')
}

function Get-IntegrationCatalogProductNames {
    param($Catalog = (Get-IntegrationWizardCatalog))
    return @(Get-IntegrationCatalogIntegrations -Catalog $Catalog | ForEach-Object { [string]$_.coverage } | Sort-Object -Unique)
}

function Get-IntegrationCatalogCredentialKind {
    param(
        [Parameter(Mandatory)][string]$KindId,
        $Catalog = (Get-IntegrationWizardCatalog)
    )
    $prop = $Catalog.credentialKinds.PSObject.Properties | Where-Object { $_.Name -eq $KindId }
    if (-not $prop) {
        throw "Unknown credential kind: $KindId"
    }
    [ordered]@{
        Id             = $KindId
        Label          = [string]$prop.Value.label
        Discriminators = @($prop.Value.discriminators)
        SecretFields   = @($prop.Value.secretFields)
        CheckSubject   = [string]$prop.Value.checkSubject
    }
}

function Get-IntegrationCatalogFlatBindings {
    param(
        [string]$IntegrationId,
        [string]$Coverage,
        [string]$Product,
        $Catalog = (Get-IntegrationWizardCatalog)
    )
    $flat = [System.Collections.Generic.List[object]]::new()
    $integrations = if ($IntegrationId) {
        @(Get-IntegrationCatalogIntegration -IntegrationId $IntegrationId -Catalog $Catalog)
    }
    else {
        Get-IntegrationCatalogIntegrations -Catalog $Catalog
    }
    $filterCoverage = if ($Coverage) { $Coverage } elseif ($Product) { $Product } else { '' }
    foreach ($integration in $integrations) {
        $coverageLabel = [string]$integration.coverage
        if ($filterCoverage -and $coverageLabel -ne $filterCoverage) { continue }
        $bindings = @($integration.bindings)
        foreach ($binding in $bindings) {
            $hosting = if ($binding.PSObject.Properties.Name -contains 'hosting' -and $binding.hosting) {
                [string]$binding.hosting
            } elseif ($integration.PSObject.Properties.Name -contains 'hosting' -and $integration.hosting) {
                [string]$integration.hosting
            } else {
                'saas'
            }
            $targetHostRole = if ($binding.PSObject.Properties.Name -contains 'targetHostRole' -and $binding.targetHostRole) {
                [string]$binding.targetHostRole
            } elseif ($integration.PSObject.Properties.Name -contains 'targetHostRole' -and $integration.targetHostRole) {
                [string]$integration.targetHostRole
            } else {
                ''
            }
            $defIds = if ($binding.PSObject.Properties.Name -contains 'definitionIds' -and $binding.definitionIds) {
                @($binding.definitionIds | ForEach-Object { [string]$_ })
            } else {
                @([string]$binding.definitionId)
            }
            $defModules = if ($binding.PSObject.Properties.Name -contains 'definitionModules' -and $binding.definitionModules) {
                @($binding.definitionModules | ForEach-Object { [string]$_ })
            } else {
                @([string]$binding.definitionModule)
            }
            $legacySwitches = if ($binding.PSObject.Properties.Name -contains 'legacySwitches' -and $binding.legacySwitches) {
                @($binding.legacySwitches | ForEach-Object { [string]$_ })
            } else {
                @()
            }
            $flat.Add([ordered]@{
                IntegrationId     = [string]$integration.id
                IntegrationTitle  = [string]$integration.title
                Coverage          = $coverageLabel
                Product           = $coverageLabel
                PlatformName      = [string]$integration.platformName
                Cli               = [string]$integration.cli
                Launcher          = [string]$integration.launcher
                Hosting           = $hosting
                TargetHostRole    = $targetHostRole
                VariantId         = [string]$binding.variantId
                Label             = [string]$binding.label
                DefinitionId      = [string]$binding.definitionId
                DefinitionIds     = $defIds
                DefinitionModule  = [string]$binding.definitionModule
                DefinitionModules = $defModules
                LegacySwitches    = $legacySwitches
                FolderName        = [string]$binding.folderName
                CredentialKinds   = @($binding.credentialKinds)
                ContextDefaults   = if ($binding.PSObject.Properties.Name -contains 'contextDefaults' -and $binding.contextDefaults) {
                    $h = @{}
                    foreach ($p in $binding.contextDefaults.PSObject.Properties) {
                        $h[$p.Name] = $p.Value
                    }
                    $h
                }
                else { @{} }
            })
        }
    }
    return @($flat)
}

function Resolve-IntegrationCatalogBinding {
    param(
        [Parameter(Mandatory)][string]$IntegrationId,
        [string]$Product,
        [string]$VariantId,
        [string]$CredentialKind,
        $Catalog = (Get-IntegrationWizardCatalog)
    )
    $candidates = @(Get-IntegrationCatalogFlatBindings -IntegrationId $IntegrationId -Catalog $Catalog)
    if ($candidates.Count -eq 0) {
        throw "No bindings for integration '$IntegrationId'."
    }
    if ($VariantId) {
        $candidates = @($candidates | Where-Object { [string]$_.VariantId -eq $VariantId })
        if ($candidates.Count -eq 0) {
            throw "No binding variant '$VariantId' for integration '$IntegrationId'."
        }
    }
    if ($candidates.Count -gt 1 -and -not $VariantId) {
        throw "Multiple bindings for integration '$IntegrationId'; specify -VariantId."
    }
    $binding = $candidates[0]
    if ($CredentialKind) {
        if (@($binding.CredentialKinds) -notcontains $CredentialKind) {
            throw "Credential kind '$CredentialKind' is not valid for binding $($binding.VariantId)."
        }
        $binding['SelectedCredentialKind'] = $CredentialKind
    }
    return $binding
}

function Test-IntegrationWizardCatalog {
    param(
        [Parameter(Mandatory)]$Catalog,
        [string]$WizardRoot = (Get-IntegrationWizardRootFromCatalogModule)
    )
    if ([int]$Catalog.version -ne 1) {
        throw "Unsupported catalog version: $($Catalog.version)"
    }
    if ($Catalog.PSObject.Properties.Name -contains 'menuFlow' -and @($Catalog.menuFlow) -contains 'Product') {
        throw 'Unified catalog menuFlow must not include Product.'
    }
    if ($Catalog.policies -and ($Catalog.policies.PSObject.Properties.Name -contains 'oneProductPerRun') -and [bool]$Catalog.policies.oneProductPerRun) {
        throw 'Unified catalog policies must not enforce oneProductPerRun.'
    }
    if ($Catalog.PSObject.Properties.Name -contains 'products' -and $null -ne $Catalog.products) {
        throw 'Unified catalog must not define top-level products split.'
    }
    $kindIds = @($Catalog.credentialKinds.PSObject.Properties | ForEach-Object { $_.Name })
    if ($kindIds.Count -eq 0) {
        throw 'Catalog credentialKinds is empty.'
    }
    foreach ($forbiddenKind in @('entroOutpost.connector', 'github.ghesPat')) {
        if ($kindIds -contains $forbiddenKind) {
            throw "Catalog must not contain deprecated credential kind: $forbiddenKind"
        }
    }

    $validCoverages = Get-IntegrationCatalogCoverageValues
    $validHostings = @('saas', 'hybrid', 'on-prem', 'self-hosted', 'infrastructure')
    $seenVariantKeys = @{}
    foreach ($integration in @($Catalog.integrations)) {
        if (-not $integration.id) { throw 'Integration entry missing id.' }
        if ([string]$integration.id -eq 'entro-outpost') {
            throw 'Catalog must not contain deprecated entro-outpost integration.'
        }
        if (-not $integration.platformName) { throw "Integration $($integration.id) missing platformName." }
        if (-not $integration.cli) { throw "Integration $($integration.id) missing cli." }
        $coverage = if ($integration.PSObject.Properties.Name -contains 'coverage') { [string]$integration.coverage } else { '' }
        if ($validCoverages -notcontains $coverage) {
            throw "Integration $($integration.id) has invalid coverage '$coverage'. Expected one of: $($validCoverages -join ', ')."
        }
        if ($integration.PSObject.Properties.Name -contains 'requiresOutpost' -and [bool]$integration.requiresOutpost) {
            throw "Integration $($integration.id) must not set requiresOutpost."
        }
        if ($integration.PSObject.Properties.Name -contains 'hosting' -and $integration.hosting) {
            if ($validHostings -notcontains [string]$integration.hosting) {
                throw "Integration $($integration.id) has invalid hosting '$($integration.hosting)'."
            }
        }
        $launcherPath = Join-Path $WizardRoot ([string]$integration.launcher)
        if (-not (Test-Path -LiteralPath $launcherPath)) {
            throw "Integration $($integration.id) launcher not found: $launcherPath"
        }
        $bindings = @($integration.bindings)
        if ($bindings.Count -eq 0) {
            throw "Integration $($integration.id) has no bindings."
        }
        foreach ($binding in $bindings) {
            if (-not $binding.variantId) { throw "Binding missing variantId on $($integration.id)." }
            if ($binding.PSObject.Properties.Name -contains 'requiresOutpost' -and [bool]$binding.requiresOutpost) {
                throw "Binding $($integration.id)/$($binding.variantId) must not set requiresOutpost."
            }
            if ($binding.PSObject.Properties.Name -contains 'hosting' -and $binding.hosting) {
                if ($validHostings -notcontains [string]$binding.hosting) {
                    throw "Binding $($integration.id)/$($binding.variantId) has invalid hosting '$($binding.hosting)'."
                }
            }
            $defIds = if ($binding.PSObject.Properties.Name -contains 'definitionIds' -and $binding.definitionIds) {
                @($binding.definitionIds | ForEach-Object { [string]$_ })
            } else {
                @([string]$binding.definitionId)
            }
            foreach ($did in $defIds) {
                if ($did -in @('github-ghes-entro', 'aws-ciem-connector', 'google-ciem-connector', 'entro-outpost-docker', 'entro-outpost-kubernetes')) {
                    throw "Binding $($integration.id)/$($binding.variantId) references retired definitionId '$did'."
                }
            }
            $variantKey = "$($integration.id)|$($binding.variantId)"
            if ($seenVariantKeys.ContainsKey($variantKey)) {
                throw "Duplicate variant key: $variantKey"
            }
            $seenVariantKeys[$variantKey] = $true

            $modules = if ($binding.PSObject.Properties.Name -contains 'definitionModules' -and $binding.definitionModules) {
                @($binding.definitionModules | ForEach-Object { [string]$_ })
            } else {
                @([string]$binding.definitionModule)
            }
            foreach ($mRel in $modules) {
                $modPath = Join-Path $WizardRoot $mRel
                if (-not (Test-Path -LiteralPath $modPath)) {
                    throw "Definition module not found: $modPath"
                }
            }
            foreach ($kind in @($binding.credentialKinds)) {
                if ($kindIds -notcontains [string]$kind) {
                    throw "Binding $variantKey references unknown credential kind: $kind"
                }
            }
        }
    }
    return $true
}

Export-ModuleMember -Function @(
    'Get-IntegrationWizardCatalogPath'
    'Import-IntegrationWizardCatalog'
    'Get-IntegrationWizardCatalog'
    'Get-IntegrationCatalogIntegrations'
    'Get-IntegrationCatalogIntegration'
    'Get-IntegrationCatalogCoverageValues'
    'Get-IntegrationCatalogProductNames'
    'Get-IntegrationCatalogCredentialKind'
    'Get-IntegrationCatalogFlatBindings'
    'Resolve-IntegrationCatalogBinding'
    'Test-IntegrationWizardCatalog'
)
