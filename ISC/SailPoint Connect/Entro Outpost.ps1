#Requires -Version 7
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [switch]$Wizard,

    [Parameter(ParameterSetName = 'DockerCompose', Mandatory)]
    [switch]$DockerCompose,

    [Parameter(ParameterSetName = 'KubernetesHelm', Mandatory)]
    [switch]$KubernetesHelm,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$WorkerGroup,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$AwsRegion,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$AwsAccessKeyId,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$AwsSecretAccessKey,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$CrPat,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$LogGroup,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [ValidateSet('No', 'Yes')]
    [string]$EnableEncryptedSecrets,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [ValidateSet('No', 'Yes')]
    [string]$UseProxy,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$HttpProxy,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$NoProxy,

    # Docker Compose options
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [ValidateSet('Standard', 'Large')]
    [string]$DeploymentTier,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$InstallDirectory,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$ComposeFileUrl,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$OutputBucket,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$SqsQueueUrl,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$RedshiftBucket,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [string]$LogStream,

    # Kubernetes Helm options
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$KubernetesNamespace,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$HelmReleaseName,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$ChartVersion,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$AwsAccountId,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$EntroConnectorId,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$EntroPassword,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [ValidateSet('No', 'Yes')]
    [string]$EnableScheduling,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$ScheduleScaleUp,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$ScheduleScaleDown,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$ScheduleTimeZone,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [string]$OutputDirectory,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'DockerCompose')]
    [Parameter(ParameterSetName = 'KubernetesHelm')]
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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/EntroOutpost.psm1') -Force

Register-IntegrationWizardPlatform -Name 'EntroOutpost' -Title 'Entro Outpost' -CoreOptions @('DockerCompose', 'KubernetesHelm') -CliName 'pwsh'
Register-EntroOutpostDefinitions

$coreHelp = [ordered]@{
    DockerCompose  = @{ Short = 'Docker Compose'; Long = 'Deploy Entro Outpost on an on-premises Linux AMD64 Docker host via Docker Compose' }
    KubernetesHelm = @{ Short = 'Kubernetes Helm'; Long = 'Deploy Entro Outpost into Kubernetes (Linux AMD64 nodes) via OCI Helm chart' }
}

$context = @{
    Wizard                 = [bool]$Wizard
    NonInteractive         = [bool]$NonInteractive
    DockerCompose          = [bool]$DockerCompose
    KubernetesHelm         = [bool]$KubernetesHelm
    Action                 = $Action
    WorkerGroup            = $WorkerGroup
    AwsRegion              = $AwsRegion
    AwsAccessKeyId         = $AwsAccessKeyId
    AwsSecretAccessKey     = $AwsSecretAccessKey
    CrPat                  = $CrPat
    LogGroup               = $LogGroup
    EnableEncryptedSecrets = $EnableEncryptedSecrets
    UseProxy               = $UseProxy
    HttpProxy              = $HttpProxy
    NoProxy                = $NoProxy
    DeploymentTier         = $DeploymentTier
    InstallDirectory       = $InstallDirectory
    ComposeFileUrl         = $ComposeFileUrl
    OutputBucket           = $OutputBucket
    SqsQueueUrl            = $SqsQueueUrl
    RedshiftBucket         = $RedshiftBucket
    LogStream              = $LogStream
    KubernetesNamespace    = $KubernetesNamespace
    HelmReleaseName        = $HelmReleaseName
    ChartVersion           = $ChartVersion
    AwsAccountId           = $AwsAccountId
    EntroConnectorId       = $EntroConnectorId
    EntroPassword          = $EntroPassword
    EnableScheduling       = $EnableScheduling
    ScheduleScaleUp        = $ScheduleScaleUp
    ScheduleScaleDown      = $ScheduleScaleDown
    ScheduleTimeZone       = $ScheduleTimeZone
    OutputDirectory        = $OutputDirectory
    OutputFormat           = $OutputFormat
    Project                = $Project
}

$hasCore = $DockerCompose -or $KubernetesHelm
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'EntroOutpost' -ScriptName 'Entro Outpost.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'EntroOutpost' -ScriptName 'Entro Outpost.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $picked = Read-Choice -Prompt 'Select Entro Outpost deployment model' `
            -Options @('DockerCompose', 'KubernetesHelm') `
            -Labels @('Docker Compose (Linux AMD64 VM / host)', 'Kubernetes Helm (OCI chart on Linux AMD64 nodes)') `
            -Default 'DockerCompose'
        $context['DockerCompose'] = ($picked -eq 'DockerCompose')
        $context['KubernetesHelm'] = ($picked -eq 'KubernetesHelm')
        if ($picked -eq 'DockerCompose') {
            Get-IntegrationWizardDefinition -Id 'entro-outpost-docker'
        }
        else {
            Get-IntegrationWizardDefinition -Id 'entro-outpost-kubernetes'
        }
    } `
    -Discover { param($n, $c) @() } `
    -Execute { param($def, $ctx) Invoke-IntegrationWizardAction -Definition $def -Context $ctx -WhatIf:$WhatIfPreference }
