ServiceNow Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/servicenow/servicenow-permissions-reference.md).

This page outlines all **ServiceNow roles**, **API scopes**, and **access configurations** used by Entro Security during integration. Entro operates strictly in **read-only mode** - the integration is limited to discovery and metadata retrieval through the ServiceNow REST APIs. No modification or deletion occurs.
GitBook Assistant

Entro operates in read-only mode. All API operations are restricted to retrieval (GET) only.
GitBook Assistant
## Integration Roles[#integration-roles](#integration-roles)

Entro requires a dedicated **Integration User** in ServiceNow with the following roles:
GitBook Assistant

- 

`itil` - read access to incidents, problems, change requests, and CMDB records.
GitBook Assistant
- 

`snc_read_only` - enforces read-only behavior across the user's assigned roles.
GitBook Assistant
- 

`knowledge` - read access to knowledge articles, knowledge bases, and article feedback.
GitBook Assistant
- 

`personalize_dictionary` - *optional*, allows discovery and scanning of custom tables.
GitBook Assistant

These roles grant read access while maintaining least-privilege. Two access paths fall outside ServiceNow's standard roles and must be configured explicitly:
GitBook AssistantData scannedServiceNow tableAccess requirement

Incidents, Problems, Change Requests, CMDB
GitBook Assistant

`incident`, `sc_request`, `problem`, `change_request`, `cmdb_ci`
GitBook Assistant

`itil`
GitBook Assistant

Knowledge Articles, Knowledge Bases, Feedback
GitBook Assistant

`kb_knowledge`, `kb_knowledge_base`, `kb_feedback`
GitBook Assistant

`knowledge` role **plus** inclusion in each knowledge base's **"Can Read" user criteria**
GitBook Assistant

Journals (work notes & comments)
GitBook Assistant

`sys_journal_field`
GitBook Assistant

Explicit `Record` / `read` **ACL** on `sys_journal_field`, scoped to the integration role
GitBook Assistant

Custom tables
GitBook Assistant

varies
GitBook Assistant

`personalize_dictionary` *(and any per-table roles)*
GitBook Assistant
## API Auth Scopes[#api-auth-scopes](#api-auth-scopes)

Each **Auth Scope** must:
GitBook Assistant

- 

Be explicitly assigned to its respective REST API
GitBook Assistant
- 

Have **Apply auth scope to all HTTP methods** unchecked
GitBook Assistant
- 

Be linked to the same **Authentication Profile** created during onboarding
GitBook Assistant
REST APIAuth ScopePurpose

Table API
GitBook Assistant

`entro-auth-scope`
GitBook Assistant

Read-only access to tickets, articles, and configuration records
GitBook Assistant

Attachment API
GitBook Assistant

`entro-auth-scope`
GitBook Assistant

Read-only access to attachments and file content
GitBook Assistant

Ensure the auth scopes are linked to the Authentication Profile created during onboarding.
GitBook Assistant
## API Access Policies[#api-access-policies](#api-access-policies)

Entro communicates with the ServiceNow instance through **API Access Policies** that enforce inbound authentication and scope restrictions. Each API (Table and Attachment) must be associated with:
GitBook Assistant

- 

The **Inbound Authentication Profile** created during onboarding
GitBook Assistant
- 

The corresponding `entro-auth-scope`
GitBook Assistant

Ensure **Apply to all methods** is **unchecked** for both APIs to restrict operations to `GET` (read-only).
GitBook Assistant
## REST API Key Configuration[#rest-api-key-configuration](#rest-api-key-configuration)

All **API Access Tokens** must be generated from: **System Web Services → API Access Policies → REST API Key**
GitBook Assistant

Configuration requirements:
GitBook Assistant

- 

Assign to the Integration User created during onboarding
GitBook Assistant
- 

Link to the `entro-auth-scope`
GitBook Assistant
- 

Copy and store the token securely immediately after creation - ServiceNow does **not** allow retrieval later
GitBook Assistant

## Entro Access Summary[#entro-access-summary](#entro-access-summary)

- 

**Access Mode:** Read-only
GitBook Assistant
- 

**APIs Used:** Table API, Attachment API
GitBook Assistant
- 

**Authentication:** API Access Token
GitBook Assistant
- 

**Data Retrieved:** Tickets, Journals, Knowledge Base, Attachments, and Configuration Records, Users, Groups, Group Members, Journals (comments/work notes), Feedbacks, and DB Objects/Dictionaries
GitBook Assistant
- 

**Scope Enforcement:** `entro-auth-scope` (Table + Attachment APIs)
GitBook Assistant
- 

**Integration Validation:** Automatic verification during connection; displays **Verified** on success
GitBook Assistant

Integration is automatically validated during connection. On success, the integration displays "Verified"
GitBook Assistant[PreviousServiceNow Troubleshooting and Validation](/integrations/collaboration-and-saas/servicenow/servicenow-troubleshooting-and-validation)[NextSlack](/integrations/collaboration-and-saas/slack)

Last updated 2 months ago

- [Integration Roles](#integration-roles)
- [API Auth Scopes](#api-auth-scopes)
- [API Access Policies](#api-access-policies)
- [REST API Key Configuration](#rest-api-key-configuration)
- [Entro Access Summary](#entro-access-summary)
