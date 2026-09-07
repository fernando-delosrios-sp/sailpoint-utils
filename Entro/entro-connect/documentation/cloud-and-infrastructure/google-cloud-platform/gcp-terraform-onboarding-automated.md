GCP terraform onboarding automated | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-terraform-onboarding-automated.md).

This method onboards Entro to GCP using Terraform for automated, repeatable configuration. It provisions the service account, assigns IAM roles, enables required APIs, and configures audit logs - all in a single `terraform apply`.
GitBook Assistant

**Estimated time:** 10–15 minutes (once Terraform is configured) **Best for:** DevOps/SecOps teams · Enterprises with IaC pipelines · Multi-project organizations
GitBook Assistant

📦 **Terraform Template** — Upload `entro-gcp-terraform-onboarding-wif.zip` to your GitBook space assets, then replace this hint with a `{% file %}` block pointing to it.
GitBook Assistant

**Use the same **`**.tfvars**`** file every time.** Re-running Terraform with a different var file may tear down resources created by previous runs. Keep your `my.tfvars` in source control alongside the Terraform files.
GitBook Assistant
## How It Works[#how-it-works](#how-it-works)

The Terraform template supports three configuration modes via variable files. Choose the one that fits your setup:
GitBook AssistantModeWhat it does

**Enable services only**
GitBook Assistant

Enables all required APIs across projects. You create the service account and key/WIF manually.
GitBook Assistant

**Service account + services**
GitBook Assistant

Creates the service account and enables all required APIs.
GitBook Assistant

**WIF + service account + services**
GitBook Assistant

Full automated setup including Workload Identity Federation. Recommended for keyless auth.
GitBook Assistant1
#### Step 1 - Prepare the Host Project[#step-1-prepare-the-host-project](#step-1-prepare-the-host-project)

Select an existing project to host the Entro service account, or create a new one (e.g., `entro-security`).
GitBook Assistant

Enable the following APIs on this project so that Terraform can operate:
GitBook AssistantGitBook AssistantAskCopy
```
export PROJECT_ID="<your-host-project-id>"

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  cloudasset.googleapis.com \
  serviceusage.googleapis.com \
  --project="$PROJECT_ID"
```
2
#### Step 2 - Prepare Variables[#step-2-prepare-variables](#step-2-prepare-variables)

Download the Terraform template above and create a variables file named `my.tfvars` in the Terraform directory.
GitBook Assistant

For a **standard first-time onboarding**, use the values below. All condition flags are set to `true` so Terraform creates everything in one run.
GitBook Assistant

To use **Workload Identity Federation instead of a JSON key**, set `service_account_key_create_condition = false` and follow the WIF + Terraform guide.
GitBook AssistantGitBook AssistantAskCopy
```
# my.tfvars — Standard onboarding with Service Account Key
# Replace all placeholder values before running.

organization_domain  = "your-org.com"             # Your GCP org domain
project              = "<your-host-project-id>"    # Project to create the service account in
region               = "us-central1"
zone                 = "us-central1-a"
service_account_name = "entro-integration"

# ── What should Terraform create? ──────────────────────────────────────────────
service_account_create_condition     = true  # Create the Entro service account
service_account_key_create_condition = true  # Generate a JSON key (set false for WIF)
service_account_grant_roles_condition = true # Assign required IAM roles
audit_log_configure_condition        = true  # Configure audit log settings
audit_log_all_services_condition     = true  # Apply to all services (recommended)

# ── Auto-enforce new projects (optional — see Step 7) ─────────────────────────
# create_enforcer = false  # Deploy a Cloud Function that auto-enables APIs on new projects
# enforcer_only   = false  # Skip Terraform API loop once enforcer is active (faster for large orgs)
```
3
#### Step 3 - Configure gcloud CLI[#step-3-configure-gcloud-cli](#step-3-configure-gcloud-cli)

Set your onboarding project as the active project for the gcloud CLI:
GitBook AssistantGitBook AssistantAskCopy
```
gcloud auth login --update-adc --project=<your-host-project-id>
```
4
#### Step 4 — Remote Terraform State (Optional)[#step-4-remote-terraform-state-optional](#step-4-remote-terraform-state-optional)

If you want to store Terraform state in GCP (recommended for teams):
GitBook Assistant

1. 

Create a GCS bucket in your host project:
GitBook AssistantGitBook AssistantAskCopy
```
gsutil mb -p <your-host-project-id> gs://entro-terraform-state-<unique-suffix>
```

1. 

Add a `backend.tf` file to your Terraform directory:
GitBook AssistantGitBook AssistantAskCopy
```
terraform {
  backend "gcs" {
    bucket = "entro-terraform-state-<unique-suffix>"
    prefix = "entro/gcp-onboarding"
  }
}
```

5
#### Step 5 — Initialize and Apply Terraform[#step-5-initialize-and-apply-terraform](#step-5-initialize-and-apply-terraform)

Run the following from the Terraform directory:
GitBook AssistantGitBook AssistantAskCopy
```
terraform init
terraform apply -var-file my.tfvars
```

Terraform will display a plan of all resources to be created. Review and confirm with `yes`.
GitBook Assistant

📸 **Screenshot needed:** Terminal showing `terraform apply` output with the resource plan summary and the `yes` prompt, then the "Apply complete!" success message.
GitBook Assistant6
#### Step 6 — Verify Resources and Connect to Entro[#step-6-verify-resources-and-connect-to-entro](#step-6-verify-resources-and-connect-to-entro)

After the run completes, confirm the following in GCP:
GitBook Assistant

- 

✅ Service account `entro-integration@<project>.iam.gserviceaccount.com` exists under **IAM & Admin → Service Accounts**
GitBook Assistant
- 

✅ Required IAM roles are assigned at org or project scope under **IAM & Admin → IAM**
GitBook Assistant
- 

✅ Audit logs are enabled for Secret Manager, Cloud Functions, and IAM under **IAM & Admin → Audit Logs**
GitBook Assistant
- 

✅ A JSON key or WIF configuration file has been generated (check Terraform outputs)
GitBook Assistant

Then complete onboarding in the Entro portal:
GitBook Assistant

1. 

Go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**
GitBook Assistant
1. 

Upload the JSON key or WIF config generated by Terraform
GitBook Assistant
1. 

Click **Connect** and verify the status shows **Verified**
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Accounts & Integrations → GCP showing the **Verified** ✅ status badge after a successful Terraform-based connection.
GitBook Assistant7
#### Step 7 (Optional) — Auto-Onboard New Projects[#step-7-optional-auto-onboard-new-projects](#step-7-optional-auto-onboard-new-projects)

By default, Terraform enables APIs for all projects that exist at the time of the run. New projects created afterwards won't be covered automatically unless you enable the enforcer.
GitBook Assistant

**To enable automatic coverage of new projects:**
GitBook Assistant

1. 

Add the following to your `my.tfvars`:
GitBook AssistantGitBook AssistantAskCopy
```
create_enforcer = true
```

1. 

Re-run:
GitBook AssistantGitBook AssistantAskCopy
```
terraform apply -var-file my.tfvars
```

This deploys a Cloud Function that runs every hour and enables the required APIs on any new projects automatically.
GitBook Assistant

**Prerequisites for the enforcer:**
GitBook Assistant

- 

Host project must have a billing account attached
GitBook Assistant
- 

Cloud Functions API and Service Usage API must be enabled on the host project
GitBook Assistant

Once the enforcer is running and confirmed working, you can set `enforcer_only = true` in `my.tfvars` to skip the Terraform API-enabling loop on future runs. This is significantly faster for large organizations with many projects.
GitBook Assistant

Note: When `use_billing_required_services = true`, projects without billing attached will fail to enable billing-required APIs. Set it to `false` first to verify the rest of onboarding succeeds, then enable billing services separately.
GitBook Assistant

Last updated 4 months ago
