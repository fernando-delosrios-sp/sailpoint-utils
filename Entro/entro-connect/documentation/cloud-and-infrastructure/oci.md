Oracle Cloud Infrastructure (OCI) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/oci.md).

Entro connects to your Oracle Cloud Infrastructure (OCI) tenancy to discover, monitor, and analyze non-human identities and their permissions. This integration helps security teams gain visibility into OCI credentials and prevent lateral movement or unauthorized access.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → Oracle Cloud Infrastructure
GitBook Assistant
## Purpose[#purpose](#purpose)

The OCI integration ingests IAM metadata to identify:
GitBook Assistant

- 

IAM User API keys.
GitBook Assistant
- 

Lifecycle risks on API Keys.
GitBook Assistant
- 

Relationships between IAM users and cloud resources.
GitBook Assistant

## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
+-----------------------+
|     Entro Console     |
|    (Control Plane)    |
+-----------+-----------+
            |
            | HTTPS / TLS 1.3 (OCI API)
            |
            V
+-----------+-----------+
| Oracle Cloud (OCI)    |
|   - Domains Service   |
+-----------------------+
```

## Security Model[#security-model](#security-model)

- 

Entro connects using a **read-only ACL policy**
GitBook Assistant
- 

No secret values or credentials are ever extracted
GitBook Assistant
- 

All tokens and policies are encrypted using **AES-256**
GitBook Assistant
- 

All communication occurs via **HTTPS/TLS 1.2+**
GitBook Assistant
- 

Integration complies with **SOC 2 Type II**, **ISO 27001**, and **GDPR**
GitBook Assistant
[PreviousHashiCorp Vault Permissions Reference](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-permissions-reference)[NextOCI Onboarding](/integrations/cloud-and-infrastructure/oci/oci-onboarding)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Purpose](#purpose)
- [Architecture](#architecture)
- [Security Model](#security-model)
