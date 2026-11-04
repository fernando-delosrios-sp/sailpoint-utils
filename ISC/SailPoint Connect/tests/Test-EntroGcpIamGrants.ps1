#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-IscModule -Path (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force
Import-IscModule -Path (Join-Path $wizardRoot 'modules/ISC.EntroGcp.psm1') -Force

$org = '416188549418'
$project = 'emea-tes-team'
$sa = 'entro-automatic-onboard'
$member = "serviceAccount:$sa@$project.iam.gserviceaccount.com"
$env:ENTRO_GCP_IAM_STATE = Join-Path ([System.IO.Path]::GetTempPath()) "entro-iam-test-$([guid]::NewGuid()).state"

$script:Bound = [System.Collections.Generic.HashSet[string]]::new()
$script:Roles = @{}
$script:Calls = [System.Collections.Generic.List[string]]::new()
$script:FailOnRole = $null

function global:Invoke-GCloud {
    param([string[]]$GcloudArgs)
    $line = $GcloudArgs -join ' '
    $script:Calls.Add($line)
    $arg = { param($prefix) ($GcloudArgs | Where-Object { $_ -like "$prefix*" } | Select-Object -First 1) -replace "^$([regex]::Escape($prefix))", '' }
    switch -Regex ($line) {
        '^organizations get-iam-policy .*--filter=bindings\.role=' {
            $role = & $arg '--filter=bindings.role='
            if ($script:Bound.Contains($role)) { return $member } else { return '' }
        }
        '^organizations get-iam-policy .*--filter=bindings\.members=' { return (@($script:Bound) -join "`n") }
        '^organizations add-iam-policy-binding' {
            $role = & $arg '--role='
            if ($role -eq $script:FailOnRole) { throw "simulated failure binding $role" }
            $null = $script:Bound.Add($role); return ''
        }
        '^organizations remove-iam-policy-binding' { $null = $script:Bound.Remove((& $arg '--role=')); return '' }
        '^iam roles describe' {
            $id = $GcloudArgs[3]
            if (-not $script:Roles.ContainsKey($id)) { throw "NOT_FOUND $id" }
            return ($script:Roles[$id] -join ';')
        }
        '^iam roles create' { $script:Roles[$GcloudArgs[3]] = @((& $arg '--permissions=') -split ','); return '' }
        '^iam roles update' { $script:Roles[$GcloudArgs[3]] = @((& $arg '--permissions=') -split ','); return '' }
        '^iam roles delete' { $script:Roles.Remove($GcloudArgs[3]); return '' }
        default { throw "unexpected gcloud call: $line" }
    }
}

$iam = @{ OrganizationId = $org; ProjectId = $project; ServiceAccountName = $sa }
function Get-CreatedRoleCount { @($script:Calls | Where-Object { $_ -like 'iam roles create*' }).Count }

try {
    # An interrupted run keeps what it already did in the state file.
    $script:FailOnRole = 'roles/iam.supportUser'
    $failed = $false
    try { Invoke-EntroGcpIamGrants @iam -Mode apply 6>$null } catch { $failed = $true }
    Assert-True $failed 'simulated mid-run failure surfaces'
    Assert-True (Test-Path -LiteralPath $env:ENTRO_GCP_IAM_STATE) 'state file is written before the failure'
    $stateText = Get-Content -LiteralPath $env:ENTRO_GCP_IAM_STATE -Raw
    Assert-True ($stateText -match 'custom-role\tentroLoggingRole_\d+') 'state records the created custom role'
    Assert-True ($stateText -match 'roles/secretmanager\.viewer') 'state records bindings added before the failure'
    $roleId = ([regex]::Match($stateText, 'entroLoggingRole_\d+')).Value

    # Rerun resumes from the state file instead of refusing.
    $script:FailOnRole = $null
    Invoke-EntroGcpIamGrants @iam -Mode apply 6>$null
    Assert-Equal 1 (Get-CreatedRoleCount) 'resume reuses the recorded custom role'
    Assert-True (Test-EntroGcpIamGrantsComplete @iam) 'resume completes every grant'
    Assert-True ((Get-Content -LiteralPath $env:ENTRO_GCP_IAM_STATE -Raw) -match 'roles/iam\.supportUser') 'state records the bindings added on resume'

    # A complete setup is a no-op, even with a state file present.
    $before = @($script:Calls | Where-Object { $_ -match 'add-iam-policy-binding|roles (create|update)' }).Count
    Invoke-EntroGcpIamGrants @iam -Mode apply 6>$null
    $after = @($script:Calls | Where-Object { $_ -match 'add-iam-policy-binding|roles (create|update)' }).Count
    Assert-Equal $before $after 'complete setup makes no changes'

    # Lost state file: adopt the bound custom role instead of minting a second one.
    Remove-Item -LiteralPath $env:ENTRO_GCP_IAM_STATE -Force
    $null = $script:Bound.Remove('roles/cloudasset.viewer')
    Invoke-EntroGcpIamGrants @iam -Mode apply 6>$null
    Assert-Equal 1 (Get-CreatedRoleCount) 'lost state adopts the already-bound custom role'
    Assert-True (Test-EntroGcpIamGrantsComplete @iam) 'lost state still completes missing grants'

    # Rollback removes everything the state file recorded.
    Remove-Item -LiteralPath $env:ENTRO_GCP_IAM_STATE -Force
    $script:Bound.Clear(); $script:Roles.Clear(); $script:Calls.Clear()
    Invoke-EntroGcpIamGrants @iam -Mode apply 6>$null
    Invoke-EntroGcpIamGrants @iam -Mode rollback 6>$null
    Assert-Equal 0 $script:Bound.Count 'rollback removes every recorded binding'
    Assert-Equal 0 $script:Roles.Count 'rollback deletes the recorded custom role'
    Assert-True (-not (Test-Path -LiteralPath $env:ENTRO_GCP_IAM_STATE)) 'rollback removes the state file'
    Assert-True (-not [string]::IsNullOrEmpty($roleId)) 'custom role id was captured'
}
finally {
    if ($env:ENTRO_GCP_IAM_STATE -and (Test-Path -LiteralPath $env:ENTRO_GCP_IAM_STATE)) {
        Remove-Item -LiteralPath $env:ENTRO_GCP_IAM_STATE -Force
    }
    Remove-Item Env:ENTRO_GCP_IAM_STATE -ErrorAction SilentlyContinue
    Remove-Item Function:global:Invoke-GCloud -ErrorAction SilentlyContinue
}

$stateDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-state-dir-{0}" -f [guid]::NewGuid().ToString('N'))
$legacyRoot = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$legacyName = 'entro-gcp-iam-org-test-proj-test-sa-test.state'
$legacy = Join-Path $legacyRoot $legacyName
try {
    Set-Content -LiteralPath $legacy -Value "custom-role`tentroLoggingRole_9" -Encoding utf8
    $resolved = & (Get-Module ISC.EntroGcp) {
        param($Directory)
        Get-EntroGcpIamStatePath -OrganizationId 'org-test' -ProjectId 'proj-test' -ServiceAccountName 'sa-test' -Directory $Directory
    } $stateDir
    $dest = Join-Path $stateDir $legacyName
    Assert-Equal $dest $resolved 'state file lives in the integration folder'
    Assert-True (Test-Path -LiteralPath $dest) 'legacy temp state is moved into that folder'
    Assert-True (-not (Test-Path -LiteralPath $legacy)) 'legacy temp state is removed'
    Assert-True ((Get-Content -LiteralPath $dest -Raw) -match 'entroLoggingRole_9') 'moved state keeps its contents'
}
finally {
    if (Test-Path -LiteralPath $legacy) { Remove-Item -LiteralPath $legacy -Force }
    if (Test-Path -LiteralPath $stateDir) { Remove-Item -LiteralPath $stateDir -Recurse -Force }
}

Write-Host "PASS ($script:AssertionCount assertions)"
