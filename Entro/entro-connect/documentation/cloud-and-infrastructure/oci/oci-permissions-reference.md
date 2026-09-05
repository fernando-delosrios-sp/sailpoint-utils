OCI Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/oci/oci-permissions-reference.md).

This section explains the required ACL policies for integrating Oracle Cloud Infrastructure with Entro Security.
GitBook Assistant
## Required Permissions[#required-permissions](#required-permissions)

#### Summary[#summary](#summary)

Entro requires a dedicated IAM user with read-only access. No administrative or write privileges are required.
GitBook Assistant
#### Required Roles and Access[#required-roles-and-access](#required-roles-and-access)

The integration requires the ability to enumerate compartments, users, keys, vaults and secrets to build a security graph.
GitBook Assistant

**Scope Name**
GitBook Assistant

**Purpose**
GitBook Assistant

`inspect compartments`
GitBook Assistant

List all compartments to discover resource locations.
GitBook Assistant

`inspect users`
GitBook Assistant

Identify IAM users and their associated metadata.
GitBook Assistant

`inspect keys`
GitBook Assistant

Enumerate encryption keys used for secrets.
GitBook Assistant

`inspect vaults`
GitBook Assistant

Enumerate the vaults that hold encryption keys and secrets, so they can be discovered before their keys are inspected.
GitBook Assistant

`read secret-family`
GitBook Assistant

Read the content of secrets for classification and risk scoring.
GitBook Assistant
#### Security Notes[#security-notes](#security-notes)

- 

**Least Privilege:** Do not assign the user to the `Administrators` group.
GitBook Assistant
- 

**Rotation:** OCI allows a maximum of 3 API keys per user. Ensure you delete old keys before adding a 4th during rotation.
GitBook Assistant
[PreviousOCI Troubleshooting And Validation](/integrations/cloud-and-infrastructure/oci/oci-troubleshooting-and-validation)[NextRemote File System](/integrations/cloud-and-infrastructure/remote-file-system)

Last updated 2 months ago
