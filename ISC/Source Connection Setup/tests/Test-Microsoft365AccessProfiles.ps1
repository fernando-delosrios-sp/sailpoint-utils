$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    $script:AssertionCount++
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    $script:AssertionCount++
    if ($Expected -ne $Actual) {
        throw "Assertion failed: $Message. Expected '$Expected', got '$Actual'."
    }
}

$moduleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'modules'
Import-Module (Join-Path $moduleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $moduleRoot 'ISC.SailPointSdk.psm1') -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $moduleRoot 'ISC.Microsoft365AccessProfiles.psm1') -Force -WarningAction SilentlyContinue

# --- YAML env catalog ---
$yaml = @'
activeenvironment: emea-tes-team
authtype: pat
environments:
  emea-tes-team:
    authtype: pat
    baseurl: https://company24509-poc.api.identitynow-demo.com
    tenanturl: https://company24509-poc.identitynow-demo.com
  fernando:
    baseurl: https://company12926-poc.api.identitynow-demo.com
    tenanturl: https://company12926-poc.identitynow-demo.com
'@
$parsed = ConvertFrom-SailpointSimpleYaml -Content $yaml
Assert-Equal 'emea-tes-team' $parsed.ActiveEnvironment 'active environment parsed'
Assert-Equal 2 $parsed.Environments.Count 'two environments parsed'
$emea = @($parsed.Environments | Where-Object { $_.Name -eq 'emea-tes-team' } | Select-Object -First 1)
Assert-True ($emea.BaseUrl -like 'https://company24509-poc.api.*') 'emea baseurl parsed'

# --- Credential resolution order ---
$priorBase = $env:SAIL_BASE_URL
$priorId = $env:SAIL_CLIENT_ID
$priorSecret = $env:SAIL_CLIENT_SECRET
try {
    Remove-Item Env:SAIL_BASE_URL -ErrorAction SilentlyContinue
    Remove-Item Env:SAIL_CLIENT_ID -ErrorAction SilentlyContinue
    Remove-Item Env:SAIL_CLIENT_SECRET -ErrorAction SilentlyContinue
    Assert-True ($null -eq (Get-SailpointSdkConfigFromEnvironment)) 'no env credentials when unset'

    Set-SailpointProcessCredentials -BaseUrl 'https://example.api.identitynow.com' -ClientId 'id' -ClientSecret 'secret'
    $fromEnv = Get-SailpointSdkConfigFromEnvironment
    Assert-equal 'environment' $fromEnv.Source 'env credentials source'
    Assert-equal 'https://example.api.identitynow.com' $fromEnv.BaseUrl 'env base url'

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("sail-config-{0}.json" -f [guid]::NewGuid())
    @{ BaseURL = 'https://file.api.identitynow.com'; ClientId = 'file-id'; ClientSecret = 'file-secret' } |
        ConvertTo-Json | Set-Content -LiteralPath $tmp -Encoding UTF8
    $fromFile = Get-SailpointSdkConfigFromFile -Path $tmp
    Assert-equal 'config.json' $fromFile.Source 'file credentials source'
    Assert-equal 'file-id' $fromFile.ClientId 'file client id'
    Remove-Item -LiteralPath $tmp -Force
}
finally {
    if ($null -ne $priorBase) { $env:SAIL_BASE_URL = $priorBase } else { Remove-Item Env:SAIL_BASE_URL -ErrorAction SilentlyContinue }
    if ($null -ne $priorId) { $env:SAIL_CLIENT_ID = $priorId } else { Remove-Item Env:SAIL_CLIENT_ID -ErrorAction SilentlyContinue }
    if ($null -ne $priorSecret) { $env:SAIL_CLIENT_SECRET = $priorSecret } else { Remove-Item Env:SAIL_CLIENT_SECRET -ErrorAction SilentlyContinue }
}

# --- Entra source heuristic ---
Assert-True (Test-IsEntraIscSource -Source ([pscustomobject]@{ name = 'Entra Prod'; type = 'Microsoft Entra ID'; connector = 'microsoft-entra-id' })) 'entra source detected'
Assert-True (-not (Test-IsEntraIscSource -Source ([pscustomobject]@{ name = 'AD'; type = 'Active Directory - Direct'; connector = 'active-directory' }))) 'AD source rejected'

# --- Friendly name mapping ---
$csv = @'
Product_Display_Name,String_Id,GUID,Service_Plan_Name,Service_Plan_Id,Service_Plans_Included_Friendly_Names
Office 365 E3,ENTERPRISEPACK,6fd2c87f-b296-42f0-b197-1e91e994b900,FLOW_O365_P2,c1ec4a95-1f57-4f4a-8c5b-1d5f0b0c0f11,Flow for Office 365 (c1ec4a95-1f57-4f4a-8c5b-1d5f0b0c0f11)
Office 365 E3,ENTERPRISEPACK,6fd2c87f-b296-42f0-b197-1e91e994b900,TEAMS1,57ff2da0-773e-42df-b2af-ffb7a2317929,Microsoft Teams (57ff2da0-773e-42df-b2af-ffb7a2317929)
Microsoft Entra ID P1,AAD_PREMIUM,078d2b04-f1bd-4111-bbd4-b4b1b354cef4,AAD_PREMIUM,41781fb2-bc02-4b7c-bd55-b576c07bb09d,Microsoft Entra ID P1 (41781fb2-bc02-4b7c-bd55-b576c07bb09d)
Microsoft 365 Business Basic,O365_BUSINESS_ESSENTIALS,3b555118-da6a-4418-894f-7df1e2096870,YAMMER_ENTERPRISE,7547a3fe-08ee-4ccb-b430-5077c5041653,YAMMER_ENTERPRISE
Microsoft 365 Business Premium,SPB,cbdc14ab-d96c-4c30-b9f4-6ada7cdc1d46,YAMMER_ENTERPRISE,7547a3fe-08ee-4ccb-b430-5077c5041653,Yammer Enterprise
'@
$map = ConvertFrom-MicrosoftLicensingCsv -CsvText $csv
Assert-equal 'Yammer Enterprise' $map.ByPlanName['YAMMER_ENTERPRISE'] 'prefers human friendly over raw code'
Assert-equal 'Microsoft Nucleus' $map.ByPlanName['NUCLEUS'] 'override for Nucleus'
Assert-equal 'Exchange Online (Plan 2)' $map.ByPlanName['EXCHANGE_S_ENTERPRISE'] 'Exchange Online Plan 2 override'
$flowEnt = [pscustomobject]@{ id = 'ent-flow'; name = 'FLOW_O365_P2'; value = 'c1ec4a95-1f57-4f4a-8c5b-1d5f0b0c0f11'; type = 'servicePlan' }
$teamsEnt = [pscustomobject]@{ id = 'ent-teams'; name = 'TEAMS1'; value = '57ff2da0-773e-42df-b2af-ffb7a2317929'; type = 'servicePlan' }
Assert-equal 'Flow for Office 365' (Resolve-ServicePlanFriendlyName -Entitlement $flowEnt -FriendlyNameMap $map) 'flow friendly name'
Assert-equal 'Microsoft Teams' (Resolve-ServicePlanFriendlyName -Entitlement $teamsEnt -FriendlyNameMap $map) 'teams friendly name'

# Entra connector names: "PLAN [of] SKU" (developer pack, enterprise, etc.)
$devEnt = [ordered]@{
    id    = 'ent-aad-dev'
    name  = 'AAD_PREMIUM [of] DEVELOPERPACK_E5'
    value = 'AAD_PREMIUM [of] DEVELOPERPACK_E5'
    type  = 'servicePlan'
}
Assert-equal 'Microsoft Entra ID P1' (Resolve-ServicePlanFriendlyName -Entitlement $devEnt -FriendlyNameMap $map) 'strips [of] SKU for friendly name'
$devRows = @(Build-ServicePlanSelectionRows -Entitlements @($devEnt) -FriendlyNameMap $map)
Assert-equal 'AAD_PREMIUM' $devRows[0].InternalName 'internal name is bare plan id'
Assert-True ($devRows[0].Label -match 'Microsoft Entra ID P1') 'label uses Microsoft friendly name'

# StrictMode-safe when SDK entitlement omits value
$noValueEnt = [pscustomobject]@{ id = 'ent-noval'; name = 'POWERAPPS_O365_P2'; type = 'servicePlan' }
Assert-equal 'POWERAPPS_O365_P2' (Resolve-ServicePlanFriendlyName -Entitlement $noValueEnt -FriendlyNameMap $map) 'name fallback without value'
$rowsNoValue = @(Build-ServicePlanSelectionRows -Entitlements @($noValueEnt) -FriendlyNameMap $map)
Assert-equal 1 @($rowsNoValue).Count 'row built without value property'
Assert-equal 'POWERAPPS_O365_P2' $rowsNoValue[0].InternalName 'internal name from name only'

# Nested entitlement array must flatten into multiple selection rows
$nested = ,@($flowEnt, $teamsEnt)
$rowsNested = @(Build-ServicePlanSelectionRows -Entitlements $nested -FriendlyNameMap $map)
Assert-equal 2 @($rowsNested).Count 'nested entitlements flatten to rows'
Assert-True (@($rowsNested | Where-Object { $_.Id }).Count -eq 2) 'flattened rows have option keys'

# SDK array payloads arrive as hashtables (ConvertFrom-Json -AsHashtable)
$flowHash = [ordered]@{
    id        = 'ent-flow-hash'
    name      = 'FLOW_O365_P2'
    value     = 'c1ec4a95-1f57-4f4a-8c5b-1d5f0b0c0f11'
    attribute = 'servicePlan'
    type      = 'servicePlan'
}
Assert-equal 'Flow for Office 365' (Resolve-ServicePlanFriendlyName -Entitlement $flowHash -FriendlyNameMap $map) 'hashtable entitlement friendly name'
$rowsHash = @(Build-ServicePlanSelectionRows -Entitlements @($flowHash) -FriendlyNameMap $map)
Assert-equal 'FLOW_O365_P2' $rowsHash[0].InternalName 'hashtable entitlement internal name'
Assert-True ($rowsHash[0].Label -notmatch 'Unknown') 'hashtable entitlement label is not Unknown'

$flatFetch = @(Get-ServicePlanEntitlementsForSource -SourceId 'src' -EntitlementFetcher {
        param($filters)
        # Simulate accidental nested return
        , @($flowEnt, $teamsEnt)
    })
Assert-equal 2 @($flatFetch).Count 'entitlement fetch flattens nested arrays'

$rows = @(Build-ServicePlanSelectionRows -Entitlements @($flowEnt, $teamsEnt) -FriendlyNameMap $map)
Assert-Equal 2 @($rows).Count 'selection rows built'
Assert-True (@($rows)[0].Label -match '\(') 'selection label includes internal name'

Assert-equal 'M365 - Microsoft Teams' (New-AccessProfileName -Prefix 'M365 - ' -FriendlyName 'Microsoft Teams') 'prefix applied'
Assert-equal 'M365 - Microsoft Teams' (New-AccessProfileName -Prefix 'M365 -' -FriendlyName 'Microsoft Teams') 'prefix hyphen gets trailing space'
$oldManifestRow = [pscustomobject]@{
    FriendlyName = 'Exchange Online (Plan 2)'
    AccessProfileName = 'Microsoft 365 @emea-tes-team.cloud -Exchange Online (Plan 2)'
}
Assert-equal 'Microsoft 365 @emea-tes-team.cloud - Exchange Online (Plan 2)' `
    (Get-M365ReplayAccessProfileName -ManifestRow $oldManifestRow -CurrentFriendlyName 'Exchange Online (Plan 2)') `
    'CSV replay infers and normalizes the previous prefix'
Assert-equal 'M365 - Microsoft Teams' `
    (Get-M365ReplayAccessProfileName -ManifestRow $oldManifestRow -CurrentFriendlyName 'Microsoft Teams' -ManifestPrefix 'M365 -') `
    'JSON replay rebuilds the name from manifest prefix and current friendly name'
$lookupNames = @(Get-M365AccessProfileLookupNames -ManifestRow $oldManifestRow `
        -CurrentFriendlyName 'Exchange Online (Plan 2)' `
        -ManifestPrefix 'Microsoft 365 @emea-tes-team.cloud -')
Assert-True ($lookupNames -contains 'Microsoft 365 @emea-tes-team.cloud -Exchange Online (Plan 2)') `
    'lookup includes the raw previous name'
Assert-True ($lookupNames -contains 'Microsoft 365 @emea-tes-team.cloud - Exchange Online (Plan 2)') `
    'lookup includes the spaced previous prefix name'

# Previous JSON and CSV manifests load as replay inputs
$tmpManifestDir = Join-Path ([System.IO.Path]::GetTempPath()) ("m365-replay-{0}" -f [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmpManifestDir -Force | Out-Null
try {
    $jsonManifestPath = Join-Path $tmpManifestDir 'previous.json'
    [pscustomobject]@{
        Environment = 'test-env'
        SourceId    = 'src-1'
        SourceName  = 'Entra'
        Prefix      = 'M365 - '
        Application = [pscustomobject]@{ Name = 'Microsoft 365' }
        Results     = @([pscustomobject]@{
                InternalName = 'TEAMS1'; EntitlementId = 'ent-teams'
                AccessProfileName = 'M365 - Microsoft Teams'
            })
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonManifestPath -Encoding UTF8
    $jsonReplay = Read-M365AccessProfileManifest -Path $jsonManifestPath
    Assert-equal 'Json' $jsonReplay.Format 'JSON replay format'
    Assert-equal 'src-1' $jsonReplay.SourceId 'JSON replay source'
    Assert-equal 'Microsoft 365' $jsonReplay.ApplicationName 'JSON replay application'
    Assert-equal 1 @($jsonReplay.Results).Count 'JSON replay rows'

    $csvManifestPath = Join-Path $tmpManifestDir 'previous.csv'
    @"
InternalName,EntitlementId,AccessProfileName
TEAMS1,ent-teams,M365 - Microsoft Teams
"@ | Set-Content -LiteralPath $csvManifestPath -Encoding UTF8
    $csvReplay = Read-M365AccessProfileManifest -Path $csvManifestPath
    Assert-equal 'Csv' $csvReplay.Format 'CSV replay format'
    Assert-equal 1 @($csvReplay.Results).Count 'CSV replay rows'
    Assert-equal 'M365 - Microsoft Teams' $csvReplay.Results[0].AccessProfileName 'CSV replay preserves exact name'
}
finally {
    Remove-Item -LiteralPath $tmpManifestDir -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Idempotent AP resolve ---
$existingAp = [pscustomobject]@{
    id           = 'ap-1'
    name         = 'M365 - Microsoft Teams'
    source       = [pscustomobject]@{ id = 'src-1' }
    entitlements = @([pscustomobject]@{ id = 'ent-teams' })
}
$reused = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - Microsoft Teams' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-teams' `
    -AccessProfileFetcher { param($f) @($existingAp) } `
    -EntitlementListFetcher { param($id) @([pscustomobject]@{ id = 'ent-teams' }) }
Assert-Equal 'skipped' $reused.Status 'existing AP skipped by default'

# Hashtable list responses keep their source scoping (ConvertFrom-Json -AsHashtable)
$existingApHash = [ordered]@{
    id     = 'ap-hash-1'
    name   = 'M365 - Microsoft Teams'
    source = [ordered]@{ id = 'src-1' }
}
$scopedHash = @(Find-AccessProfilesByName -Name 'M365 - Microsoft Teams' -SourceId 'src-1' `
        -AccessProfileFetcher { param($f) @($existingApHash) })
Assert-equal 1 @($scopedHash).Count 'hashtable AP matches its source'
$scopedOther = @(Find-AccessProfilesByName -Name 'M365 - Microsoft Teams' -SourceId 'src-other' `
        -AccessProfileFetcher { param($f) @($existingApHash) })
Assert-equal 0 @($scopedOther).Count 'hashtable AP excluded from another source'

$script:updatedAccessProfile = $null
$updatedExisting = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - Microsoft Teams' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-other' `
    -AccessProfileFetcher { param($f) @($existingAp) } `
    -ExistingItemAction Update `
    -PatchFetcher {
        param($id, $ops)
        $script:updatedAccessProfile = [pscustomobject]@{ Id = $id; Operations = $ops }
        $ops
    }
Assert-Equal 'updated' $updatedExisting.Status 'existing AP fully reconciled'
Assert-Equal 'ap-1' $script:updatedAccessProfile.Id 'existing AP patched by id'
$entitlementOp = @($script:updatedAccessProfile.Operations | Where-Object { $_.path -eq '/entitlements' })[0]
Assert-Equal 'ent-other' $entitlementOp.value[0].id 'existing AP entitlement replaced'
$sourceOp = @($script:updatedAccessProfile.Operations | Where-Object { $_.path -eq '/source' })[0]
Assert-Equal 'src-1' $sourceOp.value.id 'existing AP source reconciled'

$script:renamedFromPrevious = $null
$oldNamedAp = [pscustomobject]@{
    id           = 'ap-old'
    name         = 'Microsoft 365 @t.cloud - Microsoft Teams'
    source       = [pscustomobject]@{ id = 'src-1' }
    entitlements = @([pscustomobject]@{ id = 'ent-teams' })
}
$renamed = Resolve-OrCreateAccessProfileForPlan -Name 'Microsoft 365 @t.cloud (Users) - Microsoft Teams' `
    -SourceId 'src-1' -SourceName 'Entra' -OwnerId 'owner-1' -EntitlementId 'ent-teams' `
    -ExistingItemAction Update `
    -PreviousNames @('Microsoft 365 @t.cloud - Microsoft Teams', 'Microsoft 365 @t.cloud -Microsoft Teams') `
    -AccessProfileFetcher {
        param($f)
        if ($f -match 'Users') { @() } else { @($oldNamedAp) }
    } `
    -PatchFetcher {
        param($id, $ops)
        $script:renamedFromPrevious = [pscustomobject]@{ Id = $id; Operations = $ops }
        $ops
    }
Assert-Equal 'updated' $renamed.Status 'previous-name lookup updates instead of creating'
Assert-Equal 'ap-old' $script:renamedFromPrevious.Id 'rename patches the previous profile'
Assert-Equal 'Microsoft 365 @t.cloud (Users) - Microsoft Teams' `
    (@($script:renamedFromPrevious.Operations | Where-Object { $_.path -eq '/name' })[0].value) `
    'rename sets the new prefix'

$createdPayload = $null
$created = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - Flow for Office 365' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-flow' `
    -AccessProfileFetcher { param($f) @() } `
    -CreateFetcher {
        param($payload)
        $script:createdPayload = $payload
        return [pscustomobject]@{ id = 'ap-new'; name = [string]$payload.name }
    }
Assert-equal 'created' $created.Status 'missing AP created'
Assert-equal 'ap-new' $created.AccessProfileId 'created id returned'
Assert-True ($null -ne $createdPayload) 'create payload captured'
Assert-equal $true ([bool]$createdPayload.requestable) 'created AP is requestable'
Assert-equal 'ent-flow' ([string]$createdPayload.entitlements[0].id) 'created AP binds entitlement'

$whatIf = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - New Plan' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-x' -WhatIf `
    -AccessProfileFetcher { param($f) @() }
Assert-equal 'would-create' $whatIf.Status 'WhatIf does not create'

# Create response deserialized as a hashtable (ConvertFrom-Json -AsHashtable) still yields an id
$createdHash = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - Hash Plan' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-hash' `
    -AccessProfileFetcher { param($f) @() } `
    -CreateFetcher { param($p) [ordered]@{ id = 'ap-hash'; name = [string]$p.name } }
Assert-equal 'created' $createdHash.Status 'hashtable create response is created'
Assert-equal 'ap-hash' $createdHash.AccessProfileId 'hashtable create response yields id'

# Create response without an id falls back to a lookup by name so app linking still gets ids
$script:lookupCalls = 0
$createdLookup = Resolve-OrCreateAccessProfileForPlan -Name 'M365 - Silent Plan' -SourceId 'src-1' -SourceName 'Entra' `
    -OwnerId 'owner-1' -EntitlementId 'ent-silent' `
    -AccessProfileFetcher {
        param($f)
        $script:lookupCalls++
        if ($script:lookupCalls -eq 1) {
            @()
        }
        else {
            @([pscustomobject]@{ id = 'ap-found'; name = 'M365 - Silent Plan'; source = [pscustomobject]@{ id = 'src-1' } })
        }
    } `
    -CreateFetcher { param($p) $null }
Assert-equal 'created' $createdLookup.Status 'idless create response is created'
Assert-equal 'ap-found' $createdLookup.AccessProfileId 'idless create response resolves id by name'

# --- Source app patch ops ---
$ops = @(Build-SourceAppAccessProfilePatch -AccessProfileIds @('ap-1', 'ap-2', 'ap-1') -ExistingAccessProfileIds @('ap-1'))
Assert-equal 1 $ops.Count 'only missing AP is patched'
Assert-equal 'add' $ops[0].op 'patch op is add'
Assert-equal '/accessProfiles/-' $ops[0].path 'patch path appends'
Assert-equal 'ap-2' $ops[0].value 'patch value is new AP id'

$script:sourceAppOwnerPatch = $null
$appCreated = Resolve-OrCreateSourceApp -Name 'Microsoft 365' -SourceId 'src-1' -OwnerId 'id-current' `
    -SourceAppFetcher { param($f) @() } `
    -CreateFetcher { param($p) [pscustomobject]@{ id = 'app-1'; name = $p.name } } `
    -OwnerPatchFetcher {
        param($id, $ops)
        $script:sourceAppOwnerPatch = [pscustomobject]@{ AppId = $id; Operations = $ops }
        $ops
    }
Assert-equal 'created' $appCreated.Status 'source app created'
Assert-equal 'app-1' $appCreated.AppId 'source app id'
Assert-equal 'app-1' $script:sourceAppOwnerPatch.AppId 'source app owner patched on create'
Assert-equal 'id-current' $script:sourceAppOwnerPatch.Operations[0].value.id 'source app owner is current identity'

# App create response without an id falls back to a lookup by name, so linking and owner patch still run
$script:appLookupCalls = 0
$script:idlessOwnerPatch = $null
$appIdless = Resolve-OrCreateSourceApp -Name 'Microsoft 365' -SourceId 'src-1' -OwnerId 'id-current' `
    -SourceAppFetcher {
        param($f)
        $script:appLookupCalls++
        if ($script:appLookupCalls -eq 1) {
            @()
        }
        else {
            @([pscustomobject]@{ id = 'app-found'; name = 'Microsoft 365'; accountSource = [pscustomobject]@{ id = 'src-1' } })
        }
    } `
    -CreateFetcher { param($p) $null } `
    -OwnerPatchFetcher {
        param($id, $ops)
        $script:idlessOwnerPatch = $id
        $ops
    }
Assert-equal 'created' $appIdless.Status 'idless app create response is created'
Assert-equal 'app-found' $appIdless.AppId 'idless app create response resolves id by name'
Assert-equal 'app-found' $script:idlessOwnerPatch 'owner patch uses the resolved app id'

# Hashtable app list responses keep their account-source scoping
$appHash = [ordered]@{ id = 'app-hash'; name = 'Microsoft 365'; accountSource = [ordered]@{ id = 'src-1' } }
$appScoped = @(Find-SourceAppByName -Name 'Microsoft 365' -SourceId 'src-1' -SourceAppFetcher { param($f) @($appHash) })
Assert-equal 1 @($appScoped).Count 'hashtable app matches its account source'
$appScopedOther = @(Find-SourceAppByName -Name 'Microsoft 365' -SourceId 'src-other' -SourceAppFetcher { param($f) @($appHash) })
Assert-equal 0 @($appScopedOther).Count 'hashtable app excluded from another account source'

$appReused = Resolve-OrCreateSourceApp -Name 'Microsoft 365' -SourceId 'src-1' `
    -SourceAppFetcher {
        param($f)
        @([pscustomobject]@{ id = 'app-1'; name = 'Microsoft 365'; accountSource = [pscustomobject]@{ id = 'src-1' } })
    }
Assert-equal 'skipped' $appReused.Status 'existing source app skipped by default'

$script:updatedSourceApp = $null
$appUpdated = Resolve-OrCreateSourceApp -Name 'Microsoft 365' -SourceId 'src-1' -OwnerId 'id-current' `
    -ExistingItemAction Update `
    -SourceAppFetcher {
        param($f)
        @([pscustomobject]@{ id = 'app-1'; name = 'Microsoft 365'; accountSource = [pscustomobject]@{ id = 'src-1' } })
    } `
    -OwnerPatchFetcher {
        param($id, $ops)
        $script:updatedSourceApp = [pscustomobject]@{ Id = $id; Operations = $ops }
        $ops
    }
Assert-equal 'updated' $appUpdated.Status 'existing source app reconciled'
Assert-equal 'id-current' (@($script:updatedSourceApp.Operations | Where-Object { $_.path -eq '/owner' })[0].value.id) `
    'existing source app owner updated'

$link = Add-AccessProfilesToSourceApp -AppId 'app-1' -AccessProfileIds @('ap-1', 'ap-2') `
    -ExistingFetcher { param($id) @([pscustomobject]@{ id = 'ap-1' }) } `
    -PatchFetcher { param($id, $ops) $ops }
Assert-equal 'patched' $link.Status 'app linked'
Assert-equal 1 @($link.Added).Count 'one AP added to app'

# --- Source discovery with mocks ---
$sources = @(
    [pscustomobject]@{ id = 'src-entra'; name = 'Entra Users'; type = 'Microsoft Entra ID'; connector = 'microsoft-entra-id' }
    [pscustomobject]@{ id = 'src-ad'; Name = 'AD'; type = 'Active Directory - Direct'; connector = 'active-directory' }
)
$found = @(Find-EntraSourcesWithServicePlans -SourceFetcher { $sources } -EntitlementFetcher {
        param($filters)
        if ($filters -match 'src-entra') {
            @([pscustomobject]@{ id = 'ent-1'; name = 'TEAMS1'; value = '57ff2da0-773e-42df-b2af-ffb7a2317929'; type = 'servicePlan' })
        }
        else { @() }
    })
Assert-equal 1 $found.Count 'only entra+plans source returned'
Assert-equal 'src-entra' $found[0].Id 'correct source id'
Assert-equal 1 $found[0].PlanCount 'plan count set'

# --- Identity search uses fetcher when provided ---
$identityHits = @(Find-IdentitiesByQuery -Query 'robot' -IdentityFetcher {
        param($q)
        @([pscustomobject]@{ id = 'id-robot'; name = 'Robot Account'; alias = 'robot'; email = 'robot@example.com' })
    })
Assert-equal 1 $identityHits.Count 'identity fetcher returns hit'
Assert-equal 'id-robot' $identityHits[0].id 'identity id preserved'

# --- Current identity from parameter, JWT, or PAT owner=me ---
$fromParam = Get-CurrentIscIdentity -OwnerId 'id-override'
Assert-equal 'id-override' $fromParam.Id 'OwnerId override wins'
Assert-equal 'parameter' $fromParam.Source 'OwnerId source is parameter'

$jwtPayload = '{"identity_id":"id-current","user_name":"alice"}'
$jwtBody = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jwtPayload)).TrimEnd('=')
$jwt = "e30.$jwtBody.sig"
$fromJwt = Get-CurrentIscIdentity -TokenFetcher { $jwt } -PersonalAccessTokenFetcher { @() }
Assert-equal 'id-current' $fromJwt.Id 'JWT identity_id is current owner'
Assert-equal 'alice' $fromJwt.Name 'JWT user_name is current owner name'
Assert-equal 'token' $fromJwt.Source 'JWT source is token'

$fromPat = Get-CurrentIscIdentity -TokenFetcher { 'not-a-jwt' } -PersonalAccessTokenFetcher {
    @([pscustomobject]@{ owner = [pscustomobject]@{ id = 'id-pat'; name = 'Pat Owner' } })
}
Assert-equal 'id-pat' $fromPat.Id 'PAT owner-id=me is current owner'
Assert-equal 'Pat Owner' $fromPat.Name 'PAT owner name'
Assert-equal 'personal-access-token' $fromPat.Source 'PAT source'

$unresolved = $false
try {
    $null = Get-CurrentIscIdentity -TokenFetcher { $null } -PersonalAccessTokenFetcher { @() }
}
catch { $unresolved = $true }
Assert-True $unresolved 'throws when current identity cannot be resolved'

# --- Manifest format: JSON or CSV only ---
$tmpOut = Join-Path ([System.IO.Path]::GetTempPath()) ("m365-manifest-{0}" -f [guid]::NewGuid())
try {
    $sample = [pscustomobject]@{
        OwnerId = 'id-current'
        Results = @([pscustomobject]@{ AccessProfileName = 'M365 - Teams'; AccessProfileId = 'ap-1' })
    }
    $jsonOnly = Write-M365AccessProfileManifest -Manifest $sample -OutputDirectory $tmpOut -Format Json
    Assert-True ([bool]$jsonOnly.JsonPath) 'JSON format writes json'
    Assert-True (Test-Path -LiteralPath $jsonOnly.JsonPath) 'JSON file exists'
    Assert-True (-not $jsonOnly.CsvPath) 'JSON format skips csv'
    $csvOnly = Write-M365AccessProfileManifest -Manifest $sample -OutputDirectory $tmpOut -Format Csv
    Assert-True ([bool]$csvOnly.CsvPath) 'CSV format writes csv'
    Assert-True (Test-Path -LiteralPath $csvOnly.CsvPath) 'CSV file exists'
    Assert-True (-not $csvOnly.JsonPath) 'CSV format skips json'
}
finally {
    if (Test-Path -LiteralPath $tmpOut) {
        Remove-Item -LiteralPath $tmpOut -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS ($script:AssertionCount assertions)"
