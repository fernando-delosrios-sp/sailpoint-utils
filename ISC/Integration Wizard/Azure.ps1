#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$Wizard,

    # There is no separate "Combined" set. -Connector plus -Entro resolves to the Connector set,
    # which lists the Entro switch and inputs as optional (see AWS.ps1 for the reasoning).
    [Parameter(ParameterSetName = 'Connector', Mandatory)]
    [switch]$Connector,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$TenantId,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$ApplicationName,
    [Parameter(ParameterSetName = 'Connector')]
    [string[]]$Feature,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'Connector')]
    [string]$EnvironmentNickname,
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$NonInteractive,
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$RotateSecret,

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Azure' -Title 'Azure' -CoreOptions @('Connector', 'Entro') -CliName 'az' `
    -EntroCompanions @{
        Connector = @{ EntroSwitch = 'Entro' }
    }
Register-AzureConnectorDefinitions
Register-AzureEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'Entra ID connector'; Long = 'Microsoft Entra ID connector application' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro Microsoft ecosystem integration' }
}
$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro
    Access = $Access; Action = $Action
    TenantId = $TenantId; ApplicationName = $ApplicationName; Feature = $Feature
    EnvironmentNickname = $EnvironmentNickname; OutputDirectory = $OutputDirectory; RotateSecret = [bool]$RotateSecret
    Project = $Project
}
$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'Azure' -ScriptName 'Azure.ps1' -CoreOptionHelp $coreHelp
    return
}
Start-IntegrationWizardFlow -Platform 'Azure' -ScriptName 'Azure.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('Microsoft Entra ID connector', 'Entro Microsoft ecosystem') -Default 'Connector'
        if ($picked -eq 'Connector') {
            $context.Connector = $true
            return Get-IntegrationWizardDefinition -Id 'azure-connector'
        }
        $context.Entro = $true
        Get-IntegrationWizardDefinition -Id 'azure-entro'
    } `
    -Discover {
        param($name, $ctx)
        if ($name -eq 'ApplicationName') {
            $json = az ad app list --display-name '' --query "[].displayName" -o json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) { return @($json | ConvertFrom-Json) }
        }
        @()
    } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx -WhatIf:$WhatIfPreference }
