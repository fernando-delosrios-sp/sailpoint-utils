Set-StrictMode -Version Latest

function Register-CrowdStrikeEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'crowdstrike-entro'
        Platform     = 'CrowdStrike'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'falcon'
        Title        = 'Entro CrowdStrike integration'
        FolderName   = 'Entro-CrowdStrike'
        AccessLevels = @()
        AdminRoles   = @('CrowdStrike Falcon Administrator (API Clients and Keys)')
        OutputsHelp  = 'Paste Environment nickname, Client ID, and Client Secret into the Entro admin console.'
        Inputs       = @(
            @{ Name = 'Environment'; Source = 'Supply'; Prompt = 'Environment nickname'; Purpose = 'Label in Entro'; Required = $true }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client ID'; Purpose = 'Falcon API Client ID'; Required = $true }
            @{ Name = 'ClientSecret'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client Secret'; Purpose = 'Falcon API Client Secret'; Required = $false; Secret = $true }
            @{ Name = 'BaseUrl'; Source = 'Supply'; Prompt = 'Falcon Cloud API Base URL'; Purpose = 'Falcon Cloud region endpoint'; Required = $false; Default = 'https://api.crowdstrike.com' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client ID'; Purpose = 'Falcon API Client ID to verify'; Required = $true }
            @{ Name = 'ClientSecret'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client Secret'; Purpose = 'Falcon API Client Secret'; Required = $true; Secret = $true }
            @{ Name = 'BaseUrl'; Source = 'Supply'; Prompt = 'Falcon Cloud API Base URL'; Purpose = 'Falcon Cloud region endpoint'; Required = $false; Default = 'https://api.crowdstrike.com' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-crowdstrike-client'
                    Title = 'Configure CrowdStrike Falcon API Client for Entro'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        'Create'
                    }
                    Run   = {
                        param($c)
                        Write-Step 'Entro CrowdStrike Falcon Integration Setup'
                        Write-Info "In CrowdStrike Falcon Console -> Support and resources -> API clients and keys, create a client for Entro."
                        Write-Info "Base URL: $($c['BaseUrl'])"
                        Write-Info "Environment nickname: $($c['Environment'])"
                        Write-Info "Optional Capability: Deploy Entro Falcon RTR secrets scanner for endpoint non-human identity scanning."
                    }
                    BuildScript = {
                        param($c)
                        $baseUrl = if ($c['BaseUrl']) { $c['BaseUrl'] } else { 'https://api.crowdstrike.com' }
                        @"
# Entro CrowdStrike Falcon Integration Setup
Write-Host "Configuring Entro integration for CrowdStrike Falcon ($baseUrl)..." -ForegroundColor Cyan
Write-Host "Environment Nickname: $($c['Environment'])"
Write-Host "Client ID: $($c['ClientId'])"
Write-Host "Paste Client ID and Client Secret into Entro console -> Integrations -> CrowdStrike."
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $baseUrl = if ($ctx['BaseUrl']) { $ctx['BaseUrl'] } else { 'https://api.crowdstrike.com' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Environment: $($ctx['Environment'])"
            Write-Host "  Base URL: $baseUrl"
            Write-Host "  Client ID: $($ctx['ClientId'])"
            Write-Host '  Registration: paste API Client ID and Secret into Entro UI'
            Write-Host '  Optional: Deploy Entro Falcon RTR secrets scanner'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-CrowdStrikeEntroDefinitions
