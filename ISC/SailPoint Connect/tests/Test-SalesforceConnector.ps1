#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.SalesforceConnector.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Salesforce.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Salesforce.Entro.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-IntegrationWizardPlatform -Name 'Salesforce' -Title 'Salesforce' -CoreOptions @('Connector', 'Entro') -CliName 'sf'
Register-SalesforceConnectorDefinitions
Register-SalesforceEntroDefinitions

# 1. Verify connector definition
$def = Get-IntegrationWizardDefinition -Id 'salesforce-connector'
Assert-True ($null -ne $def) 'Salesforce connector definition is registered'
Assert-Equal 'Salesforce' $def.Platform 'Platform is Salesforce'
Assert-Equal 'Connector' $def.CoreSwitch 'Core switch is Connector'
Assert-Equal 'sf' $def.CliName 'CLI is sf'

# 2. Verify feature packs & Agentforce
$packs = Get-SalesforceFeaturePacks
Assert-True ($packs.ContainsKey('AgentDiscovery')) 'AgentDiscovery feature pack exists'
Assert-True ($packs.ContainsKey('ActivityInsights')) 'ActivityInsights feature pack exists'

$agentforce = Get-SalesforceAgentDiscoveryFeaturePack
Assert-Equal 'AgentDiscovery' $agentforce.Name 'AgentDiscovery name matches'
Assert-True ($agentforce.Label -like '*Agentforce*') 'AgentDiscovery label highlights Agentforce'

# 3. Verify checklist and connection settings
$checklist = Get-SalesforceIscFeatureChecklist -FeatureNames @('AgentDiscovery')
Assert-True (($checklist -join ' ') -like '*Agentforce*') 'Checklist includes Agentforce'
Assert-True (($checklist -join ' ') -like '*Agentic Fabric*') 'Checklist requires Agentic Fabric'

$connSettings = Build-SalesforceConnectionSettings -InstanceUrl 'https://acme.my.salesforce.com' `
    -ConsumerKey '3MVG9...key' -Username 'svc_sailpoint@acme.com' -FeatureNames @('AgentDiscovery')
Assert-True ($connSettings -like '*Instance URL: https://acme.my.salesforce.com*') 'Instance URL in connection settings'
Assert-True ($connSettings -like '*Consumer Key*: 3MVG9...key*') 'Consumer key in connection settings'
Assert-True ($connSettings -like '*Agentforce AI Agent Discovery*') 'Agentforce section included in settings'

# 4. Verify step generation
$baseCtx = @{ InstanceUrl = 'https://acme.my.salesforce.com'; ConsumerKey = 'key-1'; ConsumerSecret = 'secret-1' }
$stepsBase = @(& $def.Steps $baseCtx)
Assert-Equal 1 $stepsBase.Count 'Base connector has 1 step'
Assert-Equal 'connected-app-check' $stepsBase[0].Id 'Base step is connected app validation'

$agentCtx = @{ InstanceUrl = 'https://acme.my.salesforce.com'; ConsumerKey = 'key-1'; ConsumerSecret = 'secret-1'; Feature = 'AgentDiscovery' }
$stepsAgent = @(& $def.Steps $agentCtx)
Assert-Equal 2 $stepsAgent.Count 'AgentDiscovery adds agentforce-discovery step'
Assert-Equal 'agentforce-discovery' $stepsAgent[1].Id 'Second step is agentforce-discovery'

# 5. Run steps
$runCtx = $agentCtx.Clone()
foreach ($step in $stepsAgent) {
    $probe = & $step.Probe $runCtx
    Assert-Equal 'Skip' $probe 'Probe skips when required inputs exist'
    & $step.Run $runCtx
}
$record = Get-SalesforceRunRecord -Context $runCtx
Assert-Equal 'Verified' $record.ConnectedAppResult 'Connected app marked verified'
Assert-Equal 'Configured' $record.AgentforceResult 'Agentforce marked configured'

# 6. Verify Entro Salesforce definition
$entroDef = Get-IntegrationWizardDefinition -Id 'salesforce-entro'
Assert-True ($null -ne $entroDef) 'Entro Salesforce definition is registered'
Assert-Equal 'Entro' $entroDef.Product 'Entro definition product is Entro'
$entroSteps = @(& $entroDef.Steps @{ Environment = 'Production'; InstanceUrl = 'https://acme.my.salesforce.com' })
Assert-Equal 1 $entroSteps.Count 'Entro Salesforce has 1 step'
Assert-Equal 'entro-salesforce-app' $entroSteps[0].Id 'Entro step is entro-salesforce-app'

Write-Host "PASS ($script:AssertionCount assertions)"
