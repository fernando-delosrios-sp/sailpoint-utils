HashiCorp Vault | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/hashicorp-vault.md).

The **HashiCorp Vault Integration** enables Entro Security to continuously monitor your Vault environment and identify secrets, tokens, and metadata associated with Non-Human Identities (NHIs). This integration operates in **read-only** mode to ensure maximum security while providing complete visibility into vaulted secrets and metadata.
GitBook Assistant

HashiCorp integration is supported in the **Community** license.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → HashiCorp Vault
GitBook Assistant
## Purpose[#purpose](#purpose)

HashiCorp Vault is commonly used to store and manage secrets across enterprise systems. Entro integrates with Vault to:
GitBook Assistant

- 

Discover and analyze secret metadata across paths
GitBook Assistant
- 

Correlate secret ownership with NHIs
GitBook Assistant
- 

Identify configuration and policy misconfigurations
GitBook Assistant
- 

Provide continuous monitoring without secret value access
GitBook Assistant

## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
┌───────────────────────────────┐
│       Entro Security Cloud    │
│  (Secret & NHI Detection)     │
└──────────────┬────────────────┘
               │  HTTPS (TLS 1.2+)
               ▼
┌───────────────────────────────┐
│       HashiCorp Vault         │
│ (Secrets, Policies, Tokens)   │
└───────────────────────────────┘
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

## Integration Flow[#integration-flow](#integration-flow)
1
#### Create a Vault ACL policy[#create-a-vault-acl-policy](#create-a-vault-acl-policy)

Create a Vault ACL policy for Entro read-only access.
GitBook Assistant2
#### Generate a Vault token[#generate-a-vault-token](#generate-a-vault-token)

Generate a Vault token bound to the created policy.
GitBook Assistant3
#### Provide Vault Server URL and Token[#provide-vault-server-url-and-token](#provide-vault-server-url-and-token)

Provide the **Vault Server URL** and **Token** in the Entro onboarding form.
GitBook Assistant4
#### Validation and scanning[#validation-and-scanning](#validation-and-scanning)

Entro validates connectivity and begins scanning Vault metadata.
GitBook Assistant[PreviousGCP Permissions Reference](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-permissions-reference)[NextHashiCorp Vault Onboarding](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-onboarding)

Last updated 1 month ago

- [Navigation Path](#navigation-path)
- [Purpose](#purpose)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Integration Flow](#integration-flow)
