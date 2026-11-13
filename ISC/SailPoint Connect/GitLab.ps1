#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Connector', Mandatory)]
    [switch]$Connector,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'GitLabSelfManaged', Mandatory)]
    [switch]$GitLabSelfManaged,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
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
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$Nickname,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$GitLabUrl,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [ValidateSet('Group', 'Personal')]
    [string]$TokenKind,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$GroupPath,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$Username,
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$TokenExpires,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$WorkerGroup,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$OutpostId,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$OutpostPublicKeyPath,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$OutpostDeploymentMode,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [switch]$NonInteractive,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GitLabSelfManaged')]
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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitLab.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitLab.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GitLab' -Title 'GitLab' -CoreOptions @('Connector', 'Entro', 'GitLabSelfManaged') -CliName 'glab' `
    -EntroCompanions @{ Connector = @{ EntroSwitch = 'Entro' } }
Register-GitLabConnectorDefinitions
Register-GitLabEntroDefinitions

$coreHelp = [ordered]@{
    Connector          = @{ Short = 'GitLab SaaS connector'; Long = 'GitLab PAT / group token & NHI discovery' }
    Entro              = @{ Short = 'Entro'; Long = 'Entro GitLab (gitlab.com)' }
    GitLabSelfManaged  = @{ Short = 'Self-managed'; Long = 'Entro GitLab self-managed (requires an Outpost)' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro; GitLabSelfManaged = [bool]$GitLabSelfManaged; Action = $Action
    BaseUrl = $BaseUrl; SelfManaged = $SelfManaged; AuthType = $AuthType
    AccessToken = $AccessToken; TargetGroups = $TargetGroups
    Nickname = $Nickname; GitLabUrl = $GitLabUrl; TokenKind = $TokenKind
    GroupPath = $GroupPath; Username = $Username; TokenExpires = $TokenExpires
    WorkerGroup = $WorkerGroup
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

$hasCore = $Connector -or $Entro -or $GitLabSelfManaged
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GitLab' -ScriptName 'GitLab.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'GitLab' -ScriptName 'GitLab.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro', 'GitLabSelfManaged') `
            -Labels @(
                'GitLab SaaS connector',
                'Entro GitLab (gitlab.com)',
                'Entro GitLab self-managed [Requires Outpost]'
            ) -Default 'Connector'
        switch ($picked) {
            'Connector' { $context['Connector'] = $true; Get-IntegrationWizardDefinition -Id 'gitlab-connector' }
            'Entro' { $context['Entro'] = $true; Get-IntegrationWizardDefinition -Id 'gitlab-entro' }
            'GitLabSelfManaged' { $context['GitLabSelfManaged'] = $true; Get-IntegrationWizardDefinition -Id 'gitlab-selfmanaged-entro' }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
