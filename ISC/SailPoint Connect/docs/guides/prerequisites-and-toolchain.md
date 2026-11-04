# Prerequisites & Toolchain

SailPoint Connect runs on modern cross-platform PowerShell and integrates with official cloud CLIs.

---

## 1. PowerShell 7+
PowerShell 7.0 or higher is required.

- **macOS**: `brew install powershell/tap/powershell`
- **Windows**: `winget install Microsoft.PowerShell`
- **Linux**: See official Microsoft packages for your distribution.

Verify:
```powershell
pwsh -NoLogo -Command '$PSVersionTable.PSVersion'
```

---

## 2. Cloud CLIs

SailPoint Connect auto-detects and checks your cloud CLI sessions. If a tool is missing, the built-in toolchain adapter offers to install it via Homebrew (macOS/Linux) or winget (Windows):

| Cloud / Component | CLI | Sign-In Verification |
| :--- | :--- | :--- |
| **AWS** | `aws` | `aws sts get-caller-identity` |
| **Azure / Entra ID** | `az` or Microsoft Graph | `az account show` or Graph sign-in |
| **Google Cloud** | `gcloud` | `gcloud auth list` |
| **Databricks** | `databricks` | Databricks CLI authentication |
| **SailPoint ISC** | `sail` / `PSSailpoint` | `~/.sailpoint/config.yaml` |

---

## 3. PowerShell Modules

When installed from the PowerShell Gallery (`Install-Module SailPoint.Connect`), module dependencies are resolved automatically.

- **PSSailpoint**: Official SailPoint PowerShell SDK for ISC tenant APIs.
- **Microsoft.Graph**: Used for Entra ID app registration and consent grants.
