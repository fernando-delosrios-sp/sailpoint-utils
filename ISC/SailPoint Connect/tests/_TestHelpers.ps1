$ErrorActionPreference = 'Stop'

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

function Get-SourceConnectionSetupRoot {
    return Split-Path -Parent $PSScriptRoot
}

function Import-IscModule {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force,
        [switch]$Global = $true
    )

    $importParams = @{
        Name          = $Path
        WarningAction = 'SilentlyContinue'
        Global        = [bool]$Global
    }
    if ($Force) { $importParams['Force'] = $true }
    Import-Module @importParams
}
