@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'SailPoint.Connect.psm1'

    # Version number of this module.
    ModuleVersion = '1.7.1'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # ID used to uniquely identify this module
    GUID = 'cbeb9c96-64a1-41e6-8f40-1ba3850c69f1'

    # Author of this module
    Author = 'SailPoint Technologies'

    # Company or vendor of this module
    CompanyName = 'SailPoint Technologies'

    # Copyright statement for this module
    Copyright = '(c) 2026 SailPoint Technologies. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'SailPoint Connect: checklist, read-only check of an existing identity, or an explicit Run for SailPoint ISC connectors, Entro cloud onboarding, Microsoft 365 access profiles, and IQService host management.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Functions to export from this module, for best performance, do not use wildcards
    FunctionsToExport = @(
        'Invoke-SailPointConnect'
        'Connect-SailPointAWS'
        'Connect-SailPointAzure'
        'Connect-SailPointGoogleCloud'
        'Connect-SailPointDatabricks'
        'Connect-SailPointSalesforce'
        'Connect-SailPointGitHub'
        'Connect-SailPointOkta'
        'Connect-SailPointGitLab'
        'Connect-SailPointSlack'
        'Connect-SailPointSnowflake'
        'Connect-SailPointServiceNow'
        'Connect-SailPointHashiCorpVault'
        'Connect-SailPointCrowdStrike'
        'Invoke-SailPointIQServiceControl'
        'New-SailPointM365AccessProfile'
        'Get-SailPointConnectProject'
        'Set-SailPointConnectProject'
        'Update-SailPointConnect'
        'Get-SailPointConnectUpdate'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards
    AliasesToExport = @(
        'sailpoint-connect'
        'Start-SailPointIQServiceControl'
        'update-sailpoint-connect'
    )

    # Private data to pass to the module specified in RootModule/ModuleList
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for discoverability in PowerShell Gallery
            Tags = @(
                'SailPoint'
                'ISC'
                'IdentitySecurityCloud'
                'Entro'
                'AWS'
                'Azure'
                'EntraID'
                'GoogleCloud'
                'GCP'
                'Databricks'
                'Salesforce'
                'GitHub'
                'CrowdStrike'
                'IQService'
                'Connector'
            )

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/sailpoint-oss/sailpoint-connect/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/sailpoint-oss/sailpoint-connect'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Fix Wizard navigation allowing Esc back from integration selection to root platform menu; add CheckInputs across integrations collecting expected target credentials (e.g. Tenant ID, Client ID, Client Secret for Azure / Entro) directly validating live permissions while bypassing unnecessary CLI sign-in options; fix parameter set resolution and suppress False stdout leakage.'

            # External help XML URI
            HelpInfoURI = 'https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs'
        }
    }
}
