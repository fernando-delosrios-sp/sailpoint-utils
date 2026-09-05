Wiz Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/wiz/wiz-permissions-reference.md).

This section outlines the access scopes and justifications for the Wiz–Entro integration.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Wiz
GitBook Assistant
## Required Permissions[#required-permissions](#required-permissions)

The Wiz Service Account must have the following permissions for Entro to retrieve and generate reports securely:
GitBook AssistantPermissionTypePurpose

**read:data_findings**
GitBook Assistant

Read
GitBook Assistant

Retrieve sensitive data classification and context
GitBook Assistant

**create:reports**
GitBook Assistant

Write
GitBook Assistant

Generate new DSPM report jobs for NHI exposure correlation
GitBook Assistant

**read:reports**
GitBook Assistant

Read
GitBook Assistant

Access completed report data for ingestion into Entro
GitBook Assistant
## Permissions Justification[#permissions-justification](#permissions-justification)

- 

Entro generates **Data Findings Reports** to identify all cloud assets and their related data risks.
GitBook Assistant
- 

The **create:reports** permission is required to initiate this report within Wiz.
GitBook Assistant
- 

The **read:data_findings** and **read:reports** scopes allow Entro to access only **DATA_SCAN** report types — no configuration, user, or secret data is retrieved.
GitBook Assistant

## Access Summary[#access-summary](#access-summary)

- 

Authentication uses **Service Account Client ID** and **Client Secret**
GitBook Assistant
- 

All requests performed via the **Wiz REST API**
GitBook Assistant
- 

All operations are read-only and executed over **TLS 1.2+**
GitBook Assistant
- 

Tokens are stored encrypted in Entro’s Worker Group environment (**AES-256**)
GitBook Assistant

[PreviousWiz Troubleshooting And Validation](/integrations/security-and-identity/wiz/wiz-troubleshooting-and-validation)[NextSailPoint Identity Security Cloud (formerly IdentityNow)](/integrations/security-and-identity/sailpoint-isc)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Required Permissions](#required-permissions)
- [Permissions Justification](#permissions-justification)
- [Access Summary](#access-summary)
