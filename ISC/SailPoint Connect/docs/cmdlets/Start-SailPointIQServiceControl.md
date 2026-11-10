# `Invoke-SailPointIQServiceControl` & `New-SailPointM365AccessProfile`

## `Invoke-SailPointIQServiceControl` (Alias: `Start-SailPointIQServiceControl`)

Operator utility for Windows IQService hosts.

### Synopsis
```powershell
Invoke-SailPointIQServiceControl [[-Action] <String>] [-InstallPath <String>]
    [-InstanceName <String>] [-DownloadUri <String>] [-ZipPath <String>]
    [-LogLevel <String>] [-NonInteractive] [<CommonParameters>]
```

### Key Actions
- `Status`: Inspect service state, port, version, and TLS.
- `Download`: Fetch IQService from an ISC pre-signed URL.
- `Install`: Extract, unblock binaries, and register Windows service.
- `StreamLogs`: Colored real-time streaming of IQService logs.
- `EnableLdaps`: Verifies AD LDAPS (TCP 636) and exports PEM certificates for VA truststores.

---

## `New-SailPointM365AccessProfile`

Creates requestable SailPoint access profiles from Microsoft Entra service plan entitlements.

### Synopsis
```powershell
New-SailPointM365AccessProfile [-Environment <String>] [-SourceId <String>]
    [-PlanValues <String[]>] [-AccessProfilePrefix <String>]
    [-ApplicationName <String>] [-SkipApplication] [-NonInteractive]
```

### Features
1. Discovers Microsoft Entra sources in ISC with `type=servicePlan` entitlements.
2. Displays friendly Microsoft 365 licensing plan names for interactive multi-selection.
3. Automatically creates prefixed access profiles and an optional grouping source application in ISC.
