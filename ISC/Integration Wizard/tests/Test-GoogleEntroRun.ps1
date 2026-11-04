#Requires -Version 7
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_TestHelpers.ps1')

$wizardRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $wizardRoot 'modules/IW.Core.psm1') -Force
Import-Module (Join-Path $wizardRoot 'modules/Definitions/Google.Entro.psm1') -Force
Register-GoogleEntroDefinitions

$def = Get-IntegrationWizardDefinition -Id 'google-gcp-entro'
Assert-True ($null -ne $def) 'GCP Entro definition is registered'

$ctx = @{
    OrganizationId     = '416188549418'
    ProjectId          = 'tes-sea-trial'
    Method             = 'PrivateKey'
    ServiceAccountName = 'entro-automatic-onboard'
    OutputDirectory    = "/tmp/o'brien"
}
$steps = @(& $def.Steps $ctx)
Assert-Equal 7 @($steps).Count 'PrivateKey run has precheck, APIs, service account, IAM, key, Entro upload, and audit'
Assert-Equal 'precheck,apis,sa-create,iam,key,entro-upload,audit' (($steps | ForEach-Object { $_.Id }) -join ',') 'PrivateKey steps run in onboarding order'

function Get-EntroStep {
    param($All, [string]$Id)
    @($All) | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
}

$pre = Get-EntroStep $steps 'precheck'
Assert-Equal 'Ensure' $pre.Kind 'precheck is executed'
$preScript = & $pre.BuildScript $ctx
Assert-True ($preScript -match 'Invoke-EntroGcpPreOnboardingCheck') 'precheck script runs the Entro check'
Assert-True ($preScript.Contains("'/tmp/o''brien/entro-gcp-report.md'")) 'report path is the markdown file'
Assert-True ($preScript -notmatch 'Mode apply') 'precheck does not apply changes'

$apiScript = & (Get-EntroStep $steps 'apis').BuildScript $ctx
$applyAt = $apiScript.IndexOf('Mode apply')
$verifyAt = $apiScript.IndexOf('Mode verify')
Assert-True ($applyAt -ge 0 -and $applyAt -lt $verifyAt) 'API step applies, then verifies'
Assert-True ($apiScript -match '416188549418') 'API step receives the organization id'
Assert-True ($apiScript -match 'tes-sea-trial') 'API step receives the host project'

$sa = Get-EntroStep $steps 'sa-create'
Assert-True ($sa.ContainsKey('Probe')) 'service account step checks for an existing account'
$saScript = & $sa.BuildScript $ctx
Assert-True ($saScript -match 'Invoke-EntroGcpEnsureServiceAccount') 'service account step creates the reader account'
Assert-True ($saScript -match 'entro-automatic-onboard') 'service account step uses the requested name'

$iam = Get-EntroStep $steps 'iam'
Assert-True ($iam.ContainsKey('Probe')) 'IAM step checks whether the grants are already in place'
$iamScript = & $iam.BuildScript $ctx
Assert-True ($iamScript -match 'Mode apply') 'IAM script applies the grants'
Assert-True ($iamScript -match 'StateDirectory') 'IAM script keeps state in the integration folder'
Assert-True ($iamScript.Contains("-StateDirectory '/tmp/o''brien'")) 'IAM state directory is single-quoted'

$key = Get-EntroStep $steps 'key'
Assert-Equal 'Ensure' $key.Kind 'private key is created with the signed-in gcloud session'
Assert-True ($key.ContainsKey('Run')) 'the wizard creates the key'
$keyScript = & $key.BuildScript $ctx
Assert-True ($keyScript -match 'Invoke-EntroGcpEnsureServiceAccountKey') 'key script creates the JSON key'
Assert-True ($keyScript.Contains("'/tmp/o''brien/entro-reader-key.json'")) 'key script writes into the integration folder'
Assert-True ($keyScript -notmatch 'Get-Content') 'key script does not read the key back'
Assert-True ($keyScript -notmatch 'private_key') 'key script does not embed key material'

$upload = Get-EntroStep $steps 'entro-upload'
Assert-Equal 'Manual' $upload.Kind 'uploading the key into Entro stays an operator action'
Assert-True ($upload.Manual -match 'Entro GCP onboarding') 'the upload step names Entro onboarding'
Assert-True ($upload.Manual -match [regex]::Escape("/tmp/o'brien/entro-reader-key.json")) 'the upload step points at the key file'
Assert-True ($upload.Manual -notmatch 'keys create') 'the upload step is not the key command'

$audit = Get-EntroStep $steps 'audit'
Assert-Equal 'Manual' $audit.Kind 'audit logs stay a console step'
Assert-True ($audit.Manual -match 'Secret Manager') 'audit step names the console change'

$defaultCtx = @{
    OrganizationId  = '416188549418'
    ProjectId       = 'tes-sea-trial'
    Method          = 'PrivateKey'
    OutputDirectory = '/tmp/entro-out'
}
$defaultKey = Get-EntroStep @(& $def.Steps $defaultCtx) 'key'
$defaultKeyScript = & $defaultKey.BuildScript $defaultCtx
Assert-True ($defaultKeyScript -match 'entro-automatic-onboard') 'omitted service account name uses the Entro default'

$wifCtx = @{
    OrganizationId     = '416188549418'
    ProjectId          = 'tes-sea-trial'
    Method             = 'WorkloadIdentity'
    ServiceAccountName = 'entro-automatic-onboard'
    OutputDirectory    = '/tmp/entro-out'
}
$wifSteps = @(& $def.Steps $wifCtx)
Assert-Equal 'precheck,apis,sa-create,iam,wif,audit' (($wifSteps | ForEach-Object { $_.Id }) -join ',') 'Workload Identity skips private key creation'
$wif = Get-EntroStep $wifSteps 'wif'
Assert-Equal 'Manual' $wif.Kind 'Workload Identity handoff is an operator action'
Assert-True ($wif.Manual -match 'workload identity pool') 'Workload Identity run tells the operator what is left'
Assert-True ($wif.Manual -notmatch 'keys create') 'Workload Identity run does not create a private key'

Import-Module (Join-Path $wizardRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $wizardRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-OperatorConsole -NonInteractive
$keyDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-key-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $keyDir | Out-Null
$keyFile = Join-Path $keyDir 'entro-reader-key.json'
$script:KeyCreates = 0
function global:Invoke-GCloud {
    param([string[]]$GcloudArgs, [switch]$ExpectJson)
    $line = $GcloudArgs -join ' '
    if ($line -match 'keys create') {
        $script:KeyCreates++
        $path = $GcloudArgs[4]
        @{
            type          = 'service_account'
            client_email  = 'entro-automatic-onboard@tes-sea-trial.iam.gserviceaccount.com'
            private_key   = "-----BEGIN PRIVATE KEY-----`nnot-a-real-key`n-----END PRIVATE KEY-----`n"
        } | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding utf8
        return 'created key'
    }
    throw "unexpected gcloud call: $line"
}
try {
    $keyCtx = @{}
    Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $keyFile -Context $keyCtx
    $created = Get-EntroGcpRunRecord -Context $keyCtx
    Assert-Equal 'Created in this run' $created.KeyResult 'a missing key file is created'
    Assert-Equal $keyFile $created.KeyPath 'the report records the key path'
    Assert-Equal 1 $script:KeyCreates 'gcloud keys create runs once'
    $again = @{}
    Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $keyFile -Context $again
    Assert-Equal 'Already on disk' (Get-EntroGcpRunRecord -Context $again).KeyResult 'an existing key file is reused'
    Assert-Equal 1 $script:KeyCreates 'a second run does not mint another key'
    $blockedDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-key-blocked-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $blockedDir | Out-Null
    $blockedFile = Join-Path $blockedDir 'entro-reader-key.json'
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        if (($GcloudArgs -join ' ') -match 'keys create') {
            Set-Content -LiteralPath $GcloudArgs[4] -Value '' -Encoding utf8
            throw 'gcloud iam service-accounts keys create failed: constraints/iam.managed.disableServiceAccountKeyCreation'
        }
        throw 'unexpected gcloud call'
    }
    $blocked = @{}
    $null = Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $blockedFile -Context $blocked
    $blockedRecord = Get-EntroGcpRunRecord -Context $blocked
    Assert-Equal 'Blocked by organization policy' $blockedRecord.KeyResult 'an org policy refusal is recorded'
    Assert-True (-not (Test-Path -LiteralPath $blockedFile)) 'a failed key create does not leave an empty file'
    Assert-True ($blockedRecord.KeyGuidance -match 'roles/orgpolicy.policyAdmin') 'the refusal names who can change the policy'
    Assert-True ($blockedRecord.KeyGuidance -match 'enforce: false') 'the refusal shows the project override'
    Assert-True ($blockedRecord.KeyGuidance -match 'projects/tes-sea-trial/policies/iam.managed.disableServiceAccountKeyCreation') 'the override names this project and this constraint'
    Assert-True ($blockedRecord.KeyGuidance -match '15 minutes') 'the refusal says to wait for the policy to take effect'
    $other = Get-EntroGcpPreconditionGuidance -ErrorMessage 'FAILED_PRECONDITION: constraints/iam.disableServiceAccountCreation' -ProjectId 'host-proj' -Email 'reader@host-proj.iam.gserviceaccount.com'
    Assert-True ($other -match 'constraints/iam.disableServiceAccountCreation') 'another precondition names its constraint'
    Assert-True ($other -match 'roles/orgpolicy.policyAdmin') 'another precondition names the organization policy role'
    Assert-True ($other -notmatch 'enforce: false') 'another precondition does not reuse the key-creation override'
    Assert-True ($null -eq (Get-EntroGcpPreconditionGuidance -ErrorMessage 'PERMISSION_DENIED: not a precondition' -ProjectId 'host-proj' -Email 'reader@host-proj.iam.gserviceaccount.com')) 'a different gcloud error is not treated as a precondition'
    Assert-True ($blockedRecord.KeyGuidance -match 'did not change the policy') 'a non-interactive run does not apply the override'

    $applyDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-key-apply-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $applyDir | Out-Null
    $applyFile = Join-Path $applyDir 'entro-reader-key.json'
    $script:KeyAttempts = 0
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        $line = $GcloudArgs -join ' '
        if ($line -match 'keys create') {
            $script:KeyAttempts++
            if ($script:KeyAttempts -eq 1) {
                Set-Content -LiteralPath $GcloudArgs[4] -Value '' -Encoding utf8
                throw 'FAILED_PRECONDITION: constraints/iam.managed.disableServiceAccountKeyCreation'
            }
            @{
                type         = 'service_account'
                client_email = 'entro-automatic-onboard@tes-sea-trial.iam.gserviceaccount.com'
                private_key  = "-----BEGIN PRIVATE KEY-----`nnot-a-real-key`n-----END PRIVATE KEY-----`n"
            } | ConvertTo-Json | Set-Content -LiteralPath $GcloudArgs[4] -Encoding utf8
            return 'created key'
        }
        if ($line -match '^services enable orgpolicy.googleapis.com') { return '' }
        if ($line -match '^org-policies set-policy') { return '' }
        throw "unexpected gcloud call: $line"
    }
    $applyCtx = @{ ApplyPreconditionFix = $true }
    $null = Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $applyFile -Context $applyCtx
    $applied = Get-EntroGcpRunRecord -Context $applyCtx
    Assert-Equal 'Created in this run' $applied.KeyResult 'yes applies the override and retries the key'
    Assert-Equal 'Applied in this run' $applied.KeyPolicyResult 'the project override is part of the run record'
    Assert-Equal 2 $script:KeyAttempts 'the key is retried after the override'
    $policyFile = Join-Path $applyDir 'allow-service-account-keys.yaml'
    $policy = Get-Content -LiteralPath $policyFile -Raw
    Assert-True ($policy -match 'projects/tes-sea-trial/policies/iam.managed.disableServiceAccountKeyCreation') 'the policy file names this project'
    Assert-True ($policy -match 'enforce: false') 'the policy file turns the constraint off for this project'
    Remove-Item -LiteralPath $applyDir -Recurse -Force
    Remove-Item -LiteralPath $blockedDir -Recurse -Force
    $mode = (Get-Item -LiteralPath $keyFile).UnixFileMode
    Assert-True (($mode -band [System.IO.UnixFileMode]::GroupRead) -eq 0) 'the key file is not group-readable'
}
finally {
    Remove-Item Function:global:Invoke-GCloud -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $keyDir) { Remove-Item -LiteralPath $keyDir -Recurse -Force }
}

Write-Host "PASS ($script:AssertionCount assertions)"
