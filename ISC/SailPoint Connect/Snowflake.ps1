#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Entro')]
    [string]$Environment,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$DisplayName,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$AccountUrl,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$EntroUser,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$NonInteractive,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Snowflake.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Snowflake' -Title 'Snowflake' -CoreOptions @('Entro') -CliName 'snow'
Register-SnowflakeEntroDefinitions

$coreHelp = [ordered]@{
    Entro = @{ Short = 'Entro'; Long = 'Entro Snowflake key-pair user integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive; Entro = [bool]$Entro; Action = $Action
    Environment = $Environment; DisplayName = $DisplayName; AccountUrl = $AccountUrl; EntroUser = $EntroUser
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $Entro) {
    Show-IntegrationWizardPlatformHelp -Platform 'Snowflake' -ScriptName 'Snowflake.ps1' -CoreOptionHelp $coreHelp
    return
}

Start-IntegrationWizardFlow -Platform 'Snowflake' -ScriptName 'Snowflake.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $context['Entro'] = $true
        Get-IntegrationWizardDefinition -Id 'snowflake-entro'
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
