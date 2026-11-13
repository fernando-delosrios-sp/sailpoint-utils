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
    Import-Module (Join-Path $defRoot 'EntroOutpost.psm1') -Force
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
    Register-EntroOutpostDefinitions
    Register-ActiveDirectoryEntroDefinitions
    Register-RemoteFileSystemEntroDefinitions
}

$catalog = Import-IntegrationWizardCatalog -Force
Assert-Equal 1 ([int]$catalog.version) 'catalog version is 1'
Assert-True ($catalog.policies.oneProductPerRun) 'one product per run'

$integrations = @(Get-IntegrationCatalogIntegrations)
Assert-True ($integrations.Count -ge 5) 'catalog lists multiple integrations'

Register-AllCatalogDefinitions

foreach ($row in @(Get-IntegrationCatalogFlatBindings)) {
    $def = Get-IntegrationWizardDefinition -Id $row.DefinitionId
    Assert-True ($null -ne $def) "definition $($row.DefinitionId) registered for $($row.IntegrationId)/$($row.Product)/$($row.VariantId)"
    Assert-Equal $row.PlatformName ([string]$def.Platform) "platform matches for $($row.DefinitionId)"
}

$azureCiem = Resolve-IntegrationCatalogBinding -IntegrationId 'azure' -Product 'ciem' -VariantId 'entra-ciem'
Assert-Equal 'Ciem' $azureCiem.ContextDefaults['Feature'] 'azure ciem binding sets Feature Ciem'
Assert-Equal 'Microsoft-Entra-CIEM' $azureCiem.FolderName 'azure ciem folder'

$gcpEntro = Resolve-IntegrationCatalogBinding -IntegrationId 'google-cloud' -Product 'entro' -VariantId 'gcp-org'
Assert-Equal 'google-gcp-entro' $gcpEntro.DefinitionId 'google gcp entro variant resolves'

$kind = Get-IntegrationCatalogCredentialKind -KindId 'entra.appClientSecret'
Assert-True ($kind.Discriminators -contains 'TenantId') 'entra kind has TenantId discriminator'

$threw = $false
try {
    Resolve-IntegrationCatalogBinding -IntegrationId 'google-cloud' -Product 'entro'
}
catch {
    $threw = $true
}
Assert-True $threw 'entro without variant throws when multiple bindings'

$azureCiemBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'azure' -Product 'ciem' -VariantId 'entra-ciem'
$legacyCiem = Get-IntegrationCatalogLegacyLaunchParameters -Binding $azureCiemBinding -Product 'ciem'
Assert-True ([bool]$legacyCiem['Connector']) 'azure ciem legacy launch uses Connector switch'
Assert-True (@($legacyCiem['Feature']) -contains 'Ciem') 'azure ciem legacy launch includes Ciem feature'

$awsFabric = Resolve-IntegrationCatalogBinding -IntegrationId 'aws' -Product 'fabric' -VariantId 'saas'
$legacyAws = Get-IntegrationCatalogLegacyLaunchParameters -Binding $awsFabric -Product 'fabric'
Assert-True ([bool]$legacyAws['SaaSConnector']) 'aws fabric legacy launch uses SaaSConnector'

$gcpEntroBinding = Resolve-IntegrationCatalogBinding -IntegrationId 'google-cloud' -Product 'entro' -VariantId 'gcp-org'
$legacyGcp = Get-IntegrationCatalogLegacyLaunchParameters -Binding $gcpEntroBinding -Product 'entro'
Assert-True ([bool]$legacyGcp['GcpEntro']) 'google gcp entro legacy launch uses GcpEntro'

Write-Host "PASS ($script:AssertionCount assertions)"
