# `Connect-SailPointGoogleCloud`

Configures SailPoint ISC Google Workspace connectors, GCP CIEM, and Entro.

## Synopsis

```powershell
Connect-SailPointGoogleCloud [-Wizard] [-SaaSConnector] [-CiemConnector]
    [-GcpEntro] [-WorkspaceEntro] [-Feature <String[]>] [-Access <String>]
    [-Action <String>] [-OrganizationId <String>] [-ProjectId <String>]
    [-ImpersonateUser <String>] [-Method <String>] [-Project <String>]
    [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointGoogleCloud` sets up Google Cloud and Google Workspace integrations:
1. **Google Workspace / GCP connector**: Configures service account keys or Workload Identity Federation, domain-wide delegation, and optional GCP / CIEM feature packs (`-Feature Gcp,Ciem`).
2. **Entro GCP Organization integration**: Automated service account provisioning, organization IAM grant, and audit log verification (`-Access ReadOnly` or `ReadWrite`).
3. **Combined Runs**: Combines the Google connector with either Entro GCP or Entro Workspace.

## Parameters

### `-Wizard`
Interactive guided questionnaire. You can type every value. A signed-in `gcloud` session can offer existing projects and organizations. It does not create them. The default action is a checklist.

### `-Action`
`BuildRequirements`, `Check` (read IAM permissions on an existing service account), `BuildScript`, or `Run`. OAuth scopes and domain-wide delegation are compared by hand. Only `Run` changes the tenant, after you confirm.

### `-SaaSConnector`
Targets the Google Workspace / GCP connector.

### `-CiemConnector`
Backward-compatible alias that targets `-SaaSConnector` with `-Feature Gcp,Ciem`.

### `-GcpEntro`
Targets Entro Google GCP organization integration.

### `-OrganizationId`
Google Cloud numeric organization ID.

### `-ProjectId`
Google Cloud project ID.

### `-ImpersonateUser`
Admin email used for domain-wide delegation impersonation in Google Workspace.

### `-Method`
Authentication method: `PrivateKey` (Service Account JSON) or `WorkloadIdentity`.

## Examples

### Example 1: Interactive wizard
```powershell
Connect-SailPointGoogleCloud -Wizard
```

### Example 2: Combined Workspace + Entro requirements build
```powershell
Connect-SailPointGoogleCloud -SaaSConnector -GcpEntro `
    -OrganizationId "416188549418" `
    -ProjectId "sec-trial" `
    -ImpersonateUser "admin@domain.com" `
    -Action BuildRequirements
```
