param(
    [string]$ModulePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.OperatorConsole.psm1')
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

Import-Module $ModulePath -Force -WarningAction SilentlyContinue
Initialize-OperatorConsole -NonInteractive

Assert-Equal '***' (Get-MaskedSecretDisplay -Value 'abcd') 'short secrets mask fully'
Assert-Equal '***wxyz' (Get-MaskedSecretDisplay -Value 'abcdefghijwxyz') 'long secrets keep suffix'

$preview = Get-CompletionPreview -Value ('x' * 80) -Mask
Assert-True ($preview.Length -le 72) 'masked preview stays short'

Assert-Equal 'non-interactive mode' (Get-ConsoleMenuBlocker) 'non-interactive mode blocks menus'

Write-Host "PASS ($script:AssertionCount assertions)"
