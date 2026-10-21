#Requires -Version 7.0
<#
.SYNOPSIS
    Lists the identities that have AI access request recommendations, one row per recommendation.

.DESCRIPTION
    Iterates identities from an optional ISC search expression, asks the Access Request
    Recommender for each one, drops items already ignored or requested, and writes the
    survivors to CSV (and optionally a self-contained HTML table).

    All tenant calls go through the sailor CLI (`sail`), which supplies auth from its own
    configured environments. No PSSailpoint module or client credentials are needed.

    Run it with no parameters to be prompted for the environment, scope, and outputs.
    Pass -NonInteractive to skip the prompts and use the defaults.

    Read-only. Nothing in the tenant is created, changed, or marked viewed.

.PARAMETER Environment
    Named environment from the sail CLI (`sail env list`). Defaults to the active environment.

.PARAMETER SailpointConfigPath
    Optional path to the CLI catalog used to read the active environment. Default:
    ~/.sailpoint/config.yaml

.PARAMETER SearchQuery
    ISC search expression over the identities index that narrows the iteration.
    Default '*' (every identity). 'manager.name:*' is a cheaper scope: the recommender
    only serves identities that have a manager.

.PARAMETER LimitPerIdentity
    Maximum recommendations requested per identity. The API caps this at 15.

.PARAMETER SkipTranslationMessages
    Do not request the explanation messages. They are on by default because they are the
    part a reviewer reads.

.PARAMETER OutputPath
    CSV path. Default: ./access-request-recommendations-<timestamp>.csv

.PARAMETER HtmlPath
    Optional path for a self-contained HTML table of the same rows.

.PARAMETER MaxIdentities
    Safety cap on identities iterated. 0 (default) means no cap.

.PARAMETER ThrottleMs
    Milliseconds to pause between per-identity calls. Default 0.

.PARAMETER MaxRetries
    Retries for a throttled (HTTP 429) recommendation call. Default 4.

.PARAMETER TimeoutSeconds
    Per-call ceiling for a `sail` invocation. A call that hangs is abandoned and the
    identity is recorded as a failure. Default 30.

.PARAMETER NonInteractive
    Skip the prompts and use each parameter's default. For automation.

.EXAMPLE
    ./Get-AccessRequestRecommendations.ps1 -Environment emea-tes-team

.EXAMPLE
    ./Get-AccessRequestRecommendations.ps1 -SearchQuery 'manager.name:* AND attributes.department:Finance' -HtmlPath ./recommendations.html

.EXAMPLE
    # Interactive: prompts for environment, scope, and outputs
    ./Get-AccessRequestRecommendations.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Environment,

    [Parameter()]
    [string]$SailpointConfigPath,

    [Parameter()]
    [string]$SearchQuery = '*',

    [Parameter()]
    [ValidateRange(1, 15)]
    [int]$LimitPerIdentity = 15,

    [Parameter()]
    [switch]$SkipTranslationMessages,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$HtmlPath,

    [Parameter()]
    [int]$MaxIdentities = 0,

    [Parameter()]
    [int]$ThrottleMs = 0,

    [Parameter()]
    [int]$MaxRetries = 4,

    [Parameter()]
    [int]$TimeoutSeconds = 30,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SearchPageSize = 250
$script:SearchOffsetCeiling = 10000
$script:SailCommand = $null

$sourceSetupModules = Join-Path (Split-Path -Parent $PSScriptRoot) 'Source Connection Setup/modules'
Import-Module (Join-Path $sourceSetupModules 'ISC.OperatorConsole.psm1') -Force -WarningAction SilentlyContinue

Initialize-OperatorConsole -NonInteractive:$NonInteractive

class SailApiError : System.Exception {
    [int]$Status

    SailApiError([int]$status, [string]$message) : base($message) {
        $this.Status = $status
    }
}

function Get-ObjectPropertySafe {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $null
}

function Resolve-SailCommand {
    $command = Get-Command sail -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) {
        throw 'The sail CLI was not found on PATH. Install it (brew install sailpoint-oss/tap/sailpoint-cli) and retry.'
    }
    return $command.Source
}

function Remove-SailChrome {
    <#
        Strips CLI chrome so the remainder is the API payload:
          - logger lines:  2026/10/21 13:01:35 INFO Making GET request ...
          - status line:   Status: 200 OK
    #>
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }

    $kept = foreach ($line in ($Text -split "`r?`n")) {
        if ($line -match '^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\s') { continue }
        if ($line -match '^Status:\s*\d') { continue }
        $line
    }

    return (($kept -join "`n").Trim())
}

function Invoke-SailApi {
    <#
        Runs `sail api <method> <path>` and returns the parsed JSON payload.

        The CLI always exits 0, even on 4xx/5xx, so the `Status:` line is the only signal.
        With `-j` the evaluated result is on stdout; without it the raw body is on stderr and
        stdout carries only `Status:`. A hard per-call timeout keeps one hung request from
        stalling the whole run.
    #>
    param(
        [Parameter(Mandatory)][ValidateSet('get', 'post')][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        [string[]]$Query,
        [string[]]$Header,
        [string]$Body,
        [string]$JsonPath,
        [Parameter(Mandatory)][string]$Environment,
        [int]$TimeoutSeconds = 30
    )

    $arguments = [System.Collections.Generic.List[string]]::new()
    $arguments.Add('api')
    $arguments.Add($Method)
    $arguments.Add($Path)
    foreach ($item in @($Query)) {
        if (-not [string]::IsNullOrWhiteSpace($item)) { $arguments.Add('-q'); $arguments.Add($item) }
    }
    foreach ($item in @($Header)) {
        if (-not [string]::IsNullOrWhiteSpace($item)) { $arguments.Add('-H'); $arguments.Add($item) }
    }
    if (-not [string]::IsNullOrWhiteSpace($Body)) { $arguments.Add('-b'); $arguments.Add($Body) }
    if (-not [string]::IsNullOrWhiteSpace($JsonPath)) { $arguments.Add('-j'); $arguments.Add($JsonPath) }
    $arguments.Add('--env')
    $arguments.Add($Environment)

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $script:SailCommand
    foreach ($argument in $arguments) { $startInfo.ArgumentList.Add($argument) }
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    try {
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill($true) } catch { }
            throw [SailApiError]::new(0, "sail api $Method $Path timed out after ${TimeoutSeconds}s.")
        }
        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()
    }
    finally {
        $process.Dispose()
    }

    $statusMatch = [regex]::Match($stdoutText, 'Status:\s*(\d{3})')
    $status = if ($statusMatch.Success) { [int]$statusMatch.Groups[1].Value } else { 0 }

    $stdoutPayload = Remove-SailChrome -Text $stdoutText
    $stderrPayload = Remove-SailChrome -Text $stderrText
    if (-not [string]::IsNullOrWhiteSpace($JsonPath)) {
        $payload = if (-not [string]::IsNullOrWhiteSpace($stdoutPayload)) { $stdoutPayload } else { $stderrPayload }
    }
    else {
        $payload = if (-not [string]::IsNullOrWhiteSpace($stderrPayload)) { $stderrPayload } else { $stdoutPayload }
    }

    if ($status -ge 400) {
        throw [SailApiError]::new($status, "sail api $Method $Path returned HTTP $status. $payload")
    }

    if ([string]::IsNullOrWhiteSpace($payload)) {
        return @()
    }

    try {
        return $payload | ConvertFrom-Json
    }
    catch {
        throw "sail api $Method $Path returned an unreadable response: $($_.Exception.Message)"
    }
}
function Get-SailEnvironmentCatalog {
    <#
        Runs `sail env list`, which prints the catalog as JSON on stdout. The command
        warns and asks for Enter first, so an empty line is piped in.
    #>
    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            '' | & $script:SailCommand env list 1> $stdoutFile 2> $stderrFile
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previous
        }
        $raw = Get-Content -LiteralPath $stdoutFile -Raw
    }
    finally {
        Remove-Item -LiteralPath $stdoutFile, $stderrFile -Force -ErrorAction SilentlyContinue
    }

    $start = $raw.IndexOf('{')
    $end = $raw.LastIndexOf('}')
    if ($start -lt 0 -or $end -lt $start) {
        throw 'sail env list did not return an environment catalog. Run `sail env list` to check the CLI.'
    }

    $json = $raw.Substring($start, $end - $start + 1) | ConvertFrom-Json
    $names = @($json.PSObject.Properties.Name | Where-Object { $_ -notmatch '^_' })

    $environments = foreach ($name in $names) {
        $baseUrl = [string](Get-ObjectPropertySafe -Object (Get-ObjectPropertySafe -Object $json -Name $name) -Name 'baseurl')
        [pscustomobject]@{ Name = $name; BaseUrl = $baseUrl }
    }

    return @($environments)
}

function Get-ActiveSailEnvironment {
    param([string]$ConfigPath)

    $path = if ($ConfigPath) { $ConfigPath } else { Join-Path (Join-Path $HOME '.sailpoint') 'config.yaml' }
    if (-not (Test-Path -LiteralPath $path)) { return $null }

    foreach ($line in (Get-Content -LiteralPath $path)) {
        if ($line -match '^activeenvironment:\s*(\S+)\s*$') {
            return $Matches[1].Trim('"').Trim("'")
        }
    }

    return $null
}

function Get-IdentityScope {
    <#
        Pages the identities search index for the given expression and returns { Id, Name }.
        The ids are offset paged, which the search API serves up to 10,000 records.
    #>
    param(
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)][string]$Environment,
        [int]$Max = 0,
        [int]$TimeoutSeconds = 120
    )

    $body = @{ indices = @('identities'); query = @{ query = $Query } } | ConvertTo-Json -Compress -Depth 5
    $offset = 0
    $results = [System.Collections.Generic.List[object]]::new()

    while ($true) {
        if ($offset -ge $script:SearchOffsetCeiling) {
            Write-Warning ("Stopped at the {0:N0}-record search offset ceiling. Narrow -SearchQuery, or page with searchAfter." -f $script:SearchOffsetCeiling)
            break
        }

        $flat = @(Invoke-SailApi -Method post -Path "/search/v1?limit=$($script:SearchPageSize)&offset=$offset" `
                -Body $body -JsonPath '$[*]["id","displayName"]' -Environment $Environment -TimeoutSeconds $TimeoutSeconds)

        if ($flat.Count -eq 0) { break }

        if ($flat.Count % 2 -ne 0) {
            Write-Warning 'Search returned an unexpected shape (id/displayName did not pair up); using ids as names for this page.'
            for ($i = 0; $i -lt $flat.Count; $i++) {
                $id = [string]$flat[$i]
                if ($id) { $results.Add([pscustomobject]@{ Id = $id; Name = $id }) }
            }
        }
        else {
            for ($i = 0; $i -lt $flat.Count; $i += 2) {
                $id = [string]$flat[$i]
                if (-not $id) { continue }
                $name = [string]$flat[$i + 1]
                if (-not $name) { $name = $id }
                $results.Add([pscustomobject]@{ Id = $id; Name = $name })
            }
        }

        if ($Max -gt 0 -and $results.Count -ge $Max) { break }

        $pageHits = if ($flat.Count % 2 -ne 0) { [int][Math]::Floor($flat.Count / 2) } else { $flat.Count / 2 }
        if ($pageHits -lt $script:SearchPageSize) { break }

        $offset += $script:SearchPageSize
    }

    if ($Max -gt 0 -and $results.Count -gt $Max) { return $results.GetRange(0, $Max).ToArray() }
    return $results.ToArray()
}

function Get-IdentityRecommendations {
    param(
        [Parameter(Mandatory)][string]$IdentityId,
        [Parameter(Mandatory)][string]$Environment,
        [int]$Limit = 15,
        [bool]$WithMessages = $true,
        [int]$Retries = 4,
        [int]$TimeoutSeconds = 30
    )

    $attempt = 0
    while ($true) {
        try {
            return @(Invoke-SailApi -Method get -Path '/ai-access-request-recommendations/v1' `
                    -Query @("identity-id=$IdentityId", "limit=$Limit", "include-translation-messages=$($WithMessages.ToString().ToLowerInvariant())") `
                    -Header @('X-SailPoint-Experimental: true') `
                    -Environment $Environment -TimeoutSeconds $TimeoutSeconds)
        }
        catch {
            $status = 0
            if ($_.Exception -is [SailApiError]) { $status = $_.Exception.Status }
            elseif ($_.Exception.InnerException -is [SailApiError]) { $status = $_.Exception.InnerException.Status }

            if ($status -eq 429 -and $attempt -lt $Retries) {
                $attempt++
                $wait = [Math]::Min(60, 5 * [int][Math]::Pow(2, $attempt - 1))
                Write-Verbose "Throttled on identity $IdentityId; retrying in ${wait}s (attempt $attempt of $Retries)."
                Start-Sleep -Seconds $wait
                continue
            }
            throw
        }
    }
}

function Get-RecommendationExplanation {
    param([AllowNull()]$Item)

    # messages[].interpretation is the rendered sentence ("83% of people like you on your
    # team have this access."). translationMessages[].values only carries the interpolation
    # inputs ("83"), so it is a last-resort fallback, never the first choice.
    $messages = @(Get-ObjectPropertySafe -Object $Item -Name 'messages')
    if ($messages.Count -gt 0) {
        $joined = (@($messages | ForEach-Object { [string](Get-ObjectPropertySafe -Object $_ -Name 'interpretation') }) |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
        if (-not [string]::IsNullOrWhiteSpace($joined)) { return $joined.Trim() }
    }

    $translations = @(Get-ObjectPropertySafe -Object $Item -Name 'translationMessages')
    if ($translations.Count -gt 0) {
        $values = foreach ($message in $translations) {
            @(Get-ObjectPropertySafe -Object $message -Name 'values')
        }
        $joined = (@($values) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ }) -join ' '
        if (-not [string]::IsNullOrWhiteSpace($joined)) { return $joined.Trim() }
    }

    return ''
}

function ConvertTo-EscapedHtml {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function New-RecommendationsHtml {
    param(
        [Parameter(Mandatory)][object[]]$Rows,
        [Parameter(Mandatory)][string]$Title
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine('<!doctype html><html><head><meta charset="utf-8">')
    [void]$builder.AppendLine("<title>$(ConvertTo-EscapedHtml $Title)</title>")
    [void]$builder.AppendLine('<style>body{font-family:-apple-system,Segoe UI,Roboto,sans-serif;margin:2rem;color:#0f172a}table{border-collapse:collapse;width:100%;font-size:.9rem}th,td{border-bottom:1px solid #e2e8f0;padding:.45rem .6rem;text-align:left;vertical-align:top}th{background:#f8fafc;font-size:.75rem;text-transform:uppercase;letter-spacing:.03em;color:#64748b}</style>')
    [void]$builder.AppendLine('</head><body>')
    [void]$builder.AppendLine("<h1>$(ConvertTo-EscapedHtml $Title)</h1>")
    [void]$builder.AppendLine("<p>$(ConvertTo-EscapedHtml (Get-Date -Format 'yyyy-MM-dd HH:mm')) &middot; $($Rows.Count) recommendation(s)</p>")
    [void]$builder.AppendLine('<table><thead><tr><th>Identity</th><th>Access</th><th>Type</th><th>Source</th><th>Viewed</th><th>Why</th></tr></thead><tbody>')

    foreach ($row in $Rows) {
        [void]$builder.AppendLine(('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>' -f `
                    (ConvertTo-EscapedHtml $row.Identity), `
                    (ConvertTo-EscapedHtml $row.AccessName), `
                    (ConvertTo-EscapedHtml $row.AccessType), `
                    (ConvertTo-EscapedHtml $row.SourceName), `
                    $(if ($row.Viewed) { 'yes' } else { 'no' }), `
                    (ConvertTo-EscapedHtml $row.Explanation)))
    }

    [void]$builder.AppendLine('</tbody></table></body></html>')
    return $builder.ToString()
}

# --- Resolve environment -----------------------------------------------------

Write-Step 'Access request recommendations'

$script:SailCommand = Resolve-SailCommand
Write-Ok ("sail:         {0}" -f $script:SailCommand)

$environments = Get-SailEnvironmentCatalog
$activeEnvironment = Get-ActiveSailEnvironment -ConfigPath $SailpointConfigPath
$selected = $null

if (-not [string]::IsNullOrWhiteSpace($Environment)) {
    $selected = @($environments | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1)
    if (-not $selected) {
        throw "Environment '$Environment' was not found by the sail CLI. Run `sail env list` to check the name."
    }
}
elseif (-not (Test-OperatorNonInteractive)) {
    if ($environments.Count -eq 0) {
        throw 'The sail CLI has no environments configured. Add one with `sail env create`, then retry.'
    }
    if ($environments.Count -eq 1) {
        $Environment = $environments[0].Name
    }
    else {
        $options = @($environments | ForEach-Object { $_.Name })
        $labels = @($environments | ForEach-Object {
                $activeMark = if ($_.Name -eq $activeEnvironment) { '  (active)' } else { '' }
                "$($_.Name)  $($_.BaseUrl)$activeMark"
            })
        $default = if ($activeEnvironment -and $options -contains $activeEnvironment) { $activeEnvironment } else { $options[0] }
        $Environment = Read-Choice -Prompt 'Select an ISC environment:' -Options $options -Labels $labels -Default $default
    }
    $selected = @($environments | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1)
}
elseif ($activeEnvironment) {
    $Environment = $activeEnvironment
    $selected = @($environments | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1)
}

Write-Ok ("Environment:  {0}{1}" -f $Environment, $(if ($selected -and $selected.BaseUrl) { " ($($selected.BaseUrl))" } else { '' }))

# --- Collect any inputs that were not passed as parameters -------------------

if (-not $PSBoundParameters.ContainsKey('SearchQuery')) {
    if (-not (Test-OperatorNonInteractive)) {
        Write-Info "Leave blank for every identity; 'manager.name:*' skips identities the recommender never serves."
    }
    $SearchQuery = Read-InputString -Prompt 'Search expression over the identities index' -Default '*'
    if ([string]::IsNullOrWhiteSpace($SearchQuery)) { $SearchQuery = '*' }
}

if (-not $PSBoundParameters.ContainsKey('LimitPerIdentity')) {
    $answer = Read-InputString -Prompt 'Recommendations per identity (1-15)' -Default '15' -Validate {
        param($value)
        $number = 0
        if (-not [int]::TryParse($value, [ref]$number) -or $number -lt 1 -or $number -gt 15) {
            return 'Enter a whole number from 1 to 15.'
        }
        return $null
    }
    $LimitPerIdentity = [int]$answer
}

if (-not $PSBoundParameters.ContainsKey('SkipTranslationMessages')) {
    $SkipTranslationMessages = -not (Read-YesNo -Prompt 'Include the explanation text' -Default $true)
}

if (-not $PSBoundParameters.ContainsKey('MaxIdentities')) {
    $answer = Read-InputString -Prompt 'Cap the number of identities scanned (0 = all)' -Default '0' -Validate {
        param($value)
        $number = 0
        if (-not [int]::TryParse($value, [ref]$number) -or $number -lt 0) {
            return 'Enter 0 or a positive whole number.'
        }
        return $null
    }
    $MaxIdentities = [int]$answer
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $defaultCsv = Join-Path (Get-Location) ("access-request-recommendations-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $OutputPath = Read-InputString -Prompt 'CSV output path' -Default $defaultCsv
}

if (-not $PSBoundParameters.ContainsKey('HtmlPath')) {
    if (Read-YesNo -Prompt 'Also write a self-contained HTML table' -Default $false) {
        $HtmlPath = Read-InputString -Prompt 'HTML output path' -Default (Join-Path (Get-Location) 'access-request-recommendations.html')
    }
}

Write-Ok ("Scope:        {0}" -f $SearchQuery)
Write-Ok ("Per identity: {0} (explanations {1})" -f $LimitPerIdentity, $(if ($SkipTranslationMessages) { 'off' } else { 'on' }))
Write-Ok ("CSV:          {0}" -f $OutputPath)
if ($HtmlPath) { Write-Ok ("HTML:         {0}" -f $HtmlPath) }

# --- Iterate -----------------------------------------------------------------

$identities = Get-IdentityScope -Query $SearchQuery -Environment $Environment -Max $MaxIdentities
Write-Ok ("Identities:   {0}" -f $identities.Count)

if ($identities.Count -eq 0) {
    Write-Host 'No identities matched the search expression; nothing to do.' -ForegroundColor Yellow
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[object]]::new()
$withRecommendations = 0
$withMessages = -not $SkipTranslationMessages

$index = 0
foreach ($identity in $identities) {
    $index++
    Write-Progress -Activity 'Fetching access request recommendations' -Status $identity.Name -PercentComplete (($index / $identities.Count) * 100)

    try {
        $recommendations = Get-IdentityRecommendations -IdentityId $identity.Id -Environment $Environment -Limit $LimitPerIdentity -WithMessages $withMessages -Retries $MaxRetries -TimeoutSeconds $TimeoutSeconds
    }
    catch {
        $failures.Add([pscustomobject]@{ Identity = $identity.Name; IdentityId = $identity.Id; Error = $_.Exception.Message })
        if ($ThrottleMs -gt 0) { Start-Sleep -Milliseconds $ThrottleMs }
        continue
    }

    $kept = @($recommendations | Where-Object {
            -not ([bool](Get-ObjectPropertySafe -Object $_ -Name 'ignored')) -and
            -not ([bool](Get-ObjectPropertySafe -Object $_ -Name 'requested'))
        })

    if ($kept.Count -gt 0) { $withRecommendations++ }

    foreach ($item in $kept) {
        $access = Get-ObjectPropertySafe -Object $item -Name 'access'
        $rows.Add([pscustomobject][ordered]@{
                Identity    = $identity.Name
                IdentityId  = $identity.Id
                AccessName  = [string](Get-ObjectPropertySafe -Object $access -Name 'name')
                AccessType  = [string](Get-ObjectPropertySafe -Object $access -Name 'type')
                SourceName  = [string](Get-ObjectPropertySafe -Object $access -Name 'sourceName')
                AccessId    = [string](Get-ObjectPropertySafe -Object $access -Name 'id')
                Viewed      = [bool](Get-ObjectPropertySafe -Object $item -Name 'viewed')
                Explanation = Get-RecommendationExplanation -Item $item
            })
    }

    if ($ThrottleMs -gt 0) { Start-Sleep -Milliseconds $ThrottleMs }
}

Write-Progress -Activity 'Fetching access request recommendations' -Completed

# --- Report ------------------------------------------------------------------

if ($rows.Count -gt 0) {
    $rows.ToArray() | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
}
else {
    'Identity,IdentityId,AccessName,AccessType,SourceName,AccessId,Viewed,Explanation' | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
Write-Host ''
Write-Host ("Identities scanned:               {0}" -f $identities.Count)
Write-Host ("Identities with a recommendation: {0}" -f $withRecommendations)
Write-Host ("Recommendations:                  {0}" -f $rows.Count)
Write-Host ("Failures:                         {0}" -f $failures.Count)
Write-Host ("CSV:                              {0}" -f $OutputPath) -ForegroundColor Green

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'Identities that failed (first 20):' -ForegroundColor Yellow
    foreach ($failure in ($failures | Select-Object -First 20)) {
        Write-Host (" - {0}: {1}" -f $failure.Identity, $failure.Error)
    }
}

if ($HtmlPath) {
    $html = New-RecommendationsHtml -Rows $rows.ToArray() -Title ("Access request recommendations - {0}" -f $Environment)
    Set-Content -LiteralPath $HtmlPath -Value $html -Encoding UTF8
    Write-Host ("HTML:                             {0}" -f $HtmlPath) -ForegroundColor Green
}
