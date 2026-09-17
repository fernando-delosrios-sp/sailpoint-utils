#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:ServerAuthOid = '1.3.6.1.5.5.7.3.1'
$script:VaTlsConfigUrl = 'https://documentation.sailpoint.com/connectors/iqservice/help/common/va_topics_and_snippets/tls_config_on_va.html'
$script:VaConfigTlsUrl = 'https://documentation.sailpoint.com/saas/help/va/config_va.html#transport-layer-security'
$script:LdapsPort = 636
$script:FirewallRuleName = 'SailPoint AD LDAPS (TCP 636)'

function Get-AdLdapsHostNames {
    param([string[]]$ExtraDnsName)

    $names = [System.Collections.Generic.List[string]]::new()
    $candidates = [System.Collections.Generic.List[string]]::new()

    # Prefer the AD DNS hostname (COMPUTERNAME + USERDNSDOMAIN). GetHostEntry('localhost')
    # can return a value that is not the DC FQDN Schannel expects for LDAPS.
    if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN) -and -not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        $candidates.Add("$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)")
    }
    try {
        $byName = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName
        if ($byName) { $candidates.Add($byName) }
    }
    catch { }
    try {
        $byLocal = [System.Net.Dns]::GetHostEntry('localhost').HostName
        if ($byLocal -and $byLocal -ne 'localhost') { $candidates.Add($byLocal) }
    }
    catch { }
    if ($env:COMPUTERNAME) { $candidates.Add($env:COMPUTERNAME) }

    foreach ($name in @($candidates) + @($ExtraDnsName)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $normalized = $name.Trim().ToLowerInvariant()
        if ($normalized -eq 'localhost') { continue }
        if ($names -notcontains $normalized) {
            $names.Add($normalized)
        }
    }
    return [string[]]$names.ToArray()
}

function Test-AdDomainController {
    $ntds = Get-Service -Name 'NTDS' -ErrorAction SilentlyContinue
    if ($ntds) {
        return [PSCustomObject]@{
            IsDomainController = $true
            Reason             = "NTDS service is present (Status=$($ntds.Status))."
            NtdsStatus         = [string]$ntds.Status
        }
    }

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        # DomainRole: 4 = Backup DC, 5 = Primary DC
        if ([int]$cs.DomainRole -in @(4, 5)) {
            return [PSCustomObject]@{
                IsDomainController = $true
                Reason             = "Win32_ComputerSystem DomainRole=$($cs.DomainRole)."
                NtdsStatus         = $null
            }
        }
        return [PSCustomObject]@{
            IsDomainController = $false
            Reason             = "Host DomainRole=$($cs.DomainRole) is not a domain controller (need 4 or 5)."
            NtdsStatus         = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            IsDomainController = $false
            Reason             = "Unable to determine domain controller role: $($_.Exception.Message)"
            NtdsStatus         = $null
        }
    }
}

function Assert-AdDomainController {
    $check = Test-AdDomainController
    if (-not $check.IsDomainController) {
        throw "EnableLdaps requires a domain controller. $($check.Reason)"
    }
    return $check
}

function Get-AdLdapsCertificateDnsNames {
    param([Parameter(Mandatory)]$Certificate)

    $names = [System.Collections.Generic.List[string]]::new()
    if ($Certificate.PSObject.Properties['DnsNames'] -and $Certificate.DnsNames) {
        foreach ($n in @($Certificate.DnsNames)) {
            if ($n) { $names.Add([string]$n) }
        }
        return [string[]]$names.ToArray()
    }

    $subject = [string]$Certificate.Subject
    if ($subject -match 'CN=([^,]+)') {
        $names.Add($Matches[1].Trim())
    }

    if ($Certificate.PSObject.Properties['Extensions'] -and $Certificate.Extensions) {
        foreach ($ext in @($Certificate.Extensions)) {
            if (-not $ext.Oid -or $ext.Oid.Value -ne '2.5.29.17') { continue }
            try {
                $san = New-Object System.Security.Cryptography.X509Certificates.X509SubjectAlternativeNameExtension($ext.RawData, $false)
                $formatted = $san.Format($false)
                foreach ($part in ($formatted -split '[,;\r\n]+')) {
                    $trimmed = $part.Trim()
                    if ($trimmed -match '(?i)^DNS Name[=:]?\s*(.+)$' -or $trimmed -match '(?i)^DNS=(.+)$') {
                        $names.Add($Matches[1].Trim())
                    }
                }
            }
            catch { }
        }
    }
    return [string[]]@($names | Select-Object -Unique)
}

function Test-AdLdapsCertificateNameMatch {
    param(
        [Parameter(Mandatory)]$Certificate,
        [Parameter(Mandatory)][string[]]$HostNames
    )

    $certNames = @(Get-AdLdapsCertificateDnsNames -Certificate $Certificate | ForEach-Object { $_.ToLowerInvariant() })
    foreach ($hostName in $HostNames) {
        $want = $hostName.ToLowerInvariant()
        if ($certNames -contains $want) { return $true }
        foreach ($cn in $certNames) {
            if ($cn.StartsWith('*.') -and $want.EndsWith($cn.Substring(1))) { return $true }
        }
    }
    return $false
}

function Get-AdLdapsKeySpec {
    param([Parameter(Mandatory)]$Certificate)

    if ($Certificate.PSObject.Properties['KeySpec'] -and $null -ne $Certificate.KeySpec) {
        return [string]$Certificate.KeySpec
    }

    try {
        if ($Certificate.HasPrivateKey -and $Certificate.PrivateKey -and $Certificate.PrivateKey.CspKeyContainerInfo) {
            $keyNumber = [int]$Certificate.PrivateKey.CspKeyContainerInfo.KeyNumber
            # 1 = Exchange, 2 = Signature
            if ($keyNumber -eq 1) { return 'KeyExchange' }
            if ($keyNumber -eq 2) { return 'Signature' }
        }
    }
    catch { }

    try {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
        if ($rsa) {
            # CNG keys used with New-SelfSignedCertificate -KeySpec KeyExchange are exchange-capable.
            return 'KeyExchange'
        }
    }
    catch { }

    return 'Unknown'
}

function Get-AdLdapsEnhancedKeyUsages {
    param([Parameter(Mandatory)]$Certificate)

    if ($Certificate.PSObject.Properties['EnhancedKeyUsageList'] -and $null -ne $Certificate.EnhancedKeyUsageList) {
        return [string[]]@($Certificate.EnhancedKeyUsageList | ForEach-Object { [string]$_ })
    }

    if (-not $Certificate.PSObject.Properties['Extensions'] -or -not $Certificate.Extensions) {
        return $null
    }

    $ekuExt = @($Certificate.Extensions) | Where-Object { $_.Oid -and $_.Oid.Value -eq '2.5.29.37' } | Select-Object -First 1
    if (-not $ekuExt) {
        return $null
    }

    $eku = New-Object System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension($ekuExt, $false)
    return [string[]]@($eku.EnhancedKeyUsages | ForEach-Object { $_.Value })
}

function Get-AdLdapsKeyUsageFlags {
    param([Parameter(Mandatory)]$Certificate)

    if ($Certificate.PSObject.Properties['KeyUsageFlags'] -and $null -ne $Certificate.KeyUsageFlags) {
        return [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]$Certificate.KeyUsageFlags
    }

    if (-not $Certificate.PSObject.Properties['Extensions'] -or -not $Certificate.Extensions) {
        return $null
    }

    $kuExt = @($Certificate.Extensions) | Where-Object { $_.Oid -and $_.Oid.Value -eq '2.5.29.15' } | Select-Object -First 1
    if (-not $kuExt) {
        return $null
    }

    $ku = New-Object System.Security.Cryptography.X509Certificates.X509KeyUsageExtension($kuExt, $false)
    return $ku.KeyUsages
}

function Test-AdLdapsCertificateUses {
    param([Parameter(Mandatory)]$Certificate)

    $reasons = [System.Collections.Generic.List[string]]::new()
    $details = [ordered]@{}

    $hasPrivateKey = [bool]$Certificate.HasPrivateKey
    $details['HasPrivateKey'] = $hasPrivateKey
    if (-not $hasPrivateKey) {
        $reasons.Add('Certificate has no associated private key.')
    }

    $ekus = Get-AdLdapsEnhancedKeyUsages -Certificate $Certificate
    $details['EnhancedKeyUsages'] = $ekus
    if ($null -eq $ekus) {
        $details['EnhancedKeyUsage'] = 'Absent (treated as all purposes)'
    }
    elseif ($ekus -notcontains $script:ServerAuthOid) {
        $reasons.Add("Enhanced Key Usage does not include Server Authentication ($($script:ServerAuthOid)).")
    }
    else {
        $details['EnhancedKeyUsage'] = 'Server Authentication present'
    }

    $ku = Get-AdLdapsKeyUsageFlags -Certificate $Certificate
    $details['KeyUsageFlags'] = $ku
    if ($null -eq $ku) {
        $details['KeyUsage'] = 'Absent (treated as unrestricted)'
    }
    else {
        $needDigital = [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature
        $needEncipher = [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment
        $missing = [System.Collections.Generic.List[string]]::new()
        if (($ku -band $needDigital) -ne $needDigital) { $missing.Add('DigitalSignature') }
        if (($ku -band $needEncipher) -ne $needEncipher) { $missing.Add('KeyEncipherment') }
        if ($missing.Count -gt 0) {
            $reasons.Add("Key Usage is missing required bit(s): $($missing -join ', ').")
        }
        else {
            $details['KeyUsage'] = 'DigitalSignature + KeyEncipherment'
        }
    }

    $keySpec = Get-AdLdapsKeySpec -Certificate $Certificate
    $details['KeySpec'] = $keySpec
    if ($keySpec -eq 'Signature') {
        $reasons.Add('KeySpec is signature-only (AT_SIGNATURE); LDAPS/Schannel requires key exchange (AT_KEYEXCHANGE).')
    }

    return [PSCustomObject]@{
        Ok      = ($reasons.Count -eq 0)
        Reasons = @($reasons)
        Details = $details
    }
}

function Test-AdLdapsCertificateCandidate {
    param(
        [Parameter(Mandatory)]$Certificate,
        [Parameter(Mandatory)][string[]]$HostNames,
        [datetime]$Now = $(Get-Date)
    )

    $reasons = [System.Collections.Generic.List[string]]::new()

    $notBefore = [datetime]$Certificate.NotBefore
    $notAfter = [datetime]$Certificate.NotAfter
    if ($Now -lt $notBefore -or $Now -gt $notAfter) {
        $reasons.Add("Certificate is outside validity window ($notBefore - $notAfter).")
    }

    if (-not (Test-AdLdapsCertificateNameMatch -Certificate $Certificate -HostNames $HostNames)) {
        $reasons.Add("Certificate DNS names do not match host ($($HostNames -join ', ')).")
    }

    $uses = Test-AdLdapsCertificateUses -Certificate $Certificate
    foreach ($r in $uses.Reasons) { $reasons.Add($r) }

    return [PSCustomObject]@{
        Ok      = ($reasons.Count -eq 0)
        Reasons = @($reasons)
        Uses    = $uses
    }
}

function Get-AdLdapsCertificateStoreCandidates {
    param(
        [string[]]$StoreNames = @('NTDS', 'My'),
        [string]$Location = 'LocalMachine'
    )

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($storeName in $StoreNames) {
        $store = $null
        try {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, $Location)
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        }
        catch {
            continue
        }

        try {
            foreach ($cert in $store.Certificates) {
                $results.Add([PSCustomObject]@{
                    Certificate = $cert
                    StoreName   = $storeName
                    Location    = $Location
                })
            }
        }
        finally {
            if ($store) { $store.Close() }
        }
    }
    return [object[]]$results.ToArray()
}

function Find-AdLdapsCertificate {
    param(
        [string]$Thumbprint,
        [string[]]$DnsName,
        [object[]]$Candidates,
        [datetime]$Now = $(Get-Date)
    )

    $hostNames = Get-AdLdapsHostNames -ExtraDnsName $DnsName
    if (-not $Candidates) {
        $Candidates = @(Get-AdLdapsCertificateStoreCandidates)
    }

    $rejected = [System.Collections.Generic.List[object]]::new()
    $accepted = [System.Collections.Generic.List[object]]::new()

    foreach ($item in $Candidates) {
        $cert = if ($item.PSObject.Properties['Certificate']) { $item.Certificate } else { $item }
        $storeName = if ($item.PSObject.Properties['StoreName']) { [string]$item.StoreName } else { 'My' }

        if ($Thumbprint) {
            $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
            $certTp = ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
            if ($certTp -ne $tp) { continue }
        }

        $check = Test-AdLdapsCertificateCandidate -Certificate $cert -HostNames $hostNames -Now $Now
        $entry = [PSCustomObject]@{
            Certificate = $cert
            StoreName   = $storeName
            Thumbprint  = [string]$cert.Thumbprint
            NotAfter    = [datetime]$cert.NotAfter
            DnsNames    = @(Get-AdLdapsCertificateDnsNames -Certificate $cert)
            Check       = $check
        }

        if ($check.Ok) {
            $accepted.Add($entry)
        }
        else {
            $rejected.Add($entry)
            foreach ($reason in $check.Reasons) {
                if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                    Write-Info "Skipping $($cert.Thumbprint) ($storeName): $reason"
                }
            }
        }
    }

    if ($Thumbprint -and $accepted.Count -eq 0) {
        $pinRejects = @($rejected | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq ($Thumbprint -replace '\s', '').ToUpperInvariant()
        })
        if ($pinRejects.Count -gt 0) {
            $why = ($pinRejects[0].Check.Reasons) -join ' '
            throw "Certificate thumbprint '$Thumbprint' does not have the required LDAPS uses: $why"
        }
        throw "Certificate thumbprint '$Thumbprint' was not found in LocalMachine NTDS or My stores."
    }

    $ranked = @($accepted | Sort-Object `
        @{ Expression = { if ($_.StoreName -eq 'NTDS') { 0 } else { 1 } }; Ascending = $true }, `
        @{ Expression = { $_.NotAfter }; Ascending = $false }, `
        @{ Expression = {
            $names = @($_.DnsNames | ForEach-Object { $_.ToLowerInvariant() })
            if ($names -contains $hostNames[0]) { 0 } else { 1 }
        }; Ascending = $true })

    return [PSCustomObject]@{
        Certificate = if ($ranked.Count -gt 0) { $ranked[0].Certificate } else { $null }
        StoreName   = if ($ranked.Count -gt 0) { $ranked[0].StoreName } else { $null }
        Thumbprint  = if ($ranked.Count -gt 0) { $ranked[0].Thumbprint } else { $null }
        HostNames   = $hostNames
        Accepted    = $ranked
        Rejected    = @($rejected)
    }
}

function Get-AdLdapsNtdsServiceCertificateRegistryPath {
    return 'HKLM:\Software\Microsoft\Cryptography\Services\NTDS\SystemCertificates\My\Certificates'
}

function Get-AdLdapsLocalMachineCertificateRegistryPath {
    param([Parameter(Mandatory)][string]$Thumbprint)

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    return "HKLM:\Software\Microsoft\SystemCertificates\My\Certificates\$tp"
}

function Test-AdLdapsCertificateInNtdsServiceStore {
    param([Parameter(Mandatory)][string]$Thumbprint)

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    $path = Join-Path (Get-AdLdapsNtdsServiceCertificateRegistryPath) $tp
    return Test-Path -LiteralPath $path
}

function Install-AdLdapsCertificateIntoNtdsServiceStore {
    param(
        [Parameter(Mandatory)][string]$Thumbprint
    )

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    $source = Get-AdLdapsLocalMachineCertificateRegistryPath -Thumbprint $tp
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Certificate $tp is not present under LocalMachine\My (registry path missing). AD DS needs the cert in the computer Personal store before it can be linked into the NTDS service store."
    }

    $destRoot = Get-AdLdapsNtdsServiceCertificateRegistryPath
    if (-not (Test-Path -LiteralPath $destRoot)) {
        New-Item -Path $destRoot -Force | Out-Null
        Write-Ok "Created NTDS service certificate store at $destRoot"
    }

    $dest = Join-Path $destRoot $tp
    if (Test-Path -LiteralPath $dest) {
        Write-Info "Certificate $tp is already in the NTDS service Personal store."
        return $false
    }

    # Documented Microsoft / community method: copy the LocalMachine\My registry blob into the
    # NTDS *service* store. X509Store('NTDS','LocalMachine') is NOT this store and will not
    # make AD DS listen on TCP 636.
    Copy-Item -Path $source -Destination $destRoot -ErrorAction Stop
    Write-Ok "Linked certificate $tp into the NTDS service Personal store (Cryptography\\Services\\NTDS\\...\\My)."
    return $true
}

function Invoke-AdLdapsCertificateRenewal {
    # Ask AD DS to reload SSL certificates without a full reboot (Server 2008+).
    try {
        $rootDse = New-Object System.DirectoryServices.DirectoryEntry('LDAP://localhost/RootDSE')
        $rootDse.Properties['renewServerCertificate'].Value = 1
        $rootDse.CommitChanges()
        Write-Ok 'Triggered RootDSE renewServerCertificate so AD DS reloads the LDAPS certificate.'
        return $true
    }
    catch {
        Write-Info "Could not trigger renewServerCertificate ($($_.Exception.Message)). NTDS restart may still be required."
        return $false
    }
}

function New-AdLdapsSelfSignedCertificate {
    param(
        [string[]]$DnsName,
        [datetime]$NotAfter = $(Get-Date).AddYears(2)
    )

    $hostNames = Get-AdLdapsHostNames -ExtraDnsName $DnsName
    if ($hostNames.Count -eq 0) {
        throw 'Unable to determine DNS names for the LDAPS certificate.'
    }

    $friendly = "SailPoint AD LDAPS ($($hostNames[0]))"
    $params = @{
        Subject            = "CN=$($hostNames[0])"
        DnsName            = $hostNames
        KeyAlgorithm       = 'RSA'
        KeyLength          = 2048
        KeyExportPolicy    = 'Exportable'
        KeySpec            = 'KeyExchange'
        KeyUsage           = @('DigitalSignature', 'KeyEncipherment')
        TextExtension      = @("2.5.29.37={text}$($script:ServerAuthOid)")
        NotAfter           = $NotAfter
        CertStoreLocation  = 'Cert:\LocalMachine\My'
        FriendlyName       = $friendly
        Provider           = 'Microsoft RSA SChannel Cryptographic Provider'
    }

    Write-Step "Creating self-signed LDAPS certificate for $($hostNames -join ', ')"
    $cert = New-SelfSignedCertificate @params
    Write-Ok "Created certificate $($cert.Thumbprint) (CN/SAN: $($hostNames -join ', '))"

    # Trust the self-signed root on this machine so chain building succeeds for export.
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
    $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $rootStore.Add($cert)
        Write-Ok 'Added self-signed certificate to LocalMachine\Root'
    }
    finally {
        $rootStore.Close()
    }

    return $cert
}

function Enable-AdLdapsFirewallRule {
    $existing = Get-NetFirewallRule -DisplayName $script:FirewallRuleName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Info "Firewall rule already exists: $($script:FirewallRuleName)"
        return $false
    }

    New-NetFirewallRule -DisplayName $script:FirewallRuleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $script:LdapsPort `
        -Action Allow `
        -Profile Any `
        -Description 'Allow LDAPS for SailPoint ISC Active Directory / VA TLS' | Out-Null
    Write-Ok "Opened inbound TCP $($script:LdapsPort) ($($script:FirewallRuleName))"
    return $true
}

function Test-AdLdapsPort {
    param(
        [string]$ComputerName = '127.0.0.1',
        [int]$Port = 636,
        [int]$TimeoutMs = 2000
    )

    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $waited = $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if (-not $waited) {
            return [PSCustomObject]@{ Listening = $false; Detail = "Timed out connecting to ${ComputerName}:$Port" }
        }
        $client.EndConnect($async)
        return [PSCustomObject]@{ Listening = $true; Detail = "TCP $Port accepts connections on $ComputerName" }
    }
    catch {
        return [PSCustomObject]@{ Listening = $false; Detail = $_.Exception.Message }
    }
    finally {
        if ($client) { $client.Dispose() }
    }
}

function Restart-AdNtdsService {
    Write-Step 'Restarting NTDS so Schannel can pick up the LDAPS certificate'
    Restart-Service -Name 'NTDS' -Force -ErrorAction Stop
    $svc = Get-Service -Name 'NTDS'
    Write-Ok "NTDS status: $($svc.Status)"
    return [string]$svc.Status
}

function ConvertTo-X509Pem {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Certificate
    )

    if ($null -eq $Certificate) {
        throw 'Certificate is required for PEM conversion.'
    }

    $raw = $null
    if ($Certificate -is [byte[]]) {
        $raw = $Certificate
    }
    elseif ($null -ne $Certificate.PSObject.Properties['RawData'] -and $null -ne $Certificate.RawData) {
        $raw = [byte[]]$Certificate.RawData
    }
    elseif ($Certificate -is [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
        $raw = $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    }
    else {
        throw 'Certificate must provide RawData bytes or be an X509Certificate2.'
    }

    $b64 = [Convert]::ToBase64String($raw)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('-----BEGIN CERTIFICATE-----')
    for ($i = 0; $i -lt $b64.Length; $i += 64) {
        $len = [Math]::Min(64, $b64.Length - $i)
        $lines.Add($b64.Substring($i, $len))
    }
    $lines.Add('-----END CERTIFICATE-----')
    return ($lines -join "`n")
}

function Get-AdLdapsCertificateChain {
    param([Parameter(Mandatory)]$Certificate)

    if ($null -ne $Certificate.PSObject.Properties['ChainCertificates'] -and $null -ne $Certificate.ChainCertificates) {
        return [object[]]@($Certificate.ChainCertificates)
    }

    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
    try {
        [void]$chain.Build($Certificate)
    }
    catch {
        return [object[]]@($Certificate)
    }

    $certs = [System.Collections.Generic.List[object]]::new()
    foreach ($element in $chain.ChainElements) {
        $certs.Add($element.Certificate)
    }
    if ($certs.Count -eq 0) {
        $certs.Add($Certificate)
    }
    return [object[]]$certs.ToArray()
}

function Export-AdLdapsCertificateChain {
    param(
        [Parameter(Mandatory)]$Certificate,
        [Parameter(Mandatory)][string]$OutputPath,
        [string]$FilePrefix
    )

    if (-not (Test-Path -LiteralPath $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $hostNames = @(Get-AdLdapsCertificateDnsNames -Certificate $Certificate)
    $safeHost = if ($hostNames.Count -gt 0) {
        ($hostNames[0] -replace '[^A-Za-z0-9._-]', '_').ToLowerInvariant()
    }
    else {
        'ldaps'
    }
    if (-not $FilePrefix) { $FilePrefix = "$safeHost-ldaps" }

    $chain = [System.Collections.Generic.List[object]]::new()
    foreach ($member in (Get-AdLdapsCertificateChain -Certificate $Certificate)) {
        $chain.Add($member)
    }
    if ($chain.Count -eq 0) {
        $chain.Add($Certificate)
    }
    $written = [System.Collections.Generic.List[string]]::new()
    $pemBlocks = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $chain.Count; $i++) {
        $role = if ($i -eq 0) { 'leaf' } elseif ($i -eq ($chain.Count - 1)) { 'root' } else { 'intermediate' }
        $fileName = '{0}-{1:D2}-{2}.pem' -f $FilePrefix, $i, $role
        $path = Join-Path $OutputPath $fileName
        $pem = ConvertTo-X509Pem -Certificate $chain[$i]
        Set-Content -LiteralPath $path -Value $pem -Encoding ascii
        $written.Add($path)
        $pemBlocks.Add($pem)
    }

    $chainPath = Join-Path $OutputPath ("{0}-chain.pem" -f $FilePrefix)
    Set-Content -LiteralPath $chainPath -Value ($pemBlocks -join "`n`n") -Encoding ascii
    $written.Add($chainPath)

    return [PSCustomObject]@{
        OutputPath   = $OutputPath
        ChainCount   = $chain.Count
        LeafPath     = $written[0]
        ChainPath    = $chainPath
        Files        = @($written)
        Thumbprint   = [string]$Certificate.Thumbprint
        DnsNames     = $hostNames
    }
}

function Get-AdLdapsVaManualSteps {
    param(
        [string]$ChainPath,
        [string]$PemDirectory
    )

    $steps = [System.Collections.Generic.List[string]]::new()
    $steps.Add('Manual VA truststore install (do this on every VA in the cluster before relying on TLS):')
    $steps.Add('1. Pause connection testing and scheduled aggregations for the Active Directory source if it is already connected.')
    $steps.Add('2. Confirm the source Hostname matches the certificate SAN/CN (hostname, not an IP address) and that the Domain/Forest port is 636 with Use TLS enabled.')
    $steps.Add("3. Copy the PEM files (leaf, intermediates, and root — or the concatenated chain) to /home/sailpoint/certificates on each VA. PEM format only.")
    if ($PemDirectory) {
        $steps.Add("   Local PEM directory on this host: $PemDirectory")
    }
    if ($ChainPath) {
        $steps.Add("   Concatenated chain file: $ChainPath")
    }
    $steps.Add('4. On each VA run: sudo systemctl restart ccg')
    $steps.Add('5. Watch /home/sailpoint/log/ccg-start.log for "Importing cert" messages. An error usually means the file is not valid PEM.')
    $steps.Add("6. Tenant toggle reference: $($script:VaConfigTlsUrl)")
    $steps.Add("7. Manual certificate upload reference: $($script:VaTlsConfigUrl)")
    return [string[]]$steps.ToArray()
}

function Show-AdLdapsCompletion {
    param([Parameter(Mandatory)]$Result)

    $situation = [System.Collections.Generic.List[string]]::new()
    if ($Result.CreatedCertificate) {
        $situation.Add("Created a self-signed LDAPS certificate ($($Result.Thumbprint)) with Server Authentication, DigitalSignature, KeyEncipherment, and KeyExchange.")
    }
    else {
        $situation.Add("Reused existing LDAPS-capable certificate ($($Result.Thumbprint)) from LocalMachine\$($Result.StoreName).")
    }
    if ($Result.PSObject.Properties['NtdsServiceLinked'] -and $Result.NtdsServiceLinked) {
        $situation.Add('Certificate is linked in the NTDS service Personal store (Cryptography\\Services\\NTDS\\...\\My).')
    }
    else {
        $situation.Add('Pending: certificate is not in the NTDS service Personal store — AD DS will not bind TCP 636 until it is.')
    }
    if ($Result.PSObject.Properties['RenewServerCertificate'] -and $Result.RenewServerCertificate) {
        $situation.Add('Triggered RootDSE renewServerCertificate to reload SSL certificates.')
    }
    if ($Result.FirewallRuleCreated) {
        $situation.Add("Opened inbound TCP $($script:LdapsPort) in Windows Firewall.")
    }
    if ($Result.NtdsRestarted) {
        $situation.Add("NTDS was restarted (status: $($Result.NtdsStatus)).")
    }
    elseif ($Result.CreatedCertificate -or ($Result.PSObject.Properties['NtdsLinkCreated'] -and $Result.NtdsLinkCreated)) {
        $situation.Add('Pending: restart NTDS (or reboot) if TCP 636 is not listening yet.')
    }
    if ($Result.PortCheck) {
        if ($Result.PortCheck.Listening) {
            $situation.Add("Port $($script:LdapsPort): $($Result.PortCheck.Detail)")
        }
        else {
            $situation.Add("Port $($script:LdapsPort) not accepting connections yet: $($Result.PortCheck.Detail)")
            $situation.Add('Check netstat -an | findstr 636 and Event Viewer (Directory Service) for LDAP over SSL / Schannel errors.')
        }
    }
    $situation.Add("Exported $($Result.Export.ChainCount) certificate(s) as PEM under $($Result.Export.OutputPath).")
    foreach ($step in @(Get-AdLdapsVaManualSteps -ChainPath $Result.Export.ChainPath -PemDirectory $Result.Export.OutputPath)) {
        $situation.Add($step)
    }

    $items = [System.Collections.Generic.List[object]]::new()
    $items.Add([PSCustomObject]@{ Label = 'Certificate thumbprint'; Value = $Result.Thumbprint; Kind = 'Copy'; Mask = $false })
    if ($Result.DnsNames) {
        $items.Add([PSCustomObject]@{ Label = 'Certificate DNS names'; Value = ($Result.DnsNames -join ', '); Kind = 'Copy'; Mask = $false })
    }
    $items.Add([PSCustomObject]@{ Label = 'PEM directory'; Value = $Result.Export.OutputPath; Kind = 'Copy'; Mask = $false })
    $items.Add([PSCustomObject]@{ Label = 'PEM chain file'; Value = $Result.Export.ChainPath; Kind = 'Copy'; Mask = $false })
    $items.Add([PSCustomObject]@{ Label = 'LDAPS port'; Value = [string]$script:LdapsPort; Kind = 'Copy'; Mask = $false })
    $items.Add([PSCustomObject]@{ Label = 'VA TLS config (tenant)'; Value = $script:VaConfigTlsUrl; Kind = 'Copy'; Mask = $false })
    $items.Add([PSCustomObject]@{ Label = 'VA manual cert upload'; Value = $script:VaTlsConfigUrl; Kind = 'Copy'; Mask = $false })

    Write-CompletionSummary -Title 'Next: import LDAPS chain on each VA' `
        -Situation @($situation) `
        -Items $items.ToArray()
}

function Format-AdLdapsCertificateChoiceLabel {
    param(
        [Parameter(Mandatory)]$Entry,
        [switch]$IncludeThumbprint
    )

    $store = if ($Entry.PSObject.Properties['StoreName'] -and $Entry.StoreName) { [string]$Entry.StoreName } else { 'My' }
    $dns = @()
    if ($Entry.PSObject.Properties['DnsNames'] -and $Entry.DnsNames) {
        $dns = @($Entry.DnsNames)
    }
    elseif ($Entry.PSObject.Properties['Certificate'] -and $Entry.Certificate) {
        $dns = @(Get-AdLdapsCertificateDnsNames -Certificate $Entry.Certificate)
    }
    $dnsText = if ($dns.Count -gt 0) { ($dns | Select-Object -First 2) -join ', ' } else { '(no DNS)' }
    if ($dns.Count -gt 2) { $dnsText += ', …' }

    $expires = $null
    if ($Entry.PSObject.Properties['NotAfter'] -and $Entry.NotAfter) {
        $expires = ([datetime]$Entry.NotAfter).ToString('yyyy-MM-dd')
    }
    elseif ($Entry.PSObject.Properties['Certificate'] -and $Entry.Certificate -and $Entry.Certificate.NotAfter) {
        $expires = ([datetime]$Entry.Certificate.NotAfter).ToString('yyyy-MM-dd')
    }
    $expiryText = if ($expires) { "expires $expires" } else { 'expiry unknown' }

    $label = "$store | $dnsText | $expiryText"
    if ($IncludeThumbprint) {
        $tp = if ($Entry.PSObject.Properties['Thumbprint']) { [string]$Entry.Thumbprint } else { [string]$Entry.Certificate.Thumbprint }
        $short = if ($tp.Length -gt 12) { $tp.Substring(0, 12) + '…' } else { $tp }
        $label = "$label | $short"
    }
    return $label
}

function Select-AdLdapsCertificate {
    param(
        [string[]]$DnsName,
        [object[]]$Candidates,
        [datetime]$Now = $(Get-Date),
        [string]$Prompt = 'Select the LDAPS certificate to use:'
    )

    $found = Find-AdLdapsCertificate -DnsName $DnsName -Candidates $Candidates -Now $Now
    $accepted = @($found.Accepted)
    $rejected = @($found.Rejected)

    if ($rejected.Count -gt 0 -and (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        Write-Info "$($rejected.Count) certificate(s) in LocalMachine NTDS/My were skipped (failed name match or required uses)."
    }

    $options = [System.Collections.Generic.List[string]]::new()
    $labels = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $accepted) {
        $options.Add([string]$entry.Thumbprint)
        $labels.Add((Format-AdLdapsCertificateChoiceLabel -Entry $entry -IncludeThumbprint))
    }

    $options.Add('__CREATE__')
    $labels.Add('Create a new self-signed Schannel certificate')

    $default = if ($accepted.Count -gt 0) { [string]$accepted[0].Thumbprint } else { '__CREATE__' }

    if ($accepted.Count -eq 0 -and (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        Write-Info 'No LDAPS-usable certificate found. You can create a self-signed Schannel certificate.'
    }

    $choice = Read-Choice -Prompt $Prompt -Options @($options) -Labels @($labels) -Default $default
    if ($choice -eq '__CREATE__') {
        return [PSCustomObject]@{
            Thumbprint       = $null
            CreateSelfSigned = $true
            Entry            = $null
        }
    }

    $selected = $accepted | Where-Object { [string]$_.Thumbprint -eq $choice } | Select-Object -First 1
    return [PSCustomObject]@{
        Thumbprint       = $choice
        CreateSelfSigned = $false
        Entry            = $selected
    }
}

function Enable-AdLdaps {
    param(
        [string]$PemOutputPath,
        [string]$Thumbprint,
        [string[]]$DnsName,
        [switch]$RestartNtds,
        [switch]$CreateSelfSigned,
        [switch]$NonInteractive,
        [string]$InstallPath
    )

    Assert-Elevated -Operation 'EnableLdaps'
    $dc = Assert-AdDomainController
    Write-Ok $dc.Reason

    if (-not $PemOutputPath) {
        if ($InstallPath) {
            $PemOutputPath = Join-Path $InstallPath 'va-certificates'
        }
        else {
            $PemOutputPath = 'C:\SailPoint\va-certificates'
        }
    }

    Write-Step 'Selecting LDAPS certificate (Server Auth + DigitalSignature + KeyEncipherment + KeyExchange)'
    $created = $false
    $cert = $null
    $storeName = $null

    if ($CreateSelfSigned) {
        if ($Thumbprint) {
            throw 'Specify either -Thumbprint or -CreateSelfSigned, not both.'
        }
        Write-Info 'Creating a new self-signed Schannel certificate as requested.'
        $cert = New-AdLdapsSelfSignedCertificate -DnsName $DnsName
        $created = $true
        $storeName = 'My'
    }
    else {
        $found = Find-AdLdapsCertificate -Thumbprint $Thumbprint -DnsName $DnsName
        $cert = $found.Certificate
        $storeName = $found.StoreName

        if (-not $cert) {
            if ($Thumbprint) {
                throw "No usable LDAPS certificate matched thumbprint '$Thumbprint'."
            }
            Write-Info 'No existing LDAPS-capable certificate found; creating a self-signed Schannel certificate.'
            $cert = New-AdLdapsSelfSignedCertificate -DnsName $DnsName
            $created = $true
            $storeName = 'My'
        }
        else {
            Write-Ok "Using certificate $($cert.Thumbprint) from LocalMachine\$storeName"
        }
    }

    # Ensure the private-key cert lives in LocalMachine\My, then link it into the NTDS *service*
    # Personal store (registry under Cryptography\Services\NTDS). That is what AD DS actually
    # searches for LDAPS — not X509Store('NTDS','LocalMachine').
    Write-Step 'Installing certificate into the NTDS service Personal store for LDAPS'
    $myStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('My', 'LocalMachine')
    $myStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $inMy = $myStore.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
        } | Select-Object -First 1
        if (-not $inMy) {
            $myStore.Add($cert)
            Write-Ok "Copied certificate into LocalMachine\My"
        }
    }
    finally {
        $myStore.Close()
    }

    $ntdsLinked = Install-AdLdapsCertificateIntoNtdsServiceStore -Thumbprint $cert.Thumbprint
    $renewed = Invoke-AdLdapsCertificateRenewal

    Write-Step 'Ensuring inbound LDAPS firewall rule'
    $fwCreated = $false
    try {
        $fwCreated = Enable-AdLdapsFirewallRule
    }
    catch {
        Write-Info "Could not create firewall rule (may need manual allow for TCP $($script:LdapsPort)): $($_.Exception.Message)"
    }

    $ntdsRestarted = $false
    $ntdsStatus = $dc.NtdsStatus
    $portCheck = Test-AdLdapsPort -Port $script:LdapsPort
    $needsRestart = $created -or $ntdsLinked -or -not $portCheck.Listening
    if ($needsRestart) {
        $shouldRestart = [bool]$RestartNtds
        if (-not $NonInteractive -and -not $RestartNtds) {
            $defaultRestart = -not $portCheck.Listening
            $shouldRestart = Read-YesNo -Prompt "Restart NTDS so AD DS binds LDAPS on TCP $($script:LdapsPort)? (brief AD outage)" -Default $defaultRestart
        }
        elseif ($NonInteractive -and -not $RestartNtds -and -not $portCheck.Listening) {
            Write-Info "TCP $($script:LdapsPort) is not listening yet. Pass -RestartNtds to restart AD DS after linking the certificate."
        }
        if ($shouldRestart) {
            $ntdsStatus = Restart-AdNtdsService
            $ntdsRestarted = $true
            Start-Sleep -Seconds 2
            $portCheck = Test-AdLdapsPort -Port $script:LdapsPort
        }
    }

    Write-Step "Exporting certificate chain as PEM to $PemOutputPath"
    $export = Export-AdLdapsCertificateChain -Certificate $cert -OutputPath $PemOutputPath
    Write-Ok "Wrote $($export.Files.Count) PEM file(s); chain: $($export.ChainPath)"

    if ($portCheck.Listening) {
        Write-Ok $portCheck.Detail
    }
    else {
        Write-Host ''
        Write-Host "   TCP $($script:LdapsPort) is still not accepting connections." -ForegroundColor Yellow
        Write-Host '   Verify: netstat -an | findstr 636' -ForegroundColor Yellow
        Write-Host "   Confirm the cert is under HKLM:\\Software\\Microsoft\\Cryptography\\Services\\NTDS\\SystemCertificates\\My\\Certificates\\$($cert.Thumbprint)" -ForegroundColor Yellow
        Write-Host '   Confirm CN/SAN matches this DC FQDN, then restart AD DS (NTDS) again.' -ForegroundColor Yellow
    }

    $result = [PSCustomObject]@{
        Thumbprint           = [string]$cert.Thumbprint
        StoreName            = $storeName
        DnsNames             = @(Get-AdLdapsCertificateDnsNames -Certificate $cert)
        CreatedCertificate   = $created
        NtdsServiceLinked    = [bool](Test-AdLdapsCertificateInNtdsServiceStore -Thumbprint $cert.Thumbprint)
        NtdsLinkCreated      = $ntdsLinked
        RenewServerCertificate = $renewed
        FirewallRuleCreated  = $fwCreated
        NtdsRestarted        = $ntdsRestarted
        NtdsStatus           = $ntdsStatus
        PortCheck            = $portCheck
        Export               = $export
    }

    Show-AdLdapsCompletion -Result $result
    return $result
}

Export-ModuleMember -Function @(
    'Get-AdLdapsHostNames'
    'Test-AdDomainController'
    'Assert-AdDomainController'
    'Get-AdLdapsCertificateDnsNames'
    'Test-AdLdapsCertificateNameMatch'
    'Get-AdLdapsKeySpec'
    'Get-AdLdapsEnhancedKeyUsages'
    'Get-AdLdapsKeyUsageFlags'
    'Test-AdLdapsCertificateUses'
    'Test-AdLdapsCertificateCandidate'
    'Get-AdLdapsCertificateStoreCandidates'
    'Find-AdLdapsCertificate'
    'Format-AdLdapsCertificateChoiceLabel'
    'Select-AdLdapsCertificate'
    'Get-AdLdapsNtdsServiceCertificateRegistryPath'
    'Get-AdLdapsLocalMachineCertificateRegistryPath'
    'Test-AdLdapsCertificateInNtdsServiceStore'
    'Install-AdLdapsCertificateIntoNtdsServiceStore'
    'Invoke-AdLdapsCertificateRenewal'
    'New-AdLdapsSelfSignedCertificate'
    'Enable-AdLdapsFirewallRule'
    'Test-AdLdapsPort'
    'Restart-AdNtdsService'
    'ConvertTo-X509Pem'
    'Get-AdLdapsCertificateChain'
    'Export-AdLdapsCertificateChain'
    'Get-AdLdapsVaManualSteps'
    'Show-AdLdapsCompletion'
    'Enable-AdLdaps'
)
