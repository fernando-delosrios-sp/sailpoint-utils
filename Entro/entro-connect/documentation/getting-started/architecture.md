Architecture | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/getting-started/architecture.md).
#### **System Overview**[#system-overview](#system-overview)

SailPoint Entro’s architecture is designed for scalability, data security, and modular extensibility. It integrates with multiple developer and cloud ecosystems while maintaining strict separation between detection, processing, and storage layers.
GitBook Assistant
#### **Core Components**[#core-components](#core-components)
ComponentDescription

**Collector Layer**
GitBook Assistant

Gathers secrets data from integrations (e.g., GitHub, AWS, Jira). Collectors operate as lightweight, isolated modules running in Docker containers or Kubernetes pods.
GitBook Assistant

**Processing Engine**
GitBook Assistant

Normalizes and enriches raw data, applying Entro’s proprietary AI models for classification, exposure scoring, and correlation of secrets to identities.
GitBook Assistant

**Database Layer**
GitBook Assistant

Uses encrypted storage for metadata and findings. Supports both PostgreSQL and AWS RDS with TLS encryption and at-rest AES-256.
GitBook Assistant

**Secrets Graph Engine**
GitBook Assistant

Builds relationship graphs between secrets, users, and assets to surface high-impact exposure paths. Powers 
GitBook Assistant

**Connector Service**
GitBook Assistant

Enables secure communication between on-premises environments and Entro SaaS using mutual TLS authentication.
GitBook Assistant

**API Gateway**
GitBook Assistant

Provides authenticated access for integrations and internal services. Supports JWT and OAuth 2.0.
GitBook Assistant

**Web Console**
GitBook Assistant

The frontend dashboard for visualization, investigation, and policy management. Built in React and backed by a GraphQL API.
GitBook Assistant
#### **Data Flow Summary**[#data-flow-summary](#data-flow-summary)

1. 

**Ingestion:** Collectors scan integrated systems (e.g., Git repositories, cloud accounts).
GitBook Assistant
1. 

**Normalization:** Extracted data is standardized into Entro’s schema.
GitBook Assistant
1. 

**Classification:** AI models classify entities as secrets, non-secrets, or metadata.
GitBook Assistant
1. 

**Correlation:** Secrets are linked to owners, assets, and potential exposures.
GitBook Assistant
1. 

**Scoring:** A risk engine calculates severity and prioritization.
GitBook Assistant
1. 

**Storage:** Results are securely written to the Entro database.
GitBook Assistant
1. 

**Visualization:** Users access insights through the Entro Web Console or APIs.
GitBook Assistant

####  **Security Principles**[#entro-security-data-flow](#entro-security-data-flow)

- 

**Zero Trust Architecture:** No implicit trust between services.
GitBook Assistant
- 

**Least Privilege:** Each module operates with minimal access rights.
GitBook Assistant
- 

**Encryption:** All data encrypted in transit (TLS 1.3) and at rest (AES-256).
GitBook Assistant
- 

**Auditability:** Every data action is logged and traceable.
GitBook Assistant
- 

**Data Minimization:** Only metadata required for analysis is stored.
GitBook Assistant
[PreviousAbout SailPoint Entro](/)[NextData Flow](/getting-started/data-flow)

Last updated 2 months ago
