#Requires -Version 5.1
Set-StrictMode -Version Latest

function Initialize-GoogleCiemConnectorData {
    $script:GcpScopes = @(
        @{ Value = 'https://www.googleapis.com/auth/cloud-platform'; Purpose = 'GCP resource and IAM access' }
        @{ Value = 'https://www.googleapis.com/auth/iam';            Purpose = 'GCP IAM API' }
    )

    $script:GcpFeaturePacks = [ordered]@{
        Gcp = @{
            Label = 'Google Cloud Platform (folders, projects, IAM inventory)'
            Apis  = @('iam.googleapis.com', 'cloudresourcemanager.googleapis.com', 'cloudasset.googleapis.com')
        }
        Ciem = @{
            Label = 'CIEM cloud governance (requires a CIEM license)'
            Apis  = @('iam.googleapis.com', 'cloudresourcemanager.googleapis.com', 'cloudasset.googleapis.com', 'logging.googleapis.com')
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
            Label = 'Machine identity governance - GCP Vertex AI agents'
            Apis  = @('aiplatform.googleapis.com', 'cloudasset.googleapis.com', 'iam.googleapis.com')
        }
    }

    $script:EmbeddedCiemFeaturePack = $script:GcpFeaturePacks.Ciem

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
    $script:GcpPackNames = @('Gcp', 'Ciem', 'NhiDiscovery', 'AgentDiscovery')
}

function Test-EmbeddedCiemSelected {
    param([string[]]$FeatureNames)
    return @($FeatureNames) -contains 'Ciem'
}

function Get-EmbeddedCiemFeaturePack {
    return $script:EmbeddedCiemFeaturePack
}

function Test-NeedsGcp {
    param([string[]]$FeatureNames)
    foreach ($name in @($FeatureNames)) {
        if ($script:GcpPackNames -contains $name) { return $true }
    }
    return $false
}

function Get-GoogleCiemFeaturePacks {
    return $script:GcpFeaturePacks
}

function Get-GoogleCiemCatalog {
    return [PSCustomObject]@{
        GcpScopes       = $script:GcpScopes
        NhiBuiltInRoles = $script:NhiBuiltInRoles
        CustomRoleId    = $script:CustomRoleId
    }
}

function Get-GoogleCiemApis {
    param([string[]]$FeatureNames)

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @($FeatureNames)) {
        if (-not $script:GcpFeaturePacks.Contains($name)) { continue }
        foreach ($api in @($script:GcpFeaturePacks[$name].Apis)) {
            if ($api -and -not $values.Contains($api)) { $values.Add($api) }
        }
    }
    return $values.ToArray()
}

function Get-GoogleCiemScopes {
    param([string[]]$FeatureNames)

    if (-not (Test-NeedsGcp -FeatureNames $FeatureNames)) { return @() }
    return @($script:GcpScopes | ForEach-Object { $_.Value })
}

function Get-GoogleCustomRolePermissions {
    param(
        [string[]]$FeatureNames,
        [switch]$SkipGcpWrite
    )

    if (-not (Test-NeedsGcp -FeatureNames $FeatureNames)) { return @() }

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

function Apply-EmbeddedCiemPrerequisites {
    param($Context)
    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) { return }
    if (-not $Context.OrganizationId) {
        throw 'Embedded CIEM (-Feature Ciem) requires a GCP organization ID.'
    }
    Write-Verbose 'Google embedded CIEM: org custom role and logging API are applied by the orchestrator.'
}

function Build-EmbeddedCiemConnectionSettings {
    param($Context)
    if (-not (Test-EmbeddedCiemSelected -FeatureNames $Context.FeatureNames)) {
        return [ordered]@{}
    }
    $fields = [ordered]@{
        'Enable CIEM on SaaS source' = 'Grant Type must remain Service Account; enable CIEM in ISC after setup'
    }
    if ($Context.OrganizationId) {
        $fields['Google Organization ID (CIEM)'] = [string]$Context.OrganizationId
    }
    return $fields
}

function Get-GoogleIscFeatureChecklist {
    param(
        [string[]]$FeatureNames,
        [string]$OrganizationId,
        [string[]]$GcpRegions,
        [string]$GrantType
    )

    $items = [System.Collections.Generic.List[string]]::new()
    if (@($FeatureNames) -contains 'ActivityInsights') {
        $items.Add('Enable Activity Insights on the source (Service Account grant + domain-wide delegation scopes).')
    }
    if (@($FeatureNames) -contains 'AgentDiscovery') {
        $items.Add('Machine Identity Governance: enable GCP Vertex AI Agents.')
        if ($OrganizationId) {
            $items.Add("Google Organization ID: $OrganizationId")
        }
        if ($GcpRegions -and $GcpRegions.Count -gt 0) {
            $items.Add("GCP Regions: $($GcpRegions -join ', ')")
        }
        else {
            $items.Add('GCP Regions: add at least one region (for example us-central1) in Machine Identity Governance Settings.')
        }
    }
    if (Test-EmbeddedCiemSelected -FeatureNames $FeatureNames) {
        $items.Add('Enable Cloud Infrastructure Entitlement Management (CIEM) on the Google Workspace SaaS source.')
        if ($GrantType -ne 'ServiceAccount') {
            $items.Add('CIEM requires Grant Type Service Account — re-run with Service Account grant type.')
        }
    }
    if (@($FeatureNames) -contains 'NhiDiscovery') {
        $items.Add('NHI Discovery requires SailPoint Agentic Fabric license.')
    }
    return @($items)
}

Export-ModuleMember -Function @(
    'Initialize-GoogleCiemConnectorData'
    'Test-EmbeddedCiemSelected'
    'Get-EmbeddedCiemFeaturePack'
    'Test-NeedsGcp'
    'Get-GoogleCiemFeaturePacks'
    'Get-GoogleCiemCatalog'
    'Get-GoogleCiemApis'
    'Get-GoogleCiemScopes'
    'Get-GoogleCustomRolePermissions'
    'Apply-EmbeddedCiemPrerequisites'
    'Build-EmbeddedCiemConnectionSettings'
    'Get-GoogleIscFeatureChecklist'
)
