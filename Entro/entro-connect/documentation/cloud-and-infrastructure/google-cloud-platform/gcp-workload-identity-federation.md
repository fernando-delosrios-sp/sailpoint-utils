GCP Workload Identity Federation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform/gcp-workload-identity-federation.md).
## Step-by-Step Guide: Setting Up Workload Identity Federation in GCP[#step-by-step-guide-setting-up-workload-identity-federation-in-gcp](#step-by-step-guide-setting-up-workload-identity-federation-in-gcp)
1
#### **Navigate to Workload Identity Federation:**[#navigate-to-workload-identity-federation](#navigate-to-workload-identity-federation)

- 

In the GCP Portal, type "Workload identity federation" in the search bar.
GitBook Assistant
- 

Select the option that appears.
GitBook Assistant
2
#### **Create a Pool:**[#create-a-pool](#create-a-pool)

- 

Click on "+ CREATE POOL".
GitBook Assistant
- 

In the prompt, enter the desired name and description.
GitBook Assistant
- 

Click "CONTINUE".
GitBook Assistant
3
#### **Configure the Provider:**[#configure-the-provider](#configure-the-provider)

- 

Under **Select a provider**, choose **AWS**.
GitBook Assistant
- 

Enter any desired **name**.
GitBook Assistant
- 

Input the **AWS Account ID**: `937217723901`.
GitBook Assistant
- 

Click "**CONTINUE**" and then "**SAVE**" 
GitBook Assistant
- 

*No need to change the values in "Configure provider attributes"*
GitBook Assistant
4
#### **Grant Access:**[#grant-access](#grant-access)

- 

Once the pool is created, click "GRANT ACCESS".
GitBook Assistant
- 

Select "*Grant access using Service Account impersonation*".
GitBook Assistant
5
#### **Select Service Account:**[#select-service-account](#select-service-account)

Under **Select service account**, choose the service account created for Entro.
GitBook Assistant6
#### **Set Attributes:**[#set-attributes](#set-attributes)

- 

For **attribute name**, select `aws_role`.
GitBook Assistant
- 

For **attribute value**, enter the **ARN of Entro's AWS Role** provided during onboarding.
GitBook Assistant
7
#### **Complete the Setup:**[#complete-the-setup](#complete-the-setup)

- 

Ensure the ARN follows the format: `arn:aws:sts::937217723901:assumed-role/EntroTrustRole-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
GitBook Assistant
- 

Click "SAVE".
GitBook Assistant
8
#### **Download Configuration:**[#download-configuration](#download-configuration)

- 

A new prompt will appear post-saving.
GitBook Assistant
- 

Select the AWS Provider you created.
GitBook Assistant
- 

Click "DOWNLOAD CONFIG" and save the file for Entro's onboarding.
GitBook Assistant

Last updated 2 months ago
