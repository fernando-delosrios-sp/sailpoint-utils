GCP pre-onboarding check | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-pre-onboarding-check.md).

Run this script before starting onboarding to verify that your account has the access Entro needs. It checks across all projects in your organization and writes a summary to `report.txt`.
GitBook Assistant

**What it checks:**
GitBook Assistant

- 

Your user can list and access all relevant projects
GitBook Assistant
- 

Required APIs (Logging, Secret Manager, etc.) are enabled
GitBook Assistant
- 

IAM roles are assigned at the project level
GitBook Assistant

## Prerequisites[#prerequisites](#prerequisites)

Before running the script, make sure `gcloud` is installed and you are authenticated as the user who will perform the onboarding:
GitBook AssistantGitBook AssistantAskCopy
```
gcloud auth login
gcloud config set account YOUR_EMAIL@your-org.com
```

You must have organization-level permissions to list projects.
GitBook Assistant
## Run the Script[#run-the-script](#run-the-script)

Save the script below as `gcp_pre_onboarding_check.sh`, then execute it:
GitBook AssistantGitBook AssistantAskCopy
```
chmod +x gcp_pre_onboarding_check.sh
./gcp_pre_onboarding_check.sh
```
gcp_pre_onboarding_check.shGitBook AssistantAskCopy
```
#!/bin/bash

# Output file for the report
REPORT_FILE="report.txt"
echo "Starting role and log check..." | tee -a "$REPORT_FILE"
echo "Output is saved to $REPORT_FILE"

# Get the organization ID
ORG_ID=$(gcloud organizations list --format='value(name)')
if [ -z "$ORG_ID" ]; then
  echo "Error: Unable to fetch organization ID. Ensure you have access to an organization." | tee -a "$REPORT_FILE"
  exit 1
fi

# Get the current user's email
CURRENT_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [ -z "$CURRENT_USER" ]; then
  echo "Error: Unable to determine the active user." | tee -a "$REPORT_FILE"
  exit 1
fi

echo "Organization ID: $ORG_ID" | tee -a "$REPORT_FILE"
echo "Active user: $CURRENT_USER" | tee -a "$REPORT_FILE"

# List all projects under the organization
PROJECTS=$(gcloud projects list --filter="parent.id=$ORG_ID AND parent.type=organization" --format="value(projectId)")
if [ -z "$PROJECTS" ]; then
  echo "Error: No projects found under the organization." | tee -a "$REPORT_FILE"
  exit 1
fi

echo -e "\nFound projects:" | tee -a "$REPORT_FILE"
echo "$PROJECTS" | tee -a "$REPORT_FILE"

check_role_in_project() {
  local PROJECT_ID=$1
  local ROLE=$2
  echo -n "  Checking for role: $ROLE... " | tee -a "$REPORT_FILE"
  IAM_POLICY=$(gcloud projects get-iam-policy "$PROJECT_ID" --format="json")
  if echo "$IAM_POLICY" | grep -q "$ROLE" && echo "$IAM_POLICY" | grep -q "$CURRENT_USER"; then
    echo "✅ Assigned" | tee -a "$REPORT_FILE"
  else
    echo "❌ Not assigned" | tee -a "$REPORT_FILE"
  fi
}

check_logs_enabled() {
  local PROJECT_ID=$1
  LOGGING_STATUS=$(gcloud services list --enabled \
    --filter="config.name=logging.googleapis.com" \
    --project="$PROJECT_ID" \
    --format="value(config.name)")
  if [ "$LOGGING_STATUS" == "logging.googleapis.com" ]; then
    echo "  ✅ Logs are enabled" | tee -a "$REPORT_FILE"
  else
    echo "  ❌ Logs are NOT enabled" | tee -a "$REPORT_FILE"
  fi
}

for PROJECT_ID in $PROJECTS; do
  echo -e "\nChecking project: $PROJECT_ID" | tee -a "$REPORT_FILE"
  echo "  Checking roles:" | tee -a "$REPORT_FILE"
  for ROLE in "roles/owner" "roles/editor" "roles/viewer"; do
    check_role_in_project "$PROJECT_ID" "$ROLE"
  done
  echo "  Checking log settings:" | tee -a "$REPORT_FILE"
  check_logs_enabled "$PROJECT_ID"
done

echo -e "\nRole and log check completed." | tee -a "$REPORT_FILE"
echo "Report saved to $REPORT_FILE"
```

📸 **Screenshot needed:** Terminal window showing the script running with sample ✅ / ❌ output per project.
GitBook Assistant
## Interpreting Results[#interpreting-results](#interpreting-results)

Open `report.txt` after the script completes and review each project.
GitBook AssistantResultMeaningAction

✅ Role assigned
GitBook Assistant

Your account has visibility into this project
GitBook Assistant

No action needed
GitBook Assistant

❌ Role not assigned
GitBook Assistant

This project may not be fully visible to Entro
GitBook Assistant

Assign the required Entro roles — see Permissions Reference
GitBook Assistant

✅ Logs enabled
GitBook Assistant

Audit log ingestion will work
GitBook Assistant

No action needed
GitBook Assistant

❌ Logs NOT enabled
GitBook Assistant

Entro won't receive activity events from this project
GitBook Assistant

Enable `logging.googleapis.com` for this project
GitBook Assistant

This script checks for broad roles (`owner`, `editor`, `viewer`) as a quick access proxy. For the exact permissions Entro requires, see the GCP Permissions Reference.
GitBook Assistant

If any projects show ❌ for roles or logs, resolve these before proceeding with onboarding. Contact your GCP admin or follow the Console Onboarding guide to assign the correct roles.
GitBook Assistant

Last updated 4 months ago

- [Prerequisites](#prerequisites)
- [Run the Script](#run-the-script)
- [Interpreting Results](#interpreting-results)
