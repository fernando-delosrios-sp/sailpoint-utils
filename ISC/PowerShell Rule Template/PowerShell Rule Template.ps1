###############################################################################################################################
# ISC IQService PowerShell Connector Rule Template
#
# Copy this file as the starting point for ConnectorBeforeCreate, ConnectorBeforeModify, ConnectorBeforeDelete,
# ConnectorAfterCreate, ConnectorAfterModify, and ConnectorAfterDelete rules on Active Directory and Azure AD.
#
# Upload the finished script as a Connector Rule using the SailPoint Identity Security Cloud VS Code extension:
# https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow
# Attach the rule to your source through connectorAttributes.nativeRules.
#
# APPLICATION ATTRIBUTES (connectorAttributes on the source). Defaults are false when omitted.
# Script variables of the same name, if defined, take precedence over these attributes.
#   - PwshSilentError (boolean): When true, process failures exit 0 and IQService reports success.
#   - PwshUnsafePayloadLogging (boolean): When true, logs and replay scripts store raw payloads.
#   - PwshReplay (boolean): When true, write a timestamped .replay.ps1 next to the log for this run.
#
# SailPoint documentation:
# https://developer.sailpoint.com/docs/extensibility/rules/connector-rules
#
# IQService copies each uploaded rule to a generated runtime file named Script_<GUID>.ps1 in the IQService folder.
# This template preserves that runtime script, a self-contained replay script with Request/Application
# context, and a per-run log under <IQService>\scripts.
#
# CUSTOM CODE INPUTS:
#   - $ctx.Request.Operation / NativeIdentity / Attributes / AttributeRequests
#   - $ctx.Application["SourceAttributeName"]
#   - Get-RequestAttribute "name" [default]
#   - Get-ApplicationAttribute "name" [default]
# $ctx is reserved. Do not assign a new value to it.
###############################################################################################################################

###############################################################################################################################
# CONFIGURATION - edit these constants when you copy this template
###############################################################################################################################

# Set this to match the connector rule type configured in ISC for this script.
# Allowed values:
#   ConnectorBeforeCreate, ConnectorBeforeModify, ConnectorBeforeDelete
#   ConnectorAfterCreate, ConnectorAfterModify, ConnectorAfterDelete
$ConnectorRuleType = "ConnectorAfterCreate"

# Optional display name from the ISC connector rule. Used as the artifact filename prefix when set; otherwise the runtime GUID is used.
$ConnectorRuleName = ""

# Optional script overrides. Define any of these to take precedence over the source connectorAttributes
# of the same name (PwshSilentError, PwshUnsafePayloadLogging, PwshReplay). Leave them undefined
# to use the application attributes, which default to false.
# $PwshSilentError = $false
# $PwshUnsafePayloadLogging = $false
# $PwshReplay = $false

# Relative folder under the IQService install directory where script dumps and logs are stored.
$ScriptsSubfolder = "scripts"

###############################################################################################################################
# RUNTIME CONTEXT - $ctx is reserved; do not reassign it in copied rules
###############################################################################################################################

$ctx = [PSCustomObject]@{
    Request = [PSCustomObject]@{
        Operation         = $null
        NativeIdentity    = $null
        Attributes        = @{}
        AttributeRequests = [object[]]@()
    }
    Application = @{}
    Options = [PSCustomObject]@{
        PwshSilentError                = $false
        PwshSilentErrorSource          = "default"
        PwshUnsafePayloadLogging       = $false
        PwshUnsafePayloadLoggingSource = "default"
        PwshReplay                     = $false
        PwshReplaySource               = "default"
    }
    Runtime = [PSCustomObject]@{
        LogFile                  = $null
        EmergencyLogFile         = $null
        ArtifactsDirectory       = $null
        BaseName                 = $null
        ScriptPath               = $null
        ScriptResolved           = $false
        ScriptReason             = $null
        ScriptDumpPath           = $null
        ReplayScriptPath         = $null
        IQServiceDirectory       = $null
        IQServiceDirectorySource = $null
        Phase                    = "bootstrap"
        ReplayMode               = $false
    }
}

###############################################################################################################################
# HELPER FUNCTIONS
###############################################################################################################################

function Test-ConnectorRuleTypeConfigured {
    param([string] $RuleType)

    $validTypes = @(
        "ConnectorBeforeCreate",
        "ConnectorBeforeModify",
        "ConnectorBeforeDelete",
        "ConnectorAfterCreate",
        "ConnectorAfterModify",
        "ConnectorAfterDelete"
    )

    if ([string]::IsNullOrWhiteSpace($RuleType)) {
        return $false
    }

    return ($validTypes -contains $RuleType)
}

function Get-AccountRequestOperation {
    return $ctx.Request.Operation
}

function Write-RuleLog {
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")][string] $Level = "INFO",
        [string] $Phase = $null
    )

    $activePhase = $Phase
    if ([string]::IsNullOrWhiteSpace($activePhase)) {
        $activePhase = $ctx.Runtime.Phase
    }

    $timestampLocal = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $timestampUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.fff")
    $line = "[$timestampLocal | $timestampUtc UTC] [$Level] [$activePhase] $Message"

    $targets = @()
    if ($ctx.Runtime.LogFile) { $targets += $ctx.Runtime.LogFile }
    if ($ctx.Runtime.EmergencyLogFile) { $targets += $ctx.Runtime.EmergencyLogFile }

    foreach ($target in $targets) {
        try {
            [System.IO.File]::AppendAllText($target, ($line + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
        } catch {
            # Keep trying remaining targets.
        }
    }

    if (-not $ctx.Runtime.LogFile -and -not $ctx.Runtime.EmergencyLogFile) {
        try {
            Write-Host $line
        } catch {
            # IQService may not surface host output.
        }
    }
}

function Format-RuleErrorRecord($errorRecord) {
    if (-not $errorRecord) {
        return "<no error record>"
    }

    $message = $errorRecord.Exception.Message
    $itemName = $errorRecord.Exception.ItemName
    $category = $errorRecord.CategoryInfo
    $position = $errorRecord.InvocationInfo.PositionMessage

    return "Message = $message | Item = $itemName | Category = $category | Position = $position"
}

function Format-RulePayloadParseError($errorRecord) {
    if (-not $errorRecord -or -not $errorRecord.Exception) {
        return "<no parse error>"
    }

    $exception = $errorRecord.Exception
    while ($exception.InnerException) {
        $exception = $exception.InnerException
    }

    return "$($exception.GetType().Name): $($exception.Message)"
}

function Get-TextSha256([string] $text) {
    if ($null -eq $text) {
        return "<null>"
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
}

function Get-FileSha256([string] $path) {
    if (-not (Test-Path -LiteralPath $path)) {
        return "<missing>"
    }

    $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

function Get-RuleArtifactBaseName {
    param([string] $FallbackBaseName)

    if (-not [string]::IsNullOrWhiteSpace($ConnectorRuleName)) {
        $sanitized = $ConnectorRuleName.Trim()
        foreach ($invalidChar in [System.IO.Path]::GetInvalidFileNameChars()) {
            $sanitized = $sanitized.Replace("$invalidChar", "_")
        }

        if (-not [string]::IsNullOrWhiteSpace($sanitized)) {
            return $sanitized
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($FallbackBaseName)) {
        return $FallbackBaseName
    }

    return "RuleTemplate"
}

function Write-RuleValue {
    param($Value)

    if ($Value -is [System.Array]) {
        Write-Output -NoEnumerate $Value
        return
    }

    return $Value
}

function ConvertFrom-RuleXmlValue {
    param([System.Xml.XmlElement] $Node)

    if ($null -eq $Node) {
        return $null
    }

    if ($Node.HasAttribute("value")) {
        return $Node.GetAttribute("value")
    }

    $nodeName = $Node.LocalName
    if ($nodeName -eq "entry" -or $nodeName -eq "AttributeRequest") {
        $valueNode = $Node.SelectSingleNode("./value")
        if (-not $valueNode) {
            return $null
        }
        $value = ConvertFrom-RuleXmlValue -Node $valueNode
        Write-RuleValue $value
        return
    }

    if ($nodeName -eq "Map") {
        $map = @{}
        foreach ($entry in $Node.SelectNodes("./entry")) {
            $key = $entry.GetAttribute("key")
            if (-not [string]::IsNullOrWhiteSpace($key)) {
                $map[$key] = ConvertFrom-RuleXmlValue -Node $entry
            }
        }
        return $map
    }

    if ($nodeName -eq "List") {
        $items = New-Object System.Collections.ArrayList
        foreach ($child in $Node.ChildNodes) {
            if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                [void]$items.Add((ConvertFrom-RuleXmlValue -Node $child))
            }
        }
        Write-RuleValue ([object[]]$items.ToArray())
        return
    }

    $elementChildren = @(
        $Node.ChildNodes | Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
    )

    if ($elementChildren.Count -eq 1) {
        $value = ConvertFrom-RuleXmlValue -Node $elementChildren[0]
        Write-RuleValue $value
        return
    }

    if ($elementChildren.Count -gt 1) {
        $items = New-Object System.Collections.ArrayList
        foreach ($child in $elementChildren) {
            [void]$items.Add((ConvertFrom-RuleXmlValue -Node $child))
        }
        Write-RuleValue ([object[]]$items.ToArray())
        return
    }

    return $Node.InnerText.Trim()
}

function Initialize-ApplicationContext {
    $ctx.Application = @{}

    if ([string]::IsNullOrWhiteSpace($env:Application)) {
        Write-RuleLog -Level WARN -Message "env:Application is null or empty. No source attributes are available."
        return
    }

    try {
        $appXml = [xml]$env:Application

        # IQService normally sends a bare <Map> root. Only select TOP-LEVEL entries:
        # nested maps keep their own keys and cannot overwrite source attributes.
        $entries = $null
        foreach ($xpath in @("/Map/entry", "/Application/Attributes/Map/entry", "//Attributes/Map/entry")) {
            $candidate = $appXml.SelectNodes($xpath)
            if ($candidate -and $candidate.Count -gt 0) {
                $entries = $candidate
                Write-RuleLog -Level INFO -Message "Source attributes read using XPath '$xpath' ($($candidate.Count) entries)."
                break
            }
        }

        if (-not $entries) {
            $rootName = $(if ($appXml.DocumentElement) { $appXml.DocumentElement.Name } else { "<none>" })
            Write-RuleLog -Level WARN -Message "No source attributes found in env:Application. Root element is '$rootName', which none of the known payload shapes match."
            return
        }

        foreach ($entry in $entries) {
            $key = $entry.GetAttribute("key")
            if (-not [string]::IsNullOrWhiteSpace($key)) {
                $ctx.Application[$key] = ConvertFrom-RuleXmlValue -Node $entry
            }
        }
    } catch {
        $ctx.Application = @{}
        Write-RuleLog -Level ERROR -Message "Error parsing application attributes: $(Format-RulePayloadParseError $_)"
    }
}

function Initialize-RequestContext {
    $ctx.Request.Operation = $null
    $ctx.Request.NativeIdentity = $null
    $ctx.Request.Attributes = @{}
    $ctx.Request.AttributeRequests = [object[]]@()

    if ([string]::IsNullOrWhiteSpace($env:Request)) {
        Write-RuleLog -Level WARN -Message "env:Request is null or empty. No account request is available."
        return
    }

    try {
        $requestXml = [xml]$env:Request
        $accountRequest = $requestXml.SelectSingleNode("/AccountRequest")
        if (-not $accountRequest) {
            $accountRequest = $requestXml.SelectSingleNode("//AccountRequest")
        }
        if (-not $accountRequest) {
            Write-RuleLog -Level WARN -Message "No AccountRequest element found in env:Request."
            return
        }

        $ctx.Request.Operation = $accountRequest.GetAttribute("op")
        $ctx.Request.NativeIdentity = $accountRequest.GetAttribute("nativeIdentity")

        $requests = New-Object System.Collections.ArrayList
        foreach ($attributeRequest in $accountRequest.SelectNodes("./AttributeRequest")) {
            $name = $attributeRequest.GetAttribute("name")
            if ([string]::IsNullOrWhiteSpace($name)) {
                continue
            }

            $value = ConvertFrom-RuleXmlValue -Node $attributeRequest
            $request = [PSCustomObject]@{
                Name      = $name
                Operation = $attributeRequest.GetAttribute("op")
                Value     = $value
            }
            [void]$requests.Add($request)
            $ctx.Request.Attributes[$name] = $value
        }

        $ctx.Request.AttributeRequests = [object[]]$requests.ToArray()
    } catch {
        $ctx.Request.Operation = $null
        $ctx.Request.NativeIdentity = $null
        $ctx.Request.Attributes = @{}
        $ctx.Request.AttributeRequests = [object[]]@()
        Write-RuleLog -Level ERROR -Message "Error parsing account request: $(Format-RulePayloadParseError $_)"
    }
}

function Get-ApplicationAttributes {
    return $ctx.Application
}

function Get-RuleMapValue {
    param(
        [hashtable] $Map,
        [Parameter(Mandatory = $true, Position = 0)][string] $Name,
        [Parameter(Position = 1)] $Default = $null
    )

    if ($null -ne $Map -and $Map.ContainsKey($Name)) {
        Write-RuleValue ($Map[$Name])
        return
    }

    Write-RuleValue $Default
}

function Get-RequestAttribute {
    param(
        [Parameter(Mandatory = $true, Position = 0)][string] $Name,
        [Parameter(Position = 1)] $Default = $null
    )

    $value = Get-RuleMapValue -Map $ctx.Request.Attributes -Name $Name -Default $Default
    Write-RuleValue $value
}

function Get-ApplicationAttribute {
    param(
        [Parameter(Mandatory = $true, Position = 0)][string] $Name,
        [Parameter(Position = 1)] $Default = $null
    )

    $value = Get-RuleMapValue -Map $ctx.Application -Name $Name -Default $Default
    Write-RuleValue $value
}

function Get-AttributeValueCaseInsensitive([hashtable] $attributes, [String] $name) {
    $value = Get-RuleMapValue -Map $attributes -Name $name
    Write-RuleValue $value
}

function ConvertTo-RuleBoolean {
    param(
        $Value,
        [bool] $Default = $false
    )

    if ($Value -is [bool]) {
        return [bool]$Value
    }

    if ($null -eq $Value) {
        return $Default
    }

    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $Default
    }

    if ($text -match '^(?i)(true|1|yes)$') {
        return $true
    }

    if ($text -match '^(?i)(false|0|no)$') {
        return $false
    }

    Write-RuleLog -Level WARN -Message "Could not parse '$text' as boolean. Using $Default."
    return $Default
}

function Get-ScriptVariableIfDefined {
    param([Parameter(Mandatory = $true)][string] $Name)

    $variable = Get-Variable -Name $Name -Scope Script -ErrorAction SilentlyContinue
    if ($null -ne $variable) {
        return $variable
    }

    return (Get-Variable -Name $Name -ErrorAction SilentlyContinue)
}

function Resolve-RuleBooleanOption {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [bool] $Default = $false
    )

    $scriptVariable = Get-ScriptVariableIfDefined -Name $Name
    if ($null -ne $scriptVariable) {
        $value = ConvertTo-RuleBoolean -Value $scriptVariable.Value -Default $Default
        Write-RuleLog -Level INFO -Phase bootstrap -Message ("{0} : {1} (script variable)" -f $Name, $value)
        return @{ Value = $value; Source = "script" }
    }

    $appRaw = Get-ApplicationAttribute -Name $Name
    if (-not [string]::IsNullOrWhiteSpace([string]$appRaw)) {
        $value = ConvertTo-RuleBoolean -Value $appRaw -Default $Default
        Write-RuleLog -Level INFO -Phase bootstrap -Message ("{0} : {1} (application attribute)" -f $Name, $value)
        return @{ Value = $value; Source = "application" }
    }

    Write-RuleLog -Level INFO -Phase bootstrap -Message ("{0} : {1} (default)" -f $Name, $Default)
    return @{ Value = $Default; Source = "default" }
}

function Initialize-RuleOptions {
    $silent = Resolve-RuleBooleanOption -Name "PwshSilentError" -Default $false
    $unsafe = Resolve-RuleBooleanOption -Name "PwshUnsafePayloadLogging" -Default $false
    $replay = Resolve-RuleBooleanOption -Name "PwshReplay" -Default $false

    $ctx.Options.PwshSilentError = $silent.Value
    $ctx.Options.PwshSilentErrorSource = $silent.Source
    $ctx.Options.PwshUnsafePayloadLogging = $unsafe.Value
    $ctx.Options.PwshUnsafePayloadLoggingSource = $unsafe.Source
    $ctx.Options.PwshReplay = $replay.Value
    $ctx.Options.PwshReplaySource = $replay.Source
}

# Only the script dump and the replay script need the runtime path. Logging must not depend on it,
# so an unresolvable path is reported rather than thrown: IQService can execute a rule body without
# leaving a backing .ps1 file, and that must not cost us the log.
function Resolve-RuntimeScriptIdentity {
    param([string] $ScriptPath)

    $identity = @{
        ScriptPath = $null
        FileName   = $null
        BaseName   = $null
        Resolved   = $false
        Reason     = $null
    }

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        $identity.Reason = "Both `$PSCommandPath and `$MyInvocation.MyCommand.Path were empty, so IQService ran this rule without a backing script file."
        return $identity
    }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        $identity.Reason = "Runtime script path does not exist: '$ScriptPath'"
        return $identity
    }

    $resolvedPath = (Resolve-Path -LiteralPath $ScriptPath).Path
    $fileName = Split-Path -Path $resolvedPath -Leaf

    $identity.ScriptPath = $resolvedPath
    $identity.FileName = $fileName
    $identity.BaseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $identity.Resolved = $true

    return $identity
}

function Test-LooksLikeIQServiceDirectory {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    foreach ($marker in @("IQService.exe", "Utils.dll")) {
        if (Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $marker)) {
            return $true
        }
    }

    return $false
}

function Expand-IQServiceDirectoryCandidates {
    param([string[]] $Paths)

    $expanded = @()
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $expanded += $path

        try {
            $parent = Split-Path -Path $path -Parent
            if (-not [string]::IsNullOrWhiteSpace($parent)) {
                $expanded += $parent
            }
        } catch {
            # Ignore.
        }
    }

    return $expanded
}

function Resolve-IQServiceDirectory {
    param([string] $preferredPath)

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($preferredPath)) {
        $candidates += $preferredPath
    }

    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += $PSScriptRoot
    }

    try {
        $workingDirectory = (Get-Location).Path
        if (-not [string]::IsNullOrWhiteSpace($workingDirectory)) {
            $candidates += $workingDirectory
        }
    } catch {
        # Ignore.
    }

    try {
        $serviceKeys = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services" -ErrorAction Stop |
            Where-Object { $_.PSChildName -like "*IQService*" }

        foreach ($serviceKey in $serviceKeys) {
            $imagePath = [string](Get-ItemProperty -Path $serviceKey.PSPath -Name ImagePath -ErrorAction SilentlyContinue).ImagePath
            if ([string]::IsNullOrWhiteSpace($imagePath)) {
                continue
            }

            if ($imagePath -match '^\s*"([^"]+)"') {
                $exePath = $matches[1]
            } elseif ($imagePath -match '^\s*(\S+)') {
                $exePath = $matches[1]
            } else {
                continue
            }

            $candidates += (Split-Path -Path $exePath -Parent)
        }
    } catch {
        Write-RuleLog -Level WARN -Phase bootstrap -Message "Could not enumerate IQService registry entries: $($_.Exception.Message)"
    }

    $candidates = Expand-IQServiceDirectoryCandidates -Paths $candidates

    $attempted = @()
    $fallback = $null
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if ($attempted -contains $candidate) {
            continue
        }
        $attempted += $candidate

        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }

        $resolved = (Resolve-Path -LiteralPath $candidate).Path
        if (-not $fallback) {
            $fallback = $resolved
        }

        if (Test-LooksLikeIQServiceDirectory -Path $resolved) {
            $ctx.Runtime.IQServiceDirectorySource = "IQService.exe or Utils.dll found in the directory"
            return $resolved
        }
    }

    if ($fallback) {
        # Nothing carried an IQService marker, so this is the first readable candidate and may well be
        # the working directory rather than the install directory. Say so in the log instead of implying
        # the lookup succeeded.
        $ctx.Runtime.IQServiceDirectorySource = "first readable candidate, no IQService marker found in any of: $($attempted -join '; ')"
        return $fallback
    }

    throw "Unable to resolve the IQService directory. Checked: $($attempted -join '; ')"
}

function Initialize-EmergencyLogFile {
    param([string] $runtimeBaseName)

    $tempDirectory = $env:TEMP
    if ([string]::IsNullOrWhiteSpace($tempDirectory)) {
        $tempDirectory = [System.IO.Path]::GetTempPath()
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmssfff"
    $fileName = "${runtimeBaseName}_${stamp}.emergency.log"
    $path = Join-Path -Path $tempDirectory -ChildPath $fileName

    try {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType File -Path $path -Force -ErrorAction Stop | Out-Null
        }
        $ctx.Runtime.EmergencyLogFile = $path
        return $path
    } catch {
        return $null
    }
}

function Initialize-RuleArtifacts {
    param(
        [string] $scriptsSubfolder,
        [hashtable] $runtimeIdentity
    )

    $ctx.Runtime.BaseName = $runtimeIdentity.BaseName
    $ctx.Runtime.ScriptPath = $runtimeIdentity.ScriptPath
    $ctx.Runtime.IQServiceDirectory = Resolve-IQServiceDirectory -preferredPath $PSScriptRoot
    $ctx.Runtime.ArtifactsDirectory = Join-Path -Path $ctx.Runtime.IQServiceDirectory -ChildPath $scriptsSubfolder

    if (-not (Test-Path -LiteralPath $ctx.Runtime.ArtifactsDirectory)) {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "Creating scripts directory: $($ctx.Runtime.ArtifactsDirectory)"
        New-Item -ItemType Directory -Path $ctx.Runtime.ArtifactsDirectory -Force -ErrorAction Stop | Out-Null
    }

    $probeFile = Join-Path -Path $ctx.Runtime.ArtifactsDirectory -ChildPath (".write-test-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    try {
        New-Item -ItemType File -Path $probeFile -Force -ErrorAction Stop | Out-Null
        Remove-Item -LiteralPath $probeFile -Force -ErrorAction Stop
    } catch {
        throw "The IQService Run As account cannot write to '$($ctx.Runtime.ArtifactsDirectory)'. $($_.Exception.Message)"
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmssfff"
    $artifactBaseName = Get-RuleArtifactBaseName -FallbackBaseName $runtimeIdentity.BaseName
    $ctx.Runtime.LogFile = Join-Path -Path $ctx.Runtime.ArtifactsDirectory -ChildPath ($artifactBaseName + "_" + $stamp + ".log")
    New-Item -ItemType File -Path $ctx.Runtime.LogFile -Force -ErrorAction Stop | Out-Null

    $dumpExtension = ".ps1"
    if (-not [string]::IsNullOrWhiteSpace($runtimeIdentity.FileName)) {
        $runtimeExtension = [System.IO.Path]::GetExtension($runtimeIdentity.FileName)
        if (-not [string]::IsNullOrWhiteSpace($runtimeExtension)) {
            $dumpExtension = $runtimeExtension
        }
    }

    $ctx.Runtime.ScriptDumpPath = Join-Path -Path $ctx.Runtime.ArtifactsDirectory -ChildPath ($artifactBaseName + $dumpExtension)
    $ctx.Runtime.ReplayScriptPath = Join-Path -Path $ctx.Runtime.ArtifactsDirectory -ChildPath ($artifactBaseName + "_" + $stamp + ".replay.ps1")
}

function Copy-RuntimeScriptDump {
    param(
        [string] $sourcePath,
        [string] $destinationPath
    )

    if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path -LiteralPath $sourcePath)) {
        throw "Runtime script source path is missing or unreadable: '$sourcePath'"
    }

    $destinationDirectory = Split-Path -Path $destinationPath -Parent
    $tempPath = Join-Path -Path $destinationDirectory -ChildPath (".tmp-" + [Guid]::NewGuid().ToString("N") + ".ps1")

    try {
        Copy-Item -LiteralPath $sourcePath -Destination $tempPath -Force -ErrorAction Stop

        $sourceHash = Get-FileSha256 $sourcePath
        $tempHash = Get-FileSha256 $tempPath
        if ($sourceHash -ne $tempHash) {
            throw "Script dump hash mismatch. Source=$sourceHash Temp=$tempHash"
        }

        if (Test-Path -LiteralPath $destinationPath) {
            Remove-Item -LiteralPath $destinationPath -Force -ErrorAction Stop
        }

        Move-Item -LiteralPath $tempPath -Destination $destinationPath -Force -ErrorAction Stop

        $destinationHash = Get-FileSha256 $destinationPath
        if ($sourceHash -ne $destinationHash) {
            throw "Script dump verification failed after move. Source=$sourceHash Destination=$destinationHash"
        }

        Write-RuleLog -Level INFO -Phase bootstrap -Message "Preserved runtime script at '$destinationPath' (SHA256=$destinationHash)"
    } finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function ConvertTo-ReplayEnvAssignment {
    param(
        [Parameter(Mandatory = $true)][string] $VariableName,
        [string] $Payload
    )

    if ([string]::IsNullOrEmpty($Payload)) {
        return "`$env:$VariableName = ''"
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Payload)
    $encoded = [Convert]::ToBase64String($bytes)
    return "`$env:$VariableName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encoded'))"
}

function Write-ReplayScript {
    param(
        [string] $sourcePath,
        [string] $destinationPath
    )

    if ($ctx.Runtime.ReplayMode) {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "Skipping replay script write because this run is already a replay."
        return
    }

    if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path -LiteralPath $sourcePath)) {
        throw "Replay source path is missing or unreadable: '$sourcePath'"
    }

    $requestPayload = Get-PayloadForLog -payload $env:Request
    $applicationPayload = Get-PayloadForLog -payload $env:Application
    $redacted = -not $ctx.Options.PwshUnsafePayloadLogging
    $originalScript = [System.IO.File]::ReadAllText($sourcePath)

    $headerLines = @(
        "###############################################################################################################################"
        "# REPLAY WRAPPER - generated by PowerShell Rule Template. Do not upload this file to ISC."
        "# Restores `$env:Request` and `$env:Application` from the original IQService invocation, then runs the captured script."
        "# Captured at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") local / $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.fff")) UTC"
        "# Runtime script: $sourcePath"
        $(if ($redacted) {
            "# Payloads are REDACTED. Set PwshUnsafePayloadLogging to true and reproduce for a fully faithful replay."
        } else {
            "# Payloads are UNREDACTED and may contain credentials. Restrict file permissions and delete this file when finished."
        })
        "###############################################################################################################################"
        ""
        "`$env:SAILPOINT_RULE_REPLAY = '1'"
        (ConvertTo-ReplayEnvAssignment -VariableName "Request" -Payload $requestPayload)
        (ConvertTo-ReplayEnvAssignment -VariableName "Application" -Payload $applicationPayload)
        ""
        "###############################################################################################################################"
        "# ORIGINAL RUNTIME SCRIPT"
        "###############################################################################################################################"
        ""
        $originalScript
    )

    $content = $headerLines -join [Environment]::NewLine
    $utf8Bom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($destinationPath, $content, $utf8Bom)

    Write-RuleLog -Level INFO -Phase bootstrap -Message ("Wrote replay script at '$destinationPath'" + $(if ($redacted) { " with redacted Request/Application." } else { " with unredacted Request/Application." }))
}

function Test-XmlAttributeRequestIsSecret($attributeRequestNode) {
    if (-not $attributeRequestNode) {
        return $false
    }

    $name = $attributeRequestNode.GetAttribute("name")
    if ($name -match '(?i)(password|passwd|secret|token|credential|privatekey|apikey|clientsecret)') {
        return $true
    }

    $secretEntry = $attributeRequestNode.SelectSingleNode(".//Attributes/Map/entry[@key='secret']")
    if ($secretEntry) {
        $secretValue = $secretEntry.GetAttribute("value")
        if ($secretValue -match '^(?i)true$') {
            return $true
        }
    }

    return $false
}

function Redact-XmlPayload {
    param([string] $xmlText)

    if ([string]::IsNullOrWhiteSpace($xmlText)) {
        return $xmlText
    }

    try {
        $document = New-Object System.Xml.XmlDocument
        $document.PreserveWhitespace = $true
        $document.LoadXml($xmlText)

        foreach ($entry in $document.SelectNodes("//entry")) {
            $key = $entry.GetAttribute("key")
            if ([string]::IsNullOrWhiteSpace($key)) {
                continue
            }

            if ($key -match '(?i)(password|passwd|secret|token|credential|privatekey|apikey|clientsecret|cookie|encrypted)') {
                if ($entry.HasAttribute("value")) {
                    $entry.SetAttribute("value", "[REDACTED]")
                }

                foreach ($valueNode in $entry.SelectNodes(".//value")) {
                    $valueNode.InnerText = "[REDACTED]"
                }
            }
        }

        foreach ($attributeRequest in $document.SelectNodes("//AttributeRequest")) {
            if (Test-XmlAttributeRequestIsSecret $attributeRequest) {
                if ($attributeRequest.HasAttribute("value")) {
                    $attributeRequest.SetAttribute("value", "[REDACTED]")
                }

                foreach ($valueNode in $attributeRequest.SelectNodes(".//value")) {
                    $valueNode.InnerText = "[REDACTED]"
                }
            }
        }

        $sw = New-Object System.IO.StringWriter
        $document.Save($sw)
        return $sw.ToString()
    } catch {
        return "[REDACTION FAILED: $($_.Exception.Message)] OriginalLength=$($xmlText.Length) OriginalSha256=$(Get-TextSha256 $xmlText)"
    }
}

function Get-PayloadForLog {
    param([string] $payload)

    if ($ctx.Options.PwshUnsafePayloadLogging) {
        return $payload
    }

    return (Redact-XmlPayload -xmlText $payload)
}

function Write-RuleContextBlock {
    $ctx.Runtime.Phase = "context"

    Write-RuleLog -Level INFO -Message "=== Rule context ==="

    try {
        if (-not (Test-ConnectorRuleTypeConfigured -RuleType $ConnectorRuleType)) {
            Write-RuleLog -Level WARN -Message ("ConnectorRuleType           : {0} (set `$ConnectorRuleType to one of the supported ConnectorBefore* or ConnectorAfter* values)" -f ($(if ([string]::IsNullOrWhiteSpace($ConnectorRuleType)) { "<not configured>" } else { $ConnectorRuleType })))
        } else {
            Write-RuleLog -Level INFO -Message ("ConnectorRuleType           : {0}" -f $ConnectorRuleType)
        }

        if (-not [string]::IsNullOrWhiteSpace($ConnectorRuleName)) {
            Write-RuleLog -Level INFO -Message ("ConnectorRuleName           : {0}" -f $ConnectorRuleName)
        }

        $requestOperation = Get-AccountRequestOperation
        if (-not [string]::IsNullOrWhiteSpace($requestOperation)) {
            Write-RuleLog -Level INFO -Message ("AccountRequestOperation   : {0}" -f $requestOperation)
        } else {
            Write-RuleLog -Level WARN -Message "AccountRequestOperation   : <not present in env:Request>"
        }

        Write-RuleLog -Level INFO -Message ("PwshSilentError                 : {0} ({1})" -f $ctx.Options.PwshSilentError, $ctx.Options.PwshSilentErrorSource)
        Write-RuleLog -Level INFO -Message ("PwshUnsafePayloadLogging  : {0} ({1})" -f $ctx.Options.PwshUnsafePayloadLogging, $ctx.Options.PwshUnsafePayloadLoggingSource)
        Write-RuleLog -Level INFO -Message ("PwshReplay                      : {0} ({1})" -f $ctx.Options.PwshReplay, $ctx.Options.PwshReplaySource)
        Write-RuleLog -Level INFO -Message ("PowerShellVersion          : {0}" -f $PSVersionTable.PSVersion)
        Write-RuleLog -Level INFO -Message ("OSVersion                  : {0}" -f [System.Environment]::OSVersion.VersionString)
        Write-RuleLog -Level INFO -Message ("MachineName                : {0}" -f $env:COMPUTERNAME)
        Write-RuleLog -Level INFO -Message ("ProcessId                  : {0}" -f $PID)

        try {
            Write-RuleLog -Level INFO -Message ("RunningAs                  : {0}" -f ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))
        } catch {
            Write-RuleLog -Level WARN -Message ("RunningAs                  : <unavailable> $($_.Exception.Message)")
        }

        try {
            Write-RuleLog -Level INFO -Message ("ExecutionPolicy            : {0}" -f (Get-ExecutionPolicy))
        } catch {
            Write-RuleLog -Level WARN -Message ("ExecutionPolicy            : <unavailable> $($_.Exception.Message)")
        }

        try {
            Write-RuleLog -Level INFO -Message ("WorkingDirectory           : {0}" -f (Get-Location).Path)
        } catch {
            Write-RuleLog -Level WARN -Message ("WorkingDirectory           : <unavailable> $($_.Exception.Message)")
        }

        Write-RuleLog -Level INFO -Message ("PSScriptRoot               : {0}" -f $PSScriptRoot)
        if ($ctx.Runtime.ScriptResolved) {
            Write-RuleLog -Level INFO -Message ("RuntimeScriptPath          : {0}" -f $ctx.Runtime.ScriptPath)
        } else {
            Write-RuleLog -Level WARN -Message ("RuntimeScriptPath          : <unresolved> {0}" -f $ctx.Runtime.ScriptReason)
        }
        Write-RuleLog -Level INFO -Message ("RuntimeScriptName          : {0}" -f $ctx.Runtime.BaseName)
        Write-RuleLog -Level INFO -Message ("IQServiceDirectory         : {0}" -f $ctx.Runtime.IQServiceDirectory)
        Write-RuleLog -Level INFO -Message ("IQServiceDirectorySource   : {0}" -f $ctx.Runtime.IQServiceDirectorySource)
        Write-RuleLog -Level INFO -Message ("ArtifactsDirectory         : {0}" -f $ctx.Runtime.ArtifactsDirectory)
        Write-RuleLog -Level INFO -Message ("LogFile                    : {0}" -f $ctx.Runtime.LogFile)
        Write-RuleLog -Level INFO -Message ("ScriptDumpPath             : {0}" -f $ctx.Runtime.ScriptDumpPath)
        if ($ctx.Options.PwshReplay -and -not $ctx.Runtime.ReplayMode) {
            Write-RuleLog -Level INFO -Message ("ReplayScriptPath           : {0}" -f $ctx.Runtime.ReplayScriptPath)
        } else {
            Write-RuleLog -Level INFO -Message "ReplayScriptPath           : <not written>"
        }
        Write-RuleLog -Level INFO -Message ("ReplayMode                 : {0}" -f $ctx.Runtime.ReplayMode)

        if ($ctx.Runtime.EmergencyLogFile) {
            Write-RuleLog -Level WARN -Message ("EmergencyLogFile           : {0}" -f $ctx.Runtime.EmergencyLogFile)
        }

        if ($ctx.Runtime.ScriptPath) {
            Write-RuleLog -Level INFO -Message ("RuntimeScriptSha256        : {0}" -f (Get-FileSha256 $ctx.Runtime.ScriptPath))
        }

        if ($ctx.Options.PwshUnsafePayloadLogging) {
            Write-RuleLog -Level WARN -Message "Unsafe payload logging is ENABLED. Logs may contain credentials and other sensitive data."
        } else {
            Write-RuleLog -Level INFO -Message "Payload logging uses redaction. Set PwshUnsafePayloadLogging to true only for short-lived troubleshooting."
        }

        if ($env:Request) {
            $requestForLog = Get-PayloadForLog -payload $env:Request
            Write-RuleLog -Level INFO -Message ("RequestLength              : {0}" -f $env:Request.Length)
            Write-RuleLog -Level INFO -Message ("RequestSha256              : {0}" -f (Get-TextSha256 $env:Request))
            Write-RuleLog -Level INFO -Message ("env:Request                : {0}" -f $requestForLog)
        } else {
            Write-RuleLog -Level WARN -Message "env:Request                : <null or empty>"
        }

        if ($env:Application) {
            $applicationForLog = Get-PayloadForLog -payload $env:Application
            Write-RuleLog -Level INFO -Message ("ApplicationLength          : {0}" -f $env:Application.Length)
            Write-RuleLog -Level INFO -Message ("ApplicationSha256          : {0}" -f (Get-TextSha256 $env:Application))
            Write-RuleLog -Level INFO -Message ("env:Application            : {0}" -f $applicationForLog)
        } else {
            Write-RuleLog -Level WARN -Message "env:Application            : <null or empty>"
        }
    } catch {
        Write-RuleLog -Level ERROR -Message ("Context block failed: $(Format-RuleErrorRecord $_)")
    }

    Write-RuleLog -Level INFO -Message "=== End rule context ==="
}

function Exit-Rule {
    param([int] $FailureCode)

    if ($FailureCode -eq 0) {
        Write-RuleLog -Level INFO -Phase completion -Message "Rule completed successfully. Exiting with code 0."
        exit 0
    }

    if (-not $ctx.Options.PwshSilentError) {
        Write-RuleLog -Level ERROR -Phase completion -Message "Rule failed. Exiting with code 1 because PwshSilentError is false. IQService reports this rule as failed. Before rules abort the pending operation; for After rules the operation is already complete and rollback depends on rollbackCreatedAccountOnError."
        exit 1
    }

    Write-RuleLog -Level WARN -Phase completion -Message "Rule failed, but exiting with code 0 because PwshSilentError is true. IQService reports success and the failure is recorded only in this log."
    exit 0
}

###############################################################################################################################
# BOOTSTRAP
###############################################################################################################################

trap {
    if (-not $ctx.Runtime.LogFile -and -not $ctx.Runtime.EmergencyLogFile) {
        Initialize-EmergencyLogFile -runtimeBaseName (Get-RuleArtifactBaseName -FallbackBaseName $ctx.Runtime.BaseName) | Out-Null
    }

    Write-RuleLog -Level ERROR -Phase bootstrap -Message ("Unhandled error: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

$ruleRuntimeScriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($ruleRuntimeScriptPath)) {
    $ruleRuntimeScriptPath = $MyInvocation.MyCommand.Path
}

$runtimeIdentity = Resolve-RuntimeScriptIdentity -ScriptPath $ruleRuntimeScriptPath
$ctx.Runtime.ScriptPath = $runtimeIdentity.ScriptPath
$ctx.Runtime.ScriptResolved = $runtimeIdentity.Resolved
$ctx.Runtime.ScriptReason = $runtimeIdentity.Reason
$ctx.Runtime.ReplayMode = ($env:SAILPOINT_RULE_REPLAY -eq "1")

try {
    Initialize-RuleArtifacts -scriptsSubfolder $ScriptsSubfolder -runtimeIdentity $runtimeIdentity
} catch {
    Initialize-EmergencyLogFile -runtimeBaseName (Get-RuleArtifactBaseName -FallbackBaseName $runtimeIdentity.BaseName) | Out-Null
    Write-RuleLog -Level ERROR -Phase bootstrap -Message ("Artifact initialization failed: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

Write-RuleLog -Level INFO -Phase bootstrap -Message ("=== Rule bootstrap started | {0}{1} ===" -f $ConnectorRuleType, $(if ([string]::IsNullOrWhiteSpace($ConnectorRuleName)) { "" } else { " | $ConnectorRuleName" }))

Initialize-ApplicationContext

try {
    Initialize-RuleOptions
} catch {
    Write-RuleLog -Level WARN -Phase bootstrap -Message ("Option initialization failed: $(Format-RuleErrorRecord $_). Using defaults (all false).")
}

Initialize-RequestContext

if ($ctx.Runtime.ReplayMode) {
    Write-RuleLog -Level INFO -Phase bootstrap -Message "Replay mode: restoring captured Request/Application and skipping dump/replay writes."
} elseif (-not $ctx.Runtime.ScriptResolved) {
    Write-RuleLog -Level WARN -Phase bootstrap -Message ("Skipping the script dump and replay script because the runtime script path is unresolved. {0} Logging and rule logic are unaffected." -f $ctx.Runtime.ScriptReason)
} else {
    # Both artifacts are debugging aids. A failure here must not fail the connector operation, so it is
    # logged and the rule continues.
    try {
        Copy-RuntimeScriptDump -sourcePath $ctx.Runtime.ScriptPath -destinationPath $ctx.Runtime.ScriptDumpPath
    } catch {
        Write-RuleLog -Level WARN -Phase bootstrap -Message ("Script dump failed: $(Format-RuleErrorRecord $_). Continuing without it.")
    }

    if ($ctx.Options.PwshReplay) {
        try {
            Write-ReplayScript -sourcePath $ctx.Runtime.ScriptPath -destinationPath $ctx.Runtime.ReplayScriptPath
        } catch {
            Write-RuleLog -Level WARN -Phase bootstrap -Message ("Replay script write failed: $(Format-RuleErrorRecord $_). The hash-verified script dump is still available.")
        }
    } else {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "PwshReplay is false. Skipping replay script."
    }
}

Write-RuleContextBlock

###############################################################################################################################
# CUSTOM PROCESS CODE - replace this section in copied rules
###############################################################################################################################

$ctx.Runtime.Phase = "process"

try {
    Write-RuleLog -Level INFO -Message "CUSTOM PROCESS CODE placeholder reached. Replace this section with rule-specific logic."

    #
    # Common input access does not require Utils.dll:
    # $operation = $ctx.Request.Operation
    # $nativeIdentity = $ctx.Request.NativeIdentity
    # $samAccountName = Get-RequestAttribute "sAMAccountName"
    # $basePath = Get-ApplicationAttribute "HomeFolderBasePath"
    #
    # For advanced code that needs SailPoint's typed AccountRequest object:
    #
    # Add-Type -Path (Join-Path $ctx.Runtime.IQServiceDirectory "Utils.dll")
    # $sReader = New-Object System.IO.StringReader([System.String]$env:Request)
    # $xmlReader = [System.Xml.XmlTextReader]([sailpoint.utils.xml.XmlUtil]::getReader($sReader))
    # $requestObject = New-Object Sailpoint.Utils.objects.AccountRequest($xmlReader)
    #
    # Write-RuleLog -Level DEBUG -Message ("Account operation: $($requestObject.Operation)")
    #

    #
    # End CUSTOM PROCESS CODE
    #
}
catch {
    Write-RuleLog -Level ERROR -Phase process -Message ("Process error: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

Exit-Rule 0
