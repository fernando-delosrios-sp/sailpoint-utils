# sailpoint-utils

## Purpose

Curated collection of reusable [SailPoint Identity Security Cloud (ISC)](https://www.sailpoint.com/products/identity-security-cloud/) and IdentityIQ (IIQ) patterns — rules, transforms, connector tooling, and third-party integrations. Each utility is self-contained with its own README for setup, artifacts, and usage. Browse by area below or see [CHANGELOG.md](CHANGELOG.md) for release history.

## Repository layout

| Path | Description |
| --- | --- |
| [`ISC/`](ISC/) | Rules, transforms, forms, and tenant configuration patterns |
| [`SaaS Connectivity/`](SaaS%20Connectivity/) | Connector testing helpers and custom-operation templates |
| [`Entro/`](Entro/) | Entro integration tooling and agent skills |
| [`Third-Party/`](Third-Party/) | Integrations with external systems |
| [`skills/`](skills/) | Installable agent skills (`npx skills add`) |
| [`IIQ/`](IIQ/) | IdentityIQ assets *(reserved)* |

## ISC utilities

| Utility | Description |
| --- | --- |
| [Active Directory Home Folders](ISC/Active%20Directory%20Home%20Folders/) | ConnectorAfterCreate rule (built from PowerShell Rule Template) that creates home folders with NTFS ACLs from configurable base path and template |
| [Active Directory OU Management](ISC/Active%20Directory%20OU%20Management/) | IQService BeforeScripts that create missing OUs—and optionally AD groups—during AD provisioning |
| [Active Directory Privileged Tasks](ISC/Active%20Directory%20Privileged%20Tasks/) | Interactive workflows to create an AD security group (PAG) or a CIFS share (access request + template-based BeforeModify rule) |
| [Demo Data](ISC/Demo%20Data/) | Tenant-seeded demo access model: delimited sources, birthright title/department roles, dimensional Workplace User with city dimensions, requestable SoD Demo roles that contain policy violations, and conflicting-access SoD policies |
| [Dynamic forms and user data collection](ISC/Dynamic%20forms%20and%20user%20data%20collection/) | Example form with cascading dropdowns and CSV-backed reference data |
| [Email Templates](ISC/Email%20Templates/) | Branded replacements for all ISC email templates: end-user wording translated into seven languages, and admin alerts kept in SailPoint's English inside the branded layout |
| [Emergency Termination](ISC/Emergency%20Termination/) | Interactive workflow that sets an active direct report to an Emergency Termination lifecycle state, with optional second-level manager approval |
| [Generic Manager Correlation](ISC/Generic%20Manager%20Correlation/) | Reusable pattern for correlating managers across heterogeneous sources |
| [Identity Match & Onboard](ISC/Identity%20Match%20%26%20Onboard/) | Interactive onboarding with a duplicate check, collision-safe usernames, optional manager approval, and a confirmed update when the person already has a source account |
| [JDBC SaaS Driver Downloader](ISC/JDBC%20SaaS%20Driver%20Downloader/) | Download and package JDBC drivers from Maven Central for SaaS upload |
| [LCS Operations](ISC/LCS%20Operations/) | BeforeProvisioning rule that maps lifecycle-state dummy attributes to native connector operations |
| [Machine Identity Security](ISC/Machine%20Identity%20Security/) | AD and Entra ID NHI package: subtypes, classification, mapping transforms, create forms, and machine-account provisioning policies |
| [Optimistic Provisioning Generic SDIM](ISC/Optimistic%20Provisioning%20Generic%20SDIM/) | Configuration guide for optimistic provisioning with Generic SDIM |
| [Organizational Hierarchy Path](ISC/Organizational%20Hierarchy%20Path/) | Transform rule that builds a consolidated org hierarchy path from entitlements |
| [PowerShell Rule Template](ISC/PowerShell%20Rule%20Template/) | Copy-ready IQService connector-rule bootstrap with logging, redaction, exit handling, and optional replay |
| [Source Connection Setup](ISC/Source%20Connection%20Setup/) | Entra ID app registration, Microsoft 365 access-profile wizard (service plans), AWS SaaS IAM role setup, Google Workspace SaaS service account setup, and IQService host control |
| [Source Management](ISC/Workflows/Source%20Management/) | Interactive workflow to pick a source and run account aggregation (optimised/full), entitlement aggregation, identity profile refresh, or source reset (accounts and/or entitlements) |
| [Transforms](ISC/Transforms/) | Reusable transform definitions (dates, lifecycle state, attribute history, manager flag) |

## SaaS Connectivity

| Utility | Description |
| --- | --- |
| [Postman remote source evaluation](SaaS%20Connectivity/Postman%20remote%20source%20evaluation/) | Postman pre-request script for ISC auth, source resolution, and remote connector invoke |
| [saas-custom-operations](SaaS%20Connectivity/saas-custom-operations/) | Foundation template for ISC custom operations with loopback API and dummy result source |

## Third-Party integrations

| Integration | Description |
| --- | --- |
| [MelonHRM HR source](Third-Party/MelonHRM/) | PostgreSQL HR feed (`melonhrm.sql`) with 15 identities for Identity Fusion NG scenario coverage |
| [OrangeHRM → ISC aggregation](Third-Party/OrangeHRM/) | Triggers SailPoint account aggregation after OrangeHRM employee lifecycle events |

## Entro

| Utility | Description |
| --- | --- |
| [entro-connect](Entro/entro-connect/) | Agent skill and tooling to walk SailPoint Entro Integration Connect runs (ingest, catalog, prep automation) |

## Skills

Install skills from this repo into your agent environment:

```bash
npx skills add fernando-delosrios-sp/sailpoint-utils --skill entro-connect
```

Use `--skill` when installing so repo-root [`.agents/skills/`](.agents/skills/) maintainer skills are not included by default.

| Skill | Install path | Authoring |
| --- | --- | --- |
| [sail](skills/sail/) | `skills/sail/` | Definition-only; identical working copy at [`.agents/skills/sail/`](.agents/skills/sail/). Install: `npx skills add fernando-delosrios-sp/sailpoint-utils --skill sail` |
| [nerm-cli](.agents/skills/nerm-cli/) | — | Maintainer skill only (not under `skills/`). Drives the external [`nerm`](https://www.npmjs.com/package/nerm-cli) CLI for NERM profiles, domain commands, and raw REST. Install the CLI with `npm install -g nerm-cli`. |
| [entro-connect](skills/entro-connect/) | `skills/entro-connect/` | Dedicated project under [`Entro/entro-connect/`](Entro/entro-connect/); local working copy at `.agents/skills/entro-connect/`; [`Entro/entro-connect/skills`](Entro/entro-connect/skills) symlinks to repo-root `skills/` |

**Adding a skill**

- **Definition-only** — add `skills/<name>/SKILL.md` (and supporting files) at the repo root.
- **Dedicated space** — keep the project under `Entro/` (or similar), maintain a local `.agents/skills/<name>/` working copy, and symlink the project's `skills/` to `../../skills` so generators and tests keep path-stable dual trees.

## Getting started

1. **Pick a utility** from the tables above and open its folder README.
2. **Import or deploy artifacts** as described in that README (rules, transforms, connector bundles, Postman collections, etc.).
3. **Adapt configuration** to your tenant—source IDs, attribute names, and OAuth clients are environment-specific.

Utilities that include a Node.js toolchain (for example, [JDBC SaaS Driver Downloader](ISC/JDBC%20SaaS%20Driver%20Downloader/) or [saas-custom-operations](SaaS%20Connectivity/saas-custom-operations/)) document their own prerequisites and npm scripts locally.

## PowerShell 7+

PowerShell scripts in this repository are for **PowerShell 7+** (`pwsh`). On Windows, use the PowerShell 7 app, which sits beside the built-in Windows PowerShell 5.1 (`powershell.exe`). Install PowerShell 7 or later, then run the scripts from a `pwsh` session.

That covers [Email Templates](ISC/Email%20Templates/), [Source Connection Setup](ISC/Source%20Connection%20Setup/), [Demo Data](ISC/Demo%20Data/), [PowerShell Rule Template](ISC/PowerShell%20Rule%20Template/) and the Active Directory rules built from it, and the Entro Azure onboarding script under [entro-connect](Entro/entro-connect/). Each of those folders repeats these install steps.

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

## Contributing

When adding a new utility or integration pattern:

1. Place it under the appropriate top-level folder (`ISC/`, `SaaS Connectivity/`, `Entro/`, `Third-Party/`, or `IIQ/`).
2. Include a `README.md` with a **Purpose** section, setup steps, artifacts, and usage examples.
3. Add an entry under the newest dated section in [CHANGELOG.md](CHANGELOG.md) (create one for today's date if needed).

When adding an agent skill, follow the **Skills** section above and add `skills/<name>/SKILL.md` at the repo root.

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md), grouped by date in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

