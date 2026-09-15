# Active Directory OU Management

## Purpose

IQService Before rules for the Active Directory connector that create missing Organizational Units—and optionally a dedicated security group for each OU in the path—so accounts land in the correct container without manual AD preparation.

These rules are built from [PowerShell Rule Template](../PowerShell%20Rule%20Template/README.md). Bootstrap, artifact preservation, context logging, redaction, and exit handling come from the template. Distinguished-name walking, OU creation, and group creation live in the custom process section.

## Scripts

- **`ConnectorBeforeCreate - Create Active Directory OU.ps1`**: ConnectorBeforeCreate rule. Reads the OU path from the account request `NativeIdentity` and ensures every OU in that path exists.
- **`ConnectorBeforeModify - Create Active Directory OU.ps1`**: ConnectorBeforeModify rule. Reads the OU path from the `AC_NewParent` attribute request (account move) and ensures every OU in that path exists.

## Installation

IQService runs Before Create/Modify PowerShell from the connector rules attached on the source. **Do not copy these scripts onto each IQService host manually.** Upload each rule to ISC and reference both names from the source's `nativeRules` list. See [BeforeCreate / nativeRules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules#aftercreate-aftermodify-afterdelete-beforecreate-beforemodify-beforedelete-rules).

Use the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow) for installation and configuration.

### 1. Install the VS Code extension

1. Install [SailPoint Identity Security Cloud for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow).
2. Connect the extension to your ISC tenant (Personal Access Client credentials).

### 2. IQService prerequisites

On each IQService host that may execute the rules:

1. Confirm the IQService Windows Service **Run As** account can create and write under `<IQService>\scripts`.
2. Confirm the [RSAT Active Directory module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/) is installed.
3. Verify that account can create Organizational Units and Groups in the target domain.
4. Set the IQService Windows Service **Run As** account to that service account (not Local System or the logged-on user).
5. Confirm the PowerShell execution policy allows the generated runtime script to run.

Request and application XML are parsed through `$ctx`. `Utils.dll` is not required. The ActiveDirectory module is imported only when `OUCreationEnabled` is true and a target distinguished name is present.

### 3. Create the connector rules

In VS Code, using the SailPoint Identity Security Cloud extension, create two rules:

| ISC rule name | Type | Script |
| :------------ | :--- | :----- |
| `ConnectorBeforeCreate - Create Active Directory OU` | ConnectorBeforeCreate | `ConnectorBeforeCreate - Create Active Directory OU.ps1` |
| `ConnectorBeforeModify - Create Active Directory OU` | ConnectorBeforeModify | `ConnectorBeforeModify - Create Active Directory OU.ps1` |

For each rule: import or paste the matching script, then save it to the tenant. The `$ConnectorRuleName` constant in each file must match the ISC display name.

### 4. Attach the rules to the AD source

In the extension, open your Active Directory source and edit **Native Rules** (`connectorAttributes.nativeRules`):

1. Add both OU rule names to the native rules list.
2. Include **every** Before/After Create/Modify/Delete native rule that source should run, not only these.
3. Save the source.

### 5. Configure source attributes

On the same AD source, add the connector attributes in [Configuration](#configuration). Save the source after updating them.

### 6. Test

Provision a new AD account whose `NativeIdentity` includes an OU that does not yet exist, and move an account into a new parent. Confirm:

- Missing OUs (and optional groups) are created before the account operation proceeds.
- A per-run log and a preserved runtime script appear under `<IQService>\scripts`.

## Configuration

### Script constants

These live at the top of each script. They are not source attributes.

| Constant             | Create rule                                            | Modify rule                                            | Description |
| :------------------- | :----------------------------------------------------- | :----------------------------------------------------- | :---------- |
| `$ConnectorRuleType` | `"ConnectorBeforeCreate"`                              | `"ConnectorBeforeModify"`                              | Must match the connector rule type configured in ISC. |
| `$ConnectorRuleName` | `"ConnectorBeforeCreate - Create Active Directory OU"` | `"ConnectorBeforeModify - Create Active Directory OU"` | ISC rule display name. Prefix for dump, log, and replay filenames. |
| `$ScriptsSubfolder`  | `"scripts"`                                            | `"scripts"`                                            | Folder under the IQService install directory for artifacts. |

Optional script overrides. If you **define** `$PwshSilentError`, `$PwshUnsafePayloadLogging`, or `$PwshReplay`, that value wins over the matching source attribute. Leave them commented out to use the source.

### Source attributes

The rules read configuration from the SailPoint **Application Hashmap** (source `connectorAttributes`) through `$ctx.Application`.

| Attribute                  | Type      | Description |
| :------------------------- | :-------- | :---------- |
| `OUCreationEnabled`        | `boolean` | Set to `"true"` to create missing OUs. Missing or `false` skips the rule without calling Active Directory. |
| `OUDebugEnabled`           | `boolean` | Set to `"true"` to write extra process debug lines. The template context block is always written. |
| `OUGroupCreationEnabled`   | `boolean` | Set to `"true"` to ensure a dedicated security group for each OU in the path (new or already present). |
| `OUGroupBaseDN`            | `string`  | **Optional.** Container for those groups. When omitted, each group is created inside its OU. |
| `OUGroupNameTemplate`      | `string`  | Group name template. `{ouName}` is replaced with the OU name from `OU=Name`. Required when group creation is enabled. Example: `GrQ-HI-{ouName}`. |
| `PwshSilentError`          | `boolean` | **Optional.** Template option, default `false`. When `true`, process failures exit `0`. Script `$PwshSilentError` wins if defined. |
| `PwshUnsafePayloadLogging` | `boolean` | **Optional.** Template option, default `false`. When `true`, logs and replay scripts store raw payloads. |
| `PwshReplay`               | `boolean` | **Optional.** Template option, default `false`. When `true`, write a timestamped replay script for that run. |

`$logFile` and `$enableDebug` from earlier versions are unused. Logs always go under `<IQService>\scripts`. Use `OUDebugEnabled` for extra process detail.

### How these rules read inputs

```powershell
# Before Create
$targetDn = $ctx.Request.NativeIdentity

# Before Modify
$targetDn = Get-RequestAttribute "AC_NewParent"

$enabled = Get-ApplicationAttribute "OUCreationEnabled"
$template = Get-ApplicationAttribute "OUGroupNameTemplate"
```

Request and application XML are normalized once during bootstrap. See the template's [Rule input context](../PowerShell%20Rule%20Template/README.md#rule-input-context).

### Example source configuration

```json
{
  "connectorAttributes": {
    "nativeRules": [
      "ConnectorBeforeCreate - Create Active Directory OU",
      "ConnectorBeforeModify - Create Active Directory OU"
    ],
    "OUCreationEnabled": "true",
    "OUDebugEnabled": "true",
    "OUGroupCreationEnabled": "true",
    "OUGroupBaseDN": "OU=Groups,DC=example,DC=com",
    "OUGroupNameTemplate": "GrQ-HI-{ouName}",
    "PwshReplay": "true",
    "PwshSilentError": "false",
    "PwshUnsafePayloadLogging": "false"
  }
}
```

Turn `PwshReplay` off in steady state so timestamped `.replay.ps1` files do not accumulate.

## How it works

1. IQService copies the uploaded rule to a generated runtime file such as `Script_<GUID>.ps1` and executes it before the AD create or modify.
2. Template bootstrap resolves the IQService directory, creates `<IQService>\scripts` if needed, and opens a per-run log. It preserves the runtime script when IQService provided a backing file.
3. The template converts the application and account request XML into `$ctx.Application` and `$ctx.Request`, then writes a context block.
4. Custom process code reads `OUCreationEnabled`. If it is not true, the rule exits `0` without importing ActiveDirectory.
5. The Create rule uses `NativeIdentity`. The Modify rule uses `AC_NewParent`. CN and other non-OU RDNs are ignored. Domain components become the search base.
6. OU RDNs are walked from the domain downward. Each missing OU is created (up to three retries). If `OUGroupCreationEnabled` is true, a group named from `OUGroupNameTemplate` is ensured for every OU in the path.

## Artifact layout

```
C:\SailPoint\IQService-IDN\
  Script_<GUID>.ps1
  scripts\
    ConnectorBeforeCreate - Create Active Directory OU.ps1
    ConnectorBeforeCreate - Create Active Directory OU_<timestamp>.log
```

The Modify rule uses the matching `ConnectorBeforeModify - Create Active Directory OU*` names. The dump is overwritten on each run of that rule. Timestamped logs accumulate without automatic cleanup.

## Failure handling

These are **Before** rules. IQService treats a non-zero exit as a failed connector script and **aborts the pending create or move**.

| Setting                         | Behavior on OU or group-path failure |
| :------------------------------ | :----------------------------------- |
| `PwshSilentError = false` (default) | Exit code 1. The pending AD operation does not proceed. |
| `PwshSilentError = true`            | Exit code 0. The pending operation proceeds; the failure is only in the rule log. |

Group creation failures after a successful OU create are logged and do not abort the operation. Failed OU create after retries throws and follows the table above.

Earlier versions logged process errors and always continued. That silent-continue behavior is gone unless you set `PwshSilentError` to `true`.

The trailing text after `exit code : 1 :` in the IQService log is empty. The rule log under `<IQService>\scripts` is the authoritative failure record.

## Troubleshooting

### No log under `<IQService>\scripts`

1. Confirm the updated rule was uploaded and its name appears in `connectorAttributes.nativeRules`.
2. Search the host for `ConnectorBeforeCreate - Create Active Directory OU_*.log` (or the Modify name). `IQServiceDirectorySource` in an unexpected log says how the directory was chosen.
3. Check `%TEMP%` for `*.emergency.log` under the IQService **Run As** account (or `C:\Windows\Temp` for `LOCAL SYSTEM`).
4. Confirm that account can create `<IQService>\scripts`.

If nothing appears, the script never ran: not re-uploaded, not in `nativeRules`, blocked by execution policy or antivirus, or the uploaded body is malformed.

### ActiveDirectory module errors

The module is imported only when creation is enabled and a target DN is present. Install RSAT Active Directory tools on the IQService host and confirm `Import-Module ActiveDirectory` works as the Run As account.

### Need the raw request or application payload

Set `PwshUnsafePayloadLogging` to `true`, reproduce once, collect the log, then set it back to `false`.

## Out of scope

- Does not rename, move, or delete existing OUs or groups.
- Does not change the account `NativeIdentity` in the provisioning plan; it only prepares AD so the connector can use that path.
- The Modify rule does nothing when `AC_NewParent` is absent (attribute changes that are not a move).

## References

- [PowerShell Rule Template](../PowerShell%20Rule%20Template/README.md)
- [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow)
- [Before and after operations on source account Rule](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules/before-and-after-rule-operations)
- [Connector executed Rules](https://developer.sailpoint.com/docs/extensibility/rules/connector-rules)
