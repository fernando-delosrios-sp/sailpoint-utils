#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.CrowdStrikeConnector.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/CrowdStrike.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/CrowdStrike.Entro.psm1') -Force

Initialize-OperatorConsole -NonInteractive
Register-IntegrationWizardPlatform -Name 'CrowdStrike' -Title 'CrowdStrike' -CoreOptions @('Connector', 'Entro') -CliName 'falcon'
Register-CrowdStrikeConnectorDefinitions
Register-CrowdStrikeEntroDefinitions

# 1. Verify connector definition
$def = Get-IntegrationWizardDefinition -Id 'crowdstrike-connector'
Assert-True ($null -ne $def) 'CrowdStrike connector definition is registered'
Assert-Equal 'CrowdStrike' $def.Platform 'Platform is CrowdStrike'
Assert-Equal 'Connector' $def.CoreSwitch 'Core switch is Connector'
Assert-Equal 'falcon' $def.CliName 'CLI is falcon'

# 2. Verify feature packs
$packs = Get-CrowdStrikeFeaturePacks
Assert-True ($packs.ContainsKey('Discover')) 'Discover feature pack exists'
Assert-True ($packs.ContainsKey('IdentityProtection')) 'IdentityProtection feature pack exists'
Assert-True ($packs.ContainsKey('CloudSecurity')) 'CloudSecurity feature pack exists'
Assert-True ($packs.ContainsKey('RealTimeResponse')) 'RealTimeResponse feature pack exists'

$discover = $packs['Discover']
Assert-Equal 'Discover' $discover.Name 'Discover name matches'
Assert-True ($discover.Label -like '*Falcon Discover*') 'Discover label highlights Falcon Discover'

# 3. Verify checklist and connection settings
$checklist = Get-CrowdStrikeIscFeatureChecklist -FeatureNames @('Discover', 'IdentityProtection')
Assert-True (($checklist -join ' ') -like '*discover:read*') 'Checklist includes discover:read'
Assert-True (($checklist -join ' ') -like '*identity-protection:read*') 'Checklist includes identity-protection:read'

$connSettings = Build-CrowdStrikeConnectionSettings -BaseUrl 'https://api.crowdstrike.com' -ClientId 'client-xyz' -Access 'ReadWrite' -FeatureNames @('Discover')
Assert-True ($connSettings -like '*Base URL: https://api.crowdstrike.com*') 'Base URL in connection settings'
Assert-True ($connSettings -like '*Client ID: client-xyz*') 'Client ID in connection settings'
Assert-True ($connSettings -like '*Access Level: ReadWrite*') 'Access Level in connection settings'
Assert-True ($connSettings -like '*hosts:write*') 'ReadWrite includes hosts:write'
Assert-True ($connSettings -like '*discover:read*') 'Settings include discover:read'

# 4. Verify step generation
$baseCtx = @{ BaseUrl = 'https://api.crowdstrike.com'; ClientId = 'client-xyz'; Access = 'ReadOnly' }
$stepsBase = @(& $def.Steps $baseCtx)
Assert-Equal 1 $stepsBase.Count 'Base connector has 1 step'
Assert-Equal 'crowdstrike-auth-check' $stepsBase[0].Id 'Base step is crowdstrike-auth-check'

$featureCtx = @{ BaseUrl = 'https://api.crowdstrike.com'; ClientId = 'client-xyz'; Access = 'ReadWrite'; Feature = 'Discover,IdentityProtection,CloudSecurity,RealTimeResponse' }
$stepsFeature = @(& $def.Steps $featureCtx)
Assert-Equal 5 $stepsFeature.Count 'All 4 feature packs add steps'
Assert-Equal 'crowdstrike-auth-check' $stepsFeature[0].Id 'Step 0 is auth check'
Assert-Equal 'crowdstrike-discover' $stepsFeature[1].Id 'Step 1 is discover'
Assert-Equal 'crowdstrike-identity-protection' $stepsFeature[2].Id 'Step 2 is identity protection'
Assert-Equal 'crowdstrike-cloud-security' $stepsFeature[3].Id 'Step 3 is cloud security'
Assert-Equal 'crowdstrike-rtr' $stepsFeature[4].Id 'Step 4 is rtr'

# 5. Run steps probe
$runCtx = $featureCtx.Clone()
foreach ($step in $stepsFeature) {
    $probe = & $step.Probe $runCtx
    Assert-Equal 'Skip' $probe "Probe skips when required inputs exist ($($step.Id))"
    & $step.Run $runCtx
}
$record = Get-CrowdStrikeRunRecord -Context $runCtx
Assert-Equal 'Verified' $record.AuthResult 'Auth marked verified'
Assert-Equal 'Configured' $record.DiscoverResult 'Discover marked configured'
Assert-Equal 'Configured' $record.IdentityProtResult 'IdentityProtection marked configured'
Assert-Equal 'Configured' $record.CloudSecResult 'CloudSecurity marked configured'
Assert-Equal 'Configured' $record.RtrResult 'RealTimeResponse marked configured'

# 6. Verify Entro CrowdStrike definition
$entroDef = Get-IntegrationWizardDefinition -Id 'crowdstrike-entro'
Assert-True ($null -ne $entroDef) 'Entro CrowdStrike definition is registered'
Assert-Equal 'Entro' $entroDef.Product 'Entro definition product is Entro'
$entroSteps = @(& $entroDef.Steps @{ Environment = 'prod-falcon'; ClientId = 'client-xyz' })
Assert-Equal 1 $entroSteps.Count 'Entro CrowdStrike has 1 step'
Assert-Equal 'entro-crowdstrike-client' $entroSteps[0].Id 'Entro step is entro-crowdstrike-client'

Write-Host "PASS ($script:AssertionCount assertions)"
