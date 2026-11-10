#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
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

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$BaseUrl,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$ClientId,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$ClientSecret,

    [Parameter(ParameterSetName = 'Connector')]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
        @('Discover', 'IdentityProtection', 'CloudSecurity', 'RealTimeResponse') | Where-Object { $_ -like "$wordToComplete*" }
    })]
    [string[]]$Feature,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'Connector')]
    [string]$Environment,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutputDirectory,

    [Parameter(ParameterSetName = 'Connector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$NonInteractive,

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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/CrowdStrike.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/CrowdStrike.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'CrowdStrike' -Title 'CrowdStrike' -CoreOptions @('Connector', 'Entro') -CliName 'falcon' `
    -EntroCompanions @{
        Connector = @{ EntroSwitch = 'Entro' }
    }
Register-CrowdStrikeConnectorDefinitions
Register-CrowdStrikeEntroDefinitions

$validFeatures = @('Discover', 'IdentityProtection', 'CloudSecurity', 'RealTimeResponse')
$parsedFeatures = if ($Feature) {
    @($Feature | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
} else { @() }
foreach ($f in $parsedFeatures) {
    if ($f -notin $validFeatures) {
        throw "Cannot validate argument on parameter 'Feature'. The argument '$f' does not belong to the set '$($validFeatures -join ', ')'."
    }
}

$coreHelp = [ordered]@{
    Connector = @{ Short = 'CrowdStrike Falcon SaaS connector'; Long = 'CrowdStrike Falcon SaaS connector & Machine Identity Governance' }
    Entro     = @{ Short = 'Entro'; Long = 'Entro CrowdStrike integration' }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    Connector = [bool]$Connector; Entro = [bool]$Entro
    Access = $Access; Action = $Action
    BaseUrl = $BaseUrl; ClientId = $ClientId; ClientSecret = $ClientSecret
    Feature = if ($parsedFeatures.Count -gt 0) { ($parsedFeatures -join ',') } else { $null }
    Environment = $Environment; OutputDirectory = $OutputDirectory
    Project = $Project
}

$hasCore = $Connector -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'CrowdStrike' -ScriptName 'CrowdStrike.ps1' -CoreOptionHelp $coreHelp
    return
}

Start-IntegrationWizardFlow -Platform 'CrowdStrike' -ScriptName 'CrowdStrike.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' -Options @('Connector', 'Entro') `
            -Labels @('CrowdStrike Falcon SaaS connector (with Machine Identity Governance)', 'Entro CrowdStrike integration') -Default 'Connector'
        switch ($picked) {
            'Connector' {
                $context['Connector'] = $true
                Get-IntegrationWizardDefinition -Id 'crowdstrike-connector'
            }
            'Entro' {
                $context['Entro'] = $true
                Get-IntegrationWizardDefinition -Id 'crowdstrike-entro'
            }
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
