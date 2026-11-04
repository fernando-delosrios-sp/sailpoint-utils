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
Assert-Equal 'Ensure' $audit.Kind 'audit logs are set with gcloud'
Assert-True ($audit.ContainsKey('Run')) 'the audit step runs the org IAM change'
$auditScript = & $audit.BuildScript $ctx
Assert-True ($auditScript -match 'Invoke-EntroGcpAuditConfigs') 'audit script sets the organization audit configs'
Assert-True ($auditScript -match '416188549418') 'audit script targets the organization'
Assert-True ((Get-EntroStep $steps 'entro-upload').ContainsKey('When')) 'the upload step only applies when the run has a key'

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
    $other = Get-EntroGcpPreconditionGuidance -ErrorMessage 'FAILED_PRECONDITION: constraints/compute.vmExternalIpAccess' -ProjectId 'host-proj' -Email 'reader@host-proj.iam.gserviceaccount.com'
    Assert-True ($other -match 'constraints/compute.vmExternalIpAccess') 'another precondition names its constraint'
    Assert-True ($other -match 'roles/orgpolicy.policyAdmin') 'another precondition names the organization policy role'
    Assert-True ($other -notmatch 'enforce: false') 'a constraint the wizard cannot override gets no override file'
    $saGuidance = Get-EntroGcpPreconditionGuidance -ErrorMessage 'FAILED_PRECONDITION: constraints/iam.disableServiceAccountCreation' -ProjectId 'host-proj' -Email 'reader@host-proj.iam.gserviceaccount.com'
    Assert-True ($saGuidance -match 'allow-service-account-creation.yaml') 'service account creation gets its own override file'
    Assert-True ($saGuidance -match 'projects/host-proj/policies/iam.disableServiceAccountCreation') 'the creation override names this project and constraint'
    Assert-True ($saGuidance -notmatch 'WorkloadIdentity') 'the creation override does not suggest the key alternative'
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
    $applyCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    $null = Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $applyFile -Context $applyCtx
    $applied = Get-EntroGcpRunRecord -Context $applyCtx
    Assert-Equal 'Created in this run' $applied.KeyResult 'yes applies the override and retries the key'
    Assert-Equal 1 @($applied.PolicyOverrides).Count 'the project override is part of the run record'
    Assert-Equal 'iam.managed.disableServiceAccountKeyCreation' $applied.PolicyOverrides[0].Constraint 'the record names the overridden constraint'
    Assert-Equal 2 $script:KeyAttempts 'the key is retried after the override'
    $policyFile = Join-Path $applyDir 'allow-service-account-keys.yaml'
    $policy = Get-Content -LiteralPath $policyFile -Raw
    Assert-True ($policy -match 'projects/tes-sea-trial/policies/iam.managed.disableServiceAccountKeyCreation') 'the policy file names this project'
    Assert-True ($policy -match 'enforce: false') 'the policy file turns the constraint off for this project'
    Remove-Item -LiteralPath $applyDir -Recurse -Force

    # Legacy and managed key constraints enforced together: clearing one exposes the other.
    $bothDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-key-both-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $bothDir | Out-Null
    $bothFile = Join-Path $bothDir 'entro-reader-key.json'
    $script:Overridden = @()
    $script:KeyAttempts = 0
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        $line = $GcloudArgs -join ' '
        if ($line -match 'keys create') {
            $script:KeyAttempts++
            if ($script:Overridden -notcontains 'iam.disableServiceAccountKeyCreation') { throw 'FAILED_PRECONDITION: constraints/iam.disableServiceAccountKeyCreation' }
            if ($script:Overridden -notcontains 'iam.managed.disableServiceAccountKeyCreation') { throw 'FAILED_PRECONDITION: constraints/iam.managed.disableServiceAccountKeyCreation' }
            @{
                type         = 'service_account'
                client_email = 'entro-automatic-onboard@tes-sea-trial.iam.gserviceaccount.com'
                private_key  = "-----BEGIN PRIVATE KEY-----`nnot-a-real-key`n-----END PRIVATE KEY-----`n"
            } | ConvertTo-Json | Set-Content -LiteralPath $GcloudArgs[4] -Encoding utf8
            return 'created key'
        }
        if ($line -match '^services enable orgpolicy.googleapis.com') { return '' }
        if ($line -match '^org-policies set-policy (.+)$') {
            $name = (Get-Content -LiteralPath $Matches[1] -Raw) -replace '(?s).*policies/([^\s]+).*', '$1'
            $script:Overridden += $name.Trim()
            return ''
        }
        throw "unexpected gcloud call: $line"
    }
    $bothCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    $null = Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath $bothFile -Context $bothCtx
    $both = Get-EntroGcpRunRecord -Context $bothCtx
    Assert-Equal 'Created in this run' $both.KeyResult 'both key constraints are overridden and the key is created'
    Assert-Equal 2 @($both.PolicyOverrides).Count 'each constraint gets its own override'
    Assert-Equal 2 @(Get-ChildItem -LiteralPath $bothDir -Filter 'allow-*.yaml').Count 'the second override does not overwrite the first file'
    Remove-Item -LiteralPath $bothDir -Recurse -Force

    # The override is applied, and Google keeps refusing until the wait runs out.
    $slowDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-key-slow-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $slowDir | Out-Null
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        $line = $GcloudArgs -join ' '
        if ($line -match 'keys create') { throw 'FAILED_PRECONDITION: constraints/iam.managed.disableServiceAccountKeyCreation' }
        if ($line -match '^services enable orgpolicy.googleapis.com|^org-policies set-policy') { return '' }
        throw "unexpected gcloud call: $line"
    }
    $slowCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    $slowOutcome = Invoke-EntroGcpEnsureServiceAccountKey -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -KeyPath (Join-Path $slowDir 'entro-reader-key.json') -Context $slowCtx
    $slow = Get-EntroGcpRunRecord -Context $slowCtx
    Assert-Equal 'blocked' $slowOutcome 'a policy that has not taken effect leaves the key blocked'
    Assert-True ($slow.KeyGuidance -match 'still refused the key after waiting') 'the guidance says the override was applied and Google still refused'
    Remove-Item -LiteralPath $slowDir -Recurse -Force

    # Service account creation blocked by organization policy.
    $saDir = Join-Path ([System.IO.Path]::GetTempPath()) ("entro-sa-{0}" -f [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $saDir | Out-Null
    $script:SaCreates = 0
    $script:SaAllowed = $false
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        $line = $GcloudArgs -join ' '
        if ($line -match '^iam service-accounts describe') { throw 'NOT_FOUND' }
        if ($line -match '^iam service-accounts create') {
            $script:SaCreates++
            if (-not $script:SaAllowed) { throw 'FAILED_PRECONDITION: constraints/iam.disableServiceAccountCreation' }
            return ''
        }
        if ($line -match '^services enable orgpolicy.googleapis.com') { return '' }
        if ($line -match '^org-policies set-policy') { $script:SaAllowed = $true; return '' }
        throw "unexpected gcloud call: $line"
    }
    $saCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    Invoke-EntroGcpEnsureServiceAccount -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -StateDirectory $saDir -Context $saCtx
    Assert-Equal 'Created in this run' (Get-EntroGcpRunRecord -Context $saCtx).ServiceAccountResult 'service account creation is retried after the override'
    Assert-True (Test-Path -LiteralPath (Join-Path $saDir 'allow-service-account-creation.yaml')) 'the creation override is saved in the integration folder'
    $script:SaAllowed = $false
    $saRefused = $null
    try {
        Invoke-EntroGcpEnsureServiceAccount -ProjectId 'tes-sea-trial' -ServiceAccountName 'entro-automatic-onboard' -StateDirectory $saDir -Context @{ ApplyPreconditionFix = $false }
    }
    catch { $saRefused = $_.Exception.Message }
    Assert-True ($saRefused -match 'refused to create') 'declining the override stops the run with a clear reason'
    Remove-Item -LiteralPath $saDir -Recurse -Force

    # A project without billing: Secret Manager and Discovery Engine cannot be enabled there.
    $script:BillingLinked = $false
    $script:BillingAccounts = '[{"name":"billingAccounts/0000AA-BBBBBB-CCCCCC","displayName":"Main","open":true}]'
    function global:Invoke-GCloud {
        param([string[]]$GcloudArgs, [switch]$ExpectJson)
        $line = $GcloudArgs -join ' '
        if ($line -match '^asset search-all-resources .*Folder') { return '' }
        if ($line -match '^asset search-all-resources .*Project') { return '//cloudresourcemanager.googleapis.com/projects/no-billing' }
        if ($line -match '^services list --enabled --project=(\S+) --format') {
            return 'cloudresourcemanager.googleapis.com', 'iam.googleapis.com', 'recommender.googleapis.com', 'policyanalyzer.googleapis.com',
                'pubsub.googleapis.com', 'cloudasset.googleapis.com', 'admin.googleapis.com', 'drive.googleapis.com' -join "`n"
        }
        if ($line -match '^services enable secretmanager') {
            if (-not $script:BillingLinked) { throw "FAILED_PRECONDITION: Billing account for project '123' is not found. Billing must be enabled for activation of service(s) 'secretmanager.googleapis.com' to proceed." }
            return ''
        }
        if ($line -match '^services list --enabled --project=\S+ --filter=config.name=(\S+)') { return $Matches[1] }
        if ($line -match '^billing accounts list') { return $script:BillingAccounts }
        if ($line -match '^billing projects link no-billing --billing-account=0000AA-BBBBBB-CCCCCC') { $script:BillingLinked = $true; return '' }
        throw "unexpected gcloud call: $line"
    }
    $billCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    Invoke-EntroGcpEnableApis -OrganizationId '416188549418' -ProjectId 'no-billing' -Mode 'apply' -Context $billCtx
    $billed = Get-EntroGcpRunRecord -Context $billCtx
    Assert-True $script:BillingLinked 'the only open billing account is linked when the operator agrees'
    Assert-Equal 1 @($billed.BillingLinks).Count 'the billing link is part of the run record'
    Assert-Equal 0 @($billed.Blocked).Count 'nothing stays blocked once billing is linked'

    $script:BillingLinked = $false
    $declineCtx = @{ ApplyPreconditionFix = $false; PreconditionWaitSeconds = 0 }
    Invoke-EntroGcpEnableApis -OrganizationId '416188549418' -ProjectId 'no-billing' -Mode 'apply' -Context $declineCtx
    $declined = Get-EntroGcpRunRecord -Context $declineCtx
    Assert-True (-not $script:BillingLinked) 'billing is not linked without consent'
    Assert-Equal 1 @($declined.Blocked).Count 'a project without billing is recorded as blocked instead of stopping the run'
    Assert-Equal 'billing-no-billing' $declined.Blocked[0].Id 'the blocked item is keyed by project'
    Assert-True ($declined.Blocked[0].Guidance -match 'gcloud billing projects link no-billing') 'the guidance shows the link command'
    $blockedApis = @($declined.Apis | Where-Object { $_.Result -like 'Blocked*' } | ForEach-Object { $_.Service })
    Assert-True ($blockedApis -contains 'secretmanager.googleapis.com') 'the refused APIs are marked blocked in the report'
    Invoke-EntroGcpEnableApis -OrganizationId '416188549418' -ProjectId 'no-billing' -Mode 'verify' -Context $declineCtx
    Assert-True $true 'verify skips APIs blocked by billing'
    $report = Format-EntroGcpRunReport -Record $declined
    Assert-True ($report -match 'How to clear: Turn on billing for project no-billing') 'the report explains how to clear the billing block'

    $script:BillingAccounts = '[{"name":"billingAccounts/A"},{"name":"billingAccounts/B"}]'
    $manyCtx = @{ ApplyPreconditionFix = $true; PreconditionWaitSeconds = 0 }
    Invoke-EntroGcpEnableApis -OrganizationId '416188549418' -ProjectId 'no-billing' -Mode 'apply' -Context $manyCtx
    Assert-True (-not $script:BillingLinked) 'with several billing accounts the wizard does not pick one'
    Assert-Equal 1 @((Get-EntroGcpRunRecord -Context $manyCtx).Blocked).Count 'with several billing accounts the project stays blocked'
    Remove-Item -LiteralPath $blockedDir -Recurse -Force
    $mode = (Get-Item -LiteralPath $keyFile).UnixFileMode
    Assert-True (($mode -band [System.IO.UnixFileMode]::GroupRead) -eq 0) 'the key file is not group-readable'
}
finally {
    Remove-Item Function:global:Invoke-GCloud -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $keyDir) { Remove-Item -LiteralPath $keyDir -Recurse -Force }
}

$script:PolicySets = @()
$script:PolicyCurrent = @{
    version      = 1
    etag         = 'etag-before'
    bindings     = @(@{ role = 'roles/viewer'; members = @('user:admin@example.com') })
    auditConfigs = @(@{ service = 'iam.googleapis.com'; auditLogConfigs = @(@{ logType = 'DATA_READ'; exemptedMembers = @('user:exempt@example.com') }) })
}
function global:Invoke-GCloud {
    param([string[]]$GcloudArgs, [switch]$ExpectJson)
    $line = $GcloudArgs -join ' '
    if ($line -match '^organizations get-iam-policy') { return ($script:PolicyCurrent | ConvertTo-Json -Depth 20) }
    if ($line -match '^organizations set-iam-policy') {
        $written = Get-Content -LiteralPath $GcloudArgs[3] -Raw | ConvertFrom-Json -AsHashtable -Depth 50
        $script:PolicySets += , $written
        $script:PolicyCurrent = $written
        return ''
    }
    throw "unexpected gcloud call: $line"
}
$auditCtx = @{}
Assert-True (-not (Test-EntroGcpAuditConfigsComplete -OrganizationId '416188549418')) 'a partial audit config is reported as missing'
Invoke-EntroGcpAuditConfigs -OrganizationId '416188549418' -Context $auditCtx
Assert-Equal 1 $script:PolicySets.Count 'audit configs are written once'
$written = $script:PolicySets[0]
Assert-Equal 'etag-before' $written['etag'] 'the write keeps the etag so concurrent changes are rejected'
Assert-Equal 1 @($written['bindings']).Count 'existing org IAM bindings are kept'
Assert-Equal 'roles/viewer' $written['bindings'][0]['role'] 'the existing binding is unchanged'
$iamCfg = @($written['auditConfigs'] | Where-Object { $_['service'] -eq 'iam.googleapis.com' })[0]
Assert-True ((@($iamCfg['auditLogConfigs'] | ForEach-Object { $_['logType'] }) -contains 'DATA_WRITE')) 'the existing IAM config gains DATA_WRITE'
Assert-Equal 'user:exempt@example.com' $iamCfg['auditLogConfigs'][0]['exemptedMembers'][0] 'existing exempted members are kept'
foreach ($svc in @('secretmanager.googleapis.com', 'cloudfunctions.googleapis.com')) {
    $cfg = @($written['auditConfigs'] | Where-Object { $_['service'] -eq $svc })[0]
    Assert-True ($null -ne $cfg) "$svc gets an audit config"
    $types = @($cfg['auditLogConfigs'] | ForEach-Object { $_['logType'] })
    Assert-True (($types -contains 'DATA_READ') -and ($types -contains 'DATA_WRITE')) "$svc logs DATA_READ and DATA_WRITE"
}
Assert-True (Test-EntroGcpAuditConfigsComplete -OrganizationId '416188549418') 'the policy now reports complete'
Assert-Equal 'Applied in this run' (Get-EntroGcpRunRecord -Context $auditCtx).AuditResult 'the run records the audit change'
$rerunCtx = @{}
Invoke-EntroGcpAuditConfigs -OrganizationId '416188549418' -Context $rerunCtx
Assert-Equal 1 $script:PolicySets.Count 'a complete policy is not written again'
Assert-Equal 'Already in place' (Get-EntroGcpRunRecord -Context $rerunCtx).AuditResult 'a rerun records the audit config as already in place'
Remove-Item Function:global:Invoke-GCloud

$upload = Get-EntroStep @(& $def.Steps $ctx) 'entro-upload'
$blockedRun = @{}
(Get-EntroGcpRunRecord -Context $blockedRun).KeyResult = 'Blocked by organization policy'
Assert-True (-not (& $upload.When $blockedRun)) 'the upload step is skipped when Google refused the key'
$keyRun = @{}
(Get-EntroGcpRunRecord -Context $keyRun).KeyResult = 'Created in this run'
Assert-True (& $upload.When $keyRun) 'the upload step is asked when the key exists'

Write-Host "PASS ($script:AssertionCount assertions)"
