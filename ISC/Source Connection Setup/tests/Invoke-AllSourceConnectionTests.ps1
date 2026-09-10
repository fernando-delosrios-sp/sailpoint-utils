$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$failures = @()

Get-ChildItem -LiteralPath $root -Filter 'Test-*.ps1' | Sort-Object Name | ForEach-Object {
    Write-Host "Running $($_.Name)..."
    $output = & pwsh -NoProfile -File $_.FullName 2>&1
    $text = ($output | Out-String)
    Write-Host $text
    if ($LASTEXITCODE -ne 0 -or $text -notmatch 'PASS \(\d+ assertions\)') {
        $failures += $_.Name
        Write-Host "FAIL: $($_.Name)" -ForegroundColor Red
    }
}

if ($failures.Count -gt 0) {
    throw "Test failures: $($failures.Count)"
}

Write-Host 'All Source Connection Setup tests passed.'
