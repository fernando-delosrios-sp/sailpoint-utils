#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/IW.Project.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force

Register-IntegrationWizardPlatform -Name 'GoogleCloud' -Title 'Google Cloud' -CoreOptions @('GcpEntro') -CliName 'gcloud'
Register-GoogleEntroDefinitions
$def = Get-IntegrationWizardDefinition -Id 'google-gcp-entro'
Assert-True ($null -ne $def) 'google-gcp-entro registered'

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("iw-project-test-{0}" -f [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:SAILPOINT_CONNECT_ROOT = Join-Path $tmp '.sailpoint-connect'
Push-Location $tmp
try {
    $thrown = $false
    try { Test-IntegrationProjectName -Name '../bad' } catch { $thrown = $true }
    Assert-True $thrown 'rejects path separators in project name'

    $ctx = @{
        Project          = 'demo-customer'
        NonInteractive   = $true
        Action           = 'BuildRequirements'
        OrganizationId   = '416188549418'
        ProjectId        = 'emea-tes-team'
        Method           = 'PrivateKey'
        OutputDirectory  = $null
    }
    Initialize-IntegrationProjectContext -Platform 'GoogleCloud' -PlatformTitle 'Google Cloud' -Plan $def -Context $ctx -ScriptName 'Google Cloud.ps1'

    $root = Get-IntegrationProjectRoot
    Assert-True (Test-Path -LiteralPath $root) '.sailpoint-connect created on project init'

    $expectedFolder = Join-Path (Join-Path (Join-Path $root 'demo-customer') 'Google Cloud') 'Entro GCP'
    Assert-Equal $expectedFolder $ctx['IntegrationFolderPath'] 'integration folder path'
    Assert-Equal $expectedFolder $ctx['OutputDirectory'] 'OutputDirectory defaults to integration folder'

    Write-IntegrationProjectLogLine -Level 'STEP' -Message 'Test step line'
    $logPath = Join-Path $expectedFolder 'activity.log'
    Assert-True (Test-Path -LiteralPath $logPath) 'activity.log exists'
    $logText = Get-Content -LiteralPath $logPath -Raw
    Assert-True ($logText -match 'Test step line') 'activity.log contains step line'

    $ctxWithSecret = @{
        IntegrationProjectName = 'demo-customer'
        Action                 = 'Run'
        OrganizationId         = '1'
        ClientSecret           = 'super-secret'
    }
    $defSecret = @{
        Title  = 'Secret test'
        Inputs = @(
            @{ Name = 'OrganizationId'; Required = $false }
            @{ Name = 'ClientSecret'; Secret = $true; Required = $false }
        )
    }
    $snap = Get-IntegrationProjectSelectionSnapshot -Context $ctxWithSecret -Definition $defSecret -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1'
    Assert-Equal '***' $snap.inputs.ClientSecret 'secrets masked in selection snapshot'

    $defInferredSecret = @{
        Title  = 'Inferred secret test'
        Inputs = @(
            @{ Name = 'ApiToken'; Required = $false }
        )
    }
    $ctxInferred = @{ IntegrationProjectName = 'demo-customer'; ApiToken = 'pat-token-value' }
    $snapInferred = Get-IntegrationProjectSelectionSnapshot -Context $ctxInferred -Definition $defInferredSecret -Platform 'GitHub' -ScriptName 'GitHub.ps1'
    Assert-Equal '***' $snapInferred.inputs.ApiToken 'inferred secret by name is masked in selection snapshot'

    $record = Get-IntegrationProjectSelectionSnapshot -Context $ctx -Definition $def -Platform 'GoogleCloud' -ScriptName 'Google Cloud.ps1'
    Write-IntegrationProjectSelection -Record $record
    $selPath = Join-Path (Join-Path $root 'demo-customer') 'selection.json'
    Assert-True (Test-Path -LiteralPath $selPath) 'selection.json written'
    $sel = Get-Content -LiteralPath $selPath -Raw | ConvertFrom-Json
    Assert-Equal 'Entro GCP' $sel.integrationFolder 'selection records integration folder name'

    $jsonl = Join-Path (Join-Path $root 'demo-customer') 'selections.jsonl'
    Assert-True (Test-Path -LiteralPath $jsonl) 'selections.jsonl appended'

    $overridePath = Join-Path $tmp 'custom-out'
    $ctxOverride = @{
        Project         = 'demo-customer'
        NonInteractive  = $true
        Action          = 'BuildRequirements'
        OrganizationId  = '1'
        ProjectId       = 'p'
        Method          = 'PrivateKey'
        OutputDirectory = $overridePath
    }
    Initialize-IntegrationProjectActivityLog -LogPath (Join-Path $expectedFolder 'activity-override.log')
    Initialize-IntegrationProjectContext -Platform 'GoogleCloud' -PlatformTitle 'Google Cloud' -Plan $def -Context $ctxOverride -ScriptName 'Google Cloud.ps1'
    Assert-Equal $overridePath $ctxOverride['OutputDirectory'] 'explicit OutputDirectory unchanged'
    Assert-True $ctxOverride['IntegrationOutputOverride'] 'override flag set'

    $folderName = Get-IntegrationWizardIntegrationFolderName -Definition $def
    Assert-Equal 'Entro GCP' $folderName 'FolderName from definition'

    $saasMember = @{
        Id          = 'google-saas-connector'
        Title       = 'Google Workspace connector'
        FolderName  = 'Google Workspace'
        Platform    = 'GoogleCloud'
        CliName     = 'gcloud'
        Inputs      = @()
        AdminRoles  = @()
        OutputsHelp = ''
        Steps       = { param($ctx) @() }
    }
    $combined = Merge-IntegrationWizardDefinitions -Members @($saasMember, $def)
    $combinedFolder = Get-IntegrationWizardIntegrationFolderName -Definition $combined
    Assert-Equal 'Google Workspace and Entro GCP' $combinedFolder 'composite folder name is filesystem-safe'
    Assert-True ($combinedFolder -notmatch '[+]') 'composite folder name contains no plus sign'

    $existingOnly = @(Get-IntegrationProjectNames)
    Assert-True ($existingOnly -contains 'demo-customer') 'lists project subfolders only'

    Import-Module (Join-Path $wizardRoot 'modules/IW.Render.psm1') -Force
    Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
    Initialize-OperatorConsole -NonInteractive
    $runCtx = @{
        IntegrationProjectName    = 'demo-customer'
        IntegrationPlatformTitle  = 'Google Cloud'
        NonInteractive            = $true
        ConnectionMode            = 'NoSession'
        ManualDetail              = 'Enable audit logs.'
    }
    $manualDef = @{
        Title      = 'Entro GCP'
        FolderName = 'Entro GCP'
        Platform   = 'GoogleCloud'
        CliName    = 'gcloud'
        Steps      = {
            param($c)
            @(
                @{ Id = 'audit'; Title = 'Org audit logs'; Kind = 'Manual'; Manual = [string]$c['ManualDetail'] }
            )
        }
    }
    Invoke-IntegrationWizardRun -Definition $manualDef -Context $runCtx
    $actionsPath = Get-IntegrationProjectOperatorActionsPath -ProjectName 'demo-customer'
    Assert-True (Test-Path -LiteralPath $actionsPath) 'operator-actions.md written for the project'
    $open = @(Read-IntegrationProjectOperatorActions -ProjectName 'demo-customer')
    Assert-Equal 1 $open.Count 'one operator action recorded'
    Assert-Equal 'audit' $open[0].Id 'operator action keeps the step id'
    Assert-True (-not $open[0].Done) 'a non-interactive run leaves the action open'
    Assert-Equal 'Google Cloud / Entro GCP' $open[0].Section 'section names the platform and integration'

    $otherDef = @{
        Title      = 'Entro Workspace'
        FolderName = 'Entro Workspace'
        Platform   = 'GoogleCloud'
        CliName    = 'gcloud'
        Steps      = {
            param($c)
            @(
                @{ Id = 'dwd'; Title = 'Domain-wide delegation'; Kind = 'Manual'; Manual = 'Authorize the client.' }
            )
        }
    }
    Invoke-IntegrationWizardRun -Definition $otherDef -Context $runCtx
    $both = @(Read-IntegrationProjectOperatorActions -ProjectName 'demo-customer')
    Assert-Equal 2 $both.Count 'a second integration adds its own section'
    Assert-Equal 'audit,dwd' (($both | ForEach-Object { $_.Id }) -join ',') 'both integrations stay in the project file'

    $done = @{
        Section = 'Google Cloud / Entro GCP'
        Id      = 'audit'
        Title   = 'Org audit logs'
        Detail  = 'Enable audit logs.'
        Done    = $true
    }
    Save-IntegrationProjectOperatorAction -ProjectName 'demo-customer' -Action $done
    Invoke-IntegrationWizardRun -Definition $manualDef -Context $runCtx
    $kept = @(@(Read-IntegrationProjectOperatorActions -ProjectName 'demo-customer') | Where-Object { $_.Id -eq 'audit' })[0]
    Assert-True $kept.Done 'rerun keeps an action marked done when the instruction is unchanged'
    Assert-Equal 2 @(Read-IntegrationProjectOperatorActions -ProjectName 'demo-customer').Count 'rerun does not drop the other integration'

    $runCtx['ManualDetail'] = 'Enable a different set of audit logs.'
    Invoke-IntegrationWizardRun -Definition $manualDef -Context $runCtx
    $reset = @(@(Read-IntegrationProjectOperatorActions -ProjectName 'demo-customer') | Where-Object { $_.Id -eq 'audit' })[0]
    Assert-True (-not $reset.Done) 'a changed instruction becomes open again'
    Assert-Equal 'Enable a different set of audit logs.' $reset.Detail 'the file stores the new instruction'
}
finally {
    Remove-Item env:SAILPOINT_CONNECT_ROOT -ErrorAction SilentlyContinue
    Pop-Location
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "PASS ($script:AssertionCount assertions)"
