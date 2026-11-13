# Prerequisites & Toolchain

SailPoint Connect runs on modern cross-platform PowerShell and integrates with official cloud CLIs.

---

## 1. PowerShell 7+

PowerShell 7.0 or higher (`pwsh`) is required on macOS, Windows, and Linux. On Windows, use the PowerShell 7 app, which sits beside the built-in Windows PowerShell 5.1 (`powershell.exe`).

Confirm the version after install:

```powershell
pwsh -NoLogo -Command '$PSVersionTable.PSVersion'
```

Major version 7 or higher is the expected result.

### macOS

With [Homebrew](https://brew.sh/):

```bash
brew install --cask powershell
```

Microsoft's supported installer is the signed package on the [PowerShell releases](https://github.com/PowerShell/PowerShell/releases) page (`powershell-*-osx-arm64.pkg` on Apple silicon, `powershell-*-osx-x64.pkg` on Intel). Details: [Install PowerShell on macOS](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-macos).

### Windows

PowerShell 7 installs beside Windows PowerShell 5.1. On Windows 11 or Windows Server 2025:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Start **PowerShell 7** from the Start menu, or run `pwsh`. The **Windows PowerShell** shortcut is version 5.1. On Windows Server without `winget`, install the MSI from the [releases](https://github.com/PowerShell/PowerShell/releases) page. Details: [Install PowerShell on Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows).

### Linux

**Ubuntu** 22.04, 24.04, or 26.04. This registers the Microsoft package repository, then installs PowerShell:

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q "https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

**Red Hat Enterprise Linux** 8, 9, or 10:

```bash
source /etc/os-release
majorver=${VERSION_ID%.*}
curl -sSL -O "https://packages.microsoft.com/config/rhel/$majorver/packages-microsoft-prod.rpm"
sudo rpm -i packages-microsoft-prod.rpm
rm packages-microsoft-prod.rpm
sudo dnf install powershell -y
```

Debian and other distributions: [Install PowerShell on Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux). Then run `pwsh`.

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
