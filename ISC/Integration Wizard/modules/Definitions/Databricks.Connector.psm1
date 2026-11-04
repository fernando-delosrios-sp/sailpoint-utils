Set-StrictMode -Version Latest

function Register-DatabricksConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'databricks-connector'
        Platform     = 'Databricks'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'databricks'
        Title        = 'Databricks SaaS connector service principal'
        FolderName   = 'Databricks'
        AccessLevels = @()
        AdminRoles   = @('Databricks Account Admin')
        OutputsHelp  = 'Paste Cloud Type, Client ID, Client Secret, Account ID, and Metastore ID into the Databricks connector Connection Settings in ISC.'
        Inputs       = @(
            @{ Name = 'Cloud'; Source = 'Supply'; Prompt = 'Cloud type'; Purpose = 'Aws, Azure, or Gcp'; Required = $true; ValidateSet = @('Aws', 'Azure', 'Gcp'); Default = 'Aws' }
            @{ Name = 'Auth'; Source = 'Supply'; Prompt = 'Authentication'; Purpose = 'DatabricksM2M or Entra on Azure'; Required = $true; ValidateSet = @('DatabricksM2M', 'Entra'); Default = 'DatabricksM2M' }
            @{ Name = 'ServicePrincipalName'; Source = 'Supply'; Prompt = 'Service principal display name'; Purpose = 'Account-level SP for ISC'; Required = $false; Default = 'SailPoint-source' }
            @{ Name = 'AccountId'; Source = 'Discover'; Prompt = 'Databricks Account ID'; Purpose = 'From account console menu'; Required = $true }
            @{ Name = 'MetastoreId'; Source = 'Supply'; Prompt = 'Unity Catalog metastore ID'; Purpose = 'Governs workspaces in metastore'; Required = $true }
            @{ Name = 'RotateSecret'; Source = 'Supply'; Prompt = 'Rotate OAuth secret'; Purpose = 'Create new secret if SP exists'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'sp-create'
                    Title = 'Ensure account service principal with Account Admin'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Cli   = {
                        param($c)
                        $name = if ($c['ServicePrincipalName']) { $c['ServicePrincipalName'] } else { 'SailPoint-source' }
                        "# Create service principal and assign Account admin in Databricks Account Console, or use account API when available.`n# Display name: $name"
                    }
                }
                @{
                    Id    = 'oauth-secret'
                    Title = 'OAuth client credentials'
                    Kind  = 'Manual'
                    Manual = 'In Account Console → Service Principals → Secrets, generate OAuth secret unless -RotateSecret is false and a secret already exists. Copy Client ID and Client Secret once.'
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Databricks connector handoff' -ForegroundColor Cyan
            Write-Host "  Cloud: $($ctx['Cloud'])"
            Write-Host "  Auth: $($ctx['Auth'])"
            Write-Host "  Account ID: $($ctx['AccountId'])"
            Write-Host "  Metastore ID: $($ctx['MetastoreId'])"
            Write-Host '  Client ID / Secret: from service principal OAuth credentials'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-DatabricksConnectorDefinitions
