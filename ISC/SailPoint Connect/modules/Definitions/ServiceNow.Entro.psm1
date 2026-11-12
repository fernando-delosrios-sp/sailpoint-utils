Set-StrictMode -Version Latest

function Register-ServiceNowEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'servicenow-entro'
        Platform     = 'ServiceNow'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'servicenow'
        Title        = 'Entro ServiceNow integration'
        FolderName   = 'Entro-ServiceNow'
        AccessLevels = @()
        AdminRoles   = @('ServiceNow admin (integration user + REST API key)')
        OutputsHelp  = 'Paste Environment, Display Name, instance URL, and REST API key into Entro.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment label'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'Display name in Entro'; Purpose = 'Operator-chosen label'; Required = $true }
            @{ Name = 'InstanceUrl'; Source = 'Supply'; Prompt = 'ServiceNow instance URL'; Purpose = 'https://domain.service-now.com'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'InstanceUrl'; Source = 'Supply'; Prompt = 'ServiceNow instance URL'; Purpose = 'Instance to verify'; Required = $true }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'REST API access token'; Purpose = 'API key to verify'; Required = $true; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-servicenow-api'
                    Title = 'Create ServiceNow integration user and REST API key'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Entro ServiceNow API key'
                        Write-Info "Create integration user and REST API key on $($c['InstanceUrl'])."
                        Write-Info 'Copy token Value once into the operator vault.'
                    }
                    BuildScript = {
                        param($c)
                        "Write-Host 'ServiceNow Entro API key for $($c['InstanceUrl'])'"
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Environment: $($ctx['Environment'])"
            Write-Host "  Instance URL: $($ctx['InstanceUrl'])"
            Write-Host '  Access token: REST API key from System Web Services'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-ServiceNowEntroDefinitions
