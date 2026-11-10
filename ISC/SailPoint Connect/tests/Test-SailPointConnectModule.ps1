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
Assert-Equal '1.2.0' $manifest.Version.ToString() 'Manifest version 1.2.0'
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
    'Connect-SailPointCrowdStrike',
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

    Import-Module (Join-Path $connectRoot 'modules/Definitions/CrowdStrike.Connector.psm1') -Force
    Register-IntegrationWizardPlatform -Name 'CrowdStrike' -Title 'CrowdStrike' -CoreOptions @('Connector', 'Entro') -CliName 'falcon'
    Register-CrowdStrikeConnectorDefinitions
    $csTarget = @(Get-IntegrationWizardTargets -Platform 'CrowdStrike' -Context @{ Connector = $true })
    Assert-Equal 1 $csTarget.Count 'CrowdStrike connector target resolves'
    Assert-Equal 'crowdstrike-connector' $csTarget[0]['Id'] 'CrowdStrike connector id matches'

    # 7) Verify Invoke-SailPointConnect forwards named arguments cleanly without positional argument errors
    $fwdErr = $null
    $fwdOutDir = Join-Path $tmp 'fwd-out'
    New-Item -ItemType Directory -Path $fwdOutDir -Force | Out-Null
    try {
        Invoke-SailPointConnect -Platform AWS -SaaSConnector -Action BuildRequirements -Access ReadOnly -NonInteractive -Project 'test-project-alpha' -OutputDirectory $fwdOutDir
    }
    catch {
        $fwdErr = $_
    }
    Assert-True ($null -eq $fwdErr) 'Invoke-SailPointConnect forwards extra named arguments cleanly'
    $fwdArtifact = Join-Path $fwdOutDir 'aws-saas-connector-requirements.md'
    Assert-True (Test-Path -LiteralPath $fwdArtifact) 'Invoke-SailPointConnect with forwarded parameters writes expected artifact'

    # 8) Verify Connect-SailPoint* -Action Check succeeds in argument validation
    $checkPlatforms = @(
        @{ Cmd = 'Connect-SailPointAWS'; Script = 'AWS.ps1' }
        @{ Cmd = 'Connect-SailPointAzure'; Script = 'Azure.ps1' }
        @{ Cmd = 'Connect-SailPointGoogleCloud'; Script = 'Google Cloud.ps1' }
        @{ Cmd = 'Connect-SailPointDatabricks'; Script = 'Databricks.ps1' }
        @{ Cmd = 'Connect-SailPointSalesforce'; Script = 'Salesforce.ps1' }
        @{ Cmd = 'Connect-SailPointCrowdStrike'; Script = 'CrowdStrike.ps1' }
    )
    foreach ($p in $checkPlatforms) {
        $cmdInfo = Get-Command $p.Cmd
        $actionAttr = $cmdInfo.Parameters['Action'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        Assert-True ($actionAttr.ValidValues -contains 'Check') "$($p.Cmd) includes Check in Action ValidateSet"

        $scriptInfo = Get-Command (Join-Path $connectRoot $p.Script)
        $scriptActionAttr = $scriptInfo.Parameters['Action'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        Assert-True ($scriptActionAttr.ValidValues -contains 'Check') "$($p.Script) includes Check in Action ValidateSet"
    }

    # 9) OutputFormat parameter and ValidateSet verification on all connector cmdlets
    $connectorCmdlets = @(
        'Connect-SailPointAWS',
        'Connect-SailPointAzure',
        'Connect-SailPointGoogleCloud',
        'Connect-SailPointDatabricks',
        'Connect-SailPointSalesforce',
        'Connect-SailPointGitHub',
        'Connect-SailPointCrowdStrike'
    )
    foreach ($cmdletName in $connectorCmdlets) {
        $cmd = Get-Command $cmdletName -ErrorAction Stop
        Assert-True ($cmd.Parameters.ContainsKey('OutputFormat')) "$cmdletName has OutputFormat parameter"
        $paramDef = $cmd.Parameters['OutputFormat']
        $valSet = $paramDef.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
        Assert-True ($null -ne $valSet) "$cmdletName OutputFormat has ValidateSet"
        Assert-Equal 'Json,Text' (($valSet.ValidValues | Sort-Object) -join ',') "$cmdletName ValidateSet is Text,Json"
    }

    # 10) Non-interactive execution without -Project returning structured pipeline output
    $outTestDir = Join-Path $tmp 'headless-output'
    $pipelineResult = @(Connect-SailPointAWS -SaaSConnector -Access ReadOnly -Action BuildRequirements -NonInteractive -OutputDirectory $outTestDir -OutputFormat Json)
    Assert-Equal 1 $pipelineResult.Count 'Pipeline returned exactly 1 object on Stream 1 with zero stream pollution'
    Assert-True ($pipelineResult[0] -is [System.Management.Automation.PSCustomObject]) 'Result is a PSCustomObject'
    Assert-Equal 'Success' $pipelineResult[0].Status 'Status is Success'
    Assert-Equal 'BuildRequirements' $pipelineResult[0].Action 'Action is BuildRequirements'
    Assert-Equal 'AWS' $pipelineResult[0].Platform 'Platform is AWS'
    Assert-True (Test-Path -LiteralPath $pipelineResult[0].Path) 'Requirements markdown path exists'
    Assert-True ($pipelineResult[0].PSObject.Properties.Match('JsonPath').Count -gt 0) 'JsonPath property exists'
    Assert-True (Test-Path -LiteralPath $pipelineResult[0].JsonPath) 'Requirements JSON file exists'

    $jsonData = Get-Content -LiteralPath $pipelineResult[0].JsonPath -Raw | ConvertFrom-Json
    Assert-Equal 'AWS' $jsonData.platform 'JSON platform matches'
    Assert-Equal 'BuildRequirements' $jsonData.action 'JSON action matches'
    Assert-True ($jsonData.inputs.Count -gt 0) 'JSON contains inputs list'

    # 11) BuildScript action also returns structured PSCustomObject
    $scriptResult = @(Connect-SailPointAWS -SaaSConnector -Access ReadOnly -Action BuildScript -NonInteractive -OutputDirectory $outTestDir)
    Assert-Equal 1 $scriptResult.Count 'BuildScript returned exactly 1 object on Stream 1'
    Assert-Equal 'BuildScript' $scriptResult[0].Action 'Action is BuildScript'
    Assert-True (Test-Path -LiteralPath $scriptResult[0].Path) 'Build script file exists'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"
