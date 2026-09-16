#Requires -Version 5.1
Set-StrictMode -Version Latest

function Test-IsEntraIscSource {
    param([Parameter(Mandatory)]$Source)

    $type = [string]($Source.type)
    $connector = ''
    if ($Source.PSObject.Properties['connector'] -and $Source.connector) {
        $connector = [string]$Source.connector
    }
    elseif ($Source.PSObject.Properties['connectorName'] -and $Source.connectorName) {
        $connector = [string]$Source.connectorName
    }

    $name = [string]$Source.name
    $blob = "$type|$connector|$name".ToLowerInvariant()
    return $blob -match 'entra|azure\s*ad|azuread|microsoft.?entra|ms.?graph|azure active directory'
}

function Get-ServicePlanEntitlementsForSource {
    param(
        [Parameter(Mandatory)][string]$SourceId,
        [scriptblock]$EntitlementFetcher
    )

    $filters = "source.id eq `"$SourceId`" and type eq `"servicePlan`""
    $items = if ($EntitlementFetcher) {
        @(& $EntitlementFetcher $filters)
    }
    else {
        @(
            Invoke-SailPointSdkPagedList -Fetcher {
                param($page)
                @(Get-EntitlementsV1 -Filters $filters -Offset $page.Offset -Limit $page.Limit -ErrorAction Stop)
            }
        )
    }

    # Flatten accidental nested arrays from SDK/`return ,` callers.
    return [object[]]@(Expand-EntitlementList -Entitlements $items)
}

function Find-EntraSourcesWithServicePlans {
    param(
        [scriptblock]$SourceFetcher,
        [scriptblock]$EntitlementFetcher
    )

    $sources = if ($SourceFetcher) {
        @(& $SourceFetcher)
    }
    else {
        @(
            Invoke-SailPointSdkPagedList -Fetcher {
                param($page)
                @(Get-SourcesV1 -Offset $page.Offset -Limit $page.Limit -ErrorAction Stop)
            }
        )
    }

    $matchedSources = [System.Collections.Generic.List[object]]::new()
    foreach ($source in $sources) {
        if (-not (Test-IsEntraIscSource -Source $source)) { continue }
        $plans = @(Get-ServicePlanEntitlementsForSource -SourceId ([string]$source.id) -EntitlementFetcher $EntitlementFetcher)
        if ($plans.Count -eq 0) { continue }
        $matchedSources.Add([pscustomobject]@{
                Id           = [string]$source.id
                Name         = [string]$source.name
                Type         = [string]$source.type
                PlanCount    = $plans.Count
                Source       = $source
                ServicePlans = $plans
            })
    }
    # Always return a flat object array. Avoid `,$array` which nests and breaks single-hit callers.
    return [object[]]@($matchedSources.ToArray())
}

function Get-ServicePlanFriendlyNameQuality {
    param(
        [AllowNull()][string]$PlanName,
        [AllowNull()][string]$Friendly
    )

    if ([string]::IsNullOrWhiteSpace($Friendly)) { return -1 }
    $friendly = $Friendly.Trim()
    $plan = if ($PlanName) { $PlanName.Trim() } else { '' }

    # Microsoft CSV often repeats the raw plan code as the "friendly" value.
    if ($plan -and $friendly.Equals($plan, [System.StringComparison]::OrdinalIgnoreCase)) { return 0 }
    # ALL-CAPS labels (even with spaces/punctuation) are weak CSV leftovers.
    if ($friendly -ceq $friendly.ToUpperInvariant() -and $friendly -match '[A-Z]') {
        return 1
    }

    $score = 10
    if ($friendly -match '\s') { $score += 20 }
    # Prefer current Entra branding over legacy Azure AD labels when both exist.
    if ($friendly -match '(?i)Microsoft Entra') { $score += 15 }
    elseif ($friendly -match '(?i)Azure Active Directory') { $score += 5 }
    # Prefer title-style product names over shouty CSV fragments.
    if ($friendly -cmatch '[a-z]') { $score += 10 }
    $score += [Math]::Min($friendly.Length, 40)
    return $score
}

function Set-ServicePlanFriendlyMapEntry {
    param(
        [Parameter(Mandatory)][hashtable]$Map,
        [Parameter(Mandatory)][string]$Key,
        [AllowNull()][string]$PlanName,
        [Parameter(Mandatory)][string]$Friendly,
        [switch]$Force
    )

    $quality = Get-ServicePlanFriendlyNameQuality -PlanName $PlanName -Friendly $Friendly
    if ($quality -lt 0) { return }
    if (-not $Force -and $Map.ContainsKey($Key)) {
        $existingQuality = Get-ServicePlanFriendlyNameQuality -PlanName $PlanName -Friendly ([string]$Map[$Key])
        if ($quality -le $existingQuality) { return }
    }
    $Map[$Key] = $Friendly.Trim()
}

function Get-ServicePlanFriendlyNameOverrides {
    # Microsoft's CSV leaves a few plan codes without a human label (or only the code).
    return [ordered]@{
        'YAMMER_ENTERPRISE'   = 'Yammer Enterprise'
        'YAMMER_MIDSIZE'      = 'Yammer Midsize'
        'NUCLEUS'             = 'Microsoft Nucleus'
        'ONEDRIVEENTERPRISE'  = 'OneDrive for Business (Plan 2)'
        'SHAREPOINTLITE'      = 'SharePoint Lite'
        'ONEDRIVESTANDARD'    = 'OneDrive for Business (Plan 1)'
        'MCOPSTN3'            = 'Skype for Business PSTN Calling'
        'BI_AZURE_P0'         = 'Power BI (free)'
        'AAD_PREMIUM'         = 'Microsoft Entra ID P1'
        'AAD_PREMIUM_P2'      = 'Microsoft Entra ID P2'
        'EXCHANGE_S_ENTERPRISE' = 'Exchange Online (Plan 2)'
        'EXCHANGE_S_STANDARD'   = 'Exchange Online (Plan 1)'
        'EXCHANGE_S_DESKLESS'   = 'Exchange Online Kiosk'
        'EXCHANGE_B_STANDARD'   = 'Exchange Online POP'
        'EXCHANGE_L_STANDARD'   = 'Exchange Online (Plan 1)'
        'EXCHANGE_S_ESSENTIALS' = 'Exchange Online Essentials'
        'EXCHANGE_S_STANDARD_MIDMARKET' = 'Exchange Online (Plan 1)'
        'EXCHANGE_S_ARCHIVE'    = 'Exchange Online Archiving for Exchange Server'
        'SHAREPOINTENTERPRISE'  = 'SharePoint Online (Plan 2)'
        'SHAREPOINTSTANDARD'    = 'SharePoint Online (Plan 1)'
        'OFFICESUBSCRIPTION'    = 'Microsoft 365 Apps for enterprise'
        'SHAREPOINTWAC'         = 'Office for the web'
        '7547a3fe-08ee-4ccb-b430-5077c5041653' = 'Yammer Enterprise'
        'db4d623d-b514-490b-b7ef-8885eee514de' = 'Microsoft Nucleus'
        'afcafa6a-d966-4462-918c-ec0b4e0fe642' = 'OneDrive for Business (Plan 2)'
        '41781fb2-bc02-4b7c-bd55-b576c07bb09d' = 'Microsoft Entra ID P1'
        'eec0eb4f-6444-4f95-aba0-50c24d67f998' = 'Microsoft Entra ID P2'
        'efb87545-963c-4e0d-99df-69c6916d9eb0' = 'Exchange Online (Plan 2)'
        '9aaf7827-d63c-4b61-89c3-182f06f82e5c' = 'Exchange Online (Plan 1)'
        '5dbe027f-2339-4123-9542-606e4d348a72' = 'SharePoint Online (Plan 2)'
        '43de0ff5-c92c-492b-9116-175376d08c38' = 'Microsoft 365 Apps for enterprise'
        'e95bec33-7c88-4a70-8e19-b10bd9d0c014' = 'Office for the web'
    }
}

function Resolve-LicensingCsvFriendlyFragment {
    param(
        [Parameter(Mandatory)][string]$FriendlyColumn,
        [AllowNull()][string]$PlanId
    )

    $friendly = $FriendlyColumn.Trim()
    if (-not $friendly) { return $friendly }

    if ($PlanId -and $friendly -match [regex]::Escape($PlanId)) {
        # Allow nested display parens like "SharePoint (Plan 2) (guid)".
        $pattern = "((?:[^();]|\([^)]*\))+?)\s*\(\s*$([regex]::Escape($PlanId))\s*\)"
        if ($friendly -match $pattern) {
            $fragment = $Matches[1].Trim()
            # CSV sometimes glues names: "SharePoint (Plan 2)Dynamics 365..."
            if ($fragment -match '\)(?=[A-Za-z])') {
                $parts = [regex]::Split($fragment, '(?<=\))(?=[A-Za-z])')
                $fragment = $parts[-1].Trim()
            }
            return $fragment
        }
    }

    if ($friendly -notmatch ';' -and $friendly -notmatch '\([0-9a-fA-F-]{36}\)') {
        return $friendly
    }

    $first = ($friendly -split ';')[0].Trim()
    if ($first -match '^(.*?)\s*\([0-9a-fA-F-]{36}\)\s*$') {
        return $Matches[1].Trim()
    }
    return $first
}

function ConvertFrom-MicrosoftLicensingCsv {
    param([Parameter(Mandatory)][string]$CsvText)

    $rows = $CsvText | ConvertFrom-Csv
    $byPlanId = @{}
    $byPlanName = @{}

    foreach ($row in $rows) {
        $props = @{}
        foreach ($p in $row.PSObject.Properties) {
            $props[$p.Name.Trim().Trim([char]0xFEFF)] = [string]$p.Value
        }

        $planId = $null
        $planName = $null
        $friendly = $null

        foreach ($key in $props.Keys) {
            $normalized = $key.ToLowerInvariant().Replace(' ', '_')
            switch -Regex ($normalized) {
                '^service_plan_id$' { $planId = $props[$key]; break }
                '^service_plan_name$' { $planName = $props[$key]; break }
                'friendly' {
                    if (-not $friendly) { $friendly = $props[$key] }
                }
            }
        }

        if (-not $friendly) {
            foreach ($key in $props.Keys) {
                if ($key -match 'Service_Plans_Included_Friendly_Names|ServicePlanFriendly') {
                    $friendly = $props[$key]
                    break
                }
            }
        }

        if (-not $friendly) { continue }

        $matchedFriendly = Resolve-LicensingCsvFriendlyFragment -FriendlyColumn $friendly -PlanId $planId

        if ($planId) {
            Set-ServicePlanFriendlyMapEntry -Map $byPlanId -Key $planId.ToLowerInvariant() -PlanName $planName -Friendly $matchedFriendly
        }
        if ($planName) {
            Set-ServicePlanFriendlyMapEntry -Map $byPlanName -Key $planName.ToUpperInvariant() -PlanName $planName -Friendly $matchedFriendly
        }
    }

    foreach ($entry in (Get-ServicePlanFriendlyNameOverrides).GetEnumerator()) {
        $key = [string]$entry.Key
        $value = [string]$entry.Value
        if ($key -match '^[0-9a-fA-F-]{36}$') {
            Set-ServicePlanFriendlyMapEntry -Map $byPlanId -Key $key.ToLowerInvariant() -PlanName $null -Friendly $value -Force
        }
        else {
            Set-ServicePlanFriendlyMapEntry -Map $byPlanName -Key $key.ToUpperInvariant() -PlanName $key -Friendly $value -Force
        }
    }

    return [pscustomobject]@{
        ByPlanId   = $byPlanId
        ByPlanName = $byPlanName
    }
}

function Get-MicrosoftServicePlanFriendlyNameMap {
    param(
        [string]$CsvUrl,
        [string]$CsvText
    )

    if (-not $CsvText) {
        $url = if ($CsvUrl) { $CsvUrl } else { Get-MicrosoftLicensingCsvUrl }
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $content = $response.Content
        if ($content -is [byte[]]) {
            $CsvText = [System.Text.Encoding]::UTF8.GetString($content)
        }
        else {
            $CsvText = [string]$content
        }
    }
    return ConvertFrom-MicrosoftLicensingCsv -CsvText $CsvText
}

function Get-ServicePlanLookupKeys {
    param(
        [AllowNull()][string]$Name,
        [AllowNull()][string]$Value
    )

    $keys = [System.Collections.Generic.List[string]]::new()
    foreach ($raw in @($Name, $Value)) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        $trimmed = $raw.Trim()
        if (-not $keys.Contains($trimmed)) { $keys.Add($trimmed) }

        # Entra connector entitlement names: "AAD_PREMIUM [of] DEVELOPERPACK_E5"
        if ($trimmed -match '^\s*(?<plan>.+?)\s*\[of\]\s*(?<sku>.+)\s*$') {
            $plan = $Matches['plan'].Trim()
            if ($plan -and -not $keys.Contains($plan)) { $keys.Add($plan) }
        }
    }
    return [string[]]@($keys.ToArray())
}

function Get-ObjectPropertySafe {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$AlternateNames = @()
    )

    if ($null -eq $Object) { return $null }

    $names = @($Name) + @($AlternateNames)

    # PSSailpoint array responses deserialize with ConvertFrom-Json -AsHashtable.
    # Hashtable PSObject.Properties are Keys/Values/Count — not the JSON fields.
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

function Resolve-ServicePlanFriendlyName {
    param(
        [Parameter(Mandatory)]$Entitlement,
        [Parameter(Mandatory)]$FriendlyNameMap
    )

    $value = [string](Get-ObjectPropertySafe -Object $Entitlement -Name 'value' -AlternateNames @('Value', 'attributeValue'))
    $name = [string](Get-ObjectPropertySafe -Object $Entitlement -Name 'name' -AlternateNames @('Name', 'attribute'))
    $displayName = [string](Get-ObjectPropertySafe -Object $Entitlement -Name 'displayName' -AlternateNames @('DisplayName'))
    $id = [string](Get-ObjectPropertySafe -Object $Entitlement -Name 'id' -AlternateNames @('Id'))

    $attributes = Get-ObjectPropertySafe -Object $Entitlement -Name 'attributes' -AlternateNames @('Attributes')
    $attrPlanId = [string](Get-ObjectPropertySafe -Object $attributes -Name 'servicePlanId' -AlternateNames @('ServicePlanId', 'GUID', 'guid'))
    $attrPlanName = [string](Get-ObjectPropertySafe -Object $attributes -Name 'servicePlanName' -AlternateNames @('ServicePlanName', 'skuPartNumber'))

    foreach ($candidate in @($value, $attrPlanId)) {
        if (-not $candidate) { continue }
        $key = $candidate.ToLowerInvariant()
        if ($FriendlyNameMap.ByPlanId.ContainsKey($key)) {
            return [string]$FriendlyNameMap.ByPlanId[$key]
        }
    }

    foreach ($candidate in (Get-ServicePlanLookupKeys -Name $name -Value $value) + @($attrPlanName)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $key = $candidate.ToUpperInvariant()
        if ($FriendlyNameMap.ByPlanName.ContainsKey($key)) {
            return [string]$FriendlyNameMap.ByPlanName[$key]
        }
    }

    if ($displayName) { return $displayName }
    # Prefer bare plan name over "PLAN [of] SKU" when no CSV hit.
    foreach ($candidate in (Get-ServicePlanLookupKeys -Name $name -Value $value)) {
        if ($candidate -notmatch '\[of\]') { return $candidate }
    }
    if ($name) { return $name }
    if ($value) { return $value }
    if ($id) { return $id }
    return 'Unknown service plan'
}

function Expand-EntitlementList {
    param([AllowNull()]$Entitlements)

    $flat = [System.Collections.Generic.List[object]]::new()
    foreach ($item in @($Entitlements)) {
        if ($null -eq $item) { continue }
        if ($item -is [System.Array] -and -not ($item -is [string])) {
            foreach ($inner in (Expand-EntitlementList -Entitlements $item)) {
                $flat.Add($inner)
            }
        }
        else {
            $flat.Add($item)
        }
    }
    return [object[]]@($flat.ToArray())
}

function Build-ServicePlanSelectionRows {
    param(
        [Parameter(Mandatory)][object[]]$Entitlements,
        [Parameter(Mandatory)]$FriendlyNameMap
    )

    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($ent in (Expand-EntitlementList -Entitlements $Entitlements)) {
        $friendly = Resolve-ServicePlanFriendlyName -Entitlement $ent -FriendlyNameMap $FriendlyNameMap
        $value = [string](Get-ObjectPropertySafe -Object $ent -Name 'value' -AlternateNames @('Value', 'attributeValue'))
        $name = [string](Get-ObjectPropertySafe -Object $ent -Name 'name' -AlternateNames @('Name', 'attribute'))
        $id = [string](Get-ObjectPropertySafe -Object $ent -Name 'id' -AlternateNames @('Id'))
        $lookupKeys = @(Get-ServicePlanLookupKeys -Name $name -Value $value)
        $barePlan = @($lookupKeys | Where-Object { $_ -notmatch '\[of\]' } | Select-Object -First 1)
        $internal = if ($barePlan) { [string]$barePlan[0] } elseif ($name) { $name } elseif ($value) { $value } else { $id }
        if (-not $internal) { $internal = 'unknown' }
        # Menu -Options cannot be empty strings; prefer id, then value, then internal name.
        $optionKey = if ($id) { $id } elseif ($value) { $value } else { $internal }
        $list.Add([pscustomobject]@{
                Id           = $optionKey
                Value        = $value
                InternalName = $internal
                FriendlyName = $friendly
                Label        = "$friendly  ($internal)"
                Entitlement  = $ent
            })
    }
    $sorted = @($list | Sort-Object FriendlyName, InternalName)
    return [object[]]@($sorted)
}

function New-AccessProfileName {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Prefix,
        [Parameter(Mandatory)][string]$FriendlyName
    )

    # Normalize "...-" / "... -" / "...- " to "... - " so the friendly name is separated cleanly.
    $prefix = $Prefix.TrimEnd()
    if ($prefix -match '-\s*$') {
        $prefix = ($prefix -replace '-\s*$', '').TrimEnd() + ' - '
    }
    elseif ($prefix -and -not $prefix.EndsWith(' ')) {
        $prefix = "$prefix "
    }

    return ($prefix + $FriendlyName.Trim()).Trim()
}

function Get-M365ReplayAccessProfileName {
    param(
        [Parameter(Mandatory)]$ManifestRow,
        [Parameter(Mandatory)][string]$CurrentFriendlyName,
        [AllowEmptyString()][string]$ManifestPrefix
    )

    if (-not [string]::IsNullOrWhiteSpace($ManifestPrefix)) {
        return New-AccessProfileName -Prefix $ManifestPrefix -FriendlyName $CurrentFriendlyName
    }

    $previousName = [string](Get-ObjectPropertySafe -Object $ManifestRow -Name 'AccessProfileName')
    $previousFriendlyName = [string](Get-ObjectPropertySafe -Object $ManifestRow -Name 'FriendlyName')
    if ($previousName -and $previousFriendlyName -and
        $previousName.EndsWith($previousFriendlyName, [StringComparison]::OrdinalIgnoreCase)) {
        $inferredPrefix = $previousName.Substring(0, $previousName.Length - $previousFriendlyName.Length)
        return New-AccessProfileName -Prefix $inferredPrefix -FriendlyName $CurrentFriendlyName
    }

    if ($previousName) { return $previousName }
    return New-AccessProfileName -Prefix '' -FriendlyName $CurrentFriendlyName
}

function Get-M365AccessProfileLookupNames {
    param(
        [Parameter(Mandatory)]$ManifestRow,
        [Parameter(Mandatory)][string]$CurrentFriendlyName,
        [AllowEmptyString()][string]$ManifestPrefix
    )

    $names = [System.Collections.Generic.List[string]]::new()
    $add = {
        param([string]$Candidate)
        if ([string]::IsNullOrWhiteSpace($Candidate)) { return }
        if (-not $names.Contains($Candidate)) { $names.Add($Candidate) }
    }

    & $add ([string](Get-ObjectPropertySafe -Object $ManifestRow -Name 'AccessProfileName'))
    if (-not [string]::IsNullOrWhiteSpace($ManifestPrefix)) {
        & $add (New-AccessProfileName -Prefix $ManifestPrefix -FriendlyName $CurrentFriendlyName)
    }
    & $add (Get-M365ReplayAccessProfileName -ManifestRow $ManifestRow `
            -CurrentFriendlyName $CurrentFriendlyName -ManifestPrefix $ManifestPrefix)
    & $add (Get-M365ReplayAccessProfileName -ManifestRow $ManifestRow `
            -CurrentFriendlyName $CurrentFriendlyName -ManifestPrefix '')
    return [string[]]@($names)
}

function Find-AccessProfilesByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$SourceId,
        [scriptblock]$AccessProfileFetcher
    )

    $escaped = $Name.Replace('"', '\"')
    $filters = "name eq `"$escaped`""
    if ($PSBoundParameters.ContainsKey('AccessProfileFetcher') -and $null -ne $AccessProfileFetcher) {
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

function Get-ObjectIdSafe {
    param($Object)
    if ($null -eq $Object) { return $null }
    if ($Object -is [string]) { return $Object }
    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in @('id', 'Id')) {
            if ($Object.Contains($key) -and $Object[$key]) { return [string]$Object[$key] }
            # Hashtable Contains is case-sensitive for some implementations; scan keys.
        }
        foreach ($key in @($Object.Keys)) {
            if ([string]$key -ieq 'id' -and $Object[$key]) { return [string]$Object[$key] }
        }
        return $null
    }
    $id = Get-ObjectPropertySafe -Object $Object -Name 'id' -AlternateNames @('Id')
    if ($id) { return [string]$id }
    return $null
}

function Get-AccessProfileEntitlementIds {
    param(
        [Parameter(Mandatory)]$AccessProfile,
        [scriptblock]$EntitlementListFetcher
    )

    $entitlements = Get-ObjectPropertySafe -Object $AccessProfile -Name 'entitlements' -AlternateNames @('Entitlements')
    if ($null -ne $entitlements) {
        $ids = foreach ($ent in @($entitlements)) {
            if ($null -eq $ent) { continue }
            if ($ent -is [string]) { $ent; continue }
            $id = Get-ObjectIdSafe -Object $ent
            if ($id) { $id }
        }
        return @($ids)
    }

    if ($EntitlementListFetcher) {
        return @(& $EntitlementListFetcher (Get-ObjectIdSafe -Object $AccessProfile) | ForEach-Object {
                if ($_ -is [string]) { $_ } else { Get-ObjectIdSafe -Object $_ }
            })
    }

    if (-not (Get-Command Get-AccessProfileEntitlementsV1 -ErrorAction SilentlyContinue)) {
        return @()
    }

    $listed = @(Get-AccessProfileEntitlementsV1 -Id (Get-ObjectIdSafe -Object $AccessProfile) -Limit 250 -ErrorAction Stop)
    return @($listed | ForEach-Object { [string]$_.id })
}

function Build-AccessProfileCreatePayload {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$SourceId,
        [string]$SourceName,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string]$EntitlementId,
        [string]$Description,
        [bool]$Enabled = $true,
        [bool]$Requestable = $true
    )

    return [pscustomobject]@{
        name        = $Name
        description = $(if ($Description) { $Description } else { "Microsoft 365 service plan access profile for $Name" })
        enabled     = $Enabled
        requestable = $Requestable
        owner       = [pscustomobject]@{ type = 'IDENTITY'; id = $OwnerId }
        source      = [pscustomobject]@{
            type = 'SOURCE'
            id   = $SourceId
            name = $SourceName
        }
        entitlements = @(
            [pscustomobject]@{ type = 'ENTITLEMENT'; id = $EntitlementId }
        )
    }
}

function Resolve-OrCreateAccessProfileForPlan {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$SourceId,
        [string]$SourceName,
        [Parameter(Mandatory)][string]$OwnerId,
        [Parameter(Mandatory)][string]$EntitlementId,
        [string]$Description,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [string[]]$PreviousNames = @(),
        [switch]$WhatIf,
        [scriptblock]$AccessProfileFetcher,
        [scriptblock]$CreateFetcher,
        [scriptblock]$EntitlementListFetcher,
        [scriptblock]$PatchFetcher
    )

    $lookupNames = [System.Collections.Generic.List[string]]::new()
    foreach ($candidate in @($Name) + @($PreviousNames)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if (-not $lookupNames.Contains($candidate)) { $lookupNames.Add($candidate) }
    }

    $existing = @()
    foreach ($candidate in $lookupNames) {
        $hits = @(Find-AccessProfilesByName -Name $candidate -SourceId $SourceId -AccessProfileFetcher $AccessProfileFetcher)
        if ($hits.Count -eq 0) { continue }
        $existing = $hits
        break
    }
    if ($existing.Count -gt 1) {
        return [pscustomobject]@{
            Status          = 'conflict'
            AccessProfileId = $null
            Name            = $Name
            Message         = "Multiple access profiles named '$Name' exist on this source."
        }
    }

    if ($existing.Count -eq 1) {
        $existingId = Get-ObjectIdSafe -Object $existing[0]
        if ($ExistingItemAction -eq 'Skip') {
            return [pscustomobject]@{
                Status          = 'skipped'
                AccessProfileId = $existingId
                Name            = $Name
                Message         = 'Existing access profile skipped.'
            }
        }

        $desiredDescription = if ($Description) { $Description } else { "Microsoft 365 service plan access profile for $Name" }
        $ops = @(
            [pscustomobject]@{ op = 'replace'; path = '/name'; value = $Name }
            [pscustomobject]@{ op = 'replace'; path = '/description'; value = $desiredDescription }
            [pscustomobject]@{ op = 'replace'; path = '/enabled'; value = $true }
            [pscustomobject]@{ op = 'replace'; path = '/requestable'; value = $true }
            [pscustomobject]@{ op = 'replace'; path = '/owner'; value = [pscustomobject]@{ type = 'IDENTITY'; id = $OwnerId } }
            [pscustomobject]@{ op = 'replace'; path = '/source'; value = [pscustomobject]@{ type = 'SOURCE'; id = $SourceId; name = $SourceName } }
            [pscustomobject]@{ op = 'replace'; path = '/entitlements'; value = @([pscustomobject]@{ type = 'ENTITLEMENT'; id = $EntitlementId }) }
        )
        if ($WhatIf) {
            return [pscustomobject]@{
                Status          = 'would-update'
                AccessProfileId = $existingId
                Name            = $Name
                Message         = 'WhatIf: would reconcile existing access profile.'
                Operations      = $ops
            }
        }
        if ($PatchFetcher) {
            $null = & $PatchFetcher $existingId $ops
        }
        else {
            $null = Update-AccessProfileV1 -Id $existingId -JsonPatchOperation $ops -ErrorAction Stop
        }
        return [pscustomobject]@{
            Status          = 'updated'
            AccessProfileId = $existingId
            Name            = $Name
            Message         = 'Existing access profile reconciled.'
        }
    }

    $payload = Build-AccessProfileCreatePayload -Name $Name -SourceId $SourceId -SourceName $SourceName `
        -OwnerId $OwnerId -EntitlementId $EntitlementId -Description $Description

    if ($WhatIf) {
        return [pscustomobject]@{
            Status          = 'would-create'
            AccessProfileId = $null
            Name            = $Name
            Message         = 'WhatIf: would create access profile.'
            Payload         = $payload
        }
    }

    $created = if ($CreateFetcher) {
        & $CreateFetcher $payload
    }
    else {
        New-AccessProfileV1 -AccessProfile $payload -ErrorAction Stop
    }

    $newId = Get-ObjectIdSafe -Object $created
    if (-not $newId) {
        # Some SDK/API responses omit the body; re-read by name so callers can link the AP to an app.
        $newId = Get-ObjectIdSafe -Object (
            @(Find-AccessProfilesByName -Name $Name -SourceId $SourceId -AccessProfileFetcher $AccessProfileFetcher) |
                Select-Object -First 1
        )
    }

    return [pscustomobject]@{
        Status          = 'created'
        AccessProfileId = $newId
        Name            = $Name
        Message         = 'Access profile created.'
    }
}

function Find-SourceAppByName {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$SourceId,
        [scriptblock]$SourceAppFetcher
    )

    $escaped = $Name.Replace('"', '\"')
    $filters = "name eq `"$escaped`""
    if ($PSBoundParameters.ContainsKey('SourceAppFetcher') -and $null -ne $SourceAppFetcher) {
        $apps = @(& $SourceAppFetcher $filters)
    }
    else {
        $apps = @(Get-AllSourceAppV1 -Filters $filters -Limit 250 -XSailPointExperimental 'true' -ErrorAction Stop)
    }

    if ($SourceId) {
        $apps = @(
            $apps | Where-Object {
                $accountSource = Get-ObjectPropertySafe -Object $_ -Name 'accountSource' -AlternateNames @('AccountSource')
                [string](Get-ObjectIdSafe -Object $accountSource) -eq $SourceId
            }
        )
    }
    return @($apps)
}

function Resolve-OrCreateSourceApp {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$SourceId,
        [string]$Description = 'Microsoft 365 service plan access profiles',
        [string]$OwnerId,
        [ValidateSet('Skip', 'Update')]
        [string]$ExistingItemAction = 'Skip',
        [switch]$WhatIf,
        [scriptblock]$SourceAppFetcher,
        [scriptblock]$CreateFetcher,
        [scriptblock]$OwnerPatchFetcher
    )

    $existing = @(Find-SourceAppByName -Name $Name -SourceId $SourceId -SourceAppFetcher $SourceAppFetcher)
    if ($existing.Count -gt 1) {
        throw "Multiple source apps named '$Name' exist for this source."
    }
    if ($existing.Count -eq 1) {
        $appId = Get-ObjectIdSafe -Object $existing[0]
        if ($ExistingItemAction -eq 'Skip') {
            return [pscustomobject]@{
                Status = 'skipped'
                AppId  = $appId
                Name   = $Name
                App    = $existing[0]
            }
        }

        $ops = @(
            [pscustomobject]@{ op = 'replace'; path = '/name'; value = $Name }
            [pscustomobject]@{ op = 'replace'; path = '/description'; value = $Description }
            [pscustomobject]@{ op = 'replace'; path = '/owner'; value = [pscustomobject]@{ type = 'IDENTITY'; id = $OwnerId } }
            [pscustomobject]@{ op = 'replace'; path = '/accountSource'; value = [pscustomobject]@{ id = $SourceId } }
        )
        if ($WhatIf) {
            return [pscustomobject]@{
                Status     = 'would-update'
                AppId      = $appId
                Name       = $Name
                App        = $existing[0]
                Operations = $ops
            }
        }
        if ($OwnerPatchFetcher) {
            $null = & $OwnerPatchFetcher $appId $ops
        }
        else {
            $null = Update-SourceAppV1 -Id $appId -JsonPatchOperation $ops -XSailPointExperimental 'true' -ErrorAction Stop
        }
        return [pscustomobject]@{
            Status = 'updated'
            AppId  = $appId
            Name   = $Name
            App    = $existing[0]
        }
    }

    $payload = [pscustomobject]@{
        name           = $Name
        description    = $Description
        accountSource  = [pscustomobject]@{ id = $SourceId }
    }

    if ($WhatIf) {
        return [pscustomobject]@{
            Status  = 'would-create'
            AppId   = $null
            Name    = $Name
            Payload = $payload
            App     = $null
        }
    }

    $created = if ($CreateFetcher) {
        & $CreateFetcher $payload
    }
    else {
        New-SourceAppV1 -SourceAppCreateDto $payload -XSailPointExperimental 'true' -ErrorAction Stop
    }

    $appId = Get-ObjectIdSafe -Object $created
    if (-not $appId) {
        # The create response can omit the body; re-read by name so access profiles can still be linked.
        $appId = Get-ObjectIdSafe -Object (
            @(Find-SourceAppByName -Name $Name -SourceId $SourceId -SourceAppFetcher $SourceAppFetcher) |
                Select-Object -First 1
        )
    }

    if ($OwnerId -and $appId) {
        $ops = @(
            [pscustomobject]@{
                op    = 'replace'
                path  = '/owner'
                value = [pscustomobject]@{ type = 'IDENTITY'; id = $OwnerId }
            }
        )
        if ($OwnerPatchFetcher) {
            $null = & $OwnerPatchFetcher $appId $ops
        }
        else {
            $null = Update-SourceAppV1 -Id $appId -JsonPatchOperation $ops -XSailPointExperimental 'true' -ErrorAction Stop
        }
    }

    return [pscustomobject]@{
        Status = 'created'
        AppId  = $appId
        Name   = $Name
        App    = $created
    }
}

function Build-SourceAppAccessProfilePatch {
    param(
        [Parameter(Mandatory)][string[]]$AccessProfileIds,
        [string[]]$ExistingAccessProfileIds = @()
    )

    $existing = [System.Collections.Generic.HashSet[string]]::new([string[]]@($ExistingAccessProfileIds))
    $ops = foreach ($id in $AccessProfileIds) {
        if ($existing.Contains($id)) { continue }
        [pscustomobject]@{
            op    = 'add'
            path  = '/accessProfiles/-'
            value = $id
        }
    }
    return , @($ops)
}

function Add-AccessProfilesToSourceApp {
    param(
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string[]]$AccessProfileIds,
        [switch]$WhatIf,
        [scriptblock]$ExistingFetcher,
        [scriptblock]$PatchFetcher
    )

    $existing = if ($ExistingFetcher) {
        @(& $ExistingFetcher $AppId)
    }
    else {
        @(Get-AccessProfilesForSourceAppV1 -Id $AppId -Limit 250 -XSailPointExperimental 'true' -ErrorAction SilentlyContinue)
    }
    $existingIds = @($existing | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['id']) { [string]$_.id }
            else { [string]$_ }
        })

    $ops = @(Build-SourceAppAccessProfilePatch -AccessProfileIds $AccessProfileIds -ExistingAccessProfileIds $existingIds)
    if ($ops.Count -eq 0) {
        return [pscustomobject]@{ Status = 'unchanged'; Added = @(); Operations = @() }
    }

    if ($WhatIf) {
        return [pscustomobject]@{
            Status     = 'would-patch'
            Added      = @($ops | ForEach-Object { $_.value })
            Operations = $ops
        }
    }

    if ($PatchFetcher) {
        $null = & $PatchFetcher $AppId $ops
    }
    else {
        $null = Update-SourceAppV1 -Id $AppId -JsonPatchOperation $ops -XSailPointExperimental 'true' -ErrorAction Stop
    }

    return [pscustomobject]@{
        Status     = 'patched'
        Added      = @($ops | ForEach-Object { $_.value })
        Operations = $ops
    }
}

function Find-IdentitiesByQuery {
    param(
        [Parameter(Mandatory)][string]$Query,
        [scriptblock]$IdentityFetcher
    )

    if ($IdentityFetcher) {
        return [object[]]@(Expand-EntitlementList -Entitlements (& $IdentityFetcher $Query))
    }

    $escaped = $Query.Replace('"', '\"').Trim()
    if (-not $escaped) { return [object[]]@() }

    $byId = [ordered]@{}
    $addHits = {
        param($Items)
        foreach ($item in (Expand-EntitlementList -Entitlements $Items)) {
            $id = [string](Get-ObjectPropertySafe -Object $item -Name 'id' -AlternateNames @('Id'))
            if ($id -and -not $byId.Contains($id)) {
                $byId[$id] = $item
            }
        }
    }

    # 1) Preferred: ISC Search (free-text across name/alias/email).
    try {
        $searchBody = [pscustomobject]@{
            indices = @('identities')
            query   = [pscustomobject]@{ query = $Query.Trim() }
            sort    = @('displayName')
        }
        $searchHits = @(Search-PostV1 -Search $searchBody -Limit 25 -ErrorAction Stop)
        & $addHits $searchHits
    }
    catch {
        # Fall through to filter-based lookups.
    }

    if ($byId.Count -gt 0) {
        return [object[]]@($byId.Values)
    }

    # 2) Public identities: alias/email/firstname/lastname with sw/eq (no "name" / no "co").
    $publicFilters = @(
        "alias sw `"$escaped`""
        "email sw `"$escaped`""
        "firstname sw `"$escaped`""
        "lastname sw `"$escaped`""
        "alias eq `"$escaped`""
        "email eq `"$escaped`""
    )
    foreach ($filters in $publicFilters) {
        try {
            if (Get-Command Get-PublicIdentitiesV1 -ErrorAction SilentlyContinue) {
                & $addHits (Get-PublicIdentitiesV1 -Filters $filters -Limit 25 -ErrorAction Stop)
            }
        }
        catch { }
    }

    if ($byId.Count -gt 0) {
        return [object[]]@($byId.Values)
    }

    # 3) Identities list: name/alias/email support eq/sw only (not co).
    $identityFilters = @(
        "name sw `"$escaped`""
        "alias sw `"$escaped`""
        "email sw `"$escaped`""
        "name eq `"$escaped`""
        "alias eq `"$escaped`""
        "email eq `"$escaped`""
    )
    foreach ($filters in $identityFilters) {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $err = $null
            $page = Get-IdentitiesV1 -Filters $filters -Limit 25 -ErrorAction SilentlyContinue -ErrorVariable err
            if ($err) { continue }
            & $addHits $page
        }
        catch {
            # Swallow 400/unsupported filter combinations.
        }
        finally {
            $ErrorActionPreference = $prevEap
        }
    }

    return [object[]]@($byId.Values)
}

function ConvertFrom-JwtPayload {
    param([AllowNull()][string]$Token)

    if ([string]::IsNullOrWhiteSpace($Token)) { return $null }
    $parts = $Token.Split('.')
    if ($parts.Count -lt 2) { return $null }
    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        1 { return $null }
        2 { $payload += '==' }
        3 { $payload += '=' }
    }
    try {
        $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
        return $json | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Get-CurrentIscIdentity {
    param(
        [string]$OwnerId,
        [scriptblock]$TokenFetcher,
        [scriptblock]$PersonalAccessTokenFetcher
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

    $payload = ConvertFrom-JwtPayload -Token ([string]$token)
    if ($payload) {
        $id = [string](Get-ObjectPropertySafe -Object $payload -Name 'identity_id' -AlternateNames @('identityId', 'uid'))
        $name = [string](Get-ObjectPropertySafe -Object $payload -Name 'user_name' -AlternateNames @('userName', 'sub'))
        if (-not [string]::IsNullOrWhiteSpace($id) -and $id -ne 'null') {
            return [pscustomobject]@{
                Id     = $id
                Name   = $name
                Source = 'token'
            }
        }
    }

    $tokens = @()
    if ($PersonalAccessTokenFetcher) {
        $tokens = @(Expand-EntitlementList -Entitlements (& $PersonalAccessTokenFetcher))
    }
    elseif (Get-Command Get-PersonalAccessTokensV1 -ErrorAction SilentlyContinue) {
        try {
            $tokens = @(Get-PersonalAccessTokensV1 -OwnerId 'me' -ErrorAction Stop)
        }
        catch { }
    }

    foreach ($pat in $tokens) {
        $owner = Get-ObjectPropertySafe -Object $pat -Name 'owner' -AlternateNames @('Owner')
        $id = [string](Get-ObjectPropertySafe -Object $owner -Name 'id' -AlternateNames @('Id'))
        $name = [string](Get-ObjectPropertySafe -Object $owner -Name 'name' -AlternateNames @('Name'))
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            return [pscustomobject]@{
                Id     = $id
                Name   = $name
                Source = 'personal-access-token'
            }
        }
    }

    throw 'Unable to resolve the current ISC identity as owner. Authenticate with a PAT issued to an identity, or pass -OwnerId.'
}

function Read-M365AccessProfileManifest {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Manifest not found: $Path"
    }

    $extension = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($extension -eq '.json') {
        $manifest = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        $results = @(Get-ObjectPropertySafe -Object $manifest -Name 'Results' -AlternateNames @('results'))
        if ($results.Count -eq 0) {
            throw "JSON manifest contains no Results: $Path"
        }
        $application = Get-ObjectPropertySafe -Object $manifest -Name 'Application' -AlternateNames @('application')
        return [pscustomobject]@{
            Path            = (Resolve-Path -LiteralPath $Path).Path
            Format          = 'Json'
            Environment     = [string](Get-ObjectPropertySafe -Object $manifest -Name 'Environment')
            SourceId        = [string](Get-ObjectPropertySafe -Object $manifest -Name 'SourceId')
            SourceName      = [string](Get-ObjectPropertySafe -Object $manifest -Name 'SourceName')
            Prefix          = [string](Get-ObjectPropertySafe -Object $manifest -Name 'Prefix')
            ApplicationName = [string](Get-ObjectPropertySafe -Object $application -Name 'Name')
            Results         = @($results)
        }
    }

    if ($extension -eq '.csv') {
        $results = @(Import-Csv -LiteralPath $Path)
        if ($results.Count -eq 0) {
            throw "CSV manifest contains no rows: $Path"
        }
        foreach ($row in $results) {
            if ([string]::IsNullOrWhiteSpace([string]$row.AccessProfileName) -or
                ([string]::IsNullOrWhiteSpace([string]$row.InternalName) -and
                 [string]::IsNullOrWhiteSpace([string]$row.EntitlementId))) {
                throw "CSV manifest must contain AccessProfileName and InternalName or EntitlementId columns: $Path"
            }
        }
        return [pscustomobject]@{
            Path            = (Resolve-Path -LiteralPath $Path).Path
            Format          = 'Csv'
            Environment     = $null
            SourceId        = $null
            SourceName      = $null
            Prefix          = $null
            ApplicationName = $null
            Results         = @($results)
        }
    }

    throw "Manifest must be a .json or .csv file: $Path"
}

function Write-M365AccessProfileManifest {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$OutputDirectory,
        [ValidateSet('Json', 'Csv', 'Both')]
        [string]$Format = 'Both'
    )

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $jsonPath = $null
    $csvPath = $null
    if ($Format -in @('Json', 'Both')) {
        $jsonPath = Join-Path $OutputDirectory "m365-access-profiles-$stamp.json"
        $Manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    }
    if ($Format -in @('Csv', 'Both') -and $Manifest.Results) {
        $csvPath = Join-Path $OutputDirectory "m365-access-profiles-$stamp.csv"
        $Manifest.Results | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
    }
    return [pscustomobject]@{ JsonPath = $jsonPath; CsvPath = $csvPath }
}

Export-ModuleMember -Function @(
    'Test-IsEntraIscSource'
    'Get-ServicePlanEntitlementsForSource'
    'Find-EntraSourcesWithServicePlans'
    'ConvertFrom-MicrosoftLicensingCsv'
    'Get-MicrosoftServicePlanFriendlyNameMap'
    'Get-ServicePlanLookupKeys'
    'Get-ObjectPropertySafe'
    'Expand-EntitlementList'
    'Resolve-ServicePlanFriendlyName'
    'Build-ServicePlanSelectionRows'
    'New-AccessProfileName'
    'Get-M365ReplayAccessProfileName'
    'Get-M365AccessProfileLookupNames'
    'Find-AccessProfilesByName'
    'Get-AccessProfileEntitlementIds'
    'Build-AccessProfileCreatePayload'
    'Resolve-OrCreateAccessProfileForPlan'
    'Find-SourceAppByName'
    'Resolve-OrCreateSourceApp'
    'Build-SourceAppAccessProfilePatch'
    'Add-AccessProfilesToSourceApp'
    'Find-IdentitiesByQuery'
    'ConvertFrom-JwtPayload'
    'Get-CurrentIscIdentity'
    'Read-M365AccessProfileManifest'
    'Write-M365AccessProfileManifest'
)
