# What SailPoint Connect changes

SailPoint Connect prepares a connector or an Entro integration. It does not change your cloud tenant, your identity provider, or Identity Security Cloud unless you choose `Run` and answer yes.

People are right to hesitate before pointing a setup tool at production. The ordinary way to use this module never writes there.

## Four ways through it

| Action | What you get | What happens to the tenant |
| --- | --- | --- |
| `BuildRequirements` | A Markdown checklist of the role, app, service account, or API client this integration needs, including read-only versus read-write and any feature packs you selected | Nothing |
| `Check` | A read of an identity that **already exists**, and a report of which of those requirements it already has | Nothing. It only reads. |
| `BuildScript` | A script you can read, attach to a change, and run later under your own process | Nothing, until someone runs that script |
| `Run` | The identity is created or updated | This is the only action that writes, and only after you see the plan and answer yes |

In the wizard, that choice is the first question, before the project, the connector, or any value. Interactive mode defaults to `BuildRequirements`. Pressing Enter does not apply anything.

`Run` still supports `-WhatIf`, which prints the steps and does not write. `Check` is already read-only; `-WhatIf` on `Check` skips the tenant read as well and writes the checklist of what it would have compared.

## Discovery is a pick-list, not the path

Some questions can offer names that already exist: an IAM role, a CloudTrail bucket, a Google project, a Databricks account. That happens only when you are signed in to the platform CLI, and only to save typing.

You can always type the value. If you are not signed in, the wizard defaults to typing every value yourself. Signing in is offered as a second choice, and it is described as a read: the CLI is used to list names, not to create them.

A later question still asks what should happen. Offering a list of existing roles does not create a role.

## Check an identity you already have

Use `Check` when the role, app registration, or service account was created by your own change process and you want to know whether it is enough for the integration you selected.

```powershell
# AWS: read the IAM role. Does not create it.
Connect-SailPointAWS -SaaSConnector -Access ReadOnly -RoleName 'SailPointAWSRole' -Action Check

# Entra: read granted application permissions (admin consent), not merely requested ones.
Connect-SailPointAzure -Connector -ApplicationName 'SailPoint-ISC' -Access ReadOnly -Action Check

# Google: read IAM permissions on the service account.
# OAuth scopes and domain-wide delegation are set in the Admin console;
# the report lists those for a person to compare.
Connect-SailPointGoogleCloud -SaaSConnector -ProjectId 'sec-proj' -OrganizationId '123' -Action Check
```

The report is a local file, `*-check.md`, next to the requirements checklist. The verdict is one of:

- **Meets the requirements.** Every requirement this check can read is present on that identity.
- **Does not meet the requirements.** Something required is missing, denied, or the identity was not found. The report names the gaps. In `-NonInteractive` mode this fails the command. Nothing was changed either way.
- **Needs a person to finish the comparison.** Part of the requirement cannot be read from the CLI (for example Google Admin console delegation, a Databricks Account Admin assignment, a Salesforce Connected App, a GitHub credential, or a CrowdStrike API client), or you ran `Check` without a CLI session. The report says exactly what to open.

`ReadOnly` does not fail the check because write permissions are absent. Those are listed as "not required for ReadOnly". Choose `-Access ReadWrite` when you want the write permissions included.

An AWS check reads the role's attached and inline policies, including managed policies, and treats a broader action such as `iam:*` as covering `iam:ListUsers`. An explicit deny covers the action even when another statement allows it. An Entra check reads **granted** app roles on the service principal. A permission that is only requested, and not consented, does not count.

## A production sequence that never has to write

1. Run `BuildRequirements` for the connector, access level, and feature packs you actually want. Send that file to the team that owns the tenant.
2. That team creates a new identity, or points at one they already have, under their change process.
3. Run `Check` against that identity. Fix only what the report says is missing. Run `Check` again.
4. Paste the connection settings (role name, client id, external id, and so on) into Identity Security Cloud.

You do not have to use `Run` at all. `Run` is there when you have decided this machine should be the thing that applies the change, and you have confirmed the plan.
