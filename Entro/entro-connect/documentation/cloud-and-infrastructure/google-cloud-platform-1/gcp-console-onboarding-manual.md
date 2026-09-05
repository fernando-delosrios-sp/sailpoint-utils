GCP Console Onboarding (Manual) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual.md).1
#### Create a Service Account[#create-a-service-account](#create-a-service-account)

[Create a service account](https://console.cloud.google.com/iam-admin/serviceaccounts/create) in any project within your GCP organization.
GitBook Assistant2
#### Choose an authorization method[#choose-an-authorization-method](#choose-an-authorization-method)

Choose one of the following authorization methods:
GitBook Assistant

1. 

[Create a **Service Account Key**](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#create-a-service-account) for the created service account, select “JSON” key type. *or*
GitBook Assistant
1. 

Allow Entro's dedicated AWS role to **impersonate this service account**. Follow [these steps](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-workload-identity-federation) to **enable impersonation** via GCP's "Workload Identity Federation" guide​
GitBook Assistant
3
#### [Assign roles](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#assign-roles-for-entros-service-account) for Entro's Service Account[#assign-roles-for-entros-service-account](#assign-roles-for-entros-service-account)

Grant Entro Service Account, in a **organization, folder** or **specific project** scope.
GitBook Assistant4
#### Enable APIs on [all GCP Projects](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#enable-required-apis) or on [host-project only](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#limited-api-permissions-appendix)[#enable-apis-on-all-gcp-projects-or-on-host-project-only](#enable-apis-on-all-gcp-projects-or-on-host-project-only)

To maintain Entro's reachability, certain APIs must be enabled on all projects in the organization. This can be done via CLI script or [Terraform](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated), see [**Enabled Required APIs**](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#enable-required-apis) below.
GitBook Assistant5
#### [Enable audit logs](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual#audit-logs)[#enable-audit-logs](#enable-audit-logs)
6
#### Complete onboarding in Entro portal[#complete-onboarding-in-entro-portal](#complete-onboarding-in-entro-portal)

### Create a service account[#create-a-service-account-1](#create-a-service-account-1)

[Click on this link](https://console.cloud.google.com/iam-admin/serviceaccounts/create) to create a service account in you GCP Portal. Permissions should be set later with your desired scope (project, folder or organization).
GitBook Assistant
### Create a Service Account Key[#create-a-service-account-key](#create-a-service-account-key)

To create a new key for your service account:
GitBook Assistant

1. 

Click on the service account to open its settings.
GitBook Assistant
1. 

Navigate to the **Keys** tab.
GitBook Assistant
1. 

Click **Add Key** and choose **Create new key** from the dropdown.
GitBook Assistant
1. 

Ensure the **JSON** option is selected.
GitBook Assistant
1. 

Click **Create**.
GitBook Assistant

### Enable Required APIs[#enable-required-apis](#enable-required-apis)

Run the following commands in Cloud Shell to enable required APIs across all GCP projects.
GitBook Assistant

**Which APIs are enabled by default?** **Often already enabled** in existing projects: `cloudresourcemanager.googleapis.com`, `iam.googleapis.com`, `logging.googleapis.com`. You can try enabling only the others first; enable these if you see permission/not-enabled errors.
GitBook Assistant

**Usually not enabled** and typically need to be turned on: `recommender.googleapis.com`, `cloudasset.googleapis.com` , `apikeys.googleapis.com,`
GitBook Assistant

**Enabled when used** and typically no need to be turned on manually: `secretmanager.googleapis.com`, `cloudfunctions.googleapis.com` .
GitBook AssistantOption 1 - All Projects, All OrgsOption 2 - All Projects, Single OrgOption 3 - Host Project only (Minimum APIs)

After running the previous script according to the desired scope, make sure to also enable those APIs on Entro's hosting project.
GitBook Assistant

Replace the project ID with the ID of the hosting project `<host project id>` :
GitBook Assistant
### Organization Roles[#organization-roles](#organization-roles)

1. 

Navigate to [IAM](https://console.cloud.google.com/iam-admin/iam) within your project, folder, or organization and click **Grant access**.
GitBook Assistant
1. 

Select the newly created Entro service account from the previous step.
GitBook Assistant
1. 

Assign the required role (details below).
GitBook Assistant
1. 

Click **Save** to apply changes.
GitBook Assistant

**Assign these read-only role at the organization level to the Service Account (Recommended for future compatibility):**
GitBook Assistant

- 

Support User
GitBook Assistant
- 

Private Logs Viewer
GitBook Assistant

**Or cherry-pick these roles (Least Privilege)**
GitBook Assistant

- 

Logs Viewer
GitBook Assistant
- 

Logs View Accessor
GitBook Assistant
- 

Private Logs Viewer
GitBook Assistant
- 

Organization Viewer
GitBook Assistant
- 

Secret Manager Viewer
GitBook Assistant
- 

View Service Accounts
GitBook Assistant
- 

Cloud Functions Viewer
GitBook Assistant
- 

IAM Recommender Viewer
GitBook Assistant
- 

Cloud Asset Viewer
GitBook Assistant
- 

Activity Analysis Viewer
GitBook Assistant
- 

Organization Role Viewer
GitBook Assistant
- 

Security Reviewer
GitBook Assistant
- 

Folder Viewer
GitBook Assistant
- 

API Keys Viewer
GitBook Assistant
- 

Secret Manager Secret Accessor
GitBook Assistant
- 

Discovery Engine Viewer
GitBook Assistant

### Audit Logs[#audit-logs](#audit-logs)

To ensure Entro's validation and anomaly detection, follow these steps:
GitBook Assistant

1. 

Navigate to the [**Audit Logs**](https://console.cloud.google.com/iam-admin/audit) page in the GCP Portal, selecting your preferred scope (project, folder, or organization).
GitBook Assistant
1. 

Filter for the following services using the OR condition:
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

1. 

Select the checkboxes for these services.
GitBook Assistant
1. 

Set their Permission types to:
GitBook Assistant

- 

Admin read
GitBook Assistant
- 

Data read
GitBook Assistant
- 

Data write
GitBook Assistant

1. 

Click **Save**.
GitBook Assistant

## Limited API Permissions (Appendix)[#limited-api-permissions-appendix](#limited-api-permissions-appendix)

If you would like to restrict access for certain APIs, you can use **limited manual onboarding**: enable only the APIs on the project that hosts Entro's service account (no org-wide API enablement). Some functionality will be lost.
GitBook Assistant
### What you get with limited onboarding[#what-you-get-with-limited-onboarding](#what-you-get-with-limited-onboarding)

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
### APIs: enable on the host project only (limited onboarding)[#apis-enable-on-the-host-project-only-limited-onboarding](#apis-enable-on-the-host-project-only-limited-onboarding)

Enable APIs **only on the project that hosts Entro's service account**. Not all of these are required—only the **core** set is needed for the backend; the rest are for **agent-driven features** (IAM analysis, Recommender, Cloud Functions scan, etc.). When enabled only on the host project, those agent features only run for the host project.
GitBook AssistantAPIUsed byRequired?

**cloudresourcemanager.googleapis.com**
GitBook Assistant

project discovery, org resolution
GitBook Assistant

**Yes**
GitBook Assistant

**iam.googleapis.com**
GitBook Assistant

NHI Enumeration (service account/key checks, archive flow)
GitBook Assistant

**Yes**
GitBook Assistant

**logging.googleapis.com**
GitBook Assistant

Activity monitoring
GitBook Assistant

**Yes**
GitBook Assistant

**secretmanager.googleapis.com**
GitBook Assistant

Backend (list/read secrets)
GitBook Assistant

Yes if you use Secret Manager (Usually switches on automatically)
GitBook Assistant

**cloudfunctions.googleapis.com**
GitBook Assistant

Cloud Functions exposed-secrets scan
GitBook Assistant

Only if you want CF scanning
GitBook Assistant

**recommender.googleapis.com**
GitBook Assistant

IAM Permissions Recommender insights
GitBook Assistant

Only if you want permissions recommender data
GitBook Assistant

**cloudasset.googleapis.com**
GitBook Assistant

Resources, hierarchy
GitBook Assistant

Yes
GitBook Assistant

**pubsub.googleapis.com**
GitBook Assistant

Alternative audit logs ingestion
GitBook Assistant

No
GitBook Assistant

**admin.googleapis.com**
GitBook Assistant

Google Workspace users enumeration
GitBook Assistant

No
GitBook Assistant

**drive.googleapis.com**
GitBook Assistant

Google Drive exposed secrets scanning
GitBook Assistant

No
GitBook Assistant

**Minimum (Project scope):**
GitBook Assistant

**Full set (Project scope):**
GitBook Assistant[PreviousGCP Pre Onboarding Check](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-pre-onboarding-check)[NextGCP Workload Identity Federation (Manual)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual/gcp-workload-identity-federation-manual)

Last updated 2 months ago

- [Create a service account](#create-a-service-account-1)
- [Create a Service Account Key](#create-a-service-account-key)
- [Enable Required APIs](#enable-required-apis)
- [Organization Roles](#organization-roles)
- [Audit Logs](#audit-logs)
- [Limited API Permissions (Appendix)](#limited-api-permissions-appendix)
- [What you get with limited onboarding](#what-you-get-with-limited-onboarding)
- [What you'll miss](#what-youll-miss)
- [APIs: enable on the host project only (limited onboarding)](#apis-enable-on-the-host-project-only-limited-onboarding)
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
  cloudfunctions.googleapis.com \
  recommender.googleapis.com \
  policyanalyzer.googleapis.com \
  cloudasset.googleapis.com \
  pubsub.googleapis.com \
  apikeys.googleapis.com \
  admin.googleapis.com \
  drive.googleapis.com \
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
  apikeys.googleapis.com \
  admin.googleapis.com \
  drive.googleapis.com \
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
  cloudasset.googleapis.com \
  pubsub.googleapis.com \
  admin.googleapis.com \
  drive.googleapis.com \
  --project="$PROJECT_ID"
```
