IAM Policy Creation Steps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-policy-creation-steps.md).

This section outlines how to create the **EntroReadOnlyAccess** policy required for Entro to securely connect to your AWS environment using least-privilege permissions.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

AWS Console → IAM → Policies → Create Policy → JSON Tab
GitBook Assistant
## Overview[#overview](#overview)

The policy grants Entro read-only access to the relevant AWS services. This ensures that Entro can **discover and monitor secrets** without having permissions to modify or delete resources.
GitBook Assistant1
#### Create a New Policy[#create-a-new-policy](#create-a-new-policy)

- 

Sign in to the **AWS Management Console**.
GitBook Assistant
- 

Navigate to **IAM → Policies → Create Policy**.
GitBook Assistant
- 

Select the **JSON** tab and replace any existing text with [the policy below](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-policy-creation-steps#iam-policy).
GitBook Assistant
2
#### Review and Name the Policy[#review-and-name-the-policy](#review-and-name-the-policy)

- 

Choose **Next: Tags** (optional).
GitBook Assistant
- 

Choose **Next: Review**.
GitBook Assistant
- 

Enter the following details:
GitBook Assistant

- 

**Name:** `EntroReadOnlyAccess`
GitBook Assistant
- 

**Description:** *Provides read-only access for Entro Security integration.*
GitBook Assistant

- 

Click **Create Policy**.
GitBook Assistant
3
#### Verify the Policy[#verify-the-policy](#verify-the-policy)

After creation, confirm the policy exists in IAM:
GitBook Assistant

- 

Navigate to **IAM → Policies**.
GitBook Assistant
- 

Search for `EntroReadOnlyAccess`.
GitBook Assistant
- 

Confirm that the **policy ARN** matches the expected format: `arn:aws:iam::<account-id>:policy/EntroReadOnlyAccess`.
GitBook Assistant
IAM Policy[#iam-policy](#iam-policy)EntroReadOnlyAccess policy.jsonGitBook AssistantAskCopy
```
{
  "Version": "2012-10-17",
  "Statement": [
                {
                  "Effect": "Allow",
                  "Action": [
                    "secretsmanager:ListSecrets",
                    "secretsmanager:TagResource",
                    "secretsmanager:GetResourcePolicy",
                    "secretsmanager:DescribeSecret",
                    "secretsmanager:ValidateResourcePolicy",
                    "secretsmanager:ListSecretVersionIds",
                    "kms:DescribeKey",
                    "kms:ListAliases",
                    "kms:ListKeys",
                    "EC2:Get*",
                    "EC2:Describe*",
                    "EC2:List*",
                    "s3:GetObject",
                    "s3:ListBucket",
                    "cloudtrail:DescribeTrails",
                    "cloudtrail:GetTrailStatus",
                    "cloudtrail:GetEventSelectors",
                    "cloudtrail:LookupEvents",
                    "cloudformation:DescribeChangeSet",
                    "cloudformation:DescribeStackResource",
                    "cloudformation:DescribeStacks",
                    "lambda:ListFunctions",
                    "lambda:GetFunction",
                    "iam:Get*",
                    "iam:List*",
                    "iam:GenerateServiceLastAccessedDetails",
                    "rds:Describe*",
                    "rds:ListTagsForResource",
                    "ssm:ListCommands",
                    "ssm:ListDocumentVersions",
                    "ssm:ListDocumentMetadataHistory",
                    "ssm:DescribeMaintenanceWindowSchedule",
                    "ssm:DescribeInstancePatches",
                    "ssm:ListInstanceAssociations",
                    "ssm:GetParameter",
                    "ssm:GetMaintenanceWindowExecutionTaskInvocation",
                    "ssm:DescribeAutomationExecutions",
                    "ssm:GetMaintenanceWindowTask",
                    "ssm:DescribeMaintenanceWindowExecutionTaskInvocations",
                    "ssm:DescribeAutomationStepExecutions",
                    "ssm:ListOpsMetadata",
                    "ssm:DescribeParameters",
                    "ssm:ListResourceDataSync",
                    "ssm:ListDocuments",
                    "ssm:DescribeMaintenanceWindowsForTarget",
                    "ssm:ListComplianceItems",
                    "ssm:GetConnectionStatus",
                    "ssm:GetMaintenanceWindowExecutionTask",
                    "ssm:GetOpsItem",
                    "ssm:GetMaintenanceWindowExecution",
                    "ssm:ListResourceComplianceSummaries",
                    "ssm:GetParameters",
                    "ssm:GetOpsMetadata",
                    "ssm:ListOpsItemRelatedItems",
                    "ssm:DescribeOpsItems",
                    "ssm:DescribeMaintenanceWindows",
                    "ssm:DescribeEffectivePatchesForPatchBaseline",
                    "ssm:GetServiceSetting",
                    "ssm:DescribeAssociationExecutions",
                    "ssm:DescribeDocumentPermission",
                    "ssm:ListCommandInvocations",
                    "ssm:GetAutomationExecution",
                    "ssm:DescribePatchGroups",
                    "ssm:GetDefaultPatchBaseline",
                    "ssm:DescribeDocument",
                    "ssm:DescribeMaintenanceWindowTasks",
                    "ssm:ListAssociationVersions",
                    "ssm:GetPatchBaselineForPatchGroup",
                    "ssm:PutConfigurePackageResult",
                    "ssm:DescribePatchGroupState",
                    "ssm:DescribeMaintenanceWindowExecutions",
                    "ssm:GetManifest",
                    "ssm:DescribeMaintenanceWindowExecutionTasks",
                    "ssm:DescribeInstancePatchStates",
                    "ssm:DescribeInstancePatchStatesForPatchGroup",
                    "ssm:GetDocument",
                    "ssm:GetInventorySchema",
                    "ssm:GetParametersByPath",
                    "ssm:GetMaintenanceWindow",
                    "ssm:DescribeInstanceAssociationsStatus",
                    "ssm:DescribeAssociationExecutionTargets",
                    "ssm:GetPatchBaseline",
                    "ssm:DescribeInstanceProperties",
                    "ssm:ListInventoryEntries",
                    "ssm:DescribeAssociation",
                    "ssm:ListOpsItemEvents",
                    "ssm:GetDeployablePatchSnapshotForInstance",
                    "ssm:DescribeSessions",
                    "ssm:GetParameterHistory",
                    "ssm:DescribeMaintenanceWindowTargets",
                    "ssm:DescribePatchBaselines",
                    "ssm:DescribeEffectiveInstanceAssociations",
                    "ssm:DescribeInventoryDeletions",
                    "ssm:DescribePatchProperties",
                    "ssm:GetInventory",
                    "ssm:GetOpsSummary",
                    "ssm:DescribeActivations",
                    "ssm:GetCommandInvocation",
                    "ssm:ListComplianceSummaries",
                    "ssm:DescribeInstanceInformation",
                    "ssm:ListTagsForResource",
                    "ssm:DescribeDocumentParameters",
                    "ssm:GetCalendar",
                    "ssm:ListAssociations",
                    "ssm:GetCalendarState",
                    "ssm:DescribeAvailablePatches",
                    "lambda:ListVersionsByFunction",
                    "lambda:GetLayerVersion",
                    "lambda:GetAccountSettings",
                    "lambda:GetFunctionConfiguration",
                    "lambda:GetLayerVersionPolicy",
                    "lambda:ListProvisionedConcurrencyConfigs",
                    "lambda:GetProvisionedConcurrencyConfig",
                    "lambda:ListTags",
                    "lambda:ListLayerVersions",
                    "lambda:ListLayers",
                    "lambda:ListCodeSigningConfigs",
                    "lambda:GetAlias",
                    "lambda:ListFunctions",
                    "lambda:GetEventSourceMapping",
                    "lambda:GetFunction",
                    "lambda:ListAliases",
                    "lambda:GetFunctionUrlConfig",
                    "lambda:ListFunctionUrlConfigs",
                    "lambda:GetFunctionCodeSigningConfig",
                    "lambda:ListFunctionEventInvokeConfigs",
                    "lambda:ListFunctionsByCodeSigningConfig",
                    "lambda:GetFunctionConcurrency",
                    "lambda:GetFunctionEventInvokeConfig",
                    "lambda:ListEventSourceMappings",
                    "lambda:GetCodeSigningConfig",
                    "lambda:GetPolicy",
                    "eks:ListNodegroups",
                    "eks:DescribeFargateProfile",
                    "eks:ListTagsForResource",
                    "eks:ListAddons",
                    "eks:DescribeAddon",
                    "eks:ListFargateProfiles",
                    "eks:DescribeNodegroup",
                    "eks:DescribeIdentityProviderConfig",
                    "eks:ListUpdates",
                    "eks:DescribeUpdate",
                    "eks:AccessKubernetesApi",
                    "eks:DescribeCluster",
                    "eks:ListClusters",
                    "eks:DescribeAddonVersions",
                    "eks:ListIdentityProviderConfigs",
                    // Optional permissions to support future feature
                    // This will allow gathering better context about accounts and NHIs
                    "organizations:ListAccounts",
                    "sso:ListInstances",
                    "identitystore:ListUsers",
                    "identitystore:ListGroupMembershipsForMember","sso:ListPermissionSets",
                    "sso:GetInlinePolicyForPermissionSet",
                    "sso:ListManagedPoliciesInPermissionSet",
                    "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
                    "sso:DescribePermissionSet",
                    "sso:DescribePermissionSet",
                    "sso:ListAccountsForProvisionedPermissionSet",
                    "sso:ListAccountAssignments",
                    "sso:ListManagedPoliciesInPermissionSet",
                    "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
                    "sso:ListInstances",
                    "sso:ListPermissionSets",
                    "identitystore:DescribeUser",
                    // Bedrock AI
                    "bedrock-agentcore:List*",
                    "bedrock-agentcore:Get*",
                    "bedrock:List*",
                    "bedrock:Get*"
                    // Zero Trust Prevention
                    "iam:GetUserPolicy",
                    "iam:PutUserPolicy",
                    "iam:DeleteUserPolicy",
                    "iam:GetLoginProfile"
                  ],
      "Resource": "*"
    }
  ]
}
```

Security Principle
GitBook Assistant

The EntroReadOnlyAccess policy adheres to the **least privilege** model:
GitBook Assistant

- 

No write or delete actions permitted.
GitBook Assistant
- 

No access to resource content beyond metadata and secret identifiers.
GitBook Assistant
- 

Only discovery-level visibility for inventory synchronization.
GitBook Assistant
[PreviousAWS Manual Onboarding](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding)[NextIAM Role Creation Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/iam-role-creation-steps)

Last updated 3 months ago

- [Navigation Path](#navigation-path)
- [Overview](#overview)
