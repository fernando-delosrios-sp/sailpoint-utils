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

$items = @(
    [PSCustomObject]@{ Label = 'Role ARN'; Value = 'arn:aws:iam::123:role/SailPointCIEMAuditRole'; Kind = 'Copy'; Mask = $false }
    [PSCustomObject]@{ Label = 'Client Secret'; Value = 'super-secret-value'; Kind = 'Copy'; Mask = $true }
    [PSCustomObject]@{ Label = 'IAM role in AWS console'; Value = 'https://console.aws.amazon.com/iam/home#/roles/SailPointCIEMAuditRole'; Kind = 'Open'; Mask = $false }
)

Assert-Equal 'Save to disk (sailpoint-ciem-aws-connection-settings.txt)' `
    (Get-CompletionSaveToDiskLabel -Path './sourceConfig/aws-ciem/sailpoint-ciem-aws-connection-settings.txt') `
    'Save to disk label uses the filename'

$withoutSave = Get-CompletionActionMenuChoices -Items $items
Assert-True ($withoutSave -notcontains (Get-CompletionSaveToDiskLabel -Path 'results.txt')) 'IQService-style menu omits Save to disk'
Assert-Equal 'Done' $withoutSave[-1] 'Done stays last without Save to disk'

$withSave = Get-CompletionActionMenuChoices -Items $items -AllowSaveToDisk -SavePath './sourceConfig/aws-ciem/sailpoint-ciem-aws-connection-settings.txt'
Assert-Equal 'Save to disk (sailpoint-ciem-aws-connection-settings.txt)' $withSave[-2] 'Save to disk sits above Done'
Assert-Equal 'Done' $withSave[-1] 'Done stays the default last choice'
Assert-True ($withSave[1] -match '\*\*\*') 'secret preview stays masked in the menu'
Assert-True ($withSave[1] -notmatch 'super-secret-value') 'menu labels never show the raw secret'

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("isc-completion-save-" + [guid]::NewGuid().ToString('N'))
$savePath = Join-Path $tempRoot 'results.txt'
try {
    $written = Save-CompletionResultsToDisk -Items $items -Path $savePath -Title 'CIEM AWS results' -Situation @('Setup complete.')
    Assert-Equal $savePath $written 'save returns the path written'
    $content = Get-Content -LiteralPath $savePath -Raw
    Assert-True ($content -match 'super-secret-value') 'saved file includes secrets in full'
    Assert-True ($content -notmatch '\*\*\*') 'saved file does not mask secrets'
    Assert-True ($content -match 'arn:aws:iam::123:role/SailPointCIEMAuditRole') 'saved file includes copy values'
    Assert-True ($content -match 'https://console.aws.amazon.com/iam/home#/roles/SailPointCIEMAuditRole') 'saved file includes open links'
    Assert-True ($content -match 'Setup complete') 'saved file includes the situation statement'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
