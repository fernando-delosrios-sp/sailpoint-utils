#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstraps the ISC Demo Data access model (department, workforce, and office sources/roles).

.DESCRIPTION
    Loads config/demo-access-model.json, authenticates with PSSailpoint, and reconciles:
      - Delimited File sources (Department Services, Workforce Access, Workplace Access)
      - Entitlement CSV import / aggregation guidance
      - Source applications and Create Account provisioning policies
      - Birthright title and department roles (entitlements attached directly)
      - Five requestable SoD Demo roles (each contains a named policy violation)
      - Dimensional Workplace User role with city dimensions
      - Conflicting-access SoD policies and mitigating controls from config/demo-sod-policies.json

.PARAMETER Environment
    Named environment from ~/.sailpoint/config.yaml.

.PARAMETER ConfigPath
    Optional path to a PSSailpoint config.json (BaseURL, ClientId, ClientSecret).

.PARAMETER SailpointConfigPath
    Optional path to the CLI-style YAML catalog. Default: ~/.sailpoint/config.yaml.

.PARAMETER ModelPath
    Path to demo-access-model.json. Default: ./config/demo-access-model.json

.PARAMETER OwnerId
    Identity id that owns created objects. Default: alias slpt.services (SailPoint Services).

.PARAMETER ExistingItemAction
    How to handle objects that already exist: Skip or Update.

.PARAMETER WhatIf
    Build and report actions without creating or updating tenant objects.

.EXAMPLE
    .\Demo Data.ps1 -Environment emea-tes-team -WhatIf

.EXAMPLE
    .\Demo Data.ps1 -Environment emea-tes-team -ExistingItemAction Update
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
    [string]$ModelPath,

    [Parameter()]
    [string]$OwnerId,

    [Parameter()]
    [ValidateSet('Skip', 'Update')]
    [string]$ExistingItemAction = 'Skip'
)

$ErrorActionPreference = 'Stop'
$demoRoot = $PSScriptRoot
$sourceSetupModules = Join-Path (Split-Path -Parent $demoRoot) 'Source Connection Setup/modules'
$demoModules = Join-Path $demoRoot 'modules'

Import-Module (Join-Path $sourceSetupModules 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $sourceSetupModules 'ISC.OperatorToolchain.psm1') -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $sourceSetupModules 'ISC.SailPointSdk.psm1') -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $demoModules 'ISC.DemoData.psm1') -Force -WarningAction SilentlyContinue

if (-not $ModelPath) {
    $ModelPath = Join-Path $demoRoot 'config/demo-access-model.json'
}

$model = Import-DemoAccessModel -Path $ModelPath
$validation = Test-DemoAccessModelInvariants -Model $model
if (-not $validation.Ok) {
    throw ("Demo access model failed validation:`n - {0}" -f ($validation.Errors -join "`n - "))
}

$catalog = Get-SailpointCliEnvironments -ConfigPath $SailpointConfigPath
if (-not $Environment) {
    $Environment = $catalog.ActiveEnvironment
}
if (-not $Environment) {
    throw 'Pass -Environment or set activeenvironment in ~/.sailpoint/config.yaml.'
}

$envEntry = @($catalog.Environments | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1)
$preferredBaseUrl = $null
if ($envEntry) {
    $preferredBaseUrl = $envEntry.BaseUrl
}
elseif ($env:SAIL_BASE_URL) {
    Write-Host "Environment '$Environment' was not parsed from $($catalog.Path); using SAIL_BASE_URL." -ForegroundColor DarkYellow
    $preferredBaseUrl = $env:SAIL_BASE_URL.TrimEnd('/')
}
else {
    throw "Environment '$Environment' was not found in $($catalog.Path)."
}

$credentials = Resolve-SailpointSdkCredentials -ConfigPath $ConfigPath -PreferredBaseUrl $preferredBaseUrl
if (-not $credentials) {
    throw 'No PSSailpoint credentials found. Set SAIL_BASE_URL/SAIL_CLIENT_ID/SAIL_CLIENT_SECRET or provide config.json.'
}

Initialize-SailPointSdkSession -Credentials $credentials -Experimental
$null = Test-SailPointSdkConnection

$owner = Resolve-DemoOwnerIdentity -OwnerId $OwnerId
Write-Host ("Owner: {0}{1} ({2})" -f $owner.Id, $(if ($owner.Name) { " / $($owner.Name)" } else { '' }), $owner.Source) -ForegroundColor Cyan
Write-Host ("Model: {0} departments, {1} titles, {2} cities" -f `
        @($model['departmentRoles']).Count, `
        @($model['titleRoles']).Count, `
        @($model['workplaceRole']['dimensions']).Count) -ForegroundColor Cyan

$whatIf = [bool]$WhatIfPreference
if ($whatIf -or $PSCmdlet.ShouldProcess("ISC environment '$Environment'", 'Bootstrap demo access model')) {
    $summary = Invoke-DemoDataBootstrap -Model $model -OwnerId $owner.Id `
        -ExistingItemAction $ExistingItemAction -WhatIf:$whatIf

    $grouped = $summary.Results | Group-Object Status
    foreach ($g in $grouped) {
        Write-Host ("{0}: {1}" -f $g.Name, $g.Count)
    }

    $manual = @($summary.Results | Where-Object { $_.Status -in @('manual', 'missing') })
    if ($manual.Count -gt 0) {
        Write-Host ''
        Write-Host 'Follow-up required:' -ForegroundColor Yellow
        foreach ($item in $manual) {
            $msg = if ($item.PSObject.Properties['Message'] -and $item.Message) { $item.Message } else { $item.Name }
            Write-Host (" - [{0}] {1}" -f $item.Kind, $msg)
        }
        Write-Host 'After entitlement aggregation completes, re-run with -ExistingItemAction Update.' -ForegroundColor Yellow
    }

    $sodPath = Join-Path $demoRoot 'config/demo-sod-policies.json'
    if (Test-Path -LiteralPath $sodPath) {
        $sodModel = Import-DemoSodPolicies -Path $sodPath
        $entByName = @{}
        $catalog = Get-DemoModelEntitlementCatalog -Model $model
        foreach ($entId in @($catalog.Keys)) {
            $displayName = [string]$catalog[$entId].Name
            if ($summary.EntitlementIds.ContainsKey([string]$entId) -and $summary.EntitlementIds[[string]$entId] -notlike 'pending:*') {
                $entByName[$displayName] = [string]$summary.EntitlementIds[[string]$entId]
            }
        }

        Write-Host ''
        Write-Host ("SoD controls: {0}" -f @($sodModel['mitigatingControls']).Count) -ForegroundColor Cyan
        $ctrlSummary = Invoke-DemoSodControlBootstrap -SodModel $sodModel -OwnerId $owner.Id `
            -ExistingItemAction $ExistingItemAction -WhatIf:$whatIf
        $ctrlGrouped = $ctrlSummary.Results | Group-Object Status
        foreach ($g in $ctrlGrouped) {
            Write-Host ("Control {0}: {1}" -f $g.Name, $g.Count)
        }

        Write-Host ("SoD policies: {0}" -f @($sodModel['policies']).Count) -ForegroundColor Cyan
        $sodSummary = Invoke-DemoSodPolicyBootstrap -SodModel $sodModel -OwnerId $owner.Id `
            -EntitlementIdsByName $entByName `
            -ControlIdsByKey $ctrlSummary.ControlIdsByKey `
            -ControlNamesByKey $ctrlSummary.ControlNamesByKey `
            -ExistingItemAction $ExistingItemAction -WhatIf:$whatIf
        $sodGrouped = $sodSummary.Results | Group-Object Status
        foreach ($g in $sodGrouped) {
            Write-Host ("SoD {0}: {1}" -f $g.Name, $g.Count)
        }
        $summary | Add-Member -NotePropertyName SodControlResults -NotePropertyValue $ctrlSummary.Results -Force
        $summary | Add-Member -NotePropertyName SodResults -NotePropertyValue $sodSummary.Results -Force
    }

    Write-Host ''
    Write-Host 'Role membership evaluates asynchronously after identity processing.' -ForegroundColor DarkGray
    Write-Host 'SoD violations evaluate after policy scheduling / identity refresh.' -ForegroundColor DarkGray
    return $summary
}
