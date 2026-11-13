#Requires -Version 7
Set-StrictMode -Version Latest

# Load core modules
$script:ModuleRoot = $PSScriptRoot
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Project.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $script:ModuleRoot 'modules/ISC.OperatorToolchain.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Catalog.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.CatalogMenu.psm1') -Force -Global -WarningAction SilentlyContinue

function Convert-RemainingArgumentsToHashtable {
    param(
        $Arguments
    )

    $result = [ordered]@{}
    if ($null -eq $Arguments) { return $result }

    $argList = @($Arguments)
    $i = 0
    while ($i -lt $argList.Count) {
        $item = $argList[$i]
        if ($null -eq $item) {
            $i++
            continue
        }

        if ($item -is [string] -and $item -match '^--?([a-zA-Z_][a-zA-Z0-9_]*)(?:[:=](.*))?$') {
            $paramName = $Matches[1]
            $inlineValue = $Matches[2]

            if ($null -ne $inlineValue) {
                if ($inlineValue -in @('$true', 'true', '$True', 'True')) {
                    $result[$paramName] = $true
                }
                elseif ($inlineValue -in @('$false', 'false', '$False', 'False')) {
                    $result[$paramName] = $false
                }
                elseif ($inlineValue -match '^-?\d+$') {
                    $result[$paramName] = [int]$inlineValue
                }
                else {
                    $result[$paramName] = $inlineValue
                }
                $i++
            }
            else {
                if (($i + 1) -lt $argList.Count) {
                    $nextItem = $argList[$i + 1]
                    if ($nextItem -is [string] -and $nextItem -match '^--?[a-zA-Z_][a-zA-Z0-9_]*') {
                        $result[$paramName] = $true
                        $i++
                    }
                    else {
                        if ($nextItem -is [string] -and ($nextItem -in @('$true', 'true', '$True', 'True'))) {
                            $result[$paramName] = $true
                        }
                        elseif ($nextItem -is [string] -and ($nextItem -in @('$false', 'false', '$False', 'False'))) {
                            $result[$paramName] = $false
                        }
                        else {
                            $result[$paramName] = $nextItem
                        }
                        $i += 2
                    }
                }
                else {
                    $result[$paramName] = $true
                    $i++
                }
            }
        }
        else {
            $i++
        }
    }

    return $result
}

function Invoke-SailPointConnectSessionReentry {
    [CmdletBinding()]
    param(
        [hashtable]$ConnectParams
    )

    if (-not $ConnectParams) { $ConnectParams = @{} }
    $cmd = @(Get-Command -Name 'Invoke-SailPointConnect' -Module 'SailPoint.Connect' -ErrorAction Stop)
    if ($cmd.Count -eq 0) {
        throw 'SailPoint.Connect is not loaded after update.'
    }
    return & $cmd[0] @ConnectParams
}

<#
.SYNOPSIS
    Unified entry point for SailPoint Connect.

.DESCRIPTION
    Runs progressive-disclosure setup for SailPoint Identity Security Cloud (ISC) connectors,
    Entro cloud onboarding, Microsoft 365 access profiles, and IQService host management.

    When called with no parameters in an interactive session, displays a guided platform picker.
    When called with -Platform and -Wizard, launches the guided setup wizard for that platform.
    Artifacts, configuration records, and execution logs are stored under ~/.sailpoint-connect/.

.PARAMETER Platform
    Target platform or component to configure:
    - AWS: Amazon Web Services SaaS connector, CIEM, or Entro
    - Azure: Microsoft Entra ID connector or Entro
    - GoogleCloud (or GCP): Google Workspace SaaS connector, GCP CIEM, or Entro
    - Databricks: Databricks account & metastore connector
    - EntroOutpost: Entro Outpost on-premise container runtime (Docker Compose or Kubernetes Helm)
    - OnPremActiveDirectory: Entro on-prem Active Directory service account and LDAPS CA
    - RemoteFileSystem: Entro SMB, SFTP, or WinRM file scanning
    - IQService: IQService host management and Active Directory LDAPS
    - M365AccessProfiles: Requestable access profiles from Entra service plans

.PARAMETER Wizard
    Launches the guided step-by-step interactive questionnaire for the chosen platform.

.PARAMETER Project
    Workspace project name. Artifacts and logs will be written under
    ~/.sailpoint-connect/<Project>/<Platform>/<Integration>/.
    If omitted in an interactive session, prompts for a project or creates a new one.

.PARAMETER Action
    What to do. Only Run changes the tenant, and the wizard asks you to confirm first.
    - BuildRequirements: Writes a checklist. Nothing is created.
    - Check: Reads an identity that already exists and reports gaps. Nothing is created.
    - BuildScript: Writes a script to review and run later. Nothing is created until that script is run.
    - Run: Creates or updates the identity after you confirm.

.PARAMETER OutputDirectory
    Overrides the default output directory for generated artifacts while keeping logs in ~/.sailpoint-connect/.

.PARAMETER NonInteractive
    Runs in non-interactive / headless mode for CI/CD or automation. Fails if required parameters are missing.

.EXAMPLE
    Invoke-SailPointConnect
    Opens the interactive platform picker to select AWS, Azure, Google Cloud, Databricks, IQService, or M365.

.EXAMPLE
    Invoke-SailPointConnect -Platform AWS -Wizard
    Starts the interactive guided questionnaire for AWS SaaS connector and/or Entro.

.EXAMPLE
    Invoke-SailPointConnect -Platform Azure -Wizard -Project "acme-tenant"
    Starts the Azure wizard and stores all runbooks, scripts, and logs under workspace project "acme-tenant".

.EXAMPLE
    Invoke-SailPointConnect -Platform GoogleCloud -Action BuildRequirements -Project "demo"
    Generates the prerequisite checklist for Google Cloud without executing cloud changes.

.OUTPUTS
    System.Management.Automation.PSCustomObject or output text depending on the executed target.

.NOTES
    Requires PowerShell 7+ (pwsh).
    Artifacts and state are saved in ~/.sailpoint-connect/.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect
.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs
#>
function Invoke-SailPointConnect {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('AWS', 'Azure', 'GoogleCloud', 'GCP', 'Databricks', 'Salesforce', 'GitHub', 'CrowdStrike', 'Okta', 'GitLab', 'Slack', 'Snowflake', 'ServiceNow', 'HashiCorpVault', 'EntroOutpost', 'OnPremActiveDirectory', 'RemoteFileSystem', 'IQService', 'M365AccessProfiles', 'Update')]
        [string]$Platform,

        [Parameter()]
        [switch]$Wizard,

        [Parameter()]
        [string]$Project,

        [Parameter()]
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,

        [Parameter()]
        [string]$OutputDirectory,

        [Parameter()]
        [switch]$NonInteractive,

        [Parameter()]
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',

        [Parameter()]
        [switch]$Update,

        [Parameter()]
        [switch]$CheckUpdate,

        [Parameter()]
        [switch]$SkipUpdateCheck,

        [Parameter(ValueFromRemainingArguments = $true)]
        $RemainingArguments
    )

    Initialize-OperatorConsole -NonInteractive:$NonInteractive
    $extraArgs = Convert-RemainingArgumentsToHashtable -Arguments $RemainingArguments

    if ($SkipUpdateCheck) {
        $env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK = '1'
    }

    if ($Update -or $Platform -eq 'Update') {
        $updateResult = Update-SailPointConnect -NonInteractive:$NonInteractive
        if ($updateResult.Reloaded -and -not $NonInteractive -and $Update -and -not $Platform) {
            return (Invoke-SailPointConnectSessionReentry -ConnectParams @{
                    Project              = $Project
                    SkipUpdateCheck      = $SkipUpdateCheck
                    RemainingArguments   = $RemainingArguments
                })
        }
        return $updateResult
    }

    if ($CheckUpdate) {
        return (Update-SailPointConnect -CheckOnly -NonInteractive:$NonInteractive)
    }

    $isInteractiveRoot = (-not $Platform -and -not $NonInteractive)
    :rootLoop while ($true) {
        $activePlatform = $Platform
        $activeWizard = [bool]$Wizard
        if (-not $activePlatform) {
            if ($NonInteractive) {
                throw "Non-interactive invocation requires -Platform. Choose from: AWS, Azure, GoogleCloud, Databricks, Salesforce, GitHub, CrowdStrike, Okta, GitLab, Slack, Snowflake, ServiceNow, HashiCorpVault, EntroOutpost, OnPremActiveDirectory, RemoteFileSystem, IQService, M365AccessProfiles, Update."
            }

            try {
                $rootMenuUpdateInfo = $null
                if ($env:SAILPOINT_CONNECT_SKIP_UPDATE_CHECK -notin @('1', 'true', '$true', 'True')) {
                    $rootMenuUpdateInfo = Get-SailPointConnectUpdate
                }
                Write-SailPointConnectBanner -ProjectName $Project -UpdateInfo $rootMenuUpdateInfo
                if (Confirm-SailPointConnectUpdate -Wizard -UpdateInfo $rootMenuUpdateInfo) {
                    return (Invoke-SailPointConnectSessionReentry -ConnectParams @{
                            Project              = $Project
                            SkipUpdateCheck      = $SkipUpdateCheck
                            RemainingArguments   = $RemainingArguments
                        })
                }

                Write-Host "Project workspace root: $(Get-IntegrationProjectRoot)`n" -ForegroundColor DarkGray

                $catalogResult = Start-IntegrationCatalogRootMenu -WizardRoot $script:ModuleRoot -Project $Project `
                    -Action $Action -OutputDirectory $OutputDirectory -OutputFormat $OutputFormat
                if ($catalogResult -and $catalogResult['Cancelled']) { return }
                if ($catalogResult -and $catalogResult['Launched']) { return }
                if ($catalogResult -and $catalogResult['Platform']) {
                    $special = [string]$catalogResult['Platform']
                    if ($special -eq 'Update') {
                        $menuUpdateResult = Update-SailPointConnect
                        if ($menuUpdateResult.Reloaded) {
                            return (Invoke-SailPointConnectSessionReentry -ConnectParams @{
                                    Project              = $Project
                                    SkipUpdateCheck      = $SkipUpdateCheck
                                    RemainingArguments   = $RemainingArguments
                                })
                        }
                        return $menuUpdateResult
                    }
                    $activePlatform = $special
                    $activeWizard = $true
                }
                else {
                    return
                }
            }
            catch {
                if (Test-CancelledNavigation $_) {
                    Write-Host ''
                    Write-Host 'Cancelled.' -ForegroundColor Yellow
                    return
                }
                throw
            }
        }

        $targetPlatform = if ($activePlatform -eq 'GCP') { 'GoogleCloud' } else { $activePlatform }

        try {
            switch ($targetPlatform) {
                'Update' {
                    return (Update-SailPointConnect -NonInteractive:$NonInteractive)
                }
                'AWS' {
                    $script = Join-Path $script:ModuleRoot 'AWS.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Azure' {
                    $script = Join-Path $script:ModuleRoot 'Azure.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'GoogleCloud' {
                    $script = Join-Path $script:ModuleRoot 'Google Cloud.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'Google-Cloud.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Databricks' {
                    $script = Join-Path $script:ModuleRoot 'Databricks.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Salesforce' {
                    $script = Join-Path $script:ModuleRoot 'Salesforce.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'GitHub' {
                    $script = Join-Path $script:ModuleRoot 'GitHub.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'CrowdStrike' {
                    $script = Join-Path $script:ModuleRoot 'CrowdStrike.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Okta' {
                    $script = Join-Path $script:ModuleRoot 'Okta.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'GitLab' {
                    $script = Join-Path $script:ModuleRoot 'GitLab.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Slack' {
                    $script = Join-Path $script:ModuleRoot 'Slack.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'Snowflake' {
                    $script = Join-Path $script:ModuleRoot 'Snowflake.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'ServiceNow' {
                    $script = Join-Path $script:ModuleRoot 'ServiceNow.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'HashiCorpVault' {
                    $script = Join-Path $script:ModuleRoot 'HashiCorp Vault.ps1'
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'EntroOutpost' {
                    $script = Join-Path $script:ModuleRoot 'Entro Outpost.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'Entro-Outpost.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'OnPremActiveDirectory' {
                    $script = Join-Path $script:ModuleRoot 'On-Prem Active Directory.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'On-Prem-Active-Directory.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'RemoteFileSystem' {
                    $script = Join-Path $script:ModuleRoot 'Remote File System.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'Remote-File-System.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($Project) { $pass['Project'] = $Project }
                    if ($Action) { $pass['Action'] = $Action }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputFormat) { $pass['OutputFormat'] = $OutputFormat }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'IQService' {
                    $script = Join-Path $script:ModuleRoot 'IQService-Control.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'IQService Control.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
                'M365AccessProfiles' {
                    $script = Join-Path $script:ModuleRoot 'Microsoft-365-Access-Profiles.ps1'
                    if (-not (Test-Path -LiteralPath $script)) {
                        $script = Join-Path $script:ModuleRoot 'Microsoft 365 Access Profiles.ps1'
                    }
                    $pass = @{}
                    if ($activeWizard) { $pass['Wizard'] = $true }
                    if ($NonInteractive) { $pass['NonInteractive'] = $true }
                    if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
                    foreach ($k in $extraArgs.Keys) { $pass[$k] = $extraArgs[$k] }
                    & $script @pass
                }
            }
        }
        catch {
            if (Test-CancelledNavigation $_) {
                if ($isInteractiveRoot) {
                    Write-Host ''
                    continue :rootLoop
                }
                Write-Host ''
                Write-Host 'Cancelled.' -ForegroundColor Yellow
                return
            }
            throw
        }

        if ($isInteractiveRoot -and (Get-Command Test-IntegrationWizardCancelled -ErrorAction SilentlyContinue) -and (Test-IntegrationWizardCancelled)) {
            Write-Host ''
            continue :rootLoop
        }

        break :rootLoop
    }
}

<#
.SYNOPSIS
    Configures SailPoint ISC AWS connectors and Entro onboarding.

.DESCRIPTION
    Runs the AWS setup wizard or CLI driver. Supports configuring:
    - Amazon Web Services SaaS connector IAM role and permissions
    - AWS CIEM connector CloudFormation stack and CloudTrail bucket integration
    - Entro AWS organization integration
    - Combined SaaS connector + Entro execution with shared context

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER SaaSConnector
    Targets the AWS SaaS connector IAM role.

.PARAMETER CiemConnector
    Targets the AWS CIEM connector.

.PARAMETER Entro
    Targets the Entro AWS onboarding integration.

.PARAMETER Method
    Entro onboarding method: AssumeRole, CloudFormation, or Terraform.

.PARAMETER Cloud
    Commercial or GovCloud AWS environment.

.PARAMETER Region
    Primary AWS region (e.g. us-east-1, eu-west-1).

.PARAMETER Access
    Permission access mode: ReadOnly or ReadWrite.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.PARAMETER IscExternalId
    External ID required for ISC connector connection settings trust policy.

.PARAMETER EntroExternalId
    External ID required for Entro onboarding trust policy.

.PARAMETER RoleName
    IAM role name. Check reads the role that already has this name. Run creates or updates it, after you confirm.

.PARAMETER Project
    Workspace project name under ~/.sailpoint-connect/.

.PARAMETER OutputDirectory
    Directory to store generated templates/scripts.

.PARAMETER NonInteractive
    Runs headlessly for CI/CD pipelines.

.EXAMPLE
    Connect-SailPointAWS -Wizard
    Starts guided interactive setup for AWS.

.EXAMPLE
    Connect-SailPointAWS -SaaSConnector -Access ReadOnly -RoleName "SailPointAWSRole" -Action Check
    Reads the existing IAM role and reports whether it already meets the ReadOnly requirements. Nothing is created.

.EXAMPLE
    Connect-SailPointAWS -SaaSConnector -Access ReadOnly -IscExternalId "ext-12345" -Action Run
    Creates the ISC AWS SaaS connector IAM role non-interactively. This is the action that changes the account.

.EXAMPLE
    Connect-SailPointAWS -SaaSConnector -Entro -IscExternalId "isc-1" -EntroExternalId "en-2" -Action BuildRequirements
    Builds the combined prerequisite requirements checklist for ISC + Entro.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Connect-SailPointAWS.md
#>
function Connect-SailPointAWS {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$SaaSConnector,
        [switch]$CiemConnector,
        [switch]$Entro,
        [ValidateSet('AssumeRole', 'CloudFormation', 'Terraform')]
        [string]$Method,
        [ValidateSet('Commercial', 'GovCloud')]
        [string]$Cloud,
        [string]$Region,
        [ValidateSet('Default', 'Europe')]
        [string]$EntroTemplateRegion,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$IscExternalId,
        [string]$EntroExternalId,
        [string]$RoleName,
        [string]$EntroRoleName,
        [string]$ProfileName,
        [switch]$NonInteractive,
        [string[]]$Feature,
        [string]$CloudTrailBucket,
        [string]$OutputDirectory,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'AWS.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Microsoft Entra / Azure connectors and Entro.

.DESCRIPTION
    Runs the Azure & Entra ID setup wizard or CLI driver. Supports:
    - Microsoft Entra ID connector application registration, client credentials, and permissions
    - Entro Microsoft ecosystem onboarding
    - Combined Entra connector + Entro execution with shared context

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the Microsoft Entra ID connector application registration.

.PARAMETER Entro
    Targets the Entro Microsoft ecosystem onboarding integration.

.PARAMETER Access
    Permission level: ReadOnly or ReadWrite.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.PARAMETER TenantId
    Microsoft Entra tenant ID (GUID).

.PARAMETER ApplicationName
    Name of the application registration in Entra ID. Default: SailPoint-ISC-EntraID.

.PARAMETER EnvironmentNickname
    Nickname used for Entro environment registration.

.PARAMETER RotateSecret
    Generates a new client secret even if the application already exists.

.PARAMETER Project
    Workspace project name under ~/.sailpoint-connect/.

.PARAMETER OutputDirectory
    Directory to store generated configuration files.

.PARAMETER NonInteractive
    Runs headlessly for automated execution.

.EXAMPLE
    Connect-SailPointAzure -Wizard
    Starts guided interactive setup for Microsoft Entra ID.

.EXAMPLE
    Connect-SailPointAzure -Connector -TenantId "11111111-2222-3333-4444-555555555555" -Access ReadOnly -Action Run
    Configures the Entra ID application registration in the specified tenant.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Connect-SailPointAzure.md
#>
function Connect-SailPointAzure {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$TenantId,
        [string]$ApplicationName,
        [string[]]$Feature,
        [string]$EnvironmentNickname,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [switch]$RotateSecret,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Azure.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Google Cloud / Workspace connectors and Entro.

.DESCRIPTION
    Runs the Google Cloud and Google Workspace setup wizard or CLI driver. Supports:
    - Google Workspace SaaS connector (Service Account or OAuth2)
    - Google Cloud CIEM connector
    - Entro GCP organization integration (automated service account and IAM roles)
    - Entro Google Workspace integration

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER SaaSConnector
    Targets Google Workspace SaaS connector.

.PARAMETER CiemConnector
    Targets GCP CIEM connector.

.PARAMETER GcpEntro
    Targets Entro Google GCP organization integration.

.PARAMETER WorkspaceEntro
    Targets Entro Google Workspace integration.

.PARAMETER Access
    Permission level: ReadOnly or ReadWrite.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.PARAMETER OrganizationId
    Google Cloud Organization ID.

.PARAMETER ProjectId
    Google Cloud Project ID.

.PARAMETER ImpersonateUser
    Admin email address for Google Workspace domain-wide delegation.

.PARAMETER Method
    Authentication method: PrivateKey or OAuth.

.PARAMETER Project
    Workspace project name under ~/.sailpoint-connect/.

.PARAMETER OutputDirectory
    Directory to store credentials and generated outputs.

.PARAMETER NonInteractive
    Runs headlessly without prompting.

.EXAMPLE
    Connect-SailPointGoogleCloud -Wizard
    Starts guided interactive setup for Google Cloud / Workspace.

.EXAMPLE
    Connect-SailPointGoogleCloud -SaaSConnector -GcpEntro -OrganizationId "123456789" -ProjectId "sec-proj" -Action BuildRequirements
    Builds the requirements checklist for Google Workspace SaaS connector + Entro GCP.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Connect-SailPointGoogleCloud.md
#>
function Connect-SailPointGoogleCloud {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$SaaSConnector,
        [switch]$CiemConnector,
        [switch]$GcpEntro,
        [switch]$WorkspaceEntro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$OrganizationId,
        [string]$ProjectId,
        [string]$ImpersonateUser,
        [ValidateSet('ActivityInsights', 'AgentDiscovery', 'Ciem', 'DeltaAggregation', 'DomainManagement', 'Gcp', 'GmailDelegates', 'NhiDiscovery')]
        [string[]]$Feature,
        [ValidateSet('PrivateKey', 'WorkloadIdentity')]
        [string]$Method,
        [string]$ClientId,
        [string]$ServiceAccountName,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project,
        [switch]$ApplyPreconditionFix
    )
    $script = Join-Path $script:ModuleRoot 'Google Cloud.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'Google-Cloud.ps1'
    }
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Databricks Account and Metastore connector.

.DESCRIPTION
    Runs the Databricks setup wizard or CLI driver. Configures:
    - Databricks Service Principal creation in the Databricks Account Console
    - Role assignments (Account Admin)
    - OAuth M2M credentials generation
    - Formatted SailPoint ISC Source Connection Settings output

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the Databricks connector setup.

.PARAMETER Cloud
    Hosting cloud: Aws, Azure, or Gcp.

.PARAMETER Auth
    Authentication mechanism: DatabricksM2M or Entra.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.PARAMETER ServicePrincipalName
    Name of the Databricks service principal. Default: SailPoint-source.

.PARAMETER AccountId
    Databricks Account ID.

.PARAMETER MetastoreId
    Unity Catalog Metastore ID.

.PARAMETER Project
    Workspace project name under ~/.sailpoint-connect/.

.PARAMETER OutputDirectory
    Directory to store credentials and generated connection settings.

.PARAMETER NonInteractive
    Runs headlessly for CI/CD automation.

.EXAMPLE
    Connect-SailPointDatabricks -Wizard
    Starts guided interactive setup for Databricks.

.EXAMPLE
    Connect-SailPointDatabricks -Connector -Cloud Aws -AccountId "acc-1234" -Action Run
    Creates the Databricks service principal and outputs ISC connection settings.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Connect-SailPointDatabricks.md
#>
function Connect-SailPointDatabricks {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [ValidateSet('Aws', 'Azure', 'Gcp')]
        [string]$Cloud,
        [ValidateSet('DatabricksM2M', 'Entra')]
        [string]$Auth,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$ServicePrincipalName,
        [string]$AccountId,
        [string]$MetastoreId,
        [ValidateSet('AgentDiscovery')]
        [string[]]$Feature,
        [switch]$RotateSecret,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Databricks.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Salesforce connector and Entro onboarding.

.DESCRIPTION
    Runs the Salesforce setup wizard or CLI driver. Supports configuring:
    - Salesforce SaaS connector Connected App
    - Machine identity governance for Salesforce Agentforce AI agents and bot users
    - Entro Salesforce integration

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the Salesforce SaaS connector.

.PARAMETER Entro
    Targets the Entro Salesforce integration.

.PARAMETER InstanceUrl
    Salesforce My Domain URL (e.g. https://mycompany.my.salesforce.com).

.PARAMETER Feature
    Feature packs: AgentDiscovery (Agentforce), ActivityInsights.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.EXAMPLE
    Connect-SailPointSalesforce -Wizard
    Starts guided interactive setup for Salesforce and Agentforce discovery.

.EXAMPLE
    Connect-SailPointSalesforce -Connector -InstanceUrl "https://mycompany.my.salesforce.com" -Feature AgentDiscovery -Action Run
    Configures Salesforce SaaS connector with Agentforce AI agent discovery.
#>
function Connect-SailPointSalesforce {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$InstanceUrl,
        [string]$LoginUrl,
        [string]$ConsumerKey,
        [string]$ConsumerSecret,
        [string]$Username,
        [ValidateSet('AgentDiscovery', 'ActivityInsights')]
        [string[]]$Feature,
        [string]$Environment,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Salesforce.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC GitHub connector and Entro onboarding.

.DESCRIPTION
    Runs the GitHub setup wizard or CLI driver. Supports configuring:
    - GitHub SaaS connector organization authentication
    - Machine identity governance for GitHub Copilot seats, GitHub Apps, and Bots
    - Entro GitHub Cloud integration (App installation or PAT)
    - Entro GitHub Enterprise Server classic PAT (requires an Outpost)

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the GitHub SaaS connector.

.PARAMETER Entro
    Targets the Entro GitHub Cloud integration.

.PARAMETER GhesEntro
    Targets Entro onboarding for GitHub Enterprise Server. Requires an Outpost Worker Group.

.PARAMETER Organization
    GitHub organization name.

.PARAMETER Feature
    Feature packs: AgentDiscovery (Copilot seats & Bots), ActivityInsights.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.EXAMPLE
    Connect-SailPointGitHub -Wizard
    Starts guided interactive setup for GitHub SaaS connector and Copilot/bot discovery.

.EXAMPLE
    Connect-SailPointGitHub -Connector -Organization "acme-corp" -Feature AgentDiscovery -Action Run
    Configures GitHub SaaS connector with Copilot seat and bot machine identity discovery.

.EXAMPLE
    Connect-SailPointGitHub -GhesEntro -Hostname "github.corp.local" -DisplayName "Corp GHES" -Action BuildScript -NonInteractive
    Writes the GitHub Enterprise Server classic PAT checklist script. Run does not create the PAT.
#>
function Connect-SailPointGitHub {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [switch]$GhesEntro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Organization,
        [string]$ApiUrl,
        [ValidateSet('PersonalAccessToken', 'GitHubApp')]
        [string]$AuthMethod,
        [string]$Token,
        [string]$AppId,
        [string]$InstallationId,
        [string]$PrivateKey,
        [ValidateSet('AgentDiscovery', 'ActivityInsights')]
        [string[]]$Feature,
        [ValidateSet('GitHubApp', 'ClassicPAT')]
        [string]$Method,
        [string]$Hostname,
        [string]$DisplayName,
        [ValidateSet('Production', 'Development', 'Staging')]
        [string]$EnvironmentType,
        [string]$WorkerGroup,
        [string]$OutpostId,
        [string]$OutpostPublicKeyPath,
        [string]$OutpostDeploymentMode,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'GitHub.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Okta connector and Entro onboarding.
.DESCRIPTION
    Runs the Okta wizard for Agentic Fabric JWT service-app authentication and Entro API Services app handoff.
.EXAMPLE
    Connect-SailPointOkta -Wizard
#>
function Connect-SailPointOkta {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$OktaDomain,
        [string]$ClientId,
        [string]$TokenUrl,
        [string]$Scope,
        [string]$JwtHeader,
        [string]$PrivateKey,
        [string]$PrivateKeyPassword,
        [string]$Environment,
        [string]$DisplayName,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Okta.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC GitLab connector and Entro onboarding.
.DESCRIPTION
    Runs the GitLab wizard for access-token-based Agentic Fabric sources, Entro GitLab on gitlab.com, and self-managed GitLab through an Outpost.
.EXAMPLE
    Connect-SailPointGitLab -Wizard

.EXAMPLE
    Connect-SailPointGitLab -GitLabSelfManaged -Nickname "corp-gitlab" -GitLabUrl "https://gitlab.corp.local" -Action BuildScript -NonInteractive
    Writes the self-managed GitLab token script. The admin token stays in the environment and is not written into the file.
#>
function Connect-SailPointGitLab {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [switch]$GitLabSelfManaged,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$BaseUrl,
        [ValidateSet('Yes', 'No')]
        [string]$SelfManaged,
        [ValidateSet('PersonalAccessToken', 'GroupAccessToken')]
        [string]$AuthType,
        [string]$AccessToken,
        [string]$TargetGroups,
        [string]$Nickname,
        [string]$GitLabUrl,
        [ValidateSet('Group', 'Personal')]
        [string]$TokenKind,
        [string]$GroupPath,
        [string]$Username,
        [string]$TokenExpires,
        [string]$WorkerGroup,
        [string]$OutpostId,
        [string]$OutpostPublicKeyPath,
        [string]$OutpostDeploymentMode,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'GitLab.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC Slack connector and Entro onboarding.
.DESCRIPTION
    Runs the Slack wizard for workspace app tokens (Agentic Fabric) and Entro private-app manifest install.
.EXAMPLE
    Connect-SailPointSlack -Wizard
#>
function Connect-SailPointSlack {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$WorkspaceName,
        [string]$BotUserOAuthToken,
        [string]$UserOAuthToken,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Slack.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures Entro Snowflake integration onboarding.
.DESCRIPTION
    Runs the Snowflake Entro wizard for key-pair user setup and account URL handoff.
.EXAMPLE
    Connect-SailPointSnowflake -Wizard
#>
function Connect-SailPointSnowflake {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Environment,
        [string]$DisplayName,
        [string]$AccountUrl,
        [string]$EntroUser,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Snowflake.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures Entro ServiceNow integration onboarding.
.DESCRIPTION
    Runs the ServiceNow Entro wizard for REST API key integration user setup.
.EXAMPLE
    Connect-SailPointServiceNow -Wizard
#>
function Connect-SailPointServiceNow {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Environment,
        [string]$DisplayName,
        [string]$InstanceUrl,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'ServiceNow.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures Entro HashiCorp Vault integration onboarding.
.DESCRIPTION
    Runs the Vault Entro wizard for entro-policy ACL and renewable token handoff. The target is a host that can reach the Vault API. An Outpost Worker Group scans the cluster.
.EXAMPLE
    Connect-SailPointHashiCorpVault -Wizard

.EXAMPLE
    Connect-SailPointHashiCorpVault -Entro -Environment "prod" -VaultUrl "https://vault.corp.local:8200" -Action BuildScript -NonInteractive
    Writes the entro-policy and token script. The admin token is read from the environment at run time.
#>
function Connect-SailPointHashiCorpVault {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Environment,
        [string]$VaultUrl,
        [ValidateSet('Standard', 'KvMetadata')]
        [string]$PolicyMode,
        [string]$KvMount,
        [string]$WorkerGroup,
        [string]$OutpostId,
        [string]$OutpostPublicKeyPath,
        [string]$OutpostDeploymentMode,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'HashiCorp Vault.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Deploys or generates artifacts for the Entro Outpost on-premise container runtime.

.DESCRIPTION
    Configures, checks, or deploys an Entro Outpost worker group via Docker Compose
    (on a Linux AMD64 host) or Kubernetes Helm (OCI chart on Linux AMD64 nodes).
    Supports BuildRequirements, Check, BuildScript, and Run actions across both modes.

.PARAMETER Wizard
    Runs the interactive guided setup for Entro Outpost.

.PARAMETER DockerCompose
    Targets the Docker Compose deployment model on a Linux AMD64 host.

.PARAMETER KubernetesHelm
    Targets the Kubernetes Helm deployment model via oci://ghcr.io/entro-security-registry/entro-connector-helm.

.PARAMETER Action
    BuildRequirements (checklist), Check (probe host/cluster prerequisites), BuildScript (write deploy script), or Run (execute deployment).

.PARAMETER WorkerGroup
    Logical Entro Worker Group name.

.PARAMETER AwsRegion
    AWS region for Entro Outpost S3/SQS/CloudWatch Logs (default us-east-1).

.PARAMETER AwsAccessKeyId
    AWS Access Key ID from the Entro Outpost console wizard.

.PARAMETER AwsSecretAccessKey
    AWS Secret Access Key from the Entro Outpost console wizard.

.PARAMETER CrPat
    GitHub Container Registry PAT for entro-registry.

.PARAMETER LogGroup
    CloudWatch log group name (default /entro/connector).

.PARAMETER EnableEncryptedSecrets
    Yes or No to generate an RSA-2048 key pair for Encrypted Integration Secrets.

.PARAMETER UseProxy
    Yes or No to configure HTTP_PROXY and NO_PROXY.

.PARAMETER HttpProxy
    HTTP/HTTPS proxy URL when UseProxy is Yes.

.PARAMETER NoProxy
    Comma-separated NO_PROXY bypass list when UseProxy is Yes.

.PARAMETER DeploymentTier
    Docker Compose host sizing tier (Standard or Large).

.PARAMETER InstallDirectory
    Target install directory on the Linux host for Docker Compose (default /opt/entro-outpost).

.PARAMETER ComposeFileUrl
    Path or URL to docker-compose.yaml from the Entro Outpost wizard.

.PARAMETER OutputBucket
    S3 bucket name (OUTPUT_BUCKET) for Docker Compose.

.PARAMETER SqsQueueUrl
    SQS queue URL (SQS_QUEUE_URL) for Docker Compose.

.PARAMETER RedshiftBucket
    Optional Redshift S3 bucket name (REDSHIFT_BUCKET) for Docker Compose.

.PARAMETER LogStream
    CloudWatch log stream name for Docker Compose.

.PARAMETER KubernetesNamespace
    Target Kubernetes namespace for Helm deployment (default entro).

.PARAMETER HelmReleaseName
    Helm release name (default entro-connector).

.PARAMETER ChartVersion
    Helm chart version or 'latest'.

.PARAMETER AwsAccountId
    Entro AWS Account ID for Helm values (default 937217723901).

.PARAMETER EntroConnectorId
    Entro Connector ID for Helm values.

.PARAMETER EntroPassword
    Entro Connector password for Helm values.

.PARAMETER EnableScheduling
    Yes or No to configure KEDA/cron pod scaling schedule in Helm values.

.PARAMETER ScheduleScaleUp
    Cron schedule for scale-up (default 0 7 * * 1-5).

.PARAMETER ScheduleScaleDown
    Cron schedule for scale-down (default 0 19 * * 1-5).

.PARAMETER ScheduleTimeZone
    IANA timezone for pod scaling schedule (default UTC).

.PARAMETER OutputDirectory
    Overrides output directory for generated artifacts.

.PARAMETER NonInteractive
    Runs in headless mode without prompts.

.PARAMETER OutputFormat
    Output format: Text or Json.

.PARAMETER Project
    Workspace project name.

.EXAMPLE
    Connect-SailPointEntroOutpost -Wizard
    Starts the interactive Entro Outpost wizard to select Docker Compose or Kubernetes Helm.

.EXAMPLE
    Connect-SailPointEntroOutpost -DockerCompose -Action BuildRequirements -NonInteractive -OutputFormat Json
    Generates the Docker Compose prerequisite checklist and returns structured JSON.
#>
function Connect-SailPointEntroOutpost {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$DockerCompose,
        [switch]$KubernetesHelm,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$WorkerGroup,
        [string]$AwsRegion,
        [string]$AwsAccessKeyId,
        [string]$AwsSecretAccessKey,
        [string]$CrPat,
        [string]$LogGroup,
        [ValidateSet('No', 'Yes')]
        [string]$EnableEncryptedSecrets,
        [ValidateSet('No', 'Yes')]
        [string]$UseProxy,
        [string]$HttpProxy,
        [string]$NoProxy,
        [ValidateSet('Standard', 'Large')]
        [string]$DeploymentTier,
        [string]$InstallDirectory,
        [string]$ComposeFileUrl,
        [string]$OutputBucket,
        [string]$SqsQueueUrl,
        [string]$RedshiftBucket,
        [string]$LogStream,
        [string]$KubernetesNamespace,
        [string]$HelmReleaseName,
        [string]$ChartVersion,
        [string]$AwsAccountId,
        [string]$EntroConnectorId,
        [string]$EntroPassword,
        [ValidateSet('No', 'Yes')]
        [string]$EnableScheduling,
        [string]$ScheduleScaleUp,
        [string]$ScheduleScaleDown,
        [string]$ScheduleTimeZone,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Entro Outpost.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'Entro-Outpost.ps1'
    }
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures Entro on-prem Active Directory onboarding.

.DESCRIPTION
    Creates a read-only AD service account and exports the LDAPS root CA for Entro.
    Run this on a Windows host with the ActiveDirectory module, or use BuildScript and copy the .ps1 there.
    An Outpost Worker Group must reach the domain controller. The account is not added to an admin group.

.PARAMETER Entro
    Targets the Entro on-prem Active Directory integration.

.PARAMETER Action
    BuildRequirements, Check, BuildScript, or Run.

.EXAMPLE
    Connect-SailPointOnPremActiveDirectory -Wizard
    Starts the guided on-prem Active Directory wizard.

.EXAMPLE
    Connect-SailPointOnPremActiveDirectory -Entro -Nickname "corp-ad" -DomainController "dc01" -DcFqdn "dc01.corp.local" -Domain "corp.local" -EnvironmentNickname "corp" -Action BuildScript -NonInteractive
    Writes the service-account and root CA script. The password is not written into the file.
#>
function Connect-SailPointOnPremActiveDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Entro,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Nickname,
        [string]$DomainController,
        [string]$DcFqdn,
        [string]$Domain,
        [string]$SamAccountName,
        [string]$EnvironmentNickname,
        [ValidateSet('Production', 'Staging', 'Dev')]
        [string]$EnvironmentType,
        [string]$WorkerGroup,
        [string]$OutpostId,
        [string]$OutpostPublicKeyPath,
        [string]$OutpostDeploymentMode,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'On-Prem Active Directory.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'On-Prem-Active-Directory.ps1'
    }
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures Entro remote file scanning over SMB, SFTP, or WinRM.

.DESCRIPTION
    Prepares a read-only file account and the Entro handoff for one transport.
    SMB and WinRM Run on the Windows host that will be changed. SFTP can run from any host that can reach port 22 and has ssh-keygen.
    Each transport requires an Outpost Worker Group. Passwords are not written into generated scripts.

.PARAMETER Smb
    Targets SMB file shares.

.PARAMETER Sftp
    Targets SFTP.

.PARAMETER WinRm
    Targets WinRM.

.PARAMETER FileHost
    DNS name or IP of the SFTP or WinRM host. Alias: TargetHostName.

.PARAMETER Action
    BuildRequirements, Check, BuildScript, or Run.

.EXAMPLE
    Connect-SailPointRemoteFileSystem -Wizard
    Starts the guided remote file system wizard.

.EXAMPLE
    Connect-SailPointRemoteFileSystem -Smb -Nickname "finance" -Username "CORP\entro_smb" -ShareHost "files.corp.local" -Action BuildScript -NonInteractive
    Writes the SMB account script and smb-file-shares.json template. The password stays in the environment.
#>
function Connect-SailPointRemoteFileSystem {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Smb,
        [switch]$Sftp,
        [switch]$WinRm,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Nickname,
        [ValidateSet('Domain', 'Local')]
        [string]$AccountScope,
        [string]$Username,
        [string]$ShareHost,
        [string]$ShareNames,
        [string]$IgnoreShares,
        [Alias('TargetHostName')]
        [string]$FileHost,
        [string]$TargetDirectories,
        [string]$PublicKeyPath,
        [string]$WorkerGroup,
        [string]$OutpostId,
        [string]$OutpostPublicKeyPath,
        [string]$OutpostDeploymentMode,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'Remote File System.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'Remote-File-System.ps1'
    }
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Configures SailPoint ISC CrowdStrike Falcon connector and Entro onboarding.

.DESCRIPTION
    Runs the CrowdStrike Falcon setup wizard or CLI driver. Supports configuring:
    - CrowdStrike Falcon SaaS connector API client authentication (OAuth2)
    - Access Level segmentation (ReadOnly vs ReadWrite host containment & user management)
    - Feature packs: Falcon Discover (Machine Identity & unmanaged assets), Falcon Identity Threat Protection (ITDR), Falcon Horizon (CSPM), and Real Time Response (RTR)
    - Entro CrowdStrike integration & optional Falcon RTR secrets scanner

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the CrowdStrike Falcon SaaS connector.

.PARAMETER Entro
    Targets the Entro CrowdStrike integration.

.PARAMETER BaseUrl
    CrowdStrike Falcon Cloud API Base URL or region (e.g. US-1, US-2, EU-1, US-GOV-1).

.PARAMETER ClientId
    Falcon OAuth2 API Client ID.

.PARAMETER ClientSecret
    Falcon OAuth2 API Client Secret.

.PARAMETER Access
    Access level: ReadOnly or ReadWrite. ReadOnly performs aggregation; ReadWrite authorizes host containment and user provisioning.

.PARAMETER Feature
    Feature packs: Discover, IdentityProtection, CloudSecurity, RealTimeResponse.

.PARAMETER Environment
    Environment nickname for Entro integration.

.PARAMETER Action
    BuildRequirements (checklist), Check (read an existing identity), BuildScript (review, then run it yourself), or Run (the only action that changes the tenant, after you confirm).

.PARAMETER OutputDirectory
    Overrides output directory for generated artifacts and connection settings.

.PARAMETER NonInteractive
    Runs in headless mode.

.PARAMETER Project
    Workspace project name.

.EXAMPLE
    Connect-SailPointCrowdStrike -Wizard
    Starts guided interactive setup for CrowdStrike Falcon SaaS connector and Entro onboarding.

.EXAMPLE
    Connect-SailPointCrowdStrike -Connector -BaseUrl "https://api.crowdstrike.com" -ClientId "client-id" -Access ReadOnly -Feature Discover,IdentityProtection -Action BuildScript
    Generates a standalone CLI/PowerShell script validating Falcon API connectivity, host aggregation, Falcon Discover machine identity governance, and ITDR scopes.
#>
function Connect-SailPointCrowdStrike {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$BaseUrl,
        [string]$ClientId,
        [string]$ClientSecret,
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            @('Discover', 'IdentityProtection', 'CloudSecurity', 'RealTimeResponse') | Where-Object { $_ -like "$wordToComplete*" }
        })]
        [string[]]$Feature,
        [string]$Environment,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [ValidateSet('Text', 'Json')]
        [string]$OutputFormat = 'Text',
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'CrowdStrike.ps1'
    & $script @PSBoundParameters
}

<#
.SYNOPSIS
    Manages SailPoint IQService lifecycle and Active Directory LDAPS setup.

.DESCRIPTION
    Windows operator utility for IQService hosts.
    Supports downloading IQService from ISC pre-signed URLs, extracting and unblocking
    binaries (including Utils.dll), registering or upgrading the Windows service,
    starting/stopping, configuring logging, colored live log streaming, status reporting,
    and configuring Active Directory LDAPS (TCP 636) with PEM export for Virtual Appliance truststores.

.PARAMETER Action
    Download, Install, Update, Uninstall, Start, Stop, Restart, SetLogLevel, StreamLogs,
    Status, Unblock, or EnableLdaps. If omitted, displays an interactive menu.

.PARAMETER InstallPath
    IQService installation directory (default: C:\SailPoint\IQService).

.PARAMETER InstanceName
    Selects an existing instance by Windows service name or registry key.

.PARAMETER DownloadUri
    Pre-signed ISC download URL for IQService.zip.

.PARAMETER ZipPath
    Path to a local IQService.zip file.

.EXAMPLE
    Invoke-SailPointIQServiceControl
    Opens interactive operator console for IQService (aliased as Start-SailPointIQServiceControl).

.EXAMPLE
    Invoke-SailPointIQServiceControl -Action Status
    Queries the current status, port, version, and TLS configuration of IQService.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Start-SailPointIQServiceControl.md
#>
function Invoke-SailPointIQServiceControl {
    [CmdletBinding()]
    param(
        [switch]$Wizard,
        [ValidateSet('Download', 'Install', 'Update', 'Uninstall', 'Start', 'Stop', 'Restart', 'SetLogLevel', 'StreamLogs', 'Status', 'Unblock', 'EnableLdaps')]
        [string]$Action,
        [string]$InstallPath,
        [string]$InstanceName,
        [string]$DownloadUri,
        [string]$ZipPath,
        [int]$Port,
        [int]$TlsPort,
        [switch]$SkipSecondary,
        [ValidateSet('Off', 'Error', 'Info', 'Debug', 'Trace')]
        [string]$LogLevel,
        [string]$TraceFile,
        [int]$Tail = 50,
        [switch]$StartAfterInstall,
        [Alias('LdapsExportDirectory')]
        [string]$PemOutputPath,
        [string]$Thumbprint,
        [Alias('LdapsCertSubject')]
        [string[]]$DnsName,
        [switch]$RestartNtds,
        [switch]$CreateSelfSigned,
        [switch]$NonInteractive
    )
    $script = Join-Path $script:ModuleRoot 'IQService-Control.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'IQService Control.ps1'
    }
    $pass = @{}
    foreach ($k in $PSBoundParameters.Keys) { $pass[$k] = $PSBoundParameters[$k] }
    if (-not $Action -and -not $pass.ContainsKey('Wizard') -and -not $NonInteractive) {
        $pass['Wizard'] = $true
    }
    & $script @pass
}

<#
.SYNOPSIS
    Creates requestable SailPoint access profiles from Microsoft Entra service-plan entitlements.

.DESCRIPTION
    Interactive wizard that:
    1. Authenticates to ISC via PSSailpoint using ~/.sailpoint/config.yaml or credentials.
    2. Discovers Microsoft Entra sources with servicePlan entitlements.
    3. Displays friendly Microsoft 365 licensing plan names for multi-select.
    4. Automatically creates requestable access profiles and an optional grouping source app.

.PARAMETER Environment
    Named environment from ~/.sailpoint/config.yaml.

.PARAMETER SourceId
    ISC source ID containing Entra service plans.

.PARAMETER PlanValues
    Specific service plan GUIDs or internal names for non-interactive creation.

.PARAMETER AccessProfilePrefix
    Prefix for created access profile names. Default: "M365 - ".

.PARAMETER ApplicationName
    Name of the grouping source application.

.PARAMETER SkipApplication
    Skips creating the grouping source application.

.EXAMPLE
    New-SailPointM365AccessProfile
    Launches the interactive service plan discovery and access profile creator.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/New-SailPointM365AccessProfile.md
#>
function New-SailPointM365AccessProfile {
    [CmdletBinding()]
    param(
        [switch]$Wizard,
        [string]$Environment,
        [string]$ConfigPath,
        [string]$SailpointConfigPath,
        [string]$SourceId,
        [string[]]$PlanValues,
        [string]$AccessProfilePrefix = 'M365 - ',
        [string]$ApplicationName,
        [switch]$SkipApplication,
        [Alias('OwnerIdentityId')]
        [string]$OwnerId,
        [string]$PreviousManifestPath,
        [ValidateSet('Ask', 'Skip', 'Update')]
        [string]$ExistingItemAction = 'Ask',
        [string]$OutputDirectory,
        [switch]$NonInteractive
    )
    $script = Join-Path $script:ModuleRoot 'Microsoft-365-Access-Profiles.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'Microsoft 365 Access Profiles.ps1'
    }
    $pass = @{}
    foreach ($k in $PSBoundParameters.Keys) { $pass[$k] = $PSBoundParameters[$k] }
    if (-not $Environment -and -not $PreviousManifestPath -and -not $pass.ContainsKey('Wizard') -and -not $NonInteractive) {
        $pass['Wizard'] = $true
    }
    & $script @pass
}

<#
.SYNOPSIS
    Lists all project workspaces stored in ~/.sailpoint-connect/.

.DESCRIPTION
    Returns metadata for all integration projects currently saved in the user's
    ~/.sailpoint-connect/ directory, indicating which project is currently active.

.EXAMPLE
    Get-SailPointConnectProject
    Returns a table of all projects, paths, and current selection indicator.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Properties: Name, IsCurrent, Path

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Get-SailPointConnectProject.md
#>
function Get-SailPointConnectProject {
    [CmdletBinding()]
    param()
    $root = Get-IntegrationProjectRoot
    $current = Get-IntegrationProjectLastSelected -Root $root
    $names = @(Get-IntegrationProjectNames -Root $root)
    foreach ($name in $names) {
        [PSCustomObject]@{
            Name      = $name
            IsCurrent = ($name -eq $current)
            Path      = Join-Path $root $name
        }
    }
}

<#
.SYNOPSIS
    Sets the active project workspace in ~/.sailpoint-connect/.

.DESCRIPTION
    Updates current.json in ~/.sailpoint-connect/ to set the default project
    selected during interactive runs and CLI defaults.

.PARAMETER Name
    The project workspace name to set as active.

.EXAMPLE
    Set-SailPointConnectProject -Name "emea-tes-team"
    Sets "emea-tes-team" as the current project.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Set-SailPointConnectProject.md
#>
function Set-SailPointConnectProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    Test-IntegrationProjectName -Name $Name
    $root = Get-IntegrationProjectRoot
    $projDir = Join-Path $root $Name
    if (-not (Test-Path -LiteralPath $projDir)) {
        New-Item -ItemType Directory -Path $projDir -Force | Out-Null
    }
    Set-IntegrationProjectLastSelected -ProjectName $Name -Root $root
    Write-Host "Active SailPoint Connect project set to: $Name" -ForegroundColor Green
}

<#
.SYNOPSIS
    Checks whether an update is available for the SailPoint Connect PowerShell module.

.DESCRIPTION
    Queries PowerShell Gallery to compare the latest published release against the
    locally installed or active version.

.PARAMETER CurrentVersion
    Optional override for the current version string. Defaults to the active module version.

.PARAMETER Repository
    PowerShell repository to check. Default: PSGallery.

.PARAMETER TimeoutSeconds
    Network timeout in seconds for repository query. Default: 4.

.PARAMETER Force
    Bypasses any update skip environment variables.

.EXAMPLE
    Get-SailPointConnectUpdate
    Checks PowerShell Gallery for the latest version of SailPoint.Connect.

.OUTPUTS
    System.Management.Automation.PSCustomObject with UpdateAvailable, CurrentVersion, and LatestVersion.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Get-SailPointConnectUpdate.md
#>
function Get-SailPointConnectUpdate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$CurrentVersion,

        [Parameter()]
        [string]$Repository = 'PSGallery',

        [Parameter()]
        [int]$TimeoutSeconds = 4,

        [Parameter()]
        [switch]$Force
    )
    $mod = @(Get-Module 'ISC.OperatorToolchain' | Where-Object { $_.ExportedFunctions.ContainsKey('Get-SailPointConnectUpdate') }) | Select-Object -Last 1
    if ($mod) {
        $fn = $mod.ExportedFunctions['Get-SailPointConnectUpdate']
        $pass = @{}
        foreach ($k in $PSBoundParameters.Keys) { $pass[$k] = $PSBoundParameters[$k] }
        & $fn @pass
    }
}

<#
.SYNOPSIS
    Updates the SailPoint Connect PowerShell module to the latest version.

.DESCRIPTION
    Checks PowerShell Gallery for a newer release of SailPoint.Connect and installs
    or updates the module for the current user.

.PARAMETER CheckOnly
    Checks whether a newer version is available and outputs the result without updating.

.PARAMETER Force
    Reinstalls the latest version even if the current version is up to date.

.PARAMETER Scope
    Installation scope: CurrentUser (default) or AllUsers.

.PARAMETER TargetVersion
    Optional specific version to install.

.PARAMETER NonInteractive
    Runs headlessly without confirmation prompts.

.EXAMPLE
    Update-SailPointConnect
    Checks for a newer version and installs the update if available.

.EXAMPLE
    Update-SailPointConnect -CheckOnly
    Reports whether an update is available without making changes.

.OUTPUTS
    System.Management.Automation.PSCustomObject with update results.

.LINK
    https://github.com/sailpoint-oss/sailpoint-connect/tree/main/docs/cmdlets/Update-SailPointConnect.md
#>
function Update-SailPointConnect {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [switch]$CheckOnly,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [Parameter()]
        [string]$TargetVersion,

        [Parameter()]
        [switch]$NonInteractive
    )
    $mod = @(Get-Module 'ISC.OperatorToolchain' | Where-Object { $_.ExportedFunctions.ContainsKey('Update-SailPointConnect') }) | Select-Object -Last 1
    if ($mod) {
        $fn = $mod.ExportedFunctions['Update-SailPointConnect']
        $pass = @{}
        foreach ($k in $PSBoundParameters.Keys) { $pass[$k] = $PSBoundParameters[$k] }
        if ($WhatIfPreference) { $pass['WhatIf'] = $true }
        & $fn @pass
    }
}

# Aliases
Set-Alias -Name 'sailpoint-connect' -Value 'Invoke-SailPointConnect' -Description 'SailPoint Connect unified runner'
Set-Alias -Name 'Start-SailPointIQServiceControl' -Value 'Invoke-SailPointIQServiceControl' -Description 'Alias for Invoke-SailPointIQServiceControl'
Set-Alias -Name 'update-sailpoint-connect' -Value 'Update-SailPointConnect' -Description 'Alias for Update-SailPointConnect'

Export-ModuleMember -Function @(
    'Invoke-SailPointConnect',
    'Connect-SailPointAWS',
    'Connect-SailPointAzure',
    'Connect-SailPointGoogleCloud',
    'Connect-SailPointDatabricks',
    'Connect-SailPointSalesforce',
    'Connect-SailPointGitHub',
    'Connect-SailPointOkta',
    'Connect-SailPointGitLab',
    'Connect-SailPointSlack',
    'Connect-SailPointSnowflake',
    'Connect-SailPointServiceNow',
    'Connect-SailPointHashiCorpVault',
    'Connect-SailPointEntroOutpost',
    'Connect-SailPointOnPremActiveDirectory',
    'Connect-SailPointRemoteFileSystem',
    'Connect-SailPointCrowdStrike',
    'Invoke-SailPointIQServiceControl',
    'New-SailPointM365AccessProfile',
    'Get-SailPointConnectProject',
    'Set-SailPointConnectProject',
    'Update-SailPointConnect',
    'Get-SailPointConnectUpdate'
) -Alias @(
    'sailpoint-connect',
    'Start-SailPointIQServiceControl',
    'update-sailpoint-connect'
)
