IAM Role Creation Steps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-role-creation-steps.md).

After creating the `EntroReadOnlyAccess` policy, the next step is to create an IAM Role that Entro can securely assume. This role establishes a trust relationship with Entro’s AWS Account and applies the read-only permissions from the previously created policy.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

AWS Console → IAM → Roles → Create Role → Another AWS Account
GitBook Assistant1
#### Create a New IAM Role[#create-a-new-iam-role](#create-a-new-iam-role)

- 

Sign in to the **AWS Management Console**.
GitBook Assistant
- 

Navigate to **IAM → Roles → Create Role**.
GitBook Assistant
- 

Under **Trusted Entity Type**, select **Another AWS Account**.
GitBook Assistant
- 

In the **Account ID** field, enter the **Entro AWS Account ID** displayed in the Entro setup wizard.
GitBook Assistant
- 

Check **Require external ID** and paste the **External ID** provided by Entro.
GitBook Assistant
- 

Click **Next**.
GitBook Assistant
2
#### Attach the Entro Policy[#attach-the-entro-policy](#attach-the-entro-policy)

- 

From the list of policies, search for `EntroReadOnlyAccess`.
GitBook Assistant
- 

Select the checkbox next to it.
GitBook Assistant
- 

Click **Next: Tags** (optional).
GitBook Assistant
- 

Choose **Next: Review**.
GitBook Assistant
- 

Enter the following details:
GitBook Assistant

- 

**Role name:** `EntroRoleAWS` (Must begin with "EntroRole")
GitBook Assistant
- 

**Description:** *Allows Entro Security to assume a read-only role for AWS integration.*
GitBook Assistant

- 

Click **Create Role**.
GitBook Assistant
3
#### Review Trust Relationship[#review-trust-relationship](#review-trust-relationship)

After the role is created, verify its **Trust Relationship** in the AWS Console. This defines the permission for Entro to assume the role using the external ID.
GitBook Assistant

Example JSON:
GitBook Assistanttrust-policy.jsonGitBook AssistantAskCopy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "AWS": "arn:aws:iam::<ENTRO_ACCOUNT_ID>:user/liminal-saas-assume-role"
            },
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "<ENTRO_EXTERNAL_ID>"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "AWS": "arn:aws:iam::<ENTRO_ACCOUNT_ID>:role/EntroTrustRole-<ENTRO_EXTERNAL_ID>"
            },
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "<ENTRO_EXTERNAL_ID>"
                }
            }
        }
    ]
}
```
4
#### Confirm Role Creation[#confirm-role-creation](#confirm-role-creation)

Return to **IAM → Roles** and verify:
GitBook Assistant

- 

Role name = `EntroRoleAWS`
GitBook Assistant
- 

Attached policy = `EntroReadOnlyAccess`
GitBook Assistant
- 

Trust relationship includes Entro’s AWS Account ID and External ID
GitBook Assistant
5
#### Retrieve Role ARN[#retrieve-role-arn](#retrieve-role-arn)

1. 

Click on the created role.
GitBook Assistant
1. 

Copy the **Role ARN** (e.g. `arn:aws:iam::123456789012:role/EntroRoleAWS`).
GitBook Assistant
1. 

You’ll use this ARN in the next step to connect the role to Entro.
GitBook Assistant

Security Validation
GitBook Assistant

- 

Entro assumes this role using temporary credentials only.
GitBook Assistant
- 

No write, delete, or modify actions are permitted.
GitBook Assistant
- 

Role usage can be monitored in AWS CloudTrail for full traceability.
GitBook Assistant
[PreviousIAM Policy Creation Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-policy-creation-steps)[NextAssume Role Link to Entro](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/assume-role-link-to-entro)

Last updated 4 months ago
