# `Connect-SailPointSlack`

Configures SailPoint ISC Slack SaaS connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointSlack [-Wizard] [-Connector] [-Entro]
    [-Action <String>] [-WorkspaceName <String>] [-BotUserOAuthToken <String>]
    [-UserOAuthToken <String>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointSlack` configures Slack Enterprise Grid integrations:
1. **SailPoint Fabric (Slack SaaS Connector)**: Aggregates and provisions Slack Enterprise Grid users, channels, and IDP groups.
2. **Entro Slack**: Analyzes Slack app installations, bot tokens, and machine user privileges.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-WorkspaceName`
Slack workspace or Enterprise Grid domain.

### `-BotUserOAuthToken` / `-UserOAuthToken`
Slack app OAuth tokens (`xoxb-*` and `xoxp-*`).

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointSlack -Wizard
```
