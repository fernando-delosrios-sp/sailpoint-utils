Atlassian Ecosystem | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem.md).

The **Atlassian Ecosystem** integration enables Entro Security to detect and analyze exposed secrets across your organization’s collaboration and development tools - including **Jira and** **Confluence**, and **Bitbucket Cloud**. By connecting Entro to your Atlassian environment, you gain continuous visibility into sensitive information shared in tickets, repositories, and documentation.
GitBook Assistant
## Overview[#overview](#overview)

Entro Security integrates with Atlassian products via secure API connections or an on-premise Worker, depending on your deployment type. This enables organizations to monitor and remediate exposed secrets in both **Atlassian Cloud** and **Server (On-premise)** environments.
GitBook Assistant
## Integration Capabilities[#integration-capabilities](#integration-capabilities)

Entro Security scans and analyzes metadata across Atlassian environments to identify:
GitBook Assistant

- 

**Exposed secrets** in Jira issues, comments, and attachments
GitBook Assistant
- 

**Sensitive tokens or credentials** in Confluence pages or files
GitBook Assistant
- 

**Access anomalies** or role misconfigurations in integrated environments
GitBook Assistant

**Detection scope:** Entro leverages proprietary pattern matching, entropy analysis, and context-based correlation to classify secrets as **Generic** or **Exposed**, helping teams prioritize remediation.
GitBook Assistant
## Supported Products & Data[#supported-products-and-data](#supported-products-and-data)
ProductData ScannedWhat’s Not Scanned

**Jira**
GitBook Assistant

Issue titles, descriptions, comments, and text-based attachments (`.txt`, `.log`, `.json`, `.yaml`, etc.)
GitBook Assistant

Issue history, archived projects, encrypted or binary attachments
GitBook Assistant

**Confluence**
GitBook Assistant

Page content, comments, and attachments (text-based)
GitBook Assistant

Deleted pages, page history versions, encrypted or binary files
GitBook Assistant

View the complete list in [Supported Data Sources](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/supported-data-sources).
GitBook Assistant
#### Security Model[#security-model](#security-model)

Entro Security integrates with Atlassian through **read-only access**, ensuring:
GitBook Assistant

- 

No data is modified or deleted
GitBook Assistant
- 

Only metadata required for secret detection is analyzed
GitBook Assistant
- 

Sensitive data remains within your environment for on-prem setups
GitBook Assistant
- 

All communication occurs securely via HTTPS/TLS
GitBook Assistant

Compliance alignment:
GitBook Assistant

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

Principle of least privilege (read-only scope)
GitBook Assistant
[PreviousJFrogArtifactory Troubleshooting And Validation](/integrations/container-registries/jfrog-artifactory/jfrogartifactory-troubleshooting-and-validation)[NextAtlassian Onboarding](/integrations/collaboration-and-saas/atlassian-ecosystem/atlassian-onboarding)

Last updated 4 months ago

- [Overview](#overview)
- [Integration Capabilities](#integration-capabilities)
- [Supported Products & Data](#supported-products-and-data)
