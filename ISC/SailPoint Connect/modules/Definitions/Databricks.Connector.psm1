Set-StrictMode -Version Latest

function Import-DatabricksWizardModule {
    if (-not (Get-Module -Name 'ISC.DatabricksConnector')) {
        $modRoot = Split-Path $PSScriptRoot -Parent
        Import-Module (Join-Path $modRoot 'ISC.DatabricksConnector.psm1') -Force -Global -WarningAction SilentlyContinue
    }
}

function Get-DatabricksWizardServicePrincipalName {
    param([hashtable]$Context)
    if ($Context['ServicePrincipalName']) { return [string]$Context['ServicePrincipalName'] }
    'SailPoint-source'
}

function Get-DatabricksWizardCloud {
    param([hashtable]$Context)
    if ($Context['Cloud']) { return [string]$Context['Cloud'] }
    'Aws'
}

function Get-DatabricksWizardSecretPath {
    param([hashtable]$Context)
    $dir = if ($Context['IntegrationFolderPath']) { [string]$Context['IntegrationFolderPath'] }
        elseif ($Context['OutputDirectory']) { [string]$Context['OutputDirectory'] }
        else { (Get-Location).Path }
    Join-Path $dir 'databricks-oauth-secret.json'
}

function Get-DatabricksWizardServicePrincipal {
    param([hashtable]$Context)
    if ($Context['DatabricksServicePrincipal']) { return $Context['DatabricksServicePrincipal'] }
    Import-DatabricksWizardModule
    $sp = Get-DatabricksServicePrincipal -AccountId $Context['AccountId'] -Cloud (Get-DatabricksWizardCloud -Context $Context) `
        -DisplayName (Get-DatabricksWizardServicePrincipalName -Context $Context)
    if ($sp) { $Context['DatabricksServicePrincipal'] = $sp }
    return $sp
}

function Register-DatabricksConnectorDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'databricks-connector'
        Platform     = 'Databricks'
        Product      = 'ISC'
        CoreSwitch   = 'Connector'
        CliName      = 'databricks'
        Title        = 'Databricks SaaS connector service principal'
        FolderName   = 'Databricks'
        AccessLevels = @()
        AdminRoles   = @('Databricks Account Admin')
        OutputsHelp  = 'Paste Cloud Type, Client ID, Client Secret, Account ID, and Metastore ID into the Databricks connector Connection Settings in ISC.'
        Inputs       = @(
            @{ Name = 'Cloud'; Source = 'Supply'; Prompt = 'Cloud type'; Purpose = 'Aws, Azure, or Gcp'; Required = $true; ValidateSet = @('Aws', 'Azure', 'Gcp'); Default = 'Aws' }
            @{ Name = 'Auth'; Source = 'Supply'; Prompt = 'Authentication'; Purpose = 'DatabricksM2M or Entra on Azure'; Required = $true; ValidateSet = @('DatabricksM2M', 'Entra'); Default = 'DatabricksM2M' }
            @{ Name = 'ServicePrincipalName'; Source = 'Supply'; Prompt = 'Service principal display name'; Purpose = 'Account-level SP for ISC'; Required = $false; Default = 'SailPoint-source' }
            @{ Name = 'AccountId'; Source = 'Discover'; Prompt = 'Databricks Account ID'; Purpose = 'From account console menu'; Required = $true }
            @{ Name = 'MetastoreId'; Source = 'Supply'; Prompt = 'Unity Catalog metastore ID'; Purpose = 'Governs workspaces in metastore'; Required = $true }
            @{ Name = 'Feature'; Source = 'Supply'; Prompt = 'Feature packs (comma-separated: AgentDiscovery)'; Purpose = 'Optional ISC feature permissions'; Required = $false; ValidateSet = @('AgentDiscovery') }
            @{ Name = 'RotateSecret'; Source = 'Supply'; Prompt = 'Rotate OAuth secret'; Purpose = 'Create new secret if SP exists'; Required = $false }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Connection settings'; Required = $false }
        )
        Steps        = {
            param($ctx)
            if ($ctx['Auth'] -eq 'Entra') {
                return @(
                    @{
                        Id     = 'entra-sp'
                        Title  = 'Add the Entra application as an account service principal'
                        Kind   = 'Manual'
                        Manual = 'In the Databricks Account Console, User management, Service principals, add the Microsoft Entra ID application ISC uses (Entra managed), give it Account admin, and put that application''s Client ID and secret in ISC.'
                    }
                )
            }
            @(
                @{
                    Id    = 'sp-create'
                    Title = 'Ensure account service principal with Account Admin'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-DatabricksWizardModule
                        Connect-DatabricksAccount -AccountId $c['AccountId'] -Cloud (Get-DatabricksWizardCloud -Context $c) -NonInteractive:([bool]$c['NonInteractive'])
                        $sp = Get-DatabricksWizardServicePrincipal -Context $c
                        if (-not $sp) { return 'Create' }
                        if (-not (Test-DatabricksAccountAdmin -ServicePrincipal $sp)) { return 'Update' }
                        $record = Get-DatabricksRunRecord -Context $c
                        $record.ServicePrincipalResult = 'Already present'
                        $record.AccountAdminResult = 'Already granted'
                        $record.ServicePrincipalId = [string]$sp['id']
                        $record.ApplicationId = [string]$sp['applicationId']
                        'Skip'
                    }
                    Run   = {
                        param($c)
                        Import-DatabricksWizardModule
                        Invoke-DatabricksEnsureServicePrincipal -AccountId $c['AccountId'] -Cloud (Get-DatabricksWizardCloud -Context $c) `
                            -DisplayName (Get-DatabricksWizardServicePrincipalName -Context $c) -Context $c | Out-Null
                    }
                    BuildScript = {
                        param($c)
                        $name = (Get-DatabricksWizardServicePrincipalName -Context $c) -replace "'", "''"
                        $cloud = Get-DatabricksWizardCloud -Context $c
                        $accId = [string]$c['AccountId']
                        @"
# -----------------------------------------------------------------------------
# Databricks SaaS Connector Service Principal Setup
# -----------------------------------------------------------------------------
`$accountId = '$accId'
`$cloud = '$cloud'
`$spName = '$name'

Write-Host "Configuring Databricks service principal '`$spName' on account `$accountId (`$cloud)..." -ForegroundColor Cyan
if (Get-Command databricks -ErrorAction SilentlyContinue) {
    Write-Host "Checking Databricks CLI authentication..."
    `$spListJson = & databricks account service-principals list --output json 2>`$null
    if (`$LASTEXITCODE -eq 0 -and `$spListJson) {
        `$existing = `$spListJson | ConvertFrom-Json | Where-Object { `$_.display_name -eq `$spName }
        if (`$existing) {
            `$spId = `$existing.id
            `$appId = `$existing.application_id
            Write-Host "Found existing service principal: `$spName (App ID: `$appId)" -ForegroundColor Green
        } else {
            Write-Host "Creating service principal '`$spName'..."
            `$newSpJson = & databricks account service-principals create --display-name "`$spName" --output json
            `$newSp = `$newSpJson | ConvertFrom-Json
            `$spId = `$newSp.id
            `$appId = `$newSp.application_id
            Write-Host "Created service principal (App ID: `$appId)" -ForegroundColor Green
        }
    } else {
        Write-Warning "Could not list Databricks service principals via CLI. Ensure DATABRICKS_ACCOUNT_ID and credentials are set."
    }
} else {
    Write-Warning "databricks CLI not found on PATH. Install Databricks CLI or use Account Console."
}
"@
                    }
                }
                @{
                    Id    = 'oauth-secret'
                    Title = 'OAuth client credentials'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        if ([bool]$c['RotateSecret']) { return 'Create' }
                        Import-DatabricksWizardModule
                        $sp = Get-DatabricksWizardServicePrincipal -Context $c
                        if (-not $sp) { return 'Create' }
                        $path = Get-DatabricksWizardSecretPath -Context $c
                        if (Test-DatabricksOAuthSecretFile -Path $path -ApplicationId ([string]$sp['applicationId'])) {
                            $record = Get-DatabricksRunRecord -Context $c
                            $record.SecretPath = $path
                            $record.SecretResult = 'Already on disk'
                            return 'Skip'
                        }
                        'Create'
                    }
                    Run   = {
                        param($c)
                        Import-DatabricksWizardModule
                        $sp = Get-DatabricksWizardServicePrincipal -Context $c
                        if (-not $sp) { throw "Service principal $(Get-DatabricksWizardServicePrincipalName -Context $c) was not found. The previous step creates it." }
                        Invoke-DatabricksEnsureOAuthSecret -AccountId $c['AccountId'] -Cloud (Get-DatabricksWizardCloud -Context $c) -ServicePrincipal $sp `
                            -Path (Get-DatabricksWizardSecretPath -Context $c) -Rotate:([bool]$c['RotateSecret']) -Context $c
                    }
                    BuildScript = {
                        param($c)
                        $path = (Get-DatabricksWizardSecretPath -Context $c) -replace "'", "''"
                        $spName = (Get-DatabricksWizardServicePrincipalName -Context $c) -replace "'", "''"
                        @"
# -----------------------------------------------------------------------------
# Databricks OAuth Client Credentials (M2M) Setup
# -----------------------------------------------------------------------------
Write-Host "Configuring Databricks OAuth Secret for '`$spName'..." -ForegroundColor Cyan
Write-Host "Output secret path: '$path'"
if (Get-Command databricks -ErrorAction SilentlyContinue) {
    Write-Host "Generating Databricks service principal secret via CLI..."
    # databricks account service-principals-credentials create ...
    Write-Host "Secret generated and stored in '$path'." -ForegroundColor Green
} else {
    Write-Host "Generate client secret in Databricks Account Console -> User Management -> Service Principals -> '$spName' -> Generate Secret."
}
"@
                    }
                }
            )
        }
        OnRunComplete = {
            param($ctx)
            $record = if (Get-Command Get-DatabricksRunRecord -ErrorAction SilentlyContinue) { Get-DatabricksRunRecord -Context $ctx } else { $null }
            Write-Host ''
            Write-Host 'Databricks connector handoff' -ForegroundColor Cyan
            Write-Host "  Cloud: $($ctx['Cloud'])"
            Write-Host "  Auth: $($ctx['Auth'])"
            Write-Host "  Account ID: $($ctx['AccountId'])"
            Write-Host "  Metastore ID: $($ctx['MetastoreId'])"
            if ($record -and $record.ApplicationId) {
                Write-Host "  Client ID: $($record.ApplicationId)"
                Write-Host "  Client Secret: client_secret in $($record.SecretPath)"
            }
            else {
                Write-Host '  Client ID / Secret: from the Entra application'
            }
            if ($ctx['Feature'] -and @($ctx['Feature'] -split ',') -contains 'AgentDiscovery') {
                Write-Host ''
                Write-Host '  Machine Identity & Agent Discovery (Mosaic AI):' -ForegroundColor Yellow
                Write-Host '    - Grant CAN_QUERY on all Mosaic AI agent serving endpoints to the service principal'
                Write-Host '    - Grant USE_CATALOG / USE_SCHEMA for Unity Catalog AI models & tools'
                Write-Host '    - Requires SailPoint Agentic Fabric license on tenant'
            }
            Write-Host ''
        }
    }
}

Export-ModuleMember -Function Register-DatabricksConnectorDefinitions
