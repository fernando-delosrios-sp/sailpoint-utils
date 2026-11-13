# `Connect-SailPointCrowdStrike`

Configures SailPoint ISC CrowdStrike Falcon SaaS connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointCrowdStrike [-Wizard] [-Connector] [-Entro]
    [-Access <String>] [-Action <String>] [-BaseUrl <String>]
    [-ClientId <String>] [-ClientSecret <String>] [-Feature <String[]>]
    [-Project <String>] [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointCrowdStrike` configures OAuth2 API client credentials for:
1. **SailPoint Fabric (CrowdStrike Falcon SaaS Connector)**: Governs Falcon users, role assignments, and policies. Optional feature packs support Falcon Discover, Identity Threat Detection and Response (ITDR), CSPM, and Real Time Response (RTR).
2. **Entro CrowdStrike**: Ingests CrowdStrike Falcon security posture and identity metrics into Entro.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-Connector`
Selects the CrowdStrike Falcon connector.

### `-Entro`
Selects Entro Falcon integration.

### `-BaseUrl`
Falcon cloud API base URL (e.g., `https://api.crowdstrike.com` or `https://api.us-2.crowdstrike.com`).

### `-ClientId` / `-ClientSecret`
Falcon OAuth2 API client credentials.

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Setup
```powershell
Connect-SailPointCrowdStrike -Wizard
```

### Example 2: Requirements Checklist for Security Operations
```powershell
Connect-SailPointCrowdStrike -Connector -Access ReadOnly -BaseUrl "https://api.crowdstrike.com" -Action BuildRequirements
```
