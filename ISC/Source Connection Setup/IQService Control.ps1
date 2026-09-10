#Requires -Version 5.1
<#
.SYNOPSIS
    Downloads, installs, updates, and manages SailPoint IQService on a Windows host.

.DESCRIPTION
    Operator script for IQService hosts that need the Integration Service for Active Directory,
    Azure AD, Windows Local, SharePoint, or Domino connectors.

    Supports downloading IQService from a pasted ISC pre-signed ZIP URL, extracting and
    unblocking binaries (including Utils.dll),     registering or upgrading the Windows service,
    start/stop/restart, log-level configuration, colored log streaming, and status reporting.

    Pre-signed download URLs expire (typically within an hour). Obtain a fresh link from
    Connections > Sources > [source requiring IQService] > IQService / Integration Service > Download.

.PARAMETER Action
    Download, Install, Update, Uninstall, Start, Stop, Restart, SetLogLevel, StreamLogs, Status, or Unblock.
    When omitted, an interactive menu is shown.

.PARAMETER InstallPath
    IQService installation directory. Default: C:\SailPoint\IQService, or the path discovered
    from an existing Windows service.

.PARAMETER DownloadUri
    Pre-signed ISC VA-image URL for IQService.zip. Never commit or share these URLs; they expire.

.PARAMETER ZipPath
    Local path to an IQService.zip file instead of downloading.

.PARAMETER Port
    Non-TLS port passed to IQService.exe -p during install or update.

.PARAMETER TlsPort
    TLS port passed to IQService.exe -o during install or update.

.PARAMETER SkipSecondary
    Pass -b to IQService.exe -i to skip installing the secondary fallback instance.

.PARAMETER LogLevel
    Off, Error, Info, or Debug (maps to IQService trace levels 0-3).

.PARAMETER TraceFile
    Trace log file path for -l / -f and StreamLogs. Default: registry tracefile, else {InstallPath}\iqtrace.log

.PARAMETER Tail
    Number of existing log lines to print before following. StreamLogs only. Default: 50.

.PARAMETER StartAfterInstall
    Start the service after install or update.

.PARAMETER NonInteractive
    Do not prompt; required parameters must be supplied.

.EXAMPLE
    .\IQService Control.ps1

.EXAMPLE
    .\IQService Control.ps1 -Action Status

.EXAMPLE
    .\IQService Control.ps1 -Action Download -DownloadUri 'https://va-access.infra.identitynow.com/...'

.EXAMPLE
    .\IQService Control.ps1 -Action Update -ZipPath 'D:\Downloads\IQService-914.zip' -StartAfterInstall

.EXAMPLE
    .\IQService Control.ps1 -Action StreamLogs -Tail 100

.NOTES
    Install, update, uninstall, and service control require an elevated PowerShell session.
    Reference: https://documentation.sailpoint.com/connectors/iqservice/help/integrating_iqservice_admin/
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('Download', 'Install', 'Update', 'Uninstall', 'Start', 'Stop', 'Restart', 'SetLogLevel', 'StreamLogs', 'Status', 'Unblock')]
    [string]$Action,

    [Parameter()]
    [string]$InstallPath,

    [Parameter()]
    [string]$DownloadUri,

    [Parameter()]
    [string]$ZipPath,

    [Parameter()]
    [int]$Port,

    [Parameter()]
    [int]$TlsPort,

    [Parameter()]
    [switch]$SkipSecondary,

    [Parameter()]
    [ValidateSet('Off', 'Error', 'Info', 'Debug')]
    [string]$LogLevel,

    [Parameter()]
    [string]$TraceFile,

    [Parameter()]
    [ValidateRange(0, 100000)]
    [int]$Tail = 50,

    [Parameter()]
    [switch]$StartAfterInstall,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.IQService.psm1') -Force
Initialize-OperatorConsole -NonInteractive:$NonInteractive
Initialize-IQServiceData -NonInteractive:$NonInteractive

# -----------------------------------------------------------------------------
# Platform and console helpers
# -----------------------------------------------------------------------------


function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  IQService Control' -ForegroundColor Cyan
    Write-Host '  Download, install, update, and manage IQService on this host.' -ForegroundColor DarkCyan
    Write-Host ''
}

# Main
# -----------------------------------------------------------------------------

try {
    Assert-WindowsHost
    Write-Banner

    $resolvedPath = Resolve-IQServiceInstallPath -PreferredPath $InstallPath
    if (-not $Action) {
        Show-InteractiveMenu -ResolvedInstallPath $resolvedPath -TraceFile $TraceFile -TailLines $Tail
        return
    }

    switch ($Action) {
        'Status' {
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Status'
        }
        'Download' {
            if ([string]::IsNullOrWhiteSpace($DownloadUri) -and [string]::IsNullOrWhiteSpace($ZipPath)) {
                throw 'Download requires -DownloadUri or -ZipPath in non-interactive mode.'
            }
            Save-IQServiceZip -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Download'
        }
        'Install' {
            if (-not [string]::IsNullOrWhiteSpace($DownloadUri) -or -not [string]::IsNullOrWhiteSpace($ZipPath)) {
                Save-IQServiceZip -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath | Out-Null
            }
            Install-IQServiceInstance -InstallPath $resolvedPath -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary -StartAfterInstall:$StartAfterInstall
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Install'
        }
        'Update' {
            Update-IQServiceInstance -InstallPath $resolvedPath -DownloadUri $DownloadUri -ZipPath $ZipPath -Port:$Port -TlsPort:$TlsPort -SkipSecondary:$SkipSecondary -StartAfterInstall:$StartAfterInstall
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Update' -ServiceStoppedAfterUpdate:(-not $StartAfterInstall)
        }
        'Uninstall' {
            Invoke-IQServiceServiceAction -ServiceAction Uninstall -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Uninstall'
        }
        'Start' {
            Invoke-IQServiceServiceAction -ServiceAction Start -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Start'
        }
        'Stop' {
            Invoke-IQServiceServiceAction -ServiceAction Stop -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Stop'
        }
        'Restart' {
            Invoke-IQServiceServiceAction -ServiceAction Restart -InstallPath $resolvedPath
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Restart'
        }
        'SetLogLevel' {
            if (-not $LogLevel) {
                throw 'SetLogLevel requires -LogLevel (Off, Error, Info, or Debug) in non-interactive mode.'
            }
            $logResult = Set-IQServiceTraceLevel -InstallPath $resolvedPath -Level $LogLevel -TraceFile $TraceFile -RestartIfRunning
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'SetLogLevel' `
                -RestartPendingForLogLevel:([bool]$logResult.RestartPending)
        }
        'StreamLogs' {
            Show-IQServiceLogStream -InstallPath $resolvedPath -TraceFile $TraceFile -TailLines $Tail
        }
        'Unblock' {
            Write-Step 'Unblocking IQService files'
            $result = Unblock-IQServiceFiles -InstallPath $resolvedPath
            Write-Ok "Unblocked $($result.Unblocked) of $($result.Checked) file(s)"
            $remaining = [Math]::Max(0, $result.Checked - $result.Unblocked)
            Show-IQServiceCompletion -InstallPath $resolvedPath -CompletedAction 'Unblock' -BlockedFilesRemaining $remaining
        }
    }
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    Write-Error $_
    exit 1
}
