#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [switch]$Wizard,

    # There is no separate "Combined" set. -SaaSConnector plus an Entro switch resolves to the
    # SaaSConnector set, which lists the Entro switches and inputs as optional. Keeping a second
    # set that overlapped the single-target sets made PowerShell report an ambiguous parameter set.
    [Parameter(ParameterSetName = 'SaaSConnector', Mandatory)]
    [switch]$SaaSConnector,
    [Parameter(ParameterSetName = 'CiemConnector', Mandatory)]
    [switch]$CiemConnector,
    [Parameter(ParameterSetName = 'GcpEntro', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [switch]$GcpEntro,
    [Parameter(ParameterSetName = 'WorkspaceEntro', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [switch]$WorkspaceEntro,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements')]
    [string]$Action,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [string]$OrganizationId,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [string]$ProjectId,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$ImpersonateUser,
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('ActivityInsights', 'AgentDiscovery', 'Ciem', 'DeltaAggregation', 'DomainManagement', 'Gcp', 'GmailDelegates', 'NhiDiscovery')]
    [string[]]$Feature,
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [ValidateSet('PrivateKey', 'WorkloadIdentity')]
    [string]$Method,
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [switch]$ApplyPreconditionFix,
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [string]$ClientId,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [string]$OutputDirectory,
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'GcpEntro')]
    [Parameter(ParameterSetName = 'WorkspaceEntro')]
    [string]$Project
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Combined run (Google Workspace connector + one Entro variant). Both Entro variants at once is not allowed.
if ($SaaSConnector -and $GcpEntro -and $WorkspaceEntro) {
    throw 'Combined mode allows only one Entro variant (-GcpEntro or -WorkspaceEntro).'
}

$wizardRoot = $PSScriptRoot
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-IntegrationWizardConsole -WizardRoot $wizardRoot -NonInteractive:$NonInteractive
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' `
    -CoreOptions @('SaaSConnector', 'CiemConnector', 'GcpEntro', 'WorkspaceEntro') -CliName 'gcloud' `
    -EntroCompanions @{
        SaaSConnector = @{ Variants = @('GcpEntro', 'WorkspaceEntro') }
    }
Register-GoogleConnectorDefinitions
Register-GoogleEntroDefinitions

$coreHelp = [ordered]@{
    SaaSConnector   = @{ Short = 'Workspace connector'; Long = 'Google Workspace connector' }
    CiemConnector   = @{ Short = 'GCP CIEM connector'; Long = 'GCP CIEM connector feature packs' }
    GcpEntro        = @{ Short = 'GCP Entro'; Long = 'Entro Google GCP organization integration' }
    WorkspaceEntro  = @{ Short = 'Workspace Entro'; Long = 'Entro Google Workspace integration' }
}
$context = @{
    Wizard = [bool]$Wizard; NonInteractive = [bool]$NonInteractive
    SaaSConnector = [bool]$SaaSConnector; CiemConnector = [bool]$CiemConnector
    GcpEntro = [bool]$GcpEntro; WorkspaceEntro = [bool]$WorkspaceEntro
    Access = $Access; Action = $Action
    OrganizationId = $OrganizationId; ProjectId = $ProjectId; ImpersonateUser = $ImpersonateUser; Feature = $Feature
    Method = $Method; ClientId = $ClientId; OutputDirectory = $OutputDirectory
    Project = $Project
}
if ($PSBoundParameters.ContainsKey('ApplyPreconditionFix')) {
    $context['ApplyPreconditionFix'] = [bool]$ApplyPreconditionFix
}
$hasCore = $SaaSConnector -or $CiemConnector -or $GcpEntro -or $WorkspaceEntro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp
    return
}
Start-IntegrationWizardFlow -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'What do you want to configure?' `
            -Options @('SaaSConnector', 'CiemConnector', 'GcpEntro', 'WorkspaceEntro') `
            -Labels @('Google Workspace connector', 'GCP CIEM connector', 'Entro GCP', 'Entro Workspace') -Default 'SaaSConnector'
        $context[$picked] = $true
        switch ($picked) {
            'SaaSConnector' { Get-IntegrationWizardDefinition -Id 'google-saas-connector' }
            'CiemConnector' { Get-IntegrationWizardDefinition -Id 'google-ciem-connector' }
            'GcpEntro' { Get-IntegrationWizardDefinition -Id 'google-gcp-entro' }
            'WorkspaceEntro' { Get-IntegrationWizardDefinition -Id 'google-workspace-entro' }
        }
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
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx }
