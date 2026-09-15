#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:DefaultSailpointConfigPath = Join-Path (Join-Path $HOME '.sailpoint') 'config.yaml'
$script:MicrosoftLicensingCsvUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'

function Get-SailpointConfigYamlPath {
    param([string]$Path)
    if ($Path) { return $Path }
    return $script:DefaultSailpointConfigPath
}

function ConvertFrom-SailpointSimpleYaml {
    <#
    .SYNOPSIS
        Minimal reader for ~/.sailpoint/config.yaml environment catalog (URLs only).
    #>
    param([Parameter(Mandatory)][string]$Content)

    $active = $null
    $environments = [ordered]@{}
    $currentEnv = $null
    $inEnvironments = $false

    foreach ($raw in ($Content -split "`r?`n")) {
        $line = $raw
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }

        if ($line -match '^activeenvironment:\s*(.+)\s*$') {
            $active = $Matches[1].Trim().Trim('"').Trim("'")
            $inEnvironments = $false
            $currentEnv = $null
            continue
        }

        if ($line -match '^environments:\s*$') {
            $inEnvironments = $true
            $currentEnv = $null
            continue
        }

        if ($inEnvironments -and $line -match '^  ([^:\s][^:]*):\s*$') {
            $currentEnv = $Matches[1].Trim()
            if (-not $environments.Contains($currentEnv)) {
                $environments[$currentEnv] = [ordered]@{
                    Name      = $currentEnv
                    BaseUrl   = $null
                    TenantUrl = $null
                    AuthType  = $null
                }
            }
            continue
        }

        if ($inEnvironments -and $currentEnv -and $line -match '^    ([A-Za-z0-9_]+):\s*(.*)\s*$') {
            $key = $Matches[1].Trim().ToLowerInvariant()
            $value = $Matches[2].Trim().Trim('"').Trim("'")
            switch ($key) {
                'baseurl' { $environments[$currentEnv].BaseUrl = $value }
                'tenanturl' { $environments[$currentEnv].TenantUrl = $value }
                'authtype' { $environments[$currentEnv].AuthType = $value }
            }
            continue
        }

        if ($line -match '^[A-Za-z]' -and $line -notmatch '^environments:') {
            $inEnvironments = $false
            $currentEnv = $null
        }
    }

    return [pscustomobject]@{
        ActiveEnvironment = $active
        Environments      = @($environments.Values)
    }
}

function Get-SailpointCliEnvironments {
    param([string]$ConfigPath)

    $path = Get-SailpointConfigYamlPath -Path $ConfigPath
    if (-not (Test-Path -LiteralPath $path)) {
        return [pscustomobject]@{
            Path              = $path
            ActiveEnvironment = $null
            Environments      = @()
            Exists            = $false
        }
    }

    $parsed = ConvertFrom-SailpointSimpleYaml -Content (Get-Content -LiteralPath $path -Raw -Encoding UTF8)
    return [pscustomobject]@{
        Path              = $path
        ActiveEnvironment = $parsed.ActiveEnvironment
        Environments      = @($parsed.Environments)
        Exists            = $true
    }
}

function Save-SailpointCliEnvironmentUrls {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$TenantUrl,
        [string]$ConfigPath,
        [switch]$SetActive
    )

    $path = Get-SailpointConfigYamlPath -Path $ConfigPath
    $directory = Split-Path -Parent $path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $catalog = Get-SailpointCliEnvironments -ConfigPath $path
    $envs = [System.Collections.Generic.List[object]]::new()
    foreach ($existing in @($catalog.Environments)) {
        if ($existing.Name -ne $Name) { $envs.Add($existing) }
    }
    $envs.Add([pscustomobject]@{
            Name      = $Name
            BaseUrl   = $BaseUrl.TrimEnd('/')
            TenantUrl = $TenantUrl.TrimEnd('/')
            AuthType  = 'pat'
        })

    $active = if ($SetActive -or -not $catalog.ActiveEnvironment) { $Name } else { $catalog.ActiveEnvironment }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("activeenvironment: $active")
    [void]$sb.AppendLine('authtype: pat')
    [void]$sb.AppendLine('environments:')
    foreach ($env in ($envs | Sort-Object Name)) {
        [void]$sb.AppendLine("  $($env.Name):")
        [void]$sb.AppendLine("    authtype: pat")
        [void]$sb.AppendLine("    baseurl: $($env.BaseUrl)")
        [void]$sb.AppendLine("    tenanturl: $($env.TenantUrl)")
    }
    Set-Content -LiteralPath $path -Value $sb.ToString() -Encoding UTF8
    return $path
}

function Get-SailpointSdkConfigFromFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "config.json was not found at $Path"
    }

    $json = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $baseUrl = if ($json.BaseURL) { [string]$json.BaseURL } elseif ($json.BaseUrl) { [string]$json.BaseUrl } else { $null }
    $clientId = if ($json.ClientId) { [string]$json.ClientId } else { $null }
    $clientSecret = if ($json.ClientSecret) { [string]$json.ClientSecret } else { $null }

    if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($clientSecret)) {
        throw "config.json at $Path must include BaseURL, ClientId, and ClientSecret."
    }

    return [pscustomobject]@{
        Source       = 'config.json'
        Path         = $Path
        BaseUrl      = $baseUrl.TrimEnd('/')
        ClientId     = $clientId
        ClientSecret = $clientSecret
    }
}

function Get-SailpointSdkConfigFromEnvironment {
    if ($env:SAIL_BASE_URL -and $env:SAIL_CLIENT_ID -and $env:SAIL_CLIENT_SECRET) {
        return [pscustomobject]@{
            Source       = 'environment'
            Path         = $null
            BaseUrl      = $env:SAIL_BASE_URL.TrimEnd('/')
            ClientId     = $env:SAIL_CLIENT_ID
            ClientSecret = $env:SAIL_CLIENT_SECRET
        }
    }
    return $null
}

function Set-SailpointProcessCredentials {
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$ClientSecret
    )

    $env:SAIL_BASE_URL = $BaseUrl.TrimEnd('/')
    $env:SAIL_CLIENT_ID = $ClientId
    $env:SAIL_CLIENT_SECRET = $ClientSecret
}

function Resolve-SailpointSdkCredentials {
    param(
        [string]$ConfigPath,
        [string]$PreferredBaseUrl
    )

    $fromEnv = Get-SailpointSdkConfigFromEnvironment
    if ($fromEnv) {
        if ($PreferredBaseUrl -and ($fromEnv.BaseUrl.TrimEnd('/') -ne $PreferredBaseUrl.TrimEnd('/'))) {
            $message = "SAIL_* environment credentials target $($fromEnv.BaseUrl); preferred env API URL is $PreferredBaseUrl."
            if (Get-Command Write-Info -ErrorAction SilentlyContinue) {
                Write-Info $message
            }
            else {
                Write-Host "   $message" -ForegroundColor DarkGray
            }
        }
        return $fromEnv
    }

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($ConfigPath) { $candidates.Add($ConfigPath) }
    $candidates.Add((Join-Path (Get-Location) 'config.json'))
    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            return Get-SailpointSdkConfigFromFile -Path $path
        }
    }

    return $null
}

function Ensure-SailPointSdkModule {
    Install-PowerShellGalleryModuleSet -ModuleNames @('PSSailpoint') -PromptTitle 'SailPoint PowerShell SDK (PSSailpoint) is required'
    Import-PowerShellGalleryModuleSet -ModuleNames @('PSSailpoint')
}

function Initialize-SailPointSdkSession {
    param(
        [Parameter(Mandatory)]$Credentials,
        [switch]$Experimental
    )

    Ensure-SailPointSdkModule
    Set-SailpointProcessCredentials -BaseUrl $Credentials.BaseUrl -ClientId $Credentials.ClientId -ClientSecret $Credentials.ClientSecret

    if (Get-Command Set-DefaultConfiguration -ErrorAction SilentlyContinue) {
        $params = @{
            BaseUrl      = $Credentials.BaseUrl
            ClientId     = $Credentials.ClientId
            ClientSecret = $Credentials.ClientSecret
        }
        if ($Experimental) { $params['Experimental'] = $true }
        Set-DefaultConfiguration @params
    }

    $null = Get-DefaultConfiguration
}

function Invoke-SailPointSdkPagedList {
    param(
        [Parameter(Mandatory)][scriptblock]$Fetcher,
        [int]$PageSize = 250
    )

    $offset = 0
    $all = [System.Collections.Generic.List[object]]::new()
    while ($true) {
        $page = @(
            & $Fetcher @{
                Offset = $offset
                Limit  = $PageSize
            }
        )
        if ($page.Count -eq 0) { break }
        foreach ($item in $page) { $all.Add($item) }
        if ($page.Count -lt $PageSize) { break }
        $offset += $PageSize
    }
    return , $all.ToArray()
}

function Test-SailPointSdkConnection {
    if (-not (Get-Command Get-SourcesV1 -ErrorAction SilentlyContinue)) {
        throw 'PSSailpoint cmdlets were not imported. Install-Module PSSailpoint -Scope CurrentUser and retry.'
    }
    $null = @(Get-SourcesV1 -Limit 1 -ErrorAction Stop)
    return $true
}

function Get-MicrosoftLicensingCsvUrl {
    return $script:MicrosoftLicensingCsvUrl
}

Export-ModuleMember -Function @(
    'Get-SailpointConfigYamlPath'
    'ConvertFrom-SailpointSimpleYaml'
    'Get-SailpointCliEnvironments'
    'Save-SailpointCliEnvironmentUrls'
    'Get-SailpointSdkConfigFromFile'
    'Get-SailpointSdkConfigFromEnvironment'
    'Set-SailpointProcessCredentials'
    'Resolve-SailpointSdkCredentials'
    'Ensure-SailPointSdkModule'
    'Initialize-SailPointSdkSession'
    'Invoke-SailPointSdkPagedList'
    'Test-SailPointSdkConnection'
    'Get-MicrosoftLicensingCsvUrl'
)
