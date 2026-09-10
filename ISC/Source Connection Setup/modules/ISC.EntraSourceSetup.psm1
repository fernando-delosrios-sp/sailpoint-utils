#Requires -Version 5.1
Set-StrictMode -Version Latest

function Import-SourceSetupModule {
    param(
        [Parameter(Mandatory)][string]$ModuleRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FileName
    )

    if (-not (Get-Module -Name $Name)) {
        Import-Module (Join-Path $ModuleRoot $FileName) -Force -Global -WarningAction SilentlyContinue
    }
}

function Import-AgentAdapterModule {
    if (-not (Get-Module -Name 'ISC.AgentAdapter')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.AgentAdapter.psm1') -Force -WarningAction SilentlyContinue
    }
}

function Initialize-EntraSourceSetup {
    param(
        [string]$ModuleRoot,
        [switch]$NonInteractive
    )

    if (-not $ModuleRoot) {
        $ModuleRoot = $PSScriptRoot
    }
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorConsole' -FileName 'ISC.OperatorConsole.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorToolchain' -FileName 'ISC.OperatorToolchain.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.EntraConnector' -FileName 'ISC.EntraConnector.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.EntraCiemConnector' -FileName 'ISC.EntraCiemConnector.psm1'
    Initialize-OperatorConsole -NonInteractive:$NonInteractive
    Initialize-EntraConnectorData
    Initialize-EntraCiemConnectorData
}

function Get-EntraAgentCatalog {
    Initialize-EntraSourceSetup
    $catalog = Get-EntraConnectorCatalog
    return [ordered]@{
        permissionModes = @('Granular', 'Directory')
        featurePacks    = @($catalog.FeaturePacks.Keys)
        directoryRoles  = @($catalog.DirectoryRoleMap.Keys)
        requiredConfig  = @('applicationName')
        optionalConfig  = @('tenantId', 'permissionMode', 'features', 'directoryRole', 'rotateSecret', 'outputDirectory')
        secretFields    = @('clientSecret')
    }
}

function Get-EntraResolvedConfig {
    param($Request)

    Import-AgentAdapterModule
    $config = Get-AgentRequestValue -Object $Request -Name 'config' -Default @{}
    $decisions = Get-AgentRequestValue -Object $Request -Name 'decisions' -Default @{}
    return [PSCustomObject]@{
        TenantId             = $(if (Get-AgentRequestValue -Object $config -Name 'tenantId') { [string](Get-AgentRequestValue -Object $config -Name 'tenantId') } else { $null })
        ApplicationName      = [string](Get-AgentRequestValue -Object $config -Name 'applicationName')
        PermissionMode       = if (Get-AgentRequestValue -Object $config -Name 'permissionMode') { [string](Get-AgentRequestValue -Object $config -Name 'permissionMode') } else { 'Granular' }
        Feature              = @($(Get-AgentRequestValue -Object $config -Name 'features' -Default @()))
        DirectoryRole        = if (Get-AgentRequestValue -Object $config -Name 'directoryRole') { [string](Get-AgentRequestValue -Object $config -Name 'directoryRole') } else { 'UserAdministrator' }
        SecretDisplayName    = if (Get-AgentRequestValue -Object $config -Name 'secretDisplayName') { [string](Get-AgentRequestValue -Object $config -Name 'secretDisplayName') } else { 'ISC' }
        SecretValidityMonths = if (Get-AgentRequestValue -Object $config -Name 'secretValidityMonths') { [int](Get-AgentRequestValue -Object $config -Name 'secretValidityMonths') } else { 24 }
        RotateSecret         = [bool](Get-AgentRequestValue -Object $config -Name 'rotateSecret' -Default $false)
        OutputDirectory      = if (Get-AgentRequestValue -Object $config -Name 'outputDirectory') { [string](Get-AgentRequestValue -Object $config -Name 'outputDirectory') } else { (Join-Path (Get-Location) (Join-Path 'sourceConfig' 'entra-id-isc')) }
        TargetAppObjectId    = $(if (Get-AgentRequestValue -Object $decisions -Name 'targetAppObjectId') { [string](Get-AgentRequestValue -Object $decisions -Name 'targetAppObjectId') } else { $null })
        CreateNewApplication = $(if ($null -ne (Get-AgentRequestValue -Object $decisions -Name 'createNewApplication')) { [bool](Get-AgentRequestValue -Object $decisions -Name 'createNewApplication') } else { $null })
        AllowGlobalAdmin     = [bool](Get-AgentRequestValue -Object $decisions -Name 'allowGlobalAdministrator' -Default $false)
        CreateSecret         = $(if ($null -ne (Get-AgentRequestValue -Object $decisions -Name 'createSecret')) { [bool](Get-AgentRequestValue -Object $decisions -Name 'createSecret') } else { -not [bool](Get-AgentRequestValue -Object $config -Name 'skipSecret' -Default $false) })
    }
}

function New-EntraAgentPlan {
    param([Parameter(Mandatory)]$Request)

    Initialize-EntraSourceSetup
    $resolved = Get-EntraResolvedConfig -Request $Request
    $needsInput = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $manualSteps = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($resolved.ApplicationName)) {
        $needsInput.Add([ordered]@{ field = 'applicationName'; reason = 'Application display name is required.' })
    }

    if ($resolved.DirectoryRole -eq 'GlobalAdministrator' -and -not $resolved.AllowGlobalAdmin) {
        $needsInput.Add([ordered]@{ field = 'decisions.allowGlobalAdministrator'; reason = 'Global Administrator is high risk; set true to proceed.' })
    }

    $discoveries = [ordered]@{}
    $mutations = @('connect-graph', 'resolve-permissions', 'create-or-update-app', 'grant-consent', 'assign-directory-roles')
    if ($resolved.CreateSecret -or $resolved.RotateSecret) {
        $mutations += 'create-client-secret'
    }

    if (-not [string]::IsNullOrWhiteSpace($resolved.ApplicationName)) {
        try {
            Ensure-MicrosoftGraphModules
            $session = Connect-EntraGraph -RequestedTenantId $resolved.TenantId
            $discoveries.tenantId = $session.TenantId
            $discoveries.domainName = $session.DomainName
            $existingApps = @(Find-EntraApplicationByName -DisplayName $resolved.ApplicationName)
            $discoveries.existingApplications = @($existingApps | ForEach-Object {
                [ordered]@{ objectId = $_.Id; appId = $_.AppId; displayName = $_.DisplayName }
            })
            if ($existingApps.Count -eq 1 -and -not $resolved.TargetAppObjectId -and $null -eq $resolved.CreateNewApplication) {
                $needsInput.Add([ordered]@{
                    field  = 'decisions'
                    reason = "Application '$($resolved.ApplicationName)' already exists."
                    options = @(
                        [ordered]@{ decision = 'targetAppObjectId'; value = $existingApps[0].Id; label = 'Update existing application' }
                        [ordered]@{ decision = 'createNewApplication'; value = $true; label = 'Create new application with a different name' }
                    )
                })
            }
            if ($existingApps.Count -gt 1 -and -not $resolved.TargetAppObjectId -and $null -eq $resolved.CreateNewApplication) {
                $needsInput.Add([ordered]@{
                    field  = 'decisions.targetAppObjectId'
                    reason = 'Multiple applications share this display name.'
                    options = @($existingApps | ForEach-Object {
                        [ordered]@{ value = $_.Id; appId = $_.AppId; displayName = $_.DisplayName }
                    })
                })
            }
        }
        catch {
            $warnings.Add("Live discovery skipped: $($_.Exception.Message)")
            $manualSteps.Add('Sign in with Microsoft Graph (Connect-MgGraph) before Apply.')
        }
    }

    $manualSteps.Add('Grant admin consent in Entra portal if automated consent fails.')
    $manualSteps.Add('Assign Reader role at tenant root management group for read-only Azure cloud object access.')

    $status = if ($needsInput.Count -gt 0) { 'needsInput' } else { 'ready' }
    return [ordered]@{
        status      = $status
        requestHash = (Get-AgentRequestHash -Request $Request)
        resolved    = $resolved
        discoveries = $discoveries
        mutations   = $mutations
        prerequisites = @('Microsoft Graph PowerShell modules', 'Entra admin rights')
        warnings    = @($warnings)
        manualSteps = @($manualSteps)
        needsInput  = @($needsInput)
    }
}

function Invoke-EntraSourceApply {
    param(
        [Parameter(Mandatory)]$Resolved,
        [string]$TargetAppObjectId,
        [bool]$CreateSecret,
        [switch]$WhatIf
    )

    $catalog = Get-EntraConnectorCatalog
    $session = Connect-EntraGraph -RequestedTenantId $Resolved.TenantId
    $TenantId = $session.TenantId
    $isUpdate = [bool]$TargetAppObjectId
    $permissions = @(Get-SelectedPermissions -Mode $Resolved.PermissionMode -FeatureNames $Resolved.Feature)
    $roleNames = @($catalog.DirectoryRoleMap[$Resolved.DirectoryRole])

    if ($WhatIf) {
        return [PSCustomObject]@{
            Session         = $session
            IsUpdate        = $isUpdate
            Permissions     = $permissions
            RoleNames       = $roleNames
            ConsentFailures = @()
            Pair            = $null
            SecretValue     = $null
            SecretExpires   = $null
            AssignedRoles   = @()
        }
    }

    Write-Step 'Resolving API permissions'
    $rolesByResource = @{}
    $resourceServicePrincipals = @{}
    foreach ($group in ($permissions | Group-Object Resource)) {
        $resourceKey = $group.Name
        $resource = $catalog.Resources[$resourceKey]
        $resourceSp = Get-ApiServicePrincipal -AppId $resource.AppId -Name $resource.Name
        if (-not $resourceSp) {
            if ($resource.Required) {
                throw "The $($resource.Name) service principal was not found in tenant $TenantId."
            }
            continue
        }
        $roles = @(Resolve-AppRoles -ServicePrincipal $resourceSp -PermissionValues @($group.Group.Value) -ResourceName $resource.Name)
        if ($roles.Count -eq 0) {
            if ($resource.Required) { throw "No $($resource.Name) application permissions could be resolved." }
            continue
        }
        $rolesByResource[$resourceKey] = $roles
        $resourceServicePrincipals[$resourceKey] = $resourceSp
    }

    Write-Step $(if ($isUpdate) { 'Updating application' } else { 'Creating application' })
    if ($isUpdate) {
        $pair = Get-EntraConnectorApplication -ApplicationObjectId $TargetAppObjectId
        Write-Ok "Using application $($pair.Application.AppId)"
    }
    else {
        $pair = New-EntraConnectorApplication -DisplayName $Resolved.ApplicationName
        Write-Ok "Created application $($pair.Application.AppId)"
    }

    Write-Step 'Updating requested API permissions'
    Set-RequiredResourceAccess -Application $pair.Application -RolesByResource $rolesByResource
    Write-Ok 'Application manifest updated'

    Write-Step 'Granting admin consent'
    $consentFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($resourceKey in $rolesByResource.Keys) {
        $result = Grant-AppRoleConsent -ServicePrincipal $pair.ServicePrincipal `
            -ResourceServicePrincipal $resourceServicePrincipals[$resourceKey] `
            -AppRoles $rolesByResource[$resourceKey]
        foreach ($failure in $result.Failed) { $consentFailures.Add($failure) }
    }

    $assignedRoles = @()
    if ($roleNames.Count -gt 0) {
        Write-Step 'Assigning directory roles'
        $assignedRoles = @(Add-EntraDirectoryRoles -ServicePrincipal $pair.ServicePrincipal -RoleDisplayNames $roleNames)
    }

    $secretValue = $null
    $secretExpires = $null
    if ($CreateSecret) {
        Write-Step 'Creating client secret'
        $secret = New-EntraClientSecret -Application $pair.Application -DisplayName $Resolved.SecretDisplayName -ValidityMonths $Resolved.SecretValidityMonths
        Write-Ok "Secret '$($Resolved.SecretDisplayName)' created, expires $($secret.EndDateTime)"
        $secretValue = $secret.SecretText
        $secretExpires = $secret.EndDateTime
    }

    return [PSCustomObject]@{
        Session         = $session
        IsUpdate        = $isUpdate
        Permissions     = $permissions
        RoleNames       = $roleNames
        ConsentFailures = @($consentFailures)
        Pair            = $pair
        SecretValue     = $secretValue
        SecretExpires   = $secretExpires
        AssignedRoles   = $assignedRoles
    }
}

function Build-EntraSourceResult {
    param(
        [Parameter(Mandatory)]$Resolved,
        [Parameter(Mandatory)]$ApplyResult,
        [string]$RunDirectory
    )

    $pair = $ApplyResult.Pair
    $domainName = if ($ApplyResult.Session.DomainName) { $ApplyResult.Session.DomainName } else { $ApplyResult.Session.TenantId }
    $situation = [System.Collections.Generic.List[string]]::new()
    $situation.Add('Entra ID application setup is complete. Paste the Connection Settings values into ISC.')
    if ($ApplyResult.ConsentFailures.Count -gt 0) {
        $situation.Add("Pending: grant admin consent in the Entra portal for: $($ApplyResult.ConsentFailures -join ', ').")
    }
    if ($ApplyResult.RoleNames.Count -gt 0) {
        $missingRoles = @($ApplyResult.RoleNames | Where-Object { $ApplyResult.AssignedRoles -notcontains $_ })
        if ($missingRoles.Count -gt 0) {
            $situation.Add("Pending: assign directory role(s) to the service principal: $($missingRoles -join ', ').")
        }
    }
    if ($ApplyResult.SecretValue) {
        $situation.Add('Store the client secret now — Microsoft will not display it again.')
    }

    $fields = [ordered]@{
        'Grant Type'  = 'Client Credentials'
        'Client ID'   = [string]$pair.Application.AppId
        'Domain Name' = $domainName
    }

    $secretArtifacts = @()
    if ($ApplyResult.SecretValue) {
        $secretPath = Join-Path $RunDirectory 'client-secret.txt'
        Set-AgentRestrictedFile -Path $secretPath -Content $ApplyResult.SecretValue
        $fields['Client Secret'] = $ApplyResult.SecretValue
        $secretArtifacts += [ordered]@{ label = 'Client Secret'; path = $secretPath }
    }

    if (-not (Test-Path -LiteralPath $Resolved.OutputDirectory)) {
        New-Item -ItemType Directory -Path $Resolved.OutputDirectory -Force | Out-Null
    }
    $settingsPath = Join-Path $Resolved.OutputDirectory 'sailpoint-entra-connection-settings.txt'
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $publicSettings = [ordered]@{
        'Grant Type'  = 'Client Credentials'
        'Client ID'   = [string]$pair.Application.AppId
        'Domain Name' = $domainName
    }

    $portalUrl = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($pair.Application.AppId)"
    $permissionsUrl = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($pair.Application.AppId)"
    foreach ($checklistItem in @(Get-EntraIscFeatureChecklist -FeatureNames $Resolved.Feature)) {
        $situation.Add("ISC: $checklistItem")
    }
    $ciemCtx = @{ FeatureNames = $Resolved.Feature }
    Apply-EmbeddedCiemPrerequisites -Context $ciemCtx
    foreach ($entry in (Build-EmbeddedCiemConnectionSettings -Context $ciemCtx).GetEnumerator()) {
        $situation.Add("ISC: $($entry.Key) — $($entry.Value)")
    }

    $completionItems = @(
        [PSCustomObject]@{ Label = 'Grant Type'; Value = 'Client Credentials'; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Client ID'; Value = [string]$pair.Application.AppId; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Domain Name'; Value = $domainName; Kind = 'Copy'; Mask = $false }
    )
    if ($ApplyResult.SecretValue) {
        $completionItems += [PSCustomObject]@{ Label = 'Client Secret'; Value = $ApplyResult.SecretValue; Kind = 'Copy'; Mask = $true }
    }
    $completionItems += [PSCustomObject]@{ Label = 'Entra app overview'; Value = $portalUrl; Kind = 'Open'; Mask = $false }
    if ($ApplyResult.ConsentFailures.Count -gt 0) {
        $completionItems += [PSCustomObject]@{ Label = 'API permissions (grant consent)'; Value = $permissionsUrl; Kind = 'Open'; Mask = $false }
    }

    return [ordered]@{
        status             = 'ok'
        connectionSettings = $publicSettings
        artifacts          = @([ordered]@{ label = 'Connection settings'; path = $settingsPath })
        secretArtifacts    = $secretArtifacts
        manualSteps        = @($situation)
        verification       = [ordered]@{ appId = $pair.Application.AppId; tenantId = $ApplyResult.Session.TenantId }
        situation          = @($situation)
        completionItems    = $completionItems
    }
}

function Invoke-EntraAgentApply {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Plan,
        [switch]$WhatIf
    )

    Initialize-EntraSourceSetup
    Ensure-MicrosoftGraphModules
    $resolved = Get-EntraResolvedConfig -Request $Request
    if ($Plan.resolved) {
        foreach ($prop in $Plan.resolved.PSObject.Properties) {
            $resolved.$($prop.Name) = $prop.Value
        }
    }
    $targetAppObjectId = $resolved.TargetAppObjectId
    $createSecret = if ($resolved.CreateSecret) { $true } elseif ($resolved.RotateSecret) { $true } else { -not $targetAppObjectId }

    $applyResult = Invoke-EntraSourceApply -Resolved $resolved -TargetAppObjectId $targetAppObjectId -CreateSecret $createSecret -WhatIf:$WhatIf
    if ($WhatIf) {
        return [ordered]@{ status = 'whatIf'; mutations = $Plan.mutations; resolved = $resolved }
    }

    $run = New-AgentRunDirectory -ConnectorSlug 'entra-id-isc' -RunId (Get-AgentRequestValue -Object $Request -Name 'runId')
    return Build-EntraSourceResult -Resolved $resolved -ApplyResult $applyResult -RunDirectory $run.Path
}

Export-ModuleMember -Function @(
    'Initialize-EntraSourceSetup'
    'Get-EntraAgentCatalog'
    'Get-EntraResolvedConfig'
    'New-EntraAgentPlan'
    'Invoke-EntraSourceApply'
    'Build-EntraSourceResult'
    'Invoke-EntraAgentApply'
)
