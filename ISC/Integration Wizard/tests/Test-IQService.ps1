param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.IQService.psm1'),
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

Import-Module $ConsolePath -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole -NonInteractive
Import-Module $ModulePath -Force -WarningAction SilentlyContinue
Initialize-IQServiceData -NonInteractive

function New-TestService {
    param([string]$Name, [string]$InstallPath, [string]$Status = 'Running')
    return [PSCustomObject]@{
        Name        = $Name
        DisplayName = $Name
        Status      = $Status
        StartType   = 'Automatic'
        ImagePath   = "$InstallPath\IQService.exe"
        InstallPath = $InstallPath
        StartName   = 'SERI\svc-iqservice'
    }
}

function New-TestRegistryInstance {
    param([string]$InstanceName, $Port, $TlsPort, [string]$TraceFile, $TraceLevel = 2)
    return [PSCustomObject]@{
        InstanceName    = $InstanceName
        Port            = $Port
        TlsPort         = $TlsPort
        TraceFile       = $TraceFile
        TraceLevel      = $TraceLevel
        MaxTraceFiles   = 10
        TraceFileSize   = 10240
        ClientAuthUsers = $null
    }
}

# Path comparison
Assert-True (Test-SameIQServicePath -Left 'C:\SailPoint\IQService' -Right 'c:\sailpoint\iqservice\') 'path comparison ignores case and trailing separator'
Assert-True (-not (Test-SameIQServicePath -Left 'C:\SailPoint\IQService' -Right 'C:\SailPoint\IQService2')) 'sibling install paths are not the same instance'
Assert-True (-not (Test-SameIQServicePath -Left '' -Right 'C:\SailPoint\IQService')) 'an unknown path never matches'
Assert-Equal 'C:\SailPoint\IQService' (Get-IQServiceParentPath -Path 'C:\SailPoint\IQService\iqtrace.log') 'Windows trace paths yield their parent directory'
Assert-Equal '/opt/sailpoint' (Get-IQServiceParentPath -Path '/opt/sailpoint/iqtrace.log') 'forward-slash paths yield their parent directory'
Assert-Equal '' (Get-IQServiceParentPath -Path 'iqtrace.log') 'a bare file name has no parent directory'

# Two instances, correlated by matching service and registry key names
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
    (New-TestService -Name 'SailPointIQService2' -InstallPath 'D:\SailPoint\IQService2')
) -RegistryInstances @(
    (New-TestRegistryInstance -InstanceName 'SailPointIQService2' -Port 5051 -TlsPort 5551 -TraceFile 'D:\SailPoint\IQService2\iqtrace.log')
    (New-TestRegistryInstance -InstanceName 'SailPointIQService' -Port 5050 -TlsPort 5550 -TraceFile 'C:\SailPoint\IQService\iqtrace.log')
))
Assert-Equal 2 $records.Count 'two services produce two instance records'
$first = $records | Where-Object { $_.InstallPath -eq 'C:\SailPoint\IQService' }
$second = $records | Where-Object { $_.InstallPath -eq 'D:\SailPoint\IQService2' }
Assert-Equal 5050 $first.Port 'first instance keeps its own port despite registry enumeration order'
Assert-Equal 5051 $second.Port 'second instance keeps its own port'
Assert-Equal 'ServiceName' $first.MatchedBy 'matching names correlate by service name'
Assert-Equal 'D:\SailPoint\IQService2\iqtrace.log' $second.TraceFile 'each instance keeps its own trace file'

# Registry keys named differently from the services fall back to the trace file directory
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
    (New-TestService -Name 'SailPointIQService2' -InstallPath 'D:\SailPoint\IQService2')
) -RegistryInstances @(
    (New-TestRegistryInstance -InstanceName 'prod-b' -Port 5051 -TlsPort $null -TraceFile 'D:\SailPoint\IQService2\iq2.log')
    (New-TestRegistryInstance -InstanceName 'prod-a' -Port 5050 -TlsPort $null -TraceFile 'C:\SailPoint\IQService\iq1.log')
))
$first = $records | Where-Object { $_.InstallPath -eq 'C:\SailPoint\IQService' }
$second = $records | Where-Object { $_.InstallPath -eq 'D:\SailPoint\IQService2' }
Assert-Equal 'prod-a' $first.InstanceName 'trace file location correlates the first instance'
Assert-Equal 'TraceFilePath' $first.MatchedBy 'fallback correlation is reported as TraceFilePath'
Assert-Equal 5051 $second.Port 'trace file location correlates the second instance'

# A single unnameable instance may still be paired, but only when it is the only one
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
) -RegistryInstances @(
    (New-TestRegistryInstance -InstanceName 'default' -Port 5050 -TlsPort $null -TraceFile 'C:\Windows\system32\iqtrace.log')
))
Assert-Equal 'SoleInstance' $records[0].MatchedBy 'a lone service pairs with a lone registry key'
Assert-Equal 5050 $records[0].Port 'the lone pairing carries the port through'

# With two services and one uncorrelatable key, nothing is guessed
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
    (New-TestService -Name 'SailPointIQService2' -InstallPath 'D:\SailPoint\IQService2')
) -RegistryInstances @(
    (New-TestRegistryInstance -InstanceName 'mystery' -Port 5050 -TlsPort $null -TraceFile 'C:\Windows\system32\iqtrace.log')
))
$services = @($records | Where-Object { $_.HasService })
Assert-Equal 2 $services.Count 'both services are still reported'
Assert-Equal 0 @($services | Where-Object { $_.HasRegistry }).Count 'an ambiguous registry key is not attributed to either service'
$orphan = @($records | Where-Object { -not $_.HasService })
Assert-Equal 1 $orphan.Count 'the uncorrelated registry key is reported on its own'
Assert-Equal 'mystery' $orphan[0].InstanceName 'the orphan keeps its registry key name'

# Missing optional registry values must not throw under Set-StrictMode
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
) -RegistryInstances @(
    [PSCustomObject]@{ InstanceName = 'SailPointIQService'; Port = 5050 }
))
Assert-Equal 5050 $records[0].Port 'a registry key holding only a port still correlates'
Assert-True ($null -eq $records[0].TlsPort) 'an absent tlsPort reads as null instead of throwing'

# Services with no registry key at all
$records = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
) -RegistryInstances @())
Assert-Equal 1 $records.Count 'a service without registry settings is still an instance'
Assert-True (-not $records[0].HasRegistry) 'the record reports that it has no registry settings'
Assert-True ($null -eq $records[0].TraceFile) 'no trace file is invented for it'
Assert-Equal 0 @(Resolve-IQServiceInstanceRecords -Services @() -RegistryInstances @()).Count 'a host with no IQService yields no instances'

# Scoped lookup
$instances = @(Resolve-IQServiceInstanceRecords -Services @(
    (New-TestService -Name 'SailPointIQService' -InstallPath 'C:\SailPoint\IQService')
    (New-TestService -Name 'SailPointIQService2' -InstallPath 'D:\SailPoint\IQService2')
) -RegistryInstances @(
    (New-TestRegistryInstance -InstanceName 'SailPointIQService' -Port 5050 -TlsPort 5550 -TraceFile 'C:\SailPoint\IQService\iqtrace.log')
    (New-TestRegistryInstance -InstanceName 'SailPointIQService2' -Port 5051 -TlsPort 5551 -TraceFile 'D:\SailPoint\IQService2\iqtrace.log' -TraceLevel 3)
))
$scoped = Get-IQServiceInstanceForPath -InstallPath 'd:\sailpoint\iqservice2\' -Instances $instances
Assert-Equal 5051 $scoped.Port 'scoped lookup normalizes the path it is given'
Assert-Equal 3 $scoped.TraceLevel 'scoped lookup returns that instance trace level'
Assert-True ($null -eq (Get-IQServiceInstanceForPath -InstallPath 'E:\Elsewhere' -Instances $instances)) 'an unknown install path resolves to no instance'
Assert-True ((Get-IQServiceInstanceLabel -Instance $scoped) -like '*SailPointIQService2*D:\SailPoint\IQService2*') 'instance labels name the instance and its path'
Assert-Equal '(unknown instance)' (Get-IQServiceInstanceLabel -Instance $null) 'a missing instance still labels safely'

# Install arguments
Assert-Equal '-i' ((Build-IQServiceInstallArguments) -join ' ') 'install defaults to bare registration'
Assert-Equal '-i -p 5050 -o 5550 -b' ((Build-IQServiceInstallArguments -Port 5050 -TlsPort 5550 -SkipSecondary) -join ' ') 'ports and secondary skip are passed through'
Assert-Equal '-i' ((Build-IQServiceInstallArguments -Port 0 -TlsPort 0) -join ' ') 'zero ports are omitted'

Assert-Equal 'C:\SailPoint\IQService' (Get-IQServiceDefaultInstallPath) 'the default install path is available without prior initialization'

Write-Host "PASS ($script:AssertionCount assertions)"
