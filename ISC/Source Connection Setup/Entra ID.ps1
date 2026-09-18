#Requires -Version 5.1
<#
.SYNOPSIS
    Creates or updates the Microsoft Entra ID application used by the SailPoint Identity Security Cloud
    Microsoft Entra ID connector (SaaS "Microsoft Entra" and VA "Azure Active Directory").

.DESCRIPTION
    Registers an Entra ID application, assigns the Microsoft Graph application permissions documented by
    SailPoint, grants admin consent, assigns the directory roles the connector needs for Set Password and
    Delete User, and issues a client secret.

    All permissions from SailPoint's required-permissions table are granted by default. Optional feature
    packs (access packages, MFA management, CIEM, NHI discovery, Teams / SharePoint scanning, Copilot
    discovery, Agent 365, Defender hunting) are opt-in because they map to features that must be licensed
    or enabled.

    The Agent 365 pack also grants delegated permissions and runs an authorization-code flow, because the
    Microsoft Agent 365 catalog rejects application tokens and ISC needs a refresh token for it.

    Existing applications with the same display name are updated in place rather than duplicated.

    Reference:
    https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/administrator_permission.html

.PARAMETER TenantId
    Entra ID tenant ID (GUID) or verified domain. Prompts when omitted.

.PARAMETER ApplicationName
    Display name of the app registration. Prompts when omitted.

.PARAMETER PermissionMode
    Granular  - the documented per-API required permission table (default, least privilege).
    Directory - the documented coarse alternative: Directory.Read.All + Directory.ReadWrite.All.

.PARAMETER Feature
    Optional documented feature packs to add. See the README for the permissions in each pack.

.PARAMETER DirectoryRole
    Directory role for the service principal. Default UserAdministrator, which SailPoint requires for
    Set Password and Delete User.

.PARAMETER SecretDisplayName
    Display name of the client secret. Default: ISC.

.PARAMETER SecretValidityMonths
    Client secret lifetime in months (1-24). Default: 24.

.PARAMETER RotateSecret
    When updating an existing application, create a new client secret.

.PARAMETER OutputDirectory
    Directory for the Connection Settings file. Default: ./sourceConfig/entra-id-isc

.PARAMETER Agent365RedirectUri
    Loopback redirect URI registered on the application and used by the -Feature Agent365
    authorization-code flow. Default: http://localhost:8400/

.PARAMETER PowerPlatformEnvironmentUrl
    Dataverse org URL (https://org.crm.dynamics.com) to configure for Copilot Studio agent
    discovery. Omit it and the environments are discovered through the Global Discovery Service.

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\Entra ID.ps1

.EXAMPLE
    .\Entra ID.ps1 -ApplicationName 'SailPoint ISC Entra ID' -Feature AccessPackages,MfaManagement -NonInteractive

.EXAMPLE
    .\Entra ID.ps1 -ApplicationName 'SailPoint ISC Entra ID' -Feature CopilotDiscovery,Agent365 -RotateSecret

.NOTES
    Sign in as an account that can create applications, grant admin consent, and assign directory roles
    (Application Administrator + Privileged Role Administrator, or Global Administrator).
    The client secret is displayed once and cannot be retrieved afterwards.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [string]$ApplicationName,

    [Parameter()]
    [ValidateSet('Granular', 'Directory')]
    [string]$PermissionMode = 'Granular',

    [Parameter()]
    [ValidateSet('AccessPackages', 'ActivityInsights', 'AdministrativeUnits', 'Agent365', 'Ciem',
        'CopilotDiscovery', 'DefenderHunting', 'ExchangeOnline', 'MfaManagement', 'NhiDiscovery',
        'ServicePrincipalProvisioning', 'SharePointScanning', 'TeamsMessaging', 'TeamsSecretScanning')]
    [string[]]$Feature,

    [Parameter()]
    [ValidateSet('None', 'UserAdministrator', 'PrivilegedAdmin', 'GlobalAdministrator')]
    [string]$DirectoryRole,

    [Parameter()]
    [string]$SecretDisplayName = 'ISC',

    [Parameter()]
    [ValidateRange(1, 24)]
    [int]$SecretValidityMonths = 24,

    [Parameter()]
    [switch]$RotateSecret,

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [string]$Agent365RedirectUri = 'http://localhost:8400/',

    [Parameter()]
    [string]$PowerPlatformEnvironmentUrl,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.EntraConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.EntraCiemConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.EntraSourceSetup.psm1') -Force
Initialize-OperatorConsole -NonInteractive:$NonInteractive
Initialize-EntraSourceSetup -ModuleRoot $script:ModuleRoot -NonInteractive:$NonInteractive
$catalog = Get-EntraConnectorCatalog



# -----------------------------------------------------------------------------
# Console helpers
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Microsoft Entra ID source connection setup' -ForegroundColor Cyan
    Write-Host '  Creates or updates the app registration used by the Entra ID connector.' -ForegroundColor DarkCyan
    Write-Host ''
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

try {
    Write-Banner
    Ensure-MicrosoftGraphModules

    $session = $null
    $connectRequest = $null
    $targetAppObjectId = $null
    $createSecret = $true

    # Whether each value still has to be asked for is decided once, from what the caller passed.
    # Testing the variables instead would stop a step from asking again when Esc returns to it.
    $askTenantId = -not $TenantId -and -not $NonInteractive
    $askApplicationName = -not $ApplicationName
    $askFeature = -not $PSBoundParameters.ContainsKey('Feature')
    $askDirectoryRole = -not $DirectoryRole

    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            if (Enter-WizardPrompt) {
                if ($askTenantId) {
                    $TenantId = Read-InputString -Prompt 'Entra ID tenant ID or domain (blank = home tenant from sign-in)' -Default $TenantId
                }
                Complete-WizardPrompt
            }

            if (-not $session -or $TenantId -ne $connectRequest) {
                $session = Connect-EntraGraph -RequestedTenantId $TenantId
                $connectRequest = $TenantId
                $TenantId = $session.TenantId
            }

            if (Enter-WizardPrompt) {
                if ($askApplicationName) {
                    $ApplicationName = Read-InputString -Prompt 'Application display name' -Default $(if ($ApplicationName) { $ApplicationName } else { 'SailPoint ISC Entra ID' }) -Required
                }
                Complete-WizardPrompt
            }

            # @() is required on every call site below: PowerShell unrolls an array returned from a
            # function, so a zero-result lookup arrives as $null and $null.Count throws under StrictMode.
            $existingApps = @(Find-EntraApplicationByName -DisplayName $ApplicationName)

            if (Enter-WizardPrompt) {
                $targetAppObjectId = $null
                if ($existingApps.Count -eq 1) {
                    Write-Step "An application named '$ApplicationName' already exists"
                    Write-Info "Client ID: $($existingApps[0].AppId)"
                    if (Read-YesNo -Prompt 'Update it instead of creating a new one?' -Default $true) {
                        $targetAppObjectId = $existingApps[0].Id
                    }
                    else {
                        $ApplicationName = Read-InputString -Prompt 'New application display name' -Required
                    }
                }
                elseif ($existingApps.Count -gt 1) {
                    Write-Step "Multiple applications are named '$ApplicationName'"
                    $options = @('CreateNew') + @($existingApps.Id)
                    $labels = @('Create a new application with a different name') +
                        @($existingApps | ForEach-Object { "Update $($_.DisplayName)  ($($_.AppId))" })
                    $picked = Read-Choice -Prompt 'Choose an application:' -Options $options -Labels $labels -Default $existingApps[0].Id
                    if ($picked -eq 'CreateNew') {
                        $ApplicationName = Read-InputString -Prompt 'New application display name' -Required
                    }
                    else {
                        $targetAppObjectId = $picked
                    }
                }
                Complete-WizardPrompt
            }

            $isUpdate = [bool]$targetAppObjectId

            if (Enter-WizardPrompt) {
                if ($askFeature) {
                    $packNames = @($catalog.FeaturePacks.Keys)
                    $packLabels = @($packNames | ForEach-Object { $catalog.FeaturePacks[$_].Label })
                    Write-Step 'Permissions'
                    Write-Info "All $($catalog.CorePermissions.Count) required permissions from SailPoint's permission table are always granted."
                    $Feature = @(Read-MultiChoice -Prompt 'Optional feature permissions to add:' -Options $packNames -Labels $packLabels)
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askDirectoryRole) {
                    $DirectoryRole = Read-Choice -Prompt 'Directory role for the service principal:' -Options @(
                        'UserAdministrator', 'PrivilegedAdmin', 'None', 'GlobalAdministrator'
                    ) -Labels @(
                        'User Administrator - required by SailPoint for Set Password and Delete User'
                        'User Administrator + Privileged Authentication Administrator - also manage users holding admin roles'
                        'None - Graph application permissions only (Set Password and Delete User will fail)'
                        'Global Administrator - excessive; only if your organization mandates it'
                    ) -Default $(if ($DirectoryRole) { $DirectoryRole } else { 'UserAdministrator' })
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($DirectoryRole -eq 'GlobalAdministrator') {
                    Write-Warning 'Global Administrator on a connector service principal is high risk. SailPoint only requires User Administrator (plus Privileged Authentication Administrator for admin users).'
                    if (-not (Read-YesNo -Prompt 'Continue with Global Administrator?' -Default $false)) {
                        $DirectoryRole = 'PrivilegedAdmin'
                        Write-Ok 'Using User Administrator + Privileged Authentication Administrator instead.'
                    }
                }
                Complete-WizardPrompt
            }

            $needsAgent365 = Test-Agent365Selected -FeatureNames $Feature

            if (Enter-WizardPrompt) {
                $createSecret = $true
                if ($isUpdate) {
                    $createSecret = [bool]$RotateSecret
                    if (-not $NonInteractive -and -not $RotateSecret) {
                        # The Agent 365 flow exchanges its authorization code with the client secret,
                        # and Entra never shows an existing one again.
                        if ($needsAgent365) {
                            Write-Info 'Agent 365 needs the client secret to mint the refresh token. Answer No only if you still have the current one.'
                        }
                        $createSecret = Read-YesNo -Prompt 'Create a new client secret?' -Default $needsAgent365
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if (-not $OutputDirectory) {
                    $OutputDirectory = Join-Path (Get-Location) (Join-Path 'sourceConfig' 'entra-id-isc')
                }
                $OutputDirectory = Read-InputString -Prompt 'Output directory for connection settings' -Default $OutputDirectory -Required
                Complete-WizardPrompt
            }

            $permissions = @(Get-SelectedPermissions -Mode $PermissionMode -FeatureNames $Feature)
            $delegated = @(Get-SelectedDelegatedPermissions -FeatureNames $Feature)
            $roleNames = @($catalog.DirectoryRoleMap[$DirectoryRole])

            $planAction = if ($isUpdate) { 'Update existing application' } else { 'Create application' }
            $planFeatures = if ($Feature) { $Feature -join ', ' } else { 'none' }
            $planRoles = if ($roleNames.Count -gt 0) { $roleNames -join ', ' } else { 'none' }
            $planSecret = if ($createSecret) { "$SecretDisplayName, $SecretValidityMonths months" } else { 'unchanged' }

            Write-Step 'Plan'
            Write-Host "   Action         : $planAction"
            Write-Host "   Application    : $ApplicationName"
            Write-Host "   Tenant         : $TenantId"
            Write-Host "   Permission set : $PermissionMode ($($permissions.Count) permissions)"
            Write-Host "   Feature packs  : $planFeatures"
            Write-Host "   Directory role : $planRoles"
            Write-Host "   Client secret  : $planSecret"
            if ($needsAgent365) {
                Write-Host "   Agent 365      : refresh token via $Agent365RedirectUri"
            }
            if (Test-CopilotStudioSelected -FeatureNames $Feature) {
                $planEnvironment = if ($PowerPlatformEnvironmentUrl) { $PowerPlatformEnvironmentUrl } else { 'discovered environments' }
                Write-Host "   Copilot Studio : Dataverse application user in $planEnvironment"
            }
            Write-Host ''
            foreach ($group in ($permissions | Group-Object Resource)) {
                Write-Info "$($catalog.Resources[$group.Name].Name): $(($group.Group.Value | Sort-Object) -join ', ')"
            }
            foreach ($group in ($delegated | Group-Object Resource)) {
                Write-Info "$($catalog.Resources[$group.Name].Name) (delegated): $(($group.Group.Value | Sort-Object) -join ', ')"
            }

            if (Enter-WizardPrompt) {
                if (-not (Read-YesNo -Prompt 'Proceed?' -Default $true)) {
                    Write-Host 'Cancelled.' -ForegroundColor Yellow
                    return
                }
                Complete-WizardPrompt
            }

            $wizardComplete = $true
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if (-not (Move-WizardBack)) {
                Write-Host ''
                Write-Host 'Cancelled.' -ForegroundColor Yellow
                return
            }
        }
    }

    $action = if ($isUpdate) { "Update application '$ApplicationName'" } else { "Create application '$ApplicationName'" }
    if (-not $PSCmdlet.ShouldProcess($ApplicationName, $action)) { return }

    $resolved = [PSCustomObject]@{
        TenantId             = $TenantId
        ApplicationName      = $ApplicationName
        PermissionMode       = $PermissionMode
        Feature              = @($Feature)
        DirectoryRole        = $DirectoryRole
        SecretDisplayName    = $SecretDisplayName
        SecretValidityMonths = $SecretValidityMonths
        RotateSecret         = [bool]$RotateSecret
        OutputDirectory      = $OutputDirectory
        CreateSecret         = [bool]$createSecret
        Agent365RedirectUri  = $Agent365RedirectUri
        PowerPlatformEnvironmentUrl = $PowerPlatformEnvironmentUrl
        # Secret references are an agent-path concept; the wizard asks the operator instead.
        ClientSecretRef         = $null
        Agent365RefreshTokenRef = $null
    }

    $applyResult = Invoke-EntraSourceApply -Resolved $resolved -TargetAppObjectId $targetAppObjectId -CreateSecret $createSecret
    $runDir = Join-Path $OutputDirectory (Join-Path 'agent-runs' 'interactive')
    if (-not (Test-Path -LiteralPath $runDir)) {
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    }
    $result = Build-EntraSourceResult -Resolved $resolved -ApplyResult $applyResult -RunDirectory $runDir

    $entraSavePath = Join-Path $OutputDirectory 'sailpoint-entra-connection-settings.txt'
    Invoke-CompletionActionMenu -Title 'Next: complete ISC Connection Settings' `
        -Situation $result.situation `
        -Items $result.completionItems `
        -AllowSaveToDisk `
        -SavePath $entraSavePath
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    if (Get-EntraCreatedAppId) {
        Write-Warning "Application $(Get-EntraCreatedAppId) was created before this failure. Re-run the script with the same display name to finish configuring it."
    }
    Write-Error $_
    exit 1
}
