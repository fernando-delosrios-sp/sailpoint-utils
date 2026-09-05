AWS Onboarding Steps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps.md).

The AWS Onboarding process connects your AWS environment to Entro for continuous discovery and monitoring of secrets, tokens, and Non-Human Identities (NHIs). You can onboard AWS accounts automatically using **CloudFormation** or manually using **IAM Role Assume** configuration.
GitBook Assistant
## Overview[#overview](#overview)

Entro offers two secure onboarding options for AWS:
GitBook AssistantMethodDescriptionRecommended For

**Automatic (CloudFormation)**
GitBook Assistant

Deploys a read-only IAM Role and Policy in AWS using a CloudFormation stack.
GitBook Assistant

Most environments and standard single-account setups
GitBook Assistant

**Manual (Assume Role)**
GitBook Assistant

Manually create an IAM Role, attach Entro's read-only policy, and link the Role ARN in Entro.
GitBook Assistant

Restricted environments or custom IAM management policies
GitBook Assistant

Both options enable Entro to continuously monitor secrets across AWS Secrets Manager, Parameter Store, and related NHIs - without granting write privileges or administrative control.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Before starting the onboarding process, ensure the following:
GitBook Assistant

- 

You have **Administrator Access** or sufficient permissions to create IAM Roles and Policies.
GitBook Assistant
- 

You can log into the target AWS Account via the AWS Management Console.
GitBook Assistant
- 

You have your **Entro AWS Account ID** and **External ID** (available in the Entro setup wizard).
GitBook Assistant
- 

Outbound HTTPS connectivity is enabled to `api.entro.security`.
GitBook Assistant
- 

Your network/firewall allows traffic to AWS and Entro endpoints.
GitBook Assistant

## Onboarding Flow[#onboarding-flow](#onboarding-flow)
1
#### Choose Onboarding Method[#choose-onboarding-method](#choose-onboarding-method)

When adding a new AWS account, Entro will prompt you to choose between:
GitBook Assistant

- 

**Automatic Setup (CloudFormation)** – the recommended path for fast and secure deployment.
GitBook Assistant
- 

**Manual Setup (Assume Role)** – for environments that prohibit CloudFormation stack deployment.
GitBook Assistant
2
#### Deploy or Create IAM Role[#deploy-or-create-iam-role](#deploy-or-create-iam-role)

Depending on the selected method:
GitBook Assistant

- 

**Automatic:** Launch Entro’s CloudFormation stack directly from the Entro Dashboard.
GitBook Assistant
- 

**Manual:** Follow the steps in [AWS Manual Onboarding](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding) to create an IAM Policy and Role manually.
GitBook Assistant
3
#### Verify Account Connection[#verify-account-connection](#verify-account-connection)

Once the setup is complete:
GitBook Assistant

1. 

Navigate to **Integrations → AWS** in Entro.
GitBook Assistant
1. 

Confirm that your AWS account appears as **Active**.
GitBook Assistant
1. 

Check the sync logs to verify that NHIs and secrets are being ingested.
GitBook Assistant
4
#### (Optional) Configure CloudTrail S3 Integration[#optional-configure-cloudtrail-s3-integration](#optional-configure-cloudtrail-s3-integration)

You can optionally enhance visibility by connecting **AWS CloudTrail logs**. This allows Entro to correlate secret activity with CloudTrail events and detect anomalous credential usage.
GitBook Assistant

Follow the guide at: [CloudTrail S3 Setup →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup)
GitBook Assistant5
#### Multi-Account Automation[#multi-account-automation](#multi-account-automation)

For organizations using multiple AWS accounts under an AWS Organization, Entro supports **multi-account automation**. This enables scalable onboarding using AWS StackSets or organizational IAM roles.
GitBook Assistant

Refer to: [AWS Multiple Account Automation →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation)
GitBook Assistant

Optional: Connecting CloudTrail S3 provides enhanced correlation between secret access/use and CloudTrail events, improving detection of anomalous credential behavior.
GitBook Assistant
## Validation Checklist[#validation-checklist](#validation-checklist)
CheckDescription

Account listed as Active
GitBook Assistant

Visible under Integrations → AWS
GitBook Assistant

Secrets detected
GitBook Assistant

Found under Inventory → Secrets
GitBook Assistant

NHIs discovered
GitBook Assistant

Found under Inventory → NHIs
GitBook Assistant

Optional CloudTrail connected
GitBook Assistant

Verified in integration summary
GitBook Assistant[PreviousAmazon Web Services](/integrations/cloud-and-infrastructure/amazon-web-services)[NextAWS Multiple Account Automation](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation)

Last updated 4 months ago

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Onboarding Flow](#onboarding-flow)
- [Validation Checklist](#validation-checklist)
GitBook AssistantAskCopy
```
Entro Security Dashboard
   ↓
Select AWS Integration
   ↓
Choose Setup Type (CloudFormation or Assume Role)
   ↓
Create IAM Policy and Role
   ↓
Entro assumes the AWS Role
   ↓
Secrets and NHIs sync into Entro Dashboard
```
