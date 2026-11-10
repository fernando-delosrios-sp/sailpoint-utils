Set-StrictMode -Version Latest

function Import-EntroGcpWizardModules {
    $wizardRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $modRoot = Join-Path $wizardRoot 'modules'
    # -Global: the step Run blocks call these from a different scope, and ISC.EntroGcp
    # resolves Invoke-GCloud (exported by ISC.GoogleWorkspaceConnector) via Get-Command.
    # Every step calls this, so a loaded module is kept: re-importing would replace an Invoke-GCloud the caller already set up.
    if (-not (Get-Command Invoke-GCloud -ErrorAction SilentlyContinue)) {
        Import-Module (Join-Path $modRoot 'ISC.GoogleWorkspaceConnector.psm1') -Force -Global -WarningAction SilentlyContinue
        Initialize-GoogleWorkspaceConnectorData
    }
    if (-not (Get-Module -Name 'ISC.EntroGcp')) {
        Import-Module (Join-Path $modRoot 'ISC.EntroGcp.psm1') -Force -Global -WarningAction SilentlyContinue
    }
}

function Get-EntroGcpWizardReportPath {
    param([hashtable]$Context)
    $base = if ($Context['OutputDirectory']) { $Context['OutputDirectory'] } else { Get-Location }
    Join-Path $base 'entro-gcp-report.md'
}

function Get-EntroGcpServiceAccountName {
    param([hashtable]$Context)
    if ($Context['ServiceAccountName']) { return [string]$Context['ServiceAccountName'] }
    'entro-automatic-onboard'
}

function Get-EntroGcpWizardStateDirectory {
    param([hashtable]$Context)
    if ($Context['IntegrationFolderPath']) { return [string]$Context['IntegrationFolderPath'] }
    if ($Context['OutputDirectory']) { return [string]$Context['OutputDirectory'] }
    return (Get-Location).Path
}

function Get-EntroGcpServiceAccountKeyPath {
    param([hashtable]$Context)
    Join-Path (Get-EntroGcpWizardStateDirectory -Context $Context) 'entro-reader-key.json'
}

function Get-EntroGcpServiceAccountKeyStep {
    @{
        Id    = 'key'
        Title = 'Service account key'
        Kind  = 'Ensure'
        Probe = {
            param($c)
            Import-EntroGcpWizardModules
            $name = Get-EntroGcpServiceAccountName -Context $c
            $path = Get-EntroGcpServiceAccountKeyPath -Context $c
            $email = "$name@$($c['ProjectId']).iam.gserviceaccount.com"
            if (Test-EntroGcpServiceAccountKeyFile -Path $path -Email $email) {
                Invoke-EntroGcpEnsureServiceAccountKey -ProjectId $c['ProjectId'] -ServiceAccountName $name -KeyPath $path -Context $c
                'Skip'
            }
            else { 'Create' }
        }
        Run   = {
            param($c)
            Import-EntroGcpWizardModules
            $name = Get-EntroGcpServiceAccountName -Context $c
            return Invoke-EntroGcpEnsureServiceAccountKey -ProjectId $c['ProjectId'] -ServiceAccountName $name `
                -KeyPath (Get-EntroGcpServiceAccountKeyPath -Context $c) -Context $c
        }
        BuildScript = {
            param($c)
            $sa = Get-EntroGcpServiceAccountName -Context $c
            $keyPath = (Get-EntroGcpServiceAccountKeyPath -Context $c) -replace "'", "''"
            @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpEnsureServiceAccountKey -ProjectId '$($c['ProjectId'])' -ServiceAccountName '$sa' -KeyPath '$keyPath'
"@
        }
    }
}

function Get-EntroGcpOperatorHandoffStep {
    param([hashtable]$Context)
    $sa = Get-EntroGcpServiceAccountName -Context $Context
    $project = [string]$Context['ProjectId']
    $account = "$sa@$project.iam.gserviceaccount.com"
    if ($Context['Method'] -eq 'WorkloadIdentity') {
        return @{
            Id     = 'wif'
            Title  = 'Workload Identity handoff'
            Kind   = 'Manual'
            Manual = "Create the Workload Identity pool and provider Entro documents, then upload the WIF JSON and the organization domain in Entro GCP onboarding. This run does not create a private key for $account."
        }
    }
    $keyPath = Get-EntroGcpServiceAccountKeyPath -Context $Context
    return @{
        Id     = 'entro-upload'
        Title  = 'Upload the key in Entro'
        Kind   = 'Manual'
        Manual = "Upload '$keyPath' and the organization domain in Entro GCP onboarding."
        When   = {
            param($c)
            if (-not (Get-Command Get-EntroGcpRunRecord -ErrorAction SilentlyContinue)) { return $true }
            $record = Get-EntroGcpRunRecord -Context $c
            return [string]$record.KeyResult -ne 'Blocked by organization policy'
        }
    }
}

function Register-GoogleEntroDefinitions {
    Register-IntegrationWizardDefinition @{
        Id           = 'google-gcp-entro'
        Platform     = 'GoogleCloud'
        Product      = 'Entro'
        CoreSwitch   = 'GcpEntro'
        CliName      = 'gcloud'
        Title        = 'Entro Google GCP organization integration'
        FolderName   = 'Entro-GCP'
        AccessLevels = @()
        AdminRoles   = @('Organization admin')
        OutputsHelp  = 'Upload private key JSON or WIF JSON and organization domain in Entro GCP onboarding.'
        Inputs       = @(
            @{ Name = 'OrganizationId'; Source = 'Discover'; Prompt = 'Organization ID'; Purpose = 'Google Cloud organization'; Required = $true }
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Host project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'Method'; Source = 'Supply'; Prompt = 'Auth method'; Purpose = 'PrivateKey or WorkloadIdentity'; Required = $true; ValidateSet = @('PrivateKey', 'WorkloadIdentity'); Default = 'PrivateKey' }
            @{ Name = 'ServiceAccountName'; Source = 'Supply'; Prompt = 'Service account name'; Purpose = 'Entro SA id'; Required = $false; Default = 'entro-automatic-onboard' }
        )
        CheckInputs  = @(
            @{ Name = 'ProjectId'; Source = 'Discover'; Prompt = 'Host project ID'; Purpose = 'Host project'; Required = $true }
            @{ Name = 'ServiceAccountName'; Source = 'Supply'; Prompt = 'Service account name'; Purpose = 'Entro SA id to verify'; Required = $false; Default = 'entro-automatic-onboard' }
            @{ Name = 'OutputDirectory'; Source = 'Supply'; Prompt = 'Output directory'; Purpose = 'Wizard output directory'; Required = $false }
        )
        Steps        = {
            param($ctx)
            $keyStep = if ($ctx['Method'] -eq 'WorkloadIdentity') { $null } else { Get-EntroGcpServiceAccountKeyStep }
            $all = @(
                @{
                    Id    = 'precheck'
                    Title = 'Pre-onboarding check'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        Import-EntroGcpWizardModules
                        Invoke-EntroGcpPreOnboardingCheck -ReportPath (Get-EntroGcpWizardReportPath -Context $c) -Context $c
                    }
                    BuildScript = {
                        param($c)
                        $report = Get-EntroGcpWizardReportPath -Context $c
                        @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpPreOnboardingCheck -ReportPath '$($report -replace "'", "''")'
"@
                    }
                }
                @{
                    Id    = 'apis'
                    Title = 'Enable APIs'
                    Kind  = 'Ensure'
                    Run   = {
                        param($c)
                        Import-EntroGcpWizardModules
                        Invoke-EntroGcpEnableApis -OrganizationId $c['OrganizationId'] -ProjectId $c['ProjectId'] -Mode 'apply' -Context $c
                        Invoke-EntroGcpEnableApis -OrganizationId $c['OrganizationId'] -ProjectId $c['ProjectId'] -Mode 'verify' -Context $c
                    }
                    BuildScript = {
                        param($c)
                        @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpEnableApis -OrganizationId '$($c['OrganizationId'])' -ProjectId '$($c['ProjectId'])' -Mode apply
Invoke-EntroGcpEnableApis -OrganizationId '$($c['OrganizationId'])' -ProjectId '$($c['ProjectId'])' -Mode verify
"@
                    }
                }
                @{
                    Id    = 'sa-create'
                    Title = 'Create Entro reader service account'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-EntroGcpWizardModules
                        $name = Get-EntroGcpServiceAccountName -Context $c
                        if (Test-EntroGcpServiceAccountExists -ProjectId $c['ProjectId'] -ServiceAccountName $name) {
                            Invoke-EntroGcpEnsureServiceAccount -ProjectId $c['ProjectId'] -ServiceAccountName $name -Context $c
                            'Skip'
                        }
                        else { 'Create' }
                    }
                    Run   = {
                        param($c)
                        Import-EntroGcpWizardModules
                        Invoke-EntroGcpEnsureServiceAccount -ProjectId $c['ProjectId'] -ServiceAccountName (Get-EntroGcpServiceAccountName -Context $c) `
                            -StateDirectory (Get-EntroGcpWizardStateDirectory -Context $c) -Context $c
                    }
                    BuildScript = {
                        param($c)
                        $sa = Get-EntroGcpServiceAccountName -Context $c
                        @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpEnsureServiceAccount -ProjectId '$($c['ProjectId'])' -ServiceAccountName '$sa'
"@
                    }
                }
                @{
                    Id    = 'iam'
                    Title = 'IAM grants'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-EntroGcpWizardModules
                        $sa = Get-EntroGcpServiceAccountName -Context $c
                        if (Test-EntroGcpIamGrantsComplete -OrganizationId $c['OrganizationId'] -ProjectId $c['ProjectId'] -ServiceAccountName $sa) {
                            Sync-EntroGcpIamReport -OrganizationId $c['OrganizationId'] -ProjectId $c['ProjectId'] `
                                -ServiceAccountName $sa -StateDirectory (Get-EntroGcpWizardStateDirectory -Context $c) -Context $c
                            'Skip'
                        }
                        else { 'Apply' }
                    }
                    Run   = {
                        param($c)
                        Import-EntroGcpWizardModules
                        $sa = Get-EntroGcpServiceAccountName -Context $c
                        Invoke-EntroGcpIamGrants -OrganizationId $c['OrganizationId'] -ProjectId $c['ProjectId'] `
                            -ServiceAccountName $sa -StateDirectory (Get-EntroGcpWizardStateDirectory -Context $c) -Context $c -Mode 'apply'
                    }
                    BuildScript = {
                        param($c)
                        $sa = Get-EntroGcpServiceAccountName -Context $c
                        $stateDir = (Get-EntroGcpWizardStateDirectory -Context $c) -replace "'", "''"
                        @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpIamGrants -OrganizationId '$($c['OrganizationId'])' -ProjectId '$($c['ProjectId'])' -ServiceAccountName '$sa' -StateDirectory '$stateDir' -Mode apply
"@
                    }
                }
                $keyStep
                (Get-EntroGcpOperatorHandoffStep -Context $ctx)
                @{
                    Id    = 'audit'
                    Title = 'Org audit logs'
                    Kind  = 'Ensure'
                    Probe = {
                        param($c)
                        Import-EntroGcpWizardModules
                        if (Test-EntroGcpAuditConfigsComplete -OrganizationId $c['OrganizationId']) {
                            $record = Get-EntroGcpRunRecord -Context $c
                            if ($record) { $record.AuditResult = 'Already in place' }
                            'Skip'
                        }
                        else { 'Apply' }
                    }
                    Run   = {
                        param($c)
                        Import-EntroGcpWizardModules
                        Invoke-EntroGcpAuditConfigs -OrganizationId $c['OrganizationId'] -Context $c
                    }
                    BuildScript = {
                        param($c)
                        @"
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.GoogleWorkspaceConnector.psm1') -Force
Import-Module (Join-Path `$PSScriptRoot 'modules/ISC.EntroGcp.psm1') -Force
Initialize-GoogleWorkspaceConnectorData
Invoke-EntroGcpAuditConfigs -OrganizationId '$($c['OrganizationId'])'
"@
                    }
                }
            )
            $kept = [System.Collections.Generic.List[object]]::new()
            foreach ($item in $all) {
                if ($null -ne $item) { $kept.Add($item) }
            }
            return @($kept)
        }
        OnRunComplete = {
            param($ctx)
            Import-EntroGcpWizardModules
            $record = Get-EntroGcpRunRecord -Context $ctx
            $record.Finished = $true
            if ($ctx['Method']) { $record.Method = [string]$ctx['Method'] }
            if (-not $record.OrganizationId -and $ctx['OrganizationId']) { $record.OrganizationId = [string]$ctx['OrganizationId'] }
            if (-not $record.ProjectId -and $ctx['ProjectId']) { $record.ProjectId = [string]$ctx['ProjectId'] }
            $sa = Get-EntroGcpServiceAccountName -Context $ctx
            if (-not $record.ServiceAccountEmail -and $ctx['ProjectId']) {
                $record.ServiceAccountEmail = "$sa@$($ctx['ProjectId']).iam.gserviceaccount.com"
            }
            $pending = @()
            $platform = if ($ctx['IntegrationPlatformTitle']) { [string]$ctx['IntegrationPlatformTitle'] } else { 'Google Cloud' }
            $section = "$platform / Entro GCP"
            if (-not (Get-Command Save-IntegrationProjectOperatorAction -ErrorAction SilentlyContinue)) {
                Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'IW.Project.psm1') -WarningAction SilentlyContinue
            }
            $blockedActions = [System.Collections.Generic.List[hashtable]]::new()
            if ($record.KeyGuidance) {
                $blockedActions.Add(@{
                    Section = $section
                    Id      = 'key-policy'
                    Title   = 'Allow the service account key'
                    Detail  = 'Google returned FAILED_PRECONDITION. Follow "How to clear this precondition" in entro-gcp-report.md, rerun the wizard, then upload the key file and the organization domain in Entro.'
                    Done    = $false
                })
            }
            foreach ($item in @($record.Blocked)) {
                $blockedActions.Add(@{ Section = $section; Id = [string]$item.Id; Title = [string]$item.Title; Detail = [string]$item.Detail; Done = $false })
            }
            if ($ctx['IntegrationProjectName'] -and (Get-Command Save-IntegrationProjectOperatorAction -ErrorAction SilentlyContinue)) {
                foreach ($action in $blockedActions) {
                    Save-IntegrationProjectOperatorAction -ProjectName ([string]$ctx['IntegrationProjectName']) -Action $action
                }
            }
            if ($ctx['IntegrationProjectName'] -and (Get-Command Read-IntegrationProjectOperatorActions -ErrorAction SilentlyContinue)) {
                $pending = @(Read-IntegrationProjectOperatorActions -ProjectName ([string]$ctx['IntegrationProjectName']) | Where-Object { $_.Section -eq $section })
            }
            if ($pending.Count -eq 0) {
                $pending = @($blockedActions)
                if (-not $record.KeyGuidance) {
                    $handoff = Get-EntroGcpOperatorHandoffStep -Context $ctx
                    $pending = @(@{ Title = $handoff.Title; Detail = $handoff.Manual; Done = $false }) + $pending
                }
            }
            Write-EntroGcpRunReport -Context $ctx -Path (Get-EntroGcpWizardReportPath -Context $ctx) -Pending $pending
        }
    }
    Register-IntegrationWizardDefinition @{
        Id           = 'google-workspace-entro'
        Platform     = 'GoogleCloud'
        Product      = 'Entro'
        CoreSwitch   = 'WorkspaceEntro'
        CliName      = 'gcloud'
        Title        = 'Entro Google Workspace integration'
        FolderName   = 'Entro-Workspace'
        AccessLevels = @()
        AdminRoles   = @('Google Workspace super admin for domain-wide delegation')
        OutputsHelp  = 'Paste Client ID and service account key JSON in Entro Workspace onboarding.'
        Inputs       = @(
            @{ Name = 'ClientId'; Source = 'Supply'; Prompt = 'OAuth client ID'; Purpose = 'Workspace admin console'; Required = $true }
        )
        Steps        = {
            param($ctx)
            @(
                @{
                    Id     = 'dwd'
                    Title  = 'Domain-wide delegation'
                    Kind   = 'Manual'
                    Manual = 'In Google Workspace Admin → Security → API controls, authorize the service account Client ID with Drive scopes documented by Entro.'
                }
            )
        }
    }
}

Export-ModuleMember -Function Register-GoogleEntroDefinitions
