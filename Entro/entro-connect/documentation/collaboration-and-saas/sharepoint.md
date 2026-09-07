SharePoint / OneDrive | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/sharepoint.md).

The **SharePoint Integration** enables Entro Security to continuously monitor for exposed secrets within SharePoint / OneDrive files. The integration leverages the same **Microsoft ecosystem App Registration** used for Azure and entire M365 suite, ensuring unified authentication and read-only access through Microsoft Graph APIs.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem
GitBook Assistant
## Purpose[#purpose](#purpose)

Integrating SharePoint with Entro provide continuous scanning of files for exposed secrets within SharePoint sites, OneDrive files
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
┌───────────────────────────────┐
│       Entro Security Cloud    │
│       Microsoft Graph API     │
└──────────────┬────────────────┘
               │  HTTPS (TLS 1.2+)
               ▼
┌───────────────────────────────┐
│       Microsoft SharePoint    │
│  (Tenant, Sites, Files, APIs) │
└───────────────────────────────┘
```

## Security Model[#security-model](#security-model)

- 

Integration operates in **read-only** mode
GitBook Assistant
- 

Authentication via **App Registration Client Secret**
GitBook Assistant
- 

All communications over **HTTPS/TLS 1.2+**
GitBook Assistant
- 

Secrets encrypted with **AES-256**
GitBook Assistant
- 

Fully compliant with **SOC 2 Type II**, **ISO 27001**, and **GDPR**
GitBook Assistant
[PreviousMicrosoft Teams Permissions Reference](/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-permissions-reference)[NextSharePoint Onboarding](/integrations/collaboration-and-saas/sharepoint/sharepoint-onboarding)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Purpose](#purpose)
- [Architecture](#architecture)
- [Security Model](#security-model)
