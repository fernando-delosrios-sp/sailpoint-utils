#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
$azure = Import-Module (Join-Path $wizardRoot 'modules/Definitions/Azure.Connector.psm1') -Force -PassThru
$awsMod = Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Connector.psm1') -Force -PassThru
$google = Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Connector.psm1') -Force -PassThru
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'AWS' -Title 'AWS' -CoreOptions @('SaaSConnector', 'CiemConnector', 'Entro') -CliName 'aws'
Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' -CoreOptions @('SaaSConnector', 'CiemConnector') -CliName 'gcloud'
Register-AwsConnectorDefinitions
Register-AwsEntroDefinitions
Register-GoogleConnectorDefinitions

$readWrite = & $azure { Get-AzureLegacyArguments -Context @{ Access = 'ReadWrite' } }
Assert-Equal 'Granular' $readWrite.PermissionMode 'ReadWrite defaults to Granular permissions'
Assert-True (-not $readWrite.ContainsKey('Feature')) 'an omitted Entra feature list is not splatted as null'

$directory = & $azure { Get-AzureLegacyArguments -Context @{ Access = 'ReadWrite'; PermissionMode = 'Directory' } }
Assert-Equal 'Directory' $directory.PermissionMode 'explicit Directory mode is kept for ReadWrite'

$readOnly = & $azure { Get-AzureLegacyArguments -Context @{ Access = 'ReadOnly'; PermissionMode = 'Directory' } }
Assert-Equal 'Granular' $readOnly.PermissionMode 'ReadOnly stays on Granular permissions'

$saasDef = Get-IntegrationWizardDefinition -Id 'aws-saas-connector'
Assert-True (@($saasDef.Inputs.Name) -contains 'Feature') 'AWS SaaS definition collects feature packs'

$packed = & $awsMod { Get-AwsLegacyArguments -SourceType 'AwsSaas' -Context @{ Feature = 'ActivityInsights,Ciem'; IscExternalId = 'ext' } }
Assert-Equal 'ActivityInsights' @($packed.Feature)[0] 'comma-separated feature packs split'
Assert-Equal 'Ciem' @($packed.Feature)[1] 'second feature pack is kept'
Assert-Equal 2 @($packed.Feature).Count 'two feature packs are passed'

$none = & $awsMod { Get-AwsLegacyArguments -SourceType 'AwsSaas' -Context @{ Feature = ''; IscExternalId = 'ext' } }
Assert-True ($none.ContainsKey('Feature')) 'an answered empty feature list is explicit'
Assert-Equal 0 @($none.Feature).Count 'an empty feature answer passes no packs'

$omitted = & $awsMod { Get-AwsLegacyArguments -SourceType 'AwsSaas' -Context @{ IscExternalId = 'ext' } }
Assert-True (-not $omitted.ContainsKey('Feature')) 'a missing feature list is left for the legacy prompt'
Assert-True (-not $omitted.ContainsKey('Cloud')) 'an omitted cloud is left for the legacy prompt'

$govCloud = & $awsMod { Get-AwsLegacyArguments -SourceType 'AwsSaas' -Context @{ IscExternalId = 'ext'; Cloud = 'GovCloud' } }
Assert-Equal 'GovCloud' $govCloud.Cloud 'an explicit cloud is passed through'

Assert-True (@($saasDef.Inputs.Name) -contains 'Cloud') 'AWS SaaS definition collects the AWS cloud'
$ciemAwsDef = Get-IntegrationWizardDefinition -Id 'aws-ciem-connector'
Assert-True (@($ciemAwsDef.Inputs.Name) -contains 'Cloud') 'AWS CIEM definition collects the AWS cloud'

function Get-ScriptParameterSetNames {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$ParameterName)
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors) { throw "Failed to parse ${Path}: $($parseErrors[0].Message)" }
    $paramAst = @($ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq $ParameterName })
    if ($paramAst.Count -ne 1) { throw "Parameter $ParameterName was not found in $Path" }
    $sets = [System.Collections.Generic.List[string]]::new()
    foreach ($attr in $paramAst[0].Attributes) {
        if ($attr.TypeName.Name -ne 'Parameter') { continue }
        $setArg = @($attr.NamedArguments | Where-Object { $_.ArgumentName -eq 'ParameterSetName' })
        if ($setArg.Count -eq 1) { $sets.Add([string]$setArg[0].Argument.Value) }
    }
    return $sets.ToArray()
}

$awsFeatureSets = @(Get-ScriptParameterSetNames -Path (Join-Path $wizardRoot 'AWS.ps1') -ParameterName 'Feature')
Assert-True ($awsFeatureSets -contains 'SaaSConnector') 'AWS.ps1 accepts -Feature for the SaaS connector'

$awsCloudSets = @(Get-ScriptParameterSetNames -Path (Join-Path $wizardRoot 'AWS.ps1') -ParameterName 'Cloud')
Assert-True ($awsCloudSets -contains 'SaaSConnector') 'AWS.ps1 accepts -Cloud for the SaaS connector'
Assert-True ($awsCloudSets -contains 'CiemConnector') 'AWS.ps1 accepts -Cloud for the CIEM connector'

$ciemDef = Get-IntegrationWizardDefinition -Id 'google-ciem-connector'
Assert-True (@($ciemDef.Inputs.Name) -contains 'ImpersonateUser') 'GCP CIEM collects the impersonated admin'
$missingImpersonation = Test-IntegrationWizardRequiredInputs -Definition $ciemDef -Context @{ OrganizationId = '1'; ProjectId = 'p' }
Assert-True ($missingImpersonation -contains 'ImpersonateUser') 'GCP CIEM requires ImpersonateUser'

$ciemArgs = & $google { Get-GoogleLegacyArguments -Mode 'Ciem' -Context @{ Feature = 'NhiDiscovery,AgentDiscovery'; ImpersonateUser = 'admin@contoso.com' } }
Assert-Equal 'Gcp' @($ciemArgs.Feature)[0] 'CIEM mode enables the Gcp pack'
Assert-Equal 'Ciem' @($ciemArgs.Feature)[1] 'CIEM mode enables the Ciem pack'
Assert-Equal 'NhiDiscovery' @($ciemArgs.Feature)[2] 'CIEM mode keeps the first extra pack'
Assert-Equal 'AgentDiscovery' @($ciemArgs.Feature)[3] 'CIEM mode keeps the second extra pack'
Assert-Equal 'admin@contoso.com' $ciemArgs.ImpersonateUser 'CIEM mode passes ImpersonateUser'
$saasArgs = & $google { Get-GoogleLegacyArguments -Mode 'Saas' -Context @{ ImpersonateUser = 'admin@contoso.com' } }
Assert-True (-not $saasArgs.ContainsKey('Feature')) 'SaaS mode does not force CIEM packs'

$googlePath = Join-Path $wizardRoot 'Google Cloud.ps1'
$googleImpersonateSets = @(Get-ScriptParameterSetNames -Path $googlePath -ParameterName 'ImpersonateUser')
Assert-True ($googleImpersonateSets -contains 'CiemConnector') 'Google Cloud.ps1 accepts -ImpersonateUser for CIEM'
$googleFeatureSets = @(Get-ScriptParameterSetNames -Path $googlePath -ParameterName 'Feature')
Assert-True ($googleFeatureSets -contains 'CiemConnector') 'Google Cloud.ps1 accepts -Feature for CIEM'

$render = Get-Module -Name 'IW.Render'
& $render {
    function script:Get-IntegrationWizardCliSession {
        param([Parameter(Mandatory)][string]$CliName)
        return @{ SignedIn = $false; Installed = $false }
    }
    function script:Install-IntegrationWizardCli {
        param([Parameter(Mandatory)][string]$CliName, [switch]$NonInteractive)
        $global:IwInstallCount++
    }
    function script:Invoke-IntegrationWizardCliLogin {
        param([Parameter(Mandatory)][string]$CliName, [switch]$NonInteractive)
        $global:IwLoginCount++
    }
}
$runDef = @{ CliName = 'aws'; Title = 'test'; Steps = { param($ctx) ,@() } }
$global:IwInstallCount = 0
$global:IwLoginCount = 0
Invoke-IntegrationWizardRun -Definition $runDef -Context @{ ConnectionMode = 'NoSession'; NonInteractive = $true }
Assert-Equal 0 $global:IwInstallCount 'NoSession does not install the CLI'
Assert-Equal 0 $global:IwLoginCount 'NoSession does not sign in'
Invoke-IntegrationWizardRun -Definition $runDef -Context @{ ConnectionMode = 'UseSession'; NonInteractive = $true }
Assert-Equal 1 $global:IwInstallCount 'a missing session installs the CLI'
Assert-Equal 1 $global:IwLoginCount 'a missing session signs in'

Assert-Equal 'Entro-ext-id-123' (Get-EntroAwsCloudFormationStackName -ExternalId 'ext id/123') 'stack name keeps only stack-safe characters'
Assert-Equal 'Skip' (Get-EntroAwsCloudFormationProbeResult -StackStatus 'CREATE_COMPLETE') 'a completed stack is unchanged'
Assert-Equal 'Create' (Get-EntroAwsCloudFormationProbeResult -StackStatus '') 'a missing stack is created'
Assert-Equal 'Update' (Get-EntroAwsCloudFormationProbeResult -StackStatus 'ROLLBACK_COMPLETE') 'a failed stack is deployed again'
Assert-Equal 'Skip' (Get-EntroAwsCloudFormationProbeResult -StackStatus 'CREATE_IN_PROGRESS') 'an in-progress stack is left alone'

$script:AwsCalls = @()
$script:StackStatus = $null
function global:Invoke-MockAwsCli {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$AwsCliArgs)
    $line = $AwsCliArgs -join ' '
    $script:AwsCalls += $line
    if ($line -match 'describe-stacks') {
        if ($script:StackStatus) {
            $global:LASTEXITCODE = 0
            return $script:StackStatus
        }
        $global:LASTEXITCODE = 254
        return ''
    }
    if ($line -match 'get-role') {
        $global:LASTEXITCODE = 0
        return 'exists'
    }
    $global:LASTEXITCODE = 0
    return ''
}
Set-Alias -Name aws -Value Invoke-MockAwsCli -Scope Global -Force
$entro = Get-IntegrationWizardDefinition -Id 'aws-entro'
$cfCtx = @{
    EntroExternalId = 'ext-id-123'; Method = 'CloudFormation'; EntroRoleName = 'EntroReadOnly'
    Region = 'eu-west-1'; EntroTemplateRegion = 'Default'; OutputDirectory = (Get-Location).Path
}
$cfSteps = & $entro.Steps $cfCtx
$trust = @($cfSteps | Where-Object { $_.Id -eq 'entro-trust' })[0]
Assert-Equal 'Create' (& $trust.Probe $cfCtx) 'CloudFormation is not skipped just because the IAM role exists'
Assert-True (@($script:AwsCalls | Where-Object { $_ -match 'describe-stacks' -and $_ -match 'Entro-ext-id-123' -and $_ -match 'eu-west-1' }).Count -ge 1) 'CloudFormation probe checks the stack in the selected region'

$script:StackStatus = 'CREATE_COMPLETE'
Assert-Equal 'Skip' (& $trust.Probe $cfCtx) 'CloudFormation skips when that stack is already complete'

$assumeCtx = @{ EntroExternalId = 'ext-id-123'; Method = 'AssumeRole'; EntroRoleName = 'EntroReadOnly' }
$assumeSteps = & $entro.Steps $assumeCtx
$assumeTrust = @($assumeSteps | Where-Object { $_.Id -eq 'entro-trust' })[0]
Assert-Equal 'Skip' (& $assumeTrust.Probe $assumeCtx) 'AssumeRole still skips when the role exists'

$script:AwsCalls = @()
$script:StackStatus = $null
& $trust.Run $cfCtx
Assert-True (@($script:AwsCalls | Where-Object { $_ -match 'cloudformation deploy' -and $_ -match 'Entro-ext-id-123' -and $_ -match 'eu-west-1' }).Count -ge 1) 'CloudFormation deploy uses the stable stack name and region'

Write-Host "PASS ($script:AssertionCount assertions)"
