#Requires -Version 7.0
<#
.SYNOPSIS
    Sail-associated NERM API helper (PowerShell Core).

.EXAMPLE
    pwsh -NoProfile -File scripts/nerm_api.ps1 env list
.EXAMPLE
    pwsh -NoProfile -File scripts/nerm_api.ps1 get -Env fernando /profiles -Query 'query[limit]=1'
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot 'NermApi.psm1'
Import-Module $modulePath -Force -DisableNameChecking

function Show-NermHelp {
    @'
Sail-associated NERM API helper (PowerShell Core)

Usage:
  pwsh -NoProfile -File nerm_api.ps1 env list [-Sidecar path]
  pwsh -NoProfile -File nerm_api.ps1 env show -Env <name> [-Sidecar path]
  pwsh -NoProfile -File nerm_api.ps1 env set -Env <name> -NermUrl <url> [-Sidecar path]
  pwsh -NoProfile -File nerm_api.ps1 env unset -Env <name> [-Sidecar path]
  pwsh -NoProfile -File nerm_api.ps1 get|post|put|patch|delete -Env <name> <path>
       [-Query key=value ...] [-Body '<json>' | -BodyFile path]
       [-Paginate] [-MaxPages N] [-Sidecar path]

'@ | Write-Output
}

function ConvertTo-NermArgMap {
    param([string[]]$Items)
    $map = [ordered]@{
        Env         = $null
        NermUrl     = $null
        Sidecar     = (Get-NermDefaultSidecar)
        Path        = $null
        Query       = [System.Collections.Generic.List[string]]::new()
        Body        = $null
        BodyFile    = $null
        Paginate    = $false
        MaxPages    = 50
        Help        = $false
        Positionals = [System.Collections.Generic.List[string]]::new()
    }

    $i = 0
    while ($i -lt $Items.Count) {
        $a = $Items[$i]
        switch -Regex ($a) {
            '^(?i)-Env$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-Env requires a value' }
                $map.Env = $Items[$i]
            }
            '^(?i)-NermUrl$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-NermUrl requires a value' }
                $map.NermUrl = $Items[$i]
            }
            '^(?i)-Sidecar$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-Sidecar requires a value' }
                $map.Sidecar = $Items[$i]
            }
            '^(?i)-Query$|^-q$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-Query requires a value' }
                [void]$map.Query.Add($Items[$i])
            }
            '^(?i)-Body$|^-b$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-Body requires a value' }
                $map.Body = $Items[$i]
            }
            '^(?i)-BodyFile$|^-f$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-BodyFile requires a value' }
                $map.BodyFile = $Items[$i]
            }
            '^(?i)-Paginate$' {
                $map.Paginate = $true
            }
            '^(?i)-MaxPages$' {
                $i++; if ($i -ge $Items.Count) { Write-NermError '-MaxPages requires a value' }
                $map.MaxPages = [int]$Items[$i]
            }
            '^(?i)-h$|^(?i)-Help$|^(?i)--help$' {
                $map.Help = $true
            }
            Default {
                if ($a.StartsWith('-')) {
                    Write-NermError "unknown argument: $a"
                }
                [void]$map.Positionals.Add($a)
            }
        }
        $i++
    }
    return $map
}

function Invoke-NermEnvList {
    param($Map)
    $sidecar = Import-NermSidecar -Path $Map.Sidecar
    $sailEnvs = $null
    try {
        $sailEnvs = Invoke-SailEnvList
    }
    catch {
        [Console]::Error.WriteLine("warning: $($_.Exception.Message)")
        $sailEnvs = [ordered]@{}
    }

    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($k in $sidecar.Keys) { [void]$names.Add([string]$k) }
    foreach ($k in $sailEnvs.Keys) { [void]$names.Add([string]$k) }

    $out = [ordered]@{}
    foreach ($name in ($names | Sort-Object)) {
        $entry = [ordered]@{}
        if ($sailEnvs.Contains($name)) {
            $entry['sail'] = [ordered]@{
                baseurl   = $sailEnvs[$name]['baseurl']
                tenanturl = $sailEnvs[$name]['tenanturl']
                authtype  = $sailEnvs[$name]['authtype']
            }
        }
        if ($sidecar.Contains($name) -and $sidecar[$name]['nermurl']) {
            $entry['nermurl'] = $sidecar[$name]['nermurl']
        }
        $out[$name] = $entry
    }
    Write-NermJson $out
}

function Invoke-NermEnvShow {
    param($Map)
    if (-not $Map.Env) { Write-NermError '-Env is required' }
    $url = Resolve-NermAssociation -Env $Map.Env -SidecarPath $Map.Sidecar
    Write-NermJson ([ordered]@{ env = $Map.Env; nermurl = $url })
}

function Invoke-NermEnvSet {
    param($Map)
    if (-not $Map.Env) { Write-NermError '-Env is required' }
    if (-not $Map.NermUrl) { Write-NermError '-NermUrl is required' }
    $envs = Import-NermSidecar -Path $Map.Sidecar
    $url = Normalize-NermUrl -Url $Map.NermUrl
    $envs[$Map.Env] = [ordered]@{ nermurl = $url }
    Export-NermSidecar -Path $Map.Sidecar -Environments $envs
    Write-NermJson ([ordered]@{ env = $Map.Env; nermurl = $url })
}

function Invoke-NermEnvUnset {
    param($Map)
    if (-not $Map.Env) { Write-NermError '-Env is required' }
    $envs = Import-NermSidecar -Path $Map.Sidecar
    $key = $null
    foreach ($k in @($envs.Keys)) {
        if ([string]$k -eq $Map.Env -or [string]$k.ToLowerInvariant() -eq $Map.Env.ToLowerInvariant()) {
            $key = $k
            break
        }
    }
    if (-not $key) { Write-NermError "no association for env $($Map.Env)" }
    $envs.Remove($key)
    Export-NermSidecar -Path $Map.Sidecar -Environments $envs
    Write-NermJson ([ordered]@{ unset = $Map.Env })
}

function Invoke-NermHttpCommand {
    param(
        [Parameter(Mandatory)][string]$Method,
        $Map
    )
    if (-not $Map.Env) { Write-NermError '-Env is required' }
    $path = $Map.Path
    if (-not $path -and $Map.Positionals.Count -gt 0) {
        $path = $Map.Positionals[0]
    }
    if (-not $path) { Write-NermError 'path is required' }

    $nermBase = Resolve-NermAssociation -Env $Map.Env -SidecarPath $Map.Sidecar
    $iscBase = Get-SailEnvBaseUrl -Env $Map.Env
    $token = Resolve-NermBearerToken -Env $Map.Env -BaseUrl $iscBase
    $query = ConvertFrom-NermQueryFlags -Values @($Map.Query)
    $body = Get-NermRequestBody -Body $Map.Body -BodyFile $Map.BodyFile

    if ($Map.Paginate) {
        if ($Method -ne 'get') { Write-NermError '-Paginate only applies to get' }
        $payload = Invoke-NermPaginatedGet -Path $path -NermBase $nermBase -Token $token -Query $query -MaxPages $Map.MaxPages
        Write-NermJson $payload
        return
    }

    $url = Join-NermUrl -Base $nermBase -Path $path
    $result = Invoke-NermRest -Method $Method -Url $url -Token $token -Query $query -Body $body
    if ($null -eq $result.Payload) {
        Write-NermJson ([ordered]@{ status = $result.Status })
    }
    elseif ($result.Payload -is [string]) {
        Write-Output $result.Payload
    }
    else {
        Write-NermJson $result.Payload
    }
}

try {
    $cliArgs = @($args | ForEach-Object { [string]$_ })
    if ($cliArgs.Count -eq 0 -or $cliArgs[0] -in @('-h', '-Help', '--help', 'help')) {
        Show-NermHelp
        exit 0
    }

    $command = $cliArgs[0]
    $rest = @($cliArgs | Select-Object -Skip 1)

    if ($command.ToLowerInvariant() -eq 'env') {
        if ($rest.Count -eq 0) { Write-NermError 'env requires a subcommand (list|show|set|unset)' }
        $sub = $rest[0]
        $map = ConvertTo-NermArgMap -Items @($rest | Select-Object -Skip 1)
        if ($map.Help) { Show-NermHelp; exit 0 }
        switch ($sub.ToLowerInvariant()) {
            'list' { Invoke-NermEnvList -Map $map }
            'show' { Invoke-NermEnvShow -Map $map }
            'set' { Invoke-NermEnvSet -Map $map }
            'unset' { Invoke-NermEnvUnset -Map $map }
            Default { Write-NermError "unknown env subcommand: $sub" }
        }
    }
    else {
        $map = ConvertTo-NermArgMap -Items $rest
        if ($map.Help) { Show-NermHelp; exit 0 }
        switch ($command.ToLowerInvariant()) {
            'get' { Invoke-NermHttpCommand -Method get -Map $map }
            'post' { Invoke-NermHttpCommand -Method post -Map $map }
            'put' { Invoke-NermHttpCommand -Method put -Map $map }
            'patch' { Invoke-NermHttpCommand -Method patch -Map $map }
            'delete' { Invoke-NermHttpCommand -Method delete -Map $map }
            Default { Write-NermError "unknown command: $command" }
        }
    }
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
