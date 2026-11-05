#Requires -Version 7
Set-StrictMode -Version Latest

$script:CrowdStrikeCloudRegions = [ordered]@{
    'US-1'      = 'https://api.crowdstrike.com'
    'US-2'      = 'https://api.us-2.crowdstrike.com'
    'EU-1'      = 'https://api.eu-1.crowdstrike.com'
    'US-GOV-1'  = 'https://api.laggar.gcw.crowdstrike.com'
}

$script:CrowdStrikeFeaturePacks = @{
    Discover = @{
        Name        = 'Discover'
        Label       = 'Falcon Discover - Unmanaged Asset & Machine Identity Governance'
        Description = 'Discovers unmanaged endpoints, shadow cloud compute instances, machine accounts, and unauthorized software across enterprise networks'
        Permissions = @(
            'discover:read'
        )
    }
    IdentityProtection = @{
        Name        = 'IdentityProtection'
        Label       = 'Falcon Identity Threat Protection (ITDR)'
        Description = 'Gathers identity threat indicators, anomalous authentication events, and risk scores into SailPoint Identity Security Cloud'
        Permissions = @(
            'identity-protection:read'
            'identity-protection:write'
        )
    }
    CloudSecurity = @{
        Name        = 'CloudSecurity'
        Label       = 'Falcon Horizon - Cloud Security Posture Management (CSPM)'
        Description = 'Aggregates multi-cloud accounts, misconfigurations, and cloud IAM security posture into SailPoint governance'
        Permissions = @(
            'cspm-registration:read'
        )
    }
    RealTimeResponse = @{
        Name        = 'RealTimeResponse'
        Label       = 'Falcon Real Time Response (RTR) - Incident Containment'
        Description = 'Enables real-time remote investigative capabilities and automated incident remediation scripts on managed endpoints'
        Permissions = @(
            'real-time-response:read'
            'real-time-response:write'
        )
    }
}

function Get-CrowdStrikeCloudRegions {
    return $script:CrowdStrikeCloudRegions
}

function Get-CrowdStrikeFeaturePacks {
    return $script:CrowdStrikeFeaturePacks
}

function Get-CrowdStrikeApiBaseUrl {
    param([string]$RegionOrUrl = 'US-1')
    if ([string]::IsNullOrWhiteSpace($RegionOrUrl)) {
        return $script:CrowdStrikeCloudRegions['US-1']
    }
    if ($script:CrowdStrikeCloudRegions.Contains($RegionOrUrl.ToUpperInvariant())) {
        return $script:CrowdStrikeCloudRegions[$RegionOrUrl.ToUpperInvariant()]
    }
    if ($RegionOrUrl -like 'http*://*') {
        return $RegionOrUrl.TrimEnd('/')
    }
    return $script:CrowdStrikeCloudRegions['US-1']
}

function Get-CrowdStrikeRunRecord {
    param([hashtable]$Context)
    if (-not $Context) { return $null }
    if (-not $Context.ContainsKey('CrowdStrikeRunRecord') -or $null -eq $Context['CrowdStrikeRunRecord']) {
        $Context['CrowdStrikeRunRecord'] = @{
            BaseUrl           = $null
            ClientId          = $null
            ClientSecret      = $null
            Access            = $null
            AuthResult        = $null
            DiscoverResult    = $null
            IdentityProtResult= $null
            CloudSecResult    = $null
            RtrResult         = $null
            SettingsPath      = $null
        }
    }
    return $Context['CrowdStrikeRunRecord']
}

function Get-CrowdStrikeIscFeatureChecklist {
    param([string[]]$FeatureNames = @())
    $items = [System.Collections.Generic.List[string]]::new()
    $features = @($FeatureNames | Where-Object { $_ })

    if ($features -contains 'Discover') {
        $items.Add('Falcon Discover: Enable unmanaged asset, shadow compute, and machine identity discovery in ISC.')
        $items.Add('Discover Scopes: Grant `discover:read` to query unmanaged hosts and accounts.')
    }
    if ($features -contains 'IdentityProtection') {
        $items.Add('Identity Threat Detection: Correlate Falcon identity threat detections with ISC access certifications.')
        $items.Add('IdentityProtection Scopes: Grant `identity-protection:read` and `identity-protection:write`.')
    }
    if ($features -contains 'CloudSecurity') {
        $items.Add('Falcon Horizon CSPM: Ingest multi-cloud misconfigurations and posture signals.')
        $items.Add('CloudSecurity Scopes: Grant `cspm-registration:read`.')
    }
    if ($features -contains 'RealTimeResponse') {
        $items.Add('Falcon Real Time Response: Authorize containment and automated investigation commands.')
        $items.Add('RTR Scopes: Grant `real-time-response:read` and `real-time-response:write`.')
    }

    return @($items)
}

function Build-CrowdStrikeConnectionSettings {
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [string]$ClientSecretMasked = '***',
        [string]$Access = 'ReadOnly',
        [string[]]$FeatureNames = @()
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# SailPoint ISC CrowdStrike Falcon SaaS Connection Settings')
    [void]$sb.AppendLine("Base URL: $BaseUrl")
    [void]$sb.AppendLine("Client ID: $ClientId")
    [void]$sb.AppendLine("Client Secret: $ClientSecretMasked")
    [void]$sb.AppendLine("Access Level: $Access")

    $scopes = [System.Collections.Generic.List[string]]::new()
    $scopes.Add('hosts:read')
    $scopes.Add('host-groups:read')
    $scopes.Add('user-management:read')

    if ($Access -eq 'ReadWrite') {
        $scopes.Add('hosts:write')
        $scopes.Add('user-management:write')
    }

    foreach ($f in $FeatureNames) {
        if ($script:CrowdStrikeFeaturePacks.ContainsKey($f)) {
            foreach ($p in $script:CrowdStrikeFeaturePacks[$f].Permissions) {
                if (-not $scopes.Contains($p)) { $scopes.Add($p) }
            }
        }
    }

    [void]$sb.AppendLine("Required OAuth2 Scopes: $($scopes -join ', ')")

    $checklist = Get-CrowdStrikeIscFeatureChecklist -FeatureNames $FeatureNames
    if ($checklist.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Machine Identity & Feature Checklist')
        foreach ($item in $checklist) {
            [void]$sb.AppendLine("- $item")
        }
    }
    return $sb.ToString().Trim()
}

Export-ModuleMember -Function @(
    'Get-CrowdStrikeCloudRegions',
    'Get-CrowdStrikeFeaturePacks',
    'Get-CrowdStrikeApiBaseUrl',
    'Get-CrowdStrikeRunRecord',
    'Get-CrowdStrikeIscFeatureChecklist',
    'Build-CrowdStrikeConnectionSettings'
)
