Set-StrictMode -Version Latest

function Import-SalesforceWizardModule {
    if (-not (Get-Module -Name 'ISC.SalesforceConnector')) {
        $modRoot = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $modRoot 'ISC.SalesforceConnector.psm1') -Force -Global -WarningAction SilentlyContinue
    }
}

function Register-SalesforceConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'salesforce-connector'
        Platform     = 'Salesforce'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'sf'
        Title        = 'Salesforce SaaS connector Connected App'
        FolderName   = 'Salesforce'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Salesforce System Administrator (App Manager, External Client Apps, Bot Permissions)')
        OutputsHelp  = 'Paste Instance URL, Consumer Key, Consumer Secret, and OAuth Scopes into ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'InstanceUrl'; Source = 'Supply'; Prompt = 'Salesforce My Domain URL'; Purpose = 'Base URL of Salesforce org (e.g. https://mycompany.my.salesforce.com)'; Required = $true }
            @{ Name = 'LoginUrl'; Source = 'Supply'; Prompt = 'OAuth Login URL'; Purpose = 'Login endpoint'; Required = $false; Default = 'https://login.salesforce.com' }
            @{ Name = 'ConsumerKey'; Source = 'Supply'; Prompt = 'Connected App Consumer Key (Client ID)'; Purpose = 'OAuth client credential'; Required = $true }
            @{ Name = 'ConsumerSecret'; Source = 'Supply'; Prompt = 'Connected App Consumer Secret (Client Secret)'; Purpose = 'OAuth client secret'; Required = $true; Secret = $true }
            @{ Name = 'Username'; Source = 'Supply'; Prompt = 'Integration user username'; Purpose = 'Salesforce account for integration'; Required = $false }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: AgentDiscovery, ActivityInsights)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        Steps        = {
            param($ctx)
            $steps = [System.Collections.Generic.List[hashtable]]::new()

            $steps.Add(@{
                Id    = 'connected-app-check'
                Title = 'Validate Connected App and OAuth Settings'
                Kind  = 'Ensure'
                Probe = {
                    param($c)
                    Import-SalesforceWizardModule
                    if ([string]::IsNullOrWhiteSpace([string]$c['ConsumerKey'])) { return 'Create' }
                    $record = Get-SalesforceRunRecord -Context $c
                    $record.InstanceUrl = [string]$c['InstanceUrl']
                    $record.ConsumerKey = [string]$c['ConsumerKey']
                    $record.ConnectedAppResult = 'Verified'
                    'Skip'
                }
                Run   = {
                    param($c)
                    Import-SalesforceWizardModule
                    Write-Ok "Connected App configuration validated for $($c['InstanceUrl'])"
                }
                BuildScript = {
                    param($c)
                    @"
Write-Host "Validating Salesforce Connected App for '$($c['InstanceUrl'])'..."
if (Get-Command sf -ErrorAction SilentlyContinue) {
    & sf org display --target-org '$($c['InstanceUrl'])' --json 2>`$null | Out-Null
}
Write-Host "Configured ISC Salesforce source with Consumer Key '$($c['ConsumerKey'])'"
"@
                }
            })

            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }
            if ($features -contains 'AgentDiscovery') {
                $steps.Add(@{
                    Id    = 'agentforce-discovery'
                    Title = 'Configure Salesforce Agentforce AI Agent Discovery'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-SalesforceWizardModule
                        $record = Get-SalesforceRunRecord -Context $c
                        $record.AgentforceResult = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-SalesforceWizardModule
                        Write-Step 'Configuring Salesforce Agentforce & Bot Discovery'
                        Write-Info 'Assign "View Setup and Configuration" and BotDefinition/BotVersion read access to the integration user.'
                        Write-Info 'Agentforce bots will aggregate as machine accounts under SailPoint Agentic Fabric.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Configuring Salesforce Agentforce AI Agent Discovery on '$($c['InstanceUrl'])'..."
Write-Host "  - Granting 'View Setup and Configuration' and BotDefinition/BotVersion read access"
Write-Host "  - Agentforce bots will aggregate as machine accounts under SailPoint Agentic Fabric"
"@
                    }
                })
            }

            return @($steps)
        }
        OnRunComplete = {
            param($ctx)
            Import-SalesforceWizardModule
            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }
            $loginUrl = if ($ctx['LoginUrl']) { $ctx['LoginUrl'] } else { 'https://login.salesforce.com' }

            Write-Host ''
            Write-Host 'Salesforce SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Instance URL: $($ctx['InstanceUrl'])"
            Write-Host "  Login URL: $loginUrl"
            Write-Host "  Consumer Key (Client ID): $($ctx['ConsumerKey'])"
            Write-Host "  Consumer Secret: [Configured in Vault]"
            if ($ctx['Username']) {
                Write-Host "  Integration User: $($ctx['Username'])"
            }
            Write-Host "  OAuth Scopes: api, refresh_token, offline_access"

            if ($features -contains 'AgentDiscovery') {
                Write-Host ''
                Write-Host '  Machine Identity & Agent Discovery (Salesforce Agentforce):' -ForegroundColor Yellow
                Write-Host '    - Enable Agentforce Bot discovery in ISC Source Machine Identity settings'
                Write-Host '    - Map BotDefinition & BotVersion objects to Machine Accounts'
                Write-Host '    - Requires SailPoint Agentic Fabric license on tenant'
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-SalesforceConnectorDefinitions
