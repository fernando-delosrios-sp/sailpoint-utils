Set-StrictMode -Version Latest

function Get-EntroConnectSkillRoot {
    # 1. Environment variable override
    if ($env:ENTRO_CONNECT_SKILL_ROOT -and (Test-Path -LiteralPath $env:ENTRO_CONNECT_SKILL_ROOT)) {
        return $env:ENTRO_CONNECT_SKILL_ROOT
    }

    # 2. Check within the module itself (e.g. if bundled, vendored, or symlinked)
    $wizardRoot = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { $null }
    if ($wizardRoot) {
        $moduleCandidates = @(
            (Join-Path $wizardRoot 'skills/entro-connect'),
            (Join-Path $wizardRoot 'entro-connect'),
            (Join-Path $wizardRoot 'data/entro-connect')
        )
        foreach ($cand in $moduleCandidates) {
            if (Test-Path -LiteralPath $cand) { return $cand }
        }
    }

    # 3. In-tree repository lookup: walk upwards from $PSScriptRoot
    if ($PSScriptRoot) {
        $dir = $PSScriptRoot
        while ($dir -and (Test-Path -LiteralPath $dir)) {
            $cand1 = Join-Path $dir 'Entro/entro-connect/.agents/skills/entro-connect'
            if (Test-Path -LiteralPath $cand1) { return $cand1 }
            $cand2 = Join-Path $dir 'skills/entro-connect'
            if (Test-Path -LiteralPath $cand2) { return $cand2 }
            $cand3 = Join-Path $dir '.agents/skills/entro-connect'
            if (Test-Path -LiteralPath $cand3) { return $cand3 }

            $parent = Split-Path $dir -Parent
            if (-not $parent -or $parent -eq $dir) { break }
            $dir = $parent
        }
    }

    # 4. Check Current Working Directory ancestors
    try {
        $loc = (Get-Location).Path
        $dir = $loc
        while ($dir -and (Test-Path -LiteralPath $dir)) {
            $cand1 = Join-Path $dir 'Entro/entro-connect/.agents/skills/entro-connect'
            if (Test-Path -LiteralPath $cand1) { return $cand1 }
            $cand2 = Join-Path $dir 'skills/entro-connect'
            if (Test-Path -LiteralPath $cand2) { return $cand2 }
            $cand3 = Join-Path $dir '.agents/skills/entro-connect'
            if (Test-Path -LiteralPath $cand3) { return $cand3 }

            $parent = Split-Path $dir -Parent
            if (-not $parent -or $parent -eq $dir) { break }
            $dir = $parent
        }
    } catch {}

    # 5. Check well-known development repository locations
    $homeDir = [System.Environment]::GetFolderPath('UserProfile')
    if (-not $homeDir -and $env:HOME) { $homeDir = $env:HOME }
    if ($homeDir) {
        $knownPaths = @(
            (Join-Path $homeDir 'Documents/Development/TES/sailpoint-utils/Entro/entro-connect/.agents/skills/entro-connect'),
            (Join-Path $homeDir 'Documents/Development/TES/sailpoint-utils/skills/entro-connect'),
            (Join-Path $homeDir 'Development/TES/sailpoint-utils/Entro/entro-connect/.agents/skills/entro-connect'),
            (Join-Path $homeDir 'Development/TES/sailpoint-utils/skills/entro-connect')
        )
        foreach ($kp in $knownPaths) {
            if (Test-Path -LiteralPath $kp) { return $kp }
        }
    }

    # 6. Fallback to in-tree path structure calculation
    if ($wizardRoot) {
        $p1 = Split-Path $wizardRoot -Parent
        if ($p1) {
            $repoRoot = Split-Path $p1 -Parent
            if ($repoRoot) {
                return (Join-Path $repoRoot 'Entro/entro-connect/.agents/skills/entro-connect')
            }
        }
    }

    return $null
}

function Get-EntroIntegrationCatalog {
    param([Parameter(Mandatory)][string]$IntegrationFolder)
    $skillRoot = Get-EntroConnectSkillRoot
    if (-not $skillRoot -or -not (Test-Path -LiteralPath $skillRoot)) {
        throw "Entro connect skill root not found. Set `$env:ENTRO_CONNECT_SKILL_ROOT to the skill folder."
    }
    $path = Join-Path $skillRoot "integrations/$IntegrationFolder/catalog.json"
    if (-not (Test-Path -LiteralPath $path)) { throw "Entro catalog not found: $path" }
    Get-Content -Raw -Path $path | ConvertFrom-Json
}

Export-ModuleMember -Function Get-EntroConnectSkillRoot, Get-EntroIntegrationCatalog
