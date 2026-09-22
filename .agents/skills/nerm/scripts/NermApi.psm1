#Requires -Version 7.0
<#
.SYNOPSIS
    Sail-associated NERM API library (sidecar + auth + REST helpers).
#>

Set-StrictMode -Version Latest

$script:DefaultSidecar = Join-Path $HOME '.sailpoint' 'nerm.yaml'
$script:KeyringClientId = 'environments.pat.clientid'
$script:KeyringClientSecret = 'environments.pat.clientsecret'

function Get-NermDefaultSidecar {
    return $script:DefaultSidecar
}

function Test-NermDictKey {
    param(
        [System.Collections.IDictionary]$Dictionary,
        [string]$Key
    )
    if ($null -eq $Dictionary) { return $false }
    return $Dictionary.Contains($Key)
}

function Write-NermError {
    param([Parameter(Mandatory)][string]$Message)
    $ex = [System.Exception]::new($Message)
    throw $ex
}

function ConvertFrom-NermYamlScalar {
    param([string]$Value)
    $v = $Value.Trim()
    if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
        return $v.Substring(1, $v.Length - 2)
    }
    return $v
}

function ConvertFrom-NermSidecarYaml {
    param([Parameter(Mandatory)][string]$Text)
    $envs = [ordered]@{}
    $inEnvironments = $false
    $current = $null

    foreach ($raw in ($Text -split "`r?`n")) {
        $line = ($raw -split '#', 2)[0].TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        if (-not $line.StartsWith(' ') -and -not $line.StartsWith("`t")) {
            $key = $line.Trim().TrimEnd(':')
            $inEnvironments = ($key -eq 'environments')
            $current = $null
            continue
        }
        if (-not $inEnvironments) { continue }

        if ($line -match '^  ([^\s:]+):\s*$') {
            $current = $Matches[1]
            if (-not $envs.Contains($current)) {
                $envs[$current] = [ordered]@{}
            }
            continue
        }

        if ($current -and $line -match '^\s+nermurl:\s*(.+?)\s*$') {
            if (-not $envs.Contains($current)) {
                $envs[$current] = [ordered]@{}
            }
            $envs[$current]['nermurl'] = ConvertFrom-NermYamlScalar $Matches[1]
        }
    }

    return $envs
}

function ConvertTo-NermSidecarYaml {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Environments)
    if ($Environments.Count -eq 0) {
        return "environments: {}`n"
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('environments:')
    foreach ($name in ($Environments.Keys | Sort-Object)) {
        $lines.Add("  ${name}:")
        $url = [string]$Environments[$name]['nermurl']
        $lines.Add("    nermurl: $url")
    }
    return (($lines -join "`n") + "`n")
}

function Import-NermSidecar {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{}
    }
    $text = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    if ([string]::IsNullOrWhiteSpace($text)) {
        return [ordered]@{}
    }
    return ConvertFrom-NermSidecarYaml -Text $text
}

function Export-NermSidecar {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Environments
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $yaml = ConvertTo-NermSidecarYaml -Environments $Environments
    Set-Content -LiteralPath $Path -Value $yaml -Encoding utf8 -NoNewline
    if ($IsLinux -or $IsMacOS) {
        try { & chmod 600 $Path 2>$null } catch { }
    }
}

function Join-NermUrl {
    param(
        [Parameter(Mandatory)][string]$Base,
        [Parameter(Mandatory)][string]$Path
    )
    $base = $Base.TrimEnd('/')
    if (-not $Path.StartsWith('/')) {
        $Path = '/' + $Path
    }
    if ($Path -eq '/api' -or $Path.StartsWith('/api/')) {
        Write-NermError 'path must be a resource under the NERM /api base (e.g. /profiles), not another /api prefix'
    }
    return $base + $Path
}

function ConvertFrom-SailEnvList {
    param([Parameter(Mandatory)][string]$Stdout)
    $start = $Stdout.IndexOf('{')
    $end = $Stdout.LastIndexOf('}')
    if ($start -lt 0 -or $end -lt 0 -or $end -lt $start) {
        Write-NermError 'could not parse sail env list JSON'
    }
    $json = $Stdout.Substring($start, $end - $start + 1)
    try {
        $data = $json | ConvertFrom-Json -AsHashtable
    }
    catch {
        Write-NermError 'could not parse sail env list JSON'
    }
    if ($data -isnot [System.Collections.IDictionary]) {
        Write-NermError 'sail env list JSON was not an object'
    }
    return $data
}

function Invoke-SailEnvList {
    param(
        [scriptblock]$Runner
    )
    if (-not $Runner) {
        $Runner = {
            param($InputText)
            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName = 'sail'
            $psi.ArgumentList.Add('env')
            $psi.ArgumentList.Add('list')
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            try {
                $p = [System.Diagnostics.Process]::Start($psi)
            }
            catch {
                Write-NermError 'sail not found on PATH'
            }
            $p.StandardInput.Write($InputText)
            $p.StandardInput.Close()
            $stdout = $p.StandardOutput.ReadToEnd()
            $stderr = $p.StandardError.ReadToEnd()
            $p.WaitForExit()
            [pscustomobject]@{
                ExitCode = $p.ExitCode
                StdOut   = $stdout
                StdErr   = $stderr
            }
        }
    }

    $result = & $Runner "`n"
    if ($result.ExitCode -ne 0) {
        $err = if ($result.StdErr) { $result.StdErr.Trim() } elseif ($result.StdOut) { $result.StdOut.Trim() } else { [string]$result.ExitCode }
        Write-NermError "sail env list failed: $err"
    }
    return ConvertFrom-SailEnvList -Stdout $result.StdOut
}

function Get-SailEnvBaseUrl {
    param(
        [Parameter(Mandatory)][string]$Env,
        [System.Collections.IDictionary]$SailEnvs
    )
    if (-not $SailEnvs) {
        $SailEnvs = Invoke-SailEnvList
    }
    $hit = $null
    foreach ($key in $SailEnvs.Keys) {
        if ([string]$key -eq $Env -or [string]$key.ToLowerInvariant() -eq $Env.ToLowerInvariant()) {
            $hit = $SailEnvs[$key]
            break
        }
    }
    if (-not $hit) {
        Write-NermError "sail environment not found: $Env"
    }
    $base = $hit['baseurl']
    if (-not $base) { $base = $hit['baseUrl'] }
    if (-not $base) {
        Write-NermError "sail environment $Env has no baseurl"
    }
    return ([string]$base).TrimEnd('/')
}

function Get-NermKeyringSecret {
    param(
        [Parameter(Mandatory)][string]$Service,
        [Parameter(Mandatory)][string]$Account
    )
    if (Get-Command security -ErrorAction SilentlyContinue) {
        $out = & security find-generic-password -s $Service -a $Account -w 2>$null
        if ($LASTEXITCODE -eq 0 -and $out) {
            return ([string]$out).Trim()
        }
    }
    return $null
}

function Get-NermPatCredentials {
    param(
        [Parameter(Mandatory)][string]$Env,
        [System.Collections.IDictionary]$Environ
    )
    if (-not $Environ) {
        $Environ = [ordered]@{}
        foreach ($entry in [System.Environment]::GetEnvironmentVariables().GetEnumerator()) {
            $Environ[[string]$entry.Key] = [string]$entry.Value
        }
    }

    $clientId = $Environ['SAIL_CLIENT_ID']
    if (-not $clientId) { $clientId = Get-NermKeyringSecret -Service $script:KeyringClientId -Account $Env }
    if (-not $clientId) { $clientId = Get-NermKeyringSecret -Service $script:KeyringClientId -Account $Env.ToLowerInvariant() }

    $clientSecret = $Environ['SAIL_CLIENT_SECRET']
    if (-not $clientSecret) { $clientSecret = Get-NermKeyringSecret -Service $script:KeyringClientSecret -Account $Env }
    if (-not $clientSecret) { $clientSecret = Get-NermKeyringSecret -Service $script:KeyringClientSecret -Account $Env.ToLowerInvariant() }

    if (-not $clientId -or -not $clientSecret) {
        Write-NermError "PAT credentials missing for env $Env; run sail set pat --env <name> or set SAIL_CLIENT_ID/SAIL_CLIENT_SECRET"
    }
    return @{ ClientId = $clientId; ClientSecret = $clientSecret }
}

function Get-NermAccessToken {
    param(
        [Parameter(Mandatory)][string]$TokenUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [scriptblock]$Invoker
    )
    $body = @{
        grant_type    = 'client_credentials'
        client_id     = $ClientId
        client_secret = $ClientSecret
    }
    try {
        if ($Invoker) {
            $resp = & $Invoker $TokenUrl $body
        }
        else {
            $resp = Invoke-RestMethod -Method Post -Uri $TokenUrl -Body $body -ContentType 'application/x-www-form-urlencoded' -TimeoutSec 60
        }
    }
    catch {
        $code = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $code = [int]$_.Exception.Response.StatusCode
        }
        if ($code) {
            Write-NermError "oauth token request failed: HTTP $code"
        }
        Write-NermError 'oauth token request failed: network error'
    }

    if ($resp -is [hashtable] -or $resp -is [System.Collections.IDictionary]) {
        $token = $resp['access_token']
    }
    else {
        $token = $resp.access_token
    }
    if (-not $token) {
        Write-NermError 'oauth token response missing access_token'
    }
    return [string]$token
}

function Resolve-NermBearerToken {
    param(
        [Parameter(Mandatory)][string]$Env,
        [Parameter(Mandatory)][string]$BaseUrl,
        [System.Collections.IDictionary]$Environ,
        [scriptblock]$TokenInvoker
    )
    if (-not $Environ) {
        $Environ = [ordered]@{}
        foreach ($entry in [System.Environment]::GetEnvironmentVariables().GetEnumerator()) {
            $Environ[[string]$entry.Key] = [string]$entry.Value
        }
    }
    if ($Environ['NERM_TOKEN']) { return [string]$Environ['NERM_TOKEN'] }
    if ($Environ['SAIL_ACCESS_TOKEN']) { return [string]$Environ['SAIL_ACCESS_TOKEN'] }

    $pat = Get-NermPatCredentials -Env $Env -Environ $Environ
    $tokenUrl = $BaseUrl.TrimEnd('/') + '/oauth/token'
    return Get-NermAccessToken -TokenUrl $tokenUrl -ClientId $pat.ClientId -ClientSecret $pat.ClientSecret -Invoker $TokenInvoker
}

function ConvertFrom-NermQueryFlags {
    param([string[]]$Values)
    $out = [ordered]@{}
    foreach ($item in @($Values)) {
        if ([string]::IsNullOrWhiteSpace($item)) { continue }
        if ($item -notmatch '=') {
            Write-NermError "query must be key=value: $item"
        }
        $idx = $item.IndexOf('=')
        $key = $item.Substring(0, $idx)
        $val = $item.Substring($idx + 1)
        $out[$key] = $val
    }
    return $out
}

function Get-NermRequestBody {
    param(
        [string]$Body,
        [string]$BodyFile
    )
    if ($Body -and $BodyFile) {
        Write-NermError 'use only one of -Body or -BodyFile'
    }
    if ($BodyFile) {
        $text = Get-Content -LiteralPath $BodyFile -Raw -Encoding utf8
        return ($text | ConvertFrom-Json -AsHashtable)
    }
    if ($null -ne $Body -and $Body -ne '') {
        return ($Body | ConvertFrom-Json -AsHashtable)
    }
    return $null
}

function Get-NermSafeErrorBody {
    param([string]$Raw)
    $raw = if ($null -eq $Raw) { '' } else { $Raw.Trim() }
    if (-not $raw) { return '(empty body)' }
    try {
        $data = $raw | ConvertFrom-Json -AsHashtable
    }
    catch {
        if ($raw.Length -gt 500) { return $raw.Substring(0, 500) }
        return $raw
    }
    $pieces = [System.Collections.Generic.List[string]]::new()
    foreach ($key in @('error', 'message', 'errors', 'base')) {
        if ((Test-NermDictKey -Dictionary $data -Key $key) -and $null -ne $data[$key]) {
            $pieces.Add("${key}: $($data[$key])")
        }
    }
    if ($pieces.Count -gt 0) {
        $joined = $pieces -join ' | '
        if ($joined.Length -gt 1000) { return $joined.Substring(0, 1000) }
        return $joined
    }
    $dump = ($data | ConvertTo-Json -Compress -Depth 10)
    if ($dump.Length -gt 1000) { return $dump.Substring(0, 1000) }
    return $dump
}

function Build-NermUri {
    param(
        [Parameter(Mandatory)][string]$Url,
        [System.Collections.IDictionary]$Query
    )
    if (-not $Query -or $Query.Count -eq 0) { return $Url }
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $Query.Keys) {
        $encKey = [System.Uri]::EscapeDataString([string]$key)
        $encVal = [System.Uri]::EscapeDataString([string]$Query[$key])
        $parts.Add("${encKey}=${encVal}")
    }
    $qs = $parts -join '&'
    if ($Url.Contains('?')) { return "$Url&$qs" }
    return "$Url`?$qs"
}

function Invoke-NermRest {
    param(
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Token,
        [System.Collections.IDictionary]$Query,
        $Body,
        [scriptblock]$Invoker
    )
    $fullUrl = Build-NermUri -Url $Url -Query $Query
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = 'application/json'
    }

    try {
        if ($Invoker) {
            return & $Invoker $Method $fullUrl $headers $Body
        }

        $params = @{
            Method      = $Method.ToUpperInvariant()
            Uri         = $fullUrl
            Headers     = $headers
            TimeoutSec  = 120
        }
        if ($null -ne $Body) {
            $params['ContentType'] = 'application/json'
            if ($Body -is [string]) {
                $params['Body'] = $Body
            }
            else {
                $params['Body'] = ($Body | ConvertTo-Json -Depth 20 -Compress)
            }
        }
        $response = Invoke-WebRequest @params
        $status = [int]$response.StatusCode
        $raw = [string]$response.Content
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @{ Status = $status; Payload = $null }
        }
        try {
            return @{ Status = $status; Payload = ($raw | ConvertFrom-Json -AsHashtable) }
        }
        catch {
            return @{ Status = $status; Payload = $raw }
        }
    }
    catch {
        $status = $null
        $raw = ''
        if ($_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { }
            try {
                $stream = $_.Exception.Response.Content.ReadAsStream()
                $reader = [System.IO.StreamReader]::new($stream)
                $raw = $reader.ReadToEnd()
                $reader.Dispose()
            }
            catch {
                if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                    $raw = [string]$_.ErrorDetails.Message
                }
            }
        }
        if ($status) {
            $detail = Get-NermSafeErrorBody -Raw $raw
            Write-NermError "HTTP ${status}: $detail"
        }
        Write-NermError 'request failed: network error'
    }
}

function Get-NermCollectionKey {
    param([System.Collections.IDictionary]$Payload)
    if (-not (Test-NermDictKey -Dictionary $Payload -Key '_metadata')) { return $null }
    foreach ($key in $Payload.Keys) {
        if ($key -eq '_metadata') { continue }
        if ($Payload[$key] -is [System.Collections.IList]) { return [string]$key }
    }
    return $null
}

function Invoke-NermPaginatedGet {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$NermBase,
        [Parameter(Mandatory)][string]$Token,
        [System.Collections.IDictionary]$Query,
        [int]$MaxPages = 50,
        [scriptblock]$Invoker
    )
    if (-not $Query) { $Query = [ordered]@{} }
    $qmap = [ordered]@{}
    foreach ($k in $Query.Keys) { $qmap[$k] = $Query[$k] }
    if (-not $qmap.Contains('query[limit]')) { $qmap['query[limit]'] = '100' }

    $limit = [int]$qmap['query[limit]']
    $offset = if ($qmap.Contains('query[offset]')) { [int]$qmap['query[offset]'] } else { 0 }
    $merged = [System.Collections.Generic.List[object]]::new()
    $primary = $null
    $pages = 0
    $meta = [ordered]@{}

    while ($pages -lt $MaxPages) {
        $qmap['query[offset]'] = [string]$offset
        $url = Join-NermUrl -Base $NermBase -Path $Path
        $result = Invoke-NermRest -Method GET -Url $url -Token $Token -Query $qmap -Invoker $Invoker
        $pages++
        $payload = $result.Payload
        if ($payload -isnot [System.Collections.IDictionary]) {
            return $payload
        }
        $key = Get-NermCollectionKey -Payload $payload
        if (-not $key) { $key = $primary }
        if (-not $key) { return $payload }
        $primary = $key
        $items = @($payload[$key])
        foreach ($item in $items) { $merged.Add($item) }
        if ((Test-NermDictKey -Dictionary $payload -Key '_metadata') -and $payload['_metadata']) {
            $meta = [ordered]@{}
            foreach ($mk in $payload['_metadata'].Keys) {
                $meta[$mk] = $payload['_metadata'][$mk]
            }
        }
        $total = if ($meta.Contains('total')) { [int]$meta['total'] } else { $offset + $items.Count }
        $pageLimit = if ($meta.Contains('limit')) { [int]$meta['limit'] } else { $limit }
        $pageOffset = if ($meta.Contains('offset')) { [int]$meta['offset'] } else { $offset }
        $offset = $pageOffset + $pageLimit
        if ($items.Count -lt $pageLimit -or $offset -ge $total) { break }
    }

    $meta['fetched'] = $merged.Count
    $meta['pages'] = $pages
    $outKey = if ($primary) { $primary } else { 'items' }
    return [ordered]@{
        $outKey      = @($merged)
        '_metadata'  = $meta
    }
}

function Normalize-NermUrl {
    param([Parameter(Mandatory)][string]$Url)
    $url = $Url.TrimEnd('/')
    if (-not $url.EndsWith('/api')) {
        $url = $url + '/api'
    }
    return $url
}

function Resolve-NermAssociation {
    param(
        [Parameter(Mandatory)][string]$Env,
        [Parameter(Mandatory)][string]$SidecarPath
    )
    $sidecar = Import-NermSidecar -Path $SidecarPath
    $hit = $null
    foreach ($key in $sidecar.Keys) {
        if ([string]$key -eq $Env -or [string]$key.ToLowerInvariant() -eq $Env.ToLowerInvariant()) {
            $hit = $sidecar[$key]
            break
        }
    }
    if (-not $hit -or -not $hit['nermurl']) {
        Write-NermError "no NERM URL associated for env $Env; run env set"
    }
    return [string]$hit['nermurl']
}

function Write-NermJson {
    param($Object)
    ($Object | ConvertTo-Json -Depth 30) | Write-Output
}

Export-ModuleMember -Function @(
    'Get-NermDefaultSidecar',
    'Test-NermDictKey',
    'ConvertFrom-NermSidecarYaml',
    'ConvertTo-NermSidecarYaml',
    'Import-NermSidecar',
    'Export-NermSidecar',
    'Join-NermUrl',
    'ConvertFrom-SailEnvList',
    'Invoke-SailEnvList',
    'Get-SailEnvBaseUrl',
    'Get-NermKeyringSecret',
    'Get-NermPatCredentials',
    'Get-NermAccessToken',
    'Resolve-NermBearerToken',
    'ConvertFrom-NermQueryFlags',
    'Get-NermRequestBody',
    'Get-NermSafeErrorBody',
    'Build-NermUri',
    'Invoke-NermRest',
    'Get-NermCollectionKey',
    'Invoke-NermPaginatedGet',
    'Normalize-NermUrl',
    'Resolve-NermAssociation',
    'Write-NermJson',
    'Write-NermError'
)
