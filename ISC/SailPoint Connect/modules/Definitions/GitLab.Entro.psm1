Set-StrictMode -Version Latest

function Register-GitLabEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'gitlab-entro'
        Platform     = 'GitLab'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'glab'
        Title        = 'Entro GitLab integration'
        FolderName   = 'Entro-GitLab'
        AccessLevels = @()
        AdminRoles   = @('GitLab Group Owner or Maintainer')
        OutputsHelp  = 'Paste Nickname, GitLab URL, and access token into Entro admin console.'
        Inputs       = @(
            @{ Name = 'Nickname'; Source = 'Supply'; Prompt = 'Nickname in Entro'; Purpose = 'Operator-chosen label'; Required = $true }
            @{ Name = 'GitLabUrl'; Source = 'Supply'; Prompt = 'GitLab URL'; Purpose = 'https://gitlab.com or self-managed'; Required = $false; Default = 'https://gitlab.com' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'GitLabUrl'; Source = 'Supply'; Prompt = 'GitLab URL'; Purpose = 'Instance to verify'; Required = $true }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'GitLab access token'; Purpose = 'Group or project token'; Required = $true; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-gitlab-token'
                    Title = 'Create GitLab access token for Entro'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Entro GitLab token'
                        Write-Info "Create a group or project access token on $($c['GitLabUrl']) with Entro read scopes."
                    }
                    BuildScript = {
                        param($c)
                        "# Entro GitLab token for $($c['GitLabUrl'])"
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host "  Nickname: $($ctx['Nickname'])"
            Write-Host "  GitLab URL: $($ctx['GitLabUrl'])"
            Write-Host '  Access token: paste into Entro'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitLabEntroDefinitions
