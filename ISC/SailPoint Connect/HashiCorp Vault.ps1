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
    [string]$VaultUrl,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/HashiCorp.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'HashiCorpVault' -Title 'HashiCorp Vault' -CoreOptions @('Entro') -CliName 'vault'
Register-HashiCorpEntroDefinitions

$coreHelp = [ordered]@{
    Entro = @{ Short = 'Entro'; Long = 'Entro HashiCorp Vault policy and token integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive; Entro = [bool]$Entro; Action = $Action
    Environment = $Environment; VaultUrl = $VaultUrl
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $Entro) {
    Show-IntegrationWizardPlatformHelp -Platform 'HashiCorpVault' -ScriptName 'HashiCorp Vault.ps1' -CoreOptionHelp $coreHelp
    return
}

Start-IntegrationWizardFlow -Platform 'HashiCorpVault' -ScriptName 'HashiCorp Vault.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $context['Entro'] = $true
        Get-IntegrationWizardDefinition -Id 'hashicorp-vault-entro'
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
