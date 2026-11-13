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
    [string]$Nickname,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$DomainController,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$DcFqdn,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$Domain,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$SamAccountName,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$EnvironmentNickname,
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Production', 'Staging', 'Dev')]
    [string]$EnvironmentType,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$WorkerGroup,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutpostId,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutpostPublicKeyPath,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutpostDeploymentMode,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/ActiveDirectory.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'OnPremActiveDirectory' -Title 'On-Prem Active Directory' -CoreOptions @('Entro') -CliName 'pwsh'
Register-ActiveDirectoryEntroDefinitions

$coreHelp = [ordered]@{
    Entro = @{ Short = 'Entro'; Long = 'Entro on-prem Active Directory service account and LDAPS CA' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive; Entro = [bool]$Entro; Action = $Action
    Nickname = $Nickname; DomainController = $DomainController; DcFqdn = $DcFqdn; Domain = $Domain
    SamAccountName = $SamAccountName; EnvironmentNickname = $EnvironmentNickname; EnvironmentType = $EnvironmentType
    WorkerGroup = $WorkerGroup
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $Entro) {
    Show-IntegrationWizardPlatformHelp -Platform 'OnPremActiveDirectory' -ScriptName 'On-Prem Active Directory.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'OnPremActiveDirectory' -ScriptName 'On-Prem Active Directory.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $context['Entro'] = $true
        Get-IntegrationWizardDefinition -Id 'on-prem-active-directory-entro'
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
