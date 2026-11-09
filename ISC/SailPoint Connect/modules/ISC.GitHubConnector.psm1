#Requires -Version 7
Set-StrictMode -Version Latest

$script:GitHubFeaturePacks = @{
    AgentDiscovery = @{
        Name        = 'AgentDiscovery'
        Label       = 'Machine identity governance - GitHub Copilot, GitHub Apps & Bots'
        Description = 'Discovers autonomous AI agents, GitHub Copilot seat assignments, GitHub App installations, Bot identities, and machine deploy keys'
        Permissions = @(
            'manage_billing:copilot'
            'read:org'
            'admin:org (for app and bot inventory)'
            'repo (for deploy keys and repository tokens)'
        )
    }
    ActivityInsights = @{
        Name        = 'ActivityInsights'
        Label       = 'Activity Insights - GitHub audit log stream'
        Description = 'Gathers repository activity, commit events, and member audit logs for identity governance'
        Permissions = @(
            'admin:org'
            'read:audit_log'
        )
    }
}

function Get-GitHubFeaturePacks {
    return $script:GitHubFeaturePacks
}

function Get-GitHubAgentDiscoveryFeaturePack {
    return $script:GitHubFeaturePacks['AgentDiscovery']
}

function Get-GitHubRunRecord {
    param([hashtable]$Context)
    if (-not $Context) { return $null }
    if (-not $Context.ContainsKey('GitHubRunRecord') -or $null -eq $Context['GitHubRunRecord']) {
        $Context['GitHubRunRecord'] = @{
            Organization     = $null
            ApiUrl           = $null
            AuthMethod       = $null
            AuthResult       = $null
            AgentDiscovery   = $null
            SettingsPath     = $null
        }
    }
    return $Context['GitHubRunRecord']
}

function Invoke-GitHubCli {
    param(
        [Parameter(Mandatory)][string[]]$CliArgs,
        [switch]$IgnoreError
    )
    $output = & gh @CliArgs 2>&1
    $exit = $LASTEXITCODE
    $errors = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($exit -ne 0 -and -not $IgnoreError) {
        throw "gh $($CliArgs -join ' ') failed: $((@($errors) + @($text) | Where-Object { $_ }) -join ' ')"
    }
    if (-not $text) { return $null }
    try {
        return ($text | ConvertFrom-Json -AsHashtable -Depth 20)
    }
    catch {
        return $text
    }
}

function Connect-GitHubOrg {
    param(
        [string]$Organization,
        [switch]$NonInteractive
    )
    try {
        $status = Invoke-GitHubCli -CliArgs @('auth', 'status') -IgnoreError
        if ($status -and $LASTEXITCODE -eq 0) { return }
    }
    catch {}

    if ($NonInteractive) {
        throw "The GitHub CLI (gh) is not authenticated. Run: gh auth login"
    }
    Write-Info "Signing in to GitHub via CLI (gh auth login). Follow prompts."
    & gh auth login
    if ($LASTEXITCODE -ne 0) { throw "GitHub authentication failed. Run: gh auth login" }
}

function Get-GitHubIscFeatureChecklist {
    param([string[]]$FeatureNames = @())
    $items = [System.Collections.Generic.List[string]]::new()
    $features = @($FeatureNames | Where-Object { $_ })

    if ($features -contains 'AgentDiscovery') {
        $items.Add('Machine Identity Governance: Enable GitHub Copilot seat discovery and bot governance in ISC.')
        $items.Add('Copilot Seats: Grant `manage_billing:copilot` to discover assigned GitHub Copilot licenses.')
        $items.Add('GitHub Apps & Bots: Grant `admin:org` to aggregate Installed Apps, Bot users ([bot]), and service accounts.')
        $items.Add('Deploy Keys & Machine Tokens: Ensure read access on repository deploy keys and fine-grained PATs.')
        $items.Add('License: Machine Identity & Agent Discovery requires the SailPoint Agentic Fabric license on the tenant.')
    }
    if ($features -contains 'ActivityInsights') {
        $items.Add('Activity Insights: Ensure `read:audit_log` is granted to stream organization audit logs into ISC.')
    }
    return @($items)
}

function Build-GitHubConnectionSettings {
    param(
        [string]$Organization = '',
        [string]$ApiUrl = 'https://api.github.com',
        [string]$AuthMethod = 'PersonalAccessToken',
        [string]$TokenMasked = '***',
        [string[]]$FeatureNames = @()
    )
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# SailPoint ISC GitHub SaaS Connection Settings')
    $orgLine = if (-not [string]::IsNullOrWhiteSpace($Organization)) { $Organization } else { '[Your-GitHub-Organization]' }
    [void]$sb.AppendLine("Organization: $orgLine")
    [void]$sb.AppendLine("API URL: $ApiUrl")
    [void]$sb.AppendLine("Authentication Method: $AuthMethod")
    [void]$sb.AppendLine("Access Token: $TokenMasked")
    [void]$sb.AppendLine("Recommended Scopes: repo, admin:org, manage_billing:copilot, read:audit_log")

    $checklist = @(Get-GitHubIscFeatureChecklist -FeatureNames $FeatureNames)
    if ($checklist.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Machine Identity & Agent Discovery Checklist')
        foreach ($item in $checklist) {
            [void]$sb.AppendLine("- $item")
        }
    }
    return $sb.ToString().Trim()
}

Export-ModuleMember -Function @(
    'Get-GitHubFeaturePacks'
    'Get-GitHubAgentDiscoveryFeaturePack'
    'Get-GitHubRunRecord'
    'Invoke-GitHubCli'
    'Connect-GitHubOrg'
    'Get-GitHubIscFeatureChecklist'
    'Build-GitHubConnectionSettings'
)
