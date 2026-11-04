# `Connect-SailPointAWS`

Configures SailPoint ISC AWS connectors and Entro cloud integrations.

## Synopsis

```powershell
Connect-SailPointAWS [-Wizard] [-SaaSConnector] [-CiemConnector] [-Entro]
    [-Method <String>] [-Cloud <String>] [-Region <String>]
    [-Access <String>] [-Action <String>] [-IscExternalId <String>]
    [-EntroExternalId <String>] [-RoleName <String>] [-Project <String>]
    [-OutputDirectory <String>] [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointAWS` configures AWS IAM roles, policies, and CloudFormation stacks for:
1. **Amazon Web Services SaaS connector**: Creates or updates the connector IAM role with tailored ReadOnly or ReadWrite policies and STS external-ID trust.
2. **AWS CIEM connector**: Provisions CloudFormation stacks and integrates CloudTrail S3 bucket event notifications.
3. **Entro AWS Onboarding**: Creates the Entro IAM trust and permissions across commercial AWS or GovCloud.
4. **Combined SaaS + Entro**: Configures both ISC SaaS connector and Entro in a single coordinated run.

## Parameters

### `-Wizard`
Launches the interactive questionnaire. Discovers existing IAM roles and CloudTrail buckets via AWS CLI.

### `-SaaSConnector`
Selects the ISC Amazon Web Services SaaS connector IAM role.

### `-CiemConnector`
Selects the AWS CIEM CloudFormation connector.

### `-Entro`
Selects the Entro AWS integration. Can be combined with `-SaaSConnector`.

### `-Method`
Entro onboarding method: `AssumeRole`, `CloudFormation`, or `Terraform`.

### `-Cloud`
AWS environment: `Commercial` (default) or `GovCloud`.

### `-Access`
Permission level: `ReadOnly` or `ReadWrite`.

### `-Action`
`Run`, `BuildScript`, or `BuildRequirements`.

### `-IscExternalId`
External ID for the ISC connector trust relationship.

### `-EntroExternalId`
External ID for the Entro trust relationship.

## Examples

### Example 1: Guided interactive setup
```powershell
Connect-SailPointAWS -Wizard
```

### Example 2: Combined ISC + Entro requirements build
```powershell
Connect-SailPointAWS -SaaSConnector -Entro `
    -IscExternalId "isc-ext-001" `
    -EntroExternalId "entro-ext-002" `
    -Action BuildRequirements `
    -Project "aws-client"
```
