#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Catalog.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.CatalogMenu.psm1') -Force -Global

function Register-AllCatalogDefinitions {
    $defRoot = Join-Path $wizardRoot 'modules/Definitions'
    Import-Module (Join-Path $defRoot 'Aws.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Aws.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Azure.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Azure.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Google.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Google.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitHub.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitHub.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Okta.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Okta.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'CrowdStrike.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'CrowdStrike.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Slack.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Slack.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitLab.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'GitLab.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Salesforce.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Salesforce.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'Databricks.Connector.psm1') -Force
    Import-Module (Join-Path $defRoot 'Snowflake.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'ServiceNow.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'HashiCorp.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'ActiveDirectory.Entro.psm1') -Force
    Import-Module (Join-Path $defRoot 'RemoteFileSystem.Entro.psm1') -Force
    Register-AwsConnectorDefinitions
    Register-AwsEntroDefinitions
    Register-AzureConnectorDefinitions
    Register-AzureEntroDefinitions
    Register-GoogleConnectorDefinitions
    Register-GoogleEntroDefinitions
    Register-GitHubConnectorDefinitions
    Register-GitHubEntroDefinitions
    Register-OktaConnectorDefinitions
    Register-OktaEntroDefinitions
    Register-CrowdStrikeConnectorDefinitions
    Register-CrowdStrikeEntroDefinitions
    Register-SlackConnectorDefinitions
    Register-SlackEntroDefinitions
    Register-GitLabConnectorDefinitions
    Register-GitLabEntroDefinitions
    Register-SalesforceConnectorDefinitions
    Register-SalesforceEntroDefinitions
    Register-DatabricksConnectorDefinitions
    Register-SnowflakeEntroDefinitions
    Register-ServiceNowEntroDefinitions
    Register-HashiCorpEntroDefinitions
    Register-ActiveDirectoryEntroDefinitions
    Register-RemoteFileSystemEntroDefinitions
}

$catalog = Import-IntegrationWizardCatalog -Force
Assert-Equal 1 ([int]$catalog.version) 'catalog version is 1'
Assert-True (@($catalog.menuFlow) -notcontains 'Product') 'unified catalog menuFlow omits Product prompt'
Assert-True ((-not ($catalog.policies.PSObject.Properties.Name -contains 'oneProductPerRun')) -or (-not [bool]$catalog.policies.oneProductPerRun)) 'unified catalog does not enforce oneProductPerRun'

$coverages = @(Get-IntegrationCatalogProductNames)
Assert-True ($coverages -contains 'SailPoint Fabric') 'catalog includes SailPoint Fabric coverage'
Assert-True ($coverages -contains 'SailPoint Fabric (ISC)') 'catalog includes SailPoint Fabric (ISC) coverage'
Assert-True ($coverages -contains 'Entro') 'catalog includes Entro coverage'
Assert-Equal 3 $coverages.Count 'catalog uses strictly three coverage badge values'

$integrations = @(Get-IntegrationCatalogIntegrations)
Assert-True ($integrations.Count -ge 15) 'catalog lists all unified integrations'
Assert-True (@($integrations.id) -notcontains 'entro-outpost') 'entro-outpost is removed from catalog'

Register-AllCatalogDefinitions

foreach ($row in @(Get-IntegrationCatalogFlatBindings)) {
    foreach ($did in @($row.DefinitionIds)) {
        $def = Get-IntegrationWizardDefinition -Id $did
        Assert-True ($null -ne $def) "definition $did registered for $($row.IntegrationId)/$($row.VariantId)"
        Assert-Equal $row.PlatformName ([string]$def.Platform) "platform matches for $did"
    }
}

$awsBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'aws' -VariantId 'aws'
Assert-Equal 'aws-saas-connector' $awsBinding.DefinitionId 'aws primary definition is aws-saas-connector'
Assert-True (@($awsBinding.DefinitionIds) -contains 'aws-entro') 'aws binding combines aws-entro'
$legacyAws = Get-IntegrationCatalogLegacyLaunchParameters -Binding $awsBinding -Product 'SailPoint Fabric'
Assert-True ([bool]$legacyAws['SaaSConnector']) 'aws unified legacy launch sets SaaSConnector'
Assert-True ([bool]$legacyAws['Entro']) 'aws unified legacy launch sets Entro'

$azureBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'azure' -VariantId 'azure'
Assert-Equal 'Microsoft-Entra-ID' $azureBinding.FolderName 'azure unified folder'
Assert-True (@($azureBinding.DefinitionIds) -contains 'azure-connector') 'azure binding includes azure-connector'
Assert-True (@($azureBinding.DefinitionIds) -contains 'azure-entro') 'azure binding includes azure-entro'
$legacyAzure = Get-IntegrationCatalogLegacyLaunchParameters -Binding $azureBinding -Product 'SailPoint Fabric'
Assert-True ([bool]$legacyAzure['Connector']) 'azure unified legacy launch sets Connector switch'
Assert-True ([bool]$legacyAzure['Entro']) 'azure unified legacy launch sets Entro switch'

$gcpBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'google-cloud' -VariantId 'gcp'
Assert-Equal 'google-saas-connector' $gcpBinding.DefinitionId 'google gcp variant primary definition is google-saas-connector'
Assert-True (@($gcpBinding.DefinitionIds) -contains 'google-gcp-entro') 'google gcp variant combines google-gcp-entro'
$legacyGcp = Get-IntegrationCatalogLegacyLaunchParameters -Binding $gcpBinding -Product 'SailPoint Fabric'
Assert-True ([bool]$legacyGcp['SaaSConnector']) 'google gcp legacy launch uses SaaSConnector'
Assert-True ([bool]$legacyGcp['GcpEntro']) 'google gcp legacy launch uses GcpEntro'

$kind = Get-IntegrationCatalogCredentialKind -KindId 'entra.appClientSecret'
Assert-True ($kind.Discriminators -contains 'TenantId') 'entra kind has TenantId discriminator'

$threw = $false
try {
    Resolve-IntegrationCatalogBinding -IntegrationId 'google-cloud'
}
catch {
    $threw = $true
}
Assert-True $threw 'google-cloud without variant throws when multiple bindings exist'

# Negative guardrail: retired definitionIds must fail catalog validation
$badCatalog = $catalog | ConvertTo-Json -Depth 12 | ConvertFrom-Json
$badCatalog.integrations[0].bindings[0].definitionId = 'aws-ciem-connector'
$badCatalog.integrations[0].bindings[0].definitionIds = @('aws-ciem-connector')
$guardThrew = $false
try {
    Test-IntegrationWizardCatalog -Catalog $badCatalog -WizardRoot $wizardRoot | Out-Null
}
catch {
    $guardThrew = $_.Exception.Message -match 'retired definitionId'
}
Assert-True $guardThrew 'Test-IntegrationWizardCatalog rejects retired definitionIds'

Write-Host "PASS ($script:AssertionCount assertions)"
