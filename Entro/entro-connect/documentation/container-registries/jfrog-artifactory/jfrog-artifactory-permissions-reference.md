JFrog Artifactory Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/container-registries/jfrog-artifactory/jfrog-artifactory-permissions-reference.md).

This section describes all required roles, scopes, and access settings for Entro’s JFrog Artifactory integration.
GitBook Assistant
## Overview[#overview](#overview)

Entro uses a read-only Access Token associated with a user in the `readers` group. This grants minimal access for repository enumeration and metadata inspection.
GitBook Assistant
## Required Roles & Scopes[#required-roles-and-scopes](#required-roles-and-scopes)
ScopePurposeEndpoint

`read_repo`
GitBook Assistant

Read repository metadata and images
GitBook Assistant

`/api/repositories`
GitBook Assistant

`read_artifact`
GitBook Assistant

Access image layers for secret scanning
GitBook Assistant

`/api/storage/*`
GitBook Assistant

`read_token`
GitBook Assistant

Validate access token
GitBook Assistant

`/api/security/token`
GitBook Assistant
## Auth Profile Mapping[#auth-profile-mapping](#auth-profile-mapping)

- 

**Inbound Auth:** Token-based (Bearer)
GitBook Assistant
- 

**Scope Enforcement:** Read-only, limited to repositories assigned to the group
GitBook Assistant

Entro never modifies or deletes any content. All requests use HTTPS with TLS 1.2+ and tokens encrypted with AES-256.
GitBook Assistant

Compliance & Security Notes:
GitBook Assistant

- 

SOC 2 Type II
GitBook Assistant
- 

ISO 27001
GitBook Assistant
- 

GDPR
GitBook Assistant
- 

TLS 1.2+ and AES-256
GitBook Assistant

Last updated 4 months ago

- [Overview](#overview)
- [Required Roles & Scopes](#required-roles-and-scopes)
- [Auth Profile Mapping](#auth-profile-mapping)
