Azure / Entra / M365 | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure.md).

The **Azure / Entra / M365 Integration** enables Entro Security to continuously monitor and scan your Microsoft Entra environments, Azure subscriptions for Non-Human Identities (NHIs), secrets, and AI Agents. It connects securely through **App Registration** via **Graph APIs,** **Azure Resource Manager (ARM) APIs**, providing deep visibility into service principals, managed identities, key vault configurations and AI Agents.
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
+-----------------------+
|     Entro Security    |
|  Cloud (EU / US SaaS) |
+----------+------------+
           |
        HTTPS/TLS
           |
+----------v------------+
|   Microsoft Azure     |
|  (Entra ID, ARM, KV)  |
+-----------------------+
```

## Onboarding Options[#onboarding-options](#onboarding-options)
1
#### [Automated PowerShell Onboarding (recommended)](/integrations/cloud-and-infrastructure/azure/automated-powershell-onboarding)[#automated-powershell-onboarding-recommended](#automated-powershell-onboarding-recommended)

Creates an App Registration automatically and applies the required roles, permissions, and Log Analytics settings.
GitBook Assistant2
#### [Manual Portal Onboarding](/integrations/cloud-and-infrastructure/azure/azure-manual-onboarding)[#manual-portal-onboarding](#manual-portal-onboarding)

Create an App Registration, create a role, and assign it directly in the Entra ID portal.
GitBook Assistant3
#### Extra: [Continuous Permissions Assignment for Key Vaults, Subscriptions](/integrations/cloud-and-infrastructure/azure/azure-continuous-onboarding)- Following Manual or Automated onboarding[#extra-continuous-permissions-assignment-for-key-vaults-subscriptions-following-manual-or-automated-o](#extra-continuous-permissions-assignment-for-key-vaults-subscriptions-following-manual-or-automated-o)

Continuously grants read permissions for Entro's app on all new Azure Key Vaults, Subscriptions
GitBook Assistant
## Integration Highlights[#integration-highlights](#integration-highlights)

- 

Discover and manage Microsoft NHIs and AI agents
GitBook Assistant

- 

App registrations
GitBook Assistant
- 

SAML certificates
GitBook Assistant
- 

Entra users (hybrid AD and cloud)
GitBook Assistant
- 

Copilot chats
GitBook Assistant
- 

Copilot Studio agents
GitBook Assistant
- 

MS Defender Endpoints
GitBook Assistant

- 

Continuously scan for exposed secrets 
GitBook Assistant

- 

SharePoint
GitBook Assistant
- 

Teams
GitBook Assistant
- 

Azure Functions
GitBook Assistant

- 

Detect posture issues and anomalous behavior in service principals
GitBook Assistant
- 

Get contextual metadata from Microsoft Defender
GitBook Assistant
- 

Discover secrets stored in **Azure Key Vault**
GitBook Assistant
- 

Support both **Automated PowerShell Onboarding,** **Manual Portal Onboarding, Continous Key Vaults Onboarding**
GitBook Assistant

## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Before onboarding Azure to Entro Security, ensure the following:
GitBook Assistant

- 

You have **Global Administrator** or **Application Administrator** rights in Azure Entra ID
GitBook Assistant
- 

Azure CLI or Azure Portal access is available
GitBook Assistant
- 

*Self hosted connector only: *Outbound network egress to `https://api.entro.security` is allowed from the connector
GitBook Assistant

## Data Flow Summary[#data-flow-summary](#data-flow-summary)
1
#### Azure API credentials provided[#azure-api-credentials-provided](#azure-api-credentials-provided)

`client_id`, `client_secret`, and `tenant_id` are supplied securely to Entro.
GitBook Assistant2
#### Credentials validated and stored[#credentials-validated-and-stored](#credentials-validated-and-stored)

Entro validates and encrypts credentials using AES-256 encryption.
GitBook Assistant3
#### Querying Azure APIs[#querying-azure-apis](#querying-azure-apis)

Entro queries Entra ID and ARM APIs for identity and resource metadata.
GitBook Assistant4
#### Normalization and analysis[#normalization-and-analysis](#normalization-and-analysis)

Results are normalized, classified, and analyzed by Entro's NHI Engine.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Entro follows a **least-privilege** and **read-only** principle across all integrations.
GitBook Assistant

- 

Write only required for Teams (sending risk messages from Entro)
GitBook Assistant

- 

Access tokens are encrypted in-transit and at-rest (**TLS 1.2+**, **AES-256**).
GitBook Assistant
- 

Entro complies with **SOC 2 Type II**, **ISO 27001**, and **GDPR** standards.
GitBook Assistant
[PreviousAWS Permissions Reference](/integrations/cloud-and-infrastructure/amazon-web-services/aws-permissions-reference)[NextAzure Pre Onboarding Check](/integrations/cloud-and-infrastructure/azure/azure-pre-onboarding-check)

Last updated 2 months ago

- [Architecture Diagram](#architecture-diagram)
- [Onboarding Options](#onboarding-options)
- [Integration Highlights](#integration-highlights)
- [Navigation Path](#navigation-path)
- [Prerequisites](#prerequisites)
- [Data Flow Summary](#data-flow-summary)
- [Security & Compliance](#security-and-compliance)
