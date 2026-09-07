GCP Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-permissions-reference.md).

This section lists all the required IAM roles, API scopes, and optional permissions for Entro's GCP integration, along with clarifications for each feature.
GitBook Assistant
## Required APIs[#required-apis](#required-apis)
RolePurpose

Logging API
GitBook Assistant

Audit logs access for NHI usage tracking `[MANDATORY]`
GitBook Assistant

Secret Manager API
GitBook Assistant

Vaulted secrets management `[OPTIONAL]`
GitBook Assistant

Cloud Resource Manager API
GitBook Assistant

`[MANDATORY]`
GitBook Assistant

IAM API
GitBook Assistant

NHI, Permissions `[MANDATORY]`
GitBook Assistant

Recommender API
GitBook Assistant

NHI Last usage timestamp, Excessive permissions analysis `[MANDATORY]`
GitBook Assistant

Cloud Functions API
GitBook Assistant

Secrets scanning Cloud Functions `[OPTIONAL]`
GitBook Assistant

Cloud Asset API
GitBook Assistant

NHIs and Vaulted keys owner detection `[MANDATORY]`
GitBook Assistant

Cloud Identity API
GitBook Assistant

`[MANDATORY]`
GitBook Assistant

Admin SDK API
GitBook Assistant

Optional to auto-scan all drives`[OPTIONAL]`
GitBook Assistant

Discovery Engine API
GitBook Assistant

Google AI Agents discovery `[OPTIONAL]`
GitBook Assistant

Google Drive API
GitBook Assistant

Google Workspace Directory, Google Drive secrets scanning `[OPTIONAL]`
GitBook Assistant

PubSub API
GitBook Assistant

Ingestion via PubSub instead of Logging API `[OPTIONAL]`
GitBook Assistant
## Required Roles[#required-roles](#required-roles)
RolePurpose

Logs Viewer
GitBook Assistant

View log entries
GitBook Assistant

Secret Manager Viewer
GitBook Assistant

Access stored secrets
GitBook Assistant

IAM Recommender Viewer
GitBook Assistant

Review IAM suggestions
GitBook Assistant

Organization Viewer
GitBook Assistant

Access org-wide metadata
GitBook Assistant

Cloud Asset Viewer
GitBook Assistant

List assets for audit
GitBook Assistant

API Keys Viewer
GitBook Assistant

Access API key metadata
GitBook Assistant

Security Reviewer
GitBook Assistant

Review IAM permissions
GitBook Assistant

Folder Viewer
GitBook Assistant

Access nested folders
GitBook Assistant

Cloud Functions Viewer
GitBook Assistant

Inspect functions
GitBook Assistant

Private Logs Viewer
GitBook Assistant

Access restricted logs
GitBook Assistant

Viewer
GitBook Assistant

Optional for future compatibility
GitBook Assistant
#### Permissions and organizational struct:[#permissions-and-organizational-struct](#permissions-and-organizational-struct)

Entro assesses permissions linked to Non-Human Identities (NHIs), analyzes stored secrets, and identifies potential NHI owners. This process involves listing permissions for all Google Cloud Platform (GCP) assets and accessing the organizational structure.
GitBook Assistant
#### Excessive permissions analysis:[#excessive-permissions-analysis](#excessive-permissions-analysis)

Entro leverages GCP's existing iam policy recommendation to diff between used and unused permissions.
GitBook Assistant
#### Last usage timestamp of NHIs:[#last-usage-timestamp-of-nhis](#last-usage-timestamp-of-nhis)

Determine the last usage timestamp of Service accounts, and their keys.
GitBook Assistant
#### Secrets Manager :[#secrets-manager](#secrets-manager)

Management of NHIs and secrets stored within the "Secret Manager." It monitors and mitigates potential threats, misuse attempts, and unauthorized access.
GitBook Assistant
#### GCP Functions scanning :[#gcp-functions-scanning](#gcp-functions-scanning)

Find cleartext secrets within GCP Functions env-vars.
GitBook Assistant
#### Service accounts management (NHI) :[#service-accounts-management-nhi](#service-accounts-management-nhi)

#### Audit logs, metrics access:[#audit-logs-metrics-access](#audit-logs-metrics-access)

Entro collects audit logs from relevant services, focusing on both human and non-human identities as actors or targets. It is also used to identify potential 'owners' of Entro assets.
GitBook Assistant
#### Google AI Agents:[#google-ai-agents](#google-ai-agents)

Support for Agentic AI Discovery in the Google eco-system. Linking between AI Clients and data sources they're connected to.
GitBook Assistant

Optional Roles
GitBook Assistant

- 

Support User (general read-only) for extended visibility.
GitBook Assistant

Compliance & Security
GitBook Assistant

- 

TLS 1.2+ encryption
GitBook Assistant
- 

AES-256 token protection
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR
GitBook Assistant
[PreviousGCP Troubleshooting And Validation](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-troubleshooting-and-validation)[NextHashiCorp Vault](/integrations/cloud-and-infrastructure/hashicorp-vault)

Last updated 4 months ago

- [Required APIs](#required-apis)
- [Required Roles](#required-roles)
GitBook AssistantAskCopy
```
"iam.roles.list",
"iam.roles.get",
"resourcemanager.organizations.getIamPolicy",
"resourcemanager.projects.getIamPolicy",
"resourcemanager.folders.getIamPolicy",
"resourcemanager.folders.get"
"resourcemanager.organizations.get",
"resourcemanager.projects.get",
"resourcemanager.projects.list",
"cloudasset.assets.listResource",
"cloudasset.assets.listIamPolicy",
"cloudasset.assets.listOrgPolicy",
"cloudasset.assets.listAccessPolicy",
"cloudasset.assets.listOSInventories",
"iam.serviceAccounts.getIamPolicy",
"secretmanager.secrets.getIamPolicy",
```
GitBook AssistantAskCopy
```
"recommender.iamPolicyInsights.get",
"recommender.iamPolicyInsights.list",
"recommender.iamPolicyLateralMovementInsights.get",
"recommender.iamPolicyLateralMovementInsights.list",
"recommender.iamPolicyRecommendations.get",
"recommender.iamPolicyRecommendations.list",
"recommender.iamPolicyRecommenderConfig.get",
"recommender.iamServiceAccountInsights.get",
"recommender.iamServiceAccountInsights.list",
"recommender.locations.get",
"recommender.locations.list",
"recommender.cloudAssetInsights.get",
"recommender.cloudAssetInsights.list",
```
GitBook AssistantAskCopy
```
"policyanalyzer.serviceAccountKeyLastAuthenticationActivities.query",
"policyanalyzer.serviceAccountLastAuthenticationActivities.query",
```
GitBook AssistantAskCopy
```
"secretmanager.versions.access", //optional
"secretmanager.secrets.list",
"secretmanager.versions.list",
"secretmanager.locations.list",
```
GitBook AssistantAskCopy
```
"cloudfunctions.functions.get",
"cloudfunctions.functions.list",
"cloudbuild.builds.get",
"cloudbuild.builds.list",
"cloudbuild.operations.get",
"cloudbuild.operations.list",
```
GitBook AssistantAskCopy
```
"iam.serviceAccounts.list",
"iam.serviceAccounts.get",
"iam.serviceAccountKeys.get",
"iam.serviceAccountKeys.list",
```
GitBook AssistantAskCopy
```
"logging.buckets.get",
"logging.buckets.list",
"logging.exclusions.get",
"logging.exclusions.list",
"logging.links.get",
"logging.links.list",
"logging.locations.get",
"logging.locations.list",
"logging.logEntries.download",
"logging.logEntries.list",
"logging.logMetrics.get",
"logging.logMetrics.list",
"logging.logServiceIndexes.list",
"logging.logServices.list",
"logging.logs.list",
"logging.operations.get",
"logging.operations.list",
"logging.privateLogEntries.list",
"logging.queries.create",
"logging.queries.delete",
"logging.queries.get",
"logging.queries.list",
"logging.queries.listShared",
"logging.queries.update",
"logging.sinks.get",
"logging.sinks.list",
"logging.usage.get",
"logging.views.access",
"logging.views.get",
"logging.views.list",
"logging.views.listLogs",
"logging.views.listResourceKeys",
"logging.views.listResourceValues",
"serviceusage.quotas.get",
"serviceusage.services.get",
"serviceusage.services.list",
```
GitBook AssistantAskCopy
```
"discoveryengine.dataStores.list",
"discoveryengine.dataStores.get",
"discoveryengine.engines.list",
"discoveryengine.engines.get"
```
