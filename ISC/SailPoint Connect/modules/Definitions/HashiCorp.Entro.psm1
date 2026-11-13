Set-StrictMode -Version Latest

$script:ProbeModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.OnPremProbe.psm1'
Import-Module $script:ProbeModule -Force -WarningAction SilentlyContinue

function Get-EntroVaultPolicyHcl {
    param(
        [ValidateSet('Standard', 'KvMetadata')]
        [string]$Mode = 'Standard',
        [string]$KvMount = 'secret'
    )
    if ($Mode -eq 'KvMetadata') {
        $mount = ([string]$KvMount).Trim('/')
        if ([string]::IsNullOrWhiteSpace($mount)) { $mount = 'secret' }
        return @"
path "sys/mounts" {
  capabilities = ["read"]
}
path "$mount/metadata" {
  capabilities = ["list"]
}
path "$mount/metadata/*" {
  capabilities = ["list", "read"]
}
path "sys/auth" {
  capabilities = ["read"]
}
path "auth/userpass/users" {
  capabilities = ["list"]
}
path "auth/userpass/users/*" {
  capabilities = ["list", "read"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
"@
    }
    @'
path "*" {
  capabilities = ["list", "read"]
}
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}
path "auth/token/accessors" {
  capabilities = ["list", "sudo"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
'@
}

function Get-EntroVaultTokenCreateBody {
    @{
        policies          = @('entro-policy')
        no_default_policy = $true
        ttl               = '30d'
        period            = '30d'
        renewable         = $true
    }
}

function Test-HashiCorpVaultEntroCheck {
    param($Context, [bool]$WhatIf)
    $missing = [System.Collections.Generic.List[string]]::new()
    $met = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    $url = [string]$Context['VaultUrl']
    if ([string]::IsNullOrWhiteSpace($url)) {
        $missing.Add('VaultUrl')
    }
    else {
        $ep = Get-OnPremEndpoint -Address $url -DefaultPort 8200
        if ($WhatIf) {
            $manual.Add("TCP $($ep.Host):$($ep.Port)")
        }
        elseif (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port) {
            $met.Add("TCP $($ep.Host):$($ep.Port)")
            try {
                Invoke-WebRequest -Uri "$($ep.Url)/v1/sys/health" -Method Get -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop | Out-Null
                $met.Add('Vault sys/health')
            }
            catch {
                $code = $null
                if ($_.Exception.PSObject.Properties.Name -contains 'Response' -and $_.Exception.Response) {
                    $code = [int]$_.Exception.Response.StatusCode
                }
                if ($code) { $met.Add("Vault sys/health HTTP $code") }
                else { $missing.Add('Vault sys/health did not respond') }
            }
        }
        else {
            $missing.Add("TCP $($ep.Host):$($ep.Port)")
        }
    }
    $token = [string]$Context['AccessToken']
    if ([string]::IsNullOrWhiteSpace($token)) {
        $manual.Add('Access token lookup (supply AccessToken to verify entro-policy)')
    }
    elseif (-not [string]::IsNullOrWhiteSpace($url) -and -not $WhatIf) {
        $ep = Get-OnPremEndpoint -Address $url -DefaultPort 8200
        try {
            $lookup = Invoke-RestMethod -Method Get -Uri "$($ep.Url)/v1/auth/token/lookup-self" -Headers @{ 'X-Vault-Token' = $token } -TimeoutSec 20
            $policies = @($lookup.data.policies)
            if ($policies -contains 'entro-policy') { $met.Add('Token policy entro-policy') }
            else { $missing.Add('Token is missing entro-policy') }
            if ($lookup.data.renewable) { $met.Add('Token renewable') }
            else { $missing.Add('Token is not renewable') }
        }
        catch {
            $missing.Add("Token lookup failed: $($_.Exception.Message)")
        }
    }
    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    @{
        Subject       = @{ Kind = 'VaultCluster'; Label = 'HashiCorp Vault'; Name = $url; Note = 'Read-only probe. Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = -not $WhatIf
        Found         = $true
        Required      = @('TCP reachability', 'Vault sys/health', 'entro-policy token')
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = @{
            'TCP reachability'  = 'Outpost or operator host can open the Vault API port'
            'Vault sys/health'  = 'Vault API is responding'
            'entro-policy token' = 'Renewable token is bound to entro-policy'
        }
        ReadNote      = "Checked Vault from $([Environment]::MachineName)."
    }
}

function Register-HashiCorpEntroDefinitions {
    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }
    Register-IntegrationWizardDefinition @{
        Id           = 'hashicorp-vault-entro'
        Platform     = 'HashiCorpVault'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'pwsh'
        Title        = 'Entro HashiCorp Vault integration'
        FolderName   = 'Entro-HashiCorp-Vault'
        RequiredTools = @('Network path to the Vault API (default port 8200)')
        AccessLevels = @()
        AdminRoles   = @('Vault operator who can write ACL policies and create tokens')
        OutputsHelp  = @'
Paste into Entro (Management -> Accounts & Integrations -> HashiCorp Vault):
Environment, Vault Server URL, the renewable access token written to entro-vault-token.txt, and the Outpost Worker Group.
Do not commit the token file.
'@
        TargetHost   = @{
            Role  = 'Internal host with HTTPS reachability to the Vault API'
            Notes = 'Run on a host that can reach Vault (often the Outpost host or a jump host). The Outpost Worker Group must also reach Vault. This does not use the vault CLI.'
            Assert = {
                param($c)
                $ep = Get-OnPremEndpoint -Address ([string]$c['VaultUrl']) -DefaultPort 8200
                if (-not (Test-OnPremTcpPort -HostName $ep.Host -Port $ep.Port)) {
                    throw "Cannot reach Vault at $($ep.Host):$($ep.Port). Run on a host that can reach the Vault API, or use BuildScript and copy the .ps1 there."
                }
            }
            AssertScript = @'
$vaultEndpoint = [Uri]$(if ($VaultUrl -match '^[a-z][a-z0-9+\.-]*://') { $VaultUrl } else { "https://$VaultUrl" })
$vaultPort = if ($vaultEndpoint.Port -gt 0) { $vaultEndpoint.Port } else { 8200 }
$vaultClient = [System.Net.Sockets.TcpClient]::new()
try {
    $vaultWait = $vaultClient.BeginConnect($vaultEndpoint.Host, $vaultPort, $null, $null)
    if (-not $vaultWait.AsyncWaitHandle.WaitOne(4000, $false)) { throw "Cannot reach Vault at $($vaultEndpoint.Host):$vaultPort." }
    $vaultClient.EndConnect($vaultWait)
}
finally { $vaultClient.Dispose() }
'@
        }
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment label'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'VaultUrl'; Source = 'Supply'; Prompt = 'Vault server URL'; Purpose = 'https://vault.example.com:8200'; Required = $true }
            @{ Name = 'PolicyMode'; Source = 'Supply'; Prompt = 'ACL policy'; Purpose = 'Standard list/read, or KV v2 metadata-only'; ValidateSet = @('Standard', 'KvMetadata'); Default = 'Standard'; Required = $false }
            @{ Name = 'KvMount'; Source = 'Supply'; Prompt = 'KV v2 mount path'; Purpose = 'Mount path for metadata-only ACL (for example secret)'; Default = 'secret'; Required = $false; When = { param($c) $c['PolicyMode'] -eq 'KvMetadata' } }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that will scan this Vault'; Required = $false }
            @{ Name = 'VaultAdminToken'; Source = 'Supply'; Prompt = 'Vault admin token (policy write + token create)'; Purpose = 'Short-lived admin token used only to create entro-policy'; Secret = $true; When = $runRequired; Required = $runRequired }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'VaultUrl'; Source = 'Supply'; Prompt = 'Vault server URL'; Purpose = 'Cluster to verify'; Required = $true }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'Vault access token'; Purpose = 'entro-policy token'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe   = { param($ctx, $whatIf) Test-HashiCorpVaultEntroCheck -Context $ctx -WhatIf:$whatIf }
        Steps        = {
            param($ctx)
            $mode = if ($ctx['PolicyMode']) { [string]$ctx['PolicyMode'] } else { 'Standard' }
            @(
                @{
                    Id     = 'entro-vault-outpost'
                    Title  = 'Confirm the Outpost Worker Group can reach Vault'
                    Kind   = 'Manual'
                    Why    = 'Entro scans Vault from the on-prem Outpost, not from SailPoint Cloud.'
                    Manual = 'Select the project Outpost Worker Group in Entro. The connector host needs TCP to the Vault API (usually 8200).'
                }
                @{
                    Id    = 'entro-vault-policy'
                    Title = "Write entro-policy ($mode)"
                    Kind  = 'Ensure'
                    Why   = 'Entro documents a read/list ACL named entro-policy, plus token lookup and renew-self.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $modeName = if ($c['PolicyMode']) { [string]$c['PolicyMode'] } else { 'Standard' }
                        $mount = if ($c['KvMount']) { [string]$c['KvMount'] } else { 'secret' }
                        $hcl = Get-EntroVaultPolicyHcl -Mode $modeName -KvMount $mount
                        $ep = Get-OnPremEndpoint -Address ([string]$c['VaultUrl']) -DefaultPort 8200
                        $headers = @{ 'X-Vault-Token' = [string]$c['VaultAdminToken'] }
                        $body = @{ policy = $hcl } | ConvertTo-Json -Compress
                        Invoke-RestMethod -Method Put -Uri "$($ep.Url)/v1/sys/policies/acl/entro-policy" -Headers $headers -Body $body -ContentType 'application/json' -TimeoutSec 30 | Out-Null
                        Write-Ok 'Wrote Vault ACL policy entro-policy.'
                    }
                    BuildScript = {
                        param($c)
                        $modeName = if ($c['PolicyMode']) { [string]$c['PolicyMode'] } else { 'Standard' }
                        $mount = if ($c['KvMount']) { [string]$c['KvMount'] } else { 'secret' }
                        $hcl = Get-EntroVaultPolicyHcl -Mode $modeName -KvMount $mount
                        @"
if ([string]::IsNullOrWhiteSpace(`$VaultAdminToken)) { `$VaultAdminToken = Read-Host 'Vault admin token' }
`$vaultAddr = [string]`$VaultUrl
if ([string]::IsNullOrWhiteSpace(`$vaultAddr)) { throw 'VaultUrl is required.' }
`$vaultAddr = `$vaultAddr.TrimEnd('/')
if (`$vaultAddr -notmatch '^[a-z][a-z0-9+\.-]*://') { `$vaultAddr = "https://`$vaultAddr" }
`$policy = @'
$hcl
'@
`$policyBody = @{ policy = `$policy } | ConvertTo-Json -Compress
Invoke-RestMethod -Method Put -Uri "`$vaultAddr/v1/sys/policies/acl/entro-policy" -Headers @{ 'X-Vault-Token' = `$VaultAdminToken } -Body `$policyBody -ContentType 'application/json' -TimeoutSec 30 | Out-Null
Write-Host 'Wrote Vault ACL policy entro-policy.'
"@
                    }
                }
                @{
                    Id    = 'entro-vault-token'
                    Title = 'Create a renewable entro-policy token'
                    Kind  = 'Ensure'
                    Why   = 'Entro stores a renewable token with ttl and period of 30 days and no default policy.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $ep = Get-OnPremEndpoint -Address ([string]$c['VaultUrl']) -DefaultPort 8200
                        $headers = @{ 'X-Vault-Token' = [string]$c['VaultAdminToken'] }
                        $body = Get-EntroVaultTokenCreateBody | ConvertTo-Json -Compress
                        $created = Invoke-RestMethod -Method Post -Uri "$($ep.Url)/v1/auth/token/create" -Headers $headers -Body $body -ContentType 'application/json' -TimeoutSec 30
                        $token = [string]$created.auth.client_token
                        if ([string]::IsNullOrWhiteSpace($token)) { throw 'Vault did not return auth.client_token.' }
                        $dir = if ($c['OutputDirectory']) { [string]$c['OutputDirectory'] } else { (Get-Location).Path }
                        $path = Join-Path $dir 'entro-vault-token.txt'
                        Write-OnPremSecretFile -Path $path -Value $token
                        $c['CreatedTokenPath'] = $path
                        Write-Ok "Wrote the renewable token to $path. Paste it into Entro. Do not commit that file."
                    }
                    BuildScript = {
                        param($c)
                        @'
$tokenBody = @{
    policies          = @('entro-policy')
    no_default_policy = $true
    ttl               = '30d'
    period            = '30d'
    renewable         = $true
} | ConvertTo-Json -Compress
$created = Invoke-RestMethod -Method Post -Uri "$vaultAddr/v1/auth/token/create" -Headers @{ 'X-Vault-Token' = $VaultAdminToken } -Body $tokenBody -ContentType 'application/json' -TimeoutSec 30
$token = [string]$created.auth.client_token
if ([string]::IsNullOrWhiteSpace($token)) { throw 'Vault did not return auth.client_token.' }
$outDir = if ($OutputDirectory) { $OutputDirectory } else { (Get-Location).Path }
$tokenPath = Join-Path $outDir 'entro-vault-token.txt'
Set-Content -LiteralPath $tokenPath -Value $token -Encoding ascii
if ([System.OperatingSystem]::IsLinux() -or [System.OperatingSystem]::IsMacOS()) { try { & chmod 600 $tokenPath } catch { } }
Write-Host "Wrote the renewable token to $tokenPath. Paste it into Entro. Do not commit that file."
'@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            $tokenPath = if ($ctx['CreatedTokenPath']) { $ctx['CreatedTokenPath'] } else { 'entro-vault-token.txt' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Target host: internal host that can reach $($ctx['VaultUrl'])"
            Write-Host "  Environment: $($ctx['Environment'])"
            Write-Host "  Vault URL: $($ctx['VaultUrl'])"
            Write-Host "  Worker Group: $wg"
            Write-Host "  Access token file: $tokenPath"
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-HashiCorpEntroDefinitions, Get-EntroVaultPolicyHcl, Get-EntroVaultTokenCreateBody
