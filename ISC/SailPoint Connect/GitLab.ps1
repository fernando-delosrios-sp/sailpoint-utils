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
    [string]$BaseUrl,
    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('Yes', 'No')]
    [string]$SelfManaged,
    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('PersonalAccessToken', 'GroupAccessToken')]
    [string]$AuthType,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$AccessToken,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$TargetGroups,

    [Parameter(ParameterSetName = 'Entro')]
    [string]$Nickname,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$GitLabUrl,

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
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitLab.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitLab.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GitLab' -Title 'GitLab' -CoreOptions @('Connector', 'Entro') -CliName 'glab' `
    -EntroCompanions @{ Connector = @{ EntroSwitch = 'Entro' } }
Register-GitLabConnectorDefinitions
Register-GitLabEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'GitLab SaaS connector'; Long = 'GitLab PAT / group token & NHI discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro GitLab integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro; Action = $Action
    BaseUrl = $BaseUrl; SelfManaged = $SelfManaged; AuthType = $AuthType
    AccessToken = $AccessToken; TargetGroups = $TargetGroups
    Nickname = $Nickname; GitLabUrl = $GitLabUrl
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GitLab' -ScriptName 'GitLab.ps1' -CoreOptionHelp $coreHelp
    return
}

Start-IntegrationWizardFlow -Platform 'GitLab' -ScriptName 'GitLab.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('GitLab SaaS connector', 'Entro GitLab integration') -Default 'Connector'
        switch ($picked) {
            'Connector' { $context['Connector'] = $true; Get-IntegrationWizardDefinition -Id 'gitlab-connector' }
            'Entro' { $context['Entro'] = $true; Get-IntegrationWizardDefinition -Id 'gitlab-entro' }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
