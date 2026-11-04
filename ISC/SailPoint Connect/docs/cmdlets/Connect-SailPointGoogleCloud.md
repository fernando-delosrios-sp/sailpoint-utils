# `Connect-SailPointGoogleCloud`

Configures SailPoint ISC Google Workspace connectors, GCP CIEM, and Entro.

## Synopsis

```powershell
Connect-SailPointGoogleCloud [-Wizard] [-SaaSConnector] [-CiemConnector]
    [-GcpEntro] [-WorkspaceEntro] [-Access <String>] [-Action <String>]
    [-OrganizationId <String>] [-ProjectId <String>] [-ImpersonateUser <String>]
    [-Method <String>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointGoogleCloud` (alias `Connect-SailPointGCP`) sets up Google Cloud and Google Workspace integrations:
1. **Google Workspace SaaS connector**: Configures service account keys or OAuth2 consent with domain-wide delegation.
2. **Google Cloud CIEM connector**: Assigns IAM audit logging and viewer permissions.
3. **Entro GCP Organization integration**: Automated service account provisioning, organization IAM grant, and audit log verification.
4. **Combined Runs**: Combines Workspace SaaS connector with either Entro GCP or Entro Workspace.

## Parameters

### `-Wizard`
Interactive guided questionnaire with `gcloud` session discovery.

### `-SaaSConnector`
Targets the Google Workspace SaaS connector.

### `-GcpEntro`
Targets Entro Google GCP organization integration.

### `-OrganizationId`
Google Cloud numeric organization ID.

### `-ProjectId`
Google Cloud project ID.

### `-ImpersonateUser`
Admin email used for domain-wide delegation impersonation in Google Workspace.

### `-Method`
Authentication method: `PrivateKey` (Service Account JSON) or `OAuth`.

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
