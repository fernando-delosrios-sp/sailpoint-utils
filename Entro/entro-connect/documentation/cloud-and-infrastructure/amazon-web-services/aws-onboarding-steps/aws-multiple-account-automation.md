AWS Multiple Account Automation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation.md).

For organizations managing multiple AWS accounts under **AWS Organizations**, Entro provides a scalable method to onboard and maintain integrations automatically. This ensures consistent visibility and secret management across all member accounts without manual setup in each environment.
GitBook Assistant
## Overview[#overview](#overview)

The **Multiple Account Automation** feature allows administrators to deploy the Entro AWS integration across multiple linked accounts using:
GitBook Assistant

- 

**AWS CloudFormation StackSets**
GitBook Assistant
- 

**Terraform (Infrastructure-as-Code)**
GitBook Assistant

Both methods create the required cross-account IAM Roles and Entro policies automatically, eliminating the need to repeat manual onboarding in each account.
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS/TLS)
Management AWS Account (Root)
   ├── StackSet deployment → Member Account A
   ├── StackSet deployment → Member Account B
   └── StackSet deployment → Member Account C
```

Each member account runs a read-only IAM Role (`EntroAWSIntegrationRole`) provisioned automatically through StackSets or delegated administrator permissions.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

**AWS Organizations** is enabled and configured.
GitBook Assistant
- 

You have **management account** or **delegated admin** privileges with permission to deploy organization-wide resources.
GitBook Assistant
- 

One of the following automation options is available in your environment:
GitBook Assistant

- 

**CloudFormation StackSets** (recommended)
GitBook Assistant
- 

**Terraform** with permissions to create IAM roles and policies across member accounts.
GitBook Assistant

- 

**Entro permissions** (`EntroReadOnlyAccess` policy) are included in the deployment template or Terraform module.
GitBook Assistant
- 

All linked accounts have **outbound HTTPS/TLS connectivity** to Entro’s API endpoints.
GitBook Assistant

## Setup Steps[#setup-steps](#setup-steps)
1
#### Select the Root or Delegated Management Account[#select-the-root-or-delegated-management-account](#select-the-root-or-delegated-management-account)

Launch the integration from your **AWS Management Account** in Entro. Entro will automatically detect all child accounts under the AWS Organization.
GitBook Assistant2

**Choose Deployment Method**
GitBook Assistant

You can onboard all member accounts using either:
GitBook Assistant

- 

**Option A:** CloudFormation StackSet (recommended)
GitBook Assistant
- 

**Option B:** Terraform (for IaC-managed environments)
GitBook Assistant
3
#### Deploy the StackSet[#deploy-the-stackset](#deploy-the-stackset)

**Option A - CloudFormation StackSet**
GitBook Assistant

1. 

In the **AWS** console proceed to **CloudFormation**
GitBook Assistant
1. 

In the burger menu on the left click S**tacksets**
GitBook Assistant
1. 

Select - Service-managed permissions, Template is ready and then upload the below file.
GitBook Assistant
1. 

Download or copy the prebuilt CloudFormation template ([`entro-aws-multi-account.json`](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation#option-a-cloudformation-stackset-template-reference)).
GitBook Assistant
1. 

Enter a StackSet name eg. EntroStackset
GitBook Assistant
1. 

Enter the provided **ExternalID, Remote Agent and SNSTopic** from Entro Security
GitBook Assistant
1. 

Click next
GitBook Assistant
1. 

At the bottom click "**I acknowledge that AWS CloudFormation might create IAM resources with custom names"** and click next
GitBook Assistant
1. 

Under "Specify Regions" select **US East 1** and click next and submit
GitBook Assistant

**Option B - Terraform**
GitBook Assistant

1. 

Copy the Terraform module provided in this guide under “[`entro-aws-multi-account.json`](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation#option-b-terraform-infrastructure-as-code-template-refere)”
GitBook Assistant
1. 

Define the required variables (`external_id`, `remote_agent`, and optional `sns_topic_arn_suffix`).
GitBook Assistant
1. 

Apply the module from your Terraform pipeline or management workspace.
GitBook Assistant
4
#### Role and Policy Deployment[#role-and-policy-deployment](#role-and-policy-deployment)

The deployment (StackSet or Terraform) automatically creates the integration roles in each account:
GitBook Assistant

- 

**Role Name:** `EntroAWSIntegrationRole`
GitBook Assistant
- 

**Policy Name:** `EntroReadOnlyAccess`
GitBook Assistant

These roles are assumed by Entro’s AWS Account using a secure external ID and trust policy configured during deployment.
GitBook Assistant5
#### Verify Integration[#verify-integration](#verify-integration)

- 

Return to Entro → **Integrations → AWS**.
GitBook Assistant
- 

All child accounts appear automatically under the parent integration.
GitBook Assistant
- 

Verify account sync status = **Active** for each linked account.
GitBook Assistant

#### **Option A - CloudFormation StackSet Template Reference**[#option-a-cloudformation-stackset-template-reference](#option-a-cloudformation-stackset-template-reference)
[Entro Security AWS Template.json](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2Ffr76VnNgyKG0QWp33bei%2FEntro%20Security%20AWS%20Template.json?alt=media&token=60ba41ca-2650-4a2a-b009-06a4cb878447)14KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2Ffr76VnNgyKG0QWp33bei%2FEntro%20Security%20AWS%20Template.json?alt=media&token=60ba41ca-2650-4a2a-b009-06a4cb878447)[Entro Security AWS Template - Europe region.json](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F6oW6sEHA2yJR9TAJYYze%2FEntro%20Security%20AWS%20Template%20-%20Europe%20region.json?alt=media&token=f22aaa1f-aeb4-44e7-9100-cdd8b4fe0b6d)14KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2F6oW6sEHA2yJR9TAJYYze%2FEntro%20Security%20AWS%20Template%20-%20Europe%20region.json?alt=media&token=f22aaa1f-aeb4-44e7-9100-cdd8b4fe0b6d)
#### **Option B - Terraform (Infrastructure-as-Code) Template Reference**[#option-b-terraform-infrastructure-as-code-template-reference](#option-b-terraform-infrastructure-as-code-template-reference)
[Terraform-Entro.tf](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FgS6Obp4amonTVi2QYRlR%2FTerraform-Entro.tf?alt=media&token=6e1d2f3e-1aff-4eb4-9df7-8d5acf9ae794)12KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FgS6Obp4amonTVi2QYRlR%2FTerraform-Entro.tf?alt=media&token=6e1d2f3e-1aff-4eb4-9df7-8d5acf9ae794)[Terraform-Entro - Europe region.tf](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2Ffkmf6UwXcWLxrnGJOeaX%2FTerraform-Entro%20-%20Europe%20region.tf?alt=media&token=b56e1a72-aa00-47ae-82d7-5222db774314)12KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2Ffkmf6UwXcWLxrnGJOeaX%2FTerraform-Entro%20-%20Europe%20region.tf?alt=media&token=b56e1a72-aa00-47ae-82d7-5222db774314)

Please note the external_id and remote_agent variables which will be provided by the Entro team
GitBook Assistant
## Troubleshooting[#troubleshooting](#troubleshooting)
StackSet deployment fails[#stackset-deployment-fails](#stackset-deployment-fails)

Cause:
GitBook Assistant

- 

Missing permissions in target accounts
GitBook Assistant

Resolution:
GitBook Assistant

- 

Verify delegated admin permissions and StackSet IAM execution role
GitBook Assistant
Accounts not appearing in Entro[#accounts-not-appearing-in-entro](#accounts-not-appearing-in-entro)

Cause:
GitBook Assistant

- 

Trust policy mismatch
GitBook Assistant

Resolution:
GitBook Assistant

- 

Ensure each IAM Role trusts Entro’s AWS Account ID
GitBook Assistant
Partial sync[#partial-sync](#partial-sync)

Cause:
GitBook Assistant

- 

Network egress blocked
GitBook Assistant

Resolution:
GitBook Assistant

- 

Allow HTTPS/TLS to Entro’s API endpoints
GitBook Assistant
[PreviousAWS Onboarding Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps)[NextAWS Manual Onboarding](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding)

Last updated 3 months ago

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [Setup Steps](#setup-steps)
- [Troubleshooting](#troubleshooting)
