# `Connect-SailPointAWS`

Configures SailPoint ISC AWS connectors and Entro cloud integrations.

## Synopsis

```powershell
Connect-SailPointAWS [-Wizard] [-SaaSConnector] [-CiemConnector] [-Entro]
    [-Method <String>] [-Cloud <String>] [-Region <String>]
    [-Feature <String[]>] [-Scope <String>] [-Access <String>]
    [-Action <String>] [-IscExternalId <String>] [-EntroExternalId <String>]
    [-RoleName <String>] [-Project <String>] [-OutputDirectory <String>]
    [-NonInteractive] [<CommonParameters>]
```

## Description

`Connect-SailPointAWS` configures AWS IAM roles and policies for:
1. **Amazon Web Services connector**: Creates or updates the connector IAM role with tailored ReadOnly or ReadWrite policies and STS external-ID trust (including optional `-Feature Ciem` for CloudTrail + Identity Center CIEM permissions).
2. **Entro AWS Onboarding**: Creates the Entro IAM trust and permissions across commercial AWS or GovCloud.
3. **Combined Connector + Entro**: Configures both ISC AWS connector and Entro in a single coordinated run.

## Parameters

### `-Wizard`
Launches the interactive questionnaire. You can type every value. If you are signed in, some questions also offer existing IAM roles and CloudTrail buckets. That pick-list does not create them. The default action is a checklist.

### `-SaaSConnector`
Selects the ISC Amazon Web Services connector IAM role (add `-Feature Ciem` to include CIEM permissions).

### `-CiemConnector`
Backward-compatible alias that targets the AWS connector with the `Ciem` feature enabled.

### `-Entro`
Selects the Entro AWS integration. Can be combined with `-SaaSConnector`.

### `-Feature`
Optional feature packs for the AWS connector (`ActivityInsights`, `AgentDiscovery`, `Ciem`).

### `-Scope`
AWS deployment scope (`CurrentAccount` or `Organization`). With `Organization` and `-Feature Ciem`, attaches the CIEM Identity Center permission policy.

### `-Method`
Entro onboarding method: `AssumeRole`, `CloudFormation`, or `Terraform`.

### `-Cloud`
AWS environment: `Commercial` (default) or `GovCloud`.

### `-Access`
Permission level: `ReadOnly` or `ReadWrite`.

### `-Action`
`BuildRequirements` (checklist), `Check` (read an existing IAM role and report gaps), `BuildScript` (review, then run it yourself), or `Run` (the only action that changes the account, after you confirm).

### `-IscExternalId`
External ID for the ISC connector trust relationship.

### `-EntroExternalId`
External ID for the Entro trust relationship.

## Examples

### Example 1: Guided interactive setup
```powershell
Connect-SailPointAWS -Wizard
```

### Example 2: Read an existing role
```powershell
Connect-SailPointAWS -SaaSConnector -Access ReadOnly -RoleName "SailPointAWSRole" -Action Check
```
Reports whether that role already has the ReadOnly permissions. Nothing is created.

### Example 3: Combined ISC + Entro requirements build
```powershell
Connect-SailPointAWS -SaaSConnector -Entro `
    -IscExternalId "isc-ext-001" `
    -EntroExternalId "entro-ext-002" `
    -Action BuildRequirements `
    -Project "aws-client"
```
