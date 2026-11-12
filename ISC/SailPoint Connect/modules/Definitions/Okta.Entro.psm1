Set-StrictMode -Version Latest

function Register-OktaEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'okta-entro'
        Platform     = 'Okta'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'okta'
        Title        = 'Entro Okta integration'
        FolderName   = 'Entro-Okta'
        AccessLevels = @()
        AdminRoles   = @('Okta Super Administrator')
        OutputsHelp  = 'Paste Environment, Display Name, Okta domain, and Client ID into Entro after API Services app setup.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment label'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'DisplayName'; Source = 'Supply'; Prompt = 'Display name in Entro'; Purpose = 'Operator-chosen label'; Required = $true }
            @{ Name = 'OktaDomain'; Source = 'Supply'; Prompt = 'Okta org URL'; Purpose = 'https://org.okta.com'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'OktaDomain'; Source = 'Supply'; Prompt = 'Okta org URL'; Purpose = 'Org to verify'; Required = $true }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'API Services Client ID'; Purpose = 'Client ID after Entro public key is added'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-okta-app'
                    Title = 'Configure Okta API Services app for Entro'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Entro Okta onboarding'
                        Write-Info 'In Entro Add New Account → Okta, copy the Public Key from the form.'
                        Write-Info 'Create the API Services app, paste the Entro public key, and record the Client ID.'
                        Write-Info "Domain: $($c['OktaDomain'])"
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Entro Okta: configure API Services app for $($c['OktaDomain'])"
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
            Write-Host "  Display Name: $($ctx['DisplayName'])"
            Write-Host "  Okta domain: $($ctx['OktaDomain'])"
            Write-Host '  Client ID: from API Services app after Entro public key is installed'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-OktaEntroDefinitions
