Google Workspace GDrive Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-permissions-reference.md).

The following OAuth scopes are required for Entro Security to perform metadata-based secret scanning within Google Workspace (GDrive).
GitBook Assistant
## Required Scopes and Purpose[#required-scopes-and-purpose](#required-scopes-and-purpose)
ScopePurpose

https://www.googleapis.com/auth/drive.readonly
GitBook Assistant

Read-only access to all Google Drive files
GitBook Assistant

https://www.googleapis.com/auth/admin.directory.user.readonly
GitBook Assistant

Retrieve user metadata for file ownership correlation
GitBook Assistant

https://www.googleapis.com/auth/admin.directory.group.readonly
GitBook Assistant

Discover group associations
GitBook Assistant

https://www.googleapis.com/auth/admin.directory.group.member.readonly
GitBook Assistant

Retrieve group membership lists
GitBook Assistant

https://www.googleapis.com/auth/admin.directory.customer.readonly
GitBook Assistant

Read organizational metadata
GitBook Assistant

Access Model
GitBook Assistant

- 

All data is accessed in read-only mode.
GitBook Assistant
- 

File content is never modified or stored.
GitBook Assistant
- 

Metadata only (name, path, permissions, timestamps) is retrieved.
GitBook Assistant
- 

Tokens are AES-256 encrypted in Entro’s Worker environment.
GitBook Assistant

Security & Compliance
GitBook Assistant

- 

TLS 1.2+ enforced
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR certified
GitBook Assistant
- 

Read-only OAuth access, revocable at any time
GitBook Assistant
[PreviousGoogle Workspace GDrive Troubleshooting And Validation](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-troubleshooting-and-validation)[NextMicrosoft Teams](/integrations/collaboration-and-saas/microsoft-teams)

Last updated 4 months ago
