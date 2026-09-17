param(
    [string] $TemplatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "PowerShell Rule Template.ps1"),
    [string] $HomeFolderPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Active Directory Home Folders/ConnectorAfterCreate - Create Active Directory Home Folder.ps1"),
    [string] $OuCreatePath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Active Directory OU Management/ConnectorBeforeCreate - Create Active Directory OU.ps1"),
    [string] $OuModifyPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Active Directory OU Management/ConnectorBeforeModify - Create Active Directory OU.ps1"),
    [string] $SharedFolderPath = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "Active Directory Privileged Tasks/ConnectorBeforeModify - Create Shared Folder in Active Directory.ps1")
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

$resolvedOuCreatePath = (Resolve-Path -LiteralPath $OuCreatePath).Path
$resolvedOuModifyPath = (Resolve-Path -LiteralPath $OuModifyPath).Path

foreach ($ouPath in @($resolvedOuCreatePath, $resolvedOuModifyPath)) {
    $ouTokens = $null
    $ouParseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($ouPath, [ref]$ouTokens, [ref]$ouParseErrors)
    Assert-Equal 0 $ouParseErrors.Count "OU rule '$ouPath' must parse without syntax errors"
}

$ouCreateTokens = $null
$ouCreateParseErrors = $null
$ouCreateAst = [System.Management.Automation.Language.Parser]::ParseFile($resolvedOuCreatePath, [ref]$ouCreateTokens, [ref]$ouCreateParseErrors)
$ouFunctionDefinitions = $ouCreateAst.FindAll({
    param($node)
    return ($node -is [System.Management.Automation.Language.FunctionDefinitionAst])
}, $true)

$splitOuDefinition = $ouFunctionDefinitions |
    Where-Object { $_.Name -eq "Split-OrganizationalUnitPath" } |
    Select-Object -First 1
Assert-True ($null -ne $splitOuDefinition) "OU management function 'Split-OrganizationalUnitPath' must exist"
Invoke-Expression $splitOuDefinition.Extent.Text

$createTarget = Split-OrganizationalUnitPath -DistinguishedName "CN=Jane Smith,OU=People,DC=example,DC=com"
Assert-Equal 1 $createTarget.OrganizationalUnits.Count "Create NativeIdentity must yield one OU component"
Assert-Equal "OU=People" $createTarget.OrganizationalUnits[0] "Create NativeIdentity must ignore the CN RDN"
Assert-Equal "DC=example,DC=com" $createTarget.BasePath "Create NativeIdentity must keep domain components as the base path"

$moveTarget = Split-OrganizationalUnitPath -DistinguishedName "OU=Sales,OU=People,DC=example,DC=com"
Assert-Equal 2 $moveTarget.OrganizationalUnits.Count "AC_NewParent must preserve every OU RDN"
Assert-Equal "OU=Sales" $moveTarget.OrganizationalUnits[0] "AC_NewParent must keep leaf-first DN order before reverse"
Assert-Equal "DC=example,DC=com" $moveTarget.BasePath "AC_NewParent must keep domain components as the base path"

$escapedTarget = Split-OrganizationalUnitPath -DistinguishedName "OU=Sales\, West,OU=People,DC=example,DC=com"
Assert-Equal "OU=Sales\, West" $escapedTarget.OrganizationalUnits[0] "escaped commas in an OU name must not split the DN"

function Invoke-OuRuleCase {
    param(
        [string] $ScriptPath,
        [string] $RequestXml,
        [string] $ApplicationXml
    )

    $caseDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("ou-management-context-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $caseDirectory -Force | Out-Null

    $oldRequest = $env:Request
    $oldApplication = $env:Application
    $hadRequest = Test-Path Env:Request
    $hadApplication = Test-Path Env:Application

    try {
        $caseScript = Join-Path $caseDirectory "OuManagement.ps1"
        Copy-Item -LiteralPath $ScriptPath -Destination $caseScript
        New-Item -ItemType File -Path (Join-Path $caseDirectory "Utils.dll") -Force | Out-Null

        $env:Request = $RequestXml
        $env:Application = $ApplicationXml

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

$ouCreateDisabled = Invoke-OuRuleCase -ScriptPath $resolvedOuCreatePath -RequestXml $createRequest -ApplicationXml "<Map><entry key=`"OUDebugEnabled`" value=`"true`" /></Map>"
Assert-Equal 0 $ouCreateDisabled.ExitCode "OU Create must skip when OUCreationEnabled is omitted"
Assert-True ($ouCreateDisabled.LogText -match "OUCreationEnabled is not true") "OU Create must log the disabled skip"
Assert-True ($ouCreateDisabled.LogText -match "ConnectorBeforeCreate") "OU Create must log its connector rule type"
Assert-True ($ouCreateDisabled.LogText -notmatch "Loaded SailPoint Utils|Utils.dll could not be loaded") "OU Create must not load Utils.dll"

$ouModifyEmptyParent = Invoke-OuRuleCase -ScriptPath $resolvedOuModifyPath -RequestXml ([System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-modify.xml"))) -ApplicationXml "<Map><entry key=`"OUCreationEnabled`" value=`"true`" /><entry key=`"OUDebugEnabled`" value=`"true`" /></Map>"
Assert-Equal 0 $ouModifyEmptyParent.ExitCode "OU Modify must skip when AC_NewParent is absent"
Assert-True ($ouModifyEmptyParent.LogText -match "Target distinguished name is empty") "OU Modify must use Get-RequestAttribute AC_NewParent"
Assert-True ($ouModifyEmptyParent.LogText -match "ConnectorBeforeModify") "OU Modify must log its connector rule type"
Assert-True ($ouModifyEmptyParent.LogText -notmatch "Import-Module") "OU Modify must not import ActiveDirectory when the target DN is empty"

$resolvedSharedFolderPath = (Resolve-Path -LiteralPath $SharedFolderPath).Path
$sharedTokens = $null
$sharedParseErrors = $null
$sharedAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $resolvedSharedFolderPath,
    [ref]$sharedTokens,
    [ref]$sharedParseErrors
)
Assert-Equal 0 $sharedParseErrors.Count "the shared-folder rule must parse without syntax errors"

$sharedFunctionDefinitions = $sharedAst.FindAll({
    param($node)
    return ($node -is [System.Management.Automation.Language.FunctionDefinitionAst])
}, $true)

foreach ($functionName in @("Get-SharedFolderRequestComments", "ConvertFrom-SharedFolderMetadata", "Assert-SharedFolderParentAllowed")) {
    $definition = $sharedFunctionDefinitions |
        Where-Object { $_.Name -eq $functionName } |
        Select-Object -First 1
    Assert-True ($null -ne $definition) "shared-folder rule function '$functionName' must exist"
    Invoke-Expression $definition.Extent.Text
}

$env:Request = [System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-shared-folder.xml"))
$sharedComments = Get-SharedFolderRequestComments
Assert-True ($sharedComments -match '"shareName":"finance"') "shared-folder rule must read memberOf comments from the account request XML"
$sharedMetadata = ConvertFrom-SharedFolderMetadata -Comments $sharedComments
Assert-Equal "finance" $sharedMetadata.FolderName "shared-folder rule must parse folderName"
Assert-Equal "finance" $sharedMetadata.ShareName "shared-folder rule must parse shareName"
Assert-Equal "C:\Shared folders\finance" $sharedMetadata.FullPath "shared-folder rule must join parent and folder without requiring a local C: drive"

Assert-SharedFolderParentAllowed -ParentFolder "C:\Shared folders" -AllowedPaths @("D:\Department shares", "C:\Shared folders")
$disallowedParentRejected = $false
try {
    Assert-SharedFolderParentAllowed -ParentFolder "C:\Other" -AllowedPaths @("C:\Shared folders")
} catch {
    $disallowedParentRejected = $true
}
Assert-True $disallowedParentRejected "shared-folder rule must reject parent folders outside the source allowlist"

foreach ($invalidMetadata in @(
    '{"folderName":"..","parentFolder":"C:\\Shared folders","shareName":"finance"}',
    '{"folderName":"Finance/Reports","parentFolder":"C:\\Shared folders","shareName":"finance"}',
    '{"folderName":"Finance","parentFolder":"relative","shareName":"finance"}',
    '{"folderName":"Finance","parentFolder":"C:\\Shared folders","shareName":"finance reports"}',
    '{"folderName":"Finance","parentFolder":"C:\\Shared folders","shareName":"abcdefghijklmnopqrstuvwxyz123456789012345"}'
)) {
    $rejected = $false
    try {
        [void](ConvertFrom-SharedFolderMetadata -Comments $invalidMetadata)
    } catch {
        $rejected = $true
    }
    Assert-True $rejected "shared-folder rule must reject unsafe or unsupported metadata: $invalidMetadata"
}

$sharedFolderSkip = Invoke-OuRuleCase -ScriptPath $resolvedSharedFolderPath -RequestXml $createRequest -ApplicationXml "<Map><entry key=`"SharedFolderDebugEnabled`" value=`"true`" /></Map>"
Assert-Equal 0 $sharedFolderSkip.ExitCode "shared-folder rule must skip non-Modify requests successfully"
Assert-True ($sharedFolderSkip.LogText -match "Current operation: Create") "shared-folder rule must use the hydrated operation"
Assert-True ($sharedFolderSkip.LogText -match "ConnectorBeforeModify") "shared-folder rule must log its connector rule type"
Assert-True ($sharedFolderSkip.LogText -notmatch "Loaded SailPoint Utils|Utils.dll could not be loaded") "shared-folder rule must not load Utils.dll"
Assert-True ($sharedFolderSkip.LogText -notmatch "Import-Module") "shared-folder rule must not import ActiveDirectory when skipping"

$sharedFolderNoComments = Invoke-OuRuleCase -ScriptPath $resolvedSharedFolderPath -RequestXml ([System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-modify.xml"))) -ApplicationXml "<Map />"
Assert-Equal 0 $sharedFolderNoComments.ExitCode "shared-folder rule must skip Modify requests without metadata comments"
Assert-True ($sharedFolderNoComments.LogText -match "No memberOf comments") "shared-folder rule must log the missing-comments skip"
Assert-True ($sharedFolderNoComments.LogText -notmatch "Import-Module") "shared-folder rule must not import ActiveDirectory when comments are absent"

$sharedFolderOrdinaryComment = Invoke-OuRuleCase -ScriptPath $resolvedSharedFolderPath -RequestXml ([System.IO.File]::ReadAllText((Join-Path $fixturesDirectory "request-modify-memberof-comment.xml"))) -ApplicationXml "<Map />"
Assert-Equal 0 $sharedFolderOrdinaryComment.ExitCode "shared-folder rule must skip Modify requests whose memberOf comments are not shared-folder JSON"
Assert-True ($sharedFolderOrdinaryComment.LogText -match "not shared-folder metadata") "shared-folder rule must log the ordinary-comment skip"
Assert-True ($sharedFolderOrdinaryComment.LogText -notmatch "Process error") "shared-folder rule must not treat ordinary memberOf comments as a process failure"
Assert-True ($sharedFolderOrdinaryComment.LogText -notmatch "Import-Module") "shared-folder rule must not import ActiveDirectory for ordinary memberOf comments"

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
    foreach ($path in @($resolvedTemplatePath, $resolvedHomeFolderPath, $resolvedOuCreatePath, $resolvedOuModifyPath, $resolvedSharedFolderPath)) {
        $compatibilityProblems = @(
            Invoke-ScriptAnalyzer -Path $path -Settings $compatibilitySettings |
                Where-Object { $_.RuleName -eq "PSUseCompatibleSyntax" }
        )
        Assert-Equal 0 $compatibilityProblems.Count "'$path' syntax must be compatible with Windows PowerShell 5.1"
    }
}

Write-Host "PASS: $script:AssertionCount assertions"
