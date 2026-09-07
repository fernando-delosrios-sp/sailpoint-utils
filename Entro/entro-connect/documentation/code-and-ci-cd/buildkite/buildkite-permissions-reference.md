Buildkite Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/buildkite/buildkite-permissions-reference.md).

This page defines the API scopes and permissions required for the Buildkite–Entro integration.
GitBook Assistant
## Required API Permissions[#required-api-permissions](#required-api-permissions)

The Buildkite API Access Token used for the integration must have read-only permissions for all relevant resources.
GitBook AssistantScopePermission TypeDescription

Builds
GitBook Assistant

Read
GitBook Assistant

Retrieve build and job metadata
GitBook Assistant

Pipelines
GitBook Assistant

Read
GitBook Assistant

Access pipeline definitions and configurations
GitBook Assistant

Organizations
GitBook Assistant

Read
GitBook Assistant

Verify organization-level details and tokens
GitBook Assistant

Agents
GitBook Assistant

Read
GitBook Assistant

Inspect build agent and environment metadata
GitBook Assistant
## Access Summary[#access-summary](#access-summary)

- 

Integration uses a Personal Access Token (PAT) for API authentication.
GitBook Assistant
- 

Access is limited to read-only API calls.
GitBook Assistant
- 

No modifications or deletions are performed.
GitBook Assistant
- 

Tokens are stored in encrypted form (AES-256).
GitBook Assistant
- 

Communications occur via TLS 1.2+.
GitBook Assistant

Entro adheres to least-privilege access: the integration only requests the minimum required read-only scopes.
GitBook Assistant
## Compliance & Security Notes[#compliance-and-security-notes](#compliance-and-security-notes)
Details[#details](#details)

- 

Entro never retrieves or stores build secrets or logs.
GitBook Assistant
- 

All operations comply with SOC 2 Type II, ISO 27001, and GDPR standards.
GitBook Assistant
- 

Integration strictly adheres to least-privilege access principles.
GitBook Assistant

Last updated 4 months ago

- [Required API Permissions](#required-api-permissions)
- [Access Summary](#access-summary)
- [Compliance & Security Notes](#compliance-and-security-notes)
