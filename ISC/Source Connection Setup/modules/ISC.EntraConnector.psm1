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
    AzureServiceManagement = @{ AppId = '797f4846-ba00-4fd7-ba43-dac1f8f63013'; Name = 'Windows Azure Service Management API'; Required = $false }
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
        # Foundry agent aggregation reaches Azure Resource Manager to enumerate accounts and
        # projects, which the connector documentation gates behind this delegated scope. The Azure
        # RBAC roles it also needs (Reader, Cognitive Services Data Contributor) stay manual.
        DelegatedPermissions = @(
            @{ Value = 'user_impersonation'; Resource = 'AzureServiceManagement' }
        )
    }
    Agent365 = @{
        # The Agent 365 catalog endpoints reject application tokens, so this pack grants delegated
        # permissions and mints the refresh token ISC asks for in Machine Identity Governance Settings.
        Label                = 'Machine identity governance - Microsoft Agent 365 catalog (delegated refresh token)'
        Permissions          = @()
        DelegatedPermissions = @(
            @{ Value = 'CopilotPackages.Read.All' }
            @{ Value = 'CopilotPackages.ReadWrite.All' }
            @{ Value = 'User.Read' }
            @{ Value = 'offline_access' }
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
    param(
        [string]$RequestedTenantId,
        [string[]]$AdditionalScopes = @()
    )

    $scopes = @(
        'Application.ReadWrite.All'
        'AppRoleAssignment.ReadWrite.All'
        'Directory.Read.All'
        'RoleManagement.ReadWrite.Directory'
    ) + @($AdditionalScopes | Where-Object { $_ })
    $scopes = @($scopes | Select-Object -Unique)

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

# Delegated permissions are kept apart from the application permissions above because they are
# consented and carried differently: they only take effect inside a user token, which this script
# obtains through the authorization-code flow rather than through client credentials.
function Get-SelectedDelegatedPermissions {
    param([string[]]$FeatureNames)

    $selected = [System.Collections.Generic.List[object]]::new()
    foreach ($name in @($FeatureNames)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if (-not $script:FeaturePacks.Contains($name)) { continue }
        $pack = $script:FeaturePacks[$name]
        if (-not $pack.Contains('DelegatedPermissions')) { continue }
        foreach ($permission in $pack.DelegatedPermissions) {
            $resource = if ($permission.ContainsKey('Resource')) { $permission.Resource } else { 'Graph' }
            $selected.Add([PSCustomObject]@{
                Resource = $resource
                Value    = $permission.Value
                Pack     = $name
            })
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
        # Entra types the identities Foundry and Copilot Studio mint for agents as ServiceIdentity,
        # so the connector default silently drops every agent identity.
        $items.Add('Service Principal Account Filter: the default servicePrincipalType eq ''Application'' excludes agent identities. Use servicePrincipalType eq ''Application'' or servicePrincipalType eq ''ServiceIdentity'' to govern Foundry and Copilot Studio agents.')
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
        $items.Add('For Agent 365 catalog aggregation, add -Feature Agent365 so the delegated refresh token is issued.')
        $items.Add('For Foundry: assign Reader and Cognitive Services Data Contributor (Preview) on each Azure subscription. Without both, the Foundry dataset aggregation reaches neither ARM nor the agents data plane and returns nothing.')
        $items.Add('For Foundry: add the Azure Service Management user_impersonation delegated permission to the app registration.')
        $items.Add('Agent identities are servicePrincipalType ServiceIdentity; widen the Service Principal Account Filter or they never aggregate as accounts.')
        # Copilot Studio agents live in Dataverse, not Azure, so Entra permissions alone never reach
        # them. The connector authenticates to each Power Platform environment as an application user.
        $items.Add('For Copilot Studio: add the app registration as a Dataverse application user in every Power Platform environment that holds agents.')
        $items.Add('For Copilot Studio: give that application user the Global Discovery Service Role plus a custom BotReader role granting organization-level Read on bot and botcomponent.')
        $items.Add('For Copilot Studio: do not rely on the built-in Bot Viewer role; it reads only owned records, so an application user sees zero agents.')
    }
    if (@($FeatureNames) -contains 'Agent365') {
        $items.Add('Machine Identity Governance: enable Microsoft Agent 365 and select the catalog platforms.')
        $items.Add('Machine Identity Governance: paste the Agent 365 refresh token. Client Credentials sources fail aggregation without it.')
        $items.Add('The account that authorized the refresh token needs AI Administrator (or Global Administrator) and a Microsoft Agent 365 license.')
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

function Resolve-DelegatedScopes {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)][string[]]$PermissionValues,
        [Parameter(Mandatory)][string]$ResourceName
    )

    $scopeProperty = $ServicePrincipal.PSObject.Properties['Oauth2PermissionScopes']
    $scopes = @()
    if ($scopeProperty) { $scopes = @($scopeProperty.Value) }
    if ($scopes.Count -eq 0) {
        throw "$ResourceName exposes no delegated permissions. The signed-in account may lack Directory.Read.All."
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($value in $PermissionValues) {
        $scope = $scopes | Where-Object { $_.Value -eq $value } | Select-Object -First 1
        if (-not $scope) {
            Write-Warning "$ResourceName does not expose '$value' as a delegated permission in this tenant. Skipping."
            continue
        }
        $resolved.Add([PSCustomObject]@{ Id = $scope.Id; Value = $value })
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
        [Parameter(Mandatory)][hashtable]$RolesByResource,
        [hashtable]$ScopesByResource = @{}
    )

    $managedKeys = @(@($RolesByResource.Keys) + @($ScopesByResource.Keys) | Select-Object -Unique)
    $managedAppIds = @(foreach ($key in $managedKeys) { $script:Resources[$key].AppId })

    $required = [System.Collections.Generic.List[object]]::new()

    # Preserve entries for resources this script does not manage.
    foreach ($entry in @($Application.RequiredResourceAccess)) {
        if ($managedAppIds -contains $entry.ResourceAppId) { continue }
        $required.Add(@{
            ResourceAppId  = $entry.ResourceAppId
            ResourceAccess = @(foreach ($ra in $entry.ResourceAccess) { @{ Id = $ra.Id; Type = $ra.Type } })
        })
    }

    foreach ($key in $managedKeys) {
        $access = [System.Collections.Generic.List[object]]::new()
        foreach ($role in @($RolesByResource[$key])) {
            if ($role) { $access.Add(@{ Id = $role.Id; Type = 'Role' }) }
        }
        foreach ($scope in @($ScopesByResource[$key])) {
            if ($scope) { $access.Add(@{ Id = $scope.Id; Type = 'Scope' }) }
        }
        if ($access.Count -eq 0) { continue }
        $required.Add(@{
            ResourceAppId  = $script:Resources[$key].AppId
            ResourceAccess = $access.ToArray()
        })
    }

    Update-MgApplication -ApplicationId $Application.Id -RequiredResourceAccess $required.ToArray() -ErrorAction Stop
}

function Set-EntraRedirectUri {
    param(
        [Parameter(Mandatory)]$Application,
        [Parameter(Mandatory)][string]$RedirectUri
    )

    $existing = @()
    $web = $Application.PSObject.Properties['Web']
    if ($web -and $web.Value) {
        $uris = $web.Value.PSObject.Properties['RedirectUris']
        if ($uris) { $existing = @($uris.Value | Where-Object { $_ }) }
    }
    if ($existing -contains $RedirectUri) {
        Write-Info "Redirect URI already registered: $RedirectUri"
        return @($existing)
    }

    $updated = @($existing) + $RedirectUri
    Update-MgApplication -ApplicationId $Application.Id -Web @{ RedirectUris = $updated } -ErrorAction Stop
    Write-Ok "Registered redirect URI: $RedirectUri"
    return @($updated)
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

# Tenant-wide consent for delegated permissions is a single oauth2PermissionGrant per resource whose
# scope is one space-delimited string, so an existing grant is merged into rather than duplicated.
function Grant-DelegatedConsent {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)]$ResourceServicePrincipal,
        [Parameter(Mandatory)]$Scopes
    )

    $wanted = @(@($Scopes) | ForEach-Object { [string]$_.Value })
    if ($wanted.Count -eq 0) {
        return [PSCustomObject]@{ Granted = @(); Skipped = @(); Failed = @() }
    }

    $existing = $null
    try {
        $grants = Invoke-MgGraphRequest -Method GET -OutputType PSObject -ErrorAction Stop `
            -Uri "/v1.0/servicePrincipals/$($ServicePrincipal.Id)/oauth2PermissionGrants"
        $existing = @($grants.value) |
            Where-Object { $_.resourceId -eq $ResourceServicePrincipal.Id -and $_.consentType -eq 'AllPrincipals' } |
            Select-Object -First 1
    }
    catch {
        Write-Verbose "Could not list delegated permission grants: $($_.Exception.Message)"
    }

    $current = @()
    if ($existing) {
        $scopeProperty = $existing.PSObject.Properties['scope']
        if ($scopeProperty -and $scopeProperty.Value) {
            $current = @([string]$scopeProperty.Value -split '\s+' | Where-Object { $_ })
        }
    }

    $missing = @($wanted | Where-Object { $current -notcontains $_ })
    if ($missing.Count -eq 0) {
        Write-Info "$($wanted.Count) delegated permission(s) already consented"
        return [PSCustomObject]@{ Granted = @(); Skipped = @($wanted); Failed = @() }
    }

    $merged = (@(@($current) + $missing | Select-Object -Unique)) -join ' '

    # A newly created service principal can take a few seconds to replicate.
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if ($existing) {
                Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/oauth2PermissionGrants/$($existing.id)" `
                    -Body @{ scope = $merged } -ErrorAction Stop | Out-Null
            }
            else {
                Invoke-MgGraphRequest -Method POST -Uri '/v1.0/oauth2PermissionGrants' -ErrorAction Stop -Body @{
                    clientId    = $ServicePrincipal.Id
                    consentType = 'AllPrincipals'
                    resourceId  = $ResourceServicePrincipal.Id
                    scope       = $merged
                } | Out-Null
            }
            foreach ($value in $missing) { Write-Ok "Delegated consent granted: $value" }
            return [PSCustomObject]@{ Granted = @($missing); Skipped = @($current); Failed = @() }
        }
        catch {
            if ($attempt -lt 3) {
                Start-Sleep -Seconds (2 * $attempt)
                continue
            }
            Write-Warning "Failed to grant delegated consent: $($_.Exception.Message)"
            return [PSCustomObject]@{ Granted = @(); Skipped = @(); Failed = @($missing) }
        }
    }
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

# -----------------------------------------------------------------------------
# Agent 365 refresh token - OAuth 2.0 authorization-code flow
#
# The Microsoft Agent 365 catalog endpoints accept delegated tokens only, so a Client Credentials
# source cannot aggregate them from its own token. ISC redeems this refresh token instead, which is
# why it is pasted into Machine Identity Governance Settings rather than Connection Settings.
# https://documentation.sailpoint.com/connectors/microsoft/entra_id/help/integrating_entra_id/generating_refresh_tokens.html
# -----------------------------------------------------------------------------

$script:EntraAuthCodeTimeoutSeconds = 300
$script:Agent365Scopes = @('offline_access', 'https://graph.microsoft.com/.default')

function Get-Agent365Scopes {
    return @($script:Agent365Scopes)
}

function Get-EntraAuthorizationUrl {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$RedirectUri,
        [Parameter(Mandatory)][string[]]$Scopes,
        [Parameter(Mandatory)][string]$State
    )

    $query = @(
        "client_id=$([uri]::EscapeDataString($ClientId))"
        'response_type=code'
        "redirect_uri=$([uri]::EscapeDataString($RedirectUri))"
        'response_mode=query'
        "scope=$([uri]::EscapeDataString(($Scopes -join ' ')))"
        "state=$([uri]::EscapeDataString($State))"
        'prompt=select_account'
    ) -join '&'

    return "https://login.microsoftonline.com/$([uri]::EscapeDataString($TenantId))/oauth2/v2.0/authorize?$query"
}

# Blocks on the loopback redirect until Entra sends the code back, so the operator never has to copy
# anything out of the address bar.
function Wait-EntraAuthorizationCode {
    param(
        [Parameter(Mandatory)][string]$RedirectUri,
        [Parameter(Mandatory)][string]$State
    )

    $prefix = $RedirectUri.TrimEnd('/') + '/'
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($prefix)
    try {
        $listener.Start()
    }
    catch {
        throw "Could not listen on $prefix. Choose a free port with -Agent365RedirectUri. $($_.Exception.Message)"
    }

    try {
        Write-Info "Waiting for the Entra redirect on $prefix (Ctrl+C to cancel) ..."
        # A blocked sign-in never redirects here, so the wait is bounded rather than hanging until
        # Ctrl+C. Polling also keeps Ctrl+C responsive.
        $pending = $listener.GetContextAsync()
        $deadline = (Get-Date).AddSeconds($script:EntraAuthCodeTimeoutSeconds)
        while (-not $pending.Wait(500)) {
            if ((Get-Date) -gt $deadline) {
                throw ("No redirect arrived on $prefix within $([int]($script:EntraAuthCodeTimeoutSeconds / 60)) minutes. " +
                    'Confirm the redirect URI is registered on the app registration and that the sign-in was not blocked by Conditional Access.')
            }
        }

        $context = $pending.Result
        $code = $context.Request.QueryString['code']
        $failure = $context.Request.QueryString['error']
        $description = $context.Request.QueryString['error_description']
        $returnedState = $context.Request.QueryString['state']

        $body = if ($code) {
            '<html><body style="font-family:sans-serif"><h3>Authorization complete</h3><p>Return to the PowerShell window.</p></body></html>'
        }
        else {
            "<html><body style='font-family:sans-serif'><h3>Authorization failed</h3><p>$failure</p></body></html>"
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $context.Response.ContentType = 'text/html'
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.OutputStream.Close()

        if (-not $code) {
            $detail = if ($description) { "$failure - $description" } else { $failure }
            throw "Entra returned an error instead of an authorization code: $detail"
        }
        if ($returnedState -ne $State) {
            throw 'The redirect carried a different state value than the request. Discarding the authorization code.'
        }
        return $code
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

function Invoke-EntraTokenExchange {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [Parameter(Mandatory)][string]$RedirectUri,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string[]]$Scopes,
        [int]$RetryDelaySeconds = 5
    )

    $uri = "https://login.microsoftonline.com/$([uri]::EscapeDataString($TenantId))/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        code          = $Code
        redirect_uri  = $RedirectUri
        grant_type    = 'authorization_code'
        scope         = ($Scopes -join ' ')
    }

    # AADSTS7000215 here means the secret has not replicated to this token endpoint yet. Entra
    # rejects the client before it reads the code, so the code survives and a retry is safe.
    for ($attempt = 1; ; $attempt++) {
        try {
            return Invoke-RestMethod -Method Post -Uri $uri -ErrorAction Stop -Body $body
        }
        catch {
            $detail = $_.ErrorDetails
            $failure = if ($detail) { [string]$detail.Message } else { [string]$_.Exception.Message }
            if ($attempt -ge 3 -or $failure -notmatch 'AADSTS7000215') {
                throw "Entra rejected the token exchange: $failure"
            }
            Write-Info 'The client secret is not active yet; retrying the token exchange ...'
            if ($RetryDelaySeconds -gt 0) { Start-Sleep -Seconds $RetryDelaySeconds }
        }
    }
}

# A client-credentials request is the cheapest way to prove a freshly created secret is usable.
# Doing it before the browser hand-off keeps the authorization code, which Entra expires in
# minutes, out of the replication race.
function Wait-EntraClientSecretReady {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [int]$TimeoutSeconds = 120,
        [int]$DelaySeconds = 5
    )

    $uri = "https://login.microsoftonline.com/$([uri]::EscapeDataString($TenantId))/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        grant_type    = 'client_credentials'
        scope         = 'https://graph.microsoft.com/.default'
    }
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $waited = $false
    while ($true) {
        try {
            $null = Invoke-RestMethod -Method Post -Uri $uri -ErrorAction Stop -Body $body
            if ($waited) { Write-Ok 'Client secret is active' }
            return $true
        }
        catch {
            $detail = $_.ErrorDetails
            $failure = if ($detail) { [string]$detail.Message } else { [string]$_.Exception.Message }
            # Any other failure is the authorization code exchange's problem to report in context.
            if ($failure -notmatch 'AADSTS7000215') { return $true }
            if ((Get-Date) -ge $deadline) { return $false }
            if (-not $waited) {
                Write-Info 'Waiting for Entra to activate the new client secret ...'
                $waited = $true
            }
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Get-EntraAgent365RefreshToken {
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret,
        [Parameter(Mandatory)][string]$RedirectUri
    )

    if (-not (Wait-EntraClientSecretReady -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret)) {
        throw 'Entra has not activated the client secret yet (AADSTS7000215). Re-run the script to retry; a new secret is usually usable within a minute.'
    }

    $scopes = Get-Agent365Scopes
    $state = [guid]::NewGuid().ToString('N')
    $authUrl = Get-EntraAuthorizationUrl -TenantId $TenantId -ClientId $ClientId -RedirectUri $RedirectUri `
        -Scopes $scopes -State $state

    Write-Host ''
    Write-Host 'Authorize the application at:' -ForegroundColor White
    Write-Host $authUrl -ForegroundColor Yellow
    Write-Host ''
    if (-not (Open-Url -Url $authUrl)) {
        Write-Info 'Could not open a browser automatically; copy the URL above.'
    }
    Write-Info 'Sign in as a user with AI Administrator (or Global Administrator) and a Microsoft Agent 365 license.'

    $code = Wait-EntraAuthorizationCode -RedirectUri $RedirectUri -State $state
    $response = Invoke-EntraTokenExchange -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret `
        -RedirectUri $RedirectUri -Code $code -Scopes $scopes

    $refreshProperty = $response.PSObject.Properties['refresh_token']
    if (-not $refreshProperty -or [string]::IsNullOrWhiteSpace([string]$refreshProperty.Value)) {
        throw 'Entra returned an access token without a refresh token. Confirm offline_access is consented on the application.'
    }
    return [string]$refreshProperty.Value
}

function Get-EntraConnectorCatalog {
    $packs = [ordered]@{}
    foreach ($key in $script:FeaturePacks.Keys) {
        $packs[$key] = $script:FeaturePacks[$key]
    }
    if (Get-Command Get-EmbeddedCiemFeaturePack -ErrorAction SilentlyContinue) {
        $packs['Ciem'] = Get-EmbeddedCiemFeaturePack
    }
    $sorted = [ordered]@{}
    foreach ($key in @($packs.Keys | Sort-Object { [string]$packs[$_].Label })) {
        $sorted[$key] = $packs[$key]
    }
    return [PSCustomObject]@{
        Resources        = $script:Resources
        CorePermissions  = $script:CorePermissions
        FeaturePacks     = $sorted
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
    'Get-SelectedDelegatedPermissions'
    'Get-EntraIscFeatureChecklist'
    'Get-ServicePrincipalByAppId'
    'Get-ApiServicePrincipal'
    'Resolve-AppRoles'
    'Resolve-DelegatedScopes'
    'Find-EntraApplicationByName'
    'New-EntraConnectorApplication'
    'Get-EntraConnectorApplication'
    'Set-RequiredResourceAccess'
    'Set-EntraRedirectUri'
    'Grant-AppRoleConsent'
    'Grant-DelegatedConsent'
    'Get-ServicePrincipalRoleMembership'
    'Add-EntraDirectoryRoles'
    'New-EntraClientSecret'
    'Get-Agent365Scopes'
    'Get-EntraAuthorizationUrl'
    'Wait-EntraAuthorizationCode'
    'Invoke-EntraTokenExchange'
    'Wait-EntraClientSecretReady'
    'Get-EntraAgent365RefreshToken'
)
