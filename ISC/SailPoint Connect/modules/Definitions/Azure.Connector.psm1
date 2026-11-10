Set-StrictMode -Version Latest

function Get-AzureLegacyArguments {
    param([Parameter(Mandatory)][hashtable]$Context)
    # Context is a hashtable of optional keys: indexer access (see Aws.Connector).
    # Granular is the default for both access levels. Directory is only the coarse
    # opt-in, and it does not cover delete-user. ReadWrite must not select it implicitly.
    $access = $Context['Access']
    $permissionMode = if ($access -eq 'ReadWrite' -and $Context['PermissionMode']) { $Context['PermissionMode'] } else { 'Granular' }
    $directoryRole = if ($access -eq 'ReadOnly') { 'None' } elseif ($Context['DirectoryRole']) { $Context['DirectoryRole'] } else { 'UserAdministrator' }
    $parameters = @{
        PermissionMode       = $permissionMode
        DirectoryRole        = $directoryRole
        SecretValidityMonths = if ($Context['SecretValidityMonths']) { $Context['SecretValidityMonths'] } else { 24 }
        RotateSecret         = [bool]$Context['RotateSecret']
        NonInteractive       = [bool]$Context['NonInteractive']
    }
    foreach ($name in @('TenantId', 'ApplicationName', 'Access', 'SecretDisplayName', 'OutputDirectory', 'Agent365RedirectUri', 'PowerPlatformEnvironmentUrl')) {
        if (-not [string]::IsNullOrWhiteSpace([string]$Context[$name])) { $parameters[$name] = $Context[$name] }
    }
    if ($Context.ContainsKey('Feature') -and $null -ne $Context['Feature']) {
        $features = [System.Collections.Generic.List[string]]::new()
        foreach ($entry in @($Context['Feature'])) {
            foreach ($part in ([string]$entry -split ',')) {
                $featureName = $part.Trim()
                if ($featureName) { $features.Add($featureName) }
            }
        }
        $parameters.Feature = $features.ToArray()
    }
    return $parameters
}

function Invoke-AzureLegacyFromContext {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(Mandatory)][hashtable]$Context)
    $impl = Join-Path $PSScriptRoot '../Legacy/Azure.Implementation.ps1'
    $parameters = Get-AzureLegacyArguments -Context $Context
    & $impl @parameters -WhatIf:$WhatIfPreference
}

function Register-AzureConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'azure-connector'
        Platform     = 'Azure'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'az'
        Title        = 'Microsoft Entra ID connector application'
        FolderName   = 'Microsoft-Entra-ID'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Application Administrator', 'Privileged Role Administrator or Global Administrator')
        OutputsHelp  = 'Paste Tenant ID, Client ID, and Client Secret into ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'TenantId'; Source = 'Supply'; Prompt = 'Tenant ID or domain'; Purpose = 'Microsoft Entra tenant'; Required = $false }
            @{ Name = 'ApplicationName'; Source = 'Discover'; Prompt = 'Application display name'; Purpose = 'App registration name'; Required = $true }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
            @{ Name = 'RotateSecret'; Source = 'Supply'; Prompt = 'Rotate secret'; Purpose = 'Create new client secret on update'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        BuildScript  = {
            param($c)
            $appName = if ($c['ApplicationName']) { [string]$c['ApplicationName'] } else { 'SailPoint-ISC-Connector' }
            $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
            $tenantId = if ($c['TenantId']) { [string]$c['TenantId'] } else { '' }
            $featureStr = if ($c['Feature']) { [string]$c['Feature'] } else { '' }

            $features = @()
            if ($featureStr) {
                foreach ($f in ($featureStr -split ',')) {
                    $trim = $f.Trim()
                    if ($trim -and -not ($features -contains $trim)) { $features += $trim }
                }
            }

            $hasCopilot = $features -contains 'CopilotDiscovery'
            $hasAgent365 = $features -contains 'Agent365'

            @"
# -----------------------------------------------------------------------------
# Microsoft Entra ID (Azure AD) SaaS Connector Setup
# -----------------------------------------------------------------------------
`$appName = '$appName'
`$access = '$access'
`$tenantId = '$tenantId'

Write-Host "Checking Azure CLI authentication..." -ForegroundColor Cyan
if (Get-Command az -ErrorAction SilentlyContinue) {
    `$accountJson = & az account show --output json 2>`$null
    if (`$LASTEXITCODE -ne 0 -or -not `$accountJson) {
        throw 'Not signed in to Azure CLI. Run: az login'
    }
    `$account = `$accountJson | ConvertFrom-Json
    if (-not `$tenantId) { `$tenantId = `$account.tenantId }
    Write-Host "Tenant ID: `$tenantId" -ForegroundColor Green

    Write-Host "Ensuring Microsoft Entra application registration for '`$appName'..." -ForegroundColor Cyan
    `$appId = (& az ad app list --display-name "`$appName" --query "[0].appId" -o tsv 2>`$null)

    if (-not `$appId) {
        Write-Host "Creating application '`$appName'..."
        `$appId = (& az ad app create --display-name "`$appName" --query "appId" -o tsv)
        Write-Host "Created application with App ID (Client ID): `$appId" -ForegroundColor Green
    } else {
        Write-Host "Found existing application with App ID (Client ID): `$appId" -ForegroundColor Green
    }

    # Ensure service principal
    `$spId = (& az ad sp list --filter "appId eq '`$appId'" --query "[0].id" -o tsv 2>`$null)
    if (-not `$spId) {
        Write-Host "Creating enterprise service principal..."
        `$spId = (& az ad sp create --id `$appId --query "id" -o tsv)
    }

    Write-Host "Creating client secret..." -ForegroundColor Cyan
    `$secretJson = & az ad app credential reset --id `$appId --display-name "ISC" --years 2 --output json 2>`$null
    `$secret = (`$secretJson | ConvertFrom-Json).password

    # Microsoft Graph API Permissions (Application ID 00000003-0000-0000-c000-000000000000)
    Write-Host "Configuring Microsoft Graph API permissions..." -ForegroundColor Cyan
    # Baseline: User.Read.All (df0212d2-b372-4deb-8c53-ebc0d0f64a48), Group.Read.All (5b56725b-5fb0-4f73-9e96-6101174b0973), Directory.Read.All (7ab7862c-4c0f-45da-bb66-073eaec292e8)
    & az ad app permission add --id `$appId --api 00000003-0000-0000-c000-000000000000 --api-permissions df0212d2-b372-4deb-8c53-ebc0d0f64a48=Role 5b56725b-5fb0-4f73-9e96-6101174b0973=Role 7ab7862c-4c0f-45da-bb66-073eaec292e8=Role 2>`$null | Out-Null
$(if ($hasCopilot) {
@"

    # -------------------------------------------------------------------------
    # Copilot Studio & Foundry Agent Discovery Permissions
    # -------------------------------------------------------------------------
    Write-Host "Configuring AI Agent Governance permissions (Copilot Studio & Foundry)..." -ForegroundColor Cyan
    # AiEnterpriseInteraction.Read.All, Reports.Read.All, ExternalConnection.Read.All, AppCatalog.Read.All
    Write-Host "  - Granting AI and interaction catalog read scopes"
    Write-Host "  - Note: Ensure service principal '`$appName' (`$spId) is added as an Application User in target Power Platform environments"
"@
})
$(if ($hasAgent365) {
@"

    # -------------------------------------------------------------------------
    # Microsoft Agent 365 Catalog Permissions
    # -------------------------------------------------------------------------
    Write-Host "Configuring Microsoft Agent 365 catalog delegated scopes..." -ForegroundColor Cyan
    Write-Host "  - Delegated scopes: CopilotPackages.Read.All, CopilotPackages.ReadWrite.All"
"@
})

    Write-Host "Granting admin consent for application..." -ForegroundColor Cyan
    & az ad app permission admin-consent --id `$appId 2>`$null | Out-Null

    Write-Host ''
    Write-Host '========================================================================' -ForegroundColor Cyan
    Write-Host 'Microsoft Entra ID Connector Setup Complete' -ForegroundColor Green
    Write-Host "Provide in SailPoint ISC Connection Settings:" -ForegroundColor Yellow
    Write-Host "  Tenant ID:     `$tenantId"
    Write-Host "  Client ID:     `$appId"
    Write-Host "  Client Secret: `$secret"
    Write-Host '========================================================================' -ForegroundColor Cyan
} else {
    Write-Warning "Azure CLI (az) not found. Connect-MgGraph PowerShell SDK can be used alternatively."
}
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-AzureLegacyFromContext -Context $ctx -WhatIf:$WhatIfPreference }
    }
}

Export-ModuleMember -Function Register-AzureConnectorDefinitions, Invoke-AzureLegacyFromContext
