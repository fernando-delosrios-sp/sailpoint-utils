# `Connect-SailPointSalesforce`

Configures SailPoint ISC Salesforce SaaS connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointSalesforce [-Wizard] [-Connector] [-Entro]
    [-Access <String>] [-Action <String>] [-InstanceUrl <String>]
    [-LoginUrl <String>] [-ConsumerKey <String>] [-ConsumerSecret <String>]
    [-Username <String>] [-Feature <String[]>] [-Project <String>]
    [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointSalesforce` configures and audits Salesforce integrations:
1. **SailPoint Fabric (Salesforce SaaS Connector)**: Configures OAuth Connected App credentials, permissions, and Agentforce AI agent discovery.
2. **Entro Onboarding**: Audits and sets up Entro Non-Human Identity posture analysis for Salesforce.

## Parameters

### `-Wizard`
Launches the interactive keyboard-driven questionnaire.

### `-Connector`
Selects the SailPoint Fabric Salesforce SaaS connector.

### `-Entro`
Selects Entro Salesforce onboarding.

### `-Access`
Permission level: `ReadOnly` (aggregation only) or `ReadWrite` (provisioning enabled).

### `-Action`
`BuildRequirements` (checklist), `Check` (read-only audit of existing Connected App), `BuildScript` (offline executable script), or `Run` (direct apply with confirmation).

### `-InstanceUrl`
Salesforce instance URL (e.g., `https://yourcompany.my.salesforce.com`).

### `-ConsumerKey` / `-ConsumerSecret`
OAuth Connected App credentials.

### `-Feature`
Optional feature packs, including `AgentDiscovery` for Salesforce Agentforce bot governance (`BotDefinition` and `BotVersion`).

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointSalesforce -Wizard
```

### Example 2: Read-Only Audit of Existing Connected App
```powershell
Connect-SailPointSalesforce -Connector -Access ReadOnly -InstanceUrl "https://mycorp.my.salesforce.com" -Action Check
```
