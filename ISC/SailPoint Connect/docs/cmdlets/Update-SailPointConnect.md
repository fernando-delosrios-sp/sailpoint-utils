# `Update-SailPointConnect` and `Get-SailPointConnectUpdate`

Manages SailPoint Connect module updates from the PowerShell Gallery.

## `Update-SailPointConnect`

Checks whether a newer release is published on PowerShell Gallery and updates or reinstalls the module. Also offered automatically when starting the interactive platform wizard if a newer release is detected.

### Synopsis

```powershell
Update-SailPointConnect [-CheckOnly] [-Force] [-Scope <CurrentUser | AllUsers>] [-TargetVersion <String>] [-NonInteractive] [-WhatIf] [-Confirm]
```

### Parameters

- `-CheckOnly`: Queries PowerShell Gallery and reports if an update is available without installing.
- `-Force`: Reinstalls the latest release even if the module is already up to date.
- `-Scope`: Target installation scope (`CurrentUser` by default, or `AllUsers`).
- `-TargetVersion`: Specific version string to install.
- `-NonInteractive`: Runs in automation or CI/CD pipelines without interactive confirmation prompts.

### Examples

```powershell
# Check for updates and install if a newer version is available
Update-SailPointConnect

# Or via alias
update-sailpoint-connect

# Check only without installing
Update-SailPointConnect -CheckOnly

# Reinstall or force update
Update-SailPointConnect -Force
```

---

## `Get-SailPointConnectUpdate`

Queries PowerShell Gallery (fast REST endpoint with fallback to `Find-Module`) to compare the latest published version against the currently running version.

### Synopsis

```powershell
Get-SailPointConnectUpdate [[-CurrentVersion] <String>] [-Repository <String>] [-TimeoutSeconds <Int32>] [-Force]
```

### Outputs

Returns a `PSCustomObject`:
- `UpdateAvailable`: Boolean indicating whether a newer release exists.
- `CurrentVersion`: Active version of the module.
- `LatestVersion`: Highest published release found on PowerShell Gallery.
- `Repository`: Name of the checked repository (`PSGallery`).
- `Skipped`: True if checks were suppressed via `SAILPOINT_CONNECT_SKIP_UPDATE_CHECK`.

### Example

```powershell
$status = Get-SailPointConnectUpdate
if ($status.UpdateAvailable) {
    Write-Host "Newer version available: $($status.LatestVersion)"
}
```
