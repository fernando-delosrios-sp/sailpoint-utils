#Requires -Version 5.1
Set-StrictMode -Version Latest

function Import-SourceSetupModule {
    param(
        [Parameter(Mandatory)][string]$ModuleRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FileName
    )

    if (-not (Get-Module -Name $Name)) {
        Import-Module (Join-Path $ModuleRoot $FileName) -Force -Global -WarningAction SilentlyContinue
    }
}

function Import-AgentAdapterModule {
    if (-not (Get-Module -Name 'ISC.AgentAdapter')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.AgentAdapter.psm1') -Force -WarningAction SilentlyContinue
    }
}

function Initialize-IQServiceSourceSetup {
    param(
        [string]$ModuleRoot,
        [switch]$NonInteractive
    )

    if (-not $ModuleRoot) { $ModuleRoot = $PSScriptRoot }
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorConsole' -FileName 'ISC.OperatorConsole.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorToolchain' -FileName 'ISC.OperatorToolchain.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.IQService' -FileName 'ISC.IQService.psm1'
    Initialize-IQServiceData -NonInteractive:$NonInteractive
    Initialize-OperatorConsole -NonInteractive:$NonInteractive
}

function Get-IQServiceAgentCatalog {
    Initialize-IQServiceSourceSetup
    return [ordered]@{
        actions        = @('Status', 'Download', 'Install', 'Update', 'Uninstall', 'Start', 'Stop', 'Restart', 'SetLogLevel', 'Unblock')
        unsupported    = @('StreamLogs')
        requiredConfig = @('action')
        secretFields   = @('downloadUri')
        manualSteps    = @('tlsConfiguration', 'serviceLogOnAccount', 'iscSourcePanel')
    }
}

function Get-IQServiceResolvedConfig {
    param([Parameter(Mandatory)]$Request)

    Import-AgentAdapterModule
    $config = Get-AgentRequestValue -Object $Request -Name 'config' -Default @{}
    $decisions = Get-AgentRequestValue -Object $Request -Name 'decisions' -Default @{}
    $secretRefs = Get-AgentRequestValue -Object $Request -Name 'secretRefs' -Default @{}

    if (-not $script:DefaultInstallPath) {
        Initialize-IQServiceData
    }

    return [PSCustomObject]@{
        Action            = [string](Get-AgentRequestValue -Object $config -Name 'action')
        InstallPath       = if (Get-AgentRequestValue -Object $config -Name 'installPath') { [string](Get-AgentRequestValue -Object $config -Name 'installPath') } else { $script:DefaultInstallPath }
        DownloadUriRef    = $(if (Get-AgentRequestValue -Object $secretRefs -Name 'downloadUri') { [string](Get-AgentRequestValue -Object $secretRefs -Name 'downloadUri') } else { $null })
        ZipPath           = $(if (Get-AgentRequestValue -Object $config -Name 'zipPath') { [string](Get-AgentRequestValue -Object $config -Name 'zipPath') } else { $null })
        Port              = Get-AgentRequestValue -Object $config -Name 'port'
        TlsPort           = Get-AgentRequestValue -Object $config -Name 'tlsPort'
        SkipSecondary     = [bool](Get-AgentRequestValue -Object $config -Name 'skipSecondary' -Default $false)
        LogLevel          = $(if (Get-AgentRequestValue -Object $config -Name 'logLevel') { [string](Get-AgentRequestValue -Object $config -Name 'logLevel') } else { $null })
        TraceFile         = $(if (Get-AgentRequestValue -Object $config -Name 'traceFile') { [string](Get-AgentRequestValue -Object $config -Name 'traceFile') } else { $null })
        StartAfterInstall = [bool](Get-AgentRequestValue -Object $config -Name 'startAfterInstall' -Default $false)
        ApproveDestructive = [bool](Get-AgentRequestValue -Object $decisions -Name 'approveDestructive' -Default $false)
    }
}

function New-IQServiceAgentPlan {
    param([Parameter(Mandatory)]$Request)

    Initialize-IQServiceSourceSetup
    Assert-WindowsHost
    $resolved = Get-IQServiceResolvedConfig -Request $Request
    $needsInput = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($resolved.Action)) {
        $needsInput.Add([ordered]@{ field = 'action'; reason = 'IQService action is required.' })
    }
    if ($resolved.Action -eq 'StreamLogs') {
        $needsInput.Add([ordered]@{ field = 'action'; reason = 'StreamLogs is not supported by the agent adapter.' })
    }
    if ($resolved.Action -in @('Download', 'Install', 'Update') -and -not $resolved.DownloadUriRef -and -not $resolved.ZipPath) {
        $needsInput.Add([ordered]@{ field = 'secretRefs.downloadUri or zipPath'; reason = 'Download/Install/Update requires a signed URL reference or local zip path.' })
    }
    if ($resolved.Action -eq 'SetLogLevel' -and -not $resolved.LogLevel) {
        $needsInput.Add([ordered]@{ field = 'logLevel'; reason = 'SetLogLevel requires logLevel.' })
    }
    if ($resolved.Action -in @('Uninstall', 'Update') -and -not $resolved.ApproveDestructive) {
        $needsInput.Add([ordered]@{ field = 'decisions.approveDestructive'; reason = 'Destructive IQService action requires explicit approval.' })
    }

    $installPath = Resolve-IQServiceInstallPath -PreferredPath $resolved.InstallPath
    $snapshot = Get-IQServiceConfigurationSnapshot -InstallPath $installPath

    return [ordered]@{
        status      = if ($needsInput.Count -gt 0) { 'needsInput' } else { 'ready' }
        requestHash = (Get-AgentRequestHash -Request $Request)
        resolved    = $resolved
        discoveries = [ordered]@{ installPath = $installPath; snapshot = $snapshot }
        mutations   = @($resolved.Action)
        prerequisites = @('Windows host', 'Administrator elevation for service mutations')
        warnings    = @($warnings)
        manualSteps = @('Configure TLS certificates and service Log On account in services.msc.', 'Register IQService in ISC source panel.')
        needsInput  = @($needsInput)
    }
}

function Build-IQServiceAgentResult {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$CompletedAction,
        [object]$Extra = $null
    )

    $result = Build-IQServiceResult -InstallPath $InstallPath -CompletedAction $CompletedAction
    if ($Extra) {
        $result.verification = $Extra
    }
    return $result
}

function Invoke-IQServiceAgentApply {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Plan,
        [switch]$WhatIf
    )

    Initialize-IQServiceSourceSetup
    Assert-WindowsHost
    $resolved = Get-IQServiceResolvedConfig -Request $Request
    if ($Plan.resolved) {
        foreach ($prop in $Plan.resolved.PSObject.Properties) {
            $resolved.$($prop.Name) = $prop.Value
        }
    }

    $installPath = Resolve-IQServiceInstallPath -PreferredPath $resolved.InstallPath
    if ($WhatIf) {
        return [ordered]@{ status = 'whatIf'; action = $resolved.Action; installPath = $installPath }
    }

    $downloadUri = $null
    if ($resolved.DownloadUriRef) {
        $downloadUri = Resolve-AgentSecretReference -Reference $resolved.DownloadUriRef
    }

    switch ($resolved.Action) {
        'Status' {
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Status'
        }
        'Download' {
            Save-IQServiceZip -InstallPath $installPath -DownloadUri $downloadUri -ZipPath $resolved.ZipPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Download'
        }
        'Install' {
            if ($downloadUri -or $resolved.ZipPath) {
                Save-IQServiceZip -InstallPath $installPath -DownloadUri $downloadUri -ZipPath $resolved.ZipPath | Out-Null
            }
            Install-IQServiceInstance -InstallPath $installPath -Port:$resolved.Port -TlsPort:$resolved.TlsPort `
                -SkipSecondary:$resolved.SkipSecondary -StartAfterInstall:$resolved.StartAfterInstall
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Install'
        }
        'Update' {
            Update-IQServiceInstance -InstallPath $installPath -DownloadUri $downloadUri -ZipPath $resolved.ZipPath `
                -Port:$resolved.Port -TlsPort:$resolved.TlsPort -SkipSecondary:$resolved.SkipSecondary `
                -StartAfterInstall:$resolved.StartAfterInstall
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Update' `
                -Extra ([ordered]@{ serviceStoppedAfterUpdate = -not $resolved.StartAfterInstall })
        }
        'Uninstall' {
            Invoke-IQServiceServiceAction -ServiceAction Uninstall -InstallPath $installPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Uninstall'
        }
        'Start' {
            Invoke-IQServiceServiceAction -ServiceAction Start -InstallPath $installPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Start'
        }
        'Stop' {
            Invoke-IQServiceServiceAction -ServiceAction Stop -InstallPath $installPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Stop'
        }
        'Restart' {
            Invoke-IQServiceServiceAction -ServiceAction Restart -InstallPath $installPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Restart'
        }
        'SetLogLevel' {
            $logResult = Set-IQServiceTraceLevel -InstallPath $installPath -Level $resolved.LogLevel `
                -TraceFile $resolved.TraceFile -RestartIfRunning
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'SetLogLevel' `
                -Extra ([ordered]@{ restartPending = [bool]$logResult.RestartPending })
        }
        'Unblock' {
            $unblock = Unblock-IQServiceFiles -InstallPath $installPath
            return Build-IQServiceAgentResult -InstallPath $installPath -CompletedAction 'Unblock' `
                -Extra ([ordered]@{ unblocked = $unblock.Unblocked; checked = $unblock.Checked })
        }
        default {
            throw "Unsupported IQService action '$($resolved.Action)'."
        }
    }
}

Export-ModuleMember -Function @(
    'Initialize-IQServiceSourceSetup'
    'Get-IQServiceAgentCatalog'
    'Get-IQServiceResolvedConfig'
    'New-IQServiceAgentPlan'
    'Build-IQServiceAgentResult'
    'Invoke-IQServiceAgentApply'
)
