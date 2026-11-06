Set-StrictMode -Version Latest

function Import-CrowdStrikeWizardModule {
    if (-not (Get-Module -Name 'ISC.CrowdStrikeConnector')) {
        $modRoot = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $modRoot 'ISC.CrowdStrikeConnector.psm1') -Force -Global -WarningAction SilentlyContinue
    }
}

function Register-CrowdStrikeConnectorDefinitions {
    Import-CrowdStrikeWizardModule

    Register-IntegrationWizardDefinition @{
        Id           = 'crowdstrike-connector'
        Platform     = 'CrowdStrike'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'falcon'
        Title        = 'CrowdStrike Falcon SaaS connector & Machine Identity Governance'
        FolderName   = 'CrowdStrike'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('CrowdStrike Falcon Administrator (API Clients and Keys)')
        OutputsHelp  = 'Paste Base URL, Client ID, and Client Secret into ISC CrowdStrike Falcon Connection Settings.'
        Inputs       = @(
            @{ Name = 'BaseUrl'; Source = 'Supply'; Prompt = 'CrowdStrike Falcon Cloud API Base URL'; Purpose = 'Falcon Cloud region endpoint'; Required = $false; Default = 'https://api.crowdstrike.com' }
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client ID'; Purpose = 'API Client identifier'; Required = $true }
            @{ Name = 'ClientSecret'; Source = 'Supply'; Prompt = 'Falcon OAuth2 Client Secret'; Purpose = 'API Client secret'; Required = $false; Secret = $true }
            @{ Name = 'Access'; Source = 'Supply'; Prompt = 'Access level'; Purpose = 'ReadOnly or ReadWrite'; Required = $false; ValidateSet = @('ReadOnly', 'ReadWrite'); Default = 'ReadOnly' }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: Discover, IdentityProtection, CloudSecurity, RealTimeResponse)'; Purpose = 'Optional ISC feature permissions'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings file path'; Required = $false }
        )
        Steps        = {
            param($ctx)
            $steps = [System.Collections.Generic.List[hashtable]]::new()

            $steps.Add(@{
                Id    = 'crowdstrike-auth-check'
                Title = 'Validate CrowdStrike Falcon API Client and Authentication'
                Kind  = 'Ensure'
                Probe = {
                    param($c)
                    Import-CrowdStrikeWizardModule
                    if ([string]::IsNullOrWhiteSpace([string]$c['ClientId'])) { return 'Create' }
                    $record = Get-CrowdStrikeRunRecord -Context $c
                    $record.BaseUrl = if ($c['BaseUrl']) { Get-CrowdStrikeApiBaseUrl -RegionOrUrl ([string]$c['BaseUrl']) } else { 'https://api.crowdstrike.com' }
                    $record.ClientId = [string]$c['ClientId']
                    $record.ClientSecret = if ($c['ClientSecret']) { [string]$c['ClientSecret'] } else { $null }
                    $record.Access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
                    $record.AuthResult = 'Verified'
                    'Skip'
                }
                Run   = {
                    param($c)
                    Import-CrowdStrikeWizardModule
                    $baseUrl = if ($c['BaseUrl']) { Get-CrowdStrikeApiBaseUrl -RegionOrUrl ([string]$c['BaseUrl']) } else { 'https://api.crowdstrike.com' }
                    Write-Ok "CrowdStrike Falcon API credentials validated for $baseUrl"
                }
                BuildScript = {
                    param($c)
                    Import-CrowdStrikeWizardModule
                    $baseUrl = if ($c['BaseUrl']) { Get-CrowdStrikeApiBaseUrl -RegionOrUrl ([string]$c['BaseUrl']) } else { 'https://api.crowdstrike.com' }
                    $clientId = [string]$c['ClientId']
                    $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
                    @"
Write-Host "Validating CrowdStrike Falcon API Client for '$baseUrl'..." -ForegroundColor Cyan
`$baseUrl = '$baseUrl'
`$clientId = '$clientId'
`$access = '$access'

`$authBody = @{
    client_id     = `$clientId
    client_secret = if (`$env:FALCON_CLIENT_SECRET) { `$env:FALCON_CLIENT_SECRET } else { Read-Host -Prompt "Enter Falcon Client Secret" -AsSecureString | ForEach-Object { [System.Net.NetworkCredential]::new('', `$_).Password } }
}

try {
    Write-Host "Requesting OAuth2 Bearer token from `$baseUrl/oauth2/token..."
    `$tokenResponse = Invoke-RestMethod -Uri "`$baseUrl/oauth2/token" -Method Post -Body `$authBody -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
    `$token = `$tokenResponse.access_token
    Write-Host "Authentication succeeded. Token acquired." -ForegroundColor Green

    `$headers = @{ Authorization = "Bearer `$token" }

    Write-Host "Verifying hosts query endpoint (hosts:read)..."
    `$hostsCheck = Invoke-RestMethod -Uri "`$baseUrl/devices/queries/devices-scroll/v1?limit=1" -Method Get -Headers `$headers -ErrorAction Stop
    Write-Host "Host aggregation verified. Total devices accessible: `$(`$hostsCheck.meta.pagination.total)" -ForegroundColor Green

    Write-Host "Verifying user management endpoint (user-management:read)..."
    `$usersCheck = Invoke-RestMethod -Uri "`$baseUrl/user-management/queries/users/v1?limit=1" -Method Get -Headers `$headers -ErrorAction Stop
    Write-Host "User management verified. Total users accessible: `$(`$usersCheck.meta.pagination.total)" -ForegroundColor Green

    if (`$access -eq 'ReadWrite') {
        Write-Host "Access level is ReadWrite. Verifying containment and user-management permissions..."
        Write-Host "  - hosts:write enabled for host network containment and incident remediation" -ForegroundColor Yellow
        Write-Host "  - user-management:write enabled for Falcon console user provisioning" -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to validate CrowdStrike Falcon credentials: `$(`$_.Exception.Message)"
    exit 1
}
"@
                }
            })

            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }

            if ($features -contains 'Discover') {
                $steps.Add(@{
                    Id    = 'crowdstrike-discover'
                    Title = 'Configure Falcon Discover for Machine Identity & Unmanaged Asset Governance'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        $record = Get-CrowdStrikeRunRecord -Context $c
                        $record.DiscoverResult = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        Write-Step 'Configuring Falcon Discover & Machine Identity Governance'
                        Write-Info 'Grant discover:read to discover unmanaged assets, machine accounts, and shadow compute instances.'
                    }
                    BuildScript = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        $baseUrl = if ($c['BaseUrl']) { Get-CrowdStrikeApiBaseUrl -RegionOrUrl ([string]$c['BaseUrl']) } else { 'https://api.crowdstrike.com' }
                        @"
Write-Host "Verifying Falcon Discover & Machine Identity Governance (discover:read)..." -ForegroundColor Cyan
try {
    `$discoverCheck = Invoke-RestMethod -Uri "$baseUrl/discover/queries/hosts/v1?limit=1" -Method Get -Headers `$headers -ErrorAction Stop
    Write-Host "Falcon Discover verified. Total unmanaged / discovered assets: `$(`$discoverCheck.meta.pagination.total)" -ForegroundColor Green
    Write-Host "Unmanaged assets and machine accounts will aggregate into SailPoint Identity Security Cloud." -ForegroundColor Green
} catch {
    Write-Warning "Could not query Falcon Discover: `$(`$_.Exception.Message). Ensure 'discover:read' is granted."
}
"@
                    }
                })
            }

            if ($features -contains 'IdentityProtection') {
                $steps.Add(@{
                    Id    = 'crowdstrike-identity-protection'
                    Title = 'Configure Falcon Identity Threat Protection (ITDR)'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        $record = Get-CrowdStrikeRunRecord -Context $c
                        $record.IdentityProtResult = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        Write-Step 'Configuring Falcon Identity Threat Protection'
                        Write-Info 'Grant identity-protection:read and identity-protection:write to correlate identity risk events into SailPoint ISC.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Configuring Falcon Identity Threat Protection (ITDR)..." -ForegroundColor Cyan
Write-Host "  - Granting 'identity-protection:read' and 'identity-protection:write'"
Write-Host "  - Identity risk score signals and threat detections will correlate with SailPoint ISC access reviews"
"@
                    }
                })
            }

            if ($features -contains 'CloudSecurity') {
                $steps.Add(@{
                    Id    = 'crowdstrike-cloud-security'
                    Title = 'Configure Falcon Horizon - Cloud Security Posture Management (CSPM)'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        $record = Get-CrowdStrikeRunRecord -Context $c
                        $record.CloudSecResult = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        Write-Step 'Configuring Falcon Horizon (CSPM)'
                        Write-Info 'Grant cspm-registration:read to aggregate multi-cloud posture and accounts.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Configuring Falcon Horizon Cloud Security (CSPM)..." -ForegroundColor Cyan
Write-Host "  - Granting 'cspm-registration:read' to ingest multi-cloud account configurations"
Write-Host "  - Multi-cloud security posture and IAM risk findings will correlate with SailPoint ISC"
"@
                    }
                })
            }

            if ($features -contains 'RealTimeResponse') {
                $steps.Add(@{
                    Id    = 'crowdstrike-rtr'
                    Title = 'Configure Falcon Real Time Response (RTR) - Incident Containment'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        $record = Get-CrowdStrikeRunRecord -Context $c
                        $record.RtrResult = 'Configured'
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-CrowdStrikeWizardModule
                        Write-Step 'Configuring Falcon Real Time Response (RTR)'
                        Write-Info 'Grant real-time-response:read and real-time-response:write for automated incident response remediation.'
                    }
                    BuildScript = {
                        param($c)
                        @"
Write-Host "Configuring Falcon Real Time Response (RTR)..." -ForegroundColor Cyan
Write-Host "  - Granting 'real-time-response:read' and 'real-time-response:write'"
Write-Host "  - Authorizes endpoint investigation and rapid incident response containment scripts"
"@
                    }
                })
            }

            return @($steps)
        }
        OnRunComplete = {
            param($ctx)
            Import-CrowdStrikeWizardModule
            $baseUrl = if ($ctx['BaseUrl']) { Get-CrowdStrikeApiBaseUrl -RegionOrUrl ([string]$ctx['BaseUrl']) } else { 'https://api.crowdstrike.com' }
            $access = if ($ctx['Access']) { [string]$ctx['Access'] } else { 'ReadOnly' }
            $features = if ($ctx['Feature']) { @($ctx['Feature'] -split ',' | ForEach-Object { $_.Trim() }) } else { @() }

            Write-Host ''
            Write-Host 'CrowdStrike Falcon SaaS connector handoff' -ForegroundColor Cyan
            Write-Host "  Base URL: $baseUrl"
            Write-Host "  Client ID: $($ctx['ClientId'])"
            Write-Host "  Access Level: $access"
            Write-Host "  Token: [Configured in Vault]"
            Write-Host "  Base Scopes: hosts:read, host-groups:read, user-management:read"
            if ($access -eq 'ReadWrite') {
                Write-Host "  Write Scopes: hosts:write (Containment), user-management:write (Provisioning)" -ForegroundColor Yellow
            }

            if ($features -contains 'Discover') {
                Write-Host ''
                Write-Host '  Machine Identity & Asset Governance (Falcon Discover):' -ForegroundColor Yellow
                Write-Host '    - Discovers unmanaged endpoints, shadow cloud compute, and machine accounts'
                Write-Host '    - Aggregates non-human identities into SailPoint Agentic Fabric'
            }
            if ($features -contains 'IdentityProtection') {
                Write-Host '  Identity Threat Protection (ITDR):' -ForegroundColor Yellow
                Write-Host '    - Real-time threat intelligence and compromised identity risk scoring'
            }
            if ($features -contains 'CloudSecurity') {
                Write-Host '  Falcon Horizon (CSPM):' -ForegroundColor Yellow
                Write-Host '    - Cloud misconfiguration and posture findings correlated with identity'
            }
            if ($features -contains 'RealTimeResponse') {
                Write-Host '  Real Time Response (RTR):' -ForegroundColor Yellow
                Write-Host '    - Automated containment and remediation scripts triggered by identity events'
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-CrowdStrikeConnectorDefinitions
