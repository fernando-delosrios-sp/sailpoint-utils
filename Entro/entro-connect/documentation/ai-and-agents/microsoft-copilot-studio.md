Microsoft Copilot Studio | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/microsoft-copilot-studio.md).

Entro Security integrates with Microsoft Copilot Studio and the underlying Microsoft Power Platform to provide continuous discovery, classification, and security monitoring of AI agents and associated resources. The integration identifies identity risks, exposed credentials, over-privileged service principals, and risky connection references inside your environments.
GitBook Assistant
## Supported Environments[#supported-environments](#supported-environments)

- 

Microsoft Power Platform tenants with Dataverse-backed environments hosting Copilot Studio AI agents.
GitBook Assistant
- 

Co-existence with standard Microsoft Entra ID setups.
GitBook Assistant

## Architecture[#architecture](#architecture)

All communications between Entro Security and your Microsoft environment utilize secure APIs using encrypted credentials.
GitBook AssistantGitBook AssistantAskCopy
```
+-----------------------------------+
|           Entro Console           |
|          (Control Plane)          |
+-----------------+-----------------+
                  |
                  | Control API & AES-256 Encrypted Token
                  v
+-----------------------------------+
|       Entro SaaS Platform         |
|        Processing Engine          |
+-----------------+-----------------+
                  |
                  | HTTPS / API (TLS 1.3)
                  v
+-----------------------------------+
|    Microsoft Power Platform       |
|  (Copilot Studio AI Resources)    |
+-----------------------------------+
```

## What Entro Scans[#what-entro-scans](#what-entro-scans)

- 

**Non-Human Identities (NHIs):** Service principals and application users associated with AI agent workloads.
GitBook Assistant
- 

**Credentials Inventory:** Hidden or embedded secrets, tokens, and keys within connection references.
GitBook Assistant
- 

**Environment Posture:** Role assignments, tenant-wide configurations, and application packages.
GitBook Assistant
- 

**Owner Correlation:** Cross-referencing directory users and groups to map operational ownership of AI assets.
GitBook Assistant

Last updated 3 months ago

- [Supported Environments](#supported-environments)
- [Architecture](#architecture)
- [What Entro Scans](#what-entro-scans)
