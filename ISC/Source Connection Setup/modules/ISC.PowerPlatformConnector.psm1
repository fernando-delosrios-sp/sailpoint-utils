#Requires -Version 5.1
Set-StrictMode -Version Latest

# -----------------------------------------------------------------------------
# Microsoft Copilot Studio agents live in Dataverse, not Azure, so the ISC connector reads them as a
# Dataverse application user rather than through Microsoft Graph. This module checks for that
# application user and creates it with the two security roles SailPoint's connector documentation
# asks for.
#
# https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/copilot_studio_agents.html
# -----------------------------------------------------------------------------

$script:GlobalDiscoveryResource = 'https://globaldisco.crm.dynamics.com'
$script:DataverseApiVersion = 'v9.2'

$script:DiscoveryRoleName = 'Global Discovery Service Role'

# The built-in Bot Viewer role grants prvReadbot at Basic depth, which scopes reads to records the
# user owns. An application user owns no agents, so it authenticates successfully and then reads
# zero bots. Only organization-level (Global) depth works, which is why SailPoint documents a custom
# BotReader role; this module creates one rather than relying on a built-in role.
$script:BotReaderRoleName = 'SailPoint BotReader'
$script:BotReadPrivileges = @('prvReadbot', 'prvReadbotcomponent')

function Get-CopilotStudioRoleNames {
    return @($script:DiscoveryRoleName, $script:BotReaderRoleName)
}

function Get-BotReadPrivilegeNames {
    return @($script:BotReadPrivileges)
}

function Invoke-AzCliJson {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$AzPath
    )

    if (-not $AzPath) { $AzPath = Ensure-AzCliCommand }
    $output = & $AzPath @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "az $($Arguments -join ' ') failed: $(@($output) -join ' ')"
    }
    $text = (@($output) -join "`n").Trim()
    if (-not $text) { return $null }
    return $text | ConvertFrom-Json
}

# The Azure CLI mints tokens per audience, so a Dataverse call needs the environment URL as the
# resource rather than the Graph or ARM default.
function Get-DataverseAccessToken {
    param(
        [Parameter(Mandatory)][string]$Resource,
        [string]$AzPath
    )

    if (-not $AzPath) { $AzPath = Ensure-AzCliCommand }
    $result = & $AzPath 'account' 'get-access-token' '--resource' $Resource '--query' 'accessToken' '-o' 'tsv' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("Could not get a Dataverse token for $Resource. Run 'az login' as a Power Platform administrator first. " +
            "$(@($result) -join ' ')")
    }
    $token = (@($result) -join '').Trim()
    if (-not $token) { throw "The Azure CLI returned an empty token for $Resource." }
    return $token
}

function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$Path,
        [string]$Method = 'GET',
        $Body,
        [Parameter(Mandatory)][string]$Token,
        [hashtable]$ExtraHeaders = @{}
    )

    $headers = @{
        Authorization    = "Bearer $Token"
        Accept           = 'application/json'
        'OData-Version'  = '4.0'
        'OData-MaxVersion' = '4.0'
    }
    foreach ($entry in $ExtraHeaders.GetEnumerator()) { $headers[$entry.Key] = $entry.Value }

    $uri = "$($EnvironmentUrl.TrimEnd('/'))/api/data/$script:DataverseApiVersion/$($Path.TrimStart('/'))"
    $parameters = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $headers
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $parameters['Body'] = ($Body | ConvertTo-Json -Depth 5 -Compress)
        $parameters['ContentType'] = 'application/json'
    }

    return Invoke-RestMethod @parameters
}

function Get-PowerPlatformEnvironment {
    param([string]$AzPath)

    $token = Get-DataverseAccessToken -Resource $script:GlobalDiscoveryResource -AzPath $AzPath
    $response = Invoke-RestMethod -Method GET -ErrorAction Stop `
        -Uri "$script:GlobalDiscoveryResource/api/discovery/v2.0/Instances" `
        -Headers @{ Authorization = "Bearer $token"; Accept = 'application/json' }

    $environments = [System.Collections.Generic.List[object]]::new()
    foreach ($instance in @($response.value)) {
        $environments.Add([PSCustomObject]@{
            Name = [string]$instance.FriendlyName
            Url  = [string]$instance.ApiUrl
            Id   = [string]$instance.EnvironmentId
        })
    }
    return @($environments | Sort-Object Name)
}

function Get-DataverseApplicationUser {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$Token
    )

    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "systemusers?`$filter=applicationid eq $ClientId&`$select=fullname,applicationid"
    return @($response.value) | Select-Object -First 1
}

function Get-DataverseRootBusinessUnit {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$Token
    )

    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "businessunits?`$select=name,businessunitid&`$filter=_parentbusinessunitid_value eq null"
    $unit = @($response.value) | Select-Object -First 1
    if (-not $unit) { throw "Could not find the root business unit in $EnvironmentUrl." }
    return $unit
}

function New-DataverseApplicationUser {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$BusinessUnitId,
        [Parameter(Mandatory)][string]$Token
    )

    $body = [ordered]@{
        applicationid                = $ClientId
        'businessunitid@odata.bind'  = "/businessunits($BusinessUnitId)"
    }
    return Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token -Method 'POST' `
        -Path 'systemusers' -Body $body -ExtraHeaders @{ Prefer = 'return=representation' }
}

function Get-DataverseSecurityRole {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Token
    )

    $escaped = $Name.Replace("'", "''")
    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "roles?`$select=name,roleid&`$filter=name eq '$escaped'"
    return @($response.value) | Select-Object -First 1
}

function Get-DataverseAssignedRole {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$SystemUserId,
        [Parameter(Mandatory)][string]$Token
    )

    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "systemusers($SystemUserId)/systemuserroles_association?`$select=name,roleid"
    return @(@($response.value) | ForEach-Object {
        [PSCustomObject]@{ Name = [string]$_.name; RoleId = [string]$_.roleid }
    })
}

function Get-DataversePrivilege {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Token
    )

    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "privileges?`$select=name,privilegeid&`$filter=name eq '$Name'"
    $privilege = @($response.value) | Select-Object -First 1
    if (-not $privilege) { throw "The $Name privilege does not exist in $EnvironmentUrl." }
    return $privilege
}

# Depth is what separates a role that works from one that silently returns nothing, so it is read
# back rather than inferred from the role name.
function Test-DataverseGlobalBotRead {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$RoleId,
        [Parameter(Mandatory)][string]$Token
    )

    $response = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token `
        -Path "RetrieveRolePrivilegesRole(RoleId=$RoleId)"
    $granted = @($response.RolePrivileges) | Where-Object {
        $_.PrivilegeName -eq 'prvReadbot' -and $_.Depth -eq 'Global'
    }
    return [bool]$granted
}

function New-DataverseBotReaderRole {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$BusinessUnitId,
        [Parameter(Mandatory)][string]$Token,
        [string]$Name = $script:BotReaderRoleName
    )

    $role = Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token -Method 'POST' `
        -Path 'roles' -ExtraHeaders @{ Prefer = 'return=representation' } `
        -Body ([ordered]@{ name = $Name; 'businessunitid@odata.bind' = "/businessunits($BusinessUnitId)" })

    $privileges = @()
    foreach ($privilegeName in Get-BotReadPrivilegeNames) {
        $privilege = Get-DataversePrivilege -EnvironmentUrl $EnvironmentUrl -Name $privilegeName -Token $Token
        $privileges += [ordered]@{
            Depth          = 'Global'
            PrivilegeId    = [string]$privilege.privilegeid
            BusinessUnitId = $BusinessUnitId
        }
    }

    Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token -Method 'POST' `
        -Path "roles($($role.roleid))/Microsoft.Dynamics.CRM.AddPrivilegesRole" `
        -Body ([ordered]@{ Privileges = $privileges }) | Out-Null

    return $role
}

function Add-DataverseSecurityRole {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$SystemUserId,
        [Parameter(Mandatory)][string]$RoleId,
        [Parameter(Mandatory)][string]$Token
    )

    $reference = "$($EnvironmentUrl.TrimEnd('/'))/api/data/$script:DataverseApiVersion/roles($RoleId)"
    Invoke-DataverseRequest -EnvironmentUrl $EnvironmentUrl -Token $Token -Method 'POST' `
        -Path "systemusers($SystemUserId)/systemuserroles_association/`$ref" `
        -Body ([ordered]@{ '@odata.id' = $reference }) | Out-Null
}

# Returns what the environment needed rather than throwing, so one unreachable environment cannot
# fail a run that has already configured the application.
function Set-CopilotStudioDataverseAccess {
    param(
        [Parameter(Mandatory)][string]$EnvironmentUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [string]$EnvironmentName,
        [switch]$WhatIf,
        [string]$AzPath
    )

    $label = if ($EnvironmentName) { $EnvironmentName } else { $EnvironmentUrl }
    $result = [PSCustomObject]@{
        Environment  = $label
        Url          = $EnvironmentUrl
        UserCreated  = $false
        RolesAdded   = @()
        RolesPresent = @()
        RolesMissing = @()
        Error        = $null
    }

    try {
        $token = Get-DataverseAccessToken -Resource $EnvironmentUrl -AzPath $AzPath
        $user = Get-DataverseApplicationUser -EnvironmentUrl $EnvironmentUrl -ClientId $ClientId -Token $token

        if (-not $user) {
            if ($WhatIf) {
                $result.UserCreated = $true
                $result.RolesMissing = @(Get-CopilotStudioRoleNames)
                return $result
            }
            $unit = Get-DataverseRootBusinessUnit -EnvironmentUrl $EnvironmentUrl -Token $token
            $user = New-DataverseApplicationUser -EnvironmentUrl $EnvironmentUrl -ClientId $ClientId `
                -BusinessUnitId $unit.businessunitid -Token $token
            $result.UserCreated = $true
            Write-Ok "$label : created the application user"
        }

        $assigned = @(Get-DataverseAssignedRole -EnvironmentUrl $EnvironmentUrl -SystemUserId $user.systemuserid -Token $token)
        $assignedNames = @($assigned | ForEach-Object { $_.Name })
        $added = [System.Collections.Generic.List[string]]::new()
        $missing = [System.Collections.Generic.List[string]]::new()

        if ($assignedNames -notcontains $script:DiscoveryRoleName) {
            $role = Get-DataverseSecurityRole -EnvironmentUrl $EnvironmentUrl -Name $script:DiscoveryRoleName -Token $token
            if (-not $role) {
                Write-Warning "$label : the '$script:DiscoveryRoleName' security role does not exist; assign an equivalent manually."
                $missing.Add($script:DiscoveryRoleName)
            }
            elseif ($WhatIf) { $added.Add($script:DiscoveryRoleName) }
            else {
                Add-DataverseSecurityRole -EnvironmentUrl $EnvironmentUrl -SystemUserId $user.systemuserid `
                    -RoleId $role.roleid -Token $token
                $added.Add($script:DiscoveryRoleName)
                Write-Ok "$label : assigned $script:DiscoveryRoleName"
            }
        }

        # Any already assigned role granting organization-level bot read is enough, so a hand-built
        # BotReader or Bot Contributor is honoured instead of assigning a second role.
        $hasBotRead = $false
        foreach ($role in $assigned) {
            if (Test-DataverseGlobalBotRead -EnvironmentUrl $EnvironmentUrl -RoleId $role.RoleId -Token $token) {
                $hasBotRead = $true
                $result.RolesPresent = @($result.RolesPresent) + $role.Name
                break
            }
        }

        if (-not $hasBotRead) {
            if ($WhatIf) { $added.Add($script:BotReaderRoleName) }
            else {
                $botReader = Get-DataverseSecurityRole -EnvironmentUrl $EnvironmentUrl -Name $script:BotReaderRoleName -Token $token
                if ($botReader -and -not (Test-DataverseGlobalBotRead -EnvironmentUrl $EnvironmentUrl -RoleId $botReader.roleid -Token $token)) {
                    $botReader = $null
                }
                if (-not $botReader) {
                    $unit = Get-DataverseRootBusinessUnit -EnvironmentUrl $EnvironmentUrl -Token $token
                    $botReader = New-DataverseBotReaderRole -EnvironmentUrl $EnvironmentUrl `
                        -BusinessUnitId $unit.businessunitid -Token $token
                    Write-Ok "$label : created the $script:BotReaderRoleName role with organization-level bot read"
                }
                Add-DataverseSecurityRole -EnvironmentUrl $EnvironmentUrl -SystemUserId $user.systemuserid `
                    -RoleId $botReader.roleid -Token $token
                $added.Add($script:BotReaderRoleName)
                Write-Ok "$label : assigned $script:BotReaderRoleName"
            }
        }

        $result.RolesAdded = @($added)
        $result.RolesMissing = @($missing)
        $result.RolesPresent = @(@($result.RolesPresent) + @($assignedNames | Where-Object { $_ -eq $script:DiscoveryRoleName }) | Select-Object -Unique)
        if (-not $result.UserCreated -and $added.Count -eq 0 -and $missing.Count -eq 0) {
            Write-Info "$label : already configured"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Warning "$label : $($_.Exception.Message)"
    }

    return $result
}

Export-ModuleMember -Function @(
    'Get-CopilotStudioRoleNames'
    'Get-BotReadPrivilegeNames'
    'Get-DataversePrivilege'
    'Test-DataverseGlobalBotRead'
    'New-DataverseBotReaderRole'
    'Get-DataverseAccessToken'
    'Invoke-DataverseRequest'
    'Get-PowerPlatformEnvironment'
    'Get-DataverseApplicationUser'
    'Get-DataverseRootBusinessUnit'
    'New-DataverseApplicationUser'
    'Get-DataverseSecurityRole'
    'Get-DataverseAssignedRole'
    'Add-DataverseSecurityRole'
    'Set-CopilotStudioDataverseAccess'
)
