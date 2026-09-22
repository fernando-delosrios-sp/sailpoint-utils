#Requires -Version 7.0
<#
.SYNOPSIS
    Offline unit tests for NermApi.psm1 (no network / no real keychain).
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:AssertionCount++
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    $script:AssertionCount++
    if ($Expected -ne $Actual) {
        throw "Assertion failed: $Message. Expected '$Expected', got '$Actual'."
    }
}

function Assert-Throws {
    param([scriptblock]$Script, [string]$MessageSubstring)
    $script:AssertionCount++
    $threw = $false
    try {
        & $Script
    }
    catch {
        $threw = $true
        if ($MessageSubstring -and ($_.Exception.Message -notlike "*$MessageSubstring*")) {
            throw "Assertion failed: expected error containing '$MessageSubstring', got '$($_.Exception.Message)'."
        }
    }
    if (-not $threw) {
        throw "Assertion failed: expected throw containing '$MessageSubstring'."
    }
}

Import-Module (Join-Path $PSScriptRoot 'NermApi.psm1') -Force -DisableNameChecking

$noisySail = @'
2026/09/22 WARN You are about to Print out the list of Environments
Press Enter to continue 2026/09/22 INFO Response res=""
{
  "emea-tes-team": {
    "authtype": "pat",
    "baseurl": "https://company24509-poc.api.identitynow-demo.com",
    "tenanturl": "https://company24509-poc.identitynow-demo.com"
  },
  "fernando": {
    "authtype": "pat",
    "baseurl": "https://company12926-poc.api.identitynow-demo.com",
    "tenanturl": "https://company12926-poc.identitynow-demo.com"
  }
}
'@

# --- sail env list parsing ---
$parsed = ConvertFrom-SailEnvList -Stdout $noisySail
Assert-True ($parsed.Contains('emea-tes-team')) 'parses emea-tes-team'
Assert-Equal 'https://company12926-poc.api.identitynow-demo.com' $parsed['fernando']['baseurl'] 'parses fernando baseurl'
Assert-Throws { ConvertFrom-SailEnvList -Stdout 'no json here' } 'could not parse'

# --- sidecar round-trip ---
$yaml = ConvertTo-NermSidecarYaml -Environments ([ordered]@{
        'emea-tes-team' = [ordered]@{ nermurl = 'https://acme.nonemployee.com/api' }
    })
$fromYaml = ConvertFrom-NermSidecarYaml -Text $yaml
Assert-Equal 'https://acme.nonemployee.com/api' $fromYaml['emea-tes-team']['nermurl'] 'sidecar round-trip'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("nerm-test-" + [guid]::NewGuid().ToString('n'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $sidecarPath = Join-Path $tmp 'nerm.yaml'
    Export-NermSidecar -Path $sidecarPath -Environments ([ordered]@{
            fernando = [ordered]@{ nermurl = 'https://x.nonemployee.com/api' }
        })
    $loaded = Import-NermSidecar -Path $sidecarPath
    Assert-Equal 'https://x.nonemployee.com/api' $loaded['fernando']['nermurl'] 'sidecar file load'
    Assert-True ((Import-NermSidecar -Path (Join-Path $tmp 'missing.yaml')).Count -eq 0) 'missing sidecar empty'

    # CLI env set via script
    $scriptPath = Join-Path $PSScriptRoot 'nerm_api.ps1'
    $null = & pwsh -NoProfile -File $scriptPath env set -Env fernando -NermUrl 'https://acme.nonemployee.com' -Sidecar $sidecarPath
    Assert-Equal 0 $LASTEXITCODE 'env set exit 0'
    $afterSet = Import-NermSidecar -Path $sidecarPath
    Assert-Equal 'https://acme.nonemployee.com/api' $afterSet['fernando']['nermurl'] 'env set normalizes /api'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# --- URL join ---
Assert-Equal 'https://acme.nonemployee.com/api/profiles' (Join-NermUrl -Base 'https://acme.nonemployee.com/api' -Path '/profiles') 'join with slash'
Assert-Equal 'https://acme.nonemployee.com/api/profiles' (Join-NermUrl -Base 'https://acme.nonemployee.com/api/' -Path 'profiles') 'join without slash'
Assert-Throws { Join-NermUrl -Base 'https://acme.nonemployee.com/api' -Path '/api/profiles' } 'another /api prefix'

# --- token precedence ---
$token = Resolve-NermBearerToken -Env fernando -BaseUrl 'https://example.api.identitynow.com' -Environ ([ordered]@{ NERM_TOKEN = 'legacy-key' })
Assert-Equal 'legacy-key' $token 'NERM_TOKEN wins'

$token2 = Resolve-NermBearerToken -Env fernando -BaseUrl 'https://example.api.identitynow.com' -Environ ([ordered]@{ SAIL_ACCESS_TOKEN = 'jwt-from-env' })
Assert-Equal 'jwt-from-env' $token2 'SAIL_ACCESS_TOKEN'

$captured = @{ Url = $null }
$minted = Resolve-NermBearerToken -Env fernando -BaseUrl 'https://example.api.identitynow.com' -Environ ([ordered]@{
        SAIL_CLIENT_ID     = 'cid'
        SAIL_CLIENT_SECRET = 'csecret'
    }) -TokenInvoker {
    param($TokenUrl, $Body)
    $captured.Url = $TokenUrl
    return @{ access_token = 'minted-jwt'; expires_in = 700 }
}
Assert-Equal 'minted-jwt' $minted 'mints from env PAT'
Assert-Equal 'https://example.api.identitynow.com/oauth/token' $captured.Url 'token url'

Assert-Throws {
    Resolve-NermBearerToken -Env missing -BaseUrl 'https://example.api.identitynow.com' -Environ ([ordered]@{})
} 'PAT credentials missing'

# --- query / body / uri ---
$q = ConvertFrom-NermQueryFlags -Values @('query[limit]=5', 'name=foo')
Assert-Equal '5' $q['query[limit]'] 'query limit'
Assert-equal 'foo' $q['name'] 'query name'
Assert-Throws { ConvertFrom-NermQueryFlags -Values @('nolimit') } 'key=value'

$uri = Build-NermUri -Url 'https://acme.nonemployee.com/api/profiles' -Query ([ordered]@{ 'query[limit]' = '10'; 'query[offset]' = '0' })
Assert-True ($uri -like '*query%5Blimit%5D=10*') 'encodes query brackets'

# --- safe error body ---
$safe = Get-NermSafeErrorBody -Raw '{"error":"unauthorized"}'
Assert-True ($safe -like '*unauthorized*') 'safe error parses json'
Assert-True ($safe -notlike '*Bearer*') 'safe error has no bearer'

# --- pagination merge ---
$pages = @(
    [ordered]@{
        profiles   = @(@{ id = '1' }, @{ id = '2' })
        _metadata  = [ordered]@{ total = 3; limit = 2; offset = 0 }
    },
    [ordered]@{
        profiles   = @(@{ id = '3' })
        _metadata  = [ordered]@{ total = 3; limit = 2; offset = 2 }
    }
)
$calls = @{ n = 0 }
$merged = Invoke-NermPaginatedGet -Path '/profiles' -NermBase 'https://acme.nonemployee.com/api' -Token 'tok' -Query ([ordered]@{}) -MaxPages 10 -Invoker {
    param($Method, $Url, $Headers, $Body)
    $idx = $calls.n
    $calls.n++
    return @{ Status = 200; Payload = $pages[$idx] }
}
Assert-Equal 3 @($merged['profiles']).Count 'paginated merge count'
Assert-Equal 3 $merged['_metadata']['fetched'] 'paginated fetched'
Assert-Equal 2 $calls.n 'two page calls'

# --- request invoker receives bearer header (secret stays out of errors) ---
$script:SeenAuth = $null
$null = Invoke-NermRest -Method GET -Url 'https://acme.nonemployee.com/api/profiles' -Token 'secret-token' -Invoker {
    param($Method, $Url, $Headers, $Body)
    $script:SeenAuth = $Headers['Authorization']
    return @{ Status = 200; Payload = [ordered]@{ ok = $true } }
}
Assert-Equal 'Bearer secret-token' $script:SeenAuth 'authorization header set'

Write-Host "OK ($script:AssertionCount assertions)"
