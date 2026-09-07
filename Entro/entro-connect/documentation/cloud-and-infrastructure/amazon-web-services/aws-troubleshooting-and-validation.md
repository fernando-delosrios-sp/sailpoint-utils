AWS Troubleshooting and Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-troubleshooting-and-validation.md).

This section outlines verification procedures and troubleshooting steps for AWS integrations in Entro Security. Use it to confirm successful setup or to resolve common onboarding and synchronization issues.
GitBook Assistant
## Overview[#overview](#overview)

After integrating AWS, Entro performs continuous sync and health validation. The following checks and commands help you verify the connection and fix configuration issues.
GitBook Assistant
## Validation Checklist[#validation-checklist](#validation-checklist)
Validation ItemExpected ResultVerification Location

**AWS Account shows as Active**
GitBook Assistant

Integration status = “Active”
GitBook Assistant

Entro Dashboard → Integrations → AWS
GitBook Assistant

**Secrets discovered**
GitBook Assistant

Secrets appear under *Inventory → Secrets*
GitBook Assistant

Entro Dashboard
GitBook Assistant

**NHIs discovered**
GitBook Assistant

NHIs appear under *Inventory → NHIs*
GitBook Assistant

Entro Dashboard
GitBook Assistant

**IAM Policy attached**
GitBook Assistant

`EntroReadOnlyAccess` attached to `EntroRoleAWS` role 
GitBook Assistant

AWS Console → IAM → Roles
GitBook Assistant

**Trust relationship valid**
GitBook Assistant

Entro AWS Account ID + External ID configured
GitBook Assistant

AWS Console → IAM → Role → Trust Relationships
GitBook Assistant

**CloudTrail connected (optional)**
GitBook Assistant

CloudTrail status = “Connected”
GitBook Assistant

Entro Dashboard → Integrations → AWS → CloudTrail
GitBook Assistant

**Logs visible in S3**
GitBook Assistant

AWSLogs folder populated
GitBook Assistant

AWS Console → S3
GitBook Assistant1
#### Verify Role Assumption[#verify-role-assumption](#verify-role-assumption)

Use the AWS CLI to confirm that Entro can assume the integration role.
GitBook AssistantGitBook AssistantAskCopy
```
aws sts assume-role   --role-arn arn:aws:iam::<account-id>:role/EntroAWSIntegrationRole   --role-session-name EntroValidationTest
```

If successful, you’ll receive a temporary security token. If not, review the trust relationship JSON and ensure the external ID matches.
GitBook Assistant2
#### Confirm IAM Permissions[#confirm-iam-permissions](#confirm-iam-permissions)

Simulate permissions for Entro’s role:
GitBook AssistantGitBook AssistantAskCopy
```
aws iam simulate-principal-policy   --policy-source-arn arn:aws:iam::<account-id>:role/EntroAWSIntegrationRole   --action-names secretsmanager:ListSecrets ssm:GetParameter kms:DescribeKey
```

All actions should return `"allowed": true`.
GitBook Assistant3
#### Check CloudFormation Stack (Automatic Setup)[#check-cloudformation-stack-automatic-setup](#check-cloudformation-stack-automatic-setup)

For CloudFormation-based integrations:
GitBook Assistant

- 

Go to AWS Console → CloudFormation → Stacks.
GitBook Assistant
- 

Locate the stack name (e.g., `Entro-AWS-Integration`).
GitBook Assistant
- 

Confirm stack status = `CREATE_COMPLETE`.
GitBook Assistant
- 

Review the **Resources** tab to verify IAM Role and Policy creation.
GitBook Assistant
4
#### Common Issues and Fixes[#common-issues-and-fixes](#common-issues-and-fixes)
SymptomLikely CauseResolution

**Integration not appearing in Entro**
GitBook Assistant

Role ARN incorrect
GitBook Assistant

Copy correct ARN from AWS IAM console
GitBook Assistant

**STS AssumeRole failed**
GitBook Assistant

Missing trust relationship or wrong external ID
GitBook Assistant

Update trust JSON in IAM Role
GitBook Assistant

**No secrets detected**
GitBook Assistant

Policy missing required actions
GitBook Assistant

Ensure `secretsmanager:ListSecrets` and `ssm:GetParameter` are present
GitBook Assistant

**CloudTrail access denied**
GitBook Assistant

Missing S3 read permissions
GitBook Assistant

Add `s3:GetObject` and `s3:ListBucket` to the policy
GitBook Assistant

**Sync incomplete**
GitBook Assistant

Network timeout or blocked endpoint
GitBook Assistant

Allow outbound HTTPS to `api.entro.security`
GitBook Assistant

**Duplicate AWS accounts**
GitBook Assistant

Integration added multiple times
GitBook Assistant

Remove redundant integration in Entro
GitBook Assistant5
#### Review Logs and API Responses[#review-logs-and-api-responses](#review-logs-and-api-responses)

Entro logs each synchronization attempt. Review these locations:
GitBook Assistant

- 

Entro Dashboard → Integrations → AWS → Logs
GitBook Assistant
- 

Activity → System Logs (for detailed sync attempts)
GitBook Assistant
6
#### AWS CloudTrail Verification[#aws-cloudtrail-verification](#aws-cloudtrail-verification)

To confirm that Entro has read access to your CloudTrail S3 bucket:
GitBook Assistant

- 

Navigate to CloudTrail → Event History.
GitBook Assistant
- 

Search for `EventName = AssumeRole`.
GitBook Assistant
- 

Confirm that the Principal corresponds to Entro’s AWS Account ID.
GitBook Assistant
- 

Verify log delivery frequency matches expected cadence.
GitBook Assistant

## Advanced Validation (Optional)[#advanced-validation-optional](#advanced-validation-optional)

### AWS CLI Secret Listing Test[#aws-cli-secret-listing-test](#aws-cli-secret-listing-test)

Run the following command under your Entro-assumed role:
GitBook Assistant

Expected result: a JSON list of secret metadata (not secret values).
GitBook Assistant
### AWS CloudTrail Log Check[#aws-cloudtrail-log-check](#aws-cloudtrail-log-check)

Expected result: timestamped log folders for recent events.
GitBook Assistant
## Network Requirements[#network-requirements](#network-requirements)
ComponentEndpointPortProtocol

**Entro API**
GitBook Assistant

`api.entro.security`
GitBook Assistant

443
GitBook Assistant

HTTPS
GitBook Assistant

**AWS API (STS, IAM, SSM, Secrets Manager)**
GitBook Assistant

`*.amazonaws.com`
GitBook Assistant

443
GitBook Assistant

HTTPS
GitBook Assistant
## Security Reminder[#security-reminder](#security-reminder)

Entro performs all actions using temporary STS credentials. No long-term keys are stored, and all requests are encrypted over HTTPS/TLS.
GitBook Assistant[PreviousConfigure Trail CloudTrail Console](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console)[NextAWS Permissions Reference](/integrations/cloud-and-infrastructure/amazon-web-services/aws-permissions-reference)

Last updated 4 months ago

- [Overview](#overview)
- [Validation Checklist](#validation-checklist)
- [Advanced Validation (Optional)](#advanced-validation-optional)
- [AWS CLI Secret Listing Test](#aws-cli-secret-listing-test)
- [AWS CloudTrail Log Check](#aws-cloudtrail-log-check)
- [Network Requirements](#network-requirements)
- [Security Reminder](#security-reminder)
GitBook AssistantAskCopy
```
aws secretsmanager list-secrets --max-items 5
```
GitBook AssistantAskCopy
```
aws s3 ls s3://<cloudtrail-logs-bucket>/AWSLogs/<account-id>/CloudTrail/
```
