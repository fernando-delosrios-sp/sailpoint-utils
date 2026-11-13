# `Get-SailPointConnectUpdate`

Checks PowerShell Gallery for updates to the `SailPoint.Connect` module.

## Synopsis

```powershell
Get-SailPointConnectUpdate [-CurrentVersion <Version>] [-Repository <String>]
    [-TimeoutSeconds <Int32>] [-Force] [<CommonParameters>]
```

## Description

`Get-SailPointConnectUpdate` queries the PowerShell Gallery to determine whether a newer version of `SailPoint.Connect` is published. It returns a custom object detailing the installed version, online version, and whether an update is available.

## Parameters

### `-Force`
Bypasses cached version checks and forces a fresh query to the gallery.

### `-TimeoutSeconds`
Web request timeout in seconds (default: 5).

## Examples

```powershell
Get-SailPointConnectUpdate
```
