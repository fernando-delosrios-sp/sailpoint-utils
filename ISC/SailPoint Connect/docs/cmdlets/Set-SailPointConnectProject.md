# `Set-SailPointConnectProject`

Sets the active project workspace for SailPoint Connect.

## Synopsis

```powershell
Set-SailPointConnectProject [-Name] <String> [<CommonParameters>]
```

## Description

`Set-SailPointConnectProject` updates the current project pointer in `~/.sailpoint-connect/current.json`. Subsequent commands and wizards will default to this workspace folder for logs, checklists, generated scripts, and audit records.

## Parameters

### `-Name`
The project name (e.g., `production`, `acme-migration`).

## Examples

```powershell
Set-SailPointConnectProject -Name "acme-corp"
```
