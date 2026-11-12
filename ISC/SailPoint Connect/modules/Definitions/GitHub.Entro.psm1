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
        FolderName   = 'Entro-GitHub'
        AccessLevels = @()
        AdminRoles   = @('GitHub Organization Owner')
        OutputsHelp  = 'Install the Entro GitHub App on your organization or paste a Classic PAT into the Entro admin console.'
        Inputs       = @(
            @{ Name = 'Method'; Source = 'Supply'; Prompt = 'Integration method'; Purpose = 'GitHubApp (Entro Cloud - New) or ClassicPAT'; Required = $true; ValidateSet = @('ClassicPAT', 'GitHubApp'); Default = 'GitHubApp' }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Personal Access Token (PAT)'; Purpose = 'GitHub Personal Access Token (PAT)'; Required = $false; Secret = $true }
            @{ Name = 'Organization'; Source = 'Discover'; Prompt = 'GitHub Organization name (optional)'; Purpose = 'GitHub Organization name'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Personal Access Token (PAT)'; Purpose = 'GitHub PAT to verify'; Required = $true; Secret = $true }
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name (optional)'; Purpose = 'Organization to verify'; Required = $false }
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
                        $hasOrg = -not [string]::IsNullOrWhiteSpace([string]$c['Organization'])
                        $targetDesc = if ($hasOrg) { "organization '$($c['Organization'])'" } else { 'your GitHub account' }
                        if ($method -eq 'GitHubApp') {
                            Write-Info "Install the Entro GitHub App on $targetDesc."
                            Write-Info "In Entro UI -> Integrations -> GitHub -> install the app with permissions."
                        }
                        else {
                            Write-Info "Generate a Classic PAT with repo and read:org scopes for $targetDesc."
                            Write-Info "Paste the token into the Entro admin console."
                        }
                    }
                    BuildScript = {
                        param($c)
                        $hasOrg = -not [string]::IsNullOrWhiteSpace([string]$c['Organization'])
                        $targetDesc = if ($hasOrg) { "organization '$($c['Organization'])'" } else { 'GitHub account' }
                        @"
# Entro GitHub Integration Setup
Write-Host "Configure Entro integration for $targetDesc"
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $target = if (-not [string]::IsNullOrWhiteSpace([string]$ctx['Organization'])) { $ctx['Organization'] } else { '[Personal / All accessible repos]' }
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Target: $target"
            Write-Host "  Method: $($ctx['Method'])"
            Write-Host '  Registration: complete GitHub App installation or paste PAT in Entro UI'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitHubEntroDefinitions
