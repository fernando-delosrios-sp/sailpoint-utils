#Requires -Version 7
<#
.SYNOPSIS
    AWS integration wizard for ISC connectors and Entro.
#>
[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Help')]
param(
    [Parameter(ParameterSetName = 'Wizard', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$Wizard,

    # There is no separate "Combined" set. -SaaSConnector plus -Entro resolves to the SaaSConnector
    # set, which lists the Entro switches and inputs as optional. A second overlapping set made
    # PowerShell report an ambiguous parameter set for single-target calls such as -SaaSConnector.
    [Parameter(ParameterSetName = 'SaaSConnector', Mandatory)]
    [switch]$SaaSConnector,

    [Parameter(ParameterSetName = 'CiemConnector', Mandatory)]
    [switch]$CiemConnector,

    [Parameter(ParameterSetName = 'Entro', Mandatory)]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [switch]$Entro,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [ValidateSet('AssumeRole', 'CloudFormation', 'Terraform')]
    [string]$Method,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('Commercial', 'GovCloud')]
    [string]$Cloud,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$Region,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [ValidateSet('Default', 'Europe')]
    [string]$EntroTemplateRegion,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('ReadOnly', 'ReadWrite')]
    [string]$Access,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
    [string]$Action,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$IscExternalId,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [string]$EntroExternalId,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$RoleName,

    [Parameter(ParameterSetName = 'Entro')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [string]$EntroRoleName,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$ProfileName,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [ValidateSet('ActivityInsights', 'AgentDiscovery', 'Ciem')]
    [string[]]$Feature,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [ValidateSet('CurrentAccount', 'Organization')]
    [string]$Scope,

    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [string]$CloudTrailBucket,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'Entro')]
    [string]$OutputDirectory,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'Entro')]
    [switch]$NonInteractive,

    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
    [Parameter(ParameterSetName = 'Entro')]
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text',

    [Parameter(ParameterSetName = 'Help')]
    [Parameter(ParameterSetName = 'Wizard')]
    [Parameter(ParameterSetName = 'SaaSConnector')]
    [Parameter(ParameterSetName = 'CiemConnector')]
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
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'AWS' -Title 'AWS' -CoreOptions @('SaaSConnector', 'Entro') -CliName 'aws' `
    -EntroCompanions @{
        SaaSConnector = @{ EntroSwitch = 'Entro' }
    }
Register-AwsConnectorDefinitions
Register-AwsEntroDefinitions

$coreHelp = [ordered]@{
    SaaSConnector = @{ Short = 'AWS connector'; Long = 'ISC "Amazon Web Services" connector IAM role (select Ciem in Feature for CIEM)' }
    Entro         = @{ Short = 'Entro'; Long = 'Entro AWS integration (Assume Role / CloudFormation / Terraform)' }
}

$resolvedFeature = @(if ($Feature) { $Feature })
$effectiveSaas = [bool]$SaaSConnector
if ($CiemConnector) {
    $effectiveSaas = $true
    if ($resolvedFeature -notcontains 'Ciem') {
        $resolvedFeature += 'Ciem'
    }
}

$context = @{
    Wizard           = [bool]$Wizard
    NonInteractive   = [bool]$NonInteractive
    SaaSConnector    = $effectiveSaas
    Entro            = [bool]$Entro
    Method           = $Method
    Cloud            = $Cloud
    Region           = $Region
    EntroTemplateRegion = $EntroTemplateRegion
    Access           = $Access
    Action           = $Action
    IscExternalId    = $IscExternalId
    EntroExternalId  = $EntroExternalId
    RoleName         = $RoleName
    EntroRoleName    = $EntroRoleName
    ProfileName      = $ProfileName
    Feature          = $(if (@($resolvedFeature).Count -gt 0) { $resolvedFeature } else { $Feature })
    Scope            = $Scope
    CloudTrailBucket = $CloudTrailBucket
    OutputDirectory  = $OutputDirectory
    OutputFormat     = $OutputFormat
    Project          = $Project
}

$hasCore = $effectiveSaas -or $Entro
if ($PSCmdlet.ParameterSetName -eq 'Help' -and -not $Wizard -and -not $hasCore) {
    Show-IntegrationWizardPlatformHelp -Platform 'AWS' -ScriptName 'AWS.ps1' -CoreOptionHelp $coreHelp
    return
}

Copy-IntegrationWizardCatalogContext -Context $context -BoundParameters $PSBoundParameters

Start-IntegrationWizardFlow -Platform 'AWS' -ScriptName 'AWS.ps1' -CoreOptionHelp $coreHelp -Context $context `
    -PickTarget {
        $context.SaaSConnector = $true
        $context.Entro = $true
        Get-IntegrationWizardDefinition -Id 'aws-saas-connector'
    } `
    -Discover {
        param($name, $ctx)
        if ($name -eq 'RoleName') {
            $json = aws iam list-roles --max-items 20 --output json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                return @($json | ConvertFrom-Json | ForEach-Object { $_.Roles } | ForEach-Object { $_.RoleName })
            }
        }
        if ($name -eq 'CloudTrailBucket') {
            $json = aws cloudtrail describe-trails --output json 2>$null
            if ($LASTEXITCODE -eq 0 -and $json) {
                return @($json | ConvertFrom-Json | ForEach-Object { $_.trailList } | ForEach-Object { $_.S3BucketName } | Select-Object -Unique)
            }
        }
        @()
    } `
    -Execute {
        param($def, $ctx)
        Invoke-IntegrationWizardAction -Definition $def -Context $ctx -WhatIf:$WhatIfPreference
    }
