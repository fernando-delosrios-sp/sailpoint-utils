# Active Directory OU Management Scripts

## Purpose

IQService BeforeScripts for the Active Directory connector that parse provisioning requests and automatically create missing Organizational Units—and optionally a dedicated security group for each new OU—so accounts land in the correct container without manual AD preparation.

## Scripts
* **`ConnectorBeforeCreate - Create Active Directory OU.ps1`**: Triggered before an account creation. Extracts the OU path from the requested `NativeIdentity` and ensures all OUs in the path exist.
* **`ConnectorBeforeModify - Create Active Directory OU.ps1`**: Triggered before an account modification. Extracts the OU path from the `AC_NewParent` attribute request and ensures all OUs in the path exist.

## Setup Instructions

For each IQService host that could run the script, perform the following setup:
1. Update the path to `Utils.dll` in the script if necessary (it defaults to `c:\SailPoint\IQService-IDN\Utils.dll`). It can be an unqualified path like `"Utils.dll"` if the script is copied directly to the IQService folder for execution.
2. Ensure the `Utils.dll` is present in the specified folder on each IQService host.
3. Verify that the Windows Service account running IQService has the appropriate Active Directory permissions to create Organizational Units and Groups.
4. Set the "Run As" account for the IQService Windows Service to the designated service account instead of just "Local System" or the logged-on user.
5. Set a proper location for the log file by updating the `$logFile` variable in the script.
6. Toggle the `$enableDebug` flag to `$true` or `$false` depending on your logging requirements.

## Configuration

Instead of relying on local configuration files on the IQService hosts, these scripts read their configuration dynamically from the SailPoint **Application Hashmap** (Source Attributes). 

Identity Security Cloud passes the Source configuration attributes directly to the IQService via the `$env:application` XML payload. The script will parse this payload for the configuration options.

### Available Configuration Attributes

You must define the following attributes on your Active Directory Source in ISC (via the REST API `connectorAttributes` or via Rule Attributes if deployed through the Connector Rules API):

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `OUDebugEnabled` | `boolean` | Set to `"true"` to enable detailed debug logging for the script execution to the log file. |
| `OUCreationEnabled` | `boolean` | Set to `"true"` to enable the automatic creation of missing OUs. If this is missing or `false`, the script will skip execution entirely. |
| `OUGroupCreationEnabled` | `boolean` | Set to `"true"` to enable the creation of a dedicated AD group for any new OU created by the script. |
| `OUGroupBaseDN` | `string` | **Optional.** The BaseDN where the dedicated groups should be created. If not provided, the group will be created inside the newly created OU. |
| `OUGroupNameTemplate` | `string` | The template string used to format the dedicated group name. You can use `{ouName}` as a placeholder, which will be replaced by the extracted OU name attribute (e.g., in `OU=Sales`, the placeholder resolves to `Sales`). Example: `GrQ-HI-{ouName}` |

### Example Source Configuration JSON Snippet
```json
{
  "connectorAttributes": {
    "OUDebugEnabled": "true",
    "OUCreationEnabled": "true",
    "OUGroupCreationEnabled": "true",
    "OUGroupBaseDN": "OU=Groups,DC=example,DC=com",
    "OUGroupNameTemplate": "GrQ-HI-{ouName}"
  }
}
```

## How It Works

1. The script reads the `$env:Request` string containing the SailPoint provisioning plan/account request.
2. It parses the `$env:application` string to load configuration flags.
3. If `OUCreationEnabled` is `true`, it analyzes the requested distinguished name.
4. It iterates from the top-level Domain Components (DC) downwards, checking if each OU in the path exists.
5. If an OU is missing, it attempts to create it (with retries on failure).
6. If the OU is successfully created and `OUGroupCreationEnabled` is `true`, it provisions a new AD Group formatted by `OUGroupNameTemplate` in the `OUGroupBaseDN` (or inside the new OU if no BaseDN is specified).

