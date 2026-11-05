#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$connectRoot = Split-Path $PSScriptRoot -Parent
$manifestPath = Join-Path $connectRoot 'SailPoint.Connect.psd1'
$modulePath = Join-Path $connectRoot 'SailPoint.Connect.psm1'

# 1) Manifest validation
Assert-True (Test-Path -LiteralPath $manifestPath) 'SailPoint.Connect.psd1 exists'
$manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
Assert-Equal 'SailPoint.Connect' $manifest.Name 'Manifest module name'
Assert-Equal '1.1.2' $manifest.Version.ToString() 'Manifest version 1.1.2'
Assert-Equal 'SailPoint Technologies' $manifest.Author 'Manifest author'

# 2) Module import and exported members
$m = Import-Module $manifestPath -PassThru -Force
$expectedFunctions = @(
    'Invoke-SailPointConnect',
    'Connect-SailPointAWS',
    'Connect-SailPointAzure',
    'Connect-SailPointGoogleCloud',
    'Connect-SailPointDatabricks',
    'Connect-SailPointSalesforce',
    'Connect-SailPointGitHub',
    'Start-SailPointIQServiceControl',
    'New-SailPointM365AccessProfile',
    'Get-SailPointConnectProject',
    'Set-SailPointConnectProject'
)
foreach ($fn in $expectedFunctions) {
    Assert-True ($m.ExportedFunctions.ContainsKey($fn)) "Function $fn is exported"
}

$expectedAliases = @('sailpoint-connect')
foreach ($alias in $expectedAliases) {
    Assert-True ($m.ExportedAliases.ContainsKey($alias)) "Alias $alias is exported"
}
Assert-True (-not $m.ExportedAliases.ContainsKey('Connect-SailPointGCP')) "Connect-SailPointGCP alias is dropped"

# 3) Ubiquitous Comment-Based Help verification
foreach ($fn in $expectedFunctions) {
    $help = Get-Help $fn -Full
    $synopsis = ($help.Synopsis | Out-String).Trim()
    $description = ($help.Description | Out-String).Trim()
    Assert-True (-not [string]::IsNullOrWhiteSpace($synopsis)) "$fn has Synopsis in Get-Help"
    Assert-True (-not [string]::IsNullOrWhiteSpace($description)) "$fn has Description in Get-Help"
    Assert-True ($help.Examples.example.Count -gt 0) "$fn has at least one Example in Get-Help"
}

# 4) Project management cmdlets with isolated root
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("sp-connect-test-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:SAILPOINT_CONNECT_ROOT = $tmp

try {
    # Initially no projects
    $projects = @(Get-SailPointConnectProject)
    Assert-Equal 0 $projects.Count 'Initially empty project list'

    # Create and set a project
    Set-SailPointConnectProject -Name 'test-project-alpha'
    $projects = @(Get-SailPointConnectProject)
    Assert-Equal 1 $projects.Count 'One project after Set-SailPointConnectProject'
    Assert-Equal 'test-project-alpha' $projects[0].Name 'Project name matches'
    Assert-True $projects[0].IsCurrent 'Project is marked as current'

    # 5) Verify Databricks wizard target resolution under strict mode
    Import-Module (Join-Path $connectRoot 'modules/Definitions/Databricks.Connector.psm1') -Force
    Register-IntegrationWizardPlatform -Name 'Databricks' -Title 'Databricks' -CoreOptions @('Connector') -CliName 'databricks'
    Register-DatabricksConnectorDefinitions
    $dbxTarget = @(Get-IntegrationWizardTargets -Platform 'Databricks' -Context @{ Connector = $true })
    Assert-Equal 1 $dbxTarget.Count 'Databricks connector target resolves when Connector switch is set'
    Assert-Equal 'databricks-connector' $dbxTarget[0]['Id'] 'Databricks connector definition id matches'

    # 6) Verify Salesforce and GitHub target resolution
    Import-Module (Join-Path $connectRoot 'modules/Definitions/Salesforce.Connector.psm1') -Force
    Register-IntegrationWizardPlatform -Name 'Salesforce' -Title 'Salesforce' -CoreOptions @('Connector', 'Entro') -CliName 'sf'
    Register-SalesforceConnectorDefinitions
    $sfTarget = @(Get-IntegrationWizardTargets -Platform 'Salesforce' -Context @{ Connector = $true })
    Assert-Equal 1 $sfTarget.Count 'Salesforce connector target resolves'
    Assert-Equal 'salesforce-connector' $sfTarget[0]['Id'] 'Salesforce connector id matches'

    Import-Module (Join-Path $connectRoot 'modules/Definitions/GitHub.Connector.psm1') -Force
    Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro') -CliName 'gh'
    Register-GitHubConnectorDefinitions
    $ghTarget = @(Get-IntegrationWizardTargets -Platform 'GitHub' -Context @{ Connector = $true })
    Assert-Equal 1 $ghTarget.Count 'GitHub connector target resolves'
    Assert-Equal 'github-connector' $ghTarget[0]['Id'] 'GitHub connector id matches'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"
