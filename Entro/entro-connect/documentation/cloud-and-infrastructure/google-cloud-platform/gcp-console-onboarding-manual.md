GCP console onboarding manual | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-console-onboarding-manual.md).

This guide connects Entro to your GCP organization by creating a dedicated Service Account and granting it read-only access. All operations performed by Entro are read-only — no data is modified.
GitBook Assistant

**Estimated time:** 20–30 minutes **Navigation path in Entro:** Management → Accounts & Integrations → Add New Account → Google Cloud Platform
GitBook Assistant

**Run the pre-check first.** Before starting, run the [GCP Pre-Onboarding Check](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check) to verify your account has the access needed.
GitBook Assistant1
#### Step 1 - Create a Service Account[#step-1-create-a-service-account](#step-1-create-a-service-account)

1. 

In the GCP Console, go to **IAM & Admin → Service Accounts**.
GitBook Assistant
1. 

Select the **host project** - the project where the Entro service account will live. &#xNAN;*Tip: Use a dedicated shared-services project (e.g., *`*entro-security*`*) or an existing platform project. Avoid any project at risk of deletion.*
GitBook Assistant
1. 

Click **+ Create Service Account**.
GitBook Assistant
1. 

Give it a recognizable name, for example: `entro-integration`
GitBook Assistant
1. 

Click **Create and Continue** - skip optional role grants on this screen, you'll assign roles in Step 3.
GitBook Assistant
1. 

Click **Done**.
GitBook Assistant

📸 **Screenshot needed:** GCP Console → IAM & Admin → Service Accounts page, showing the **+ Create Service Account** button and an example service account in the list.
GitBook Assistant2
#### Step 2 - Choose an Authentication Method[#step-2-choose-an-authentication-method](#step-2-choose-an-authentication-method)

Choose **one** method. Use **Service Account Key** for simplicity, or **Workload Identity Federation** for a keyless, more secure setup.
GitBook AssistantOption A — Service Account KeyOption B — Workload Identity Federation (Keyless)

1. 

In the Service Accounts list, click on the service account you just created.
GitBook Assistant
1. 

Go to the **Keys** tab.
GitBook Assistant
1. 

Click **Add Key → Create new key**.
GitBook Assistant
1. 

Select **JSON** and click **Create**.
GitBook Assistant
1. 

Save the downloaded `.json` file - you will upload this to Entro in Step 6.
GitBook Assistant

📸 **Screenshot needed:** Service Account detail page showing the **Keys** tab with the **Add Key** dropdown open and **JSON** selected.
GitBook Assistant

Store this file securely. Anyone with access to it can impersonate the service account. Do not commit it to source control.
GitBook Assistant

Use this option to avoid storing a JSON key file entirely. Entro's AWS role will securely impersonate your GCP service account.
GitBook Assistant

Follow the Workload Identity Federation setup guide, then return here to continue with Step 3.
GitBook Assistant3
#### Step 3 - Assign IAM Roles to the Service Account[#step-3-assign-iam-roles-to-the-service-account](#step-3-assign-iam-roles-to-the-service-account)

Assign roles at the **organization**, **folder**, or **project** level depending on the scope of visibility you want Entro to have. Organization scope is recommended for full coverage.
GitBook Assistant

1. 

Navigate to **IAM & Admin → IAM** at your desired scope.
GitBook Assistant
1. 

Click **Grant Access**.
GitBook Assistant
1. 

In the **New principals** field, enter the service account email: `entro-integration@YOUR_PROJECT_ID.iam.gserviceaccount.com`
GitBook Assistant
1. 

Assign roles using one of the two options below.
GitBook Assistant
1. 

Click **Save**.
GitBook Assistant

📸 **Screenshot needed:** IAM page at organization scope showing the **Grant Access** button. Then a second screenshot of the **Grant Access** side panel with the service account email entered and a role selected.
GitBook AssistantRecommended — Single RoleLeast Privilege — Specific Roles

Assign this one role at the **organization level** for the broadest coverage and best forward compatibility:
GitBook AssistantRoleWhy

**Viewer** (`roles/viewer`)
GitBook Assistant

Broad read-only access across all GCP services
GitBook Assistant

The `Viewer` role is the simplest and most future-proof option. If your organization restricts broad viewer access, use the least-privilege set instead.
GitBook Assistant

Assign all of the following roles at the **organization level**:
GitBook AssistantRolePurpose

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

Secret Manager Viewer
GitBook Assistant

List secrets and metadata
GitBook Assistant

View Service Accounts
GitBook Assistant

List and inspect service accounts
GitBook Assistant

Cloud Functions Viewer
GitBook Assistant

Inspect Cloud Functions
GitBook Assistant

IAM Recommender Viewer
GitBook Assistant

Review IAM recommendations
GitBook Assistant

Cloud Asset Viewer
GitBook Assistant

List GCP assets
GitBook Assistant

Activity Analysis Viewer
GitBook Assistant

Last-used timestamp for NHIs
GitBook Assistant

Organization Role Viewer
GitBook Assistant

View custom IAM roles
GitBook Assistant

Security Reviewer
GitBook Assistant

Review IAM permissions
GitBook Assistant

Folder Viewer
GitBook Assistant

Access folder hierarchy
GitBook Assistant

API Keys Viewer
GitBook Assistant

Access API key metadata
GitBook Assistant

Secret Manager Secret Accessor
GitBook Assistant

Read secret values
GitBook Assistant

Discovery Engine Viewer
GitBook Assistant

Google AI agent discovery
GitBook Assistant

For the full permissions breakdown, see the GCP Permissions Reference.
GitBook Assistant4
#### Step 4 - Enable Required APIs[#step-4-enable-required-apis](#step-4-enable-required-apis)

Entro requires specific GCP APIs to be enabled across your projects. Choose the script that matches your environment.
GitBook Assistant

**Which script should I use?**
GitBook Assistant

- 

**Script A** — Use this for most organizations. Iterates all projects using `gcloud projects list`.
GitBook Assistant
- 

**Script B** — Use this if Script A misses projects due to complex folder hierarchies. Uses `gcloud asset search-all-resources` for complete coverage.
GitBook Assistant
- 

**Script C** — Use this for a minimal-footprint setup. Enables APIs on the host project only. See the [Limited Onboarding Appendix](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-console-onboarding-manual#limited-api-permissions-appendix) for trade-offs.
GitBook Assistant
Script A — All Projects (Standard)Script B — All Projects (Asset Search)Script C — Host Project Only (Limited)

Run in Cloud Shell or with `gcloud` configured for your onboarding user.
GitBook AssistantGitBook AssistantAskCopy
```
#!/usr/bin/env bash
set -u

NON_BILLING_SERVICES=(
  cloudresourcemanager.googleapis.com
  iam.googleapis.com
  apikeys.googleapis.com
  recommender.googleapis.com
  cloudasset.googleapis.com
  policyanalyzer.googleapis.com
)

BILLING_SERVICES=(
  discoveryengine.googleapis.com
  secretmanager.googleapis.com
  cloudfunctions.googleapis.com
)

for PROJECT_ID in $(gcloud projects list --format="value(projectId)"); do
  [[ -z "$PROJECT_ID" ]] && continue
  [[ "$PROJECT_ID" == sys-* ]] && continue

  echo "Enabling APIs for project: $PROJECT_ID"

  gcloud services enable "${NON_BILLING_SERVICES[@]}" \
    --project="$PROJECT_ID" 2>&1 || echo "Warning: some non-billing APIs failed for $PROJECT_ID"

  gcloud services enable "${BILLING_SERVICES[@]}" \
    --project="$PROJECT_ID" 2>&1 || echo "Warning: some billing APIs failed for $PROJECT_ID"
done

echo "Done"
```

Use this if Script A misses projects. Replace `<your-org-id>` with your GCP organization ID.
GitBook Assistant

Enables APIs only on the host project. Some features will not be available across the full org. See [Limited Onboarding Appendix](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-console-onboarding-manual#limited-api-permissions-appendix) for details.
GitBook Assistant

**Minimum set:**
GitBook Assistant

**Full set (host project only):**
GitBook Assistant

**Also Enable APIs on the Host Project**
GitBook Assistant

After running Script A or B above, **also run the following** on your host project specifically to ensure all APIs are available where the service account lives:
GitBook AssistantGitBook AssistantAskCopy
```
export PROJECT_ID="<host-project-id>"   # Replace with your host project ID

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
  --project="$PROJECT_ID"
```

**Already enabled in most projects:** `cloudresourcemanager.googleapis.com`, `iam.googleapis.com`, `logging.googleapis.com`. Run the script first - you only need to enable these manually if you see "API not enabled" errors.
GitBook Assistant

📸 **Screenshot needed:** Cloud Shell terminal showing the script running with "Enabling APIs for project: project-name" output lines scrolling.
GitBook Assistant5
#### Step 5 - Enable Audit Logs[#step-5-enable-audit-logs](#step-5-enable-audit-logs)

Audit logs allow Entro to detect usage patterns and anomalous activity across your NHIs.
GitBook Assistant

1. 

In the GCP Console, go to **IAM & Admin → Audit Logs**.
GitBook Assistant
1. 

Select your desired scope — **organization level is recommended** for full coverage.
GitBook Assistant
1. 

Using the filter, select all three of the following services:
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

1. 

For each selected service, enable all three **Permission types**:
GitBook Assistant

- 

✅ Admin Read
GitBook Assistant
- 

✅ Data Read
GitBook Assistant
- 

✅ Data Write
GitBook Assistant

1. 

Click **Save**.
GitBook Assistant

📸 **Screenshot needed:** Audit Logs page showing the three services (Secret Manager API, Cloud Functions API, IAM API) selected with all three permission type checkboxes (Admin Read, Data Read, Data Write) enabled.
GitBook Assistant

Without audit logs enabled, Entro cannot detect usage patterns or identify the human owners of NHIs. This step is required for full functionality.
GitBook Assistant6
#### Step 6 - Complete Onboarding in the Entro Portal[#step-6-complete-onboarding-in-the-entro-portal](#step-6-complete-onboarding-in-the-entro-portal)

1. 

In the Entro portal, go to **Management → Accounts & Integrations**.
GitBook Assistant
1. 

Click **Add New Account** (top right corner).
GitBook Assistant
1. 

Select **Google Cloud Platform**.
GitBook Assistant
1. 

Fill in the connection form:
GitBook Assistant

- 

**Organization Domain** — your GCP org domain (e.g., `yourcompany.com`)
GitBook Assistant
- 

**Authentication method** — choose **Service Account Key** or **Workload Identity Federation**
GitBook Assistant

- 

*Service Account Key:* upload the `.json` file downloaded in Step 2
GitBook Assistant
- 

*Workload Identity Federation:* upload the configuration file downloaded during WIF setup
GitBook Assistant

1. 

Click **Connect**.
GitBook Assistant
1. 

Entro will validate the connection. Once the status shows **Verified**, the integration is active and the first sync will begin automatically.
GitBook Assistant

📸 **Screenshot needed:** Entro portal GCP onboarding form (Step 3 above), showing the Organization Domain field and authentication method selector.
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Accounts & Integrations → GCP, showing the **Verified** ✅ status badge after a successful connection.
GitBook Assistant

The initial sync may take 5–15 minutes depending on the size of your organization. You can monitor progress under **Management → Accounts & Integrations → GCP**.
GitBook Assistant

If the status shows an error after connecting, see Troubleshooting & Validation before re-attempting.
GitBook Assistant
## Limited API Permissions (Appendix)[#limited-api-permissions-appendix](#limited-api-permissions-appendix)

Use this option if your organization requires a minimal footprint — APIs enabled on the host project only, no org-wide enablement.
GitBook Assistant

**What you get:**
GitBook Assistant

Project discovery, Secret Manager (metadata + values), Cloud Functions secrets scan, audit log viewer, IAM service account visibility, policy/recommender data, and activity analysis — all scoped to the host project.
GitBook Assistant

**What you lose:**
GitBook AssistantFeatureWhy it's lost

Google API Keys discovery across all projects
GitBook Assistant

Requires `apikeys.googleapis.com` enabled on every project
GitBook Assistant

Full project-level human ownership attribution for service accounts
GitBook Assistant

Requires org-wide agent-driven data collection
GitBook Assistant

If you start with limited onboarding and later want full coverage, simply re-run Script A or B to enable APIs across all projects — no need to recreate the service account.
GitBook Assistant

Last updated 4 months ago
GitBook AssistantAskCopy
```
#!/usr/bin/env bash
set -u

ORG_ID="<your-org-id>"   # Replace with your GCP organization ID

NON_BILLING_SERVICES=(
  cloudresourcemanager.googleapis.com
  iam.googleapis.com
  apikeys.googleapis.com
  recommender.googleapis.com
  cloudasset.googleapis.com
  policyanalyzer.googleapis.com
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
  [[ "$PROJECT_ID" == sys-* ]] && continue

  echo "Enabling APIs for project: $PROJECT_ID"

  gcloud services enable "${NON_BILLING_SERVICES[@]}" \
    --project="$PROJECT_ID" 2>&1 || echo "Warning: some non-billing APIs failed for $PROJECT_ID"

  gcloud services enable "${BILLING_SERVICES[@]}" \
    --project="$PROJECT_ID" 2>&1 || echo "Warning: some billing APIs failed for $PROJECT_ID"
done

echo "Done"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host-project-id>"

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  --project="$PROJECT_ID"
```
GitBook AssistantAskCopy
```
export PROJECT_ID="<host-project-id>"

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  secretmanager.googleapis.com \
  cloudfunctions.googleapis.com \
  recommender.googleapis.com \
  cloudasset.googleapis.com \
  pubsub.googleapis.com \
  --project="$PROJECT_ID"
```
