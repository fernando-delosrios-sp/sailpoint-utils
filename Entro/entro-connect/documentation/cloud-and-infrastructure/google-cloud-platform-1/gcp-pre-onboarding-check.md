GCP Pre Onboarding Check | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-pre-onboarding-check.md).

Before onboarding Entro’s GCP integration, use the script below to verify that the onboarding user has access to relevant projects and that logs are enabled.
GitBook Assistant

A report file will be generated to **report.txt**, especially useful if the onboarding user has access to many projects.
GitBook Assistant

Run this script with gcloud configured for the onboarding user. The script writes detailed output to `report.txt`.
GitBook Assistantgcp_pre_onboarding_check.shGitBook AssistantAskCopy
```
#!/bin/bash

# Output file for the report
REPORT_FILE="report.txt"
echo "Starting role and log check..." | tee -a "$REPORT_FILE"
echo "Output is saved to $REPORT_FILE"

# Check for broad roles and logs across all projects in the organization
echo "Checking roles and log settings across all projects..." | tee -a "$REPORT_FILE"

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

# Function to check if the user has a specific role in a project
check_role_in_project() {
    local PROJECT_ID=$1
    local ROLE=$2
    echo -n "    Checking for role: $ROLE... "| tee -a "$REPORT_FILE"
    IAM_POLICY=$(gcloud projects get-iam-policy $PROJECT_ID --format="json")
    if echo "$IAM_POLICY" | grep -q "$ROLE" && echo "$IAM_POLICY" | grep -q "$CURRENT_USER"; then
        echo "✅ Assigned" | tee -a "$REPORT_FILE"
    else
        echo "❌ Not assigned" | tee -a "$REPORT_FILE"
    fi
}

# Function to check if logs are enabled for a project
check_logs_enabled() {
    local PROJECT_ID=$1
    LOGGING_STATUS=$(gcloud services list --enabled --filter="config.name=logging.googleapis.com" --project=$PROJECT_ID --format="value(config.name)")
    if [ "$LOGGING_STATUS" == "logging.googleapis.com" ]; then
        echo "    ✅ Logs are enabled" | tee -a "$REPORT_FILE"
    else
        echo "    ❌ Logs are NOT enabled" | tee -a "$REPORT_FILE"
    fi
}

# Check roles and logs for all projects
for PROJECT_ID in $PROJECTS; do
    echo -e "\nChecking project: $PROJECT_ID" | tee -a "$REPORT_FILE"
    echo "  Checking roles:" | tee -a "$REPORT_FILE"
    for ROLE in "roles/owner" "roles/editor" "roles/viewer"; do
        check_role_in_project $PROJECT_ID $ROLE
    done

    echo "  Checking log settings:" | tee -a "$REPORT_FILE"
    check_logs_enabled $PROJECT_ID
done

echo -e "\nRole and log check completed." | tee -a "$REPORT_FILE"
echo "Report saved to $REPORT_FILE"
```
[PreviousGoogle Cloud Platform](/integrations/cloud-and-infrastructure/google-cloud-platform-1)[NextGCP Console Onboarding (Manual)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual)

Last updated 4 months ago
