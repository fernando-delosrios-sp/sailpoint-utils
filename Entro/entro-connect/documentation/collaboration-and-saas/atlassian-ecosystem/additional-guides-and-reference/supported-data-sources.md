Supported Data Sources | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/supported-data-sources.md).
## Jira Integration[#jira-integration](#jira-integration)

Entro Security scans Jira metadata and content to identify secrets that may have been shared or exposed.
GitBook AssistantCategoryDescription

**Issues**
GitBook Assistant

Titles, descriptions, and comments in all accessible projects
GitBook Assistant

**Attachments**
GitBook Assistant

Text-based attachments such as `.txt`, `.log`, `.json`, `.yaml`, `.ini`, `.config`, `.env`, `.csv` (≤ 10 MB)
GitBook Assistant

**Custom Fields**
GitBook Assistant

Text-based custom fields defined by administrators
GitBook Assistant

**Projects**
GitBook Assistant

All active and non-archived projects accessible to the integration user
GitBook Assistant

*Detection includes API keys, database credentials, tokens, SSH keys, and cloud provider secrets.*
GitBook Assistant
### Out of scope[#out-of-scope](#out-of-scope)

To protect performance and data privacy, the following are excluded from scanning:
GitBook Assistant

- 

Issue history and changelog events
GitBook Assistant
- 

Archived or deleted projects
GitBook Assistant
- 

Encrypted or binary attachments (e.g., `.zip`, `.pdf`, `.jpg`)
GitBook Assistant
- 

Audit logs or system configuration data
GitBook Assistant
- 

Third‑party marketplace app data
GitBook Assistant

*These exclusions ensure minimal system overhead and compliance with Atlassian’s API policies.*
GitBook Assistant
## Confluence Integration[#confluence-integration](#confluence-integration)

Entro Security scans for secrets across the following Confluence components:
GitBook Assistant

- 

**Pages**
GitBook Assistant

- 

Full page body (plain text and wiki storage formats)
GitBook Assistant
- 

Titles and metadata
GitBook Assistant

- 

**Comments**
GitBook Assistant

- 

Page-level and inline comments
GitBook Assistant

- 

**Attachments**
GitBook Assistant

- 

Supported text-based file formats:
GitBook Assistant

- 

`.txt`, `.log`, `.json`, `.yaml`, `.yml`, `.xml`, `.ini`, `.csv`, `.config`, `.properties`
GitBook Assistant

- 

Maximum file size: **10 MB**
GitBook Assistant

- 

**Metadata**
GitBook Assistant

- 

Page ID, space key, creator, and modification timestamps
GitBook Assistant

*Detection Engine: Entro uses contextual scanning and entropy-based algorithms to detect API keys, credentials, tokens, and misconfigured secrets.*
GitBook Assistant
### Out of scope[#out-of-scope-1](#out-of-scope-1)

For performance and privacy reasons, the following are **excluded** from scanning:
GitBook Assistant

- 

Deleted or archived spaces and pages
GitBook Assistant
- 

Historical page versions (only latest version is scanned)
GitBook Assistant
- 

Encrypted or binary attachments (e.g., `.zip`, `.jpg`, `.pdf`)
GitBook Assistant
- 

Audit logs, templates, or macros
GitBook Assistant
- 

Marketplace app data and third-party plugin storage
GitBook Assistant

*These exclusions are intentional to maintain data integrity and minimize API load.*
GitBook Assistant[PreviousAPI Endpoints in Use](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/api-endpoints-in-use)[NextGoogle Workspace - Google Drive](/integrations/collaboration-and-saas/google-workspace-google-drive)

Last updated 4 months ago

- [Jira Integration](#jira-integration)
- [Out of scope](#out-of-scope)
- [Confluence Integration](#confluence-integration)
- [Out of scope](#out-of-scope-1)
