Okta | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/okta.md).

The **Okta Integration** enables Entro Security to continuously monitor and discover non-human identities, application secrets, and employee directory data across your Okta organization. Once connected, Entro maps Okta applications, client credentials, role assignments, and audit logs into a unified NHI inventory.
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
+-----------------------+           +-----------------------+
|    Entro Security     |           |      Okta Cloud       |
|    (Control Plane)    | <-------> |   (API + Directory)   |
+-----------------------+   HTTPS   +-----------------------+
                          (TLS 1.2+)
```

## Integration Highlights[#integration-highlights](#integration-highlights)

- 

Discover Okta applications and their client credentials
GitBook Assistant
- 

Map API grant permissions per application for NHI visibility
GitBook Assistant
- 

Enumerate directory users and employee profiles for ownership attribution
GitBook Assistant
- 

Collect Okta audit logs for continuous monitoring and anomaly detection
GitBook Assistant
- 

Read role assignments across users and applications
GitBook Assistant

## Prerequisites[#prerequisites](#prerequisites)

- 

Administrator access to your Okta organization
GitBook Assistant
- 

Ability to create an API Service App in the Okta Admin Console
GitBook Assistant
- 

Access to grant API scopes and assign admin roles in Okta
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Entro authenticates via an **API Service App** using a **Client ID and Public Key** pair - no passwords or long-lived tokens are stored
GitBook Assistant
- 

All operations are **read-only** - Entro never modifies or deletes data in Okta
GitBook Assistant
- 

API credentials are **AES-256 encrypted** at rest within Entro
GitBook Assistant
- 

All communication over **HTTPS / TLS 1.2+**
GitBook Assistant
- 

Entro is **SOC 2 Type II** certified, **ISO 27001** and **GDPR** compliant
GitBook Assistant
[PreviousAI Security RTR Integration](/integrations/security-and-identity/crowdstrike/ai-security-rtr-integration)[NextOkta Onboarding](/integrations/security-and-identity/okta/okta-onboarding)

Last updated 2 months ago

- [Architecture](#architecture)
- [Integration Highlights](#integration-highlights)
- [Prerequisites](#prerequisites)
- [Security & Compliance](#security-and-compliance)
