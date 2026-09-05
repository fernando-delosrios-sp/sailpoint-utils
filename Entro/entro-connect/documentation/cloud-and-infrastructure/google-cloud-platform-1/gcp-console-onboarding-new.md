GCP Console Onboarding - New | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-new.md).
## 1. Create a Service Account[#id-1.-create-a-service-account](#id-1.-create-a-service-account)

Create a service account in any project within your GCP organization.
GitBook Assistant
## 2. Choose an authorization method[#id-2.-choose-an-authorization-method](#id-2.-choose-an-authorization-method)

Choose one of the following authorization methods:
GitBook Assistant1
#### Create a Service Account Key[#create-a-service-account-key](#create-a-service-account-key)

Create a **Service Account Key** for the created service account, select **JSON** key type.
GitBook Assistant2
#### Impersonation via Workload Identity Federation[#impersonation-via-workload-identity-federation](#impersonation-via-workload-identity-federation)

Allow Entro's dedicated AWS role to **impersonate this service account**. Follow the steps to enable impersonation via GCP's [Workload Identity Federation](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-workload-identity-federation) guide.
GitBook Assistant
## 3. Update new projects with the required APIs[#id-3.-update-new-projects-with-the-required-apis](#id-3.-update-new-projects-with-the-required-apis)

To maintain Entro's reachability, certain APIs must be enabled on all projects in the organization. Without these APIs, Entro won't be able to find resources. To make sure new projects are reachable, you must ensure the APIs specified below are enabled in the new projects.
GitBook Assistant
## Enable Required APIs[#enable-required-apis](#enable-required-apis)

Run the following commands in Cloud Shell to enable required APIs across all GCP projects.
GitBook Assistant

**Optional APIs** The following APIs are optional. You may remove them from the script if you do not require these features. Enabling these APIs may incur standard GCP usage fees.
GitBook Assistant

- 

`**secretmanager.googleapis.com**` – Remove this if you do not use Secret Manager or do not want Entro to analyze your secret details. (Note: Entro reads metadata only and does not access secret values.)
GitBook Assistant
- 

`**cloudfunctions.googleapis.com**` – Remove this if you do not want Entro scanning your Cloud Functions for secret exposure.
GitBook Assistant
Option 1 - All Projects, All OrgsOption 2 - All Projects, Single Org
## Host project: enable required APIs for Entro's service account[#host-project-enable-required-apis-for-entros-service-account](#host-project-enable-required-apis-for-entros-service-account)

Get the project ID hosting Entro's service account (the **main project** where the Entro SA is created), and enable these APIs. The backend uses the first four; the rest are used by agents (IAM analysis, Recommender, Cloud Functions scan, etc.).
GitBook AssistantAPIUsed byRequired?

**cloudresourcemanager.googleapis.com**
GitBook Assistant

Backend (project discovery, org resolution)
GitBook Assistant

**Yes**
GitBook Assistant

**iam.googleapis.com**
GitBook Assistant

Backend (service account/key checks, archive flow)
GitBook Assistant

**Yes**
GitBook Assistant

**logging.googleapis.com**
GitBook Assistant

Backend ("is active" checks, log entries)
GitBook Assistant

**Yes**
GitBook Assistant

**secretmanager.googleapis.com**
GitBook Assistant

Backend (list/read secrets)
GitBook Assistant

Yes if you use Secret Manager
GitBook Assistant

**cloudfunctions.googleapis.com**
GitBook Assistant

Agent (Cloud Functions exposed-secrets scan)
GitBook Assistant

Only if you want CF scanning
GitBook Assistant

**recommender.googleapis.com**
GitBook Assistant

Agent (IAM Recommender insights)
GitBook Assistant

Only if you want recommender data
GitBook Assistant

**policyanalyzer.googleapis.com**
GitBook Assistant

Agent (IAM Policy Analyzer)
GitBook Assistant

Only if you want IAM policy analysis
GitBook Assistant

**cloudasset.googleapis.com**
GitBook Assistant

Agent (asset inventory / analysis)
GitBook Assistant

Only if you want asset-based features
GitBook Assistant

**pubsub.googleapis.com**
GitBook Assistant

Agent (notifications / job delivery)
GitBook Assistant

Often needed for agent pipeline
GitBook Assistant

**cloudidentity.googleapis.com**
GitBook Assistant

UI / labels only (not backend)
GitBook Assistant

Optional
GitBook Assistant

**Minimum (backend only):**
GitBook Assistant

**Full set (backend + agent features):**
GitBook Assistant
## Organization Roles[#organization-roles](#organization-roles)

Add these roles at the **organization level** to the Service Account:
GitBook AssistantRole

Logs Viewer
GitBook Assistant

Logs View Accessor
GitBook Assistant

Private Logs Viewer
GitBook Assistant

Organization Viewer
GitBook Assistant

Secret Manager Viewer
GitBook Assistant

View Service Accounts
GitBook Assistant

Cloud Functions Viewer
GitBook Assistant

IAM Recommender Viewer
GitBook Assistant

Cloud Asset Viewer
GitBook Assistant

Activity Analysis Viewer
GitBook Assistant

Organization Role Viewer
GitBook Assistant

Security Reviewer
GitBook Assistant

Folder Viewer
GitBook Assistant

API Keys Viewer
GitBook Assistant

Secret Manager Secret Accessor
GitBook Assistant

Discovery Engine Viewer
GitBook Assistant

Viewer (optional) / Support User (optional)
GitBook Assistant
## Audit Logs[#audit-logs](#audit-logs)

Enable logging for these required services:
GitBook Assistant

- 

**Secret Manager API**
GitBook Assistant
- 

**Cloud Functions API**
GitBook Assistant
- 

**Identity and Access Management (IAM) API**
GitBook Assistant

These logs are mandatory for Entro's validation and anomaly detection.
GitBook Assistant
## Limited Permissions / Manual Onboarding[#limited-permissions-manual-onboarding](#limited-permissions-manual-onboarding)

If you would like to restrict access for certain APIs, you can use **manual onboarding**: enable only the APIs on the project that hosts Entro's service account (no org-wide API enablement). Some functionality will be lost.
GitBook Assistant
### What you get with manual onboarding[#what-you-get-with-manual-onboarding](#what-you-get-with-manual-onboarding)

- 

**Project discovery** (add child accounts), **Secret Manager** (metadata + values), **Cloud Functions** (exposed-secrets scan), **logs** (viewer), **IAM** (service account viewer, policy/recommender/asset for agents), and **Activity Analysis**.
GitBook Assistant
- 

All of this works with the **minimal role set** listed below, with APIs enabled only on the **host project** (the project where the Entro service account is created).
GitBook Assistant

### What you'll miss[#what-youll-miss](#what-youll-miss)

With manual onboarding (APIs only on the host project, minimal roles), the following are **not** supported:
GitBook Assistant

1. 

**Google API Keys discovery, management, and correlation** Requires `apikeys.googleapis.com` and API Keys Viewer (and optional org-wide API enablement) on every project where you want API key visibility.
GitBook Assistant
1. 

**Project-level human ownership attribution for Service Accounts** Full ownership attribution uses agent-driven flows and extra data; with minimal setup you won't get project-level human ownership for service accounts.
GitBook Assistant

If you need these features, use the full onboarding (org-wide API enablement and the full organization roles list above).
GitBook Assistant
### APIs: enable on the host project only (manual onboarding)[#apis-enable-on-the-host-project-only-manual-onboarding](#apis-enable-on-the-host-project-only-manual-onboarding)

Enable APIs **only on the project that hosts Entro's service account**. Not all of these are required—only the **core** set is needed for the backend; the rest are for **agent-driven features** (IAM analysis, Recommender, Cloud Functions scan, etc.). When enabled only on the host project, those agent features only run for the host project.
GitBook AssistantAPIUsed byRequired?

**cloudresourcemanager.googleapis.com**
GitBook Assistant

Backend (project discovery, org resolution)
GitBook Assistant

**Yes**
GitBook Assistant

**iam.googleapis.com**
GitBook Assistant

Backend (service account/key checks, archive flow)
GitBook Assistant

**Yes**
GitBook Assistant

**logging.googleapis.com**
GitBook Assistant

Backend ("is active" checks, log entries)
GitBook Assistant

**Yes**
GitBook Assistant

**secretmanager.googleapis.com**
GitBook Assistant

Backend (list/read secrets)
GitBook Assistant

Yes if you use Secret Manager
GitBook Assistant

**cloudfunctions.googleapis.com**
GitBook Assistant

Agent (Cloud Functions exposed-secrets scan)
GitBook Assistant

Only if you want CF scanning
GitBook Assistant

**recommender.googleapis.com**
GitBook Assistant

Agent (IAM Recommender insights → S3)
GitBook Assistant

Only if you want recommender data
GitBook Assistant

**policyanalyzer.googleapis.com**
GitBook Assistant

Agent (IAM Policy Analyzer → S3)
GitBook Assistant

Only if you want IAM policy analysis
GitBook Assistant

**cloudasset.googleapis.com**
GitBook Assistant

Agent (asset inventory / analysis → S3)
GitBook Assistant

Only if you want asset-based features
GitBook Assistant

**pubsub.googleapis.com**
GitBook Assistant

Agent (notifications / job delivery)
GitBook Assistant

Often needed for agent pipeline
GitBook Assistant

**Minimum (backend only, no agent features):**
GitBook Assistant

**Full set (backend + agent features on host project):**
GitBook Assistant

**Optional (remove if you don't need the feature):**
GitBook Assistant

- 

`secretmanager.googleapis.com` – Omit if you don't use Secret Manager or don't want Entro to analyze secret metadata/values.
GitBook Assistant
- 

`cloudfunctions.googleapis.com` – Omit if you don't want Entro to scan Cloud Functions for secret exposure.
GitBook Assistant
- 

`recommender.googleapis.com`, `policyanalyzer.googleapis.com`, `cloudasset.googleapis.com`, `pubsub.googleapis.com` – Omit if you don't need agent-driven IAM/recommender/asset features (or accept they only work for the host project).
GitBook Assistant

**Which APIs are enabled by default?** **Often already enabled** in existing projects: `cloudresourcemanager.googleapis.com`, `iam.googleapis.com`, `logging.googleapis.com`. You can try enabling only the others first; enable these if you see permission/not-enabled errors.
GitBook Assistant

**Usually not enabled** and typically need to be turned on: `secretmanager.googleapis.com`, `cloudfunctions.googleapis.com`, `recommender.googleapis.com`, `policyanalyzer.googleapis.com`, `pubsub.googleapis.com`, `cloudasset.googleapis.com`.
GitBook Assistant

`cloudidentity.googleapis.com` is **not** required for the minimal backend flows (project list, secrets, logs, IAM). It is only referenced in the UI. You can omit it for manual/minimal onboarding.
GitBook Assistant
### Organization roles (minimal working set for manual onboarding)[#organization-roles-minimal-working-set-for-manual-onboarding](#organization-roles-minimal-working-set-for-manual-onboarding)

Assign these **organization-level** roles to the Entro service account. This set is the minimal known-good set (e.g. a service account such as `entro-test-sa@<project>.iam.gserviceaccount.com` with only these roles):
GitBook AssistantRolePurpose

**Activity Analysis Viewer (Beta)**
GitBook Assistant

Activity analysis data for the agent pipeline.
GitBook Assistant

**Cloud Asset Viewer**
GitBook Assistant

Asset inventory used by agents (e.g. IAM analysis).
GitBook Assistant

**Cloud Functions Viewer**
GitBook Assistant

List/inspect Cloud Functions for exposed-secrets scan.
GitBook Assistant

**IAM Recommender Viewer**
GitBook Assistant

Recommender insights (e.g. permission recommendations).
GitBook Assistant

**Logs View Accessor**
GitBook Assistant

Read log metadata.
GitBook Assistant

**Logs Viewer**
GitBook Assistant

Read log entries (e.g. "is active", token/secret access).
GitBook Assistant

**Private Logs Viewer**
GitBook Assistant

Access to private log buckets if used.
GitBook Assistant

**Secret Manager Viewer**
GitBook Assistant

List secrets and versions (metadata).
GitBook Assistant

**Secret Manager Secret Accessor**
GitBook Assistant

Read secret values (origin, rotation, CRC).
GitBook Assistant

**Security Reviewer**
GitBook Assistant

Security findings and reviewer data.
GitBook Assistant

**View Service Accounts**
GitBook Assistant

List and get service account details (tokens, archive flow).
GitBook Assistant

**Optional**, for full feature parity with the full onboarding list:
GitBook Assistant

- 

Organization Viewer, Organization Role Viewer, Folder Viewer
GitBook Assistant
- 

**API Keys Viewer** – Only needed if you want Google API Keys discovery, management, and correlation.
GitBook Assistant
- 

**Discovery Engine Viewer** – Only if you use Discovery Engine and want it in scope.
GitBook Assistant

### Audit logs (manual onboarding)[#audit-logs-manual-onboarding](#audit-logs-manual-onboarding)

Enable audit logging for the same services as in full onboarding:
GitBook Assistant

- 

Secret Manager API
GitBook Assistant
- 

Cloud Functions API
GitBook Assistant
- 

Identity and Access Management (IAM) API
GitBook Assistant

### Summary: manual onboarding[#summary-manual-onboarding](#summary-manual-onboarding)
ItemManual onboarding (minimal)

**APIs**
GitBook Assistant

Enable only on the **host project** (see list above).
GitBook Assistant

**Roles**
GitBook Assistant

Assign the organization roles in the table above to the Entro service account.
GitBook Assistant

**Not included**
GitBook Assistant

Google API Keys discovery/management/correlation; project-level human ownership attribution for Service Accounts.
GitBook Assistant

If you need those missing features, use the full GCP onboarding with org-wide API enablement and the full organization roles list.
GitBook Assistant

Last updated 4 months ago

- [1. Create a Service Account](#id-1.-create-a-service-account)
- [2. Choose an authorization method](#id-2.-choose-an-authorization-method)
- [3. Update new projects with the required APIs](#id-3.-update-new-projects-with-the-required-apis)
- [Enable Required APIs](#enable-required-apis)
- [Host project: enable required APIs for Entro's service account](#host-project-enable-required-apis-for-entros-service-account)
- [Organization Roles](#organization-roles)
- [Audit Logs](#audit-logs)
- [Limited Permissions / Manual Onboarding](#limited-permissions-manual-onboarding)
- [What you get with manual onboarding](#what-you-get-with-manual-onboarding)
- [What you'll miss](#what-youll-miss)
- [APIs: enable on the host project only (manual onboarding)](#apis-enable-on-the-host-project-only-manual-onboarding)
- [Organization roles (minimal working set for manual onboarding)](#organization-roles-minimal-working-set-for-manual-onboarding)
- [Audit logs (manual onboarding)](#audit-logs-manual-onboarding)
- [Summary: manual onboarding](#summary-manual-onboarding)
GitBook AssistantAskCopy
```
#!/usr/bin/env bash
set -u
NON_BILLING_SERVICES=(
  cloudresourcemanager.googleapis.com
  iam.googleapis.com
  apikeys.googleapis.com
  recommender.googleapis.com
)
BILLING_SERVICES=(
  discoveryengine.googleapis.com
  secretmanager.googleapis.com
  cloudfunctions.googleapis.com
)
for PROJECT_ID in $(gcloud projects list --format="value(projectId)"); do
  [[ -z "$PROJECT_ID" ]] && continue
  if [[ "$PROJECT_ID" == sys-* ]]; then
    continue
  fi
  echo "Enabling APIs for project: $PROJECT_ID"
  if [ ${#NON_BILLING_SERVICES[@]} -gt 0 ]; then
    ERROR_OUTPUT=""
    if ERROR_OUTPUT=$(gcloud services enable "${NON_BILLING_SERVICES[@]}" \
        --project="$PROJECT_ID" \
        2>&1); then
      echo "Enabled non-billing APIs for $PROJECT_ID"
    else
      RC=$?
      echo "Failed enabling non-billing APIs for $PROJECT_ID (exit code: $RC)"
      echo "$ERROR_OUTPUT" | head -n 200
    fi
  fi
  if [ ${#BILLING_SERVICES[@]} -gt 0 ]; then
    ERROR_OUTPUT=""
    if ERROR_OUTPUT=$(gcloud services enable "${BILLING_SERVICES[@]}" \
        --project="$PROJECT_ID" \
        2>&1); then
      echo "Enabled billing APIs for $PROJECT_ID"
    else
      RC=$?
      echo "Failed enabling billing APIs for $PROJECT_ID (exit code: $RC)"
      echo "$ERROR_OUTPUT" | head -n 200
    fi
  fi
done
echo "Done"
```
GitBook AssistantAskCopy
```
#!/usr/bin/env bash
set -u
ORG_ID="<your org id>"
NON_BILLING_SERVICES=(
  cloudresourcemanager.googleapis.com
  iam.googleapis.com
  apikeys.googleapis.com
  recommender.googleapis.com
)
BILLING_SERVICES=(
  discoveryengine.googleapis.com
  secretmanager.googleapis.com
  cloudfunctions.googleapis.com
)
gcloud asset search-all-resources \
  --scope="organizations/${ORG_ID}" \
  --asset-types="cloudresourcemanager.googleapis.com/Project" \
  --filter="state=ACTIVE" \
  --format="value(additionalAttributes.projectId)" |
while IFS= read -r PROJECT_ID; do
  [[ -z "$PROJECT_ID" ]] && continue
  if [[ "$PROJECT_ID" == sys-* ]]; then
    continue
  fi
  echo "Enabling APIs for project: $PROJECT_ID"
  if [ ${#NON_BILLING_SERVICES[@]} -gt 0 ]; then
    ERROR_OUTPUT=""
    if ERROR_OUTPUT=$(gcloud services enable "${NON_BILLING_SERVICES[@]}" \
        --project="$PROJECT_ID" \
        2>&1); then
      echo "Enabled non-billing APIs for $PROJECT_ID"
    else
      RC=$?
      echo "Failed enabling non-billing APIs for $PROJECT_ID (exit code: $RC)"
      echo "$ERROR_OUTPUT" | head -n 200
    fi
  fi
  if [ ${#BILLING_SERVICES[@]} -gt 0 ]; then
    ERROR_OUTPUT=""
    if ERROR_OUTPUT=$(gcloud services enable "${BILLING_SERVICES[@]}" \
        --project="$PROJECT_ID" \
        2>&1); then
      echo "Enabled billing APIs for $PROJECT_ID"
    else
      RC=$?
      echo "Failed enabling billing APIs for $PROJECT_ID (exit code: $RC)"
      echo "$ERROR_OUTPUT" | head -n 200
    fi
  fi
done
echo "Done"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host project id>"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  --project="$PROJECT_ID"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host project id>"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  cloudfunctions.googleapis.com \
  recommender.googleapis.com \
  policyanalyzer.googleapis.com \
  cloudasset.googleapis.com \
  pubsub.googleapis.com \
  cloudidentity.googleapis.com \
  --project="$PROJECT_ID"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host project id>"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  --project="$PROJECT_ID"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host project id>"
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  cloudfunctions.googleapis.com \
  recommender.googleapis.com \
  policyanalyzer.googleapis.com \
  cloudasset.googleapis.com \
  pubsub.googleapis.com \
  --project="$PROJECT_ID"
```
