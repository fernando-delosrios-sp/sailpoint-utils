param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorToolchain.psm1'),
    [string]$ConsolePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorConsole.psm1')
)

$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0
$script:InstalledPackages = @()

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

Import-Module $ConsolePath -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole -NonInteractive
Import-Module $ModulePath -Force -WarningAction SilentlyContinue

Set-OperatorToolchainPackageManager `
    -TestPackageManager { return $true } `
    -InstallPackage {
        param($PackageId, $BrewPackage)
        $script:InstalledPackages += $PackageId
    }

$openssl = Resolve-CliCommand -CommandNames @('openssl')
if ($openssl) {
    Assert-True (Test-Path -LiteralPath $openssl) 'existing openssl resolves on PATH'
}
else {
    $path = Ensure-CliCommand -CommandNames @('fakecli-test') -WingetPackageId 'Test.Package' -BrewPackage 'test-package' -ManualHint 'manual'
    Assert-Equal 1 $script:InstalledPackages.Count 'fake package manager records install'
}

$names = Get-AwsToolsModuleNames -ExtraModules @('AWS.Tools.CloudFormation')
Assert-True ($names -contains 'AWS.Tools.CloudFormation') 'extra AWS modules merge uniquely'

$pinned = Resolve-AwsToolsTargetVersion -SessionVersion ([Version]'5.0.293') -InstalledVersions @([Version]'5.0.293', [Version]'5.0.294')
Assert-Equal '5.0.293' $pinned.ToString() 'import pin prefers the version already loaded in the session'

$latest = Resolve-AwsToolsTargetVersion -InstalledVersions @([Version]'5.0.293', [Version]'5.0.294')
Assert-Equal '5.0.294' $latest.ToString() 'without a session, import pin uses the newest installed version'

$installed = @{
    'AWS.Tools.Common'           = @([Version]'5.0.293')
    'AWS.Tools.SecurityToken'    = @([Version]'5.0.293')
    'AWS.Tools.S3'               = @()
}
$missing = Get-AwsToolsMissingModuleNames -RequiredNames @('AWS.Tools.Common', 'AWS.Tools.S3') -TargetVersion ([Version]'5.0.293') -InstalledByName $installed
$missing = @($missing)
Assert-Equal 1 $missing.Count 'only S3 is missing at the session version'
Assert-Equal 'AWS.Tools.S3' $missing[0] 'missing extra is AWS.Tools.S3'

Assert-True (-not (Test-AwsToolsNeedsVersionSync -SessionVersion ([Version]'5.0.293') -InstalledVersionLabels @('5.0.293', '5.0.294'))) 'do not upgrade the full set while a session already has AWS.Tools loaded'
Assert-True (Test-AwsToolsNeedsVersionSync -InstalledVersionLabels @('5.0.293', '5.0.294')) 'empty session still synchronizes mixed disk versions'

$s3Path = Resolve-AwsToolsModuleImportPath -Name 'AWS.Tools.S3' -TargetVersion ([Version]'5.0.293') -Available @(
    [PSCustomObject]@{ Name = 'AWS.Tools.S3'; Version = [Version]'5.0.294'; Path = '/modules/AWS.Tools.S3/5.0.294/AWS.Tools.S3.psd1' }
    [PSCustomObject]@{ Name = 'AWS.Tools.S3'; Version = [Version]'5.0.293'; Path = '/modules/AWS.Tools.S3/5.0.293/AWS.Tools.S3.psd1' }
)
Assert-Equal '/modules/AWS.Tools.S3/5.0.293/AWS.Tools.S3.psd1' $s3Path 'import uses the session-pinned module path, not the newest on disk'
Assert-True (Test-AwsToolsImportNeedsNewSession -Message "Could not load file or assembly 'AWSSDK.Core, Version=4.0.0.0'. Assembly with same name is already loaded") 'AWSSDK.Core already loaded requires a new session'

Write-Host "PASS ($script:AssertionCount assertions)"
