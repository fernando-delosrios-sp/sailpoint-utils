param(
    [string] $TemplatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "PowerShell Rule Template.ps1"),
    [string] $HomeFolderPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Active Directory Home Folders/Active Directory Home Folders.ps1")
)

$ErrorActionPreference = "Stop"
$script:AssertionCount = 0
$script:CapturedLogs = @()

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    $script:AssertionCount++
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Assert-Equal {
    param(
        $Expected,
        $Actual,
        [string] $Message
    )

    $script:AssertionCount++
    if ($Expected -ne $Actual) {
        throw "Assertion failed: $Message. Expected '$Expected', got '$Actual'."
    }
}

function Write-RuleLog {
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [string] $Level = "INFO",
        [string] $Phase = $null
    )

    $script:CapturedLogs += "[$Level] $Message"
}

$resolvedTemplatePath = (Resolve-Path -LiteralPath $TemplatePath).Path
$tokens = $null
$parseErrors = $null
$templateAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $resolvedTemplatePath,
    [ref]$tokens,
    [ref]$parseErrors
)
Assert-Equal 0 $parseErrors.Count "the template must parse without syntax errors"

$functionNames = @(
    "Format-RuleErrorRecord",
    "Format-RulePayloadParseError",
    "Write-RuleValue",
    "ConvertFrom-RuleXmlValue",
    "Initialize-ApplicationContext",
    "Initialize-RequestContext",
    "Get-ApplicationAttributes",
    "Get-RuleMapValue",
    "Get-RequestAttribute",
    "Get-ApplicationAttribute",
    "Get-AttributeValueCaseInsensitive"
)

$functionDefinitions = $templateAst.FindAll({
    param($node)
    return ($node -is [System.Management.Automation.Language.FunctionDefinitionAst])
}, $true)

foreach ($functionName in $functionNames) {
    $definition = $functionDefinitions |
        Where-Object { $_.Name -eq $functionName } |
        Select-Object -First 1
    Assert-True ($null -ne $definition) "template function '$functionName' must exist"
    Invoke-Expression $definition.Extent.Text
}

$ctx = [PSCustomObject]@{
    Request = [PSCustomObject]@{
        Operation         = $null
        NativeIdentity    = $null
        Attributes        = @{}
        AttributeRequests = [object[]]@()
    }
    Application = @{}
}

$fixturesDirectory = Join-Path $PSScriptRoot "fixtures"
$env:Application = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "application-bare.xml"))
Initialize-ApplicationContext

Assert-Equal "C:\Homes" $ctx.Application["homefolderbasepath"] "application keys must be case-insensitive"
Assert-Equal "from-child" $ctx.Application["ChildValue"] "child String values must be read"
Assert-True ($ctx.Application["EmptyList"] -is [object[]]) "an empty list must remain an object array"
Assert-Equal 0 $ctx.Application["EmptyList"].Count "an empty list must have zero items"
Assert-True ($ctx.Application["SingleList"] -is [object[]]) "a single-item list must remain an object array"
Assert-Equal 1 $ctx.Application["SingleList"].Count "a single-item list must contain one item"
Assert-Equal "one" $ctx.Application["SingleList"][0] "the single list item must be preserved"
Assert-Equal 2 $ctx.Application["MultiList"].Count "a multi-item list must preserve every item"
Assert-True ($ctx.Application["Complex"] -is [hashtable]) "a nested Map must become a hashtable"
Assert-Equal "nested-path" $ctx.Application["Complex"]["homefolderbasepath"] "nested keys must be case-insensitive"
Assert-Equal "C:\Homes" $ctx.Application["HomeFolderBasePath"] "nested keys must not replace top-level keys"
Assert-True ($ctx.Application["Complex"]["Names"] -is [object[]]) "a nested single-item list must remain an array"
Assert-Equal 2 $ctx.Application["Complex"]["Items"].Count "a list of maps must preserve all maps"
Assert-Equal "second" $ctx.Application["Complex"]["Items"][1]["Name"] "a map inside a list must remain indexable"

$singleList = Get-ApplicationAttribute "singlelist"
Assert-True ($singleList -is [object[]]) "the application helper must preserve a one-item array"
Assert-Equal "fallback" (Get-ApplicationAttribute "missing" "fallback") "the application helper must return its default"
Assert-Equal $null (Get-ApplicationAttribute "missing") "the application helper must return null without a default"

$env:Application = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "application-wrapped.xml"))
Initialize-ApplicationContext
Assert-Equal "wrapped-value" $ctx.Application["WrappedSetting"] "the wrapped Application payload shape must be supported"

$env:Request = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-create.xml"))
Initialize-RequestContext

Assert-Equal "Create" $ctx.Request.Operation "request operation must be exposed"
Assert-Equal "CN=Jane Smith,OU=People,DC=example,DC=com" $ctx.Request.NativeIdentity "native identity must be exposed"
Assert-Equal "jsmith" $ctx.Request.Attributes["SAMACCOUNTNAME"] "request keys must be case-insensitive"
Assert-Equal 3 $ctx.Request.AttributeRequests.Count "all Create attribute requests must be preserved"
Assert-True ($ctx.Request.Attributes["singleGroup"] -is [object[]]) "a request one-item list must remain an array"
Assert-Equal 2 $ctx.Request.Attributes["proxyAddresses"].Count "request multi-values must preserve all items"

$requestSingleList = Get-RequestAttribute "SINGLEGROUP"
Assert-True ($requestSingleList -is [object[]]) "the request helper must preserve a one-item array"
Assert-Equal "fallback" (Get-RequestAttribute "missing" "fallback") "the request helper must return its default"

$env:Request = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-modify.xml"))
Initialize-RequestContext

Assert-Equal "Modify" $ctx.Request.Operation "Modify operation must be exposed"
Assert-Equal 3 $ctx.Request.AttributeRequests.Count "all Modify entries must be preserved"
Assert-Equal "Add" $ctx.Request.AttributeRequests[0].Operation "the first repeated change must preserve Add"
Assert-Equal "Remove" $ctx.Request.AttributeRequests[2].Operation "the later repeated change must preserve Remove"
Assert-Equal "CN=Old Group,OU=Groups,DC=example,DC=com" $ctx.Request.Attributes["memberOf"][0] "the convenience map must use the last repeated value"

$script:CapturedLogs = @()
$env:Application = "<Map><entry key=`"password`" value=`"never-log-this`"></Map>"
Initialize-ApplicationContext
Assert-Equal 0 $ctx.Application.Count "a malformed application payload must leave an empty map"
Assert-True (($script:CapturedLogs -join "`n") -match "Error parsing application attributes") "a malformed application payload must be logged"
Assert-True (($script:CapturedLogs -join "`n") -notmatch "never-log-this") "a malformed payload error must not expose its value"

$script:CapturedLogs = @()
$env:Request = "<AccountRequest op=`"Create`"><AttributeRequest name=`"password`" value=`"never-log-this`"></AccountRequest>"
Initialize-RequestContext
Assert-Equal 0 $ctx.Request.Attributes.Count "a malformed request payload must leave an empty map"
Assert-True (($script:CapturedLogs -join "`n") -match "Error parsing account request") "a malformed request payload must be logged"
Assert-True (($script:CapturedLogs -join "`n") -notmatch "never-log-this") "a malformed request error must not expose its value"

Remove-Item Env:Application, Env:Request -ErrorAction SilentlyContinue
Initialize-ApplicationContext
Initialize-RequestContext
Assert-Equal 0 $ctx.Application.Count "a missing application payload must leave an empty map"
Assert-Equal 0 $ctx.Request.Attributes.Count "a missing request payload must leave an empty map"

function Invoke-TemplateCase {
    param(
        [string] $Name,
        [string] $RequestXml,
        [string] $ApplicationXml,
        [bool] $FailProcess = $false,
        [bool] $UseScriptSilentOverride = $false,
        [bool] $RunReplay = $false
    )

    $caseDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("rule-context-$Name-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $caseDirectory -Force | Out-Null

    $oldRequest = $env:Request
    $oldApplication = $env:Application
    $oldReplayMode = $env:SAILPOINT_RULE_REPLAY
    $hadRequest = Test-Path Env:Request
    $hadApplication = Test-Path Env:Application
    $hadReplayMode = Test-Path Env:SAILPOINT_RULE_REPLAY

    try {
        $caseScript = Join-Path $caseDirectory "Rule.ps1"
        $scriptText = [System.IO.File]::ReadAllText($resolvedTemplatePath)

        if ($FailProcess) {
            $placeholder = 'Write-RuleLog -Level INFO -Message "CUSTOM PROCESS CODE placeholder reached. Replace this section with rule-specific logic."'
            $scriptText = $scriptText.Replace($placeholder, 'throw "fixture process failure"')
        }

        if ($UseScriptSilentOverride) {
            $scriptText = $scriptText.Replace("# `$PwshSilentError = `$false", "`$PwshSilentError = `$false")
        }

        [System.IO.File]::WriteAllText($caseScript, $scriptText, [System.Text.Encoding]::UTF8)
        New-Item -ItemType File -Path (Join-Path $caseDirectory "Utils.dll") -Force | Out-Null

        $env:Request = $RequestXml
        $env:Application = $ApplicationXml
        Remove-Item Env:SAILPOINT_RULE_REPLAY -ErrorAction SilentlyContinue

        $powerShellExecutable = (Get-Process -Id $PID).Path
        & $powerShellExecutable -NoProfile -File $caseScript *> $null
        $exitCode = $LASTEXITCODE

        $artifactsDirectory = Join-Path $caseDirectory "scripts"
        $replayFiles = @(Get-ChildItem -LiteralPath $artifactsDirectory -Filter "*.replay.ps1" -ErrorAction SilentlyContinue)
        $replayExitCode = $null

        if ($RunReplay -and $replayFiles.Count -eq 1) {
            & $powerShellExecutable -NoProfile -File $replayFiles[0].FullName *> $null
            $replayExitCode = $LASTEXITCODE
            $replayFiles = @(Get-ChildItem -LiteralPath $artifactsDirectory -Filter "*.replay.ps1")
        }

        $logText = @(
            Get-ChildItem -LiteralPath $artifactsDirectory -Filter "*.log" -ErrorAction SilentlyContinue |
                ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }
        ) -join "`n"
        $replayText = @(
            $replayFiles | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }
        ) -join "`n"

        return [PSCustomObject]@{
            ExitCode       = $exitCode
            ReplayExitCode = $replayExitCode
            ReplayCount    = $replayFiles.Count
            LogText        = $logText
            ReplayText     = $replayText
            DumpExists     = $null -ne (Get-ChildItem -LiteralPath $artifactsDirectory -Filter "Rule.ps1" -ErrorAction SilentlyContinue)
        }
    } finally {
        if ($hadRequest) { $env:Request = $oldRequest } else { Remove-Item Env:Request -ErrorAction SilentlyContinue }
        if ($hadApplication) { $env:Application = $oldApplication } else { Remove-Item Env:Application -ErrorAction SilentlyContinue }
        if ($hadReplayMode) { $env:SAILPOINT_RULE_REPLAY = $oldReplayMode } else { Remove-Item Env:SAILPOINT_RULE_REPLAY -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $caseDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$createRequest = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-create.xml"))
$normalApplication = "<Map><entry key=`"PwshReplay`" value=`"false`" /></Map>"

$success = Invoke-TemplateCase -Name "success" -RequestXml $createRequest -ApplicationXml $normalApplication
Assert-Equal 0 $success.ExitCode "a successful rule must exit 0"
Assert-True $success.DumpExists "a successful rule must preserve its runtime script"
Assert-True ($success.LogText -match "AccountRequestOperation\s+: Create") "a full run must log the hydrated request operation"

$failure = Invoke-TemplateCase -Name "failure" -RequestXml $createRequest -ApplicationXml $normalApplication -FailProcess $true
Assert-Equal 1 $failure.ExitCode "a process failure must exit 1 by default"

$silentApplication = "<Map><entry key=`"PwshSilentError`" value=`"true`" /></Map>"
$silentFailure = Invoke-TemplateCase -Name "silent" -RequestXml $createRequest -ApplicationXml $silentApplication -FailProcess $true
Assert-Equal 0 $silentFailure.ExitCode "PwshSilentError=true must convert a process failure to exit 0"
Assert-True ($silentFailure.LogText -match "PwshSilentError\s+: True \(application\)") "application option source must be preserved"

$scriptOverride = Invoke-TemplateCase -Name "override" -RequestXml $createRequest -ApplicationXml $silentApplication -FailProcess $true -UseScriptSilentOverride $true
Assert-Equal 1 $scriptOverride.ExitCode "a script option must override the application option"
Assert-True ($scriptOverride.LogText -match "PwshSilentError\s+: False \(script\)") "script option source must be preserved"

$secret = "rule-context-secret"
$replayApplication = "<Map><entry key=`"PwshReplay`" value=`"true`" /><entry key=`"password`" value=`"$secret`" /></Map>"
$replay = Invoke-TemplateCase -Name "replay" -RequestXml $createRequest -ApplicationXml $replayApplication -RunReplay $true
Assert-Equal 0 $replay.ExitCode "a replay-enabled rule must exit 0"
Assert-Equal 0 $replay.ReplayExitCode "the generated replay must exit 0"
Assert-Equal 1 $replay.ReplayCount "replay mode must not create a nested replay"
Assert-True ($replay.ReplayText -match "\[REDACTED\]") "the replay must contain a redacted secret"
Assert-True ($replay.ReplayText -notmatch $secret) "the replay must not contain the raw secret"
Assert-True ($replay.LogText -notmatch $secret) "logs must not contain the raw secret"

$malformedSecret = "malformed-rule-context-secret"
$malformedApplication = "<Map><entry key=`"password`" value=`"$malformedSecret`"></Map>"
$malformed = Invoke-TemplateCase -Name "malformed" -RequestXml $createRequest -ApplicationXml $malformedApplication
Assert-Equal 0 $malformed.ExitCode "a malformed application payload must not fail otherwise successful process code"
Assert-True ($malformed.LogText -match "Error parsing application attributes") "a full malformed-input run must log the parse error"
Assert-True ($malformed.LogText -notmatch $malformedSecret) "a full malformed-input run must not leak the malformed secret"

$resolvedHomeFolderPath = (Resolve-Path -LiteralPath $HomeFolderPath).Path
$homeTokens = $null
$homeParseErrors = $null
$homeAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $resolvedHomeFolderPath,
    [ref]$homeTokens,
    [ref]$homeParseErrors
)
Assert-Equal 0 $homeParseErrors.Count "the Home Folders rule must parse without syntax errors"

$homeFunctionDefinitions = $homeAst.FindAll({
    param($node)
    return ($node -is [System.Management.Automation.Language.FunctionDefinitionAst])
}, $true)

foreach ($functionName in @("Get-AccountRequestAttributeMap", "Expand-HomeFolderTemplate")) {
    $definition = $homeFunctionDefinitions |
        Where-Object { $_.Name -eq $functionName } |
        Select-Object -First 1
    Assert-True ($null -ne $definition) "Home Folders function '$functionName' must exist"
    Invoke-Expression $definition.Extent.Text
}

$env:Request = $createRequest
Initialize-RequestContext
$homeAttributes = Get-AccountRequestAttributeMap
Assert-Equal "jsmith" $homeAttributes["sAMAccountName"] "Home Folders must use hydrated request attributes"
Assert-Equal $ctx.Request.NativeIdentity $homeAttributes["nativeIdentity"] "Home Folders must retain nativeIdentity template support"
Assert-Equal "Sales\Personal\jsmith" (Expand-HomeFolderTemplate '$department\Personal\$sAMAccountName' (@{
    department    = "Sales"
    sAMAccountName = "jsmith"
})) "Home Folders must expand request attribute placeholders"

function Invoke-HomeFolderSkipCase {
    $caseDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("home-folder-context-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $caseDirectory -Force | Out-Null

    $oldRequest = $env:Request
    $oldApplication = $env:Application
    $hadRequest = Test-Path Env:Request
    $hadApplication = Test-Path Env:Application

    try {
        $caseScript = Join-Path $caseDirectory "HomeFolders.ps1"
        Copy-Item -LiteralPath $resolvedHomeFolderPath -Destination $caseScript
        New-Item -ItemType File -Path (Join-Path $caseDirectory "Utils.dll") -Force | Out-Null

        $env:Request = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-modify.xml"))
        $env:Application = "<Map><entry key=`"HomeFolderDebugEnabled`" value=`"true`" /></Map>"

        $powerShellExecutable = (Get-Process -Id $PID).Path
        & $powerShellExecutable -NoProfile -File $caseScript *> $null
        $exitCode = $LASTEXITCODE

        $logText = @(
            Get-ChildItem -LiteralPath (Join-Path $caseDirectory "scripts") -Filter "*.log" |
                ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }
        ) -join "`n"

        return [PSCustomObject]@{
            ExitCode = $exitCode
            LogText  = $logText
        }
    } finally {
        if ($hadRequest) { $env:Request = $oldRequest } else { Remove-Item Env:Request -ErrorAction SilentlyContinue }
        if ($hadApplication) { $env:Application = $oldApplication } else { Remove-Item Env:Application -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $caseDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$homeFolderSkip = Invoke-HomeFolderSkipCase
Assert-Equal 0 $homeFolderSkip.ExitCode "Home Folders must skip non-Create requests successfully"
Assert-True ($homeFolderSkip.LogText -match "Current operation: Modify") "Home Folders must use the hydrated operation"
Assert-True ($homeFolderSkip.LogText -notmatch "Loaded SailPoint Utils|Utils.dll could not be loaded") "Home Folders must not load Utils.dll"

$analyzer = Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
if ($analyzer) {
    $compatibilitySettings = @{
        Rules = @{
            PSUseCompatibleSyntax = @{
                Enable         = $true
                TargetVersions = @("5.1")
            }
        }
    }
    foreach ($path in @($resolvedTemplatePath, $resolvedHomeFolderPath)) {
        $compatibilityProblems = @(
            Invoke-ScriptAnalyzer -Path $path -Settings $compatibilitySettings |
                Where-Object { $_.RuleName -eq "PSUseCompatibleSyntax" }
        )
        Assert-Equal 0 $compatibilityProblems.Count "'$path' syntax must be compatible with Windows PowerShell 5.1"
    }
}

Write-Host "PASS: $script:AssertionCount assertions"
