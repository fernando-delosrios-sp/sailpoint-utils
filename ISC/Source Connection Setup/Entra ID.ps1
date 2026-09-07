#Requires -Version 5.1
<#
.SYNOPSIS
    Creates or updates the Microsoft Entra ID application used by the SailPoint Identity Security Cloud
    Microsoft Entra ID connector (SaaS "Microsoft Entra" and VA "Azure Active Directory").

.DESCRIPTION
    Registers an Entra ID application, assigns the Microsoft Graph application permissions documented by
    SailPoint, grants admin consent, assigns the directory roles the connector needs for Set Password and
    Delete User, and issues a client secret.

    All permissions from SailPoint's required-permissions table are granted by default. Optional feature
    packs (access packages, MFA management, CIEM, NHI discovery, Teams / SharePoint scanning, Copilot
    discovery, Defender hunting) are opt-in because they map to features that must be licensed or enabled.

    Existing applications with the same display name are updated in place rather than duplicated.

    Reference:
    https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/administrator_permission.html

.PARAMETER TenantId
    Entra ID tenant ID (GUID) or verified domain. Prompts when omitted.

.PARAMETER ApplicationName
    Display name of the app registration. Prompts when omitted.

.PARAMETER PermissionMode
    Granular  - the documented per-API required permission table (default, least privilege).
    Directory - the documented coarse alternative: Directory.Read.All + Directory.ReadWrite.All.

.PARAMETER Feature
    Optional documented feature packs to add. See the README for the permissions in each pack.

.PARAMETER DirectoryRole
    Directory role for the service principal. Default UserAdministrator, which SailPoint requires for
    Set Password and Delete User.

.PARAMETER SecretDisplayName
    Display name of the client secret. Default: ISC.

.PARAMETER SecretValidityMonths
    Client secret lifetime in months (1-24). Default: 24.

.PARAMETER RotateSecret
    When updating an existing application, create a new client secret.

.PARAMETER OutputDirectory
    Directory for the Connection Settings file. Default: ./sourceConfig/entra-id-isc

.PARAMETER NonInteractive
    Fail instead of prompting when required values are missing.

.EXAMPLE
    .\Entra ID.ps1

.EXAMPLE
    .\Entra ID.ps1 -ApplicationName 'SailPoint ISC Entra ID' -Feature AccessPackages,MfaManagement -NonInteractive

.NOTES
    Sign in as an account that can create applications, grant admin consent, and assign directory roles
    (Application Administrator + Privileged Role Administrator, or Global Administrator).
    The client secret is displayed once and cannot be retrieved afterwards.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [string]$ApplicationName,

    [Parameter()]
    [ValidateSet('Granular', 'Directory')]
    [string]$PermissionMode = 'Granular',

    [Parameter()]
    [ValidateSet('AccessPackages', 'MfaManagement', 'Ciem', 'NhiDiscovery', 'TeamsSecretScanning',
        'TeamsMessaging', 'SharePointScanning', 'CopilotDiscovery', 'DefenderHunting')]
    [string[]]$Feature,

    [Parameter()]
    [ValidateSet('None', 'UserAdministrator', 'PrivilegedAdmin', 'GlobalAdministrator')]
    [string]$DirectoryRole,

    [Parameter()]
    [string]$SecretDisplayName = 'ISC',

    [Parameter()]
    [ValidateRange(1, 24)]
    [int]$SecretValidityMonths = 24,

    [Parameter()]
    [switch]$RotateSecret,

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:CreatedAppId = $null

# API resources the connector can be granted permissions on.
$script:Resources = [ordered]@{
    # Microsoft Graph's well-known appId uses c000, not 0000, in the third group.
    Graph    = @{ AppId = '00000003-0000-0000-c000-000000000000'; Name = 'Microsoft Graph'; Required = $true }
    Defender = @{ AppId = 'fc780465-2017-40d4-a0c5-307022471b92'; Name = 'WindowsDefenderATP'; Required = $false }
}

# -----------------------------------------------------------------------------
# Permissions - SailPoint Microsoft Entra ID connector required-permissions table
# https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/administrator_permission.html
#
# User.Read and Directory.AccessAsUser.All appear in the table as delegated permissions for
# SAML bearer / auth-code / JWT grant types. This script configures client-credentials
# (client secret) auth, so they are intentionally not requested.
# -----------------------------------------------------------------------------

$script:CorePermissions = @(
    @{ Value = 'User.Invite.All';                   Purpose = 'Create / invite B2B user' }
    @{ Value = 'User.Read.All';                     Purpose = 'Account aggregation, delta, role and group membership' }
    @{ Value = 'User.ReadWrite.All';                Purpose = 'Create / update / enable / disable / delete user, licenses' }
    @{ Value = 'User.EnableDisableAccount.All';     Purpose = 'Delete user' }
    @{ Value = 'User-PasswordProfile.ReadWrite.All'; Purpose = 'Set password' }
    @{ Value = 'Organization.Read.All';             Purpose = 'Aggregate tenant license packs and plans' }
    @{ Value = 'Group.Read.All';                    Purpose = 'Group aggregation' }
    @{ Value = 'Group.ReadWrite.All';               Purpose = 'Create / update / delete group' }
    @{ Value = 'RoleManagement.Read.Directory';     Purpose = 'Directory role aggregation' }
    @{ Value = 'RoleManagement.ReadWrite.Directory'; Purpose = 'Add / remove directory roles' }
    @{ Value = 'Application.Read.All';              Purpose = 'Application role aggregation' }
    @{ Value = 'AppRoleAssignment.ReadWrite.All';   Purpose = 'Add / remove users from service principal' }
    @{ Value = 'DelegatedPermissionGrant.Read.All'; Purpose = 'Aggregate admin / user consented permissions' }
)

# Documented coarse alternative to the granular table.
$script:DirectoryPermissions = @(
    @{ Value = 'Directory.Read.All';      Purpose = 'Read directory data' }
    @{ Value = 'Directory.ReadWrite.All'; Purpose = 'Read and write directory data (excludes deleting users and groups)' }
)

$script:FeaturePacks = [ordered]@{
    AccessPackages = @{
        Label       = 'Access packages (entitlement management)'
        Permissions = @(
            @{ Value = 'EntitlementManagement.Read.All' }
            @{ Value = 'EntitlementManagement.ReadWrite.All' }
        )
    }
    MfaManagement = @{
        Label       = 'MFA / authentication method management'
        Permissions = @(
            @{ Value = 'UserAuthenticationMethod.Read.All' }
            @{ Value = 'UserAuthenticationMethod.ReadWrite.All' }
        )
    }
    Ciem = @{
        Label       = 'CIEM - PIM group eligibility'
        Permissions = @(
            @{ Value = 'PrivilegedAccess.Read.AzureADGroup' }
            @{ Value = 'PrivilegedAssignmentSchedule.Read.AzureADGroup' }
            @{ Value = 'PrivilegedEligibilitySchedule.Read.AzureADGroup' }
        )
    }
    NhiDiscovery = @{
        Label       = 'NHI discovery - Azure cloud and NHI analysis'
        Permissions = @(
            @{ Value = 'AuditLog.Read.All' }
            @{ Value = 'Device.Read.All' }
        )
    }
    TeamsSecretScanning = @{
        Label       = 'NHI discovery - Microsoft Teams secret scanning'
        Permissions = @(
            @{ Value = 'Channel.ReadBasic.All' }
            @{ Value = 'ChannelMember.Read.All' }
            @{ Value = 'ChannelMessage.Read.All' }
            @{ Value = 'ChannelSettings.Read.All' }
            @{ Value = 'Chat.Read.All' }
            @{ Value = 'TeamsActivity.Read.All' }
            @{ Value = 'TeamsAppInstallation.ReadForChat.All' }
            @{ Value = 'TeamsAppInstallation.ReadForTeam.All' }
            @{ Value = 'TeamsAppInstallation.ReadForUser.All' }
            @{ Value = 'TeamsTab.Read.All' }
            @{ Value = 'TeamSettings.Read.All' }
        )
    }
    TeamsMessaging = @{
        Label       = 'NHI discovery - Microsoft Teams risk notifications'
        Permissions = @(
            @{ Value = 'TeamsAppInstallation.ReadWriteForTeam.All' }
            @{ Value = 'TeamsAppInstallation.ReadWriteForUser.All' }
            @{ Value = 'TeamsAppInstallation.ReadWriteSelfForUser.All' }
        )
    }
    SharePointScanning = @{
        Label       = 'NHI discovery - SharePoint and OneDrive secret scanning'
        Permissions = @(
            @{ Value = 'Files.Read.All' }
            @{ Value = 'Sites.Read.All' }
        )
    }
    CopilotDiscovery = @{
        Label       = 'NHI discovery - Copilot and AI agent discovery'
        Permissions = @(
            @{ Value = 'AiEnterpriseInteraction.Read.All' }
            @{ Value = 'Reports.Read.All' }
            @{ Value = 'ExternalConnection.Read.All' }
            @{ Value = 'AppCatalog.Read.All' }
        )
    }
    DefenderHunting = @{
        Label       = 'NHI discovery - Microsoft Defender (WindowsDefenderATP API)'
        Permissions = @(
            # Advanced hunting is exposed as ThreatHunting.Read.All on Microsoft Graph; the legacy
            # WindowsDefenderATP resource names it AdvancedQuery.Read.All.
            @{ Value = 'Machine.Read.All';        Resource = 'Defender' }
            @{ Value = 'AdvancedQuery.Read.All';  Resource = 'Defender' }
            @{ Value = 'ThreatHunting.Read.All'; Resource = 'Graph' }
        )
    }
}

$script:DirectoryRoleMap = [ordered]@{
    None                = @()
    UserAdministrator   = @('User Administrator')
    PrivilegedAdmin     = @('User Administrator', 'Privileged Authentication Administrator')
    GlobalAdministrator = @('Global Administrator')
}

# -----------------------------------------------------------------------------
# Console helpers
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Microsoft Entra ID source connection setup' -ForegroundColor Cyan
    Write-Host '  Creates or updates the app registration used by the Entra ID connector.' -ForegroundColor DarkCyan
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

function Write-ConnectionSettings {
    param(
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Fields,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Path
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $Fields.Keys) {
        $lines.Add("### $name")
        $lines.Add([string]$Fields[$name])
        $lines.Add('')
    }
    Set-Content -LiteralPath $Path -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Ok "Saved $Title to $Path"
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

# Arrow-key menus need a host that reads single keys and a terminal that understands ANSI cursor
# movement. Returns $null when menus work, otherwise the reason they do not.
function Get-ConsoleMenuBlocker {
    if ($NonInteractive) { return 'non-interactive mode' }
    # The ISE draws its own command pane and implements neither key reading nor cursor movement.
    if ($Host.Name -eq 'Windows PowerShell ISE Host') { return 'the ISE cannot read single keystrokes' }

    # Only a real console host is checked through [Console]: editor hosts such as the VS Code /
    # Cursor PowerShell extension throw there yet still read keys through RawUI, so they are tried
    # optimistically and fall back if the first read fails.
    if ($Host.Name -eq 'ConsoleHost') {
        # KeyAvailable throws when stdin is not a console. Unlike a cursor-position request it asks
        # the terminal nothing and consumes no input, so it is safe to call before every menu.
        try { $null = [Console]::KeyAvailable }
        catch { return 'this console cannot read single keystrokes' }

        try { if ([Console]::IsOutputRedirected) { return 'console output is redirected' } } catch { }
    }

    # Only Windows consoles are ever without virtual terminal support; every terminal PowerShell
    # runs in on Unix renders these sequences regardless of what TERM advertises.
    $platform = if ($PSVersionTable.PSObject.Properties['Platform']) { $PSVersionTable.Platform } else { 'Win32NT' }
    if ($platform -ne 'Unix') {
        $vt = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
        if ($vt -and -not $vt.Value) { return 'this console does not support virtual terminal sequences' }
    }

    return $null
}

# RawUI.ReadKey is used rather than [Console]::ReadKey because the editor hosts implement it while
# [Console] throws; in a console host it is a thin wrapper over [Console]::ReadKey anyway.
# ConsoleKey values and Windows virtual key codes agree on the keys below.
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

# Editor hosts throw on [Console] size members but answer through RawUI, so both are tried.
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

# Returns the picked indices, an empty array when the user pressed Escape, or $null when the
# console is too small to host the menu and the caller should prompt for numbers instead.
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
    # A console that will not report its height still gets the menu; only a known-too-short one
    # falls back, because the block has to fit on screen for the in-place redraw to line up.
    if ($windowHeight -gt 0 -and $windowHeight -le $rows) {
        $script:MenuBlockerDetail = "the console is $windowHeight rows tall and this menu needs $($rows + 1)"
        return $null
    }

    # Every frame is redrawn in place by moving the cursor up over the block just written, so the
    # menu never needs to know its absolute row and survives the console scrolling underneath it.
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
            # Truncating keeps a long label from wrapping, which would desynchronize the cursor
            # from the row count the next frame moves up by.
            $text = $line[0]
            if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
            Write-Host ($text + $script:AnsiEraseLine) -ForegroundColor $line[1]
        }
    }

    try {
        try { [Console]::CursorVisible = $false } catch { }

        while ($true) {
            # Dot-sourced so the frame counter it flips stays visible to the next iteration.
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

# -----------------------------------------------------------------------------
# Modules and Graph connection
# -----------------------------------------------------------------------------

function Initialize-GraphModules {
    $required = @(
        'Microsoft.Graph.Authentication'
        'Microsoft.Graph.Applications'
        'Microsoft.Graph.Identity.DirectoryManagement'
    )

    $missing = @($required | Where-Object { -not (Get-Module -ListAvailable -Name $_) })
    if ($missing.Count -gt 0) {
        Write-Step 'Microsoft Graph PowerShell modules are required'
        foreach ($name in $missing) { Write-Info $name }
        if (-not (Read-YesNo -Prompt 'Install the missing modules for the current user?' -Default $true)) {
            throw "Install the modules manually: Install-Module $($missing -join ', ') -Scope CurrentUser"
        }
        foreach ($name in $missing) {
            Write-Info "Installing $name ..."
            Install-Module -Name $name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
    }

    foreach ($name in $required) {
        Import-Module $name -ErrorAction Stop
    }
}

function Connect-EntraGraph {
    param([string]$RequestedTenantId)

    $scopes = @(
        'Application.ReadWrite.All'
        'AppRoleAssignment.ReadWrite.All'
        'Directory.Read.All'
        'RoleManagement.ReadWrite.Directory'
    )

    $context = Get-MgContext -ErrorAction SilentlyContinue
    $needsConnect = $true
    if ($context) {
        $missingScopes = @($scopes | Where-Object { $context.Scopes -notcontains $_ })
        $tenantMismatch = $RequestedTenantId -and $context.TenantId -and
            ($RequestedTenantId -ne $context.TenantId) -and ($context.Account -notlike "*$RequestedTenantId")
        if ($missingScopes.Count -eq 0 -and -not $tenantMismatch) {
            $needsConnect = -not (Read-YesNo -Prompt "Already connected as $($context.Account). Reuse this session?" -Default $true)
        }
    }

    if ($needsConnect) {
        Write-Step 'Sign in to Microsoft Graph'
        $connectParams = @{ Scopes = $scopes }
        if ($RequestedTenantId) { $connectParams.TenantId = $RequestedTenantId }
        try {
            Connect-MgGraph @connectParams -NoWelcome -ErrorAction Stop
        }
        catch [System.Management.Automation.ParameterBindingException] {
            Connect-MgGraph @connectParams -ErrorAction Stop
        }
        $context = Get-MgContext
    }

    if (-not $context) { throw 'Microsoft Graph authentication failed.' }

    $orgName = $null
    $domainName = $null
    try {
        $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
        if ($org) {
            $orgName = $org.DisplayName
            $domains = @($org.VerifiedDomains)
            $initial = $domains | Where-Object { $_.IsInitial } | Select-Object -First 1
            $default = $domains | Where-Object { $_.IsDefault } | Select-Object -First 1
            if ($initial) { $domainName = $initial.Name }
            elseif ($default) { $domainName = $default.Name }
            elseif ($domains.Count -gt 0) { $domainName = $domains[0].Name }
        }
    }
    catch {
        Write-Warning "Could not read organization details: $($_.Exception.Message)"
    }

    $tenantLabel = if ($orgName) { "$orgName ($($context.TenantId))" } else { $context.TenantId }
    Write-Ok "Connected as $($context.Account)"
    Write-Ok "Tenant: $tenantLabel"

    return [PSCustomObject]@{
        TenantId   = $context.TenantId
        Account    = $context.Account
        OrgName    = $orgName
        DomainName = $domainName
    }
}

# -----------------------------------------------------------------------------
# Permission resolution
# -----------------------------------------------------------------------------

function Get-SelectedPermissions {
    param(
        [string]$Mode,
        [string[]]$FeatureNames
    )

    $selected = [System.Collections.Generic.List[object]]::new()
    $base = if ($Mode -eq 'Directory') { $script:DirectoryPermissions } else { $script:CorePermissions }
    foreach ($permission in $base) {
        $selected.Add([PSCustomObject]@{
            Resource = 'Graph'
            Value    = $permission.Value
            Pack     = 'Core'
        })
    }

    foreach ($name in @($FeatureNames)) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        foreach ($permission in $script:FeaturePacks[$name].Permissions) {
            $resource = if ($permission.ContainsKey('Resource')) { $permission.Resource } else { 'Graph' }
            $selected.Add([PSCustomObject]@{
                Resource = $resource
                Value    = $permission.Value
                Pack     = $name
            })
        }
    }

    return @($selected | Sort-Object Resource, Value -Unique)
}

# Why each lookup failed, so a failure to find a service principal can explain itself.
$script:ServicePrincipalLookupErrors = [System.Collections.Generic.List[string]]::new()

function Get-ServicePrincipalByAppId {
    param([Parameter(Mandatory)][string]$AppId)

    # The alternate-key REST call is tried first because Get-MgServicePrincipal -Filter returns an
    # empty result on some SDK versions even when the service principal exists.
    try {
        $sp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals(appId='$AppId')" -OutputType PSObject -ErrorAction Stop
        if ($sp) { return $sp }
        $script:ServicePrincipalLookupErrors.Add("servicePrincipals(appId='$AppId') returned nothing")
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("servicePrincipals(appId='$AppId'): $($_.Exception.Message)")
    }

    try {
        $sp = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop | Select-Object -First 1
        if ($sp) { return $sp }
        $script:ServicePrincipalLookupErrors.Add("Get-MgServicePrincipal -Filter returned nothing")
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("Get-MgServicePrincipal -Filter: $($_.Exception.Message)")
    }

    return $null
}

function Get-ApiServicePrincipal {
    param(
        [Parameter(Mandatory)][string]$AppId,
        [Parameter(Mandatory)][string]$Name
    )

    $script:ServicePrincipalLookupErrors.Clear()

    # Retried because throttling and transient 5xx responses are the usual reason a service
    # principal that certainly exists comes back empty.
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $sp = Get-ServicePrincipalByAppId -AppId $AppId
        if ($sp) { return $sp }
        if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
    }

    # Last resort for tenants where filtering on appId is unreliable. Only identifiers are listed:
    # selecting appRoles across every service principal is the query most likely to time out, so
    # the roles are fetched afterwards from the one match.
    Write-Info "Searching the tenant service principal list for $Name ..."
    try {
        $match = Get-MgServicePrincipal -All -Property 'id,appId,displayName' -ErrorAction Stop |
            Where-Object { $_.AppId -eq $AppId } | Select-Object -First 1
        if ($match) { return Get-MgServicePrincipal -ServicePrincipalId $match.Id -ErrorAction Stop }
        $script:ServicePrincipalLookupErrors.Add('the tenant service principal list contains no such appId')
    }
    catch {
        $script:ServicePrincipalLookupErrors.Add("service principal enumeration: $($_.Exception.Message)")
    }

    return $null
}

function Resolve-AppRoles {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)][string[]]$PermissionValues,
        [Parameter(Mandatory)][string]$ResourceName
    )

    # REST responses expose 'appRoles', SDK objects expose 'AppRoles'; member lookup is case-insensitive.
    $appRolesProperty = $ServicePrincipal.PSObject.Properties['AppRoles']
    $appRoles = @()
    if ($appRolesProperty) { $appRoles = @($appRolesProperty.Value) }
    if ($appRoles.Count -eq 0) {
        throw "$ResourceName exposes no application roles. The signed-in account may lack Directory.Read.All."
    }

    $resolved = [System.Collections.Generic.List[object]]::new()
    foreach ($value in $PermissionValues) {
        $role = $appRoles |
            Where-Object { $_.Value -eq $value -and $_.AllowedMemberTypes -contains 'Application' } |
            Select-Object -First 1
        if (-not $role) {
            Write-Warning "$ResourceName does not expose '$value' as an application permission in this tenant. Skipping."
            continue
        }
        $resolved.Add([PSCustomObject]@{ Id = $role.Id; Value = $value })
    }
    return @($resolved)
}

# -----------------------------------------------------------------------------
# Application operations
# -----------------------------------------------------------------------------

function Find-EntraApplicationByName {
    param([Parameter(Mandatory)][string]$DisplayName)

    $escaped = $DisplayName.Replace("'", "''")
    return @(Get-MgApplication -Filter "displayName eq '$escaped'" -All -ErrorAction Stop)
}

function New-EntraConnectorApplication {
    param(
        [Parameter(Mandatory)][string]$DisplayName
    )

    $body = @{
        DisplayName    = $DisplayName
        SignInAudience = 'AzureADMyOrg'
        Description    = 'SailPoint Identity Security Cloud - Microsoft Entra ID connector'
    }

    $app = New-MgApplication -BodyParameter $body -ErrorAction Stop
    $script:CreatedAppId = $app.AppId

    # The new application can take a few seconds to replicate before a service principal can reference it.
    $sp = $null
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            $sp = New-MgServicePrincipal -AppId $app.AppId -ErrorAction Stop
            break
        }
        catch {
            if ($attempt -eq 4) { throw }
            Start-Sleep -Seconds (2 * $attempt)
        }
    }

    return [PSCustomObject]@{ Application = $app; ServicePrincipal = $sp }
}

function Get-EntraConnectorApplication {
    param([Parameter(Mandatory)][string]$ApplicationObjectId)

    $app = Get-MgApplication -ApplicationId $ApplicationObjectId -ErrorAction Stop
    $sp = Get-ServicePrincipalByAppId -AppId $app.AppId
    if (-not $sp) {
        Write-Warning 'The application has no service principal. Creating one.'
        $sp = New-MgServicePrincipal -AppId $app.AppId -ErrorAction Stop
    }
    return [PSCustomObject]@{ Application = $app; ServicePrincipal = $sp }
}

function Set-RequiredResourceAccess {
    param(
        [Parameter(Mandatory)]$Application,
        [Parameter(Mandatory)][hashtable]$RolesByResource
    )

    $managedAppIds = @(
        foreach ($key in $RolesByResource.Keys) { $script:Resources[$key].AppId }
    )

    $required = [System.Collections.Generic.List[object]]::new()

    # Preserve entries for resources this script does not manage.
    foreach ($entry in @($Application.RequiredResourceAccess)) {
        if ($managedAppIds -contains $entry.ResourceAppId) { continue }
        $required.Add(@{
            ResourceAppId  = $entry.ResourceAppId
            ResourceAccess = @(foreach ($ra in $entry.ResourceAccess) { @{ Id = $ra.Id; Type = $ra.Type } })
        })
    }

    foreach ($key in $RolesByResource.Keys) {
        $roles = $RolesByResource[$key]
        if (-not $roles -or $roles.Count -eq 0) { continue }
        $required.Add(@{
            ResourceAppId  = $script:Resources[$key].AppId
            ResourceAccess = @(foreach ($role in $roles) { @{ Id = $role.Id; Type = 'Role' } })
        })
    }

    Update-MgApplication -ApplicationId $Application.Id -RequiredResourceAccess $required.ToArray() -ErrorAction Stop
}

function Grant-AppRoleConsent {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [Parameter(Mandatory)]$ResourceServicePrincipal,
        [Parameter(Mandatory)]$AppRoles
    )

    $existing = @()
    try {
        $existing = @(Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -All -ErrorAction Stop)
    }
    catch {
        Write-Warning "Could not list existing app role assignments: $($_.Exception.Message)"
    }

    $granted = 0
    $skipped = 0
    $failed = [System.Collections.Generic.List[string]]::new()

    foreach ($role in $AppRoles) {
        $already = $existing | Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $ResourceServicePrincipal.Id }
        if ($already) {
            $skipped++
            continue
        }

        $body = @{
            PrincipalId = $ServicePrincipal.Id
            ResourceId  = $ResourceServicePrincipal.Id
            AppRoleId   = $role.Id
        }

        # A newly created service principal can take a few seconds to replicate.
        $attempt = 0
        while ($true) {
            $attempt++
            try {
                New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -BodyParameter $body -ErrorAction Stop | Out-Null
                Write-Ok "Consent granted: $($role.Value)"
                $granted++
                break
            }
            catch {
                if ($_.Exception.Message -match 'already exists|Permission being assigned already exists') {
                    $skipped++
                    break
                }
                if ($attempt -lt 3) {
                    Start-Sleep -Seconds (2 * $attempt)
                    continue
                }
                Write-Warning "Failed to grant $($role.Value): $($_.Exception.Message)"
                $failed.Add($role.Value)
                break
            }
        }
        Start-Sleep -Milliseconds 300
    }

    if ($skipped -gt 0) { Write-Info "$skipped permission(s) already consented" }
    return [PSCustomObject]@{ Granted = $granted; Skipped = $skipped; Failed = @($failed) }
}

function Add-EntraDirectoryRoles {
    param(
        [Parameter(Mandatory)]$ServicePrincipal,
        [string[]]$RoleDisplayNames
    )

    $assigned = [System.Collections.Generic.List[string]]::new()
    foreach ($displayName in @($RoleDisplayNames)) {
        $escaped = $displayName.Replace("'", "''")
        $role = Get-MgDirectoryRole -Filter "displayName eq '$escaped'" -ErrorAction SilentlyContinue | Select-Object -First 1

        if (-not $role) {
            $template = Get-MgDirectoryRoleTemplate -All -ErrorAction Stop |
                Where-Object { $_.DisplayName -eq $displayName } | Select-Object -First 1
            if (-not $template) {
                Write-Warning "Directory role template not found: $displayName"
                continue
            }
            $role = New-MgDirectoryRole -RoleTemplateId $template.Id -ErrorAction Stop
            Write-Info "Activated directory role: $displayName"
        }

        $isMember = $false
        try {
            $members = @(Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All -ErrorAction Stop)
            $isMember = [bool]($members | Where-Object { $_.Id -eq $ServicePrincipal.Id })
        }
        catch {
            Write-Verbose "Could not enumerate members of $displayName : $($_.Exception.Message)"
        }

        if ($isMember) {
            Write-Info "Already a member of $displayName"
            $assigned.Add($displayName)
            continue
        }

        try {
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter @{
                '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($ServicePrincipal.Id)"
            } -ErrorAction Stop
            Write-Ok "Assigned directory role: $displayName"
            $assigned.Add($displayName)
        }
        catch {
            Write-Warning "Failed to assign $displayName : $($_.Exception.Message)"
        }
    }
    return @($assigned)
}

function New-EntraClientSecret {
    param(
        [Parameter(Mandatory)]$Application,
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][int]$ValidityMonths
    )

    $result = Add-MgApplicationPassword -ApplicationId $Application.Id -PasswordCredential @{
        DisplayName = $DisplayName
        EndDateTime = (Get-Date).ToUniversalTime().AddMonths($ValidityMonths)
    } -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($result.SecretText)) {
        throw 'The client secret was created but its value was not returned. Create one in the Entra portal instead.'
    }
    return $result
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

try {
    Write-Banner
    Initialize-GraphModules

    $session = $null
    $connectRequest = $null
    $targetAppObjectId = $null
    $createSecret = $true

    # Whether each value still has to be asked for is decided once, from what the caller passed.
    # Testing the variables instead would stop a step from asking again when Esc returns to it.
    $askTenantId = -not $TenantId -and -not $NonInteractive
    $askApplicationName = -not $ApplicationName
    $askFeature = -not $PSBoundParameters.ContainsKey('Feature')
    $askDirectoryRole = -not $DirectoryRole

    $wizardComplete = $false
    while (-not $wizardComplete) {
        Start-WizardPass
        try {
            if (Enter-WizardPrompt) {
                if ($askTenantId) {
                    $TenantId = Read-InputString -Prompt 'Entra ID tenant ID or domain (blank = home tenant from sign-in)' -Default $TenantId
                }
                Complete-WizardPrompt
            }

            if (-not $session -or $TenantId -ne $connectRequest) {
                $session = Connect-EntraGraph -RequestedTenantId $TenantId
                $connectRequest = $TenantId
                $TenantId = $session.TenantId
            }

            if (Enter-WizardPrompt) {
                if ($askApplicationName) {
                    $ApplicationName = Read-InputString -Prompt 'Application display name' -Default $(if ($ApplicationName) { $ApplicationName } else { 'SailPoint ISC Entra ID' }) -Required
                }
                Complete-WizardPrompt
            }

            # @() is required on every call site below: PowerShell unrolls an array returned from a
            # function, so a zero-result lookup arrives as $null and $null.Count throws under StrictMode.
            $existingApps = @(Find-EntraApplicationByName -DisplayName $ApplicationName)

            if (Enter-WizardPrompt) {
                $targetAppObjectId = $null
                if ($existingApps.Count -eq 1) {
                    Write-Step "An application named '$ApplicationName' already exists"
                    Write-Info "Client ID: $($existingApps[0].AppId)"
                    if (Read-YesNo -Prompt 'Update it instead of creating a new one?' -Default $true) {
                        $targetAppObjectId = $existingApps[0].Id
                    }
                    else {
                        $ApplicationName = Read-InputString -Prompt 'New application display name' -Required
                    }
                }
                elseif ($existingApps.Count -gt 1) {
                    Write-Step "Multiple applications are named '$ApplicationName'"
                    $options = @('CreateNew') + @($existingApps.Id)
                    $labels = @('Create a new application with a different name') +
                        @($existingApps | ForEach-Object { "Update $($_.DisplayName)  ($($_.AppId))" })
                    $picked = Read-Choice -Prompt 'Choose an application:' -Options $options -Labels $labels -Default $existingApps[0].Id
                    if ($picked -eq 'CreateNew') {
                        $ApplicationName = Read-InputString -Prompt 'New application display name' -Required
                    }
                    else {
                        $targetAppObjectId = $picked
                    }
                }
                Complete-WizardPrompt
            }

            $isUpdate = [bool]$targetAppObjectId

            if (Enter-WizardPrompt) {
                if ($askFeature) {
                    $packNames = @($script:FeaturePacks.Keys)
                    $packLabels = @($packNames | ForEach-Object { $script:FeaturePacks[$_].Label })
                    Write-Step 'Permissions'
                    Write-Info "All $($script:CorePermissions.Count) required permissions from SailPoint's permission table are always granted."
                    $Feature = @(Read-MultiChoice -Prompt 'Optional feature permissions to add:' -Options $packNames -Labels $packLabels)
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($askDirectoryRole) {
                    $DirectoryRole = Read-Choice -Prompt 'Directory role for the service principal:' -Options @(
                        'UserAdministrator', 'PrivilegedAdmin', 'None', 'GlobalAdministrator'
                    ) -Labels @(
                        'User Administrator - required by SailPoint for Set Password and Delete User'
                        'User Administrator + Privileged Authentication Administrator - also manage users holding admin roles'
                        'None - Graph application permissions only (Set Password and Delete User will fail)'
                        'Global Administrator - excessive; only if your organization mandates it'
                    ) -Default $(if ($DirectoryRole) { $DirectoryRole } else { 'UserAdministrator' })
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if ($DirectoryRole -eq 'GlobalAdministrator') {
                    Write-Warning 'Global Administrator on a connector service principal is high risk. SailPoint only requires User Administrator (plus Privileged Authentication Administrator for admin users).'
                    if (-not (Read-YesNo -Prompt 'Continue with Global Administrator?' -Default $false)) {
                        $DirectoryRole = 'PrivilegedAdmin'
                        Write-Ok 'Using User Administrator + Privileged Authentication Administrator instead.'
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                $createSecret = $true
                if ($isUpdate) {
                    $createSecret = [bool]$RotateSecret
                    if (-not $NonInteractive -and -not $RotateSecret) {
                        $createSecret = Read-YesNo -Prompt 'Create a new client secret?' -Default $false
                    }
                }
                Complete-WizardPrompt
            }

            if (Enter-WizardPrompt) {
                if (-not $OutputDirectory) {
                    $OutputDirectory = Join-Path (Get-Location) (Join-Path 'sourceConfig' 'entra-id-isc')
                }
                $OutputDirectory = Read-InputString -Prompt 'Output directory for connection settings' -Default $OutputDirectory -Required
                Complete-WizardPrompt
            }

            $permissions = @(Get-SelectedPermissions -Mode $PermissionMode -FeatureNames $Feature)
            $roleNames = @($script:DirectoryRoleMap[$DirectoryRole])

            $planAction = if ($isUpdate) { 'Update existing application' } else { 'Create application' }
            $planFeatures = if ($Feature) { $Feature -join ', ' } else { 'none' }
            $planRoles = if ($roleNames.Count -gt 0) { $roleNames -join ', ' } else { 'none' }
            $planSecret = if ($createSecret) { "$SecretDisplayName, $SecretValidityMonths months" } else { 'unchanged' }

            Write-Step 'Plan'
            Write-Host "   Action         : $planAction"
            Write-Host "   Application    : $ApplicationName"
            Write-Host "   Tenant         : $TenantId"
            Write-Host "   Permission set : $PermissionMode ($($permissions.Count) permissions)"
            Write-Host "   Feature packs  : $planFeatures"
            Write-Host "   Directory role : $planRoles"
            Write-Host "   Client secret  : $planSecret"
            Write-Host ''
            foreach ($group in ($permissions | Group-Object Resource)) {
                Write-Info "$($script:Resources[$group.Name].Name): $(($group.Group.Value | Sort-Object) -join ', ')"
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

    $action = if ($isUpdate) { "Update application '$ApplicationName'" } else { "Create application '$ApplicationName'" }
    if (-not $PSCmdlet.ShouldProcess($ApplicationName, $action)) { return }

    Write-Step 'Resolving API permissions'
    $rolesByResource = @{}
    $resourceServicePrincipals = @{}
    foreach ($group in ($permissions | Group-Object Resource)) {
        $resourceKey = $group.Name
        $resource = $script:Resources[$resourceKey]
        $resourceSp = Get-ApiServicePrincipal -AppId $resource.AppId -Name $resource.Name

        if (-not $resourceSp) {
            foreach ($failure in $script:ServicePrincipalLookupErrors) { Write-Warning $failure }
            $message = "The $($resource.Name) service principal (appId $($resource.AppId)) was not found in tenant $TenantId."
            if ($resource.Required) {
                throw "$message Confirm you are signed in to the correct tenant and that the signed-in account has Directory.Read.All."
            }
            Write-Warning "$message Skipping its permissions."
            continue
        }

        $roles = @(Resolve-AppRoles -ServicePrincipal $resourceSp -PermissionValues @($group.Group.Value) -ResourceName $resource.Name)
        if ($roles.Count -eq 0) {
            if ($resource.Required) { throw "No $($resource.Name) application permissions could be resolved." }
            continue
        }
        $rolesByResource[$resourceKey] = $roles
        $resourceServicePrincipals[$resourceKey] = $resourceSp
        Write-Ok "$($resource.Name): $($roles.Count) application permission(s) resolved"
    }

    Write-Step $(if ($isUpdate) { 'Updating application' } else { 'Creating application' })
    if ($isUpdate) {
        $pair = Get-EntraConnectorApplication -ApplicationObjectId $targetAppObjectId
        Write-Ok "Using application $($pair.Application.AppId)"
    }
    else {
        $pair = New-EntraConnectorApplication -DisplayName $ApplicationName
        Write-Ok "Created application $($pair.Application.AppId)"
        Write-Ok "Created service principal $($pair.ServicePrincipal.Id)"
    }

    Write-Step 'Updating requested API permissions'
    Set-RequiredResourceAccess -Application $pair.Application -RolesByResource $rolesByResource
    Write-Ok 'Application manifest updated'

    Write-Step 'Granting admin consent'
    $consentFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($resourceKey in $rolesByResource.Keys) {
        $result = Grant-AppRoleConsent -ServicePrincipal $pair.ServicePrincipal `
            -ResourceServicePrincipal $resourceServicePrincipals[$resourceKey] `
            -AppRoles $rolesByResource[$resourceKey]
        foreach ($failure in $result.Failed) { $consentFailures.Add($failure) }
    }
    if ($consentFailures.Count -gt 0) {
        Write-Warning "Grant admin consent manually in the Entra portal for: $($consentFailures -join ', ')"
    }

    $assignedRoles = @()
    if ($roleNames.Count -gt 0) {
        Write-Step 'Assigning directory roles'
        $assignedRoles = @(Add-EntraDirectoryRoles -ServicePrincipal $pair.ServicePrincipal -RoleDisplayNames $roleNames)
    }

    $secretValue = $null
    $secretExpires = $null
    if ($createSecret) {
        Write-Step 'Creating client secret'
        $secret = New-EntraClientSecret -Application $pair.Application -DisplayName $SecretDisplayName -ValidityMonths $SecretValidityMonths
        $secretValue = $secret.SecretText
        $secretExpires = $secret.EndDateTime
        Write-Ok "Secret '$SecretDisplayName' created, expires $secretExpires"
    }

    $portalUrl = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($pair.Application.AppId)"
    $permissionsUrl = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$($pair.Application.AppId)"

    $domainName = if ($session.DomainName) { $session.DomainName } else { $TenantId }

    $situation = [System.Collections.Generic.List[string]]::new()
    $situation.Add('Entra ID application setup is complete. Paste the Connection Settings values into ISC.')
    if ($consentFailures.Count -gt 0) {
        $situation.Add("Pending: grant admin consent in the Entra portal for: $($consentFailures -join ', ').")
    }
    if ($roleNames.Count -gt 0) {
        $missingRoles = @($roleNames | Where-Object { $assignedRoles -notcontains $_ })
        if ($missingRoles.Count -gt 0) {
            $situation.Add("Pending: assign directory role(s) to the service principal: $($missingRoles -join ', ').")
        }
    }
    if ($secretValue) {
        $situation.Add('Store the client secret now — Microsoft will not display it again.')
    }
    elseif (-not $createSecret) {
        $situation.Add('No new client secret was created. Re-run with -RotateSecret if ISC needs a new secret.')
    }
    $situation.Add('For read-only Azure cloud object access, also assign the built-in Reader role at the tenant root management group.')
    $situation.Add('VA-based Azure Active Directory sources must have useMSGraphAPI set to true.')

    $fields = [ordered]@{
        'Grant Type' = 'Client Credentials'
        'Client ID' = [string]$pair.Application.AppId
        'Domain Name' = $domainName
    }
    if ($secretValue) {
        $fields['Client Secret'] = $secretValue
    }
    $settingsPath = Join-Path $OutputDirectory 'sailpoint-entra-connection-settings.txt'
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $completionItems = @(
        [PSCustomObject]@{ Label = 'Grant Type'; Value = 'Client Credentials'; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Client ID'; Value = [string]$pair.Application.AppId; Kind = 'Copy'; Mask = $false }
        [PSCustomObject]@{ Label = 'Domain Name'; Value = $domainName; Kind = 'Copy'; Mask = $false }
    )
    if ($secretValue) {
        $completionItems += [PSCustomObject]@{ Label = 'Client Secret'; Value = $secretValue; Kind = 'Copy'; Mask = $true }
    }
    $completionItems += @(
        [PSCustomObject]@{ Label = 'Entra app overview'; Value = $portalUrl; Kind = 'Open'; Mask = $false }
    )
    if ($consentFailures.Count -gt 0) {
        $completionItems += [PSCustomObject]@{ Label = 'API permissions (grant consent)'; Value = $permissionsUrl; Kind = 'Open'; Mask = $false }
    }

    Invoke-CompletionActionMenu -Title 'Next: complete ISC Connection Settings' `
        -Situation $situation.ToArray() `
        -Items $completionItems
}
catch {
    if (Test-CancelledNavigation $_) {
        Write-Host ''
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    if ($script:CreatedAppId) {
        Write-Warning "Application $script:CreatedAppId was created before this failure. Re-run the script with the same display name to finish configuring it."
    }
    Write-Error $_
    exit 1
}
