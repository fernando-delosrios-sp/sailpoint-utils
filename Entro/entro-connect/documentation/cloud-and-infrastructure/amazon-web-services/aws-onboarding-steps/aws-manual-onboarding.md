AWS Manual Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding.md).

If your organization restricts CloudFormation deployments, you can connect Entro to AWS manually using an **IAM Role Assume** configuration. This process involves creating a custom IAM Policy and Role, establishing a trust relationship with Entro’s AWS Account, and linking the Role ARN in the Entro Dashboard.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → AWS**
GitBook Assistant
## Overview[#overview](#overview)

Manual onboarding gives you complete control over permissions and policies while still providing Entro with read-only access. The process consists of three primary steps:
GitBook Assistant

- 

Create IAM Policy – Define least-privilege read-only access for secrets and NHIs.
GitBook Assistant
- 

Create IAM Role – Establish a trusted relationship with Entro’s AWS Account.
GitBook Assistant
- 

Connect Role to Entro – Paste the Role ARN into Entro’s setup wizard.
GitBook Assistant

## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (Assume Role)
AWS Account
   ├── IAM Policy (EntroReadOnlyAccess)
   ├── IAM Role (EntroAWSIntegrationRole)
   └── Secrets Manager / SSM / KMS
```

## Prerequisites[#prerequisites](#prerequisites)

1. 

IAM administrative privileges in the AWS account.
GitBook Assistant
1. 

Entro AWS Account ID and External ID (displayed in the Entro setup wizard).
GitBook Assistant
1. 

Outbound connectivity to `api.entro.security`.
GitBook Assistant
1. 

Optional: Access to CloudTrail S3 bucket if audit log correlation is desired.
GitBook Assistant
1
#### Create IAM Policy[#create-iam-policy](#create-iam-policy)

To grant Entro limited, read-only visibility into your AWS environment, create a policy named **EntroReadOnlyAccess**.
GitBook Assistant

Follow detailed instructions in: [IAM Policy Creation Steps →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-policy-creation-steps)
GitBook Assistant2
#### Create IAM Role[#create-iam-role](#create-iam-role)

Create a role named **EntroAWSIntegrationRole** that allows Entro’s AWS Account to assume it using the external ID provided in the wizard.
GitBook Assistant

Full instructions: [IAM Role Creation Steps →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-role-creation-steps)
GitBook Assistant3
#### Link the Role to Entro[#link-the-role-to-entro](#link-the-role-to-entro)

After creating the Role, copy its **Role ARN** from AWS IAM and paste it into Entro’s **Assume Role setup**.
GitBook Assistant

Detailed guide: [Assume Role Link to Entro →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/assume-role-link-to-entro)
GitBook Assistant
## (Optional) Connect CloudTrail Logs[#optional-connect-cloudtrail-logs](#optional-connect-cloudtrail-logs)

If you want Entro to correlate secret events with AWS CloudTrail, follow: [AWS CloudTrail S3 Setup →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup)
GitBook Assistant
## Validation Checklist[#validation-checklist](#validation-checklist)
CheckDescription

IAM Policy created
GitBook Assistant

EntroReadOnlyAccess exists in IAM
GitBook Assistant

IAM Role created
GitBook Assistant

EntroAWSIntegrationRole visible under IAM Roles
GitBook Assistant

Role trust policy configured
GitBook Assistant

Entro AWS Account ID and external ID correctly applied
GitBook Assistant

Role linked in Entro
GitBook Assistant

Account shows as Active in AWS Integrations
GitBook Assistant

Optional CloudTrail connected
GitBook Assistant

Verified under Integration Summary
GitBook Assistant
## Troubleshooting[#troubleshooting](#troubleshooting)
IssueCauseResolution

Role not assumable
GitBook Assistant

Trust policy missing Entro principal
GitBook Assistant

Update trust policy JSON
GitBook Assistant

Secrets not detected
GitBook Assistant

Missing Secrets Manager permission
GitBook Assistant

Reattach read-only policy
GitBook Assistant

Account not appearing in Entro
GitBook Assistant

Incorrect Role ARN
GitBook Assistant

Re-enter ARN from AWS IAM console
GitBook Assistant[PreviousAWS Multiple Account Automation](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation)[NextIAM Policy Creation Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-policy-creation-steps)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [(Optional) Connect CloudTrail Logs](#optional-connect-cloudtrail-logs)
- [Validation Checklist](#validation-checklist)
- [Troubleshooting](#troubleshooting)
