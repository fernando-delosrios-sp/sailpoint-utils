#Requires -Version 5.1
Set-StrictMode -Version Latest

function Import-SourceSetupModule {
    param(
        [Parameter(Mandatory)][string]$ModuleRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FileName
    )

    if (-not (Get-Module -Name $Name)) {
        Import-Module (Join-Path $ModuleRoot $FileName) -Force -Global -WarningAction SilentlyContinue
    }
}

function Import-AgentAdapterModule {
    if (-not (Get-Module -Name 'ISC.AgentAdapter')) {
        Import-Module (Join-Path $PSScriptRoot 'ISC.AgentAdapter.psm1') -Force -WarningAction SilentlyContinue
    }
}

function Initialize-GoogleSourceSetup {
    param(
        [string]$ModuleRoot,
        [switch]$NonInteractive
    )

    if (-not $ModuleRoot) { $ModuleRoot = $PSScriptRoot }
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorConsole' -FileName 'ISC.OperatorConsole.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.OperatorToolchain' -FileName 'ISC.OperatorToolchain.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.GoogleWorkspaceConnector' -FileName 'ISC.GoogleWorkspaceConnector.psm1'
    Import-SourceSetupModule -ModuleRoot $ModuleRoot -Name 'ISC.GoogleCiemConnector' -FileName 'ISC.GoogleCiemConnector.psm1'
    Initialize-OperatorConsole -NonInteractive:$NonInteractive
    Initialize-GoogleWorkspaceConnectorData
    Initialize-GoogleCiemConnectorData
}

function Get-GoogleAgentCatalog {
    Initialize-GoogleSourceSetup
    $catalog = Get-GoogleWorkspaceCatalog
    return [ordered]@{
        grantTypes     = @('ServiceAccount', 'ClientCredentials')
        featurePacks   = @($catalog.FeaturePacks.Keys)
        requiredConfig = @('projectId')
        optionalConfig = @('grantType', 'organizationId', 'impersonateUser', 'features', 'rotateKey', 'outputDirectory')
        secretFields   = @('clientSecret', 'refreshToken', 'privateKey', 'privateKeyPassword')
        manualSteps    = @('domainWideDelegation', 'oauthClientCreation')
    }
}

function Get-GoogleResolvedConfig {
    param([Parameter(Mandatory)]$Request)

    Import-AgentAdapterModule
    $config = Get-AgentRequestValue -Object $Request -Name 'config' -Default @{}
    $decisions = Get-AgentRequestValue -Object $Request -Name 'decisions' -Default @{}
    $secretRefs = Get-AgentRequestValue -Object $Request -Name 'secretRefs' -Default @{}
    $outputDir = if (Get-AgentRequestValue -Object $config -Name 'outputDirectory') { [string](Get-AgentRequestValue -Object $config -Name 'outputDirectory') } else { (Join-Path (Get-Location) (Join-Path 'sourceConfig' 'google-workspace-isc')) }

    return [PSCustomObject]@{
        GrantType                    = if (Get-AgentRequestValue -Object $config -Name 'grantType') { [string](Get-AgentRequestValue -Object $config -Name 'grantType') } else { 'ServiceAccount' }
        OrganizationId               = $(if (Get-AgentRequestValue -Object $config -Name 'organizationId') { [string](Get-AgentRequestValue -Object $config -Name 'organizationId') } else { $null })
        ProjectId                    = [string](Get-AgentRequestValue -Object $config -Name 'projectId')
        ServiceAccountId             = if (Get-AgentRequestValue -Object $config -Name 'serviceAccountId') { [string](Get-AgentRequestValue -Object $config -Name 'serviceAccountId') } else { 'sailpoint-isc-gws' }
        DisplayName                  = if (Get-AgentRequestValue -Object $config -Name 'displayName') { [string](Get-AgentRequestValue -Object $config -Name 'displayName') } else { 'SailPoint ISC Google Workspace' }
        ImpersonateUser              = $(if (Get-AgentRequestValue -Object $config -Name 'impersonateUser') { [string](Get-AgentRequestValue -Object $config -Name 'impersonateUser') } else { $null })
        Feature                      = @($(Get-AgentRequestValue -Object $config -Name 'features' -Default @()))
        AggregationOnly              = [bool](Get-AgentRequestValue -Object $config -Name 'aggregationOnly' -Default $false)
        RotateKey                    = $(if ($null -ne (Get-AgentRequestValue -Object $config -Name 'rotateKey')) { [bool](Get-AgentRequestValue -Object $config -Name 'rotateKey') } else { $true })
        OutputDirectory              = $outputDir
        ClientId                     = $(if (Get-AgentRequestValue -Object $config -Name 'clientId') { [string](Get-AgentRequestValue -Object $config -Name 'clientId') } else { $null })
        ClientSecretRef              = $(if (Get-AgentRequestValue -Object $secretRefs -Name 'clientSecret') { [string](Get-AgentRequestValue -Object $secretRefs -Name 'clientSecret') } else { $null })
        RefreshTokenRef              = $(if (Get-AgentRequestValue -Object $secretRefs -Name 'refreshToken') { [string](Get-AgentRequestValue -Object $secretRefs -Name 'refreshToken') } else { $null })
        KeyPasswordRef               = $(if (Get-AgentRequestValue -Object $secretRefs -Name 'keyPassword') { [string](Get-AgentRequestValue -Object $secretRefs -Name 'keyPassword') } else { $null })
        SkipDomainWideDelegation     = [bool](Get-AgentRequestValue -Object $config -Name 'skipDomainWideDelegationWalkthrough' -Default $false)
        UpdateExistingServiceAccount = $(if ($null -ne (Get-AgentRequestValue -Object $decisions -Name 'updateExistingServiceAccount')) { [bool](Get-AgentRequestValue -Object $decisions -Name 'updateExistingServiceAccount') } else { $null })
    }
}

function New-GoogleAgentPlan {
    param([Parameter(Mandatory)]$Request)

    Initialize-GoogleSourceSetup
    $resolved = Get-GoogleResolvedConfig -Request $Request
    $needsInput = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $manualSteps = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($resolved.ProjectId)) {
        $needsInput.Add([ordered]@{ field = 'projectId'; reason = 'GCP project ID is required.' })
    }
    if ($resolved.GrantType -eq 'ServiceAccount' -and [string]::IsNullOrWhiteSpace($resolved.ImpersonateUser)) {
        $needsInput.Add([ordered]@{ field = 'impersonateUser'; reason = 'Service Account grant type requires impersonate user email.' })
    }
    if ($resolved.GrantType -eq 'ClientCredentials') {
        if (-not $resolved.ClientId) {
            $needsInput.Add([ordered]@{ field = 'clientId'; reason = 'Client Credentials grant type requires OAuth client ID.' })
        }
        if (-not $resolved.ClientSecretRef) {
            $needsInput.Add([ordered]@{ field = 'secretRefs.clientSecret'; reason = 'Provide client secret via env: or file: reference.' })
        }
    }
    if ((Test-NeedsGcp -FeatureNames $resolved.Feature) -and [string]::IsNullOrWhiteSpace($resolved.OrganizationId)) {
        $needsInput.Add([ordered]@{ field = 'organizationId'; reason = 'GCP/CIEM feature packs require organization ID.' })
    }

    $manualSteps.Add('Complete domain-wide delegation in Google Admin console when using Service Account grant type.')
    if ($resolved.GrantType -eq 'ClientCredentials' -and -not $resolved.RefreshTokenRef) {
        $manualSteps.Add('Run OAuth authorization flow or supply refresh token via secret reference.')
    }

    return [ordered]@{
        status      = if ($needsInput.Count -gt 0) { 'needsInput' } else { 'ready' }
        requestHash = (Get-AgentRequestHash -Request $Request)
        resolved    = $resolved
        discoveries = [ordered]@{}
        mutations   = @('connect-gcloud', 'enable-apis', 'configure-service-account-or-oauth')
        prerequisites = @('Google Cloud SDK (gcloud)', 'Organization/project permissions')
        warnings    = @($warnings)
        manualSteps = @($manualSteps)
        needsInput  = @($needsInput)
    }
}

function Invoke-GoogleAgentApply {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Plan,
        [switch]$WhatIf
    )

    Initialize-GoogleSourceSetup
    $resolved = Get-GoogleResolvedConfig -Request $Request
    if ($Plan.resolved) {
        foreach ($prop in $Plan.resolved.PSObject.Properties) {
            $resolved.$($prop.Name) = $prop.Value
        }
    }

    if ($WhatIf) {
        return [ordered]@{ status = 'whatIf'; grantType = $resolved.GrantType; projectId = $resolved.ProjectId }
    }

    $run = New-AgentRunDirectory -ConnectorSlug 'google-workspace-isc' -RunId (Get-AgentRequestValue -Object $Request -Name 'runId')
    $account = Connect-GoogleCloud -ProjectId $resolved.ProjectId
    $apis = @(Get-SelectedApis -FeatureNames $resolved.Feature)
    if ($apis.Count -gt 0) {
        Invoke-GCloud -GcloudArgs @('services', 'enable') + $apis + @('--project', $resolved.ProjectId, '--quiet')
    }

    $fields = [ordered]@{}
    $secretArtifacts = @()

    if ($resolved.GrantType -eq 'ServiceAccount') {
        $email = Get-ServiceAccountEmail -ProjectId $resolved.ProjectId -ServiceAccountId $resolved.ServiceAccountId
        $existing = Get-ExistingServiceAccount -Email $email
        if (-not $existing) {
            Invoke-GCloud -GcloudArgs @(
                'iam', 'service-accounts', 'create', $resolved.ServiceAccountId,
                '--project', $resolved.ProjectId,
                '--display-name', $resolved.DisplayName
            )
        }
        Set-GoogleCreatedServiceAccount -Email $email

        if ($resolved.RotateKey) {
            $jsonPath = Join-Path $resolved.OutputDirectory 'sailpoint-gws-key.json'
            $pemPath = Join-Path $resolved.OutputDirectory 'sailpoint-gws-rsa.pem'
            if (-not (Test-Path -LiteralPath $resolved.OutputDirectory)) {
                New-Item -ItemType Directory -Path $resolved.OutputDirectory -Force | Out-Null
            }
            Invoke-GCloud -GcloudArgs @('iam', 'service-accounts', 'keys', 'create', '--iam-account', $email, '--key-file-type', 'json', '--key-file', $jsonPath, '--quiet')
            $keyPassword = if ($resolved.KeyPasswordRef) { Resolve-AgentSecretReference -Reference $resolved.KeyPasswordRef } else { New-KeyPassword }
            $null = ConvertTo-EncryptedRsaPem -JsonKeyPath $jsonPath -PemPath $pemPath -Passphrase $keyPassword
            Set-AgentRestrictedFile -Path (Join-Path $run.Path 'private-key-password.txt') -Content $keyPassword
            $secretArtifacts += @(
                [ordered]@{ label = 'JSON key'; path = $jsonPath }
                [ordered]@{ label = 'Private Key Password'; path = (Join-Path $run.Path 'private-key-password.txt') }
            )
            $fields['Grant Type'] = 'Service Account'
            $fields['Service Account Email'] = $email
            $fields['Impersonate User'] = $resolved.ImpersonateUser
            $fields['Private Key'] = (Get-Content -LiteralPath $pemPath -Raw)
            $fields['Private Key Password'] = $keyPassword
        }
        else {
            $fields['Grant Type'] = 'Service Account'
            $fields['Service Account Email'] = $email
            $fields['Impersonate User'] = $resolved.ImpersonateUser
        }
    }
    else {
        $clientSecret = Resolve-AgentSecretReference -Reference $resolved.ClientSecretRef
        $refreshToken = if ($resolved.RefreshTokenRef) {
            Resolve-AgentSecretReference -Reference $resolved.RefreshTokenRef
        } else {
            Get-GoogleRefreshToken -OAuthClientId $resolved.ClientId -OAuthClientSecret $clientSecret -RedirectUri 'http://localhost:8088'
        }
        Set-AgentRestrictedFile -Path (Join-Path $run.Path 'client-secret.txt') -Content $clientSecret
        Set-AgentRestrictedFile -Path (Join-Path $run.Path 'refresh-token.txt') -Content $refreshToken
        $secretArtifacts += @(
            [ordered]@{ label = 'Client Secret'; path = (Join-Path $run.Path 'client-secret.txt') }
            [ordered]@{ label = 'Refresh Token'; path = (Join-Path $run.Path 'refresh-token.txt') }
        )
        $fields['Grant Type'] = 'Client Credentials'
        $fields['Client ID'] = $resolved.ClientId
        $fields['Client Secret'] = $clientSecret
        $fields['Refresh Token'] = $refreshToken
    }

    $settingsPath = Join-Path $resolved.OutputDirectory 'sailpoint-gws-connection-settings.txt'
    if (-not (Test-Path -LiteralPath $resolved.OutputDirectory)) {
        New-Item -ItemType Directory -Path $resolved.OutputDirectory -Force | Out-Null
    }
    Write-ConnectionSettings -Fields $fields -Title 'ISC source Connection Settings' -Path $settingsPath

    $publicSettings = [ordered]@{}
    foreach ($entry in $fields.GetEnumerator()) {
        if (-not (Test-ConnectionSettingIsSecret -Name $entry.Key)) {
            $publicSettings[$entry.Key] = $entry.Value
        }
    }

    $manual = @('Paste Connection Settings into ISC.')
    if (-not $resolved.SkipDomainWideDelegation -and $resolved.GrantType -eq 'ServiceAccount') {
        $manual += 'Complete domain-wide delegation in Google Admin console.'
    }

    return [ordered]@{
        status             = 'ok'
        connectionSettings = $publicSettings
        artifacts          = @([ordered]@{ label = 'Connection settings'; path = $settingsPath })
        secretArtifacts    = $secretArtifacts
        manualSteps        = $manual
        verification       = [ordered]@{ projectId = $resolved.ProjectId; serviceAccount = (Get-GoogleCreatedServiceAccount) }
        situation          = $manual
    }
}

Export-ModuleMember -Function @(
    'Initialize-GoogleSourceSetup'
    'Get-GoogleAgentCatalog'
    'Get-GoogleResolvedConfig'
    'New-GoogleAgentPlan'
    'Invoke-GoogleAgentApply'
)
