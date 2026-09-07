Akeyless Vault | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/akeyless-vault.md).

Entro Security integrates natively with **Akeyless Vault** to provide continuous, read-only visibility into your organization's secrets infrastructure.This integration allows security and DevOps teams to detect misconfigurations, monitor access patterns, and identify potential exposures without retrieving or modifying secret values.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

### Management → Accounts & Integrations → Add New Account (top right) → Akeyless[#management-accounts-and-integrations-add-new-account-top-right-akeyless](#management-accounts-and-integrations-add-new-account-top-right-akeyless)

## Capabilities[#capabilities](#capabilities)

- 

Continuous discovery of secrets and metadata across Akeyless Vault environments
GitBook Assistant
- 

Monitoring of roles and access permissions for overprivileged or misconfigured identities
GitBook Assistant
- 

Detection of long-lived or unused secrets and anomalous secret activity
GitBook Assistant
- 

Cross-platform visibility through correlation with other Entro integrations
GitBook Assistant
- 

Read-only, zero-touch data collection ensuring vault integrity
GitBook Assistant

## Supported Authentication Methods[#supported-authentication-methods](#supported-authentication-methods)

- 

**Universal Identity** – recommended for modern deployments
GitBook Assistant
- 

**API Key** – for restricted or legacy Akeyless environments
GitBook Assistant

## Security Principles[#security-principles](#security-principles)

- 

Entro connects to Akeyless using read-only API calls only
GitBook Assistant
- 

No secret values are ever retrieved or modified
GitBook Assistant
- 

All data access is performed through encrypted **HTTPS/TLS 1.2+** connections
GitBook Assistant
- 

Tokens and keys are encrypted with **AES-256** within the Entro Worker (Connector)
GitBook Assistant

## Architecture Diagram[#architecture-diagram](#architecture-diagram)

## Data Processed[#data-processed](#data-processed)

Entro retrieves only metadata such as:
GitBook Assistant

- 

Secret identifiers, creation timestamps, and usage metadata
GitBook Assistant
- 

Role associations, policy definitions, and permission scope details
GitBook Assistant

No secret content or decrypted data is ever transmitted or stored.
GitBook Assistant
## Compliance and Privacy[#compliance-and-privacy](#compliance-and-privacy)

All Akeyless integrations comply with Entro’s internal and external standards:
GitBook Assistant

- 

**SOC 2 Type II**
GitBook Assistant
- 

**ISO 27001**
GitBook Assistant
- 

**GDPR**
GitBook Assistant
- 

Read-only, least-privilege access enforced
GitBook Assistant
[PreviousConnector versions](/integrations/entro-connector/entro-connector/connector-versions)[NextAkeyless Onboarding](/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-onboarding)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Management → Accounts & Integrations → Add New Account (top right) → Akeyless](#management-accounts-and-integrations-add-new-account-top-right-akeyless)
- [Capabilities](#capabilities)
- [Supported Authentication Methods](#supported-authentication-methods)
- [Security Principles](#security-principles)
- [Architecture Diagram](#architecture-diagram)
- [Data Processed](#data-processed)
- [Compliance and Privacy](#compliance-and-privacy)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS/TLS 1.2+)
Akeyless Vault (Read-Only API Access)
   ├── Secrets Metadata
   ├── Access Roles
   └── Audit Policies
```
