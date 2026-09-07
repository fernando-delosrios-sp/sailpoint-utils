#Requires -Version 5.1
<#
.SYNOPSIS
    Creates or updates the GCP service account used by the SailPoint Identity Security Cloud
    Google Workspace SaaS connector.

.DESCRIPTION
    Covers both grant types the connector supports.

    Service Account (default, and the only grant type CIEM and NHI Discovery support): uses the
    Google Cloud SDK (gcloud) to create or update a service account, enable the APIs SailPoint
    documents, attach an organization-level custom IAM role for GCP / CIEM features, issue a JSON
    key, and convert it to the encrypted traditional RSA PEM the ISC source expects. Domain-wide
    delegation and Google Workspace admin roles still have to be granted in the Admin console; the
    script prints the client ID, OAuth scopes, and impersonate-user roles to paste there.

    Client Credentials: enables the same APIs, then runs the OAuth 2.0 authorization-code flow for
    an existing OAuth client (loopback redirect or the documented OAuth Playground redirect) and
    exchanges the code for the offline refresh token the source needs.

    Both modes end with copy-paste-ready Connection Settings values, written to files and offered
    for clipboard copy one field at a time.

    Existing service accounts with the same ID in the project are updated in place rather than duplicated.

    Reference:
    https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/introduction.html
    https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prerequisites.html
    https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prereqs_for_oauth_2_0.html
    https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/connection_settings.html

.PARAMETER GrantType
    ServiceAccount     - service account, domain-wide delegation, impersonated admin (default).
    ClientCredentials  - OAuth client ID, client secret, and offline refresh token.

.PARAMETER ClientId
    OAuth client ID for ClientCredentials, or for the Super Admin sign-in under
    -AssignWorkspaceRoles. Google has no API for creating OAuth clients, so the script walks
    you through the Cloud Console when this is omitted.

.PARAMETER ClientSecret
    OAuth client secret for ClientCredentials.

.PARAMETER RefreshToken
    Existing refresh token. Skips the authorization-code flow.

.PARAMETER RedirectUri
    Redirect URI registered on the OAuth client. Default: http://localhost:8088 (loopback listener).
    Pass https://developers.google.com/oauthplayground to paste the code by hand instead.

.PARAMETER ConsentUser
    Workspace user who authorizes the OAuth client and holds the admin roles under
    ClientCredentials. Used for GCP role binding; defaults to the signed-in gcloud account.

.PARAMETER OrganizationId
    GCP organization ID (numeric). Prompts when omitted.

.PARAMETER ProjectId
    GCP project ID that will own the service account. Prompts when omitted.

.PARAMETER CreateProject
    Create ProjectId under the organization when it does not exist.

.PARAMETER BillingAccountId
    Billing account to link when -CreateProject is used.

.PARAMETER ServiceAccountId
    Service account ID (the part before @). Default: sailpoint-isc-gws.

.PARAMETER DisplayName
    Service account display name. Default: SailPoint ISC Google Workspace.

.PARAMETER ImpersonateUser
    Google Workspace admin email the connector impersonates.

.PARAMETER Feature
    Optional documented feature packs. See the README.

.PARAMETER AggregationOnly
    Omit GCP write permissions (setIamPolicy, IAM role CRUD, service account create).
    Workspace OAuth scopes stay as SailPoint documents them for aggregation and test connection.

.PARAMETER RotateKey
    When updating an existing service account, issue a new JSON key and RSA PEM so the
    script can print Private Key and Private Key Password for Connection Settings.
    Google cannot retrieve an existing key. Omit this only when you already have those
    values from a previous run.

.PARAMETER KeyPassword
    Passphrase for the encrypted RSA private key. Generated when omitted.

.PARAMETER OutputDirectory
    Directory for the JSON key, RSA PEM, and scopes file. Default: ./sourceConfig/google-workspace-isc

.PARAMETER SkipDomainWideDelegationWalkthrough
    Do not open the Admin console or copy the domain-wide delegation Client ID and scopes.

.PARAMETER AssignWorkspaceRoles
    After Service Account setup, sign in as a Super Admin and assign User Management Admin
    and Groups Admin to the impersonate user via the Admin SDK. Super Admin is only assigned
    when DomainManagement is selected (with confirmation). The Admin SDK needs a user token,
    so this needs an OAuth client: pass -ClientId and -ClientSecret, or let the script walk
    you through creating one in the Cloud Console. Domain-wide delegation itself has no
    public API and still uses the Admin console walkthrough.

.PARAMETER OpenSslPath
    openssl executable. Uses PATH when omitted.

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\Google Workspace.ps1

.EXAMPLE
    .\Google Workspace.ps1 -ProjectId 'sailpoint-isc' -ImpersonateUser 'admin@contoso.com' -Feature Gcp,Ciem -NonInteractive

.EXAMPLE
    .\Google Workspace.ps1 -GrantType ClientCredentials -ProjectId 'sailpoint-isc' -ClientId '...apps.googleusercontent.com' -ClientSecret 'GOCSPX-...'

.NOTES
    Sign in with gcloud as a user who can create service accounts and, for GCP/CIEM packs,
    organization custom roles and IAM bindings. The RSA passphrase is displayed once.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateSet('ServiceAccount', 'ClientCredentials')]
    [string]$GrantType,

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$ClientSecret,

    [Parameter()]
    [string]$RefreshToken,

    [Parameter()]
    [string]$RedirectUri,

    [Parameter()]
    [string]$ConsentUser,

    [Parameter()]
    [string]$OrganizationId,

    [Parameter()]
    [string]$ProjectId,

    [Parameter()]
    [switch]$CreateProject,

    [Parameter()]
    [string]$BillingAccountId,

    [Parameter()]
    [string]$ServiceAccountId = 'sailpoint-isc-gws',

    [Parameter()]
    [string]$DisplayName = 'SailPoint ISC Google Workspace',

    [Parameter()]
    [string]$ImpersonateUser,

    [Parameter()]
    [ValidateSet('Gcp', 'Ciem', 'GmailDelegates', 'DeltaAggregation', 'DomainManagement',
        'ActivityInsights', 'NhiDiscovery', 'AgentDiscovery')]
    [string[]]$Feature,

    [Parameter()]
    [switch]$AggregationOnly,

    [Parameter()]
    [switch]$RotateKey,

    [Parameter()]
    [string]$KeyPassword,

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$SkipDomainWideDelegationWalkthrough,

    [Parameter()]
    [switch]$AssignWorkspaceRoles,

    [Parameter()]
    [string]$OpenSslPath,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CreatedServiceAccount = $null

# -----------------------------------------------------------------------------
# Scopes - SailPoint Google Workspace SaaS service-account table
# https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prereqs_for_oauth_2_0.html
# -----------------------------------------------------------------------------

$script:CoreScopes = @(
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.group';                 Purpose = 'Group aggregation and provisioning' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.user';                  Purpose = 'User aggregation and provisioning' }
    @{ Value = 'https://www.googleapis.com/auth/apps.groups.settings';                  Purpose = 'Group Settings API' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.rolemanagement';        Purpose = 'Role create / assign' }
    @{ Value = 'https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly'; Purpose = 'Role aggregation' }
)

$script:GcpScopes = @(
    @{ Value = 'https://www.googleapis.com/auth/cloud-platform'; Purpose = 'GCP resource and IAM access' }
    @{ Value = 'https://www.googleapis.com/auth/iam';            Purpose = 'GCP IAM API' }
)

$script:FeaturePacks = [ordered]@{
    Gcp = @{
        Label = 'Google Cloud Platform (folders, projects, IAM inventory)'
        Apis  = @('iam.googleapis.com', 'cloudresourcemanager.googleapis.com', 'cloudasset.googleapis.com')
    }
    Ciem = @{
        Label = 'CIEM cloud governance (requires a CIEM license)'
        Apis  = @('iam.googleapis.com', 'cloudresourcemanager.googleapis.com', 'cloudasset.googleapis.com', 'logging.googleapis.com')
    }
    GmailDelegates = @{
        Label  = 'Gmail delegates'
        Apis   = @('gmail.googleapis.com')
        Scopes = @(
            'https://www.googleapis.com/auth/gmail.settings.sharing'
            'https://www.googleapis.com/auth/gmail.settings.basic'
            'https://mail.google.com/'
            'https://www.googleapis.com/auth/gmail.modify'
            'https://www.googleapis.com/auth/gmail.readonly'
        )
    }
    DeltaAggregation = @{
        Label  = 'Delta aggregation (Reports audit)'
        Apis   = @()
        Scopes = @('https://www.googleapis.com/auth/admin.reports.audit.readonly')
    }
    DomainManagement = @{
        Label  = 'Manage domain as a GCP account type'
        Apis   = @()
        Scopes = @('https://www.googleapis.com/auth/admin.directory.domain')
    }
    ActivityInsights = @{
        Label  = 'Activity Insights (audit and usage reports)'
        Apis   = @()
        Scopes = @(
            'https://www.googleapis.com/auth/admin.reports.audit.readonly'
            'https://www.googleapis.com/auth/admin.reports.usage.readonly'
        )
    }
    NhiDiscovery = @{
        Label = 'NHI discovery (secrets, IAM monitoring, compliance)'
        Apis  = @(
            'cloudasset.googleapis.com'
            'apikeys.googleapis.com'
            'recommender.googleapis.com'
            'logging.googleapis.com'
            'secretmanager.googleapis.com'
            'cloudfunctions.googleapis.com'
            'drive.googleapis.com'
        )
    }
    AgentDiscovery = @{
        Label = 'Vertex AI agent aggregation'
        Apis  = @('aiplatform.googleapis.com', 'cloudasset.googleapis.com', 'iam.googleapis.com')
    }
}

$script:CoreApis = @(
    'admin.googleapis.com'
    'groupssettings.googleapis.com'
)

# Custom org role - CIEM minimum permissions plus connector custom-role operations.
# https://documentation.sailpoint.com/saas/help/ciem/gcp/config_gcp.html
# https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/custom_roles.html
$script:GcpReadPermissions = @(
    'cloudasset.assets.searchAllIamPolicies'
    'cloudasset.assets.searchAllResources'
    'iam.roles.get'
    'iam.roles.list'
    'iam.serviceAccounts.get'
    'iam.serviceAccounts.getIamPolicy'
    'iam.serviceAccounts.list'
    'logging.logEntries.list'
    'resourcemanager.folders.getIamPolicy'
    'resourcemanager.folders.list'
    'resourcemanager.organizations.get'
    'resourcemanager.organizations.getIamPolicy'
    'resourcemanager.projects.get'
    'resourcemanager.projects.getIamPolicy'
    'resourcemanager.projects.list'
)

$script:GcpWritePermissions = @(
    'iam.roles.create'
    'iam.roles.delete'
    'iam.roles.update'
    'iam.serviceAccounts.create'
    'iam.serviceAccounts.setIamPolicy'
    'resourcemanager.folders.setIamPolicy'
    'resourcemanager.organizations.setIamPolicy'
    'resourcemanager.projects.setIamPolicy'
)

$script:AgentPermissions = @(
    'aiplatform.agents.get'
    'aiplatform.agents.list'
)

# Display names follow SailPoint NHI docs; IDs are GCP predefined roles (not the display-name slug).
# Secret Manager Viewer is roles/secretmanager.viewer; API Keys Viewer is roles/serviceusage.apiKeysViewer.
$script:NhiBuiltInRoles = @(
    @{ Id = 'roles/viewer';                              Label = 'Viewer' }
    @{ Id = 'roles/resourcemanager.organizationViewer';  Label = 'Organization Viewer' }
    @{ Id = 'roles/secretmanager.viewer';                Label = 'Secret Manager Viewer' }
    @{ Id = 'roles/secretmanager.secretAccessor';        Label = 'Secret Manager Secret Accessor' }
    @{ Id = 'roles/serviceusage.apiKeysViewer';          Label = 'API Keys Viewer' }
    @{ Id = 'roles/cloudfunctions.viewer';               Label = 'Cloud Functions Viewer' }
    @{ Id = 'roles/iam.serviceAccountViewer';            Label = 'View Service Accounts' }
    @{ Id = 'roles/recommender.iamViewer';               Label = 'IAM Recommender Viewer' }
    @{ Id = 'roles/iam.organizationRoleViewer';          Label = 'Organization Role Viewer' }
    @{ Id = 'roles/resourcemanager.folderViewer';        Label = 'Folder Viewer' }
    @{ Id = 'roles/logging.viewer';                      Label = 'Logs Viewer' }
    @{ Id = 'roles/logging.viewAccessor';                Label = 'Logs View Accessor' }
    @{ Id = 'roles/logging.privateLogViewer';            Label = 'Private Logs Viewer' }
    @{ Id = 'roles/iam.securityReviewer';                Label = 'Security Reviewer' }
)

$script:CustomRoleId = 'sailpointGoogleWorkspace'

# -----------------------------------------------------------------------------
# Console helpers
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Google Workspace SaaS source connection setup' -ForegroundColor Cyan
    Write-Host '  Creates or updates the GCP service account used by the Google Workspace connector.' -ForegroundColor DarkCyan
    Write-Host ''
}

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor DarkGray
}

$script:Esc = [char]27
$script:AnsiEraseLine = "$([char]27)[K"
$script:PromptBackToken = 'PROMPT_BACK'
$script:MenuFallbackReported = $false
$script:MenuBlockerDetail = 'the console window is too short'

# Prompts answered so far. A wizard step compares this before and after its block to tell a step
# that asked the operator something from one that resolved on its own.
$script:PromptCount = 0

$script:WizardCursor = 0
$script:WizardResume = 0
$script:WizardStep = -1
$script:WizardStepPromptCount = 0
$script:WizardAskedSteps = @{}
$script:InWizardPrompt = $false

function Test-PromptBack {
    param($ErrorRecord)
    return [string]$ErrorRecord.Exception.Message -eq $script:PromptBackToken
}

function Invoke-PromptBack {
    throw $script:PromptBackToken
}

function Invoke-PromptExit {
    Write-Host ''
    Write-Host 'Cancelled.' -ForegroundColor Yellow
    exit 0
}

# The wizard body is replayed from the top after every Esc, so each pass starts at step 0 and the
# steps before the resume point reuse the answers already given.
function Start-WizardPass {
    $script:WizardCursor = 0
    $script:InWizardPrompt = $false
}

function Enter-WizardPrompt {
    $step = $script:WizardCursor
    $script:WizardCursor++
    if ($step -lt $script:WizardResume) { return $false }
    $script:WizardStep = $step
    $script:WizardStepPromptCount = $script:PromptCount
    $script:InWizardPrompt = $true
    return $true
}

function Complete-WizardPrompt {
    if (-not $script:InWizardPrompt) { return }
    $script:InWizardPrompt = $false
    if ($script:PromptCount -gt $script:WizardStepPromptCount) {
        $script:WizardAskedSteps[$script:WizardStep] = $true
    }
    $script:WizardResume = $script:WizardCursor
}

# Esc resumes at the closest earlier step that actually asked something; steps that ran
# automatically are not return points. Returns $false when nothing was asked before this one.
function Move-WizardBack {
    # Esc on a prompt goes to the previous asked step. Esc between prompts (for example while
    # reconnecting) goes back to the last asked step, which may be the one just completed.
    $before = if ($script:InWizardPrompt) { $script:WizardStep } else { $script:WizardStep + 1 }
    $target = -1
    foreach ($step in $script:WizardAskedSteps.Keys) {
        if ($step -lt $before -and $step -gt $target) { $target = $step }
    }
    if ($target -lt 0) { return $false }

    # Everything after the target is asked again on the way forward, so let the record rebuild
    # instead of keeping steps that may no longer prompt.
    foreach ($step in @($script:WizardAskedSteps.Keys)) {
        if ($step -gt $target) { $script:WizardAskedSteps.Remove($step) }
    }
    $script:WizardResume = $target
    return $true
}

function Test-CancelledNavigation {
    param($ErrorRecord)
    if (Test-PromptBack $ErrorRecord) { return $true }
    return $ErrorRecord.Exception -is [System.Management.Automation.PipelineStoppedException]
}

function Get-ConsoleMenuBlocker {
    if ($NonInteractive) { return 'non-interactive mode' }
    if ($Host.Name -eq 'Windows PowerShell ISE Host') { return 'the ISE cannot read single keystrokes' }

    if ($Host.Name -eq 'ConsoleHost') {
        try { $null = [Console]::KeyAvailable }
        catch { return 'this console cannot read single keystrokes' }

        try { if ([Console]::IsOutputRedirected) { return 'console output is redirected' } } catch { }
    }

    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -ne 'Unix') {
        $vt = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
        if ($vt -and -not $vt.Value) { return 'this console does not support virtual terminal sequences' }
    }

    return $null
}

function Read-MenuKey {
    $info = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $code = [int]$info.VirtualKeyCode
    $character = $info.Character
    $ctrl = $false
    try { $ctrl = ([int]$info.ControlKeyState -band 0x0C) -ne 0 } catch { }

    if ([int][char]$character -eq 3 -or $code -eq 3 -or ($ctrl -and $code -eq 67)) {
        return [PSCustomObject]@{ Name = 'CtrlC'; Char = [char]0; Character = $character }
    }

    $name = switch ($code) {
        8       { 'Backspace' }
        38      { 'Up' }
        40      { 'Down' }
        36      { 'Home' }
        35      { 'End' }
        32      { 'Space' }
        13      { 'Enter' }
        27      { 'Escape' }
        default { 'Other' }
    }
    return [PSCustomObject]@{
        Name      = $name
        Char      = [char]::ToLowerInvariant($character)
        Character = $character
    }
}

function Write-MenuFallbackNotice {
    param([string]$Reason)

    if ($NonInteractive -or -not $Reason -or $script:MenuFallbackReported) { return }
    $script:MenuFallbackReported = $true
    Write-Info "Arrow-key menus are unavailable here ($Reason); using numbered prompts."
}

function Get-MenuWindowSize {
    try { return @{ Width = [Console]::WindowWidth; Height = [Console]::WindowHeight } } catch { }
    try {
        $size = $Host.UI.RawUI.WindowSize
        return @{ Width = $size.Width; Height = $size.Height }
    }
    catch { }
    return @{ Width = 0; Height = 0 }
}

function Get-MenuWidth {
    $width = (Get-MenuWindowSize).Width
    if ($width -le 20) { return 80 }
    return $width - 1
}

function Invoke-ConsoleMenu {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Labels,
        [switch]$MultiSelect,
        [switch]$EscapeMeansDefault,
        [int]$InitialIndex = 0
    )

    $count = $Labels.Count
    if ($count -eq 0) { return , @() }

    $selected = New-Object 'bool[]' $count
    $cursor = [Math]::Min([Math]::Max($InitialIndex, 0), $count - 1)
    $hint = if ($MultiSelect) {
        'Up/Down move   Space select   A all   N none   Enter confirm   Esc back   Ctrl+C exit'
    }
    elseif ($EscapeMeansDefault) {
        'Up/Down move   Enter select   Esc done   Ctrl+C exit'
    }
    else {
        'Up/Down move   Enter select   Esc back   Ctrl+C exit'
    }

    $rows = $count + 2
    $windowHeight = (Get-MenuWindowSize).Height
    if ($windowHeight -gt 0 -and $windowHeight -le $rows) {
        $script:MenuBlockerDetail = "the console is $windowHeight rows tall and this menu needs $($rows + 1)"
        return $null
    }

    $drawn = $false
    $draw = {
        $width = Get-MenuWidth
        if ($drawn) { Write-Host ("{0}[{1}A" -f $script:Esc, $rows) -NoNewline }
        $drawn = $true

        $lines = @(, @($Prompt, [System.ConsoleColor]::White))
        $lines += , @("   $hint", [System.ConsoleColor]::DarkGray)
        for ($i = 0; $i -lt $count; $i++) {
            $marker = if ($i -eq $cursor) { '>' } else { ' ' }
            $box = if ($MultiSelect) { if ($selected[$i]) { '[x] ' } else { '[ ] ' } } else { '' }
            $color = if ($i -eq $cursor) { [System.ConsoleColor]::Cyan }
                elseif ($MultiSelect -and $selected[$i]) { [System.ConsoleColor]::Green }
                else { [System.ConsoleColor]::Gray }
            $lines += , @(("  {0} {1}{2}" -f $marker, $box, $Labels[$i]), $color)
        }

        foreach ($line in $lines) {
            $text = $line[0]
            if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
            Write-Host ($text + $script:AnsiEraseLine) -ForegroundColor $line[1]
        }
    }

    try {
        try { [Console]::CursorVisible = $false } catch { }

        while ($true) {
            . $draw

            try { $key = Read-MenuKey }
            catch {
                $script:MenuBlockerDetail = 'this host cannot read single keystrokes'
                return $null
            }

            if ($key.Name -eq 'CtrlC') { Invoke-PromptExit }

            if ($key.Name -eq 'Up' -or $key.Char -eq 'k') {
                $cursor = ($cursor - 1 + $count) % $count
            }
            elseif ($key.Name -eq 'Down' -or $key.Char -eq 'j') {
                $cursor = ($cursor + 1) % $count
            }
            elseif ($key.Name -eq 'Home') {
                $cursor = 0
            }
            elseif ($key.Name -eq 'End') {
                $cursor = $count - 1
            }
            elseif ($key.Name -eq 'Space') {
                if ($MultiSelect) { $selected[$cursor] = -not $selected[$cursor] } else { return , @($cursor) }
            }
            elseif ($key.Name -eq 'Enter') {
                if (-not $MultiSelect) { return , @($cursor) }
                return , @(for ($i = 0; $i -lt $count; $i++) { if ($selected[$i]) { $i } })
            }
            elseif ($key.Name -eq 'Escape') {
                if ($EscapeMeansDefault) { return , @() }
                Invoke-PromptBack
            }
            elseif ($MultiSelect -and $key.Char -eq 'a') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $true }
            }
            elseif ($MultiSelect -and $key.Char -eq 'n') {
                for ($i = 0; $i -lt $count; $i++) { $selected[$i] = $false }
            }
        }
    }
    finally {
        try { . $draw } catch { }
        try { [Console]::CursorVisible = $true } catch { }
    }
}

function Read-TypedLine {
    param([string]$PromptText)

    if (Get-ConsoleMenuBlocker) {
        return Read-Host $PromptText
    }

    Write-Host "${PromptText}: " -NoNewline
    $buffer = [System.Text.StringBuilder]::new()
    while ($true) {
        try { $key = Read-MenuKey }
        catch {
            Write-Host ''
            return Read-Host $PromptText
        }

        switch ($key.Name) {
            'CtrlC' { Invoke-PromptExit }
            'Escape' {
                Write-Host ''
                Invoke-PromptBack
            }
            'Enter' {
                Write-Host ''
                return $buffer.ToString()
            }
            'Backspace' {
                if ($buffer.Length -gt 0) {
                    $null = $buffer.Remove($buffer.Length - 1, 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            default {
                $ch = $key.Character
                if ($ch -and [int][char]$ch -ge 32) {
                    $null = $buffer.Append($ch)
                    Write-Host $ch -NoNewline
                }
            }
        }
    }
}

function Read-InputString {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [string]$Default,
        [switch]$Required,
        [scriptblock]$Validate
    )

    if ($NonInteractive) {
        if ($Required -and [string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a value for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
    $suffix = if ($Default) { " [$Default]" } else { '' }
    while ($true) {
        $value = Read-TypedLine "$Prompt$suffix"
        if ([string]::IsNullOrWhiteSpace($value)) { $value = $Default }
        $value = if ($null -eq $value) { '' } else { $value.Trim() }

        if ($Required -and [string]::IsNullOrWhiteSpace($value)) {
            Write-Host '   A value is required.' -ForegroundColor Yellow
            continue
        }
        if ($Validate -and -not [string]::IsNullOrWhiteSpace($value)) {
            $failure = & $Validate $value
            if ($failure) {
                Write-Host "   $failure" -ForegroundColor Yellow
                continue
            }
        }
        return $value
    }
}

function Read-Choice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels,
        [string]$Default,
        [switch]$EscapeMeansDefault
    )

    if (-not $Labels) { $Labels = $Options }
    if ($NonInteractive) {
        if ([string]::IsNullOrWhiteSpace($Default)) {
            throw "Non-interactive mode requires a choice for: $Prompt"
        }
        return $Default
    }

    $script:PromptCount++
    $defaultIndex = if ($Default) { [array]::IndexOf($Options, $Default) } else { 0 }
    if ($defaultIndex -lt 0) { $defaultIndex = 0 }

    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $menuLabels = @(
            for ($i = 0; $i -lt $Options.Count; $i++) {
                if ($Options[$i] -eq $Default) { "$($Labels[$i])  (default)" } else { $Labels[$i] }
            }
        )
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $menuLabels -InitialIndex $defaultIndex `
            -EscapeMeansDefault:$EscapeMeansDefault
        if ($null -ne $picked) {
            if (@($picked).Count -gt 0) { return $Options[@($picked)[0]] }
            return $Options[$defaultIndex]
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $marker = if ($Options[$i] -eq $Default) { '*' } else { ' ' }
        Write-Host ("  {0} {1}) {2}" -f $marker, ($i + 1), $Labels[$i])
    }

    $defaultNumber = if ($Default) { $defaultIndex + 1 } else { 0 }
    while ($true) {
        $label = if ($EscapeMeansDefault) {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber]" } else { "Select 1-$($Options.Count)" }
        }
        else {
            if ($defaultNumber -gt 0) { "Select 1-$($Options.Count) [$defaultNumber], or b to go back" } else { "Select 1-$($Options.Count), or b to go back" }
        }
        $raw = Read-Host $label
        if (-not $EscapeMeansDefault -and $raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw) -and $defaultNumber -gt 0) {
            return $Options[$defaultNumber - 1]
        }
        $n = 0
        if ([int]::TryParse($raw, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
            return $Options[$n - 1]
        }
        Write-Host '   Enter a number from the list.' -ForegroundColor Yellow
    }
}

function Read-MultiChoice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [string[]]$Labels
    )

    if (-not $Labels) { $Labels = $Options }
    if ($NonInteractive) { return @() }

    $script:PromptCount++
    $blocker = Get-ConsoleMenuBlocker
    if (-not $blocker) {
        $picked = Invoke-ConsoleMenu -Prompt $Prompt -Labels $Labels -MultiSelect
        if ($null -ne $picked) {
            return @(@($picked) | ForEach-Object { $Options[$_] })
        }
        $blocker = $script:MenuBlockerDetail
    }
    Write-MenuFallbackNotice -Reason $blocker

    Write-Host $Prompt -ForegroundColor White
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("    {0}) {1}" -f ($i + 1), $Labels[$i])
    }

    while ($true) {
        $raw = Read-Host "Select numbers separated by commas, Enter for none, or b to go back"
        if ($raw -match '^(b|back)$') { Invoke-PromptBack }
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }

        $selected = [System.Collections.Generic.List[string]]::new()
        $valid = $true
        foreach ($token in ($raw -split ',')) {
            $n = 0
            if ([int]::TryParse($token.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) {
                if (-not $selected.Contains($Options[$n - 1])) { $selected.Add($Options[$n - 1]) }
            }
            else {
                $valid = $false
                break
            }
        }
        if ($valid) { return $selected.ToArray() }
        Write-Host '   Enter numbers from the list, separated by commas.' -ForegroundColor Yellow
    }
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [bool]$Default = $true
    )

    if ($NonInteractive) { return $Default }

    $defaultOption = if ($Default) { 'Yes' } else { 'No' }
    return (Read-Choice -Prompt $Prompt -Options @('Yes', 'No') -Default $defaultOption) -eq 'Yes'
}

# -----------------------------------------------------------------------------
# gcloud / openssl
# -----------------------------------------------------------------------------

function Get-GCloudCommand {
    $cmd = Get-Command gcloud -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command gcloud.cmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'The Google Cloud SDK (gcloud) was not found on PATH. Install it from https://cloud.google.com/sdk/docs/install and run gcloud init.'
}

function Invoke-GCloud {
    param(
        [Parameter(Mandatory)][string[]]$GcloudArgs,
        [switch]$ExpectJson
    )

    $gcloud = Get-GCloudCommand
    $errorFile = [System.IO.Path]::GetTempFileName()
    $previousPrompt = $env:CLOUDSDK_CORE_DISABLE_PROMPTS
    $env:CLOUDSDK_CORE_DISABLE_PROMPTS = '1'
    try {
        $stdout = & $gcloud @GcloudArgs 2>$errorFile
        $code = $LASTEXITCODE
        $stderr = ''
        if (Test-Path $errorFile) {
            $stderr = [System.IO.File]::ReadAllText($errorFile)
        }
        if ($code -ne 0) {
            $detail = (@($stderr, $stdout) | Where-Object { $_ } ) -join ' '
            throw ("gcloud {0} failed: {1}" -f ($GcloudArgs -join ' '), $detail.Trim())
        }
        if (-not $ExpectJson) {
            if ($null -eq $stdout) { return '' }
            return ($stdout | Out-String).Trim()
        }
        $text = if ($stdout -is [array]) { $stdout -join "`n" } else { [string]$stdout }
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }
        return $text | ConvertFrom-Json
    }
    finally {
        if ($null -eq $previousPrompt) {
            Remove-Item Env:CLOUDSDK_CORE_DISABLE_PROMPTS -ErrorAction SilentlyContinue
        }
        else {
            $env:CLOUDSDK_CORE_DISABLE_PROMPTS = $previousPrompt
        }
        Remove-Item -LiteralPath $errorFile -Force -ErrorAction SilentlyContinue
    }
}

function Test-GCloudAuth {
    $account = Invoke-GCloud -GcloudArgs @('config', 'get-value', 'account', '--quiet')
    if ([string]::IsNullOrWhiteSpace($account) -or $account -eq '(unset)') {
        return $null
    }
    return $account
}

function Connect-GoogleCloud {
    Write-Step 'Google Cloud SDK'
    $null = Get-GCloudCommand
    Write-Ok 'gcloud is on PATH'

    $account = Test-GCloudAuth
    if ($account) {
        $reuse = Read-YesNo -Prompt "Already signed in as $account. Reuse this session?" -Default $true
        if ($reuse) {
            Write-Ok "Using $account"
            return $account
        }
    }

    Write-Info 'Opening the Google sign-in flow...'
    Invoke-GCloud -GcloudArgs @('auth', 'login', '--brief', '--quiet') | Out-Null
    $account = Test-GCloudAuth
    if (-not $account) {
        throw 'gcloud auth login did not produce an active account.'
    }
    Write-Ok "Signed in as $account"
    return $account
}

function Get-OpenSslCommand {
    if ($OpenSslPath) {
        if (-not (Test-Path -LiteralPath $OpenSslPath)) {
            throw "openssl was not found at $OpenSslPath"
        }
        return $OpenSslPath
    }
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'openssl was not found on PATH. Install OpenSSL (Git for Windows includes it) or pass -OpenSslPath. SailPoint requires a traditional encrypted RSA PEM.'
}

# Set-StrictMode turns a missing property into a terminating error, so optional JSON fields are
# read through the property bag instead.
function Get-JsonProperty {
    param(
        [Parameter(Mandatory)][AllowNull()]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if (-not $property) { return $null }
    return $property.Value
}

function Test-OpenSslTraditionalFlag {
    param([Parameter(Mandatory)][string]$OpenSsl)

    # LibreSSL (macOS /usr/bin/openssl) treats unknown flags as cipher names:
    # "Invalid cipher 'traditional'". OpenSSL 3 documents -traditional as a real flag.
    $help = & $OpenSsl rsa -help 2>&1 | Out-String
    return [bool]($help -match '(?m)^\s*-traditional\b')
}

function ConvertTo-EncryptedRsaPem {
    param(
        [Parameter(Mandatory)][string]$JsonKeyPath,
        [Parameter(Mandatory)][string]$PemPath,
        [Parameter(Mandatory)][string]$Passphrase
    )

    $openssl = Get-OpenSslCommand
    $json = Get-Content -LiteralPath $JsonKeyPath -Raw | ConvertFrom-Json
    $privateKey = Get-JsonProperty -InputObject $json -Name 'private_key'
    if (-not $privateKey) {
        throw "JSON key $JsonKeyPath does not contain private_key."
    }

    $pkcs8Path = [System.IO.Path]::ChangeExtension($PemPath, '.pkcs8.pem')
    $pkcs8 = $privateKey -replace '\\n', "`n"
    [System.IO.File]::WriteAllText($pkcs8Path, $pkcs8.Trim() + "`n")

    $previous = $env:SP_GWS_PEM_PASS
    $env:SP_GWS_PEM_PASS = $Passphrase
    try {
        $rsaArgs = @(
            'rsa'
            '-aes-256-cbc'
            '-in', $pkcs8Path
            '-out', $PemPath
            '-passout', 'env:SP_GWS_PEM_PASS'
        )
        if (Test-OpenSslTraditionalFlag -OpenSsl $openssl) {
            $rsaArgs += '-traditional'
        }

        $errorFile = [System.IO.Path]::GetTempFileName()
        $null = & $openssl @rsaArgs 2>$errorFile
        $code = $LASTEXITCODE
        $stderr = if (Test-Path $errorFile) { [System.IO.File]::ReadAllText($errorFile) } else { '' }
        Remove-Item -LiteralPath $errorFile -Force -ErrorAction SilentlyContinue
        if ($code -ne 0 -or -not (Test-Path -LiteralPath $PemPath)) {
            throw "openssl failed to convert the key to traditional RSA PEM: $stderr"
        }

        $pemText = [System.IO.File]::ReadAllText($PemPath)
        if ($pemText -notmatch 'BEGIN RSA PRIVATE KEY') {
            throw "openssl wrote a key that is not traditional RSA PEM (expected BEGIN RSA PRIVATE KEY). Install OpenSSL 3+ or pass -OpenSslPath. Output started with: $($pemText.Substring(0, [Math]::Min(40, $pemText.Length)))"
        }
    }
    finally {
        if ($null -eq $previous) {
            Remove-Item Env:SP_GWS_PEM_PASS -ErrorAction SilentlyContinue
        }
        else {
            $env:SP_GWS_PEM_PASS = $previous
        }
        Remove-Item -LiteralPath $pkcs8Path -Force -ErrorAction SilentlyContinue
    }

    return $json
}

function New-KeyPassword {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()
    return [Convert]::ToBase64String($bytes)
}

function Test-NeedsGcp {
    param([string[]]$FeatureNames)
    foreach ($name in @($FeatureNames)) {
        if (@('Gcp', 'Ciem', 'NhiDiscovery', 'AgentDiscovery') -contains $name) { return $true }
    }
    return $false
}

function Get-SelectedScopes {
    param([string[]]$FeatureNames)

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $script:CoreScopes) {
        if (-not $values.Contains($item.Value)) { $values.Add($item.Value) }
    }
    if (Test-NeedsGcp -FeatureNames $FeatureNames) {
        foreach ($item in $script:GcpScopes) {
            if (-not $values.Contains($item.Value)) { $values.Add($item.Value) }
        }
    }
    foreach ($name in @($FeatureNames)) {
        $pack = $script:FeaturePacks[$name]
        if ($pack.ContainsKey('Scopes')) {
            foreach ($scope in @($pack.Scopes)) {
                if (-not $values.Contains($scope)) { $values.Add($scope) }
            }
        }
    }
    return $values.ToArray()
}

function Get-SelectedApis {
    param([string[]]$FeatureNames)

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($api in $script:CoreApis) { $values.Add($api) }
    foreach ($name in @($FeatureNames)) {
        foreach ($api in @($script:FeaturePacks[$name].Apis)) {
            if ($api -and -not $values.Contains($api)) { $values.Add($api) }
        }
    }
    return $values.ToArray()
}

function Get-CustomRolePermissions {
    param(
        [string[]]$FeatureNames,
        [switch]$SkipGcpWrite
    )

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $script:GcpReadPermissions) { $values.Add($p) }
    if (-not $SkipGcpWrite) {
        foreach ($p in $script:GcpWritePermissions) { $values.Add($p) }
    }
    if (@($FeatureNames) -contains 'AgentDiscovery') {
        foreach ($p in $script:AgentPermissions) {
            if (-not $values.Contains($p)) { $values.Add($p) }
        }
    }
    return @($values | Sort-Object -Unique)
}

function ConvertTo-RoleYaml {
    param(
        [Parameter(Mandatory)][string[]]$Permissions,
        [Parameter(Mandatory)][string]$Title
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("title: $Title")
    $lines.Add('description: SailPoint Identity Security Cloud Google Workspace SaaS connector')
    $lines.Add('stage: GA')
    $lines.Add('includedPermissions:')
    foreach ($p in $Permissions) {
        $lines.Add("- $p")
    }
    return ($lines -join "`n") + "`n"
}

function Get-ServiceAccountEmail {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Project
    )
    return "$AccountId@$Project.iam.gserviceaccount.com"
}

function Get-ExistingServiceAccount {
    param(
        [Parameter(Mandatory)][string]$Email,
        [Parameter(Mandatory)][string]$Project
    )
    try {
        return Invoke-GCloud -ExpectJson -GcloudArgs @(
            'iam', 'service-accounts', 'describe', $Email,
            "--project=$Project", '--format=json', '--quiet'
        )
    }
    catch {
        return $null
    }
}

function Set-OrganizationCustomRole {
    param(
        [Parameter(Mandatory)][string]$OrgId,
        [Parameter(Mandatory)][string[]]$Permissions
    )

    $yamlPath = Join-Path ([System.IO.Path]::GetTempPath()) "sailpoint-gws-role-$OrgId.yaml"
    [System.IO.File]::WriteAllText($yamlPath, (ConvertTo-RoleYaml -Permissions $Permissions -Title 'SailPoint ISC Google Workspace'))
    $roleName = "organizations/$OrgId/roles/$($script:CustomRoleId)"
    try {
        $exists = $false
        try {
            Invoke-GCloud -GcloudArgs @('iam', 'roles', 'describe', $script:CustomRoleId, "--organization=$OrgId", '--quiet') | Out-Null
            $exists = $true
        }
        catch { }

        if ($exists) {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'roles', 'update', $script:CustomRoleId,
                "--organization=$OrgId", "--file=$yamlPath", '--quiet'
            ) | Out-Null
            Write-Ok "Updated organization role $roleName"
        }
        else {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'roles', 'create', $script:CustomRoleId,
                "--organization=$OrgId", "--file=$yamlPath", '--quiet'
            ) | Out-Null
            Write-Ok "Created organization role $roleName"
        }
        return $roleName
    }
    finally {
        Remove-Item -LiteralPath $yamlPath -Force -ErrorAction SilentlyContinue
    }
}

function Add-IamPolicyBinding {
    param(
        [Parameter(Mandatory)][ValidateSet('organizations', 'projects')][string]$ResourceKind,
        [Parameter(Mandatory)][string]$ResourceId,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Role
    )

    $bindArgs = @(
        $ResourceKind, 'add-iam-policy-binding', $ResourceId,
        "--member=$Member",
        "--role=$Role",
        '--condition=None',
        '--quiet'
    )
    try {
        Invoke-GCloud -GcloudArgs $bindArgs | Out-Null
    }
    catch {
        Invoke-GCloud -GcloudArgs @(
            $ResourceKind, 'add-iam-policy-binding', $ResourceId,
            "--member=$Member",
            "--role=$Role",
            '--quiet'
        ) | Out-Null
    }
}

# -----------------------------------------------------------------------------
# OAuth 2.0 authorization-code flow (Client Credentials grant type)
# -----------------------------------------------------------------------------

$script:GoogleAuthUri = 'https://accounts.google.com/o/oauth2/v2/auth'
$script:GoogleTokenUri = 'https://oauth2.googleapis.com/token'
$script:PlaygroundRedirect = 'https://developers.google.com/oauthplayground'
$script:AuthCodeTimeoutSeconds = 300

function Get-GoogleAuthorizationUrl {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes
    )

    $query = @(
        "client_id=$([uri]::EscapeDataString($OAuthClientId))"
        "redirect_uri=$([uri]::EscapeDataString($Redirect))"
        'response_type=code'
        'access_type=offline'
        'prompt=consent'
        'include_granted_scopes=true'
        "scope=$([uri]::EscapeDataString(($Scopes -join ' ')))"
    ) -join '&'

    return "$script:GoogleAuthUri`?$query"
}

function Open-Url {
    param([Parameter(Mandatory)][string]$Url)

    try {
        $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
        if ($platform -eq 'Unix') {
            $opener = if (Get-Command open -ErrorAction SilentlyContinue) { 'open' } else { 'xdg-open' }
            Start-Process $opener $Url -ErrorAction Stop | Out-Null
        }
        else {
            Start-Process $Url -ErrorAction Stop | Out-Null
        }
        return $true
    }
    catch {
        return $false
    }
}

# Blocks on the loopback redirect until Google sends the code back, so the operator never has to
# copy anything out of the address bar.
function Wait-GoogleAuthorizationCode {
    param([Parameter(Mandatory)][string]$Redirect)

    $prefix = $Redirect.TrimEnd('/') + '/'
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($prefix)
    try {
        $listener.Start()
    }
    catch {
        throw "Could not listen on $prefix. Choose a free port with -RedirectUri, or use the OAuth Playground redirect. $($_.Exception.Message)"
    }

    try {
        Write-Info "Waiting for the Google redirect on $prefix (Ctrl+C to cancel) ..."
        # A consent screen that blocks the sign-in never redirects here, so the wait is bounded
        # rather than hanging until Ctrl+C. Polling also keeps Ctrl+C responsive.
        $pending = $listener.GetContextAsync()
        $deadline = (Get-Date).AddSeconds($script:AuthCodeTimeoutSeconds)
        while (-not $pending.Wait(500)) {
            if ((Get-Date) -gt $deadline) {
                $waited = if ($script:AuthCodeTimeoutSeconds -ge 120) { "$([int]($script:AuthCodeTimeoutSeconds / 60)) minutes" } else { "$script:AuthCodeTimeoutSeconds seconds" }
                throw ("No redirect arrived on $prefix within $waited. " +
                    "If the browser showed 'Access blocked - has not completed the Google verification process', the OAuth client's audience does not allow that account: " +
                    'add it under Audience > Test users, or set User type to Internal, then retry.')
            }
        }
        $context = $pending.Result
        $code = $context.Request.QueryString['code']
        $failure = $context.Request.QueryString['error']

        $body = if ($code) {
            '<html><body style="font-family:sans-serif"><h3>Authorization complete</h3><p>Return to the PowerShell window.</p></body></html>'
        }
        else {
            "<html><body style='font-family:sans-serif'><h3>Authorization failed</h3><p>$failure</p></body></html>"
        }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $context.Response.ContentType = 'text/html'
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.OutputStream.Close()

        if (-not $code) {
            throw "Google returned an error instead of an authorization code: $failure"
        }
        return $code
    }
    finally {
        $listener.Stop()
        $listener.Close()
    }
}

function Invoke-GoogleTokenExchange {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$Code
    )

    try {
        return Invoke-RestMethod -Method Post -Uri $script:GoogleTokenUri -ErrorAction Stop -Body @{
            code          = $Code
            client_id     = $OAuthClientId
            client_secret = $OAuthClientSecret
            redirect_uri  = $Redirect
            grant_type    = 'authorization_code'
        }
    }
    catch {
        $detail = $_.ErrorDetails
        $body = if ($detail) { $detail.Message } else { $_.Exception.Message }
        throw "Google rejected the token exchange: $body"
    }
}

function Get-GoogleOAuthToken {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes,
        [Parameter(Mandatory)][string]$SignInHint
    )

    $authUrl = Get-GoogleAuthorizationUrl -OAuthClientId $OAuthClientId -Redirect $Redirect -Scopes $Scopes
    $isLoopback = $Redirect -match '^http://(localhost|127\.0\.0\.1)'

    Write-Host ''
    Write-Host 'Authorize the OAuth client at:' -ForegroundColor White
    Write-Host $authUrl -ForegroundColor Yellow
    Write-Host ''
    if (-not (Open-Url -Url $authUrl)) {
        Write-Info 'Could not open a browser automatically; copy the URL above.'
    }
    Write-Info $SignInHint

    $code = if ($isLoopback) {
        Wait-GoogleAuthorizationCode -Redirect $Redirect
    }
    else {
        Write-Info 'The OAuth Playground shows the authorization code under "Step 2 - Exchange authorization code for tokens".'
        Read-InputString -Prompt 'Authorization code' -Required
    }

    return Invoke-GoogleTokenExchange -OAuthClientId $OAuthClientId -OAuthClientSecret $OAuthClientSecret `
        -Redirect $Redirect -Code $code
}

function Get-GoogleRefreshToken {
    param(
        [Parameter(Mandatory)][string]$OAuthClientId,
        [Parameter(Mandatory)][string]$OAuthClientSecret,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string[]]$Scopes
    )

    $response = Get-GoogleOAuthToken -OAuthClientId $OAuthClientId -OAuthClientSecret $OAuthClientSecret `
        -Redirect $Redirect -Scopes $Scopes `
        -SignInHint 'Sign in as the Workspace user whose roles the connector should use, and accept every scope.'

    $refresh = Get-JsonProperty -InputObject $response -Name 'refresh_token'
    if (-not $refresh) {
        throw 'Google returned an access token without a refresh token. Remove the app under https://myaccount.google.com/permissions and authorize again so consent is re-prompted.'
    }
    return [string]$refresh
}

function Invoke-AdminSdk {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        $Body
    )

    $headers = @{ Authorization = "Bearer $AccessToken" }
    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $headers
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = ($Body | ConvertTo-Json -Compress -Depth 6)
    }
    try {
        return Invoke-RestMethod @params
    }
    catch {
        $detail = $_.ErrorDetails
        $message = if ($detail) { $detail.Message } else { $_.Exception.Message }
        throw "Admin SDK $Method $Uri failed: $message"
    }
}

function Get-AdminSdkRoles {
    param([Parameter(Mandatory)][string]$AccessToken)

    $roles = [System.Collections.Generic.List[object]]::new()
    $uri = 'https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roles?maxResults=100'
    while ($uri) {
        $page = Invoke-AdminSdk -AccessToken $AccessToken -Method Get -Uri $uri
        foreach ($role in @((Get-JsonProperty -InputObject $page -Name 'items'))) {
            if ($role) { $roles.Add($role) }
        }
        $token = Get-JsonProperty -InputObject $page -Name 'nextPageToken'
        if ($token) {
            $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roles?maxResults=100&pageToken=$([uri]::EscapeDataString([string]$token))"
        }
        else {
            $uri = $null
        }
    }
    return $roles.ToArray()
}

function Resolve-WorkspaceAdminRole {
    param(
        [Parameter(Mandatory)]$Roles,
        [Parameter(Mandatory)][string]$RoleName,
        [Parameter(Mandatory)][string]$Description
    )

    foreach ($role in @($Roles)) {
        $name = [string](Get-JsonProperty -InputObject $role -Name 'roleName')
        $desc = [string](Get-JsonProperty -InputObject $role -Name 'roleDescription')
        if ($name -eq $RoleName -or $desc -eq $Description) {
            return $role
        }
    }
    return $null
}

function Test-WorkspaceRoleAssigned {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$UserId,
        [Parameter(Mandatory)][string]$RoleId
    )

    $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments?userKey=$([uri]::EscapeDataString($UserId))&maxResults=100"
    while ($uri) {
        $page = Invoke-AdminSdk -AccessToken $AccessToken -Method Get -Uri $uri
        foreach ($assignment in @((Get-JsonProperty -InputObject $page -Name 'items'))) {
            if (-not $assignment) { continue }
            if ([string](Get-JsonProperty -InputObject $assignment -Name 'roleId') -eq $RoleId) {
                return $true
            }
        }
        $token = Get-JsonProperty -InputObject $page -Name 'nextPageToken'
        if ($token) {
            $uri = "https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments?userKey=$([uri]::EscapeDataString($UserId))&maxResults=100&pageToken=$([uri]::EscapeDataString([string]$token))"
        }
        else {
            $uri = $null
        }
    }
    return $false
}

function Get-WorkspaceAdminAccounts {
    param([Parameter(Mandatory)][string]$AccessToken)

    try {
        $response = Invoke-AdminSdk -AccessToken $AccessToken -Method Get `
            -Uri 'https://admin.googleapis.com/admin/directory/v1/users?customer=my_customer&query=isAdmin%3Dtrue&maxResults=25&projection=basic'
        $users = Get-JsonProperty -InputObject $response -Name 'users'
        return @($users | ForEach-Object { [string](Get-JsonProperty -InputObject $_ -Name 'primaryEmail') } | Where-Object { $_ })
    }
    catch {
        return @()
    }
}

function Add-WorkspaceAdminRoles {
    param(
        [Parameter(Mandatory)][string]$AccessToken,
        [Parameter(Mandatory)][string]$UserEmail,
        [Parameter(Mandatory)][string[]]$WantedDescriptions,
        [hashtable]$RoleNameByDescription
    )

    Write-Step "Assigning Workspace admin roles to $UserEmail"
    # A mistyped address reaches this point looking like any other failure, so name the cause and
    # show the admins that do exist rather than returning a raw 404.
    try {
        $user = Invoke-AdminSdk -AccessToken $AccessToken -Method Get `
            -Uri "https://admin.googleapis.com/admin/directory/v1/users/$([uri]::EscapeDataString($UserEmail))"
    }
    catch {
        if ([string]$_.Exception.Message -notmatch '404|notFound|Resource Not Found') { throw }
        Write-Warning "This Workspace has no user $UserEmail. A typo in the address or the domain is the usual cause."
        $admins = @(Get-WorkspaceAdminAccounts -AccessToken $AccessToken)
        if ($admins.Count) {
            Write-Info 'Admin accounts that do exist here:'
            foreach ($admin in $admins) { Write-Host "     $admin" -ForegroundColor White }
        }
        throw "The impersonate user $UserEmail does not exist, so no roles can be assigned. Re-run with -ImpersonateUser set to the correct address; Connection Settings carry the same address and need it too."
    }
    $userId = [string](Get-JsonProperty -InputObject $user -Name 'id')
    if (-not $userId) {
        throw "Admin SDK did not return an id for $UserEmail."
    }

    $roles = @(Get-AdminSdkRoles -AccessToken $AccessToken)
    foreach ($description in $WantedDescriptions) {
        $roleName = $RoleNameByDescription[$description]
        $role = Resolve-WorkspaceAdminRole -Roles $roles -RoleName $roleName -Description $description
        if (-not $role) {
            Write-Warning "Workspace role '$description' ($roleName) was not found in this customer."
            continue
        }
        $roleId = [string](Get-JsonProperty -InputObject $role -Name 'roleId')
        if (Test-WorkspaceRoleAssigned -AccessToken $AccessToken -UserId $userId -RoleId $roleId) {
            Write-Ok "$description is already assigned"
            continue
        }
        Invoke-AdminSdk -AccessToken $AccessToken -Method Post `
            -Uri 'https://admin.googleapis.com/admin/directory/v1/customer/my_customer/roleassignments' `
            -Body @{
                roleId    = $roleId
                assignedTo = $userId
                scopeType = 'CUSTOMER'
            } | Out-Null
        Write-Ok "Assigned $description"
    }
}

function Show-CopyPasteValue {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Instruction,
        [switch]$HideValue
    )

    if (-not $HideValue) {
        Write-Info "${Label}:"
        Write-Host "   $Value" -ForegroundColor White
    }
    if (Copy-ToClipboard -Text $Value) {
        Write-Ok "$Instruction Copied to the clipboard as well."
    }
    else {
        Write-Warning 'No clipboard tool is available. Copy from the value above.'
        Write-Ok $Instruction
    }
}

function Write-DomainWideDelegationValues {
    param(
        [Parameter(Mandatory)][string]$ClientIdValue,
        [Parameter(Mandatory)][string]$ScopesValue
    )

    Write-Info 'Client ID:'
    Write-Host "   $ClientIdValue" -ForegroundColor White
    Write-Info 'OAuth scopes to add (comma-delimited):'
    Write-Host "   $ScopesValue" -ForegroundColor White
    foreach ($scope in ($ScopesValue -split ',')) {
        if (-not [string]::IsNullOrWhiteSpace($scope)) {
            Write-Host "     $scope" -ForegroundColor DarkGray
        }
    }
}

function Wait-Continue {
    param([Parameter(Mandatory)][string]$Prompt)

    if ($NonInteractive) { return }
    $null = Read-TypedLine $Prompt
}

function Get-OAuthClientCreateUrl {
    param([Parameter(Mandatory)][string]$Project)

    return "https://console.cloud.google.com/auth/clients/create?project=$Project"
}

function Get-OAuthAudienceUrl {
    param([Parameter(Mandatory)][string]$Project)

    return "https://console.cloud.google.com/auth/audience?project=$Project"
}

function Write-OAuthClientSteps {
    param(
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$ClientName
    )

    Write-Host ''
    Write-Host '   1. Application type: Web application' -ForegroundColor White
    Write-Host "   2. Name: $ClientName" -ForegroundColor White
    Write-Host "   3. Authorized redirect URIs → Add URI → $Redirect" -ForegroundColor White
    Write-Host '   4. Create, then copy the Client ID and Client secret from the dialog' -ForegroundColor White
    Write-Host ''
    Write-Info 'Google shows the client secret only once, in that dialog. Copy it before closing.'
    Write-Info 'If the console asks you to configure Google Auth Platform first, do that, then come back to Clients.'
    Write-Info 'User type Internal is only offered when the project belongs to a Workspace organization. Otherwise choose External.'
}

# An External app in Testing rejects every account that is not a test user, with
# "Access blocked - has not completed the Google verification process". The account has to be
# listed before the sign-in, so this runs while the browser is still on the console.
function Invoke-OAuthAudienceWalkthrough {
    param(
        [Parameter(Mandatory)][string]$Project,
        [string]$SignInAccount
    )

    if ($NonInteractive) { return }

    Write-Info 'Audience: an External app in Testing only lets accounts listed as test users sign in.'
    Write-Info 'Internal apps (Workspace organization projects) allow everyone in the organization, so they need nothing here.'
    if (-not (Read-YesNo -Prompt 'Open the Audience page to add the signing-in account as a test user?' -Default $true)) {
        return
    }

    $audienceUrl = Get-OAuthAudienceUrl -Project $Project
    if (Open-Url -Url $audienceUrl) {
        Write-Ok "Opened $audienceUrl"
    }
    else {
        Write-Info "Open $audienceUrl"
    }
    Write-Info 'Under Test users: Add users → the Super Admin account you will sign in with → Save.'

    if ($SignInAccount) {
        Show-CopyPasteValue -Label 'Likely test user' -Value $SignInAccount `
            -Instruction 'Add this account if it is the one that will sign in. Otherwise add the Super Admin you use.'
    }
    Wait-Continue 'Press Enter once the account is saved as a test user'
}

# Google has no API for creating a consent-screen OAuth client: gcloud iam oauth-clients manages
# Workforce Identity Federation clients, and IAP clients are locked to IAP redirect URIs. The
# Admin SDK only accepts a user token, so the console is the only way to get one. This walkthrough
# opens the create page, copies the redirect URI, and collects the pair. Returns $null when the
# operator opts out; Esc on the client ID rethrows so the caller can re-offer.
function Invoke-OAuthClientWalkthrough {
    param(
        [Parameter(Mandatory)][string]$Project,
        [Parameter(Mandatory)][string]$Redirect,
        [Parameter(Mandatory)][string]$Reason,
        [string]$ClientName = 'SailPoint ISC setup script',
        [string]$SignInAccount
    )

    if ($NonInteractive) { return $null }

    Write-Step 'OAuth client (Cloud Console — Google has no API for this)'
    Write-Info $Reason
    Write-Info 'The client is only used for this sign-in. Delete it afterwards if you prefer.'

    if (-not (Read-YesNo -Prompt 'Create the OAuth client now (No assigns the roles in the Admin console instead)?' -Default $true)) {
        return $null
    }

    $createUrl = Get-OAuthClientCreateUrl -Project $Project
    if (Open-Url -Url $createUrl) {
        Write-Ok "Opened $createUrl"
    }
    else {
        Write-Info "Open $createUrl"
    }

    Write-OAuthClientSteps -Redirect $Redirect -ClientName $ClientName
    Show-CopyPasteValue -Label 'Authorized redirect URI' -Value $Redirect `
        -Instruction 'Paste under Authorized redirect URIs. It must match exactly.'

    $clientIdValue = $null
    $clientSecretValue = $null
    $phase = 0
    while ($phase -lt 2) {
        try {
            if ($phase -eq 0) {
                $clientIdValue = Read-InputString -Prompt 'Client ID from the dialog' -Required
                $phase = 1
            }
            else {
                $clientSecretValue = Read-InputString -Prompt 'Client secret from the dialog' -Required
                $phase = 2
            }
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if ($phase -eq 0) { throw }
            $phase = 0
        }
    }

    Invoke-OAuthAudienceWalkthrough -Project $Project -SignInAccount $SignInAccount

    return [PSCustomObject]@{ ClientId = $clientIdValue; ClientSecret = $clientSecretValue }
}

# Google does not publish an API for domain-wide delegation. This walkthrough opens the Admin
# console page, prints Client ID and OAuth scopes first, then copies each field so the Super
# Admin only has to click Add new. Values are not secrets; they stay on screen if the clipboard
# is overwritten. Esc on a wait returns to the previous field; Esc on Client ID returns to Yes/No.
function Invoke-DomainWideDelegationWalkthrough {
    param(
        [Parameter(Mandatory)][string]$ClientIdValue,
        [Parameter(Mandatory)][string]$ScopesValue
    )

    Write-Step 'Domain-wide delegation (Admin console — Google has no API for this)'
    Write-Info 'Only a Super Admin can authorize the service account. The console page will open; this script copies each field in order.'
    Write-Info 'Esc goes back to the previous field. Client ID and scopes stay on screen if the clipboard is overwritten.'
    $dwdUrl = 'https://admin.google.com/ac/owl/domainwidedelegation'
    if (Open-Url -Url $dwdUrl) {
        Write-Ok "Opened $dwdUrl"
    }
    else {
        Write-Info "Open $dwdUrl"
    }

    Write-DomainWideDelegationValues -ClientIdValue $ClientIdValue -ScopesValue $ScopesValue

    $phase = 0
    while ($phase -lt 2) {
        try {
            if ($phase -eq 0) {
                Show-CopyPasteValue -Label 'Client ID' -Value $ClientIdValue -HideValue `
                    -Instruction 'In the Admin console: Add new → paste into Client ID.'
                Wait-Continue 'Press Enter after the Client ID is pasted (Esc goes back)'
                $phase = 1
            }
            else {
                Show-CopyPasteValue -Label 'OAuth scopes' -Value $ScopesValue -HideValue `
                    -Instruction 'Paste into OAuth scopes (comma-delimited), then Authorize.'
                Wait-Continue 'Press Enter after Authorize succeeds (Esc goes back to Client ID)'
                $phase = 2
            }
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if ($phase -eq 0) { throw }
            $phase = 0
        }
    }
}

function Copy-ToClipboard {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    $setClipboard = Get-Command Set-Clipboard -ErrorAction SilentlyContinue
    if ($setClipboard) {
        try {
            Set-Clipboard -Value $Text -ErrorAction Stop
            return $true
        }
        catch { }
    }

    foreach ($tool in @('pbcopy', 'wl-copy', 'xclip')) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        try {
            $toolArgs = if ($tool -eq 'xclip') { @('-selection', 'clipboard') } else { @() }
            $Text | & $cmd.Source @toolArgs
            return $true
        }
        catch { }
    }

    return $false
}

function Get-MaskedSecretDisplay {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 4) { return '***' }
    return ('***' + $Value.Substring($Value.Length - 4))
}

function Get-CompletionPreview {
    param(
        [AllowNull()][string]$Value,
        [switch]$Mask
    )

    if ($Mask) { return Get-MaskedSecretDisplay -Value $Value }
    if ([string]::IsNullOrEmpty($Value)) { return '(empty)' }
    if ($Value.Length -le 72) { return $Value }
    return ($Value.Substring(0, 69) + '...')
}

function Invoke-CompletionActionMenu {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string[]]$Situation,
        [Parameter(Mandatory)][object[]]$Items
    )

    Write-Host ''
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * [Math]::Min($Title.Length, 60))) -ForegroundColor Cyan
    foreach ($line in $Situation) {
        Write-Host "  $line" -ForegroundColor White
    }
    Write-Host ''
    Write-Host '  Copy each value into the matching ISC Connection Settings field, or open a link to finish pending manual steps.' -ForegroundColor Yellow

    if ($Items.Count -eq 0) { return }

    if ($NonInteractive) {
        Write-Host ''
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            Write-Host "  $($item.Label): $preview ($verb)" -ForegroundColor Yellow
        }
        return
    }

    $doneLabel = 'Done'
    while ($true) {
        $labels = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Items) {
            $preview = Get-CompletionPreview -Value ([string]$item.Value) -Mask:([bool]$item.Mask)
            $verb = if ($item.Kind -eq 'Open') { 'Open' } else { 'Copy' }
            $labels.Add(('{0}: {1} ({2})' -f $item.Label, $preview, $verb))
        }
        $labels.Add($doneLabel)

        $picked = Read-Choice -Prompt 'Select a value to copy or a link to open:' `
            -Options $labels.ToArray() `
            -Default $doneLabel `
            -EscapeMeansDefault
        if ($picked -eq $doneLabel) { return }

        $index = [array]::IndexOf($labels.ToArray(), $picked)
        if ($index -lt 0 -or $index -ge $Items.Count) { continue }

        $selected = $Items[$index]
        if ($selected.Kind -eq 'Open') {
            if (Open-Url -Url ([string]$selected.Value)) {
                Write-Ok "Opened $($selected.Label)"
            }
            else {
                Write-Warning "Could not open a browser. URL: $($selected.Value)"
            }
        }
        else {
            if (Copy-ToClipboard -Text ([string]$selected.Value)) {
                Write-Ok "$($selected.Label) copied to the clipboard"
            }
            else {
                Write-Warning 'No clipboard tool is available (Set-Clipboard, pbcopy, wl-copy, or xclip). Copy from the list above.'
            }
        }
    }
}

# Values print flush left under their label so a double- or triple-click selects the value alone.
function Write-ConnectionSettings {
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Fields,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Path
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $Fields.Keys) {
        $lines.Add("### $name")
        $lines.Add([string]$Fields[$name])
        $lines.Add('')
    }
    Set-Content -LiteralPath $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Ok "Saved $Title to $Path"
}

function Test-ConnectionSettingIsSecret {
    param([Parameter(Mandatory)][string]$Name)

    return @(
        'Private Key'
        'Private Key Password'
        'Client Secret'
        'Refresh Token'
    ) -contains $Name
}

function Add-ConnectorIamBinding {
    param(
        [Parameter(Mandatory)][string]$OrgId,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$Member,
        [Parameter(Mandatory)][string]$Role
    )

    try {
        Add-IamPolicyBinding -ResourceKind organizations -ResourceId $OrgId -Member $Member -Role $Role
        return 'organization'
    }
    catch {
        $message = $_.Exception.Message
        if ($message -notmatch 'not supported for this resource') {
            throw
        }
        Add-IamPolicyBinding -ResourceKind projects -ResourceId $ProjectId -Member $Member -Role $Role
        return 'project'
    }
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

Write-Banner

try {
    $account = Connect-GoogleCloud

    $askGrantType = -not $GrantType
    $askOrganizationId = -not $OrganizationId
    $askProjectId = -not $ProjectId
    $askCreateProject = -not $PSBoundParameters.ContainsKey('CreateProject')
    $askBillingAccountId = -not $BillingAccountId
    $askRedirectUri = -not $RedirectUri
    $askFeature = -not $PSBoundParameters.ContainsKey('Feature')
    $askAggregationOnly = -not $PSBoundParameters.ContainsKey('AggregationOnly') -and -not $NonInteractive
    $askRotateKey = -not $PSBoundParameters.ContainsKey('RotateKey') -and -not $NonInteractive
    $askKeyPassword = -not $KeyPassword

    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            Write-Step 'Grant type'
            if (Enter-WizardPrompt) {
                if ($askGrantType) {
                    $GrantType = Read-Choice -Prompt 'Grant Type used by the ISC source' `
                        -Options @('ServiceAccount', 'ClientCredentials') `
                        -Labels @(
                            'Service Account - service account key + impersonated admin (required for CIEM and NHI Discovery)'
                            'Client Credentials - OAuth client ID, secret, and refresh token'
                        ) `
                        -Default $(if ($GrantType) { $GrantType } else { 'ServiceAccount' })
                }
                Complete-WizardPrompt
            }
            $isServiceAccount = $GrantType -eq 'ServiceAccount'
            Write-Ok $(if ($isServiceAccount) { 'Service Account' } else { 'Client Credentials' })

            if ($isServiceAccount) {
                $null = Get-OpenSslCommand
                Write-Ok 'openssl is available for RSA conversion'
            }

            Write-Step 'Organization'
            $orgs = @()
            try {
                $orgs = @(Invoke-GCloud -ExpectJson -GcloudArgs @('organizations', 'list', '--format=json', '--quiet'))
            }
            catch {
                Write-Warning "Could not list organizations: $($_.Exception.Message)"
            }
            if (Enter-WizardPrompt) {
                if ($orgs.Count -eq 1 -and $askOrganizationId -and -not $OrganizationId) {
                    $OrganizationId = [string]$orgs[0].name.Replace('organizations/', '')
                    Write-Ok "Using organization $($orgs[0].displayName) ($OrganizationId)"
                }
                elseif ($orgs.Count -gt 1 -and $askOrganizationId) {
                    $orgIds = @($orgs | ForEach-Object { [string]$_.name.Replace('organizations/', '') })
                    $orgLabels = @(
                        for ($i = 0; $i -lt $orgs.Count; $i++) {
                            '{0} ({1})' -f $orgs[$i].displayName, $orgIds[$i]
                        }
                    )
                    $OrganizationId = Read-Choice -Prompt 'GCP organization' -Options $orgIds -Labels $orgLabels -Default $(if ($OrganizationId) { $OrganizationId } else { $orgIds[0] })
                }
                elseif ($orgs.Count -eq 0 -and $askOrganizationId) {
                    $OrganizationId = Read-InputString -Prompt 'GCP organization ID (blank to skip GCP/CIEM org roles)' -Default $OrganizationId
                }
                Complete-WizardPrompt
            }
            if ($OrganizationId) {
                Write-Ok "Organization $OrganizationId"
            }
            else {
                Write-Info 'No organization selected. GCP / CIEM / NHI packs will not be available.'
            }

            Write-Step 'Project'
            $configuredProject = Invoke-GCloud -GcloudArgs @('config', 'get-value', 'project', '--quiet')
            if ($configuredProject -eq '(unset)') { $configuredProject = '' }
            if (Enter-WizardPrompt) {
                if ($askProjectId) {
                    $ProjectId = Read-InputString -Prompt 'GCP project ID' -Default $(if ($ProjectId) { $ProjectId } else { $configuredProject }) -Required
                }
                Complete-WizardPrompt
            }

            $projectExists = $false
            try {
                Invoke-GCloud -GcloudArgs @('projects', 'describe', $ProjectId, '--quiet') | Out-Null
                $projectExists = $true
                Write-Ok "Project $ProjectId exists"
            }
            catch {
                Write-Info "Project $ProjectId was not found"
            }

            if (Enter-WizardPrompt) {
                if (-not $projectExists) {
                    if ($askCreateProject) {
                        $CreateProject = [switch](Read-YesNo -Prompt "Create project $ProjectId?" -Default $true)
                    }
                    if (-not $CreateProject) {
                        throw "Project $ProjectId does not exist. Re-run with -CreateProject or pass an existing -ProjectId."
                    }
                    if (-not $OrganizationId) {
                        throw 'Creating a project requires -OrganizationId.'
                    }
                    if ($askBillingAccountId) {
                        $billing = @()
                        try {
                            $billing = @(Invoke-GCloud -ExpectJson -GcloudArgs @('billing', 'accounts', 'list', '--format=json', '--quiet'))
                        }
                        catch { }
                        $open = @($billing | Where-Object { $_.open -eq $true })
                        if ($open.Count -gt 0) {
                            $billIds = @($open | ForEach-Object { [string]$_.name.Replace('billingAccounts/', '') })
                            $billLabels = @($open | ForEach-Object { $_.displayName })
                            $BillingAccountId = Read-Choice -Prompt 'Billing account' -Options $billIds -Labels $billLabels -Default $(if ($BillingAccountId) { $BillingAccountId } else { $billIds[0] })
                        }
                        else {
                            $BillingAccountId = Read-InputString -Prompt 'Billing account ID' -Default $BillingAccountId -Required
                        }
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($isServiceAccount) {
                    $ServiceAccountId = Read-InputString -Prompt 'Service account ID' -Default $ServiceAccountId -Required -Validate {
                        param($v)
                        if ($v -notmatch '^[a-z][a-z0-9-]{4,28}[a-z0-9]$') {
                            return 'Use 6-30 characters: lowercase letters, digits, hyphens; must start with a letter.'
                        }
                    }
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                if ($isServiceAccount) {
                    $DisplayName = Read-InputString -Prompt 'Service account display name' -Default $DisplayName -Required
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                if ($isServiceAccount) {
                    # A consumer account has no Admin console, so it can be neither the impersonate
                    # user nor the Super Admin who authorizes delegation. Warn rather than block:
                    # only the operator knows which domain their Workspace tenant uses.
                    while ($true) {
                        $ImpersonateUser = Read-InputString -Prompt 'Email of Workspace user to impersonate' -Default $ImpersonateUser -Required -Validate {
                            param($v)
                            if ($v -notmatch '^[^@]+@[^@]+\.[^@]+$') { return 'Enter a full email address.' }
                            if ($v -match '@(gmail|googlemail)\.com$' -and $v -match '^[^@]*[^a-zA-Z0-9.+@]') {
                                return 'Gmail addresses only contain letters, digits, and dots, so this address cannot exist. Check for a typo.'
                            }
                        }
                        if ($ImpersonateUser -notmatch '@(gmail|googlemail)\.com$') { break }
                        Write-Warning 'That is a consumer Google account. The connector impersonates a Workspace admin in your managed domain, and only that domain has the Admin console where delegation and admin roles are granted.'
                        if ($NonInteractive -or (Read-YesNo -Prompt 'Use it anyway?' -Default $false)) { break }
                    }
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                    if (-not $isServiceAccount) {
                    Write-Step 'OAuth client'
                    Write-Info 'Google has no API for creating OAuth clients, so this one is created in the Cloud Console.'
                    if ($askRedirectUri) {
                        $RedirectUri = Read-Choice -Prompt 'Redirect URI registered on that OAuth client' `
                            -Options @('http://localhost:8088', $script:PlaygroundRedirect) `
                            -Labels @(
                                'http://localhost:8088 - this script catches the code automatically'
                                "$($script:PlaygroundRedirect) - documented flow, paste the code by hand"
                            ) `
                            -Default $(if ($RedirectUri) { $RedirectUri } else { 'http://localhost:8088' })
                    }
                    if ($ClientId -and $ClientSecret) {
                        Write-Info "Make sure $RedirectUri is registered under Authorized redirect URIs on that client."
                    }
                    else {
                        Write-OAuthClientSteps -Redirect $RedirectUri -ClientName 'SailPoint ISC Google Workspace'
                        if (Read-YesNo -Prompt 'Open the Cloud Console page to create it?' -Default $true) {
                            $oauthCreateUrl = Get-OAuthClientCreateUrl -Project $ProjectId
                            if (Open-Url -Url $oauthCreateUrl) {
                                Write-Ok "Opened $oauthCreateUrl"
                            }
                            else {
                                Write-Info "Open $oauthCreateUrl"
                            }
                            Show-CopyPasteValue -Label 'Authorized redirect URI' -Value $RedirectUri `
                                -Instruction 'Paste under Authorized redirect URIs. It must match exactly.'
                        }
                    }
                    Write-Info 'An External app left in Testing expires refresh tokens after 7 days, which breaks the source. Publish it, or use an Internal app in a Workspace organization.'
                    Invoke-OAuthAudienceWalkthrough -Project $ProjectId -SignInAccount $(if ($ConsentUser) { $ConsentUser } else { $account })
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                if (-not $isServiceAccount) {
                    $ClientId = Read-InputString -Prompt 'OAuth client ID' -Default $ClientId -Required
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                if (-not $isServiceAccount) {
                    $ClientSecret = Read-InputString -Prompt 'OAuth client secret' -Default $ClientSecret -Required
                }
                Complete-WizardPrompt
            }
            if (Enter-WizardPrompt) {
                if (-not $isServiceAccount) {
                    $ConsentUser = Read-InputString -Prompt 'Workspace user that authorizes the client' -Default $(if ($ConsentUser) { $ConsentUser } else { $account }) -Required -Validate {
                        param($v)
                        if ($v -notmatch '^[^@]+@[^@]+\.[^@]+$') { return 'Enter a full email address.' }
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askFeature) {
                    $packNames = @($script:FeaturePacks.Keys)
                    $packLabels = @($packNames | ForEach-Object { $script:FeaturePacks[$_].Label })
                    $Feature = @(Read-MultiChoice -Prompt 'Optional feature packs (Enter for none)' -Options $packNames -Labels $packLabels)
                }
                Complete-WizardPrompt
            }
            $Feature = @($Feature | Where-Object { $_ })

            if (Enter-WizardPrompt) {
                if ($askAggregationOnly) {
                    $AggregationOnly = [switch](Read-YesNo -Prompt 'Aggregation only (skip GCP write permissions)?' -Default $false)
                }
                Complete-WizardPrompt
            }

            $needsGcp = Test-NeedsGcp -FeatureNames $Feature
            if ($needsGcp -and -not $OrganizationId) {
                throw 'Gcp, Ciem, NhiDiscovery, and AgentDiscovery require a GCP organization. Pass -OrganizationId.'
            }

            $saEmail = $null
            $isUpdate = $false
            if ($isServiceAccount) {
                $saEmail = Get-ServiceAccountEmail -AccountId $ServiceAccountId -Project $ProjectId
                $existing = $null
                if ($projectExists) {
                    $existing = Get-ExistingServiceAccount -Email $saEmail -Project $ProjectId
                }
                $isUpdate = $null -ne $existing

                if (Enter-WizardPrompt) {
                    if ($isUpdate) {
                        Write-Ok "Service account $saEmail already exists (update)"
                        if ($askRotateKey) {
                            Write-Host ''
                            Write-Info 'Google cannot show an existing private key again.'
                            Write-Info 'Y - issue a new key and print Private Key + Private Key Password for Connection Settings.'
                            Write-Info 'N - update APIs and roles only. Paste the PEM and password from a previous run.'
                            $RotateKey = [switch](Read-YesNo -Prompt 'Print a new Private Key and password for Connection Settings?' -Default $false)
                        }
                    }
                    else {
                        $RotateKey = [switch]$true
                        Write-Info "Will create $saEmail and print a new Private Key and password"
                    }
                    Complete-WizardPrompt
                }

                if (Enter-WizardPrompt) {
                    if ($RotateKey -and $askKeyPassword) {
                        if ($NonInteractive) {
                            $KeyPassword = New-KeyPassword
                        }
                        else {
                            $entered = Read-InputString -Prompt 'Private Key Password for the ISC source (blank to generate)'
                            $KeyPassword = if ($entered) { $entered } else { New-KeyPassword }
                        }
                    }
                    Complete-WizardPrompt
                }
            }
            else {
                if (Enter-WizardPrompt) { Complete-WizardPrompt }
                if (Enter-WizardPrompt) { Complete-WizardPrompt }
            }

            if (Enter-WizardPrompt) {
                if (-not $OutputDirectory) {
                    $OutputDirectory = Join-Path (Get-Location) (Join-Path 'sourceConfig' 'google-workspace-isc')
                }
                $OutputDirectory = Read-InputString -Prompt 'Output directory for key files' -Default $OutputDirectory -Required
                Complete-WizardPrompt
            }

            $scopes = Get-SelectedScopes -FeatureNames $Feature
            $apis = Get-SelectedApis -FeatureNames $Feature
            $scopeCsv = $scopes -join ','

            Write-Host ''
            Write-Host "   Signed in           : $account"
            Write-Host "   Grant type          : $(if ($isServiceAccount) { 'Service Account' } else { 'Client Credentials' })"
            Write-Host "   Organization        : $(if ($OrganizationId) { $OrganizationId } else { '(none)' })"
            Write-Host "   Project             : $ProjectId"
            if ($isServiceAccount) {
                Write-Host "   Service account     : $saEmail"
                Write-Host "   Impersonate user    : $ImpersonateUser"
                Write-Host "   Issue key           : $RotateKey"
            }
            else {
                Write-Host "   OAuth client ID     : $ClientId"
                Write-Host "   Redirect URI        : $RedirectUri"
                Write-Host "   Authorizing user    : $ConsentUser"
                Write-Host "   Refresh token       : $(if ($RefreshToken) { 'supplied' } else { 'authorization-code flow' })"
            }
            Write-Host "   Features            : $(if ($Feature.Count) { $Feature -join ', ' } else { '(none)' })"
            Write-Host "   Aggregation only    : $AggregationOnly"
            Write-Host ''
            if ($isServiceAccount) {
                Write-Info 'After this script, a Super Admin must add domain-wide delegation in Admin console (Security → API controls).'
            }
            else {
                Write-Info 'The authorizing user needs the Workspace admin roles for the operations the source performs.'
            }

            if (Enter-WizardPrompt) {
                if (-not (Read-YesNo -Prompt 'Proceed?' -Default $true)) {
                    Write-Host 'Cancelled.' -ForegroundColor Yellow
                    return
                }
                Complete-WizardPrompt
            }

            $wizardComplete = $true
        }
        catch {
            if (-not (Test-PromptBack $_)) { throw }
            if (-not (Move-WizardBack)) {
                Write-Host ''
                Write-Host 'Cancelled.' -ForegroundColor Yellow
                return
            }
        }
    }

    $target = if ($isServiceAccount) { $saEmail } else { $ProjectId }
    $action = if (-not $isServiceAccount) { "Configure Client Credentials for $ProjectId" }
        elseif ($isUpdate) { "Update service account $saEmail" }
        else { "Create service account $saEmail" }
    if (-not $PSCmdlet.ShouldProcess($target, $action)) { return }

    if (-not $projectExists -and $CreateProject) {
        Write-Step "Creating project $ProjectId"
        Invoke-GCloud -GcloudArgs @(
            'projects', 'create', $ProjectId,
            "--organization=$OrganizationId",
            "--name=$DisplayName",
            '--quiet'
        ) | Out-Null
        Invoke-GCloud -GcloudArgs @(
            'billing', 'projects', 'link', $ProjectId,
            "--billing-account=$BillingAccountId",
            '--quiet'
        ) | Out-Null
        Write-Ok "Created and billed $ProjectId"
        $projectExists = $true
    }

    Invoke-GCloud -GcloudArgs @('config', 'set', 'project', $ProjectId, '--quiet') | Out-Null

    Write-Step 'Enabling APIs'
    Invoke-GCloud -GcloudArgs (@('services', 'enable') + $apis + @("--project=$ProjectId", '--quiet')) | Out-Null
    Write-Ok ($apis -join ', ')

    $delegationClientId = $null
    if ($isServiceAccount) {
        Write-Step $(if ($isUpdate) { 'Updating service account' } else { 'Creating service account' })
        if (-not $isUpdate) {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'service-accounts', 'create', $ServiceAccountId,
                "--display-name=$DisplayName",
                "--description=SailPoint ISC Google Workspace SaaS connector",
                "--project=$ProjectId",
                '--quiet'
            ) | Out-Null
            $script:CreatedServiceAccount = $saEmail
            Write-Ok "Created $saEmail"
        }
        else {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'service-accounts', 'update', $saEmail,
                "--display-name=$DisplayName",
                "--project=$ProjectId",
                '--quiet'
            ) | Out-Null
            Write-Ok "Updated display name on $saEmail"
        }

        $sa = Get-ExistingServiceAccount -Email $saEmail -Project $ProjectId
        if (-not $sa) { throw "Service account $saEmail was not found after create/update." }
        $delegationClientId = [string]$sa.uniqueId
        Write-Ok "Client ID (domain-wide delegation): $delegationClientId"
    }

    $customRoleName = $null
    if ($needsGcp) {
        # Client Credentials calls Google as the consenting Workspace user, so GCP access is
        # granted to that user rather than to a service account.
        $member = if ($isServiceAccount) { "serviceAccount:$saEmail" } else { "user:$ConsentUser" }

        Write-Step 'Organization custom IAM role'
        $permissions = Get-CustomRolePermissions -FeatureNames $Feature -SkipGcpWrite:$AggregationOnly
        $customRoleName = Set-OrganizationCustomRole -OrgId $OrganizationId -Permissions $permissions

        Write-Step 'Binding custom role at organization scope'
        Add-IamPolicyBinding -ResourceKind organizations -ResourceId $OrganizationId -Member $member -Role $customRoleName
        Write-Ok "$member <- $customRoleName"

        if (@($Feature) -contains 'NhiDiscovery') {
            Write-Step 'Binding NHI discovery built-in roles'
            foreach ($role in $script:NhiBuiltInRoles) {
                try {
                    $scope = Add-ConnectorIamBinding -OrgId $OrganizationId -ProjectId $ProjectId -Member $member -Role $role.Id
                    if ($scope -eq 'project') {
                        Write-Ok "$($role.Label) (project; not valid at organization)"
                    }
                    else {
                        Write-Ok $role.Label
                    }
                }
                catch {
                    Write-Warning "Could not bind $($role.Id) ($($role.Label)): $($_.Exception.Message)"
                }
            }
        }
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }

    $jsonPath = $null
    $pemPath = $null
    $pemText = $null
    if ($isServiceAccount -and $RotateKey) {
        Write-Step 'Creating service account key and RSA PEM'
        $jsonPath = Join-Path $OutputDirectory 'sailpoint-gws-key.json'
        $pemPath = Join-Path $OutputDirectory 'sailpoint-gws-rsa.pem'
        Invoke-GCloud -GcloudArgs @(
            'iam', 'service-accounts', 'keys', 'create', $jsonPath,
            "--iam-account=$saEmail",
            "--project=$ProjectId",
            '--quiet'
        ) | Out-Null
        Write-Ok "JSON key: $jsonPath"
        $keyMeta = ConvertTo-EncryptedRsaPem -JsonKeyPath $jsonPath -PemPath $pemPath -Passphrase $KeyPassword
        $keyClientId = Get-JsonProperty -InputObject $keyMeta -Name 'client_id'
        if ($keyClientId) { $delegationClientId = [string]$keyClientId }
        $pemText = [System.IO.File]::ReadAllText($pemPath).Trim()
        Write-Ok "RSA PEM: $pemPath"
    }

    if (-not $isServiceAccount -and -not $RefreshToken) {
        Write-Step 'Authorizing the OAuth client'
        $RefreshToken = Get-GoogleRefreshToken -OAuthClientId $ClientId -OAuthClientSecret $ClientSecret `
            -Redirect $RedirectUri -Scopes $scopes
        Write-Ok 'Refresh token issued'
    }

    $fields = [ordered]@{}
    if ($isServiceAccount) {
        $fields['Grant Type'] = 'Service Account'
        $fields['Service Account Email Address'] = $saEmail
        $fields['Email Address of User to Impersonate'] = $ImpersonateUser
        $fields['Scopes'] = $scopeCsv
        if ($pemText) {
            $fields['Private Key'] = $pemText
            $fields['Private Key Password'] = $KeyPassword
        }
    }
    else {
        $fields['Grant Type'] = 'Client Credentials'
        $fields['Client ID'] = $ClientId
        $fields['Client Secret'] = $ClientSecret
        $fields['Refresh Token'] = $RefreshToken
    }

    $settingsPath = Join-Path $OutputDirectory 'sailpoint-gws-connection-settings.txt'
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $copyFields = [ordered]@{}
    foreach ($name in $fields.Keys) { $copyFields[$name] = $fields[$name] }

    $delegationPending = $false
    $rolesPending = $false
    if ($isServiceAccount) {
        $delegation = [ordered]@{
            'Domain-wide delegation Client ID' = $delegationClientId
            'Domain-wide delegation OAuth Scopes' = $scopeCsv
        }
        $delegationPath = Join-Path $OutputDirectory 'sailpoint-gws-domain-wide-delegation.txt'
        Write-ConnectionSettings -Fields $delegation -Title 'Google Admin console - domain-wide delegation' -Path $delegationPath
        foreach ($name in $delegation.Keys) { $copyFields[$name] = $delegation[$name] }

        $runWalkthrough = -not $SkipDomainWideDelegationWalkthrough
        if (-not $PSBoundParameters.ContainsKey('SkipDomainWideDelegationWalkthrough') -and -not $NonInteractive) {
            $runWalkthrough = Read-YesNo -Prompt 'Open Admin console and copy Client ID then scopes for domain-wide delegation?' -Default $true
        }
        if ($NonInteractive -and -not $PSBoundParameters.ContainsKey('SkipDomainWideDelegationWalkthrough')) {
            $runWalkthrough = $false
        }
        while ($true) {
            try {
                if ($runWalkthrough) {
                    Invoke-DomainWideDelegationWalkthrough -ClientIdValue $delegationClientId -ScopesValue $scopeCsv
                }
                else {
                    $delegationPending = $true
                }
                break
            }
            catch {
                if (-not (Test-PromptBack $_)) { throw }
                $runWalkthrough = Read-YesNo -Prompt 'Open Admin console and copy Client ID then scopes for domain-wide delegation?' -Default $true
            }
        }

        $wantRoles = $AssignWorkspaceRoles
        $rolesSkipped = $false
        if (-not $PSBoundParameters.ContainsKey('AssignWorkspaceRoles') -and -not $NonInteractive) {
            $wantRoles = Read-YesNo -Prompt "Assign Workspace admin roles to $ImpersonateUser now?" -Default $true
        }
        if ($wantRoles) {
            $roleClientId = $ClientId
            $roleSecret = $ClientSecret
            $roleRedirect = if ($RedirectUri) { $RedirectUri } else { 'http://localhost:8088' }
            $rolesSkipped = $true
            $rolesManualHint = "Assign User Management Admin and Groups Admin to $ImpersonateUser at https://admin.google.com/ac/roles."

            while ($true) {
                if (-not $roleClientId -or -not $roleSecret) {
                    if ($NonInteractive) {
                        Write-Warning "Skipping Workspace role assignment: -AssignWorkspaceRoles needs -ClientId and -ClientSecret. $rolesManualHint"
                        break
                    }
                    $oauthClient = $null
                    try {
                        $oauthClient = Invoke-OAuthClientWalkthrough -Project $ProjectId -Redirect $roleRedirect `
                            -ClientName 'SailPoint ISC Workspace role assignment' `
                            -SignInAccount $ImpersonateUser `
                            -Reason 'The Admin SDK only accepts a Super Admin user token — gcloud credentials are rejected — so this sign-in needs an OAuth client in your project.'
                    }
                    catch {
                        if (-not (Test-PromptBack $_)) { throw }
                    }
                    if (-not $oauthClient) {
                        Write-Warning "Skipping Workspace role assignment. $rolesManualHint"
                        break
                    }
                    $roleClientId = $oauthClient.ClientId
                    $roleSecret = $oauthClient.ClientSecret
                }

                try {
                    $roleToken = Get-GoogleOAuthToken -OAuthClientId $roleClientId -OAuthClientSecret $roleSecret `
                        -Redirect $roleRedirect `
                        -Scopes @(
                            'https://www.googleapis.com/auth/admin.directory.rolemanagement'
                            'https://www.googleapis.com/auth/admin.directory.user.readonly'
                        ) `
                        -SignInHint 'Sign in as a Super Admin and accept Directory role-management access.'
                    $access = [string](Get-JsonProperty -InputObject $roleToken -Name 'access_token')
                    $wanted = [System.Collections.Generic.List[string]]::new()
                    $wanted.Add('User Management Admin')
                    $wanted.Add('Groups Admin')
                    if (@($Feature) -contains 'DomainManagement') {
                        $addSuper = $true
                        if (-not $NonInteractive) {
                            $addSuper = Read-YesNo -Prompt 'Also assign Super Admin (required for domain-as-account and Workspace role operations)?' -Default $true
                        }
                        if ($addSuper) { $wanted.Add('Super Admin') }
                    }
                    Add-WorkspaceAdminRoles -AccessToken $access -UserEmail $ImpersonateUser `
                        -WantedDescriptions $wanted.ToArray() `
                        -RoleNameByDescription @{
                            'User Management Admin' = '_USER_MANAGEMENT_ADMIN_ROLE'
                            'Groups Admin'          = '_GROUPS_ADMIN_ROLE'
                            'Super Admin'           = '_SEED_ADMIN_ROLE'
                        }
                    $rolesSkipped = $false
                    break
                }
                catch {
                    if (Test-PromptBack $_) {
                        Write-Warning "Skipping Workspace role assignment. $rolesManualHint"
                        break
                    }
                    $failure = [string]$_.Exception.Message
                    Write-Warning "Workspace role assignment failed: $failure"
                    if ($failure -match 'redirect_uri_mismatch') {
                        Write-Info "Add $roleRedirect under Authorized redirect URIs on that client, or re-run with -RedirectUri set to one that is registered."
                    }
                    # A blocked consent screen is the client's audience, not the client itself, so
                    # that retry keeps the same credentials and only revisits the Audience page.
                    $audienceBlocked = $failure -match 'access_denied|verification process|No redirect arrived'
                    if ($audienceBlocked) {
                        Write-Info "Google blocks accounts the app's audience does not cover. External apps in Testing only admit accounts listed under Test users; Internal apps admit the whole Workspace organization."
                    }
                    # Another OAuth client cannot fix an address that does not exist.
                    if ($NonInteractive -or $failure -match 'does not exist') {
                        Write-Warning $rolesManualHint
                        break
                    }

                    try {
                        if ($audienceBlocked) {
                            if (-not (Read-YesNo -Prompt 'Fix the audience and retry with the same OAuth client?' -Default $true)) {
                                Write-Warning $rolesManualHint
                                break
                            }
                            Invoke-OAuthAudienceWalkthrough -Project $ProjectId -SignInAccount $ImpersonateUser
                        }
                        else {
                            if (-not (Read-YesNo -Prompt 'Try again with a different OAuth client?' -Default $true)) {
                                Write-Warning $rolesManualHint
                                break
                            }
                            $roleClientId = $null
                            $roleSecret = $null
                        }
                    }
                    catch {
                        if (-not (Test-PromptBack $_)) { throw }
                        Write-Warning $rolesManualHint
                        break
                    }
                }
            }
        }
        else {
            $rolesSkipped = $true
        }
        $rolesPending = $rolesSkipped
    }

    $gcpConsoleUrl = "https://console.cloud.google.com/iam-admin/serviceaccounts?project=$ProjectId"
    $dwdUrl = 'https://admin.google.com/ac/owl/domainwidedelegation'
    $adminRolesUrl = 'https://admin.google.com/ac/roles'

    $situation = [System.Collections.Generic.List[string]]::new()
    $situation.Add('Google Workspace GCP setup is complete. Paste Connection Settings into ISC.')
    if ($isServiceAccount) {
        if (-not $pemText) {
            $situation.Add('Pending: no Private Key was issued this run. Re-run with -RotateKey or paste the PEM and password you stored earlier.')
        }
        else {
            $situation.Add('Paste the Private Key exactly as stored (including BEGIN/END lines). Store the password — Google cannot recover it.')
        }
        if ($delegationPending) {
            $situation.Add('Pending: a Super Admin must authorize domain-wide delegation in the Admin console (Client ID and OAuth scopes).')
        }
        if ($rolesPending) {
            $situation.Add("Pending: assign User Management Admin and Groups Admin to $ImpersonateUser in the Admin console.")
        }
        $situation.Add('Do not commit JSON keys or PEM files. Keep them in a vault.')
    }
    else {
        $situation.Add("The refresh token belongs to $ConsentUser. CIEM and NHI Discovery require the Service Account grant type.")
    }
    $situation.Add('In ISC: Connections > Sources > [your source] > Connection Settings.')

    $completionItems = [System.Collections.Generic.List[object]]::new()
    foreach ($name in $copyFields.Keys) {
        $completionItems.Add([PSCustomObject]@{
            Label = $name
            Value = [string]$copyFields[$name]
            Kind  = 'Copy'
            Mask  = (Test-ConnectionSettingIsSecret -Name $name)
        })
    }
    if ($isServiceAccount) {
        $completionItems.Add([PSCustomObject]@{ Label = 'Domain-wide delegation (Admin console)'; Value = $dwdUrl; Kind = 'Open'; Mask = $false })
        if ($rolesPending) {
            $completionItems.Add([PSCustomObject]@{ Label = 'Workspace admin roles (Admin console)'; Value = $adminRolesUrl; Kind = 'Open'; Mask = $false })
        }
    }
    $completionItems.Add([PSCustomObject]@{ Label = 'GCP service accounts'; Value = $gcpConsoleUrl; Kind = 'Open'; Mask = $false })

    Invoke-CompletionActionMenu -Title 'Next: complete ISC Connection Settings' `
        -Situation $situation.ToArray() `
        -Items $completionItems.ToArray()
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    if ($script:CreatedServiceAccount) {
        Write-Warning "Service account $script:CreatedServiceAccount was created before this failure. Re-run with the same project and service account ID to finish configuring it."
    }
    Write-Error $_
    exit 1
}
