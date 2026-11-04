#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:ServerAuthOid = '1.3.6.1.5.5.7.3.1'
$script:VaTlsConfigUrl = 'https://documentation.sailpoint.com/connectors/iqservice/help/common/va_topics_and_snippets/tls_config_on_va.html'
$script:VaConfigTlsUrl = 'https://documentation.sailpoint.com/saas/help/va/config_va.html#transport-layer-security'
$script:LdapsPort = 636
$script:FirewallRuleName = 'SailPoint AD LDAPS (TCP 636)'
$script:ManagedFriendlyNamePrefix = 'SailPoint AD LDAPS'

function Get-AdLdapsMachineDnsFullyQualifiedName {
    if (-not ('AdLdapsNative' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class AdLdapsNative
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern bool GetComputerNameEx(int nameType, StringBuilder buffer, ref uint size);

    public static string GetDnsFullyQualifiedName()
    {
        const int ComputerNameDnsFullyQualified = 3;
        uint size = 1024;
        var buffer = new StringBuilder((int)size);
        if (!GetComputerNameEx(ComputerNameDnsFullyQualified, buffer, ref size))
        {
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        }
        return buffer.ToString().TrimEnd('.');
    }
}
'@
    }

    try {
        return [AdLdapsNative]::GetDnsFullyQualifiedName()
    }
    catch {
        if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN) -and -not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
            return "$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)".TrimEnd('.')
        }
        try {
            return [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName.TrimEnd('.')
        }
        catch {
            return $env:COMPUTERNAME
        }
    }
}

function Get-AdLdapsHostNames {
    param([string[]]$ExtraDnsName)

    $names = [System.Collections.Generic.List[string]]::new()
    $candidates = [System.Collections.Generic.List[string]]::new()

    # AD DS ValidateLdapCertificate matches GetComputerNameEx(ComputerNameDnsFullyQualified).
    $adDns = Get-AdLdapsMachineDnsFullyQualifiedName
    if ($adDns) { $candidates.Add($adDns) }

    if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN) -and -not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        $candidates.Add("$($env:COMPUTERNAME).$($env:USERDNSDOMAIN)")
    }
    try {
        $byName = [System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName
        if ($byName) { $candidates.Add($byName) }
    }
    catch { }
    if ($env:COMPUTERNAME) { $candidates.Add($env:COMPUTERNAME) }

    foreach ($name in @($candidates) + @($ExtraDnsName)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $normalized = $name.Trim().TrimEnd('.').ToLowerInvariant()
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

    $certNames = @(Get-AdLdapsCertificateDnsNames -Certificate $Certificate | ForEach-Object {
        $_.TrimEnd('.').ToLowerInvariant()
    })
    foreach ($hostName in $HostNames) {
        $want = $hostName.TrimEnd('.').ToLowerInvariant()
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

    $oids = [System.Collections.Generic.List[string]]::new()

    foreach ($item in @(
        $(if ($Certificate.PSObject.Properties['EnhancedKeyUsageList'] -and $null -ne $Certificate.EnhancedKeyUsageList) {
            @($Certificate.EnhancedKeyUsageList)
        } else { @() })
    )) {
        if ($null -eq $item) { continue }
        if ($item -is [System.Security.Cryptography.Oid] -and $item.Value) {
            $oids.Add([string]$item.Value)
            continue
        }
        if ($item.PSObject.Properties['Value'] -and [string]$item.Value -match '^\d+(\.\d+)+$') {
            $oids.Add([string]$item.Value)
            continue
        }
        if ($item.PSObject.Properties['ObjectId'] -and $item.ObjectId) {
            $oids.Add([string]$item.ObjectId)
            continue
        }
        $text = [string]$item
        if ($text -match '^\d+(\.\d+)+$') {
            $oids.Add($text)
        }
        elseif ($text -match '(?i)Server Authentication') {
            $oids.Add($script:ServerAuthOid)
        }
    }

    if ($oids.Count -gt 0) {
        return [string[]]@($oids | Select-Object -Unique)
    }

    if (-not $Certificate.PSObject.Properties['Extensions'] -or -not $Certificate.Extensions) {
        return $null
    }

    $ekuExt = @($Certificate.Extensions) | Where-Object { $_.Oid -and $_.Oid.Value -eq '2.5.29.37' } | Select-Object -First 1
    if (-not $ekuExt) {
        return $null
    }

    $eku = New-Object System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension($ekuExt, $false)
    foreach ($item in @($eku.EnhancedKeyUsages)) {
        if ($item -and $item.Value) {
            $oids.Add([string]$item.Value)
        }
    }
    if ($oids.Count -eq 0) { return $null }
    return [string[]]@($oids | Select-Object -Unique)
}

function Test-AdLdapsCertificateHasPrivateKey {
    param([Parameter(Mandatory)]$Certificate)

    # Prefer probing the actual key. HasPrivateKey alone is unreliable after a bad CSP
    # create or Root-store Add() — it can stay $true while GetRSAPrivateKey returns null.
    try {
        $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
        if ($rsa) { return $true }
    }
    catch { }
    try {
        if ($Certificate.PrivateKey) { return $true }
    }
    catch { }

    $isRealCert = $Certificate -is [System.Security.Cryptography.X509Certificates.X509Certificate2]
    if ($isRealCert) {
        return $false
    }

    # Unit-test mocks expose HasPrivateKey without a real key handle.
    if ($Certificate.PSObject.Properties['HasPrivateKey'] -and [bool]$Certificate.HasPrivateKey) {
        return $true
    }
    return $false
}

function Test-AdLdapsManagedCertificate {
    param([Parameter(Mandatory)]$Certificate)

    if (-not $Certificate.PSObject.Properties['FriendlyName'] -or -not $Certificate.FriendlyName) {
        return $false
    }
    return ([string]$Certificate.FriendlyName).StartsWith(
        $script:ManagedFriendlyNamePrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )
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

    $hasPrivateKey = Test-AdLdapsCertificateHasPrivateKey -Certificate $Certificate
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
        [string]$RequiredDnsName,
        [datetime]$Now = $(Get-Date)
    )

    $reasons = [System.Collections.Generic.List[string]]::new()

    $notBefore = [datetime]$Certificate.NotBefore
    $notAfter = [datetime]$Certificate.NotAfter
    if ($Now -lt $notBefore -or $Now -gt $notAfter) {
        $reasons.Add("Certificate is outside validity window ($notBefore - $notAfter).")
    }

    # AD DS matches GetComputerNameEx(DnsFullyQualified). Short name alone (CN=ad-resource) is not enough.
    $required = if ($RequiredDnsName) {
        $RequiredDnsName.TrimEnd('.').ToLowerInvariant()
    }
    elseif ($HostNames.Count -gt 0 -and $HostNames[0] -match '\.') {
        $HostNames[0].TrimEnd('.').ToLowerInvariant()
    }
    else {
        try { (Get-AdLdapsMachineDnsFullyQualifiedName).TrimEnd('.').ToLowerInvariant() } catch { $null }
    }

    if ($required) {
        if (-not (Test-AdLdapsCertificateNameMatch -Certificate $Certificate -HostNames @($required))) {
            $have = @(Get-AdLdapsCertificateDnsNames -Certificate $Certificate) -join ', '
            $reasons.Add("Certificate DNS names ($have) do not include the AD DS FQDN '$required' (short name alone is not enough for LDAPS).")
        }
    }
    elseif (-not (Test-AdLdapsCertificateNameMatch -Certificate $Certificate -HostNames $HostNames)) {
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
        [string]$RequiredDnsName,
        [object[]]$Candidates,
        [datetime]$Now = $(Get-Date)
    )

    $hostNames = Get-AdLdapsHostNames -ExtraDnsName $DnsName
    if (-not $RequiredDnsName) {
        try { $RequiredDnsName = Get-AdLdapsMachineDnsFullyQualifiedName } catch { }
        if (-not $RequiredDnsName -and $hostNames.Count -gt 0) { $RequiredDnsName = $hostNames[0] }
    }

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

        $check = Test-AdLdapsCertificateCandidate -Certificate $cert -HostNames $hostNames `
            -RequiredDnsName $RequiredDnsName -Now $Now

        # Re-open from My so we never offer a public-only / broken-key leftover from a failed create.
        if ($check.Ok -and $storeName -eq 'My' -and
            ($cert -is [System.Security.Cryptography.X509Certificates.X509Certificate2])) {
            try {
                $cert = Get-AdLdapsCertificateFromLocalMachineMy -Thumbprint $cert.Thumbprint
            }
            catch {
                $check = [PSCustomObject]@{
                    Ok      = $false
                    Reasons = @($_.Exception.Message)
                    Uses    = $null
                }
                if (Test-AdLdapsManagedCertificate -Certificate $item.Certificate) {
                    $null = Remove-AdLdapsCertificateByThumbprint -Thumbprint ([string]$item.Certificate.Thumbprint)
                }
            }
        }

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

function Initialize-AdLdapsCertOpenStoreType {
    if ('AdLdapsCertStoreNative' -as [type]) { return }

    Add-Type -TypeDefinition @'
using Microsoft.Win32.SafeHandles;
using System;
using System.Runtime.InteropServices;

namespace AdLdapsCertStore
{
    public class NativeMethods
    {
        [DllImport("Crypt32.dll")]
        public static extern bool CertCloseStore(IntPtr hCertStore, uint dwFlags);

        [DllImport("Crypt32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern SafeX509Store CertOpenStore(
            IntPtr lpszStoreProvider,
            uint dwEncodingType,
            IntPtr hCryptProv,
            uint dwFlags,
            string pvPara);
    }

    public class SafeX509Store : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeX509Store() : base(true) { }

        protected override bool ReleaseHandle()
        {
            return NativeMethods.CertCloseStore(handle, 0);
        }
    }
}
'@
}

function Open-AdLdapsServiceCertificateStore {
    param(
        [string]$ServiceName = 'NTDS',
        [string]$StoreName = 'My',
        [System.Security.Cryptography.X509Certificates.OpenFlags]$OpenFlags = [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite
    )

    Initialize-AdLdapsCertOpenStoreType

    # CERT_STORE_PROV_SYSTEM_W = 10, CERT_SYSTEM_STORE_SERVICES = 0x00050000
    $provider = [IntPtr]::new(10)
    $flags = [uint32](0x00050000 -bor 0x00000004)
    $openMode = [int]$OpenFlags -band 3
    switch ($openMode) {
        0 { $flags = $flags -bor 0x00008000 } # ReadOnly -> CERT_STORE_READONLY_FLAG
        2 { $flags = $flags -bor 0x00001000 } # MaxAllowed / OpenExisting-ish write path
    }
    if ($OpenFlags.HasFlag([System.Security.Cryptography.X509Certificates.OpenFlags]::OpenExistingOnly)) {
        $flags = $flags -bor 0x00004000
    }

    $handle = [AdLdapsCertStore.NativeMethods]::CertOpenStore(
        $provider, 0, [IntPtr]::Zero, $flags, "$ServiceName\$StoreName"
    )
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($handle.IsInvalid) {
        throw "Failed to open service certificate store '$ServiceName\$StoreName': $(([ComponentModel.Win32Exception]$err).Message)"
    }

    try {
        # Transfer ownership of the store handle to X509Store; do not CertCloseStore via SafeHandle.
        $ptr = $handle.DangerousGetHandle()
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($ptr)
        $handle.SetHandleAsInvalid()
        return $store
    }
    catch {
        $handle.Dispose()
        throw
    }
}

function Get-AdLdapsCertificateFromLocalMachineMy {
    param([Parameter(Mandatory)][string]$Thumbprint)

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('My', 'LocalMachine')
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
    try {
        $cert = $store.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp
        } | Select-Object -First 1
        if (-not $cert) {
            throw "Certificate $tp was not found in LocalMachine\My."
        }
        if (-not (Test-AdLdapsCertificateHasPrivateKey -Certificate $cert)) {
            throw "Certificate $tp in LocalMachine\My has no private key. AD DS cannot use it for LDAPS."
        }
        return $cert
    }
    finally {
        $store.Close()
    }
}

function Test-AdLdapsCertificateIsSelfSigned {
    param([Parameter(Mandatory)]$Certificate)

    try {
        $subject = [string]$Certificate.Subject
        $issuer = [string]$Certificate.Issuer
        if ($subject -and $issuer -and ($subject -eq $issuer)) { return $true }
    }
    catch { }
    return $false
}

function Remove-AdLdapsCertificateByThumbprint {
    param(
        [Parameter(Mandatory)][string]$Thumbprint,
        [string[]]$StoreNames = @('My', 'Root')
    )

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    $removed = [System.Collections.Generic.List[string]]::new()

    foreach ($storeName in $StoreNames) {
        $store = $null
        try {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
            $matches = @($store.Certificates | Where-Object {
                ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp
            })
            foreach ($cert in $matches) {
                $store.Remove($cert)
                $removed.Add("$storeName")
            }
        }
        catch { }
        finally {
            if ($store) { $store.Close() }
        }
    }

    try {
        $ntds = Open-AdLdapsServiceCertificateStore -ServiceName 'NTDS' -StoreName 'My' `
            -OpenFlags ([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        try {
            $matches = @($ntds.Certificates | Where-Object {
                ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp
            })
            foreach ($cert in $matches) {
                $ntds.Remove($cert)
                $removed.Add('NTDS\My')
            }
        }
        finally {
            $ntds.Close()
        }
    }
    catch { }

    $regPath = Join-Path (Get-AdLdapsNtdsServiceCertificateRegistryPath) $tp
    if (Test-Path -LiteralPath $regPath) {
        Remove-Item -LiteralPath $regPath -Recurse -Force -ErrorAction SilentlyContinue
        $removed.Add('NTDS-registry')
    }

    return [string[]]@($removed | Select-Object -Unique)
}

function Clear-AdLdapsUnusableManagedCertificates {
    $removed = [System.Collections.Generic.List[string]]::new()
    $candidates = @(Get-AdLdapsCertificateStoreCandidates -StoreNames @('My'))
    foreach ($item in $candidates) {
        $cert = $item.Certificate
        if (-not (Test-AdLdapsManagedCertificate -Certificate $cert)) { continue }
        $uses = Test-AdLdapsCertificateUses -Certificate $cert
        if ($uses.Ok) { continue }

        $tp = ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
        $why = ($uses.Reasons | Select-Object -First 1)
        if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
            Write-Info "Removing unusable managed LDAPS certificate $tp ($why)"
        }
        $null = Remove-AdLdapsCertificateByThumbprint -Thumbprint $tp
        $removed.Add($tp)
    }
    return [string[]]@($removed)
}

function Clear-AdLdapsManagedCertificates {
    param([string]$KeepThumbprint)

    $keep = if ($KeepThumbprint) { ($KeepThumbprint -replace '\s', '').ToUpperInvariant() } else { $null }
    $removed = [System.Collections.Generic.List[string]]::new()
    $candidates = @(Get-AdLdapsCertificateStoreCandidates -StoreNames @('My'))
    foreach ($item in $candidates) {
        $cert = $item.Certificate
        if (-not (Test-AdLdapsManagedCertificate -Certificate $cert)) { continue }
        $tp = ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
        if ($keep -and $tp -eq $keep) { continue }
        if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
            Write-Info "Removing previous managed LDAPS certificate $tp ($($cert.FriendlyName))"
        }
        $null = Remove-AdLdapsCertificateByThumbprint -Thumbprint $tp
        $removed.Add($tp)
    }
    return [string[]]@($removed)
}

function Install-AdLdapsCertificateIntoTrustedRoot {
    param([Parameter(Mandatory)]$Certificate)

    $tp = ([string]$Certificate.Thumbprint -replace '\s', '').ToUpperInvariant()
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('Root', 'LocalMachine')
    $rootStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $existing = $rootStore.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp
        } | Select-Object -First 1
        if ($existing) {
            Write-Info "Certificate $tp is already in LocalMachine\Root."
            return $false
        }
        # Public-only copy — never push the private-key handle into the Root store.
        $publicBytes = $Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        $publicCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(,$publicBytes)
        $rootStore.Add($publicCert)
        Write-Ok "Added certificate $tp to LocalMachine\Root (required for AD DS to trust a self-signed LDAPS cert)."
        return $true
    }
    finally {
        $rootStore.Close()
    }
}

function Test-AdLdapsCertificateSchannelReady {
    param(
        [Parameter(Mandatory)]$Certificate,
        [string]$DnsName
    )

    $reasons = [System.Collections.Generic.List[string]]::new()
    $expected = if ($DnsName) { $DnsName.TrimEnd('.').ToLowerInvariant() } else { (Get-AdLdapsMachineDnsFullyQualifiedName).TrimEnd('.').ToLowerInvariant() }
    $certNames = @(Get-AdLdapsCertificateDnsNames -Certificate $Certificate | ForEach-Object { $_.TrimEnd('.').ToLowerInvariant() })
    if ($certNames -notcontains $expected) {
        $reasons.Add("Certificate DNS names ($($certNames -join ', ')) do not include the AD DS FQDN '$expected'. Short name alone (e.g. ad-resource) will not enable LDAPS — create a new cert or pick one that includes the FQDN.")
    }

    $uses = Test-AdLdapsCertificateUses -Certificate $Certificate
    foreach ($r in $uses.Reasons) { $reasons.Add($r) }

    if ((Test-AdLdapsCertificateIsSelfSigned -Certificate $Certificate)) {
        Install-AdLdapsCertificateIntoTrustedRoot -Certificate $Certificate | Out-Null
    }

    $testCert = Get-Command Test-Certificate -ErrorAction SilentlyContinue
    if ($testCert -and $reasons.Count -eq 0) {
        try {
            $ok = Test-Certificate -Cert $Certificate -Policy SSL -EKU @($script:ServerAuthOid) -DNSName $expected -ErrorAction Stop
            if (-not $ok) {
                $reasons.Add('Test-Certificate -Policy SSL failed for this certificate (chain/EKU/DNS).')
            }
        }
        catch {
            $msg = [string]$_.Exception.Message
            # Self-signed / lab CAs: AD DS still selects certs with unknown revocation; untrusted root
            # after we just installed to Root can be a timing/cache issue — warn, do not hard-fail.
            if ($msg -match '(?i)revocation|UNTRUSTEDROOT|not trusted by the trust provider|0x800b0109') {
                if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                    Write-Info "Test-Certificate trust/revocation warning (continuing for LDAPS): $msg"
                }
            }
            else {
                $reasons.Add("Test-Certificate -Policy SSL: $msg")
            }
        }
    }

    return [PSCustomObject]@{
        Ok             = ($reasons.Count -eq 0)
        Reasons        = @($reasons)
        ExpectedDns    = $expected
        CertificateDns = $certNames
    }
}

function Install-AdLdapsCertificateIntoNtdsServiceStore {
    param(
        [Parameter(Mandatory)][string]$Thumbprint,
        [switch]$RemoveCompetingCertificates
    )

    $tp = ($Thumbprint -replace '\s', '').ToUpperInvariant()
    $cert = Get-AdLdapsCertificateFromLocalMachineMy -Thumbprint $tp

    # Prefer CertOpenStore("NTDS\My") + Add() so the private key is available to the NTDS
    # service. A bare registry Copy-Item of the LocalMachine\My blob often leaves a public
    # cert without a usable key, and AD DS silently skips it (no listener on 636).
    $store = $null
    $added = $false
    $removed = [System.Collections.Generic.List[string]]::new()
    try {
        $store = Open-AdLdapsServiceCertificateStore -ServiceName 'NTDS' -StoreName 'My' `
            -OpenFlags ([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

        # RabbitMQ / FAM / short-name certs in NTDS\My win selection or break TLS even when
        # TCP 636 is open. Keep only the LDAPS cert we intend AD DS to present.
        if ($RemoveCompetingCertificates) {
            $competitors = @($store.Certificates | Where-Object {
                ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -ne $tp
            })
            foreach ($other in $competitors) {
                $otherTp = ([string]$other.Thumbprint -replace '\s', '').ToUpperInvariant()
                $label = if ($other.Subject) { $other.Subject } else { $otherTp }
                Write-Info "Removing competing NTDS\My certificate: $label ($otherTp)"
                $store.Remove($other)
                $removed.Add($otherTp)
            }
        }

        $existing = @($store.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp
        })
        foreach ($old in $existing) {
            if (-not $old.HasPrivateKey) {
                Write-Info "Removing NTDS\My entry for $tp that has no private key (likely a registry-only copy)."
                $store.Remove($old)
            }
        }

        $stillThere = @($store.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq $tp -and $_.HasPrivateKey
        })
        if ($stillThere.Count -eq 0) {
            $store.Add($cert)
            $added = $true
            Write-Ok "Added certificate $tp with private key to the NTDS service Personal store (NTDS\My)."
        }
        else {
            Write-Info "Certificate $tp with private key is already in NTDS\My."
        }
    }
    catch {
        Write-Info "CertOpenStore NTDS\My failed ($($_.Exception.Message)); falling back to registry link."
        $destRoot = Get-AdLdapsNtdsServiceCertificateRegistryPath
        if (-not (Test-Path -LiteralPath $destRoot)) {
            New-Item -Path $destRoot -Force | Out-Null
        }
        if ($RemoveCompetingCertificates -and (Test-Path -LiteralPath $destRoot)) {
            Get-ChildItem -LiteralPath $destRoot -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.PSChildName.ToUpperInvariant() -ne $tp) {
                    Write-Info "Removing competing NTDS registry cert $($_.PSChildName)"
                    Remove-Item -LiteralPath $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    $removed.Add($_.PSChildName.ToUpperInvariant())
                }
            }
        }
        $source = Get-AdLdapsLocalMachineCertificateRegistryPath -Thumbprint $tp
        $dest = Join-Path $destRoot $tp
        if (-not (Test-Path -LiteralPath $dest)) {
            Copy-Item -Path $source -Destination $destRoot -ErrorAction Stop
            $added = $true
            Write-Ok "Linked certificate $tp into NTDS service store via registry (fallback)."
        }
    }
    finally {
        if ($store) { $store.Close() }
    }

    return [PSCustomObject]@{
        Added              = $added
        RemovedThumbprints = @($removed)
    }
}

function Invoke-AdLdapsCertificateRenewal {
    try {
        $dse = [adsi]'LDAP://localhost/rootDSE'
        [void]$dse.Properties['renewServerCertificate'].Add(1)
        $dse.CommitChanges()
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
    $fqdn = $null
    try { $fqdn = Get-AdLdapsMachineDnsFullyQualifiedName } catch { }
    if ($fqdn) {
        $fqdn = $fqdn.TrimEnd('.').ToLowerInvariant()
        # Ensure FQDN is first (Subject CN) — AD DS will not select a short-name-only cert.
        $hostNames = @($fqdn) + @($hostNames | Where-Object { $_.TrimEnd('.').ToLowerInvariant() -ne $fqdn })
    }
    if ($hostNames.Count -eq 0) {
        throw 'Unable to determine DNS names for the LDAPS certificate.'
    }

    $friendly = "SailPoint AD LDAPS ($($hostNames[0]))"
    # Prefer the default CNG/Schannel-capable provider. The legacy "Microsoft RSA SChannel
    # Cryptographic Provider" often yields a cert whose private key is not visible to the
    # creating process (HasPrivateKey=$false), which then fails Schannel validation.
    $params = @{
        Subject           = "CN=$($hostNames[0])"
        DnsName           = $hostNames
        KeyAlgorithm      = 'RSA'
        KeyLength         = 2048
        KeyExportPolicy   = 'Exportable'
        KeySpec           = 'KeyExchange'
        KeyUsage          = @('DigitalSignature', 'KeyEncipherment')
        TextExtension     = @("2.5.29.37={text}$($script:ServerAuthOid)")
        NotAfter          = $NotAfter
        CertStoreLocation = 'Cert:\LocalMachine\My'
        FriendlyName      = $friendly
    }

    # Replace prior SailPoint-created LDAPS certs so a broken create does not linger in the picker.
    $null = Clear-AdLdapsManagedCertificates

    Write-Step "Creating self-signed LDAPS certificate for $($hostNames -join ', ')"
    Write-Info "Subject CN / primary SAN will be '$($hostNames[0])' (must match AD DS FQDN)."
    $created = New-SelfSignedCertificate @params
    $thumb = [string]$created.Thumbprint

    # Re-open from LocalMachine\My so we hold a cert object with a usable private key after
    # any subsequent public-only Root store import.
    $cert = Get-AdLdapsCertificateFromLocalMachineMy -Thumbprint $thumb
    Write-Ok "Created certificate $thumb (CN/SAN: $($hostNames -join ', '))"

    $uses = Test-AdLdapsCertificateUses -Certificate $cert
    if (-not $uses.Ok) {
        throw "Newly created certificate $thumb failed LDAPS uses checks: $($uses.Reasons -join ' ')"
    }

    Install-AdLdapsCertificateIntoTrustedRoot -Certificate $cert | Out-Null
    # Refresh again after Root import.
    $cert = Get-AdLdapsCertificateFromLocalMachineMy -Thumbprint $thumb

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

    $listenDetail = $null
    $getConn = Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue
    if ($getConn) {
        try {
            $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
            if ($listeners.Count -gt 0) {
                $addrs = ($listeners | ForEach-Object { "$($_.LocalAddress):$($_.LocalPort)" } | Select-Object -Unique) -join ', '
                return [PSCustomObject]@{
                    Listening = $true
                    Detail    = "TCP $Port is listening ($addrs)"
                }
            }
            $listenDetail = "Get-NetTCPConnection found no Listen state on TCP $Port"
        }
        catch {
            $listenDetail = "Get-NetTCPConnection failed: $($_.Exception.Message)"
        }
    }

    $client = $null
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $waited = $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if (-not $waited) {
            $extra = if ($listenDetail) { " ($listenDetail)" } else { '' }
            return [PSCustomObject]@{ Listening = $false; Detail = "Timed out connecting to ${ComputerName}:$Port$extra" }
        }
        $client.EndConnect($async)
        return [PSCustomObject]@{ Listening = $true; Detail = "TCP $Port accepts connections on $ComputerName" }
    }
    catch {
        $extra = if ($listenDetail) { " ($listenDetail)" } else { '' }
        return [PSCustomObject]@{ Listening = $false; Detail = "$($_.Exception.Message)$extra" }
    }
    finally {
        if ($client) { $client.Dispose() }
    }
}

function Test-AdLdapsTlsHandshake {
    param(
        [string]$HostName,
        [int]$Port = 636,
        [string]$ExpectedThumbprint,
        [int]$TimeoutMs = 5000
    )

    if (-not $HostName) {
        $HostName = Get-AdLdapsMachineDnsFullyQualifiedName
    }
    $HostName = $HostName.TrimEnd('.')

    $tcp = $null
    $ssl = $null
    $state = @{ Cert = $null }
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $async = $tcp.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            return [PSCustomObject]@{
                Ok         = $false
                Detail     = "TLS probe timed out connecting to ${HostName}:$Port"
                Thumbprint = $null
                Subject    = $null
            }
        }
        $tcp.EndConnect($async)

        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, {
            param($sender, $certificate, $chain, $errors)
            if ($certificate) {
                $state.Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificate)
            }
            return $true
        }.GetNewClosure())
        $ssl.AuthenticateAsClient($HostName)
        $cert = $state.Cert

        if (-not $cert) {
            return [PSCustomObject]@{
                Ok         = $false
                Detail     = "TLS connected to ${HostName}:$Port but no server certificate was presented."
                Thumbprint = $null
                Subject    = $null
            }
        }

        $tp = ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
        $expected = if ($ExpectedThumbprint) { ($ExpectedThumbprint -replace '\s', '').ToUpperInvariant() } else { $null }
        if ($expected -and $tp -ne $expected) {
            return [PSCustomObject]@{
                Ok         = $false
                Detail     = "TLS on ${HostName}:$Port presented unexpected cert $tp ($($cert.Subject)); expected $expected. Competing NTDS\My certificates may still be selected."
                Thumbprint = $tp
                Subject    = [string]$cert.Subject
            }
        }

        return [PSCustomObject]@{
            Ok         = $true
            Detail     = "TLS handshake to ${HostName}:$Port succeeded; presented $tp ($($cert.Subject))"
            Thumbprint = $tp
            Subject    = [string]$cert.Subject
        }
    }
    catch {
        return [PSCustomObject]@{
            Ok         = $false
            Detail     = "TLS handshake to ${HostName}:$Port failed: $($_.Exception.Message)"
            Thumbprint = $null
            Subject    = $null
        }
    }
    finally {
        if ($ssl) { $ssl.Dispose() }
        if ($tcp) { $tcp.Dispose() }
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
    if ($Result.PSObject.Properties['CompetingRemoved'] -and @($Result.CompetingRemoved).Count -gt 0) {
        $situation.Add("Removed $(@($Result.CompetingRemoved).Count) competing certificate(s) from NTDS\My so AD DS presents this LDAPS cert.")
    }
    if ($Result.PortCheck) {
        if ($Result.PortCheck.Listening) {
            $situation.Add("Port $($script:LdapsPort): $($Result.PortCheck.Detail)")
        }
        else {
            $situation.Add("Port $($script:LdapsPort) not accepting connections yet: $($Result.PortCheck.Detail)")
        }
    }
    if ($Result.PSObject.Properties['TlsCheck'] -and $Result.TlsCheck) {
        if ($Result.TlsCheck.Ok) {
            $situation.Add("TLS: $($Result.TlsCheck.Detail)")
        }
        else {
            $situation.Add("TLS handshake failed: $($Result.TlsCheck.Detail)")
            $situation.Add('TCP 636 can be open while the wrong cert is presented — check certutil -store -service NTDS My.')
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
    $friendly = $null
    if ($Entry.PSObject.Properties['Certificate'] -and $Entry.Certificate -and
        $Entry.Certificate.PSObject.Properties['FriendlyName'] -and $Entry.Certificate.FriendlyName) {
        $friendly = [string]$Entry.Certificate.FriendlyName
    }
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

    $subject = if ($friendly) { $friendly } else { $dnsText }
    $label = "$store | $subject | $expiryText"
    if ($friendly -and $dnsText -and $friendly -ne $dnsText) {
        $label = "$store | $friendly | $dnsText | $expiryText"
    }
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
        [string]$RequiredDnsName,
        [object[]]$Candidates,
        [datetime]$Now = $(Get-Date),
        [string]$Prompt = 'Select the LDAPS certificate to use:'
    )

    if (-not $RequiredDnsName) {
        try { $RequiredDnsName = Get-AdLdapsMachineDnsFullyQualifiedName } catch { }
    }

    # Drop prior SailPoint self-signed LDAPS certs that have no usable private key / uses.
    if (-not $Candidates) {
        $null = Clear-AdLdapsUnusableManagedCertificates
    }

    $found = Find-AdLdapsCertificate -DnsName $DnsName -RequiredDnsName $RequiredDnsName `
        -Candidates $Candidates -Now $Now
    $accepted = @($found.Accepted)
    $rejected = @($found.Rejected)

    if ($RequiredDnsName -and (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        Write-Info "AD DS requires certificate SAN/CN to include: $RequiredDnsName"
    }

    if ($rejected.Count -gt 0 -and (Get-Command Write-Info -ErrorAction SilentlyContinue)) {
        Write-Info "$($rejected.Count) certificate(s) in LocalMachine NTDS/My were skipped (failed FQDN match or required uses)."
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

    # Purge SailPoint self-signed LDAPS certs that cannot present a private key.
    $null = Clear-AdLdapsUnusableManagedCertificates

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

    $machineDns = Get-AdLdapsMachineDnsFullyQualifiedName
    Write-Info "AD DS machine DNS name (must match cert SAN/CN): $machineDns"

    Write-Step 'Validating certificate for Schannel / LDAPS selection'
    $schannel = Test-AdLdapsCertificateSchannelReady -Certificate $cert -DnsName $machineDns
    if (-not $schannel.Ok) {
        foreach ($reason in $schannel.Reasons) {
            Write-Host "   $reason" -ForegroundColor Yellow
        }
        throw "Certificate $($cert.Thumbprint) is not ready for AD DS LDAPS. Fix the issues above (especially DNS name '$machineDns'), or choose Create self-signed."
    }
    Write-Ok "Certificate passes Schannel readiness checks for '$machineDns'."

    Write-Step 'Installing certificate into NTDS\My (private key) and removing competing NTDS certs'
    $myStore = New-Object System.Security.Cryptography.X509Certificates.X509Store('My', 'LocalMachine')
    $myStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $inMy = $myStore.Certificates | Where-Object {
            ([string]$_.Thumbprint -replace '\s', '').ToUpperInvariant() -eq ([string]$cert.Thumbprint -replace '\s', '').ToUpperInvariant()
        } | Select-Object -First 1
        if (-not $inMy) {
            $myStore.Add($cert)
            Write-Ok 'Copied certificate into LocalMachine\My'
        }
    }
    finally {
        $myStore.Close()
    }

    $ntdsInstall = Install-AdLdapsCertificateIntoNtdsServiceStore -Thumbprint $cert.Thumbprint -RemoveCompetingCertificates
    $ntdsLinked = [bool]$ntdsInstall.Added -or ($ntdsInstall.RemovedThumbprints.Count -gt 0)
    if ($ntdsInstall.RemovedThumbprints.Count -gt 0) {
        Write-Ok "Removed $($ntdsInstall.RemovedThumbprints.Count) competing certificate(s) from NTDS\My (e.g. RabbitMQ / short-name)."
    }
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
    Start-Sleep -Seconds 1
    $portCheck = Test-AdLdapsPort -Port $script:LdapsPort
    $tlsCheck = Test-AdLdapsTlsHandshake -HostName $machineDns -Port $script:LdapsPort -ExpectedThumbprint $cert.Thumbprint
    $needsRestart = $created -or $ntdsLinked -or -not $portCheck.Listening -or -not $tlsCheck.Ok
    if ($needsRestart) {
        $shouldRestart = [bool]$RestartNtds
        if (-not $NonInteractive -and -not $RestartNtds) {
            $shouldRestart = Read-YesNo -Prompt "Restart NTDS so AD DS presents the LDAPS certificate on TCP $($script:LdapsPort)? (brief AD outage)" -Default $true
        }
        elseif ($NonInteractive -and -not $RestartNtds -and (-not $portCheck.Listening -or -not $tlsCheck.Ok)) {
            Write-Info "LDAPS is not healthy yet. Pass -RestartNtds (recommended) after installing the certificate."
        }
        if ($shouldRestart) {
            $ntdsStatus = Restart-AdNtdsService
            $ntdsRestarted = $true
            Start-Sleep -Seconds 3
            $renewed = (Invoke-AdLdapsCertificateRenewal) -or $renewed
            Start-Sleep -Seconds 2
            $portCheck = Test-AdLdapsPort -Port $script:LdapsPort
            $tlsCheck = Test-AdLdapsTlsHandshake -HostName $machineDns -Port $script:LdapsPort -ExpectedThumbprint $cert.Thumbprint
        }
    }

    Write-Step "Exporting certificate chain as PEM to $PemOutputPath"
    $export = Export-AdLdapsCertificateChain -Certificate $cert -OutputPath $PemOutputPath
    Write-Ok "Wrote $($export.Files.Count) PEM file(s); chain: $($export.ChainPath)"

    $result = [PSCustomObject]@{
        Thumbprint             = [string]$cert.Thumbprint
        StoreName              = $storeName
        DnsNames               = @(Get-AdLdapsCertificateDnsNames -Certificate $cert)
        MachineDnsName         = $machineDns
        CreatedCertificate     = $created
        NtdsServiceLinked      = [bool](Test-AdLdapsCertificateInNtdsServiceStore -Thumbprint $cert.Thumbprint)
        NtdsLinkCreated        = [bool]$ntdsInstall.Added
        CompetingRemoved       = @($ntdsInstall.RemovedThumbprints)
        RenewServerCertificate = $renewed
        FirewallRuleCreated    = $fwCreated
        NtdsRestarted          = $ntdsRestarted
        NtdsStatus             = $ntdsStatus
        PortCheck              = $portCheck
        TlsCheck               = $tlsCheck
        Export                 = $export
        SchannelCheck          = $schannel
    }

    $healthy = $portCheck.Listening -and $tlsCheck.Ok
    if ($healthy) {
        Write-Ok $portCheck.Detail
        Write-Ok $tlsCheck.Detail
        Show-AdLdapsCompletion -Result $result
        return $result
    }

    $diag = [System.Collections.Generic.List[string]]::new()
    if (-not $portCheck.Listening) {
        $diag.Add("TCP $($script:LdapsPort) is not listening: $($portCheck.Detail)")
    }
    else {
        $diag.Add("TCP $($script:LdapsPort) is open, but TLS is not healthy: $($tlsCheck.Detail)")
        $diag.Add('lsass can listen on 636 while presenting a wrong cert (RabbitMQ/FAM/short-name). Clients then fall back to LDAP 389.')
    }
    $diag.Add("Machine DNS name AD DS expects: $machineDns")
    $diag.Add("Certificate thumbprint: $($cert.Thumbprint)")
    $diag.Add("Certificate DNS names: $((@(Get-AdLdapsCertificateDnsNames -Certificate $cert)) -join ', ')")
    $diag.Add("In NTDS service store: $($result.NtdsServiceLinked)")
    $diag.Add('Run: certutil -store -service NTDS My')
    $diag.Add("Run: Test-AdLdapsTlsHandshake -HostName $machineDns -ExpectedThumbprint $($cert.Thumbprint)")
    $diag.Add('If still failing after NTDS restart, reboot the domain controller once.')
    foreach ($line in $diag) {
        Write-Host "   $line" -ForegroundColor Yellow
    }
    Show-AdLdapsCompletion -Result $result
    throw ($diag -join ' ')
}

Export-ModuleMember -Function @(
    'Get-AdLdapsHostNames'
    'Get-AdLdapsMachineDnsFullyQualifiedName'
    'Test-AdDomainController'
    'Assert-AdDomainController'
    'Get-AdLdapsCertificateDnsNames'
    'Test-AdLdapsCertificateNameMatch'
    'Get-AdLdapsKeySpec'
    'Get-AdLdapsEnhancedKeyUsages'
    'Test-AdLdapsCertificateHasPrivateKey'
    'Test-AdLdapsManagedCertificate'
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
    'Initialize-AdLdapsCertOpenStoreType'
    'Open-AdLdapsServiceCertificateStore'
    'Get-AdLdapsCertificateFromLocalMachineMy'
    'Test-AdLdapsCertificateIsSelfSigned'
    'Remove-AdLdapsCertificateByThumbprint'
    'Clear-AdLdapsUnusableManagedCertificates'
    'Clear-AdLdapsManagedCertificates'
    'Install-AdLdapsCertificateIntoTrustedRoot'
    'Test-AdLdapsCertificateSchannelReady'
    'Install-AdLdapsCertificateIntoNtdsServiceStore'
    'Invoke-AdLdapsCertificateRenewal'
    'New-AdLdapsSelfSignedCertificate'
    'Enable-AdLdapsFirewallRule'
    'Test-AdLdapsPort'
    'Test-AdLdapsTlsHandshake'
    'Restart-AdNtdsService'
    'ConvertTo-X509Pem'
    'Get-AdLdapsCertificateChain'
    'Export-AdLdapsCertificateChain'
    'Get-AdLdapsVaManualSteps'
    'Show-AdLdapsCompletion'
    'Enable-AdLdaps'
)
