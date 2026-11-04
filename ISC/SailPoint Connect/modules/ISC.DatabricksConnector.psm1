#Requires -Version 7
Set-StrictMode -Version Latest

function Get-DatabricksAccountHost {
    param([string]$Cloud = 'Aws')
    switch ($Cloud) {
        'Azure' { return 'https://accounts.azuredatabricks.net' }
        'Gcp' { return 'https://accounts.gcp.databricks.com' }
        default { return 'https://accounts.cloud.databricks.com' }
    }
}

function Get-DatabricksRunRecord {
    param([hashtable]$Context)
    if (-not $Context) { return $null }
    if (-not $Context.ContainsKey('DatabricksRunRecord') -or $null -eq $Context['DatabricksRunRecord']) {
        $Context['DatabricksRunRecord'] = @{
            ServicePrincipalId     = $null
            ApplicationId          = $null
            ServicePrincipalResult = $null
            AccountAdminResult     = $null
            SecretPath             = $null
            SecretResult           = $null
        }
    }
    return $Context['DatabricksRunRecord']
}

function Invoke-DatabricksAccountCli {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Cloud,
        [Parameter(Mandatory)][string[]]$CliArgs
    )
    # Account-level commands need the accounts host and the account ID, not the workspace profile the CLI may default to.
    $saved = @{
        DATABRICKS_HOST           = $env:DATABRICKS_HOST
        DATABRICKS_ACCOUNT_ID     = $env:DATABRICKS_ACCOUNT_ID
        DATABRICKS_CONFIG_PROFILE = $env:DATABRICKS_CONFIG_PROFILE
    }
    try {
        $env:DATABRICKS_HOST = Get-DatabricksAccountHost -Cloud $Cloud
        $env:DATABRICKS_ACCOUNT_ID = $AccountId
        Remove-Item Env:DATABRICKS_CONFIG_PROFILE -ErrorAction SilentlyContinue
        $output = & databricks @CliArgs --output json 2>&1
        $exit = $LASTEXITCODE
    }
    finally {
        foreach ($name in $saved.Keys) {
            if ($null -eq $saved[$name]) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
            else { Set-Item "Env:$name" -Value $saved[$name] }
        }
    }
    $errors = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.ToString() })
    $text = (@($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ($exit -ne 0) {
        throw "databricks $($CliArgs -join ' ') failed: $((@($errors) + @($text) | Where-Object { $_ }) -join ' ')"
    }
    if (-not $text) { return $null }
    return ($text | ConvertFrom-Json -AsHashtable -Depth 20)
}

function Connect-DatabricksAccount {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Cloud,
        [switch]$NonInteractive
    )
    try {
        Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud -CliArgs @('account', 'metastores', 'list') | Out-Null
        return
    }
    catch {
        $firstError = $_.Exception.Message
    }
    $accountHost = Get-DatabricksAccountHost -Cloud $Cloud
    $login = "databricks auth login --host $accountHost --account-id $AccountId"
    if ($NonInteractive) {
        throw "The Databricks CLI has no account-level session for $AccountId. Run: $login. CLI said: $firstError"
    }
    Write-Info "Signing in to the Databricks account console ($accountHost). A browser window opens."
    & databricks auth login --host $accountHost --account-id $AccountId
    if ($LASTEXITCODE -ne 0) { throw "Databricks sign-in failed. Run: $login" }
    Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud -CliArgs @('account', 'metastores', 'list') | Out-Null
}

function Get-DatabricksServicePrincipal {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Cloud,
        [Parameter(Mandatory)][string]$DisplayName
    )
    $list = Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud `
        -CliArgs @('account', 'service-principals', 'list', '--filter', "displayName eq `"$DisplayName`"")
    return @(@($list) | Where-Object { $_ -and [string]$_['displayName'] -eq $DisplayName }) | Select-Object -First 1
}

function Test-DatabricksAccountAdmin {
    param([hashtable]$ServicePrincipal)
    if (-not $ServicePrincipal -or -not $ServicePrincipal.ContainsKey('roles')) { return $false }
    return @(@($ServicePrincipal['roles']) | Where-Object { $_ -and [string]$_['value'] -eq 'account_admin' }).Count -gt 0
}

function Invoke-DatabricksEnsureServicePrincipal {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Cloud,
        [Parameter(Mandatory)][string]$DisplayName,
        [hashtable]$Context
    )
    $record = Get-DatabricksRunRecord -Context $Context
    $sp = Get-DatabricksServicePrincipal -AccountId $AccountId -Cloud $Cloud -DisplayName $DisplayName
    if ($sp) {
        if ($record) { $record.ServicePrincipalResult = 'Already present' }
        Write-Ok "Service principal $DisplayName already exists"
    }
    else {
        $sp = Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud `
            -CliArgs @('account', 'service-principals', 'create', '--display-name', $DisplayName)
        if (-not $sp -or -not $sp['id']) { throw "databricks did not return the new service principal $DisplayName." }
        if ($record) { $record.ServicePrincipalResult = 'Created in this run' }
        Write-Ok "Created service principal $DisplayName"
    }
    if (Test-DatabricksAccountAdmin -ServicePrincipal $sp) {
        if ($record) { $record.AccountAdminResult = 'Already granted' }
    }
    else {
        $patch = @{
            schemas    = @('urn:ietf:params:scim:api:messages:2.0:PatchOp')
            Operations = @(@{ op = 'add'; path = 'roles'; value = @(@{ value = 'account_admin' }) })
        } | ConvertTo-Json -Depth 6 -Compress
        Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud `
            -CliArgs @('account', 'service-principals', 'patch', [string]$sp['id'], '--json', $patch) | Out-Null
        if ($record) { $record.AccountAdminResult = 'Granted in this run' }
        Write-Ok "Granted Account admin to $DisplayName"
    }
    if ($record) {
        $record.ServicePrincipalId = [string]$sp['id']
        $record.ApplicationId = [string]$sp['applicationId']
    }
    if ($Context) { $Context['DatabricksServicePrincipal'] = $sp }
    return $sp
}

function Get-DatabricksOAuthSecretPath {
    param([Parameter(Mandatory)][string]$Directory)
    Join-Path $Directory 'databricks-oauth-secret.json'
}

function Test-DatabricksOAuthSecretFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ApplicationId
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable
    }
    catch {
        return $false
    }
    if (-not $json) { return $false }
    return ([string]$json['client_id'] -eq $ApplicationId) -and -not [string]::IsNullOrWhiteSpace([string]$json['client_secret'])
}

function Protect-DatabricksSecretFile {
    param([Parameter(Mandatory)][string]$Path)
    if ($IsWindows) { return }
    & chmod 600 $Path
}

function Invoke-DatabricksEnsureOAuthSecret {
    param(
        [Parameter(Mandatory)][string]$AccountId,
        [Parameter(Mandatory)][string]$Cloud,
        [Parameter(Mandatory)][hashtable]$ServicePrincipal,
        [Parameter(Mandatory)][string]$Path,
        [switch]$Rotate,
        [hashtable]$Context
    )
    $record = Get-DatabricksRunRecord -Context $Context
    $applicationId = [string]$ServicePrincipal['applicationId']
    if ($record) { $record.SecretPath = $Path }
    if (-not $Rotate -and (Test-DatabricksOAuthSecretFile -Path $Path -ApplicationId $applicationId)) {
        Protect-DatabricksSecretFile -Path $Path
        if ($record) { $record.SecretResult = 'Already on disk' }
        Write-Ok "OAuth secret already on disk: $Path"
        return
    }
    # Databricks shows a secret only when it is created, so a secret that is not on disk cannot be reused.
    $created = Invoke-DatabricksAccountCli -AccountId $AccountId -Cloud $Cloud `
        -CliArgs @('account', 'service-principal-secrets', 'create', [string]$ServicePrincipal['id'])
    if (-not $created -or [string]::IsNullOrWhiteSpace([string]$created['secret'])) {
        throw "databricks did not return an OAuth secret for service principal $applicationId."
    }
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [ordered]@{
        client_id     = $applicationId
        client_secret = [string]$created['secret']
        secret_id     = [string]$created['id']
        account_id    = $AccountId
        cloud         = $Cloud
        created       = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $Path -Encoding utf8
    Protect-DatabricksSecretFile -Path $Path
    if ($record) { $record.SecretResult = 'Created in this run' }
    Write-Ok "Created OAuth secret: $Path"
}

Export-ModuleMember -Function @(
    'Get-DatabricksAccountHost'
    'Get-DatabricksRunRecord'
    'Invoke-DatabricksAccountCli'
    'Connect-DatabricksAccount'
    'Get-DatabricksServicePrincipal'
    'Test-DatabricksAccountAdmin'
    'Invoke-DatabricksEnsureServicePrincipal'
    'Get-DatabricksOAuthSecretPath'
    'Test-DatabricksOAuthSecretFile'
    'Invoke-DatabricksEnsureOAuthSecret'
)
