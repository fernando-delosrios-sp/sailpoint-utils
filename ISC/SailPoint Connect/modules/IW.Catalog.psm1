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

function Get-IntegrationCatalogProductNames {
    param($Catalog = (Get-IntegrationWizardCatalog))
    @($Catalog.products.PSObject.Properties | ForEach-Object { $_.Name })
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
        Id           = $KindId
        Label        = [string]$prop.Value.label
        Discriminators = @($prop.Value.discriminators)
        SecretFields = @($prop.Value.secretFields)
        CheckSubject = [string]$prop.Value.checkSubject
    }
}

function Get-IntegrationCatalogFlatBindings {
    param(
        [string]$IntegrationId,
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
    foreach ($integration in $integrations) {
        foreach ($productProp in $integration.products.PSObject.Properties) {
            $productName = [string]$productProp.Name
            if ($Product -and $productName -ne $Product) { continue }
            $bindings = @($productProp.Value.bindings)
            foreach ($binding in $bindings) {
                $hosting = if ($binding.PSObject.Properties.Name -contains 'hosting' -and $binding.hosting) {
                    [string]$binding.hosting
                } elseif ($integration.PSObject.Properties.Name -contains 'hosting' -and $integration.hosting) {
                    [string]$integration.hosting
                } else {
                    'saas'
                }
                $requiresOutpost = if ($binding.PSObject.Properties.Name -contains 'requiresOutpost') {
                    [bool]$binding.requiresOutpost
                } elseif ($integration.PSObject.Properties.Name -contains 'requiresOutpost') {
                    [bool]$integration.requiresOutpost
                } else {
                    $false
                }
                $targetHostRole = if ($binding.PSObject.Properties.Name -contains 'targetHostRole' -and $binding.targetHostRole) {
                    [string]$binding.targetHostRole
                } elseif ($integration.PSObject.Properties.Name -contains 'targetHostRole' -and $integration.targetHostRole) {
                    [string]$integration.targetHostRole
                } else {
                    ''
                }
                $flat.Add([ordered]@{
                    IntegrationId    = [string]$integration.id
                    IntegrationTitle = [string]$integration.title
                    PlatformName     = [string]$integration.platformName
                    Cli              = [string]$integration.cli
                    Launcher         = [string]$integration.launcher
                    Hosting          = $hosting
                    RequiresOutpost  = $requiresOutpost
                    TargetHostRole   = $targetHostRole
                    Product          = $productName
                    VariantId        = [string]$binding.variantId
                    Label            = [string]$binding.label
                    DefinitionId     = [string]$binding.definitionId
                    DefinitionModule = [string]$binding.definitionModule
                    FolderName       = [string]$binding.folderName
                    CredentialKinds  = @($binding.credentialKinds)
                    ContextDefaults  = if ($binding.PSObject.Properties.Name -contains 'contextDefaults' -and $binding.contextDefaults) {
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
    }
    return @($flat)
}

function Resolve-IntegrationCatalogBinding {
    param(
        [Parameter(Mandatory)][string]$IntegrationId,
        [Parameter(Mandatory)][string]$Product,
        [string]$VariantId,
        [string]$CredentialKind,
        $Catalog = (Get-IntegrationWizardCatalog)
    )
    $candidates = @(Get-IntegrationCatalogFlatBindings -IntegrationId $IntegrationId -Product $Product -Catalog $Catalog)
    if ($candidates.Count -eq 0) {
        throw "No bindings for integration '$IntegrationId' product '$Product'."
    }
    if ($VariantId) {
        $candidates = @($candidates | Where-Object { [string]$_.VariantId -eq $VariantId })
        if ($candidates.Count -eq 0) {
            throw "No binding variant '$VariantId' for integration '$IntegrationId' product '$Product'."
        }
    }
    if ($candidates.Count -gt 1 -and -not $VariantId) {
        throw "Multiple bindings for integration '$IntegrationId' product '$Product'; specify -VariantId."
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
    if (-not $Catalog.policies -or -not $Catalog.policies.oneProductPerRun) {
        throw 'Catalog policies.oneProductPerRun must be true.'
    }
    $knownProducts = @(Get-IntegrationCatalogProductNames -Catalog $Catalog)
    if ($knownProducts.Count -lt 3) {
        throw 'Catalog must define fabric, entro, and ciem products.'
    }
    foreach ($required in @('fabric', 'entro', 'ciem')) {
        if ($knownProducts -notcontains $required) {
            throw "Catalog missing product definition: $required"
        }
    }
    $kindIds = @($Catalog.credentialKinds.PSObject.Properties | ForEach-Object { $_.Name })
    if ($kindIds.Count -eq 0) {
        throw 'Catalog credentialKinds is empty.'
    }
    $validHostings = @('saas', 'hybrid', 'on-prem', 'self-hosted', 'infrastructure')
    $hasOutpostEntry = @($Catalog.integrations | Where-Object { [string]$_.id -eq 'entro-outpost' }).Count -gt 0
    $seenVariantKeys = @{}
    foreach ($integration in @($Catalog.integrations)) {
        if (-not $integration.id) { throw 'Integration entry missing id.' }
        if (-not $integration.platformName) { throw "Integration $($integration.id) missing platformName." }
        if (-not $integration.cli) { throw "Integration $($integration.id) missing cli." }
        if ($integration.PSObject.Properties.Name -contains 'hosting' -and $integration.hosting) {
            if ($validHostings -notcontains [string]$integration.hosting) {
                throw "Integration $($integration.id) has invalid hosting '$($integration.hosting)'."
            }
        }
        $launcherPath = Join-Path $WizardRoot ([string]$integration.launcher)
        if (-not (Test-Path -LiteralPath $launcherPath)) {
            throw "Integration $($integration.id) launcher not found: $launcherPath"
        }
        foreach ($productProp in $integration.products.PSObject.Properties) {
            $productName = [string]$productProp.Name
            if ($knownProducts -notcontains $productName) {
                throw "Integration $($integration.id) references unknown product: $productName"
            }
            $bindings = @($productProp.Value.bindings)
            if ($bindings.Count -eq 0) {
                throw "Integration $($integration.id) product $productName has no bindings."
            }
            foreach ($binding in $bindings) {
                if (-not $binding.variantId) { throw "Binding missing variantId on $($integration.id)/$productName." }
                if ($binding.PSObject.Properties.Name -contains 'hosting' -and $binding.hosting) {
                    if ($validHostings -notcontains [string]$binding.hosting) {
                        throw "Binding $($integration.id)/$productName/$($binding.variantId) has invalid hosting '$($binding.hosting)'."
                    }
                }
                $reqOutpost = ($binding.PSObject.Properties.Name -contains 'requiresOutpost' -and [bool]$binding.requiresOutpost) -or
                    ($integration.PSObject.Properties.Name -contains 'requiresOutpost' -and [bool]$integration.requiresOutpost)
                if ($reqOutpost -and -not $hasOutpostEntry) {
                    throw "Binding $($integration.id)/$productName/$($binding.variantId) sets requiresOutpost=true, but catalog is missing 'entro-outpost' integration."
                }
                $variantKey = "$($integration.id)|$productName|$($binding.variantId)"
                if ($seenVariantKeys.ContainsKey($variantKey)) {
                    throw "Duplicate variant key: $variantKey"
                }
                $seenVariantKeys[$variantKey] = $true
                $modPath = Join-Path $WizardRoot ([string]$binding.definitionModule)
                if (-not (Test-Path -LiteralPath $modPath)) {
                    throw "Definition module not found: $modPath"
                }
                foreach ($kind in @($binding.credentialKinds)) {
                    if ($kindIds -notcontains [string]$kind) {
                        throw "Binding $variantKey references unknown credential kind: $kind"
                    }
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
    'Get-IntegrationCatalogProductNames'
    'Get-IntegrationCatalogCredentialKind'
    'Get-IntegrationCatalogFlatBindings'
    'Resolve-IntegrationCatalogBinding'
    'Test-IntegrationWizardCatalog'
)
