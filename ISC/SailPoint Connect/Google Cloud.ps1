#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [switch]$Wizard,

    # There is no separate "Combined" set. -SaaSConnector plus an Entro switch resolves to the
    # SaaSConnector set, which lists the Entro switches and inputs as optional. Keeping a second
    # set that overlapped the single-target sets made PowerShell report an ambiguous parameter set.
    [Parameter(ParameterSetName = 'SaaSConnector', Mandatory)]
    [switch]$SaaSConnector,
    [Parameter(ParameterSetName = 'CiemConnector', Mandatory)]
    [switch]$CiemConnector,
    # BothEntro lets -GcpEntro -WorkspaceEntro bind so the script can reject that pair.
    # Without it, PowerShell resolves the pair to SaaSConnector and demands -SaaSConnector.
    [Parameter(ParameterSetName = 'GcpEntro', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro', Mandatory)]
    [switch]$GcpEntro,
    [Parameter(ParameterSetName = 'WorkspaceEntro', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro', Mandatory)]
    [switch]$WorkspaceEntro,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [string]$OrganizationId,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [string]$ProjectId,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$ImpersonateUser,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('ActivityInsights', 'AgentDiscovery', 'Ciem', 'DeltaAggregation', 'DomainManagement', 'Gcp', 'GmailDelegates', 'NhiDiscovery')]
    [string[]]$Feature,
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [ValidateSet('PrivateKey', 'WorkloadIdentity')]
    [string]$Method,
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [switch]$ApplyPreconditionFix,
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [string]$ClientId,
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [string]$ServiceAccountName,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'BothEntro')]
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

# One Entro variant may accompany the Workspace connector. Both Entro variants at once is not allowed.
if ($GcpEntro -and $WorkspaceEntro) {
    throw 'Combined mode allows only one Entro variant (-GcpEntro or -WorkspaceEntro).'
}

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' `
    -CoreOptions @('SaaSConnector', 'GcpEntro', 'WorkspaceEntro') -CliName 'gcloud' `
    -EntroCompanions @{
        SaaSConnector = @{ Variants = @('GcpEntro', 'WorkspaceEntro') }
    }
Register-GoogleConnectorDefinitions
Register-GoogleEntroDefinitions

$coreHelp = [ordered]@{
    SaaSConnector   = @{ Short = 'Google connector'; Long = 'Google Workspace / GCP connector (select Gcp/Ciem in Feature for CIEM)' }
    GcpEntro        = @{ Short = 'GCP Entro'; Long = 'Entro Google GCP organization integration' }
    WorkspaceEntro  = @{ Short = 'Workspace Entro'; Long = 'Entro Google Workspace integration' }
}

$resolvedFeature = @(if ($Feature) { $Feature })
$effectiveSaas = [bool]$SaaSConnector
if ($CiemConnector) {
    $effectiveSaas = $true
    foreach ($reqPack in @('Gcp', 'Ciem')) {
        if ($resolvedFeature -notcontains $reqPack) {
            $resolvedFeature += $reqPack
        }
    }
}

$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    SaaSConnector = $effectiveSaas
    GcpEntro = [bool]$GcpEntro; WorkspaceEntro = [bool]$WorkspaceEntro
    Access = $Access; Action = $Action
    OrganizationId = $OrganizationId; ProjectId = $ProjectId; ImpersonateUser = $ImpersonateUser
    Feature = $(if (@($resolvedFeature).Count -gt 0) { $resolvedFeature } else { $Feature })
    Method = $Method; ClientId = $ClientId; ServiceAccountName = $ServiceAccountName; OutputDirectory = $OutputDirectory
    OutputFormat = $OutputFormat
    Project = $Project
}
if ($PSBoundParameters.ContainsKey('ApplyPreconditionFix')) {
    $context['ApplyPreconditionFix'] = [bool]$ApplyPreconditionFix
}
$hasCore = $effectiveSaas -or $GcpEntro -or $WorkspaceEntro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp
    return
}
Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' `
            -Options @('GcpCombined', 'WorkspaceCombined') `
            -Labels @('Google Cloud Platform (Connector + Entro GCP)', 'Google Workspace (Connector + Entro Workspace)') -Default 'GcpCombined'
        $context.SaaSConnector = $true
        $context.GcpEntro = ($picked -ne 'WorkspaceCombined')
        $context.WorkspaceEntro = ($picked -eq 'WorkspaceCombined')
        Get-IntegrationWizardDefinition -Id 'google-saas-connector'
    } `
    -Discover {
        param($name, $ctx)
        if ($name -eq 'OrganizationId') {
            $json = gcloud organizations list --format=json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                return @($json | ConvertFrom-Json | ForEach-Object { $_.name -replace '^organizations/', '' })
            }
            Write-Warning "Could not list organizations (gcloud exit $LASTEXITCODE). If the session expired, run: gcloud auth login"
        }
        if ($name -eq 'ProjectId') {
            $json = gcloud projects list --format=json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                return @($json | ConvertFrom-Json | ForEach-Object { $_.projectId })
            }
        }
        @()
    } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx -WhatIf:$WhatIfPreference }
