# ISC API collection

Snapshot of the Identity Security Cloud API Postman collection (`d0033512-30e9-4299-b57e-6d3056a8a080`), taken 2026-10-15. 940 endpoints in 114 groups.

Open the one group whose name is the object you are calling. Each endpoint states method, path, success status, query fields, and a body example when the collection has one. `Experimental` means send the header from [`conventions.md`](conventions.md). List, filter, sort, and search syntax is in that file.

The group file is the contract. A **gap** is a path that 404s, or a field, enum, or error you must handle that the group file does not state. Fetch [the API specs](https://developer.sailpoint.com/docs/api) only to close a gap.

| Group | Endpoints | What it covers |
| --- | ---: | --- |
| [Access Model Metadata](groups/access-model-metadata.md) | 13 | Use this API to create and manage metadata attributes for your Access Model. |
| [Access Profiles](groups/access-profiles.md) | 14 | Use this API to implement and customize access profile functionality. |
| [Access Request Approvals](groups/access-request-approvals.md) | 7 | Use this API to implement and customize access request approval functionality. |
| [Access Request Identity Metrics](groups/access-request-identity-metrics.md) | 1 | Use this API to implement access request identity metrics functionality. |
| [Access Requests](groups/access-requests.md) | 13 |  This endpoint returns the current access-request configuration. |
| [Account Activities](groups/account-activities.md) | 2 | Use this API to implement account activity tracking functionality. |
| [Account Aggregations](groups/account-aggregations.md) | 1 | Use this API to implement account aggregation progress tracking functionality. |
| [Account Deletion Requests](groups/account-deletion-requests.md) | 2 |  Retrieves a paginated list of account deletion requests filtered by the provided query parameters. |
| [Account Usages](groups/account-usages.md) | 1 | Use this API to implement account usage insight functionality. |
| [Accounts](groups/accounts.md) | 16 | Use this API to implement and customize account functionality. |
| [Api Usage](groups/api-usage.md) | 2 | Use this API to retrieve metrics about an org's API usage. |
| [Application Discovery](groups/application-discovery.md) | 4 | Use this API to implement application discovery functionality. |
| [Approvals](groups/approvals.md) | 15 | Use this API to implement approval functionality. |
| [Apps](groups/apps.md) | 14 | Use this API to implement source application functionality. |
| [Auth Profile](groups/auth-profile.md) | 3 | Use this API to implement Auth Profile functionality. |
| [Auth Users](groups/auth-users.md) | 2 | Use this API to implement user authentication system functionality. |
| [Branding](groups/branding.md) | 5 | Use this API to implement and customize branding functionality. |
| [Business Applications](groups/business-applications.md) | 4 | A Business Application groups machine identities (for example AI agents or applications) under a common owner and sanctioned status. |
| [Certification Campaign Filters](groups/certification-campaign-filters.md) | 5 | Use this API to implement the certification campaign filter functionality. |
| [Certification Campaigns](groups/certification-campaigns.md) | 22 | Use this API to implement certification campaign functionality. |
| [Certification Summaries](groups/certification-summaries.md) | 4 | Use this API to implement certification summary functionality. |
| [Certifications](groups/certifications.md) | 11 | Use this API to implement certification functionality. |
| [Classify Source](groups/classify-source.md) | 3 |  Use this API to classify all the accounts from a source. |
| [Configuration Hub](groups/configuration-hub.md) | 20 | Use this API to implement and customize configuration settings management. |
| [Connector Customizers](groups/connector-customizers.md) | 6 | Saas Connectivity Customizers are cloud-based connector customizers. |
| [Connector Rule Management](groups/connector-rule-management.md) | 6 | Use this API to implement connector rule management functionality. |
| [Connectors](groups/connectors.md) | 13 | Use this API to implement connector functionality. |
| [Custom Forms](groups/custom-forms.md) | 18 | Use this API to build and manage custom forms. |
| [Custom Password Instructions](groups/custom-password-instructions.md) | 3 | Use this API to implement custom password instruction functionality. |
| [Custom User Levels](groups/custom-user-levels.md) | 9 | Use this API to implement custom user level functionality. |
| [Data Access Security](groups/data-access-security.md) | 31 | Use this API to enable data ownership election campaigns, assign resource owners, and respond to identity lifecycle events to maintain continuous accountability. |
| [Data Segmentation](groups/data-segmentation.md) | 8 | This service is responsible for creating segments that will determine how access is delegated to identities withing the organization. |
| [Declassify Source](groups/declassify-source.md) | 1 |  Use this API to declassify all the accounts from a source. |
| [Dimensions](groups/dimensions.md) | 8 | Use this API to implement and customize dynamic role functionality. |
| [Entitlement Connections](groups/entitlement-connections.md) | 3 | Use this API to search and manage entitlement connections. |
| [Entitlements](groups/entitlements.md) | 16 |  This API returns a list of entitlements. |
| [Global Tenant Security Settings](groups/global-tenant-security-settings.md) | 9 | Use this API to implement and customize global tenant security settings. |
| [Governance Groups](groups/governance-groups.md) | 10 | Use this API to implement and customize Governance Group functionality. |
| [IAI Access Request Recommendations](groups/iai-access-request-recommendations.md) | 10 |  This API returns the access request recommendations for the specified identity. |
| [IAI Common Access](groups/iai-common-access.md) | 3 |  This endpoint returns the current common access for a customer. |
| [IAI Outliers](groups/iai-outliers.md) | 9 |  This API returns a summary containing the number of identities that customer has, the number of outliers, and the type of outlier. |
| [IAI Peer Group Strategies](groups/iai-peer-group-strategies.md) | 1 |  -- Deprecated : See 'IAI Outliers' This API will be used by Identity Governance systems to identify identities that are not included in an organization's peer groups. |
| [IAI Recommendations](groups/iai-recommendations.md) | 3 |  The getRecommendations API returns recommendations based on the requested object. |
| [IAI Role Mining](groups/iai-role-mining.md) | 25 |  This submits a create role mining session request to the role mining application. |
| [Icons](groups/icons.md) | 2 | Use this API to implement functionality related to object icons (application icons for example). |
| [Identities](groups/identities.md) | 12 | Use this API to implement identity functionality. |
| [Identity Attributes](groups/identity-attributes.md) | 6 |  Use this API to get a collection of identity attributes. |
| [Identity History](groups/identity-history.md) | 11 |  This gets the list of identities for the customer. |
| [Identity Profiles](groups/identity-profiles.md) | 11 | Use this API to implement identity profile functionality. |
| [Intelligence](groups/intelligence.md) | 8 | HTTP API that returns the Intelligence (identity context) for SecOps enrichment use cases (SIEM/SOAR connectors, MCP, browser extension), and accepts asynchronous response actions for remediation. |
| [JIT Access](groups/jit-access.md) | 2 | Use these APIs to configure JIT provisioning activation policy for the tenant. |
| [JIT Activations](groups/jit-activations.md) | 7 | Use this API to start and manage Just-In-Time (JIT) Privileged activation workflows for entitlement connections, to read and submit activation frictions, and to search activation history. |
| [Launchers](groups/launchers.md) | 6 | Use this API to manage Launchers. A launcher lets users start a workflow on demand from Identity Security Cloud, such as a Privileged Workflow or a workflow that creates an Active Directory group. |
| [Lifecycle States](groups/lifecycle-states.md) | 6 | Use this API to implement and customize lifecycle state functionality. |
| [Machine Account Classify](groups/machine-account-classify.md) | 1 |  Use this API to classify a single machine account. |
| [Machine Account Creation Request](groups/machine-account-creation-request.md) | 3 | Use this API to submit and retrieve machine account creation requests. |
| [Machine Account Mappings](groups/machine-account-mappings.md) | 4 |  Retrieves Machine account mappings for a specified source using Source ID. |
| [Machine Account Subtypes](groups/machine-account-subtypes.md) | 8 | Use this API to get, update, and delete machine account subtype for sources. |
| [Machine Accounts](groups/machine-accounts.md) | 14 |  This returns a list of machine accounts. |
| [Machine Classification Config](groups/machine-classification-config.md) | 3 |  This API returns a Machine Classification Config for a Source using Source ID. |
| [Machine Identities](groups/machine-identities.md) | 18 |  This API returns a list of machine identities. |
| [Machine Identity Lifecycle Actions](groups/machine-identity-lifecycle-actions.md) | 4 | Experimental APIs for machine identity lifecycle requests (`ACTIVATE`, `DEACTIVATE`), including approval and provisioning status. |
| [Managed Clients](groups/managed-clients.md) | 7 | Use this API to implement managed client functionality. |
| [Managed Cluster Types](groups/managed-cluster-types.md) | 5 | Use this API to implement managed cluster types functionality. |
| [Managed Clusters](groups/managed-clusters.md) | 8 | Use this API to implement managed cluster functionality. |
| [MFA Configuration](groups/mfa-configuration.md) | 7 | Configure and test multifactor authentication (MFA) methods |
| [Multi-Host Integration](groups/multi-host-integration.md) | 14 | Use this API to build a Multi-Host Integration. |
| [Non-Employee Lifecycle Management](groups/non-employee-lifecycle-management.md) | 32 | Use this API to implement non-employee lifecycle management functionality. |
| [Notifications](groups/notifications.md) | 18 |  Returns global variables and template-specific variables for a given notification template key and medium. |
| [OAuth Clients](groups/oauth-clients.md) | 5 | Use this API to implement OAuth client functionality. |
| [Org Config](groups/org-config.md) | 3 | Use this API to implement organization configuration functionality. |
| [Parameter Storage](groups/parameter-storage.md) | 8 | The Parameter Storage is SailPoint's centralized repository for authentication, authorization, and connection configurations, stored as typed Parameters. |
| [Password Configuration](groups/password-configuration.md) | 3 | Use this API to implement organization password configuration functionality. |
| [Password Dictionary](groups/password-dictionary.md) | 2 | Use this API to implement password dictionary functionality. |
| [Password Management](groups/password-management.md) | 4 | Use this API to implement password management functionality. |
| [Password Policies](groups/password-policies.md) | 5 | Use these APIs to implement password policies functionality. |
| [Password Sync Groups](groups/password-sync-groups.md) | 5 | Use this API to implement password sync group functionality. |
| [Personal Access Tokens](groups/personal-access-tokens.md) | 5 | Use this API to implement personal access token (PAT) functionality. |
| [Privilege Criteria](groups/privilege-criteria.md) | 5 | Use this API to create, retrieve, update, and delete privilege criteria. |
| [Privilege Criteria Configuration](groups/privilege-criteria-configuration.md) | 3 | Use this API to manage the configuration of privilege criteria. |
| [Public Identities](groups/public-identities.md) | 1 | Use this API in conjunction with Public Identites Config to enable non-administrators to view identities' publicly visible attributes. |
| [Public Identities Config](groups/public-identities-config.md) | 2 | Use this API to implement public identity configuration functionality. |
| [Public Machine Identities](groups/public-machine-identities.md) | 1 | Use this API to list machine identities with a reduced, public-safe payload for catalog and request workflows. |
| [Reports Data Extraction](groups/reports-data-extraction.md) | 4 | Use this API to implement reports lifecycle managing and monitoring. |
| [Requestable Objects](groups/requestable-objects.md) | 1 | Use this API to implement requestable object functionality. |
| [Role Insights](groups/role-insights.md) | 9 |  Submits a create role insights request to the role insights application. |
| [Role Propagation](groups/role-propagation.md) | 6 | Role Change Propagation ensures that any changes to the composition of a role’s access objects (entitlements, access profiles, or dimensions) are applied to all member identities. |
| [Roles](groups/roles.md) | 16 | Use this API to implement and customize role functionality. |
| [Saved Search](groups/saved-search.md) | 6 | Use this API to implement saved search functionality. |
| [Scheduled Search](groups/scheduled-search.md) | 6 | Use this API to implement scheduled search functionality. |
| [Search](groups/search.md) | 4 | Use this API to implement search functionality. |
| [Search Attribute Configuration](groups/search-attribute-configuration.md) | 5 | Use this API to implement search attribute configuration functionality, along with Search. |
| [Segments](groups/segments.md) | 5 | Use this API to implement and customize access request segment functionality. |
| [Service Desk Integration](groups/service-desk-integration.md) | 10 | Use this API to build an integration between Identity Security Cloud and a service desk ITSM (IT service management) solution. |
| [Shared Signals Framework (SSF)](groups/shared-signals-framework-ssf.md) | 10 | The SSF Transmitter Service is a security event notification system that monitors identity attribute changes and automatically triggers session revocation events when specific lifecycle conditions are met. |
| [SIM Integrations](groups/sim-integrations.md) | 7 | Use this API to administer IdentityNow's Service Integration Module, or SIM integration with ServiceNow, so that it converts IdentityNow provisioning actions into tickets in ServiceNow. |
| [SOD Controls](groups/sod-controls.md) | 5 | Use this API to create, list, retrieve, update, and delete compensating controls associated with separation-of-duties policies. |
| [SOD Policies](groups/sod-policies.md) | 17 | Use this API to implement and manage "separation of duties" (SOD) policies. |
| [SOD Violations](groups/sod-violations.md) | 7 | Use this API to check for current "separation of duties" (SOD) policy violations as well as potential future SOD policy violations. |
| [Source Usages](groups/source-usages.md) | 2 | Use this API to implement source usage insight functionality. |
| [Sources](groups/sources.md) | 77 | Use this API to implement and customize source functionality. |
| [SP-Config](groups/sp-config.md) | 7 | Import and export configuration for some objects between tenants. |
| [Suggested Entitlement Description](groups/suggested-entitlement-description.md) | 15 | Use this API to implement Suggested Entitlement Description (SED) functionality. |
| [Tagged Objects](groups/tagged-objects.md) | 8 | Use this API to implement object tagging functionality. |
| [Tags](groups/tags.md) | 4 | Use this API to manage the tags available in your Identity Security Cloud tenant. |
| [Task Management](groups/task-management.md) | 3 |  Get task status by task ID. |
| [Tenant](groups/tenant.md) | 1 | API for reading tenant details. |
| [Tenant Context](groups/tenant-context.md) | 2 | The purpose of this API is to manage key-value pairs specific to a tenant's context, enabling dynamic configuration and personalized settings per tenant. |
| [Transforms](groups/transforms.md) | 5 | The purpose of this API is to expose functionality for the manipulation of Transform objects. |
| [Triggers](groups/triggers.md) | 10 | Event Triggers provide real-time updates to changes in Identity Security Cloud so you can take action as soon as an event occurs, rather than poll an API endpoint for updates. |
| [UI Metadata](groups/ui-metadata.md) | 2 | API for managing UI Metadata. Use this API to manage metadata about your User Interface. |
| [Work Items](groups/work-items.md) | 13 | Use this API to implement work item functionality. |
| [Work Reassignment](groups/work-reassignment.md) | 9 | Use this API to implement work reassignment functionality. |
| [Workflows](groups/workflows.md) | 19 | Workflows allow administrators to create custom automation scripts directly within Identity Security Cloud. |
