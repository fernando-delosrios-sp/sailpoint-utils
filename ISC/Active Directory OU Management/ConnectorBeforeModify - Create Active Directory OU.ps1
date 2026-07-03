// ###############################################################################################################################
# SETUP
# Instructions (for each IQService host that could run the script):
#   - Update the path to Utils.dll (can be an unqualified path like "Utils.dll" since script is copied to IQService folder for execution)
#   - Make sure Utils.dll is in the specified folder on each IQService host
#   - Be sure the account that runs IQService has appropriate permissions to create directories and set permissions on them
#   - Be sure to set the "run as" account for the IQService in Windows Service to the above-specified account instead of just the "logged on" user
#   - Set a proper location for the $logFile variable
#   - Set the $enableDebug flag to $true or $false to toggle debug mode
#
# APPLICATION ATTRIBUTES CONFIGURATION
# The following configuration options should be defined in the SailPoint Source (Application)
# attributes to control OU and group creation:
# 
# - OUDebugEnabled (boolean): Set to "true" to enable debug logging.
# - OUCreationEnabled (boolean): Set to "true" to enable OU creation.
# - OUGroupCreationEnabled (boolean): Set to "true" to enable group creation for new OUs.
# - OUGroupBaseDN (string): Optional. The BaseDN where the groups should be created. 
#                           If not provided, the group will be created inside the newly created OU.
# - OUGroupNameTemplate (string): The template string for the group name. 
#                                 Use "{ouName}" as a placeholder for the OU name.
#                                 Example: "GrQ-HI-{ouName}"
###############################################################################################################################

param (
 [Parameter(Mandatory=$true)][System.String]$requestString
)

#include SailPoint library
Add-Type -Path "c:\SailPoint\IQService-IDN\Utils.dll";

#import AD cmdlets
Import-Module activeDirectory

#log file info
$logDate = Get-Date -UFormat "%Y%m%d"
$logFile = "C:\SailPoint\ConnectorBeforeModify - Create Active Directory OU - $logDate.log"



###############################################################################################################################
# HELPER FUNCTIONS
###############################################################################################################################

#save logging files to a separate txt file
function LogToFile([String] $info) {
    $info | Out-File $logFile -Append
}

#if we have a non-null account request, get our value; otherwise return nothing
function Get-AttributeValueFromAccountRequest([sailpoint.Utils.objects.AccountRequest] $request, [String] $targetAttribute) {
    $value = $null;

    if ($request) {
        foreach ($attrib in $request.AttributeRequests) {
            if ($attrib.Name -eq $targetAttribute) {
                $value = $attrib.Value;
                break;
            }
        }
    } else {
        LogToFile("Account request object was null");
    }
    return $value;
}

#load configuration from Application XML
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

#create groups for an OU based on configuration
function Create-GroupsForOU {
    param(
        [string]$ouDistinguishedName,
        [string]$ouName,
        [object]$appAttributes
    )
    
    if (-not $appAttributes) {
        LogToFile "No application attributes provided, skipping group creation"
        return
    }
    
    $groupCreationEnabled = $false
    if ($appAttributes["OUGroupCreationEnabled"] -eq "true" -or $appAttributes["OUGroupCreationEnabled"] -eq "True") {
        $groupCreationEnabled = $true
    }
    
    if (-not $groupCreationEnabled) {
        LogToFile "Group creation is not enabled (OUGroupCreationEnabled is not true)"
        return
    }
    
    $template = $appAttributes["OUGroupNameTemplate"]
    if ([string]::IsNullOrWhiteSpace($template)) {
        LogToFile "No group name template provided (OUGroupNameTemplate is empty). Skipping group creation."
        return
    }
    
    $groupName = $template -replace '\{ouName\}', $ouName
    
    $baseDN = $appAttributes["OUGroupBaseDN"]
    if ([string]::IsNullOrWhiteSpace($baseDN)) {
        # Default to the OU itself if BaseDN is not provided
        $baseDN = $ouDistinguishedName
    }
    
    LogToFile "Creating dedicated group for OU: $ouName -> Group: $groupName in BaseDN: $baseDN"
    
    # Check if group already exists
    $groupExists = $false
    try {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$groupName'" -SearchBase $baseDN -SearchScope OneLevel -ErrorAction SilentlyContinue
        if ($existingGroup) {
            $groupExists = $true
            LogToFile "Group already exists: $groupName in $baseDN"
        }
    } catch {
        # Group doesn't exist
    }
    
    # Create the group if it doesn't exist
    if (-not $groupExists) {
        try {
            New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $baseDN
            LogToFile "Successfully created group: $groupName in $baseDN"
        } catch {
            LogToFile "Failed to create group: $groupName. Error: $($_.Exception.Message)"
        }
    }
}


###############################################################################################################################
# BODY
###############################################################################################################################
function Create-OUWithRetry {
    param(
        [string]$ouPath,
        [string]$ouName,
        [int]$maxRetries,
        [object]$appAttributes = $null
    )
    
    $retryCount = 0
    $success = $false
    
    LogToFile "Attempting to create OU: $ouName at path: $ouPath"
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            New-ADOrganizationalUnit -Name $ouName -Path $ouPath -ProtectedFromAccidentalDeletion $false
            $success = $true
            LogToFile "Successfully created OU: $ouName at $ouPath"
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                LogToFile "Failed to create OU: $ouName. Retry $retryCount of $maxRetries. Error: $($_.Exception.Message)"
                Start-Sleep -Seconds $RETRY_DELAY_SECONDS
            } else {
                LogToFile "Failed to create OU: $ouName after $maxRetries attempts. Error: $($_.Exception.Message)"
                throw "Failed to create OU: $ouName after $maxRetries attempts. Error: $($_.Exception.Message)"
            }
        }
    }
    
    # If OU was successfully created and we have appAttributes, create groups
    if ($success -and $appAttributes) {
        $ouDistinguishedName = "OU=$ouName,$ouPath"
        Create-GroupsForOU -ouDistinguishedName $ouDistinguishedName -ouName $ouName -appAttributes $appAttributes
    }
    
    return $success
}

$appAttributes = Get-ApplicationAttributes

if ($appAttributes["OUDebugEnabled"] -eq "true" -or $appAttributes["OUDebugEnabled"] -eq "True") {
    $enableDebug = $true
}

if($enableDebug) {
    LogToFile("Entering beforeScript")
    LogToFile("--- Input Variables ---")
    LogToFile("requestString parameter: $requestString")
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
        $sReader = New-Object System.IO.StringReader([System.String]$env:Request);
        $xmlReader = [System.xml.XmlTextReader]([sailpoint.utils.xml.XmlUtil]::getReader($sReader));
        $requestObject = New-Object Sailpoint.Utils.objects.AccountRequest($xmlReader);

        #debug line for testing
        if($enableDebug) {
            LogToFile("Request object contents:")
            LogToFile($requestObject | Out-String)
        }
    #
    # End SailPoint protected code
    ##########################

    # Configuration
    $MAX_RETRIES = 3
    $RETRY_DELAY_SECONDS = 2
    
    $ouCreationEnabled = $false
    if ($appAttributes["OUCreationEnabled"] -eq "true" -or $appAttributes["OUCreationEnabled"] -eq "True") {
        $ouCreationEnabled = $true
    }
    
    if (-not $ouCreationEnabled) {
        if ($enableDebug) {
            LogToFile("OU Creation is disabled by configuration (OUCreationEnabled is not true). Skipping OU creation.")
        }
    } else {
        # Get the AC_NewParent attribute value (case insensitive)
        $acNewParent = $null
        if ($requestObject -and $requestObject.AttributeRequests) {
            foreach ($attrib in $requestObject.AttributeRequests) {
                if ($attrib.Name -ieq "AC_NewParent") {
                    $acNewParent = $attrib.Value
                    break
                }
            }
        }
        
        if ($enableDebug) {
            LogToFile("AC_NewParent value: $acNewParent")
        }
        
        # If AC_NewParent is found and not empty, process OU creation
        if (-not [string]::IsNullOrWhiteSpace($acNewParent)) {
        
        # Parse the Distinguished Name to extract OU components
        # Split by comma (but handle escaped commas in DN)
        $dnComponents = $acNewParent -split '(?<!\\),'
        
        # Separate OUs from the domain components (DC)
        $ouComponents = @()
        $dcComponents = @()
        
        foreach ($component in $dnComponents) {
            $trimmedComponent = $component.Trim()
            if ($trimmedComponent -match '^OU=(.+)') {
                $ouComponents += $trimmedComponent
            } elseif ($trimmedComponent -match '^DC=(.+)') {
                $dcComponents += $trimmedComponent
            }
        }
        
        if ($enableDebug) {
            LogToFile("Found $($ouComponents.Count) OU components and $($dcComponents.Count) DC components")
        }
        
        # Build the base path from domain components
        $basePath = $dcComponents -join ','
        
        if ([string]::IsNullOrWhiteSpace($basePath)) {
            LogToFile("Warning: No domain components (DC) found in AC_NewParent. Cannot proceed with OU creation.")
        } else {
            
            if ($enableDebug) {
                LogToFile("Base domain path: $basePath")
            }
            
            # Reverse the OU components to build from top to bottom
            # (DN is in reverse order: deepest OU first)
            [array]::Reverse($ouComponents)
            
            # Iterate through each OU level and create if it doesn't exist
            $currentPath = $basePath
            $previousPath = $null
            
            foreach ($ouComponent in $ouComponents) {
                # Extract OU name from "OU=Name" format
                if ($ouComponent -match '^OU=(.+)') {
                    $ouName = $matches[1]
                    
                    # Check if this OU already exists
                    $ouExists = $false
                    $existingOUDN = $null
                    try {
                        $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $currentPath -SearchScope OneLevel -ErrorAction SilentlyContinue
                        if ($existingOU) {
                            $ouExists = $true
                            $existingOUDN = $existingOU.DistinguishedName
                            if ($enableDebug) {
                                LogToFile("OU already exists: $ouName at $currentPath")
                            }
                        }
                    } catch {
                        # OU doesn't exist or error occurred, we'll try to create it
                        if ($enableDebug) {
                            LogToFile("OU check failed (will attempt creation): $ouName at $currentPath. Error: $($_.Exception.Message)")
                        }
                    }
                    
                    # Create the OU if it doesn't exist
                    if (-not $ouExists) {
                        try {
                            Create-OUWithRetry -ouPath $currentPath -ouName $ouName -maxRetries $MAX_RETRIES -appAttributes $appAttributes
                        } catch {
                            LogToFile("Critical error: Failed to create OU $ouName at $currentPath. Stopping OU creation process.")
                            throw
                        }
                    } else {
                        # OU already exists, but we should still create groups if they don't exist
                        if ($appAttributes -and $existingOUDN) {
                            Create-GroupsForOU -ouDistinguishedName $existingOUDN -ouName $ouName -appAttributes $appAttributes
                        }
                    }
                    
                    # Update paths for the next iteration
                    $currentPath = "OU=$ouName,$currentPath"
                    $previousPath = $currentPath
                }
            }
            
            if ($enableDebug) {
                LogToFile("Completed OU path creation. Final path: $currentPath")
            }
        }
        
    } else {
        LogToFile("AC_NewParent attribute not found or is empty. No OU creation performed.")
        }
    }
    
}
catch {
    $ErrorMessage = $_.Exception.Message
   $ErrorItem = $_.Exception.ItemName
   LogToFile("Error: Item = $ErrorItem -> Message = $ErrorMessage")
}

if($enableDebug) {
    LogToFile("Exiting beforeScript")
}