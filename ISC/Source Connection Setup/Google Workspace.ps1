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
    [string[]]$GcpRegions,

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

$script:ModuleRoot = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $script:ModuleRoot 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.OperatorToolchain.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.GoogleWorkspaceConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.GoogleCiemConnector.psm1') -Force
Import-IscModule -Path (Join-Path $script:ModuleRoot 'ISC.GoogleSourceSetup.psm1') -Force
Initialize-OperatorConsole -NonInteractive:$NonInteractive
Initialize-GoogleSourceSetup -ModuleRoot $script:ModuleRoot -NonInteractive:$NonInteractive
Initialize-GoogleWorkspaceConnectorData -OpenSslPath $OpenSslPath
$catalog = Get-GoogleWorkspaceCatalog



# -----------------------------------------------------------------------------
# Console helpers
# -----------------------------------------------------------------------------

function Write-Banner {
    Write-Host ''
    Write-Host '  SailPoint ISC  -  Google Workspace SaaS source connection setup' -ForegroundColor Cyan
    Write-Host '  Creates or updates the GCP service account used by the Google Workspace connector.' -ForegroundColor DarkCyan
    Write-Host ''
}

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
    $askGcpRegions = -not $PSBoundParameters.ContainsKey('GcpRegions')
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
                $null = Ensure-OpenSslCommand -OpenSslPath $OpenSslPath
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
                            -Options @('http://localhost:8088', $catalog.PlaygroundRedirect) `
                            -Labels @(
                                'http://localhost:8088 - this script catches the code automatically'
                                "$($catalog.PlaygroundRedirect) - documented flow, paste the code by hand"
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
                    $packNames = @($catalog.FeaturePacks.Keys)
                    $packLabels = @($packNames | ForEach-Object { $catalog.FeaturePacks[$_].Label })
                    $Feature = @(Read-MultiChoice -Prompt 'Optional feature packs (Enter for none)' -Options $packNames -Labels $packLabels)
                }
                Complete-WizardPrompt
            }
            $Feature = @($Feature | Where-Object { $_ })

            if (Enter-WizardPrompt) {
                if (@($Feature) -contains 'AgentDiscovery' -and $askGcpRegions) {
                    $regionInput = Read-InputString -Prompt 'GCP regions for Vertex AI agents (comma-separated)' `
                        -Default $(if ($GcpRegions -and $GcpRegions.Count) { $GcpRegions -join ', ' } else { 'us-central1' }) -Required
                    $GcpRegions = @($regionInput -split '[,\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                }
                Complete-WizardPrompt
            }

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
            if (@($Feature) -contains 'AgentDiscovery') {
                Write-Host "   GCP regions         : $(if ($GcpRegions -and $GcpRegions.Count) { $GcpRegions -join ', ' } else { '(not set)' })"
            }
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
            Set-GoogleCreatedServiceAccount -Email $saEmail
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
            foreach ($role in $catalog.NhiBuiltInRoles) {
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
    foreach ($checklistItem in @(Get-GoogleIscFeatureChecklist -FeatureNames $Feature `
            -OrganizationId $OrganizationId -GcpRegions $GcpRegions `
            -GrantType $(if ($isServiceAccount) { 'ServiceAccount' } else { 'ClientCredentials' }))) {
        $situation.Add("ISC: $checklistItem")
    }
    $ciemCtx = @{
        FeatureNames   = $Feature
        OrganizationId = $OrganizationId
    }
    Apply-EmbeddedCiemPrerequisites -Context $ciemCtx
    foreach ($entry in (Build-EmbeddedCiemConnectionSettings -Context $ciemCtx).GetEnumerator()) {
        $situation.Add("ISC: $($entry.Key) — $($entry.Value)")
    }

    $completionItems = [System.Collections.Generic.List[object]]::new()
    foreach ($name in $copyFields.Keys) {
        $completionItems.Add([PSCustomObject]@{
            Label = $name
            Value = [string]$copyFields[$name]
            Kind  = 'Copy'
            Mask  = (Test-ConnectionSettingIsSecret -Name $name)
        })
    }
    if (@($Feature) -contains 'AgentDiscovery' -and $OrganizationId) {
        $completionItems.Add([PSCustomObject]@{
            Label = 'Google Organization ID (Machine Identity Governance)'
            Value = $OrganizationId
            Kind  = 'Copy'
            Mask  = $false
        })
    }
    if (@($Feature) -contains 'AgentDiscovery' -and $GcpRegions -and $GcpRegions.Count -gt 0) {
        $completionItems.Add([PSCustomObject]@{
            Label = 'GCP Regions (Machine Identity Governance)'
            Value = ($GcpRegions -join ', ')
            Kind  = 'Copy'
            Mask  = $false
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
    if ($null -ne (Get-GoogleCreatedServiceAccount)) {
        Write-Warning "Service account $(Get-GoogleCreatedServiceAccount) was created before this failure. Re-run with the same project and service account ID to finish configuring it."
    }
    Write-Error $_
    exit 1
}
