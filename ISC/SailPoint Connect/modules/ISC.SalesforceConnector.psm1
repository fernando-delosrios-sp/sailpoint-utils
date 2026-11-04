#Requires -Version 7
Set-StrictMode -Version Latest

$script:SalesforceFeaturePacks = @{
    AgentDiscovery = @{
        Name        = 'AgentDiscovery'
        Label       = 'Machine identity governance - Salesforce Agentforce autonomous agents & bots'
        Description = 'Discovers autonomous Agentforce AI agents, BotDefinition records, BotVersion deployments, and prompt execution identities'
        Permissions = @(
            'View Setup and Configuration'
            'Customize Application'
            'Manage Bot Users and Agents'
            'Read on BotDefinition and BotVersion objects'
            'Manage External Client Applications'
        )
    }
    ActivityInsights = @{
        Name        = 'ActivityInsights'
        Label       = 'Activity Insights - Salesforce user & agent audit activity'
        Description = 'Gathers user and machine activity events for access reviews'
        Permissions = @(
            'View Event Log Files'
            'View All Data'
        )
    }
}

function Get-SalesforceFeaturePacks {
    return $script:SalesforceFeaturePacks
}

function Get-SalesforceAgentDiscoveryFeaturePack {
    return $script:SalesforceFeaturePacks['AgentDiscovery']
}

function Get-SalesforceLoginHost {
    param([string]$EnvironmentType = 'Production')
    switch ($EnvironmentType) {
        'Sandbox' { return 'https://test.salesforce.com' }
        default   { return 'https://login.salesforce.com' }
    }
}

function Get-SalesforceRunRecord {
    param([hashtable]$Context)
    if (-not $Context) { return $null }
    if (-not $Context.ContainsKey('SalesforceRunRecord') -or $null -eq $Context['SalesforceRunRecord']) {
        $Context['SalesforceRunRecord'] = @{
            InstanceUrl          = $null
            Username             = $null
            ConsumerKey          = $null
            ConsumerSecret       = $null
            ConnectedAppResult   = $null
            AgentforceResult     = $null
            SettingsPath         = $null
        }
    }
    return $Context['SalesforceRunRecord']
}

function Invoke-SalesforceCli {
    param(
        [Parameter(Mandatory)][string[]]$CliArgs,
        [switch]$IgnoreError
    )
    $output = & sf @CliArgs --json 2>&1
    $exit = $LASTEXITCODE
    $errors = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($exit -ne 0 -and -not $IgnoreError) {
        throw "sf $($CliArgs -join ' ') failed: $((@($errors) + @($text) | Where-Object { $_ }) -join ' ')"
    }
    if (-not $text) { return $null }
    try {
        return ($text | ConvertFrom-Json -AsHashtable -Depth 20)
    }
    catch {
        return $text
    }
}

function Connect-SalesforceOrg {
    param(
        [string]$InstanceUrl,
        [string]$Alias,
        [switch]$NonInteractive
    )
    # Check if CLI has an active auth org
    try {
        $orgList = Invoke-SalesforceCli -CliArgs @('org', 'list') -IgnoreError
        if ($orgList -and $orgList.status -eq 0 -and $orgList.result -and $orgList.result.nonScratchOrgs) {
            $matched = @($orgList.result.nonScratchOrgs | Where-Object {
                ($Alias -and $_.alias -eq $Alias) -or ($InstanceUrl -and $_.instanceUrl -eq $InstanceUrl) -or $_.isDefaultUsername
            }) | Select-Object -First 1
            if ($matched) { return $matched }
        }
    }
    catch {}

    $loginUrl = if ($InstanceUrl) { $InstanceUrl } else { 'https://login.salesforce.com' }
    if ($NonInteractive) {
        throw "The Salesforce CLI (sf) is not authenticated for $loginUrl. Run: sf org login web --instance-url $loginUrl"
    }
    Write-Info "Signing in to Salesforce org ($loginUrl). A browser window opens."
    & sf org login web --instance-url $loginUrl
    if ($LASTEXITCODE -ne 0) { throw "Salesforce sign-in failed. Run: sf org login web --instance-url $loginUrl" }
}

function Get-SalesforceIscFeatureChecklist {
    param([string[]]$FeatureNames = @())
    $items = [System.Collections.Generic.List[string]]::new()
    $features = @($FeatureNames | Where-Object { $_ })

    if ($features -contains 'AgentDiscovery') {
        $items.Add('Machine Identity Governance: Enable Salesforce Agentforce AI Agent Discovery on the source.')
        $items.Add('Connected App Scopes: Ensure `api`, `refresh_token`, and `offline_access` are authorized.')
        $items.Add('Agentforce Bots: Assign "View Setup and Configuration" and Read on BotDefinition/BotVersion to the integration user.')
        $items.Add('Agent Users: Ensure Agentforce Bot users are mapped to machine accounts in SailPoint ISC.')
        $items.Add('License: Machine Identity & Agent Discovery requires the SailPoint Agentic Fabric license on the tenant.')
    }
    if ($features -contains 'ActivityInsights') {
        $items.Add('Activity Insights: Ensure "View Event Log Files" and "View All Data" are enabled on the integration user profile.')
    }
    return @($items)
}

function Build-SalesforceConnectionSettings {
    param(
        [Parameter(Mandatory)][string]$InstanceUrl,
        [Parameter(Mandatory)][string]$ConsumerKey,
        [string]$Username,
        [string]$LoginUrl = 'https://login.salesforce.com',
        [string[]]$FeatureNames = @()
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# SailPoint ISC Salesforce SaaS Connection Settings')
    [void]$sb.AppendLine("Instance URL: $InstanceUrl")
    [void]$sb.AppendLine("OAuth Login URL: $LoginUrl")
    [void]$sb.AppendLine("Client ID (Consumer Key): $ConsumerKey")
    if ($Username) {
        [void]$sb.AppendLine("Integration Username: $Username")
    }
    [void]$sb.AppendLine("OAuth Scopes: api, refresh_token, offline_access")

    $checklist = Get-SalesforceIscFeatureChecklist -FeatureNames $FeatureNames
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
    'Get-SalesforceFeaturePacks'
    'Get-SalesforceAgentDiscoveryFeaturePack'
    'Get-SalesforceLoginHost'
    'Get-SalesforceRunRecord'
    'Invoke-SalesforceCli'
    'Connect-SalesforceOrg'
    'Get-SalesforceIscFeatureChecklist'
    'Build-SalesforceConnectionSettings'
)
