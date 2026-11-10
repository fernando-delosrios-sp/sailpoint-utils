Set-StrictMode -Version Latest

function Get-GoogleContextFeatureNames {
    param($Value)
    $items = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Value) { return ,$items.ToArray() }
    foreach ($entry in @($Value)) {
        foreach ($part in ([string]$entry -split ',')) {
            $name = $part.Trim()
            if ($name) { $items.Add($name) }
        }
    }
    return ,$items.ToArray()
}

function Get-GoogleLegacyArguments {
    param(
        [Parameter(Mandatory)][ValidateSet('Saas', 'Ciem')]
        [string]$Mode,
        [Parameter(Mandatory)][hashtable]$Context
    )
    # Context is a hashtable of optional keys: indexer access (see Aws.Connector).
    # CIEM is the Workspace connector with the Gcp and Ciem packs. Mode selects those
    # packs; a SaaS run leaves Feature untouched so the operator can still choose none.
    $feature = $Context['Feature']
    if ($Mode -eq 'Ciem') {
        $names = [System.Collections.Generic.List[string]]::new()
        foreach ($required in @('Gcp', 'Ciem')) { $names.Add($required) }
        $extras = Get-GoogleContextFeatureNames $Context['Feature']
        foreach ($extra in $extras) {
            if (-not $names.Contains([string]$extra)) { $names.Add([string]$extra) }
        }
        $feature = $names.ToArray()
    }
    $parameters = @{
        GrantType       = if ($Context['GrantType']) { $Context['GrantType'] } else { 'ServiceAccount' }
        NonInteractive  = [bool]$Context['NonInteractive']
        RotateKey       = [bool]$Context['RotateKey']
    }
    foreach ($name in @('OrganizationId', 'ProjectId', 'ServiceAccountId', 'DisplayName', 'ImpersonateUser', 'OutputDirectory', 'Access')) {
        if (-not [string]::IsNullOrWhiteSpace([string]$Context[$name])) { $parameters[$name] = $Context[$name] }
    }
    if ($null -ne $feature) { $parameters.Feature = $feature }
    return $parameters
}

function Invoke-GoogleLegacyFromContext {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][ValidateSet('Saas', 'Ciem')]
        [string]$Mode,
        [Parameter(Mandatory)][hashtable]$Context
    )
    $impl = Join-Path $PSScriptRoot '../Legacy/GoogleCloud.Implementation.ps1'
    $splat = Get-GoogleLegacyArguments -Mode $Mode -Context $Context
    if ($Context['Access'] -eq 'ReadOnly') { $splat.AggregationOnly = $true }
    & $impl @splat -WhatIf:$WhatIfPreference
}

function Register-GoogleConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'google-saas-connector'
        Platform     = 'GoogleCloud'
        Product      = 'ISC'
        CoreSwitch   = 'SaaSConnector'
        CliName      = 'gcloud'
        Title        = 'Google Workspace connector'
        FolderName   = 'Google-Workspace'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Organization admin or project owner for IAM and service accounts')
        OutputsHelp  = 'Paste service account email, key, and admin email into ISC Connection Settings.'
        Inputs       = @(
            @{ Name = 'OrganizationId'; Source = 'Discover'; Prompt = 'Organization ID'; Purpose = 'Google Cloud organization'; Required = $true }
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'ImpersonateUser'; Source = 'Supply'; Prompt = 'Admin user to impersonate'; Purpose = 'Workspace domain-wide delegation'; Required = $true }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Keys and connection settings'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        BuildScript  = {
            param($c)
            $orgId = if ($c['OrganizationId']) { [string]$c['OrganizationId'] } else { '' }
            $projId = if ($c['ProjectId']) { [string]$c['ProjectId'] } else { 'YOUR_PROJECT_ID' }
            $user = if ($c['ImpersonateUser']) { [string]$c['ImpersonateUser'] } else { 'admin@yourdomain.com' }
            $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
            $saId = if ($c['ServiceAccountId']) { [string]$c['ServiceAccountId'] } else { 'sailpoint-isc-gws' }
            $saEmail = "$saId@$projId.iam.gserviceaccount.com"
            $displayName = if ($c['DisplayName']) { [string]$c['DisplayName'] } else { 'SailPoint ISC Google Workspace' }

            $scopes = if ($access -eq 'ReadOnly') {
                @('https://www.googleapis.com/auth/admin.directory.group.readonly', 'https://www.googleapis.com/auth/admin.directory.user.readonly', 'https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly')
            } else {
                @('https://www.googleapis.com/auth/admin.directory.group', 'https://www.googleapis.com/auth/admin.directory.user', 'https://www.googleapis.com/auth/apps.groups.settings', 'https://www.googleapis.com/auth/admin.directory.rolemanagement', 'https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly')
            }
            $scopeCsv = $scopes -join ','

            @"
# -----------------------------------------------------------------------------
# Google Workspace SaaS Connector Setup
# -----------------------------------------------------------------------------
`$projectId = '$projId'
`$serviceAccountId = '$saId'
`$serviceAccountEmail = '$saEmail'
`$displayName = '$displayName'
`$impersonateUser = '$user'
`$scopes = '$scopeCsv'
`$outputDir = if (`$OutputDirectory) { `$OutputDirectory } else { `$PSScriptRoot }

Write-Host "Configuring Google Cloud project: `$projectId" -ForegroundColor Cyan
& gcloud config set project `$projectId --quiet

Write-Host "Enabling Google Workspace APIs..." -ForegroundColor Cyan
& gcloud services enable admin.googleapis.com groupssettings.googleapis.com --project=`$projectId --quiet

Write-Host "Ensuring service account `$serviceAccountEmail..." -ForegroundColor Cyan
`$existingSa = & gcloud iam service-accounts list --project=`$projectId --filter="email=`$serviceAccountEmail" --format="value(email)" 2>`$null
if (-not `$existingSa) {
    Write-Host "Creating service account `$serviceAccountId..."
    & gcloud iam service-accounts create `$serviceAccountId --display-name="`$displayName" --description="SailPoint ISC Google Workspace SaaS connector" --project=`$projectId --quiet
} else {
    Write-Host "Service account `$serviceAccountEmail already exists."
}

`$uniqueId = (& gcloud iam service-accounts describe `$serviceAccountEmail --project=`$projectId --format="value(uniqueId)" 2>`$null).Trim()
Write-Host "Service Account Client ID: `$uniqueId" -ForegroundColor Green

# Generate service account key and convert to RSA PEM
`$keyPath = Join-Path `$outputDir 'sailpoint-gws-key.json'
`$pemPath = Join-Path `$outputDir 'sailpoint-gws-rsa.pem'
Write-Host "Creating service account key at `$keyPath..." -ForegroundColor Cyan
& gcloud iam service-accounts keys create `$keyPath --iam-account=`$serviceAccountEmail --project=`$projectId --quiet

if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-Host "Converting JSON private key to traditional encrypted RSA PEM..." -ForegroundColor Cyan
    `$keyJson = Get-Content -LiteralPath `$keyPath -Raw | ConvertFrom-Json
    `$pkcs8Path = Join-Path `$outputDir 'sailpoint-gws-temp.pkcs8'
    [System.IO.File]::WriteAllText(`$pkcs8Path, (`$keyJson.private_key -replace '\\n', "`n").Trim() + "`n")
    
    # Generate random passphrase
    `$passBytes = New-Object byte[] 24
    `$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    `$rng.GetBytes(`$passBytes)
    `$rng.Dispose()
    `$keyPassword = [Convert]::ToBase64String(`$passBytes)
    `$env:SP_GWS_PEM_PASS = `$keyPassword

    try {
        & openssl rsa -aes-256-cbc -in `$pkcs8Path -out `$pemPath -passout env:SP_GWS_PEM_PASS
        Write-Host "Generated RSA PEM at `$pemPath" -ForegroundColor Green
        Write-Host "Private Key Password: `$keyPassword" -ForegroundColor Yellow
    } finally {
        Remove-Item Env:SP_GWS_PEM_PASS -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath `$pkcs8Path -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host '========================================================================' -ForegroundColor Cyan
Write-Host 'Google Workspace Admin Console Action Required (Domain-Wide Delegation):' -ForegroundColor Yellow
Write-Host "1. Go to: https://admin.google.com -> Security -> Access and data control -> API controls"
Write-Host "2. Under 'Domain-wide delegation', click 'Manage Domain Wide Delegation' -> 'Add new'"
Write-Host "3. Client ID: `$uniqueId"
Write-Host "4. OAuth Scopes: `$scopes"
Write-Host "========================================================================" -ForegroundColor Cyan
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-GoogleLegacyFromContext -Mode 'Saas' -Context $ctx -WhatIf:$WhatIfPreference }
    }
    Register-IntegrationWizardDefinition @{
        Id           = 'google-ciem-connector'
        Platform     = 'GoogleCloud'
        Product      = 'ISC'
        CoreSwitch   = 'CiemConnector'
        CliName      = 'gcloud'
        Title        = 'GCP CIEM connector feature packs'
        FolderName   = 'GCP-CIEM'
        AccessLevels = @('ReadOnly', 'ReadWrite')
        AdminRoles   = @('Organization admin for custom org roles')
        OutputsHelp  = 'Enable CIEM/NHI packs in ISC using the GCP org role from connection settings.'
        Inputs       = @(
            @{ Name = 'OrganizationId'; Source = 'Discover'; Prompt = 'Organization ID'; Purpose = 'GCP organization'; Required = $true }
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'ImpersonateUser'; Source = 'Supply'; Prompt = 'Admin user to impersonate'; Purpose = 'Workspace domain-wide delegation'; Required = $true }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Extra feature packs (comma-separated)'; Purpose = 'Optional packs merged with Gcp and Ciem'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Artifacts'; Required = $false }
        )
        Steps        = { param($ctx) @() }
        BuildScript  = {
            param($c)
            $orgId = if ($c['OrganizationId']) { [string]$c['OrganizationId'] } else { 'YOUR_ORG_ID' }
            $projId = if ($c['ProjectId']) { [string]$c['ProjectId'] } else { 'YOUR_PROJECT_ID' }
            $user = if ($c['ImpersonateUser']) { [string]$c['ImpersonateUser'] } else { 'admin@yourdomain.com' }
            $access = if ($c['Access']) { [string]$c['Access'] } else { 'ReadOnly' }
            $saId = if ($c['ServiceAccountId']) { [string]$c['ServiceAccountId'] } else { 'sailpoint-isc-gws' }
            $saEmail = "$saId@$projId.iam.gserviceaccount.com"

            $features = @('Gcp', 'Ciem')
            if ($c['Feature']) {
                foreach ($f in ($c['Feature'] -split ',')) {
                    $trim = $f.Trim()
                    if ($trim -and -not ($features -contains $trim)) { $features += $trim }
                }
            }

            $perms = @(
                'cloudasset.assets.searchAllIamPolicies',
                'cloudasset.assets.searchAllResources',
                'iam.roles.get',
                'iam.roles.list',
                'iam.serviceAccounts.get',
                'iam.serviceAccounts.getIamPolicy',
                'iam.serviceAccounts.list',
                'logging.logEntries.list',
                'resourcemanager.folders.getIamPolicy',
                'resourcemanager.folders.list',
                'resourcemanager.organizations.get',
                'resourcemanager.organizations.getIamPolicy',
                'resourcemanager.projects.get',
                'resourcemanager.projects.getIamPolicy',
                'resourcemanager.projects.list'
            )
            if ($access -ne 'ReadOnly') {
                $perms += @(
                    'iam.roles.create',
                    'iam.roles.delete',
                    'iam.roles.update',
                    'iam.serviceAccounts.create',
                    'iam.serviceAccounts.setIamPolicy',
                    'resourcemanager.folders.setIamPolicy',
                    'resourcemanager.organizations.setIamPolicy',
                    'resourcemanager.projects.setIamPolicy'
                )
            }
            if ($features -contains 'AgentDiscovery') {
                $perms += @('aiplatform.agents.get', 'aiplatform.agents.list')
            }
            $permYamlList = ($perms | ForEach-Object { "- $_" }) -join "`n"

            @"
# -----------------------------------------------------------------------------
# Google Cloud CIEM Connector Setup
# -----------------------------------------------------------------------------
`$orgId = '$orgId'
`$projectId = '$projId'
`$serviceAccountEmail = '$saEmail'
`$impersonateUser = '$user'
`$customRoleTitle = 'SailPoint Google Workspace CIEM'
`$customRoleId = 'sailpointGoogleWorkspace'

Write-Host "Configuring Google Cloud project: `$projectId" -ForegroundColor Cyan
& gcloud config set project `$projectId --quiet

Write-Host "Enabling GCP & CIEM APIs..." -ForegroundColor Cyan
& gcloud services enable iam.googleapis.com cloudresourcemanager.googleapis.com cloudasset.googleapis.com logging.googleapis.com --project=`$projectId --quiet

# Create or update organization custom role
`$roleYaml = @(
    "title: `$customRoleTitle"
    "description: SailPoint Identity Security Cloud GCP CIEM custom role"
    "stage: GA"
    "includedPermissions:"
    "$permYamlList"
) -join "`n"

`$tempRoleFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path `$tempRoleFile -Value `$roleYaml -Encoding utf8

try {
    Write-Host "Checking organization custom role `$customRoleId..." -ForegroundColor Cyan
    `$roleExists = & gcloud iam roles describe `$customRoleId --organization=`$orgId 2>`$null
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "Updating custom role `$customRoleId at organization `$orgId..."
        & gcloud iam roles update `$customRoleId --organization=`$orgId --file=`$tempRoleFile --quiet
    } else {
        Write-Host "Creating custom role `$customRoleId at organization `$orgId..."
        & gcloud iam roles create `$customRoleId --organization=`$orgId --file=`$tempRoleFile --quiet
    }
} finally {
    Remove-Item -LiteralPath `$tempRoleFile -Force -ErrorAction SilentlyContinue
}

Write-Host "Binding custom role to service account and delegated admin user..." -ForegroundColor Cyan
& gcloud organizations add-iam-policy-binding `$orgId --member="serviceAccount:`$serviceAccountEmail" --role="organizations/`$orgId/roles/`$customRoleId" --quiet
& gcloud organizations add-iam-policy-binding `$orgId --member="user:`$impersonateUser" --role="organizations/`$orgId/roles/`$customRoleId" --quiet

Write-Host "CIEM organization IAM bindings applied successfully." -ForegroundColor Green
"@
        }
        LegacyRun    = { [CmdletBinding(SupportsShouldProcess = $true)] param($ctx) Invoke-GoogleLegacyFromContext -Mode 'Ciem' -Context $ctx -WhatIf:$WhatIfPreference }
    }
}

Export-ModuleMember -Function Register-GoogleConnectorDefinitions, Invoke-GoogleLegacyFromContext
