#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'AWS' -Title 'AWS' -CoreOptions @('SaaSConnector', 'Entro') -CliName 'aws' `
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

$awsFeature = @($def.Inputs | Where-Object { $_.Name -eq 'Feature' })[0]
Assert-True ($null -ne $awsFeature -and $awsFeature.Options -contains 'Ciem') 'CIEM is exposed as a selectable Feature on aws-saas-connector'

Assert-Equal 'Run: aws login  (or aws sso login / aws configure)' (Get-IntegrationWizardLoginHint -CliName 'aws') 'aws login hint points to aws login, sso, and configure'

# Test MultiChoice inputs
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Connector.psm1') -Force
Register-AzureConnectorDefinitions
$azureDef = Get-IntegrationWizardDefinition -Id 'azure-connector'
Assert-True ($null -ne $azureDef) 'azure-connector registered'
$azureFeatureInput = @($azureDef.Inputs | Where-Object { $_.Name -eq 'Feature' })[0]
Assert-True ($null -ne $azureFeatureInput) 'Feature input exists in azure-connector'
Assert-True ($azureFeatureInput.MultiChoice) 'Feature input has MultiChoice enabled'
Assert-True ($azureFeatureInput.Options -contains 'CopilotDiscovery') 'Feature options include CopilotDiscovery'
Assert-True ($azureFeatureInput.Options -contains 'Agent365') 'Feature options include Agent365'
Assert-True ($azureFeatureInput.Options -contains 'AccessPackages') 'Feature options include AccessPackages'

# Test Collect-IntegrationWizardInputs with MultiChoice
$script:MultiChoiceCalled = $false
function global:Read-MultiChoice {
    param($Options, $Prompt, $Labels)
    $script:MultiChoiceCalled = $true
    return @('CopilotDiscovery', 'Agent365')
}
$mockDef = @{
    Inputs = @(
        @{
            Name        = 'Feature'
            Source      = 'Supply'
            Prompt      = 'Feature packs'
            Required    = $false
            MultiChoice = $true
            Options     = @('CopilotDiscovery', 'Agent365', 'MfaManagement')
            Labels      = @('Copilot', 'Agent365', 'MFA')
        }
    )
}
$testCtx = @{ Action = 'Run' }
Collect-IntegrationWizardInputs -Definition $mockDef -Context $testCtx -Wizard
Assert-True $script:MultiChoiceCalled 'Read-MultiChoice was invoked for MultiChoice input'
Assert-Equal 'CopilotDiscovery,Agent365' $testCtx['Feature'] 'MultiChoice selections saved as comma-separated string'
Remove-Item function:\global:Read-MultiChoice -ErrorAction SilentlyContinue

Write-Host 'PASS (19 assertions)'
