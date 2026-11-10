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

Assert-Equal 'arn example' (ConvertTo-MenuLine "arn`r`nexample") 'menu lines flatten CR/LF'
Assert-Equal 'a b' (ConvertTo-MenuLine "a`tb") 'menu lines flatten tabs'

$preview = Get-CompletionPreview -Value ('x' * 80) -Mask
Assert-True ($preview.Length -le 72) 'masked preview stays short'

Assert-Equal 'non-interactive mode' (Get-ConsoleMenuBlocker) 'non-interactive mode blocks menus'

$items = @(
    [PSCustomObject]@{ Label = 'Role ARN'; Value = 'arn:aws:iam::123:role/SailPointCIEMAuditRole'; Kind = 'Copy'; Mask = $false }
    [PSCustomObject]@{ Label = 'Client Secret'; Value = 'super-secret-value'; Kind = 'Copy'; Mask = $true }
    [PSCustomObject]@{ Label = 'IAM role in AWS console'; Value = 'https://console.aws.amazon.com/iam/home#/roles/SailPointCIEMAuditRole'; Kind = 'Open'; Mask = $false }
)

Assert-Equal 'Save to disk (sailpoint-ciem-aws-connection-settings.txt)' `
    (Get-CompletionSaveToDiskLabel -Path './wizard-output/aws-ciem/sailpoint-ciem-aws-connection-settings.txt') `
    'Save to disk label uses the filename'

$withoutSave = Get-CompletionActionMenuChoices -Items $items
Assert-True ($withoutSave -notcontains (Get-CompletionSaveToDiskLabel -Path 'results.txt')) 'IQService-style menu omits Save to disk'
Assert-Equal 'Done' $withoutSave[-1] 'Done stays last without Save to disk'

$withSave = Get-CompletionActionMenuChoices -Items $items -AllowSaveToDisk -SavePath './wizard-output/aws-ciem/sailpoint-ciem-aws-connection-settings.txt'
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

$maskedVal = Read-InputString -Prompt 'Secret key' -Default 'my-secret' -Mask
Assert-Equal 'my-secret' $maskedVal 'Read-InputString with -Mask returns default in non-interactive mode'

$maskedRequiredThrown = $false
try {
    Read-InputString -Prompt 'Secret key' -Required -Mask
}
catch {
    $maskedRequiredThrown = $true
}
Assert-True $maskedRequiredThrown 'Read-InputString with -Mask and -Required throws when missing in non-interactive'

# Banner and report tests
$ver = Get-SailPointConnectVersion
Assert-Equal '1.2.0' $ver 'Get-SailPointConnectVersion resolves 1.2.0 from module/psd1'

# Non-interactive banner writes nothing
$nonIntBannerOut = pwsh -Command {
    param($m)
    Import-Module $m -Force
    Initialize-OperatorConsole -NonInteractive
    Write-SailPointConnectBanner
} -Args $ModulePath
Assert-True ([string]::IsNullOrWhiteSpace($nonIntBannerOut)) 'Write-SailPointConnectBanner is silent in non-interactive mode'

# Interactive banner includes project name and version
$intBannerOut = pwsh -Command {
    param($m)
    Import-Module $m -Force
    Initialize-OperatorConsole
    Write-SailPointConnectBanner -ProjectName 'DemoProject'
} -Args $ModulePath
Assert-True ((@($intBannerOut) -join "`n") -match 'SailPoint Connect') 'banner includes project title'
Assert-True ((@($intBannerOut) -join "`n") -match 'v1\.2\.0') 'banner includes module version'
Assert-True ((@($intBannerOut) -join "`n") -match 'Workspace: DemoProject') 'banner includes active workspace project'

# Report stdout output
$reportOut = pwsh -Command {
    param($m)
    Import-Module $m -Force
    Write-ReportStdout -Content "# Report Header`n`nDetails here."
} -Args $ModulePath
Assert-True ((@($reportOut) -join "`n") -match '# Report Header') 'Write-ReportStdout writes report header'
Assert-True ((@($reportOut) -join "`n") -match 'Details here\.') 'Write-ReportStdout writes report body'

# Format-TerminalHyperlink tests
$nonIntLink = Format-TerminalHyperlink -Path '/path/to/some file.txt'
Assert-Equal '/path/to/some file.txt' $nonIntLink 'Format-TerminalHyperlink returns raw path in non-interactive mode'

$intLinkOut = pwsh -Command {
    param($m)
    Import-Module $m -Force
    Initialize-OperatorConsole
    $env:TERM = 'xterm-256color'
    Remove-Item env:NO_COLOR -ErrorAction SilentlyContinue
    Format-TerminalHyperlink -Path '/path/to/some file.txt'
} -Args $ModulePath
$esc = [char]27
Assert-True ($intLinkOut -match [regex]::Escape("$esc]8;;file:///")) 'Format-TerminalHyperlink outputs OSC 8 file URI in interactive mode'
Assert-True ($intLinkOut -match '/path/to/some%20file\.txt') 'Format-TerminalHyperlink percent-encodes spaces in URI'
Assert-True ($intLinkOut -match '/path/to/some file\.txt') 'Format-TerminalHyperlink preserves original path in display text'

Write-Host "PASS ($script:AssertionCount assertions)"
