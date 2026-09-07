&{
# Configuration settings and variables
[string[]]$script:subscriptionsExactList = @() #List of Subcription IDs to include in any operations, no others will be used. {example: @("fa6448db-ey49-4118-8231-13aac72c3f89", etc.)}. Can also be set via the {hidden} menu option "setsubsexactlist"
[string[]]$script:subscriptionsToExclude = @() #List of Subcriptions IDs to exclude from any operations {example: @("fa6448db-ey49-4118-8231-13aac72c3f89", etc.)}. Can also be set via the {hidden} menu option "setsubstoexclude"
[string]$script:TenantId = "" #Optional: Specify a Tenant ID to connect to a specific Azure AD tenant
[string]$script:entroAppRegName = "EntroSecurityApp"
[string]$script:entroRoleName = "EntroSecurityRole"
[string]$script:entroLogAnalyticsWorkspaceName = "EntroSecurityLogAnalytics"
[string]$script:entroResourceGroupName = "EntroSecurityRG"
[string]$script:entroResourceGroupLocation = "eastus"
$script:curTenant = $null
$script:entroAppRegistration = $null
$script:entroServicePrincipal = $null
$script:entroLogWkspc = $null


# Script execution settings *** DO NOT MODIFY ***
$ErrorActionPreference = "Stop"
#Requires -Version 7.0

#####################################
########   Menu Functions ###########
#####################################

function Show-EntroLogo {
    $logo = @(
        "                                      @@@@                                      ",
        "   @@@@@@@@@@@     @@@& @@@@@@@@@     ,,,,,,,,   @@@@ @@@@@@@@    @@@@@@@@@@@@  ",
        " @@@@       @@@@   @@@&@     @@@@@    ,,,,,,,,   @@@@@    @@@@@  @@@@@  ** @@@@@",
        "#@@@@@@@@@@@@@@@   @@@@       @@@@(   @@@@       @@@@           @@@@  *****  @@@",
        " @@@@                         @@@@(   @@@@       @@@@           @@@@@  **   @@@@",
        "  @@@@@@@@@@@@@@   ////       @@@@(   @@@@@@@@@  @@@@            @@@@@@@@@@@@@@ ",
        "     @@@@@@@@      ////       @@@@(      @@@@@@  @@@@               @@@@@@@@    "
    )

    foreach ($line in $logo) {
        foreach ($char in $line.ToCharArray()) {
            switch ($char) {
                '@' { Write-ColoredText $char 'Gray' }
                ',' { Write-ColoredText $char 'Magenta' }
                '*' { Write-ColoredText $char 'Green' }
                '/' { Write-ColoredText $char 'DarkBlue' }
                ' ' { Write-ColoredText $char 'White' }
                default { Write-ColoredText $char 'White' }
            }
        }
        Write-Host ""  # Move to the next line
    }
    Write-Host ""
}

function Show-Menu {
    Clear-Host
    Show-EntroLogo  # Display Entro logo
    # Display current service principal if one is selected
    
    if ($script:curTenant) {
        Write-Host "Current Tenant: " -NoNewLine
        Write-Host "$($script:curTenant.DisplayName) ($($script:curTenant.Id))" -ForegroundColor DarkBlue
    }

    if ($script:entroServicePrincipal) {
        Write-Host "Current Entro App: " -NoNewline
        Write-Host "$($script:entroAppRegistration.DisplayName) ($($script:entroAppRegistration.AppId))" -ForegroundColor DarkMagenta
    }
    else {
        Write-Host "Current Entro App: " -NoNewline
        Write-Host "None selected" -ForegroundColor DarkGray
    }

    # Display current Log Analytics Workspace if one is selected
    if ($script:entroLogWkspc) {
        Write-Host "Current Entro Log Workspace: " -NoNewline
        Write-Host "$($script:entroLogWkspc.Name) ($($script:entroLogWkspc.ResourceGroupName), $($script:entroLogWkspc.Location))" -ForegroundColor DarkGreen
    }
    else {
        Write-Host "Current Entro Log Workspace: " -NoNewline
        Write-Host "None selected" -ForegroundColor DarkGray
    }
    
    # Display if subs lists are being used
    if ($script:subscriptionsExactList.Count -gt 0) {
        Write-Host "Subscription Exact List: In Use     " -ForegroundColor DarkGray -NoNewline
    }
    if ($script:subscriptionsToExclude.Count -gt 0) {
        Write-Host "Subscription Exclusion List: In Use" -ForegroundColor DarkGray -NoNewline
    }
    if ($script:subscriptionsExactList.Count -gt 0 -or $script:subscriptionsToExclude.Count -gt 0) {
        Write-Host "" # Put a new line out there if either list is being used for proper spacing
    }    
    Write-Host "" # Extra line for spacing

    $menu = @"
[1] Create/Select Entro App Registration
[2] Configure Entro App API Permissions
[3] Create and assign Entro Roles to Subscriptions/Management Groups
[4] Create/Select Entro Log Analytics Workspace
[5] Send Sign-In Logs to Entro Log Analytics Workspace
[6] Configure Keyvaults for Entro Inspection
[7] Configure Keyvaults activity for Entro Analysis
------------------------------------
[r] Remove Entro from Azure
------------------------------------
[x] Exit Script

"@

    Write-Host $menu

    $choice = Read-Host "Enter your selection"
    
    switch ($choice) {
        1 { CreateSelect-EntroAppRegistration; Show-Menu}
        2 { Configure-EntroAppApiPermissions; Show-Menu }
        3 { Create-EntroCustomRole; Show-Menu }
        4 { CreateSelect-EntroLogAnalyticsWorkspace; Show-Menu }
        5 { Configure-SignInLogForwarding ; Show-Menu }
        6 { Configure-KeyvaultsForEntro ; Show-Menu}
        7 { Configure-KeyvaultsActivityForEntro ; Show-Menu }
        r { Delete-Entro ; Show-Menu }
        x { Exit-Script }
        setsubsexactlist { selectSubs -ExactList; Show-Menu }
        setsubstoexclude { selectSubs -ExcludeList; Show-Menu }
        default { Write-Host "Please input a valid selection." -ForegroundColor Red; Start-Sleep -Seconds 2; Show-Menu }
    }
}


############################################
########   Main Action Functions ###########
############################################
function Get-EntroAuditPermissionGroups {
    return [ordered]@{
        "Mandatory" = @("User.Read", "User.Read.All", "Directory.Read.All")
        "Azure Cloud" = @("Application.Read.All", "Application.ReadWrite.All", "Device.Read.All", "AuditLog.Read.All", "SignInLogs.Read.All")
        "Teams Channels" = @("TeamsActivity.Read.All", "TeamSettings.Read.All", "TeamsTab.Read.All", "TeamsAppInstallation.ReadForChat.All", "TeamsAppInstallation.ReadForTeam.All", "TeamsAppInstallation.ReadForUser.All", "Channel.ReadBasic.All", "ChannelMember.Read.All", "ChannelMessage.Read.All", "ChannelSettings.Read.All")
        "Teams Private Chats" = @("Chat.Read.All")
        "Teams Send Messages" = @("TeamsAppInstallation.ReadWriteForTeam.All", "TeamsAppInstallation.ReadWriteSelfForUser.All", "TeamsAppInstallation.ReadWriteForUser.All")
        "SharePoint and OneDrive" = @("Sites.Read.All", "Files.Read.All")
        "Microsoft Copilot (AI Agents)" = @("AiEnterpriseInteraction.Read.All", "Reports.Read.All", "ExternalConnection.Read.All", "AppCatalog.Read.All")
        "MS Defender (AI Agents)" = @("Machine.Read.All", "ThreatHunting.Read.All")
    }
}

function Get-EntroAuditPermissionNames {
    $groups = Get-EntroAuditPermissionGroups
    $names = @()
    foreach ($group in $groups.Keys) {
        $names += $groups[$group]
    }
    return $names | Select-Object -Unique
}

function Get-EntroDefenderServicePrincipal {
    param([switch]$Ensure)

    $defenderAppId = "fc780465-2017-40d4-a0c5-307022471b92"
    try {
        $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$defenderAppId'" -ErrorAction Stop
        if (-not $servicePrincipal -and $Ensure) {
            Write-Host "WindowsDefenderATP is not provisioned in this tenant. Creating its service principal..." -ForegroundColor Yellow
            New-MgServicePrincipal -AppId $defenderAppId -ErrorAction Stop *> $null
            $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$defenderAppId'" -ErrorAction Stop
        }
        return $servicePrincipal
    }
    catch {
        Write-Host "Warning: Could not provision or retrieve the WindowsDefenderATP Service Principal. MS Defender permissions will not be available." -ForegroundColor Yellow
        Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

function Apply-EntroNamedApiPermissions {
    param([Parameter(Mandatory = $true)][string[]]$PermissionNames)

    $mgAppReg = Get-MgApplication -Filter "AppId eq '$($script:entroServicePrincipal.AppId)'"
    $maxRetries = 5
    $sleepSeconds = 2
    $attempt = 0
    while (-not $mgAppReg -and $attempt -lt $maxRetries) {
        Start-Sleep -Seconds $sleepSeconds
        $mgAppReg = Get-MgApplication -Filter "AppId eq '$($script:entroServicePrincipal.AppId)'"
        $attempt++
    }
    $attempt = 0
    $mgEntApp = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroServicePrincipal.AppId)'"
    while (-not $mgEntApp -and $attempt -lt $maxRetries) {
        Start-Sleep -Seconds $sleepSeconds
        $mgEntApp = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroServicePrincipal.AppId)'"
        $attempt++
    }
    try {
        $graphServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
    }
    catch {
        Write-Error-Message "An error occurred while fetching MS Graph Service Principal, unable to continue operations."
        Write-Host "Error Details: $($_.Exception.Message)"
        Read-Host "Press Enter to return to the menu..."
        return
    }
    $defenderServicePrincipal = Get-EntroDefenderServicePrincipal -Ensure:($PermissionNames -contains "Machine.Read.All")

    $graphRequiredAccess = @{
        ResourceAppId = $graphServicePrincipal.AppId
        ResourceAccess = @()
    }
    $defenderRequiredAccess = @{
        ResourceAppId = if ($defenderServicePrincipal) { $defenderServicePrincipal.AppId } else { "fc780465-2017-40d4-a0c5-307022471b92" }
        ResourceAccess = @()
    }
    foreach ($permissionName in $PermissionNames) {
        $appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $permissionName }
        if ($appRole) {
            $graphRequiredAccess.ResourceAccess += @{ Id = $appRole.Id; Type = "Role" }
            Write-Host "Added Graph application permission: $permissionName"
        } else {
            $oauth2Permission = $graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Value -eq $permissionName }
            if ($oauth2Permission) {
                $graphRequiredAccess.ResourceAccess += @{ Id = $oauth2Permission.Id; Type = "Scope" }
                Write-Host "Added Graph delegated permission: $permissionName"
            } elseif ($defenderServicePrincipal) {
                $defenderRole = $defenderServicePrincipal.AppRoles | Where-Object { $_.Value -eq $permissionName }
                if ($defenderRole) {
                    $defenderRequiredAccess.ResourceAccess += @{ Id = $defenderRole.Id; Type = "Role" }
                    Write-Host "Added Defender application permission: $permissionName"
                } else {
                    Write-Warning "Permission '$permissionName' not found in Microsoft Graph or Defender ATP APIs"
                }
            } else {
                Write-Warning "Permission '$permissionName' not found in Microsoft Graph API"
            }
        }
    }
    $allRequiredAccess = @()
    if ($graphRequiredAccess.ResourceAccess.Count -gt 0) { $allRequiredAccess += $graphRequiredAccess }
    if ($defenderRequiredAccess.ResourceAccess.Count -gt 0) { $allRequiredAccess += $defenderRequiredAccess }
    try {
        Update-MgApplication -ApplicationId $script:entroAppRegistration.Id -RequiredResourceAccess $allRequiredAccess
        Write-Host "API permissions have been configured for the application" -ForegroundColor Green
    }
    catch {
        Write-Error-Message "An error occurred while configuring API permissions."
        Write-Host "Error Details: $($_.Exception.Message)"
        Read-Host "Press Enter to return to the menu..."
        return
    }
    foreach ($resourceAccess in $graphRequiredAccess.ResourceAccess) {
        if ($resourceAccess.Type -eq "Role") {
            try {
                $params = @{
                    PrincipalId = $mgEntApp.Id
                    ResourceId = $graphServicePrincipal.Id
                    AppRoleId = $resourceAccess.Id
                }
                $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mgEntApp.Id |
                    Where-Object { $_.AppRoleId -eq $resourceAccess.Id -and $_.ResourceId -eq $graphServicePrincipal.Id }
                if (-not $existingAssignment) {
                    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mgEntApp.Id -BodyParameter $params *> $null
                    $permissionName = ($graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                    Write-Host "Granted application permission: $permissionName"
                } else {
                    Write-Host "Application permission already granted: $(($graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value)"
                }
            }
            catch {
                Write-Error "Error granting application permission: $_"
            }
        }
        elseif ($resourceAccess.Type -eq "Scope") {
            try {
                $params = @{
                    ClientId = $mgEntApp.Id
                    ConsentType = "AllPrincipals"
                    ResourceId = $graphServicePrincipal.Id
                    Scope = ($graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                }
                $existingGrant = Get-MgOauth2PermissionGrant -Filter "ClientId eq '$($mgEntApp.Id)' and ResourceId eq '$($graphServicePrincipal.Id)'"
                if (-not $existingGrant) {
                    try {
                        New-MgOauth2PermissionGrant -BodyParameter $params *> $null
                        Write-Host "Granted delegated permission: $($params.Scope)"
                    } catch {
                        Write-Error "Error granting delegated permission: $_"
                    }
                } else {
                    Write-Host "Delegated permission already granted: $($params.Scope)"
                }
            }
            catch {
                Write-Error "Error granting delegated permission: $_"
            }
        }
    }
    if ($defenderServicePrincipal) {
        foreach ($resourceAccess in $defenderRequiredAccess.ResourceAccess) {
            try {
                $params = @{
                    PrincipalId = $mgEntApp.Id
                    ResourceId = $defenderServicePrincipal.Id
                    AppRoleId = $resourceAccess.Id
                }
                $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mgEntApp.Id |
                    Where-Object { $_.AppRoleId -eq $resourceAccess.Id -and $_.ResourceId -eq $defenderServicePrincipal.Id }
                if (-not $existingAssignment) {
                    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mgEntApp.Id -BodyParameter $params *> $null
                    $permissionName = ($defenderServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                    Write-Host "Granted Defender application permission: $permissionName"
                }
            }
            catch {
                Write-Error "Error granting Defender application permission: $_"
            }
        }
    }
    Write-Host "API permissions have been granted for the application" -ForegroundColor Green
}

function CreateSelect-EntroAppRegistration {
    [bool]$hasErrors = $false
    Clear-Host
    
    Write-Host "Searching for any existing Entro App Registration(s)..."
    # Check if the app registration already exists
     try {
        $entroApps = Get-MgApplication -Search '"DisplayName:Entro"' -ConsistencyLevel eventual -All
    } catch {
        Write-Host "Error retrieving app registrations: $($_.Exception.Message)" -ForegroundColor Red
    }

    if ($entroApps) {
       if ($entroApps.Count -eq 1) { #found one app registration
            # Ask the user if they want to use the found app registration or create a new one
            Write-Host "Found $($entroApps.Count) matching app registration.`n"
            Write-Host "$($entroApps.DisplayName) ($($entroApps.AppId))" -ForegroundColor Yellow
            $response = Read-Host "`nPress Enter to use this app registration, or type 'n' to create a new one..."
            if ($response = $null -or $response -eq "") { #using the found app registration
                $script:entroAppRegistration = $entroApps
                try {
                    $script:entroServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroAppRegistration.AppId)'"
                }
                catch {
                    <#Do this if a terminating exception happens#>
                } 
            } else {
                # Clear out the existing app registration to create a new one below
                $script:entroAppRegistration = $null
                $script:entroServicePrincipal = $null
            }
        } else {
            # Multiple app registrations found, ask user to select one
            $script:entroAppRegistration = Show-SelectionMenu -DataObjects $entroApps -Columns @("DisplayName", "AppId") -HeaderLabels @{DisplayName = "Application"; AppId = "App ID"} -CustomMsg "Select the Entro App Registration you would like to use. SELECT NOTHING TO CREATE A NEW ENTRO APP." -SelectOne
            if ($script:entroAppRegistration) {
                try {
                    $script:entroServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroAppRegistration.AppId)'"
                }
                catch {
                    Write-Error-Message "An error occurred while retrieving the service principal for the selected app registration."
                    Write-Host "Error Details: $($_.Exception.Message)"
                    Read-Host "Press Enter to return to the menu..."
                    return
                }
            }
        }
    } else {
        Write-Host "`nNo Entro app registrations found.`n"
    }
    
    if (-not $script:entroAppRegistration) {
        Write-Host "`nCreating Entro App Registration..." -ForegroundColor Yellow

        # Ask the user to enter the app name or press Enter to use the default name
        $newAppName = Read-Host "`nEnter the name of the application you would like to use`nType q to cancel this operation and return to the menu`nPress Enter to use the default name - '$script:entroAppRegName'"
        $AppName = if ($newAppName) { $newAppName } else { $script:entroAppRegName }
        
        if ($AppName -eq 'q' -or $AppName -eq 'Q') {
            return
        }

        try {
            #Create a service principal (enterprise app, local to Azure tenant) and app registration (global Azure object) for the new app. 
            # New-AzADServicePrincipal creates the service principal and app registration in one step
            $script:entroServicePrincipal = New-AzADServicePrincipal -DisplayName $AppName
            $secret = $script:entroServicePrincipal.PasswordCredentials.SecretText
            # Adding this tag to the app registration so it appears as and "Enterprise Application" in Entra
            Update-AzADServicePrincipal -ObjectId $script:entroServicePrincipal.Id -Tag "WindowsAzureActiveDirectoryIntegratedApp"
            # Get the App Registration object from the service principal to use later
            $script:entroAppRegistration = Get-AzADApplication -ApplicationId $script:entroServicePrincipal.AppId
        }
        catch {
            Write-Error-Message "An error occurred while creating the Entro Application."
            Write-Host "Error Details: $($_.Exception.Message)"
            Read-Host "Press Enter to return to the menu..."
            return
        }

        # Now that we have the app registration created, we need to assign the necessary API permissions to it. These are the APIs that Entro will be allowed to call for the objects we assign in the role/scope later on
        write-host "`nAssigning Entro permission-audit Graph and Defender API permissions to the Entro App ..." -ForegroundColor Yellow
        Apply-EntroNamedApiPermissions -PermissionNames (Get-EntroAuditPermissionNames)
        Write-Success-Message "Entro App Registration ($AppName) created successfully"
        Write-Host "`n`n`nCOPY THE FOLLOWING INFORMATION INTO THE ENTRO SECURITY PORTAL --> https://app.entro.security/admin/account/add/2"
        Write-Notification-Message "`nAzure Tenant ID: $($script:entroServicePrincipal.AppOwnerOrganizationId)"
        Write-Notification-Message "Azure Client ID: $($script:entroAppRegistration.AppId)"
        Write-Notification-Message "Azure Client Secret: $($script:entroServicePrincipal.PasswordCredentials.SecretText)"
        Write-Host "`nPress Enter When ready to continue..."
        Read-Host
    }
}

function Configure-EntroAppApiPermissions {
    Clear-Host
    # Check if Entro App Registration has been created/selected
    if ($null -eq $script:entroAppRegistration) {
        Write-Host "No Entro App selected. Please select or create one..." -ForegroundColor Yellow
        try {
            CreateSelect-EntroAppRegistration
        } catch {
            Write-Host ("Error selecting/creating Entro app: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
        if ($null -eq $script:entroAppRegistration) {
            Write-Host "There was an error when selecting/creating the Entro App. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }

    if (-not $script:entroServicePrincipal.Id -or -not $script:entroServicePrincipal.AppId -or $script:entroServicePrincipal.AppId -ne $script:entroAppRegistration.AppId) {
        Write-Host "Invalid or mismatched service principal. Attempting to retrieve service principal for AppId: $($script:entroAppRegistration.AppId)" -ForegroundColor Yellow
        try {
            $script:entroServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroAppRegistration.AppId)'" 
            if (-not $script:entroServicePrincipal) {
                    Write-Host "No Enterprise Application found for AppId: $($script:entroAppRegistration.AppId)." -ForegroundColor Yellow
                    Read-Host "Press Enter to return to the menu..."
                    return $false
                }
        } catch {
            Write-Host ("Failed to retrieve Enterprise Application: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }

    # Refresh $script:entroAppRegistration to ensure RequiredResourceAccess is up-to-date
    try {
        $script:entroAppRegistration = Get-MgApplication -ApplicationId $script:entroAppRegistration.Id
    } catch {
        Write-Host ("Failed to refresh Entro app registration: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Read-Host "Press Enter to return to the menu..."
        return $false
    }

    # Define permission groups
    $permissionGroups = Get-EntroAuditPermissionGroups

    # Get Microsoft Graph Service Principal
    try {
        $graphServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
    }
    catch {
        Write-Error-Message "An error occurred while fetching MS Graph Service Principal, unable to continue operations."
        Write-Host "Error Details: $($_.Exception.Message)"
        Read-Host "Press Enter to return to the menu..."
        return
    }

    # Get Windows Defender ATP Service Principal (for MS Defender / AI Agents permissions)
    $defenderServicePrincipal = Get-EntroDefenderServicePrincipal

    # Check Graph session scopes
    $scopes = Get-MgContext | Select-Object -ExpandProperty Scopes
    if ($scopes -notcontains "DelegatedPermissionGrant.ReadWrite.All") {
        Write-Host "Current Graph session lacks 'DelegatedPermissionGrant.ReadWrite.All' scope. Please reconnect with required scopes." -ForegroundColor Red
        Read-Host "Press Enter to return to the menu..."
        return $false
    }

    # Get current permissions from App Registration (Graph)
    $currentGraphAccess = $script:entroAppRegistration.RequiredResourceAccess | Where-Object { $_.ResourceAppId -eq $graphServicePrincipal.AppId }
    $currentPermissions = @()
    if ($currentGraphAccess) {
        foreach ($access in $currentGraphAccess.ResourceAccess) {
            $permValue = if ($access.Type -eq "Role") {
                ($graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $access.Id }).Value
            } else {
                ($graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Id -eq $access.Id }).Value
            }
            if ($permValue) {
                $currentPermissions += [PSCustomObject]@{
                    PermissionName = $permValue
                    Type = $access.Type
                    Id = $access.Id
                }
            }
        }
    }
    # Get current permissions from App Registration (Defender ATP)
    if ($defenderServicePrincipal) {
        $currentDefenderAccess = $script:entroAppRegistration.RequiredResourceAccess | Where-Object { $_.ResourceAppId -eq $defenderServicePrincipal.AppId }
        if ($currentDefenderAccess) {
            foreach ($access in $currentDefenderAccess.ResourceAccess) {
                $permValue = ($defenderServicePrincipal.AppRoles | Where-Object { $_.Id -eq $access.Id }).Value
                if ($permValue) {
                    $currentPermissions += [PSCustomObject]@{
                        PermissionName = $permValue
                        Type = $access.Type
                        Id = $access.Id
                    }
                }
            }
        }
    }

    # Prepare all groups for selection, including Mandatory, with ListPos(-ition (for sorting))
    $groupObjects = @()
    $groupsAlreadyGranted = @()
    $groupNames = $permissionGroups.Keys
    foreach ($groupName in $groupNames) {
        $groupPerms = $permissionGroups[$groupName]
        $allAssigned = -not ($groupPerms | Where-Object { $_ -notin ($currentPermissions.PermissionName) })
        $listPos = switch ($groupName) {
            "Mandatory" { 0 }
            "Azure Cloud" { 1 }
            "Teams Channels" { 2 }
            "Teams Private Chats" { 3 }
            "Teams Send Messaging" { 4 }
            "SharePoint and OneDrive" { 5 }
            "Microsoft Copilot - Discover and Analyze AI Agents" { 6 }
            "MS Defender / AI Agents" { 7 }
            default { 99 }
        }
        $groupObjects += [PSCustomObject]@{
            GroupName = $groupName
            Status = if ($allAssigned) { "Enabled" } else { "Disabled" }
            Permissions = ($groupPerms -join ", ")
            Id = $groupName
            ListPos = $listPos
        }
        
        # Make sure groups that are currently granted are pre-selected in the menu
        if ($allAssigned) {
            $groupsAlreadyGranted += $groupName
        }
    }

    # Show menu to select which permissions to add/remove (Mandatory is always selected)
    $selectedGroups = Show-SelectionMenu `
        -DataObjects $groupObjects `
        -Columns @("GroupName", "Status", "Permissions") `
        -HeaderLabels @{ GroupName = "Group"; Status = "Current Status"; Permissions = "Permissions" } `
        -ColumnWidths @{ GroupName = -30; Status = -20; Permissions = -60 } `
        -UniqueKey "Id" `
        -SortBy "ListPos" `
        -MandatoryIds @("Mandatory") `
        -InitialSelectionIds @($permissionGroups.Keys) `
        -CustomMsg "Select permission groups to enable for $($script:entroAppRegistration.DisplayName) (Mandatory is always enabled)"

    # Calculate desired groups from selected (Mandatory is always included)
    $desiredGroups = $selectedGroups.GroupName

    # Calculate desired permissions
    $desiredPermissions = @()
    foreach ($group in $desiredGroups) {
        if ($permissionGroups.Contains($group)) {
            $desiredPermissions += $permissionGroups[$group]
        } else {
            Write-Host ("Invalid group name '{0}' encountered. Skipping." -f $group) -ForegroundColor Yellow
        }
    }
    $desiredPermissions = $desiredPermissions | Sort-Object | Select-Object -Unique

    if (-not $defenderServicePrincipal -and $desiredPermissions -contains "Machine.Read.All") {
        $defenderServicePrincipal = Get-EntroDefenderServicePrincipal -Ensure
    }

    # Debug: Output desired permissions
    Write-Host "Desired permissions: $($desiredPermissions -join ', ')" -ForegroundColor Cyan

    # Calculate permissions to add and remove
    $toAdd = $desiredPermissions | Where-Object { $_.PermissionName -notin $currentPermissions }
    $toRemove = $currentPermissions | Where-Object { $_.PermissionName -notin $desiredPermissions }

    # Build new RequiredResourceAccess (API permissions list) - separate objects per API resource
    $graphRequiredAccess = @{
        ResourceAppId = $graphServicePrincipal.AppId
        ResourceAccess = @()
    }
    $defenderRequiredAccess = @{
        ResourceAppId = if ($defenderServicePrincipal) { $defenderServicePrincipal.AppId } else { "fc780465-2017-40d4-a0c5-307022471b92" }
        ResourceAccess = @()
    }

    # Add each permission from desiredPermissions to the appropriate resource access list
    foreach ($permissionName in $desiredPermissions) {
        # Try Microsoft Graph first (Role then Scope)
        $appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $permissionName }
        if ($appRole) {
            $graphRequiredAccess.ResourceAccess += @{ Id = $appRole.Id; Type = "Role" }
            Write-Host "Added Graph application permission: $permissionName"
        } else {
            $oauth2Permission = $graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Value -eq $permissionName }
            if ($oauth2Permission) {
                $graphRequiredAccess.ResourceAccess += @{ Id = $oauth2Permission.Id; Type = "Scope" }
                Write-Host "Added Graph delegated permission: $permissionName"
            } elseif ($defenderServicePrincipal) {
                # Try Defender ATP (application roles only)
                $defenderRole = $defenderServicePrincipal.AppRoles | Where-Object { $_.Value -eq $permissionName }
                if ($defenderRole) {
                    $defenderRequiredAccess.ResourceAccess += @{ Id = $defenderRole.Id; Type = "Role" }
                    Write-Host "Added Defender application permission: $permissionName"
                } else {
                    Write-Warning "Permission '$permissionName' not found in Microsoft Graph or Defender ATP APIs"
                }
            } else {
                Write-Warning "Permission '$permissionName' not found in Microsoft Graph API"
            }
        }
    }

    # Build the combined resource access array (only include resources that have permissions)
    $allRequiredAccess = @()
    if ($graphRequiredAccess.ResourceAccess.Count -gt 0) { $allRequiredAccess += $graphRequiredAccess }
    if ($defenderRequiredAccess.ResourceAccess.Count -gt 0) { $allRequiredAccess += $defenderRequiredAccess }

    # Update the App Reg with the new permissions
    try {
        Update-MgApplication -ApplicationId $script:entroAppRegistration.Id -RequiredResourceAccess $allRequiredAccess
        Write-Host "App Reg API permissions have been configured for the application" -ForegroundColor Green
    }
    catch {
        Write-Error-Message "An error occurred while configuring App Reg API permissions."
        Write-Host "Error Details: $($_.Exception.Message)"
        Read-Host "Press Enter to return to the menu..."
        return
    }
    
    if ($toRemove.Count -gt 0) {
        # We have permissions that need to be removed
        # Get all current grants and assignments of the service principal
        $currentAppRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id -All
        $currentDelegatedGrants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $script:entroServicePrincipal.Id -All
        
        foreach ($permission in $toRemove) {
            if ($permission.Type -eq "Role") {
                $permGrant = $currentAppRoleAssignments | Where-Object { $_.AppRoleId -eq $permission.Id }
                if ($permGrant) {
                    try {
                        Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id -AppRoleAssignmentId $permGrant.Id
                        Write-Host "Removed application permission: $($permission.PermissionName)"
                    } catch {
                        Write-Error-Message "Failed to remove application permission for '$($permission.PermissionName)': $_"
                    }
                }
            } elseif ($permission.Type -eq "Scope") {
                $permGrant = $currentDelegatedGrants | Where-Object { $_.OAuth2PermissionGrantId -eq $permission.Id }
                if ($permGrant) {
                    try {
                        Remove-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $script:entroServicePrincipal.Id -OAuth2PermissionGrantId $permission.Id
                        Write-Host "Removed delegated permission: $($permGrant.PermissionName)"
                    } catch {
                            Write-Error-Message "Failed to remove delegated grant for '$($permission.PermissionName)': $_"
                    }
                }
            }
        }
        Write-Host "Service Principal permissions removal complete." -ForegroundColor Green
    }

    # Grant admin consent for Graph permissions
    foreach ($resourceAccess in $graphRequiredAccess.ResourceAccess) {
        if ($resourceAccess.Type -eq "Role") {
            try {
                $params = @{
                    PrincipalId = $script:entroServicePrincipal.Id
                    ResourceId = $graphServicePrincipal.Id
                    AppRoleId = $resourceAccess.Id
                }
                $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id |
                    Where-Object { $_.AppRoleId -eq $resourceAccess.Id -and $_.ResourceId -eq $graphServicePrincipal.Id }
                if (-not $existingAssignment) {
                    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id -BodyParameter $params *> $null
                    $permissionName = ($graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                    Write-Host "Granted application permission: $permissionName"
                } else {
                    Write-Host "Application permission already granted: $(($graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value)"
                }
            }
            catch {
                Write-Error "Error granting application permission: $_"
            }
        }
        elseif ($resourceAccess.Type -eq "Scope") {
            try {
                $params = @{
                    ClientId = $script:entroServicePrincipal.Id
                    ConsentType = "AllPrincipals"
                    ResourceId = $graphServicePrincipal.Id
                    Scope = ($graphServicePrincipal.OAuth2PermissionScopes | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                }
                $existingGrant = Get-MgOauth2PermissionGrant -Filter "ClientId eq '$($script:entroServicePrincipal.Id)' and ResourceId eq '$($graphServicePrincipal.Id)'"
                if (-not $existingGrant) {
                    try {
                        New-MgOauth2PermissionGrant -BodyParameter $params *> $null
                        Write-Host "Granted delegated permission: $($params.Scope)"
                    } catch {
                        Write-Error "Error granting delegated permission: $_"
                    }
                } else {
                    Write-Host "Delegated permission already granted: $($params.Scope)"
                }
            }
            catch {
                Write-Error "Error granting delegated permission: $_"
            }
        }
    }

    # Grant admin consent for Defender ATP permissions
    if ($defenderServicePrincipal -and $defenderRequiredAccess.ResourceAccess.Count -gt 0) {
        foreach ($resourceAccess in $defenderRequiredAccess.ResourceAccess) {
            if ($resourceAccess.Type -eq "Role") {
                try {
                    $params = @{
                        PrincipalId = $script:entroServicePrincipal.Id
                        ResourceId = $defenderServicePrincipal.Id
                        AppRoleId = $resourceAccess.Id
                    }
                    $existingAssignment = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id |
                        Where-Object { $_.AppRoleId -eq $resourceAccess.Id -and $_.ResourceId -eq $defenderServicePrincipal.Id }
                    if (-not $existingAssignment) {
                        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $script:entroServicePrincipal.Id -BodyParameter $params *> $null
                        $permissionName = ($defenderServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value
                        Write-Host "Granted Defender application permission: $permissionName"
                    } else {
                        Write-Host "Defender application permission already granted: $(($defenderServicePrincipal.AppRoles | Where-Object { $_.Id -eq $resourceAccess.Id }).Value)"
                    }
                }
                catch {
                    Write-Error "Error granting Defender application permission: $_"
                }
            }
        }
    }

    Write-Host "`nAPI permissions configuration and grant completed." -ForegroundColor Green
    Read-Host "Press Enter to return to the menu..."
    return $true
}

function Create-EntroCustomRole {
    Clear-Host
    # Check if Entro App has been selected/created (we need an app registration to assign the role to)
    if ($null -eq $script:entroAppRegistration) {
        Write-Host "No Entro App selected. Please select or create one..." -ForegroundColor Yellow
        try {
            CreateSelect-EntroAppRegistration
        } catch {
            Write-Host ("Error selecting/creating Entro app: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
        if ($null -eq $script:entroAppRegistration) {
            Write-Host "There was an error when selecting/creating the Entro App. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }
    # Validate the local service principal of the App registration has been retrieved
    if (-not $script:entroServicePrincipal.Id -or -not $script:entroServicePrincipal.AppId -or $script:entroServicePrincipal.AppId -ne $script:entroAppRegistration.AppId) {
        Write-Host "Invalid or mismatched service principal. Attempting to retrieve service principal for AppId: $($script:entroAppRegistration.AppId)" -ForegroundColor Yellow
        try {
            $script:entroServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroAppRegistration.AppId)'" 
            if (-not $script:entroServicePrincipal) {
                    Write-Host "No Enterprise Application found for AppId: $($script:entroAppRegistration.AppId)." -ForegroundColor Yellow
                    Read-Host "Press Enter to return to the menu..."
                    return $false
                }
        } catch {
            Write-Host ("Failed to retrieve Enterprise Application: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }

    # Check Selected Entro App Service Principal for exisitng role assignments
    try {
       $existingRoleAssignments = Get-AzRoleAssignment -ObjectId $script:entroServicePrincipal.Id -Scope "/" -IncludeClassicAdministrators:$false
        if ($existingRoleAssignments.Count -gt 0) {
            Write-Host "The selected Entro App already has existing role assignments. Please review or remove them before creating new roles." -ForegroundColor Yellow
            $existingRoleAssignments | Format-Table RoleDefinitionName, Scope
            Read-Host "Press Enter to return to the menu..."
            return 
        }
    } catch {
        Write-Error-Message "An error occurred while retrieving existing role assignments for the Entro service principal."
        Write-Host "Error Details: $($_.Exception.Message)"
        Read-Host "Press Enter to return to the menu..."
        return
    }

    # Begin creating the Entro role that grants the enterprise app the necessary custom permissions to the objects in the scopes assigned to the role
    # Get Entro's new custom role name from the user or use the default script variable
    $newRoleName = Read-Host "Enter a name for Entro's new custom role or leave blank to use the default role name: $script:entroRoleName"
    if (-not $newRoleName -or $newRoleName -eq "") {
        $newRoleName = $script:entroRoleName
    }
    
    $role = New-Object -TypeName Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition
    $role.Name = "$newRoleName"
    $role.Description = "Entro Security requires permissions to manage and monitor tokens, secrets, and vaults."
    $role.IsCustom = $True
    $role.AssignableScopes = @()

    # Define required custom actions and data actions for the Entro role (additional built-in roles will be added later)
    $requiredActions = @(
        "*/read",
        "Microsoft.OperationalInsights/workspaces/analytics/query/action",
        "Microsoft.OperationalInsights/workspaces/search/action",
        "Microsoft.Insights/alertRules/*",
        "Microsoft.Support/*",
        "Microsoft.Web/sites/config/list/Action"
    )
    $notActions = @("Microsoft.OperationalInsights/workspaces/sharedKeys/read")

    # Az.Resources 9.x: PSRoleDefinition has Actions/NotActions on the role; it has no Permissions property
    $role.Actions = $requiredActions
    $role.NotActions = $notActions

    # Retrieve the other built-in roles that Entro needs to function properly
    try {
        $kvReaderRoleId = (Get-AzRoleDefinition -Name "Key Vault Reader").Id
        $appConfigDataReaderRoleId = (Get-AzRoleDefinition -Name "App Configuration Data Reader").Id
    }
    catch {
        Write-Error-Message "An error occurred while retrieving the built-in roles required for Entro to function."
        Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red    
        Read-Host "Press Enter to return to the menu..."
        return
    }


    # Have user select subscriptions and/or management groups to assign the roles for the Entro app registration
    $userSelectedSubs = Get-UserSelectedSubscriptions -customMsg "Select subscriptions/Mgmt Groups to include in the scope(s) of the role" -includeMgmtGrps
    if (-not $userSelectedSubs -or $userSelectedSubs.Count -eq 0) {
        Write-Error-Message "No subscriptions or management groups selected. Cancelling operation."
        Write-Host "Press Enter to return to the menu..."
        Read-Host
        return
    }

    
    #For each selected subscription or management group, create the new custom role, assign the custom role to the Entro app registration, then assign other built-in roles to the Entro app registration.
    $counter = 0
    $userSelectedSubs | ForEach-Object {
        $counter++
        $role.Name = "$($newRoleName)$($counter)"
        if ($_.Type -eq "ManagementGroup" -or $_.Type -eq "TenantRootMgmtGroup") {
            $currentScope = "/providers/Microsoft.Management/managementGroups/$($_.Id)"
        }
        elseif ($_.Type -eq "Subscription") {
            $currentScope = "/subscriptions/$($_.Id)"
        }
        $role.AssignableScopes = @($currentScope)

        # Check if the role already exists bfore creating a new one
        $existingRole = & { Get-AzRoleDefinition -Scope $currentScope -Name $role.Name } *> $null
        if (@($existingRole).Count -gt 0) {
            Write-Host "Found exisiting role: $($existingRole.Name) in: $($_.Name)"

        } 
        else {
            try {
                Write-Host "Creating new [$($role.Name)] role in {$($_.Name)}... " -NoNewline
                New-AzRoleDefinition -SkipClientSideScopeValidation -Role $role *> $null
                Write-Host "Success" -ForegroundColor Green
                # Now wait for Role to be propagated ...
                $timeout = 60  # Max wait time in seconds
                $sleepInterval = 5  # Time between retries
                $elapsedTime = 0  # Track time spent waiting
                do {
                    Start-Sleep -Seconds $sleepInterval  # Wait for propagation
                    $elapsedTime += $sleepInterval  # Increment elapsed time

                    # Try to fetch the role
                    $entroRole = Get-AzRoleDefinition -Scope $currentScope -Name $role.Name

                    if ($entroRole) {
                        break  # Exit the loop if role is found
                    }
                } while (-not $entroRole -and $elapsedTime -lt $timeout)
                # Final Check
                if (-not $entroRole) {
                    Write-Error-Message "Role '$($role.Name)' was not found after waiting $timeout seconds."
                    Write-Host "Press Enter to return to the menu..."
                    Read-Host
                    return
                } 
                # Assign the role to the app registration
                try { # Assign the Entro role
                    Write-Host "Assigning [$($entroRole.Name)] role to $($script:entroServicePrincipal.DisplayName) for {$($_.Name)}... " -NoNewline
                    New-AzRoleAssignment -ObjectId $script:entroServicePrincipal.Id -RoleDefinitionID $entroRole.Id -Scope $currentScope *> $null
                    Write-Host "Success" -ForegroundColor Green
                }
                catch {
                    Write-Host "Failed " -ForegroundColor Red -NoNewline
                    Write-Host "($($_.Exception.Message))"
                }
            }
            catch {
                Write-Host "Failed " -ForegroundColor Red -NoNewline
                Write-Host "($($_.Exception.Message))"
            }

            try { # Assign the Key Vault Reader role
                Write-Host "Assigning [Key Vault Reader] role to $($script:entroServicePrincipal.DisplayName) for {$($_.Name)}... " -NoNewline
                New-AzRoleAssignment -ObjectId $script:entroServicePrincipal.Id -RoleDefinitionID $kvReaderRoleId -Scope $currentScope *> $null
                Write-Host "Success" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed " -ForegroundColor Red -NoNewline
                Write-Host "($($_.Exception.Message))"
            }
            try { # Assign the App Configuration Data Reader role
                Write-Host "Assigning [App Configuration Data Reader] role to $($script:entroServicePrincipal.DisplayName) for {$($_.Name)}... " -NoNewline
                New-AzRoleAssignment -ObjectId $script:entroServicePrincipal.Id -RoleDefinitionID $appConfigDataReaderRoleId -Scope $currentScope *> $null
                Write-Host "Success" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed " -ForegroundColor Red -NoNewline
                Write-Host "($($_.Exception.Message))"
            }

        }
    }

    # Register Microsoft Insights for all the selected subscriptions
    Write-Host "`nRegistering Microsoft Insights for log analysis for subscriptions that need it..." -ForegroundColor Yellow
    # Iterate through each item in $userSelectedSubs
    foreach ($item in $userSelectedSubs) {
        if ($item.Type -eq "Subscription") {
            # Process individual subscription
            $subscriptionId = $item.Id
            Write-Host "Checking Microsoft.Insights for Subscription: $subscriptionId... " -NoNewline

            # Set the current context to this subscription
            Set-AzContext -SubscriptionId $subscriptionId | Out-Null

            # Check if Microsoft.Insights is registered
            $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.Insights"

            if ($provider.RegistrationState -ne "Registered") {
                Register-AzResourceProvider -ProviderNamespace "Microsoft.Insights" | Out-Null

                # Wait for the registration to complete
                Start-Sleep -Seconds 10  
                $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.Insights"
                
                if ($provider.RegistrationState -eq "Registered") {
                    Write-Host "Registered" -ForegroundColor Green
                } else {
                    Write-Host "Registration is in progress. Please check again later." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Already Registered" -ForegroundColor Green
            }

        } elseif ($item.Type -eq "ManagementGroup") {
            # Process Management Group
            $mgId = $item.Id
            Write-Host "Processing Management Group: $mgId" -ForegroundColor Magenta

            # Get all subscriptions under the management group
            $mgSubs = Get-AzManagementGroupSubscription -GroupId $mgId

            foreach ($sub in $mgSubs) {
                $subscriptionId = ($sub.Id -split "/" | Select-Object -Last 1)
                Write-Host "Checking Microsoft.Insights for Subscription under Management Group: $subscriptionId" -ForegroundColor Cyan
                
                # Set the context
                Set-AzContext -SubscriptionId $subscriptionId | Out-Null

                # Check if Microsoft.Insights is registered
                $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.Insights"

                if ($provider.RegistrationState -ne "Registered") {
                    Write-Host "Microsoft.Insights is not registered in Subscription $subscriptionId. Registering now..." -ForegroundColor Yellow
                    Register-AzResourceProvider -ProviderNamespace "Microsoft.Insights" | Out-Null

                    # Wait for the registration to complete
                    Start-Sleep -Seconds 10  
                    $provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.Insights"
                    
                    if ($provider.RegistrationState -eq "Registered") {
                        Write-Host "Microsoft.Insights successfully registered in Subscription $subscriptionId!" -ForegroundColor Green
                    } else {
                        Write-Host "Registration is in progress. Please check again later." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Microsoft.Insights is already registered in Subscription $subscriptionId." -ForegroundColor Green
                }
            }
        }
    }
}

function CreateSelect-EntroLogAnalyticsWorkspace {
    Clear-Host

    # Get all subscriptions in the tenant
    try {
        if ($script:subscriptionsExactList.Count -gt 0) {
            $subscriptions = Get-AzSubscription | Where-Object { $_.Id -in $script:subscriptionsExactList }
        }else {
            $subscriptions = Get-AzSubscription
        }
        # Exclude specified subscriptions
        if ($script:subscriptionsToExclude.Count -gt 0) {
            $subscriptions = $subscriptions | Where-Object { $_.Id -notin $script:subscriptionsToExclude }
        }
        $totalSubs = $subscriptions.Count
        #Write-Host "Found $totalSubs subscriptions to process" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to get Azure subscriptions: $($_.Exception.Message)"
        return
    }
    $currentSub = 0
    $allLAWs = @()
    $userCancelled = $false
    # Get all Log Analytics Workspaces across all subscriptions with progress bar
    foreach ($subscription in $subscriptions) {
        # Check if user pressed 'Q' to skip remaining subscriptions
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
                Write-Host "`nUser cancelled. Skipping remaining subscriptions..." -ForegroundColor Yellow
                $userCancelled = $true
                break
            }
        }

        $currentSub++
        # Update progress bar
        $progressParams = @{
            Activity = "Retreiving all Log Analytics Workspaces"
            Status = "Processing subscription: $($subscription.Name) (Press 'Q' to skip remaining)"
            PercentComplete = ($currentSub / $totalSubs) * 100
            CurrentOperation = "Subscription $currentSub of $totalSubs"
        }
        Write-Progress @progressParams
        try {
            # Set context
            Set-AzContext -SubscriptionId $subscription.Id | Out-Null
            # Get LAWs from this subscription
            $laws = Get-AzOperationalInsightsWorkspace
            foreach ($law in $laws) {
                $allLAWs += [PSCustomObject]@{
                    ResourceGroupName = $law.ResourceGroupName
                    Name = $law.Name
                    Location = $law.Location
                    CustomerId = $law.CustomerId
                    Sku = $law.Sku
                    SubscriptionName = $subscription.Name
                    SubscriptionID = $subscription.Id
                    Tags = $law.Tags
                    ProvisioningState = $law.ProvisioningState
                    ResourceId = $law.ResourceId
                }
            }
        }
        catch {
            continue
        }
    }
    # Clear the progress bar
    Write-Progress -Activity "Collecting Log Analytics Workspaces" -Completed
    # Find all LAWs with "Entro" in the name, sorted alphabetically
    $entroLAWs = $allLAWs | Where-Object { $_.Name -like "*Entro*" } | Sort-Object Name
    # Now sort all other LAWs alphabetically
    $nonEntroLAWs = $allLAWs | Where-Object { $_.Name -notlike "*Entro*" } | Sort-Object Name
    # Combine the two arrays, with Entro LAWs first
    $allLAWsSorted = @()
    $allLAWsSorted += $entroLAWs
    $allLAWsSorted += $nonEntroLAWs
    
    if ($allLAWsSorted.Count -gt 0) {
        # Show the user menu to select an existing Entro Log Analytics Workspace or create a new one
        $selectedLAW = Show-SelectionMenu `
            -DataObjects $allLAWsSorted `
            -Columns @('Name', 'ResourceGroupName', 'Location', 'SubscriptionName') `
            -HeaderLabels @{ Name = "Workspace Name"; ResourceGroupName = "Resource Group"; Location = "Location"; SubscriptionName = "Subscription Name" } `
            -UniqueKey 'ResourceId' `
            -CustomMsg "Select an existing Log Analytics Workspace or SELECT NOTHING TO CREATE A NEW LAW" `
            -SelectOne  
        if ($selectedLAW) {
        $script:entroLogWkspc = $selectedLAW
        return
        }   
    }
    
    # No existing LAW selected, proceed to create a new one
    Write-Host "Creating a new Entro Log Analytics Workspace..." -ForegroundColor Yellow
    sleep 1
    # Ask user for a Log Analytics Workspace name, defaulting to the script variable, error check for validity
    do {
        $logAnalyticsWorkspaceName = Read-Host "`nEnter the new Entro Log Analytics Workspace name`nType q to cancel this operation and return to the menu`nPress Enter to use the default name - '$script:entroLogAnalyticsWorkspaceName'"

        # If input is empty, use the default script variable
        if ([string]::IsNullOrWhiteSpace($logAnalyticsWorkspaceName)) {
            $logAnalyticsWorkspaceName = $script:entroLogAnalyticsWorkspaceName
        }
        # Check if user wants to cancel
        if ($logAnalyticsWorkspaceName.ToLower() -eq 'q') {
            return $null
        }

        # Validate Log Analytics Workspace name
        if ($logAnalyticsWorkspaceName -match "^[A-Za-z0-9][A-Za-z0-9-]+[A-Za-z0-9]$") {
            Write-Host "Using Log Analytics Workspace name: $logAnalyticsWorkspaceName"
            break  # Exit loop if name is valid
        }
        else {
            Write-Host "`nInvalid workspace name. Please follow these rules:"
            Write-Host "- Must start and end with a letter (A-Z, a-z) or a number (0-9)."
            Write-Host "- Can contain hyphens (-), but cannot start or end with one."
            Write-Host "- No spaces or other special characters are allowed."
            Write-Host "`nPlease enter a valid workspace name."
        }

    } while ($true)
    # Have user select a subscription to create the LAW in
    $selectedSubscription = Get-UserSelectedSubscriptions -SelectOne -customMsg "Select a subscription to create/select the Log Analytics Workspace in..."
    if (-not $selectedSubscription) {
        Write-Host "No subscription selected. Cancelling operation." -ForegroundColor Red
        Read-Host "Press Enter to return to the menu..."
        return $null
    }
    try {
        Write-Host "Switching to Subscription: $($selectedSubscription.Name) ($($selectedSubscription.Id))"
        Set-AzContext -SubscriptionId $selectedSubscription.Id *> $null

    } catch {
        Write-Host "Error selecting subscription: $($_.Exception.Message)" -ForegroundColor Red
        read-host "Press Enter to return to the menu..."
        return $null
    }

    try {
        Write-Host "Retrieving existing resource groups in the selected subscription... " -NoNewLine
        $resourceGroups = @() 
        $resourceGroups = Get-AzResourceGroup
    } catch {
        Write-Host "Error retrieving resource groups: $($_.Exception.Message)" -ForegroundColor Red
        read-host "Press Enter to return to the menu..."
        return $null
    }    

    $selectedResourceGroup = @()
    # If we have any resource groups from Get command above, show menu to select one or create a new one
    if ($resourceGroups.Count -gt 0) {
        $selectedResourceGroup = Show-SelectionMenu `
        -DataObjects $resourceGroups `
        -Columns @('ResourceGroupName', 'Location') `
        -HeaderLabels @{ ResourceGroupName = "Resource Group Name"; Location = "Location" } `
        -UniqueKey 'ResourceGroupName' `
        -CustomMsg "Select an existing Resource Group for the new Entro Log Analytics Workspace or SELECT NOTHING TO CREATE A NEW RESOURCE GROUP FOR ENTRO" `
        -SelectOne
    }
    
    if ($selectedResourceGroup.Count -eq 0) {
        # No existing resource group selected, create a new one
        #write-Host "None Found" -ForegroundColor Yellow
        $resourceGroupName = Read-Host "Enter the new Entro Resource Group name [$script:entroResourceGroupName]"
        if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
            $resourceGroupName = $script:entroResourceGroupName
        }
        Write-Host "Using new Resource Group name: $resourceGroupName"
        # Ask user for Azure location to house the RG, defaulting to the script variable
        $selectedAZLocation = Get-AzureLocation -customMsg "Enter the Azure location for the Entro Resource Group"
        if ($selectedAZLocation) {
            $location = $selectedAZLocation.Location
        }else{
            $location = $script:entroResourceGroupLocation
        }
        Write-Host "Using Azure location: $location"
        # Now let's create the Resource Group
        try {
                Write-Host "Creating new Resource Group: $resourceGroupName in $location... " -NoNewLine
                $selectedResourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location #*> $null
                Write-Host "Success" -ForegroundColor Green
        } catch {
            Write-Host "Error creating Resource Group: $($_.Exception.Message)" -ForegroundColor Red
            read-host "Press Enter to return to the menu..."
            return $null
        }
    } 

    # Create Log Analytics Workspace
    try {
        Write-Host "Creating Log Analytics Workspace [$logAnalyticsWorkspaceName] in Resource Group {$($selectedResourceGroup.ResourceGroupName)}... " -NoNewLine
        $script:entroLogWkspc = New-AzOperationalInsightsWorkspace -ResourceGroupName $selectedResourceGroup.ResourceGroupName -Name $logAnalyticsWorkspaceName -Location $selectedResourceGroup.Location -Sku "PerGB2018" -RetentionInDays 30 -Force

        Write-Host "Success" -ForegroundColor Green
        sleep 1
    } catch {
        Write-Host "Error creating Log Analytics Workspace: $($_.Exception.Message)" -ForegroundColor Red
        read-host "Press Enter to return to the menu..."
        return $null
    }
}

function Configure-SignInLogForwarding {
    Clear-Host
    # Check if Entro LAW has been selected/created
    if ($null -eq $script:entroLogWkspc) {
        Write-Host "No Entro LAW selected. Please select or create one..." -ForegroundColor Yellow
        try {
            CreateSelect-EntroLogAnalyticsWorkspace
        } catch {
            Write-Host ("Error selecting/creating Entro LAW: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
        if ($null -eq $script:entroLogWkspc) {
            Write-Host "There was an error when selecting/creating the Entro LAW. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }

    Write-Host "`nForwarding Sign-in logs to Entro Log Analytics Workspace..."
    $diagnosticSettingName = "EntroSecurityLogForwarding"
    
    <# Commenting this out for now and moving to REST API. The Az module just doesn't work no matter what I try. >:(
    try {
        Write-Host "Configuring diagnostic setting via Azure PowerShell... " -NoNewline

        # Define log categories
        $logSettings = [System.Collections.Generic.List[Hashtable]]::new()
            $logSettings.Add(@{ Category = "AuditLogs"; Enabled = $true })
            $logSettings.Add(@{ Category = "SignInLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "NonInteractiveUserSignInLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "ServicePrincipalSignInLogs"; Enabled = $true })
            $logSettings.Add(@{ Category = "ManagedIdentitySignInLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "ProvisioningLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "ADFSSignInLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "RiskyUsers"; Enabled = $false })
            $logSettings.Add(@{ Category = "UserRiskEvents"; Enabled = $false })
            $logSettings.Add(@{ Category = "NetworkAccessTrafficLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "RiskyServicePrincipals"; Enabled = $false })
            $logSettings.Add(@{ Category = "ServicePrincipalRiskEvents"; Enabled = $false })
            $logSettings.Add(@{ Category = "EnrichedOffice365AuditLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "MicrosoftGraphActivityLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "RemoteNetworkHealthLogs"; Enabled = $false })
            $logSettings.Add(@{ Category = "NetworkAccessAlerts"; Enabled = $false }
        )
        New-AzDiagnosticSetting -Name $diagnosticSettingName `
            -ResourceId "/providers/microsoft.aadiam/diagnosticSettings" `
            -WorkspaceId $script:entroLogWkspc.ResourceId `
            -Log $logSettings `
            -Metric @() `
            -ErrorAction Stop

        Write-Host "Success" -ForegroundColor Green
        Read-Host "Press Enter to return to menu..."
        return
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
        }
        Read-Host "Press Enter to return to menu..."
        return
    } #>
    
    try {
        Write-Host "Retrieving Azure Resource Manager token... " -NoNewline
        $accessToken = Get-AzAccessToken -ResourceTypeName Arm
        $mgmtToken = $accessToken.Token | ConvertFrom-SecureString -AsPlainText
        if (($mgmtToken -eq $null) -or ($mgmtToken -eq "")) {
            throw "Failed to retrieve management token"
        }
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to return to menu..."
        return
    }
    try {
        Write-Host "Configuring diagnostic setting via REST API... " -NoNewline
        
        $headers = @{
            'Authorization' = "Bearer $mgmtToken"
            'Content-Type' = 'application/json'
        }

        $body = @{
                properties = @{
                    workspaceId = $script:entroLogWkspc.ResourceId
                    logAnalyticsDestinationType = $null
                    metrics = @()
                    logs = @(
                        @{
                            category = "AuditLogs"
                            categoryGroup = $null
                            enabled = $true
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "SignInLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "NonInteractiveUserSignInLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "ServicePrincipalSignInLogs"
                            categoryGroup = $null
                            enabled = $true
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "ManagedIdentitySignInLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "ProvisioningLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "ADFSSignInLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "RiskyUsers"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "UserRiskEvents"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "NetworkAccessTrafficLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "RiskyServicePrincipals"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "ServicePrincipalRiskEvents"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "EnrichedOffice365AuditLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "MicrosoftGraphActivityLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "RemoteNetworkHealthLogs"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                        @{
                            category = "NetworkAccessAlerts"
                            categoryGroup = $null
                            enabled = $false
                            retentionPolicy = @{
                                days = 0
                                enabled = $false
                            }
                        }
                    )
                }
            } | ConvertTo-Json -Depth 10

        $apiVersion = "2017-04-01"
        $uri = "https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/$diagnosticSettingName`?api-version=$apiVersion"
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body
        Write-Host "Success" -ForegroundColor Green
        Read-Host "Press Enter to return to menu..."
        return
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.ErrorDetails.Message) {
            Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
        }
        Read-Host "Press Enter to return to menu..."
        return
    }
}

function Configure-KeyvaultsForEntro {
    Clear-Host
    # Check if Entro App Registration and Service Principal has been created/selected
    if ($null -eq $script:entroAppRegistration) {
        Write-Host "No Entro App selected. Please select or create one..." -ForegroundColor Yellow
        try {
            CreateSelect-EntroAppRegistration
        } catch {
            Write-Host ("Error selecting/creating Entro app: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
        if ($null -eq $script:entroAppRegistration) {
            Write-Host "There was an error when selecting/creating the Entro App. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }
    if (-not $script:entroServicePrincipal.Id -or -not $script:entroServicePrincipal.AppId -or $script:entroServicePrincipal.AppId -ne $script:entroAppRegistration.AppId) {
        Write-Host "Invalid or mismatched service principal. Attempting to retrieve service principal for AppId: $($script:entroAppRegistration.AppId)" -ForegroundColor Yellow
        try {
            $script:entroServicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($script:entroAppRegistration.AppId)'" 
            if (-not $script:entroServicePrincipal) {
                    Write-Host "No Enterprise Application found for AppId: $($script:entroAppRegistration.AppId)." -ForegroundColor Yellow
                    Read-Host "Press Enter to return to the menu..."
                    return $false
                }
        } catch {
            Write-Host ("Failed to retrieve Enterprise Application: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }
    
    # Retrive all the Keyvaults to configure
    $vaults = @()
    $vaults = Get-UserSelectedKeyVaults -customMsg "Select Azure Key Vaults to allow Entro to inventory"
    if ($vaults.Count -eq 0) {
        Write-Host "No Key Vaults selected. Cancelling operation." -ForegroundColor Red
        Read-Host "Press Enter to return to the menu..."
        return
    }
    # Let's get configuring those key vaults
    $subsThatNeedReaderRole = @()
    foreach ($vault in $vaults) {
        If ($vault.SubscriptionId -ne (Get-AzContext).Subscription.Id) {
            try {
                Set-AzContext -SubscriptionId $vault.SubscriptionId | Out-Null
            } catch {
                Write-Error-Message "Failed to switch to subscription $($vault.SubscriptionId): $($_.Exception.Message)"
                continue
            }
        }
        #Check vault for Key Vault policy style (RBAC vs Access Policies)
        if ($vault.EnableRbacAuthorization -eq $false){
            try {
                Write-Host "Giving Entro access permissions to key vault: $($vault.VaultName)... " -NoNewline
                Set-AzKeyVaultAccessPolicy `
                    -VaultName $vault.VaultName `
                    -ObjectId $script:entroServicePrincipal.Id `
                    -BypassObjectIdValidation `
                    -PermissionsToKeys @("get", "list", "decrypt", "unwrapKey") `
                    -PermissionsToSecrets @("get", "list") `
                    -PermissionsToCertificates @("get", "list", "getissuers", "listissuers")
                Write-Host "Success" -ForegroundColor Green
            } catch {
                Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        } else {
            try { 
                Write-Host "Checking Entro Key Vault Reader access to key vault: $($vault.VaultName)... " -NoNewline
                $roleAssignment = Get-AzRoleAssignment `
                    -ObjectId $script:entroServicePrincipal.Id `
                    -Scope $vault.ResourceId `
                    -RoleDefinitionName "Key Vault Reader"
                # Output based on whether the role is assigned
                if ($roleAssignment) {
                    Write-Host "Assigned" -ForegroundColor Green
                } else {
                    Write-Host "Not Assigned" -ForegroundColor Yellow
                   if (-not ($subsThatNeedReaderRole | Where-Object { $_.SubscriptionId -eq $vault.SubscriptionId })) {
                        $subsThatNeedReaderRole += [PSCustomObject]@{
                            Subscription = $vault.Subscription
                            SubscriptionId = $vault.SubscriptionId
                        }
                    }
                }
            } catch { 
                Write-Error-Message "Error checking role assignment: $($_.Exception.Message)" 
                continue
            }
    
        }
    }

    Write-Host "`nConfiguration complete for all Keyvaults." -ForegroundColor Cyan
    if ($subsThatNeedReaderRole.Count -gt 0) {
        Write-Host "`nThe following subscriptions have Key Vaults that use RBAC authorization and need the 'Key Vault Reader' role assigned to the Entro App:" -ForegroundColor Yellow
        $subsThatNeedReaderRole | ForEach-Object {
        Write-Host "$($_.Subscription) {$($_.SubscriptionId)}" -ForegroundColor Yellow
    }
}
    Read-Host "Press Enter to return to menu..."
}

function Configure-KeyvaultsActivityForEntro {
    Clear-Host
    # Check if Entro LAW has been selected/created
    if ($null -eq $script:entroLogWkspc) {
        Write-Host "No Entro LAW selected. Please select or create one..." -ForegroundColor Yellow
        try {
            CreateSelect-EntroLogAnalyticsWorkspace
        } catch {
            Write-Host ("Error selecting/creating Entro LAW: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
        if ($null -eq $script:entroLogWkspc) {
            Write-Host "There was an error when selecting/creating the Entro LAW. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to return to the menu..."
            return $false
        }
    }
    # Retrive all the Keyvaults to configure
    $vaults = @()
    $vaults = Get-UserSelectedKeyVaults -customMsg "Select Azure Key Vaults to allow Entro to monitor vault activity"
    if ($vaults.Count -eq 0) {
        Write-Host "No Key Vaults selected. Cancelling operation." -ForegroundColor Red
        Read-Host "Press Enter to return to the menu..."
        return
    }
    # Create log settings and metrics objects for setting up diagnostic settings
    $logSettings = @()
    $logSettings += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -CategoryGroup "audit"
    $logSettings += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -CategoryGroup "allLogs"
    $metricSettings = New-AzDiagnosticSettingMetricSettingsObject -Enabled $false -Category "AllMetrics"
    # Let's get configuring those key vaults
    foreach ($vault in $vaults) {
        If ($vault.SubscriptionId -ne (Get-AzContext).Subscription.Id) {
            try {
                Set-AzContext -SubscriptionId $vault.SubscriptionId | Out-Null
            } catch {
                Write-Error-Message "Failed to switch to subscription $($vault.SubscriptionId): $($_.Exception.Message)"
                continue
            }
        }
        try {
            Write-Host "Enabling Key Vault activity logs for key vault: $($vault.VaultName)... " -NoNewline
            # Remove existing diagnostic setting if it exists
            try {
                Remove-AzDiagnosticSetting -ResourceId $vault.ResourceId -Name "EntroAuditLogging" -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore if setting doesn't exist
            }
            # Create the diagnostic setting
            New-AzDiagnosticSetting -Name "EntroKVActivityLogs" `
                -ResourceId $vault.ResourceId `
                -WorkspaceId $script:entroLogWkspc.ResourceId `
                -Log $logSettings `
                -Metric $metricSettings `
                -LogAnalyticsDestinationType "AzureDiagnostics" | Out-Null                                 
            Write-Host "Success" -ForegroundColor Green
        } catch {
            Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }   

    }

    Write-Host "`nConfiguration complete for all Keyvaults." -ForegroundColor Cyan
    Read-Host "Press Enter to return to menu..."
}

function Delete-Entro {
    # User confirmation check
    $confirmation = Read-Host "`nType 'Remove Entro' to confirm that you want to remove all Entro components from Azure. *This action cannot be undone.*"

    if ($confirmation -cne "Remove Entro") {
        Write-Host "Cancelling deletion..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    Write-Notification-Message "`nBeginning Entro cleanup..."
    # Ensure a subscription context is set
    $context = Get-AzContext
    if (-not $context.Subscription) {
        $sub = (Get-AzSubscription | Select-Object -First 1).Id
        Set-AzContext -SubscriptionId $sub
    }
    # Get all management groups
    try {
        $managementGroups = Get-AzManagementGroup
    }
    catch {
        Write-Host "Error retrieving management groups: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    # Get all subscriptions in the tenant
    try {
        $subscriptions = Get-AzSubscription
    }
    catch {
        Write-Host "Error retrieving subscriptions: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    # Get all the Service Principals with "Entro" in the Name
    #`nWrite-Host "Searching for service principals containing 'Entro' in Tenant..." -ForegroundColor Cyan
    try {
        $servicePrincipals = Get-AzADServicePrincipal | Where-Object { $_.DisplayName -match "Entro" }
    } catch {
        Write-Host "Error retrieving service principals: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # Remove Role Assignments for Service Principals with "Entro" in the Name
    Write-Host "`nSearching for Role Assignments linked to Entro service principals..." -ForegroundColor Cyan
    # First search, the Management Groups
    Write-Host "Searching Management Groups for Entro Role Assignments..." -ForegroundColor Blue
    foreach ($mg in $managementGroups) {
        Write-Host "Searching in Management Group: $($mg.DisplayName) ($($mg.Name))" 

        # Remove Role Assignments for Service Principals with "Entro" in the Name
        try {
            foreach ($sp in $servicePrincipals) {
                $roleAssignments = Get-AzRoleAssignment -ObjectId $sp.Id -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)"
                foreach ($assignment in $roleAssignments) {
                    try {
                        Write-Host "Removing Role $($assignment.RoleDefinitionName) from $($sp.DisplayName)... " -NoNewline -ForegroundColor Yellow
                        Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -RoleDefinitionId $assignment.RoleDefinitionId -Scope $assignment.Scope *> $null
                        Write-Host "Success" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        } catch {
            Write-Host "Failed to get assignments: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    # Now the Subscriptions
    Write-Host "Searching Subscriptions for Entro Role Assignments..." -ForegroundColor Blue
    foreach ($sub in $subscriptions) {
        Write-Host "Searching in Subscription: $($sub.Name)..." 
        #Set-AzContext -SubscriptionId $sub.Id *> $null

        # Remove Role Assignments for Service Principals with "Entro" in the Name
        try {
            foreach ($sp in $servicePrincipals) {
                $roleAssignments = Get-AzRoleAssignment -ObjectId $sp.Id -Scope "/subscriptions/$($sub.Id)"
                foreach ($assignment in $roleAssignments) {
                    try {
                        Write-Host "Removing Role $($assignment.RoleDefinitionName) from $($sp.DisplayName)... " -NoNewline -ForegroundColor Yellow
                        Remove-AzRoleAssignment -ObjectId $assignment.ObjectId -RoleDefinitionId $assignment.RoleDefinitionId -Scope $assignment.Scope *> $null
                        Write-Host "Success" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        } catch {
            Write-Host "Failed to get assignments: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Now we can remove the custom roles themselves across Mgmt Groups and Subscriptions
    Write-Host "`nSearching for Custom Roles with Entro in the name..." -ForegroundColor Cyan
    # First the Management Groups
    Write-Host "Searching Management Groups for Custom Entro Roles..." -ForegroundColor Blue
    foreach ($mg in $managementGroups) {
        Write-Host "Searching in Management Group: $($mg.DisplayName) ($($mg.Name))"
        # Remove Custom Roles with "Entro" in the Name
        try {
            $roles = Get-AzRoleDefinition -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)" | Where-Object { $_.Name -match "Entro" }
            foreach ($role in $roles) {
                try{
                    Write-Host "Deleting Role: $($role.Name)... " -NoNewLine -ForegroundColor Yellow
                    Remove-AzRoleDefinition -Id $role.Id -Scope $role.AssignableScopes[0] -Force *> $null
                    Write-Host "Success" -ForegroundColor Green
                } catch {
                    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                }   
            }
        } catch {
            Write-Host "Error retriving roles in Management Group: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    # Now the Subscriptions
    Write-Host "Searching Subscriptions for Custom Entro Roles..." -ForegroundColor Blue
    foreach ($sub in $subscriptions) {
        Write-Host "Searching in Subscription: $($sub.Name) ($($sub.Id))"
        #Set-AzContext -SubscriptionId $sub.Id *> $null
        try {
            $roles = Get-AzRoleDefinition -Scope "/subscriptions/$($sub.Id)" | Where-Object { $_.Name -match "Entro" }
            foreach ($role in $roles) {
                try{
                    Write-Host "Deleting Role: $($role.Name)... " -NoNewLine -ForegroundColor Yellow
                    Remove-AzRoleDefinition -Id $role.Id -Scope $role.AssignableScopes[0] -Force *> $null
                    Write-Host "Success" -ForegroundColor Green
                } catch {
                    Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "Error deleting roles in Subscription: $($_.Exception.Message)" -ForegroundColor Red
        }
    } 

     # Remove Key Vaults Diagnostic Settings with "Entro" in the Name
     write-host "`nSearching for KeyVaults with Diagnostic Settings named 'Entro'..." -ForegroundColor Cyan
     foreach ($sub in $subscriptions) {
         try {
             Set-AzContext -SubscriptionId $sub.Id *> $null
         } catch {
             Write-Warning "Failed to set context for subscription $($sub.Name): $_"
             continue
         }
         Write-Host "Searching for KeyVaults in Subscription: $($sub.Name) ($($sub.Id))"
         try {
             # Get all Key Vaults in this subscription
             $keyVaults = Get-AzKeyVault
         } catch {
             Write-Warning "Failed to list Key Vaults in subscription $($sub.Name): $_"
             continue
         }
 
         foreach ($kv in $keyVaults) {
             $resourceId = $kv.ResourceId
 
             try {
                 # Get all diagnostic settings for this Key Vault
                 $diagSettings = Get-AzDiagnosticSetting -ResourceId $resourceId 
             } catch {
                 Write-Warning "Failed to get diagnostic settings for Key Vault '$($kv.VaultName)': $_"
                 continue
             }
 
             foreach ($setting in $diagSettings) {
                 if ($setting.Name -like "*Entro*") {
                     try {
                         Write-Host "Removing diagnostic setting '$($setting.Name)' from Key Vault '$($kv.VaultName)' in subscription '$($sub.Name)'... " -NoNewLine -ForegroundColor Yellow
                         Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $setting.Name
                         Write-Host "Success" -ForegroundColor Green
                     } catch {
                         Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                     }
                 }
             }
         }
     }
 
     # Remove Log Analytics Workspaces with "Entro" in the Name
    write-host "`nSearching for Log Analytics Workspaces with names containing 'Entro'..." -ForegroundColor Cyan
    foreach ($sub in $subscriptions) {
        Write-Host "Switching to Subscription: $($sub.Name) ($($sub.Id))" -ForegroundColor Blue
        Set-AzContext -SubscriptionId $sub.Id *> $null
        try {
            Write-Host "Searching for Log Analytics Workspaces containing 'Entro' in Subscription..."
            $workspaces = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -match "Entro" }

            foreach ($workspace in $workspaces) {
                Write-Host "Deleting Log Analytics Workspace: $($workspace.Name)" -ForegroundColor Yellow
                Remove-AzOperationalInsightsWorkspace -ResourceGroupName $workspace.ResourceGroupName -Name $workspace.Name -Force *> $null
            }
        } catch {
            Write-Host "Error deleting Log Analytics Workspaces in Subscription: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    # Clear the script variable storing the Entro LAW details
    $script:entroLogWkspc = $null

   # Remove Resource Groups with "Entro" in the Name
    write-host "`nSearching for Resource Groups with names containing 'Entro'..." -ForegroundColor Cyan
    foreach ($sub in $subscriptions) {
        Write-Host "Switching to Subscription: $($sub.Name) ($($sub.Id))" -ForegroundColor Blue
        Set-AzContext -SubscriptionId $sub.Id *> $null
        try {
            $resourceGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -match "Entro" }

            if ($resourceGroups) {
                foreach ($rg in $resourceGroups) {
                    try {
                        # Check if resource group is empty
                        $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
                        if ($resources) {
                            Write-Host "Skipping deletion: Resource group '$($rg.ResourceGroupName)' is not empty."
                            continue
                        }
                        Write-Host "Deleting resource group: $($rg.ResourceGroupName)..."
                        Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force  *> $null
                    }
                    catch {
                        Write-Error "Failed to delete resource group $($rg.ResourceGroupName): $_"
                    }
                }
            }
        }
        catch {
            Write-Error "Failed to retrieve resource groups: $_"
        }
    }
    
    # Remove App Registrations with "Entro" in the Name
    write-host "`nSearching App Registrations with names containing 'Entro'..." -ForegroundColor Cyan
    try {
        Write-Host "Searching for App Registrations containing 'Entro'..."
        $apps = Get-MgApplication -ConsistencyLevel eventual -Search '"DisplayName:Entro"' -All | Where-Object { $_.DisplayName -like "*Entro*" }
        foreach ($app in $apps) {
            Write-Host "Deleting App Registration: $($app.DisplayName) ($($app.AppId))" -ForegroundColor Yellow 
            Remove-MgApplication -ApplicationId $app.Id -Confirm:$false *> $null
        }
    } catch {
        Write-Host "Error deleting App Registrations: $($_.Exception.Message)" -ForegroundColor Red
    }
    $script:entroAppRegistration = $null
    $script:entroServicePrincipal = $null
    Write-Success-Message "`nEntro cleanup completed."
    Read-Host "Press Enter to return to the menu..."
}

function Exit-Script {
    try{
        Disconnect-AzAccount *> $null
        Disconnect-MgGraph *> $null
    }
    catch { }
    Clear-Host
    Write-Host "Exiting script. Shalom!" -ForegroundColor Green
    exit
}

#######################################
########   Helper Functions ###########
#######################################
function Show-SelectionMenu {
    param (
        [Parameter(Mandatory = $true)]
        [array]$DataObjects,  # Array of objects or simple types to display and select from
        [array]$MandatoryIds = @(),  # Array of row IDs that are always selected, no number for [de]selection, shown in DarkGray color
        [array]$InitialSelectionIds = @(),  # Array of row IDs that are initially selected but can be toggled
        [string[]]$Columns,  # Optional: Array of property names to display, in order
        [hashtable]$HeaderLabels = @{},  # Optional: Hashtable of property => friendly header label
        [string]$SortBy,  # Optional: Property name to sort by
        [ValidateSet('Ascending', 'Descending')]
        [string]$SortOrder = 'Ascending',  # Optional: Sort order (Ascending or Descending)
        [string]$UniqueKey = 'Id',  # Property used as unique key for selection; for simple types, uses the value itself
        [hashtable]$ColumnWidths = @{},  # Optional: Hashtable of column name => width (positive for left-align, negative for right)
        [int]$PageSize = 9,  # Number of items per page
        [string]$CustomMsg = "",  # Custom message/prompt for the menu
        [switch]$NoHeader,  # Optional: Suppress header display
        [switch]$SelectOne  # If present, only allow single selection (disables A/L options)
    )

    # Validate input
    if ($DataObjects.Count -eq 0) {
        Write-Host "No items available for selection."
        return @()
    }

    # Determine if data is simple types (non-objects) or objects
    # Fixed: More robust check for simple vs complex types
    $firstItem = $DataObjects[0]
    $isSimple = $false
    
    # Check if it's a simple type (string, number, boolean, etc.) rather than a complex object
    if ($firstItem -is [string] -or 
        $firstItem -is [int] -or 
        $firstItem -is [long] -or 
        $firstItem -is [double] -or 
        $firstItem -is [decimal] -or 
        $firstItem -is [bool] -or 
        $firstItem -is [char] -or
        $firstItem -is [byte] -or
        $firstItem -is [float] -or
        $firstItem -is [int16] -or
        $firstItem -is [int32] -or
        $firstItem -is [int64] -or
        $firstItem -is [uint16] -or
        $firstItem -is [uint32] -or
        $firstItem -is [uint64] -or
        $firstItem -is [single]) {
        $isSimple = $true
    } else {
        # For complex objects, check if they have properties
        try {
            $properties = $firstItem.PSObject.Properties
            if ($null -eq $properties -or $properties.Count -eq 0) {
                $isSimple = $true
            }
        } catch {
            # If we can't access PSObject.Properties, it's likely a simple type
            $isSimple = $true
        }
    }

    if ($isSimple) {
        $Columns = @('Value')
        # Force array output to handle single-element arrays correctly
        $DataObjects = @($DataObjects | ForEach-Object { [pscustomobject]@{ Value = $_; Id = $_ } })
        $UniqueKey = 'Id'
        $NoHeader = $true
    } elseif (-not $Columns) {
        $firstObj = $DataObjects[0]
        $Columns = $firstObj.PSObject.Properties.Name
        if (-not $Columns) {
            Write-Host "No properties found in input objects."
            return @()
        }
        if ($Columns.Count -eq 1) {
            $NoHeader = $true
        }
    }

    # Validate columns exist in objects (skip for simple types)
    if (-not $isSimple) {
        $firstObj = $DataObjects[0]
        foreach ($col in $Columns) {
            if (-not ($firstObj.PSObject.Properties.Name -contains $col)) {
                Write-Host "Column '$col' not found in input objects."
                return @()
            }
        }
    }

    # Sort data if SortBy is specified (only for objects)
    if ($SortBy -and -not $isSimple) {
        $sortParams = @{
            Property = $SortBy
        }
        if ($SortOrder -eq 'Descending') {
            $sortParams.Descending = $true
        }
        try {
            $DataObjects = $DataObjects | Sort-Object @sortParams
        } catch {
            Write-Host "Error sorting data by '$SortBy': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Prepare headers if not suppressed
    if (-not $NoHeader) {
        $headers = @()
        foreach ($col in $Columns) {
            $headers += $HeaderLabels[$col] ? $HeaderLabels[$col] : $col
        }
    } else {
        $headers = @()
    }

    # Compute column widths
    $computedWidths = @()
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $col = $Columns[$i]
        if ($ColumnWidths.ContainsKey($col)) {
            $computedWidths += $ColumnWidths[$col]
        } else {
            $maxLen = if ($headers -and $i -lt $headers.Count) { $headers[$i].Length } else { 0 }
            foreach ($obj in $DataObjects) {
                $val = if ($isSimple -and $col -eq 'Value') { $obj } else { $obj.$col }
                $valLen = ($val | Out-String).Trim().Length
                if ($valLen -gt $maxLen) { $maxLen = $valLen }
            }
            $computedWidths += -([math]::Max($maxLen, 5) + 2)
        }
    }

    # Selection column width (for combined Marker and No.)
    $selectionColumnWidth = -8  # Accounts for [*] (3 chars) + up to 2 digits + 1 space

    # Build format string for display (single selection column)
    $formatString = "{0,$selectionColumnWidth}"
    for ($i = 0; $i -lt $computedWidths.Count; $i++) {
        $formatString += " {$($i+1),$($computedWidths[$i])}"
    }

    # Separator line
    $sepLength = [math]::Abs($selectionColumnWidth) + ($computedWidths | ForEach-Object { [math]::Abs($_) } | Measure-Object -Sum).Sum + (2 * $Columns.Count) + 2
    $separator = "-" * $sepLength

    # Selection tracking
    $selectedItems = @{}

    # Add mandatory items to selected
    foreach ($id in $MandatoryIds) {
        $mandatoryItem = $DataObjects | Where-Object {
            $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
            $key -eq $id
        } | Select-Object -First 1
        if ($mandatoryItem) {
            $uniqueVal = if ($isSimple) { $mandatoryItem.Value } else { $mandatoryItem.$UniqueKey }
            $selectedItems[$uniqueVal] = $mandatoryItem
        } else {
            Write-Host "Mandatory ID '$id' not found in DataObjects." -ForegroundColor Yellow
        }
    }

    # Add initial selection items (silently skip if not found; only first valid ID if SelectOne)
    if ($InitialSelectionIds.Count -gt 0) {
        if ($SelectOne) {
            # Select only the first valid ID
            foreach ($id in $InitialSelectionIds) {
                $initialItem = $DataObjects | Where-Object {
                    $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                    $key -eq $id
                } | Select-Object -First 1
                if ($initialItem) {
                    $uniqueVal = if ($isSimple) { $initialItem.Value } else { $initialItem.$UniqueKey }
                    if (-not $selectedItems.ContainsKey($uniqueVal)) {
                        $selectedItems[$uniqueVal] = $initialItem
                        break  # Stop after the first valid ID
                    }
                }
            }
        } else {
            # Select all valid IDs
            foreach ($id in $InitialSelectionIds) {
                $initialItem = $DataObjects | Where-Object {
                    $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                    $key -eq $id
                } | Select-Object -First 1
                if ($initialItem) {
                    $uniqueVal = if ($isSimple) { $initialItem.Value } else { $initialItem.$UniqueKey }
                    if (-not $selectedItems.ContainsKey($uniqueVal)) {
                        $selectedItems[$uniqueVal] = $initialItem
                    }
                }
            }
        }
    }

    # Initial allSelected for non-mandatory
    $nonMandatory = $DataObjects | Where-Object {
        $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
        $key -notin $MandatoryIds
    }
    $selectedNonMandatoryCount = $nonMandatory | Where-Object {
        $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
        $selectedItems.ContainsKey($key)
    } | Measure-Object | Select-Object -ExpandProperty Count
    $allSelected = $selectedNonMandatoryCount -eq ($nonMandatory | Measure-Object | Select-Object -ExpandProperty Count)

    $totalItems = $DataObjects.Count
    $currentPage = 0

    :doLoop do {
        Clear-Host

        # Display custom message or default
        if ($CustomMsg -ne "") {
            Write-Host "`n$CustomMsg" -ForegroundColor Cyan
        } else {
            Write-Host "`nSelect item(s)" -ForegroundColor Cyan
        }

        # Instructions
        if ($SelectOne) {
            Write-Host "`nSelect one item only. Selecting the same item again will deselect it."
            Write-Host "Use numbers to select/deselect, 'N' for next page, 'P' for previous page, 'D' when done."
        } else {
            Write-Host "`nUse numbers to select/deselect, 'A' to toggle all on this page, 'L' to toggle all items in all pages, 'N' for next page, 'P' for previous page, 'D' when done."
        }

        Write-Host "`n(Page $($currentPage + 1)/$([math]::Ceiling($totalItems / $PageSize)))"
        Write-Host ""

        # Display headers if not suppressed
        if (-not $NoHeader -and $headers.Count -gt 0) {
            $headerArgs = @("No.") + $headers
            try {
                Write-Host ($formatString -f $headerArgs)
                Write-Host $separator
            } catch {
                Write-Host ("Error displaying headers: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Write-Host "Format string: $formatString" -ForegroundColor Yellow
                Write-Host "Header args: $($headerArgs -join ', ')" -ForegroundColor Yellow
                Read-Host "Press Enter to continue..."
                return @()
            }
        }

        # Display paginated items
        $startIndex = $currentPage * $PageSize
        $endIndex = [math]::Min($startIndex + $PageSize, $totalItems)
        $allSelectedOnPage = $true
        $selectableIndex = 1
        $selectableMapping = @{}
        for ($i = $startIndex; $i -lt $endIndex; $i++) {
            $item = $DataObjects[$i]
            $uniqueVal = if ($isSimple) { $item.Value } else { $item.$UniqueKey }
            $isMandatory = $uniqueVal -in $MandatoryIds
            $isSelected = $selectedItems.ContainsKey($uniqueVal)
            $marker = if ($isSelected) { "*" } else { " " }
            $indexDisplay = if ($isMandatory) { "   " } else { $selectableIndex.ToString().PadLeft(2) }
            $selectionDisplay = "[$marker]$indexDisplay"  # Combine Marker and No.
            $rowArgs = @($selectionDisplay)
            foreach ($col in $Columns) {
                $rowArgs += if ($isSimple -and $col -eq 'Value') { $item } else { $item.$col }
            }
            if ($isMandatory) {
                Write-Host ($formatString -f $rowArgs) -ForegroundColor DarkGray
            } else {
                Write-Host ($formatString -f $rowArgs)
            }
            if (-not $isMandatory -and -not $isSelected) { $allSelectedOnPage = $false }
            if (-not $isMandatory) {
                $selectableMapping[$selectableIndex] = $i
                $selectableIndex++
            }
        }

        # Read user input
        $input = Read-Host "`nEnter your choice: "

        switch -Regex ($input.ToUpper()) {
            "^[1-9][0-9]*$" {
                $selectedSelectableIndex = [int]$input
                if ($selectedSelectableIndex -ge 1 -and $selectedSelectableIndex -lt $selectableIndex) {
                    $selectedIndex = $selectableMapping[$selectedSelectableIndex]
                    $selectedItem = $DataObjects[$selectedIndex]
                    $uniqueVal = if ($isSimple) { $selectedItem.Value } else { $selectedItem.$UniqueKey }
                    if ($SelectOne) {
                        if ($selectedItems.ContainsKey($uniqueVal)) {
                            # Deselect if already selected
                            $selectedItems.Remove($uniqueVal)
                            # Re-add mandatory items
                            foreach ($id in $MandatoryIds) {
                                $mandatoryItem = $DataObjects | Where-Object {
                                    $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                                    $key -eq $id
                                } | Select-Object -First 1
                                if ($mandatoryItem) {
                                    $uniqueValM = if ($isSimple) { $mandatoryItem.Value } else { $mandatoryItem.$UniqueKey }
                                    $selectedItems[$uniqueValM] = $mandatoryItem
                                }
                            }
                        } else {
                            # Clear non-mandatory selections and select new item
                            $selectedItems.Clear()
                            # Re-add mandatory items
                            foreach ($id in $MandatoryIds) {
                                $mandatoryItem = $DataObjects | Where-Object {
                                    $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                                    $key -eq $id
                                } | Select-Object -First 1
                                if ($mandatoryItem) {
                                    $uniqueValM = if ($isSimple) { $mandatoryItem.Value } else { $mandatoryItem.$UniqueKey }
                                    $selectedItems[$uniqueValM] = $mandatoryItem
                                }
                            }
                            $selectedItems[$uniqueVal] = $selectedItem
                        }
                    } else {
                        if ($selectedItems.ContainsKey($uniqueVal)) {
                            $selectedItems.Remove($uniqueVal)
                        } else {
                            $selectedItems[$uniqueVal] = $selectedItem
                        }
                    }
                    # Update allSelected
                    $selectedNonMandatoryCount = $nonMandatory | Where-Object {
                        $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                        $selectedItems.ContainsKey($key)
                    } | Measure-Object | Select-Object -ExpandProperty Count
                    $allSelected = $selectedNonMandatoryCount -eq ($nonMandatory | Measure-Object | Select-Object -ExpandProperty Count)
                }
            }
            "A" {
                if (-not $SelectOne) {
                    for ($k = 1; $k -lt $selectableIndex; $k++) {
                        $i = $selectableMapping[$k]
                        $item = $DataObjects[$i]
                        $uniqueVal = if ($isSimple) { $item.Value } else { $item.$UniqueKey }
                        if ($allSelectedOnPage) {
                            $selectedItems.Remove($uniqueVal)
                        } else {
                            $selectedItems[$uniqueVal] = $item
                        }
                    }
                    # Update allSelected
                    $selectedNonMandatoryCount = $nonMandatory | Where-Object {
                        $key = if ($isSimple) { $_.Value } else { $_.$UniqueKey }
                        $selectedItems.ContainsKey($key)
                    } | Measure-Object | Select-Object -ExpandProperty Count
                    $allSelected = $selectedNonMandatoryCount -eq ($nonMandatory | Measure-Object | Select-Object -ExpandProperty Count)
                }
            }
            "L" {
                if (-not $SelectOne) {
                    if ($allSelected) {
                        foreach ($item in $nonMandatory) {
                            $uniqueVal = if ($isSimple) { $item.Value } else { $item.$UniqueKey }
                            $selectedItems.Remove($uniqueVal)
                        }
                        $allSelected = $false
                    } else {
                        foreach ($item in $nonMandatory) {
                            $uniqueVal = if ($isSimple) { $item.Value } else { $item.$UniqueKey }
                            $selectedItems[$uniqueVal] = $item
                        }
                        $allSelected = $true
                    }
                }
            }
            "N" {
                if ($endIndex -lt $totalItems) {
                    $currentPage++
                }
            }
            "P" {
                if ($currentPage -gt 0) {
                    $currentPage--
                }
            }
            "D" {
                break doLoop
            }
            default {
                Write-Host "Invalid input. Please try again." -ForegroundColor Red
            }
        }
    } while ($true)

    # Return selected items in original structure
    if ($selectedItems.Count -eq 0) {
        Write-Host "No items selected."
        return @()
    }

    $selectedValues = $selectedItems.Values
    if ($isSimple) {
        return $selectedValues | ForEach-Object { $_.Value }
    } else {
        return $selectedValues
    }
}

function Write-ColoredText {
    param(
        [string]$Text,
        [string]$ForegroundColor,
        [string]$BackgroundColor = 'Black'
    )
    Write-Host $Text -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline
}
function Write-Error-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message,
        [bool]$throwError = $false
    )
    Write-Host $message -ForegroundColor black -BackgroundColor red -NoNewline
    Write-Host ""
    if ($throwError) {
        throw [EntroException]::new($message)
    }
}

function Write-Success-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    Write-Host $message -ForegroundColor black -BackgroundColor green -NoNewline
    Write-Host ""
}

function Write-Debug-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    Write-Host $message -ForegroundColor blue -BackgroundColor black -NoNewline
    Write-Host ""
}

function Write-Notification-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message
    )
    Write-Host $message -ForegroundColor black -BackgroundColor yellow -NoNewline
    Write-Host ""
}

function CommandExists {
    param (
        [string]$command
    )
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

function Get-AzureLocation {
    param (
        [int]$PageSize = 9,  # Number of locations displayed per page
        [string]$customMsg = ""  # Custom message for selection prompt (defaults to blank)
    )

    # Retrieve available locations
    try {
        Write-Host "Retrieving available Azure locations..."
        $locations = Get-AzLocation
    } catch {
        Write-Host "Error retrieving Azure locations: $($_.Exception.Message)" -ForegroundColor Red
        return @()  # Return an empty array on error
    }

    # Filter to only physical locations
    $physicalLocations = $locations | Where-Object { $_.RegionType -eq 'Physical' }

    # Filter out EUAP regions
    $nonEuapLocations = $physicalLocations | Where-Object { $_.DisplayName -notlike '*EUAP*' }

    # Separate US locations and sort them alphabetically by DisplayName
    $usLocations = $nonEuapLocations | Where-Object { $_.GeographyGroup -eq "US" } | Sort-Object -Property DisplayName

    # Sort non-US locations: first by GeographyGroup, then by DisplayName
    $nonUSLocations = $nonEuapLocations | Where-Object { $_.GeographyGroup -ne "US" } | Sort-Object -Property @{Expression = {$_.GeographyGroup}}, @{Expression = {$_.DisplayName}}

    # Combine sorted lists
    $sortedLocations = $usLocations + $nonUSLocations

    # Convert locations to an array of objects
    $azureLocations = @()
    foreach ($loc in $sortedLocations) {
        $azureLocations += [PSCustomObject]@{
            Location        = $loc.Location
            DisplayName     = $loc.DisplayName
            PhysicalLocation = $loc.PhysicalLocation
            GeographyGroup  = $loc.GeographyGroup
        }
    }
    # Show selection menu
    $selectedLocation = Show-SelectionMenu `
        -DataObjects $azureLocations `
        -Columns @('Location', 'DisplayName', 'PhysicalLocation', 'GeographyGroup') `
        -HeaderLabels @{ DisplayName = "Display Name"; PhysicalLocation = "Physical Location"; GeographyGroup = "Geographic Region" } `
        -UniqueKey 'Location' `
        -CustomMsg ($customMsg -ne "" ? $customMsg : "Select an Azure Location for the Entro LAW") `
        -SelectOne

    # Return an empty array if no location was selected, otherwise return the selected location
    if ($selectedLocation) {
        return $selectedLocation
    } else {
        return @()
    }
}

function Get-ResourceGroup {
    param (
        [string]$customMsg = "Select a Resource Group (Leave blank to create a new one)"  # Custom selection message
    )

    # Retrieve available resource groups
    try {
        Write-Host "Retrieving available Azure resource groups..."
        $resourceGroups = Get-AzResourceGroup
    } catch {
        Write-Host "Error retrieving resource groups: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return @()
    }

    # Get the selected resource group
    $selectedResourceGroup = Show-SelectionMenu `
        -DataObjects $resourceGroups `
        -Columns @('ResourceGroupName', 'Location') `
        -HeaderLabels @{ ResourceGroupName = "Resource Group Name"; Location = "Location" } `
        -UniqueKey 'ResourceGroupName' `
        -CustomMsg $customMsg `
        -SelectOne

    # Return an empty array if no resource group was selected (indicating new RG creation)
    if ($selectedResourceGroup) {
        return $selectedResourceGroup
    } else {
        return @()
    }
}

function Get-UserSelectedLAW {
    param (
        [int]$PageSize = 9,
        [switch]$SelectOne, # Optional switch to allow only one selection
        [string]$customMsg = ""
    )
    
    if (-not $script:subscriptionsExactList){
        # No exact subscriptions list so need to retrieve all subscriptions
        try {
            $subscriptions = Get-AzSubscription
        }
        catch {
            Write-Host "Error retrieving subscriptions: $($_.Exception.Message)" -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return @()
        }
        
    } else {
        try {
            # Use the exact subscriptions list and get the subscriptions objects
            $subscriptions = Get-AzSubscription | Where-Object { $_.SubscriptionId -in $script:subscriptionsExactList }
        }
        catch {
            Write-Host "Error retrieving subscriptions: $($_.Exception.Message)" -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return @()
        }
        
    }

    if (-not $subscriptions) {
        Write-Host "No subscriptions found."
        return @()
    }

    # Retrieve all Log Analytics Workspaces containing "Entro" in the name
    Write-Host "Retrieving Log Analytics Workspaces from all subscriptions..."
    $allLAWs = @()
    foreach ($subscription in $subscriptions) {
        Set-AzContext -SubscriptionId $subscription.SubscriptionId | Out-Null
        $workspaces = Get-AzOperationalInsightsWorkspace | 
            Where-Object { $_.Name -like "*Entro*" } <# | 
            Select-Object Name, ResourceGroupName, Location #>
        foreach ($workspace in $workspaces) {
            $allLAWs += [PSCustomObject]@{
                ResourceGroupName = $workspace.ResourceGroupName
                Name = $workspace.Name
                Location = $workspace.Location
                CustomerId = $workspace.CustomerId
                Sku = $workspace.Sku
                SubscriptionName = $subscription.Name
                SubscriptionID = $subscription.Id
                Tags = $workspace.Tags
                ProvisioningState = $workspace.ProvisioningState
                ResourceId = $workspace.ResourceId
            }
        }
    }

    # If no workspaces are found, return empty array immediately
    if (-not $allLAWs) {
        Write-Host "No Log Analytics Workspaces with 'Entro' in the name found."
        return @()
    }

    $selectedLAWs = @{}
    $totalLAWs = $allLAWs.Count
    $currentPage = 0
    $allSelected = $false

    :doLoop do {
        Clear-Host
        if ($customMsg -eq "") {
            Write-Host "`nSelect Log Analytics Workspace(s)" -ForegroundColor Cyan
        } else {
            Write-Host "`n$customMsg" -ForegroundColor Cyan
        }
        if ($SelectOne) {
            Write-Host "`nSelect one Workspace only. Choosing another will deselect the previous one."
        } else {
            Write-Host "`nUse numbers to select/deselect, 'A' to toggle all on this page, 'L' to toggle all Workspaces, 'N' for next page, 'P' for previous page, 'D' to done"
        }
        Write-Host "`n(Page $($currentPage + 1)/$([math]::Ceiling($totalLAWs / $PageSize)))"
        Write-Host ""
        # Display header
        Write-Host (" {0,-8} {1,-30} {2,-40} {3,-20}" -f "No.", "Workspace Name", "Subscription", "Location")
        Write-Host ("-" * 100)
        # Display paginated Workspaces
        $startIndex = $currentPage * $PageSize
        $endIndex = [math]::Min($startIndex + $PageSize, $totalLAWs)
        $allSelectedOnPage = $true
        for ($i = $startIndex; $i -lt $endIndex; $i++) {
            $workspace = $allLAWs[$i]
            $indexDisplay = ($i % $PageSize) + 1
            $isSelected = $selectedLAWs.ContainsKey($workspace.ResourceId)
            $marker = if ($isSelected) { "*" } else { " " }
            Write-Host ("[$marker] {0,-5} {1,-30} {2,-40} {3,-20}" -f $indexDisplay, $workspace.Name, $workspace.SubscriptionName, $workspace.Location)
            if (-not $isSelected) { $allSelectedOnPage = $false }
        }
        # Read user input
        if ($SelectOne) {
            $input = Read-Host "`nEnter number to select a Workspace, 'N/P' for navigation, 'D' to finish"
        } else {
            $input = Read-Host "`nEnter number to select/deselect, 'A' to toggle all on this page, 'L' to toggle all, 'N/P' for navigation, 'D' to finish"
        }
        switch -Regex ($input) {
            "^[1-9]$" {
                $selectedIndex = ($input - 1) + ($currentPage * $PageSize)
                if ($selectedIndex -lt $totalLAWs) {
                    $selectedLAW = $allLAWs[$selectedIndex]
                    if ($SelectOne) {
                        $selectedLAWs.Clear()
                        $selectedLAWs[$selectedLAW.ResourceId] = $selectedLAW
                    } else {
                        if ($selectedLAWs.ContainsKey($selectedLAW.ResourceId)) {
                            $selectedLAWs.Remove($selectedLAW.ResourceId)
                        } else {
                            $selectedLAWs[$selectedLAW.ResourceId] = $selectedLAW
                        }
                    }
                }
            }
            "A|a" {
                if (-not $SelectOne) {
                    for ($i = $startIndex; $i -lt $endIndex; $i++) {
                        $law = $allLAWs[$i]
                        if ($allSelectedOnPage) {
                            $selectedLAWs.Remove($law.ResourceId)
                        } else {
                            $selectedLAWs[$law.ResourceId] = $law
                        }
                    }
                }
            }
            "L|l" {
                if (-not $SelectOne) {
                    if ($allSelected) {
                        $selectedLAWs.Clear()
                        $allSelected = $false
                    } else {
                        foreach ($law in $allLAWs) {
                            $selectedLAWs[$law.ResourceId] = $law
                        }
                        $allSelected = $true
                    }
                }
            }
            "N|n" {
                if ($endIndex -lt $totalLAWs) {
                    $currentPage++
                }
            }
            "P|p" {
                if ($currentPage -gt 0) {
                    $currentPage--
                }
            }
            "D|d" {
                break doLoop
            }
            default {
                Write-Host "Invalid input. Please enter a valid number, 'N', 'P', or 'D'."
            }
        }
    } while ($true)

    if (-not $selectedLAWs -or $selectedLAWs.Count -eq 0) {
        Write-Host "No Workspaces were selected."
        return @()
    }

    # Filter $allLAWs based on user selections
    $allSelectedLAWs = @()
    $allSelectedLAWs = $allLAWs | Where-Object { $_.ResourceId -in $selectedLAWs.Keys }

    return ,$allSelectedLAWs
}

<# function Get-UserSelectedResourceGroup {
    param (
        [string]$customMsg = ""  # Custom message for selection prompt (defaults to blank)
    )

    # Retrieve available resource groups
    try {
        Write-Host "Retrieving available Azure resource groups..."
        $resourceGroups = Get-AzResourceGroup
    } catch {
        Write-Host "Error retrieving resource groups: $($_.Exception.Message)" -ForegroundColor Red
        return @()  # Return an empty array on error
    }

    # Ensure there are resource groups available
    if (-not $resourceGroups) {
        Write-Host "No resource groups found in the current Azure subscription." -ForegroundColor Red
        return @()
    }

    # Convert resource groups to an array of objects
    $resourceGroupList = @()
    foreach ($rg in $resourceGroups) {
        $resourceGroupList += @{
            Name     = $rg.ResourceGroupName
            Location = $rg.Location
            Id       = $rg.ResourceId
            Selected = $false  # Track selection state
        }
    }

    $totalResourceGroups = $resourceGroupList.Count
    $currentPage = 0

    :doLoop do {
        Clear-Host

        # Display custom message or default prompt
        if ($customMsg -ne "") {
            Write-Host "`n$customMsg" -ForegroundColor Cyan
        } else {
            Write-Host "`nSelect a Resource Group" -ForegroundColor Cyan
        }

        Write-Host "Use numbers to select, 'N' for next page, 'P' for previous page, 'D' when done."
        Write-Host "`n(Page $($currentPage + 1)/$([math]::Ceiling($totalResourceGroups / $PageSize)))"
        Write-Host ""

        # Display header
        Write-Host (" {0,-5} {1,-40} {2,-20}" -f "", "Resource Group Name", "Location")
        Write-Host ("-" * 60)

        # Display paginated resource groups with selection indicator
        $startIndex = $currentPage * $PageSize
        $endIndex = [math]::Min($startIndex + $PageSize, $totalResourceGroups)

        for ($i = $startIndex; $i -lt $endIndex; $i++) {
            $resourceGroup = $resourceGroupList[$i]
            $indexDisplay = ($i % $PageSize) + 1
            $marker = if ($resourceGroup.Selected) { "*" } else { " " }  # Selection indicator
            Write-Host ("[{0}] {1,-2} {2,-40} {3,-20}" -f $marker, $indexDisplay, $resourceGroup.Name, $resourceGroup.Location)
        }

        # Read user input
        $input = Read-Host "Enter a number to select, 'N/P' to navigate, 'D' when done"

        switch -Regex ($input) {
            "^[1-9]$" {
                $selectedIndex = ($input - 1) + ($currentPage * $PageSize)
                if ($selectedIndex -lt $totalResourceGroups) {
                    # Clear all selections
                    foreach ($rg in $resourceGroupList) { $rg.Selected = $false }
                    
                    # Select the new resource group
                    $resourceGroupList[$selectedIndex].Selected = $true
                }
            }
            "N|n" {
                if ($endIndex -lt $totalResourceGroups) {
                    $currentPage++
                }
            }
            "P|p" {
                if ($currentPage -gt 0) {
                    $currentPage--
                }
            }
            "D|d" {
                break doLoop  # Exit the selection loop
            }
            default {
                Write-Host "Invalid input. Please enter a valid number, 'N', 'P', or 'D' when done." -ForegroundColor Red
            }
        }
    } while ($true)

    # Get the selected resource group
    $selectedResourceGroup = $resourceGroupList | Where-Object { $_.Selected } | Select-Object -First 1

    # Return an empty array if no resource group was selected, otherwise return the selected resource group
    if ($selectedResourceGroup) {
        return @($selectedResourceGroup)
    } else {
        return @()
    }
}#>

function Get-UserSelectedKeyVaults {
    param (
        [switch]$SelectOne,  # Optional switch to allow only one selection
        [string]$customMsg = "Select Azure Key Vault(s)"
    )
    Clear-Host
    # Get all subscriptions in the tenant
    try {
        $subscriptions = Get-AzSubscription
        $totalSubs = $subscriptions.Count
    }
    catch {
        Write-Error "Failed to get Azure subscriptions: $($_.Exception.Message)"
        return
    }
    $currentSub = 0 
    
    # Honor subscrioptionsExactList and subscriptionsToExclude if set
    if ($script:subscriptionsExactList) {
        try {
            $subscriptions = Get-AzSubscription | Where-Object { $_.SubscriptionId -in $script:subscriptionsExactList }
        } catch {
            Write-Error "Failed to get Azure subscriptions: $($_.Exception.Message)"
            sleep 1
            return @()
        }
    } else {
        try {
            $subscriptions = Get-AzSubscription
            $totalSubs = $subscriptions.Count
        } catch {
            Write-Error "Failed to get Azure subscriptions: $($_.Exception.Message)"
            sleep 1
            return @()
        }
    }
    if ($script:subscriptionsToExclude) {
        $subscriptions = $subscriptions | Where-Object { $_.SubscriptionId -notin $script:subscriptionsToExclude }
    }
    # Warn and exit if no subscriptions found
    if (-not $subscriptions) {
        Write-Host "No subscriptions found."
        return @() 
    }
    Clear-Host
    $currentSub = 0
    $allKeyVaults = @()
    # Retrieve all Keyvaults across found subscriptions
    foreach ($subscription in $subscriptions) {
        # Check if user pressed 'Q' to skip remaining subscriptions
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
                Write-Host "`nUser cancelled. Skipping remaining subscriptions..." -ForegroundColor Yellow
                break
            }
        }

        $currentSub++
        # Update progress bar
        $progressParams = @{
            Activity = "Retreiving all Key Vaults"
            Status = "Processing subscription: $($subscription.Name) (Press 'Q' to skip remaining)"
            PercentComplete = ($currentSub / $totalSubs) * 100
            CurrentOperation = "Subscription $currentSub of $totalSubs"
        }
        Write-Progress @progressParams
        try {
            # Set context
            Set-AzContext -SubscriptionId $subscription.Id | Out-Null
            $keyVaults = Get-AzKeyVault
            foreach ($keyVault in $keyVaults) {
                try {
                    $vault = Get-AzKeyVault -VaultName $keyVault.VaultName
                    $allKeyVaults += [PSCustomObject]@{
                        VaultName = $vault.VaultName
                        Subscription = $subscription.Name
                        SubscriptionID = $subscription.Id
                        ResourceGroupName = $vault.ResourceGroupName
                        Location = $vault.Location
                        ResourceID = $vault.ResourceID
                        EnableRbacAuthorization = $vault.EnableRbacAuthorization
                    }
                }
                catch {
                    continue
                }
            
            }
        }
        catch {
            continue
        }
    }
    # Clear the progress bar
    Write-Progress -Activity "Retreiving all Key Vaults" -Completed
    if (-not $allKeyVaults) {
        Write-Host "No Key Vaults found."
        sleep 1
        return @() 
    }
    $selectedKeyVaults = @{}
    $selectedKeyVaults = Show-SelectionMenu `
        -DataObjects $allKeyVaults `
        -UniqueKey 'ResourceID' `
        -SelectOne:$SelectOne `
        -CustomMsg $customMsg `
        -Columns @("VaultName", "Subscription", "Location")
    # If nothing is selected, return an empty array
    if (-not $selectedKeyVaults -or $selectedKeyVaults.Count -eq 0) {
        Write-Host "No Key Vaults were selected."
        sleep 1
        return @()  # Explicitly return an empty array
    }
    # Return the selected list
    return $selectedKeyVaults
}

function Get-UserSelectedSubscriptions {
    param (
        [switch]$SelectOne,  # Optional switch to allow only one selection
        [string]$customMsg = "",
        [switch]$includeMgmtGrps,  # Optional switch to include Management Groups in selection list
        [switch]$sel, # Optional switch to indicate set $script:subsciptionsExactList variable
        [switch]$ste # Optional switch to indicate set $script:subscriptionsToExclude variable
    )
    # Ensure a subscription context is set
    try {
        $context = Get-AzContext
        if (-not $context.Subscription) {
            $sub = (Get-AzSubscription | Select-Object -First 1).Id
            Set-AzContext -SubscriptionId $sub
        }
    }
    catch {
        Write-Host "Unable to retrieve Azure context." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return @()  # Return an empty array to prevent errors
    }

    # Retrieve all subscriptions
    try {
        Write-Host "Retrieving details of all Azure subscriptions..."
        $allSubscriptions = Get-AzSubscription | Select-Object SubscriptionId, Name | Sort-Object Name | ForEach-Object {
            [PSCustomObject]@{
                Type = "Subscription"
                Id = $_.SubscriptionId
                Name = $_.Name
                }
        }      
    }
    catch {
        Write-Host "No subscriptions found. Please ensure you have access to at least one subscription." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return @()  # Return an empty array to prevent errors
    }

    if ($ste -or $sel) {
        # If these are specified, ignore any exact list or exclusions and use all subscriptions
        $subscriptions = $allSubscriptions
    } else {
        # If an exact list of Subscriptions is provided, make sure we honor those as the only Subscriptions to show
        if ($script:subscriptionsExactList.Count -gt 0) {
            $subscriptions = $allSubscriptions | Where-Object { $_.Id -in $script:subscriptionsExactList }
        } else {
            $subscriptions = $allSubscriptions
        }

        # Exclude specified subscriptions
        if ($script:subscriptionsToExclude.Count -gt 0) {
            $subscriptions = $subscriptions | Where-Object { $_.Id -notin $script:subscriptionsToExclude }
        }
    }

    if (-not $subscriptions) {
        Write-Host "No subscriptions found. Please ensure you have access to at least one subscription." -ForegroundColor Red
        Read-Host "Press Enter to continue..."
        return @()  # Return an empty array to prevent errors
    }

    if ($includeMgmtGrps -and ($script:subscriptionsExactList.Count -eq 0)) {
        # Retrieve all Management Groups if requested and if an exact subscriptions list is not populated
        try {
            $allMgmtGrps = Get-AzManagementGroup | Sort-Object DisplayName | ForEach-Object {
                # Extract the last part of the ID
                $lastPartOfId = ($_.Id -split '/')[-1]

                # Compare with TenantId looking for Root Mgmt Group
            if ($lastPartOfId -eq $_.TenantId) {
                    # Tenant Root Group
                    [PSCustomObject]@{
                        Type         = "TenantRootMgmtGroup"
                        Id           = $_.Name
                        Name         = $_.DisplayName
                    }
                }else { 
                    # Not Tenant Root Group
                    [PSCustomObject]@{
                        Type         = "ManagementGroup"
                        Id           = $_.Name
                        Name         = $_.DisplayName
                        IsRootTenant = $isRootTenant
                    }
                }
            }   
        }
        catch {
            Write-Host "Unable to retrieve Management Groups." -ForegroundColor Red
            Read-Host "Press Enter to continue..."
            return @()  # Return an empty array to prevent errors
        }
        $allMgmtGrps = @($allMgmtGrps)
        $rootMG = $allMgmtGrps | Where-Object { $_.Type -eq "TenantRootMgmtGroup" }
        $nonRootMGs = $allMgmtGrps | Where-Object { $_.Type -ne "TenantRootMgmtGroup" } | Sort-Object DisplayName
        $subscriptions = @($subscriptions)
        $subsList = @()
        $subsList +=  @($rootMG)
        $subsList +=  @($nonRootMGs)
        $subsList +=  @($subscriptions)
    } else {
        $subscriptions = @($subscriptions)
        $subsList = $subscriptions
    }
    
    if ($ste) {
        $selectedSubscriptions = Show-SelectionMenu -DataObjects $subsList -SelectOne:$SelectOne -CustomMsg $customMsg -InitialSelectionIds $script:subscriptionsToExclude -Columns @("Name", "Id", "Type")
    } else {
        $selectedSubscriptions = Show-SelectionMenu -DataObjects $subsList -SelectOne:$SelectOne -CustomMsg $customMsg -InitialSelectionIds $script:subscriptionsExactList -Columns @("Name", "Id", "Type")
    }
    
    return $selectedSubscriptions
}

function Grant-SharePointAppPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$AppId
    )
    
    # Check if PnP.PowerShell is available
    if (-not (Get-Module -Name PnP.PowerShell -ListAvailable)) {
        Write-Output "Installing PnP.PowerShell module..."
        Install-Module -Name PnP.PowerShell -Force
    }
    
    # Get the organization details to determine SharePoint URL
    # Assuming Graph is already connected with appropriate scopes
    Write-Output "Getting tenant information from Microsoft Graph..."
    $org = Get-MgOrganization
    $tenantName = $org.VerifiedDomains | Where-Object { $_.IsInitial -eq $true } | Select-Object -ExpandProperty Name
    $tenantPrefix = $tenantName.Split('.')[0]
    
    # Construct SharePoint URLs
    $sharePointUrl = "https://$tenantPrefix.sharepoint.com"
    $sharePointAdminUrl = "https://$tenantPrefix-admin.sharepoint.com"
    
    Write-Output "SharePoint tenant URL: $sharePointUrl"
    Write-Output "SharePoint admin URL: $sharePointAdminUrl"
    
    # Connect to SharePoint admin site using the discovered URL
    Write-Output "Connecting to SharePoint Admin..."
    if (-not (Get-PnPConnection -ErrorAction SilentlyContinue)) {
        Connect-PnPOnline -Url $sharePointAdminUrl -Interactive
    }
    
    # Determine the app to use
    $appIdToUse = $null
    $appDisplayName = $null
    
    if ($AppId) {
        $appIdToUse = $AppId
        
        # Try to get app name from Azure
        try {
            $spApp = Get-AzADServicePrincipal -ApplicationId $AppId
            $appDisplayName = $spApp.DisplayName
        }
        catch {
            $appDisplayName = Read-Host "Enter a display name for the app"
        }
        
        Write-Output "Using app ID: $appIdToUse ($appDisplayName)"
    }
    else {
        # No parameters provided, ask user for app name
        $appName = Read-Host "Enter the name of the application to use"
        
        # Try to find the app by name
        try {
            $spApp = Get-AzADServicePrincipal -DisplayName $appName
            if ($spApp -is [array]) {
                Write-Output "Multiple apps found with that name. Please select one:"
                for ($i = 0; $i -lt $spApp.Count; $i++) {
                    Write-Output "[$i] $($spApp[$i].DisplayName) (ID: $($spApp[$i].AppId))"
                }
                $selection = Read-Host "Enter the number of the app to use"
                $spApp = $spApp[$selection]
            }
            $appIdToUse = $spApp.AppId
            $appDisplayName = $spApp.DisplayName
            Write-Output "Found app: $appDisplayName ($appIdToUse)"
        }
        catch {
            Write-Error "Could not find app with name '$appName'. Please verify the app name or provide the App ID directly."
            return
        }
    }
    
    # Grant permissions
    try {
        Write-Output "Granting app permissions to SharePoint site..."
        Grant-PnPAzureADAppSitePermission -AppId $appIdToUse -DisplayName $appDisplayName -Site $sharePointUrl -Permissions "Read"
        
        # Ask if tenant-wide permissions are needed
        $grantTenantPermissions = Read-Host "Do you want to grant tenant-wide permissions? (Y/N)"
        
        if ($grantTenantPermissions -eq "Y") {
            Write-Output "Granting tenant-wide permissions..."
            Grant-PnPTenantServicePrincipalPermission -AppId $appIdToUse -Resource "Microsoft Graph" -Scope "Sites.Read.All"
        }
        
        Write-Output "Permissions granted successfully!"
    }
    catch {
        Write-Error "Error granting permissions: $_"
    }
}

function selectSubs {
    param (
        [switch]$ExactList,  # Optional switch to select the exact subscriptions to use for the rest of the script functions
        [switch]$ExcludeList  # Optional switch to select subscriptions to exclude from the rest of the script functions
    )
    # Select subscriptions to include in the script
    if ($ExactList) {
        $selectedSubs = Get-UserSelectedSubscriptions -CustomMsg "Select subscription(s) that the script will only use going forward" -sel
        $script:subscriptionsExactList = @($selectedSubs | Select-Object -ExpandProperty Id)
    }
    if ($ExcludeList) {
        $selectedSubs = Get-UserSelectedSubscriptions -CustomMsg "Select subscription(s) that the script will exclude going forward" -ste
        $script:subscriptionsToExclude = @($selectedSubs | Select-Object -ExpandProperty Id)    
    }
}

############################################
########   Script Initialization ###########
############################################

Write-Notification-Message "##############"
Write-Notification-Message "##############"
Write-Notification-Message "Initializing Entro Azure Onboarding Script"
Write-Notification-Message "##############"
Write-Notification-Message "##############"

# Check for Azure PowerShell commands/modules. Install if not found
if (-not (CommandExists -command "Connect-AzAccount")) {
    try {
        if (-not (Get-Module -Name Az.Accounts -ListAvailable)) {
            Install-Module -Name Az.Accounts -Scope CurrentUser -Force
        }
        Import-Module -Name Az.Accounts
        
        if (-not (Get-Module -Name Az.Resources -ListAvailable)) {
            Install-Module -Name Az.Resources -Scope CurrentUser -Force
        }
        Import-Module -Name Az.Resources
        
        if (-not (Get-Module -Name Az.OperationalInsights -ListAvailable)) {
            Install-Module -Name Az.OperationalInsights -Scope CurrentUser -Force
        }
        Import-Module -Name Az.OperationalInsights
        
        if (-not (Get-Module -Name Az.Monitor -ListAvailable)) {
            Install-Module -Name Az.Monitor -Scope CurrentUser -Force
        }
        Import-Module -Name Az.Monitor
        
        if (-not (Get-Module -Name Az.KeyVault -ListAvailable)) {
            Install-Module -Name Az.KeyVault -Scope CurrentUser -Force
        }
        Import-Module -Name Az.KeyVault
    } catch {
        Write-Error-Message "Azure PowerShell modules not found. Please install the module and re-run the script."
        Exit-Script
    }
}

# Check for Microsoft Graph PowerShell commands
If (-not (CommandExists -command "Get-MgContext")) {
    try {
        if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
            Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force
        }
        Import-Module -Name Microsoft.Graph
    } catch {
        Write-Error-Message "Microsoft Graph PowerShell module not found. Please install the module and re-run the script."
        Exit-Script
    } 
}
if (-not (CommandExists -command "Get-MgUser")) {
    try {
        if (-not (Get-Module -Name Microsoft.Graph.Users -ListAvailable)) {
            Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
        }
    }
    catch {
        Write-Error-Message "Microsoft Graph PowerShell Users module not found. Please install the module and re-run the script."
        Exit-Script
    }
}

# Define the required scopes to access the Microsoft Graph API

$scopesString = "Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, AuditLog.Read.All, DelegatedPermissionGrant.ReadWrite.All, Directory.ReadWrite.All, RoleManagement.ReadWrite.Directory, Organization.Read.All"

# On macOS, Connect-AzAccount's interactive login defaults to the WAM broker, which requires
# running on the main thread and fails with "must be executed on the main thread on macOS"
# in most script hosts. Disable the broker so the standard browser-based flow is used instead.
if ($IsMacOS) {
    try {
        Update-AzConfig -EnableLoginByWam $false *> $null
    }
    catch {
        # Ignore if unsupported by the installed Az.Accounts version
    }
}

if ($env:AZUREPS_HOST_ENVIRONMENT) {
    # Script run from Azure Cloud Shell, using device authentication
    Write-Output "Connecting to Azure using device authentication"
    # Connect to Microsoft Graph
    Write-Host "Authenticating to MS Graph  (1 of 2)..."
    if ($script:TenantId -eq "") {
        try {
            Connect-MgGraph -NoWelcome -Scopes $scopesString -UseDeviceAuthentication 
        }
        catch {
            exit 1
        }
    } else {
        # Tenant ID specified
        try {
            Connect-MgGraph -NoWelcome -TenantId $script:TenantId -Scopes $scopesString -UseDeviceAuthentication 
        }
        catch {
            exit 1
        }
    }
    # Get the current context
    $context = Get-MgContext

    # Check the granted scopes
    $grantedScopes = $context.Scopes

    # Verify if the required permissions are included
    $missingScopes = $scopes | Where-Object { $_ -notin $grantedScopes }

    if ($missingScopes.Count -eq 0) {
        Write-Output "All required permissions are granted."
    }
    else {
        Write-Output "Missing permissions: $($missingScopes -join ', ')"
        Read-Host "Please grant the missing permissions and re-run the script...."
    }
    
    Write-Host "Athenticating to Azure (2 of 2)..."
    If ($script:TenantId -eq "") {
        try {
            Connect-AzAccount -UseDeviceAuthentication
        } 
        catch {
            exit 1
        }
    } else {
        # Tenant ID specified
        try {
            Connect-AzAccount -Tenant $script:TenantId -UseDeviceAuthentication
        }
        catch {
            exit 1
        }    
    } 
} else {
    # Script run from local machine, using interactive login
    Write-Output "Connecting to Azure using interactive login"
    # Connect to Microsoft Graph
    Write-Host "Authenticating to MS Graph  (1 of 2)..."
    if ($script:TenantId -eq "") {
        try {
            Connect-MgGraph -NoWelcome -Scopes $scopesString *> $null
        }
        catch {
            exit 1
        }
    } else {
        # Tenant ID specified
        try {
            Connect-MgGraph -NoWelcome -TenantId $script:TenantId -Scopes $scopesString *> $null
        }
        catch {
            exit 1
        }
    }
    # Get the current context
    $context = Get-MgContext

    # Check the granted scopes
    $grantedScopes = $context.Scopes

    # Verify if the required permissions are included
    $missingScopes = $scopes | Where-Object { $_ -notin $grantedScopes }

    if ($missingScopes.Count -eq 0) {
        Write-Output "All required permissions are granted."
    }
    else {
        Write-Output "Missing permissions: $($missingScopes -join ', ')"
        Read-Host "Please grant the missing permissions and re-run the script...."
    }
    
    Write-Host "Athenticating to Azure (2 of 2)..."
    If ($script:TenantId -eq "") {
        try {
            Connect-AzAccount
        } 
        catch {
            exit 1
        }
    } else {
        # Tenant ID specified
        try {
            Connect-AzAccount -Tenant $script:TenantId
        }
        catch {
            exit 1
        }    
    }
    #Read-Host "Authenticated, press <enter> to continue...."
}

#Get Current Tenant Details
try {
    $script:curTenant = Get-MgOrganization
}
catch {
    # Ignore, unable to get tenant details
}

# Trying this to suppress the warning about breaking changes in the Az modules
try {
    #Set-AzContext -WarningAction SilentlyContinue
    Update-AzConfig -DisplayBreakingChangeWarning $false *> $null
}
catch {
    # Ignore if errors, just trying to suppress annoying warnings
}
    
# Start the script by showing the main menu
Show-Menu
}