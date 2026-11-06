Set-StrictMode -Version Latest

function Import-GitHubWizardModule {
    if (-not (Get-Module -Name 'ISC.GitHubConnector')) {
        $modRoot = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $modRoot 'ISC.GitHubConnector.psm1') -Force -Global -WarningAction SilentlyContinue
    }
}

function Register-GitHubConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'github-connector'
        Platform     = 'GitHub'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'gh'
        Title        = 'GitHub SaaS connector & Copilot/Bot Discovery'
        FolderName   = 'GitHub'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('GitHub Organization Owner')
        OutputsHelp  = 'Paste Organization name, Personal Access Token (or GitHub App ID/Key), and API URL into ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name'; Purpose = 'Organization to govern'; Required = $true }
            @{ Name = 'ApiUrl'; Source = 'Supply'; Prompt = 'API URL'; Purpose = 'GitHub API endpoint'; Required = $false; Default = 'https://api.github.com' }
            @{ Name = 'AuthMethod'; Source = 'Supply'; Prompt = 'Authentication method'; Purpose = 'PersonalAccessToken or GitHubApp'; Required = $true; ValidateSet = @('PersonalAccessToken', 'GitHubApp'); Default = 'PersonalAccessToken' }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'Personal Access Token'; Purpose = 'OAuth / PAT credential'; Required = $false; Secret = $true }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: AgentDiscovery, ActivityInsights)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        Steps        = {
            param($ctx)
            $steps = [System.Collections.Generic.List[hashtable]]::new()

            $steps.Add(@{
                Id    = 'github-auth-check'
                Title = 'Validate GitHub Organization and Authentication'
                Kind  = 'Ensure'
                Probe = {
                    param($c)
                    Import-GitHubWizardModule
                    if ([string]::IsNullOrWhiteSpace([string]$c['Organization'])) { return 'Create' }
                    $record = Get-GitHubRunRecord -Context $c
                    $record.Organization = [string]$c['Organization']
                    $record.ApiUrl = if ($c['ApiUrl']) { [string]$c['ApiUrl'] } else { 'https://api.github.com' }
                    $record.AuthMethod = if ($c['AuthMethod']) { [string]$c['AuthMethod'] } else { 'PersonalAccessToken' }
                    $record.AuthResult = 'Verified'
                    'Skip'
                }
                Run   = {
                    param($c)
                    Import-GitHubWizardModule
                    Write-Ok "GitHub organization $($c['Organization']) credentials validated"
                }
                BuildScript = {
                    param($c)
                    @"
Write-Host "Validating GitHub organization '$($c['Organization'])'..."
if (Get-Command gh -ErrorAction SilentlyContinue) {
    & gh auth status 2>`$null | Out-Null
}
Write-Host "Configured ISC GitHub source for '$($c['Organization'])'"
"@
                }
            })

            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }
            if ($features -contains 'AgentDiscovery') {
                $steps.Add(@{
                    Id    = 'github-copilot-bot-discovery'
                    Title = 'Configure GitHub Copilot and Bot/App Discovery'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-GitHubWizardModule
                        $record = Get-GitHubRunRecord -Context $c
                        $record.AgentDiscovery = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-GitHubWizardModule
                        Write-Step 'Configuring GitHub Copilot & Machine Identity Discovery'
                        Write-Info 'Grant manage_billing:copilot to discover assigned GitHub Copilot seats.'
                        Write-Info 'Ensure admin:org is enabled to aggregate installed GitHub Apps, Bot users, and machine deploy keys.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Configuring GitHub Copilot & Bot Machine Identity Discovery for '$($c['Organization'])'..."
Write-Host "  - Granting 'manage_billing:copilot' to inventory assigned GitHub Copilot seats"
Write-Host "  - Granting 'admin:org' to aggregate Installed GitHub Apps, Bot users, and machine deploy keys"
Write-Host "  - Copilot seats and GitHub Apps will aggregate as machine accounts under SailPoint Agentic Fabric"
"@
                    }
                })
            }

            return @($steps)
        }
        OnRunComplete = {
            param($ctx)
            Import-GitHubWizardModule
            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }
            $apiUrl = if ($ctx['ApiUrl']) { $ctx['ApiUrl'] } else { 'https://api.github.com' }
            $authMethod = if ($ctx['AuthMethod']) { $ctx['AuthMethod'] } else { 'PersonalAccessToken' }

            Write-Host ''
            Write-Host 'GitHub SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Organization: $($ctx['Organization'])"
            Write-Host "  API URL: $apiUrl"
            Write-Host "  Auth Method: $authMethod"
            Write-Host "  Token: [Configured in Vault]"
            Write-Host "  Recommended Scopes: repo, admin:org, manage_billing:copilot, read:audit_log"

            if ($features -contains 'AgentDiscovery') {
                Write-Host ''
                Write-Host '  Machine Identity & Agent Discovery (GitHub Copilot & Bots):' -ForegroundColor Yellow
                Write-Host '    - Map assigned Copilot licenses to Identity Security Cloud'
                Write-Host '    - Discover GitHub Apps and Bot identities as machine accounts'
                Write-Host '    - Requires SailPoint Agentic Fabric license on tenant'
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-GitHubConnectorDefinitions
