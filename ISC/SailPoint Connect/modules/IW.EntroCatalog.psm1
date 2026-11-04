Set-StrictMode -Version Latest

function Get-EntroConnectSkillRoot {
    $wizardRoot = Split-Path $PSScriptRoot -Parent
    $repoRoot = Split-Path (Split-Path $wizardRoot -Parent) -Parent
    Join-Path $repoRoot 'Entro/entro-connect/.agents/skills/entro-connect'
}

function Get-EntroIntegrationCatalog {
    param([Parameter(Mandatory)][string]$IntegrationFolder)
    $path = Join-Path (Get-EntroConnectSkillRoot) "integrations/$IntegrationFolder/catalog.json"
    if (-not (Test-Path $path)) { throw "Entro catalog not found: $path" }
    Get-Content -Raw -Path $path | ConvertFrom-Json
}

function Get-EntroCatalogFileSha256 {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    $hash.Hash.ToLowerInvariant()
}

function Test-EntroCatalogDrift {
    param(
        [Parameter(Mandatory)][string]$DataManifestPath
    )
    $manifest = Get-Content -Raw -Path $DataManifestPath | ConvertFrom-Json
    $drift = @()
    foreach ($entry in @($manifest.files)) {
        $full = Join-Path (Split-Path $DataManifestPath -Parent) $entry.path
        if (-not (Test-Path $full)) {
            $drift += [pscustomobject]@{ File = $entry.path; Issue = 'missing' }
            continue
        }
        $actual = Get-EntroCatalogFileSha256 -Path $full
        if ($actual -ne $entry.sha256) {
            $drift += [pscustomobject]@{ File = $entry.path; Issue = 'checksum mismatch'; Expected = $entry.sha256; Actual = $actual }
        }
    }
    ,$drift
}

Export-ModuleMember -Function Get-EntroConnectSkillRoot, Get-EntroIntegrationCatalog, Get-EntroCatalogFileSha256, Test-EntroCatalogDrift
