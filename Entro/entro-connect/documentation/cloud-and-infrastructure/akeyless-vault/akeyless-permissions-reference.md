Akeyless Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-permissions-reference.md).

This section outlines the permissions, scopes, and access roles required for Entro Security to operate with Akeyless Vault.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Akeyless → Permissions Reference**
GitBook Assistant
## Required Roles and Permissions[#required-roles-and-permissions](#required-roles-and-permissions)

Entro operates in read-only mode and requires access only to secret metadata and policy associations.
GitBook AssistantScopeResourcePermission TypeDescription

Items
GitBook Assistant

Secrets, Paths
GitBook Assistant

List, Read
GitBook Assistant

Allows retrieval of metadata and structure information
GitBook Assistant

Access Roles
GitBook Assistant

Roles
GitBook Assistant

List, Read
GitBook Assistant

Enables detection of privilege boundaries and scope mismatches
GitBook Assistant

Auth Methods
GitBook Assistant

Methods
GitBook Assistant

List, Read
GitBook Assistant

Correlates authentication sources and usage contexts
GitBook Assistant
#### Entro Access Summary[#entro-access-summary](#entro-access-summary)

- 

**Access Level:** Read-only (no write, modify, or delete actions)
GitBook Assistant
- 

**Token Management:** Handled within the Entro Worker (Connector)
GitBook Assistant
- 

**TLS Encryption:** TLS 1.2+ enforced for all API calls
GitBook Assistant
- 

**Key Storage:** AES-256 encrypted at rest within the Worker
GitBook Assistant

#### Compliance & Security Notes[#compliance-and-security-notes](#compliance-and-security-notes)

- 

Entro does not access or decrypt secret content
GitBook Assistant
- 

No configuration or policy modification occurs on Akeyless
GitBook Assistant
- 

API keys or UIDs are never stored in plaintext
GitBook Assistant
- 

Integration adheres to **SOC 2 Type II**, **ISO 27001**, and **GDPR**
GitBook Assistant
[PreviousAkeyless Troubleshooting And Validation](/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-troubleshooting-and-validation)[NextAmazon Web Services](/integrations/cloud-and-infrastructure/amazon-web-services)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Required Roles and Permissions](#required-roles-and-permissions)
