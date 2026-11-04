#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.EntroCatalog.psm1') -Force

$root = Get-EntroConnectSkillRoot
Assert-True (Test-Path (Join-Path $root 'integrations/amazon-web-services/catalog.json')) 'AWS Entro catalog exists'

$cat = Get-EntroIntegrationCatalog -IntegrationFolder 'amazon-web-services'
Assert-True ($cat.tile -match 'Amazon') 'catalog tile loaded'

$manifest = Join-Path $wizardRoot 'modules/Entro/data/manifest.json'
$drift = Test-EntroCatalogDrift -DataManifestPath $manifest
# Reference copies may be absent; only fail on checksum mismatch when file exists
foreach ($d in @($drift)) {
    if ($d.Issue -eq 'checksum mismatch') { throw "Drift: $($d.File)" }
}

Write-Host 'PASS (3 assertions)'
