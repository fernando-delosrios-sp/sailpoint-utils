#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$connectRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $connectRoot 'SailPoint.Connect.psd1') -Force

try {
    # 1) Get-SailPointConnectUpdate when skip env var is set
    $env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK = '1'
    $skipCheck = Get-SailPointConnectUpdate
    Assert-True $skipCheck.Skipped 'Get-SailPointConnectUpdate respects SAILPOINT_CONNECT_SKIP_UPDATE_CHECK'
    Assert-True (-not $skipCheck.UpdateAvailable) 'UpdateAvailable is false when skipped'
    Remove-Item env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -ErrorAction SilentlyContinue

    # 2) Get-SailPointConnectUpdate with mock higher version
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '9.9.9'
    $mockCheck = Get-SailPointConnectUpdate
    Assert-True $mockCheck.UpdateAvailable 'Get-SailPointConnectUpdate detects higher mock version'
    Assert-Equal '9.9.9' $mockCheck.LatestVersion.ToString() 'LatestVersion matches mock version'
    Assert-Equal '1.7.2' $mockCheck.CurrentVersion.ToString() 'CurrentVersion matches active version'

    # 3) Get-SailPointConnectUpdate with mock lower version
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '1.0.0'
    $lowerCheck = Get-SailPointConnectUpdate
    Assert-True (-not $lowerCheck.UpdateAvailable) 'UpdateAvailable is false when mock version is lower'
    Remove-Item env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION -ErrorAction SilentlyContinue

    # 4) Update-SailPointConnect -CheckOnly
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '2.0.0'
    $checkOnlyResult = Update-SailPointConnect -CheckOnly
    Assert-True $checkOnlyResult.UpdateAvailable 'Update-SailPointConnect -CheckOnly reports available update'

    # 5) Update-SailPointConnect -WhatIf (ShouldProcess)
    $whatIfResult = Update-SailPointConnect -WhatIf
    Assert-True (-not $whatIfResult.Updated) 'Update-SailPointConnect with WhatIf does not apply update'

    # 6) Update-SailPointConnect with mock success action
    $env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION = 'Success'
    $updateSuccess = Update-SailPointConnect
    Assert-True $updateSuccess.Success 'Update-SailPointConnect succeeds with mock update'
    Assert-True $updateSuccess.Updated 'Update-SailPointConnect reports Updated = true'

    # 7) Update-SailPointConnect when already up to date and no force
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '1.7.2'
    $upToDate = Update-SailPointConnect
    Assert-True $upToDate.Success 'Update-SailPointConnect succeeds when already up to date'
    Assert-True (-not $upToDate.Updated) 'Update-SailPointConnect does not reinstall when already up to date'

    # 8) Update-SailPointConnect with mock failure action
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '2.5.0'
    $env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION = 'Fail'
    $failed = $false
    try {
        Update-SailPointConnect
    }
    catch {
        $failed = $true
    }
    Assert-True $failed 'Update-SailPointConnect raises terminating exception on install failure'
    Remove-Item env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION -ErrorAction SilentlyContinue

    # 9) Invoke-SailPointConnect -CheckUpdate in non-interactive mode
    $env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION = '3.0.0'
    $invCheck = Invoke-SailPointConnect -CheckUpdate -NonInteractive
    Assert-True ($null -ne $invCheck) 'Invoke-SailPointConnect -CheckUpdate returns result'
    Assert-True $invCheck.UpdateAvailable 'Invoke-SailPointConnect -CheckUpdate identifies update'

    # 10) Invoke-SailPointConnect -Update in non-interactive mode
    $env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION = 'Success'
    $invUpdate = Invoke-SailPointConnect -Update -NonInteractive
    Assert-True $invUpdate.Success 'Invoke-SailPointConnect -Update succeeds'
    Assert-True $invUpdate.Updated 'Invoke-SailPointConnect -Update reports updated'

    # 11) Invoke-SailPointConnect -Platform Update in non-interactive mode
    $invPlatformUpdate = Invoke-SailPointConnect -Platform Update -NonInteractive
    Assert-True $invPlatformUpdate.Success 'Invoke-SailPointConnect -Platform Update succeeds'

    # 12) Confirm-SailPointConnectUpdate in non-interactive mode is silent and returns false
    Initialize-OperatorConsole -NonInteractive
    $confirmNonInt = Confirm-SailPointConnectUpdate -Wizard -Force
    Assert-True (-not $confirmNonInt) 'Confirm-SailPointConnectUpdate is non-blocking and false in non-interactive mode'

    # 13) Invoke-SailPointConnect parameter check
    $cmd = Get-Command Invoke-SailPointConnect
    Assert-True ($cmd.Parameters.ContainsKey('Update')) 'Invoke-SailPointConnect has -Update switch'
    Assert-True ($cmd.Parameters.ContainsKey('CheckUpdate')) 'Invoke-SailPointConnect has -CheckUpdate switch'
    Assert-True ($cmd.Parameters.ContainsKey('SkipUpdateCheck')) 'Invoke-SailPointConnect has -SkipUpdateCheck switch'
    $platformAttr = $cmd.Parameters['Platform'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
    Assert-True ($platformAttr.ValidValues -contains 'Update') 'Invoke-SailPointConnect -Platform includes Update in ValidateSet'

    # 14) Aliases exist and resolve
    $aliasCmd = Get-Command 'update-sailpoint-connect'
    Assert-Equal 'Update-SailPointConnect' $aliasCmd.Definition 'update-sailpoint-connect alias maps to Update-SailPointConnect'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION -ErrorAction SilentlyContinue
    Remove-Item env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"
