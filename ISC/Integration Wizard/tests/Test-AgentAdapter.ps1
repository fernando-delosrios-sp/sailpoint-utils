param(
    [string]$ModuleRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules')
)

. (Join-Path $PSScriptRoot '_TestHelpers.ps1')
$script:AssertionCount = 0

Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.AgentAdapter.psm1') -Force -Global
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.EntraSourceSetup.psm1') -Force

$request = [ordered]@{
    schemaVersion = 1
    connector     = 'entra-id'
    config        = [ordered]@{ applicationName = 'Test App' }
}

$hash = Get-AgentRequestHash -Request $request
Assert-True ($hash.Length -eq 64) 'request hash is sha256 hex'

$redacted = ConvertTo-RedactedAgentObject -InputObject ([ordered]@{
    'Client Secret' = 'super-secret-value'
    'Client ID'     = '11111111-2222-3333-4444-555555555555'
})
Assert-Equal '***redacted***' $redacted.'Client Secret' 'secret field redacted'
Assert-True ($redacted.'Client ID' -like '*5555') 'non-secret preserved'

$plan = New-EntraAgentPlan -Request $request
Assert-True ($plan.status -in @('ready', 'needsInput')) 'plan returns structured status'

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("isc-agent-test-$([Guid]::NewGuid().ToString('n'))")
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$secretPath = Join-Path $tempDir 'secret.txt'
Set-AgentRestrictedFile -Path $secretPath -Content 'top-secret'
Assert-True (Test-Path -LiteralPath $secretPath) 'restricted secret file written'
$resolved = Resolve-AgentSecretReference -Reference "file:$secretPath"
Assert-Equal 'top-secret' $resolved 'secret reference resolves from file'

$catalog = Invoke-AgentAdapter -Operation Catalog -Connector 'entra-id'
Assert-Equal 'catalog' $catalog.kind 'catalog envelope kind'

Write-Host "PASS ($script:AssertionCount assertions)"
