GCP Workload Identity Federation (Automated) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated/gcp-workload-identity-federation-automated.md).
## Overview[#overview](#overview)

The Terraform configuration creates and configures the service account, assigns required organization-level roles, and establishes a secure federation link between your AWS role and Google Cloud service account for Entro onboarding.
GitBook Assistant
## Terraform Onboarding[#terraform-onboarding](#terraform-onboarding)

This onboarding method automates **Workload Identity Federation (WIF)** configuration using Terraform.
GitBook Assistant[Entro GCP Terraform onboarding.zip](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F2laGKSno6WzPaBzuZgnW%2FEntro%20GCP%20Terraform%20onboarding.zip?alt=media&token=fa7bf5c5-156c-4bf7-9143-999fafd518a6)archive · 27KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F2laGKSno6WzPaBzuZgnW%2FEntro%20GCP%20Terraform%20onboarding.zip?alt=media&token=fa7bf5c5-156c-4bf7-9143-999fafd518a6)

In the provided files above, use following file `**tf-var-files/wif-setup.tfvars**` and fill in the required fields.
GitBook Assistant

**Where to find the Entro ARN:** In the Entro portal, go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**, then select **Workload Identity Federation** as the auth method. The ARN will be displayed on that screen.
GitBook Assistant

The format will be:
GitBook AssistantGitBook AssistantAskCopy
```
arn:aws:sts::937217723901:assumed-role/EntroTrustRole-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Set this to `false` if you want to limit API enablement to the host project only (recommended if you don't have org-wide permissions)
GitBook AssistantGitBook AssistantAskCopy
```
enable_services_on_all_projects = false
```
GitBook AssistantAskCopy
```
organization_domain  = "Your orgnization Domain"
project              = "Your selected onboarding project ID"
region               = "us-central1"
zone                 = "us-central1-a"
service_account_name = "Choose a name for your service account"
aws_sts_arn          = "Entro Arn"
aws_account_id       = "937217723901"
```

### Running the Terraform[#running-the-terraform](#running-the-terraform)
1

**Prepare the project**
GitBook Assistant

For this onboarding, select an existing project to create the service account in, or create a new one.
GitBook Assistant

Once selected, enable [Cloud Resource Manager API](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com) for the terraform to be able to operate within this project. Similarly, enable the [IAM API](https://console.cloud.google.com/apis/library/iam.googleapis.com) for the onboarding project.
GitBook Assistant2

**Configure the onboarding project as your local project for gcloud cli**
GitBook Assistant

run `gcloud auth login --update-adc --project=<onboarding-project-name>`
GitBook Assistant3

**Initialize Terraform**
GitBook Assistant4

**Plan with Variables**
GitBook Assistant5

**Apply with Variables**
GitBook Assistant
#### Output[#output](#output)

After successful execution, Terraform outputs the **onboarding JSON configuration**. Copy this JSON and use it directly in Entro’s GCP integration onboarding form including the brackets.
GitBook Assistant[PreviousGCP Terraform Onboarding (Automated)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated)[NextGCP Troubleshooting And Validation](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-troubleshooting-and-validation)

Last updated 4 months ago

- [Overview](#overview)
- [Terraform Onboarding](#terraform-onboarding)
- [Running the Terraform](#running-the-terraform)
GitBook AssistantAskCopy
```
terraform init
```
GitBook AssistantAskCopy
```
terraform plan -var-file tf-var-files/wif-setup.tfvars
```
GitBook AssistantAskCopy
```
terraform apply -var-file tf-var-files/wif-setup.tfvars
```
GitBook AssistantAskCopy
```
{
  "universe_domain": "googleapis.com",
  "type": "external_account",
  "audience": "//iam.googleapis.com/projects/2756056728/locations/global/workloadIdentityPools/entro-idp-id-589/providers/entro-wip-id-589",
  "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/entro-serviceaccount-wif-setup@gen-lang-client-0568456307.iam.gserviceaccount.com:generateAccessToken",
  "token_url": "https://sts.googleapis.com/v1/token",
  "credential_source": {
    "environment_id": "aws1",
    "region_url": "http://192.168.120.222/latest/meta-data/placement/availability-zone",
    "url": "http://194.237.299.211/latest/meta-data/iam/security-credentials",
    "regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
  }
}
```
