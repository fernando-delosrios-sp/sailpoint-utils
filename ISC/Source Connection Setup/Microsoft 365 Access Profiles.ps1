#Requires -Version 5.1
<#
.SYNOPSIS
    Creates requestable SailPoint access profiles from Microsoft Entra service-plan entitlements.

.DESCRIPTION
    Interactive wizard that:
      1. Picks an ISC environment from ~/.sailpoint/config.yaml (or creates URL entries) and
         authenticates via PSSailpoint using SAIL_* env vars or config.json — no sail CLI required.
      2. Lists Entra ISC sources that already have type=servicePlan entitlements.
      3. Shows Microsoft-friendly plan names for Space multi-select.
      4. Creates prefixed, requestable access profiles and optionally a source app to group them.

.PARAMETER Environment
    Named environment from ~/.sailpoint/config.yaml.

.PARAMETER ConfigPath
    Optional path to a PSSailpoint config.json (BaseURL, ClientId, ClientSecret).

.PARAMETER SailpointConfigPath
    Optional path to the CLI-style YAML catalog. Default: ~/.sailpoint/config.yaml.

.PARAMETER SourceId
    ISC source id to use (skips source picker when provided).

.PARAMETER PlanValues
    Service plan entitlement values (GUIDs) or internal names to select non-interactively.

.PARAMETER AccessProfilePrefix
    Prefix for access profile names. Default: "M365 - ".

.PARAMETER ApplicationName
    Source app name. When omitted interactively, the operator is asked whether to create one.

.PARAMETER SkipApplication
    Do not create or link a source app.

.PARAMETER OwnerId
    Identity id that owns the access profiles and source app. Default: the identity that owns the current PAT.

.PARAMETER PreviousManifestPath
    Previous JSON or CSV manifest to replay. Source, plans, names, prefix, and application are reused when present.

.PARAMETER ExistingItemAction
    How to handle access profiles and the source app when they already exist: Ask, Skip, or Update.

.PARAMETER OutputDirectory
    Directory for the result manifest. Default: ./sourceConfig/m365-access-profiles

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\Microsoft 365 Access Profiles.ps1

.EXAMPLE
    .\Microsoft 365 Access Profiles.ps1 -Environment emea-tes-team -SourceId fd753b8266b64d09805d101b77bc35df `
        -PlanValues FLOW_O365_P3,TEAMS1 -ApplicationName 'Microsoft 365' -NonInteractive
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$Environment,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$SailpointConfigPath,

    [Parameter()]
    [string]$SourceId,

    [Parameter()]
    [string[]]$PlanValues,

    [Parameter()]
    [string]$AccessProfilePrefix = 'M365 - ',

    [Parameter()]
    [string]$ApplicationName,

    [Parameter()]
    [switch]$SkipApplication,

    [Parameter()]
    [string]$OwnerId,

    [Parameter()]
    [string]$PreviousManifestPath,

    [Parameter()]
    [ValidateSet('Ask', 'Skip', 'Update')]
    [string]$ExistingItemAction = 'Ask',

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.SailPointSdk.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.Microsoft365AccessProfiles.psm1') -Force
Initialize-OperatorConsole -NonInteractive:$NonInteractive

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Microsoft 365 access profiles' -ForegroundColor Cyan
    Write-Host '  Build requestable APs from Entra service-plan entitlements.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Read-SecureSecret {
    param([Parameter(Mandatory)][string]$Prompt)

    if ($NonInteractive) {
        throw "Non-interactive mode requires credentials via SAIL_* or config.json ($Prompt)."
    }
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Resolve-IscEnvironmentAndCredentials {
    param(
        [string]$EnvironmentName,
        [string]$ConfigPath,
        [string]$SailpointConfigPath
    )

    $catalog = Get-SailpointCliEnvironments -ConfigPath $SailpointConfigPath
    $selectedEnv = $null

    if ($EnvironmentName) {
        $selectedEnv = @($catalog.Environments | Where-Object { $_.Name -eq $EnvironmentName } | Select-Object -First 1)
        if (-not $selectedEnv) {
            throw "Environment '$EnvironmentName' was not found in $($catalog.Path)."
        }
    }
    elseif (-not $NonInteractive) {
        $options = [System.Collections.Generic.List[string]]::new()
        $labels = [System.Collections.Generic.List[string]]::new()
        foreach ($env in @($catalog.Environments)) {
            $options.Add($env.Name)
            $activeMark = if ($env.Name -eq $catalog.ActiveEnvironment) { '  (active)' } else { '' }
            $labels.Add("$($env.Name)  $($env.BaseUrl)$activeMark")
        }
        $options.Add('__create__')
        $labels.Add('Create / update environment URLs in ~/.sailpoint/config.yaml')

        $default = if ($catalog.ActiveEnvironment -and $options -contains $catalog.ActiveEnvironment) {
            $catalog.ActiveEnvironment
        }
        elseif ($options.Count -gt 1) {
            $options[0]
        }
        else {
            '__create__'
        }

        $picked = Read-Choice -Prompt 'Select an ISC environment:' -Options @($options) -Labels @($labels) -Default $default
        if ($picked -eq '__create__') {
            $name = Read-InputString -Prompt 'Environment name' -Required
            $tenantUrl = Read-InputString -Prompt 'Tenant URL (https://tenant.identitynow.com)' -Required
            $baseUrl = Read-InputString -Prompt 'API URL (https://tenant.api.identitynow.com)' -Required
            $null = Save-SailpointCliEnvironmentUrls -Name $name -BaseUrl $baseUrl -TenantUrl $tenantUrl `
                -ConfigPath $SailpointConfigPath -SetActive
            $catalog = Get-SailpointCliEnvironments -ConfigPath $SailpointConfigPath
            $selectedEnv = @($catalog.Environments | Where-Object { $_.Name -eq $name } | Select-Object -First 1)
        }
        else {
            $selectedEnv = @($catalog.Environments | Where-Object { $_.Name -eq $picked } | Select-Object -First 1)
        }
    }
    elseif ($catalog.ActiveEnvironment) {
        $selectedEnv = @($catalog.Environments | Where-Object { $_.Name -eq $catalog.ActiveEnvironment } | Select-Object -First 1)
    }

    $preferredBaseUrl = if ($selectedEnv) { $selectedEnv.BaseUrl } else { $null }
    $creds = Resolve-SailpointSdkCredentials -ConfigPath $ConfigPath -PreferredBaseUrl $preferredBaseUrl

    if (-not $creds) {
        if ($NonInteractive) {
            throw 'Provide SAIL_BASE_URL / SAIL_CLIENT_ID / SAIL_CLIENT_SECRET or -ConfigPath to a config.json.'
        }
        Write-Step 'PSSailpoint credentials'
        Write-Info 'The SDK reads process env SAIL_* or a local config.json. Secrets stay in this process only.'
        $baseUrl = if ($preferredBaseUrl) {
            Read-InputString -Prompt 'API Base URL' -Default $preferredBaseUrl -Required
        }
        else {
            Read-InputString -Prompt 'API Base URL (https://tenant.api.identitynow.com)' -Required
        }
        $clientId = Read-InputString -Prompt 'PAT Client ID' -Required
        $clientSecret = Read-SecureSecret -Prompt 'PAT Client Secret'
        Set-SailpointProcessCredentials -BaseUrl $baseUrl -ClientId $clientId -ClientSecret $clientSecret
        $creds = Resolve-SailpointSdkCredentials -PreferredBaseUrl $baseUrl
    }
    elseif ($preferredBaseUrl -and $creds.Source -ne 'environment') {
        # Prefer selected YAML base URL when credentials came from a generic config.json without matching host.
        if ($creds.BaseUrl.TrimEnd('/') -ne $preferredBaseUrl.TrimEnd('/') -and -not $ConfigPath) {
            Write-Info "Using API URL from environment '$($selectedEnv.Name)': $preferredBaseUrl"
            Set-SailpointProcessCredentials -BaseUrl $preferredBaseUrl -ClientId $creds.ClientId -ClientSecret $creds.ClientSecret
            $creds = Resolve-SailpointSdkCredentials -PreferredBaseUrl $preferredBaseUrl
        }
    }

    return [pscustomobject]@{
        Environment = $selectedEnv
        Credentials = $creds
    }
}

try {
    Write-Banner

    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path (Join-Path $PSScriptRoot 'sourceConfig') 'm365-access-profiles'
    }

    $previousManifest = $null
    if ($PreviousManifestPath) {
        $previousManifest = Read-M365AccessProfileManifest -Path $PreviousManifestPath
        Write-Ok "Loaded $($previousManifest.Format) manifest: $($previousManifest.Path)"
        if (-not $PSBoundParameters.ContainsKey('Environment') -and $previousManifest.Environment) {
            $Environment = $previousManifest.Environment
        }
        if (-not $PSBoundParameters.ContainsKey('SourceId') -and $previousManifest.SourceId) {
            $SourceId = $previousManifest.SourceId
        }
        if (-not $PSBoundParameters.ContainsKey('AccessProfilePrefix') -and $previousManifest.Prefix) {
            $AccessProfilePrefix = $previousManifest.Prefix
        }
        if (-not $PSBoundParameters.ContainsKey('ApplicationName') -and
            -not $PSBoundParameters.ContainsKey('SkipApplication') -and
            $previousManifest.ApplicationName) {
            $ApplicationName = $previousManifest.ApplicationName
        }
    }

    $resolved = $null
    $source = $null
    $selectedRows = @()
    $owner = $null
    $prefix = $AccessProfilePrefix
    $createApp = -not $SkipApplication
    $appName = $ApplicationName
    $existingAction = if ($ExistingItemAction -eq 'Ask' -and $NonInteractive) { 'Skip' } else { $ExistingItemAction }

    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            if (Enter-WizardPrompt) {
                $resolved = Resolve-IscEnvironmentAndCredentials -EnvironmentName $Environment `
                    -ConfigPath $ConfigPath -SailpointConfigPath $SailpointConfigPath
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                Write-Step 'Connecting with PSSailpoint ...'
                Initialize-SailPointSdkSession -Credentials $resolved.Credentials -Experimental
                $null = Test-SailPointSdkConnection
                $envLabel = if ($resolved.Environment) { $resolved.Environment.Name } else { $resolved.Credentials.BaseUrl }
                Write-Ok "Connected to $envLabel"
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($SourceId) {
                    $sourceObj = Get-SourceV1 -Id $SourceId -ErrorAction Stop
                    $plans = @(Get-ServicePlanEntitlementsForSource -SourceId $SourceId)
                    if ($plans.Count -eq 0) {
                        throw "Source $SourceId has no servicePlan entitlements."
                    }
                    $source = [pscustomobject]@{
                        Id           = [string]$sourceObj.id
                        Name         = [string]$sourceObj.name
                        Type         = [string]$sourceObj.type
                        PlanCount    = $plans.Count
                        Source       = $sourceObj
                        ServicePlans = $plans
                    }
                }
                else {
                    Write-Step 'Scanning ISC for Entra sources with service plans ...'
                    # Materialize to a List so a single hit stays one object (not a char-split string[]).
                    $candidateList = [System.Collections.Generic.List[object]]::new()
                    foreach ($item in @(Find-EntraSourcesWithServicePlans)) {
                        $candidateList.Add($item)
                    }
                    if ($candidateList.Count -eq 0) {
                        throw 'No Entra sources with servicePlan entitlements were found.'
                    }
                    [string[]]$options = @(foreach ($c in $candidateList) { [string]$c.Id })
                    [string[]]$labels = @(
                        foreach ($c in $candidateList) {
                            "$($c.Name)  ($($c.PlanCount) service plans)  [$($c.Id)]"
                        }
                    )
                    $pickedId = Read-Choice -Prompt 'Select an Entra source:' -Options $options -Labels $labels -Default $options[0]
                    $source = @($candidateList | Where-Object { $_.Id -eq $pickedId } | Select-Object -First 1)[0]
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                Write-Step 'Loading Microsoft friendly service-plan names ...'
                $map = Get-MicrosoftServicePlanFriendlyNameMap
                # Re-fetch plans for the selected source so counts/ids are flat and current.
                $plans = @(Get-ServicePlanEntitlementsForSource -SourceId $source.Id)
                if ($plans.Count -eq 0 -and $source.ServicePlans) {
                    $plans = @(Expand-EntitlementList -Entitlements $source.ServicePlans)
                }
                Write-Info "$($plans.Count) service plan entitlement(s) on $($source.Name)"
                $rows = @(Build-ServicePlanSelectionRows -Entitlements $plans -FriendlyNameMap $map)
                if ($rows.Count -eq 0) {
                    throw 'No service-plan entitlements could be mapped for selection.'
                }
                if ($previousManifest) {
                    $selectedList = [System.Collections.Generic.List[object]]::new()
                    foreach ($manifestRow in @($previousManifest.Results)) {
                        $manifestEntitlementId = [string](Get-ObjectPropertySafe -Object $manifestRow -Name 'EntitlementId')
                        $manifestInternalName = [string](Get-ObjectPropertySafe -Object $manifestRow -Name 'InternalName')
                        $manifestValue = [string](Get-ObjectPropertySafe -Object $manifestRow -Name 'EntitlementValue')
                        $matched = @(
                            $rows | Where-Object {
                                ($manifestEntitlementId -and $_.Id -eq $manifestEntitlementId) -or
                                ($manifestInternalName -and $_.InternalName -ieq $manifestInternalName) -or
                                ($manifestValue -and $_.Value -ieq $manifestValue)
                            } | Select-Object -First 1
                        )
                        if ($matched.Count -eq 0) {
                            $key = if ($manifestInternalName) { $manifestInternalName } else { $manifestEntitlementId }
                            throw "Manifest entitlement '$key' was not found on source $($source.Name)."
                        }
                        $desiredName = Get-M365ReplayAccessProfileName -ManifestRow $manifestRow `
                            -CurrentFriendlyName $matched[0].FriendlyName `
                            -ManifestPrefix $previousManifest.Prefix
                        $selectedList.Add([pscustomobject]@{
                                Id                       = $matched[0].Id
                                InternalName             = $matched[0].InternalName
                                FriendlyName             = $matched[0].FriendlyName
                                Value                    = $matched[0].Value
                                Label                    = $matched[0].Label
                                DesiredAccessProfileName = $desiredName
                            })
                    }
                    $selectedRows = @($selectedList.ToArray())
                }
                elseif ($PlanValues -and $PlanValues.Count -gt 0) {
                    $wanted = [System.Collections.Generic.HashSet[string]]::new(
                        [string[]]@($PlanValues | ForEach-Object { $_.ToUpperInvariant() })
                    )
                    $selectedRows = @(
                        $rows | Where-Object {
                            $wanted.Contains($_.InternalName.ToUpperInvariant()) -or
                            ($_.Value -and $wanted.Contains($_.Value.ToUpperInvariant()))
                        }
                    )
                    if ($selectedRows.Count -eq 0) {
                        throw 'None of the -PlanValues matched service plans on the selected source.'
                    }
                }
                else {
                    [string[]]$planOptions = @(
                        foreach ($r in @($rows)) {
                            if (-not [string]::IsNullOrWhiteSpace([string]$r.Id)) { [string]$r.Id }
                        }
                    )
                    [string[]]$planLabels = @(
                        foreach ($r in @($rows)) {
                            if (-not [string]::IsNullOrWhiteSpace([string]$r.Id)) { [string]$r.Label }
                        }
                    )
                    if ($planOptions.Count -eq 0 -or $planOptions.Count -ne $planLabels.Count) {
                        throw "Unable to build plan selection options (options=$($planOptions.Count), labels=$($planLabels.Count))."
                    }
                    $pickedIds = @(Read-MultiChoice -Prompt 'Select service plans to wrap as access profiles (Space toggles):' `
                            -Options ([string[]]$planOptions) -Labels ([string[]]$planLabels))
                    if ($pickedIds.Count -eq 0) {
                        throw 'Select at least one service plan.'
                    }
                    $idSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$pickedIds)
                    $selectedRows = @($rows | Where-Object { $idSet.Contains($_.Id) })
                }
                Write-Ok "$($selectedRows.Count) plan(s) selected"
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if (-not $previousManifest) {
                    $prefix = Read-InputString -Prompt 'Access profile name prefix' -Default $AccessProfilePrefix
                    if ($null -eq $prefix) { $prefix = '' }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($SkipApplication) {
                    $createApp = $false
                }
                elseif ($ApplicationName) {
                    $createApp = $true
                    $appName = $ApplicationName
                }
                else {
                    $createApp = Read-YesNo -Prompt 'Create or reuse a source application to group these access profiles?' -Default $true
                    if ($createApp) {
                        $defaultAppName = "Microsoft 365 ($($source.Name))"
                        $appName = Read-InputString -Prompt 'Application name' -Default $defaultAppName -Required
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($existingAction -eq 'Ask') {
                    $existingAction = Read-Choice -Prompt 'When an access profile or application already exists:' `
                        -Options @('Skip', 'Update') `
                        -Labels @(
                            'Skip it (leave the existing item unchanged)'
                            'Update it (fully reconcile owner, settings, source, entitlements, and app membership)'
                        ) `
                        -Default 'Skip'
                }
                Complete-WizardPrompt
            }

            $wizardComplete = $true
        }
        catch {
            if (Test-PromptBack $_) {
                Move-WizardBack
                continue
            }
            throw
        }
    }

    Write-Step 'Resolving owner (current ISC identity) ...'
    $ownerIdentity = Get-CurrentIscIdentity -OwnerId $OwnerId
    $owner = $ownerIdentity.Id
    $ownerLabel = if ($ownerIdentity.Name) { "$($ownerIdentity.Name) [$owner]" } else { $owner }
    Write-Ok $ownerLabel

    Write-Host ''
    Write-Host 'Summary' -ForegroundColor White
    Write-Host "  Source:      $($source.Name) [$($source.Id)]"
    Write-Host "  Profiles:    $($selectedRows.Count) (prefix '$prefix')"
    Write-Host "  Owner:       $ownerLabel"
    Write-Host "  Existing:    $existingAction"
    if ($createApp) { Write-Host "  Application: $appName" } else { Write-Host '  Application: (skipped)' }
    Write-Host ''

    $target = "$($selectedRows.Count) access profile(s) on source $($source.Name)"
    if (-not $PSCmdlet.ShouldProcess($target, 'Create or reuse access profiles')) {
        return
    }

    if (-not $NonInteractive) {
        if (-not (Read-YesNo -Prompt 'Proceed with creating / linking access profiles?' -Default $true)) {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
    }

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($row in $selectedRows) {
        $apName = if ($previousManifest -and $row.DesiredAccessProfileName) {
            $row.DesiredAccessProfileName
        }
        else {
            New-AccessProfileName -Prefix $prefix -FriendlyName $row.FriendlyName
        }
        Write-Step $apName
        $outcome = Resolve-OrCreateAccessProfileForPlan -Name $apName -SourceId $source.Id -SourceName $source.Name `
            -OwnerId $owner -EntitlementId $row.Id -ExistingItemAction $existingAction -WhatIf:$WhatIfPreference
        Write-Ok "$($outcome.Status): $($outcome.Message)"
        $results.Add([pscustomobject]@{
                InternalName      = $row.InternalName
                FriendlyName      = $row.FriendlyName
                EntitlementId     = $row.Id
                EntitlementValue = $row.Value
                AccessProfileName = $apName
                AccessProfileId   = $outcome.AccessProfileId
                Status            = $outcome.Status
                Message           = $outcome.Message
            })
    }

    $appOutcome = $null
    $createdIds = @($results | Where-Object { $_.AccessProfileId } | ForEach-Object { $_.AccessProfileId })
    $missingIds = @($results | Where-Object { -not $_.AccessProfileId -and $_.Status -in @('created', 'updated', 'skipped') })
    if ($createApp -and $appName) {
        Write-Step "Source application: $appName"
        $appOutcome = Resolve-OrCreateSourceApp -Name $appName -SourceId $source.Id -OwnerId $owner `
            -ExistingItemAction $existingAction -WhatIf:$WhatIfPreference
        Write-Ok "$($appOutcome.Status) ($($appOutcome.AppId))"
        if ($missingIds.Count -gt 0) {
            Write-Warning "$($missingIds.Count) access profile(s) have no id and cannot be linked to $appName. Rerun with the same prefix to link them."
        }
        if (-not $appOutcome.AppId) {
            Write-Warning "Source application '$appName' has no id; access profiles were not linked."
        }
        elseif ($appOutcome.Status -eq 'skipped') {
            Write-Info "Existing source application skipped; membership was not changed."
        }
        elseif ($createdIds.Count -eq 0) {
            Write-Warning "No access profile ids to link to $appName."
        }
        else {
            $link = Add-AccessProfilesToSourceApp -AppId $appOutcome.AppId -AccessProfileIds $createdIds -WhatIf:$WhatIfPreference
            Write-Ok "App link: $($link.Status) (+$((@($link.Added)).Count) of $($createdIds.Count))"
        }
    }

    $manifest = [pscustomobject]@{
        GeneratedAt   = (Get-Date).ToString('o')
        Environment   = $(if ($resolved.Environment) { $resolved.Environment.Name } else { $null })
        BaseUrl       = $resolved.Credentials.BaseUrl
        SourceId      = $source.Id
        SourceName    = $source.Name
        OwnerId       = $owner
        Prefix        = $prefix
        Application   = $(if ($appOutcome) { [pscustomobject]@{ Name = $appOutcome.Name; Id = $appOutcome.AppId; Status = $appOutcome.Status } } else { $null })
        Results       = @($results)
    }

    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Green
    $created = @($results | Where-Object { $_.Status -eq 'created' }).Count
    $updated = @($results | Where-Object { $_.Status -eq 'updated' }).Count
    $skipped = @($results | Where-Object { $_.Status -eq 'skipped' }).Count
    $conflicts = @($results | Where-Object { $_.Status -eq 'conflict' }).Count
    Write-Host "  Created $created, updated $updated, skipped $skipped, conflicts $conflicts." -ForegroundColor White

    $saveFormat = $null
    if ($NonInteractive) {
        $saveFormat = 'Both'
    }
    else {
        try {
            $saveFormat = Read-Choice -Prompt 'Save a run manifest?' `
                -Options @('Json', 'Csv', 'skip') `
                -Labels @('Save JSON manifest', 'Save CSV manifest', "Don't save") `
                -Default 'skip' `
                -EscapeMeansDefault
        }
        catch {
            if (Test-PromptBack $_) {
                $saveFormat = 'skip'
            }
            else {
                throw
            }
        }
    }

    if ($saveFormat -and $saveFormat -ne 'skip') {
        $paths = Write-M365AccessProfileManifest -Manifest $manifest -OutputDirectory $OutputDirectory -Format $saveFormat
        if ($paths.JsonPath) {
            Write-Ok "JSON manifest: $($paths.JsonPath)"
        }
        if ($paths.CsvPath) {
            Write-Ok "CSV manifest: $($paths.CsvPath)"
        }
    }
}
catch {
    if (Test-PromptBack $_) {
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        exit 0
    }
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    exit 1
}
