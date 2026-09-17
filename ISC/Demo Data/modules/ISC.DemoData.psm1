#Requires -Version 5.1
Set-StrictMode -Version Latest

function Get-DemoDataRoot {
    return Split-Path -Parent $PSScriptRoot
}

function Get-ObjectPropertySafe {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$AlternateNames = @()
    )

    if ($null -eq $Object) { return $null }

    $names = @($Name) + @($AlternateNames)
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($candidate in $names) {
            foreach ($key in @($Object.Keys)) {
                if ([string]$key -ieq $candidate) {
                    $val = $Object[$key]
                    if ($null -ne $val -and "$val" -ne '') { return $val }
                }
            }
        }
        return $null
    }

    foreach ($candidate in $names) {
        $prop = $null
        foreach ($p in @($Object.PSObject.Properties)) {
            if ($p.Name -ieq $candidate) {
                $prop = $p
                break
            }
        }
        if ($null -ne $prop -and $null -ne $prop.Value -and "$($prop.Value)" -ne '') {
            return $prop.Value
        }
    }
    return $null
}

function Get-ObjectIdSafe {
    param($Object)
    if ($null -eq $Object) { return $null }
    if ($Object -is [string]) { return $Object }
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in @($Object.Keys)) {
            if ([string]$key -ieq 'id' -and $Object[$key]) { return [string]$Object[$key] }
        }
        return $null
    }
    $id = Get-ObjectPropertySafe -Object $Object -Name 'id' -AlternateNames @('Id')
    if ($id) { return [string]$id }
    return $null
}

function ConvertTo-HashtableDeep {
    param($InputObject)

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [string] -or $InputObject -is [ValueType] -or $InputObject -is [datetime]) {
        return $InputObject
    }
    if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in @($InputObject.Keys)) {
            $result[[string]$key] = ConvertTo-HashtableDeep -InputObject $InputObject[$key]
        }
        return $result
    }
    if ($InputObject -is [System.Array] -or ($InputObject -is [System.Collections.IList] -and -not ($InputObject -is [string]))) {
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in @($InputObject)) {
            $list.Add((ConvertTo-HashtableDeep -InputObject $item))
        }
        return , $list.ToArray()
    }
    if ($InputObject -is [pscustomobject] -or $InputObject.PSObject.TypeNames -contains 'System.Management.Automation.PSCustomObject') {
        $result = @{}
        foreach ($prop in @($InputObject.PSObject.Properties)) {
            $result[$prop.Name] = ConvertTo-HashtableDeep -InputObject $prop.Value
        }
        return $result
    }
    return $InputObject
}

function Import-DemoAccessModel {
    param(
        [string]$Path
    )

    if (-not $Path) {
        $Path = Join-Path (Get-DemoDataRoot) 'config/demo-access-model.json'
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Demo access model was not found at $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $json = $raw | ConvertFrom-Json
    return ConvertTo-HashtableDeep -InputObject $json
}

function Get-DemoModelEntitlementCatalog {
    param(
        [Parameter(Mandatory)][hashtable]$Model
    )

    $catalog = @{}
    $bySource = $Model['entitlements']
    if (-not $bySource) { return $catalog }
    foreach ($sourceKey in @($bySource.Keys)) {
        foreach ($ent in @($bySource[$sourceKey])) {
            $id = [string]$ent['id']
            $catalog[$id] = [pscustomobject]@{
                Id          = $id
                Name        = [string]$ent['name']
                Description = [string]$ent['description']
                SourceKey   = [string]$sourceKey
            }
        }
    }
    return $catalog
}

function Test-DemoAccessModelInvariants {
    param(
        [Parameter(Mandatory)][hashtable]$Model
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $catalog = Get-DemoModelEntitlementCatalog -Model $Model

    $sourceNames = @($Model['sources'] | ForEach-Object { [string]$_['name'] })
    if ($sourceNames -notcontains 'Department Services') { $errors.Add('Missing Department Services source.') }
    if ($sourceNames -notcontains 'Workforce Access') { $errors.Add('Missing Workforce Access source.') }
    if ($sourceNames -notcontains 'Workplace Access') { $errors.Add('Missing Workplace Access source.') }
    if ($sourceNames -contains 'Title Toolkit') { $errors.Add('Title Toolkit must not be used as a source name.') }
    if ($sourceNames -contains 'Office Access') { $errors.Add('Office Access must not be used; use Workplace Access.') }

    $counts = [System.Collections.Generic.List[int]]::new()
    $rolesToCheck = @(
        foreach ($role in @($Model['departmentRoles'])) {
            [pscustomobject]@{ Role = $role; Label = 'Department role' }
        }
        foreach ($role in @($Model['titleRoles'])) {
            [pscustomobject]@{ Role = $role; Label = 'Title role' }
        }
    )

    foreach ($item in $rolesToCheck) {
        $role = $item.Role
        $label = [string]$item.Label
        $roleName = [string]$role['name']
        $attrValue = [string]$role['attributeValue']
        $ids = @($role['entitlementIds'])
        if ($ids.Count -lt 1 -or $ids.Count -gt 2) {
            $errors.Add("$label '$roleName' must have 1 or 2 entitlements (found $($ids.Count)).")
        }
        $counts.Add($ids.Count)
        foreach ($id in $ids) {
            if (-not $catalog.ContainsKey([string]$id)) {
                $errors.Add("$label '$roleName' references unknown entitlement '$id'.")
                continue
            }
            $entName = [string]$catalog[[string]$id].Name
            if ($entName -eq $roleName -or ($attrValue -and $entName -eq $attrValue)) {
                $errors.Add("$label '$roleName' entitlement '$entName' must not match the role or attribute value.")
            }
        }
    }

    if ($counts -notcontains 1 -or $counts -notcontains 2) {
        $errors.Add('Department and title roles must mix both 1 and 2 entitlements.')
    }

    $office = $Model['workplaceRole']
    if (-not $office) {
        $errors.Add('workplaceRole is required.')
    }
    else {
        if ([string]$office['name'] -ne 'Workplace User') { $errors.Add("Workplace role name must be 'Workplace User'.") }
        if (-not [bool]$office['dimensional']) { $errors.Add('Workplace role must be dimensional.') }
        $officeEntIds = @($office['entitlementIds'])
        if ($officeEntIds.Count -ne 1) {
            $errors.Add('Workplace role must carry exactly one base entitlement (Workplace User).')
        }
        elseif ($catalog.ContainsKey([string]$officeEntIds[0])) {
            if ([string]$catalog[[string]$officeEntIds[0]].Name -ne 'Workplace User') {
                $errors.Add('Workplace role base entitlement must be named Workplace User.')
            }
        }
        $schema = $office['dimensionSchema']
        if (-not $schema -or -not @($schema['dimensionAttributes']).Count) {
            $errors.Add('Workplace role must define dimensionSchema.dimensionAttributes (city).')
        }
        else {
            $attrNames = @($schema['dimensionAttributes'] | ForEach-Object { [string]$_['name'] })
            if ($attrNames -notcontains 'city') {
                $errors.Add('Workplace role dimensionSchema must include city.')
            }
        }
        $dims = @($office['dimensions'])
        if ($dims.Count -lt 1) { $errors.Add('Workplace role must define city dimensions.') }
        foreach ($dim in $dims) {
            $dimName = [string]$dim['name']
            $ids = @($dim['entitlementIds'])
            if ($ids.Count -lt 1 -or $ids.Count -gt 2) {
                $errors.Add("City dimension '$dimName' must have 1 or 2 entitlements.")
            }
            foreach ($id in $ids) {
                if (-not $catalog.ContainsKey([string]$id)) {
                    $errors.Add("City dimension '$dimName' references unknown entitlement '$id'.")
                    continue
                }
                $entName = [string]$catalog[[string]$id].Name
                if ($entName -eq $dimName -or $entName -eq [string]$dim['attributeValue']) {
                    $errors.Add("City dimension '$dimName' entitlement '$entName' must not match the city name.")
                }
            }
        }
    }

    $sodRoles = @($Model['sodViolationRoles'])
    if ($sodRoles.Count -ne 5) {
        $errors.Add("Exactly 5 sodViolationRoles are required (found $($sodRoles.Count)).")
    }
    foreach ($role in $sodRoles) {
        $roleName = [string]$role['name']
        $ids = @($role['entitlementIds'])
        if ($ids.Count -ne 2) {
            $errors.Add("SoD violation role '$roleName' must have exactly 2 entitlements (found $($ids.Count)).")
        }
        $reqVal = Get-ObjectPropertySafe -Object $role -Name 'requestable'
        if ($null -eq $reqVal -or -not [bool]$reqVal) {
            $errors.Add("SoD violation role '$roleName' must be requestable.")
        }
        $desc = [string]$role['description']
        if ($desc -notmatch 'policy violation') {
            $errors.Add("SoD violation role '$roleName' description must indicate a policy violation.")
        }
        $policyId = [string]$role['sodPolicyId']
        if ($policyId -notmatch '^SOD-') {
            $errors.Add("SoD violation role '$roleName' must set sodPolicyId.")
        }
        elseif ($desc -notlike "*$policyId*") {
            $errors.Add("SoD violation role '$roleName' description must name $policyId.")
        }
        foreach ($id in $ids) {
            if (-not $catalog.ContainsKey([string]$id)) {
                $errors.Add("SoD violation role '$roleName' references unknown entitlement '$id'.")
            }
        }
    }

    return [pscustomobject]@{
        Ok     = ($errors.Count -eq 0)
        Errors = @($errors.ToArray())
    }
}

function Build-IdentityEqualsCriterion {
    param(
        [Parameter(Mandatory)][string]$Attribute,
        [Parameter(Mandatory)][string]$Value
    )

    return [ordered]@{
        operation   = 'EQUALS'
        key         = [ordered]@{
            type     = 'IDENTITY'
            property = "attribute.$Attribute"
        }
        stringValue = $Value
    }
}

function Build-IdentityContainsCriterion {
    param(
        [Parameter(Mandatory)][string]$Attribute,
        [Parameter(Mandatory)][string]$Value
    )

    # Title (and similar multi-select attributes) match bracketed tokens via CONTAINS,
    # e.g. values: ["[Accounts Payable Analyst]"].
    $token = if ($Value.StartsWith('[') -and $Value.EndsWith(']')) { $Value } else { "[$Value]" }

    return [ordered]@{
        operation = 'CONTAINS'
        key       = [ordered]@{
            type     = 'IDENTITY'
            property = "attribute.$Attribute"
        }
        values    = @($token)
    }
}

function Build-ActiveAndAttributeMembership {
    param(
        [Parameter(Mandatory)][string]$Attribute,
        [Parameter(Mandatory)][string]$Value
    )

    $attributeCriterion = if ($Attribute -in @('title', 'titleHistory')) {
        Build-IdentityContainsCriterion -Attribute $Attribute -Value $Value
    }
    else {
        Build-IdentityEqualsCriterion -Attribute $Attribute -Value $Value
    }

    return [ordered]@{
        type     = 'STANDARD'
        criteria = [ordered]@{
            operation = 'AND'
            children  = @(
                (Build-IdentityEqualsCriterion -Attribute 'cloudLifecycleState' -Value 'active')
                $attributeCriterion
            )
        }
    }
}

function Build-OfficeUserMembership {
    return [ordered]@{
        type     = 'STANDARD'
        criteria = [ordered]@{
            operation = 'AND'
            children  = @(
                (Build-IdentityEqualsCriterion -Attribute 'cloudLifecycleState' -Value 'active')
                [ordered]@{
                    operation = 'OR'
                    children  = @(
                        (Build-IdentityEqualsCriterion -Attribute 'userType' -Value 'Employee')
                        (Build-IdentityEqualsCriterion -Attribute 'userType' -Value 'Contractor')
                    )
                }
            )
        }
    }
}

function Build-DelimitedFileSourcePayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$OwnerId
    )

    $groupColumns = @(
        'id', 'name', 'displayName', 'created', 'description', 'modified',
        'entitlements', 'groups', 'permissions'
    )

    return [ordered]@{
        name                = $Name
        description         = $Description
        type                = 'DelimitedFile'
        connector           = 'delimited-file-angularsc'
        connectorClass      = 'sailpoint.connector.delimitedfile.DelimitedFileConnector'
        connectorScriptName = 'delimited-file-angularsc'
        owner               = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        features            = @('DIRECT_PERMISSIONS', 'DISCOVER_SCHEMA', 'NO_RANDOM_ACCESS')
        connectorAttributes = [ordered]@{
            hasHeader           = $true
            'group.hasHeader'   = $true
            delimiter           = ','
            parseType           = 'delimited'
            filetransport       = 'local'
            'group.filetransport' = 'local'
            filterEmptyRecords  = $true
            'group.filterEmptyRecords' = $true
            partitionMode       = 'disabled'
            'group.partitionMode' = 'disabled'
            'group.columnNames' = $groupColumns
            columnNames         = @('id', 'name', 'givenName', 'familyName', 'e-mail', 'location', 'manager', 'groups')
        }
    }
}

function Build-EntitlementGroupSchemaPayload {
    param(
        [Parameter(Mandatory)][string]$AttributeName = 'capability'
    )

    return [ordered]@{
        name              = 'group'
        nativeObjectType  = 'group'
        identityAttribute = 'id'
        displayAttribute  = 'name'
        attributes        = @(
            [ordered]@{ name = 'id'; type = 'STRING'; schema = $null; description = 'Entitlement id' }
            [ordered]@{ name = 'name'; type = 'STRING'; schema = $null; description = 'Entitlement display name' }
            [ordered]@{
                name          = $AttributeName
                type          = 'STRING'
                schema        = $null
                description   = 'Capability entitlement'
                isEntitlement = $true
                isGroup       = $true
            }
            [ordered]@{ name = 'description'; type = 'STRING'; schema = $null; description = 'Description' }
        )
    }
}

function New-IdentityAttributeField {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$IdentityAttribute,
        [bool]$Required = $false,
        [bool]$MultiValued = $false
    )

    return [ordered]@{
        name          = $Name
        transform     = [ordered]@{
            type       = 'identityAttribute'
            attributes = [ordered]@{ name = $IdentityAttribute }
        }
        attributes    = @{}
        isRequired    = $Required
        type          = 'string'
        isMultiValued = $MultiValued
    }
}

function Build-CreateAccountProvisioningPolicyPayload {
    param(
        [string]$Name = 'Account',
        [string]$Description = 'Create Account'
    )

    return [ordered]@{
        name        = $Name
        description = $Description
        usageType   = 'CREATE'
        fields      = @(
            (New-IdentityAttributeField -Name 'id' -IdentityAttribute 'uid' -Required $true)
            (New-IdentityAttributeField -Name 'name' -IdentityAttribute 'displayName' -Required $true)
            (New-IdentityAttributeField -Name 'givenName' -IdentityAttribute 'firstname')
            (New-IdentityAttributeField -Name 'familyName' -IdentityAttribute 'lastname')
            (New-IdentityAttributeField -Name 'e-mail' -IdentityAttribute 'email')
            (New-IdentityAttributeField -Name 'location' -IdentityAttribute 'city')
            (New-IdentityAttributeField -Name 'manager' -IdentityAttribute 'manager')
            [ordered]@{
                name          = 'groups'
                transform     = $null
                attributes    = @{}
                isRequired    = $false
                type          = 'string'
                isMultiValued = $true
            }
        )
    }
}

function Build-AccessProfilePayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string]$SourceId,
        [string]$SourceName,
        [Parameter(Mandatory)][string[]]$EntitlementIds,
        [bool]$Enabled = $true,
        [bool]$Requestable = $false
    )

    return [ordered]@{
        name         = $Name
        description  = $Description
        enabled      = $Enabled
        requestable  = $Requestable
        owner        = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        source       = [ordered]@{ type = 'SOURCE'; id = $SourceId; name = $SourceName }
        entitlements = @(
            foreach ($id in $EntitlementIds) {
                [ordered]@{ type = 'ENTITLEMENT'; id = $id }
            }
        )
    }
}

function Build-StandardRolePayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string[]]$EntitlementIds,
        [Parameter(Mandatory)]$Membership,
        [bool]$Enabled = $true,
        [bool]$Requestable = $false
    )

    return [ordered]@{
        name           = $Name
        description    = $Description
        enabled        = $Enabled
        requestable    = $Requestable
        owner          = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        entitlements   = @(
            foreach ($id in $EntitlementIds) {
                [ordered]@{ type = 'ENTITLEMENT'; id = $id }
            }
        )
        accessProfiles = @()
        membership     = $Membership
        dimensional    = $false
    }
}

function Build-DimensionalRolePayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string[]]$EntitlementIds,
        [Parameter(Mandatory)]$Membership,
        [Parameter(Mandatory)]$DimensionSchema,
        [bool]$Enabled = $true,
        [bool]$Requestable = $false
    )

    # API expects: dimensionSchema.dimensionAttributes[]
    if ($DimensionSchema -is [System.Collections.IDictionary] -and $DimensionSchema.Contains('dimensionAttributes')) {
        $schema = $DimensionSchema
    }
    else {
        $schema = [ordered]@{
            dimensionAttributes = @($DimensionSchema)
        }
    }

    return [ordered]@{
        name              = $Name
        description       = $Description
        enabled           = $Enabled
        requestable       = $Requestable
        owner             = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        entitlements      = @(
            foreach ($id in $EntitlementIds) {
                [ordered]@{ type = 'ENTITLEMENT'; id = $id }
            }
        )
        accessProfiles    = @()
        membership        = $Membership
        dimensional       = $true
        dimensionSchema   = $schema
    }
}

function Build-DimensionPayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string]$City,
        [Parameter(Mandatory)][string[]]$EntitlementIds
    )

    return [ordered]@{
        name         = $Name
        description  = $Description
        owner        = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        entitlements = @(
            foreach ($id in $EntitlementIds) {
                [ordered]@{ type = 'ENTITLEMENT'; id = $id }
            }
        )
        accessProfiles = @()
        membership   = [ordered]@{
            type     = 'STANDARD'
            criteria = (Build-IdentityEqualsCriterion -Attribute 'city' -Value $City)
        }
    }
}

function Build-SourceAppPayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$SourceId
    )

    return [ordered]@{
        name          = $Name
        description   = $Description
        accountSource = [ordered]@{ id = $SourceId }
    }
}

function Find-SourcesByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [scriptblock]$SourceFetcher
    )

    $escaped = $Name.Replace('"', '\"')
    $filters = "name eq `"$escaped`""
    if ($SourceFetcher) {
        return @(& $SourceFetcher $filters)
    }
    return @(Get-SourcesV1 -Filters $filters -Limit 250 -ErrorAction Stop)
}

function Find-RolesByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [scriptblock]$RoleFetcher
    )

    $escaped = $Name.Replace('"', '\"')
    $filters = "name eq `"$escaped`""
    if ($RoleFetcher) {
        return @(& $RoleFetcher $filters)
    }
    return @(Get-RolesV1 -Filters $filters -Limit 250 -ErrorAction Stop)
}

function Find-AccessProfilesByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$SourceId,
        [scriptblock]$AccessProfileFetcher
    )

    $escaped = $Name.Replace('"', '\"')
    $filters = "name eq `"$escaped`""
    if ($AccessProfileFetcher) {
        $profiles = @(& $AccessProfileFetcher $filters)
    }
    else {
        $profiles = @(Get-AccessProfilesV1 -Filters $filters -Limit 250 -ErrorAction Stop)
    }

    if ($SourceId) {
        $profiles = @(
            $profiles | Where-Object {
                $src = Get-ObjectPropertySafe -Object $_ -Name 'source' -AlternateNames @('Source')
                [string](Get-ObjectIdSafe -Object $src) -eq $SourceId
            }
        )
    }
    return @($profiles)
}

function Find-EntitlementByValue {
    param(
        [Parameter(Mandatory)][string]$SourceId,
        [Parameter(Mandatory)][string]$Value,
        [scriptblock]$EntitlementFetcher
    )

    $escapedValue = $Value.Replace('"', '\"')
    $filters = "source.id eq `"$SourceId`" and value eq `"$escapedValue`""
    if ($EntitlementFetcher) {
        return @(& $EntitlementFetcher $filters)
    }
    return @(
        Invoke-SailPointSdkPagedList -Fetcher {
            param($page)
            @(Get-EntitlementsV1 -Filters $filters -Offset $page.Offset -Limit $page.Limit -ErrorAction Stop)
        }
    )
}

function Resolve-OrCreateNamedObject {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Finder,
        [Parameter(Mandatory)][scriptblock]$CreatePayloadBuilder,
        [scriptblock]$CreateFetcher,
        [scriptblock]$PatchFetcher,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [switch]$WhatIf,
        [string]$ObjectLabel = 'object'
    )

    $existing = @(& $Finder)
    if ($existing.Count -gt 1) {
        return [pscustomobject]@{
            Status  = 'conflict'
            Id      = $null
            Name    = $Name
            Message = "Multiple ${ObjectLabel}s named '$Name' exist."
            Object  = $null
        }
    }

    if ($existing.Count -eq 1) {
        $existingId = Get-ObjectIdSafe -Object $existing[0]
        if ($ExistingItemAction -eq 'Skip') {
            return [pscustomobject]@{
                Status  = 'skipped'
                Id      = $existingId
                Name    = $Name
                Message = "Existing $ObjectLabel skipped."
                Object  = $existing[0]
            }
        }

        $payload = & $CreatePayloadBuilder
        if ($WhatIf) {
            return [pscustomobject]@{
                Status  = 'would-update'
                Id      = $existingId
                Name    = $Name
                Message = "WhatIf: would update $ObjectLabel."
                Payload = $payload
                Object  = $existing[0]
            }
        }
        if ($PatchFetcher) {
            $null = & $PatchFetcher $existingId $payload
        }
        return [pscustomobject]@{
            Status  = 'updated'
            Id      = $existingId
            Name    = $Name
            Message = "Existing $ObjectLabel updated."
            Object  = $existing[0]
        }
    }

    $payload = & $CreatePayloadBuilder
    if ($WhatIf) {
        return [pscustomobject]@{
            Status  = 'would-create'
            Id      = $null
            Name    = $Name
            Message = "WhatIf: would create $ObjectLabel."
            Payload = $payload
            Object  = $null
        }
    }

    $created = if ($CreateFetcher) {
        & $CreateFetcher $payload
    }
    else {
        $null
    }

    $newId = Get-ObjectIdSafe -Object $created
    if (-not $newId) {
        $again = @(& $Finder)
        $newId = Get-ObjectIdSafe -Object ($again | Select-Object -First 1)
    }

    return [pscustomobject]@{
        Status  = 'created'
        Id      = $newId
        Name    = $Name
        Message = "$ObjectLabel created."
        Object  = $created
    }
}

function Get-DemoCsvPath {
    param(
        [Parameter(Mandatory)][hashtable]$Model,
        [Parameter(Mandatory)][string]$SourceKey
    )

    $source = $null
    foreach ($candidate in @($Model['sources'])) {
        if ([string]$candidate['key'] -eq $SourceKey) {
            $source = $candidate
            break
        }
    }
    if (-not $source) { throw "Unknown source key '$SourceKey'." }
    return Join-Path (Get-DemoDataRoot) ('csv/' + [string]$source['csvFile'])
}

function Write-DemoEntitlementCsv {
    param(
        [Parameter(Mandatory)][hashtable]$Model,
        [Parameter(Mandatory)][string]$SourceKey,
        [string]$Path
    )

    if (-not $Path) {
        $Path = Get-DemoCsvPath -Model $Model -SourceKey $SourceKey
    }

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $rows = @($Model['entitlements'][$SourceKey])
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('id,name,description')
    foreach ($row in $rows) {
        $id = [string]$row['id']
        $name = [string]$row['name']
        $description = [string]$row['description']
        [void]$sb.AppendLine(('{0},{1},{2}' -f $id, $name, $description))
    }
    Set-Content -LiteralPath $Path -Value $sb.ToString() -Encoding UTF8
    return $Path
}

function Get-CurrentIscIdentity {
    param(
        [string]$OwnerId,
        [scriptblock]$TokenFetcher
    )

    if (-not [string]::IsNullOrWhiteSpace($OwnerId)) {
        return [pscustomobject]@{
            Id     = $OwnerId.Trim()
            Name   = $null
            Source = 'parameter'
        }
    }

    $token = $null
    if ($TokenFetcher) {
        $token = & $TokenFetcher
    }
    elseif (Get-Command Get-IDNAccessToken -ErrorAction SilentlyContinue) {
        try { $token = Get-IDNAccessToken } catch { }
    }

    if ($token) {
        $parts = ([string]$token).Split('.')
        if ($parts.Count -ge 2) {
            $payload = $parts[1]
            $pad = 4 - ($payload.Length % 4)
            if ($pad -lt 4) { $payload += ('=' * $pad) }
            $payload = $payload.Replace('-', '+').Replace('_', '/')
            try {
                $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
                $id = [string](Get-ObjectPropertySafe -Object $json -Name 'identity_id' -AlternateNames @('identityId', 'uid'))
                $name = [string](Get-ObjectPropertySafe -Object $json -Name 'user_name' -AlternateNames @('userName', 'sub'))
                if ($id -and $id -ne 'null') {
                    return [pscustomobject]@{
                        Id     = $id
                        Name   = $name
                        Source = 'token'
                    }
                }
            }
            catch { }
        }
    }

    throw 'Unable to resolve the current ISC identity. Pass -OwnerId or authenticate with a PAT whose token includes identity_id.'
}

function Resolve-DemoOwnerIdentity {
    param(
        [string]$OwnerId,
        [string]$OwnerAlias = 'slpt.services',
        [scriptblock]$IdentityFetcher,
        [scriptblock]$TokenFetcher
    )

    if (-not [string]::IsNullOrWhiteSpace($OwnerId)) {
        return Get-CurrentIscIdentity -OwnerId $OwnerId -TokenFetcher $TokenFetcher
    }

    $escaped = $OwnerAlias.Replace('"', '\"')
    $filters = "alias eq `"$escaped`""
    $hits = @()
    if ($IdentityFetcher) {
        $hits = @(& $IdentityFetcher $filters)
    }
    elseif (Get-Command Get-PublicIdentitiesV1 -ErrorAction SilentlyContinue) {
        $hits = @(Get-PublicIdentitiesV1 -Filters $filters -Limit 5 -ErrorAction SilentlyContinue)
    }
    elseif (Get-Command Get-IdentitiesV1 -ErrorAction SilentlyContinue) {
        $hits = @(Get-IdentitiesV1 -Filters $filters -Limit 5 -ErrorAction SilentlyContinue)
    }

    $id = Get-ObjectIdSafe -Object ($hits | Select-Object -First 1)
    if ($id) {
        $name = [string](Get-ObjectPropertySafe -Object ($hits | Select-Object -First 1) -Name 'name' -AlternateNames @('displayName', 'alias'))
        return [pscustomobject]@{
            Id     = $id
            Name   = $(if ($name) { $name } else { $OwnerAlias })
            Source = 'alias'
        }
    }

    return Get-CurrentIscIdentity -OwnerId $OwnerId -TokenFetcher $TokenFetcher
}

function Invoke-DemoDataBootstrap {
    param(
        [Parameter(Mandatory)][hashtable]$Model,
        [Parameter(Mandatory)][string]$OwnerId,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [switch]$WhatIf,
        [hashtable]$Hooks
    )

    if (-not $Hooks) { $Hooks = @{} }

    $validation = Test-DemoAccessModelInvariants -Model $Model
    if (-not $validation.Ok) {
        throw ("Demo access model failed validation:`n - {0}" -f ($validation.Errors -join "`n - "))
    }

    $results = [System.Collections.Generic.List[object]]::new()
    $sourceIds = @{}
    $entitlementIds = @{}
    $accessProfileIds = @{}
    $roleIds = @{}

    foreach ($source in @($Model['sources'])) {
        $sourceKey = [string]$source['key']
        $sourceName = [string]$source['name']
        $result = Resolve-OrCreateNamedObject -Name $sourceName -ObjectLabel 'source' `
            -ExistingItemAction $ExistingItemAction -WhatIf:$WhatIf `
            -Finder {
                if ($Hooks.ContainsKey('FindSources')) {
                    @(& $Hooks['FindSources'] $sourceName)
                }
                else {
                    @(Find-SourcesByName -Name $sourceName)
                }
            } `
            -CreatePayloadBuilder {
                Build-DelimitedFileSourcePayload -Name $sourceName -Description ([string]$source['description']) -OwnerId $OwnerId
            } `
            -CreateFetcher {
                param($payload)
                if ($Hooks.ContainsKey('CreateSource')) {
                    & $Hooks['CreateSource'] $payload
                }
                else {
                    New-SourceV1 -Source $payload -ErrorAction Stop
                }
            } `
            -PatchFetcher {
                param($id, $payload)
                if ($Hooks.ContainsKey('PatchSource')) {
                    & $Hooks['PatchSource'] $id $payload
                }
            }

        $results.Add([pscustomobject]@{
                Kind   = 'source'
                Key    = $sourceKey
                Name   = $sourceName
                Status = $result.Status
                Id     = $result.Id
            })
        if ($result.Id) { $sourceIds[$sourceKey] = $result.Id }

        if ($result.Id -and -not $WhatIf) {
            $policyPayload = Build-CreateAccountProvisioningPolicyPayload
            $policyResult = if ($Hooks.ContainsKey('EnsureCreateProvisioningPolicy')) {
                & $Hooks['EnsureCreateProvisioningPolicy'] $result.Id $policyPayload $ExistingItemAction
            }
            else {
                $existingPolicies = @()
                if (Get-Command Get-ProvisioningPoliciesV1 -ErrorAction SilentlyContinue) {
                    $existingPolicies = @(Get-ProvisioningPoliciesV1 -SourceId $result.Id -ErrorAction SilentlyContinue)
                }
                elseif (Get-Command Get-SourceProvisioningPoliciesV1 -ErrorAction SilentlyContinue) {
                    $existingPolicies = @(Get-SourceProvisioningPoliciesV1 -SourceId $result.Id -ErrorAction SilentlyContinue)
                }

                $createPolicy = @($existingPolicies | Where-Object {
                        [string](Get-ObjectPropertySafe -Object $_ -Name 'usageType') -eq 'CREATE'
                    }) | Select-Object -First 1

                if ($createPolicy) {
                    $policyId = Get-ObjectIdSafe -Object $createPolicy
                    if ($ExistingItemAction -eq 'Update') {
                        if (Get-Command Set-ProvisioningPolicyV1 -ErrorAction SilentlyContinue) {
                            $null = Set-ProvisioningPolicyV1 -SourceId $result.Id -UsageType 'CREATE' -ProvisioningPolicyDto $policyPayload -ErrorAction Stop
                        }
                        elseif (Get-Command Update-ProvisioningPolicyV1 -ErrorAction SilentlyContinue) {
                            $null = Update-ProvisioningPolicyV1 -SourceId $result.Id -UsageType 'CREATE' -ProvisioningPolicyDto $policyPayload -ErrorAction Stop
                        }
                        [pscustomobject]@{ Status = 'updated'; Id = $policyId }
                    }
                    else {
                        [pscustomobject]@{ Status = 'skipped'; Id = $policyId }
                    }
                }
                else {
                    $createdPolicy = $null
                    if (Get-Command New-ProvisioningPolicyV1 -ErrorAction SilentlyContinue) {
                        $createdPolicy = New-ProvisioningPolicyV1 -SourceId $result.Id -ProvisioningPolicyDto $policyPayload -ErrorAction Stop
                    }
                    elseif (Get-Command Create-ProvisioningPolicyV1 -ErrorAction SilentlyContinue) {
                        $createdPolicy = Create-ProvisioningPolicyV1 -SourceId $result.Id -ProvisioningPolicyDto $policyPayload -ErrorAction Stop
                    }
                    [pscustomobject]@{
                        Status = $(if ($createdPolicy) { 'created' } else { 'manual' })
                        Id     = (Get-ObjectIdSafe -Object $createdPolicy)
                        Message = $(if (-not $createdPolicy) { "Create Account provisioning policy for source '$sourceName'." } else { $null })
                    }
                }
            }

            $results.Add([pscustomobject]@{
                    Kind    = 'provisioning-policy'
                    Key     = $sourceKey
                    Name    = 'CREATE'
                    Status  = $policyResult.Status
                    Id      = $policyResult.Id
                    Message = (Get-ObjectPropertySafe -Object $policyResult -Name 'Message')
                })
        }

        if ($result.Id -and -not $WhatIf) {
            $csvPath = Get-DemoCsvPath -Model $Model -SourceKey $sourceKey
            if ($Hooks.ContainsKey('ImportEntitlements')) {
                $null = & $Hooks['ImportEntitlements'] $result.Id $csvPath $source
            }
            elseif (Get-Command Import-EntitlementsV1 -ErrorAction SilentlyContinue) {
                $null = Import-EntitlementsV1 -Id $result.Id -File $csvPath -ErrorAction Stop
            }
            elseif (Get-Command Import-SourceEntitlementsV1 -ErrorAction SilentlyContinue) {
                $null = Import-SourceEntitlementsV1 -Id $result.Id -File $csvPath -ErrorAction Stop
            }
            else {
                $results.Add([pscustomobject]@{
                        Kind    = 'entitlement-import'
                        Key     = $sourceKey
                        Name    = $sourceName
                        Status  = 'manual'
                        Message = "Upload $csvPath and aggregate entitlements for source '$sourceName'."
                    })
            }
        }
    }

    foreach ($sourceKey in @($Model['entitlements'].Keys)) {
        $sourceId = $sourceIds[$sourceKey]
        foreach ($ent in @($Model['entitlements'][$sourceKey])) {
            $value = [string]$ent['id']
            $entName = [string]$ent['name']
            if ($WhatIf -or -not $sourceId) {
                $entitlementIds[$value] = "pending:$value"
                continue
            }

            $hits = if ($Hooks.ContainsKey('FindEntitlements')) {
                @(& $Hooks['FindEntitlements'] $sourceId $value)
            }
            else {
                @(Find-EntitlementByValue -SourceId $sourceId -Value $value)
            }

            if ($hits.Count -eq 0 -and $Hooks.ContainsKey('FindEntitlementsByName')) {
                $hits = @(& $Hooks['FindEntitlementsByName'] $sourceId $entName)
            }

            $eid = Get-ObjectIdSafe -Object ($hits | Select-Object -First 1)
            if ($eid) {
                $entitlementIds[$value] = $eid
            }
            else {
                $results.Add([pscustomobject]@{
                        Kind    = 'entitlement'
                        Key     = $value
                        Name    = $entName
                        Status  = 'missing'
                        Message = "Entitlement '$entName' ($value) was not found on source '$sourceKey'. Aggregate entitlements and re-run."
                    })
            }
        }
    }

    function Resolve-LiveEntitlementIds {
        param([string[]]$ModelIds)
        $live = [System.Collections.Generic.List[string]]::new()
        foreach ($mid in $ModelIds) {
            if ($entitlementIds.ContainsKey([string]$mid) -and $entitlementIds[[string]$mid] -notlike 'pending:*') {
                $live.Add([string]$entitlementIds[[string]$mid])
            }
            elseif ($WhatIf) {
                $live.Add("whatif:$mid")
            }
        }
        return , $live.ToArray()
    }

    $standardRoles = @($Model['departmentRoles']) + @($Model['titleRoles']) + @($Model['sodViolationRoles'])
    foreach ($role in $standardRoles) {
        $roleName = [string]$role['name']
        $modelEntIds = @($role['entitlementIds'])
        $liveEntIds = @(Resolve-LiveEntitlementIds -ModelIds $modelEntIds)

        $membership = if ($role['membership']) { $role['membership'] } else {
            Build-ActiveAndAttributeMembership -Attribute ([string]$role['attribute']) -Value ([string]$role['attributeValue'])
        }

        $roleResult = Resolve-OrCreateNamedObject -Name $roleName -ObjectLabel 'role' `
            -ExistingItemAction $ExistingItemAction -WhatIf:$WhatIf `
            -Finder {
                if ($Hooks.ContainsKey('FindRoles')) {
                    @(& $Hooks['FindRoles'] $roleName)
                }
                else {
                    @(Find-RolesByName -Name $roleName)
                }
            } `
            -CreatePayloadBuilder {
                $requestable = $false
                $reqVal = Get-ObjectPropertySafe -Object $role -Name 'requestable'
                if ($null -ne $reqVal) { $requestable = [bool]$reqVal }
                Build-StandardRolePayload -Name $roleName -Description ([string]$role['description']) `
                    -OwnerId $OwnerId -EntitlementIds $liveEntIds -Membership $membership `
                    -Requestable $requestable
            } `
            -CreateFetcher {
                param($payload)
                if ($Hooks.ContainsKey('CreateRole')) {
                    & $Hooks['CreateRole'] $payload
                }
                else {
                    New-RoleV1 -Role $payload -ErrorAction Stop
                }
            } `
            -PatchFetcher {
                param($id, $payload)
                if ($Hooks.ContainsKey('PatchRole')) {
                    & $Hooks['PatchRole'] $id $payload
                }
                else {
                    $ops = @(
                        [pscustomobject]@{ op = 'replace'; path = '/name'; value = $payload['name'] }
                        [pscustomobject]@{ op = 'replace'; path = '/description'; value = $payload['description'] }
                        [pscustomobject]@{ op = 'replace'; path = '/enabled'; value = $payload['enabled'] }
                        [pscustomobject]@{ op = 'replace'; path = '/requestable'; value = $payload['requestable'] }
                        [pscustomobject]@{ op = 'replace'; path = '/owner'; value = $payload['owner'] }
                        [pscustomobject]@{ op = 'replace'; path = '/entitlements'; value = $payload['entitlements'] }
                        [pscustomobject]@{ op = 'replace'; path = '/accessProfiles'; value = $payload['accessProfiles'] }
                        [pscustomobject]@{ op = 'replace'; path = '/membership'; value = $payload['membership'] }
                    )
                    $null = Update-RoleV1 -Id $id -JsonPatchOperation $ops -ErrorAction Stop
                }
            }

        $results.Add([pscustomobject]@{
                Kind   = 'role'
                Key    = $roleName
                Name   = $roleName
                Status = $roleResult.Status
                Id     = $roleResult.Id
            })
        if ($roleResult.Id) { $roleIds[$roleName] = $roleResult.Id }
    }

    # Requestable access profiles
    foreach ($profile in @($Model['requestableAccessProfiles'])) {
        $profileName = [string]$profile['name']
        $sourceKey = [string]$profile['sourceKey']
        $sourceId = $sourceIds[$sourceKey]
        $sourceDefinition = @($Model['sources'] | Where-Object { $_['key'] -eq $sourceKey })[0]
        $sourceName = [string]$sourceDefinition['name']
        $liveEntIds = @(Resolve-LiveEntitlementIds -ModelIds @($profile['entitlementIds']))

        $profileResult = Resolve-OrCreateNamedObject -Name $profileName -ObjectLabel 'access profile' `
            -ExistingItemAction $ExistingItemAction -WhatIf:$WhatIf `
            -Finder {
                if ($Hooks.ContainsKey('FindAccessProfiles')) {
                    @(& $Hooks['FindAccessProfiles'] $profileName $sourceId)
                }
                else {
                    @(Find-AccessProfilesByName -Name $profileName -SourceId $sourceId)
                }
            } `
            -CreatePayloadBuilder {
                Build-AccessProfilePayload -Name $profileName -Description ([string]$profile['description']) `
                    -OwnerId $OwnerId -SourceId $(if ($sourceId) { $sourceId } else { 'pending-source' }) `
                    -SourceName $sourceName `
                    -EntitlementIds $liveEntIds -Requestable $true
            } `
            -CreateFetcher {
                param($payload)
                if ($Hooks.ContainsKey('CreateAccessProfile')) {
                    & $Hooks['CreateAccessProfile'] $payload
                }
                else {
                    New-AccessProfileV1 -AccessProfile $payload -ErrorAction Stop
                }
            } `
            -PatchFetcher {
                param($id, $payload)
                if ($Hooks.ContainsKey('PatchAccessProfile')) {
                    & $Hooks['PatchAccessProfile'] $id $payload
                }
                else {
                    $ops = @(
                        [pscustomobject]@{ op = 'replace'; path = '/name'; value = $payload['name'] }
                        [pscustomobject]@{ op = 'replace'; path = '/description'; value = $payload['description'] }
                        [pscustomobject]@{ op = 'replace'; path = '/enabled'; value = $payload['enabled'] }
                        [pscustomobject]@{ op = 'replace'; path = '/requestable'; value = $payload['requestable'] }
                        [pscustomobject]@{ op = 'replace'; path = '/owner'; value = $payload['owner'] }
                        [pscustomobject]@{ op = 'replace'; path = '/source'; value = $payload['source'] }
                        [pscustomobject]@{ op = 'replace'; path = '/entitlements'; value = $payload['entitlements'] }
                    )
                    $null = Update-AccessProfileV1 -Id $id -JsonPatchOperation $ops -ErrorAction Stop
                }
            }

        $results.Add([pscustomobject]@{
                Kind   = 'access-profile'
                Key    = $profileName
                Name   = $profileName
                Status = $profileResult.Status
                Id     = $profileResult.Id
            })
        if ($profileResult.Id) { $accessProfileIds[$profileName] = $profileResult.Id }
    }

    # Source applications
    foreach ($source in @($Model['sources'])) {
        $sourceKey = [string]$source['key']
        $appName = [string]$source['applicationName']
        $sourceId = $sourceIds[$sourceKey]
        $appResult = Resolve-OrCreateNamedObject -Name $appName -ObjectLabel 'source app' `
            -ExistingItemAction $ExistingItemAction -WhatIf:$WhatIf `
            -Finder {
                if ($Hooks.ContainsKey('FindSourceApps')) {
                    @(& $Hooks['FindSourceApps'] $appName $sourceId)
                }
                else {
                    $escaped = $appName.Replace('"', '\"')
                    @(Get-AllSourceAppV1 -Filters ("name eq `"$escaped`"") -Limit 250 -XSailPointExperimental 'true' -ErrorAction Stop)
                }
            } `
            -CreatePayloadBuilder {
                Build-SourceAppPayload -Name $appName -Description ([string]$source['applicationDescription']) `
                    -SourceId $(if ($sourceId) { $sourceId } else { 'pending-source' })
            } `
            -CreateFetcher {
                param($payload)
                if ($Hooks.ContainsKey('CreateSourceApp')) {
                    & $Hooks['CreateSourceApp'] $payload
                }
                else {
                    New-SourceAppV1 -SourceAppCreateDto $payload -XSailPointExperimental 'true' -ErrorAction Stop
                }
            } `
            -PatchFetcher {
                param($id, $payload)
                if ($Hooks.ContainsKey('PatchSourceApp')) {
                    & $Hooks['PatchSourceApp'] $id $payload
                }
            }

        $results.Add([pscustomobject]@{
                Kind   = 'source-app'
                Key    = $sourceKey
                Name   = $appName
                Status = $appResult.Status
                Id     = $appResult.Id
            })
    }

    # Workplace User dimensional role
    $office = $Model['workplaceRole']
    $officeName = [string]$office['name']
    $officeEntIds = @(Resolve-LiveEntitlementIds -ModelIds @($office['entitlementIds']))
    $officeMembership = if ($office['membership']) { $office['membership'] } else { Build-OfficeUserMembership }
    $dimensionSchema = $office['dimensionSchema']

    $officeRoleResult = Resolve-OrCreateNamedObject -Name $officeName -ObjectLabel 'dimensional role' `
        -ExistingItemAction $ExistingItemAction -WhatIf:$WhatIf `
        -Finder {
            if ($Hooks.ContainsKey('FindRoles')) {
                @(& $Hooks['FindRoles'] $officeName)
            }
            else {
                @(Find-RolesByName -Name $officeName)
            }
        } `
        -CreatePayloadBuilder {
            Build-DimensionalRolePayload -Name $officeName -Description ([string]$office['description']) `
                -OwnerId $OwnerId -EntitlementIds $officeEntIds -Membership $officeMembership `
                -DimensionSchema $dimensionSchema
        } `
        -CreateFetcher {
            param($payload)
            if ($Hooks.ContainsKey('CreateRole')) {
                & $Hooks['CreateRole'] $payload
            }
            else {
                New-RoleV1 -Role $payload -ErrorAction Stop
            }
        } `
        -PatchFetcher {
            param($id, $payload)
            if ($Hooks.ContainsKey('PatchRole')) {
                & $Hooks['PatchRole'] $id $payload
            }
            else {
                $ops = @(
                    [pscustomobject]@{ op = 'replace'; path = '/name'; value = $payload['name'] }
                    [pscustomobject]@{ op = 'replace'; path = '/description'; value = $payload['description'] }
                    [pscustomobject]@{ op = 'replace'; path = '/enabled'; value = $payload['enabled'] }
                    [pscustomobject]@{ op = 'replace'; path = '/requestable'; value = $payload['requestable'] }
                    [pscustomobject]@{ op = 'replace'; path = '/owner'; value = $payload['owner'] }
                    [pscustomobject]@{ op = 'replace'; path = '/entitlements'; value = $payload['entitlements'] }
                    [pscustomobject]@{ op = 'replace'; path = '/membership'; value = $payload['membership'] }
                    [pscustomobject]@{ op = 'replace'; path = '/dimensionSchema'; value = $payload['dimensionSchema'] }
                )
                $null = Update-RoleV1 -Id $id -JsonPatchOperation $ops -ErrorAction Stop
            }
        }

    $results.Add([pscustomobject]@{
            Kind   = 'role'
            Key    = 'workplaceUser'
            Name   = $officeName
            Status = $officeRoleResult.Status
            Id     = $officeRoleResult.Id
        })

    $officeRoleId = $officeRoleResult.Id
    foreach ($dim in @($office['dimensions'])) {
        $dimName = [string]$dim['name']
        $dimEntIds = @(Resolve-LiveEntitlementIds -ModelIds @($dim['entitlementIds']))
        $dimPayload = Build-DimensionPayload -Name $dimName -Description ([string]$dim['description']) `
            -OwnerId $OwnerId -City ([string]$dim['attributeValue']) -EntitlementIds $dimEntIds

        if ($WhatIf -or -not $officeRoleId) {
            $results.Add([pscustomobject]@{
                    Kind   = 'dimension'
                    Key    = $dimName
                    Name   = $dimName
                    Status = $(if ($WhatIf) { 'would-create' } else { 'skipped' })
                    Id     = $null
                })
            continue
        }

        $existingDims = if ($Hooks.ContainsKey('FindDimensions')) {
            @(& $Hooks['FindDimensions'] $officeRoleId $dimName)
        }
        elseif (Get-Command Get-RoleDimensionsV1 -ErrorAction SilentlyContinue) {
            @(Get-RoleDimensionsV1 -RoleId $officeRoleId -ErrorAction Stop | Where-Object {
                    [string](Get-ObjectPropertySafe -Object $_ -Name 'name') -eq $dimName
                })
        }
        else {
            @()
        }

        if ($existingDims.Count -gt 1) {
            $results.Add([pscustomobject]@{
                    Kind    = 'dimension'
                    Key     = $dimName
                    Name    = $dimName
                    Status  = 'conflict'
                    Message = "Multiple dimensions named '$dimName' exist on Workplace User."
                })
            continue
        }

        if ($existingDims.Count -eq 1) {
            $dimId = Get-ObjectIdSafe -Object $existingDims[0]
            if ($ExistingItemAction -eq 'Update') {
                if ($Hooks.ContainsKey('PatchDimension')) {
                    $null = & $Hooks['PatchDimension'] $officeRoleId $dimId $dimPayload
                }
                elseif (Get-Command Update-RoleDimensionV1 -ErrorAction SilentlyContinue) {
                    $ops = @(
                        [pscustomobject]@{ op = 'replace'; path = '/name'; value = $dimPayload['name'] }
                        [pscustomobject]@{ op = 'replace'; path = '/description'; value = $dimPayload['description'] }
                        [pscustomobject]@{ op = 'replace'; path = '/membership'; value = $dimPayload['membership'] }
                        [pscustomobject]@{ op = 'replace'; path = '/entitlements'; value = $dimPayload['entitlements'] }
                    )
                    $null = Update-RoleDimensionV1 -RoleId $officeRoleId -Id $dimId -JsonPatchOperation $ops -ErrorAction Stop
                }
                $results.Add([pscustomobject]@{
                        Kind   = 'dimension'
                        Key    = $dimName
                        Name   = $dimName
                        Status = 'updated'
                        Id     = $dimId
                    })
            }
            else {
                $results.Add([pscustomobject]@{
                        Kind   = 'dimension'
                        Key    = $dimName
                        Name   = $dimName
                        Status = 'skipped'
                        Id     = $dimId
                    })
            }
            continue
        }

        $createdDim = if ($Hooks.ContainsKey('CreateDimension')) {
            & $Hooks['CreateDimension'] $officeRoleId $dimPayload
        }
        elseif (Get-Command New-RoleDimensionV1 -ErrorAction SilentlyContinue) {
            New-RoleDimensionV1 -RoleId $officeRoleId -Dimension $dimPayload -ErrorAction Stop
        }
        elseif (Get-Command New-DimensionV1 -ErrorAction SilentlyContinue) {
            New-DimensionV1 -RoleId $officeRoleId -Dimension $dimPayload -ErrorAction Stop
        }
        else {
            $null
        }

        $results.Add([pscustomobject]@{
                Kind   = 'dimension'
                Key    = $dimName
                Name   = $dimName
                Status = $(if ($createdDim) { 'created' } else { 'manual' })
                Id     = (Get-ObjectIdSafe -Object $createdDim)
                Message = $(if (-not $createdDim) { "Create dimension '$dimName' under Workplace User via API/UI." } else { $null })
            })
    }

    return [pscustomobject]@{
        Results          = @($results.ToArray())
        SourceIds        = $sourceIds
        EntitlementIds   = $entitlementIds
        AccessProfileIds = $accessProfileIds
        RoleIds          = $roleIds
        OfficeRoleId     = $officeRoleId
        WorkplaceRoleId  = $officeRoleId
    }
}

function Import-DemoSodPolicies {
    param([string]$Path)

    if (-not $Path) {
        $Path = Join-Path (Get-DemoDataRoot) 'config/demo-sod-policies.json'
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Demo SoD policies were not found at $Path"
    }
    return ConvertTo-HashtableDeep -InputObject (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json)
}

function Build-SodControlPayload {
    param(
        [Parameter(Mandatory)][hashtable]$Control,
        [Parameter(Mandatory)][string]$OwnerId
    )

    return [ordered]@{
        name                   = [string]$Control['name']
        description            = [string]$Control['description']
        owner                  = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        type                   = $(if ($Control['type']) { [string]$Control['type'] } else { 'Mitigation' })
        expiration             = $(if ($Control['expiration']) { [string]$Control['expiration'] } else { '14d' })
        justificationRequired  = [bool]($(if ($null -ne $Control['justificationRequired']) { $Control['justificationRequired'] } else { $true }))
    }
}

function Build-SodAllowedControlRefs {
    param(
        [Parameter(Mandatory)][hashtable]$Policy,
        [Parameter(Mandatory)][hashtable]$ControlIdsByKey,
        [Parameter(Mandatory)][hashtable]$ControlNamesByKey
    )

    $refs = [System.Collections.Generic.List[object]]::new()
    foreach ($controlKey in @($Policy['allowedControlIds'])) {
        $key = [string]$controlKey
        if (-not $ControlIdsByKey.ContainsKey($key)) {
            throw "SoD policy '$($Policy['id'])' references unknown control '$key'."
        }
        $refs.Add([ordered]@{
                type = 'COMPENSATING_CONTROL'
                id   = [string]$ControlIdsByKey[$key]
                name = [string]$ControlNamesByKey[$key]
            })
    }
    return @($refs.ToArray())
}

function Build-SodPolicyPayload {
    param(
        [Parameter(Mandatory)][hashtable]$Policy,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][hashtable]$EntitlementIdsByName,
        [string[]]$Tags = @('demo-data', 'sod'),
        [object[]]$AllowedControls = @()
    )

    function Resolve-Side {
        param([hashtable]$Side, [string]$Label)
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($entName in @($Side['entitlementNames'])) {
            if (-not $EntitlementIdsByName.ContainsKey([string]$entName)) {
                throw "SoD policy missing live entitlement '$entName' for $Label."
            }
            $list.Add([ordered]@{
                    type = 'ENTITLEMENT'
                    id   = [string]$EntitlementIdsByName[[string]$entName]
                })
        }
        return [ordered]@{
            name         = [string]$Side['name']
            criteriaList = @($list.ToArray())
        }
    }

    $level = switch -Regex ([string]$Policy['severity']) {
        '^(?i)critical$' { 'CRITICAL' }
        '^(?i)high$' { 'HIGH' }
        '^(?i)medium$' { 'MEDIUM' }
        '^(?i)low$' { 'LOW' }
        default { 'HIGH' }
    }

    $payload = [ordered]@{
        name                             = [string]$Policy['name']
        description                      = [string]$Policy['description']
        ownerRef                         = [ordered]@{ type = 'IDENTITY'; id = $OwnerId }
        externalPolicyReference          = [string]$Policy['id']
        compensatingControls             = [string]$Policy['compensatingControls']
        correctionAdvice                 = [string]$Policy['correctionAdvice']
        state                            = $(if ($Policy['state']) { [string]$Policy['state'] } else { 'ENFORCED' })
        tags                             = @($Tags)
        violationOwnerAssignmentConfig   = [ordered]@{ assignmentRule = 'MANAGER' }
        scheduled                        = $false
        type                             = 'CONFLICTING_ACCESS_BASED'
        level                            = $level
        conflictingAccessCriteria        = [ordered]@{
            leftCriteria  = (Resolve-Side -Side $Policy['left'] -Label 'left')
            rightCriteria = (Resolve-Side -Side $Policy['right'] -Label 'right')
        }
    }
    if (@($AllowedControls).Count -gt 0) {
        $payload['allowedControls'] = @($AllowedControls)
    }
    return $payload
}

function Invoke-DemoSodControlBootstrap {
    param(
        [Parameter(Mandatory)][hashtable]$SodModel,
        [Parameter(Mandatory)][string]$OwnerId,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [switch]$WhatIf,
        [hashtable]$Hooks
    )

    if (-not $Hooks) { $Hooks = @{} }
    $results = [System.Collections.Generic.List[object]]::new()
    $controlIdsByKey = @{}
    $controlNamesByKey = @{}

    foreach ($control in @($SodModel['mitigatingControls'])) {
        $controlKey = [string]$control['id']
        $controlName = [string]$control['name']
        $controlNamesByKey[$controlKey] = $controlName
        $payload = Build-SodControlPayload -Control $control -OwnerId $OwnerId

        $found = @()
        if ($Hooks.ContainsKey('FindControls')) {
            $found = @(& $Hooks['FindControls'] $controlName $controlKey)
        }
        elseif (Get-Command Get-ControlsV1 -ErrorAction SilentlyContinue) {
            $escaped = $controlName.Replace("'", "''")
            $found = @(Get-ControlsV1 -XSailPointExperimental 'true' -Filters ("name eq '$escaped'") -Limit 25 -ErrorAction SilentlyContinue)
            if (@($found).Count -eq 0) {
                $all = @(Get-ControlsV1 -XSailPointExperimental 'true' -Limit 250 -ErrorAction SilentlyContinue)
                $found = @($all | Where-Object { [string](Get-ObjectPropertySafe -Object $_ -Name 'name') -eq $controlName })
            }
        }
        $existing = @($found)

        if (@($existing).Count -gt 1) {
            $results.Add([pscustomobject]@{
                    Kind    = 'sod-control'
                    Key     = $controlKey
                    Name    = $controlName
                    Status  = 'conflict'
                    Message = "Multiple SoD controls named '$controlName'."
                })
            continue
        }

        if (@($existing).Count -eq 1) {
            $id = Get-ObjectIdSafe -Object $existing[0]
            $controlIdsByKey[$controlKey] = $id
            if ($ExistingItemAction -eq 'Update' -and -not $WhatIf) {
                if ($Hooks.ContainsKey('UpdateControl')) {
                    $null = & $Hooks['UpdateControl'] $id $payload
                }
                elseif (Get-Command Send-ControlV1 -ErrorAction SilentlyContinue) {
                    $null = Send-ControlV1 -XSailPointExperimental 'true' -Id $id -Compensatingcontrolupdate $payload -ErrorAction Stop
                }
                $results.Add([pscustomobject]@{
                        Kind   = 'sod-control'
                        Key    = $controlKey
                        Name   = $controlName
                        Status = 'updated'
                        Id     = $id
                    })
            }
            else {
                $results.Add([pscustomobject]@{
                        Kind   = 'sod-control'
                        Key    = $controlKey
                        Name   = $controlName
                        Status = $(if ($WhatIf -and $ExistingItemAction -eq 'Update') { 'would-update' } else { 'skipped' })
                        Id     = $id
                    })
            }
            continue
        }

        if ($WhatIf) {
            $results.Add([pscustomobject]@{
                    Kind   = 'sod-control'
                    Key    = $controlKey
                    Name   = $controlName
                    Status = 'would-create'
                    Id     = $null
                })
            continue
        }

        $created = if ($Hooks.ContainsKey('CreateControl')) {
            & $Hooks['CreateControl'] $payload
        }
        elseif (Get-Command New-ControlV1 -ErrorAction SilentlyContinue) {
            New-ControlV1 -XSailPointExperimental 'true' -Compensatingcontrolcreate $payload -ErrorAction Stop
        }
        else {
            $null
        }

        $createdId = Get-ObjectIdSafe -Object $created
        if ($createdId) { $controlIdsByKey[$controlKey] = $createdId }
        $results.Add([pscustomobject]@{
                Kind    = 'sod-control'
                Key     = $controlKey
                Name    = $controlName
                Status  = $(if ($created) { 'created' } else { 'manual' })
                Id      = $createdId
                Message = $(if (-not $created) { "Create SoD control '$controlName' via API/UI." } else { $null })
            })
    }

    return [pscustomobject]@{
        Results            = @($results.ToArray())
        ControlIdsByKey    = $controlIdsByKey
        ControlNamesByKey  = $controlNamesByKey
    }
}

function Set-DemoSodPolicyAllowedControls {
    param(
        [Parameter(Mandatory)][string]$PolicyLiveId,
        [Parameter(Mandatory)][object[]]$AllowedControls,
        [hashtable]$Hooks
    )

    if (-not $Hooks) { $Hooks = @{} }
    $patch = @(
        [ordered]@{
            op    = 'replace'
            path  = '/allowedControls'
            value = @($AllowedControls)
        }
    )

    if ($Hooks.ContainsKey('PatchSodPolicy')) {
        return & $Hooks['PatchSodPolicy'] $PolicyLiveId $patch
    }
    if (Get-Command Update-SodPolicyV1 -ErrorAction SilentlyContinue) {
        return Update-SodPolicyV1 -Id $PolicyLiveId -JsonPatchOperation $patch -ErrorAction Stop
    }
    throw "No SoD policy patch cmdlet available for policy '$PolicyLiveId'."
}

function Invoke-DemoSodPolicyBootstrap {
    param(
        [Parameter(Mandatory)][hashtable]$SodModel,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][hashtable]$EntitlementIdsByName,
        [hashtable]$ControlIdsByKey,
        [hashtable]$ControlNamesByKey,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [switch]$WhatIf,
        [hashtable]$Hooks
    )

    if (-not $Hooks) { $Hooks = @{} }
    if (-not $ControlIdsByKey) { $ControlIdsByKey = @{} }
    if (-not $ControlNamesByKey) { $ControlNamesByKey = @{} }
    $results = [System.Collections.Generic.List[object]]::new()
    $tags = @($SodModel['tags'])
    if ($tags.Count -eq 0) { $tags = @('demo-data', 'sod') }
    $assignControls = ($ControlIdsByKey.Keys.Count -gt 0)

    foreach ($policy in @($SodModel['policies'])) {
        $policyId = [string]$policy['id']
        $policyName = [string]$policy['name']
        $payload = $null
        $allowedRefs = @()
        try {
            if ($assignControls -and @($policy['allowedControlIds']).Count -gt 0) {
                $allowedRefs = Build-SodAllowedControlRefs -Policy $policy `
                    -ControlIdsByKey $ControlIdsByKey -ControlNamesByKey $ControlNamesByKey
            }
            $payload = Build-SodPolicyPayload -Policy $policy -OwnerId $OwnerId `
                -EntitlementIdsByName $EntitlementIdsByName -Tags $tags -AllowedControls $allowedRefs
        }
        catch {
            $results.Add([pscustomobject]@{
                    Kind    = 'sod-policy'
                    Key     = $policyId
                    Name    = $policyName
                    Status  = 'missing'
                    Message = "$_"
                })
            continue
        }

        $found = @()
        if ($Hooks.ContainsKey('FindSodPolicies')) {
            $found = @(& $Hooks['FindSodPolicies'] $policyName $policyId)
        }
        elseif (Get-Command Get-SodPoliciesV1 -ErrorAction SilentlyContinue) {
            $escapedName = $policyName.Replace('"', '\"')
            $found = @(Get-SodPoliciesV1 -Filters ("name eq `"$escapedName`"") -Limit 25 -ErrorAction SilentlyContinue)
            if (@($found).Count -eq 0) {
                $escapedRef = $policyId.Replace('"', '\"')
                $found = @(Get-SodPoliciesV1 -Filters ("externalPolicyReference eq `"$escapedRef`"") -Limit 25 -ErrorAction SilentlyContinue)
            }
            if (@($found).Count -eq 0 -and $policyName -notlike 'SOD - *') {
                $legacyName = "SOD - $policyName"
                $escapedLegacy = $legacyName.Replace('"', '\"')
                $found = @(Get-SodPoliciesV1 -Filters ("name eq `"$escapedLegacy`"") -Limit 25 -ErrorAction SilentlyContinue)
            }
        }
        $existing = @($found)

        if (@($existing).Count -gt 1) {
            $results.Add([pscustomobject]@{
                    Kind   = 'sod-policy'
                    Key    = $policyId
                    Name   = $policyName
                    Status = 'conflict'
                    Message = "Multiple SoD policies named '$policyName'."
                })
            continue
        }

        if (@($existing).Count -eq 1) {
            $id = Get-ObjectIdSafe -Object $existing[0]
            if ($ExistingItemAction -eq 'Update' -and -not $WhatIf) {
                if ($Hooks.ContainsKey('PutSodPolicy')) {
                    $null = & $Hooks['PutSodPolicy'] $id $payload
                }
                elseif (Get-Command Send-SodPolicyV1 -ErrorAction SilentlyContinue) {
                    $null = Send-SodPolicyV1 -Id $id -SodPolicy $payload -ErrorAction Stop
                }
                if ($allowedRefs.Count -gt 0) {
                    $null = Set-DemoSodPolicyAllowedControls -PolicyLiveId $id -AllowedControls $allowedRefs -Hooks $Hooks
                }
                $results.Add([pscustomobject]@{
                        Kind   = 'sod-policy'
                        Key    = $policyId
                        Name   = $policyName
                        Status = 'updated'
                        Id     = $id
                    })
            }
            else {
                if (-not $WhatIf -and $allowedRefs.Count -gt 0 -and $ExistingItemAction -eq 'Skip') {
                    # Still attach controls when policies already exist from a prior run.
                    try {
                        $null = Set-DemoSodPolicyAllowedControls -PolicyLiveId $id -AllowedControls $allowedRefs -Hooks $Hooks
                        $results.Add([pscustomobject]@{
                                Kind   = 'sod-policy'
                                Key    = $policyId
                                Name   = $policyName
                                Status = 'controls-assigned'
                                Id     = $id
                            })
                        continue
                    }
                    catch {
                        $results.Add([pscustomobject]@{
                                Kind    = 'sod-policy'
                                Key     = $policyId
                                Name    = $policyName
                                Status  = 'skipped'
                                Id      = $id
                                Message = "Policy skipped; control assignment failed: $_"
                            })
                        continue
                    }
                }
                $results.Add([pscustomobject]@{
                        Kind   = 'sod-policy'
                        Key    = $policyId
                        Name   = $policyName
                        Status = $(if ($WhatIf -and $ExistingItemAction -eq 'Update') { 'would-update' } else { 'skipped' })
                        Id     = $id
                    })
            }
            continue
        }

        if ($WhatIf) {
            $results.Add([pscustomobject]@{
                    Kind   = 'sod-policy'
                    Key    = $policyId
                    Name   = $policyName
                    Status = 'would-create'
                    Id     = $null
                })
            continue
        }

        # Create without allowedControls first — some tenants reject them on POST.
        $createPayload = [ordered]@{}
        foreach ($key in @($payload.Keys)) {
            if ($key -eq 'allowedControls') { continue }
            $createPayload[$key] = $payload[$key]
        }

        $created = if ($Hooks.ContainsKey('CreateSodPolicy')) {
            & $Hooks['CreateSodPolicy'] $createPayload
        }
        elseif (Get-Command New-SodPolicyV1 -ErrorAction SilentlyContinue) {
            New-SodPolicyV1 -SodPolicy $createPayload -ErrorAction Stop
        }
        else {
            $null
        }

        $createdId = Get-ObjectIdSafe -Object $created
        if ($created -and $allowedRefs.Count -gt 0 -and $createdId) {
            $null = Set-DemoSodPolicyAllowedControls -PolicyLiveId $createdId -AllowedControls $allowedRefs -Hooks $Hooks
        }

        $results.Add([pscustomobject]@{
                Kind    = 'sod-policy'
                Key     = $policyId
                Name    = $policyName
                Status  = $(if ($created) { 'created' } else { 'manual' })
                Id      = $createdId
                Message = $(if (-not $created) { "Create SoD policy '$policyName' via API/UI." } else { $null })
            })
    }

    return [pscustomobject]@{
        Results = @($results.ToArray())
    }
}

Export-ModuleMember -Function @(
    'Get-DemoDataRoot'
    'Get-ObjectPropertySafe'
    'Get-ObjectIdSafe'
    'Import-DemoAccessModel'
    'Import-DemoSodPolicies'
    'Get-DemoModelEntitlementCatalog'
    'Test-DemoAccessModelInvariants'
    'Build-IdentityEqualsCriterion'
    'Build-IdentityContainsCriterion'
    'Build-ActiveAndAttributeMembership'
    'Build-OfficeUserMembership'
    'Build-DelimitedFileSourcePayload'
    'Build-EntitlementGroupSchemaPayload'
    'Build-CreateAccountProvisioningPolicyPayload'
    'Build-AccessProfilePayload'
    'Build-StandardRolePayload'
    'Build-DimensionalRolePayload'
    'Build-DimensionPayload'
    'Build-SourceAppPayload'
    'Build-SodControlPayload'
    'Build-SodAllowedControlRefs'
    'Build-SodPolicyPayload'
    'Find-SourcesByName'
    'Find-RolesByName'
    'Find-AccessProfilesByName'
    'Find-EntitlementByValue'
    'Resolve-OrCreateNamedObject'
    'Get-DemoCsvPath'
    'Write-DemoEntitlementCsv'
    'Get-CurrentIscIdentity'
    'Resolve-DemoOwnerIdentity'
    'Invoke-DemoDataBootstrap'
    'Invoke-DemoSodControlBootstrap'
    'Set-DemoSodPolicyAllowedControls'
    'Invoke-DemoSodPolicyBootstrap'
)
