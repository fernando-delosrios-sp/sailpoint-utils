Set-StrictMode -Version Latest

$script:ProbeModule = Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.OnPremProbe.psm1'
Import-Module $script:ProbeModule -Force -WarningAction SilentlyContinue

function ConvertTo-EntroShareUrl {
    param([Parameter(Mandatory)][string]$HostOrUrl, [int]$Port = 445)
    $text = $HostOrUrl.Trim()
    if ($text -match '^[a-z][a-z0-9+\.-]*://') { $text = ([Uri]$text).Host }
    if ($text -match ':\d+$') { return $text }
    "$text`:$Port"
}

function New-EntroSmbSharesJson {
    param(
        [Parameter(Mandatory)][string]$Nickname,
        [Parameter(Mandatory)][string]$User,
        [string]$Password,
        [Parameter(Mandatory)][string]$Url,
        [string[]]$IgnoreShares
    )
    $row = [ordered]@{
        nickname      = $Nickname
        user          = $User
        password      = $Password
        url           = ConvertTo-EntroShareUrl -HostOrUrl $Url -Port 445
        ignore_shares = @($IgnoreShares | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    ConvertTo-Json -InputObject @($row) -Depth 4
}

function Test-RemoteFileTcpCheck {
    param($Context, [string]$HostKey, [int[]]$Ports, [string]$Label)
    $missing = [System.Collections.Generic.List[string]]::new()
    $met = [System.Collections.Generic.List[string]]::new()
    $manual = [System.Collections.Generic.List[string]]::new()
    $hostName = [string]$Context[$HostKey]
    if ([string]::IsNullOrWhiteSpace($hostName)) { $missing.Add($HostKey) }
    else {
        $bare = $hostName
        if ($bare -match ':\d+$') { $bare = $bare -replace ':\d+$', '' }
        foreach ($port in $Ports) {
            $name = "$Label $($bare):$port"
            if (Test-OnPremTcpPort -HostName $bare -Port $port) { $met.Add($name) } else { $missing.Add($name) }
        }
    }
    $verdict = if ($missing.Count -gt 0) { 'Fail' } elseif ($manual.Count -gt 0) { 'Review' } else { 'Pass' }
    @{
        Subject       = @{ Kind = 'RemoteFile'; Label = $Label; Name = $hostName; Note = 'Read-only port probe. Nothing was changed.'; Readable = $true; ReadableFamilies = @() }
        Verdict       = $verdict
        AttemptedRead = $true
        Found         = $true
        Required      = @($Ports | ForEach-Object { "$Label port $_" })
        Met           = @($met)
        Missing       = @($missing)
        Manual        = @($manual)
        PurposeMap    = @{ "$Label port $($Ports[0])" = 'The Outpost host can open this port' }
        ReadNote      = "Checked $hostName from $([Environment]::MachineName)."
    }
}

function Register-RemoteFileSystemEntroDefinitions {
    $runRequired = { param($c) [string]$c['Action'] -eq 'Run' }
    $windowsAssert = {
        param($c)
        if (-not [System.OperatingSystem]::IsWindows()) {
            throw 'Run this on the Windows host that will be changed, or use BuildScript and copy the .ps1 there.'
        }
    }
    $windowsAssertScript = @'
if (-not [System.OperatingSystem]::IsWindows()) { throw 'Run this script on the Windows host that will be changed.' }
'@

    Register-IntegrationWizardDefinition @{
        Id            = 'remote-file-smb-entro'
        Platform      = 'RemoteFileSystem'
        Product       = 'Entro'
        CoreSwitch    = 'Smb'
        CliName       = 'pwsh'
        Title         = 'Entro remote file system (SMB)'
        FolderName    = 'Entro-Remote-File-SMB'
        RequiredTools = @('Windows file server or domain-joined admin host')
        AccessLevels  = @()
        AdminRoles    = @('File-server administrator or AD account operator')
        OutputsHelp   = 'Upload smb-file-shares.json in Entro (File Shares Scanning -> JSON Upload) or paste Nickname, Username, Password, and host:445. Select the Outpost Worker Group.'
        TargetHost    = @{
            Role         = 'Windows file server or domain-joined admin host'
            Notes        = 'The Outpost must reach the file server on TCP 445. The JSON file contains the password; do not commit it.'
            Assert       = $windowsAssert
            AssertScript = $windowsAssertScript
        }
        Inputs        = @(
            @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Label for this file server'; Required = $true }
            @{ Name = 'AccountScope'; Source = 'Supply'; Prompt = 'Account scope'; Purpose = 'Domain account or local account on the file server'; ValidateSet = @('Domain', 'Local'); Default = 'Domain'; Required = $false }
            @{ Name = 'Username'; Source = 'Supply'; Prompt = 'Service account (DOMAIN\user or local user)'; Purpose = 'Read-only account Entro will use'; Required = $true }
            @{ Name = 'ShareHost'; Source = 'Supply'; Prompt = 'File server host'; Purpose = 'Host or host:445'; Required = $true }
            @{ Name = 'ShareNames'; Source = 'Supply'; Prompt = 'Share names to grant read (comma-separated)'; Purpose = 'Existing SMB share names on this server'; Required = $false }
            @{ Name = 'IgnoreShares'; Source = 'Supply'; Prompt = 'Share names to exclude (comma-separated)'; Purpose = 'ignore_shares in the Entro JSON'; Required = $false }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that can reach port 445'; Required = $false }
            @{ Name = 'Password'; Source = 'Supply'; Prompt = 'Service account password'; Purpose = 'Password stored only in the JSON file'; Secret = $true; When = $runRequired; Required = $runRequired }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs   = @(
            @{ Name = 'ShareHost'; Source = 'Supply'; Prompt = 'File server host'; Purpose = 'Host to probe on 445'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe    = { param($ctx, $whatIf) Test-RemoteFileTcpCheck -Context $ctx -HostKey 'ShareHost' -Ports @(445) -Label 'SMB' }
        Steps         = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-smb-account'
                    Title = 'Create a read-only SMB account and grant share read'
                    Kind  = 'Ensure'
                    Why   = 'Entro only needs read access to the shares it scans.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $user = [string]$c['Username']
                        $scope = if ($c['AccountScope']) { [string]$c['AccountScope'] } else { 'Domain' }
                        $leaf = ($user -split '\\')[-1]
                        if ($scope -eq 'Domain') {
                            if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) { throw 'Domain account creation needs the ActiveDirectory module on this host.' }
                            Import-Module ActiveDirectory -ErrorAction Stop
                            $domain = (Get-ADDomain).DNSRoot
                            $existing = Get-ADUser -Filter "SamAccountName -eq '$leaf'" -ErrorAction SilentlyContinue
                            if (-not $existing) {
                                $secure = ConvertTo-SecureString ([string]$c['Password']) -AsPlainText -Force
                                New-ADUser -Name $leaf -SamAccountName $leaf -UserPrincipalName "$leaf@$domain" -AccountPassword $secure -Enabled $true -PasswordNeverExpires $true
                                Write-Ok "Created domain user $leaf. No admin group was added."
                            }
                            else { Write-Ok "Domain user $leaf already exists." }
                        }
                        else {
                            $secure = ConvertTo-SecureString ([string]$c['Password']) -AsPlainText -Force
                            if (-not (Get-LocalUser -Name $leaf -ErrorAction SilentlyContinue)) {
                                New-LocalUser -Name $leaf -Password $secure -PasswordNeverExpires
                                Write-Ok "Created local user $leaf."
                            }
                            else { Write-Ok "Local user $leaf already exists." }
                        }
                        foreach ($share in @(([string]$c['ShareNames']) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
                            Grant-SmbShareAccess -Name $share -AccountName $user -AccessRight Read -Force | Out-Null
                            Write-Ok "Granted Read on share $share to $user."
                        }
                    }
                    BuildScript = {
                        param($c)
                        @'
if ([string]::IsNullOrWhiteSpace($Password)) { $Password = Read-Host 'Service account password' }
$leaf = ($Username -split '\\')[-1]
$secure = ConvertTo-SecureString $Password -AsPlainText -Force
if ($AccountScope -eq 'Local') {
    if (-not (Get-LocalUser -Name $leaf -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $leaf -Password $secure -PasswordNeverExpires
    }
} else {
    Import-Module ActiveDirectory -ErrorAction Stop
    $domain = (Get-ADDomain).DNSRoot
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$leaf'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name $leaf -SamAccountName $leaf -UserPrincipalName "$leaf@$domain" -AccountPassword $secure -Enabled $true -PasswordNeverExpires $true
    }
}
foreach ($share in @($ShareNames -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    Grant-SmbShareAccess -Name $share -AccountName $Username -AccessRight Read -Force | Out-Null
    Write-Host "Granted Read on $share to $Username."
}
Write-Host 'SMB account is ready. It was not added to an admin group.'
'@
                    }
                }
                @{
                    Id    = 'entro-smb-json'
                    Title = 'Write smb-file-shares.json for Entro upload'
                    Kind  = 'Ensure'
                    Why   = 'Entro accepts one JSON array for bulk file-share onboarding.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        $ignore = @(([string]$c['IgnoreShares']) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                        $json = New-EntroSmbSharesJson -Nickname ([string]$c['Nickname']) -User ([string]$c['Username']) -Password ([string]$c['Password']) -Url ([string]$c['ShareHost']) -IgnoreShares $ignore
                        $dir = if ($c['OutputDirectory']) { [string]$c['OutputDirectory'] } else { (Get-Location).Path }
                        $path = Join-Path $dir 'smb-file-shares.json'
                        Write-OnPremSecretFile -Path $path -Value $json
                        $c['SmbJsonPath'] = $path
                        Write-Ok "Wrote $path. Upload it in Entro. Do not commit it."
                    }
                    BuildScript = {
                        param($c)
                        @'
if ([string]::IsNullOrWhiteSpace($Password)) { $Password = Read-Host 'Service account password' }
$url = $ShareHost.Trim()
if ($url -notmatch ':\d+$') { $url = "${url}:445" }
$ignore = @($IgnoreShares -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$doc = @([ordered]@{ nickname = $Nickname; user = $Username; password = $Password; url = $url; ignore_shares = @($ignore) })
$json = ConvertTo-Json -InputObject @($doc) -Depth 4
$outDir = if ($OutputDirectory) { $OutputDirectory } else { (Get-Location).Path }
$jsonPath = Join-Path $outDir 'smb-file-shares.json'
Set-Content -LiteralPath $jsonPath -Value $json -Encoding utf8
Write-Host "Wrote $jsonPath. Upload it in Entro. Do not commit it."
'@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            $jsonPath = if ($ctx['SmbJsonPath']) { $ctx['SmbJsonPath'] } else { 'smb-file-shares.json' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host '  Target host: Windows file server or domain admin host'
            Write-Host "  JSON: $jsonPath"
            Write-Host "  URL: $(ConvertTo-EntroShareUrl -HostOrUrl ([string]$ctx['ShareHost']))"
            Write-Host "  Worker Group: $wg"
            Write-Host ''
        }
    }

    Register-IntegrationWizardDefinition @{
        Id            = 'remote-file-sftp-entro'
        Platform      = 'RemoteFileSystem'
        Product       = 'Entro'
        CoreSwitch    = 'Sftp'
        CliName       = 'pwsh'
        Title         = 'Entro remote file system (SFTP)'
        FolderName    = 'Entro-Remote-File-SFTP'
        RequiredTools = @('ssh-keygen (when generating a key)')
        AccessLevels  = @()
        AdminRoles    = @('Administrator of the SFTP server (to install the public key)')
        OutputsHelp   = 'Paste Nickname, Host, Username, and the private key into Entro File Shares Scanning. Install the public key for that user on the server. Select the Outpost Worker Group.'
        TargetHost    = @{
            Role  = 'Operator host that can reach the SFTP server, plus the SFTP server itself for the account'
            Notes = 'This host generates the key and checks TCP 22. Create the OS user on the SFTP server with the printed commands. The Outpost must reach port 22.'
            Assert = {
                param($c)
                if ((-not $c['PublicKeyPath']) -and -not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
                    throw 'ssh-keygen was not found. Install it, or pass PublicKeyPath for a key you already created.'
                }
                $rawHost = [string]$c['FileHost']
                $port = 22
                if ($rawHost -match ':(\d+)$') { $port = [int]$Matches[1] }
                $ep = Get-OnPremEndpoint -Address $rawHost -DefaultPort $port
                if (-not (Test-OnPremTcpPort -HostName $ep.Host -Port $port)) {
                    throw "Cannot reach SFTP at $($ep.Host):$port."
                }
            }
            AssertScript = @'
if (-not $PublicKeyPath -and -not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) { throw 'Install ssh-keygen or set PublicKeyPath.' }
$sftpRaw = [string]$FileHost
$sftpPort = 22
if ($sftpRaw -match ':(\d+)$') { $sftpPort = [int]$Matches[1]; $sftpRaw = $sftpRaw -replace ':\d+$', '' }
$sftpName = ($sftpRaw -replace '^[a-z][a-z0-9+\.-]*://', '').Trim()
if ([string]::IsNullOrWhiteSpace($sftpName)) { throw 'FileHost is required.' }
$sftpClient = [System.Net.Sockets.TcpClient]::new()
try {
    $sftpWait = $sftpClient.BeginConnect($sftpName, $sftpPort, $null, $null)
    if (-not $sftpWait.AsyncWaitHandle.WaitOne(4000, $false)) { throw "Cannot reach SFTP at ${sftpName}:$sftpPort." }
    $sftpClient.EndConnect($sftpWait)
}
finally { $sftpClient.Dispose() }
'@
        }
        Inputs        = @(
            @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Label for this SFTP server'; Required = $true }
            @{ Name = 'FileHost'; Source = 'Supply'; Prompt = 'SFTP host'; Purpose = 'DNS or IP, optional :port'; Required = $true }
            @{ Name = 'Username'; Source = 'Supply'; Prompt = 'SFTP username'; Purpose = 'Read-only SFTP user'; Required = $true; Default = 'entro_sftp' }
            @{ Name = 'TargetDirectories'; Source = 'Supply'; Prompt = 'Target directories (comma-separated, optional)'; Purpose = 'Absolute paths Entro should scan'; Required = $false }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that can reach SSH'; Required = $false }
            @{ Name = 'PublicKeyPath'; Source = 'Supply'; Prompt = 'Existing public key path (leave empty to generate)'; Purpose = 'Skip ssh-keygen when you already have a key'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs   = @(
            @{ Name = 'FileHost'; Source = 'Supply'; Prompt = 'SFTP host'; Purpose = 'Host to probe on port 22'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe    = { param($ctx, $whatIf) Test-RemoteFileTcpCheck -Context $ctx -HostKey 'FileHost' -Ports @(22) -Label 'SFTP' }
        Steps         = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-sftp-key'
                    Title = 'Generate an SFTP key and the server user commands'
                    Kind  = 'Ensure'
                    Why   = 'Entro authenticates with the private key. The server only needs the public key and read access.'
                    Probe = { param($c) if ($c['PublicKeyPath']) { 'Update' } else { 'Create' } }
                    Run   = {
                        param($c)
                        $dir = if ($c['OutputDirectory']) { [string]$c['OutputDirectory'] } else { (Get-Location).Path }
                        if ($c['PublicKeyPath']) {
                            $pub = [string]$c['PublicKeyPath']
                            if (-not (Test-Path -LiteralPath $pub)) { throw "Public key not found: $pub" }
                        }
                        else {
                            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                            $priv = Join-Path $dir 'entro_sftp'
                            & ssh-keygen -t ed25519 -f $priv -N '' -C 'entro-sftp' -q
                            if ($LASTEXITCODE -ne 0) { throw 'ssh-keygen failed.' }
                            $pub = "$priv.pub"
                            $c['PrivateKeyPath'] = $priv
                        }
                        $pubText = (Get-Content -LiteralPath $pub -Raw).Trim()
                        $user = if ($c['Username']) { [string]$c['Username'] } else { 'entro_sftp' }
                        $commands = @"
# Run on the SFTP server as root. This user is not an administrator.
id -u $user >/dev/null 2>&1 || useradd --create-home --shell /usr/sbin/nologin $user
install -d -m 700 -o $user -g $user /home/$user/.ssh
printf '%s\n' '$pubText' >> /home/$user/.ssh/authorized_keys
chown ${user}:${user} /home/${user}/.ssh/authorized_keys
chmod 600 /home/$user/.ssh/authorized_keys
"@
                        $cmdPath = Join-Path $dir 'entro-sftp-user.sh'
                        Set-Content -LiteralPath $cmdPath -Value $commands -Encoding utf8
                        $c['SftpCommandPath'] = $cmdPath
                        $c['PublicKeyPath'] = $pub
                        Write-Ok "Public key: $pub"
                        Write-Ok "Server commands: $cmdPath"
                    }
                    BuildScript = {
                        param($c)
                        @'
$dir = if ($OutputDirectory) { $OutputDirectory } else { (Get-Location).Path }
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
if ($PublicKeyPath) {
    if (-not (Test-Path -LiteralPath $PublicKeyPath)) { throw "Public key not found: $PublicKeyPath" }
    $pub = $PublicKeyPath
} else {
    $priv = Join-Path $dir 'entro_sftp'
    & ssh-keygen -t ed25519 -f $priv -N '' -C 'entro-sftp' -q
    if ($LASTEXITCODE -ne 0) { throw 'ssh-keygen failed.' }
    $pub = "$priv.pub"
    Write-Host "Private key: $priv"
}
$pubText = (Get-Content -LiteralPath $pub -Raw).Trim()
$user = if ($Username) { $Username } else { 'entro_sftp' }
@"
# Run on the SFTP server as root.
id -u $user >/dev/null 2>&1 || useradd --create-home --shell /usr/sbin/nologin $user
install -d -m 700 -o $user -g $user /home/$user/.ssh
printf '%s\n' '$pubText' >> /home/$user/.ssh/authorized_keys
chown ${user}:${user} /home/${user}/.ssh/authorized_keys
chmod 600 /home/$user/.ssh/authorized_keys
"@ | Set-Content -LiteralPath (Join-Path $dir 'entro-sftp-user.sh') -Encoding utf8
Write-Host "Wrote $(Join-Path $dir 'entro-sftp-user.sh')"
'@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Nickname: $($ctx['Nickname'])"
            Write-Host "  Host: $($ctx['FileHost'])"
            Write-Host "  Username: $($ctx['Username'])"
            Write-Host "  Private key: $(if ($ctx['PrivateKeyPath']) { $ctx['PrivateKeyPath'] } else { '(use the key that matches the public key)' })"
            Write-Host "  Server script: $(if ($ctx['SftpCommandPath']) { $ctx['SftpCommandPath'] } else { 'entro-sftp-user.sh' })"
            if ($ctx['TargetDirectories']) { Write-Host "  Target directories: $($ctx['TargetDirectories'])" }
            Write-Host "  Worker Group: $wg"
            Write-Host ''
        }
    }

    Register-IntegrationWizardDefinition @{
        Id            = 'remote-file-winrm-entro'
        Platform      = 'RemoteFileSystem'
        Product       = 'Entro'
        CoreSwitch    = 'WinRm'
        CliName       = 'pwsh'
        Title         = 'Entro remote file system (WinRM)'
        FolderName    = 'Entro-Remote-File-WinRM'
        RequiredTools = @('Windows host with permission to enable PSRemoting')
        AccessLevels  = @()
        AdminRoles    = @('Local administrator on the Windows host Entro will scan')
        OutputsHelp   = 'Paste Nickname, Host, Username, and Password into Entro File Shares Scanning. Select the Outpost Worker Group. The account is in Remote Management Users only.'
        TargetHost    = @{
            Role         = 'Windows host that Entro will scan over WinRM'
            Notes        = 'Run on that host. The Outpost must reach TCP 5985 or 5986.'
            Assert       = $windowsAssert
            AssertScript = $windowsAssertScript
        }
        Inputs        = @(
            @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Label for this Windows host'; Required = $true }
            @{ Name = 'FileHost'; Source = 'Supply'; Prompt = 'Windows host'; Purpose = 'DNS or IP Entro will connect to'; Required = $true }
            @{ Name = 'Username'; Source = 'Supply'; Prompt = 'WinRM username'; Purpose = 'Local read-only WinRM user'; Default = 'entro_winrm'; Required = $false }
            @{ Name = 'TargetDirectories'; Source = 'Supply'; Prompt = 'Directories to grant read (comma-separated)'; Purpose = 'Optional NTFS read grant'; Required = $false }
            @{ Name = 'WorkerGroup'; Source = 'Supply'; Prompt = 'Entro Outpost Worker Group'; Purpose = 'Worker Group that can reach WinRM'; Required = $false }
            @{ Name = 'Password'; Source = 'Supply'; Prompt = 'WinRM user password'; Purpose = 'Password for the local user'; Secret = $true; When = $runRequired; Required = $runRequired }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs   = @(
            @{ Name = 'FileHost'; Source = 'Supply'; Prompt = 'Windows host'; Purpose = 'Host to probe on 5985 and 5986'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckProbe    = { param($ctx, $whatIf) Test-RemoteFileTcpCheck -Context $ctx -HostKey 'FileHost' -Ports @(5985, 5986) -Label 'WinRM' }
        Steps         = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-winrm-enable'
                    Title = 'Enable WinRM and create a Remote Management user'
                    Kind  = 'Ensure'
                    Why   = 'Entro reads files over WinRM. The account does not need to be an administrator.'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
                        $user = if ($c['Username']) { [string]$c['Username'] } else { 'entro_winrm' }
                        $leaf = ($user -split '\\')[-1]
                        $secure = ConvertTo-SecureString ([string]$c['Password']) -AsPlainText -Force
                        if (-not (Get-LocalUser -Name $leaf -ErrorAction SilentlyContinue)) {
                            New-LocalUser -Name $leaf -Password $secure -PasswordNeverExpires
                            Write-Ok "Created local user $leaf."
                        }
                        else { Write-Ok "Local user $leaf already exists." }
                        Add-LocalGroupMember -Group 'Remote Management Users' -Member $leaf -ErrorAction SilentlyContinue
                        foreach ($dirPath in @(([string]$c['TargetDirectories']) -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
                            & icacls $dirPath /grant "${leaf}:(OI)(CI)R" /T | Out-Null
                            Write-Ok "Granted read on $dirPath."
                        }
                        Write-Ok 'WinRM is enabled for Remote Management Users.'
                    }
                    BuildScript = {
                        param($c)
                        @'
if ([string]::IsNullOrWhiteSpace($Password)) { $Password = Read-Host 'WinRM user password' }
Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
$leaf = if ($Username) { ($Username -split '\\')[-1] } else { 'entro_winrm' }
$secure = ConvertTo-SecureString $Password -AsPlainText -Force
if (-not (Get-LocalUser -Name $leaf -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $leaf -Password $secure -PasswordNeverExpires
}
Add-LocalGroupMember -Group 'Remote Management Users' -Member $leaf -ErrorAction SilentlyContinue
foreach ($dirPath in @($TargetDirectories -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    & icacls $dirPath /grant "${leaf}:(OI)(CI)R" /T | Out-Null
}
Write-Host "WinRM user $leaf is in Remote Management Users."
'@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $wg = if ($ctx['WorkerGroup']) { $ctx['WorkerGroup'] } else { '(select the Outpost Worker Group)' }
            $user = if ($ctx['Username']) { $ctx['Username'] } else { 'entro_winrm' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host '  Target host: the Windows host Entro will scan'
            Write-Host "  Nickname: $($ctx['Nickname'])"
            Write-Host "  Host: $($ctx['FileHost'])"
            Write-Host "  Username: $user"
            Write-Host "  Worker Group: $wg"
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-RemoteFileSystemEntroDefinitions, New-EntroSmbSharesJson, ConvertTo-EntroShareUrl
