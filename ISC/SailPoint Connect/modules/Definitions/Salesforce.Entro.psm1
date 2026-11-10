Set-StrictMode -Version Latest

function Register-SalesforceEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'salesforce-entro'
        Platform     = 'Salesforce'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'sf'
        Title        = 'Entro Salesforce integration'
        FolderName   = 'Entro-Salesforce'
        AccessLevels = @()
        AdminRoles   = @('Salesforce System Administrator (Setup, App Manager, Connected Apps)')
        OutputsHelp  = 'Paste Environment nickname, Instance URL, and Access Token or refresh credentials into Entro admin console.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment nickname'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'InstanceUrl'; Source = 'Supply'; Prompt = 'Salesforce My Domain URL'; Purpose = 'Salesforce instance URL'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-salesforce-app'
                    Title = 'Configure Salesforce Connected App for Entro'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        'Create'
                    }
                    Run   = {
                        param($c)
                        Write-Step 'Entro Salesforce Connected App Setup'
                        Write-Info "In Salesforce Setup -> App Manager, create a Connected App for Entro with required OAuth scopes."
                        Write-Info "Instance: $($c['InstanceUrl'])"
                    }
                    BuildScript = {
                        param($c)
                        @"
# Entro Salesforce Connected App Setup
Write-Host "Configure Salesforce Connected App for Entro at $($c['InstanceUrl'])"
"@
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
            Write-Host '  Credentials: paste Connected App OAuth credentials into Entro'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-SalesforceEntroDefinitions
