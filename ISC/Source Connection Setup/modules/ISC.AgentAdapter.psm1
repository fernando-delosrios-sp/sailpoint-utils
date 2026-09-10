#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:SchemaVersion = 1
$script:SupportedConnectors = @(
    'entra-id'
    'aws-saas'
    'aws-ciem'
    'google-workspace'
    'iqservice'
)

function Get-AgentSchemaVersion {
    return $script:SchemaVersion
}

function Get-AgentSupportedConnectors {
    return @($script:SupportedConnectors)
}

function ConvertTo-CanonicalJson {
    param([Parameter(Mandatory)]$InputObject)

    return ($InputObject | ConvertTo-Json -Depth 20 -Compress)
}

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

function Get-AgentRequestValue {
    param(
        $Object,
        [Parameter(Mandatory)][string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $Default
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    return $Default
}

function Get-AgentRequestHash {
    param([Parameter(Mandatory)]$Request)

    $canonical = ConvertTo-CanonicalJson -InputObject $Request
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return ([BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
}

function Read-AgentJsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "JSON file is empty: $Path"
    }
    return ($raw | ConvertFrom-Json)
}

function Write-AgentJsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Object
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8 -NoNewline
}

function Resolve-AgentSecretReference {
    param([Parameter(Mandatory)][string]$Reference)

    if ($Reference -match '^env:(.+)$') {
        $name = $Matches[1]
        $value = [Environment]::GetEnvironmentVariable($name)
        if ([string]::IsNullOrEmpty($value)) {
            throw "Environment variable '$name' is not set."
        }
        return $value
    }
    if ($Reference -match '^file:(.+)$') {
        $path = $Matches[1]
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Secret file not found: $path"
        }
        return (Get-Content -LiteralPath $path -Raw).TrimEnd()
    }
    throw "Invalid secret reference '$Reference'. Use env:NAME or file:/path."
}

function Set-AgentRestrictedFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8 -NoNewline
    if ($IsWindows -or $env:OS -like 'Windows*') {
        $acl = Get-Acl -LiteralPath $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
            'FullControl',
            'Allow'
        )
        $acl.SetAccessRule($rule)
        $acl | Set-Acl -LiteralPath $Path
    }
    else {
        & chmod 600 $Path
    }
}

function New-AgentRunDirectory {
    param(
        [Parameter(Mandatory)][string]$ConnectorSlug,
        [string]$RunId
    )

    if (-not $RunId) {
        $RunId = [Guid]::NewGuid().ToString('n')
    }
    $root = Join-Path (Get-Location) (Join-Path 'sourceConfig' (Join-Path $ConnectorSlug 'agent-runs'))
    $runDir = Join-Path $root $RunId
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    return [PSCustomObject]@{
        RunId = $RunId
        Path  = $runDir
    }
}

function New-AgentEnvelope {
    param(
        [Parameter(Mandatory)][ValidateSet('catalog', 'plan', 'result', 'error')]
        [string]$Kind,
        [Parameter(Mandatory)][string]$Connector,
        [string]$Status = 'ok',
        $Body = $null,
        [string[]]$Errors = @(),
        [string[]]$Warnings = @()
    )

    return [ordered]@{
        schemaVersion = $script:SchemaVersion
        kind          = $Kind
        connector     = $Connector
        status        = $Status
        body          = $Body
        errors        = @($Errors)
        warnings      = @($Warnings)
        generatedAt   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Test-AgentSecretFieldName {
    param([Parameter(Mandatory)][string]$Name)

    $lower = $Name.ToLowerInvariant()
    return $lower -match 'secret|password|private key|refresh token|downloaduri|signed.?url'
}

function ConvertTo-RedactedAgentObject {
    param([Parameter(Mandatory)]$InputObject)

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [string]) {
        if ($InputObject.Length -le 4) { return '***' }
        return '***' + $InputObject.Substring($InputObject.Length - 4)
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            if (Test-AgentSecretFieldName -Name ([string]$key)) {
                $out[$key] = '***redacted***'
            }
            else {
                $out[$key] = ConvertTo-RedactedAgentObject -InputObject $InputObject[$key]
            }
        }
        return $out
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-RedactedAgentObject -InputObject $_ })
    }
    if ($InputObject -is [pscustomobject]) {
        $out = [ordered]@{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            if (Test-AgentSecretFieldName -Name $prop.Name) {
                $out[$prop.Name] = '***redacted***'
            }
            else {
                $out[$prop.Name] = ConvertTo-RedactedAgentObject -InputObject $prop.Value
            }
        }
        return $out
    }
    return $InputObject
}

function Test-AgentPlanReady {
    param([Parameter(Mandatory)]$Plan)

    if ($Plan.status -ne 'ready') {
        throw "Plan status is '$($Plan.status)'. Resolve needsInput items before Apply."
    }
    if (-not $Plan.requestHash) {
        throw 'Plan is missing requestHash.'
    }
    return $true
}

function Assert-AgentPlanMatchesRequest {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)]$Request
    )

    $expected = Get-AgentRequestHash -Request $Request
    if ($Plan.requestHash -ne $expected) {
        throw 'Plan requestHash does not match the supplied request. Re-run Plan.'
    }
}

function Import-AgentConnectorModule {
    param(
        [Parameter(Mandatory)][string]$ModuleRoot,
        [Parameter(Mandatory)][string]$Connector
    )

    switch ($Connector) {
        'entra-id' { Import-Module (Join-Path $ModuleRoot 'ISC.EntraSourceSetup.psm1') -Force -WarningAction SilentlyContinue }
        'aws-saas' { Import-Module (Join-Path $ModuleRoot 'ISC.AwsSourceSetup.psm1') -Force -WarningAction SilentlyContinue }
        'aws-ciem' { Import-Module (Join-Path $ModuleRoot 'ISC.AwsSourceSetup.psm1') -Force -WarningAction SilentlyContinue }
        'google-workspace' { Import-Module (Join-Path $ModuleRoot 'ISC.GoogleSourceSetup.psm1') -Force -WarningAction SilentlyContinue }
        'iqservice' { Import-Module (Join-Path $ModuleRoot 'ISC.IQServiceSourceSetup.psm1') -Force -WarningAction SilentlyContinue }
        default { throw "Unsupported connector '$Connector'." }
    }
}

function Invoke-AgentConnectorCatalog {
    param(
        [Parameter(Mandatory)][string]$Connector
    )

    switch ($Connector) {
        'entra-id' { return Get-EntraAgentCatalog }
        'aws-saas' { return Get-AwsAgentCatalog -Variant 'aws-saas' }
        'aws-ciem' { return Get-AwsAgentCatalog -Variant 'aws-ciem' }
        'google-workspace' { return Get-GoogleAgentCatalog }
        'iqservice' { return Get-IQServiceAgentCatalog }
        default { throw "Unsupported connector '$Connector'." }
    }
}

function Invoke-AgentConnectorPlan {
    param(
        [Parameter(Mandatory)][string]$Connector,
        [Parameter(Mandatory)]$Request
    )

    switch ($Connector) {
        'entra-id' { return New-EntraAgentPlan -Request $Request }
        'aws-saas' { return New-AwsAgentPlan -Request $Request -Variant 'aws-saas' }
        'aws-ciem' { return New-AwsAgentPlan -Request $Request -Variant 'aws-ciem' }
        'google-workspace' { return New-GoogleAgentPlan -Request $Request }
        'iqservice' { return New-IQServiceAgentPlan -Request $Request }
        default { throw "Unsupported connector '$Connector'." }
    }
}

function Invoke-AgentConnectorApply {
    param(
        [Parameter(Mandatory)][string]$Connector,
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Plan,
        [switch]$WhatIf
    )

    switch ($Connector) {
        'entra-id' { return Invoke-EntraAgentApply -Request $Request -Plan $Plan -WhatIf:$WhatIf }
        'aws-saas' { return Invoke-AwsAgentApply -Request $Request -Plan $Plan -Variant 'aws-saas' -WhatIf:$WhatIf }
        'aws-ciem' { return Invoke-AwsAgentApply -Request $Request -Plan $Plan -Variant 'aws-ciem' -WhatIf:$WhatIf }
        'google-workspace' { return Invoke-GoogleAgentApply -Request $Request -Plan $Plan -WhatIf:$WhatIf }
        'iqservice' { return Invoke-IQServiceAgentApply -Request $Request -Plan $Plan -WhatIf:$WhatIf }
        default { throw "Unsupported connector '$Connector'." }
    }
}

function Invoke-AgentAdapter {
    param(
        [Parameter(Mandatory)][ValidateSet('Catalog', 'Plan', 'Apply')]
        [string]$Operation,
        [Parameter(Mandatory)][string]$Connector,
        [string]$RequestPath,
        [string]$PlanPath,
        [string]$OutputPath,
        [switch]$WhatIf
    )

    if ($Connector -notin $script:SupportedConnectors) {
        throw "Unsupported connector '$Connector'. Supported: $($script:SupportedConnectors -join ', ')."
    }

    try {
        switch ($Operation) {
            'Catalog' {
                $body = Invoke-AgentConnectorCatalog -Connector $Connector
                $envelope = New-AgentEnvelope -Kind 'catalog' -Connector $Connector -Body $body
            }
            'Plan' {
                if (-not $RequestPath) { throw 'Plan requires -RequestPath.' }
                $request = Read-AgentJsonFile -Path $RequestPath
                if ($request.connector -and $request.connector -ne $Connector) {
                    throw "Request connector '$($request.connector)' does not match -Connector '$Connector'."
                }
                $planBody = Invoke-AgentConnectorPlan -Connector $Connector -Request $request
                $envelope = New-AgentEnvelope -Kind 'plan' -Connector $Connector -Status $planBody.status -Body $planBody
            }
            'Apply' {
                if (-not $RequestPath) { throw 'Apply requires -RequestPath.' }
                if (-not $PlanPath) { throw 'Apply requires -PlanPath.' }
                $request = Read-AgentJsonFile -Path $RequestPath
                $planWrapper = Read-AgentJsonFile -Path $PlanPath
                $plan = if ($planWrapper.body) { $planWrapper.body } else { $planWrapper }
                Test-AgentPlanReady -Plan $plan
                Assert-AgentPlanMatchesRequest -Plan $plan -Request $request
                $resultBody = Invoke-AgentConnectorApply -Connector $Connector -Request $request -Plan $plan -WhatIf:$WhatIf
                $envelope = New-AgentEnvelope -Kind 'result' -Connector $Connector -Status $resultBody.status -Body (ConvertTo-RedactedAgentObject -InputObject $resultBody)
            }
        }

        if ($OutputPath) {
            Write-AgentJsonFile -Path $OutputPath -Object $envelope
        }
        return $envelope
    }
    catch {
        $errorEnvelope = New-AgentEnvelope -Kind 'error' -Connector $Connector -Status 'error' -Errors @($_.Exception.Message)
        if ($OutputPath) {
            Write-AgentJsonFile -Path $OutputPath -Object $errorEnvelope
        }
        throw
    }
}

Export-ModuleMember -Function @(
    'Import-SourceSetupModule'
    'Get-AgentSchemaVersion'
    'Get-AgentSupportedConnectors'
    'ConvertTo-CanonicalJson'
    'Get-AgentRequestValue'
    'Get-AgentRequestHash'
    'Read-AgentJsonFile'
    'Write-AgentJsonFile'
    'Resolve-AgentSecretReference'
    'Set-AgentRestrictedFile'
    'New-AgentRunDirectory'
    'New-AgentEnvelope'
    'Test-AgentSecretFieldName'
    'ConvertTo-RedactedAgentObject'
    'Test-AgentPlanReady'
    'Assert-AgentPlanMatchesRequest'
    'Import-AgentConnectorModule'
    'Invoke-AgentAdapter'
)
