Google Workspace GDrive Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-troubleshooting-and-validation.md).

Follow these steps to verify and troubleshoot the GDrive integration after onboarding.
GitBook Assistant1
#### Validation Steps[#validation-steps](#validation-steps)

In the Entro Dashboard, navigate to **Accounts & Integrations → Google Workspace (GDrive)** and confirm the connection status is **Verified**.
GitBook Assistant2
#### Validate APIs[#validate-apis](#validate-apis)

Confirm the following APIs are activated:
GitBook Assistant

- 

**Google Drive API**
GitBook Assistant
- 

**Admin SDK API**
GitBook Assistant
3
#### Service Account Access[#service-account-access](#service-account-access)

Ensure the Service Account has one of the following:
GitBook Assistant

- 

Viewer or Contributor access (Option 1)
GitBook Assistant
- 

Domain-wide delegation (Option 2)
GitBook Assistant
4
#### Verify Scan Results[#verify-scan-results](#verify-scan-results)

Check that recent file scan results appear in Entro Findings.
GitBook Assistant
## Common Issues & Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

Drive API error
GitBook Assistant

API not enabled
GitBook Assistant

Enable Drive API in GCP project
GitBook Assistant

Missing or limited results
GitBook Assistant

Insufficient access scope
GitBook Assistant

Use Domain-Wide Delegation (Option 2)
GitBook Assistant

Invalid domain error
GitBook Assistant

Incorrect Workspace domain
GitBook Assistant

Verify domain in onboarding form
GitBook Assistant

Expired key
GitBook Assistant

Rotated or revoked Service Account key
GitBook Assistant

Regenerate key and update Entro
GitBook Assistant

No findings shown
GitBook Assistant

OCR not enabled
GitBook Assistant

Enable OCR in Entro settings
GitBook Assistant
## Q&A and Limitations[#q-and-a-and-limitations](#q-and-a-and-limitations)
Does Entro scan image files?[#does-entro-scan-image-files](#does-entro-scan-image-files)

Yes, except embedded images in documents. Enable OCR for full support.
GitBook AssistantSupported file types[#supported-file-types](#supported-file-types)

Documents, images, and non-binary files up to 2.5 MB.
GitBook AssistantDoes Entro scan history?[#does-entro-scan-history](#does-entro-scan-history)

Available in V2 when using Contributor permissions.
GitBook AssistantPublic or external shares[#public-or-external-shares](#public-or-external-shares)

Detected and flagged as “Externally Shared” in risk reports.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Read-only data access
GitBook Assistant
- 

TLS 1.2+ communication
GitBook Assistant
- 

AES-256 encryption at rest
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR compliant
GitBook Assistant
[PreviousGoogle Workspace GDrive Onboarding](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-onboarding)[NextGoogle Workspace GDrive Permissions Reference](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-permissions-reference)

Last updated 4 months ago

- [Common Issues & Resolutions](#common-issues-and-resolutions)
- [Q&A and Limitations](#q-and-a-and-limitations)
- [Security & Compliance](#security-and-compliance)
