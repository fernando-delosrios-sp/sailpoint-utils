#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-OperatorConsole -NonInteractive

$ctx = @{}
$record = Get-EntroGcpRunRecord -Context $ctx
$record.Finished = $true
$record.Actor = 'admin@example.com'
$record.OrganizationId = '416188549418'
$record.ProjectId = 'emea-tes-team'
$record.ServiceAccountEmail = 'entro-automatic-onboard@emea-tes-team.iam.gserviceaccount.com'
$record.ServiceAccountResult = 'Already present'
$record.Method = 'PrivateKey'
$record.KeyPath = '/tmp/entro-reader-key.json'
$record.KeyResult = 'Created in this run'
$record.CustomRoleId = 'entroLoggingRole_724'
$record.CustomRoleResult = 'Created in an earlier run'
$record.CustomRolePermissions = @('logging.logs.list')
$record.Bindings.Add(@{ Role = 'organizations/416188549418/roles/entroLoggingRole_724'; Result = 'Granted in an earlier run' })
$record.Bindings.Add(@{ Role = 'roles/cloudasset.viewer'; Result = 'Granted in this run' })
$record.Apis.Add(@{ Project = 'emea-tes-team'; Service = 'iam.googleapis.com'; Scope = 'Host project'; Result = 'Already enabled' })
$record.Apis.Add(@{ Project = 'tes-sea-trial'; Service = 'secretmanager.googleapis.com'; Scope = 'Every project in the organization; needs billing'; Result = 'Enabled in this run' })
$record.Projects = @('emea-tes-team', 'tes-sea-trial')
$record.Checks.Add(@{ Project = 'emea-tes-team'; Check = 'roles/owner for admin@example.com'; Result = 'Assigned' })
$record.Checks.Add(@{ Project = 'emea-tes-team'; Check = 'logging.googleapis.com'; Result = 'Enabled' })

$md = Format-EntroGcpRunReport -Record $record -Pending @(@{ Title = 'Upload the key in Entro'; Detail = 'Upload the JSON key and the organization domain.'; Done = $false })
Assert-True ($md.StartsWith('# Entro GCP')) 'report is a markdown document'
Assert-True ($md -match 'finished successfully') 'a finished run says so in the opening'
Assert-True ($md.Contains('Enabled `secretmanager.googleapis.com` on project `tes-sea-trial`')) 'the opening lists each API this run turned on'
Assert-True ($md.Contains('Granted `roles/cloudasset.viewer` to `entro-automatic-onboard@emea-tes-team.iam.gserviceaccount.com` on organization `416188549418`')) 'the opening names the binding this run added'
Assert-True ($md.Contains('Created a JSON key for `entro-automatic-onboard@emea-tes-team.iam.gserviceaccount.com` and saved it to `/tmp/entro-reader-key.json`')) 'the opening names the key file this run saved'
Assert-True ($md.Contains('| `/tmp/entro-reader-key.json` | Created in this run |')) 'the key section names the file and the result'
Assert-True ($md -notmatch 'BEGIN PRIVATE KEY') 'the report does not include the key'
Assert-True ($md.Contains('Custom role `entroLoggingRole_724`')) 'the custom role is named'
Assert-True ($md.Contains('| `logging.logs.list` |')) 'the custom role permissions are listed'
Assert-True ($md.Contains('| roles/owner for admin@example.com | Assigned |')) 'the pre-check says whether the signed-in user has the role'
Assert-True ($md.Contains('- [ ] **Upload the key in Entro.**')) 'open operator actions stay in the report'
Assert-True ($md -notmatch 'Starting role and log check') 'the old plain-text log is gone'

$open = Get-EntroGcpRunRecord -Context @{}
$open.Actor = 'admin@example.com'
$open.OrganizationId = '416188549418'
$open.Checks.Add(@{ Project = 'emea-tes-team'; Check = 'logging.googleapis.com'; Result = 'Enabled' })
$partial = Format-EntroGcpRunReport -Record $open
Assert-True ($partial -match 'has not finished') 'a check written before the run finishes says it is not the change record'
Assert-True ($partial -notmatch 'What this run changed') 'an unfinished check does not claim that nothing changed'

$dir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-report-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir | Out-Null
$legacy = Join-Path $dir 'entro-gcp-pre-onboarding-report.txt'
Set-Content -LiteralPath $legacy -Value 'old log' -Encoding utf8
$report = Join-Path $dir 'entro-gcp-report.md'
try {
    Write-EntroGcpRunReport -Context $ctx -Path $report -Pending @(@{ Title = 'Org audit logs'; Detail = 'Enable audit logs.'; Done = $true })
    $written = Get-Content -LiteralPath $report -Raw
    Assert-True ($written -match 'finished successfully') 'the file on disk is the finished report'
    Assert-True ($written.Contains('- [x] **Org audit logs.**')) 'a completed operator action is checked'
    Assert-True (-not (Test-Path -LiteralPath $legacy)) 'the old text report is removed'
}
finally {
    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
}

$script:Calls = [System.Collections.Generic.List[string]]::new()
function global:Invoke-GCloud {
    param([string[]]$GcloudArgs)
    $line = $GcloudArgs -join ' '
    $script:Calls.Add($line)
    if ($line -match '^asset search-all-resources .*Folder') { return '' }
    if ($line -match '^asset search-all-resources .*Project') { return 'projects/proj-a' }
    if ($line -match '^services list') {
        if ($line -match 'project=host-proj') { return "iam.googleapis.com`ncloudasset.googleapis.com" }
        return 'iam.googleapis.com'
    }
    if ($line -match '^services enable') { return '' }
    throw "unexpected gcloud call: $line"
}
$apiCtx = @{}
Invoke-EntroGcpEnableApis -OrganizationId '416188549418' -ProjectId 'host-proj' -Mode apply -Context $apiCtx
$apiRecord = Get-EntroGcpRunRecord -Context $apiCtx
$hostIam = @($apiRecord.Apis | Where-Object { $_.Project -eq 'host-proj' -and $_.Service -eq 'iam.googleapis.com' })[0]
$hostAsset = @($apiRecord.Apis | Where-Object { $_.Project -eq 'host-proj' -and $_.Service -eq 'cloudasset.googleapis.com' })[0]
$orgSecret = @($apiRecord.Apis | Where-Object { $_.Project -eq 'proj-a' -and $_.Service -eq 'secretmanager.googleapis.com' })[0]
Assert-Equal 'Already enabled' $hostIam.Result 'an API that was already on is not described as a change'
Assert-Equal 'Already enabled' $hostAsset.Result 'a second already-enabled API is recorded on its own row'
Assert-Equal 'Enabled in this run' $orgSecret.Result 'an API that was off is recorded as enabled'
Assert-True (@($script:Calls | Where-Object { $_ -match '^services enable' -and $_ -match 'secretmanager.googleapis.com' -and $_ -match 'project=proj-a' }).Count -eq 1) 'only the missing API is enabled'
Assert-True (@($script:Calls | Where-Object { $_ -match '^services enable' -and $_ -match 'project=host-proj' -and $_ -match 'iam.googleapis.com' }).Count -eq 0) 'an API that is already enabled is not enabled again'
Remove-Item Function:global:Invoke-GCloud

Write-Host "PASS ($script:AssertionCount assertions)"
