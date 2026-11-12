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
    [string]$Organization,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$ApiUrl,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('PersonalAccessToken', 'GitHubApp')]
    [string]$AuthMethod,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$Token,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$AppId,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$InstallationId,

    [Parameter(ParameterSetName = 'Connector')]
    [string]$PrivateKey,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('AgentDiscovery', 'ActivityInsights')]
    [string[]]$Feature,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('GitHubApp', 'ClassicPAT')]
    [string]$Method,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/GitHub.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro') -CliName 'gh' `
    -EntroCompanions @{
        Connector = @{ EntroSwitch = 'Entro' }
    }
Register-GitHubConnectorDefinitions
Register-GitHubEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'GitHub SaaS connector'; Long = 'GitHub SaaS connector & Copilot/Bot discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro GitHub integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro
    Access = $Access; Action = $Action
    Organization = $Organization; ApiUrl = $ApiUrl
    AuthMethod = $AuthMethod; Token = $Token; AppId = $AppId; InstallationId = $InstallationId; PrivateKey = $PrivateKey
    Feature = if ($Feature) { ($Feature -join ',') } else { $null }
    Method = $Method; OutputDirectory = $OutputDirectory
    OutputFormat = $OutputFormat
    Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GitHub' -ScriptName 'GitHub.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'GitHub' -ScriptName 'GitHub.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('GitHub SaaS connector (with Copilot/Bot discovery)', 'Entro GitHub integration') -Default 'Connector'
        switch ($picked) {
            'Connector' {
                $context['Connector'] = $true
                Get-IntegrationWizardDefinition -Id 'github-connector'
            }
            'Entro' {
                $context['Entro'] = $true
                Get-IntegrationWizardDefinition -Id 'github-entro'
            }
        }
    } `
    -Discover {
        param($name, $ctx)
        if ($name -eq 'Organization') {
            $json = gh api user/orgs --jq '.[].login' 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                return @($json -split "`n" | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
            }
        }
        @()
    } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
