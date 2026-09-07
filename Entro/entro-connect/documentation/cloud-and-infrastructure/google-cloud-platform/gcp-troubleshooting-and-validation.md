GCP troubleshooting and validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-troubleshooting-and-validation.md).

Use this page after completing onboarding to verify the connection is working correctly, and to resolve common issues.
GitBook Assistant
## Step 1 — Validate the Connection in Entro[#step-1-validate-the-connection-in-entro](#step-1-validate-the-connection-in-entro)
1
#### Validate the Connection in Entro[#validate-the-connection-in-entro](#validate-the-connection-in-entro)

- 

In the Entro portal, go to **Management → Accounts & Integrations → GCP**.
GitBook Assistant
- 

Confirm the connection status shows **Verified** ✅
GitBook Assistant
- 

Check the **Last Sync Timestamp** — it should reflect a recent sync
GitBook Assistant
- 

Review **Findings** for discovered secrets or misconfigurations
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Management → Accounts & Integrations → GCP, showing the integration row with the **Verified** ✅ status badge, Last Sync Timestamp, and Findings count.
GitBook Assistant

The initial sync may take 5–15 minutes depending on org size. If the status shows **Pending**, wait a few minutes and refresh before troubleshooting.
GitBook Assistant
## Step 2 — Validate API Access Manually[#step-2-validate-api-access-manually](#step-2-validate-api-access-manually)
1
#### Validate API Access Manually[#validate-api-access-manually](#validate-api-access-manually)

Run the following command to confirm Entro's service account can reach the GCP projects API:
GitBook AssistantGitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> auth print-access-token)" \
  https://cloudresourcemanager.googleapis.com/v1/projects
```

**Expected result:** A JSON array of projects your account can access.
GitBook Assistant

If you receive an error, check the service account's IAM roles — see GCP Permissions Reference.
GitBook Assistant
## Step 3 — Validate Audit Log Flow[#step-3-validate-audit-log-flow](#step-3-validate-audit-log-flow)
1
#### Validate Audit Log Flow[#validate-audit-log-flow](#validate-audit-log-flow)

To confirm that audit logs are flowing:
GitBook AssistantGitBook AssistantAskCopy
```
gcloud logging read \
  "logName:cloudaudit.googleapis.com" \
  --project=<your-project-id> \
  --limit=5 \
  --format="table(timestamp, logName, severity)"
```

**Expected result:** Recent audit log entries. If this returns nothing, revisit Step 5 of Console Onboarding to confirm logs are enabled for the correct services.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueLikely CauseResolution

**403 Forbidden**
GitBook Assistant

Missing IAM roles
GitBook Assistant

Verify all required roles are assigned to the service account. See GCP Permissions Reference.
GitBook Assistant

**401 Unauthorized**
GitBook Assistant

Expired or invalid Service Account key
GitBook Assistant

Regenerate the key under **IAM & Admin → Service Accounts → Keys**, then update it in Entro.
GitBook Assistant

**Connection failed**
GitBook Assistant

Entro Connector (Worker) is offline or misconfigured
GitBook Assistant

In the Entro portal, go to **Settings → Connectors** and confirm the connector assigned to your GCP integration shows a green status. If offline, restart or reinstall it.
GitBook Assistant

**No audit log data**
GitBook Assistant

Audit logs not configured, or wrong services selected
GitBook Assistant

Re-run Step 5 of Console Onboarding. Validate with the `gcloud logging read` command above.
GitBook Assistant

**Secrets not appearing**
GitBook Assistant

Secret Manager API not enabled, or missing role
GitBook Assistant

Enable `secretmanager.googleapis.com` on all projects. Verify **Secret Manager Viewer** and **Secret Manager Secret Accessor** roles are assigned.
GitBook Assistant

**Data appears stale**
GitBook Assistant

Sync hasn't run recently
GitBook Assistant

Click **Sync Now** in **Management → Accounts & Integrations → GCP**. Check the Last Sync Timestamp after 5 minutes.
GitBook Assistant

**Some projects missing**
GitBook Assistant

API-enablement script only covered some projects
GitBook Assistant

Re-run Script B (Asset Search) from the Console Onboarding guide to catch projects in complex folder hierarchies.
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Settings → Connectors, showing a connector with a green "active" status indicator so users know what a healthy connector looks like.
GitBook Assistant
## Re-Syncing After Fixes[#re-syncing-after-fixes](#re-syncing-after-fixes)
1
#### Trigger an immediate re-scan[#trigger-an-immediate-re-scan](#trigger-an-immediate-re-scan)

- 

Go to **Management → Accounts & Integrations → GCP**
GitBook Assistant
- 

Click **Sync Now**
GitBook Assistant
- 

Monitor the **Last Sync Timestamp** and **Findings** to confirm data is flowing
GitBook Assistant

📸 **Screenshot needed:** Entro portal GCP integration detail page showing the **Sync Now** button location.
GitBook Assistant
## Security & Compliance Notes[#security-and-compliance-notes](#security-and-compliance-notes)
PropertyDetail

Access type
GitBook Assistant

Read-only — Entro never writes or modifies GCP resources
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

- [Step 1 — Validate the Connection in Entro](#step-1-validate-the-connection-in-entro)
- [Step 2 — Validate API Access Manually](#step-2-validate-api-access-manually)
- [Step 3 — Validate Audit Log Flow](#step-3-validate-audit-log-flow)
- [Common Issues](#common-issues)
- [Re-Syncing After Fixes](#re-syncing-after-fixes)
- [Security & Compliance Notes](#security-and-compliance-notes)
