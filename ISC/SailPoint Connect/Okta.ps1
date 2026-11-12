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
    [string]$OktaDomain,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$ClientId,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$TokenUrl,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$Scope,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$JwtHeader,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$PrivateKey,
    [Parameter(ParameterSetName = 'Connector')]
    [string]$PrivateKeyPassword,

    [Parameter(ParameterSetName = 'Entro')]
    [string]$Environment,
    [Parameter(ParameterSetName = 'Entro')]
    [string]$DisplayName,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Okta.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Okta.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Okta' -Title 'Okta' -CoreOptions @('Connector', 'Entro') -CliName 'okta' `
    -EntroCompanions @{ Connector = @{ EntroSwitch = 'Entro' } }
Register-OktaConnectorDefinitions
Register-OktaEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'Okta SaaS connector'; Long = 'Okta service app JWT auth & Admin API token discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro Okta integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro; Action = $Action
    OktaDomain = $OktaDomain; ClientId = $ClientId; TokenUrl = $TokenUrl; Scope = $Scope
    JwtHeader = $JwtHeader; PrivateKey = $PrivateKey; PrivateKeyPassword = $PrivateKeyPassword
    Environment = $Environment; DisplayName = $DisplayName
    OutputDirectory = $OutputDirectory; OutputFormat = $OutputFormat; Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'Okta' -ScriptName 'Okta.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'Okta' -ScriptName 'Okta.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('Okta SaaS connector (Agentic Fabric)', 'Entro Okta integration') -Default 'Connector'
        switch ($picked) {
            'Connector' { $context['Connector'] = $true; Get-IntegrationWizardDefinition -Id 'okta-connector' }
            'Entro' { $context['Entro'] = $true; Get-IntegrationWizardDefinition -Id 'okta-entro' }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
