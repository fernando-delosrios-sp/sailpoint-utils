#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'Connector', Mandatory)]
    [switch]$Connector,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [Parameter(ParameterSetName = 'Connector')]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'GhesEntro', Mandatory)]
    [switch]$GhesEntro,

    [Parameter(ParameterSetName = 'Connector')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
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
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$Token,

    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$Hostname,
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$DisplayName,
    [Parameter(ParameterSetName = 'GhesEntro')]
    [ValidateSet('Production', 'Development', 'Staging')]
    [string]$EnvironmentType,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$WorkerGroup,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$OutpostId,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$OutpostPublicKeyPath,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$OutpostDeploymentMode,

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
    [Parameter(ParameterSetName = 'GhesEntro')]
    [string]$OutputDirectory,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'GhesEntro')]
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

Register-IntegrationWizardPlatform -Name 'GitHub' -Title 'GitHub' -CoreOptions @('Connector', 'Entro', 'GhesEntro') -CliName 'gh' `
    -EntroCompanions @{
        Connector = @{ EntroSwitch = 'Entro' }
    }
Register-GitHubConnectorDefinitions
Register-GitHubEntroDefinitions

$coreHelp = [ordered]@{
    Connector = @{ Short = 'GitHub SaaS connector'; Long = 'GitHub SaaS connector & Copilot/Bot discovery' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro GitHub Cloud integration' }
    GhesEntro = @{ Short = 'GHES'; Long = 'Entro GitHub Enterprise Server (requires an Outpost)' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro; GhesEntro = [bool]$GhesEntro
    Access = $Access; Action = $Action
    Organization = $Organization; ApiUrl = $ApiUrl
    Hostname = $Hostname; DisplayName = $DisplayName; EnvironmentType = $EnvironmentType
    WorkerGroup = $WorkerGroup
    AuthMethod = $AuthMethod; Token = $Token; AppId = $AppId; InstallationId = $InstallationId; PrivateKey = $PrivateKey
    Feature = if ($Feature) { ($Feature -join ',') } else { $null }
    Method = $Method; OutputDirectory = $OutputDirectory
    OutputFormat = $OutputFormat
    Project = $Project
}

$hasCore = $Connector -or $Entro -or $GhesEntro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GitHub' -ScriptName 'GitHub.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'GitHub' -ScriptName 'GitHub.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro', 'GhesEntro') `
            -Labels @(
                'GitHub SaaS connector (with Copilot/Bot discovery)',
                'Entro GitHub Cloud',
                'Entro GitHub Enterprise Server [Requires Outpost]'
            ) -Default 'Connector'
        switch ($picked) {
            'Connector' {
                $context['Connector'] = $true
                Get-IntegrationWizardDefinition -Id 'github-connector'
            }
            'Entro' {
                $context['Entro'] = $true
                Get-IntegrationWizardDefinition -Id 'github-entro'
            }
            'GhesEntro' {
                $context['GhesEntro'] = $true
                Get-IntegrationWizardDefinition -Id 'github-ghes-entro'
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
