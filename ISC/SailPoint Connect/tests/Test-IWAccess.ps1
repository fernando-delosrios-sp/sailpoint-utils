#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Access.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/ISC.EntraConnector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/ISC.EntraCiemConnector.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Aws.Entro.psm1') -Force

Initialize-EntraConnectorData
Initialize-EntraCiemConnectorData

Assert-Equal 'ReadOnly' (Get-RequirementAccessClass -Kind 'MicrosoftGraphPermission' -Name 'User.Read.All') 'Graph read permission'
Assert-Equal 'ReadWrite' (Get-RequirementAccessClass -Kind 'MicrosoftGraphPermission' -Name 'User.ReadWrite.All') 'Graph write permission'
Assert-Equal 'ReadWrite' (Get-RequirementAccessClass -Kind 'EntroGcpCustomPermission' -Name 'logging.queries.create') 'Entro GCP query create'
Assert-Equal 'ReadOnly' (Get-RequirementAccessClass -Kind 'EntroGcpCustomPermission' -Name 'logging.logEntries.list') 'Entro GCP log list'
Assert-Equal 'ReadWrite' (Get-RequirementAccessClass -Kind 'AwsAction' -Name 'kms:GenerateDataKey') 'kms generate data key is write'
Assert-Equal 'ReadOnly' (Get-RequirementAccessClass -Kind 'AwsAction' -Name 'kms:Decrypt') 'kms decrypt stays read'

$readOnlyPerms = @(Get-SelectedPermissions -Mode 'Granular' -FeatureNames @() -Access 'ReadOnly')
Assert-True (@($readOnlyPerms.Value) -contains 'User.Read.All') 'ReadOnly keeps User.Read.All'
Assert-True (@($readOnlyPerms.Value) -notcontains 'User.ReadWrite.All') 'ReadOnly drops User.ReadWrite.All'

Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Register-GoogleEntroDefinitions
$entroDef = Get-IntegrationWizardDefinition -Id 'google-gcp-entro'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("iw-access-req-$(Get-Random)")
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$reqCtx = @{
    Action = 'BuildRequirements'; OutputDirectory = $tmp
    Method = 'PrivateKey'; OrganizationId = '1'; ProjectId = 'p'; ServiceAccountName = 'entro-automatic-onboard'
}
New-IntegrationWizardRequirementsDoc -Definition $entroDef -Context $reqCtx -OutputPath (Join-Path $tmp 'google-gcp-entro-requirements.md')
$md = Get-Content (Join-Path $tmp 'google-gcp-entro-requirements.md') -Raw
Assert-True ($md -match '## Read-only requirements') 'requirements doc has read-only section'
Assert-True ($md -match '## Read-write requirements') 'requirements doc has read-write section'
Assert-True ($md -notmatch 'entro-gcp-enable-apis\.sh') 'requirements doc does not reference bash enable-apis script'

# Stubbed Google Entro Run invokes PowerShell Entro GCP functions (not shell scripts).
$script:GcloudCalls = @()
function global:Invoke-GCloud {
    param([string[]]$GcloudArgs, [switch]$ExpectJson)
    $script:GcloudCalls += ($GcloudArgs -join ' ')
    if ($GcloudArgs -contains 'organizations' -and $GcloudArgs -contains 'list') { return '123456789012' }
    if ($GcloudArgs -contains 'auth' -and $GcloudArgs -contains 'list') { return 'operator@example.com' }
    if ($GcloudArgs -contains 'projects' -and $GcloudArgs -contains 'list') { return "proj-a`nproj-b" }
    if ($GcloudArgs -contains 'get-iam-policy') { return '{"bindings":[]}' }
    if ($GcloudArgs -contains 'services' -and $GcloudArgs -contains 'list') { return 'logging.googleapis.com' }
    if ($GcloudArgs -contains 'asset') { return '' }
    return ''
}
Import-Module (Join-Path $wizardRoot 'modules/ISC.EntroGcp.psm1') -Force
$runCtx = @{
    OrganizationId = '123456789012'; ProjectId = 'host-proj'; ServiceAccountName = 'entro-automatic-onboard'
    OutputDirectory = $tmp; NonInteractive = $true
}
$steps = & $entroDef.Steps $runCtx
foreach ($step in @($steps | Where-Object { $_.Id -eq 'precheck' })) {
    & $step.Run $runCtx
}
Assert-True ($script:GcloudCalls.Count -gt 0) 'precheck step invoked gcloud via PowerShell'

$script:AwsCalls = @()
function global:Invoke-MockAwsCli {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$AwsCliArgs)
    $line = $AwsCliArgs -join ' '
    $script:AwsCalls += $line
    if ($line -match 'create-policy') {
        $global:LASTEXITCODE = 0
        return 'arn:aws:iam::111122223333:policy/EntroReadOnlyAccess'
    }
    if ($line -match 'create-role|attach-role-policy') {
        $global:LASTEXITCODE = 0
        return ''
    }
    if ($line -match 'get-role') {
        $global:LASTEXITCODE = 0
        return '{"Role":{"Arn":"arn:aws:iam::111122223333:role/EntroReadOnly"}}'
    }
    if ($line -match 'list-policies') {
        $global:LASTEXITCODE = 0
        return 'None'
    }
    $global:LASTEXITCODE = 0
    return ''
}
Set-Alias -Name aws -Value Invoke-MockAwsCli -Scope Global -Force
Register-AwsEntroDefinitions
$awsEntro = Get-IntegrationWizardDefinition -Id 'aws-entro'
$awsCtx = @{
    EntroExternalId = 'ext-id-123'; Method = 'AssumeRole'; EntroRoleName = 'EntroReadOnly'
    OutputDirectory = $tmp; EntroTemplateRegion = 'Default'
}
$awsSteps = & $awsEntro.Steps $awsCtx
$trust = @($awsSteps | Where-Object { $_.Id -eq 'entro-trust' })[0]
& $trust.Run $awsCtx
Assert-True (@($script:AwsCalls | Where-Object { $_ -match 'create-role' }).Count -ge 1) 'AWS Entro Run creates IAM role'
Assert-True (@($script:AwsCalls | Where-Object { $_ -match 'file://entro-trust-policy' }).Count -eq 0) 'AWS Entro does not use broken file:// placeholder without path'

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host 'PASS (15 assertions)'
