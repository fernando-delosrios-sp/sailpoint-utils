# Active Directory Home Folders

## Purpose

ConnectorAfterCreate rule for the Active Directory connector that creates a user's home folder on the file system after account creation, applies exclusive NTFS permissions for the new account, and derives the destination path from configurable source attributes.

Unlike a hardcoded path layout, the rule reads `HomeFolderBasePath` and `HomeFolderTemplate` from the AD source so the same rule can be reused across environments and folder structures.

This rule is built from [PowerShell Rule Template](../PowerShell%20Rule%20Template/README.md). Bootstrap, artifact preservation, context logging, redaction, and exit handling come from the template. Home-folder path resolution and ACL work live in the custom process section.

## Script

- **`Active Directory Home Folders.ps1`**: ConnectorAfterCreate rule source. Runs after a successful AD account creation, resolves the target folder path, creates the directory tree if needed, breaks inheritance, and grants Full Control to the new user and `BUILTIN\Administrators`.

## Installation

IQService runs After Create PowerShell from the connector rule attached on the source. **Do not copy this script onto each IQService host manually.** Upload the rule to ISC and reference it from the source's `nativeRules` list. See [AfterCreate / nativeRules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules#aftercreate-aftermodify-afterdelete-beforecreate-beforemodify-beforedelete-rules).

Use the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow) for installation and configuration. The extension is a community tool (not developed or supported by SailPoint) that lets you create, edit, and import connector rule scripts, and edit source configuration from VS Code.

### 1. Install the VS Code extension

1. Install [SailPoint Identity Security Cloud for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow).
2. Connect the extension to your ISC tenant (Personal Access Client credentials).

### 2. IQService prerequisites

On each IQService host that may execute the rule:

1. Confirm the IQService Windows Service **Run As** account can create and write under `<IQService>\scripts`.
2. Confirm `Utils.dll` exists in the IQService install directory. The rule loads it from `$script:RuleIQServiceDirectory` after bootstrap, then from `$PSScriptRoot` if needed. If neither works, set `HomeFolderUtilsDllPath` to the full path.
3. Verify the IQService **Run As** service account can create folders and set NTFS ACLs on the target share or volume.
4. Set the IQService Windows Service **Run As** account to that service account (not Local System or the logged-on user).
5. Confirm the PowerShell execution policy allows the generated runtime script to run.

The rule does not import the `ActiveDirectory` module, so RSAT is not required on the IQService host.

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

| Attribute                | Example value                          |
| :----------------------- | :------------------------------------- |
| `HomeFolderBasePath`     | `C:\Shared Folders`                    |
| `HomeFolderTemplate`     | `$department\Personal\$sAMAccountName` |
| `HomeFolderDebugEnabled` | `true`                                 |

Save the source after updating the attributes.

### 6. Test

Provision a new AD account and confirm:

- The folder is created at the expected path.
- The new user has Full Control on the folder.
- A per-run log and a preserved runtime script appear under `<IQService>\scripts`.

## Configuration

### Script constants

These live at the top of `Active Directory Home Folders.ps1`. They are not source attributes.

| Constant             | Value in this rule                | Description                                                                                                                                                                                  |
| :------------------- | :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$ConnectorRuleType` | `"ConnectorAfterCreate"`          | Must match the connector rule type configured in ISC.                                                                                                                                        |
| `$ConnectorRuleName` | `"Active Directory Home Folders"` | ISC rule display name. Used as the script dump filename and as the prefix for the timestamped log and replay script. Falls back to the runtime GUID if empty. Also included in the log body. |
| `$ScriptsSubfolder`  | `"scripts"`                       | Folder under the IQService install directory where script dumps and logs are stored.                                                                                                         |

Optional script overrides. If defined, they win over the matching source attributes (`PwshSilentError`, `PwshUnsafePayloadLogging`, `PwshReplay`). Leave them commented out to use the source.

### Source attributes

The rule also reads configuration from the SailPoint **Application Hashmap** (source `connectorAttributes`). ISC passes source attributes to IQService via the `$env:Application` XML payload.

Configure these attributes on your AD source using the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow) (open the source and edit its connector attributes).

| Attribute                  | Type      | Description                                                                                                                                                                                                                                                                                                                                                                                                               |
| :------------------------- | :-------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `HomeFolderBasePath`       | `string`  | Root path used when `HomeFolderTemplate` resolves to a **relative** path. Ignored when the expanded template is absolute. Required for relative templates. **Use a UNC path, not a mapped drive letter** — see [Mapped drives](#mapped-drives-do-not-work). For a UNC value, include the server name and point at a folder inside an existing share (`\\fileserver\SharedFolders\HomeDir`), not at the share root itself. |
| `HomeFolderTemplate`       | `string`  | **Optional.** Path template with placeholders filled from the account request. Supports `$attributeName` and `{attributeName}` (case-insensitive attribute match). If blank or still containing unresolved placeholders after expansion, defaults to `sAMAccountName`.                                                                                                                                                    |
| `HomeFolderDebugEnabled`   | `boolean` | Set to `"true"` to enable extra process debug lines (template expansion, request object dump, Utils.dll candidate misses). The template context block is always written.                                                                                                                                                                                                                                                  |
| `HomeFolderUtilsDllPath`   | `string`  | **Optional.** Full path to `Utils.dll` on the IQService host. Set this only when the automatic lookup described under [IQService prerequisites](#2-iqservice-prerequisites) fails.                                                                                                                                                                                                                                        |
| `HomeFolderFailOnError`    | `boolean` | **Optional.** Overrides `PwshSilentError` at process time. `"false"` sets silent mode so the run reports success and the failure is recorded in the rule log only. See [Failure handling](#failure-handling).                                                                                                                                                                                                             |
| `PwshSilentError`          | `boolean` | **Optional.** Template option, default `false`. When `true`, process failures exit `0`. Script `$PwshSilentError` wins if defined.                                                                                                                                                                                                                                                                                        |
| `PwshUnsafePayloadLogging` | `boolean` | **Optional.** Template option, default `false`. When `true`, logs and replay scripts store raw payloads. Script `$PwshUnsafePayloadLogging` wins if defined.                                                                                                                                                                                                                                                              |
| `PwshReplay`               | `boolean` | **Optional.** Template option, default `false`. When `true`, write a replay script whose timestamp matches that run's log. Script `$PwshReplay` wins if defined.                                                                                                                                                                                                                                                          |

`HomeFolderLogFile` is no longer used. Logs always go under `<IQService>\scripts` as described in the template.

### Example source configuration

Relative path (equivalent to the original hardcoded layout):

```json
{
  "connectorAttributes": {
    "HomeFolderBasePath": "C:\\Shared Folders",
    "HomeFolderTemplate": "$department\\Personal\\$sAMAccountName",
    "HomeFolderDebugEnabled": "true",
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

1. IQService copies the uploaded rule to a generated runtime file such as `Script_<GUID>.ps1` and executes it after a successful AD account creation.
2. Template bootstrap resolves the IQService directory (preferring one that contains `IQService.exe` or `Utils.dll`), creates `<IQService>\scripts` if needed, and opens a per-run log. It then preserves the runtime script with SHA256 verification when IQService provided a backing file; if it did not, that step is skipped with a warning and logging is unaffected.
3. The template writes a context block (rule type, request operation, identity, redacted payloads) before any home-folder work.
4. Custom process code reads `$env:Application` for home-folder configuration and loads `Utils.dll` from the resolved IQService directory.
5. It parses `$env:Request` into an `AccountRequest`.
6. On `Create` operations only, it builds an attribute map from the account request (including `nativeIdentity`).
7. It expands `HomeFolderTemplate` using account request attribute values.
8. Path resolution:
   - **Blank or unresolved template** → use `sAMAccountName` as the path fragment.
   - **Absolute expanded path** (`\\server\share\...` or `X:\...`) → use it directly; base path is ignored.
   - **Relative expanded path** → `Join-Path` of `HomeFolderBasePath` + expanded template. Fails if base path is missing. Creates `HomeFolderBasePath` first if it does not exist.

   Before creating anything, the rule validates the root of the path: a drive letter must be visible to the service, and a UNC share root (`\\server\share`) must already exist and be reachable. See [`The path is not of a legal form`](#the-path-is-not-of-a-legal-form).

9. It creates the home folder (and any missing intermediate directories) if needed, breaks NTFS inheritance, and applies Full Control for the new user and `BUILTIN\Administrators`.

## Artifact layout

For a runtime file named `Script_496b999e-a4b7-4b58-8abf-47da35b69b13.ps1`:

```
C:\SailPoint\IQService-IDN\
  Script_496b999e-a4b7-4b58-8abf-47da35b69b13.ps1   # generated runtime copy (IQService)
  scripts\
    Active Directory Home Folders.ps1
    Active Directory Home Folders_20260825_040053123.log
```

When `$ConnectorRuleName` is empty, those files are `Script_496b999e-a4b7-4b58-8abf-47da35b69b13.ps1` and `Script_496b999e-a4b7-4b58-8abf-47da35b69b13_20260825_040053123.log`.

The dump is overwritten on each run of this rule. Timestamped logs accumulate without automatic cleanup.

## Failure handling

IQService treats **any** non-zero exit code from an after script as a failed post script:

```
WARN : "Create operation is successful but post script execution failed : After script returned non zero exit code : 1 : "
```

ISC can respond to that partial success by **rolling back the account creation**, so a file share being briefly unreachable can cost you the AD account that was otherwise created successfully. Whether it actually does is governed by the source's own `rollbackCreatedAccountOnError` connector attribute; check it before assuming either behavior:

```
<entry key="rollbackCreatedAccountOnError" value="false" />
```

Decide which failure mode you want:

| Setting                                                              | Behavior on a home folder failure                                                                                                                                                             |
| :------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PwshSilentError = false` (default), or `HomeFolderFailOnError=true` | Exit code 1. Provisioning is reported as failed and ISC may roll back the new AD account. Choose this when an account without a home folder is not usable.                                    |
| `PwshSilentError = true`, or `HomeFolderFailOnError=false`           | Exit code 0. The AD account is kept and the failure is recorded only in the rule log. Choose this when the account is useful on its own and you would rather remediate the folder separately. |

Exiting `1` does not remove the account by itself. This rule runs after the account already exists, so a failed run with a working account is the expected outcome whenever `rollbackCreatedAccountOnError` is absent or `false`.

The trailing text after `exit code : 1 :` in the IQService log is empty for every failure; IQService does not forward script output there. The rule log under `<IQService>\scripts` is the authoritative failure record.

The rule always terminates with an explicit exit code. This matters because Windows PowerShell can set a process exit code of `1` merely because something wrote to the error stream, which would otherwise trigger a rollback even on a successful run.

## Troubleshooting

### Mapped drives do not work

Set `HomeFolderBasePath` to a UNC path:

```
\\fileserver\HomeDir        correct
S:\HomeDir                  fails under the service
```

Mapped drive letters are created per logon session. A drive that the service account can see when you are signed in interactively does **not** exist in the session Windows uses to run the service, so the path silently resolves to nothing. The rule detects this and fails with an explicit message naming the drive rather than a generic "path not found".

### `The path is not of a legal form`

This is what an unusable `HomeFolderBasePath` used to look like in the log:

```
[INFO]  [process] Creating directory: \\SharedFolders\HomeDir
[ERROR] [process] Process error: Message = The path is not of a legal form. ... [New-Item], ArgumentException
```

In a UNC path the **first** component is always the server name, so `\\SharedFolders\HomeDir` means server `SharedFolders`, share `HomeDir` — a share root rather than a folder inside a share. The rule found it unreachable, tried to create it, and `New-Item -Force` walked up to `\\SharedFolders` and then `\\`, which is where the argument error comes from.

The rule now fails before that attempt, naming the parsed server and share. Two causes, both reported the same way:

| Cause                                             | Fix                                                                                                                                                                                                                                                |
| :------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The server name is missing from the path          | Use `\\<fileserver>\SharedFolders\HomeDir`. The base path must point at a folder inside an existing share.                                                                                                                                         |
| The server and share are right, but not reachable | Confirm the share exists and that the IQService Run As account can reach and write to it. A service running as Local System reaches the network as the computer account, which usually has no share access — use a domain service account instead. |

The rule creates missing folders **inside** a share, but never the share root or a drive root.

### No log under `<IQService>\scripts`

If the IQService log shows a non-zero exit code but no rule log appears, establish execution before debugging the logic.

1. Confirm the updated rule was uploaded to the tenant.
2. Confirm the rule name appears in `connectorAttributes.nativeRules`.
3. Search the whole IQService host for `Active Directory Home Folders_*.log`, not just `<IQService>\scripts`. The rule derives its artifacts directory at runtime, so a log written somewhere unexpected means the resolved IQService directory was wrong. The `IQServiceDirectorySource` line in that log says how the directory was chosen; anything other than a directory containing `IQService.exe` or `Utils.dll` is a guess.
4. Check for an emergency log under `%TEMP%` named `Active Directory Home Folders_<timestamp>.emergency.log`, or `Script_<GUID>_<timestamp>.emergency.log` if `$ConnectorRuleName` is empty. `%TEMP%` is resolved for the IQService **Run As** account, so look under that account's profile (or `C:\Windows\Temp` for `LOCAL SYSTEM`), not your own.
5. Confirm the IQService Run As account can create and write under `<IQService>\scripts`.

If nothing appears at any of those paths, the script never ran. The rule was not re-uploaded or is not in `nativeRules`, the PowerShell execution policy or antivirus is blocking it, or the uploaded rule body is malformed.

### `Utils.dll could not be loaded`

The log lists every path that was searched, and whether each one was missing or present-but-unloadable.

- **Missing from every path**: copy the real path of `Utils.dll` from the IQService install directory into the `HomeFolderUtilsDllPath` source attribute.
- **Found but failed to load**: the file is most likely blocked by Windows because it came from a downloaded archive. Right-click `Utils.dll` → **Properties** → tick **Unblock** → **Apply**. Then confirm the PowerShell execution policy is not `Restricted`:

```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### Need the raw request or application payload

Set `PwshUnsafePayloadLogging` to `true` on the source (or define `$PwshUnsafePayloadLogging = $true` in the script), reproduce once, collect the log, then set it back to `false`.

### The folder is created but permissions are wrong

Set `HomeFolderDebugEnabled` to `true` and re-run. Debug mode logs extra process detail. The template context block already includes the effective identity, working directory, and redacted `$env:Request` / `$env:Application` payloads.

## Out of scope

- Does not set AD `homeDirectory` or `homeDrive` attributes unless those are already part of the provisioning plan.
- Does not run on Modify or Delete operations.
- Does not query Active Directory for missing template attributes; placeholders must be present in the account request (or the template falls back to `sAMAccountName`).

## References

- [PowerShell Rule Template](../PowerShell%20Rule%20Template/README.md)
- [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow)
- [Before and after operations on source account Rule](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules/before-and-after-rule-operations)
- [Connector executed Rules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules)
