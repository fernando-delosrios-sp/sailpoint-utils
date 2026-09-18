param(
    [string]$ScriptPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Agent Source Setup.ps1')
)

. (Join-Path $PSScriptRoot '_TestHelpers.ps1')
$script:AssertionCount = 0

# The facade is the agent-facing contract, so it is exercised as a child process: parameter
# binding faults and stdout/stderr separation only show up when the script is actually invoked.
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-Facade {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $errPath = Join-Path ([System.IO.Path]::GetTempPath()) ("isc-facade-$([Guid]::NewGuid().ToString('n')).err")
    try {
        $stdout = & pwsh -NoProfile -File $ScriptPath @Arguments 2>$errPath
        $exitCode = $LASTEXITCODE
        $stderr = ''
        if (Test-Path -LiteralPath $errPath) {
            $stderr = [string](Get-Content -LiteralPath $errPath -Raw)
        }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Stdout   = ($stdout | Out-String)
            Stderr   = $stderr
        }
    }
    finally {
        Remove-Item -LiteralPath $errPath -Force -ErrorAction SilentlyContinue
    }
}

Import-IscModule -Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules/ISC.AgentAdapter.psm1') -Force -Global

# PowerShell 5.1 cannot build a ValidateSet from the adapter at runtime, so the facade repeats the
# connector list. Reading it back out of the AST keeps that copy honest.
function Get-FacadeConnectorValidateSet {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
    $param = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Connector' }
    $attribute = $param.Attributes | Where-Object { $_.TypeName.GetReflectionType() -eq [ValidateSet] }
    return @($attribute.PositionalArguments | ForEach-Object { $_.Value })
}

$declared = Get-FacadeConnectorValidateSet
$supported = @(Get-AgentSupportedConnectors)
Assert-Equal ($supported -join ',') ($declared -join ',') 'facade ValidateSet matches adapter supported connectors'

foreach ($connector in $supported) {
    $run = Invoke-Facade -Arguments @('-Operation', 'Catalog', '-Connector', $connector)
    Assert-Equal 0 $run.ExitCode "catalog exits 0 for $connector"
    $envelope = $run.Stdout | ConvertFrom-Json
    Assert-Equal 'catalog' $envelope.kind "catalog envelope kind for $connector"
    Assert-Equal $connector $envelope.connector "catalog envelope connector for $connector"
}

# SupportsShouldProcess supplies -WhatIf; a locally declared switch of the same name makes every
# invocation fail to bind, so the facade is run with the flag to keep that regression out.
$whatIf = Invoke-Facade -Arguments @('-Operation', 'Catalog', '-Connector', 'entra-id', '-WhatIf')
Assert-Equal 0 $whatIf.ExitCode '-WhatIf binds against SupportsShouldProcess'
Assert-True ($whatIf.Stderr -notmatch 'defined multiple times') '-WhatIf is not a duplicate parameter'

$outputPath = Join-Path ([System.IO.Path]::GetTempPath()) ("isc-facade-$([Guid]::NewGuid().ToString('n')).json")
try {
    $written = Invoke-Facade -Arguments @('-Operation', 'Catalog', '-Connector', 'entra-id', '-OutputPath', $outputPath)
    Assert-Equal 0 $written.ExitCode 'catalog with -OutputPath exits 0'
    Assert-True ([string]::IsNullOrWhiteSpace($written.Stdout)) '-OutputPath keeps stdout quiet'
    Assert-Equal 'catalog' ((Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json).kind) 'envelope written to -OutputPath'
}
finally {
    Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
}

$failed = Invoke-Facade -Arguments @('-Operation', 'Plan', '-Connector', 'entra-id')
Assert-Equal 1 $failed.ExitCode 'missing -RequestPath exits 1'
Assert-True ([string]::IsNullOrWhiteSpace($failed.Stdout)) 'failures leave stdout free of non-JSON output'
Assert-True ($failed.Stderr -match 'Plan requires -RequestPath') 'failure reason reported on stderr'

Write-Host "PASS ($script:AssertionCount assertions)"
