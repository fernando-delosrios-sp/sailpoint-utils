# Active Directory Home Folders

## Purpose

ConnectorAfterCreate rule for the Active Directory connector that creates a user's home folder on the file system after account creation, applies exclusive NTFS permissions for the new account, and derives the destination path from configurable source attributes.

Unlike a hardcoded path layout, the rule reads `HomeFolderBasePath` and `HomeFolderTemplate` from the AD source so the same rule can be reused across environments and folder structures.

## Script

* **`Active Directory Home Folders.ps1`**: ConnectorAfterCreate rule source. Runs after a successful AD account creation, resolves the target folder path, creates the directory tree if needed, breaks inheritance, and grants Full Control to the new user and `BUILTIN\Administrators`.

## Installation

IQService runs After Create PowerShell from the connector rule attached on the source. **Do not copy this script onto each IQService host manually.** Upload the rule to ISC and reference it from the source's `nativeRules` list. See [AfterCreate / nativeRules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules#aftercreate-aftermodify-afterdelete-beforecreate-beforemodify-beforedelete-rules).

Use the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow) for installation and configuration. The extension is a community tool (not developed or supported by SailPoint) that lets you create, edit, and import connector rule scripts, and edit source configuration from VS Code.

### 1. Install the VS Code extension

1. Install [SailPoint Identity Security Cloud for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow).
2. Connect the extension to your ISC tenant (Personal Access Client credentials).

### 2. IQService prerequisites

On each IQService host that may execute the rule:

1. Confirm `Utils.dll` exists in the IQService install directory (the rule loads it with an unqualified path because IQService copies the rule script into that folder at runtime).
2. Verify the IQService **Run As** service account can create folders and set NTFS ACLs on the target share or volume.
3. Set the IQService Windows Service **Run As** account to that service account (not Local System or the logged-on user).

### 3. Create the connector rule

In VS Code, using the SailPoint Identity Security Cloud extension:

1. Open **Connector Rules** for your tenant.
2. Create a new connector rule named `Active Directory Home Folders`.
3. Set the rule type to **ConnectorAfterCreate**.
4. Import or paste the contents of `Active Directory Home Folders.ps1` into the rule script.
5. Save the rule to the tenant.

The extension handles script export/import and rule upload; you do not need to prepare JSON payloads or call the Connector Rule REST APIs manually.

### 4. Attach the rule to the AD source

In the extension, open your Active Directory source and edit **Native Rules** (`connectorAttributes.nativeRules`):

1. Add `Active Directory Home Folders` to the native rules list.
2. Include **every** Before/After Create/Modify/Delete native rule that source should run, not only this one.
3. Save the source.

### 5. Configure source attributes

On the same AD source, add these **connector attributes**:

| Attribute | Example value |
| :--- | :--- |
| `HomeFolderBasePath` | `C:\Shared Folders` |
| `HomeFolderTemplate` | `$department\Personal\$sAMAccountName` |
| `HomeFolderDebugEnabled` | `true` |
| `HomeFolderLogFile` | `C:\SailPoint\ActiveDirectoryHomeFolders.log` |

Save the source after updating the attributes.

### 6. Test

Provision a new AD account and confirm:

* The folder is created at the expected path.
* The new user has Full Control on the folder.
* Debug and operational logs appear on the IQService host. Default: `%TEMP%\ActiveDirectoryHomeFolders_YYYYMMDD.log`. With `HomeFolderLogFile` set, e.g. `C:\SailPoint\ActiveDirectoryHomeFolders.log` → `C:\SailPoint\ActiveDirectoryHomeFolders_YYYYMMDD.log`.

## Configuration

The rule reads configuration from the SailPoint **Application Hashmap** (source `connectorAttributes`). ISC passes source attributes to IQService via the `$env:Application` XML payload.

Configure these attributes on your AD source using the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow) (open the source and edit its connector attributes).

### Available configuration attributes

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `HomeFolderBasePath` | `string` | Root path used when `HomeFolderTemplate` resolves to a **relative** path. Ignored when the expanded template is absolute. Required for relative templates. |
| `HomeFolderTemplate` | `string` | **Optional.** Path template with placeholders filled from the account request. Supports `$attributeName` and `{attributeName}` (case-insensitive attribute match). If blank or still containing unresolved placeholders after expansion, defaults to `sAMAccountName`. |
| `HomeFolderDebugEnabled` | `boolean` | Set to `"true"` to enable detailed debug logging. |
| `HomeFolderLogFile` | `string` | **Optional.** Log file path such as `C:\SailPoint\ActiveDirectoryHomeFolders.log`. `_YYYYMMDD` is appended before the extension (e.g. `ActiveDirectoryHomeFolders_20260824.log`). Defaults to `%TEMP%\ActiveDirectoryHomeFolders_YYYYMMDD.log` when not set. |

### Example source configuration

Relative path (equivalent to the original hardcoded layout):

```json
{
  "connectorAttributes": {
    "HomeFolderBasePath": "C:\\Shared Folders",
    "HomeFolderTemplate": "$department\\Personal\\$sAMAccountName",
    "HomeFolderDebugEnabled": "true",
    "HomeFolderLogFile": "C:\\SailPoint\\ActiveDirectoryHomeFolders.log",
    "nativeRules": ["Active Directory Home Folders"]
  }
}
```

Absolute path (base path ignored):

```json
{
  "connectorAttributes": {
    "HomeFolderTemplate": "\\\\fileserver\\users$\\$sAMAccountName",
    "HomeFolderDebugEnabled": "false",
    "nativeRules": ["Active Directory Home Folders"]
  }
}
```

Fallback when template is missing or unresolvable:

```json
{
  "connectorAttributes": {
    "HomeFolderBasePath": "C:\\Shared Folders\\Personal",
    "HomeFolderTemplate": "",
    "nativeRules": ["Active Directory Home Folders"]
  }
}
```

Creates `C:\Shared Folders\Personal\<sAMAccountName>`.

## How it works

1. IQService executes the uploaded ConnectorAfterCreate rule after a successful AD account creation.
2. The rule parses `$env:Request` into an `AccountRequest` and reads `$env:Application` for configuration.
3. It resolves the log file path from `HomeFolderLogFile` (or the default under `%TEMP%`) and appends `_YYYYMMDD` to the file name.
4. On `Create` operations only, it builds an attribute map from the account request (including `nativeIdentity`).
5. It expands `HomeFolderTemplate` using account request attribute values.
6. Path resolution:
   * **Blank or unresolved template** → use `sAMAccountName` as the path fragment.
   * **Absolute expanded path** (`\\server\share\...` or `X:\...`) → use it directly; base path is ignored.
   * **Relative expanded path** → `Join-Path` of `HomeFolderBasePath` + expanded template. Fails if base path is missing. Creates `HomeFolderBasePath` first if it does not exist.
7. It creates the home folder (and any missing intermediate directories) if needed, breaks NTFS inheritance, and applies Full Control for the new user and `BUILTIN\Administrators`.

## Out of scope

* Does not set AD `homeDirectory` or `homeDrive` attributes unless those are already part of the provisioning plan.
* Does not run on Modify or Delete operations.
* Does not query Active Directory for missing template attributes; placeholders must be present in the account request (or the template falls back to `sAMAccountName`).

## References

* [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow)
* [Before and after operations on source account Rule](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules/before-and-after-rule-operations)
* [Connector executed Rules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules)
