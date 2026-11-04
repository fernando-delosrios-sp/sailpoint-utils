#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.GitHubConnector.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Entro.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro') -CliName 'gh'
Register-GitHubConnectorDefinitions
Register-GitHubEntroDefinitions

# 1. Verify connector definition
$def = Get-IntegrationWizardDefinition -Id 'github-connector'
Assert-True ($null -ne $def) 'GitHub connector definition is registered'
Assert-Equal 'GitHub' $def.Platform 'Platform is GitHub'
Assert-Equal 'Connector' $def.CoreSwitch 'Core switch is Connector'
Assert-Equal 'gh' $def.CliName 'CLI is gh'

# 2. Verify feature packs & Copilot/AgentDiscovery
$packs = Get-GitHubFeaturePacks
Assert-True ($packs.ContainsKey('AgentDiscovery')) 'AgentDiscovery feature pack exists'
Assert-True ($packs.ContainsKey('ActivityInsights')) 'ActivityInsights feature pack exists'

$copilot = Get-GitHubAgentDiscoveryFeaturePack
Assert-Equal 'AgentDiscovery' $copilot.Name 'AgentDiscovery name matches'
Assert-True ($copilot.Label -like '*Copilot*') 'AgentDiscovery label highlights Copilot'

# 3. Verify checklist and connection settings
$checklist = Get-GitHubIscFeatureChecklist -FeatureNames @('AgentDiscovery')
Assert-True (($checklist -join ' ') -like '*Copilot*') 'Checklist includes Copilot'
Assert-True (($checklist -join ' ') -like '*Agentic Fabric*') 'Checklist requires Agentic Fabric'

$connSettings = Build-GitHubConnectionSettings -Organization 'acme-corp' -AuthMethod 'PersonalAccessToken' -FeatureNames @('AgentDiscovery')
Assert-True ($connSettings -like '*Organization: acme-corp*') 'Organization in connection settings'
Assert-True ($connSettings -like '*Machine Identity & Agent Discovery*') 'Agent discovery section in settings'

# 4. Verify step generation
$baseCtx = @{ Organization = 'acme-corp'; AuthMethod = 'PersonalAccessToken' }
$stepsBase = @(& $def.Steps $baseCtx)
Assert-Equal 1 $stepsBase.Count 'Base connector has 1 step'
Assert-Equal 'github-auth-check' $stepsBase[0].Id 'Base step is github-auth-check'

$agentCtx = @{ Organization = 'acme-corp'; AuthMethod = 'PersonalAccessToken'; Feature = 'AgentDiscovery' }
$stepsAgent = @(& $def.Steps $agentCtx)
Assert-Equal 2 $stepsAgent.Count 'AgentDiscovery adds copilot/bot step'
Assert-Equal 'github-copilot-bot-discovery' $stepsAgent[1].Id 'Second step is github-copilot-bot-discovery'

# 5. Run steps
$runCtx = $agentCtx.Clone()
foreach ($step in $stepsAgent) {
    $probe = & $step.Probe $runCtx
    Assert-Equal 'Skip' $probe 'Probe skips when required inputs exist'
    & $step.Run $runCtx
}
$record = Get-GitHubRunRecord -Context $runCtx
Assert-Equal 'Verified' $record.AuthResult 'Auth marked verified'
Assert-Equal 'Configured' $record.AgentDiscovery 'AgentDiscovery marked configured'

# 6. Verify Entro GitHub definition
$entroDef = Get-IntegrationWizardDefinition -Id 'github-entro'
Assert-True ($null -ne $entroDef) 'Entro GitHub definition is registered'
Assert-Equal 'Entro' $entroDef.Product 'Entro definition product is Entro'
$entroSteps = @(& $entroDef.Steps @{ Organization = 'acme-corp'; Method = 'GitHubApp' })
Assert-Equal 1 $entroSteps.Count 'Entro GitHub has 1 step'
Assert-Equal 'entro-github-onboard' $entroSteps[0].Id 'Entro step is entro-github-onboard'

Write-Host "PASS ($script:AssertionCount assertions)"
