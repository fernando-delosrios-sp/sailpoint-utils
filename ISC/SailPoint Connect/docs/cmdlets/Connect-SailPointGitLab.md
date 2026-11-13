# `Connect-SailPointGitLab`

Configures SailPoint ISC GitLab SaaS connector (SailPoint Fabric) and Entro onboarding.

## Synopsis

```powershell
Connect-SailPointGitLab [-Wizard] [-Connector] [-Entro]
    [-Action <String>] [-BaseUrl <String>] [-SelfManaged]
    [-AuthType <String>] [-AccessToken <String>] [-TargetGroups <String>]
    [-Project <String>] [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointGitLab` configures credentials and access for GitLab.com or GitLab Self-Managed:
1. **SailPoint Fabric (GitLab SaaS Connector)**: Aggregates users, memberships, and groups.
2. **Entro GitLab**: Audits access tokens, SSH keys, deploy keys, and non-human identities.

## Parameters

### `-Wizard`
Launches the interactive questionnaire.

### `-BaseUrl`
GitLab base URL (default: `https://gitlab.com`).

### `-SelfManaged`
Switch for GitLab Self-Managed instances.

### `-AccessToken`
Personal Access Token or Group Access Token with `api` and `read_user` scopes.

### `-Action`
`BuildRequirements`, `Check`, `BuildScript`, or `Run`.

## Examples

### Example 1: Interactive Wizard
```powershell
Connect-SailPointGitLab -Wizard
```
