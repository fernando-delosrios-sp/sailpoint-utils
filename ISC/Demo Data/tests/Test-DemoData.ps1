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
Import-Module (Join-Path $moduleRoot 'ISC.DemoData.psm1') -Force -WarningAction SilentlyContinue

# --- Model load + invariants ---
$model = Import-DemoAccessModel
$validation = Test-DemoAccessModelInvariants -Model $model
Assert-True $validation.Ok ("model invariants: {0}" -f ($validation.Errors -join '; '))

$sourceNames = @($model['sources'] | ForEach-Object { [string]$_['name'] })
Assert-True ($sourceNames -contains 'Department Services') 'Department Services source present'
Assert-True ($sourceNames -contains 'Workforce Access') 'Workforce Access source present'
Assert-True ($sourceNames -contains 'Workplace Access') 'Workplace Access source present'
Assert-True ($sourceNames -contains 'Customer 360') 'Customer 360 source present'
Assert-True ($sourceNames -notcontains 'Title Toolkit') 'Title Toolkit is not used'

Assert-Equal 13 @($model['departmentRoles']).Count '13 department roles'
Assert-equal 81 @($model['titleRoles']).Count '81 title roles'
Assert-equal 10 @($model['workplaceRole']['dimensions']).Count '10 city dimensions'
Assert-equal 10 @($model['entitlements']['customer360']).Count '10 Customer 360 entitlements'
Assert-equal 10 @($model['requestableAccessProfiles']).Count '10 Customer 360 requestable access profiles'
Assert-equal 5 @($model['sodViolationRoles']).Count '5 SoD violation demo roles'
Assert-True ([bool]$model['workplaceRole']['dimensional']) 'office role is dimensional'
Assert-equal 'Workplace User' ([string]$model['workplaceRole']['name']) 'office role name'

$catalog = Get-DemoModelEntitlementCatalog -Model $model
$counts = [System.Collections.Generic.List[int]]::new()
foreach ($role in @($model['departmentRoles']) + @($model['titleRoles'])) {
    $ids = @($role['entitlementIds'])
    Assert-True ($ids.Count -ge 1 -and $ids.Count -le 2) ("role '{0}' has 1 or 2 entitlements" -f $role['name'])
    $counts.Add($ids.Count)
    foreach ($id in $ids) {
        $entName = [string]$catalog[[string]$id].Name
        Assert-True ($entName -ne [string]$role['name']) ("entitlement for '{0}' is not identical to role name" -f $role['name'])
        Assert-True ($entName -ne [string]$role['attributeValue']) ("entitlement for '{0}' is not identical to attribute value" -f $role['name'])
    }
}
Assert-True ($counts -contains 1) 'at least one role has a single entitlement'
Assert-True ($counts -contains 2) 'at least one role has two entitlements'

foreach ($role in @($model['sodViolationRoles'])) {
    $ids = @($role['entitlementIds'])
    Assert-equal 2 $ids.Count ("SoD demo role '{0}' has 2 entitlements" -f $role['name'])
    Assert-True ([bool]$role['requestable']) ("SoD demo role '{0}' is requestable" -f $role['name'])
    Assert-True ([string]$role['description'] -match 'policy violation') ("SoD demo role '{0}' description names a policy violation" -f $role['name'])
    Assert-True ([string]$role['description'] -like ('*{0}*' -f $role['sodPolicyId'])) ("SoD demo role '{0}' description names {1}" -f $role['name'], $role['sodPolicyId'])
}

$officeBaseId = [string]@($model['workplaceRole']['entitlementIds'])[0]
Assert-equal 'Workplace User' ([string]$catalog[$officeBaseId].Name) 'office base entitlement is Workplace User'

foreach ($dim in @($model['workplaceRole']['dimensions'])) {
    $ids = @($dim['entitlementIds'])
    Assert-True ($ids.Count -ge 1 -and $ids.Count -le 2) ("city '{0}' has 1 or 2 entitlements" -f $dim['name'])
    foreach ($id in $ids) {
        $entName = [string]$catalog[[string]$id].Name
        Assert-True ($entName -ne [string]$dim['name']) ("city entitlement for '{0}' is not identical to city" -f $dim['name'])
    }
}

# --- CSV fixtures exist ---
foreach ($source in @($model['sources'])) {
    $csvPath = Get-DemoCsvPath -Model $model -SourceKey ([string]$source['key'])
    Assert-True (Test-Path -LiteralPath $csvPath) ("csv exists for {0}" -f $source['key'])
    $lines = @(Get-Content -LiteralPath $csvPath)
    Assert-True ($lines.Count -gt 1) ("csv {0} has rows" -f $source['csvFile'])
    Assert-True ($lines[0] -match '^id,name,') ("csv {0} starts with id,name" -f $source['csvFile'])
}

# --- Membership payloads ---
$deptMembership = Build-ActiveAndAttributeMembership -Attribute 'department' -Value 'Finance'
Assert-equal 'STANDARD' $deptMembership.type 'department membership type'
Assert-equal 'AND' $deptMembership.criteria.operation 'department membership AND'
Assert-equal 'active' $deptMembership.criteria.children[0].stringValue 'lifecycle active'
Assert-equal 'attribute.department' $deptMembership.criteria.children[1].key.property 'department property'
Assert-equal 'Finance' $deptMembership.criteria.children[1].stringValue 'department value'

$titleMembership = Build-ActiveAndAttributeMembership -Attribute 'titleHistory' -Value 'Accounts Payable Analyst'
Assert-equal 'CONTAINS' $titleMembership.criteria.children[1].operation 'title uses CONTAINS'
Assert-equal 'attribute.titleHistory' $titleMembership.criteria.children[1].key.property 'titleHistory property'
Assert-equal '[Accounts Payable Analyst]' $titleMembership.criteria.children[1].values[0] 'title bracketed token'

$officeMembership = Build-OfficeUserMembership
Assert-equal 'AND' $officeMembership.criteria.operation 'office membership AND'
Assert-equal 'OR' $officeMembership.criteria.children[1].operation 'office userType OR'
Assert-equal 'Employee' $officeMembership.criteria.children[1].children[0].stringValue 'Employee'
Assert-equal 'Contractor' $officeMembership.criteria.children[1].children[1].stringValue 'Contractor'

# --- Dimensional + dimension payloads ---
$dimSchema = @([ordered]@{ name = 'city'; displayName = 'City'; derived = $false })
$dimRole = Build-DimensionalRolePayload -Name 'Workplace User' -Description 'desc' -OwnerId 'owner-1' `
    -EntitlementIds @('ent-office') -Membership $officeMembership -DimensionSchema $dimSchema
Assert-True ([bool]$dimRole.dimensional) 'dimensional flag set'
Assert-equal 'city' $dimRole.dimensionSchema.dimensionAttributes[0].name 'dimensionSchema city'
Assert-equal 'ENTITLEMENT' $dimRole.entitlements[0].type 'role entitlement type'

$dim = Build-DimensionPayload -Name 'London' -Description 'London access' -OwnerId 'owner-1' `
    -City 'London' -EntitlementIds @('ent-london')
Assert-equal 'attribute.city' $dim.membership.criteria.key.property 'dimension city property'
Assert-equal 'London' $dim.membership.criteria.stringValue 'dimension city value'

# --- Source / role payloads ---
$sourcePayload = Build-DelimitedFileSourcePayload -Name 'Workforce Access' -Description 'Workforce' -OwnerId 'owner-1'
Assert-Equal 'DelimitedFile' $sourcePayload.type 'delimited file type'
Assert-equal 'IDENTITY' $sourcePayload.owner.type 'source owner type'
Assert-True ($null -ne $sourcePayload.connectorAttributes['group.columnNames']) 'source has group.columnNames'
Assert-equal ',' $sourcePayload.connectorAttributes['delimiter'] 'source uses comma delimiter'
Assert-equal 'delimited' $sourcePayload.connectorAttributes['parseType'] 'source uses delimited parsing'

$rolePayload = Build-StandardRolePayload -Name 'Finance Department' -Description 'Finance role' `
    -OwnerId 'owner-1' -EntitlementIds @('e1', 'e2') -Membership $deptMembership
Assert-equal $false $rolePayload.dimensional 'standard role not dimensional'
Assert-equal 'ENTITLEMENT' $rolePayload.entitlements[0].type 'role entitlement ref type'
Assert-equal 0 @($rolePayload.accessProfiles).Count 'standard role has no access profiles'
Assert-equal $false $rolePayload.requestable 'birthright role not requestable'

$sodDemo = @($model['sodViolationRoles'])[0]
$sodRolePayload = Build-StandardRolePayload -Name ([string]$sodDemo['name']) -Description ([string]$sodDemo['description']) `
    -OwnerId 'owner-1' -EntitlementIds @('e1', 'e2') -Membership $sodDemo['membership'] -Requestable $true
Assert-True ([bool]$sodRolePayload.requestable) 'SoD demo role payload is requestable'

$createPolicy = Build-CreateAccountProvisioningPolicyPayload
Assert-equal 'CREATE' $createPolicy.usageType 'create policy usage'
Assert-equal 'id' $createPolicy.fields[0].name 'create policy account id field'
Assert-equal 'uid' $createPolicy.fields[0].transform.attributes.name 'create policy maps uid'
Assert-equal 'displayName' $createPolicy.fields[1].transform.attributes.name 'create policy maps displayName'
Assert-equal 'groups' $createPolicy.fields[-1].name 'create policy includes groups'

$customerProfile = @($model['requestableAccessProfiles'])[0]
$customerPayload = Build-AccessProfilePayload -Name ([string]$customerProfile['name']) `
    -Description ([string]$customerProfile['description']) -OwnerId 'owner-1' `
    -SourceId 'source-customer-360' -SourceName 'Customer 360' `
    -EntitlementIds @('ent-customer-viewer') -Requestable $true
Assert-True ([bool]$customerPayload.requestable) 'Customer 360 access profile is requestable'
Assert-equal 'source-customer-360' $customerPayload.source.id 'Customer 360 access profile source'
Assert-equal 'ent-customer-viewer' $customerPayload.entitlements[0].id 'Customer 360 access profile entitlement'

# --- Idempotent resolve with mocks ---
$created = [System.Collections.Generic.List[object]]::new()
$resolveCreate = Resolve-OrCreateNamedObject -Name 'Finance Department' -ObjectLabel 'role' `
    -Finder { @() } `
    -CreatePayloadBuilder { @{ name = 'Finance Department' } } `
    -CreateFetcher {
        param($payload)
        $obj = [pscustomobject]@{ id = 'role-new'; name = $payload['name'] }
        $created.Add($obj)
        $obj
    }
Assert-equal 'created' $resolveCreate.Status 'creates when missing'
Assert-equal 'role-new' $resolveCreate.Id 'create returns id'

$resolveSkip = Resolve-OrCreateNamedObject -Name 'Finance Department' -ObjectLabel 'role' `
    -ExistingItemAction Skip `
    -Finder { @([pscustomobject]@{ id = 'role-existing'; name = 'Finance Department' }) } `
    -CreatePayloadBuilder { @{ name = 'Finance Department' } }
Assert-equal 'skipped' $resolveSkip.Status 'skips existing'
Assert-equal 'role-existing' $resolveSkip.Id 'skip keeps existing id'

$resolveWhatIf = Resolve-OrCreateNamedObject -Name 'New Role' -ObjectLabel 'role' -WhatIf `
    -Finder { @() } `
    -CreatePayloadBuilder { @{ name = 'New Role' } }
Assert-equal 'would-create' $resolveWhatIf.Status 'whatif create'

$resolveConflict = Resolve-OrCreateNamedObject -Name 'Dup' -ObjectLabel 'role' `
    -Finder {
        @(
            [pscustomobject]@{ id = '1'; name = 'Dup' }
            [pscustomobject]@{ id = '2'; name = 'Dup' }
        )
    } `
    -CreatePayloadBuilder { @{ name = 'Dup' } }
Assert-equal 'conflict' $resolveConflict.Status 'duplicate conflict'

# --- Bootstrap WhatIf with hooks ---
$store = @{
    Sources = @{}
    Roles   = @{}
}
$bootstrap = Invoke-DemoDataBootstrap -Model $model -OwnerId 'owner-1' -WhatIf -Hooks @{
    FindSources = {
        param($name)
        if ($store.Sources.ContainsKey($name)) { @($store.Sources[$name]) } else { @() }
    }
    FindRoles = {
        param($name)
        if ($store.Roles.ContainsKey($name)) { @($store.Roles[$name]) } else { @() }
    }
    FindAccessProfiles = { param($name, $sourceId) @() }
    FindSourceApps = { param($name, $sourceId) @() }
    FindEntitlements = { param($sourceId, $value) @() }
    FindDimensions = { param($roleId, $name) @() }
}

$statuses = @($bootstrap.Results | Select-Object -ExpandProperty Status -Unique)
Assert-True ($statuses -contains 'would-create') 'bootstrap whatif reports would-create'
$officeRows = @($bootstrap.Results | Where-Object { $_.Kind -eq 'role' -and $_.Name -eq 'Workplace User' })
Assert-equal 1 $officeRows.Count 'office user role in bootstrap results'
Assert-equal 'would-create' $officeRows[0].Status 'office user would-create'
$dimRows = @($bootstrap.Results | Where-Object { $_.Kind -eq 'dimension' })
Assert-equal 10 $dimRows.Count 'ten city dimensions planned'
$customerProfileRows = @($bootstrap.Results | Where-Object { $_.Kind -eq 'access-profile' })
Assert-equal 10 $customerProfileRows.Count 'ten requestable Customer 360 access profiles planned'
Assert-True (@($customerProfileRows | Where-Object { $_.Status -eq 'would-create' }).Count -eq 10) 'Customer 360 access profiles would create'
$sodDemoRows = @($bootstrap.Results | Where-Object { $_.Kind -eq 'role' -and $_.Name -like 'SoD Demo*' })
Assert-equal 5 $sodDemoRows.Count 'five SoD demo roles planned'
Assert-True (@($sodDemoRows | Where-Object { $_.Status -eq 'would-create' }).Count -eq 5) 'SoD demo roles would create'

# --- Invalid model fails invariants ---
$bad = Import-DemoAccessModel
$bad['titleRoles'][0]['entitlementIds'] = @($bad['titleRoles'][0]['entitlementIds'][0])
# Force identical entitlement name by pointing at a fake catalog entry that matches role name
$roleName = [string]$bad['titleRoles'][0]['name']
$fakeId = 'FAKE-IDENTICAL'
$bad['entitlements']['workforceAccess'] = @($bad['entitlements']['workforceAccess']) + @(
    @{ id = $fakeId; name = $roleName; description = 'bad' }
)
$bad['titleRoles'][0]['entitlementIds'] = @($fakeId)
$badValidation = Test-DemoAccessModelInvariants -Model $bad
Assert-True (-not $badValidation.Ok) 'identical entitlement name fails validation'
Assert-True (@($badValidation.Errors | Where-Object { $_ -match 'must not match' }).Count -gt 0) 'reports identical name error'

# --- SoD policies + mitigating controls ---
$sod = Import-DemoSodPolicies
Assert-equal 20 @($sod['policies']).Count '20 SoD policies'
Assert-equal 7 @($sod['mitigatingControls']).Count '7 mitigating controls'
$fin01 = @($sod['policies'] | Where-Object { $_['id'] -eq 'SOD-FIN-01' })[0]
Assert-True ($null -ne $fin01) 'SOD-FIN-01 present'
$severitySet = @($sod['policies'] | ForEach-Object { [string]$_['severity'] } | Sort-Object -Unique)
Assert-True ($severitySet.Count -ge 4) 'SoD severities include mixed risk levels'
Assert-True ([bool]$fin01['sameRoleBundle']) 'SOD-FIN-01 marked same-role bundle'
Assert-True (@($fin01['allowedControlIds']).Count -ge 2) 'SOD-FIN-01 has allowed controls'

foreach ($role in @($model['sodViolationRoles'])) {
    $policyId = [string]$role['sodPolicyId']
    $policy = @($sod['policies'] | Where-Object { $_['id'] -eq $policyId })[0]
    Assert-True ($null -ne $policy) ("SoD demo role '{0}' maps to {1}" -f $role['name'], $policyId)
    $roleEntNames = @($role['entitlementIds'] | ForEach-Object { [string]$catalog[[string]$_].Name })
    $leftHit = @($policy['left']['entitlementNames'] | Where-Object { $roleEntNames -contains $_ }).Count -ge 1
    $rightHit = @($policy['right']['entitlementNames'] | Where-Object { $roleEntNames -contains $_ }).Count -ge 1
    Assert-True $leftHit ("SoD demo role '{0}' includes left-side entitlement of {1}" -f $role['name'], $policyId)
    Assert-True $rightHit ("SoD demo role '{0}' includes right-side entitlement of {1}" -f $role['name'], $policyId)
}

$ctrlPayload = Build-SodControlPayload -Control $sod['mitigatingControls'][0] -OwnerId 'owner-1'
Assert-equal 'IDENTITY' $ctrlPayload.owner.type 'control owner type'
Assert-equal 'owner-1' $ctrlPayload.owner.id 'control owner id'

$ctrlIds = @{
    'CTRL-MGR-DUAL'   = 'c-mgr'
    'CTRL-TREASURY'   = 'c-treas'
    'CTRL-AUDIT'      = 'c-audit'
    'CTRL-CAB'        = 'c-cab'
    'CTRL-COMP'       = 'c-comp'
    'CTRL-BLIND'      = 'c-blind'
    'CTRL-REMEDIATE'  = 'c-rem'
}
$ctrlNames = @{}
foreach ($c in @($sod['mitigatingControls'])) { $ctrlNames[[string]$c['id']] = [string]$c['name'] }
$allowed = Build-SodAllowedControlRefs -Policy $fin01 -ControlIdsByKey $ctrlIds -ControlNamesByKey $ctrlNames
Assert-equal 'COMPENSATING_CONTROL' $allowed[0].type 'allowed control type'
Assert-True (@($allowed | Where-Object { $_.id -eq 'c-mgr' }).Count -eq 1) 'FIN-01 includes manager control'

$sodPayload = Build-SodPolicyPayload -Policy $fin01 -OwnerId 'owner-1' -EntitlementIdsByName @{
    'Invoice Settlement Queue' = 'ent-settle'
    'Vendor Payment Release'   = 'ent-release'
} -AllowedControls $allowed
Assert-equal 'CONFLICTING_ACCESS_BASED' $sodPayload.type 'SoD type'
Assert-equal 'CRITICAL' $sodPayload.level 'SoD FIN-01 level'
Assert-equal 'SOD-FIN-01' $sodPayload.externalPolicyReference 'SoD external ref'
Assert-equal 'ENTITLEMENT' $sodPayload.conflictingAccessCriteria.leftCriteria.criteriaList[0].type 'left ent type'
Assert-equal 'ent-settle' $sodPayload.conflictingAccessCriteria.leftCriteria.criteriaList[0].id 'left ent id'
Assert-equal 'ent-release' $sodPayload.conflictingAccessCriteria.rightCriteria.criteriaList[0].id 'right ent id'
Assert-equal 3 @($sodPayload.allowedControls).Count 'payload carries allowed controls'

$ctrlBootstrap = Invoke-DemoSodControlBootstrap -SodModel $sod -OwnerId 'owner-1' -WhatIf `
    -Hooks @{ FindControls = { param($name, $id) @() } }
$ctrlWould = @($ctrlBootstrap.Results | Where-Object { $_.Status -eq 'would-create' })
Assert-equal 7 $ctrlWould.Count 'SoD control whatif would-create all controls'

$entMap = @{
    'Invoice Settlement Queue' = 'e1'
    'Vendor Payment Release'   = 'e2'
    'Vendor Master Desk'       = 'e3'
    'Bank Portal Access'       = 'e4'
    'Credit Memo Desk'         = 'e5'
    'Cash App Desk'            = 'e6'
    'Ledger Close Desk'        = 'e7'
    'Audit Workpaper Desk'     = 'e8'
    'ERP Config Desk'          = 'e9'
    'Control Test Desk'        = 'e10'
    'Payroll Run Desk'         = 'e11'
    'Comp Band Desk'           = 'e12'
    'Payroll Exception Desk'   = 'e13'
    'Payroll Calendar Desk'    = 'e14'
    'Equity Plan Desk'         = 'e15'
    'Offer Desk'               = 'e16'
    'ER Case Desk'             = 'e17'
    'Domain Ops Console'       = 'e18'
    'Mainframe Access Desk'    = 'e19'
    'Audit Plan Desk'          = 'e20'
    'Firewall Change Desk'     = 'e21'
    'Control Blueprint Desk'   = 'e22'
    'Schema Change Desk'       = 'e23'
    'Backup Restore Desk'      = 'e24'
    'Hotfix Desk'              = 'e25'
    'Release Signoff Desk'     = 'e26'
    'Build Pipeline Gate'      = 'e27'
    'Staging Code Bench'       = 'e28'
    'Staging Release Board'    = 'e29'
    'Purchase Requisition Desk' = 'e30'
    'Contract Desk'            = 'e31'
    'Inbound Dock Desk'        = 'e32'
    'Stock Movement Desk'      = 'e33'
    'Cycle Count Desk'         = 'e34'
}
$sodBootstrap = Invoke-DemoSodPolicyBootstrap -SodModel $sod -OwnerId 'owner-1' -WhatIf `
    -EntitlementIdsByName $entMap `
    -ControlIdsByKey $ctrlIds `
    -ControlNamesByKey $ctrlNames `
    -Hooks @{
        FindSodPolicies = { param($name, $id) @() }
    }
$sodWould = @($sodBootstrap.Results | Where-Object { $_.Status -eq 'would-create' })
Assert-equal 20 $sodWould.Count 'SoD whatif would-create all policies'

Write-Host ("PASS ({0} assertions)" -f $script:AssertionCount)
