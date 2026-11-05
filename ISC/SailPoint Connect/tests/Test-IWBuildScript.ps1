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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/CrowdStrike.Connector.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-AwsConnectorDefinitions
Register-AzureConnectorDefinitions
Register-GoogleConnectorDefinitions
Register-DatabricksConnectorDefinitions
Register-SalesforceConnectorDefinitions
Register-GitHubConnectorDefinitions
Register-CrowdStrikeConnectorDefinitions

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
    Assert-True ($awsContent -like '*aws iam create-role*') 'AWS SaaS script contains aws iam create-role CLI command'
    Assert-True ($awsContent -like '*sts:AssumeRole*') 'AWS SaaS script configures sts:AssumeRole'

    # 2. Azure BuildScript
    $azDef = Get-IntegrationWizardDefinition -Id 'azure-connector'
    $azCtx = @{ ApplicationName = 'MyEntraApp'; Access = 'ReadOnly'; TenantId = 'tenant-1' }
    $azPath = Join-Path $outDir 'azure.ps1'
    New-IntegrationWizardBuildScript -Definition $azDef -Context $azCtx -OutputPath $azPath
    $azContent = Get-Content -LiteralPath $azPath -Raw
    Assert-True ($azContent -like '*az ad app create*') 'Azure script contains az ad app create CLI command'
    Assert-True ($azContent -like '*az ad sp create*') 'Azure script contains az ad sp create CLI command'

    # 3. Google Cloud BuildScript
    $gDef = Get-IntegrationWizardDefinition -Id 'google-saas-connector'
    $gCtx = @{ OrganizationId = 'org-1'; ProjectId = 'proj-1'; ImpersonateUser = 'admin@corp.com'; Access = 'ReadOnly' }
    $gPath = Join-Path $outDir 'google.ps1'
    New-IntegrationWizardBuildScript -Definition $gDef -Context $gCtx -OutputPath $gPath
    $gContent = Get-Content -LiteralPath $gPath -Raw
    Assert-True ($gContent -like '*gcloud iam service-accounts create*') 'Google script contains gcloud iam service-accounts create CLI command'
    Assert-True ($gContent -like '*gcloud services enable*') 'Google script contains gcloud services enable CLI command'

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

    # 6. CrowdStrike BuildScript
    $csDef = Get-IntegrationWizardDefinition -Id 'crowdstrike-connector'
    $csCtx = @{ BaseUrl = 'https://api.crowdstrike.com'; ClientId = 'client-xyz'; Access = 'ReadWrite'; Feature = 'Discover,IdentityProtection' }
    $csPath = Join-Path $outDir 'crowdstrike.ps1'
    New-IntegrationWizardBuildScript -Definition $csDef -Context $csCtx -OutputPath $csPath
    $csContent = Get-Content -LiteralPath $csPath -Raw
    Assert-True ($csContent -like '*oauth2/token*') 'CrowdStrike script requests OAuth2 token'
    Assert-True ($csContent -like '*devices/queries/devices-scroll*') 'CrowdStrike script queries host devices'
    Assert-True ($csContent -like '*hosts:write*') 'CrowdStrike script verifies ReadWrite containment scope'
    Assert-True ($csContent -like '*Falcon Discover*') 'CrowdStrike script configures Falcon Discover'
    Assert-True ($csContent -like '*Identity Threat Protection*') 'CrowdStrike script configures ITDR'
}
finally {
    if (Test-Path -LiteralPath $outDir) {
        Remove-Item -LiteralPath $outDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
