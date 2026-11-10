#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Connector', Mandatory)]
    [switch]$Connector,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('Aws', 'Azure', 'Gcp')]
    [string]$Cloud,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('DatabricksM2M', 'Entra')]
    [string]$Auth,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$ServicePrincipalName,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$AccountId,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$MetastoreId,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('AgentDiscovery')]
    [string[]]$Feature,

    [Parameter(ParameterSetName = 'Connector')]
    [switch]$RotateSecret,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Databricks.Connector.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Databricks' -Title 'Databricks' -CoreOptions @('Connector') -CliName 'databricks'
Register-DatabricksConnectorDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'Databricks connector'; Long = 'Databricks SaaS connector service principal' }
}
$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive; Connector = [bool]$Connector
    Cloud = $Cloud; Auth = $Auth; Action = $Action
    ServicePrincipalName = $ServicePrincipalName; AccountId = $AccountId; MetastoreId = $MetastoreId
    Feature = if ($Feature) { ($Feature -join ',') } else { $null }
    RotateSecret = [bool]$RotateSecret; OutputDirectory = $OutputDirectory
    Project = $Project
}
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $Connector) {
    Show-IntegrationWizardPlatformHelp -Platform 'Databricks' -ScriptName 'Databricks.ps1' -CoreOptionHelp $coreHelp
    return
}
Start-IntegrationWizardFlow -Platform 'Databricks' -ScriptName 'Databricks.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $context['Connector'] = $true
        Get-IntegrationWizardDefinition -Id 'databricks-connector'
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
