GCP permissions reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-permissions-reference.md).

This page lists all IAM roles and APIs required for Entro's GCP integration, organized by feature area. All access is read-only.
GitBook Assistant
## Required APIs[#required-apis](#required-apis)

Enable these APIs across all projects using the scripts in the Console Onboarding guide.
GitBook AssistantAPIPurposeRequired?

`cloudresourcemanager.googleapis.com`
GitBook Assistant

Project discovery and org resolution
GitBook Assistant

**Mandatory**
GitBook Assistant

`iam.googleapis.com`
GitBook Assistant

NHI enumeration (service account and key checks)
GitBook Assistant

**Mandatory**
GitBook Assistant

`logging.googleapis.com`
GitBook Assistant

Audit log access for NHI activity tracking
GitBook Assistant

**Mandatory**
GitBook Assistant

`cloudasset.googleapis.com`
GitBook Assistant

Resource and hierarchy discovery
GitBook Assistant

**Mandatory**
GitBook Assistant

`recommender.googleapis.com`
GitBook Assistant

IAM Permissions Recommender — last-used timestamps and excessive permission analysis
GitBook Assistant

**Mandatory**
GitBook Assistant

`policyanalyzer.googleapis.com`
GitBook Assistant

Last authentication timestamp for service account keys
GitBook Assistant

**Mandatory**
GitBook Assistant

`apikeys.googleapis.com`
GitBook Assistant

API key discovery and correlation
GitBook Assistant

**Mandatory** for API key visibility
GitBook Assistant

`secretmanager.googleapis.com`
GitBook Assistant

Secrets management (list/read secrets)
GitBook Assistant

**Mandatory** if using Secret Manager
GitBook Assistant

`cloudfunctions.googleapis.com`
GitBook Assistant

Cloud Functions exposed-secrets scan
GitBook Assistant

Optional
GitBook Assistant

`pubsub.googleapis.com`
GitBook Assistant

Alternative audit log ingestion via PubSub
GitBook Assistant

Optional
GitBook Assistant

`discoveryengine.googleapis.com`
GitBook Assistant

Google AI Agents discovery
GitBook Assistant

Optional
GitBook Assistant

`admin.googleapis.com` (Admin SDK)
GitBook Assistant

Auto-scan all Google Drive instances
GitBook Assistant

Optional
GitBook Assistant

`drive.googleapis.com` (Google Drive API)
GitBook Assistant

Google Workspace Directory and Drive secrets scanning
GitBook Assistant

Optional
GitBook Assistant

`cloudidentity.googleapis.com` (Cloud Identity API)
GitBook Assistant

Identity metadata
GitBook Assistant

Optional
GitBook Assistant
## Required IAM Roles[#required-iam-roles](#required-iam-roles)

Assign these roles at the **organization level** for full coverage, or at folder/project level for scoped access.
GitBook Assistant

**Quickest path:** Assign `roles/viewer` (Viewer) at the organization level. This single role covers most of the required permissions and ensures forward compatibility as Entro adds capabilities.
GitBook Assistant
### Core Roles (Required)[#core-roles-required](#core-roles-required)
RolePurpose

Logs Viewer
GitBook Assistant

View audit log entries
GitBook Assistant

Logs View Accessor
GitBook Assistant

Access log views
GitBook Assistant

Private Logs Viewer
GitBook Assistant

Access restricted log entries
GitBook Assistant

Organization Viewer
GitBook Assistant

Access org-wide metadata
GitBook Assistant

Cloud Asset Viewer
GitBook Assistant

List GCP assets for audit
GitBook Assistant

IAM Recommender Viewer
GitBook Assistant

Review IAM recommendations
GitBook Assistant

Security Reviewer
GitBook Assistant

Review IAM permissions
GitBook Assistant

Folder Viewer
GitBook Assistant

Access folder hierarchy
GitBook Assistant

Organization Role Viewer
GitBook Assistant

View custom IAM roles
GitBook Assistant

Activity Analysis Viewer
GitBook Assistant

Last-used timestamp for NHIs
GitBook Assistant

View Service Accounts (`iam.serviceAccounts.list`)
GitBook Assistant

List and inspect service accounts
GitBook Assistant
### Optional Roles (Feature-Dependent)[#optional-roles-feature-dependent](#optional-roles-feature-dependent)
RolePurpose

Secret Manager Viewer
GitBook Assistant

List secrets and metadata
GitBook Assistant

Secret Manager Secret Accessor
GitBook Assistant

Read secret values
GitBook Assistant

Cloud Functions Viewer
GitBook Assistant

Inspect Cloud Functions for exposed secrets
GitBook Assistant

API Keys Viewer
GitBook Assistant

Access API key metadata
GitBook Assistant

Discovery Engine Viewer
GitBook Assistant

Google AI agent discovery
GitBook Assistant

Viewer (`roles/viewer`)
GitBook Assistant

Broad read-only access — recommended for simplicity
GitBook Assistant
## Permissions Detail by Feature[#permissions-detail-by-feature](#permissions-detail-by-feature)

### Identity & Access Management[#identity-and-access-management](#identity-and-access-management)

Entro lists permissions for all GCP assets and reads the organizational structure to assess NHIs.
GitBook Assistant
### Excessive Permissions Analysis[#excessive-permissions-analysis](#excessive-permissions-analysis)

Entro leverages GCP's IAM Policy Recommender to identify unused permissions.
GitBook Assistant
### NHI Last-Used Timestamp[#nhi-last-used-timestamp](#nhi-last-used-timestamp)

Determines when service accounts and their keys were last used.
GitBook Assistant
### Secret Manager[#secret-manager](#secret-manager)

Lists and monitors secrets stored in GCP Secret Manager.
GitBook Assistant
### Cloud Functions Scanning[#cloud-functions-scanning](#cloud-functions-scanning)

Finds cleartext secrets in Cloud Functions environment variables.
GitBook Assistant
### Service Account Management (NHI)[#service-account-management-nhi](#service-account-management-nhi)

### Audit Logs & Metrics[#audit-logs-and-metrics](#audit-logs-and-metrics)

Entro collects audit logs from relevant GCP services to identify both human and non-human identity activity, and to detect potential NHI owners.
GitBook Assistant
### Google AI Agents[#google-ai-agents](#google-ai-agents)

Supports Agentic AI discovery within the Google ecosystem — links AI clients to the data sources they access.
GitBook Assistant
## Compliance & Security[#compliance-and-security](#compliance-and-security)
PropertyDetail

Access type
GitBook Assistant

Read-only — no data is written or modified
GitBook Assistant

Transport
GitBook Assistant

TLS 1.2+
GitBook Assistant

Token encryption
GitBook Assistant

AES-256
GitBook Assistant

Certifications
GitBook Assistant

SOC 2 Type II · ISO 27001 · GDPR
GitBook Assistant

Last updated 4 months ago

- [Required APIs](#required-apis)
- [Required IAM Roles](#required-iam-roles)
- [Core Roles (Required)](#core-roles-required)
- [Optional Roles (Feature-Dependent)](#optional-roles-feature-dependent)
- [Permissions Detail by Feature](#permissions-detail-by-feature)
- [Identity & Access Management](#identity-and-access-management)
- [Excessive Permissions Analysis](#excessive-permissions-analysis)
- [NHI Last-Used Timestamp](#nhi-last-used-timestamp)
- [Secret Manager](#secret-manager)
- [Cloud Functions Scanning](#cloud-functions-scanning)
- [Service Account Management (NHI)](#service-account-management-nhi)
- [Audit Logs & Metrics](#audit-logs-and-metrics)
- [Google AI Agents](#google-ai-agents)
- [Compliance & Security](#compliance-and-security)
GitBook AssistantAskCopy
```
iam.roles.list
iam.roles.get
resourcemanager.organizations.getIamPolicy
resourcemanager.projects.getIamPolicy
resourcemanager.folders.getIamPolicy
resourcemanager.folders.get
resourcemanager.organizations.get
resourcemanager.projects.get
resourcemanager.projects.list
cloudasset.assets.listResource
cloudasset.assets.listIamPolicy
cloudasset.assets.listOrgPolicy
cloudasset.assets.listAccessPolicy
cloudasset.assets.listAccessPolicies
iam.serviceAccounts.getIamPolicy
secretmanager.secrets.getIamPolicy
```
GitBook AssistantAskCopy
```
recommender.iamPolicyInsights.get
recommender.iamPolicyInsights.list
recommender.iamPolicyLateralMovementInsights.get
recommender.iamPolicyLateralMovementInsights.list
recommender.iamPolicyRecommendations.get
recommender.iamPolicyRecommendations.list
recommender.iamPolicyRecommenderConfig.get
recommender.iamServiceAccountInsights.get
recommender.iamServiceAccountInsights.list
recommender.locations.get
recommender.locations.list
recommender.cloudAssetInsights.get
recommender.cloudAssetInsights.list
```
GitBook AssistantAskCopy
```
policyanalyzer.serviceAccountKeyLastAuthenticationActivities.query
policyanalyzer.serviceAccountLastAuthenticationActivities.query
```
GitBook AssistantAskCopy
```
secretmanager.versions.access    # Optional — only if reading secret values
secretmanager.secrets.list
secretmanager.versions.list
secretmanager.locations.list
```
GitBook AssistantAskCopy
```
cloudfunctions.functions.get
cloudfunctions.functions.list
cloudbuild.builds.get
cloudbuild.builds.list
cloudbuild.operations.get
cloudbuild.operations.list
```
GitBook AssistantAskCopy
```
iam.serviceAccounts.list
iam.serviceAccounts.get
iam.serviceAccountKeys.get
iam.serviceAccountKeys.list
```
GitBook AssistantAskCopy
```
logging.buckets.get
logging.buckets.list
logging.logEntries.list
logging.logEntries.download
logging.logs.list
logging.logMetrics.get
logging.logMetrics.list
logging.privateLogEntries.list
logging.sinks.get
logging.sinks.list
logging.views.access
logging.views.get
logging.views.list
logging.views.listLogs
serviceusage.services.get
serviceusage.services.list
```
GitBook AssistantAskCopy
```
discoveryengine.dataStores.list
discoveryengine.dataStores.get
discoveryengine.engines.list
discoveryengine.engines.get
```
