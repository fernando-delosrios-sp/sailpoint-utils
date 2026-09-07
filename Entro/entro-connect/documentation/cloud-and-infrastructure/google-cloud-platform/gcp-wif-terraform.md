GCP WIF Terraform | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-wif-terraform.md).

This guide automates the full Workload Identity Federation (WIF) setup using Terraform — creating the service account, assigning IAM roles, and establishing the cross-cloud federation link between Entro's AWS role and your GCP environment in a single run.
GitBook Assistant

**If you prefer to configure WIF manually** through the GCP Console, use the Workload Identity Federation guide instead. This page covers the Terraform-based setup only.
GitBook Assistant

📦 **Terraform Template** — Upload `entro-gcp-terraform-onboarding-wif.zip` to your GitBook space assets, then replace this hint with a `{% file %}` block pointing to it.
GitBook Assistant1
#### Step 1 - Prepare the Host Project[#step-1-prepare-the-host-project](#step-1-prepare-the-host-project)

Select or create the project where the Entro service account will live.
GitBook Assistant

Enable the APIs required for Terraform to operate:
GitBook AssistantGitBook AssistantAskCopy
```
export PROJECT_ID="<your-host-project-id>"

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project="$PROJECT_ID"
```
2
#### Step 2 - Get the Entro ARN[#step-2-get-the-entro-arn](#step-2-get-the-entro-arn)

Before filling in variables, retrieve the Entro AWS Role ARN from the Entro portal:
GitBook Assistant

1. 

Go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**
GitBook Assistant
1. 

Select **Workload Identity Federation** as the authentication method
GitBook Assistant
1. 

Copy the ARN shown on screen — it will have the format:
GitBook AssistantGitBook AssistantAskCopy
```
arn:aws:sts::937217723901:assumed-role/EntroTrustRole-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

📸 **Screenshot needed:** Entro portal — GCP onboarding form with WIF selected, showing the ARN displayed on screen so users know exactly where to find and copy it.
GitBook Assistant3
#### Step 3 - Prepare Variables[#step-3-prepare-variables](#step-3-prepare-variables)

In the downloaded Terraform template, use the file `tf-var-files/wif-setup.tfvars` and fill in the required fields:
GitBook AssistantGitBook AssistantAskCopy
```
# tf-var-files/wif-setup.tfvars

organization_domain  = "your-org.com"                    # Your GCP org domain
project              = "<your-host-project-id>"           # Host project for the service account
region               = "us-central1"
zone                 = "us-central1-a"
service_account_name = "entro-integration"

aws_sts_arn          = "<ARN from Entro portal>"          # Paste the ARN from Step 2
aws_account_id       = "937217723901"                     # Entro's AWS account ID — do not change

# ── Terraform will create all of the following ────────────────────────────────
service_account_create_condition      = true
service_account_key_create_condition  = false   # No key needed — WIF is keyless
service_account_grant_roles_condition = true
audit_log_configure_condition         = true
audit_log_all_services_condition      = true
enable_workload_identity_federation   = true
```

`aws_account_id = "937217723901"` is **Entro's** AWS account ID. Do not replace it with your own.
GitBook Assistant4
#### Step 4 - Configure gcloud CLI[#step-4-configure-gcloud-cli](#step-4-configure-gcloud-cli)
GitBook AssistantAskCopy
```
gcloud auth login --update-adc --project=<your-host-project-id>
```
5
#### Step 5 - Initialize and Apply[#step-5-initialize-and-apply](#step-5-initialize-and-apply)
GitBook AssistantAskCopy
```
terraform init
terraform plan -var-file tf-var-files/wif-setup.tfvars
terraform apply -var-file tf-var-files/wif-setup.tfvars
```

Review the plan output, then confirm with `yes`.
GitBook Assistant

📸 **Screenshot needed:** Terminal showing `terraform apply` completing successfully with the "Apply complete! Resources: X added" summary line.
GitBook Assistant6
#### Step 6 - Copy the Terraform Output[#step-6-copy-the-terraform-output](#step-6-copy-the-terraform-output)

After a successful apply, Terraform will print an onboarding configuration JSON. Copy this output — you'll paste it into the Entro portal in the next step.
GitBook AssistantGitBook AssistantAskCopy
```
Outputs:

entro_onboarding_config = {
  "type": "external_account",
  "audience": "//iam.googleapis.com/projects/...",
  ...
}
```

If the output doesn't appear automatically, run:
GitBook AssistantGitBook AssistantAskCopy
```
terraform output entro_onboarding_config
```

📸 **Screenshot needed:** Terminal showing the full `entro_onboarding_config` Terraform output JSON (with sensitive values redacted if needed).
GitBook Assistant7
#### Step 7 - Complete Onboarding in Entro[#step-7-complete-onboarding-in-entro](#step-7-complete-onboarding-in-entro)

1. 

In the Entro portal, go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**
GitBook Assistant
1. 

Select **Workload Identity Federation** as the authentication method
GitBook Assistant
1. 

Paste or upload the JSON configuration from Step 6
GitBook Assistant
1. 

Fill in your **Organization Domain**
GitBook Assistant
1. 

Click **Connect**
GitBook Assistant
1. 

Once the status shows **Verified**, the integration is active
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Accounts & Integrations → GCP showing the **Verified** ✅ status badge after a successful WIF + Terraform connection.
GitBook Assistant

With WIF + Terraform, no static credentials are created or stored at any point. The entire setup — federation, roles, and audit logs — is captured as code and can be version-controlled and re-applied.
GitBook Assistant

Last updated 4 months ago
