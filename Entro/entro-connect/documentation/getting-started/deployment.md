Deployment | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/getting-started/deployment.md).
#### **Overview**[#overview](#overview)

Entro can be deployed in **SaaS**,** hybrid**, or **self-hosted** modes. All models follow the same architectural principles but differ in control, maintenance, and data residency.
GitBook Assistant
#### **1. SaaS Deployment**[#id-1.-saas-deployment](#id-1.-saas-deployment)

- 

**Best for:** Organizations that prefer ease of deployment, managed infrastructure and automatic updates.
GitBook Assistant
- 

**Hosting:** Entro’s cloud environment (AWS, region selectable).
GitBook Assistant
- 

**Data Flow:** Connectors hosted in Entro's cloud infrastructure communicate securely with Customer's integrations via APIs over mutual TLS.
GitBook Assistant
- 

**Security:**
GitBook Assistant

- 

TLS encryption for data-in-motion (TLS 1.3), data encryption for data-at-rest (AES-256), secret data SHA256 hashed (for future correlation) and redacted.
GitBook Assistant
- 

Role-based access control (RBAC) with SSO and MFA.
GitBook Assistant
- 

SOC-2 and ISO 27001 aligned controls.
GitBook Assistant

- 

**Advantages:**
GitBook Assistant

- 

Fastest on-boarding
GitBook Assistant
- 

No maintenance overhead.
GitBook Assistant
- 

Continuous updates and feature rollouts.
GitBook Assistant
- 

Scales elastically with usage.
GitBook Assistant

#### **2. Hybrid Deployment**[#id-2.-hybrid-deployment](#id-2.-hybrid-deployment)

- 

**Best for:** Organizations with mixed cloud and internal environments and organizations that require all data processing to take place inside their data perimeter.
GitBook Assistant
- 

**Use Case:** Banks, defense, or healthcare customers balancing compliance and convenience.
GitBook Assistant
- 

**Hosting:** Entro SaaS management layer (AWS, region selectable) with Entro Outpost Connectors deployed in customers environment to process integration data.
GitBook Assistant
- 

**Data Flow:** Connectors hosted in Customer's infrastructure communicate securely with Customer's integrations via APIs over mutual TLS. After processing (including hashing, and redacting sensitive data), metadata is sent to Entro hosted management layer for correlation, risk processing, and reporting.
GitBook Assistant
- 

**Requirements:**
GitBook Assistant

- 

Kubernetes 1.24+ or Docker Compose environment for Entro Outpost Connector(s).
GitBook Assistant
- 

Network access from Entro Outpost Connector to Entro SaaS and configured integrations.
GitBook Assistant

- 

**Components:**
GitBook Assistant

- 

Entro Security Platform (API and processing services)
GitBook Assistant

- 

**Security:**
GitBook Assistant

- 

TLS encryption for data-in-motion (TLS 1.3), data encryption for data-at-rest (AES-256), secret data SHA256 hashed (for future correlation) and redacted.
GitBook Assistant
- 

Role-based access control (RBAC) with SSO and MFA.
GitBook Assistant
- 

SOC-2 and ISO 27001 aligned controls (Entro SaaS).
GitBook Assistant
- 

Support for customer-managed keys (CMK).
GitBook Assistant

#### **3. Self-Hosted Deployment**[#id-3.-self-hosted-deployment](#id-3.-self-hosted-deployment)

- 

**Best for:** Enterprises requiring full control of data and environment.
GitBook Assistant
- 

**Requirements:**
GitBook Assistant

- 

Ability to assume control of an AWS subscription provided by Entro for the Entro management platform and UI.
GitBook Assistant
- 

Kubernetes 1.24+ or Docker Compose environment for Entro Outpost Connector(s).
GitBook Assistant
- 

Network access from Entro Outpost Connector to self-hosted Entro management platform and configured integrations.
GitBook Assistant

- 

**Components:**
GitBook Assistant

- 

Entro Security Platform (hosted on customer owned AWS account)
GitBook Assistant
- 

Entro Connector or Outpost Connector (hosted in customer owned AWS account or on-premesis for connecting to internal resources)
GitBook Assistant

- 

**Security:**
GitBook Assistant

- 

TLS encryption for data-in-motion (TLS 1.3), data encryption for data-at-rest (AES-256), secret data SHA256 hashed (for future correlation) and redacted.
GitBook Assistant

#### **Deployment Process**[#deployment-process](#deployment-process)

1. 

Provision infrastructure (VMs or Kubernetes cluster) for Entro Outpost Connector(s).
GitBook Assistant
1. 

Deploy Entro Outpost Connector(s) software and supporting services using Helm or Docker Compose.
GitBook Assistant
1. 

Connect data sources through API keys or OAuth apps.
GitBook Assistant
1. 

Verify collector connectivity to Entro SaaS or self-hosted API.
GitBook Assistant
1. 

Validate first scan results in the Entro Web Console.
GitBook Assistant

#### **Maintenance**[#maintenance](#maintenance)

- 

**Monitoring:** Exposed via metrics and health endpoints.
GitBook Assistant
- 

**Logs:** Shipped via Fluentd or CloudWatch.
GitBook Assistant
- 

**Backups:** Automated daily backups (configurable retention).
GitBook Assistant
- 

**Updates:** Versioned container images with rolling deployment support.
GitBook Assistant
[PreviousSmart API Rate Limiting and Backoff Behavior](/getting-started/smart-api-rate-limiting-and-backoff-behavior)[NextGetting Started with SailPoint Entro](/getting-started/getting-started-with-sailpoint-entro)

Last updated 3 months ago
