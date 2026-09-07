SailPoint Identity Security Cloud (formerly IdentityNow) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/sailpoint-isc.md).
### Purpose[#purpose](#purpose)

The SailPoint Identity Security Cloud (ISC) integration connects your identity security tenant with Entro to continuously discover and analyze user identities, roles. This integration ingests human identity objects, assigned roles and entitlements to allow human user management and segmentation based on user's organization data.
GitBook Assistant
### Supported Environments[#supported-environments](#supported-environments)

- 

**SaaS Deployments:** Any active SailPoint Identity Security Cloud tenant reachable via public API endpoints over secure outbound traffic from the designated Entro Worker Group.
GitBook Assistant

### ASCII Architecture[#ascii-architecture](#ascii-architecture)
GitBook AssistantAskCopy
```
+-------------------------+
|      Entro Console      |
|     (Control Plane)     |
+-------------------------+
             |
             | Control API + AES-256 token
             V
+-------------------------+
|      Worker Group       |
|     (Connector VM)      |
+-------------------------+
             |
             | HTTPS (TLS 1.3) / REST API 
             V
+-------------------------+
|   SailPoint ISC Tenant  |
|  (Identity Cloud SaaS)  |
+-------------------------+
```

### What Entro Scans[#what-entro-scans](#what-entro-scans)

- 

Human identity accounts and linked security attribute metadata
GitBook Assistant
- 

Defined organizational roles and explicit user-to-role assignments
GitBook Assistant
- 

Linked source target accounts utilized for cross-source identity correlation
GitBook Assistant
- 

Base identity profile structure definitions
GitBook Assistant

### Data Access Mode and Security[#data-access-mode-and-security](#data-access-mode-and-security)

- 

**Read-Only Access:** Entro acts strictly as a read-only integration consumer. The assigned service client relies on minimal directory lookup privileges.
GitBook Assistant
- 

**Encryption Controls:** Stored integration authentication credentials and API keys are protected at rest via AES-256 encryption.
GitBook Assistant
- 

**In-Transit Protection:** All programmatic data movement between the Worker Group and SailPoint uses HTTPS secured with TLS 1.3 encryption.
GitBook Assistant
- 

**Compliance Standards:** Operation aligns explicitly with SOC 2 Type II, ISO 27001, and GDPR data management practices.
GitBook Assistant
[PreviousWiz Permissions Reference](/integrations/security-and-identity/wiz/wiz-permissions-reference)[NextSailPoint Identity Security Cloud (ISC) Onboarding Guide](/integrations/security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-onboarding-guide)

Last updated 2 months ago

- [Purpose](#purpose)
- [Supported Environments](#supported-environments)
- [ASCII Architecture](#ascii-architecture)
- [What Entro Scans](#what-entro-scans)
- [Data Access Mode and Security](#data-access-mode-and-security)
