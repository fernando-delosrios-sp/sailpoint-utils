# `Get-SailPointConnectProject` and `Set-SailPointConnectProject`

Manages project workspaces in `~/.sailpoint-connect/`.

## `Get-SailPointConnectProject`

Lists all workspaces currently stored in `~/.sailpoint-connect/`.

### Synopsis
```powershell
Get-SailPointConnectProject
```

### Outputs
Returns an array of `PSCustomObject` items:
- `Name`: Name of the workspace folder.
- `IsCurrent`: Boolean indicating whether this workspace is currently selected as active.
- `Path`: Full directory path on disk.

### Example
```powershell
Get-SailPointConnectProject | Format-Table -AutoSize
```

---

## `Set-SailPointConnectProject`

Sets the active project workspace in `~/.sailpoint-connect/current.json`.

### Synopsis
```powershell
Set-SailPointConnectProject [-Name] <String>
```

### Parameters
- `-Name`: The workspace name to activate.

### Example
```powershell
Set-SailPointConnectProject -Name "emea-tes-team"
```
