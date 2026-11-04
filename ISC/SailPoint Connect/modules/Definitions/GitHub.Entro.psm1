Set-StrictMode -Version Latest

function Register-GitHubEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'github-entro'
        Platform     = 'GitHub'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'gh'
        Title        = 'Entro GitHub integration'
        FolderName   = 'Entro GitHub'
        AccessLevels = @()
        AdminRoles   = @('GitHub Organization Owner')
        OutputsHelp  = 'Install the Entro GitHub App on your organization or paste a Classic PAT into the Entro admin console.'
        Inputs       = @(
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name'; Purpose = 'Organization to connect to Entro'; Required = $true }
            @{ Name = 'Method'; Source = 'Supply'; Prompt = 'Integration method'; Purpose = 'GitHubApp or ClassicPAT'; Required = $true; ValidateSet = @('GitHubApp', 'ClassicPAT'); Default = 'GitHubApp' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-github-onboard'
                    Title = 'Install Entro GitHub App or configure PAT'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        'Create'
                    }
                    Run   = {
                        param($c)
                        Write-Step 'Entro GitHub Onboarding'
                        $method = if ($c['Method']) { $c['Method'] } else { 'GitHubApp' }
                        if ($method -eq 'GitHubApp') {
                            Write-Info "Install the Entro GitHub App on organization '$($c['Organization'])'."
                            Write-Info "In Entro UI -> Integrations -> GitHub -> install the app with permissions."
                        }
                        else {
                            Write-Info "Generate a Classic PAT with repo and read:org scopes for organization '$($c['Organization'])'."
                            Write-Info "Paste the token into the Entro admin console."
                        }
                    }
                    BuildScript = {
                        param($c)
                        @"
# Entro GitHub Integration Setup
Write-Host "Configure Entro integration for GitHub organization '$($c['Organization'])'"
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Organization: $($ctx['Organization'])"
            Write-Host "  Method: $($ctx['Method'])"
            Write-Host '  Registration: complete GitHub App installation or paste PAT in Entro UI'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitHubEntroDefinitions
