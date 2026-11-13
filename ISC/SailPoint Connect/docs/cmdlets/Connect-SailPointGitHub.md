# `Connect-SailPointGitHub`

Configures SailPoint ISC GitHub connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointGitHub [-Wizard] [-Connector] [-Entro]
    [-Access <String>] [-Action <String>] [-Organization <String>]
    [-ApiUrl <String>] [-AuthMethod <String>] [-Token <String>]
    [-AppId <String>] [-InstallationId <String>] [-PrivateKey <String>]
    [-Feature <String[]>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointGitHub` configures authentication and permissions for GitHub organizations:
1. **SailPoint Fabric (GitHub SaaS Connector)**: Manages organization members, teams, repositories, Copilot seat allocations, and installed bot accounts.
2. **Entro GitHub**: Discovers and analyzes machine identities, tokens, and apps.

Supported authentication methods include **GitHub App** (recommended, using private key PEM) and **Personal Access Token (PAT)**.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-Connector`
Selects the SailPoint Fabric GitHub SaaS connector.

### `-Entro`
Selects Entro GitHub onboarding.

### `-AuthMethod`
Authentication type: `GitHubApp` or `PAT`.

### `-Organization`
GitHub organization name.

### `-Feature`
Optional feature packs, including `AgentDiscovery` to govern assigned GitHub Copilot seats and installed GitHub Apps.

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointGitHub -Wizard
```

### Example 2: Checklist for GitHub Organization Admin
```powershell
Connect-SailPointGitHub -Connector -Access ReadOnly -Organization "my-enterprise-org" -Feature AgentDiscovery -Action BuildRequirements
```
