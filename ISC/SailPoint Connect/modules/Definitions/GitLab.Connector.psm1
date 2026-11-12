Set-StrictMode -Version Latest

function Register-GitLabConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'gitlab-connector'
        Platform     = 'GitLab'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'glab'
        Title        = 'GitLab SaaS connector & access token discovery'
        FolderName   = 'GitLab'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('GitLab Owner or Group Maintainer (access tokens)')
        OutputsHelp  = 'Paste base URL, authentication type, access token, and target group paths into Agentic Fabric / ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'BaseUrl'; Source = 'Supply'; Prompt = 'GitLab base URL'; Purpose = 'https://gitlab.com or self-managed URL'; Required = $false; Default = 'https://gitlab.com' }
            @{ Name = 'SelfManaged'; Source = 'Supply'; Prompt = 'Self-managed instance?'; Purpose = 'Yes if not gitlab.com'; Required = $false; ValidateSet = @('Yes', 'No'); Default = 'No' }
            @{ Name = 'AuthType'; Source = 'Supply'; Prompt = 'Authentication type'; Purpose = 'Personal or group access token'; Required = $true; ValidateSet = @('PersonalAccessToken', 'GroupAccessToken'); Default = 'GroupAccessToken' }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'GitLab access token'; Purpose = 'Token with read_api scope'; Required = $true; Secret = $true }
            @{ Name = 'TargetGroups'; Source = 'Supply'; Prompt = 'Target groups (comma-separated full paths)'; Purpose = 'Top-level groups to aggregate; subgroups included automatically'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'BaseUrl'; Source = 'Supply'; Prompt = 'GitLab base URL'; Purpose = 'Instance URL'; Required = $false; Default = 'https://gitlab.com' }
            @{ Name = 'AccessToken'; Source = 'Supply'; Prompt = 'GitLab access token'; Purpose = 'Token to verify'; Required = $true; Secret = $true }
            @{ Name = 'TargetGroups'; Source = 'Supply'; Prompt = 'Target groups (optional)'; Purpose = 'Groups to verify'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id    = 'gitlab-token'
                    Title = 'Create GitLab access token with read_api'
                    Kind  = 'Ensure'
                    Probe = { param($c) 'Create' }
                    Run   = {
                        param($c)
                        Write-Step 'GitLab access token'
                        Write-Info "Create a $($c['AuthType']) on $($c['BaseUrl']) with read_api and required roles per ISC dataset docs."
                        if ($c['TargetGroups']) { Write-Info "Target groups: $($c['TargetGroups'])" }
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "GitLab connector token setup on $($c['BaseUrl'])"
Write-Host 'Scope: read_api (required for Agentic Fabric)'
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            Write-Host ''
            Write-Host 'GitLab SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Base URL: $(if ($ctx['BaseUrl']) { $ctx['BaseUrl'] } else { 'https://gitlab.com' })"
            Write-Host "  Self-managed: $(if ($ctx['SelfManaged']) { $ctx['SelfManaged'] } else { 'No' })"
            Write-Host "  Auth type: $($ctx['AuthType'])"
            Write-Host "  Target groups: $(if ($ctx['TargetGroups']) { $ctx['TargetGroups'] } else { '(all reachable groups)' })"
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitLabConnectorDefinitions
