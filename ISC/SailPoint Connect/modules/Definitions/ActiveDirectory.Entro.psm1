Set-StrictMode -Version Latest

$script:ProbeModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.OnPremProbe.psm1'
Import-Module $script:ProbeModule -Force -WarningAction SilentlyContinue

function Get-EntroAdLdapsPorts {
    @(
        @{ Name = 'LDAP'; Port = 389 }
        @{ Name = 'LDAPS'; Port = 636 }
        @{ Name = 'Global Catalog'; Port = 3268 }
        @{ Name = 'Global Catalog SSL'; Port = 3269 }
    )
}

function Export-EntroLdapsRootCaPem {
    param(
        [Parameter(Mandatory)][string]$Fqdn,
        [int]$Port = 636
    )
    $tcp = [System.Net.Sockets.TcpClient]::new()
    try {
        $tcp.Connect($Fqdn, $Port)
        $ssl = [System.Net.Security.SslStream]::new($tcp.GetStream(), $false, { param($sender, $certificate, $chain, $errors) $true })
        $ssl.AuthenticateAsClient($Fqdn)
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)
        $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
        [void]$chain.Build($cert)
        $root = $chain.ChainElements[$chain.ChainElements.Count - 1].Certificate
        $b64 = [Convert]::ToBase64String($root.RawData, [Base64FormattingOptions]::InsertLineBreaks)
        "-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----"
    }
    finally {
        $tcp.Dispose()
    }
}

function Test-ActiveDirectoryEntroCheck {
    param($Context, [bool]$WhatIf)
    $missing = [System.Collections.Generic.List[string]]::new()
    $met = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    $fqdn = [string]$Context['DcFqdn']
    if ([string]::IsNullOrWhiteSpace($fqdn)) { $missing.Add('DcFqdn') }
    else {
        try {
            [void][System.Net.Dns]::GetHostAddresses($fqdn)
            $met.Add("DNS $fqdn")
        }
        catch { $missing.Add("DNS $fqdn") }
        foreach ($row in Get-EntroAdLdapsPorts) {
            $label = "$($row.Name) $($fqdn):$($row.Port)"
            if ($WhatIf) { $manual.Add($label) }
            elseif (Test-OnPremTcpPort -HostName $fqdn -Port ([int]$row.Port)) { $met.Add($label) }
            else { $missing.Add($label) }
        }
    }
    if (-not [System.OperatingSystem]::IsWindows()) {
        $manual.Add('Service account creation requires a domain-joined Windows host with the ActiveDirectory module')
    }
    elseif (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        $manual.Add('ActiveDirectory module is not installed on this host')
    }
    else { $met.Add('ActiveDirectory module') }
    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    @{
        Subject       = @{ Kind = 'ActiveDirectory'; Label = 'On-prem Active Directory'; Name = $fqdn; Note = 'Read-only probe. The service account was not created.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = -not $WhatIf
        Found         = $true
        Required      = @('DNS', 'LDAPS 636', 'ActiveDirectory module')
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = @{
            'DNS'                    = 'The Worker Group can resolve the domain controller'
            'LDAPS 636'              = 'Entro binds over LDAPS'
            'ActiveDirectory module' = 'This host can create the read-only service account'
        }
        ReadNote      = "Checked $fqdn from $([Environment]::MachineName)."
    }
}

function Register-ActiveDirectoryEntroDefinitions {
    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }
    Register-IntegrationWizardDefinition @{
        Id            = 'on-prem-active-directory-entro'
        Platform      = 'OnPremActiveDirectory'
        Product       = 'Entro'
        CoreSwitch    = 'Entro'
        CliName       = 'pwsh'
        Title         = 'Entro on-prem Active Directory'
        FolderName    = 'Entro-On-Prem-Active-Directory'
        RequiredTools = @('ActiveDirectory module (RSAT) on a domain-joined Windows host')
        AccessLevels  = @()
        AdminRoles    = @('Account operator on a domain-joined Windows host (create a user, do not grant admin roles)')
        OutputsHelp   = @'
Paste into Entro (Management -> Accounts & Integrations -> Active Directory):
Nickname, Domain Controller, DC FQDN, Domain, Username (UPN), Password, Root CA PEM from root-ca.pem, Environment Nickname, Environment Type, and the Outpost Worker Group.
The service account is read-only. Do not add it to Domain Admins or other admin groups.
'@
        TargetHost    = @{
            Role  = 'Active Directory domain controller or domain-joined Windows host'
            Notes = 'Create svc_entro here. The Outpost Worker Group must reach the DC on LDAP 389, LDAPS 636, and Global Catalog 3268/3269.'
            Assert = {
                param($c)
                if (-not [System.OperatingSystem]::IsWindows()) {
                    throw 'On-prem Active Directory setup must run on a domain-joined Windows host. Use BuildScript and run the .ps1 there.'
                }
                if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
                    throw 'The ActiveDirectory module is not installed. Install RSAT Active Directory tools, or run the generated script on a host that has them.'
                }
            }
            AssertScript = @'
if (-not [System.OperatingSystem]::IsWindows()) { throw 'Run this script on a domain-joined Windows host.' }
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) { throw 'Install the ActiveDirectory RSAT module first.' }
'@
        }
        Inputs        = @(
            @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Label for this directory'; Required = $true }
            @{ Name = 'DomainController'; Source = 'Supply'; Prompt = 'Domain controller short name or IP'; Purpose = 'Value for the Entro Domain Controller field'; Required = $true }
            @{ Name = 'DcFqdn'; Source = 'Supply'; Prompt = 'Domain controller FQDN'; Purpose = 'For example dc01.example.local'; Required = $true }
            @{ Name = 'Domain'; Source = 'Supply'; Prompt = 'AD DNS domain'; Purpose = 'For example example.local'; Required = $true }
            @{ Name = 'SamAccountName'; Source = 'Supply'; Prompt = 'Service account sAMAccountName'; Purpose = 'Read-only bind account'; Default = 'svc_entro'; Required = $false }
            @{ Name = 'EnvironmentNickname'; Source = 'Supply'; Prompt = 'Environment nickname'; Purpose = 'Entro environment label'; Required = $true }
            @{ Name = 'EnvironmentType'; Source = 'Supply'; Prompt = 'Environment type'; Purpose = 'Production, Staging, or Dev'; ValidateSet = @('Production', 'Staging', 'Dev'); Default = 'Dev'; Required = $false }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that will query this domain'; Required = $false }
            @{ Name = 'Password'; Source = 'Supply'; Prompt = 'Service account password'; Purpose = 'Password for the read-only bind account'; Secret = $true; When = $runRequired; Required = $runRequired }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs   = @(
            @{ Name = 'DcFqdn'; Source = 'Supply'; Prompt = 'Domain controller FQDN'; Purpose = 'DC to probe'; Required = $true }
            @{ Name = 'Domain'; Source = 'Supply'; Prompt = 'AD DNS domain'; Purpose = 'Domain name'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe    = { param($ctx, $whatIf) Test-ActiveDirectoryEntroCheck -Context $ctx -WhatIf:$whatIf }
        Steps         = {
            param($ctx)
            $sam = if ($ctx['SamAccountName']) { [string]$ctx['SamAccountName'] } else { 'svc_entro' }
            @(
                @{
                    Id     = 'entro-ad-network'
                    Title  = 'Confirm Outpost reachability to the domain controller'
                    Kind   = 'Manual'
                    Why    = 'Entro queries AD from the Outpost, over LDAP, LDAPS, and the Global Catalog.'
                    Manual = "From the Outpost host, resolve $($ctx['DcFqdn']) and open TCP 389, 636, 3268, and 3269. DNS uses UDP 53."
                }
                @{
                    Id    = 'entro-ad-account'
                    Title = "Create read-only account $sam"
                    Kind  = 'Ensure'
                    Why   = 'Entro binds as a normal user. Do not grant admin roles.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $account = if ($c['SamAccountName']) { [string]$c['SamAccountName'] } else { 'svc_entro' }
                        $domain = [string]$c['Domain']
                        $upn = "$account@$domain"
                        Import-Module ActiveDirectory -ErrorAction Stop
                        $existing = Get-ADUser -Filter "SamAccountName -eq '$account'" -ErrorAction SilentlyContinue
                        if ($existing) {
                            Write-Ok "$account already exists ($($existing.DistinguishedName)). It was not modified and was not added to any admin group."
                        }
                        else {
                            $secure = ConvertTo-SecureString ([string]$c['Password']) -AsPlainText -Force
                            New-ADUser -Name $account -SamAccountName $account -UserPrincipalName $upn -AccountPassword $secure -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true
                            Write-Ok "Created $upn. No admin group membership was added."
                        }
                        $c['ServiceUpn'] = $upn
                    }
                    BuildScript = {
                        param($c)
                        @'
if ([string]::IsNullOrWhiteSpace($Password)) { $Password = Read-Host 'Service account password' }
$account = if ($SamAccountName) { $SamAccountName } else { 'svc_entro' }
$upn = "$account@$Domain"
Import-Module ActiveDirectory -ErrorAction Stop
$existing = Get-ADUser -Filter "SamAccountName -eq '$account'" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "$account already exists. It was not modified and was not added to any admin group."
} else {
    $secure = ConvertTo-SecureString $Password -AsPlainText -Force
    New-ADUser -Name $account -SamAccountName $account -UserPrincipalName $upn -AccountPassword $secure -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true
    Write-Host "Created $upn. No admin group membership was added."
}
'@
                    }
                }
                @{
                    Id    = 'entro-ad-ca'
                    Title = 'Export the LDAPS root CA as PEM'
                    Kind  = 'Ensure'
                    Why   = 'Entro wants the root CA text, including the BEGIN and END lines, not a file upload.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $pem = Export-EntroLdapsRootCaPem -Fqdn ([string]$c['DcFqdn']) -Port 636
                        $dir = if ($c['OutputDirectory']) { [string]$c['OutputDirectory'] } else { (Get-Location).Path }
                        $path = Join-Path $dir 'root-ca.pem'
                        Set-Content -LiteralPath $path -Value $pem -Encoding ascii
                        $c['RootCaPath'] = $path
                        Write-Ok "Wrote the LDAPS root CA to $path. Paste the whole PEM into Entro."
                    }
                    BuildScript = {
                        param($c)
                        @'
$tcp = [System.Net.Sockets.TcpClient]::new()
try {
    $tcp.Connect($DcFqdn, 636)
    $ssl = [System.Net.Security.SslStream]::new($tcp.GetStream(), $false, { param($sender, $certificate, $chain, $errors) $true })
    $ssl.AuthenticateAsClient($DcFqdn)
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)
    $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
    [void]$chain.Build($cert)
    $root = $chain.ChainElements[$chain.ChainElements.Count - 1].Certificate
    $b64 = [Convert]::ToBase64String($root.RawData, [Base64FormattingOptions]::InsertLineBreaks)
    $pem = "-----BEGIN CERTIFICATE-----`n$b64`n-----END CERTIFICATE-----"
} finally { $tcp.Dispose() }
$outDir = if ($OutputDirectory) { $OutputDirectory } else { (Get-Location).Path }
$caPath = Join-Path $outDir 'root-ca.pem'
Set-Content -LiteralPath $caPath -Value $pem -Encoding ascii
Write-Host "Wrote the LDAPS root CA to $caPath. Paste the whole PEM into Entro."
'@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $sam = if ($ctx['SamAccountName']) { $ctx['SamAccountName'] } else { 'svc_entro' }
            $upn = if ($ctx['ServiceUpn']) { $ctx['ServiceUpn'] } else { "$sam@$($ctx['Domain'])" }
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            $ca = if ($ctx['RootCaPath']) { $ctx['RootCaPath'] } else { 'root-ca.pem' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host '  Target host: domain-joined Windows host'
            Write-Host "  Nickname: $($ctx['Nickname'])"
            Write-Host "  Domain Controller: $($ctx['DomainController'])"
            Write-Host "  DC FQDN: $($ctx['DcFqdn'])"
            Write-Host "  Domain: $($ctx['Domain'])"
            Write-Host "  Username: $upn"
            Write-Host "  Root CA PEM: $ca"
            Write-Host "  Environment: $($ctx['EnvironmentNickname']) ($($ctx['EnvironmentType']))"
            Write-Host "  Worker Group: $wg"
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-ActiveDirectoryEntroDefinitions, Get-EntroAdLdapsPorts, Export-EntroLdapsRootCaPem
