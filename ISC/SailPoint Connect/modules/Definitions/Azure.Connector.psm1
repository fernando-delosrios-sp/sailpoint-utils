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
        FolderName   = 'Microsoft Entra ID'
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
            @"
# Ensure SailPoint.Connect module or platform runner is available
`$setupScript = Join-Path `$PSScriptRoot 'Azure.ps1'
if (-not (Test-Path -LiteralPath `$setupScript)) {
    `$mod = Get-Module -ListAvailable SailPoint.Connect | Select-Object -First 1
    if (`$mod) { `$setupScript = Join-Path (Split-Path `$mod.Path) 'Azure.ps1' }
}
if (Test-Path -LiteralPath `$setupScript) {
    & `$setupScript -Connector -Access '$access' -ApplicationName '$appName'$(if ($tenantId) { " -TenantId '$tenantId'" })$(if ($featureStr) { " -Feature '$featureStr'" }) -Action Run -NonInteractive
} else {
    throw 'Could not locate Azure.ps1 or SailPoint.Connect module.'
}
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-AzureLegacyFromContext -Context $ctx -WhatIf:$WhatIfPreference }
    }
}

Export-ModuleMember -Function Register-AzureConnectorDefinitions, Invoke-AzureLegacyFromContext
