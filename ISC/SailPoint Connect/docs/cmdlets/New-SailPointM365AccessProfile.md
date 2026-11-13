# `New-SailPointM365AccessProfile`

Creates requestable SailPoint Identity Security Cloud (ISC) access profiles from Microsoft Entra `servicePlan` entitlements.

## Synopsis

```powershell
New-SailPointM365AccessProfile [-Wizard] [-Environment <String>]
    [-ConfigPath <String>] [-SourceId <String>] [-PlanValues <String[]>]
    [-AccessProfilePrefix <String>] [-ApplicationName <String>]
    [-SkipApplication] [-OwnerId <String>] [-PreviousManifestPath <String>]
    [-ExistingItemAction <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`New-SailPointM365AccessProfile`:
1. Queries an Entra ID source for `servicePlan` entitlements.
2. Resolves human-friendly display names from Microsoft's licensing reference table.
3. Creates requestable, enabled access profiles in ISC with standardized naming.
4. Optionally groups and links created profiles under a Source Application.
5. Emits JSON and CSV audit manifests to allow repeatable synchronizations.

## Parameters

### `-Wizard`
Launches interactive menu.

### `-SourceId`
ISC Source ID for the Entra ID connector.

### `-PlanValues`
Array or comma-separated list of service plan GUIDs or internal SKU names.

### `-AccessProfilePrefix`
Prefix for generated access profile names (default: `M365 - `).

### `-ApplicationName`
Source application name to create or link.

### `-ExistingItemAction`
Behavior when an access profile or application already exists: `Ask`, `Skip`, or `Update`.

## Examples

### Example 1: Interactive Wizard
```powershell
New-SailPointM365AccessProfile
```

### Example 2: Headless Generation
```powershell
New-SailPointM365AccessProfile `
  -SourceId "fd753b8266b64d09805d101b77bc35df" `
  -PlanValues "TEAMS1,EXCHANGE_S_ENTERPRISE" `
  -AccessProfilePrefix "M365 - " `
  -NonInteractive
```
