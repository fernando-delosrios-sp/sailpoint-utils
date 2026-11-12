Set-StrictMode -Version Latest

function Register-SlackConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'slack-connector'
        Platform     = 'Slack'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'slack'
        Title        = 'Slack SaaS connector & app token discovery'
        FolderName   = 'Slack'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Slack Workspace Owner (custom app / service account)')
        OutputsHelp  = 'Paste workspace OAuth tokens or private app credentials into Agentic Fabric Connection Settings.'
        Inputs       = @(
            @{ Name = 'WorkspaceName'; Source = 'Supply'; Prompt = 'Slack workspace name'; Purpose = 'Human-readable workspace label'; Required = $false }
            @{ Name = 'BotUserOAuthToken'; Source = 'Supply'; Prompt = 'Bot User OAuth Token (xoxb-)'; Purpose = 'Bot token for aggregation'; Required = $false; Secret = $true }
            @{ Name = 'UserOAuthToken'; Source = 'Supply'; Prompt = 'User OAuth Token (xoxp-)'; Purpose = 'User token if required by datasets'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'BotUserOAuthToken'; Source = 'Supply'; Prompt = 'Bot User OAuth Token'; Purpose = 'Token to verify'; Required = $true; Secret = $true }
            @{ Name = 'UserOAuthToken'; Source = 'Supply'; Prompt = 'User OAuth Token (optional)'; Purpose = 'Secondary token'; Required = $false; Secret = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'slack-app'
                    Title = 'Install Slack app for Agentic Fabric aggregation'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'Slack workspace app'
                        Write-Info 'Create or reuse a Slack app with ISC-documented scopes; install to the workspace.'
                        Write-Info 'Copy Bot (xoxb-) and User (xoxp-) tokens from OAuth & Permissions.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host 'Slack SaaS connector: install app and record xoxb/xoxp tokens for workspace $($c['WorkspaceName'])'
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'Slack SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Workspace: $(if ($ctx['WorkspaceName']) { $ctx['WorkspaceName'] } else { '(label)' })"
            Write-Host '  Bot token: [vault]'
            Write-Host '  User token: [vault if used]'
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-SlackConnectorDefinitions
