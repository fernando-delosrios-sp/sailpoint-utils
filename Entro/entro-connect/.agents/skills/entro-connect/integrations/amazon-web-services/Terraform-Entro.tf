provider "aws" {
  region = "us-east-1" # DO NOT Change
}

# IAM Role
resource "aws_iam_role" "entro_role" {
  name = "EntroRole-${var.environment}-${local.timestamp}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::937217723901:user/liminal-saas-assume-role"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::937217723901:role/EntroTrustRole-${var.external_id}"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  inline_policy {
    name = "EntroPolicy-${var.environment}-${local.timestamp}"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
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
            "sso:ListInstances",
            "identitystore:ListUsers",
            "identitystore:ListGroupMembershipsForMember",
            "sso:ListPermissionSets",
            "sso:GetInlinePolicyForPermissionSet",
            "sso:ListManagedPoliciesInPermissionSet",
            "sso:ListCustomerManagedPolicyReferencesInPermissionSet",
            "sso:DescribePermissionSet",
            "sso:ListAccountsForProvisionedPermissionSet",
            "sso:ListAccountAssignments",
            "identitystore:DescribeUser",
            "organizations:ListAccounts",
            "bedrock-agentcore:List*",
            "bedrock-agentcore:Get*",
            "bedrock:List*",
            "bedrock:Get*"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

### Account alias/id lambda
# IAM Role for the account alias/id lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "EntroLambdaExecutionRole-${var.environment}-${local.timestamp}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

# Define the IAM Policy attached to the Lambda Role
resource "aws_iam_policy" "lambda_iam_policy" {
  name        = "EntroLambdaExecutionRolePolicy-${var.environment}-${local.timestamp}"
  description = "IAM policy for Entro lambda execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = "arn:aws:sns:us-east-1:937217723901:EntroSubsSns${var.sns_topic_arn_suffix}"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

data "aws_iam_account_alias" "account_alias" {}
# Data source to get the current account ID
data "aws_caller_identity" "current" {}

locals {
  account_alias = try(data.aws_iam_account_alias.account_alias.account_alias, data.aws_caller_identity.current.account_id)
}



# Send IAM Role ARN to existing SNS Topic in us-east-1
data "archive_file" "sns_lambda_code" {
  type        = "zip"
  output_path = "${path.root}/.archive_files/sns_lambda_code.zip"

  source {
    filename = "sns_publish.py"
    content  = <<CODE
import boto3
import os
import json

def lambda_handler(event, context):
    sns = boto3.client('sns', region_name='us-east-1')
    topic_arn = os.environ['TOPIC_ARN']

    message = {
        "ResourceProperties": {
            "RoleArn": event['role_arn'],
            "ExternalId": event['external_id'],
            "Environment": event['environment'],
            "RemoteAgent": event['remote_agent']
        },
        "RequestType": "Create",
        "ResponseURL": "https://app.entro.security/api/sns/response"
    }
    
    response = sns.publish(
        TopicArn=topic_arn,
        Message=json.dumps(message)
    )

    return response
CODE
  }
}

# Lambda function to publish to SNS
resource "aws_lambda_function" "sns_publish_lambda_function" {
  function_name = "EntroSNSPublishLambdaFunction-${var.environment}-${local.timestamp}"
  handler       = "sns_publish.lambda_handler"
  runtime       = "python3.8"
  timeout       = 30
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = data.archive_file.sns_lambda_code.output_path

  environment {
    variables = {
      TOPIC_ARN = "arn:aws:sns:us-east-1:937217723901:EntroSubsSns${var.sns_topic_arn_suffix}"
    }
  }
}

# Invoke the Lambda function to send the SNS message
resource "aws_lambda_invocation" "invoke_sns_publish" {
  function_name = aws_lambda_function.sns_publish_lambda_function.function_name

  input = jsonencode({
    role_arn     = aws_iam_role.entro_role.arn,
    external_id  = var.external_id,
    environment  = local.account_alias,
    remote_agent = var.remote_agent
  })
}

### Variables

variable "external_id" {
  description = "External ID for securing the role - Do not change"
  type        = string
}

variable "remote_agent" {
  description = "Remote agent - Do not change"
  type        = string
}

variable "sns_topic_arn_suffix" {
  description = "SNS Topic ARN Suffix - Provided by Entro if needed"
  type        = string
}

variable "environment" {
  description = "Environment - Provided by Entro"
  type        = string
}

locals {
  timestamp = formatdate("YYYYMMDDHHmmss", timestamp())
}
