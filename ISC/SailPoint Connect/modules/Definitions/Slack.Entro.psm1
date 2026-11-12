Set-StrictMode -Version Latest

function Register-SlackEntroDefinitions {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.EntroCatalog.psm1') -Force -WarningAction SilentlyContinue

    Register-IntegrationWizardDefinition @{
        Id           = 'slack-entro'
        Platform     = 'Slack'
        Product      = 'Entro'
        CoreSwitch   = 'Entro'
        CliName      = 'slack'
        Title        = 'Entro Slack integration'
        FolderName   = 'Entro-Slack'
        AccessLevels = @()
        AdminRoles   = @('Slack Workspace Admin (app manifest install)')
        OutputsHelp  = 'Paste Bot, User, and App-Level (xapp-) tokens into Entro after installing Entro manifest app.'
        Inputs       = @(
            @{ Name = 'WorkspaceName'; Source = 'Supply'; Prompt = 'Slack workspace name'; Purpose = 'Label for operator notes'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'BotUserOAuthToken'; Source = 'Supply'; Prompt = 'Bot User OAuth Token (xoxb-)'; Purpose = 'Verify bot token'; Required = $true; Secret = $true }
            @{ Name = 'UserOAuthToken'; Source = 'Supply'; Prompt = 'User OAuth Token (xoxp-)'; Purpose = 'Verify user token'; Required = $false; Secret = $true }
            @{ Name = 'AppLevelToken'; Source = 'Supply'; Prompt = 'App-Level Token (xapp-)'; Purpose = 'Socket mode token'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'entro-slack-manifest'
                    Title = 'Create Slack app from Entro manifest'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Entro Slack app'
                        Write-Info 'At api.slack.com/apps, create an app from Entro manifest, enable socket mode, install to workspace.'
                        Write-Info 'Store xoxb, xoxp, and xapp tokens in the operator vault.'
                    }
                    BuildScript = { '# Entro Slack manifest install' }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Entro handoff' -ForegroundColor Cyan
            Write-Host '  Paste Bot, User, and App-Level tokens into Entro'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-SlackEntroDefinitions
