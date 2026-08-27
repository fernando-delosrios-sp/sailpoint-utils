###############################################################################################################################
# ConnectorAfterCreate rule for Active Directory home folder provisioning.
#
# Built from ISC/PowerShell Rule Template. Keep the template bootstrap and helper functions unchanged.
# Home-folder logic lives in HOME FOLDER HELPERS and CUSTOM PROCESS CODE.
#
# Upload this script as a Connector Rule (type: ConnectorAfterCreate) using the
# SailPoint Identity Security Cloud VS Code extension:
# https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow
# Attach the rule to your AD source through connectorAttributes.nativeRules.
#
# APPLICATION ATTRIBUTES (connectorAttributes on the AD source):
#   - HomeFolderBasePath (string): Root path when HomeFolderTemplate resolves to a relative path.
#   - HomeFolderTemplate (string, optional): Path template with $attributeName or {attributeName} placeholders
#     filled from the account request. Defaults to sAMAccountName when blank or unresolvable.
#   - HomeFolderDebugEnabled (boolean): Set to "true" to enable detailed process debug logging.
#   - HomeFolderUtilsDllPath (string): Optional full path to Utils.dll when the IQService directory lookup fails.
#   - HomeFolderFailOnError (boolean): Optional override of PwshSilentError. "false" keeps the created AD account
#     and only logs the home folder failure.
#   - PwshSilentError, PwshUnsafePayloadLogging, PwshReplay (boolean): Template options. Defaults false.
#     Script variables of the same name, if defined, take precedence.
#
# IQService prerequisites:
#   - Utils.dll must be in the IQService install directory, or HomeFolderUtilsDllPath must point to it.
#   - The IQService Run As account must be able to write under <IQService>\scripts.
#   - The IQService Run As account must be able to create folders and set NTFS ACLs on the target share.
###############################################################################################################################

###############################################################################################################################
# CONFIGURATION — edit these constants when you copy this template
###############################################################################################################################

# Set this to match the connector rule type configured in ISC for this script.
# Allowed values:
#   ConnectorBeforeCreate, ConnectorBeforeModify, ConnectorBeforeDelete
#   ConnectorAfterCreate, ConnectorAfterModify, ConnectorAfterDelete
$ConnectorRuleType = "ConnectorAfterCreate"

# Optional display name from the ISC connector rule. Used as the artifact filename prefix when set; otherwise the runtime GUID is used.
$ConnectorRuleName = "Active Directory Home Folders"

# Optional script overrides. Define any of these to take precedence over the source connectorAttributes
# of the same name. Leave them undefined to use PwshSilentError, PwshUnsafePayloadLogging, and
# PwshReplay from the AD source (default false). HomeFolderFailOnError can still override PwshSilentError
# during process.
# $PwshSilentError = $false
# $PwshUnsafePayloadLogging = $false
# $PwshReplay = $false

# Relative folder under the IQService install directory where script dumps and logs are stored.
$ScriptsSubfolder = "scripts"

###############################################################################################################################
# RUNTIME STATE — do not edit below this line in copied rules unless you extend the template itself
###############################################################################################################################

$script:RuleLogFile = $null
$script:RuleEmergencyLogFile = $null
$script:RuleArtifactsDirectory = $null
$script:RuleRuntimeBaseName = $null
$script:RuleRuntimeScriptPath = $null
$script:RuleScriptDumpPath = $null
$script:RuleReplayScriptPath = $null
$script:RuleIQServiceDirectory = $null
$script:RulePhase = "bootstrap"
$script:RuleReplayMode = $false
$script:RuleApplicationAttributes = $null
$script:RuleApplicationAttributesLoaded = $false
$script:PwshSilentErrorSource = "default"
$script:PwshUnsafePayloadLoggingSource = "default"
$script:PwshReplaySource = "default"
$script:HomeFolderDebugEnabled = $false

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
    if ([string]::IsNullOrWhiteSpace($env:Request)) {
        return $null
    }

    try {
        $document = [xml]$env:Request
        $accountRequest = $document.SelectSingleNode("/AccountRequest")
        if (-not $accountRequest) {
            return $null
        }

        $operation = $accountRequest.GetAttribute("op")
        if (-not [string]::IsNullOrWhiteSpace($operation)) {
            return $operation
        }
    } catch {
        return $null
    }

    return $null
}

function Write-RuleLog {
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")][string] $Level = "INFO",
        [string] $Phase = $null
    )

    $activePhase = $Phase
    if ([string]::IsNullOrWhiteSpace($activePhase)) {
        $activePhase = $script:RulePhase
    }

    $timestampLocal = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $timestampUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss.fff")
    $line = "[$timestampLocal | $timestampUtc UTC] [$Level] [$activePhase] $Message"

    $targets = @()
    if ($script:RuleLogFile) { $targets += $script:RuleLogFile }
    if ($script:RuleEmergencyLogFile) { $targets += $script:RuleEmergencyLogFile }

    foreach ($target in $targets) {
        try {
            [System.IO.File]::AppendAllText($target, ($line + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
        } catch {
            # Keep trying remaining targets.
        }
    }

    if (-not $script:RuleLogFile -and -not $script:RuleEmergencyLogFile) {
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

function Resolve-RuntimeScriptIdentity {
    param([string] $ScriptPath)

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        throw "Unable to determine the runtime script path. `$PSCommandPath was empty."
    }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Runtime script path does not exist: '$ScriptPath'"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $ScriptPath).Path
    $fileName = Split-Path -Path $resolvedPath -Leaf
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

    return @{
        ScriptPath = $resolvedPath
        FileName   = $fileName
        BaseName   = $baseName
    }
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

    $attempted = @()
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if ($attempted -contains $candidate) {
            continue
        }
        $attempted += $candidate

        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
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
        $script:RuleEmergencyLogFile = $path
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

    $script:RuleRuntimeBaseName = $runtimeIdentity.BaseName
    $script:RuleRuntimeScriptPath = $runtimeIdentity.ScriptPath
    $script:RuleIQServiceDirectory = Resolve-IQServiceDirectory -preferredPath $PSScriptRoot
    $script:RuleArtifactsDirectory = Join-Path -Path $script:RuleIQServiceDirectory -ChildPath $scriptsSubfolder

    if (-not (Test-Path -LiteralPath $script:RuleArtifactsDirectory)) {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "Creating scripts directory: $script:RuleArtifactsDirectory"
        New-Item -ItemType Directory -Path $script:RuleArtifactsDirectory -Force -ErrorAction Stop | Out-Null
    }

    $probeFile = Join-Path -Path $script:RuleArtifactsDirectory -ChildPath (".write-test-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    try {
        New-Item -ItemType File -Path $probeFile -Force -ErrorAction Stop | Out-Null
        Remove-Item -LiteralPath $probeFile -Force -ErrorAction Stop
    } catch {
        throw "The IQService Run As account cannot write to '$script:RuleArtifactsDirectory'. $($_.Exception.Message)"
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmssfff"
    $artifactBaseName = Get-RuleArtifactBaseName -FallbackBaseName $runtimeIdentity.BaseName
    $script:RuleLogFile = Join-Path -Path $script:RuleArtifactsDirectory -ChildPath ($artifactBaseName + "_" + $stamp + ".log")
    New-Item -ItemType File -Path $script:RuleLogFile -Force -ErrorAction Stop | Out-Null

    $script:RuleScriptDumpPath = Join-Path -Path $script:RuleArtifactsDirectory -ChildPath ($artifactBaseName + [System.IO.Path]::GetExtension($runtimeIdentity.FileName))
    $script:RuleReplayScriptPath = Join-Path -Path $script:RuleArtifactsDirectory -ChildPath ($artifactBaseName + "_" + $stamp + ".replay.ps1")
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

    if ($script:RuleReplayMode) {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "Skipping replay script write because this run is already a replay."
        return
    }

    if ([string]::IsNullOrWhiteSpace($sourcePath) -or -not (Test-Path -LiteralPath $sourcePath)) {
        throw "Replay source path is missing or unreadable: '$sourcePath'"
    }

    $requestPayload = Get-PayloadForLog -payload $env:Request
    $applicationPayload = Get-PayloadForLog -payload $env:Application
    $redacted = -not $script:PwshUnsafePayloadLogging
    $originalScript = [System.IO.File]::ReadAllText($sourcePath)

    $headerLines = @(
        "###############################################################################################################################"
        "# REPLAY WRAPPER — generated by PowerShell Rule Template. Do not upload this file to ISC."
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

    if ($script:PwshUnsafePayloadLogging) {
        return $payload
    }

    return (Redact-XmlPayload -xmlText $payload)
}

function Write-RuleContextBlock {
    $script:RulePhase = "context"

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

        Write-RuleLog -Level INFO -Message ("PwshSilentError                 : {0} ({1})" -f $script:PwshSilentError, $script:PwshSilentErrorSource)
        Write-RuleLog -Level INFO -Message ("PwshUnsafePayloadLogging  : {0} ({1})" -f $script:PwshUnsafePayloadLogging, $script:PwshUnsafePayloadLoggingSource)
        Write-RuleLog -Level INFO -Message ("PwshReplay                      : {0} ({1})" -f $script:PwshReplay, $script:PwshReplaySource)
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
        Write-RuleLog -Level INFO -Message ("RuntimeScriptPath          : {0}" -f $script:RuleRuntimeScriptPath)
        Write-RuleLog -Level INFO -Message ("RuntimeScriptName          : {0}" -f $script:RuleRuntimeBaseName)
        Write-RuleLog -Level INFO -Message ("IQServiceDirectory         : {0}" -f $script:RuleIQServiceDirectory)
        Write-RuleLog -Level INFO -Message ("ArtifactsDirectory         : {0}" -f $script:RuleArtifactsDirectory)
        Write-RuleLog -Level INFO -Message ("LogFile                    : {0}" -f $script:RuleLogFile)
        Write-RuleLog -Level INFO -Message ("ScriptDumpPath             : {0}" -f $script:RuleScriptDumpPath)
        if ($script:PwshReplay -and -not $script:RuleReplayMode) {
            Write-RuleLog -Level INFO -Message ("ReplayScriptPath           : {0}" -f $script:RuleReplayScriptPath)
        } else {
            Write-RuleLog -Level INFO -Message "ReplayScriptPath           : <not written>"
        }
        Write-RuleLog -Level INFO -Message ("ReplayMode                 : {0}" -f $script:RuleReplayMode)

        if ($script:RuleEmergencyLogFile) {
            Write-RuleLog -Level WARN -Message ("EmergencyLogFile           : {0}" -f $script:RuleEmergencyLogFile)
        }

        if ($script:RuleRuntimeScriptPath) {
            Write-RuleLog -Level INFO -Message ("RuntimeScriptSha256        : {0}" -f (Get-FileSha256 $script:RuleRuntimeScriptPath))
        }

        if ($script:PwshUnsafePayloadLogging) {
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

    if (-not $script:PwshSilentError) {
        Write-RuleLog -Level ERROR -Phase completion -Message "Rule failed. Exiting with code 1 because PwshSilentError is false. IQService reports this rule as failed. The AD account already exists at this point, so whether ISC removes it depends on rollbackCreatedAccountOnError."
        exit 1
    }

    Write-RuleLog -Level WARN -Phase completion -Message "Rule failed, but exiting with code 0 because PwshSilentError is true. IQService reports success and the failure is recorded only in this log."
    exit 0
}

###############################################################################################################################
# HOME FOLDER HELPERS
###############################################################################################################################

function Write-HomeFolderDebug([string] $Message) {
    if ($script:HomeFolderDebugEnabled) {
        Write-RuleLog -Level DEBUG -Message $Message
    }
}

# A source attribute is serialized either as an attribute on <entry> or as a nested <value> element:
#   <entry key="HomeFolderBasePath" value="S:\HomeDir" />
#   <entry key="HomeFolderDebugEnabled"><value><Boolean>true</Boolean></value></entry>
# Read both explicitly rather than relying on PowerShell's XML adapter, which resolves $entry.value
# differently depending on which of the two forms it encounters.
function Get-ApplicationEntryValue($entry) {
    if ($entry.HasAttribute("value")) {
        return $entry.GetAttribute("value")
    }

    $valueNode = $entry.SelectSingleNode("value")
    if ($valueNode) {
        return $valueNode.InnerText.Trim()
    }

    return $null
}

function Get-AttributeValueFromAccountRequest($request, [String] $targetAttribute) {
    $value = $null

    if ($request) {
        foreach ($attrib in $request.AttributeRequests) {
            if ($attrib.Name -ieq $targetAttribute) {
                $value = $attrib.Value
                break
            }
        }
    } else {
        Write-RuleLog -Level WARN -Message "Account request data was null"
    }

    return $value
}

function Get-ApplicationAttributes {
    if ($script:RuleApplicationAttributesLoaded) {
        return $script:RuleApplicationAttributes
    }

    $appAttributes = @{}
    $script:RuleApplicationAttributes = $appAttributes
    $script:RuleApplicationAttributesLoaded = $true

    if (-not $env:Application) {
        Write-RuleLog -Level WARN -Message "env:Application is null or empty. No source attributes are available."
        return $appAttributes
    }

    try {
        $appXml = [xml]$env:Application

        # ISC sends a bare <Map> root. Only ever select TOP-LEVEL entries: nested <Map> values such as
        # deltaAggregation contain their own <entry> elements whose keys would otherwise collide.
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
            Write-RuleLog -Level WARN -Message "No source attributes found in env:Application. Root element is '$($appXml.DocumentElement.Name)', which none of the known payload shapes match."
            return $appAttributes
        }

        foreach ($entry in $entries) {
            $key = $entry.GetAttribute("key")
            if (-not [string]::IsNullOrWhiteSpace($key)) {
                $appAttributes[$key] = Get-ApplicationEntryValue $entry
            }
        }
    } catch {
        Write-RuleLog -Level ERROR -Message "Error parsing application attributes: $(Format-RuleErrorRecord $_)"
    }

    return $appAttributes
}

function Get-AccountRequestAttributeMap($request) {
    $attributes = @{}

    if (-not $request) {
        return $attributes
    }

    if ($request.NativeIdentity) {
        $attributes["nativeIdentity"] = $request.NativeIdentity
    }

    foreach ($attrib in $request.AttributeRequests) {
        $attributes[$attrib.Name] = $attrib.Value
    }

    return $attributes
}

function Get-AttributeValueCaseInsensitive([hashtable] $attributes, [String] $name) {
    if (-not $attributes) {
        return $null
    }

    foreach ($entry in $attributes.GetEnumerator()) {
        if ($entry.Key -ieq $name) {
            return [string]$entry.Value
        }
    }

    return $null
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

    $appRaw = Get-AttributeValueCaseInsensitive $script:RuleApplicationAttributes $Name
    if (-not [string]::IsNullOrWhiteSpace([string]$appRaw)) {
        $value = ConvertTo-RuleBoolean -Value $appRaw -Default $Default
        Write-RuleLog -Level INFO -Phase bootstrap -Message ("{0} : {1} (application attribute)" -f $Name, $value)
        return @{ Value = $value; Source = "application" }
    }

    Write-RuleLog -Level INFO -Phase bootstrap -Message ("{0} : {1} (default)" -f $Name, $Default)
    return @{ Value = $Default; Source = "default" }
}

function Initialize-RuleOptions {
    $script:RuleApplicationAttributes = Get-ApplicationAttributes

    $silent = Resolve-RuleBooleanOption -Name "PwshSilentError" -Default $false
    $unsafe = Resolve-RuleBooleanOption -Name "PwshUnsafePayloadLogging" -Default $false
    $replay = Resolve-RuleBooleanOption -Name "PwshReplay" -Default $false

    $script:PwshSilentError = $silent.Value
    $script:PwshSilentErrorSource = $silent.Source
    $script:PwshUnsafePayloadLogging = $unsafe.Value
    $script:PwshUnsafePayloadLoggingSource = $unsafe.Source
    $script:PwshReplay = $replay.Value
    $script:PwshReplaySource = $replay.Source
}

function Expand-HomeFolderTemplate([String] $template, [hashtable] $attributes) {
    if ([string]::IsNullOrWhiteSpace($template)) {
        return $null
    }

    $result = $template

    $result = [regex]::Replace($result, '\$([A-Za-z_][A-Za-z0-9_]*)', {
        param($match)
        $name = $match.Groups[1].Value
        $value = Get-AttributeValueCaseInsensitive $attributes $name
        if ($null -ne $value) { return $value }
        return $match.Value
    })

    $result = [regex]::Replace($result, '\{([A-Za-z_][A-Za-z0-9_]*)\}', {
        param($match)
        $name = $match.Groups[1].Value
        $value = Get-AttributeValueCaseInsensitive $attributes $name
        if ($null -ne $value) { return $value }
        return $match.Value
    })

    return $result
}

function Test-TemplateHasUnresolvedTokens([String] $value) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $true
    }

    return ($value -match '\$[A-Za-z_][A-Za-z0-9_]*' -or $value -match '\{[A-Za-z_][A-Za-z0-9_]*\}')
}

function Test-IsAbsolutePath([String] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $false
    }

    if ($path -match '^\\\\[^\\]+\\') {
        return $true
    }

    if ($path -match '^[A-Za-z]:\\') {
        return $true
    }

    return $false
}

# '\\fileserver\HomeDir' is a share root, not a folder: the first component is always the server name.
# Returns $null for a UNC path with no share component, such as '\\fileserver'.
function Get-UncShareRoot([String] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $null
    }

    if ($path -match '^\\\\([^\\]+)\\([^\\]+)') {
        return "\\{0}\{1}" -f $matches[1], $matches[2]
    }

    return $null
}

function Test-IsPathRoot([String] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $false
    }

    $trimmed = $path.TrimEnd('\')

    if ($trimmed -match '^[A-Za-z]:$') {
        return $true
    }

    $shareRoot = Get-UncShareRoot $trimmed
    return ($shareRoot -and $shareRoot -ieq $trimmed)
}

function Ensure-DirectoryExists {
    param([String] $path)

    if ([string]::IsNullOrWhiteSpace($path)) {
        return
    }

    if (Test-Path -LiteralPath $path) {
        return
    }

    # New-Item cannot create a drive root or a UNC share root. With -Force it walks up to an
    # illegal parent instead, and reports "The path is not of a legal form" rather than the real cause.
    if (Test-IsPathRoot $path) {
        throw "'$path' is a root, not a folder, so it cannot be created. $(Get-PathRootAdvice $path)"
    }

    Write-RuleLog -Level INFO -Message "Creating directory: $path"
    # -ErrorAction Stop, otherwise the failure is non-terminating and the caller's catch is skipped.
    New-Item -ItemType Directory -Force -Path $path -ErrorAction Stop | Out-Null
}

function Get-PathRootAdvice([String] $path) {
    if ($path -match '^\\\\([^\\]+)\\([^\\]+)') {
        return "'$path' is read as server '$($matches[1])' and share '$($matches[2])'. Both must already exist and be reachable from this IQService host, and the IQService Run As account must be able to write to the share. If '$($matches[1])' is not a server name, the server is missing from the path: use \\<fileserver>\$($matches[1])\$($matches[2])."
    }

    return "Point HomeFolderBasePath at a folder inside an existing share or volume."
}

# Two roots fail silently under a Windows service: a mapped drive letter (per-logon, so invisible to
# the service) and an unreachable UNC share. Both surface as "path not found" or as an unhelpful
# New-Item argument error, so name the actual cause here.
function Assert-PathRootAvailable([String] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return
    }

    if ($path -match '^([A-Za-z]):\\') {
        $driveRoot = $matches[1] + ":\"
        if (Test-Path -LiteralPath $driveRoot) {
            return
        }

        throw "Drive '$driveRoot' is not available to the account running IQService. Mapped network drives are per-logon and are normally invisible to a Windows service, even when the same account can see them interactively. Use a UNC path such as \\server\share in HomeFolderBasePath instead of a mapped drive letter."
    }

    if (-not $path.StartsWith("\\")) {
        return
    }

    $shareRoot = Get-UncShareRoot $path
    if (-not $shareRoot) {
        throw "'$path' is not a usable UNC path. A UNC path needs both a server and a share, as in \\fileserver\HomeDir."
    }

    if (Test-Path -LiteralPath $shareRoot) {
        Write-HomeFolderDebug "Share root '$shareRoot' is reachable."
        return
    }

    throw "Share root '$shareRoot' is not reachable from this IQService host. $(Get-PathRootAdvice $shareRoot)"
}

function Resolve-HomeFolderPath {
    param(
        [String] $basePath,
        [String] $template,
        [hashtable] $attributes,
        [String] $samAccountName
    )

    $expanded = Expand-HomeFolderTemplate $template $attributes

    if ([string]::IsNullOrWhiteSpace($expanded) -or (Test-TemplateHasUnresolvedTokens $expanded)) {
        Write-HomeFolderDebug "Template blank or contains unresolved placeholders. Falling back to sAMAccountName: '$samAccountName'"
        $expanded = $samAccountName
    }

    if (Test-IsAbsolutePath $expanded) {
        Assert-PathRootAvailable $expanded
        return $expanded
    }

    if ([string]::IsNullOrWhiteSpace($basePath)) {
        throw "HomeFolderBasePath is required when HomeFolderTemplate resolves to a relative path ('$expanded')."
    }

    Assert-PathRootAvailable $basePath
    Ensure-DirectoryExists -path $basePath

    return Join-Path -Path $basePath -ChildPath $expanded
}

function Import-SailPointUtils([String] $configuredPath) {
    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($configuredPath)) {
        $candidates += $configuredPath
    }

    if (-not [string]::IsNullOrWhiteSpace($script:RuleIQServiceDirectory)) {
        $candidates += (Join-Path $script:RuleIQServiceDirectory "Utils.dll")
    }

    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += (Join-Path $PSScriptRoot "Utils.dll")
    }

    $attempted = @()

    foreach ($candidate in $candidates) {
        if ($attempted -contains $candidate) {
            continue
        }
        $attempted += $candidate

        if (-not (Test-Path -Path $candidate)) {
            Write-HomeFolderDebug "Utils.dll not present at: $candidate"
            continue
        }

        try {
            Add-Type -Path $candidate
            Write-RuleLog -Level INFO -Message "Loaded SailPoint Utils assembly from: $candidate"
            return $candidate
        } catch {
            Write-RuleLog -Level WARN -Message "Failed to load Utils.dll from '$candidate': $($_.Exception.Message)"
        }
    }

    throw "Utils.dll could not be loaded. Searched: $($attempted -join '; '). Set HomeFolderUtilsDllPath on the AD source to the full path of Utils.dll."
}

###############################################################################################################################
# BOOTSTRAP
###############################################################################################################################

trap {
    if (-not $script:RuleLogFile -and -not $script:RuleEmergencyLogFile) {
        Initialize-EmergencyLogFile -runtimeBaseName (Get-RuleArtifactBaseName -FallbackBaseName $script:RuleRuntimeBaseName) | Out-Null
    }

    Write-RuleLog -Level ERROR -Phase bootstrap -Message ("Unhandled error: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

$ruleRuntimeScriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($ruleRuntimeScriptPath)) {
    $ruleRuntimeScriptPath = $MyInvocation.MyCommand.Path
}

$runtimeIdentity = Resolve-RuntimeScriptIdentity -ScriptPath $ruleRuntimeScriptPath
$script:RuleRuntimeScriptPath = $runtimeIdentity.ScriptPath
$script:RuleReplayMode = ($env:SAILPOINT_RULE_REPLAY -eq "1")

try {
    Initialize-RuleArtifacts -scriptsSubfolder $ScriptsSubfolder -runtimeIdentity $runtimeIdentity
} catch {
    Initialize-EmergencyLogFile -runtimeBaseName (Get-RuleArtifactBaseName -FallbackBaseName $runtimeIdentity.BaseName) | Out-Null
    Write-RuleLog -Level ERROR -Phase bootstrap -Message ("Artifact initialization failed: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

Write-RuleLog -Level INFO -Phase bootstrap -Message ("=== Rule bootstrap started | {0}{1} ===" -f $ConnectorRuleType, $(if ([string]::IsNullOrWhiteSpace($ConnectorRuleName)) { "" } else { " | $ConnectorRuleName" }))

try {
    Initialize-RuleOptions
} catch {
    Write-RuleLog -Level WARN -Phase bootstrap -Message ("Option initialization failed: $(Format-RuleErrorRecord $_). Using defaults (all false).")
}

if ($script:RuleReplayMode) {
    Write-RuleLog -Level INFO -Phase bootstrap -Message "Replay mode: restoring captured Request/Application and skipping dump/replay writes."
} else {
    try {
        Copy-RuntimeScriptDump -sourcePath $script:RuleRuntimeScriptPath -destinationPath $script:RuleScriptDumpPath
    } catch {
        if (-not $script:RuleEmergencyLogFile) {
            Initialize-EmergencyLogFile -runtimeBaseName (Get-RuleArtifactBaseName -FallbackBaseName $runtimeIdentity.BaseName) | Out-Null
        }
        Write-RuleLog -Level ERROR -Phase bootstrap -Message ("Script dump failed: $(Format-RuleErrorRecord $_)")
        Exit-Rule 1
    }

    if ($script:PwshReplay) {
        try {
            Write-ReplayScript -sourcePath $script:RuleRuntimeScriptPath -destinationPath $script:RuleReplayScriptPath
        } catch {
            Write-RuleLog -Level WARN -Phase bootstrap -Message ("Replay script write failed: $(Format-RuleErrorRecord $_). The hash-verified script dump is still available.")
        }
    } else {
        Write-RuleLog -Level INFO -Phase bootstrap -Message "PwshReplay is false. Skipping replay script."
    }
}

Write-RuleContextBlock

###############################################################################################################################
# CUSTOM PROCESS CODE — Active Directory home folder provisioning
###############################################################################################################################

$script:RulePhase = "process"

try {
    Write-RuleLog -Level INFO -Message "Starting Active Directory home folder provisioning."

    $appAttributes = Get-ApplicationAttributes

    if ((Get-AttributeValueCaseInsensitive $appAttributes "HomeFolderDebugEnabled") -ieq "true") {
        $script:HomeFolderDebugEnabled = $true
        Write-RuleLog -Level INFO -Message "HomeFolderDebugEnabled is true. Extra process debug lines will be written."
    }

    $failOnErrorOverride = Get-AttributeValueCaseInsensitive $appAttributes "HomeFolderFailOnError"
    if ($failOnErrorOverride -ieq "false") {
        $script:PwshSilentError = $true
        $script:PwshSilentErrorSource = "HomeFolderFailOnError"
        Write-RuleLog -Level INFO -Message "PwshSilentError overridden to true by HomeFolderFailOnError=false."
    } elseif ($failOnErrorOverride -ieq "true") {
        $script:PwshSilentError = $false
        $script:PwshSilentErrorSource = "HomeFolderFailOnError"
        Write-RuleLog -Level INFO -Message "PwshSilentError overridden to false by HomeFolderFailOnError=true."
    }

    Import-SailPointUtils (Get-AttributeValueCaseInsensitive $appAttributes "HomeFolderUtilsDllPath") | Out-Null

    ##########################
    # Begin SailPoint protected code -- do not modify this code block
    #
    $sReader = New-Object System.IO.StringReader([System.String]$env:Request)
    $xmlReader = [System.xml.XmlTextReader]([sailpoint.utils.xml.XmlUtil]::getReader($sReader))
    $requestObject = New-Object Sailpoint.Utils.objects.AccountRequest($xmlReader)

    Write-HomeFolderDebug "Request object contents:"
    Write-HomeFolderDebug ($requestObject | Out-String)
    #
    # End SailPoint protected code
    ##########################

    if ($requestObject.Operation -eq "Create") {
        $attributeMap = Get-AccountRequestAttributeMap $requestObject
        $SAMAccountName = Get-AttributeValueFromAccountRequest $requestObject "sAMAccountName"

        if ([string]::IsNullOrWhiteSpace($SAMAccountName)) {
            throw "sAMAccountName could not be successfully extracted from the plan payload."
        }

        $HomeFolderBasePath = Get-AttributeValueCaseInsensitive $appAttributes "HomeFolderBasePath"
        $HomeFolderTemplate = Get-AttributeValueCaseInsensitive $appAttributes "HomeFolderTemplate"

        Write-HomeFolderDebug "Parsed attributes -> sAMAccountName: '$SAMAccountName'"
        Write-HomeFolderDebug "Configuration -> HomeFolderBasePath: '$HomeFolderBasePath', HomeFolderTemplate: '$HomeFolderTemplate'"

        $TargetHomePath = Resolve-HomeFolderPath `
            -basePath $HomeFolderBasePath `
            -template $HomeFolderTemplate `
            -attributes $attributeMap `
            -samAccountName $SAMAccountName

        Write-RuleLog -Level INFO -Message "Calculated home folder target path: $TargetHomePath"

        $targetExisted = Test-Path -LiteralPath $TargetHomePath
        Ensure-DirectoryExists -path $TargetHomePath

        if ($targetExisted) {
            Write-RuleLog -Level INFO -Message "Target home folder already exists at path. Updating permissions on existing resource."
        }

        $ACL = Get-Acl -Path $TargetHomePath
        $ACL.SetAccessRuleProtection($true, $false)

        # InheritanceFlags: 3 = ContainerInherit | ObjectInherit
        # PropagationFlags: 0 = None
        # AccessControlType: 0 = Allow
        $UserAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $SAMAccountName,
            "FullControl",
            3,
            0,
            0
        )

        $AdminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Administrators",
            "FullControl",
            3,
            0,
            0
        )

        $ACL.SetAccessRule($UserAccessRule)
        $ACL.SetAccessRule($AdminAccessRule)
        Set-Acl -Path $TargetHomePath -AclObject $ACL
        Write-RuleLog -Level INFO -Message "Successfully restricted folder inheritance and applied exclusive ACL ownership to $SAMAccountName."
    } else {
        Write-RuleLog -Level INFO -Message "Skipping home folder workflow. Action is restricted exclusively to Create operations. Current operation: $($requestObject.Operation)"
    }
}
catch {
    Write-RuleLog -Level ERROR -Phase process -Message ("Process error: $(Format-RuleErrorRecord $_)")
    Exit-Rule 1
}

Exit-Rule 0
