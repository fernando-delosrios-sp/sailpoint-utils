HashiCorp Vault Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-permissions-reference.md).

## Required Permissions[#required-permissions](#required-permissions)

The following ACL configuration enables Entro to perform metadata scanning while ensuring no secret content is exposed.
GitBook AssistantGitBook AssistantAskCopy
```
path "*" {
  capabilities = ["list", "read"]
}
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}
path "auth/token/accessors" {
  capabilities = ["list", "sudo"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
```

## Permissions Justification[#permissions-justification](#permissions-justification)
PathCapabilitiesPurpose

`*`
GitBook Assistant

list, read
GitBook Assistant

Allows listing and reading metadata for all paths to identify stored secrets
GitBook Assistant

`auth/token/lookup-accessor`
GitBook Assistant

update
GitBook Assistant

Enables Entro to manage its own token session
GitBook Assistant

`auth/token/accessors`
GitBook Assistant

list, sudo
GitBook Assistant

Required for token accessor visibility and role validation
GitBook Assistant

`auth/token/renew-self`
GitBook Assistant

update
GitBook Assistant

Allows Entro to automatically renew its authentication token
GitBook Assistant
## KV v2 Metadata-Only Configuration (Optional)[#kv-v2-metadata-only-configuration-optional](#kv-v2-metadata-only-configuration-optional)

For organizations using KV v2 Secret Engines, you may apply a refined ACL for metadata-only access.
GitBook Assistant1
#### List secret engines and their paths[#list-secret-engines-and-their-paths](#list-secret-engines-and-their-paths)
2
#### Create an ACL policy for each listed path[#create-an-acl-policy-for-each-listed-path](#create-an-acl-policy-for-each-listed-path)

Replace `<PATH>` with the relevant KV mount path (e.g., `secret/`).
GitBook Assistant[PreviousHashiCorp Vault Troubleshooting And Validation](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-troubleshooting-and-validation)[NextOracle Cloud Infrastructure (OCI)](/integrations/cloud-and-infrastructure/oci)

Last updated 1 month ago

- [Required Permissions](#required-permissions)
- [Permissions Justification](#permissions-justification)
- [KV v2 Metadata-Only Configuration (Optional)](#kv-v2-metadata-only-configuration-optional)
GitBook AssistantAskCopy
```
vault secrets list -detailed | grep -E "^\S+\s+(kv|generic)"
```
GitBook AssistantAskCopy
```
path "sys/mounts" {
  capabilities = ["read"]
}
path "<PATH>/metadata" {
  capabilities = ["list"]
}
path "<PATH>/metadata/*" {
  capabilities = ["list", "read"]
}
path "sys/auth" {
  capabilities = ["read"]
}
path "auth/userpass/users" {
  capabilities = ["list"]
}
path "auth/userpass/users/*" {
  capabilities = ["list", "read"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
```
