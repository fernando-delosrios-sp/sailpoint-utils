# IQService Control & Host Management Guide

Guide for managing Windows IQService instances, service lifecycle, log tracing, and Active Directory LDAPS TLS certificate preparation via `Invoke-SailPointIQServiceControl` (`IQService Control.ps1`).

---

## 1. Overview & Capabilities

**IQService** is the native Windows service used by SailPoint Identity Security Cloud (ISC) to manage Active Directory, Windows Local, SharePoint, and Domino via native Windows APIs.

`Invoke-SailPointIQServiceControl` runs on the Windows IQService host in an elevated PowerShell 7 session to automate:
- **Download & Registration:** Unpacks and installs IQService instances.
- **Upgrades:** Backs up the directory, stops/unregisters the old binary, unpacks the new version, restores registry keys, and restarts the service.
- **Binary Unblocking:** Removes `Zone.Identifier` alternative data streams from downloaded `.dll` and `.zip` files (preventing `Utils.dll` assembly load failures).
- **Log Streaming & Trace Levels:** Live colorized log streaming and dynamic log level changes (`Error`, `Info`, `Debug`, `Trace`).
- **Active Directory LDAPS (TCP 636):** Automatic selection/creation of LDAPS certificates, linking to the NTDS service store, firewall configuration, and PEM chain export for SailPoint Virtual Appliance (VA) truststores.

---

## 2. Interactive Operator Menu

Run on the IQService host in an elevated PowerShell 7 (`pwsh`) session:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
Invoke-SailPointIQServiceControl
# Or directly via script:
.\IQService Control.ps1
```

Supported menu actions:
1. **Status:** Version, path, Windows service status, registry ports, trace settings, and `Utils.dll` state.
2. **Download ZIP:** Downloads fresh IQService bundle from a pre-signed ISC URL or local path.
3. **Install / Register:** Extracts binaries, unblocks DLLs, and executes `IQService.exe -i`.
4. **Update:** Performs atomic backup, upgrade, and restores trace settings.
5. **Start / Stop / Restart:** Wraps service control commands.
6. **Set Log Level:** Switches between `Off`, `Error`, `Info`, `Debug`, or `Trace`.
7. **Stream Logs:** Live-tails `iqtrace.log` with highlighted log levels (Press `Esc` or `Q` to stop).
8. **Unblock:** Strips mark-of-the-web from all binaries.
9. **Enable AD LDAPS:** Configures domain controller TLS certificate and exports PEM chains.
10. **Switch Instance:** Toggles between multiple installed instances on the same host.

---

## 3. Parameterized CLI Usage

```powershell
# Check current status of IQService
Invoke-SailPointIQServiceControl -Action Status

# Install IQService with custom TLS port
Invoke-SailPointIQServiceControl `
  -Action Install `
  -ZipPath 'C:\Downloads\IQService.zip' `
  -TlsPort 5050 `
  -StartAfterInstall

# Stream logs with 100 historical lines
Invoke-SailPointIQServiceControl -Action StreamLogs -Tail 100

# Set logging level to Debug
Invoke-SailPointIQServiceControl -Action SetLogLevel -LogLevel Debug

# Enable AD LDAPS on a Domain Controller and export VA certificates
Invoke-SailPointIQServiceControl -Action EnableLdaps -RestartNtds
```

---

## 4. Enabling Active Directory LDAPS (TCP 636)

Run on an Active Directory Domain Controller to prepare TLS encryption for Virtual Appliances:

1. Evaluates existing machine certificates for **Server Authentication EKU**, **DigitalSignature + KeyEncipherment**, and **KeyExchange**.
2. If none exist, generates a self-signed Schannel certificate, trusts it in `Root`, and links it to the `NTDS\My` service certificate store.
3. Configures inbound Windows Firewall rules for TCP **636**.
4. Exports the certificate chain in PEM format under `C:\SailPoint\IQService\va-certificates\`.
5. Outputs the manual steps required to upload the PEM chain to `/home/sailpoint/certificates` on each SailPoint Virtual Appliance.

---

## 5. Troubleshooting

| Symptom | Cause and Fix |
| :--- | :--- |
| `Could not load file or assembly 'Utils.dll'` | Mark-of-the-web is set on downloaded files. Run `Invoke-SailPointIQServiceControl -Action Unblock`. |
| Download fails with 403 / expired URL | Pre-signed ISC URLs expire after an hour. Generate a fresh link from **ISC → Connections → Sources → IQService → Download**. |
| `Administrator privileges are required` | Start PowerShell 7 as Administrator. |
| LDAPS clients fail to connect over 636 | Ensure the domain controller certificate is linked to `NTDS\SystemCertificates\My` (the script handles this). Confirm the certificate SAN matches the domain FQDN. |
| Multi-instance host ambiguity | When multiple IQService instances exist, supply `-InstanceName <Name>` or `-InstallPath <Path>`. |
