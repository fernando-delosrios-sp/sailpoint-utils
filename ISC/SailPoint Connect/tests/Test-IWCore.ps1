#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'AWS' -Title 'AWS' -CoreOptions @('SaaSConnector', 'CiemConnector', 'Entro') -CliName 'aws' `
    -EntroCompanions @{ SaaSConnector = @{ EntroSwitch = 'Entro' } }
Register-AwsConnectorDefinitions
Register-AwsEntroDefinitions

$def = Get-IntegrationWizardDefinition -Id 'aws-saas-connector'
Assert-True ($null -ne $def) 'aws-saas-connector registered'

$ctx = @{ SaaSConnector = $true; IscExternalId = '11111111-2222-3333-4444-555555555555'; Action = 'BuildRequirements' }
$missing = Test-IntegrationWizardRequiredInputs -Definition $def -Context $ctx
Assert-True ($missing.Count -eq 0) 'IscExternalId satisfies required inputs'

$ctx2 = @{ SaaSConnector = $true; Action = 'Run' }
$missing2 = Test-IntegrationWizardRequiredInputs -Definition $def -Context $ctx2
Assert-True ($missing2 -contains 'IscExternalId') 'IscExternalId required when absent'

$compositeCtx = @{
    SaaSConnector   = $true
    Entro           = $true
    IscExternalId   = '11111111-2222-3333-4444-555555555555'
    EntroExternalId = '22222222-3333-4444-5555-666666666666'
    Method          = 'AssumeRole'
    Action          = 'BuildRequirements'
}
$plan = Resolve-IntegrationWizardPlan -Platform 'AWS' -Context $compositeCtx
Assert-True ($plan.IsComposite) 'SaaS + Entro resolves to composite plan'
Assert-True ($plan.Inputs.Name -contains 'IscExternalId') 'composite includes IscExternalId'
Assert-True ($plan.Inputs.Name -contains 'EntroExternalId') 'composite includes EntroExternalId'

$missingComposite = Test-IntegrationWizardRequiredInputs -Definition $plan -Context $compositeCtx
Assert-True ($missingComposite.Count -eq 0) 'both external IDs satisfy composite required inputs'

$compositeCtxMissing = @{ SaaSConnector = $true; Entro = $true; IscExternalId = '11111111-2222-3333-4444-555555555555'; Action = 'Run' }
$missingEntro = Test-IntegrationWizardRequiredInputs -Definition $plan -Context $compositeCtxMissing
Assert-True ($missingEntro -contains 'EntroExternalId') 'EntroExternalId required in composite when absent'

$ciemEntroThrown = $false
try {
    $null = Resolve-IntegrationWizardPlan -Platform 'AWS' -Context @{ CiemConnector = $true; Entro = $true }
}
catch {
    $ciemEntroThrown = $true
}
Assert-True $ciemEntroThrown 'CIEM + Entro rejected'

Write-Host 'PASS (10 assertions)'
