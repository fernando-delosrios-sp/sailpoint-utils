Google Workspace - Google Drive | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/google-workspace-google-drive.md).

Entro Security integrates with Google Workspace (GDrive) to provide continuous, read-only visibility into files, shared drives, and user permissions. Using a GCP Service Account, Entro securely scans files to identify exposed secrets - without reading or modifying file content.
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS / TLS 1.2+)
GCP Service Account
   ↕ (Read-Only)
Google Drive API + Admin SDK API
```

## Integration Capabilities[#integration-capabilities](#integration-capabilities)

- 

Continuous scanning for exposed secrets in GDrive files and folders
GitBook Assistant
- 

Support for shared drives and organizational files
GitBook Assistant
- 

Read-only metadata retrieval (no secret values read or modified)
GitBook Assistant
- 

Detection of publicly or externally shared documents
GitBook Assistant
- 

Integration with existing GCP Service Accounts or new dedicated accounts
GitBook Assistant

Security & Compliance
GitBook Assistant

- 

Read-only access only
GitBook Assistant
- 

AES-256 encryption at rest
GitBook Assistant
- 

TLS 1.2+ for all communications
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR compliant
GitBook Assistant
- 

No data persistence of file content
GitBook Assistant
[PreviousSupported Data Sources](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/supported-data-sources)[NextGoogle Workspace GDrive Onboarding](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-onboarding)

Last updated 4 months ago

- [Architecture](#architecture)
- [Integration Capabilities](#integration-capabilities)
