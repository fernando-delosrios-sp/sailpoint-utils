GCP Terraform Onboarding (Automated) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated.md).

This method allows you to onboard Entro to GCP using Terraform for automated, repeatable configuration.
GitBook Assistant[Entro GCP Terraform onboarding.zip](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F2laGKSno6WzPaBzuZgnW%2FEntro%20GCP%20Terraform%20onboarding.zip?alt=media&token=fa7bf5c5-156c-4bf7-9143-999fafd518a6)archive · 27KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F2laGKSno6WzPaBzuZgnW%2FEntro%20GCP%20Terraform%20onboarding.zip?alt=media&token=fa7bf5c5-156c-4bf7-9143-999fafd518a6)
## Overview[#overview](#overview)

Download the provided Terraform files, update variables, and execute as instructed. This setup automates enabling services, service account creation, role assignment, and audit log configuration for Entro’s GCP integration.
GitBook Assistant

At the end of the process, you will have a configuration you can paste into Entro's onboarding form.
GitBook Assistant
#### How it works[#how-it-works](#how-it-works)

Alongside the code, 3 var files variations are supplied, to be used for following options -
GitBook Assistant

1. 

**Enable Services Only** - for creating the service account and key/WIF configuration yourself. This will save you the trouble of enabling all the required APIs for each project manually.
GitBook Assistant
1. 

**Create a service account and enable services** - creates a new service account that will be used for Entro integration.
GitBook Assistant
1. 

**Create WIF, Service account and enable services** - in addition to creating a service account and enabling services - it creates a WIF configuration for Entro's access (See more info under the WIF subsection)
GitBook Assistant

We recommend using the same var file when onboarding/refreshing projects, as usage of different var files could cause undesired results of tearing down resources.
GitBook Assistant

When choosing to enable services, onboarding a new project to Entro can be simply done by re-running the same terraform as previously used and the same var file. Terraform will pick up on the changes and update the service account Entro uses.
GitBook Assistant1
#### Prepare the project[#prepare-the-project](#prepare-the-project)

Select a project to create the service account in.
GitBook Assistant

Once selected, enable [Cloud Resource Manager API](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com) , [IAM API](https://console.cloud.google.com/apis/library/iam.googleapis.com), [Cloud Asset API](https://console.cloud.google.com/apis/api/cloudasset.googleapis.com), and [Service Usage API](https://console.cloud.google.com/apis/api/serviceusage.googleapis.com) in the project. These apis are required by Terraform to operate.
GitBook Assistant2
#### Prepare Variables[#prepare-variables](#prepare-variables)

Inside of the var file corresponding with the onboarding option you choose, fill in values as needed:
GitBook Assistantselected var file.tfvarsGitBook AssistantAskCopy
```
organization_domain  = "Your orgnization Domain"
project              = "Your selected onboarding project ID"
region               = "us-central1"
zone                 = "us-central1-a"
service_account_name = "Choose a name for your service account (all small letters)"
```

Notice this step is different in WIF. In WIF, you need to supply an AWS account and role as well.
GitBook Assistant3
#### Configure the onboarding project as your local project for Gcloud CLI[#configure-the-onboarding-project-as-your-local-project-for-gcloud-cli](#configure-the-onboarding-project-as-your-local-project-for-gcloud-cli)

run `gcloud auth login --update-adc --project=<onboarding-project-name>`
GitBook Assistant4
#### Remote Terraform State (optional)[#remote-terraform-state-optional](#remote-terraform-state-optional)

If using GCP for remote Terraform state, you must configure it in backend.tf. We recommend using a remote state in order to keep a common source of truth of the Terraform state.
GitBook Assistant

Create a storage bucket in the same project (for example: `onboarding-terraform-state-123`) and configure your backend in `**backend.tf**` to point to that bucket so Terraform stores the state remotely under the specified key as a file .
GitBook Assistant5
#### Initialize and Apply Terraform[#initialize-and-apply-terraform](#initialize-and-apply-terraform)

Run the following commands from the Terraform directory:
GitBook AssistantCommandsGitBook AssistantAskCopy
```
terraform init
terraform apply -var-file tf-var-files/<your file name here>.tfvars
```

Review the changes and click `y` if you want to apply. Terraform will align local and remote states and create/modify/destroy the resources defined in the configuration, using the variable values you provided.
GitBook Assistant6
#### What configuration did you choose?[#what-configuration-did-you-choose](#what-configuration-did-you-choose)

If you chose **Enable Services Only**, you've just completed the API enablement step in the [manual onboarding](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual). If you want to continue with manual onboarding, you can stop here.
GitBook Assistant

If you want to create everything using terraform you can complete the below steps. If you've chosen to onboard using WIF, please proceed to the [WIF manual for Terraform](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated/gcp-workload-identity-federation-automated).
GitBook Assistant7
#### Verify Resources[#verify-resources](#verify-resources)

After completion:
GitBook Assistant

- 

Confirm that the **service account** and **roles** were created in GCP.
GitBook Assistant
- 

Ensure **audit logs** are enabled for the selected services.
GitBook Assistant
8
#### Onboard to Entro[#onboard-to-entro](#onboard-to-entro)

Proceed to [GCP Service Accounts Page](https://console.cloud.google.com/iam-admin/serviceaccounts)
GitBook Assistant

Select your newly created service account
GitBook Assistant

Click Add Key, create a new key, and copy the JSON file contents.
GitBook Assistant

Note that this step differs in WIF. In WIF, the key is printed to your terminal and is ready to paste into the Enrto Onboarding.
GitBook Assistant

Navigate to Entro accounts page, click on GCP, and paste the new key into the onboarding form (notice the different options for json key and WIF)
GitBook Assistant9
#### Enabling API's asynchronously[#enabling-apis-asynchronously](#enabling-apis-asynchronously)

Notice the variable named `create_enforcer`.
GitBook Assistant

If it's value is set to `true`, a cron job will be created to run a cloud function to iterate over all projects every hour and ensure that the required APIs are enabled.
GitBook Assistant

In order to create the enforcer, you must have the hosting project connected to a billing account and [Cloud Functions](https://console.cloud.google.com/apis/api/cloudfunctions.googleapis.com/overview?project=gen-lang-client-0452546307) and [Service Usage](https://console.cloud.google.com/marketplace/product/google/serviceusage.googleapis.com) APIs enabled.
GitBook Assistant

Once you've set `create_enforcer = true`, you can set `enforcer_only = true` as well in order to enable apis using the function only, as opposed to terraform which could be time consuming on large environments.
GitBook Assistant

Note that when setting `use_billing_required_services=true`, some projects might fail updating because billing is not set for them. You can use `use_billing_required_services=false` to verify the rest of the onboarding is successful before setting up billing required services.
GitBook Assistant[PreviousGCP Workload Identity Federation (Manual)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual/gcp-workload-identity-federation-manual)[NextGCP Workload Identity Federation (Automated)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated/gcp-workload-identity-federation-automated)

Last updated 4 months ago
