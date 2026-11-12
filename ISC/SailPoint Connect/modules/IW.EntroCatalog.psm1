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

Export-ModuleMember -Function Get-EntroConnectSkillRoot, Get-EntroIntegrationCatalog
