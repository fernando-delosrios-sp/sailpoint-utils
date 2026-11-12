#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:PackageManagerAdapter = $null

function Set-OperatorToolchainPackageManager {
    param(
        [Parameter(Mandatory)][scriptblock]$InstallPackage,
        [Parameter(Mandatory)][scriptblock]$TestPackageManager
    )

    $script:PackageManagerAdapter = @{
        InstallPackage       = $InstallPackage
        TestPackageManager   = $TestPackageManager
    }
}

function Get-OperatorPlatform {
    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -eq 'Unix') {
        if ($IsMacOS) { return 'macOS' }
        return 'Linux'
    }
    return 'Windows'
}

function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Test-HomebrewAvailable {
    return [bool](Get-Command brew -ErrorAction SilentlyContinue)
}

function Invoke-PlatformPackageInstall {
    param(
        [Parameter(Mandatory)][string]$PackageId,
        [string]$BrewPackage,
        [string]$ManualHint
    )

    if ($script:PackageManagerAdapter) {
        & $script:PackageManagerAdapter.InstallPackage $PackageId $BrewPackage
        return
    }

    $platform = Get-OperatorPlatform
    if ($platform -eq 'Windows') {
        if (-not (Test-WingetAvailable)) {
            throw 'winget is not available. Install App Installer from the Microsoft Store or use Windows 10 1809+.'
        }
        Write-Info "Installing $PackageId via winget ..."
        & winget install --id $PackageId --exact --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0) {
            throw "winget install $PackageId failed with exit code $LASTEXITCODE."
        }
        return
    }

    if (Test-HomebrewAvailable) {
        $brewName = if ($BrewPackage) { $BrewPackage } else { $PackageId }
        Write-Info "Installing $brewName via Homebrew ..."
        & brew install $brewName
        if ($LASTEXITCODE -ne 0) {
            throw "brew install $brewName failed with exit code $LASTEXITCODE."
        }
        return
    }

    if ($ManualHint) {
        throw $ManualHint
    }
    throw "No package manager is available on $platform. Install $PackageId manually."
}

function Resolve-CliCommand {
    param(
        [Parameter(Mandatory)][string[]]$CommandNames
    )

    foreach ($name in $CommandNames) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Ensure-CliCommand {
    param(
        [Parameter(Mandatory)][string[]]$CommandNames,
        [string]$WingetPackageId,
        [string]$BrewPackage,
        [string]$ManualHint,
        [switch]$SkipInstall
    )

    $path = Resolve-CliCommand -CommandNames $CommandNames
    if ($path) { return $path }

    if ($SkipInstall) {
        if ($ManualHint) { throw $ManualHint }
        throw "Required command not found on PATH: $($CommandNames -join ', ')"
    }

    if (-not (Read-YesNo -Prompt "Install $($CommandNames[0]) using the platform package manager?" -Default $true)) {
        if ($ManualHint) { throw $ManualHint }
        throw "Required command not found: $($CommandNames -join ', ')"
    }

    Invoke-PlatformPackageInstall -PackageId $WingetPackageId -BrewPackage $BrewPackage -ManualHint $ManualHint
    $path = Resolve-CliCommand -CommandNames $CommandNames
    if (-not $path) {
        throw "Installed $($CommandNames[0]) but it is still not on PATH. Restart the terminal and re-run."
    }
    return $path
}

function Ensure-GCloudCommand {
    return Ensure-CliCommand -CommandNames @('gcloud', 'gcloud.cmd') `
        -WingetPackageId 'Google.CloudSDK' `
        -BrewPackage 'gcloud-cli' `
        -ManualHint 'Install the Google Cloud SDK from https://cloud.google.com/sdk/docs/install and run gcloud init.'
}

function Ensure-AzCliCommand {
    return Ensure-CliCommand -CommandNames @('az', 'az.cmd') `
        -WingetPackageId 'Microsoft.AzureCLI' `
        -BrewPackage 'azure-cli' `
        -ManualHint 'Install the Azure CLI from https://learn.microsoft.com/cli/azure/install-azure-cli and run az login.'
}

function Ensure-OpenSslCommand {
    param([string]$OpenSslPath)

    if ($OpenSslPath) {
        if (-not (Test-Path -LiteralPath $OpenSslPath)) {
            throw "openssl was not found at $OpenSslPath"
        }
        return $OpenSslPath
    }

    $existing = Resolve-CliCommand -CommandNames @('openssl')
    if ($existing) { return $existing }

    $platform = Get-OperatorPlatform
    if ($platform -eq 'macOS' -and (Test-Path -LiteralPath '/usr/bin/openssl')) {
        return '/usr/bin/openssl'
    }

    return Ensure-CliCommand -CommandNames @('openssl') `
        -WingetPackageId 'ShiningLight.OpenSSL.Light' `
        -BrewPackage 'openssl@3' `
        -ManualHint 'Install OpenSSL (Git for Windows includes it) or pass -OpenSslPath. SailPoint requires a traditional encrypted RSA PEM.'
}

function Install-PowerShellGalleryModuleSet {
    param(
        [Parameter(Mandatory)][string[]]$ModuleNames,
        [string]$PromptTitle = 'PowerShell Gallery modules are required'
    )

    $missing = @($ModuleNames | Where-Object { -not (Get-Module -ListAvailable -Name $_) })
    if ($missing.Count -eq 0) { return }

    Write-Step $PromptTitle
    foreach ($name in $missing) { Write-Info $name }
    if (-not (Read-YesNo -Prompt 'Install the missing modules for the current user?' -Default $true)) {
        throw "Install the modules manually: Install-Module $($missing -join ', ') -Scope CurrentUser"
    }
    foreach ($name in $missing) {
        Write-Info "Installing $name ..."
        Install-Module -Name $name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
}

function Import-PowerShellGalleryModuleSet {
    param([Parameter(Mandatory)][string[]]$ModuleNames)

    foreach ($name in $ModuleNames) {
        Import-Module $name -ErrorAction Stop
    }
}

function Ensure-MicrosoftGraphModules {
    $required = @(
        'Microsoft.Graph.Authentication'
        'Microsoft.Graph.Applications'
        'Microsoft.Graph.Identity.DirectoryManagement'
    )
    Install-PowerShellGalleryModuleSet -ModuleNames $required -PromptTitle 'Microsoft Graph PowerShell modules are required'
    Import-PowerShellGalleryModuleSet -ModuleNames $required
}

function Get-AwsToolsModuleNames {
    param([string[]]$ExtraModules = @())

    $names = @(
        'AWS.Tools.Common'
        'AWS.Tools.SecurityToken'
        'AWS.Tools.IdentityManagement'
        'AWS.Tools.Organizations'
    ) + @($ExtraModules)
    return @($names | Select-Object -Unique)
}

function Resolve-AwsToolsTargetVersion {
    param(
        [Version]$SessionVersion,
        [Version[]]$InstalledVersions
    )

    if ($SessionVersion) { return [Version]$SessionVersion }
    $sorted = @($InstalledVersions | Where-Object { $null -ne $_ } | Sort-Object -Descending)
    if ($sorted.Count -eq 0) { return $null }
    return $sorted[0]
}

function Get-AwsToolsMissingModuleNames {
    param(
        [Parameter(Mandatory)][string[]]$RequiredNames,
        [Version]$TargetVersion,
        [hashtable]$InstalledByName
    )

    $missing = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $RequiredNames) {
        $versions = @()
        if ($InstalledByName -and $InstalledByName.ContainsKey($name)) {
            $versions = @($InstalledByName[$name])
        }
        $hasTarget = if ($TargetVersion) {
            @($versions | Where-Object { $_ -eq $TargetVersion }).Count -gt 0
        }
        else {
            $versions.Count -gt 0
        }
        if (-not $hasTarget) { $missing.Add($name) }
    }
    return [string[]]@($missing)
}

function Test-AwsToolsNeedsVersionSync {
    param(
        [Version]$SessionVersion,
        [string[]]$InstalledVersionLabels
    )

    if ($SessionVersion) { return $false }
    $unique = @($InstalledVersionLabels | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    return $unique.Count -gt 1
}

function Resolve-AwsToolsModuleImportPath {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][Version]$TargetVersion,
        [Parameter(Mandatory)][object[]]$Available
    )

    $match = @(
        $Available |
            Where-Object { $_.Name -eq $Name -and $_.Version -eq $TargetVersion -and $_.Path } |
            Select-Object -First 1
    )
    if ($match.Count -eq 0) { return $null }
    return [string]$match[0].Path
}

function Test-AwsToolsImportNeedsNewSession {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }
    return $Message -match 'already loaded|AWSSDK\.Core|Assembly with same name'
}

function Get-AwsToolsSessionVersion {
    $common = Get-Module -Name 'AWS.Tools.Common'
    if ($common) { return $common.Version }
    $any = Get-Module | Where-Object { $_.Name -like 'AWS.Tools.*' } | Select-Object -First 1
    if ($any) { return $any.Version }
    return $null
}

function Get-AwsToolsInstalledVersionMap {
    param([Parameter(Mandatory)][string[]]$ModuleNames)

    $map = @{}
    foreach ($name in $ModuleNames) {
        $map[$name] = @(Get-Module -ListAvailable -Name $name | ForEach-Object { $_.Version })
    }
    return $map
}

function Install-AwsToolsModuleSet {
    param(
        [Parameter(Mandatory)][string[]]$ModuleNames,
        [Version]$Version
    )

    if (-not (Get-Module -ListAvailable -Name 'AWS.Tools.Installer')) {
        Write-Info 'Installing AWS.Tools.Installer ...'
        Install-Module -Name 'AWS.Tools.Installer' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
    Import-Module AWS.Tools.Installer -ErrorAction Stop

    $toInstall = @($ModuleNames | Where-Object { $_ -ne 'AWS.Tools.Common' })
    if ($toInstall.Count -eq 0) { $toInstall = @('AWS.Tools.SecurityToken') }

    $installParams = @{
        Name        = $toInstall
        Scope       = 'CurrentUser'
        ErrorAction = 'Stop'
    }
    if ($Version) {
        $installParams['Version'] = $Version.ToString()
        Write-Info "Installing $($toInstall -join ', ') version $Version (matching modules already loaded in this session) ..."
    }
    else {
        $installParams['Force'] = $true
        $installParams['Cleanup'] = $true
        Write-Info "Installing $($toInstall -join ', ') ..."
    }

    try {
        Install-AWSToolsModule @installParams | Out-Null
    }
    catch {
        if ($Version) {
            throw @(
                "Could not install $($toInstall -join ', ') at version $Version to match this PowerShell session."
                'Close this terminal and re-run AWS.ps1 so every AWS.Tools module can load at the same version.'
                $_.Exception.Message
            ) -join ' '
        }
        throw
    }
}

function Sync-AwsToolsModuleVersions {
    if (-not (Get-Module -ListAvailable -Name 'AWS.Tools.Installer')) {
        Write-Info 'Installing AWS.Tools.Installer ...'
        Install-Module -Name 'AWS.Tools.Installer' -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    }
    Import-Module AWS.Tools.Installer -ErrorAction Stop
    Write-Info 'Synchronizing installed AWS.Tools module versions ...'
    Update-AWSToolsModule -Scope CurrentUser -Force -CleanUp -ErrorAction Stop | Out-Null
}

function Import-AwsToolsModuleSet {
    param([Parameter(Mandatory)][string[]]$ModuleNames)

    $ordered = @('AWS.Tools.Common') + @($ModuleNames | Where-Object { $_ -ne 'AWS.Tools.Common' })
    $sessionVersion = Get-AwsToolsSessionVersion
    $installedVersions = @(
        $ordered |
            ForEach-Object { Get-Module -ListAvailable -Name $_ | ForEach-Object { $_.Version } }
    )
    $targetVersion = Resolve-AwsToolsTargetVersion -SessionVersion $sessionVersion -InstalledVersions $installedVersions
    if (-not $targetVersion) {
        throw 'AWS.Tools.Common is not installed.'
    }

    $available = @(Get-Module -ListAvailable -Name $ordered)
    foreach ($name in $ordered) {
        $importPath = Resolve-AwsToolsModuleImportPath -Name $name -TargetVersion $targetVersion -Available $available
        if (-not $importPath) {
            throw "Module $name version $targetVersion is not installed. Re-run the script and allow AWS Tools installation."
        }

        $loaded = Get-Module -Name $name
        if ($loaded) {
            if ($loaded.Version -ne $targetVersion) {
                throw @(
                    "Module $name is already loaded at version $($loaded.Version) in this PowerShell session,"
                    "but version $targetVersion is required."
                    'Close this terminal and re-run AWS.ps1.'
                ) -join ' '
            }
            continue
        }

        try {
            Import-Module -Name $importPath -ErrorAction Stop
        }
        catch {
            $msg = [string]$_
            if (Test-AwsToolsImportNeedsNewSession -Message $msg) {
                throw @(
                    "Module $name version $targetVersion could not be loaded because another AWS.Tools assembly is already in this PowerShell process."
                    'Close this terminal and re-run AWS.ps1.'
                    $msg
                ) -join ' '
            }
            throw
        }
    }
}

function Ensure-AwsToolsModules {
    param([string[]]$ExtraModules = @())

    $moduleNames = Get-AwsToolsModuleNames -ExtraModules $ExtraModules
    $sessionVersion = Get-AwsToolsSessionVersion
    $installedByName = Get-AwsToolsInstalledVersionMap -ModuleNames $moduleNames
    $installedVersions = @(
        $moduleNames |
            ForEach-Object { @($installedByName[$_]) } |
            Where-Object { $null -ne $_ }
    )
    $installedVersionLabels = @(
        $moduleNames |
            ForEach-Object {
                $module = Get-Module -ListAvailable -Name $_ | Sort-Object Version -Descending | Select-Object -First 1
                if ($module) { $module.Version.ToString() }
            }
    )
    $targetVersion = Resolve-AwsToolsTargetVersion -SessionVersion $sessionVersion -InstalledVersions $installedVersions
    $missingOnDisk = @(Get-AwsToolsMissingModuleNames -RequiredNames $moduleNames -TargetVersion $targetVersion -InstalledByName $installedByName)
    $versionMismatchOnDisk = Test-AwsToolsNeedsVersionSync -SessionVersion $sessionVersion -InstalledVersionLabels $installedVersionLabels

    if ($missingOnDisk.Count -gt 0 -or $versionMismatchOnDisk) {
        Write-Step 'AWS Tools for PowerShell modules are required'
        if ($missingOnDisk.Count -gt 0) {
            foreach ($name in $missingOnDisk) { Write-Info $name }
        }
        if ($versionMismatchOnDisk) {
            Write-Info "Installed AWS.Tools versions differ ($(($installedVersionLabels | Select-Object -Unique) -join ', ')). All modules must match."
        }
        if (-not (Read-YesNo -Prompt 'Install or synchronize AWS Tools modules for the current user?' -Default $true)) {
            throw "Install the modules manually, then start a new PowerShell session: Install-Module AWS.Tools.Installer -Scope CurrentUser; Install-AWSToolsModule -Name $($moduleNames -join ', ') -Scope CurrentUser -Force -Cleanup"
        }
        if ($missingOnDisk.Count -gt 0) {
            Install-AwsToolsModuleSet -ModuleNames $missingOnDisk -Version $targetVersion
        }
        else {
            Sync-AwsToolsModuleVersions
        }
        if (-not $sessionVersion) {
            Write-Info 'AWS Tools modules updated. If the next step fails with an ''already loaded'' error, close this terminal and re-run AWS.ps1.'
        }
    }

    Import-AwsToolsModuleSet -ModuleNames $moduleNames
}

function Save-IQServicePayload {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$DownloadUri,
        [string]$ZipPath,
        [scriptblock]$GetZipPath,
        [scriptblock]$GetBuildFromPath,
        [scriptblock]$UnblockFiles
    )

    $destination = & $GetZipPath $InstallPath
    $sourcePath = $null

    if (-not [string]::IsNullOrWhiteSpace($ZipPath)) {
        if (-not (Test-Path -LiteralPath $ZipPath)) {
            throw "ZIP file not found: $ZipPath"
        }
        $sourcePath = (Resolve-Path -LiteralPath $ZipPath).Path
        if ($sourcePath -ne $destination) {
            Copy-Item -LiteralPath $sourcePath -Destination $destination -Force
            Write-Ok "Copied $sourcePath to $destination"
        }
        else {
            Write-Ok "Using ZIP at $destination"
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($DownloadUri)) {
        Write-Step 'Downloading IQService.zip'
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $DownloadUri -OutFile $destination -UseBasicParsing
        }
        catch {
            $message = $_.Exception.Message
            if ($message -match '403|401|expired|Forbidden') {
                throw "Download failed. Pre-signed ISC download URLs expire quickly. Copy a fresh link from Connections > Sources > IQService Download. Details: $message"
            }
            throw "Download failed: $message"
        }
        Write-Ok "Saved to $destination"
        $sourcePath = $destination
    }
    else {
        throw 'Provide -DownloadUri or -ZipPath, or choose Download from the interactive menu.'
    }

    $build = & $GetBuildFromPath $destination
    if ($build) {
        Write-Ok "Detected build $build"
    }

    if ($UnblockFiles) {
        $unblock = & $UnblockFiles $InstallPath @($destination)
        if ($unblock.Unblocked -gt 0) {
            Write-Ok "Unblocked $($unblock.Unblocked) file(s) before extraction"
        }
    }

    return [PSCustomObject]@{
        ZipPath = $destination
        Build   = $build
    }
}

function Expand-IQServicePayload {
    param(
        [Parameter(Mandatory)][string]$InstallPath,
        [string]$ZipPath,
        [scriptblock]$GetZipPath,
        [scriptblock]$UnblockFiles
    )

    if ([string]::IsNullOrWhiteSpace($ZipPath)) {
        $ZipPath = & $GetZipPath $InstallPath
    }

    if (-not (Test-Path -LiteralPath $ZipPath)) {
        throw "ZIP file not found: $ZipPath. Run Download first or pass -ZipPath."
    }

    if (-not (Test-Path -LiteralPath $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    Write-Step "Extracting $ZipPath"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $InstallPath -Force
    Write-Ok "Extracted to $InstallPath"

    if ($UnblockFiles) {
        $unblock = & $UnblockFiles $InstallPath
        Write-Ok "Unblocked $($unblock.Unblocked) of $($unblock.Checked) executable file(s)"
    }
}

$script:UpdateCheckPerformed = $false

function Get-SailPointConnectVersionInstallRoots {
    [CmdletBinding()]
    param()

    $roots = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($candidate in @(
            Get-Module -ListAvailable -Name 'SailPoint.Connect' -ErrorAction SilentlyContinue
            Get-Module -Name 'SailPoint.Connect' -ErrorAction SilentlyContinue
        )) {
        foreach ($item in @($candidate)) {
            if (-not $item -or [string]::IsNullOrWhiteSpace($item.ModuleBase)) { continue }
            $base = $item.ModuleBase
            if ($base -match '[\\/]modules$') {
                $base = Split-Path -Parent $base
            }
            [void]$roots.Add($base)
        }
    }
    return @($roots)
}

function Remove-SailPointConnectSessionModules {
    [CmdletBinding()]
    param()

    $roots = Get-SailPointConnectVersionInstallRoots
    if ($roots.Count -eq 0) { return }

    $loaded = @(Get-Module | Where-Object {
            $mb = $_.ModuleBase
            if ([string]::IsNullOrWhiteSpace($mb)) { return $false }
            foreach ($root in $roots) {
                if ($mb.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { return $true }
            }
            return $false
        })

    foreach ($mod in ($loaded | Sort-Object { $_.Path.Length } -Descending)) {
        Remove-Module $mod -Force -ErrorAction SilentlyContinue
    }
}

function Import-SailPointConnectModuleFresh {
    <#
    .SYNOPSIS
        Removes in-session SailPoint Connect modules and imports the installed gallery build.
    #>
    [CmdletBinding()]
    param(
        [version]$RequiredVersion
    )

    Remove-SailPointConnectSessionModules

    $imported = $null
    $devReloadPath = $env:SAILPOINT_CONNECT_RELOAD_FROM_PATH
    if ($devReloadPath -and (Test-Path -LiteralPath $devReloadPath)) {
        $imported = @(Import-Module -Name $devReloadPath -Force -Global -PassThru -ErrorAction Stop)
    }
    else {
        $importParams = @{
            Name   = 'SailPoint.Connect'
            Force  = $true
            Global = $true
        }
        if ($RequiredVersion) {
            $importParams['RequiredVersion'] = $RequiredVersion.ToString()
        }
        $imported = @(Import-Module @importParams -PassThru -ErrorAction Stop)
    }
    $primary = @($imported | Sort-Object { $_.Version } -Descending | Select-Object -First 1)
    if ($primary.Count -eq 0) {
        throw 'SailPoint.Connect could not be reloaded into the current session.'
    }
    return $primary[0]
}

<#
.SYNOPSIS
    Checks whether an update is available for the SailPoint Connect PowerShell module.

.DESCRIPTION
    Queries PowerShell Gallery (via fast REST API and fallback Find-Module) to compare
    the latest published release against the locally installed or active version.

.PARAMETER CurrentVersion
    Optional override for the current version string. Defaults to the active module version.

.PARAMETER Repository
    PowerShell repository to check. Default: PSGallery.

.PARAMETER TimeoutSeconds
    Network timeout in seconds for repository query. Default: 4.

.PARAMETER Force
    Bypasses any update skip environment variables.

.EXAMPLE
    Get-SailPointConnectUpdate
    Checks PowerShell Gallery for the latest version of SailPoint.Connect.

.OUTPUTS
    System.Management.Automation.PSCustomObject with UpdateAvailable, CurrentVersion, and LatestVersion.
#>
function Get-SailPointConnectUpdate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$CurrentVersion,

        [Parameter()]
        [string]$Repository = 'PSGallery',

        [Parameter()]
        [int]$TimeoutSeconds = 4,

        [Parameter()]
        [switch]$Force
    )

    if (-not $Force -and ($env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -in @('1', 'true', '$true', 'True'))) {
        $cur = if ($CurrentVersion) { [version]$CurrentVersion } else { [version](Get-SailPointConnectVersion) }
        return [PSCustomObject]@{
            UpdateAvailable = $false
            CurrentVersion  = $cur
            LatestVersion   = $null
            Repository      = $Repository
            Skipped         = $true
        }
    }

    if (-not $CurrentVersion) {
        $CurrentVersion = Get-SailPointConnectVersion
    }
    if ($CurrentVersion -is [System.Collections.IEnumerable] -and $CurrentVersion -isnot [string]) {
        $firstItem = @($CurrentVersion | ForEach-Object { $_ } | Sort-Object { try { [version][string]$_ } catch { [version]'0.0.0' } } -Descending)
        $CurrentVersion = if ($firstItem.Count -gt 0) { [string]$firstItem[0] } else { '0.0.0' }
    }
    $currVer = try { [version][string]$CurrentVersion } catch { [version]'0.0.0' }

    $latestVer = $null

    if ($env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION) {
        try {
            $latestVer = [version]$env:SAILPOINT_CONNECT_MOCK_LATEST_VERSION
        }
        catch {}
    }

    if ($null -eq $latestVer) {
        $galleryUrl = "https://www.powershellgallery.com/api/v2/FindPackagesById()?id=%27SailPoint.Connect%27"
        try {
            $response = Invoke-RestMethod -Uri $galleryUrl -TimeoutSec $TimeoutSeconds -ErrorAction Stop
            $versions = @()
            if ($response) {
                foreach ($entry in @($response)) {
                    if ($entry.properties -and $entry.properties.Version) {
                        $versions += [string]$entry.properties.Version
                    }
                    elseif ($entry.properties) {
                        try {
                            $nodeList = $entry.properties.GetElementsByTagName("d:Version")
                            foreach ($node in $nodeList) {
                                $versions += [string]$node.InnerText
                            }
                        }
                        catch {}
                    }
                }
            }

            if ($versions.Count -gt 0) {
                $parsed = @($versions | ForEach-Object {
                    try { [version]$_ } catch { $null }
                } | Where-Object { $null -ne $_ } | Sort-Object -Descending)

                if ($parsed.Count -gt 0) {
                    $latestVer = $parsed[0]
                }
            }
        }
        catch {
            try {
                $mod = Find-Module -Name 'SailPoint.Connect' -Repository $Repository -ErrorAction Stop
                if ($mod -and $mod.Version) {
                    $latestVer = [version]$mod.Version
                }
            }
            catch {}
        }
    }

    $updateAvailable = ($null -ne $latestVer -and $latestVer -gt $currVer)

    return [PSCustomObject]@{
        UpdateAvailable = $updateAvailable
        CurrentVersion  = $currVer
        LatestVersion   = $latestVer
        Repository      = $Repository
        Skipped         = $false
    }
}

<#
.SYNOPSIS
    Updates the SailPoint Connect PowerShell module to the latest version.

.DESCRIPTION
    Checks PowerShell Gallery for a newer release of SailPoint.Connect and installs
    or updates the module for the current user.

.PARAMETER CheckOnly
    Checks whether a newer version is available and outputs the result without updating.

.PARAMETER Force
    Reinstalls the latest version even if the current version is up to date.

.PARAMETER Scope
    Installation scope: CurrentUser (default) or AllUsers.

.PARAMETER TargetVersion
    Optional specific version to install.

.PARAMETER NonInteractive
    Runs headlessly without confirmation prompts.

.EXAMPLE
    Update-SailPointConnect
    Checks for a newer version and installs the update if available.

.EXAMPLE
    Update-SailPointConnect -CheckOnly
    Reports whether an update is available without making changes.

.OUTPUTS
    System.Management.Automation.PSCustomObject with update results.
#>
function Update-SailPointConnect {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [switch]$CheckOnly,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [Parameter()]
        [string]$TargetVersion,

        [Parameter()]
        [switch]$NonInteractive
    )

    $updateInfo = Get-SailPointConnectUpdate -Force:$Force
    $currentVer = $updateInfo.CurrentVersion
    $latestVer = if ($TargetVersion) { try { [version]$TargetVersion } catch { $null } } else { $updateInfo.LatestVersion }

    if ($CheckOnly) {
        if ($updateInfo.UpdateAvailable) {
            Write-Host "A newer version of SailPoint.Connect is available: v$latestVer (current: v$currentVer)." -ForegroundColor Yellow
        }
        else {
            Write-Host "SailPoint.Connect is up to date (version v$currentVer)." -ForegroundColor Green
        }
        return $updateInfo
    }

    if (-not $updateInfo.UpdateAvailable -and -not $Force -and -not $TargetVersion) {
        Write-Ok "SailPoint.Connect is already up to date (v$currentVer)."
        return [PSCustomObject]@{
            Success        = $true
            Updated        = $false
            CurrentVersion = $currentVer
            LatestVersion  = $currentVer
        }
    }

    $verToInstall = if ($latestVer) { $latestVer.ToString() } else { 'latest' }

    if (-not $PSCmdlet.ShouldProcess("SailPoint.Connect", "Update module to version $verToInstall")) {
        return [PSCustomObject]@{
            Success        = $false
            Updated        = $false
            CurrentVersion = $currentVer
            LatestVersion  = $latestVer
            Message        = 'Operation cancelled by ShouldProcess / WhatIf.'
        }
    }

    if ($env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION -eq 'Fail') {
        throw "Simulated module installation failure"
    }

    Write-Step "Updating SailPoint.Connect to version $verToInstall..."

    $installSuccess = $false
    $errorMsg = $null

    if ($env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION -eq 'Success') {
        $installSuccess = $true
    }
    else {
        try {
            Write-Info "Checking installed module state..."
            Update-Module -Name 'SailPoint.Connect' -Scope $Scope -Force -AcceptLicense -ErrorAction Stop
            $installSuccess = $true
        }
        catch {
            Write-Info "Update-Module not applicable; running Install-Module -AllowClobber..."
            try {
                $installParams = @{
                    Name         = 'SailPoint.Connect'
                    Scope        = $Scope
                    Force        = $true
                    AllowClobber = $true
                    ErrorAction  = 'Stop'
                }
                if ($TargetVersion) {
                    $installParams['RequiredVersion'] = $TargetVersion
                }
                Install-Module @installParams
                $installSuccess = $true
            }
            catch {
                $errorMsg = $_.Exception.Message
            }
        }
    }

    if ($installSuccess) {
        Write-Ok "SailPoint.Connect has been successfully updated to v$verToInstall."

        $reloadedVersion = $null
        $reloadError = $null
        try {
            $reloadParams = @{}
            if ($env:SAILPOINT_CONNECT_MOCK_UPDATE_ACTION -ne 'Success') {
                $reloadTarget = if ($latestVer) { $latestVer } elseif ($TargetVersion) { try { [version]$TargetVersion } catch { $null } } else { $null }
                if ($reloadTarget) { $reloadParams['RequiredVersion'] = $reloadTarget }
            }
            $reloadedMod = Import-SailPointConnectModuleFresh @reloadParams
            $reloadedVersion = $reloadedMod.Version
            Write-Ok "Reloaded SailPoint.Connect v$reloadedVersion in this PowerShell session."
        }
        catch {
            $reloadError = $_.Exception.Message
            try {
                Import-Module -Name 'SailPoint.Connect' -Force -Global -ErrorAction Stop | Out-Null
                $reloadedMod = Get-Module -Name 'SailPoint.Connect' | Select-Object -First 1
                if ($reloadedMod) {
                    $reloadedVersion = $reloadedMod.Version
                    $reloadError = $null
                    Write-Ok "Reloaded SailPoint.Connect v$reloadedVersion in this PowerShell session."
                }
            }
            catch {
                $reloadError = "$reloadError | $($_.Exception.Message)"
            }
            if ($reloadError) {
                Write-Host "   Update installed but session reload failed: $reloadError" -ForegroundColor Yellow
                Write-Info "Run: Import-Module SailPoint.Connect -Force"
            }
        }

        return [PSCustomObject]@{
            Success         = $true
            Updated         = $true
            Reloaded        = ($null -ne $reloadedVersion)
            ReloadedVersion = $reloadedVersion
            CurrentVersion  = $currentVer
            LatestVersion   = $latestVer
            ReloadError     = $reloadError
        }
    }
    else {
        Write-Host "   Update failed: $errorMsg" -ForegroundColor Red
        return [PSCustomObject]@{
            Success        = $false
            Updated        = $false
            CurrentVersion = $currentVer
            LatestVersion  = $latestVer
            Error          = $errorMsg
        }
    }
}

function Confirm-SailPointConnectUpdate {
    [CmdletBinding()]
    param(
        [switch]$Wizard,
        [switch]$Force,
        [pscustomobject]$UpdateInfo
    )

    if (Test-OperatorNonInteractive) { return $false }
    if ($env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -in @('1', 'true', '$true', 'True')) { return $false }
    if ($script:UpdateCheckPerformed -and -not $Force) { return $false }
    $script:UpdateCheckPerformed = $true

    if ($null -eq $UpdateInfo) {
        $UpdateInfo = Get-SailPointConnectUpdate
    }
    if ($null -eq $UpdateInfo -or -not $UpdateInfo.UpdateAvailable) {
        return $false
    }

    $borderColor = 'Yellow'
    $textColor = 'Yellow'
    $lines = @(
        '⚡ A newer version of SailPoint Connect is available!'
        ("Current: v{0}  →  Latest: v{1}" -f $UpdateInfo.CurrentVersion, $UpdateInfo.LatestVersion)
    )
    $contentWidth = ($lines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    if ($contentWidth -lt 48) { $contentWidth = 48 }

    Write-Host ''
    Write-Host ("  ┌─" + ('─' * $contentWidth) + "─┐") -ForegroundColor $borderColor
    foreach ($line in $lines) {
        Write-OperatorFramedRow -Text $line -ContentWidth $contentWidth -TextColor $textColor -BorderColor $borderColor
    }
    Write-Host ("  └─" + ('─' * $contentWidth) + "─┘") -ForegroundColor $borderColor
    Write-Host ''

    $shouldUpdate = Read-YesNo -Prompt "Would you like to autoupdate SailPoint Connect to v$($UpdateInfo.LatestVersion) now?" -Default $true
    if ($shouldUpdate) {
        $result = Update-SailPointConnect -TargetVersion $UpdateInfo.LatestVersion.ToString()
        if ($result.Success -and $result.Reloaded) {
            Write-Ok "SailPoint Connect updated to v$($result.ReloadedVersion)."
            return $true
        }
        if ($result.Success -and -not $result.Reloaded) {
            Write-Host "   Updated on disk but the session could not reload automatically." -ForegroundColor Yellow
            if ($result.ReloadError) {
                Write-Info $result.ReloadError
            }
        }
        elseif (-not $result.Success) {
            Write-Host "   Autoupdate did not complete: $($result.Error)" -ForegroundColor Yellow
        }
    }
    return $false
}

Export-ModuleMember -Function @(
    'Set-OperatorToolchainPackageManager'
    'Get-OperatorPlatform'
    'Test-WingetAvailable'
    'Test-HomebrewAvailable'
    'Invoke-PlatformPackageInstall'
    'Resolve-CliCommand'
    'Ensure-CliCommand'
    'Ensure-GCloudCommand'
    'Ensure-AzCliCommand'
    'Ensure-OpenSslCommand'
    'Install-PowerShellGalleryModuleSet'
    'Import-PowerShellGalleryModuleSet'
    'Ensure-MicrosoftGraphModules'
    'Get-AwsToolsModuleNames'
    'Resolve-AwsToolsTargetVersion'
    'Get-AwsToolsMissingModuleNames'
    'Test-AwsToolsNeedsVersionSync'
    'Resolve-AwsToolsModuleImportPath'
    'Test-AwsToolsImportNeedsNewSession'
    'Ensure-AwsToolsModules'
    'Save-IQServicePayload'
    'Expand-IQServicePayload'
    'Get-SailPointConnectUpdate'
    'Update-SailPointConnect'
    'Confirm-SailPointConnectUpdate'
)
