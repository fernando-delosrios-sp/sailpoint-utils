Wiz | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/wiz.md).

The **Wiz Integration** enhances Entro Security’s Non-Human Identity (NHI) visibility by incorporating **Data Security Posture Management (DSPM)** and vulnerability insights from Wiz. This integration provides unified visibility into sensitive data risks and the NHIs interacting with that data, enabling proactive mitigation of potential threats.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → Wiz
GitBook Assistant
## Purpose[#purpose](#purpose)

By integrating Wiz with Entro Security, joint customers gain:
GitBook Assistant

- 

Data classification and access visibility
GitBook Assistant
- 

NHI permission impact analysis
GitBook Assistant
- 

Contextual risk severity mapping across cloud assets
GitBook Assistant
- 

Unified detection and reporting on sensitive data interactions
GitBook Assistant

## Supported NHI Types[#supported-nhi-types](#supported-nhi-types)

- 

AWS Role
GitBook Assistant
- 

AWS IAM Access Key
GitBook Assistant
- 

GCP Service Account *(coming soon)*
GitBook Assistant
- 

Azure App Registration Client Secret
GitBook Assistant
- 

GitHub IAM User *(coming soon)*
GitBook Assistant

## Architecture[#architecture](#architecture)

## Security Model[#security-model](#security-model)

- 

Communication secured via **HTTPS/TLS 1.2+**
GitBook Assistant
- 

Service Account credentials are **AES-256 encrypted** at rest within Entro
GitBook Assistant
- 

Integration operates with **read-only permissions** (no data modification)
GitBook Assistant
- 

All Wiz tokens and secrets are managed by Entro’s encrypted Worker Group
GitBook Assistant

## Integration Flow[#integration-flow](#integration-flow)
1
#### Create the Wiz Service Account[#create-the-wiz-service-account](#create-the-wiz-service-account)

Create a **Wiz Service Account** with the required permissions.
GitBook Assistant2
#### Retrieve Credentials[#retrieve-credentials](#retrieve-credentials)

Retrieve the **Client ID** and **Client Secret**.
GitBook Assistant3
#### Enter Credentials in Entro[#enter-credentials-in-entro](#enter-credentials-in-entro)

Enter credentials in Entro’s onboarding form.
GitBook Assistant4
#### Validation & Import[#validation-and-import](#validation-and-import)

Entro validates the connection and begins importing metadata for NHI data exposure visibility.
GitBook Assistant[PreviousSnowflake Permissions Reference](/integrations/security-and-identity/snowflake/snowflake-permissions-reference)[NextWiz Onboarding](/integrations/security-and-identity/wiz/wiz-onboarding)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Purpose](#purpose)
- [Supported NHI Types](#supported-nhi-types)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Integration Flow](#integration-flow)
GitBook AssistantAskCopy
```
┌───────────────────────────────┐
│       Entro Security Cloud    │
│  (NHI & Secret Detection)     │
└──────────────┬────────────────┘
               │  HTTPS (TLS 1.2+)
               ▼
┌───────────────────────────────┐
│          Wiz Platform         │
│ (DSPM, Findings, Reports)     │
└───────────────────────────────┘
```
