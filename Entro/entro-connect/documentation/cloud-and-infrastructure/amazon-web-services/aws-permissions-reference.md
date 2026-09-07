AWS Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-permissions-reference.md).

This page outlines all AWS IAM permissions, roles, and policy structures that Entro Security uses across its AWS integrations. It ensures transparency around access scopes, least-privilege compliance, and audit readiness for connected AWS environments.
GitBook Assistant
## Overview[#overview](#overview)

Entro Security integrates with AWS through read-only IAM Roles. All actions are restricted to discovery and metadata access. No modification, deletion, or secret extraction occurs.
GitBook Assistant

Entro supports the following integration types:
GitBook Assistant

- 

**CloudFormation** - automatic setup for single accounts
GitBook Assistant
- 

**Terraform** - Infrastructure-as-Code deployment (alternative to CloudFormation)
GitBook Assistant
- 

**StackSets (AWS Organizations)** - multi-account automation from the management account
GitBook Assistant

## IAM Roles Used[#iam-roles-used](#iam-roles-used)
Role NamePurposeCreated By

`EntroRoleAWS`
GitBook Assistant

Primary role Entro assumes to discover secrets and NHIs.
GitBook Assistant

CloudFormation or Manual setup
GitBook Assistant

`EntroReadOnlyAccess`
GitBook Assistant

Attached policy providing minimal read permissions.
GitBook Assistant

Manual or automated setup
GitBook Assistant

`EntroMultiAccountRole`
GitBook Assistant

Used during multi-account StackSets deployment.
GitBook Assistant

AWS Organizations automation
GitBook Assistant
## Base Read‑Only Policy (EntroReadOnlyAccess)[#base-read-only-policy-entroreadonlyaccess](#base-read-only-policy-entroreadonlyaccess)

This is the core IAM policy used in both single-account and multi-account setups.
GitBook Assistant
## Optional logging Permissions[#optional-logging-permissions](#optional-logging-permissions)

These permissions are automatically included when Entro detects CloudTrail or S3 log integrations. They enable secure, read-only access for audit correlation.
GitBook Assistant
## Zero Trust Permissions[#zero-trust-permissions](#zero-trust-permissions)

## Optional - Model Invocation Logging[#optional-model-invocation-logging](#optional-model-invocation-logging)

In case you use Amazon Bedrock, its recommended to enable the Model Invocation logs. This allows Entro to identify and display the identity of each model invoker.
GitBook Assistant

To set it up, follow the [instructions in AWS docs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-invocation-logging.html) to enable invocation logging and configure log delivery to Amazon S3.
GitBook Assistant
## Trust Relationship Template[#trust-relationship-template](#trust-relationship-template)

Entro assumes the AWS role using AWS STS and an external ID to prevent unauthorized access.
GitBook Assistant
## CloudFormation Automation Permissions (StackSets)[#cloudformation-automation-permissions-stacksets](#cloudformation-automation-permissions-stacksets)

When using AWS Organizations for automation, StackSets require additional permissions for delegated deployment.
GitBook Assistant
## Terraform Automation Permissions (Optional)[#terraform-automation-permissions-optional](#terraform-automation-permissions-optional)

When using **Terraform** for organization-wide deployment instead of CloudFormation, ensure the execution identity (user or CI/CD role) has the following permissions:
GitBook Assistant

**TerraformDelegationPermissions.json**
GitBook Assistant
## Security and Compliance Summary[#security-and-compliance-summary](#security-and-compliance-summary)
CategoryDescription

Principle of Least Privilege
GitBook Assistant

Entro’s AWS integrations only include discovery-level permissions.
GitBook Assistant

No Write Operations
GitBook Assistant

Entro never modifies or deletes AWS resources.
GitBook Assistant

Data Handling
GitBook Assistant

No secret plaintext leaves your AWS environment.
GitBook Assistant

Encryption
GitBook Assistant

All requests use HTTPS/TLS and signed AWS API calls.
GitBook Assistant

Logging
GitBook Assistant

All AWS actions are logged in CloudTrail.
GitBook Assistant
## Validation Checklist[#validation-checklist](#validation-checklist)
Validation ItemDescription

IAM Role Exists
GitBook Assistant

`EntroAWSIntegrationRole` visible under IAM Roles
GitBook Assistant

Policy Attached
GitBook Assistant

`EntroReadOnlyAccess` applied correctly
GitBook Assistant

Trust Relationship
GitBook Assistant

External ID and Entro Account ID verified
GitBook Assistant

CloudTrail Access (optional)
GitBook Assistant

Bucket policy includes `s3:GetObject` & `s3:ListBucket`
GitBook Assistant[PreviousAWS Troubleshooting and Validation](/integrations/cloud-and-infrastructure/amazon-web-services/aws-troubleshooting-and-validation)[NextAzure / Entra / M365](/integrations/cloud-and-infrastructure/azure)

Last updated 4 months ago

- [Overview](#overview)
- [IAM Roles Used](#iam-roles-used)
- [Base Read‑Only Policy (EntroReadOnlyAccess)](#base-read-only-policy-entroreadonlyaccess)
- [Optional logging Permissions](#optional-logging-permissions)
- [Zero Trust Permissions](#zero-trust-permissions)
- [Optional - Model Invocation Logging](#optional-model-invocation-logging)
- [Trust Relationship Template](#trust-relationship-template)
- [CloudFormation Automation Permissions (StackSets)](#cloudformation-automation-permissions-stacksets)
- [Terraform Automation Permissions (Optional)](#terraform-automation-permissions-optional)
- [Security and Compliance Summary](#security-and-compliance-summary)
- [Validation Checklist](#validation-checklist)
EntroReadOnlyAccess.jsonGitBook AssistantAskCopy
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:ListSecrets",
        "secretsmanager:DescribeSecret",
        "kms:DescribeKey",
        "kms:ListAliases",
        "ec2:Describe*",
        "cloudtrail:LookupEvents",
        "lambda:GetFunction",
        "iam:List*",
        "rds:Describe*",
        "ssm:GetParameter",
        "ssm:DescribeParameters",
        "eks:ListClusters",
        "s3:GetObject",
        "s3:ListBucket"
        "bedrock-agentcore:List*",
        "bedrock-agentcore:Get*",
        "bedrock:List*",
        "bedrock:Get*",
      ],
      "Resource": "*"
    }
  ]
}

```
CloudTrailBucketPermissions.jsonGitBook AssistantAskCopy
```
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::<cloudtrail-logs-bucket>",
    "arn:aws:s3:::<cloudtrail-logs-bucket>/*"
  ]
}
```
ZeroTrust.jsonGitBook AssistantAskCopy
```
{
    "Sid": "VisualEditor0",
    "Effect": "Allow",
    "Action": [
        "iam:GetUserPolicy",
        "iam:PutUserPolicy",
        "iam:DeleteUserPolicy",
        "iam:GetLoginProfile"
    ],
    "Resource": "*"
}
```
TrustRelationship.jsonGitBook AssistantAskCopy
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<ENTRO_ACCOUNT_ID>:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "<ENTRO_EXTERNAL_ID>"
        }
      }
    }
  ]
}
```
StackSetsDelegationPermissions.jsonGitBook AssistantAskCopy
```
{
  "Effect": "Allow",
  "Action": [
    "cloudformation:CreateStackInstances",
    "cloudformation:UpdateStackInstances",
    "cloudformation:DeleteStackInstances",
    "organizations:ListAccounts",
    "organizations:DescribeOrganization"
  ],
  "Resource": "*"
}
```
GitBook AssistantAskCopy
```
{
  "Effect": "Allow",
  "Action": [
    "iam:CreateRole",
    "iam:PutRolePolicy",
    "iam:AttachRolePolicy",
    "lambda:CreateFunction",
    "lambda:InvokeFunction",
    "sns:Publish",
    "cloudformation:DescribeStacks"
  ],
  "Resource": "*"
}
```
