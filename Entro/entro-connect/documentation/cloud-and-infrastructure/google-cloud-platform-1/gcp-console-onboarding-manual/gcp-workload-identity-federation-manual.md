GCP Workload Identity Federation (Manual) | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual/gcp-workload-identity-federation-manual.md).

Workload Identity Federation (WIF) lets Entro's AWS role impersonate your GCP service account securely - **no JSON key file required or stored**.
GitBook Assistant

This is the recommended authentication method for security-sensitive environments or organizations that enforce minimal credential storage.
GitBook Assistant

**Before starting:** Make sure you've already created a GCP service account for Entro. If not, complete Steps 1 and 3 of the [Console Onboarding guide](/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-console-onboarding-manual) first, then return here.
GitBook Assistant1
#### Navigate to Workload Identity Federation[#navigate-to-workload-identity-federation](#navigate-to-workload-identity-federation)

- 

In the GCP Console, search for **"Workload Identity Federation"** in the top search bar.
GitBook Assistant
- 

Select the result to open the Workload Identity Pools page.
GitBook Assistant
2
#### Create a Pool[#create-a-pool](#create-a-pool)

- 

Click **+ CREATE POOL**.
GitBook Assistant
- 

Enter a name (e.g., `entro-pool`) and an optional description.
GitBook Assistant
- 

Leave the pool **Enabled**.
GitBook Assistant
- 

Click **CONTINUE**.
GitBook Assistant
3
#### Configure the AWS Provider[#configure-the-aws-provider](#configure-the-aws-provider)

- 

Under **Select a provider**, choose **AWS**.
GitBook Assistant
- 

Enter a provider name (e.g., `entro-aws-provider`).
GitBook Assistant
- 

Under **AWS Account ID**, enter Entro's AWS account ID: `937217723901`
GitBook Assistant
- 

Click **CONTINUE**, then **SAVE.**
GitBook Assistant
- 

No need to configure attribute mapping.
GitBook Assistant

`937217723901` is **Entro's** AWS account ID - do not replace it with your own.
GitBook Assistant4
#### Grant Access[#grant-access](#grant-access)

- 

Once the pool is saved, click **GRANT ACCESS**.
GitBook Assistant
- 

Select **Grant access using Service Account impersonation**.
GitBook Assistant
5
#### Select the Service Account[#select-the-service-account](#select-the-service-account)

Under **Select service account**, choose the service account you created for Entro (e.g., `entro-integration`).
GitBook Assistant6
#### Set the Attribute Condition[#set-the-attribute-condition](#set-the-attribute-condition)

- 

Under **Attribute name**, select `aws_role`.
GitBook Assistant
- 

Under **Attribute value**, enter the ARN of Entro's dedicated AWS role.
GitBook Assistant

**Where to find the Entro ARN:** In the Entro portal, go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**, then select **Workload Identity Federation** as the auth method. The ARN will be displayed on that screen.
GitBook Assistant

The format will be:
GitBook AssistantGitBook AssistantAskCopy
```
arn:aws:sts::937217723901:assumed-role/EntroTrustRole-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```
7
#### Complete and Save[#complete-and-save](#complete-and-save)

- 

Confirm the ARN format matches: arn:aws:sts::937217723901:assumed-role/EntroTrustRole-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
GitBook Assistant
- 

Click **SAVE**.
GitBook Assistant
8
#### Download the Configuration File[#download-the-configuration-file](#download-the-configuration-file)

After saving in the previous step, a dialog will appear:
GitBook Assistant

- 

In the dialog, select the **AWS provider** you configured (`entro-aws-provider`).
GitBook Assistant
- 

Click **DOWNLOAD CONFIG**.
GitBook Assistant
- 

Save the downloaded JSON file — you will upload this to the Entro portal during the final onboarding step.
GitBook Assistant
9
#### Complete Onboarding in Entro[#complete-onboarding-in-entro](#complete-onboarding-in-entro)

- 

In the Entro portal, go to **Management → Accounts & Integrations → Add New Account → Google Cloud Platform**.
GitBook Assistant
- 

Select **Workload Identity Federation** as the authentication method.
GitBook Assistant
- 

Enter your **Enviroment name** (ie. Production)
GitBook Assistant
- 

Select your **Worker Group (Connector)**
GitBook Assistant
- 

Upload the configuration JSON file downloaded in the previous step.
GitBook Assistant
- 

Click **Connect Account.**
GitBook Assistant
- 

Once the status shows **Verified**, the integration is active.
GitBook Assistant

With WIF configured, Entro will never store a static credential. The federation trust is scoped specifically to Entro's designated AWS role and your service account - no broader access is granted.
GitBook Assistant[PreviousGCP Console Onboarding (Manual)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-console-onboarding-manual)[NextGCP Terraform Onboarding (Automated)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated)

Last updated 4 months ago
