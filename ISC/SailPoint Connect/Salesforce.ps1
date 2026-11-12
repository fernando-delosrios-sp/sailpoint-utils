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

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$InstanceUrl,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$LoginUrl,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$ConsumerKey,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$ConsumerSecret,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$Username,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('AgentDiscovery', 'ActivityInsights')]
    [string[]]$Feature,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'Connector')]
    [string]$Environment,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Salesforce.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Salesforce.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'Salesforce' -Title 'Salesforce' -CoreOptions @('Connector', 'Entro') -CliName 'sf' `
    -EntroCompanions @{
        Connector = @{ EntroSwitch = 'Entro' }
    }
Register-SalesforceConnectorDefinitions
Register-SalesforceEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'Salesforce SaaS connector'; Long = 'Salesforce SaaS connector Connected App & Agentforce discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro Salesforce integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro
    Access = $Access; Action = $Action
    InstanceUrl = $InstanceUrl; LoginUrl = $LoginUrl
    ConsumerKey = $ConsumerKey; ConsumerSecret = $ConsumerSecret
    Username = $Username; Feature = if ($Feature) { ($Feature -join ',') } else { $null }
    Environment = $Environment; OutputDirectory = $OutputDirectory
    OutputFormat = $OutputFormat
    Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'Salesforce' -ScriptName 'Salesforce.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'Salesforce' -ScriptName 'Salesforce.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('Salesforce SaaS connector (with Agentforce)', 'Entro Salesforce integration') -Default 'Connector'
        switch ($picked) {
            'Connector' {
                $context['Connector'] = $true
                Get-IntegrationWizardDefinition -Id 'salesforce-connector'
            }
            'Entro' {
                $context['Entro'] = $true
                Get-IntegrationWizardDefinition -Id 'salesforce-entro'
            }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
