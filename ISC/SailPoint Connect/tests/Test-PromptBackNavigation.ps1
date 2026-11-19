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
    -CoreOptions @('SaaSConnector', 'GcpEntro', 'WorkspaceEntro') -CliName 'gcloud' `
    -EntroCompanions @{
        SaaSConnector = @{ Variants = @('GcpEntro', 'WorkspaceEntro') }
    }
Register-GoogleConnectorDefinitions
Register-GoogleEntroDefinitions
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Entro.psm1') -Force
Register-AzureEntroDefinitions

# Test 1: Resolve-IntegrationWizardEntroAddon is removed in unified flow (Fabric + Entro auto-combined)
Assert-True ($null -eq (Get-Command Resolve-IntegrationWizardEntroAddon -ErrorAction SilentlyContinue)) 'Resolve-IntegrationWizardEntroAddon is removed in unified flow'

# Test 2: Collect-IntegrationWizardInputs handles Esc (PromptBack) cleanly: backing out from second prompt clears first prompt and re-asks it
$script:inputCalls = 0
function global:Read-InputString {
    param($Prompt, $Default, [switch]$Required, [switch]$Mask)
    $script:inputCalls++
    if ($script:inputCalls -eq 2) {
        Invoke-PromptBack
    }
    return "val-$($script:inputCalls)"
}
function global:Read-MultiChoice {
    param($Prompt, $Options, $Labels)
    return @()
}
function global:Read-YesNo {
    param($Prompt, $Default)
    return $true
}

$backDef = @{
    Inputs = @(
        @{ Name = 'First'; Source = 'Supply'; Prompt = 'First value'; Required = $true }
        @{ Name = 'Second'; Source = 'Supply'; Prompt = 'Second value'; Required = $true }
    )
}
$backCtx = @{ Action = 'Run' }
Collect-IntegrationWizardInputs -Definition $backDef -Context $backCtx -Wizard
Assert-Equal 4 $script:inputCalls 'Backing out at second input re-asks first then second input'
Assert-Equal 'val-3' $backCtx['First'] 'First input updated after back navigation'
Assert-Equal 'val-4' $backCtx['Second'] 'Second input collected on retry'
Remove-Item function:\global:Read-InputString -ErrorAction SilentlyContinue
Remove-Item function:\global:Read-MultiChoice -ErrorAction SilentlyContinue
Remove-Item function:\global:Read-YesNo -ErrorAction SilentlyContinue

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

Remove-Item function:\global:Read-Choice -ErrorAction SilentlyContinue

# Test 4: Invoke-SailPointConnect catches PROMPT_BACK on catalog root menu without throwing
$env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK = '1'
$env:SAILPOINT_CONNECT_TEST_CATALOG_PROMPT_BACK = '1'
Import-Module (Join-Path $wizardRoot 'SailPoint.Connect.psd1') -Force
$connectThrown = $false
try {
    Invoke-SailPointConnect -Project 'test-proj' -Action 'Run'
}
catch {
    $connectThrown = $true
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_TEST_CATALOG_PROMPT_BACK -ErrorAction SilentlyContinue
}
Assert-True (-not $connectThrown) 'Invoke-SailPointConnect handles PROMPT_BACK on catalog root menu cleanly'

# Test 5: Invoke-PromptBack throws a typed [PromptBackException]
$caughtTyped = $false
$caughtType = $null
try {
    Invoke-PromptBack
}
catch [PromptBackException] {
    $caughtTyped = $true
    $caughtType = $_.Exception.GetType().Name
}
catch {
    $caughtType = $_.Exception.GetType().Name
}
Assert-True $caughtTyped 'Invoke-PromptBack throws dedicated [PromptBackException] class'
Assert-Equal 'PromptBackException' $caughtType 'Exception type name is PromptBackException'

# Test 6: Test-PromptBack recognizes [PromptBackException] and legacy string 'PROMPT_BACK'
$exTyped = $null
try {
    Invoke-PromptBack
}
catch {
    $exTyped = $_
}
Assert-True (Test-PromptBack $exTyped) 'Test-PromptBack returns true for typed [PromptBackException] ErrorRecord'
Assert-True (Test-PromptBack $exTyped.Exception) 'Test-PromptBack returns true for typed [PromptBackException] instance'

$exLegacy = $null
try {
    throw 'PROMPT_BACK'
}
catch {
    $exLegacy = $_
}
Assert-True (Test-PromptBack $exLegacy) 'Test-PromptBack returns true for legacy string-based PROMPT_BACK'

# Test 7: Standard catch-all correctly differentiates PromptBackException from arbitrary exceptions
$otherError = $null
try {
    throw [System.InvalidOperationException]::new('Unexpected operational failure')
}
catch {
    $otherError = $_
}
# Test 8: Test-IntegrationWizardCancelled reports true when wizard is cancelled at stage 0
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Entro.psm1') -Force
Register-AzureEntroDefinitions
$azDef = Get-IntegrationWizardDefinition -Id 'azure-entro'
Assert-True ($null -ne $azDef) 'azure-entro definition exists'
$activeCheckInputs = Get-IntegrationWizardActiveInputs -Definition $azDef -Context @{ Action = 'Check' }
$activeRunInputs = Get-IntegrationWizardActiveInputs -Definition $azDef -Context @{ Action = 'Run' }
Assert-Equal 4 $activeCheckInputs.Count 'azure-entro Check inputs has 4 fields (TenantId, ClientId, ClientSecret, OutputDirectory)'
Assert-Equal 'TenantId' $activeCheckInputs[0].Name 'First active check input is TenantId'
Assert-Equal 'ClientId' $activeCheckInputs[1].Name 'Second active check input is ClientId'
Assert-Equal 'ClientSecret' $activeCheckInputs[2].Name 'Third active check input is ClientSecret'
Assert-Equal 'EnvironmentNickname' $activeRunInputs[0].Name 'Run action uses standard Inputs starting with EnvironmentNickname'

# Test 9: Start-IntegrationWizardFlow marks LastWizardCancelled when backing out at Stage 0
function global:Read-Choice {
    param($Prompt, $Options, $Labels, $Default)
    Invoke-PromptBack
}
$cancelCtx = @{ Wizard = $true; NonInteractive = $false; Action = 'Run' }
Start-IntegrationWizardFlow -Platform 'Azure' -ScriptName 'Azure.ps1' -CoreOptionHelp @{} `
    -Context $cancelCtx -PickTarget { Invoke-PromptBack } -Discover { @() } -Execute { }
Assert-True (Test-IntegrationWizardCancelled) 'Test-IntegrationWizardCancelled is true after escaping from Stage 0'

Write-Host "PASS ($script:AssertionCount assertions)"
