GitLab Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/gitlab/gitlab-permissions-reference.md).

Defines the roles, scopes, and API permissions used by Entro to securely connect with GitLab environments.
GitBook Assistant
## Overview[#overview](#overview)

Entro connects using a read-only Group or Personal Access Token. The integration requires minimal scopes to enumerate repositories, pipelines, and metadata.
GitBook Assistant
## Required Roles & Scopes[#required-roles-and-scopes](#required-roles-and-scopes)
ScopePurposeEndpoint

`api`
GitBook Assistant

Grants read/write access to the registry and repository using Git over HTTP.
GitBook Assistant

`/api`
GitBook Assistant

`read_api`
GitBook Assistant

Read group and project data
GitBook Assistant

`/api/v4/groups`
GitBook Assistant

`read_repository`
GitBook Assistant

Access repository metadata and commits
GitBook Assistant

`/api/v4/projects`
GitBook Assistant

`read_user`
GitBook Assistant

Retrieve user profile for authentication validation
GitBook Assistant

`/api/v4/user`
GitBook Assistant
## Auth Profile Mapping[#auth-profile-mapping](#auth-profile-mapping)

- 

**Inbound Auth:** Bearer Token
GitBook Assistant
- 

**Scope Enforcement:** Read-only, scoped to repositories accessible by the token owner
GitBook Assistant

Entro retrieves metadata and repository content for scanning without altering any configuration or data. All communications use HTTPS with TLS 1.2+ and AES-256 encryption.
GitBook Assistant
## Compliance & Security Notes[#compliance-and-security-notes](#compliance-and-security-notes)

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
- [Compliance & Security Notes](#compliance-and-security-notes)
