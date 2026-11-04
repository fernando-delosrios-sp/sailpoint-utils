param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.EntraConnector.psm1')
)

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

# The connector module writes progress through the console helpers, so they have to be loaded even
# for the assertions that never touch a tenant.
Import-Module (Join-Path (Split-Path -Parent $ModulePath) 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-Module $ModulePath -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole
Initialize-EntraConnectorData
$catalog = Get-EntraConnectorCatalog

Assert-True ($catalog.CorePermissions.Count -gt 0) 'core permissions load'
Assert-True ($catalog.FeaturePacks.Contains('AccessPackages')) 'feature packs include AccessPackages'
$packLabels = @($catalog.FeaturePacks.Keys | ForEach-Object { [string]$catalog.FeaturePacks[$_].Label })
Assert-Equal (($packLabels | Sort-Object) -join '|') ($packLabels -join '|') 'feature packs are ordered by label'

$perms = @(Get-SelectedPermissions -Mode 'Granular' -FeatureNames @('MfaManagement'))
Assert-True ($perms.Count -gt $catalog.CorePermissions.Count) 'feature pack expands permissions'

$directory = @(Get-SelectedPermissions -Mode 'Directory' -FeatureNames @())
Assert-True ($directory.Count -lt $perms.Count) 'directory mode is coarser than granular plus features'

# Agent 365 is delegated-only: it must not add application permissions, and its scopes must not
# leak into packs that were not selected.
$withAgent365 = @(Get-SelectedPermissions -Mode 'Granular' -FeatureNames @('Agent365'))
Assert-Equal $catalog.CorePermissions.Count $withAgent365.Count 'Agent365 adds no application permissions'

$delegated = @(@(Get-SelectedDelegatedPermissions -FeatureNames @('Agent365')).Value)
Assert-True ($delegated -contains 'CopilotPackages.Read.All') 'Agent365 requests the catalog read scope'
Assert-True ($delegated -contains 'offline_access') 'Agent365 requests offline_access so a refresh token is returned'
Assert-Equal 0 (@(Get-SelectedDelegatedPermissions -FeatureNames @('MfaManagement')).Count) 'packs without delegated permissions stay application-only'

$scopes = @(Get-Agent365Scopes)
Assert-True ($scopes -contains 'offline_access') 'authorization request asks for offline_access'
Assert-True ($scopes -contains 'https://graph.microsoft.com/.default') 'authorization request asks for the Graph default scope'

$authUrl = Get-EntraAuthorizationUrl -TenantId 'contoso.onmicrosoft.com' -ClientId '11111111-2222-3333-4444-555555555555' `
    -RedirectUri 'http://localhost:8400/' -Scopes $scopes -State 'abc123'
Assert-True ($authUrl -like 'https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/v2.0/authorize?*') 'authorization URL targets the tenant endpoint'
Assert-True ($authUrl -like '*response_type=code*') 'authorization URL requests an authorization code'
Assert-True ($authUrl -like '*redirect_uri=http%3A%2F%2Flocalhost%3A8400%2F*') 'authorization URL carries the encoded redirect URI'
Assert-True ($authUrl -like '*state=abc123*') 'authorization URL carries the state value'

# Graph writes are stubbed so the manifest and consent merging can be asserted without a tenant.
# The Graph cmdlets are not imported here, so these definitions are what the module resolves.
$script:LastUpdate = $null
function Update-MgApplication {
    param($ApplicationId, $RequiredResourceAccess, $Web)
    $script:LastUpdate = @{ RequiredResourceAccess = $RequiredResourceAccess; Web = $Web }
}

$script:GraphCalls = [System.Collections.Generic.List[object]]::new()
$script:GrantList = @{ value = @() }
function Invoke-MgGraphRequest {
    param($Method, $Uri, $Body, $OutputType, $ErrorAction)
    $script:GraphCalls.Add(@{ Method = $Method; Body = $Body })
    if ($Method -eq 'GET') { return [pscustomobject]$script:GrantList }
    return @{}
}

$graphAppId = '00000003-0000-0000-c000-000000000000'
$app = [pscustomobject]@{
    Id                     = 'app-object-id'
    AppId                  = '11111111-2222-3333-4444-555555555555'
    RequiredResourceAccess = @(
        [pscustomobject]@{ ResourceAppId = '99999999-0000-0000-0000-000000000000'; ResourceAccess = @([pscustomobject]@{ Id = 'other'; Type = 'Role' }) }
    )
    Web                    = [pscustomobject]@{ RedirectUris = @() }
}

Set-RequiredResourceAccess -Application $app `
    -RolesByResource @{ Graph = @([pscustomobject]@{ Id = 'role-1'; Value = 'User.Read.All' }) } `
    -ScopesByResource @{ Graph = @([pscustomobject]@{ Id = 'scope-1'; Value = 'CopilotPackages.Read.All' }) }
$written = @($script:LastUpdate.RequiredResourceAccess)
Assert-Equal 2 $written.Count 'unmanaged resource entries survive a manifest update'
$graphAccess = @(($written | Where-Object { $_.ResourceAppId -eq $graphAppId }).ResourceAccess)
Assert-Equal 2 $graphAccess.Count 'application and delegated permissions share one resource entry'
Assert-True (@($graphAccess.Type) -contains 'Scope') 'delegated permissions are written as Scope'
Assert-True (@($graphAccess.Type) -contains 'Role') 'application permissions are still written as Role'

Set-RequiredResourceAccess -Application $app -RolesByResource @{} `
    -ScopesByResource @{ Graph = @([pscustomobject]@{ Id = 'scope-1'; Value = 'CopilotPackages.Read.All' }) }
$graphAccess = @((@($script:LastUpdate.RequiredResourceAccess) | Where-Object { $_.ResourceAppId -eq $graphAppId }).ResourceAccess)
Assert-Equal 1 $graphAccess.Count 'a resource with only delegated permissions is still written'

$script:LastUpdate = $null
$null = Set-EntraRedirectUri -Application ([pscustomobject]@{ Id = 'a'; Web = [pscustomobject]@{ RedirectUris = @('http://localhost:8400/') } }) -RedirectUri 'http://localhost:8400/'
Assert-True ($null -eq $script:LastUpdate) 'an already registered redirect URI is left alone'

$null = Set-EntraRedirectUri -Application ([pscustomobject]@{ Id = 'a' }) -RedirectUri 'http://localhost:8400/'
Assert-Equal 1 (@($script:LastUpdate.Web.RedirectUris).Count) 'an application with no Web section gets one'

$sp = [pscustomobject]@{ Id = 'client-sp' }
$graphSp = [pscustomobject]@{ Id = 'graph-sp' }
$consentScopes = @(
    [pscustomobject]@{ Id = 's1'; Value = 'CopilotPackages.Read.All' }
    [pscustomobject]@{ Id = 's2'; Value = 'offline_access' }
)

$script:GrantList = @{ value = @([pscustomobject]@{ id = 'grant-1'; resourceId = 'graph-sp'; consentType = 'AllPrincipals'; scope = 'offline_access User.Read' }) }
$null = Grant-DelegatedConsent -ServicePrincipal $sp -ResourceServicePrincipal $graphSp -Scopes $consentScopes
$patch = @($script:GraphCalls | Where-Object { $_.Method -eq 'PATCH' })
Assert-Equal 1 $patch.Count 'an existing tenant-wide grant is patched, not duplicated'
$merged = @([string]$patch[0].Body.scope -split ' ')
Assert-True ($merged -contains 'User.Read') 'consent already given to other scopes is preserved'
Assert-Equal 1 (@($merged | Where-Object { $_ -eq 'offline_access' }).Count) 'a scope consented twice is written once'

$script:GraphCalls.Clear()
$script:GrantList = @{ value = @([pscustomobject]@{ id = 'grant-1'; resourceId = 'graph-sp'; consentType = 'AllPrincipals'; scope = 'offline_access CopilotPackages.Read.All' }) }
$null = Grant-DelegatedConsent -ServicePrincipal $sp -ResourceServicePrincipal $graphSp -Scopes $consentScopes
Assert-Equal 0 (@($script:GraphCalls | Where-Object { $_.Method -ne 'GET' }).Count) 'a fully consented grant is not rewritten'

# A secret created seconds earlier can still be unknown to the token endpoint (AADSTS7000215), and
# that used to lose both the secret and the browser round trip. The stub lives in module scope
# because Invoke-RestMethod resolves there as a cmdlet, which a global function would not shadow.
$module = Get-Module -Name 'ISC.EntraConnector'
& $module {
    Set-Variable -Name TokenCalls -Scope Script -Value ([System.Collections.Generic.List[object]]::new())
    Set-Variable -Name TokenFailures -Scope Script -Value 0
    Set-Variable -Name TokenError -Scope Script -Value 'AADSTS7000215: Invalid client secret provided.'
    Set-Item -Path 'function:script:Invoke-RestMethod' -Value {
        param($Method, $Uri, $Body, $ErrorAction)
        $script:TokenCalls.Add($Body)
        if ($script:TokenCalls.Count -le $script:TokenFailures) { throw $script:TokenError }
        return [pscustomobject]@{ refresh_token = 'refresh-value' }
    }
}

$ready = & $module {
    $script:TokenCalls.Clear()
    $script:TokenFailures = 2
    Wait-EntraClientSecretReady -TenantId 't' -ClientId 'c' -ClientSecret 's' -TimeoutSeconds 30 -DelaySeconds 0
}
Assert-True $ready 'a secret that is still replicating is waited out'
$probes = & $module { @($script:TokenCalls) }
Assert-Equal 3 $probes.Count 'the readiness probe keeps polling until the secret works'
Assert-Equal 'client_credentials' $probes[0].grant_type 'the readiness probe never spends an authorization code'

$timedOut = & $module {
    $script:TokenCalls.Clear()
    $script:TokenFailures = 99
    Wait-EntraClientSecretReady -TenantId 't' -ClientId 'c' -ClientSecret 's' -TimeoutSeconds 0 -DelaySeconds 0
}
Assert-True (-not $timedOut) 'waiting gives up instead of hanging forever'

$ready = & $module {
    $script:TokenCalls.Clear()
    $script:TokenFailures = 1
    $script:TokenError = 'AADSTS700016: application not found in the directory'
    Wait-EntraClientSecretReady -TenantId 't' -ClientId 'c' -ClientSecret 's' -TimeoutSeconds 30 -DelaySeconds 0
}
Assert-True $ready 'an unrelated failure is left for the exchange to report in context'
Assert-Equal 1 (& $module { @($script:TokenCalls).Count }) 'an unrelated failure is not polled again'

$exchange = & $module {
    $script:TokenCalls.Clear()
    $script:TokenFailures = 2
    $script:TokenError = 'AADSTS7000215: Invalid client secret provided.'
    Invoke-EntraTokenExchange -TenantId 't' -ClientId 'c' -ClientSecret 's' -RedirectUri 'http://localhost:8400/' `
        -Code 'code-1' -Scopes @('offline_access') -RetryDelaySeconds 0
}
Assert-Equal 'refresh-value' $exchange.refresh_token 'the exchange survives a secret that activates late'
$attempts = & $module { @($script:TokenCalls) }
Assert-Equal 3 $attempts.Count 'the exchange retries a replication failure'
Assert-Equal 'code-1' $attempts[-1].code 'the retry reuses the same authorization code'

$exchangeError = $null
try {
    & $module {
        $script:TokenCalls.Clear()
        $script:TokenFailures = 9
        $script:TokenError = 'AADSTS70008: the authorization code expired'
        Invoke-EntraTokenExchange -TenantId 't' -ClientId 'c' -ClientSecret 's' -RedirectUri 'http://localhost:8400/' `
            -Code 'code-1' -Scopes @('offline_access') -RetryDelaySeconds 0
    }
}
catch { $exchangeError = $_.Exception.Message }
Assert-True ($exchangeError -like '*AADSTS70008*') 'an unrelated exchange failure is reported verbatim'
Assert-Equal 1 (& $module { @($script:TokenCalls).Count }) 'a spent authorization code is not retried'

Write-Host "PASS ($script:AssertionCount assertions)"
