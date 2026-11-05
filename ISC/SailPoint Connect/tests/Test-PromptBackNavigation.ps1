#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Project.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' `
    -CoreOptions @('SaaSConnector', 'CiemConnector', 'GcpEntro', 'WorkspaceEntro') -CliName 'gcloud' `
    -EntroCompanions @{
        SaaSConnector = @{ Variants = @('GcpEntro', 'WorkspaceEntro') }
    }
Register-GoogleConnectorDefinitions
Register-GoogleEntroDefinitions

# Test 1: Resolve-IntegrationWizardEntroAddon handles Esc on variant prompt by looping back to Yes/No
$script:yesNoCalls = 0
$script:choiceCalls = 0
function Mock-PromptBackFlow {
    # Redefine Read-YesNo and Read-Choice in script scope
    $script:yesNoCalls = 0
    $script:choiceCalls = 0

    function global:Read-YesNo {
        param($Prompt, $Default)
        $script:yesNoCalls++
        if ($script:yesNoCalls -eq 1) { return $true }
        return $false
    }

    function global:Read-Choice {
        param($Prompt, $Options, $Labels, $Default)
        $script:choiceCalls++
        if ($script:choiceCalls -eq 1) {
            Invoke-PromptBack
        }
        return 'GcpEntro'
    }
}

Mock-PromptBackFlow
$ctx = @{ Wizard = $true }
$connDef = Get-IntegrationWizardDefinition -Id 'google-saas-connector'
Resolve-IntegrationWizardEntroAddon -Platform 'GoogleCloud' -Context $ctx -ConnectorDefinition $connDef -Wizard

Assert-Equal 2 $script:yesNoCalls 'Read-YesNo was called twice after Esc on variants'
Assert-Equal 1 $script:choiceCalls 'Read-Choice threw PROMPT_BACK once'
Assert-True (-not $ctx['GcpEntro']) 'GcpEntro not set because user chose No on re-prompt'

# Test 2: Resolve-IntegrationWizardEntroAddon recovers and sets chosen variant on second try
$script:yesNoCalls = 0
$script:choiceCalls = 0
function global:Read-YesNo {
    param($Prompt, $Default)
    $script:yesNoCalls++
    return $true
}
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    $script:choiceCalls++
    if ($script:choiceCalls -eq 1) {
        Invoke-PromptBack
    }
    return 'GcpEntro'
}

$ctx2 = @{ Wizard = $true }
Resolve-IntegrationWizardEntroAddon -Platform 'GoogleCloud' -Context $ctx2 -ConnectorDefinition $connDef -Wizard
Assert-Equal 2 $script:yesNoCalls 'Read-YesNo called twice when user confirms Yes second time'
Assert-Equal 2 $script:choiceCalls 'Read-Choice called second time after Esc'
Assert-True ([bool]$ctx2['GcpEntro']) 'GcpEntro set after successful second try'

# Test 3: Start-IntegrationWizardFlow catches PROMPT_BACK on PickTarget without crashing
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    Invoke-PromptBack
}

$startThrown = $false
try {
    Start-IntegrationWizardFlow -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp @{} `
        -Context @{ Wizard = $true; Project = 'test-proj' } `
        -PickTarget { Invoke-PromptBack } `
        -Discover { @() } `
        -Execute { }
}
catch {
    $startThrown = $true
}
Assert-True (-not $startThrown) 'Start-IntegrationWizardFlow handles PROMPT_BACK cleanly without throwing'

# Test 4: Invoke-SailPointConnect catches PROMPT_BACK on platform menu without throwing
Import-Module (Join-Path $wizardRoot 'SailPoint.Connect.psd1') -Force
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    Invoke-PromptBack
}
$connectThrown = $false
try {
    Invoke-SailPointConnect
}
catch {
    $connectThrown = $true
}
Assert-True (-not $connectThrown) 'Invoke-SailPointConnect handles PROMPT_BACK on root menu cleanly'

Write-Host "PASS ($script:AssertionCount assertions)"
