#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-IQServiceData {
    param([switch]$NonInteractive)

    $script:DefaultInstallPath = 'C:\SailPoint\IQService'
    $script:LogLevelMap = [ordered]@{
        Off   = 0
        Error = 1
        Info  = 2
        Debug = 3
    }
    $script:NonInteractive = [bool]$NonInteractive
}

function Test-IQServiceNonInteractive {
    return [bool]$script:NonInteractive
}

function Assert-WindowsHost {
    if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
        throw 'IQService Control must run on Windows.'
    }
    if ($env:OS -notlike 'Windows*') {
        throw 'IQService Control must run on Windows.'
    }
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Elevated {
    param([string]$Operation)

    if (-not (Test-IsElevated)) {
        throw "Administrator privileges are required for: $Operation. Re-run PowerShell as Administrator."
    }
}
function Build-IQServiceResult {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$CompletedAction,
        [switch]$ServiceStoppedAfterUpdate,
        [switch]$RestartPendingForLogLevel,
        [int]$BlockedFilesRemaining = -1
    )

    $exePath = Join-Path -Path $InstallPath -ChildPath 'IQService.exe'
    $hasExe = Test-Path -LiteralPath $exePath
    $snapshot = Get-IQServiceConfigurationSnapshot -InstallPath $InstallPath -ExecutablePath:$(if ($hasExe) { $exePath } else { $null })
    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    $build = Get-IQServiceBuildFromPath -Path $zipPath
    $utilsDll = Join-Path -Path $InstallPath -ChildPath 'Utils.dll'
    $utilsBlocked = $false
    if (Test-Path -LiteralPath $utilsDll) {
        $utilsBlocked = Test-FileBlocked -Path $utilsDll
    }
    if ($BlockedFilesRemaining -lt 0) {
        $blockedCount = 0
        if ($utilsBlocked) { $blockedCount++ }
        $BlockedFilesRemaining = $blockedCount
    }

    $primaryService = $snapshot.Services | Select-Object -First 1
    $primaryRegistry = $snapshot.Registry | Select-Object -First 1
    $hostName = $env:COMPUTERNAME
    try {
        $fqdn = [System.Net.Dns]::GetHostEntry('localhost').HostName
        if ($fqdn) { $hostName = $fqdn }
    }
    catch { }

    $port = if ($primaryRegistry -and $primaryRegistry.Port) { [string]$primaryRegistry.Port } else { '' }
    $tlsPort = if ($primaryRegistry -and $primaryRegistry.TlsPort) { [string]$primaryRegistry.TlsPort } else { '' }
    $traceFile = if ($primaryRegistry -and $primaryRegistry.TraceFile) { [string]$primaryRegistry.TraceFile } else { (Join-Path $InstallPath 'iqtrace.log') }
    $serviceStatus = if ($primaryService) { $primaryService.Status } else { 'Not registered' }

    $situation = [System.Collections.Generic.List[string]]::new()
    switch ($CompletedAction) {
        'Download' {
            $situation.Add('IQService.zip is on this host. Next: run Install or Update (Unblock first if Utils.dll is blocked).')
        }
        'Install' {
            $situation.Add('IQService is registered on this host. Confirm TLS certificates and client authentication if required, verify the Windows Log On account, then paste host and ports into ISC.')
        }
        'Update' {
            $situation.Add('IQService was updated on this host. Confirm the Log On account in Services after uninstall/reinstall cleared registry entries.')
            if ($ServiceStoppedAfterUpdate) {
                $situation.Add('Pending: start IQService before testing the ISC source connection.')
            }
        }
        'Start' {
            $situation.Add("IQService service status: $serviceStatus. Paste host and ports into the ISC source IQService panel when the service is running.")
        }
        'Stop' {
            $situation.Add("IQService is stopped ($serviceStatus). Start it again before ISC provisioning or aggregation tests.")
        }
        'Restart' {
            $situation.Add("IQService was restarted. Current status: $serviceStatus.")
        }
        'SetLogLevel' {
            $situation.Add('Trace level was updated on this host.')
            if ($RestartPendingForLogLevel) {
                $situation.Add('Pending: restart IQService for the new trace level to take effect.')
            }
        }
        'Unblock' {
            $situation.Add('File unblock completed.')
            if ($utilsBlocked -or $BlockedFilesRemaining -gt 0) {
                $situation.Add('Pending: some binaries may still be blocked. Re-run Unblock or unblock IQService.zip before extracting.')
            }
        }
        'Uninstall' {
            $situation.Add('IQService registration was removed. Reinstall from the menu or -Action Install when you are ready.')
            $situation.Add('Pending: if the Log On account changed during uninstall, set it again in Services (services.msc).')
        }
        default {
            $situation.Add("IQService on this host — status: $serviceStatus.")
        }
    }

    if ($utilsBlocked) {
        $situation.Add('Pending: Utils.dll is blocked. Run Unblock before install or service start.')
    }
    if (-not $hasExe) {
        $situation.Add('Pending: IQService.exe is missing. Download and install before configuring ISC.')
    }
    elseif ($serviceStatus -ne 'Running' -and $CompletedAction -notin @('Stop', 'Uninstall', 'Download')) {
        $situation.Add('Pending: IQService is not running. Start the service before testing from ISC.')
    }
    $situation.Add('In ISC: Connections > Sources > [source requiring IQService] > IQService / Integration Service.')

    $items = [System.Collections.Generic.List[object]]::new()
    $items.Add([PSCustomObject]@{ Label = 'Host name'; Value = $hostName; Kind = 'Copy'; Mask = $false })
    if ($port) { $items.Add([PSCustomObject]@{ Label = 'Port (non-TLS)'; Value = $port; Kind = 'Copy'; Mask = $false }) }
    if ($tlsPort) { $items.Add([PSCustomObject]@{ Label = 'TLS port'; Value = $tlsPort; Kind = 'Copy'; Mask = $false }) }
    $items.Add([PSCustomObject]@{ Label = 'Install path'; Value = $InstallPath; Kind = 'Copy'; Mask = $false })
    if ($hasExe) {
        $items.Add([PSCustomObject]@{ Label = 'IQService.exe path'; Value = $exePath; Kind = 'Copy'; Mask = $false })
    }
    if ($snapshot.Version -and $snapshot.Version -ne 'Not installed') {
        $items.Add([PSCustomObject]@{ Label = 'Version'; Value = $snapshot.Version; Kind = 'Copy'; Mask = $false })
    }
    if ($build) {
        $items.Add([PSCustomObject]@{ Label = 'ZIP build'; Value = $build; Kind = 'Copy'; Mask = $false })
    }
    if ($primaryService) {
        $items.Add([PSCustomObject]@{ Label = 'Windows service name'; Value = $primaryService.Name; Kind = 'Copy'; Mask = $false })
        if ($primaryService.StartName) {
            $items.Add([PSCustomObject]@{ Label = 'Log On account'; Value = $primaryService.StartName; Kind = 'Copy'; Mask = $false })
        }
    }
    if ($traceFile) {
        $items.Add([PSCustomObject]@{ Label = 'Trace log file'; Value = $traceFile; Kind = 'Copy'; Mask = $false })
    }
    if (Test-Path -LiteralPath $zipPath) {
        $items.Add([PSCustomObject]@{ Label = 'IQService.zip path'; Value = $zipPath; Kind = 'Copy'; Mask = $false })
    }

    $items.Add([PSCustomObject]@{
        Label = 'IQService install documentation'
        Value = 'https://documentation.sailpoint.com/connectors/iqservice/help/integrating_iqservice_admin/install_register.html'
        Kind  = 'Open'
        Mask  = $false
    })
    $items.Add([PSCustomObject]@{ Label = 'Windows Services (services.msc)'; Value = 'services.msc'; Kind = 'Open'; Mask = $false })

    $connectionSettings = [ordered]@{
        'Host name' = $hostName
    }
    if ($port) { $connectionSettings['Port (non-TLS)'] = $port }
    if ($tlsPort) { $connectionSettings['TLS port'] = $tlsPort }
    $connectionSettings['Install path'] = $InstallPath

    return [ordered]@{
        status             = 'ok'
        connectionSettings = $connectionSettings
        artifacts          = @()
        secretArtifacts    = @()
        manualSteps        = @($situation)
        verification       = [ordered]@{ serviceStatus = $serviceStatus; version = $snapshot.Version }
        situation          = @($situation)
        completionItems    = $items.ToArray()
    }
}

function Show-IQServiceCompletion {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$CompletedAction,
        [switch]$ServiceStoppedAfterUpdate,
        [switch]$RestartPendingForLogLevel,
        [int]$BlockedFilesRemaining = -1
    )

    $result = Build-IQServiceResult -InstallPath $InstallPath -CompletedAction $CompletedAction `
        -ServiceStoppedAfterUpdate:$ServiceStoppedAfterUpdate `
        -RestartPendingForLogLevel:$RestartPendingForLogLevel `
        -BlockedFilesRemaining $BlockedFilesRemaining

    Invoke-CompletionActionMenu -Title 'Next: configure ISC IQService connection' `
        -Situation $result.situation `
        -Items $result.completionItems
}

function Test-LooksLikeIQServiceDirectory {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    foreach ($marker in @('IQService.exe', 'Utils.dll')) {
        if (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $marker)) {
            return $true
        }
    }

    return $false
}

function Get-IQServiceWindowsServices {
    $services = @()
    try {
        $serviceKeys = Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop |
            Where-Object { $_.PSChildName -like '*IQService*' }

        foreach ($serviceKey in $serviceKeys) {
            $name = $serviceKey.PSChildName
            $imagePath = [string](Get-ItemProperty -Path $serviceKey.PSPath -Name ImagePath -ErrorAction SilentlyContinue).ImagePath
            if ([string]::IsNullOrWhiteSpace($imagePath)) {
                continue
            }

            if ($imagePath -match '^\s*"([^"]+)"') {
                $exePath = $matches[1]
            }
            elseif ($imagePath -match '^\s*(\S+)') {
                $exePath = $matches[1]
            }
            else {
                continue
            }

            $installDir = Split-Path -Path $exePath -Parent
            $winService = Get-Service -Name $name -ErrorAction SilentlyContinue
            $startName = $null
            try {
                $cim = Get-CimInstance -ClassName Win32_Service -Filter "Name='$name'" -ErrorAction Stop
                $startName = $cim.StartName
            }
            catch {
                # Ignore.
            }

            $services += [PSCustomObject]@{
                Name        = $name
                DisplayName = if ($winService) { $winService.DisplayName } else { $name }
                Status      = if ($winService) { $winService.Status.ToString() } else { 'Unknown' }
                StartType   = if ($winService) { $winService.StartType.ToString() } else { 'Unknown' }
                ImagePath   = $exePath
                InstallPath = $installDir
                StartName   = $startName
            }
        }
    }
    catch {
        Write-Verbose "Could not enumerate IQService Windows services: $($_.Exception.Message)"
    }

    return $services
}

function Resolve-IQServiceInstallPath {
    param([string]$PreferredPath)

    if (-not $script:DefaultInstallPath) {
        Initialize-IQServiceData
    }

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        if (-not (Test-Path -LiteralPath $PreferredPath)) {
            New-Item -ItemType Directory -Path $PreferredPath -Force | Out-Null
        }
        return (Resolve-Path -LiteralPath $PreferredPath).Path
    }

    $services = @(Get-IQServiceWindowsServices)
    foreach ($service in $services) {
        if (Test-LooksLikeIQServiceDirectory -Path $service.InstallPath) {
            return $service.InstallPath
        }
    }

    if (Test-LooksLikeIQServiceDirectory -Path $script:DefaultInstallPath) {
        return (Resolve-Path -LiteralPath $script:DefaultInstallPath).Path
    }

    if (-not (Test-Path -LiteralPath $script:DefaultInstallPath)) {
        New-Item -ItemType Directory -Path $script:DefaultInstallPath -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $script:DefaultInstallPath).Path
}

function Get-IQServiceExecutable {
    param([Parameter(Mandatory)][string]$InstallPath)

    $exePath = Join-Path -Path $InstallPath -ChildPath 'IQService.exe'
    if (-not (Test-Path -LiteralPath $exePath)) {
        throw "IQService.exe was not found in '$InstallPath'. Download and extract IQService first."
    }

    return $exePath
}

function Get-IQServiceRegistryInstances {
    $instances = @()
    $root = 'HKLM:\SOFTWARE\SailPoint\IQService Instances'

    if (-not (Test-Path -LiteralPath $root)) {
        return $instances
    }

    foreach ($key in Get-ChildItem -Path $root -ErrorAction SilentlyContinue) {
        $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
        if (-not $props) { continue }

        $instances += [PSCustomObject]@{
            InstanceName    = $key.PSChildName
            Port            = $props.port
            TlsPort         = $props.tlsPort
            TraceFile       = $props.tracefile
            TraceLevel      = $props.tracelevel
            MaxTraceFiles   = $props.maxTraceFiles
            TraceFileSize   = $props.traceFileSize
            ClientAuthUsers = $props.clientAuthUsers
        }
    }

    return $instances
}

function Get-IQServiceZipPath {
    param([Parameter(Mandatory)][string]$InstallPath)
    return Join-Path -Path $InstallPath -ChildPath 'IQService.zip'
}

function Get-IQServiceBuildFromPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $leaf = Split-Path -Path $Path -Leaf
    if ($leaf -match 'IQService-(\d+)\.zip$') {
        return $matches[1]
    }
    return $null
}

# -----------------------------------------------------------------------------
# IQService command wrapper
# -----------------------------------------------------------------------------

function Invoke-IQServiceCommand {
    param(
        [Parameter(Mandatory)][string]$ExecutablePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowNonZeroExit
    )

    $displayArgs = ($Arguments | ForEach-Object {
        if ($_ -match '\s') { """$_""" } else { $_ }
    }) -join ' '

    Write-Verbose "Running: $ExecutablePath $displayArgs"

    $output = & $ExecutablePath @Arguments 2>&1
    $text = if ($null -eq $output) { '' } else { ($output | Out-String).Trim() }
    $exitCode = $LASTEXITCODE

    if ($text) {
        foreach ($line in ($text -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Info $line
            }
        }
    }

    if (-not $AllowNonZeroExit -and $exitCode -ne 0) {
        throw "IQService.exe exited with code $exitCode. Arguments: $displayArgs"
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = $text
    }
}

function Get-IQServiceVersion {
    param([Parameter(Mandatory)][string]$ExecutablePath)

    $result = Invoke-IQServiceCommand -ExecutablePath $ExecutablePath -Arguments @('-v') -AllowNonZeroExit
    if ($result.Output) {
        return $result.Output.Trim()
    }
    return 'Unknown'
}

# -----------------------------------------------------------------------------
# File unblock helpers
# -----------------------------------------------------------------------------

function Test-FileBlocked {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        $zoneStream = Get-Item -LiteralPath $Path -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue
        return [bool]$zoneStream
    }
    catch {
        return $false
    }
}

function Unblock-IQServiceFiles {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string[]]$AdditionalPaths
    )

    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @($AdditionalPaths)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            $paths.Add($path)
        }
    }

    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    if (Test-Path -LiteralPath $zipPath) {
        $paths.Add($zipPath)
    }

    $utilsDll = Join-Path -Path $InstallPath -ChildPath 'Utils.dll'
    if (Test-Path -LiteralPath $utilsDll) {
        $paths.Add($utilsDll)
    }

    if (Test-Path -LiteralPath $InstallPath) {
        foreach ($file in Get-ChildItem -LiteralPath $InstallPath -Recurse -File -Include '*.dll', '*.exe' -ErrorAction SilentlyContinue) {
            $paths.Add($file.FullName)
        }
    }

    $unique = @($paths | Select-Object -Unique)
    $unblocked = 0
    foreach ($path in $unique) {
        if (Test-FileBlocked -Path $path) {
            Unblock-File -LiteralPath $path
            $unblocked++
        }
    }

    return [PSCustomObject]@{
        Checked   = $unique.Count
        Unblocked = $unblocked
    }
}

# -----------------------------------------------------------------------------
# Download and extract
# -----------------------------------------------------------------------------


function Save-IQServiceZip {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$DownloadUri,
        [string]$ZipPath
    )

    return Save-IQServicePayload -InstallPath $InstallPath -DownloadUri $DownloadUri -ZipPath $ZipPath `
        -GetZipPath { param($p) Get-IQServiceZipPath -InstallPath $p } `
        -GetBuildFromPath { param($p) Get-IQServiceBuildFromPath -Path $p } `
        -UnblockFiles { param($p, $extra) Unblock-IQServiceFiles -InstallPath $p -AdditionalPaths $extra }
}

function Expand-IQServiceZip {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$ZipPath
    )

    Expand-IQServicePayload -InstallPath $InstallPath -ZipPath $ZipPath `
        -GetZipPath { param($p) Get-IQServiceZipPath -InstallPath $p } `
        -UnblockFiles { param($p) Unblock-IQServiceFiles -InstallPath $p }
}

function Get-IQServiceConfigurationSnapshot {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$ExecutablePath
    )

    $services = @(Get-IQServiceWindowsServices | Where-Object { $_.InstallPath -eq $InstallPath })
    $registry = @(Get-IQServiceRegistryInstances)
    $version = 'Not installed'

    if ($ExecutablePath -and (Test-Path -LiteralPath $ExecutablePath)) {
        try {
            $version = Get-IQServiceVersion -ExecutablePath $ExecutablePath
        }
        catch {
            $version = "Unavailable: $($_.Exception.Message)"
        }
    }

    return [PSCustomObject]@{
        Version  = $version
        Services = $services
        Registry = $registry
    }
}

function Build-IQServiceInstallArguments {
    param(
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary
    )

    $installArgs = @('-i')
    if ($PSBoundParameters.ContainsKey('Port') -and $Port -gt 0) {
        $installArgs += @('-p', [string]$Port)
    }
    if ($PSBoundParameters.ContainsKey('TlsPort') -and $TlsPort -gt 0) {
        $installArgs += @('-o', [string]$TlsPort)
    }
    if ($SkipSecondary) {
        $installArgs += '-b'
    }
    return $installArgs
}

function Restore-IQServiceServiceAccount {
    param(
        [Parameter(Mandatory)][array]$Services
    )

    foreach ($service in $Services) {
        if ([string]::IsNullOrWhiteSpace($service.StartName)) {
            continue
        }

        if ($service.StartName -match 'LocalSystem|NT AUTHORITY\\LocalService|NT AUTHORITY\\NetworkService') {
            Write-Info "Service $($service.Name) uses built-in account $($service.StartName); no restore needed."
            continue
        }

        Write-Warning "Service $($service.Name) was configured to run as '$($service.StartName)'. IQService uninstall clears registry but not the service Log On account."
        Write-Warning 'If the account changed, open Services (services.msc), set Log On to the domain service account, and restart IQService.'
    }
}

function Install-IQServiceInstance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary,
        [switch]$StartAfterInstall
    )

    Assert-Elevated -Operation 'install IQService'

    $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    $zipPath = Get-IQServiceZipPath -InstallPath $InstallPath
    if (-not (Test-Path -LiteralPath $exe)) {
        Expand-IQServiceZip -InstallPath $InstallPath -ZipPath $zipPath
        $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    }

    $installArgs = Build-IQServiceInstallArguments -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary
    Write-Step 'Registering IQService Windows service'
    if (-not $PSCmdlet.ShouldProcess($InstallPath, 'Install IQService')) { return }

    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $installArgs
    Write-Ok 'IQService registered'

    if ($StartAfterInstall) {
        Write-Step 'Starting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-s')
        Write-Ok 'IQService started'
    }
}

function Update-IQServiceInstance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$DownloadUri,
        [string]$ZipPath,
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary,
        [switch]$StartAfterInstall
    )

    Assert-Elevated -Operation 'update IQService'

    $exe = $null
    if (Test-Path -LiteralPath (Join-Path $InstallPath 'IQService.exe')) {
        $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    }

    Write-Step 'Capturing current IQService configuration'
    $snapshot = Get-IQServiceConfigurationSnapshot -InstallPath $InstallPath -ExecutablePath $exe
    Write-Info "Current version: $($snapshot.Version)"

    $primaryRegistry = $snapshot.Registry | Select-Object -First 1
    $savedPort = if ($PSBoundParameters.ContainsKey('Port') -and $Port -gt 0) { $Port } elseif ($primaryRegistry.Port) { [int]$primaryRegistry.Port } else { 0 }
    $savedTlsPort = if ($PSBoundParameters.ContainsKey('TlsPort') -and $TlsPort -gt 0) { $TlsPort } elseif ($primaryRegistry.TlsPort) { [int]$primaryRegistry.TlsPort } else { 0 }
    $savedTraceLevel = if ($null -ne $primaryRegistry.TraceLevel) { [int]$primaryRegistry.TraceLevel } else { $null }
    $savedTraceFile = [string]$primaryRegistry.TraceFile
    if ([string]::IsNullOrWhiteSpace($savedTraceFile)) {
        $savedTraceFile = Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
    }

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = "$InstallPath.backup.$timestamp"

    if (Test-Path -LiteralPath $InstallPath) {
        Write-Step "Backing up $InstallPath to $backupPath"
        if (-not $PSCmdlet.ShouldProcess($InstallPath, "Back up to $backupPath")) { return }
        Copy-Item -LiteralPath $InstallPath -Destination $backupPath -Recurse -Force
        Write-Ok "Backup created at $backupPath"
    }

    if ($exe) {
        Write-Step 'Stopping IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-k') -AllowNonZeroExit
        Write-Step 'Uninstalling IQService registration'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-u') -AllowNonZeroExit
    }

    if (-not [string]::IsNullOrWhiteSpace($DownloadUri) -or -not [string]::IsNullOrWhiteSpace($ZipPath)) {
        Save-IQServiceZip -InstallPath $InstallPath -DownloadUri $DownloadUri -ZipPath $ZipPath | Out-Null
    }

    Expand-IQServiceZip -InstallPath $InstallPath
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath

    $installArgs = Build-IQServiceInstallArguments
    if ($savedPort -gt 0) { $installArgs += @('-p', [string]$savedPort) }
    if ($savedTlsPort -gt 0) { $installArgs += @('-o', [string]$savedTlsPort) }
    if ($SkipSecondary) { $installArgs += '-b' }

    Write-Step 'Re-registering IQService'
    if (-not $PSCmdlet.ShouldProcess($InstallPath, 'Reinstall IQService')) { return }
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $installArgs
    Write-Ok 'IQService re-registered'

    if ($null -ne $savedTraceLevel) {
        $logName = ($script:LogLevelMap.GetEnumerator() | Where-Object { $_.Value -eq $savedTraceLevel } | Select-Object -First 1).Name
        if ($logName) {
            Write-Step "Restoring trace level $logName ($savedTraceLevel)"
            Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-l', [string]$savedTraceLevel, '-f', $savedTraceFile)
        }
    }

    Restore-IQServiceServiceAccount -Services $snapshot.Services

    if ($StartAfterInstall) {
        Write-Step 'Starting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-s')
        Write-Ok 'IQService started'
    }
    else {
        Write-Info 'Service was stopped for the update. Start it with -Action Start or IQService.exe -s.'
    }

    Write-Ok "Update complete. Backup retained at $backupPath"
}

function Invoke-IQServiceServiceAction {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][ValidateSet('Start', 'Stop', 'Restart', 'Uninstall')]
        [string]$ServiceAction,
        [Parameter(Mandatory)][string]$InstallPath
    )

    Assert-Elevated -Operation "$($ServiceAction.ToLowerInvariant()) IQService"
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath

    $argMap = @{
        Start     = @('-s')
        Stop      = @('-k')
        Restart   = @('-t')
        Uninstall = @('-u')
    }

    if ($ServiceAction -eq 'Uninstall') {
        if (-not (Test-IQServiceNonInteractive) -and -not (Read-YesNo -Prompt 'Uninstall IQService registration and clear registry entries?' -Default $false)) {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
    }

    if (-not $PSCmdlet.ShouldProcess($InstallPath, "$ServiceAction IQService")) { return }

    Write-Step "$ServiceAction IQService"
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments $argMap[$ServiceAction] -AllowNonZeroExit:($ServiceAction -in @('Stop', 'Uninstall'))
    Write-Ok "$ServiceAction completed"
}

function Set-IQServiceTraceLevel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][ValidateSet('Off', 'Error', 'Info', 'Debug')]
        [string]$Level,
        [string]$TraceFile,
        [switch]$RestartIfRunning
    )

    Assert-Elevated -Operation 'set IQService log level'
    $exe = Get-IQServiceExecutable -InstallPath $InstallPath
    $numeric = $script:LogLevelMap[$Level]

    if ([string]::IsNullOrWhiteSpace($TraceFile)) {
        $TraceFile = Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
    }

    $services = @(Get-IQServiceWindowsServices | Where-Object { $_.InstallPath -eq $InstallPath })
    $wasRunning = @($services | Where-Object { $_.Status -eq 'Running' }).Count -gt 0
    $doRestart = $RestartIfRunning -or ($wasRunning -and -not (Test-IQServiceNonInteractive) -and (Read-YesNo -Prompt 'Restart IQService to apply the new log level?' -Default $true))

    if (-not $PSCmdlet.ShouldProcess($InstallPath, "Set log level to $Level ($numeric)")) {
        return [PSCustomObject]@{ RestartPending = $false }
    }

    Write-Step "Setting trace level to $Level ($numeric)"
    Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-l', [string]$numeric, '-f', $TraceFile)
    Write-Ok "Trace file: $TraceFile"

    if ($doRestart) {
        Write-Step 'Restarting IQService'
        Invoke-IQServiceCommand -ExecutablePath $exe -Arguments @('-t') -AllowNonZeroExit
        Write-Ok 'IQService restarted'
        return [PSCustomObject]@{ RestartPending = $false }
    }
    if ($wasRunning) {
        Write-Info 'Service is running. Restart IQService for the new log level to take effect.'
        return [PSCustomObject]@{ RestartPending = $true }
    }
    return [PSCustomObject]@{ RestartPending = $false }
}

function Show-IQServiceStatus {
    param([Parameter(Mandatory)][string]$InstallPath)

    Show-IQServiceCompletion -InstallPath $InstallPath -CompletedAction 'Status'
}

# -----------------------------------------------------------------------------
# Trace log streaming
# -----------------------------------------------------------------------------

function Resolve-IQServiceTraceFile {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$TraceFile
    )

    if (-not [string]::IsNullOrWhiteSpace($TraceFile)) {
        return $TraceFile
    }

    foreach ($instance in @(Get-IQServiceRegistryInstances)) {
        $candidate = [string]$instance.TraceFile
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    foreach ($name in @('iqtrace.log', 'IQTrace.log')) {
        $candidate = Join-Path -Path $InstallPath -ChildPath $name
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return Join-Path -Path $InstallPath -ChildPath 'iqtrace.log'
}

function Get-IQServiceLogLevelColor {
    param([string]$Level)

    switch -Regex ($Level) {
        '^ERR'          { return [System.ConsoleColor]::Red }
        '^WARN'         { return [System.ConsoleColor]::Yellow }
        '^INFO'         { return [System.ConsoleColor]::Cyan }
        '^DEBUG|^TRACE' { return [System.ConsoleColor]::DarkGray }
        default         { return [System.ConsoleColor]::Gray }
    }
}

function ConvertTo-CompleteLogLines {
    param(
        [string]$Chunk,
        [Parameter(Mandatory)][ref]$Carry
    )

    $text = $Carry.Value + $Chunk
    if ([string]::IsNullOrEmpty($text)) {
        return @()
    }

    $parts = [regex]::Split($text, '\r?\n')
    $endsWithNewline = $text.EndsWith("`n") -or $text.EndsWith("`r")
    if ($endsWithNewline) {
        $Carry.Value = ''
        if ($parts.Count -gt 0 -and $parts[-1] -eq '') {
            if ($parts.Count -eq 1) { return @() }
            return @($parts[0..($parts.Count - 2)])
        }
        return @($parts)
    }

    $Carry.Value = $parts[-1]
    if ($parts.Count -le 1) {
        return @()
    }
    return @($parts[0..($parts.Count - 2)])
}

function Write-IQServiceLogLine {
    param(
        [string]$Line,
        [Parameter(Mandatory)][ref]$LastLevel
    )

    if ($null -eq $Line) { return }

    $header = [regex]::Match(
        $Line,
        '^(?<ts>\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}:\d{2})\s*:\s*(?<comp>\S+)\s*\[\s*(?<thread>[^\]]+)\]\s*(?<level>ERROR|WARN(?:ING)?|INFO|DEBUG|TRACE)\s*:\s*(?<msg>.*)$'
    )

    if ($header.Success) {
        $level = $header.Groups['level'].Value.ToUpperInvariant()
        if ($level -eq 'WARNING') { $level = 'WARN' }
        $LastLevel.Value = $level
        $levelColor = Get-IQServiceLogLevelColor -Level $level
        $messageColor = if ($level -match '^(ERR|WARN)') { $levelColor } else { [System.ConsoleColor]::Gray }

        Write-Host $header.Groups['ts'].Value -ForegroundColor DarkGray -NoNewline
        Write-Host ' : ' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['comp'].Value -ForegroundColor White -NoNewline
        Write-Host ' [' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['thread'].Value.Trim() -ForegroundColor DarkCyan -NoNewline
        Write-Host '] ' -ForegroundColor DarkGray -NoNewline
        Write-Host $level -ForegroundColor $levelColor -NoNewline
        Write-Host ' : ' -ForegroundColor DarkGray -NoNewline
        Write-Host $header.Groups['msg'].Value -ForegroundColor $messageColor
        return
    }

    $color = Get-IQServiceLogLevelColor -Level $LastLevel.Value
    if ($Line -match '\bERROR\b') {
        $color = [System.ConsoleColor]::Red
        $LastLevel.Value = 'ERROR'
    }
    elseif ($Line -match '\bWARN(?:ING)?\b') {
        $color = [System.ConsoleColor]::Yellow
        $LastLevel.Value = 'WARN'
    }
    Write-Host $Line -ForegroundColor $color
}

function Test-LogStreamCancel {
    try {
        if (-not [Console]::KeyAvailable) { return $false }
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::C -and $key.Modifiers -eq [ConsoleModifiers]::Control) { return $true }
        if ($key.Key -eq [ConsoleKey]::Q -or $key.Key -eq [ConsoleKey]::Escape) { return $true }
    }
    catch {
        # Host cannot poll keys (ISE, redirected stdin); Ctrl+C still stops the loop via the runtime.
    }
    return $false
}

function Get-IQServiceLogFileIdentity {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $item = Get-Item -LiteralPath $Path
    return [PSCustomObject]@{
        Length           = $item.Length
        CreationTimeUtc  = $item.CreationTimeUtc
        LastWriteTimeUtc = $item.LastWriteTimeUtc
    }
}

function Read-IQServiceLogDelta {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ref]$Position,
        [Parameter(Mandatory)][ref]$Carry,
        [Parameter(Mandatory)]$Encoding
    )

    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        if ($stream.Length -lt $Position.Value) {
            $Position.Value = [int64]0
            $Carry.Value = ''
        }

        if ($stream.Length -le $Position.Value) {
            return @()
        }

        $null = $stream.Seek($Position.Value, [System.IO.SeekOrigin]::Begin)
        $toRead = [int]($stream.Length - $Position.Value)
        $buffer = New-Object byte[] $toRead
        $read = $stream.Read($buffer, 0, $toRead)
        $Position.Value += $read
        $chunk = $Encoding.GetString($buffer, 0, $read)
        return @(ConvertTo-CompleteLogLines -Chunk $chunk -Carry $Carry)
    }
    finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Show-IQServiceLogStream {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$TraceFile,
        [int]$TailLines = 50
    )

    $path = Resolve-IQServiceTraceFile -InstallPath $InstallPath -TraceFile $TraceFile
    $encoding = [System.Text.Encoding]::Default

    Write-Step "Streaming $path"
    Write-Info 'Ctrl+C, Q, or Esc to stop.'

    $traceLevel = $null
    foreach ($instance in @(Get-IQServiceRegistryInstances)) {
        if ($null -ne $instance.TraceLevel) {
            $traceLevel = [int]$instance.TraceLevel
            break
        }
    }
    if ($traceLevel -eq 0) {
        Write-Host '   Trace level is Off; the file may stay empty until you set Error, Info, or Debug.' -ForegroundColor Yellow
    }

    $treatCtrlC = $null
    try {
        $treatCtrlC = [Console]::TreatControlCAsInput
        [Console]::TreatControlCAsInput = $true
    }
    catch {
        $treatCtrlC = $null
    }

    $lastLevel = 'INFO'
    $position = [int64]0
    $carry = ''
    $identity = $null

    try {
        $waitingNotice = $false
        while (-not (Test-Path -LiteralPath $path)) {
            if (-not $waitingNotice) {
                Write-Host '   Waiting for the log file to appear...' -ForegroundColor Yellow
                $waitingNotice = $true
            }
            if (Test-LogStreamCancel) { return }
            Start-Sleep -Milliseconds 500
        }
        if ($waitingNotice) {
            Write-Ok "Log file appeared: $path"
        }

        $identity = Get-IQServiceLogFileIdentity -Path $path
        $fileLength = $identity.Length
        $bootstrapCarry = ''
        $bootstrapPosition = [int64]0

        if ($TailLines -le 0) {
            $position = $fileLength
            $carry = ''
            Write-Info 'Following new lines only.'
        }
        else {
            $window = [Math]::Max([int64]524288, [int64]$TailLines * 512)
            if ($fileLength -gt $window) {
                $bootstrapPosition = $fileLength - $window
            }
            $existing = @(Read-IQServiceLogDelta -Path $path -Position ([ref]$bootstrapPosition) -Carry ([ref]$bootstrapCarry) -Encoding $encoding)
            if ($fileLength -gt $window -and $existing.Count -gt 0) {
                $existing = @($existing | Select-Object -Skip 1)
            }
            $position = $bootstrapPosition
            $carry = $bootstrapCarry

            if ($existing.Count -gt 0) {
                $start = [Math]::Max(0, $existing.Count - $TailLines)
                for ($i = $start; $i -lt $existing.Count; $i++) {
                    Write-IQServiceLogLine -Line $existing[$i] -LastLevel ([ref]$lastLevel)
                }
            }
            else {
                Write-Info 'Log file is empty; waiting for new lines.'
            }
        }

        while ($true) {
            if (Test-LogStreamCancel) { break }

            if (-not (Test-Path -LiteralPath $path)) {
                $position = [int64]0
                $carry = ''
                $identity = $null
                Start-Sleep -Milliseconds 400
                continue
            }

            $current = Get-IQServiceLogFileIdentity -Path $path
            if (-not $current) {
                $position = [int64]0
                $carry = ''
                $identity = $null
                Start-Sleep -Milliseconds 400
                continue
            }
            if ($identity -and $current.CreationTimeUtc -ne $identity.CreationTimeUtc) {
                $position = [int64]0
                $carry = ''
            }
            $identity = $current

            $lines = @(Read-IQServiceLogDelta -Path $path -Position ([ref]$position) -Carry ([ref]$carry) -Encoding $encoding)
            foreach ($line in $lines) {
                Write-IQServiceLogLine -Line $line -LastLevel ([ref]$lastLevel)
            }

            Start-Sleep -Milliseconds 250
        }
    }
    catch [System.OperationCanceledException] {
        # Ctrl+C when TreatControlCAsInput could not be set.
    }
    finally {
        if ($null -ne $treatCtrlC) {
            try { [Console]::TreatControlCAsInput = $treatCtrlC } catch { }
        }
        Write-Host ''
        Write-Ok 'Stopped streaming.'
    }
}

# -----------------------------------------------------------------------------
# Interactive menu
# -----------------------------------------------------------------------------



function Write-IQServiceMenuHeader {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  IQService Control' -ForegroundColor Cyan
    Write-Host '  Download, install, update, and manage IQService on this host.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Show-InteractiveMenu {
    param(
        [string]$ResolvedInstallPath,
        [string]$TraceFile,
        [int]$TailLines = 50
    )

    while ($true) {
        Write-IQServiceMenuHeader
        Write-Info "Install path: $ResolvedInstallPath"
        Write-Host ''

        try {
            $choice = Read-Choice -Prompt 'Select an action:' -Options @(
                'Status', 'Download', 'Install', 'Update', 'Service', 'SetLogLevel', 'StreamLogs', 'Unblock', 'Exit'
            ) -Labels @(
                'Status'
                'Download ZIP'
                'Install / register'
                'Update (backup, replace, reinstall)'
                'Start / Stop / Restart'
                'Set log level'
                'Stream logs'
                'Unblock Utils.dll and other binaries'
                'Exit'
            ) -Default 'Status'
        }
        catch {
            if (Test-PromptBack $_) { return }
            throw
        }

        try {
            switch ($choice) {
            'Status' {
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Status'
            }
            'Download' {
                $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                    'Paste a pre-signed ISC download URL'
                    'Use a local ZIP file path'
                ) -Default 'Url'
                if ($source -eq 'Url') {
                    $uri = Read-InputString -Prompt 'Download URL' -Required
                    Save-IQServiceZip -InstallPath $ResolvedInstallPath -DownloadUri $uri | Out-Null
                }
                else {
                    $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                    Save-IQServiceZip -InstallPath $ResolvedInstallPath -ZipPath $localZip | Out-Null
                }
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Download'
            }
            'Install' {
                if (-not (Test-Path -LiteralPath (Get-IQServiceZipPath -InstallPath $ResolvedInstallPath))) {
                    $getZip = Read-YesNo -Prompt 'IQService.zip is not in the install path. Download or copy it first?' -Default $true
                    if ($getZip) {
                        $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                            'Paste a pre-signed ISC download URL'
                            'Use a local ZIP file path'
                        ) -Default 'Url'
                        if ($source -eq 'Url') {
                            $uri = Read-InputString -Prompt 'Download URL' -Required
                            Save-IQServiceZip -InstallPath $ResolvedInstallPath -DownloadUri $uri | Out-Null
                        }
                        else {
                            $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                            Save-IQServiceZip -InstallPath $ResolvedInstallPath -ZipPath $localZip | Out-Null
                        }
                    }
                }
                $start = Read-YesNo -Prompt 'Start IQService after install?' -Default $false
                Install-IQServiceInstance -InstallPath $ResolvedInstallPath -StartAfterInstall:$start
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Install'
            }
            'Update' {
                $uri = $null
                $localZip = $null
                if (Read-YesNo -Prompt 'Download or supply a new ZIP for this update?' -Default $true) {
                    $source = Read-Choice -Prompt 'Download from URL or use a local ZIP?' -Options @('Url', 'Local') -Labels @(
                        'Paste a pre-signed ISC download URL'
                        'Use a local ZIP file path'
                    ) -Default 'Url'
                    if ($source -eq 'Url') {
                        $uri = Read-InputString -Prompt 'Download URL' -Required
                    }
                    else {
                        $localZip = Read-InputString -Prompt 'Path to IQService.zip' -Required
                    }
                }
                $start = Read-YesNo -Prompt 'Start IQService after update?' -Default $true
                Update-IQServiceInstance -InstallPath $ResolvedInstallPath -DownloadUri $uri -ZipPath $localZip -StartAfterInstall:$start
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Update' -ServiceStoppedAfterUpdate:(-not $start)
            }
            'Service' {
                $svcAction = Read-Choice -Prompt 'Service action:' -Options @('Start', 'Stop', 'Restart', 'Uninstall') -Default 'Restart'
                Invoke-IQServiceServiceAction -ServiceAction $svcAction -InstallPath $ResolvedInstallPath
                $completionAction = switch ($svcAction) {
                    'Start' { 'Start' }
                    'Stop' { 'Stop' }
                    'Restart' { 'Restart' }
                    'Uninstall' { 'Uninstall' }
                }
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction $completionAction
            }
            'SetLogLevel' {
                $level = Read-Choice -Prompt 'Trace level:' -Options @('Off', 'Error', 'Info', 'Debug') -Default 'Info'
                $logResult = Set-IQServiceTraceLevel -InstallPath $ResolvedInstallPath -Level $level -RestartIfRunning
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'SetLogLevel' `
                    -RestartPendingForLogLevel:([bool]$logResult.RestartPending)
            }
            'StreamLogs' {
                Show-IQServiceLogStream -InstallPath $ResolvedInstallPath -TraceFile $TraceFile -TailLines $TailLines
            }
            'Unblock' {
                Write-Step 'Unblocking IQService files'
                $result = Unblock-IQServiceFiles -InstallPath $ResolvedInstallPath
                Write-Ok "Unblocked $($result.Unblocked) of $($result.Checked) file(s)"
                $remaining = [Math]::Max(0, $result.Checked - $result.Unblocked)
                Show-IQServiceCompletion -InstallPath $ResolvedInstallPath -CompletedAction 'Unblock' -BlockedFilesRemaining $remaining
            }
            'Exit' {
                return
            }
        }
        }
        catch {
            if (Test-PromptBack $_) { continue }
            throw
        }
    }
}


Export-ModuleMember -Function @(
    'Initialize-IQServiceData'
    'Test-IQServiceNonInteractive'
    'Build-IQServiceResult'
    'Assert-WindowsHost'
    'Test-IsElevated'
    'Assert-Elevated'
    'Show-IQServiceCompletion'
    'Test-LooksLikeIQServiceDirectory'
    'Get-IQServiceWindowsServices'
    'Resolve-IQServiceInstallPath'
    'Get-IQServiceExecutable'
    'Get-IQServiceRegistryInstances'
    'Get-IQServiceZipPath'
    'Get-IQServiceBuildFromPath'
    'Invoke-IQServiceCommand'
    'Get-IQServiceVersion'
    'Test-FileBlocked'
    'Unblock-IQServiceFiles'
    'Save-IQServiceZip'
    'Expand-IQServiceZip'
    'Get-IQServiceConfigurationSnapshot'
    'Build-IQServiceInstallArguments'
    'Restore-IQServiceServiceAccount'
    'Install-IQServiceInstance'
    'Update-IQServiceInstance'
    'Invoke-IQServiceServiceAction'
    'Set-IQServiceTraceLevel'
    'Show-IQServiceStatus'
    'Resolve-IQServiceTraceFile'
    'Get-IQServiceLogLevelColor'
    'ConvertTo-CompleteLogLines'
    'Write-IQServiceLogLine'
    'Test-LogStreamCancel'
    'Get-IQServiceLogFileIdentity'
    'Read-IQServiceLogDelta'
    'Show-IQServiceLogStream'
    'Show-InteractiveMenu'
    'Write-IQServiceMenuHeader'
)
