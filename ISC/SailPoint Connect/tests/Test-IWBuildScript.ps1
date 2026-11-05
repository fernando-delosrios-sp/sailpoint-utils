#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Databricks.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Salesforce.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Connector.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-AwsConnectorDefinitions
Register-AzureConnectorDefinitions
Register-GoogleConnectorDefinitions
Register-DatabricksConnectorDefinitions
Register-SalesforceConnectorDefinitions
Register-GitHubConnectorDefinitions

$tempRoot = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$outDir = Join-Path $tempRoot ("iw-buildscript-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

try {
    # 1. AWS SaaS BuildScript
    $awsDef = Get-IntegrationWizardDefinition -Id 'aws-saas-connector'
    $awsCtx = @{ IscExternalId = 'ext-123'; Access = 'ReadOnly'; RoleName = 'SailPointAWSRole'; Region = 'us-east-1' }
    $awsPath = Join-Path $outDir 'aws-saas.ps1'
    New-IntegrationWizardBuildScript -Definition $awsDef -Context $awsCtx -OutputPath $awsPath
    $awsContent = Get-Content -LiteralPath $awsPath -Raw
    Assert-True ($awsContent -like '*AWS.ps1*') 'AWS SaaS script contains AWS.ps1 invocation'
    Assert-True ($awsContent -like '*-SaaSConnector*') 'AWS SaaS script passes -SaaSConnector'

    # 2. Azure BuildScript
    $azDef = Get-IntegrationWizardDefinition -Id 'azure-connector'
    $azCtx = @{ ApplicationName = 'MyEntraApp'; Access = 'ReadOnly'; TenantId = 'tenant-1' }
    $azPath = Join-Path $outDir 'azure.ps1'
    New-IntegrationWizardBuildScript -Definition $azDef -Context $azCtx -OutputPath $azPath
    $azContent = Get-Content -LiteralPath $azPath -Raw
    Assert-True ($azContent -like '*Azure.ps1*') 'Azure script contains Azure.ps1 invocation'
    Assert-True ($azContent -like '*-ApplicationName ''MyEntraApp''*') 'Azure script passes application name'

    # 3. Google Cloud BuildScript
    $gDef = Get-IntegrationWizardDefinition -Id 'google-saas-connector'
    $gCtx = @{ OrganizationId = 'org-1'; ProjectId = 'proj-1'; ImpersonateUser = 'admin@corp.com'; Access = 'ReadOnly' }
    $gPath = Join-Path $outDir 'google.ps1'
    New-IntegrationWizardBuildScript -Definition $gDef -Context $gCtx -OutputPath $gPath
    $gContent = Get-Content -LiteralPath $gPath -Raw
    Assert-True ($gContent -like '*Google Cloud.ps1*') 'Google script contains Google Cloud.ps1 invocation'

    # 4. Salesforce BuildScript
    $sfDef = Get-IntegrationWizardDefinition -Id 'salesforce-connector'
    $sfCtx = @{ InstanceUrl = 'https://acme.my.salesforce.com'; ConsumerKey = 'key-1'; ConsumerSecret = 'sec-1'; Feature = 'AgentDiscovery' }
    $sfPath = Join-Path $outDir 'salesforce.ps1'
    New-IntegrationWizardBuildScript -Definition $sfDef -Context $sfCtx -OutputPath $sfPath
    $sfContent = Get-Content -LiteralPath $sfPath -Raw
    Assert-True ($sfContent -like '*Validating Salesforce Connected App*') 'Salesforce script validates connected app'
    Assert-True ($sfContent -like '*Agentforce*') 'Salesforce script configures Agentforce'

    # 5. GitHub BuildScript
    $ghDef = Get-IntegrationWizardDefinition -Id 'github-connector'
    $ghCtx = @{ Organization = 'acme-corp'; Feature = 'AgentDiscovery' }
    $ghPath = Join-Path $outDir 'github.ps1'
    New-IntegrationWizardBuildScript -Definition $ghDef -Context $ghCtx -OutputPath $ghPath
    $ghContent = Get-Content -LiteralPath $ghPath -Raw
    Assert-True ($ghContent -like '*Validating GitHub organization*') 'GitHub script validates org'
    Assert-True ($ghContent -like '*Copilot*') 'GitHub script configures Copilot'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
