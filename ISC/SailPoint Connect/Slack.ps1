#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Connector', Mandatory)]
    [switch]$Connector,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$WorkspaceName,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$BotUserOAuthToken,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$UserOAuthToken,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$NonInteractive,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$Project,
    [string]$CatalogIntegrationId,
    [string]$CatalogProduct,
    [string]$CatalogVariantId,
    [string]$CatalogCredentialKind,
    [ValidateSet('CreateNew', 'UpdateExisting')]
    [string]$CatalogReuseMode = 'CreateNew',
    [string]$CatalogCredentialId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Slack.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Slack.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Slack' -Title 'Slack' -CoreOptions @('Connector', 'Entro') -CliName 'slack' `
    -EntroCompanions @{ Connector = @{ EntroSwitch = 'Entro' } }
Register-SlackConnectorDefinitions
Register-SlackEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'Slack SaaS connector'; Long = 'Slack workspace app & token discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro Slack private app integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro; Action = $Action
    WorkspaceName = $WorkspaceName; BotUserOAuthToken = $BotUserOAuthToken; UserOAuthToken = $UserOAuthToken
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'Slack' -ScriptName 'Slack.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'Slack' -ScriptName 'Slack.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('Slack SaaS connector (Agentic Fabric)', 'Entro Slack integration') -Default 'Connector'
        switch ($picked) {
            'Connector' { $context['Connector'] = $true; Get-IntegrationWizardDefinition -Id 'slack-connector' }
            'Entro' { $context['Entro'] = $true; Get-IntegrationWizardDefinition -Id 'slack-entro' }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
