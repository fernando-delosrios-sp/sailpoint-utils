#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:CreatedAppId = $null
$script:ServicePrincipalLookupErrors = @()

function Initialize-EntraConnectorData {
# API resources the connector can be granted permissions on.
$script:Resources = [ordered]@{
    # Microsoft Graph's well-known appId uses c000, not 0000, in the third group.
    Graph    = @{ AppId = '00000003-0000-0000-c000-000000000000'; Name = 'Microsoft Graph'; Required = $true }
    Defender = @{ AppId = 'fc780465-2017-40d4-a0c5-307022471b92'; Name = 'WindowsDefenderATP'; Required = $false }
    Exchange = @{ AppId = '00000002-0000-0ff1-ce00-000000000000'; Name = 'Office 365 Exchange Online'; Required = $false }
}

# -----------------------------------------------------------------------------
# Permissions - SailPoint Microsoft Entra ID connector required-permissions table
# https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/administrator_permission.html
#
# User.Read and Directory.AccessAsUser.All appear in the table as delegated permissions for
# SAML bearer / auth-code / JWT grant types. This script configures client-credentials
# (client secret) auth, so they are intentionally not requested.
# -----------------------------------------------------------------------------

$script:CorePermissions = @(
    @{ Value = 'User.Invite.All';                   Purpose = 'Create / invite B2B user' }
    @{ Value = 'User.Read.All';                     Purpose = 'Account aggregation, delta, role and group membership' }
    @{ Value = 'User.ReadWrite.All';                Purpose = 'Create / update / enable / disable / delete user, licenses' }
    @{ Value = 'User.EnableDisableAccount.All';     Purpose = 'Delete user' }
    @{ Value = 'User-PasswordProfile.ReadWrite.All'; Purpose = 'Set password' }
    @{ Value = 'Organization.Read.All';             Purpose = 'Aggregate tenant license packs and plans' }
    @{ Value = 'Group.Read.All';                    Purpose = 'Group aggregation' }
    @{ Value = 'Group.ReadWrite.All';               Purpose = 'Create / update / delete group' }
    @{ Value = 'RoleManagement.Read.Directory';     Purpose = 'Directory role aggregation' }
    @{ Value = 'RoleManagement.ReadWrite.Directory'; Purpose = 'Add / remove directory roles' }
    @{ Value = 'Application.Read.All';              Purpose = 'Application role aggregation' }
    @{ Value = 'AppRoleAssignment.ReadWrite.All';   Purpose = 'Add / remove users from service principal' }
    @{ Value = 'DelegatedPermissionGrant.Read.All'; Purpose = 'Aggregate admin / user consented permissions' }
)

# Documented coarse alternative to the granular table.
$script:DirectoryPermissions = @(
    @{ Value = 'Directory.Read.All';      Purpose = 'Read directory data' }
    @{ Value = 'Directory.ReadWrite.All'; Purpose = 'Read and write directory data (excludes deleting users and groups)' }
)

$script:FeaturePacks = [ordered]@{
    AccessPackages = @{
        Label       = 'Access packages (entitlement management)'
        Permissions = @(
            @{ Value = 'EntitlementManagement.Read.All' }
            @{ Value = 'EntitlementManagement.ReadWrite.All' }
        )
    }
    MfaManagement = @{
        Label       = 'MFA / authentication method management'
        Permissions = @(
            @{ Value = 'UserAuthenticationMethod.Read.All' }
            @{ Value = 'UserAuthenticationMethod.ReadWrite.All' }
        )
    }
    ActivityInsights = @{
        Label       = 'Activity Insights (audit and sign-in logs)'
        Permissions = @(
            @{ Value = 'AuditLog.Read.All' }
        )
    }
    AdministrativeUnits = @{
        Label       = 'Administrative unit management'
        Permissions = @(
            @{ Value = 'AdministrativeUnit.Read.All' }
            @{ Value = 'AdministrativeUnit.ReadWrite.All' }
        )
    }
    ServicePrincipalProvisioning = @{
        Label       = 'Service principal account provisioning'
        Permissions = @(
            @{ Value = 'Application.ReadWrite.All' }
            @{ Value = 'Application.ReadWrite.OwnedBy' }
            @{ Value = 'DelegatedPermissionGrant.ReadWrite.All' }
        )
    }
    ExchangeOnline = @{
        Label       = 'Exchange Online mailbox management (also assign Exchange Administrator role + IQService cert)'
        Permissions = @(
            @{ Value = 'Exchange.ManageAsApp'; Resource = 'Exchange' }
        )
    }
    NhiDiscovery = @{
        Label       = 'NHI discovery - Azure cloud and NHI analysis'
        Permissions = @(
            @{ Value = 'Device.Read.All' }
        )
    }
    TeamsSecretScanning = @{
        Label       = 'NHI discovery - Microsoft Teams secret scanning'
        Permissions = @(
            @{ Value = 'Channel.ReadBasic.All' }
            @{ Value = 'ChannelMember.Read.All' }
            @{ Value = 'ChannelMessage.Read.All' }
            @{ Value = 'ChannelSettings.Read.All' }
            @{ Value = 'Chat.Read.All' }
            @{ Value = 'TeamsActivity.Read.All' }
            @{ Value = 'TeamsAppInstallation.ReadForChat.All' }
            @{ Value = 'TeamsAppInstallation.ReadForTeam.All' }
            @{ Value = 'TeamsAppInstallation.ReadForUser.All' }
            @{ Value = 'TeamsTab.Read.All' }
            @{ Value = 'TeamSettings.Read.All' }
        )
    }
    TeamsMessaging = @{
        Label       = 'NHI discovery - Microsoft Teams risk notifications'
        Permissions = @(
            @{ Value = 'TeamsAppInstallation.ReadWriteForTeam.All' }
            @{ Value = 'TeamsAppInstallation.ReadWriteForUser.All' }
            @{ Value = 'TeamsAppInstallation.ReadWriteSelfForUser.All' }
        )
    }
    SharePointScanning = @{
        Label       = 'NHI discovery - SharePoint and OneDrive secret scanning'
        Permissions = @(
            @{ Value = 'Files.Read.All' }
            @{ Value = 'Sites.Read.All' }
        )
    }
    CopilotDiscovery = @{
        Label       = 'Machine identity governance - Copilot Studio and Foundry agents'
        Permissions = @(
            @{ Value = 'AiEnterpriseInteraction.Read.All' }
            @{ Value = 'Reports.Read.All' }
            @{ Value = 'ExternalConnection.Read.All' }
            @{ Value = 'AppCatalog.Read.All' }
        )
    }
    DefenderHunting = @{
        Label       = 'NHI discovery - Microsoft Defender (WindowsDefenderATP API)'
        Permissions = @(
            # Advanced hunting is exposed as ThreatHunting.Read.All on Microsoft Graph; the legacy
            # WindowsDefenderATP resource names it AdvancedQuery.Read.All.
            @{ Value = 'Machine.Read.All';        Resource = 'Defender' }
            @{ Value = 'AdvancedQuery.Read.All';  Resource = 'Defender' }
            @{ Value = 'ThreatHunting.Read.All'; Resource = 'Graph' }
        )
    }
}

$script:DirectoryRoleMap = [ordered]@{
    None                = @()
    UserAdministrator   = @('User Administrator')
    PrivilegedAdmin     = @('User Administrator', 'Privileged Authentication Administrator')
    GlobalAdministrator = @('Global Administrator')
}
}

function Connect-EntraGraph {
    param([string]$RequestedTenantId)

    $scopes = @(
        'Application.ReadWrite.All'
        'AppRoleAssignment.ReadWrite.All'
        'Directory.Read.All'
        'RoleManagement.ReadWrite.Directory'
    )

    $context = Get-MgContext -ErrorAction SilentlyContinue
    $needsConnect = $true
    if ($context) {
        $missingScopes = @($scopes | Where-Object { $context.Scopes -notcontains $_ })
        $tenantMismatch = $RequestedTenantId -and $context.TenantId -and
            ($RequestedTenantId -ne $context.TenantId) -and ($context.Account -notlike "*$RequestedTenantId")
        if ($missingScopes.Count -eq 0 -and -not $tenantMismatch) {
            $needsConnect = -not (Read-YesNo -Prompt "Already connected as $($context.Account). Reuse this session?" -Default $true)
        }
    }

    if ($needsConnect) {
        Write-Step 'Sign in to Microsoft Graph'
        $connectParams = @{ Scopes = $scopes }
        if ($RequestedTenantId) { $connectParams.TenantId = $RequestedTenantId }
        try {
            Connect-MgGraph @connectParams -NoWelcome -ErrorAction Stop
        }
        catch [System.Management.Automation.ParameterBindingException] {
            Connect-MgGraph @connectParams -ErrorAction Stop
        }
        $context = Get-MgContext
    }

    if (-not $context) { throw 'Microsoft Graph authentication failed.' }

    $orgName = $null
    $domainName = $null
    try {
        $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
        if ($org) {
            $orgName = $org.DisplayName
            $domains = @($org.VerifiedDomains)
            $initial = $domains | Where-Object { $_.IsInitial } | Select-Object -First 1
            $default = $domains | Where-Object { $_.IsDefault } | Select-Object -First 1
            if ($initial) { $domainName = $initial.Name }
            elseif ($default) { $domainName = $default.Name }
            elseif ($domains.Count -gt 0) { $domainName = $domains[0].Name }
        }
    }
    catch {
        Write-Warning "Could not read organization details: $($_.Exception.Message)"
    }

    $tenantLabel = if ($orgName) { "$orgName ($($context.TenantId))" } else { $context.TenantId }
    Write-Ok "Connected as $($context.Account)"
    Write-Ok "Tenant: $tenantLabel"

    return [PSCustomObject]@{
        TenantId   = $context.TenantId
        Account    = $context.Account
        OrgName    = $orgName
        DomainName = $domainName
    }
}

# -----------------------------------------------------------------------------
# Permission resolution
# -----------------------------------------------------------------------------

function Get-SelectedPermissions {
    param(
        [string]$Mode,
        [string[]]$FeatureNames
    )

    $selected = [System.Collections.Generic.List[object]]::new()
    $base = if ($Mode -eq 'Directory') { $script:DirectoryPermissions } else { $script:CorePermissions }
    foreach ($permission in $base) {
        $selected.Add([PSCustomObject]@{
            Resource = 'Graph'
            Value    = $permission.Value
            Pack     = 'Core'
        })
    }

    foreach ($name in @($FeatureNames)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if ($name -eq 'Ciem') { continue }
        if (-not $script:FeaturePacks.Contains($name)) { continue }
        foreach ($permission in $script:FeaturePacks[$name].Permissions) {
            $resource = if ($permission.ContainsKey('Resource')) { $permission.Resource } else { 'Graph' }
            $selected.Add([PSCustomObject]@{
                Resource = $resource
                Value    = $permission.Value
                Pack     = $name
            })
        }
    }

    if (Get-Command Merge-EntraCiemPermissions -ErrorAction SilentlyContinue) {
        foreach ($item in @(Merge-EntraCiemPermissions -FeatureNames $FeatureNames)) {
            $selected.Add($item)
        }
    }

    return @($selected | Sort-Object Resource, Value -Unique)
}

function Get-EntraIscFeatureChecklist {
    param([string[]]$FeatureNames)

    $items = [System.Collections.Generic.List[string]]::new()
    $items.Add('Connection Settings: enable Use Continuous Access Evaluation if your tenant uses CAE.')
    $items.Add('Feature Management: enable Manage Microsoft 365 Groups when governing Teams.')

    if (@($FeatureNames) -contains 'ActivityInsights') {
        $items.Add('Enable Activity Insights on the source (requires Entra ID P1 or P2).')
    }
    if (@($FeatureNames) -contains 'AccessPackages') {
        $items.Add('Feature Management: enable Manage Access Packages.')
    }
    if (@($FeatureNames) -contains 'AdministrativeUnits') {
        $items.Add('Feature Management: enable Manage Administrative Units.')
    }
    if (@($FeatureNames) -contains 'ServicePrincipalProvisioning') {
        $items.Add('Feature Management: enable Manage Microsoft Entra Service Principals as Accounts.')
        $items.Add('Service Principal Account Filter: servicePrincipalType eq ''Application'' (default).')
    }
    if (@($FeatureNames) -contains 'ExchangeOnline') {
        $items.Add('Feature Management: enable Manage Exchange Online (requires IQService + certificate on the app).')
        $items.Add('Assign Exchange Administrator directory role to the app registration.')
    }
    if (Test-EmbeddedCiemSelected -FeatureNames $FeatureNames) {
        $items.Add('Feature Management: enable Privileged Identity Management for Entra PIM group eligibility (CIEM).')
    }
    elseif (@($FeatureNames) -contains 'ServicePrincipalProvisioning') {
        $items.Add('If governing PIM role memberships on service principals, enable Privileged Identity Management in ISC.')
    }
    if (@($FeatureNames) -contains 'CopilotDiscovery') {
        $items.Add('Machine Identity Governance: enable Azure AI Foundry Agents and/or Microsoft Copilot Studio Agents.')
        $items.Add('For Agent 365: paste a refresh token in Machine Identity Governance (delegated OAuth; see SailPoint docs).')
        $items.Add('For Foundry: assign Reader and Cognitive Services Data Contributor on each Azure subscription.')
    }
    $nhiPacks = @('NhiDiscovery', 'TeamsSecretScanning', 'SharePointScanning', 'DefenderHunting')
    if (@($FeatureNames | Where-Object { $nhiPacks -contains $_ }).Count -gt 0) {
        $items.Add('NHI Discovery features require SailPoint Agentic Fabric license on the tenant.')
    }
    $items.Add('Managed identities: assign Managed Identity Operator (or Reader) at Tenant Root for user-assigned identities.')
    $items.Add('Azure PIM for Azure resource roles: assign Owner or User Access Administrator on subscriptions (CIEM license).')

    return @($items)
}

# Why each lookup failed, so a failure to find a service principal can explain itself.
$script:ServicePrincipalLookupErrors = [System.Collections.Generic.List[string]]::new()

function Get-ServicePrincipalByAppId {
    param([Parameter(Mandatory)][string]$AppId)

    # The alternate-key REST call is tried first because Get-MgServicePrincipal -Filter returns an
    # empty result on some SDK versions even when the service principal exists.
    try {
        $sp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals(appId='$AppId')" -OutputType PSObject -ErrorAction Stop
        if ($sp) { return $sp }
        $script:ServicePrincipalLookupErrors.Add("servicePrincipals(appId='$AppId') returned nothing")
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("servicePrincipals(appId='$AppId'): $($_.Exception.Message)")
    }

    try {
        $sp = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop | Select-Object -First 1
        if ($sp) { return $sp }
        $script:ServicePrincipalLookupErrors.Add("Get-MgServicePrincipal -Filter returned nothing")
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("Get-MgServicePrincipal -Filter: $($_.Exception.Message)")
    }

    return $null
}

function Get-ApiServicePrincipal {
    param(
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$Name
    )

    $script:ServicePrincipalLookupErrors.Clear()

    # Retried because throttling and transient 5xx responses are the usual reason a service
    # principal that certainly exists comes back empty.
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $sp = Get-ServicePrincipalByAppId -AppId $AppId
        if ($sp) { return $sp }
        if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
    }

    # Last resort for tenants where filtering on appId is unreliable. Only identifiers are listed:
    # selecting appRoles across every service principal is the query most likely to time out, so
    # the roles are fetched afterwards from the one match.
    Write-Info "Searching the tenant service principal list for $Name ..."
    try {
        $match = Get-MgServicePrincipal -All -Property 'id,appId,displayName' -ErrorAction Stop |
            Where-Object { $_.AppId -eq $AppId } | Select-Object -First 1
        if ($match) { return Get-MgServicePrincipal -ServicePrincipalId $match.Id -ErrorAction Stop }
        $script:ServicePrincipalLookupErrors.Add('the tenant service principal list contains no such appId')
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("service principal enumeration: $($_.Exception.Message)")
    }

    return $null
}

function Resolve-AppRoles {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)][string[]]$PermissionValues,
        [Parameter(Mandatory)][string]$ResourceName
    )

    # REST responses expose 'appRoles', SDK objects expose 'AppRoles'; member lookup is case-insensitive.
    $appRolesProperty = $ServicePrincipal.PSObject.Properties['AppRoles']
    $appRoles = @()
    if ($appRolesProperty) { $appRoles = @($appRolesProperty.Value) }
    if ($appRoles.Count -eq 0) {
        throw "$ResourceName exposes no application roles. The signed-in account may lack Directory.Read.All."
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($value in $PermissionValues) {
        $role = $appRoles |
            Where-Object { $_.Value -eq $value -and $_.AllowedMemberTypes -contains 'Application' } |
            Select-Object -First 1
        if (-not $role) {
            Write-Warning "$ResourceName does not expose '$value' as an application permission in this tenant. Skipping."
            continue
        }
        $resolved.Add([PSCustomObject]@{ Id = $role.Id; Value = $value })
    }
    return @($resolved)
}

# -----------------------------------------------------------------------------
# Application operations
# -----------------------------------------------------------------------------

function Find-EntraApplicationByName {
    param([Parameter(Mandatory)][string]$DisplayName)

    $escaped = $DisplayName.Replace("'", "''")
    return @(Get-MgApplication -Filter "displayName eq '$escaped'" -All -ErrorAction Stop)
}

function New-EntraConnectorApplication {
    param(
        [Parameter(Mandatory)][string]$DisplayName
    )

    $body = @{
        DisplayName    = $DisplayName
        SignInAudience = 'AzureADMyOrg'
        Description    = 'SailPoint Identity Security Cloud - Microsoft Entra ID connector'
    }

    $app = New-MgApplication -BodyParameter $body -ErrorAction Stop
    $script:CreatedAppId = $app.AppId

    # The new application can take a few seconds to replicate before a service principal can reference it.
    $sp = $null
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            $sp = New-MgServicePrincipal -AppId $app.AppId -ErrorAction Stop
            break
        }
        catch {
            if ($attempt -eq 4) { throw }
            Start-Sleep -Seconds (2 * $attempt)
        }
    }

    return [PSCustomObject]@{ Application = $app; ServicePrincipal = $sp }
}

function Get-EntraConnectorApplication {
    param([Parameter(Mandatory)][string]$ApplicationObjectId)

    $app = Get-MgApplication -ApplicationId $ApplicationObjectId -ErrorAction Stop
    $sp = Get-ServicePrincipalByAppId -AppId $app.AppId
    if (-not $sp) {
        Write-Warning 'The application has no service principal. Creating one.'
        $sp = New-MgServicePrincipal -AppId $app.AppId -ErrorAction Stop
    }
    return [PSCustomObject]@{ Application = $app; ServicePrincipal = $sp }
}

function Set-RequiredResourceAccess {
    param(
        [Parameter(Mandatory)]$Application,
        [Parameter(Mandatory)][hashtable]$RolesByResource
    )

    $managedAppIds = @(
        foreach ($key in $RolesByResource.Keys) { $script:Resources[$key].AppId }
    )

    $required = [System.Collections.Generic.List[object]]::new()

    # Preserve entries for resources this script does not manage.
    foreach ($entry in @($Application.RequiredResourceAccess)) {
        if ($managedAppIds -contains $entry.ResourceAppId) { continue }
        $required.Add(@{
            ResourceAppId  = $entry.ResourceAppId
            ResourceAccess = @(foreach ($ra in $entry.ResourceAccess) { @{ Id = $ra.Id; Type = $ra.Type } })
        })
    }

    foreach ($key in $RolesByResource.Keys) {
        $roles = $RolesByResource[$key]
        if (-not $roles -or $roles.Count -eq 0) { continue }
        $required.Add(@{
            ResourceAppId  = $script:Resources[$key].AppId
            ResourceAccess = @(foreach ($role in $roles) { @{ Id = $role.Id; Type = 'Role' } })
        })
    }

    Update-MgApplication -ApplicationId $Application.Id -RequiredResourceAccess $required.ToArray() -ErrorAction Stop
}

function Grant-AppRoleConsent {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)]$ResourceServicePrincipal,
        [Parameter(Mandatory)]$AppRoles
    )

    $existing = @()
    try {
        $existing = @(Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -All -ErrorAction Stop)
    }
    catch {
        Write-Warning "Could not list existing app role assignments: $($_.Exception.Message)"
    }

    $granted = 0
    $skipped = 0
    $failed = [System.Collections.Generic.List[string]]::new()

    foreach ($role in $AppRoles) {
        $already = $existing | Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $ResourceServicePrincipal.Id }
        if ($already) {
            $skipped++
            continue
        }

        $body = @{
            PrincipalId = $ServicePrincipal.Id
            ResourceId  = $ResourceServicePrincipal.Id
            AppRoleId   = $role.Id
        }

        # A newly created service principal can take a few seconds to replicate.
        $attempt = 0
        while ($true) {
            $attempt++
            try {
                New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -BodyParameter $body -ErrorAction Stop | Out-Null
                Write-Ok "Consent granted: $($role.Value)"
                $granted++
                break
            }
            catch {
                if ($_.Exception.Message -match 'already exists|Permission being assigned already exists') {
                    $skipped++
                    break
                }
                if ($attempt -lt 3) {
                    Start-Sleep -Seconds (2 * $attempt)
                    continue
                }
                Write-Warning "Failed to grant $($role.Value): $($_.Exception.Message)"
                $failed.Add($role.Value)
                break
            }
        }
        Start-Sleep -Milliseconds 300
    }

    if ($skipped -gt 0) { Write-Info "$skipped permission(s) already consented" }
    return [PSCustomObject]@{ Granted = $granted; Skipped = $skipped; Failed = @($failed) }
}

# Role membership reads from the service principal side in one call. Returns $null when the
# membership cannot be read, so callers fall back to inspecting each role's member list.
function Get-ServicePrincipalRoleMembership {
    param([Parameter(Mandatory)]$ServicePrincipal)

    $roleIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        $objects = @(Get-MgServicePrincipalMemberOf -ServicePrincipalId $ServicePrincipal.Id -All -ErrorAction Stop)
    }
    catch {
        Write-Verbose "Could not read role membership of the service principal: $($_.Exception.Message)"
        return $null
    }

    foreach ($object in $objects) {
        if ($object.Id) { [void]$roleIds.Add([string]$object.Id) }
    }
    return $roleIds
}

function Add-EntraDirectoryRoles {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [string[]]$RoleDisplayNames
    )

    # directoryRoles rejects $filter on displayName in some tenants, so the activated roles are
    # listed once and matched locally.
    $activatedRoles = @()
    try { $activatedRoles = @(Get-MgDirectoryRole -All -ErrorAction Stop) }
    catch { Write-Verbose "Could not list activated directory roles: $($_.Exception.Message)" }

    $memberOfRoleIds = Get-ServicePrincipalRoleMembership -ServicePrincipal $ServicePrincipal

    $assigned = [System.Collections.Generic.List[string]]::new()
    foreach ($displayName in @($RoleDisplayNames)) {
        $role = $activatedRoles | Where-Object { $_.DisplayName -eq $displayName } | Select-Object -First 1

        if (-not $role) {
            $template = Get-MgDirectoryRoleTemplate -All -ErrorAction Stop |
                Where-Object { $_.DisplayName -eq $displayName } | Select-Object -First 1
            if (-not $template) {
                Write-Warning "Directory role template not found: $displayName"
                continue
            }
            $role = New-MgDirectoryRole -RoleTemplateId $template.Id -ErrorAction Stop
            Write-Info "Activated directory role: $displayName"
        }

        $isMember = $false
        if ($null -ne $memberOfRoleIds) {
            $isMember = $memberOfRoleIds.Contains([string]$role.Id)
        }
        else {
            try {
                $members = @(Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All -ErrorAction Stop)
                $isMember = [bool]($members | Where-Object { $_.Id -eq $ServicePrincipal.Id })
            }
            catch {
                Write-Verbose "Could not enumerate members of ${displayName}: $($_.Exception.Message)"
            }
        }

        if ($isMember) {
            Write-Info "Already assigned: $displayName"
            $assigned.Add($displayName)
            continue
        }

        try {
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter @{
                '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($ServicePrincipal.Id)"
            } -ErrorAction Stop
            Write-Ok "Assigned directory role: $displayName"
            $assigned.Add($displayName)
        }
        catch {
            # Graph reports an existing membership as a bad request on the role's members collection.
            if ($_.Exception.Message -match 'already exist') {
                Write-Info "Already assigned: $displayName"
                $assigned.Add($displayName)
                continue
            }
            Write-Warning "Failed to assign ${displayName}: $($_.Exception.Message)"
        }
    }
    return @($assigned)
}

function New-EntraClientSecret {
    param(
        [Parameter(Mandatory)]$Application,
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][int]$ValidityMonths
    )

    $result = Add-MgApplicationPassword -ApplicationId $Application.Id -PasswordCredential @{
        DisplayName = $DisplayName
        EndDateTime = (Get-Date).ToUniversalTime().AddMonths($ValidityMonths)
    } -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($result.SecretText)) {
        throw 'The client secret was created but its value was not returned. Create one in the Entra portal instead.'
    }
    return $result
}

function Get-EntraConnectorCatalog {
    $packs = [ordered]@{}
    foreach ($key in $script:FeaturePacks.Keys) {
        $packs[$key] = $script:FeaturePacks[$key]
    }
    if (Get-Command Get-EmbeddedCiemFeaturePack -ErrorAction SilentlyContinue) {
        $packs['Ciem'] = Get-EmbeddedCiemFeaturePack
    }
    return [PSCustomObject]@{
        Resources        = $script:Resources
        CorePermissions  = $script:CorePermissions
        FeaturePacks     = $packs
        DirectoryRoleMap = $script:DirectoryRoleMap
    }
}

function Get-EntraCreatedAppId {
    return $script:CreatedAppId
}

function Get-EntraServicePrincipalLookupErrors {
    return @($script:ServicePrincipalLookupErrors)
}

Export-ModuleMember -Function @(
    'Initialize-EntraConnectorData'
    'Get-EntraConnectorCatalog'
    'Get-EntraCreatedAppId'
    'Get-EntraServicePrincipalLookupErrors'
    'Connect-EntraGraph'
    'Get-SelectedPermissions'
    'Get-EntraIscFeatureChecklist'
    'Get-ServicePrincipalByAppId'
    'Get-ApiServicePrincipal'
    'Resolve-AppRoles'
    'Find-EntraApplicationByName'
    'New-EntraConnectorApplication'
    'Get-EntraConnectorApplication'
    'Set-RequiredResourceAccess'
    'Grant-AppRoleConsent'
    'Get-ServicePrincipalRoleMembership'
    'Add-EntraDirectoryRoles'
    'New-EntraClientSecret'
)
