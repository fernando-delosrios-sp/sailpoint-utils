Set-StrictMode -Version Latest

function Get-GoogleContextFeatureNames {
    param($Value)
    $items = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Value) { return ,$items.ToArray() }
    foreach ($entry in @($Value)) {
        foreach ($part in ([string]$entry -split ',')) {
            $name = $part.Trim()
            if ($name) { $items.Add($name) }
        }
    }
    return ,$items.ToArray()
}

function Get-GoogleLegacyArguments {
    param(
        [Parameter(Mandatory)][ValidateSet('Saas', 'Ciem')]
        [string]$Mode,
        [Parameter(Mandatory)][hashtable]$Context
    )
    # Context is a hashtable of optional keys: indexer access (see Aws.Connector).
    # CIEM is the Workspace connector with the Gcp and Ciem packs. Mode selects those
    # packs; a SaaS run leaves Feature untouched so the operator can still choose none.
    $feature = $Context['Feature']
    if ($Mode -eq 'Ciem') {
        $names = [System.Collections.Generic.List[string]]::new()
        foreach ($required in @('Gcp', 'Ciem')) { $names.Add($required) }
        $extras = Get-GoogleContextFeatureNames $Context['Feature']
        foreach ($extra in $extras) {
            if (-not $names.Contains([string]$extra)) { $names.Add([string]$extra) }
        }
        $feature = $names.ToArray()
    }
    $parameters = @{
        GrantType       = if ($Context['GrantType']) { $Context['GrantType'] } else { 'ServiceAccount' }
        NonInteractive  = [bool]$Context['NonInteractive']
        RotateKey       = [bool]$Context['RotateKey']
    }
    foreach ($name in @('OrganizationId', 'ProjectId', 'ServiceAccountId', 'DisplayName', 'ImpersonateUser', 'OutputDirectory', 'Access')) {
        if (-not [string]::IsNullOrWhiteSpace([string]$Context[$name])) { $parameters[$name] = $Context[$name] }
    }
    if ($null -ne $feature) { $parameters.Feature = $feature }
    return $parameters
}

function Invoke-GoogleLegacyFromContext {
    param(
        [Parameter(Mandatory)][ValidateSet('Saas', 'Ciem')]
        [string]$Mode,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $impl = Join-Path $PSScriptRoot '../Legacy/GoogleCloud.Implementation.ps1'
    $splat = Get-GoogleLegacyArguments -Mode $Mode -Context $Context
    if ($Context['Access'] -eq 'ReadOnly') { $splat.AggregationOnly = $true }
    & $impl @splat
}

function Register-GoogleConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'google-saas-connector'
        Platform     = 'GoogleCloud'
        Product      = 'ISC'
        CoreSwitch   = 'SaaSConnector'
        CliName      = 'gcloud'
        Title        = 'Google Workspace connector'
        FolderName   = 'Google Workspace'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Organization admin or project owner for IAM and service accounts')
        OutputsHelp  = 'Paste service account email, key, and admin email into ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'OrganizationId'; Source = 'Discover'; Prompt = 'Organization ID'; Purpose = 'Google Cloud organization'; Required = $true }
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'ImpersonateUser'; Source = 'Supply'; Prompt = 'Admin user to impersonate'; Purpose = 'Workspace domain-wide delegation'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Keys and connection settings'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        LegacyRun    = { param($ctx) Invoke-GoogleLegacyFromContext -Mode 'Saas' -Context $ctx }
    }
    Register-IntegrationWizardDefinition @{
        Id           = 'google-ciem-connector'
        Platform     = 'GoogleCloud'
        Product      = 'ISC'
        CoreSwitch   = 'CiemConnector'
        CliName      = 'gcloud'
        Title        = 'GCP CIEM connector feature packs'
        FolderName   = 'GCP CIEM'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Organization admin for custom org roles')
        OutputsHelp  = 'Enable CIEM/NHI packs in ISC using the GCP org role from connection settings.'
        Inputs       = @(
            @{ Name = 'OrganizationId'; Source = 'Discover'; Prompt = 'Organization ID'; Purpose = 'GCP organization'; Required = $true }
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'ImpersonateUser'; Source = 'Supply'; Prompt = 'Admin user to impersonate'; Purpose = 'Workspace domain-wide delegation'; Required = $true }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Extra feature packs (comma-separated)'; Purpose = 'Optional packs merged with Gcp and Ciem'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Artifacts'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        LegacyRun    = { param($ctx) Invoke-GoogleLegacyFromContext -Mode 'Ciem' -Context $ctx }
    }
}

Export-ModuleMember -Function Register-GoogleConnectorDefinitions, Invoke-GoogleLegacyFromContext
