param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AdLdaps.psm1'),
    [string]$ConsolePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorConsole.psm1')
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

function Assert-Contains {
    param([string]$Needle, [string]$Haystack, [string]$Message)
    $script:AssertionCount++
    if ($Haystack -notlike "*$Needle*") {
        throw "Assertion failed: $Message. Expected to find '$Needle'."
    }
}

Import-Module $ConsolePath -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole -NonInteractive
Import-Module $ModulePath -Force -WarningAction SilentlyContinue

$serverAuth = '1.3.6.1.5.5.7.3.1'
$digitalSignature = [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature
$keyEncipherment = [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment
$bothKu = $digitalSignature -bor $keyEncipherment

function New-MockCert {
    param(
        [string]$Thumbprint = 'AABBCC',
        [string[]]$DnsNames = @('dc1.contoso.local'),
        [bool]$HasPrivateKey = $true,
        $EnhancedKeyUsageList = @($serverAuth),
        $KeyUsageFlags = $bothKu,
        [string]$KeySpec = 'KeyExchange',
        [datetime]$NotBefore = $(Get-Date).AddDays(-1),
        [datetime]$NotAfter = $(Get-Date).AddYears(1),
        [string]$Subject = 'CN=dc1.contoso.local',
        [byte[]]$RawData = $null,
        $ChainCertificates = $null
    )

    if (-not $RawData) {
        $RawData = [byte[]](1..80)
    }

    return [PSCustomObject]@{
        Thumbprint            = $Thumbprint
        DnsNames              = $DnsNames
        HasPrivateKey         = $HasPrivateKey
        EnhancedKeyUsageList  = $EnhancedKeyUsageList
        KeyUsageFlags         = $KeyUsageFlags
        KeySpec               = $KeySpec
        NotBefore             = $NotBefore
        NotAfter              = $NotAfter
        Subject               = $Subject
        RawData               = $RawData
        ChainCertificates     = $ChainCertificates
        Extensions            = $null
    }
}

# --- PEM encoding ---
$leafBytes = [byte[]](0..69)
$pem = ConvertTo-X509Pem -Certificate ([PSCustomObject]@{ RawData = $leafBytes })
Assert-Contains '-----BEGIN CERTIFICATE-----' $pem 'PEM has begin marker'
Assert-Contains '-----END CERTIFICATE-----' $pem 'PEM has end marker'
$b64Body = (($pem -split "`n") | Where-Object { $_ -notmatch 'CERTIFICATE' }) -join ''
Assert-equal ([Convert]::ToBase64String($leafBytes)) $b64Body 'PEM body is Base64 of RawData'
$lines = @($pem -split "`n" | Where-Object { $_ -notmatch 'CERTIFICATE' -and $_ })
Assert-True ((($lines | Where-Object { $_.Length -gt 64 }).Count) -eq 0) 'PEM lines are at most 64 characters'

# --- Chain export leaf-first ---
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("adldaps-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
    $leaf = New-MockCert -Thumbprint 'LEAF01' -RawData ([byte[]](10..19)) -DnsNames @('dc1.contoso.local')
    $intermediate = New-MockCert -Thumbprint 'INT01' -RawData ([byte[]](20..29)) -DnsNames @('ca.contoso.local')
    $root = New-MockCert -Thumbprint 'ROOT01' -RawData ([byte[]](30..39)) -DnsNames @('root.contoso.local')
    $leaf.ChainCertificates = @($leaf, $intermediate, $root)

    $export = Export-AdLdapsCertificateChain -Certificate $leaf -OutputPath $tempRoot -FilePrefix 'dc1.contoso.local-ldaps'
    Assert-equal 3 $export.ChainCount 'chain has leaf + intermediate + root'
    Assert-equal 4 $export.Files.Count 'three member files plus concatenated chain'
    Assert-True (Test-Path -LiteralPath (Join-Path $tempRoot 'dc1.contoso.local-ldaps-00-leaf.pem')) 'leaf file named 00-leaf'
    Assert-True (Test-Path -LiteralPath (Join-Path $tempRoot 'dc1.contoso.local-ldaps-01-intermediate.pem')) 'intermediate file named 01'
    Assert-True (Test-Path -LiteralPath (Join-Path $tempRoot 'dc1.contoso.local-ldaps-02-root.pem')) 'root file named 02-root'
    Assert-True (Test-Path -LiteralPath $export.ChainPath) 'concatenated chain file exists'

    $chainPem = Get-Content -LiteralPath $export.ChainPath -Raw
    $leafPem = Get-Content -LiteralPath (Join-Path $tempRoot 'dc1.contoso.local-ldaps-00-leaf.pem') -Raw
    Assert-True $chainPem.StartsWith($leafPem.Trim()) 'concatenated chain starts with leaf PEM'
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# --- VA manual steps ---
$steps = @(Get-AdLdapsVaManualSteps -ChainPath 'C:\SailPoint\va-certificates\dc1-ldaps-chain.pem' -PemDirectory 'C:\SailPoint\va-certificates')
Assert-True ($steps.Count -ge 6) 'VA steps include numbered instructions'
Assert-True ($steps -join ' ' -match '/home/sailpoint/certificates') 'VA steps mention certificates directory'
Assert-True ($steps -join ' ' -match 'systemctl restart ccg') 'VA steps mention ccg restart'
Assert-True ($steps -join ' ' -match 'ccg-start.log') 'VA steps mention ccg-start.log'
Assert-True ($steps -join ' ' -match 'config_va.html') 'VA steps link tenant TLS docs'
Assert-True ($steps -join ' ' -match 'tls_config_on_va.html') 'VA steps link manual upload docs'

# --- Uses gate: accept unrestricted (no EKU / no KU) ---
$unrestricted = New-MockCert -EnhancedKeyUsageList $null -KeyUsageFlags $null -KeySpec 'KeyExchange'
$okUnrestricted = Test-AdLdapsCertificateUses -Certificate $unrestricted
Assert-True $okUnrestricted.Ok 'unrestricted EKU/KU with KeyExchange is accepted'

# --- Uses gate: accept full Schannel shape ---
$full = New-MockCert
$okFull = Test-AdLdapsCertificateUses -Certificate $full
Assert-True $okFull.Ok 'full Server Auth + DigitalSignature + KeyEncipherment + KeyExchange is accepted'

# --- Uses gate: reject missing Server Authentication ---
$clientOnly = New-MockCert -EnhancedKeyUsageList @('1.3.6.1.5.5.7.3.2')
$badEku = Test-AdLdapsCertificateUses -Certificate $clientOnly
Assert-True (-not $badEku.Ok) 'client-auth-only EKU is rejected'
Assert-True ($badEku.Reasons -join ' ' -match 'Server Authentication') 'rejection mentions Server Authentication'

# --- Uses gate: reject missing Key Encipherment ---
$noEncipher = New-MockCert -KeyUsageFlags $digitalSignature
$badKu = Test-AdLdapsCertificateUses -Certificate $noEncipher
Assert-True (-not $badKu.Ok) 'DigitalSignature-only Key Usage is rejected'
Assert-True ($badKu.Reasons -join ' ' -match 'KeyEncipherment') 'rejection mentions KeyEncipherment'

# --- Uses gate: reject signature-only KeySpec ---
$sigOnly = New-MockCert -KeySpec 'Signature'
$badSpec = Test-AdLdapsCertificateUses -Certificate $sigOnly
Assert-True (-not $badSpec.Ok) 'signature-only KeySpec is rejected'
Assert-True ($badSpec.Reasons -join ' ' -match 'signature-only|AT_SIGNATURE|KeyExchange') 'rejection mentions KeySpec'

# --- Uses gate: reject missing private key ---
$noKey = New-MockCert -HasPrivateKey $false
$badKey = Test-AdLdapsCertificateUses -Certificate $noKey
Assert-True (-not $badKey.Ok) 'certificate without private key is rejected'

# --- Ranking: NTDS preferred, then longest validity ---
$now = Get-Date
$myOld = New-MockCert -Thumbprint 'MYOLD' -NotAfter $now.AddMonths(1) -DnsNames @('dc1.contoso.local')
$ntdsNew = New-MockCert -Thumbprint 'NTDSNEW' -NotAfter $now.AddYears(2) -DnsNames @('dc1.contoso.local')
$myLonger = New-MockCert -Thumbprint 'MYLONG' -NotAfter $now.AddYears(3) -DnsNames @('dc1.contoso.local')

$found = Find-AdLdapsCertificate -DnsName @('dc1.contoso.local') -Candidates @(
    [PSCustomObject]@{ Certificate = $myLonger; StoreName = 'My' }
    [PSCustomObject]@{ Certificate = $ntdsNew; StoreName = 'NTDS' }
    [PSCustomObject]@{ Certificate = $myOld; StoreName = 'My' }
) -Now $now
Assert-equal 'NTDSNEW' $found.Thumbprint 'NTDS store ranks above My even when My has longer validity'

$foundMy = Find-AdLdapsCertificate -DnsName @('dc1.contoso.local') -Candidates @(
    [PSCustomObject]@{ Certificate = $myOld; StoreName = 'My' }
    [PSCustomObject]@{ Certificate = $myLonger; StoreName = 'My' }
) -Now $now
Assert-equal 'MYLONG' $foundMy.Thumbprint 'among My-store certs, longest NotAfter wins'

# --- Thumbprint pin still enforces uses gate ---
$pinnedBad = New-MockCert -Thumbprint 'BADPIN' -KeySpec 'Signature'
$threw = $false
try {
    Find-AdLdapsCertificate -Thumbprint 'BADPIN' -DnsName @('dc1.contoso.local') -Candidates @(
        [PSCustomObject]@{ Certificate = $pinnedBad; StoreName = 'My' }
    ) -Now $now | Out-Null
}
catch {
    $threw = $true
    Assert-Contains 'required LDAPS uses' $_.Exception.Message 'pinned unusable cert fails with uses message'
}
Assert-True $threw 'pinned signature-only cert throws'

# --- Name mismatch rejected from accepted set ---
$wrongHost = New-MockCert -Thumbprint 'WRONG' -DnsNames @('other.contoso.local')
$foundNone = Find-AdLdapsCertificate -DnsName @('dc1.contoso.local') -Candidates @(
    [PSCustomObject]@{ Certificate = $wrongHost; StoreName = 'My' }
) -Now $now
Assert-True ($null -eq $foundNone.Certificate) 'name mismatch yields no accepted certificate'
Assert-equal 1 $foundNone.Rejected.Count 'name mismatch is recorded as rejected'

# --- Choice labels ---
$labelEntry = [PSCustomObject]@{
    StoreName  = 'NTDS'
    DnsNames   = @('dc1.contoso.local', 'dc1', 'extra.contoso.local')
    NotAfter   = [datetime]'2027-06-15'
    Thumbprint = 'AABBCCDDEEFF00112233445566778899AABBCCDD'
}
$label = Format-AdLdapsCertificateChoiceLabel -Entry $labelEntry -IncludeThumbprint
Assert-Contains 'NTDS' $label 'choice label includes store'
Assert-Contains 'dc1.contoso.local' $label 'choice label includes primary DNS'
Assert-Contains '…' $label 'choice label truncates extra DNS and long thumbprint'
Assert-Contains 'expires 2027-06-15' $label 'choice label includes expiry'

# --- Interactive selection defaults (NonInteractive uses Default) ---
$pickExisting = Select-AdLdapsCertificate -DnsName @('dc1.contoso.local') -Candidates @(
    [PSCustomObject]@{ Certificate = $ntdsNew; StoreName = 'NTDS' }
    [PSCustomObject]@{ Certificate = $myLonger; StoreName = 'My' }
) -Now $now
Assert-equal 'NTDSNEW' $pickExisting.Thumbprint 'selection defaults to top-ranked usable cert'
Assert-True (-not $pickExisting.CreateSelfSigned) 'selection of existing cert is not CreateSelfSigned'

$pickCreate = Select-AdLdapsCertificate -DnsName @('dc1.contoso.local') -Candidates @(
    [PSCustomObject]@{ Certificate = $wrongHost; StoreName = 'My' }
) -Now $now
Assert-True $pickCreate.CreateSelfSigned 'when nothing is usable, selection defaults to create'
Assert-True ($null -eq $pickCreate.Thumbprint) 'create selection has no thumbprint'

Write-Host "PASS ($script:AssertionCount assertions)"
