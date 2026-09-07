Assume Role Link to Entro | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/assume-role-link-to-entro.md).

This section explains how to connect the IAM Role you created in AWS to Entro Security. By linking the role via its **Role ARN**, Entro can securely assume the role to read metadata and detect exposed secrets, without storing or using long‑term credentials.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

AWS Console → IAM → Roles → Create Role → Another AWS Account
GitBook Assistant1
#### Retrieve the IAM Role ARN[#retrieve-the-iam-role-arn](#retrieve-the-iam-role-arn)

- 

In the **AWS Console**, go to **IAM → Roles**.
GitBook Assistant
- 

Locate the role you created earlier (`EntroRoleAWS`).
GitBook Assistant
- 

Copy its **Role ARN** (e.g. `arn:aws:iam::123456789012:role/EntroRoleAWS`).
GitBook Assistant
2
#### Open the Entro Dashboard[#open-the-entro-dashboard](#open-the-entro-dashboard)

- 

Log into the **Entro Security Dashboard**.
GitBook Assistant
- 

Navigate to **Management → Accounts & Integrations → Add New Account**.
GitBook Assistant
- 

Select **AWS → Manual Onboarding → Assume Role**.
GitBook Assistant
3
#### Enter Required Details[#enter-required-details](#enter-required-details)

In the Entro onboarding wizard:
GitBook AssistantFieldDescription

**AWS Role ARN**
GitBook Assistant

Paste the Role ARN copied from AWS.
GitBook Assistant

**Environment**
GitBook Assistant

Choose the environment (e.g., `Production`, `Development`).
GitBook Assistant

**Worker Group (Connector)**
GitBook Assistant

Select the connector that will handle sync operations.
GitBook Assistant

Once the fields are filled out, click **Create Account**.
GitBook Assistant4
#### Validation[#validation](#validation)

- 

Entro attempts to assume the IAM Role using AWS STS.
GitBook Assistant
- 

On success, the integration status will display as **Active**.
GitBook Assistant
- 

Secrets, tokens, and NHIs from AWS begin populating automatically under **Inventory → Secrets** and **Inventory → NHIs**.
GitBook Assistant
5
#### Optional CloudTrail Verification[#optional-cloudtrail-verification](#optional-cloudtrail-verification)

To verify the assume-role activity in AWS CloudTrail:
GitBook Assistant

- 

Go to **CloudTrail → Event History**.
GitBook Assistant
- 

Search for `Event name = AssumeRole`.
GitBook Assistant
- 

Confirm the **Principal** corresponds to Entro’s AWS Account ID.
GitBook Assistant

## Troubleshooting[#troubleshooting](#troubleshooting)
Entro cannot assume role[#entro-cannot-assume-role](#entro-cannot-assume-role)

- 

Cause: External ID mismatch or incorrect ARN
GitBook Assistant
- 

Resolution: Verify the role's trust relationship (allowing Entro to assume the role) and confirm the Role ARN you pasted is correct.
GitBook Assistant
Account not appearing in Entro[#account-not-appearing-in-entro](#account-not-appearing-in-entro)

- 

Cause: Permission or network issue
GitBook Assistant
- 

Resolution: Ensure the EntroReadOnlyAccess policy is attached to the role and that outbound HTTPS is allowed from your network to permit the integration.
GitBook Assistant
Secrets not syncing[#secrets-not-syncing](#secrets-not-syncing)

- 

Cause: Insufficient permissions
GitBook Assistant
- 

Resolution: Review the attached IAM Policy for missing actions required to list/read the resources Entro needs.
GitBook Assistant

## Security Note[#security-note](#security-note)

- 

Entro uses **temporary AWS STS credentials** to assume your IAM role.
GitBook Assistant
- 

No permanent credentials are stored.
GitBook Assistant
- 

All communications are encrypted using **HTTPS/TLS**.
GitBook Assistant
[PreviousIAM Role Creation Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-role-creation-steps)[NextAWS CloudTrail S3 Setup](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Troubleshooting](#troubleshooting)
- [Security Note](#security-note)
