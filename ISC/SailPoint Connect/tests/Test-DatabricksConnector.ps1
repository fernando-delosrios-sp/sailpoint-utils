#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.DatabricksConnector.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Databricks.Connector.psm1') -Force
Initialize-OperatorConsole -NonInteractive
Register-IntegrationWizardPlatform -Name 'Databricks' -Title 'Databricks' -CoreOptions @('Connector') -CliName 'databricks'
Register-DatabricksConnectorDefinitions

$def = Get-IntegrationWizardDefinition -Id 'databricks-connector'
$m2m = @(& $def.Steps @{ Auth = 'DatabricksM2M'; Cloud = 'Aws' })
Assert-Equal 'sp-create,oauth-secret' (($m2m | ForEach-Object { $_.Id }) -join ',') 'M2M creates the service principal and its secret'
Assert-True (@($m2m | Where-Object { $_.Kind -eq 'Manual' }).Count -eq 0) 'M2M has no manual steps'
$entra = @(& $def.Steps @{ Auth = 'Entra'; Cloud = 'Azure' })
Assert-Equal 'Manual' $entra[0].Kind 'Entra auth keeps the Entra application handoff'

Assert-Equal 'https://accounts.azuredatabricks.net' (Get-DatabricksAccountHost -Cloud 'Azure') 'Azure accounts host'
Assert-Equal 'https://accounts.gcp.databricks.com' (Get-DatabricksAccountHost -Cloud 'Gcp') 'GCP accounts host'
Assert-Equal 'https://accounts.cloud.databricks.com' (Get-DatabricksAccountHost -Cloud 'Aws') 'AWS accounts host'

$script:Calls = @()
$script:Principals = @()
$script:SecretCreates = 0
function global:databricks {
    $line = $args -join ' '
    $script:Calls += , @{ Line = $line; Host = $env:DATABRICKS_HOST; Account = $env:DATABRICKS_ACCOUNT_ID }
    $global:LASTEXITCODE = 0
    if ($line -match '^account metastores list') { return '[]' }
    if ($line -match '^account service-principals list') { return (ConvertTo-Json -InputObject @($script:Principals) -Depth 6) }
    if ($line -match '^account service-principals create --display-name (\S+)') {
        $sp = @{ id = '1001'; applicationId = 'app-guid-1'; displayName = $Matches[1]; roles = @() }
        $script:Principals += $sp
        return ($sp | ConvertTo-Json -Depth 6)
    }
    if ($line -match '^account service-principals patch 1001 --json (.+) --output json$') {
        $patch = $Matches[1] | ConvertFrom-Json
        if ($patch.Operations[0].value[0].value -eq 'account_admin') { $script:Principals[0].roles = @(@{ value = 'account_admin' }) }
        return ''
    }
    if ($line -match '^account service-principal-secrets create 1001') {
        $script:SecretCreates++
        return (@{ id = "secret-$script:SecretCreates"; secret = "dose-$script:SecretCreates"; status = 'ACTIVE' } | ConvertTo-Json)
    }
    $global:LASTEXITCODE = 1
    Write-Error "unexpected databricks call: $line"
}

$outDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dbx-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $outDir | Out-Null
try {
    $env:DATABRICKS_HOST = 'https://workspace.example.com'
    $ctx = @{ Auth = 'DatabricksM2M'; Cloud = 'Aws'; AccountId = 'acct-1'; ServicePrincipalName = 'SailPoint-source'; IntegrationFolderPath = $outDir; NonInteractive = $true }
    $steps = @(& $def.Steps $ctx)
    $sp = $steps[0]
    Assert-Equal 'Create' (& $sp.Probe $ctx) 'a missing service principal is created'
    & $sp.Run $ctx
    $record = Get-DatabricksRunRecord -Context $ctx
    Assert-Equal 'Created in this run' $record.ServicePrincipalResult 'the run records the new service principal'
    Assert-Equal 'Granted in this run' $record.AccountAdminResult 'Account admin is granted'
    Assert-Equal 'app-guid-1' $record.ApplicationId 'the client ID is the application ID'
    Assert-True (@($script:Calls | Where-Object { $_.Line -match '^account ' -and $_.Host -ne 'https://accounts.cloud.databricks.com' }).Count -eq 0) 'account commands use the accounts host'
    Assert-True (@($script:Calls | Where-Object { $_.Line -match '^account ' -and $_.Account -ne 'acct-1' }).Count -eq 0) 'account commands carry the account ID'
    Assert-Equal 'https://workspace.example.com' $env:DATABRICKS_HOST 'the caller environment is restored'

    $secret = $steps[1]
    Assert-Equal 'Create' (& $secret.Probe $ctx) 'a missing secret file means a new secret'
    & $secret.Run $ctx
    $path = Join-Path $outDir 'databricks-oauth-secret.json'
    $saved = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Assert-Equal 'app-guid-1' $saved.client_id 'the secret file has the client ID'
    Assert-Equal 'dose-1' $saved.client_secret 'the secret file has the client secret'
    Assert-True (((Get-Item -LiteralPath $path).UnixFileMode -band [System.IO.UnixFileMode]::GroupRead) -eq 0) 'the secret file is not group-readable'

    $rerun = @{ Auth = 'DatabricksM2M'; Cloud = 'Aws'; AccountId = 'acct-1'; ServicePrincipalName = 'SailPoint-source'; IntegrationFolderPath = $outDir; NonInteractive = $true }
    Assert-Equal 'Skip' (& $sp.Probe $rerun) 'an existing admin service principal is unchanged'
    Assert-Equal 'Skip' (& $secret.Probe $rerun) 'an existing secret file is reused'
    Assert-Equal 1 $script:SecretCreates 'a rerun does not mint another secret'

    $rotate = $rerun.Clone(); $rotate['RotateSecret'] = $true; $rotate.Remove('DatabricksServicePrincipal')
    Assert-Equal 'Create' (& $secret.Probe $rotate) 'RotateSecret forces a new secret'
    & $secret.Run $rotate
    Assert-Equal 2 $script:SecretCreates 'rotation creates a second secret'
    Assert-Equal 'dose-2' (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json).client_secret 'rotation replaces the secret on disk'

    $script:Principals[0].roles = @()
    $noAdmin = @{ Auth = 'DatabricksM2M'; Cloud = 'Aws'; AccountId = 'acct-1'; ServicePrincipalName = 'SailPoint-source'; IntegrationFolderPath = $outDir; NonInteractive = $true }
    Assert-Equal 'Update' (& $sp.Probe $noAdmin) 'a service principal without Account admin is updated'

    function global:databricks {
        $global:LASTEXITCODE = 1
        Write-Error 'cannot configure default credentials'
    }
    $refused = $null
    try { Connect-DatabricksAccount -AccountId 'acct-1' -Cloud 'Azure' -NonInteractive } catch { $refused = $_.Exception.Message }
    Assert-True ($refused -match 'databricks auth login --host https://accounts.azuredatabricks.net --account-id acct-1') 'a missing account session names the login command'

    # Agent Discovery / Mosaic AI tests
    $packs = Get-DatabricksFeaturePacks
    Assert-True ($packs.ContainsKey('AgentDiscovery')) 'AgentDiscovery pack exists in Databricks connector'
    $agentPack = Get-DatabricksAgentDiscoveryFeaturePack
    Assert-Equal 'AgentDiscovery' $agentPack.Name 'AgentDiscovery pack name matches'
    $checklist = Get-DatabricksIscFeatureChecklist -FeatureNames @('AgentDiscovery')
    Assert-True (($checklist -join ' ') -like '*Mosaic AI*') 'Checklist includes Mosaic AI guidance'
    Assert-True (($checklist -join ' ') -like '*Agentic Fabric*') 'Checklist notes Agentic Fabric requirement'

    $connSettings = Build-DatabricksConnectionSettings -AccountId 'acct-1' -Cloud 'Aws' -MetastoreId 'meta-123' -ClientId 'app-guid-1' -FeatureNames @('AgentDiscovery')
    Assert-True ($connSettings -like '*OAuth Client ID: app-guid-1*') 'Connection settings include Client ID'
    Assert-True ($connSettings -like '*Mosaic AI Agent*') 'Connection settings include Agent Discovery section'
}
finally {
    Remove-Item Function:global:databricks -ErrorAction SilentlyContinue
    Remove-Item Env:DATABRICKS_HOST -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $outDir) { Remove-Item -LiteralPath $outDir -Recurse -Force }
}

Write-Host "PASS ($script:AssertionCount assertions)"
