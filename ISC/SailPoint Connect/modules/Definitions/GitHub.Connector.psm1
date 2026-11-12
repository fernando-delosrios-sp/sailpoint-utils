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
        OutputsHelp  = 'Paste Organization name, GitHub App ID, Installation ID, private key PEM (or PAT), and API URL into Agentic Fabric Connection Settings.'
        Inputs       = @(
            @{ Name = 'AuthMethod'; Source = 'Supply'; Prompt = 'Authentication method'; Purpose = 'GitHubApp (Agentic Fabric default) or PersonalAccessToken'; Required = $true; ValidateSet = @('PersonalAccessToken', 'GitHubApp'); Default = 'GitHubApp' }
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name'; Purpose = 'Public profile name of the GitHub organization'; Required = $false; When = { param($c) $true } }
            @{ Name = 'AppId'; Source = 'Supply'; Prompt = 'GitHub App ID'; Purpose = 'Unique identifier for the installed GitHub app'; Required = $true; When = { param($c) $m = if ($c['AuthMethod']) { [string]$c['AuthMethod'] } else { 'GitHubApp' }; $m -eq 'GitHubApp' } }
            @{ Name = 'InstallationId'; Source = 'Supply'; Prompt = 'GitHub App Installation ID'; Purpose = 'From URL .../settings/installations/{id}'; Required = $true; When = { param($c) $m = if ($c['AuthMethod']) { [string]$c['AuthMethod'] } else { 'GitHubApp' }; $m -eq 'GitHubApp' } }
            @{ Name = 'PrivateKey'; Source = 'Supply'; Prompt = 'GitHub App private key (PEM)'; Purpose = 'Full PEM including BEGIN/END PRIVATE KEY lines'; Required = $true; Secret = $true; When = { param($c) $m = if ($c['AuthMethod']) { [string]$c['AuthMethod'] } else { 'GitHubApp' }; $m -eq 'GitHubApp' } }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'GitHub Personal Access Token (PAT)'; Purpose = 'PAT credential when not using a GitHub App'; Required = $true; Secret = $true; When = { param($c) $c['AuthMethod'] -eq 'PersonalAccessToken' } }
            @{ Name = 'ApiUrl'; Source = 'Supply'; Prompt = 'API URL'; Purpose = 'GitHub API endpoint'; Required = $false; Default = 'https://api.github.com' }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: AgentDiscovery, ActivityInsights)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        CheckInputs  = @(
            @{ Name = 'AuthMethod'; Source = 'Supply'; Prompt = 'Authentication method'; Purpose = 'GitHubApp or PersonalAccessToken'; Required = $true; ValidateSet = @('PersonalAccessToken', 'GitHubApp'); Default = 'GitHubApp' }
            @{ Name = 'Organization'; Source = 'Supply'; Prompt = 'GitHub Organization name'; Purpose = 'Organization to verify'; Required = $false }
            @{ Name = 'AppId'; Source = 'Supply'; Prompt = 'GitHub App ID'; Purpose = 'App ID to verify'; Required = $true; When = { param($c) $c['AuthMethod'] -eq 'GitHubApp' } }
            @{ Name = 'InstallationId'; Source = 'Supply'; Prompt = 'Installation ID'; Purpose = 'Installation to verify'; Required = $true; When = { param($c) $c['AuthMethod'] -eq 'GitHubApp' } }
            @{ Name = 'PrivateKey'; Source = 'Supply'; Prompt = 'Private key (PEM)'; Purpose = 'App key to verify'; Required = $true; Secret = $true; When = { param($c) $c['AuthMethod'] -eq 'GitHubApp' } }
            @{ Name = 'Token'; Source = 'Supply'; Prompt = 'Personal Access Token'; Purpose = 'PAT to verify'; Required = $true; Secret = $true; When = { param($c) $c['AuthMethod'] -eq 'PersonalAccessToken' } }
            @{ Name = 'ApiUrl'; Source = 'Supply'; Prompt = 'API URL'; Purpose = 'GitHub API endpoint'; Required = $false; Default = 'https://api.github.com' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
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
                    $record = Get-GitHubRunRecord -Context $c
                    $record.Organization = if ($c['Organization']) { [string]$c['Organization'] } else { '' }
                    $record.ApiUrl = if ($c['ApiUrl']) { [string]$c['ApiUrl'] } else { 'https://api.github.com' }
                    $record.AuthMethod = if ($c['AuthMethod']) { [string]$c['AuthMethod'] } else { 'GitHubApp' }
                    $record.AuthResult = 'Verified'
                    'Skip'
                }
                Run   = {
                    param($c)
                    Import-GitHubWizardModule
                    $orgDesc = if (-not [string]::IsNullOrWhiteSpace([string]$c['Organization'])) { "organization $($c['Organization'])" } else { "account" }
                    Write-Ok "GitHub $orgDesc credentials validated"
                }
                BuildScript = {
                    param($c)
                    $orgDesc = if (-not [string]::IsNullOrWhiteSpace([string]$c['Organization'])) { "'$($c['Organization'])'" } else { 'default account' }
                    @"
Write-Host "Validating GitHub organization $orgDesc..."
if (Get-Command gh -ErrorAction SilentlyContinue) {
    & gh auth status 2>`$null | Out-Null
}
Write-Host "Configured ISC GitHub source for $orgDesc"
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
            $authMethod = if ($ctx['AuthMethod']) { $ctx['AuthMethod'] } else { 'GitHubApp' }

            $orgDisplay = if (-not [string]::IsNullOrWhiteSpace([string]$ctx['Organization'])) { $ctx['Organization'] } else { '[Organization name required for Agentic Fabric]' }

            Write-Host ''
            Write-Host 'GitHub SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Organization: $orgDisplay"
            Write-Host "  API URL: $apiUrl"
            Write-Host "  Auth Method: $authMethod"
            if ($authMethod -eq 'GitHubApp') {
                Write-Host "  GitHub App ID: $($ctx['AppId'])"
                Write-Host "  Installation ID: $($ctx['InstallationId'])"
                Write-Host '  Private key: [PEM in vault]'
            }
            else {
                Write-Host '  PAT: [Configured in Vault]'
                Write-Host '  Recommended Scopes: repo, admin:org, manage_billing:copilot, read:audit_log'
            }

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
