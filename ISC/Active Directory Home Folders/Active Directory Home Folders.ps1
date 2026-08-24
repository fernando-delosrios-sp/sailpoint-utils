###############################################################################################################################
# ConnectorAfterCreate rule for Active Directory home folder provisioning.
#
# Upload this script as a Connector Rule (type: ConnectorAfterCreate) using the
# SailPoint Identity Security Cloud VS Code extension:
# https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow
# Attach the rule to your AD source through connectorAttributes.nativeRules.
#
# APPLICATION ATTRIBUTES (connectorAttributes on the AD source):
#   - HomeFolderBasePath (string): Root path when HomeFolderTemplate resolves to a relative path.
#   - HomeFolderTemplate (string): Path template with $attributeName or {attributeName} placeholders
#     filled from the account request. Defaults to sAMAccountName when blank or unresolvable.
#   - HomeFolderDebugEnabled (boolean): Set to "true" to enable detailed debug logging.
#
# IQService prerequisites:
#   - Utils.dll must exist in the IQService install directory (unqualified load below).
#   - The IQService Run As account must be able to create folders and set NTFS ACLs on the target share.
###############################################################################################################################

# Include SailPoint library (unqualified path — IQService copies the rule script into its folder at runtime)
Add-Type -Path "Utils.dll"

Import-Module ActiveDirectory

$logDate = Get-Date -UFormat "%Y%m%d"
$logFile = Join-Path $env:TEMP "ActiveDirectoryHomeFolders_$logDate.log"
$enableDebug = $false

###############################################################################################################################
# HELPER FUNCTIONS
###############################################################################################################################

function LogToFile([String] $info) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] $info" | Out-File $logFile -Append
}

function Get-AttributeValueFromAccountRequest([sailpoint.Utils.objects.AccountRequest] $request, [String] $targetAttribute) {
    $value = $null

    if ($request) {
        foreach ($attrib in $request.AttributeRequests) {
            if ($attrib.Name -ieq $targetAttribute) {
                $value = $attrib.Value
                break
            }
        }
    } else {
        LogToFile("Account request data was null")
    }

    return $value
}

function Get-ApplicationAttributes {
    $appAttributes = @{}

    try {
        if ($env:Application) {
            $appXml = [xml]$env:Application
            $mapEntries = $appXml.SelectNodes("//Attributes/Map/entry")
            if ($mapEntries) {
                foreach ($entry in $mapEntries) {
                    $appAttributes[$entry.key] = $entry.value
                }
            }
        } else {
            LogToFile("Warning: `$env:Application is null or empty.")
        }
    } catch {
        LogToFile("Error parsing application attributes: $($_.Exception.Message)")
    }

    return $appAttributes
}

function Get-AccountRequestAttributeMap([sailpoint.Utils.objects.AccountRequest] $request) {
    $attributes = @{}

    if ($request.NativeIdentity) {
        $attributes["nativeIdentity"] = $request.NativeIdentity
    }

    if ($request) {
        foreach ($attrib in $request.AttributeRequests) {
            $attributes[$attrib.Name] = $attrib.Value
        }
    }

    return $attributes
}

function Get-AttributeValueCaseInsensitive([hashtable] $attributes, [String] $name) {
    foreach ($entry in $attributes.GetEnumerator()) {
        if ($entry.Key -ieq $name) {
            return [string]$entry.Value
        }
    }

    return $null
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

function Resolve-HomeFolderPath {
    param(
        [String] $basePath,
        [String] $template,
        [hashtable] $attributes,
        [String] $samAccountName
    )

    $expanded = Expand-HomeFolderTemplate $template $attributes

    if ([string]::IsNullOrWhiteSpace($expanded) -or (Test-TemplateHasUnresolvedTokens $expanded)) {
        if ($enableDebug) {
            LogToFile("Template blank or contains unresolved placeholders. Falling back to sAMAccountName: '$samAccountName'")
        }
        $expanded = $samAccountName
    }

    if (Test-IsAbsolutePath $expanded) {
        return $expanded
    }

    if ([string]::IsNullOrWhiteSpace($basePath)) {
        throw "HomeFolderBasePath is required when HomeFolderTemplate resolves to a relative path ('$expanded')."
    }

    return Join-Path -Path $basePath -ChildPath $expanded
}

###############################################################################################################################
# BODY
###############################################################################################################################

$appAttributes = Get-ApplicationAttributes

if ($appAttributes["HomeFolderDebugEnabled"] -eq "true" -or $appAttributes["HomeFolderDebugEnabled"] -eq "True") {
    $enableDebug = $true
}

if ($enableDebug) {
    LogToFile("Entering ConnectorAfterCreate for Active Directory Home Folders")
    LogToFile("--- Input Variables ---")
    LogToFile("env:Request: $($env:Request)")
    LogToFile("env:Application: $($env:Application)")
    LogToFile("Parsed Application Attributes:")
    if ($appAttributes) {
        $appAttributes.GetEnumerator() | ForEach-Object { LogToFile("  $($_.Name): $($_.Value)") }
    }
    LogToFile("-----------------------")
}

try {
    ##########################
    # Begin SailPoint protected code -- do not modify this code block
    #
    $sReader = New-Object System.IO.StringReader([System.String]$env:Request)
    $xmlReader = [System.xml.XmlTextReader]([sailpoint.utils.xml.XmlUtil]::getReader($sReader))
    $requestObject = New-Object Sailpoint.Utils.objects.AccountRequest($xmlReader)

    if ($enableDebug) {
        LogToFile("Request object contents:")
        LogToFile($requestObject | Out-String)
    }
    #
    # End SailPoint protected code
    ##########################

    ##########################
    # Begin Client-provided code

    if ($requestObject.Operation -eq "Create") {
        $attributeMap = Get-AccountRequestAttributeMap $requestObject
        $SAMAccountName = Get-AttributeValueFromAccountRequest $requestObject "sAMAccountName"

        if ([string]::IsNullOrWhiteSpace($SAMAccountName)) {
            throw "sAMAccountName could not be successfully extracted from the plan payload."
        }

        $HomeFolderBasePath = $appAttributes["HomeFolderBasePath"]
        $HomeFolderTemplate = $appAttributes["HomeFolderTemplate"]

        if ($enableDebug) {
            LogToFile("Parsed attributes -> sAMAccountName: '$SAMAccountName'")
            LogToFile("Configuration -> HomeFolderBasePath: '$HomeFolderBasePath', HomeFolderTemplate: '$HomeFolderTemplate'")
        }

        $TargetHomePath = Resolve-HomeFolderPath `
            -basePath $HomeFolderBasePath `
            -template $HomeFolderTemplate `
            -attributes $attributeMap `
            -samAccountName $SAMAccountName

        if ($enableDebug) {
            LogToFile("Calculated home folder target path: $TargetHomePath")
        }

        if (-not (Test-Path -Path $TargetHomePath)) {
            LogToFile("Target path missing. Creating folder tree: $TargetHomePath")
            New-Item -ItemType Directory -Force -Path $TargetHomePath | Out-Null
        } else {
            LogToFile("Target home folder already exists at path. Updating permissions on existing resource.")
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
        LogToFile("Successfully restricted folder inheritance and applied exclusive ACL ownership to $SAMAccountName.")
    } else {
        if ($enableDebug) {
            LogToFile("Skipping workflow. Action is restricted exclusively to 'Create' operations. Current operation: $($requestObject.Operation)")
        }
    }

    #
    # End Client-provided code
}
catch {
    $ErrorMessage = $_.Exception.Message
    $ErrorItem = $_.Exception.ItemName
    LogToFile("Error: Item = $ErrorItem -> Message = $ErrorMessage")
    exit 1
}

if ($enableDebug) {
    LogToFile("Exiting ConnectorAfterCreate for Active Directory Home Folders")
}
