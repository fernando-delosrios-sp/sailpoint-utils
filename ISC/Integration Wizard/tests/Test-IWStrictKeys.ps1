#Requires -Version 7
# Regression: the wizard engine runs under Set-StrictMode -Version Latest, where dot-access to a
# missing hashtable key throws PropertyNotFoundException. Definitions and contexts are bags of
# optional keys, so every optional read must use indexer access (['Key']).
# This test drives the real wizard flow with prompts answered by stubs, so the code paths that
# used to throw (Google Entro -Wizard, Google Workspace connector -Wizard with Entro declined) are exercised.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force

# Prompt stubs (defined after the console import so they override the interactive readers).
# Choices take their default, typed input is a fixed value, and the "Also configure Entro?"
# question is declined so the Google Workspace connector path stays on a single target.
$script:ConnectionChoice = 'UseSession'
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    # Pin the connection choice so the test does not depend on this machine's gcloud sign-in state.
    if ($Prompt -eq 'How do you want to connect?') {
        $script:ConnectionOptions = @($Options)
        return $script:ConnectionChoice
    }
    if ($Default) { return $Default }
    return @($Options)[0]
}
function global:Read-InputString {
    param($Prompt, $Default, [switch]$Required)
    if ($Default) { return $Default }
    return 'typed-value'
}
function global:Read-YesNo {
    param($Prompt, $Default)
    if ($Prompt -like 'Also configure Entro*') { return $false }
    return $true
}

Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' `
    -CoreOptions @('SaaSConnector', 'CiemConnector', 'GcpEntro', 'WorkspaceEntro') -CliName 'gcloud' `
    -EntroCompanions @{ SaaSConnector = @{ Variants = @('GcpEntro', 'WorkspaceEntro') } }
Register-GoogleConnectorDefinitions
Register-GoogleEntroDefinitions

$coreHelp = [ordered]@{
    SaaSConnector  = @{ Short = 'Workspace connector'; Long = 'Google Workspace connector' }
    GcpEntro       = @{ Short = 'GCP Entro'; Long = 'Entro Google GCP organization integration' }
}
$noDiscover = { param($name, $ctx) @() }

# 1) Google Entro via -Wizard: the exact path from the reported error
#    (ValidateSet-less discover inputs, then the Method ValidateSet input).
$script:Executed = $null
$ctx = @{
    Wizard = $true; NonInteractive = $false
    SaaSConnector = $false; CiemConnector = $false; GcpEntro = $true; WorkspaceEntro = $false
    Access = $null; Action = $null; OrganizationId = $null; ProjectId = $null
    ImpersonateUser = $null; Method = $null; ClientId = $null; OutputDirectory = $null
}
Start-IntegrationWizardFlow -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp -Context $ctx `
    -Discover $noDiscover `
    -Execute { param($def, $c) $script:Executed = @{ Def = $def; Ctx = $c } }

Assert-True ($null -ne $script:Executed) 'GCP Entro -Wizard reaches execute'
Assert-Equal 'google-gcp-entro' $script:Executed.Def.Id 'GCP Entro -Wizard resolves the Entro definition'
Assert-Equal 'PrivateKey' $script:Executed.Ctx['Method'] 'Method ValidateSet input collected'
Assert-Equal 'typed-value' $script:Executed.Ctx['OrganizationId'] 'discover input without ValidateSet falls back to typed input'
Assert-Equal 'entro-automatic-onboard' $script:Executed.Ctx['ServiceAccountName'] 'optional input default applied'

# 2) Google Workspace connector via -Wizard with Entro declined: exercises the Entro addon
#    companion (which has no EntroSwitch key) and the PickTarget branch.
$script:Executed = $null
$ctx2 = @{
    Wizard = $true; NonInteractive = $false
    SaaSConnector = $false; CiemConnector = $false; GcpEntro = $false; WorkspaceEntro = $false
    Access = $null; Action = $null; OrganizationId = $null; ProjectId = $null
    ImpersonateUser = $null; Method = $null; ClientId = $null; OutputDirectory = $null
}
$pickSaas = {
    $ctx2['SaaSConnector'] = $true
    Get-IntegrationWizardDefinition -Id 'google-saas-connector'
}
Start-IntegrationWizardFlow -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp -Context $ctx2 `
    -PickTarget $pickSaas -Discover $noDiscover `
    -Execute { param($def, $c) $script:Executed = @{ Def = $def; Ctx = $c } }

Assert-True ($null -ne $script:Executed) 'Google Workspace connector -Wizard reaches execute'
Assert-Equal 'google-saas-connector' $script:Executed.Def.Id 'Google Workspace connector resolves its definition'
Assert-Equal 'typed-value' $script:Executed.Ctx['ImpersonateUser'] 'SaaS required input collected'

# 2b) Combined SaaS + GCP Entro: one composite plan, shared inputs merged once (no purpose collision).
$combined = Resolve-IntegrationWizardPlan -Platform 'GoogleCloud' -Context @{ SaaSConnector = $true; GcpEntro = $true }
Assert-True ([bool]$combined['IsComposite']) 'SaaS + GCP Entro resolves to a composite plan'
Assert-Equal 1 @($combined.Inputs | Where-Object { $_.Name -eq 'OrganizationId' }).Count 'shared OrganizationId input merged once'

# 2c) Every combinable ISC + Entro pair merges without an input-name collision.
#     (Shared input names must have the same Purpose, see Merge-IntegrationWizardDefinitions.)
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Entro.psm1') -Force
Register-AwsConnectorDefinitions
Register-AwsEntroDefinitions
Register-AzureConnectorDefinitions
Register-AzureEntroDefinitions
$pairs = @(
    @{ Label = 'AWS SaaS + Entro'; Platform = 'AWS'; Context = @{ SaaSConnector = $true; Entro = $true } }
    @{ Label = 'Azure Connector + Entro'; Platform = 'Azure'; Context = @{ Connector = $true; Entro = $true } }
    @{ Label = 'Google SaaS + GCP Entro'; Platform = 'GoogleCloud'; Context = @{ SaaSConnector = $true; GcpEntro = $true } }
    @{ Label = 'Google SaaS + Workspace Entro'; Platform = 'GoogleCloud'; Context = @{ SaaSConnector = $true; WorkspaceEntro = $true } }
)
foreach ($pair in $pairs) {
    $pairPlan = Resolve-IntegrationWizardPlan -Platform $pair.Platform -Context $pair.Context
    Assert-True ([bool]$pairPlan['IsComposite']) "$($pair.Label) resolves to a composite plan"
}

# 3) Requirements document build for a definition with no composite/legacy keys.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("iw-strictkeys-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$entroDef = Get-IntegrationWizardDefinition -Id 'google-gcp-entro'
$reqCtx = @{ Action = 'BuildRequirements'; OutputDirectory = $tmp; Method = 'PrivateKey'; OrganizationId = '1'; ProjectId = 'p' }
Invoke-IntegrationWizardAction -Definition $entroDef -Context $reqCtx
$reqFile = Join-Path $tmp 'google-gcp-entro-requirements.md'
Assert-True (Test-Path $reqFile) 'requirements doc written for Entro definition'
Remove-Item $tmp -Recurse -Force

# 4) Summary and missing-input checks on definitions without optional keys.
$missing = Test-IntegrationWizardRequiredInputs -Definition $entroDef -Context @{ OrganizationId = '1' }
Assert-True ($missing -contains 'ProjectId') 'required input reported missing without throwing'

# 5) Connection choices: "Use this session" only when a usable session exists.
$script:ConnectionChoice = $null
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    if ($Prompt -eq 'How do you want to connect?') { $script:ConnectionOptions = @($Options) }
    if ($Default) { return $Default }
    return @($Options)[0]
}
$unsigned = @{ Installed = $true; SignedIn = $false; Summary = 'credentials expired' }
$unsignedMode = Resolve-IntegrationWizardConnectionChoice -CliName 'gcloud' -SessionState $unsigned -Wizard
Assert-Equal 'SignIn' $unsignedMode 'unsigned session defaults to sign in'
Assert-True (@($script:ConnectionOptions) -notcontains 'UseSession') 'unsigned session hides Use this session'
$signed = @{ Installed = $true; SignedIn = $true; Summary = 'account a project p' }
$signedMode = Resolve-IntegrationWizardConnectionChoice -CliName 'gcloud' -SessionState $signed -Wizard
Assert-Equal 'UseSession' $signedMode 'signed-in session defaults to this session'
Assert-True (@($script:ConnectionOptions) -contains 'UseSession') 'signed-in session offers Use this session'

Write-Host 'PASS (20 assertions)'
