param(
    [string]$ModuleRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules')
)

. (Join-Path $PSScriptRoot '_TestHelpers.ps1')
$script:AssertionCount = 0

Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.OperatorConsole.psm1') -Force
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $ModuleRoot 'ISC.PowerPlatformConnector.psm1') -Force
$module = Get-Module -Name 'ISC.PowerPlatformConnector'

$roles = @(Get-CopilotStudioRoleNames)
Assert-True ($roles -contains 'Global Discovery Service Role') 'the Global Discovery Service Role is required'
Assert-True ($roles -contains 'SailPoint BotReader') 'a custom BotReader role is required'
$privileges = @(Get-BotReadPrivilegeNames)
Assert-True ($privileges -contains 'prvReadbot') 'bot read is part of the custom role'
Assert-True ($privileges -contains 'prvReadbotcomponent') 'bot component read is part of the custom role'

# Dataverse is reached over its own Web API, so the whole surface is stubbed inside the module scope
# and the calls are recorded to assert what the fix actually does.
$script:Calls = [System.Collections.Generic.List[object]]::new()

function Reset-Stubs {
    param(
        [object]$ExistingUser,
        [object[]]$AssignedRoles = @(),
        [string[]]$GlobalBotReadRoleIds = @(),
        [string[]]$KnownRoles = @('Global Discovery Service Role')
    )

    $script:Calls = [System.Collections.Generic.List[object]]::new()
    & $module {
        param($existingUser, $assignedRoles, $globalReaders, $knownRoles, $calls)

        Set-Variable -Scope Script -Name ExistingUser -Value $existingUser
        Set-Variable -Scope Script -Name AssignedRoles -Value $assignedRoles
        Set-Variable -Scope Script -Name GlobalReaders -Value $globalReaders
        Set-Variable -Scope Script -Name KnownRoles -Value $knownRoles
        Set-Variable -Scope Script -Name Calls -Value $calls

        Set-Item function:script:Get-DataverseAccessToken { param($Resource, $AzPath) return 'stub-token' }

        Set-Item function:script:Get-DataverseApplicationUser {
            param($EnvironmentUrl, $ClientId, $Token)
            return $script:ExistingUser
        }

        Set-Item function:script:Get-DataverseRootBusinessUnit {
            param($EnvironmentUrl, $Token)
            return [PSCustomObject]@{ businessunitid = 'bu-1'; name = 'root' }
        }

        Set-Item function:script:New-DataverseApplicationUser {
            param($EnvironmentUrl, $ClientId, $BusinessUnitId, $Token)
            $script:Calls.Add(@{ Op = 'create-user'; Client = $ClientId; BusinessUnit = $BusinessUnitId })
            return [PSCustomObject]@{ systemuserid = 'su-1' }
        }

        Set-Item function:script:Get-DataverseAssignedRole {
            param($EnvironmentUrl, $SystemUserId, $Token)
            return @($script:AssignedRoles)
        }

        Set-Item function:script:Get-DataverseSecurityRole {
            param($EnvironmentUrl, $Name, $Token)
            if (@($script:KnownRoles) -contains $Name) {
                return [PSCustomObject]@{ roleid = "role-$Name"; name = $Name }
            }
            return $null
        }

        # Only roles explicitly listed grant organization-level bot read, which is what separates a
        # working role from Bot Viewer's user-scoped read.
        Set-Item function:script:Test-DataverseGlobalBotRead {
            param($EnvironmentUrl, $RoleId, $Token)
            return (@($script:GlobalReaders) -contains $RoleId)
        }

        Set-Item function:script:New-DataverseBotReaderRole {
            param($EnvironmentUrl, $BusinessUnitId, $Token, $Name)
            $script:Calls.Add(@{ Op = 'create-role'; BusinessUnit = $BusinessUnitId })
            return [PSCustomObject]@{ roleid = 'role-botreader'; name = 'SailPoint BotReader' }
        }

        Set-Item function:script:Add-DataverseSecurityRole {
            param($EnvironmentUrl, $SystemUserId, $RoleId, $Token)
            $script:Calls.Add(@{ Op = 'add-role'; Role = $RoleId })
        }
    } $ExistingUser $AssignedRoles $GlobalBotReadRoleIds $KnownRoles $script:Calls
}

# A missing application user is the real-world failure: Entra permissions are correct but the
# connector has no identity in Dataverse, so no agent is ever discovered.
Reset-Stubs -ExistingUser $null
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1' -EnvironmentName 'Contoso'
Assert-True $result.UserCreated 'a missing application user is created'
Assert-True ($null -eq $result.Error) 'configuring a healthy environment reports no error'
Assert-True ([bool](@($script:Calls) | Where-Object { $_.Op -eq 'create-user' -and $_.BusinessUnit -eq 'bu-1' })) 'the application user is bound to the root business unit'
Assert-True (@($result.RolesAdded) -contains 'Global Discovery Service Role') 'the discovery role is assigned'
Assert-True (@($result.RolesAdded) -contains 'SailPoint BotReader') 'the custom bot reader role is assigned'
Assert-True ([bool](@($script:Calls) | Where-Object { $_.Op -eq 'create-role' })) 'the custom role is created when no role grants organization-level bot read'

# The trap this guards against: a role is assigned and the API call succeeds, but the privilege is
# scoped to owned records, so the app reads zero agents. Presence of a role is never sufficient.
Reset-Stubs -ExistingUser ([PSCustomObject]@{ systemuserid = 'su-1' }) `
    -AssignedRoles @([PSCustomObject]@{ Name = 'Global Discovery Service Role'; RoleId = 'r-gds' },
                     [PSCustomObject]@{ Name = 'Bot Viewer'; RoleId = 'r-botviewer' }) `
    -GlobalBotReadRoleIds @()
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1'
Assert-True (@($result.RolesAdded) -contains 'SailPoint BotReader') 'Bot Viewer alone does not satisfy organization-level bot read'
Assert-True (-not (@($result.RolesAdded) -contains 'Global Discovery Service Role')) 'an already assigned discovery role is not reassigned'

# A role that does grant Global depth is honoured, whatever it is called.
Reset-Stubs -ExistingUser ([PSCustomObject]@{ systemuserid = 'su-1' }) `
    -AssignedRoles @([PSCustomObject]@{ Name = 'Global Discovery Service Role'; RoleId = 'r-gds' },
                     [PSCustomObject]@{ Name = 'Bot Contributor'; RoleId = 'r-botcontrib' }) `
    -GlobalBotReadRoleIds @('r-botcontrib')
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1'
Assert-Equal 0 (@($result.RolesAdded)).Count 'an existing role with organization-level bot read is reused'
Assert-Equal 0 (@(@($script:Calls) | Where-Object { $_.Op -eq 'add-role' })).Count 'a configured environment issues no writes'
Assert-True (-not $result.UserCreated) 'an existing application user is reused'

# WhatIf must report the same plan without writing.
Reset-Stubs -ExistingUser $null
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1' -WhatIf
Assert-True $result.UserCreated 'WhatIf reports that the application user would be created'
Assert-Equal 0 (@(@($script:Calls) | Where-Object { $_.Op -ne $null -and $_.Op -ne 'lookup' })).Count 'WhatIf writes nothing'

# An environment without the discovery role needs a manual equivalent, so the gap is reported.
Reset-Stubs -ExistingUser ([PSCustomObject]@{ systemuserid = 'su-1' }) -KnownRoles @()
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1' -WarningAction SilentlyContinue
Assert-True (@($result.RolesMissing) -contains 'Global Discovery Service Role') 'a role the environment does not define is reported as missing'

# One unreachable environment must not abort a run that already configured the application.
& $module {
    Set-Item function:script:Get-DataverseAccessToken { param($Resource, $AzPath) throw 'az login required' }
}
$result = Set-CopilotStudioDataverseAccess -EnvironmentUrl 'https://org.crm.dynamics.com' -ClientId 'client-1' -WarningAction SilentlyContinue
Assert-True ([bool]$result.Error) 'an unreachable environment is reported rather than thrown'
Assert-True ($result.Error -like '*az login*') 'the reported error explains the sign-in requirement'

Write-Host "PASS ($script:AssertionCount assertions)"
