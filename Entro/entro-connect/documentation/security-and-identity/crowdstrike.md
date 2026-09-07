CrowdStrike | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike.md).

Entro integrates with CrowdStrike to enrich devices data (endpoints), discover Endpoint AI Agents, and identify Non‑Human Identities (NHIs) linked to Active Directory or unmanaged endpoints.
GitBook Assistant
## Integration Scope[#integration-scope](#integration-scope)

- 

Device enrichment and NHI mapping
GitBook Assistant
- 

Inventorying of used MCPs, AI Agents
GitBook Assistant
- 

Active Directory Users (NHIs) management
GitBook Assistant
- 

Real‑time response and incident data ingestion
GitBook Assistant

## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account → CrowdStrike
GitBook Assistant

**Authentication**
GitBook Assistant

Integration uses an **API Client ID and Secret** generated from the [CrowdStrike management console](https://falcon.us-2.crowdstrike.com/api-clients-and-keys/clients).
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS/TLS 1.2+)
CrowdStrike Falcon Platform (API)
```

**Security & Compliance**
GitBook Assistant

- 

All API tokens are AES‑256 encrypted.
GitBook Assistant
- 

TLS 1.2+ enforced for all communications.
GitBook Assistant
- 

Entro operates in a read‑only, non‑intrusive mode.
GitBook Assistant
[PreviousActive Directory Permissions Reference](/integrations/security-and-identity/active-directory/active-directory-permissions-reference)[NextCrowdStrike Onboarding](/integrations/security-and-identity/crowdstrike/crowdstrike-onboarding)

Last updated 2 months ago

- [Integration Scope](#integration-scope)
- [Navigation Path](#navigation-path)
- [Architecture](#architecture)
