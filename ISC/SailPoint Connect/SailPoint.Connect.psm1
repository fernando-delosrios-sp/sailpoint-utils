#Requires -Version 7
Set-StrictMode -Version Latest

# Load core modules
$script:ModuleRoot = $PSScriptRoot
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Core.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Project.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/IW.Render.psm1') -Force -Global
Import-Module (Join-Path $script:ModuleRoot 'modules/ISC.OperatorConsole.psm1') -Force -Global -WarningAction SilentlyContinue
Import-Module (Join-Path $script:ModuleRoot 'modules/ISC.OperatorToolchain.psm1') -Force -Global -WarningAction SilentlyContinue

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
        [ValidateSet('AWS', 'Azure', 'GoogleCloud', 'GCP', 'Databricks', 'Salesforce', 'GitHub', 'CrowdStrike', 'IQService', 'M365AccessProfiles')]
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

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$RemainingArguments
    )

    Initialize-OperatorConsole -NonInteractive:$NonInteractive
    $hasExtra = ($null -ne $RemainingArguments) -and (@($RemainingArguments).Count -gt 0)

    try {
        if (-not $Platform) {
        if ($NonInteractive) {
            throw "Non-interactive invocation requires -Platform. Choose from: AWS, Azure, GoogleCloud, Databricks, Salesforce, GitHub, CrowdStrike, IQService, M365AccessProfiles."
        }

        Write-SailPointConnectBanner -ProjectName $Project
        Write-Host "Project workspace root: $(Get-IntegrationProjectRoot)`n" -ForegroundColor DarkGray

        $options = @('AWS', 'Azure', 'GoogleCloud', 'Databricks', 'Salesforce', 'GitHub', 'CrowdStrike', 'IQService', 'M365AccessProfiles')
        $labels = @(
            'Amazon Web Services (SaaS connector, CIEM, Entro)',
            'Microsoft Azure & Entra ID (Connector, Entro)',
            'Google Cloud & Workspace (Connector, CIEM, Entro)',
            'Databricks (Account & Metastore connector)',
            'Salesforce (SaaS connector, Agentforce, Entro)',
            'GitHub (SaaS connector, Copilot & Bots, Entro)',
            'CrowdStrike (Falcon SaaS connector, Discover & ITDR, Entro)',
            'IQService Control (Host lifecycle & AD LDAPS)',
            'Microsoft 365 Access Profiles (Entra service plans)'
        )
        $picked = Read-Choice -Prompt 'Select platform to configure' -Options $options -Labels $labels -Default 'AWS'
        $Platform = $picked
        $Wizard = $true
    }

    $targetPlatform = if ($Platform -eq 'GCP') { 'GoogleCloud' } else { $Platform }

    switch ($targetPlatform) {
        'AWS' {
            $script = Join-Path $script:ModuleRoot 'AWS.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'Azure' {
            $script = Join-Path $script:ModuleRoot 'Azure.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'GoogleCloud' {
            $script = Join-Path $script:ModuleRoot 'Google-Cloud.ps1'
            if (-not (Test-Path -LiteralPath $script)) {
                $script = Join-Path $script:ModuleRoot 'Google Cloud.ps1'
            }
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'Databricks' {
            $script = Join-Path $script:ModuleRoot 'Databricks.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'Salesforce' {
            $script = Join-Path $script:ModuleRoot 'Salesforce.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'GitHub' {
            $script = Join-Path $script:ModuleRoot 'GitHub.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'CrowdStrike' {
            $script = Join-Path $script:ModuleRoot 'CrowdStrike.ps1'
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($Project) { $pass['Project'] = $Project }
            if ($Action) { $pass['Action'] = $Action }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'IQService' {
            $script = Join-Path $script:ModuleRoot 'IQService-Control.ps1'
            if (-not (Test-Path -LiteralPath $script)) {
                $script = Join-Path $script:ModuleRoot 'IQService Control.ps1'
            }
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
        'M365AccessProfiles' {
            $script = Join-Path $script:ModuleRoot 'Microsoft-365-Access-Profiles.ps1'
            if (-not (Test-Path -LiteralPath $script)) {
                $script = Join-Path $script:ModuleRoot 'Microsoft 365 Access Profiles.ps1'
            }
            $pass = @{}
            if ($Wizard) { $pass['Wizard'] = $true }
            if ($NonInteractive) { $pass['NonInteractive'] = $true }
            if ($OutputDirectory) { $pass['OutputDirectory'] = $OutputDirectory }
            if ($hasExtra) { & $script @pass @RemainingArguments } else { & $script @pass }
        }
    }
    }
    catch {
        if (Test-PromptBack $_) {
            Write-Host ''
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
        throw
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
        [string]$OutputFormat,
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
        [ValidateSet('PrivateKey', 'OAuth')]
        [string]$Method,
        [string]$ClientId,
        [string]$ServiceAccountName,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [string]$Project,
        [switch]$ApplyPreconditionFix
    )
    $script = Join-Path $script:ModuleRoot 'Google-Cloud.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        $script = Join-Path $script:ModuleRoot 'Google Cloud.ps1'
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
    - Entro GitHub integration (App installation or PAT)

.PARAMETER Wizard
    Runs interactive guided questionnaire.

.PARAMETER Connector
    Targets the GitHub SaaS connector.

.PARAMETER Entro
    Targets the Entro GitHub integration.

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
#>
function Connect-SailPointGitHub {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Wizard,
        [switch]$Connector,
        [switch]$Entro,
        [ValidateSet('ReadOnly', 'ReadWrite')]
        [string]$Access,
        [ValidateSet('Run', 'BuildScript', 'BuildRequirements', 'Check')]
        [string]$Action,
        [string]$Organization,
        [string]$ApiUrl,
        [ValidateSet('PersonalAccessToken', 'GitHubApp')]
        [string]$AuthMethod,
        [string]$Token,
        [ValidateSet('AgentDiscovery', 'ActivityInsights')]
        [string[]]$Feature,
        [ValidateSet('GitHubApp', 'ClassicPAT')]
        [string]$Method,
        [string]$OutputDirectory,
        [switch]$NonInteractive,
        [string]$Project
    )
    $script = Join-Path $script:ModuleRoot 'GitHub.ps1'
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

# Aliases
Set-Alias -Name 'sailpoint-connect' -Value 'Invoke-SailPointConnect' -Description 'SailPoint Connect unified runner'
Set-Alias -Name 'Start-SailPointIQServiceControl' -Value 'Invoke-SailPointIQServiceControl' -Description 'Alias for Invoke-SailPointIQServiceControl'

Export-ModuleMember -Function @(
    'Invoke-SailPointConnect',
    'Connect-SailPointAWS',
    'Connect-SailPointAzure',
    'Connect-SailPointGoogleCloud',
    'Connect-SailPointDatabricks',
    'Connect-SailPointSalesforce',
    'Connect-SailPointGitHub',
    'Connect-SailPointCrowdStrike',
    'Invoke-SailPointIQServiceControl',
    'New-SailPointM365AccessProfile',
    'Get-SailPointConnectProject',
    'Set-SailPointConnectProject'
) -Alias @(
    'sailpoint-connect',
    'Start-SailPointIQServiceControl'
)
