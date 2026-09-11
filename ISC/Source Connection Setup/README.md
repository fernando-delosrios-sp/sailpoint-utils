# Source Connection Setup

## Purpose

Operator scripts for SailPoint Identity Security Cloud (ISC) source connectivity: cloud IAM setup for Entra ID, AWS, and Google Workspace SaaS connectors, and on-host IQService management for VA-based connectors.

## Artifacts

- `Entra ID.ps1` — Microsoft Graph script that creates or updates the Entra ID app registration, assigns the documented Graph application permissions, grants admin consent, assigns directory roles, and issues a client secret.
- `AWS.ps1` — AWS Tools for PowerShell script for the **Amazon Web Services SaaS** connector (native IAM role and `SP*` policies) or the **CIEM AWS** source (downloads and deploys SailPoint CloudFormation templates). Run one source type per invocation; each writes its own connection-settings file.
- `Google Workspace.ps1` — gcloud script for both Google Workspace SaaS grant types: creates or updates the service account, enables documented APIs, attaches an organization custom IAM role, converts the JSON key to the encrypted RSA PEM ISC expects, or runs the OAuth authorization-code flow for a refresh token.
- `IQService Control.ps1` — Windows operator script that downloads, installs, updates, and manages IQService (Integration Service) on a VA host.
- `Agent Source Setup.ps1` — JSON-driven headless facade for AI agents (`Catalog`, `Plan`, `Apply`). Secrets are written only to restricted files under `sourceConfig/<connector>/agent-runs/<run-id>/`; agent-visible JSON never contains secret values.

## Agent usage

Agents should use `Agent Source Setup.ps1` instead of interactive wizards.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd 'ISC/Source Connection Setup'

# 1. Discover connector options
.\Agent Source Setup.ps1 -Operation Catalog -Connector entra-id -OutputPath .\catalog.json

# 2. Build a plan from a request document (read-only discovery)
.\Agent Source Setup.ps1 -Operation Plan -Connector aws-saas `
  -RequestPath .\agent-schema\examples\aws-saas.request.json -OutputPath .\plan.json

# 3. Apply a ready plan (mutations; supports -WhatIf)
.\Agent Source Setup.ps1 -Operation Apply -Connector entra-id `
  -RequestPath .\request.json -PlanPath .\plan.json -OutputPath .\result.json
```

Request, plan, and result schemas live under `agent-schema/`. Example requests are in `agent-schema/examples/`.

**Secret policy**

- Pass sensitive inputs via `secretRefs` using `env:VARIABLE` or `file:/absolute/or/relative/path` only.
- Generated secrets (Entra client secret, Google keys/tokens, full connection-settings files with secrets) are written to `sourceConfig/<connector>/agent-runs/<run-id>/` with owner-only permissions.
- Agent stdout and JSON results contain labels and file paths only — never secret values or IQService signed download URLs.
- Authentication stays operator-local (Microsoft Graph sign-in, `aws sso login`, `gcloud auth login`, Windows admin on IQService hosts).

**Plan decisions**

Plans return `needsInput` when live discovery finds ambiguous state. Supply explicit `decisions` in the request JSON, for example:

| Connector | Decision fields |
| --- | --- |
| Entra ID | `targetAppObjectId`, `createNewApplication`, `allowGlobalAdministrator`, `createSecret` |
| AWS SaaS / CIEM | `updateExistingRole`, `approveOrganizationScope` |
| Google Workspace | `updateExistingServiceAccount` |
| IQService | `approveDestructive` (required for `Update` / `Uninstall`) |

## Modules

Shared PowerShell modules live under `modules/`. Each `.ps1` orchestrator imports them at startup.

| Module | Responsibility |
| --- | --- |
| `ISC.OperatorConsole.psm1` | Keyboard menus, Esc-back wizard, prompts, clipboard, completion copy/open menu |
| `ISC.OperatorToolchain.psm1` | PSGallery bootstrap (Graph, AWS.Tools), CLI install via winget/Homebrew, IQService ZIP payload |
| `ISC.AwsConnector.psm1` | AWS session, trust principals, Organizations context, IAM JSON helpers |
| `ISC.AwsSaasConnector.psm1` | AWS SaaS IAM policy tables, feature packs, role/policy deployment |
| `ISC.AwsCiemConnector.psm1` | Embedded CIEM (`-Feature Ciem`) and dedicated CIEM AWS source (CloudFormation) |
| `ISC.EntraConnector.psm1` | Entra permission tables, Graph app registration, consent, directory roles, secrets |
| `ISC.EntraCiemConnector.psm1` | Embedded CIEM (`-Feature Ciem`) — PIM group Graph permissions |
| `ISC.GoogleWorkspaceConnector.psm1` | gcloud/IAM, PEM conversion, OAuth and domain-wide delegation flows |
| `ISC.GoogleCiemConnector.psm1` | GCP/CIEM packs (`Gcp`, `Ciem`, `NhiDiscovery`, `AgentDiscovery`), org custom role |
| `ISC.IQService.psm1` | IQService discovery, install/update, service control, trace, log streaming |
| `ISC.AgentAdapter.psm1` | JSON envelope, request hashing, secret references, redaction, adapter dispatch |
| `ISC.EntraSourceSetup.psm1` | Entra catalog/plan/apply/result orchestration (wizard + agent) |
| `ISC.AwsSourceSetup.psm1` | AWS SaaS and CIEM catalog/plan/apply orchestration |
| `ISC.GoogleSourceSetup.psm1` | Google Workspace catalog/plan/apply orchestration |
| `ISC.IQServiceSourceSetup.psm1` | IQService catalog/plan/apply orchestration |

Each `ISC.*CiemConnector.psm1` exports the same embedded-CIEM interface: `Test-EmbeddedCiemSelected`, `Get-EmbeddedCiemFeaturePack`, `Apply-EmbeddedCiemPrerequisites`, `Build-EmbeddedCiemConnectionSettings`. AWS adds `Apply-DedicatedCiemSourceDeployment` / `Build-DedicatedCiemConnectionSettings` for `-SourceType CiemAws`.

Tests: `tests/Test-OperatorConsole.ps1`, `tests/Test-OperatorToolchain.ps1`, `tests/Test-EntraConnector.ps1`, `tests/Test-EntraCiemConnector.ps1`, `tests/Test-GoogleCiemConnector.ps1`, `tests/Test-AwsSaasConnector.ps1`, `tests/Test-AwsCiemConnector.ps1`, `tests/Test-AgentAdapter.ps1`, `tests/Test-EntraSourceSetup.ps1`, `tests/Test-AwsSourceSetup.ps1`.

### Development verification

From the repo root (no cloud credentials required for the unit tests):

```powershell
pwsh -NoProfile -File 'ISC/Source Connection Setup/tests/Invoke-AllSourceConnectionTests.ps1'
```

Each test prints `PASS (N assertions)` on success.

## Completion workflow (all scripts)

Every script ends with the same interactive pattern:

1. **Situation statement** — high-contrast white/yellow text describing what is done and what manual steps remain (never dim gray).
2. **Copy / Open menu** — arrow-key list of values and links formatted like `Role Name: SailPointAWSRole (Copy)` or `IAM role in AWS console: https://... (Open)`.

Controls:

- **Up/Down** (or `j`/`k`) move between items
- **Enter** copies the value or opens the URL
- **Save to disk (filename)** writes every menu value (unmasked secrets and Open links) to that connection-settings file under `sourceConfig/<source>`. AWS, Entra ID, and Google Workspace offer this; IQService Control does not.
- **Esc** or **Done** finishes (the menu stays open after each copy/open/save so you can work through several fields)
- **Ctrl+C** exits the script
- Sensitive values (client secrets, refresh tokens, private keys) show as `***` in the menu but copy the full value. External ID is shown in full. Save to disk writes those secrets in full.

Fallbacks:

- **Non-interactive** (`-NonInteractive`) prints the situation and all copy/open lines without the menu
- Hosts that cannot read single keystrokes (ISE, redirected output) fall back to numbered prompts

During setup prompts (not the completion menu): **Esc** returns to the previous question, and **Ctrl+C** exits. On IQService Control, Esc on a nested prompt returns to the main action list; Esc on that list exits. Numbered fallbacks accept `b` to go back.

| Script | Copy into ISC | Open for pending work |
| --- | --- | --- |
| `AWS.ps1` (SaaS) | Role Name, Region, External ID, Management Account ID, AWS Accounts; with CIEM: CloudTrail ARN(s), bucket account ID | IAM role console, Organizations console, CIEM Settings |
| `AWS.ps1` (CIEM) | Role ARN, External ID, CloudTrail ARN(s), bucket account ID, Single Account, Provision Identity Center | IAM role, CloudFormation, CIEM connect docs |
| `Google Workspace.ps1` | Connection Settings fields (Grant Type, keys, scopes, delegation) | Admin console DWD, GCP service accounts |
| `Entra ID.ps1` | Grant Type, Client ID, Client Secret, Domain Name | Entra app overview, API permissions (when consent pending) |
| `IQService Control.ps1` | Host name, ports, install path, service name, Log On account | IQService docs, `services.msc` |

## IQService Control

IQService is the native Windows service that lets ISC reach Active Directory, Azure AD, Windows Local, SharePoint, and Domino through Windows APIs. Use this script on each IQService host for download, install, upgrade, service control, trace logging, log streaming, and `Utils.dll` unblock.

Reference: [Installing and Registering IQService](https://documentation.sailpoint.com/connectors/iqservice/help/integrating_iqservice_admin/install_register.html)

### Requirements

- Windows Server with IQService support (.NET Framework 4.8 recommended)
- Windows PowerShell 5.1 or PowerShell 7+
- **Administrator** elevation for install, update, uninstall, and service start/stop/restart
- A fresh IQService ZIP from ISC: **Connections → Sources → [source requiring IQService] → IQService / Integration Service → Download**

Pre-signed download URLs look like:

`https://va-access.infra.identitynow.com/sppcbu-va-images/builds/connector-bundle/IQService/{build}/IQService-{build}.zip?...`

They expire quickly (often within an hour). Paste a new link each time; never commit or share signed URLs.

### Interactive usage

Run on the IQService host in an elevated PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\IQService Control.ps1
```

The list prompts are keyboard menus: **Up/Down** (or `j`/`k`) moves, **Enter** selects, **Esc** goes back to
the previous prompt (or leaves the main menu), and **Ctrl+C** exits. Hosts that cannot read single
keystrokes - the ISE, redirected or piped sessions - fall back to numbered prompts (`b` goes back)
and say so on the line above the list.

The menu supports:

1. **Status** — version, install path, Windows services, registry ports/trace settings, `Utils.dll` block state
2. **Download ZIP** — from a pasted ISC URL or a local file
3. **Install / register** — extract, unblock binaries, run `IQService.exe -i`
4. **Update** — backup the install tree, stop/uninstall, extract the new build, reinstall, restore trace settings
5. **Start / Stop / Restart** — wraps `IQService.exe -s`, `-k`, `-t`
6. **Set log level** — `Off`, `Error`, `Info`, or `Debug` via `-l` / `-f` (default trace file: `{InstallPath}\iqtrace.log`)
7. **Stream logs** — follow the trace file with colored `ERROR` / `INFO` / `DEBUG` lines (Ctrl+C, Q, or Esc to stop)
8. **Unblock** — clears the `Zone.Identifier` stream from `Utils.dll`, other `.dll`/`.exe` files, and `IQService.zip`

After every action except **Stream logs**, the script shows the shared completion menu: a situation statement (pending TLS, Log On account, service start, ISC IQService panel) plus copy/open actions for host name, ports, paths, and admin links. Pick **Done** to return to the main menu.

Default install path: `C:\SailPoint\IQService`, or the directory discovered from an existing IQService Windows service.

### Parameterized usage

```powershell
.\IQService Control.ps1 -Action Status

.\IQService Control.ps1 -Action Download -DownloadUri 'https://va-access.infra.identitynow.com/...'

.\IQService Control.ps1 -Action Install -ZipPath 'D:\Downloads\IQService-914.zip' -TlsPort 5050 -StartAfterInstall

.\IQService Control.ps1 -Action Update -DownloadUri 'https://va-access.infra.identitynow.com/...' -StartAfterInstall

.\IQService Control.ps1 -Action SetLogLevel -LogLevel Debug -TraceFile 'C:\SailPoint\IQService\iqtrace.log'

.\IQService Control.ps1 -Action StreamLogs -Tail 100

.\IQService Control.ps1 -Action Unblock
```

| Parameter | Purpose |
| --- | --- |
| `Action` | `Download`, `Install`, `Update`, `Uninstall`, `Start`, `Stop`, `Restart`, `SetLogLevel`, `StreamLogs`, `Status`, or `Unblock` |
| `InstallPath` | IQService directory (default `C:\SailPoint\IQService` or auto-discovered) |
| `DownloadUri` | Pre-signed ISC VA-image URL for `IQService.zip` |
| `ZipPath` | Local `IQService.zip` instead of downloading |
| `Port` | Non-TLS port for `IQService.exe -i` / `-p` |
| `TlsPort` | TLS port for `IQService.exe -i` / `-o` |
| `SkipSecondary` | Pass `-b` to skip the secondary fallback instance |
| `LogLevel` | `Off`, `Error`, `Info`, or `Debug` |
| `TraceFile` | Trace log path (default: registry `tracefile`, else `{InstallPath}\iqtrace.log`) |
| `Tail` | Existing lines to print before following (`StreamLogs` only; default `50`) |
| `StartAfterInstall` | Start the service after install or update |
| `NonInteractive` | Do not prompt |
| `WhatIf` / `Confirm` | Standard PowerShell risk mitigation |

### What the script does not do

- It does not configure TLS certificates, client authentication (`-a` / `-x`), or UpdateService (`-z`).
- It does not create or update the ISC source object; configure the source separately after IQService is running.
- It does not configure gMSA or ScriptExecutor service toggles (`-g`).
- It cannot recover the IQService **Log On** password after uninstall; if the service account changes, set it again in `services.msc`.

### Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `Could not load file or assembly 'Utils.dll'` | DLL is blocked from a downloaded ZIP. Run **Unblock** or unblock `IQService.zip` before extracting. |
| Download fails with 403 / expired | Pre-signed ISC URLs expire. Copy a fresh link from the source IQService Download panel. |
| `Administrator privileges are required` | Re-run PowerShell as Administrator for install, update, or service actions. |
| After update, provisioning fails | Confirm TLS cert and service **Log On** account; update runs `IQService.exe -u`, which clears registry entries. |
| Trace log not written | Set `-TraceFile` under the install path so the service account can write it (default `system32` may be inaccessible). |

## AWS source connection (`AWS.ps1`)

`AWS.ps1` supports two ISC sources. Pick **one per run** (`-SourceType AwsSaas` or `-SourceType CiemAws`). Each type writes a **different file** under a **different default directory** so a SaaS run cannot overwrite CIEM output:

| Source type | Default output directory | Settings file |
| --- | --- | --- |
| `AwsSaas` (default) | `./sourceConfig/aws-isc` | `sailpoint-aws-connection-settings.txt` |
| `CiemAws` | `./sourceConfig/aws-ciem` | `sailpoint-ciem-aws-connection-settings.txt` |

Do not enable CIEM on the AWS SaaS source when you also use a dedicated CIEM AWS source for the same management account.

The SaaS source governs **IAM** users and groups. **Identity Center** users and permission sets are governed by a **CIEM AWS** source (`-SourceType CiemAws`), so no SaaS option grants `sso:` or `identitystore:` permissions.

### AWS SaaS connector IAM role

The Amazon Web Services SaaS connector authenticates with **IAM Role** assumption: SailPoint assumes a role in your management account (and a role of the same name in each member account) using an External ID from the source Connection Settings.

This path creates or updates that role and the documented customer-managed policies. It does not create the ISC source; copy the External ID from ISC first, then paste the printed role name back into Connection Settings.

References:

- [Integrating SailPoint and Amazon Web Services SaaS](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/introduction.html)
- [Configuring AWS Manually](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/manual_configuration.html)
- [Connection Settings](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/connection_settings.html)
- [Cloud Infrastructure Entitlement Management (CIEM) Settings](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/ciem_settings.html)
- [Multiple Group Object Source Policies](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/mgo_source_policies.html)
- [Non Multiple-group Object Source Policies](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/non_mgo_policies.html)
- [Machine Identity Governance Policies](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/machine_identity_governance_policies.html)

#### SaaS requirements

- Windows PowerShell 5.1 or PowerShell 7+
- An AWS identity that can create IAM roles and customer-managed policies in the target account
- Permission to install [AWS Tools for PowerShell](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up.html) modules for the current user (the script offers to install them):
  - `AWS.Tools.SecurityToken`
  - `AWS.Tools.IdentityManagement`
  - `AWS.Tools.Organizations`
- For `-Feature Ciem`: `AWS.Tools.CloudTrail` and `AWS.Tools.EC2` (the script offers to install them) plus the CloudTrail log **bucket name**
- The **External ID** from the ISC AWS SaaS source **Connection Settings** (auto-populated there)
- For organization-wide deployment: `organizations:ListAccounts` plus a member-account role this identity can assume (for example `OrganizationAccountAccessRole`)

#### SaaS interactive usage

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\AWS.ps1
# or explicitly:
.\AWS.ps1 -SourceType AwsSaas
```

The script prompts for:

1. Source type (when not passed)
2. External ID from the AWS SaaS source Connection Settings
3. AWS profile (blank uses the default credential chain; run `aws sso login` first if you use IAM Identity Center)
4. Commercial vs GovCloud (selects the SailPoint trust principal)
5. Region for STS / Organizations (IAM is global; default `us-east-1` or `us-gov-west-1`)
6. IAM role name (default `SailPointAWSRole` — this is the value ISC needs, not the ARN)
7. Policy set (multiple group objects vs non-MGO)
8. Optional feature packs
9. Whether to include provisioning
10. Optional CloudTrail S3 bucket (required when the **CIEM** pack is selected)
11. When CIEM is selected: the CloudTrail log bucket (create new, discover, or enter a name), the bucket account ID, and — unless the run is creating the trail — optional extra CloudTrail ARNs
12. Current account vs entire AWS Organization
13. Output directory (default `./sourceConfig/aws-isc`)

Re-running with the same role name updates the trust policy and managed policies in place.

Before it changes anything the script calls `organizations:DescribeOrganization` to report whether the signed-in account is the **management (root)** account, and afterwards it reads the stored role back to confirm the trust principal, the External ID condition, and that `organizations:ListAccounts` is granted — the three things the **AWS Accounts** (Cloud Scope) list depends on.

#### SaaS parameterized usage

```powershell
.\AWS.ps1 `
  -ProfileName 'AdministratorAccess' `
  -ExternalId '11111111-2222-3333-4444-555555555555' `
  -RoleName 'SailPointAWSRole' `
  -Feature ActivityInsights,Ciem `
  -CloudTrailBucket 'my-org-cloudtrail-logs' `
  -NonInteractive
```

```powershell
.\AWS.ps1 `
  -ExternalId '11111111-2222-3333-4444-555555555555' `
  -Scope Organization `
  -MemberAssumeRole 'OrganizationAccountAccessRole' `
  -Feature ActivityInsights,AgentDiscovery
```

| Parameter | Purpose |
| --- | --- |
| `SourceType` | `AwsSaas` (default) or `CiemAws` |
| `ProfileName` | AWS credential profile |
| `Region` | STS / Organizations region (default `us-east-1`) |
| `Cloud` | `Commercial` (default) or `GovCloud` |
| `TrustPrincipal` | Replaces the default trusted SailPoint principal(s); accepts account IDs or full role ARNs |
| `RoleName` | IAM role name for the ISC source (default `SailPointAWSRole` for SaaS) |
| `ExternalId` | External ID from ISC Connection Settings |
| `PolicySet` | `Mgo` (default) or `NonMgo` (SaaS only) |
| `Feature` | One or more optional packs (SaaS only; see below) |
| `AggregationOnly` | Do not attach provisioning (SaaS only) |
| `CloudTrailBucket` | CloudTrail log bucket. SaaS: optional `SPCloudTrailBucketPolicy`; **required** with `-Feature Ciem`. CIEM AWS source: SailPoint `BucketName` (default `sailpoint-ciem-<account-id>`) |
| `CloudTrailBucketAccountId` | SaaS CIEM: 12-digit account that hosts the CloudTrail bucket (ISC **AWS CloudTrail Bucket Account ID**). Defaults to the signed-in account |
| `CloudTrailArn` | Extra CloudTrail ARN(s) for CIEM settings (SaaS CIEM or CIEM AWS). Ignored when this run creates the trail; otherwise trails are also discovered in this account |
| `Scope` | `CurrentAccount` (default) or `Organization` |
| `MemberAssumeRole` | Role to assume in member accounts when SaaS `Scope` is `Organization` |
| `OutputDirectory` | Connection-settings directory (type-specific default and filename) |
| `NonInteractive` | Do not prompt |
| `WhatIf` / `Confirm` | Standard PowerShell risk mitigation |

#### SaaS required policies — always attached

`PolicySet Mgo` (the default) matches SailPoint's [multiple group object](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/mgo_source_policies.html) tables. Use this when you need groups plus AWS managed / customer / inline policies, roles, OUs, SCPs, and accounts.

| Policy | Purpose |
| --- | --- |
| `SPAggregationPolicy` | Read IAM users, groups, roles, policies, tags, and credentials |
| `SPOrganizationPolicy` | Read organization accounts, OUs, SCPs, and tags (`organizations:ListAccounts` only when `NonMgo`) |
| `SPProvisioningPolicy` | Create / update / delete users and entitlements (omit with `-AggregationOnly`) |

`PolicySet NonMgo` uses the narrower [non-MGO](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/non_mgo_policies.html) organization and provisioning action lists. AWS SaaS still requires an organization policy; single-account (no Organizations) is not supported by the SaaS connector without extra schema work.

The trust policy allows `sts:AssumeRole` from:

| Cloud | Label | Principal |
| --- | --- | --- |
| Commercial | **CIEM** (documented) | `arn:aws:iam::874540850173:role/ciem_universal` |
| Commercial | **ISC SaaS** (connector runtime) | `arn:aws:iam::706944607044:role/ciem_universal` |
| GovCloud | documented | `arn:aws-us-gov:iam::229634586956:role/ciem_universal` |

conditioned on `sts:ExternalId` equal to the ISC External ID. Every member-account role must use the **same name** and **same External ID**.

**CIEM** is the account SailPoint publishes for commercial setups. **ISC SaaS** is a separate SailPoint-owned account that the AWS SaaS connector runtime uses to assume the customer role on some tenants. It is not tied to the source Region field (`us-east-1` vs `eu-west-1`). Commercial runs trust both by default.

`-TrustPrincipal` replaces those defaults. Use it only when AssumeRole fails with a *different* `ciem_universal` account than the two above. Bare 12-digit account IDs are expanded to `arn:<partition>:iam::<id>:role/ciem_universal`; full role ARNs are also accepted. Interactive runs still prompt for one extra principal.

### Optional feature packs

Opt in with `-Feature` or the interactive multi-select. These map to features that must be licensed or enabled first.

| Pack | Policy | When |
| --- | --- | --- |
| `ActivityInsights` | `SPActivityInsightsPolicy` | CloudTrail `Get*` / `Describe*` / `List*` / `LookupEvents` |
| `Ciem` | `SPCiemPolicy` | [CIEM minimum read permissions](https://documentation.sailpoint.com/saas/help/ciem/aws/config/aws_minimum_permissions.html) so you can turn on **Enable Cloud Infrastructure Entitlement Management** on the AWS SaaS source. Requires a CIEM license, `-CloudTrailBucket`, and CloudTrail ARN(s) plus the bucket account ID in [CIEM Settings](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/ciem_settings.html) |
| `AgentDiscovery` | `SPAgentDiscoveryPolicy` | [Bedrock and AgentCore](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/machine_identity_governance_policies.html) machine-identity discovery |

There is no Identity Center pack here. SailPoint governs Identity Center users and permission sets through the **CIEM AWS** source, not the SaaS source — see [Connecting AWS and SailPoint CIEM](https://documentation.sailpoint.com/saas/help/ciem/aws/connect_aws.html). Earlier versions of this script offered `IdentityCenter` and `IdentityCenterProvisioning` packs; a re-run detaches `SPIdentityCenterPolicy` and `SPIdentityCenterProvisioningPolicy` from the SaaS role.

`-CloudTrailBucket` adds `SPCloudTrailBucketPolicy` for `s3:GetBucketLocation`, `s3:ListBucket`, and `s3:GetObject` on that bucket.

##### How CloudTrail ARNs are chosen for CIEM settings

The `Ciem` pack asks how to supply the log bucket, and that answer decides where the ARNs come from:

| Bucket choice | CloudTrail ARN(s) in the output |
| --- | --- |
| Create a new CloudTrail and S3 bucket | Only the trail this run creates, taken from the CloudFormation output. The wizard does not ask for ARNs (the trail does not exist yet) and does not scan afterwards |
| Use an existing bucket from CloudTrail in this account | The trails that log into the bucket you picked |
| Enter a bucket name manually | Anything you pass at the ARN prompt or in `-CloudTrailArn`, plus the trails found writing to that bucket (up to 150) |

`SPCloudTrailBucketPolicy` grants S3 read on the chosen bucket only, so a trail logging anywhere else is unreadable by ISC. Every scan is therefore scoped to that bucket and never pads the list with unrelated trails from elsewhere in the account.

#### SaaS ISC source fields

| Script output | ISC source field |
| --- | --- |
| Role Name | Role Name (**name only**, not the ARN) |
| Region | Region |
| External ID | External ID (generated by ISC; you paste it into this script) |
| Management Account ID | Management Account ID — must be the **organization management (root) account**, not a member |
| AWS Accounts | Values that should appear under **AWS Account Settings → AWS Accounts** (Cloud Scope) |
| Enable CIEM | **Additional Settings → Enable Cloud Infrastructure Entitlement Management (CIEM)** — only when `-Feature Ciem` |
| CloudTrail ARN(s) | CIEM Settings, up to 150 ARNs, comma-separated |
| CloudTrail bucket account ID | **AWS CloudTrail Bucket Account ID** |

#### SaaS what the script does not do

- It does not create the ISC source object; configure Connection Settings in ISC after the role exists. With `-Feature Ciem` it prints the Additional Settings values; you still flip **Enable Cloud Infrastructure Entitlement Management** in the UI.
- It does not deploy CloudFormation StackSets (use `-SourceType CiemAws` for SailPoint CIEM templates).
- It does not create a CloudTrail trail or S3 bucket.
- It does not remove organization schema objects for a single-account source (that remains an ISC source-schema API change).

#### SaaS troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `AWS authentication failed` | Run `aws sso login` or `aws configure`, then pass `-ProfileName`. |
| `Assembly with same name is already loaded` / `AWSSDK.Core` already loaded | This PowerShell process already loaded AWS SDK assemblies from a different AWS.Tools version (often after a mid-session install). **Close the terminal** and re-run `AWS.ps1` so every module loads together. Optional: `Update-AWSToolsModule -Scope CurrentUser -Force -Cleanup` before the new session. |
| `Could not assume ... in <account>` | The member role is missing, or the current identity cannot assume it. Grant `sts:AssumeRole` or run the script in that account. |
| Test connection fails with assume-role / External ID | Confirm the trust principal is `ciem_universal` in SailPoint's account, and that every role uses the **same** External ID shown in ISC. |
| `is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::...:role/SailPointAWSRole` | The caller is a SailPoint `ciem_universal` account that is not in the trust policy. Commercial defaults already include CIEM (`874540850173`) and ISC SaaS (`706944607044`). If the AccessDenied principal is a third account ID, re-run with `-TrustPrincipal` including that ID plus the defaults you still need. |
| Test connection fails with AccessDenied on Organizations | Attach `SPOrganizationPolicy` in the **management** account and set Management Account ID in ISC. |
| `Failed to get config options for key: cloudScope` / AWS Accounts dropdown empty | ISC lists accounts by assuming this role and calling `organizations:ListAccounts`. That API only works in the **management** account. Put `SailPointAWSRole` + `SPOrganizationPolicy` there, set Management Account ID to that 12-digit ID, then reopen AWS Account Settings. Member accounts or an SCP denying Organizations APIs also produce this error. |
| `AWSOrganizationsNotInUseException` — *Your account is not a member of an organization* | The account is standalone, so `ListAccounts` can never succeed and Cloud Scope stays empty. SailPoint documents that [single-account configuration is not supported by AWS SaaS](https://documentation.sailpoint.com/connectors/saas/aws/help/saas_connectivity/aws/non_mgo_policies.html). Either enable an organization in this account (`aws organizations create-organization --feature-set ALL`, which makes it the management account of a one-account org), or use an account that already belongs to one. The script warns about this before creating anything. |
| Role name rejected | Enter the role **name** (`SailPointAWSRole`), not `arn:aws:iam::...:role/...`. |
| `AwsSaas -Feature Ciem requires -CloudTrailBucket` | CIEM on the SaaS source needs S3 Get/List on the log bucket. Pass `-CloudTrailBucket` (and `-CloudTrailBucketAccountId` if the bucket is not in the signed-in account). |
| `Conversion from JSON failed` / `Unexpected character encountered while parsing value: <` | `Get-S3BucketPolicy` returned XML or HTML. Re-run this script; it now reads the bucket region, unwraps an XML policy envelope, and writes CloudTrail `PutObject` / `GetBucketAcl` on that bucket (SailPoint's existing-bucket template does not). |
| CloudTrail `Incorrect S3 bucket policy is detected` | The trail's log bucket has no CloudTrail write policy. Re-run so the script applies the delivery statements, then delete a `ROLLBACK_COMPLETE` stack if one remains. |
| CIEM toggle on but no activity / empty CloudTrail ARNs | No trail logs into the bucket you chose. Confirm the bucket name, pick **Create a new CloudTrail and S3 bucket**, or pass `-CloudTrailArn`. After test connection, mark Groups, AWSManagedPolicy, CustomerManagedPolicy, and InlinePolicy as cloud-enabled. |

### CIEM AWS source (CloudFormation)

The CIEM AWS source uses SailPoint's published [CloudFormation templates](https://documentation.sailpoint.com/saas/help/ciem/aws/config/config_aws_auto.html). With `-SourceType CiemAws`, the script downloads the matching JSON from SailPoint documentation and creates or updates a **stack** (single account) or **StackSet** (organization inventory) plus an optional **activity stack** in the management account.

References:

- [Configuring Amazon Web Services (CIEM)](https://documentation.sailpoint.com/saas/help/ciem/aws/config/index.html)
- [Configuring AWS Automatically](https://documentation.sailpoint.com/saas/help/ciem/aws/config/config_aws_auto.html)
- [AWS Permission Sets](https://documentation.sailpoint.com/saas/help/ciem/aws/config/aws_permission_sets.html)
- [Connecting AWS and SailPoint CIEM](https://documentation.sailpoint.com/saas/help/ciem/aws/connect_aws.html)
- [Verifying Your AWS Configuration](https://documentation.sailpoint.com/saas/help/ciem/aws/config/verify_aws_config.html)

#### CIEM requirements

- Everything in the SaaS AWS Tools list, plus `AWS.Tools.CloudFormation`, `AWS.Tools.CloudTrail`, and `AWS.Tools.EC2`
- **External ID** from the CIEM AWS source Connection Settings
- **CloudTrail S3 bucket name** (`-CloudTrailBucket`) — SailPoint template `BucketName` (default `sailpoint-ciem-<12-digit-account-id>`)
- Organization inventory: CloudFormation StackSets with Organizations trusted access in the **management account** (the script activates it when missing; needs Organizations admin permissions)
- Default IAM role name: `SailPointCIEMAuditRole` (template default)

Published commercial templates trust only `arn:aws:iam::874540850173:role/ciem_universal`. Use `-TrustPrincipal` to add principals after deployment if needed.

After deployment the script rewrites the role's trust policy to the documented commercial principals (CIEM `874540850173` **and** ISC SaaS runtime `706944607044`) with the External ID condition, then reads the policy back and reports each principal. SailPoint templates only write the first one, which fails Test Connection on tenants whose connector runtime assumes from the second. `-TrustPrincipal` replaces that list. With `Scope Organization`, only the role in the account you are signed in to is updated; member-account roles keep the template trust.

After an organization inventory StackSet deploys, the script reads `SailPointCIEMRoleARN` from the **management-account stack instance** (not a constructed ARN).

When an activity stack reports a trail (`SailPointCIEMCloudTrailARN`), that trail alone goes into the output. Otherwise the script scans all commercial/GovCloud regions (up to 150) and keeps only trails that log into `-CloudTrailBucket`, plus any `-CloudTrailArn` you passed. If nothing matches, it warns instead of substituting unrelated trails.

#### CIEM collection modes

| Scope | Mode | SailPoint template (commercial) |
| --- | --- | --- |
| Organization | Inventory | `commercial-inventory-collection.json` (StackSet, all accounts) |
| Organization | Activity (optional) | `commercial-activity-collection.json` (stack in management account) |
| Single account | Inventory only | `commercial-inventory-collection.json` (stack) |
| Single account | Existing CloudTrail + bucket | `commercial-activity-collection-existing-cloudtrail.json` |
| Single account | New trail + existing bucket | `commercial-activity-collection-new-cloudtrail-and-existing-bucket.json` |
| Single account | New trail + new bucket | `commercial-activity-collection-new-cloudtrail-and-bucket.json` |

GovCloud uses the `gov-*` equivalents. Do not deploy both inventory and activity stacks in a single account when both would create the same role name — activity templates already include inventory permissions.

Keep the **same collection mode** when you re-run against an existing activity stack. Each mode is a different template: switching from `NewCloudTrailAndBucket` to `ExistingCloudTrail` on the same stack name removes the trail and bucket policy from the stack, which **deletes the CloudTrail** (the bucket itself is retained). To change modes, use a new `-ActivityStackName` or delete the old stack first. Re-running with identical values is a safe no-op.

Organization activity templates accept `EnableIdentityStoreReadOnly` and `EnableIdentityStoreProvision` (default `true`).

#### CIEM interactive usage

```powershell
.\AWS.ps1 -SourceType CiemAws
```

The first prompt after source type is the **External ID** from the CIEM AWS source Connection Settings. Later prompts include AWS profile, cloud, region, scope, collection mode, Identity Center permissions (Organization only), stack names, and output directory (`./sourceConfig/aws-ciem`). Organization scope defaults **Yes** for the management-account activity stack.

Every SailPoint CIEM template takes `BucketName`, but each mode needs a different kind of bucket, so the bucket question follows the collection mode:

| Collection mode | What the template needs | What the wizard asks |
| --- | --- | --- |
| Organization activity, or single-account **existing CloudTrail** | A bucket an existing trail already logs into (neither template creates a trail or outputs its ARN) | Scans CloudTrail in this account, auto-selects a single match, otherwise lists bucket plus trail names. The discovered trail ARNs go straight into Connection Settings |
| **New CloudTrail with existing S3 bucket** | A bucket that exists; the stack creates the trail | Lists the S3 buckets in this account (a bucket with no trail yet is the normal case here) |
| **New CloudTrail and new S3 bucket**, or **inventory only** | A bucket name the stack will create, or just the name the read policy is scoped to | Asks for a name, defaulting to `sailpoint-ciem-<account-id>` |

Non-interactive runs without `-CloudTrailBucket` use the same `sailpoint-ciem-<account-id>` default.

#### CIEM Identity Center permissions

**Account instance (Single Account) and Identity Center are mutually exclusive** on the CIEM AWS source. Single-account runs skip the Identity Center questions, force both flags off, and strip any leftover `SailPointCIEMAuditIC*` inline policies.

The `sso:` and `identitystore:` actions for **Provision Identity Center** exist in the organization activity template as `SailPointCIEMAuditICReadOnlyPolicy` and `SailPointCIEMAuditICProvisionPolicy`. The source has a single **Provision Identity Center** toggle, so the wizard asks **one** Identity Center question and sets read and provisioning together (provisioning calls the read APIs). It asks only when **Scope is Organization**:

- **Management activity stack** — the answer becomes the `EnableIdentityStoreReadOnly` and `EnableIdentityStoreProvision` template parameters (default `Yes`, matching the template).
- **Inventory only** — the answer attaches or removes the identical policies as inline role policies (default `No`).

For read-only Identity Center without provisioning, pass `-EnableIdentityStoreReadOnly true -EnableIdentityStoreProvision false`; passing either parameter skips the prompt. Passing `-EnableIdentityStoreReadOnly true` or `-EnableIdentityStoreProvision true` with `-Scope CurrentAccount` is an error.

#### CIEM parameterized example

```powershell
.\AWS.ps1 `
  -SourceType CiemAws `
  -ExternalId '11111111-2222-3333-4444-555555555555' `
  -CloudTrailBucket 'my-org-cloudtrail-logs' `
  -Scope Organization `
  -CiemActivity OrganizationManagement `
  -NonInteractive
```

| Parameter | Purpose |
| --- | --- |
| `InventoryStackName` | Stack or StackSet name for inventory (default `SailPointCiemInventory`) |
| `ActivityStackName` | Activity stack name (default `SailPointCiemActivity`) |
| `CiemActivity` | `None`, `OrganizationManagement`, `ExistingCloudTrail`, `NewCloudTrailExistingBucket`, `NewCloudTrailAndBucket` |
| `EnableIdentityStoreReadOnly` | Organization only. Org activity template parameter, or `SailPointCIEMAuditICReadOnlyPolicy` on inventory-only org deploys |
| `EnableIdentityStoreProvision` | Organization only. Org activity template parameter, or `SailPointCIEMAuditICProvisionPolicy` on inventory-only org deploys |
| `TrailName` | New trail name when creating CloudTrail (default `sailpoint-ciem-cloud-trail`) |
| `CloudTrailBucket` | CloudTrail S3 bucket (default `sailpoint-ciem-<account-id>`) |
| `CloudTrailArn` | Extra CloudTrail ARN(s) to include in output. Superseded when the activity stack reports the trail it created |

#### CIEM ISC source fields

| Script output | ISC source field |
| --- | --- |
| Role ARN | Role ARN (management account when using Organizations) |
| External ID | External ID |
| CloudTrail ARN(s) | CloudTrail ARN (up to 150, comma-separated) |
| CloudTrail bucket account ID | AWS account ID where the bucket is hosted |
| Single Account | Enable **Single Account** (Account instance) when `Yes`. Do not enable Identity Center in that mode |
| Provision Identity Center | Organization only. Matches the org activity template (or inline) provisioning flag |

#### CIEM what the script does not do

- It does not create the ISC CIEM AWS source object or enable the `PROVISIONING` feature string via API.
- It does not configure both SaaS and CIEM in one run.
- It does not modify SailPoint template JSON (trust principal overrides are applied to the created role after deployment).

#### CIEM troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `CiemAws requires -CloudTrailBucket` | Pass a bucket name, or accept the default `sailpoint-ciem-<account-id>`. Names must be 3–63 lowercase DNS characters. |
| `Failed to get account authorization details, please check Role ARN and External Id` (and empty aggregations) | SailPoint could not assume the role. The published templates trust **only** `874540850173`, but some tenants call `sts:AssumeRole` from the ISC SaaS runtime account `706944607044`. Re-run the script: it now rewrites the trust policy to both commercial principals and verifies the External ID. If it still fails, open CloudTrail in the role's account, find the `AssumeRole` `AccessDenied` event, and re-run with `-TrustPrincipal` including that account ID. |
| `You must enable organizations access to operate a service managed stack set` | CloudFormation StackSets trusted access is off. The script now calls `ActivateOrganizationsAccess` before deploying; if that call is denied, sign in to the **management account** with Organizations admin permissions, or activate trusted access in the CloudFormation console under **StackSets**, then re-run. |
| Activity stack `UPDATE_ROLLBACK_*` with Identity Center policies already on the role | A previous run attached `SailPointCIEMAuditICReadOnlyPolicy` / `SailPointCIEMAuditICProvisionPolicy` as unmanaged inline policies. The script removes those before the org activity stack creates them. Wait until the stack is `UPDATE_ROLLBACK_COMPLETE`, then re-run. |
| `No CloudTrail trail logs into <bucket>` | The activity stack reported no trail and nothing in the account writes to that bucket. Check `-CloudTrailBucket`, choose a mode that creates a trail (`NewCloudTrailExistingBucket` / `NewCloudTrailAndBucket`), or pass `-CloudTrailArn`. |
| Template download fails | Confirm outbound HTTPS to `documentation.sailpoint.com` or deploy manually from [config_aws_auto](https://documentation.sailpoint.com/saas/help/ciem/aws/config/config_aws_auto.html). |
| `Assembly with same name is already loaded` | Same as SaaS troubleshooting: synchronize with `Update-AWSToolsModule`, then start a **new** PowerShell session before re-running. |
| Identity Center with Single Account / Account instance | Not supported. Use Organization scope for Identity Center, or keep Provision Identity Center off with Single Account. |
| `Unable to provision Identity Center due to missing required permission(s): identitystore:*, sso:*` | The role lacks the Identity Center actions, or Single Account is on while Provision Identity Center is on. Re-run with Organization scope and answer **Yes** to the Identity Center questions, or turn Provision Identity Center off. |

## Google Workspace SaaS connector service account

The Google Workspace SaaS connector supports two grant types, and the script handles both:

| Grant type | Connection Settings fields | Use it when |
| --- | --- | --- |
| **Service Account** (default) | Service Account Email Address, Email Address of User to Impersonate, Scopes, Private Key, Private Key Password | Always safe, and **required** for CIEM and NHI Discovery |
| **Client Credentials** | Client ID, Client Secret, Refresh Token | You prefer acting as a consenting Workspace user instead of a delegated service account |

Service Account runs on a GCP service account key, domain-wide delegation of that account's numeric client ID, and impersonation of a Workspace admin. Client Credentials runs the OAuth 2.0 authorization-code flow against an OAuth client you create in the Cloud Console and returns the offline refresh token.

This script creates or updates the GCP objects, saves Connection Settings to files in the output directory, and ends with the shared copy/open completion menu. It does not create the ISC source.

References:

- [Integrating SailPoint with Google Workspace SaaS](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/introduction.html)
- [Prerequisites](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prerequisites.html)
- [Generating OAuth 2.0 Credentials](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/prereqs_for_oauth_2_0.html)
- [Connection Settings](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/connection_settings.html)
- [Required Permissions](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/administrator_permission.html)
- [Service Account Scopes and Built-in Roles](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/in_built_roles.html)
- [Service Account Scopes and Custom Roles](https://documentation.sailpoint.com/connectors/saas/googleworkspace/help/saas_connectivity/google_workspace/custom_roles.html)
- [Configuring Google Cloud Platform (CIEM)](https://documentation.sailpoint.com/saas/help/ciem/gcp/config_gcp.html)

### Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`) on PATH, with permission to create service accounts and keys in the target project
- A Google identity that can enable APIs in the project. For `Gcp`, `Ciem`, `NhiDiscovery`, or `AgentDiscovery`: organization-level custom role create and IAM bind (typically Organization Admin or equivalent)

Service Account grant type also needs:

- [OpenSSL](https://www.openssl.org/) on PATH (Git for Windows includes it; macOS LibreSSL works) for the encrypted RSA PEM SailPoint documents
- An existing Workspace admin mailbox to impersonate (the script does not create that user)

Client Credentials grant type also needs:

- An OAuth client ID of type **Web application**, created in **APIs & Services → Credentials** (`gcloud` cannot create OAuth clients), with the redirect URI you pass to the script registered on it
- A browser session for the Workspace user who authorizes the client

### Interactive usage

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Google Workspace.ps1
```

The script prompts for:

1. Whether to reuse the current `gcloud` account (or run `gcloud auth login`)
2. Grant type — Service Account or Client Credentials
3. GCP organization (required for GCP / CIEM / NHI packs)
4. Project ID (creates the project and links billing when it does not exist)
5. **Service Account:** service account ID (default `sailpoint-isc-gws`), display name, impersonate-user email
   **Client Credentials:** redirect URI, OAuth client ID and secret, authorizing user
6. Optional feature packs
7. Aggregation-only (skip GCP write permissions)
8. **Service Account only:** on update, whether to print a **new** Private Key and Private Key Password. Google cannot recover an existing key. Answer **Y** to paste into Connection Settings now; answer **N** (default) only if you already have those values. Blank passphrase generates one.
9. Output directory (default `./sourceConfig/google-workspace-isc`)

Re-running with the same project and service account ID updates the display name, APIs, and organization role in place. It does **not** reprint Private Key or Private Key Password unless you answer **Y** at the key prompt or pass `-RotateKey`.

The list prompts are the same keyboard menus as the Entra ID script.

Under Client Credentials the script opens the Google consent screen. With the default loopback redirect (`http://localhost:8088`) it catches the authorization code itself; with the OAuth Playground redirect you paste the code from **Step 2 - Exchange authorization code for tokens**.

### Output

Both grant types end with the shared completion menu: a situation statement plus copy/open actions for each Connection Settings field (values are also saved under `./sourceConfig/google-workspace-isc` unless `-OutputDirectory` is set). Sensitive fields are masked in the menu but copy in full when selected.

| File | Contents |
| --- | --- |
| `sailpoint-gws-connection-settings.txt` | Every ISC Connection Settings field for the chosen grant type |
| `sailpoint-gws-domain-wide-delegation.txt` | Client ID and scopes for the Admin console (Service Account only) |
| `sailpoint-gws-rsa.pem` | Encrypted RSA private key to paste into **Private Key** (Service Account only) |
| `sailpoint-gws-key.json` | Original Google JSON key (Service Account only) |

### Parameterized usage

```powershell
.\Google Workspace.ps1 `
  -ProjectId 'sailpoint-isc' `
  -ImpersonateUser 'admin@contoso.com' `
  -Feature Gcp,Ciem `
  -NonInteractive
```

```powershell
.\Google Workspace.ps1 `
  -OrganizationId '123456789012' `
  -ProjectId 'sailpoint-isc-gws' `
  -CreateProject `
  -BillingAccountId 'XXXXXX-XXXXXX-XXXXXX' `
  -Feature Gcp,GmailDelegates,DeltaAggregation `
  -RotateKey
```

```powershell
.\Google Workspace.ps1 `
  -GrantType ClientCredentials `
  -ProjectId 'sailpoint-isc' `
  -ClientId '1234567890-abc.apps.googleusercontent.com' `
  -ClientSecret 'GOCSPX-...' `
  -RedirectUri 'http://localhost:8088'
```

| Parameter | Purpose |
| --- | --- |
| `GrantType` | `ServiceAccount` (default) or `ClientCredentials` |
| `ClientId` / `ClientSecret` | OAuth client credentials (`ClientCredentials`) |
| `RefreshToken` | Existing refresh token; skips the authorization-code flow |
| `RedirectUri` | Redirect URI registered on the OAuth client (default `http://localhost:8088`) |
| `ConsentUser` | Workspace user who authorizes and holds the admin roles (`ClientCredentials`) |
| `OrganizationId` | Numeric GCP organization ID |
| `ProjectId` | Project that owns the service account |
| `CreateProject` | Create `ProjectId` under the organization when missing |
| `BillingAccountId` | Billing account to link when creating a project |
| `ServiceAccountId` | Account ID before `@` (default `sailpoint-isc-gws`) |
| `DisplayName` | Service account display name |
| `ImpersonateUser` | Workspace admin email the connector impersonates |
| `Feature` | One or more optional packs (see below) |
| `AggregationOnly` | Do not grant GCP write permissions (`setIamPolicy`, IAM role CRUD, service account create) |
| `RotateKey` | On update, issue a new key and print Private Key + Private Key Password. Required to paste into Connection Settings unless you already stored those values. |
| `SkipDomainWideDelegationWalkthrough` | Do not open the Admin console or copy Client ID / scopes |
| `AssignWorkspaceRoles` | Super Admin OAuth → Admin SDK assigns User Management Admin and Groups Admin to the impersonate user |
| `KeyPassword` | Passphrase for the encrypted PEM (generated when omitted) |
| `OutputDirectory` | Where to write the connection-settings, delegation, PEM, and JSON key files (default `./sourceConfig/google-workspace-isc`) |
| `OpenSslPath` | `openssl` executable when it is not on PATH |
| `NonInteractive` | Do not prompt; omitted `Feature` means no feature packs |
| `WhatIf` / `Confirm` | Standard PowerShell risk mitigation |

### Required — always configured

The script always enables Admin SDK and Groups Settings APIs, and always requests these scopes — as domain-wide delegation scopes under Service Account, and as the authorization request under Client Credentials (SailPoint's core service-account table):

| Scope | Purpose |
| --- | --- |
| `https://www.googleapis.com/auth/admin.directory.group` | Group aggregation and provisioning |
| `https://www.googleapis.com/auth/admin.directory.user` | User aggregation and provisioning |
| `https://www.googleapis.com/auth/apps.groups.settings` | Group Settings API |
| `https://www.googleapis.com/auth/admin.directory.rolemanagement` | Role create / assign |
| `https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly` | Role aggregation |

### Optional feature packs

Opt in with `-Feature` or the interactive multi-select. These map to features that must be licensed or enabled first.

| Pack | What it adds |
| --- | --- |
| `Gcp` | `cloud-platform` and `iam` scopes; Cloud Resource Manager, IAM, and Cloud Asset APIs; organization custom role `sailpointGoogleWorkspace` with documented inventory permissions (and write permissions unless `-AggregationOnly`) |
| `Ciem` | Same GCP APIs and CIEM minimum read permissions (`cloudasset.assets.searchAll*`, folder/project/org IAM get, logging list). Requires a CIEM license. Grant Type must stay **Service Account**. |
| `GmailDelegates` | Gmail API plus `gmail.settings.sharing`, `gmail.settings.basic`, `https://mail.google.com/`, `gmail.modify`, `gmail.readonly` |
| `DeltaAggregation` | `admin.reports.audit.readonly` |
| `ActivityInsights` | `admin.reports.audit.readonly` and `admin.reports.usage.readonly` |
| `DomainManagement` | `admin.directory.domain` (impersonate user needs Super Admin) |
| `NhiDiscovery` | Extra APIs (Asset, API Keys, Recommender, Logging, Secret Manager, Cloud Functions, Drive) and documented built-in roles. Viewer / Organization Viewer bind at the organization; roles GCP rejects at org scope are bound on the service-account project instead. Secret Manager Viewer is `roles/secretmanager.viewer`; API Keys Viewer is `roles/serviceusage.apiKeysViewer`. Requires SailPoint Agentic Fabric. |
| `AgentDiscovery` | Vertex AI API plus `aiplatform.agents.get` / `aiplatform.agents.list` on the custom role |

`Gcp`, `Ciem`, `NhiDiscovery`, and `AgentDiscovery` require a GCP organization. `-AggregationOnly` only affects GCP write permissions on that custom role; Workspace OAuth scopes stay as documented for test connection and aggregation.

The custom role is bound at **organization** scope — to the service account under Service Account, and to the authorizing user under Client Credentials, because that grant type calls Google as that user. NHI built-in roles that GCP does not allow on an organization are bound on the project instead. If a role is not available at either scope, the script warns and continues.

### Domain-wide delegation and impersonate user

**Domain-wide delegation cannot be created through an API.** Google only allows a Super Admin to authorize a client ID in the Admin console ([delegating domain-wide authority](https://developers.google.com/identity/protocols/oauth2/service-account#delegatingauthority)). After Connection Settings are printed, the script offers a walkthrough that opens [Manage domain-wide delegation](https://admin.google.com/ac/owl/domainwidedelegation), prints the numeric **Client ID** and the comma-delimited **OAuth scopes** (and lists each scope), then copies those fields in order so you only click **Add new** → paste → **Authorize**. Values stay on screen in case the clipboard is overwritten. Esc on a wait returns to the previous field. Interactive default is to run it. `-NonInteractive` skips it; `-SkipDomainWideDelegationWalkthrough` skips it always.

**Workspace admin roles can be assigned through the Admin SDK.** The script offers to sign in as a Super Admin and assign **User Management Admin** and **Groups Admin** to the impersonate user. Super Admin is offered only when `DomainManagement` is selected. `gcloud` tokens cannot call this API, so the sign-in needs a Web application OAuth client with the loopback redirect registered.

**Google has no API for creating that OAuth client** — `gcloud iam oauth-clients` manages Workforce Identity Federation clients, and IAP clients are locked to IAP redirect URIs. So when `-ClientId` and `-ClientSecret` are omitted, the script runs a walkthrough instead of just prompting: it opens [Create OAuth client](https://console.cloud.google.com/auth/clients/create), lists the fields to fill (application type, name, redirect URI), copies the redirect URI to the clipboard, and then asks for the client ID and secret the dialog shows. Answer **No** to that offer to assign the roles yourself at [Admin roles](https://admin.google.com/ac/roles). If the sign-in fails (for example `redirect_uri_mismatch`), the script explains the mismatch and offers to retry with a different client. `-NonInteractive` requires `-ClientId` and `-ClientSecret` and otherwise skips the step with the manual instructions.

**A new OAuth client will not let anyone sign in until its audience allows them.** `Internal` is only offered when the project belongs to a Workspace organization, and it admits everyone in that organization. Otherwise the app is `External` and starts in `Testing`, where only accounts listed under **Test users** can sign in — everyone else gets `Access blocked: ... has not completed the Google verification process` (`Error 403: access_denied`) and no redirect ever reaches the script. The walkthrough therefore opens [Audience](https://console.cloud.google.com/auth/audience) after the client is created and copies the account to add. Google's verification review is not needed: it only applies to apps published for users outside your own organization or test list.

Assign roles to the impersonate user (not to the service account). SailPoint's built-in role table:

| Need | Roles on the impersonate user |
| --- | --- |
| Users and groups | User Management Admin, Groups Admin |
| Workspace roles | Super Admin |
| Domain as a GCP account type | Super Admin |
| Gmail delegates | Gmail (Settings) in addition to user/group admin |
| Delta aggregation | Reports (custom role) in addition to user/group admin |

### ISC source fields

Service Account grant type:

| Script output | ISC source field |
| --- | --- |
| Grant Type | Grant Type (`Service Account`) |
| Service Account Email Address | Service Account Email Address |
| Email Address of User to Impersonate | Email Address of User to Impersonate |
| Scopes | Scopes (comma-separated) |
| Private Key | Private Key (contents of the encrypted RSA PEM, `BEGIN RSA PRIVATE KEY`) |
| Private Key Password | Private Key Password (the PEM passphrase) |

The Google JSON key (`BEGIN PRIVATE KEY`) is not what ISC wants. The script writes both files; paste the PEM and passphrase. The passphrase is shown once.

If the service account already exists and you decline a new key, those two fields are omitted from the output. Google cannot retrieve the previous PEM. Re-run and answer **Y**, or pass `-RotateKey`.

Client Credentials grant type:

| Script output | ISC source field |
| --- | --- |
| Grant Type | Grant Type (`Client Credentials`) |
| Client ID | Client ID |
| Client Secret | Client Secret |
| Refresh Token | Refresh Token |

The refresh token belongs to the authorizing user, so the source inherits that user's Workspace roles. Revoking the OAuth client, or disabling that user, invalidates it.

### What the script does not do

- It does not create the ISC source object; paste Connection Settings in ISC after the key or token exists.
- It does not authorize domain-wide delegation by API (Google does not expose one). It can open the Admin console page and copy Client ID then scopes.
- It does not create the impersonate user. It can assign User Management Admin and Groups Admin through the Admin SDK when you provide a Super Admin OAuth client.
- It does not create the OAuth client for Client Credentials or Admin SDK sign-in; Google has no API for that. The script opens the Cloud Console page and walks you through the fields instead.
- It does not delete old service-account keys when you rotate.

### Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `gcloud was not found on PATH` | Install the [Cloud SDK](https://cloud.google.com/sdk/docs/install) and reopen the shell. |
| `openssl was not found` | Install OpenSSL or pass `-OpenSslPath`. Git for Windows provides `openssl.exe`. macOS `/usr/bin/openssl` (LibreSSL) is enough; the script omits `-traditional` there. |
| `Invalid cipher 'traditional'` | You are on an older copy of the script. Re-run the current `Google Workspace.ps1`; LibreSSL does not accept `-traditional`. |
| `Gcp, Ciem, NhiDiscovery, and AgentDiscovery require a GCP organization` | Pass `-OrganizationId` from `gcloud organizations list`. Workspace-only setups can omit those packs. |
| Test connection fails with unauthorized_client / invalid_grant | Domain-wide delegation is missing, uses the email instead of the numeric client ID, or the scope list does not match what the connector requests. |
| Test connection fails on Admin SDK | Enable `admin.googleapis.com` and `groupssettings.googleapis.com` in the project (the script does this). Confirm the impersonate user has User Management Admin / Groups Admin. |
| CIEM or cloud scope empty | Re-run with `-Feature Gcp,Ciem`, confirm the custom role is bound at the **organization**, and keep Grant Type = Service Account. |
| ISC rejects the private key | Paste the **RSA PEM** (`Proc-Type: 4,ENCRYPTED`), not the JSON `private_key`, and the passphrase from this run. |
| Private Key is missing from the output | The service account already existed and you answered **N**. Google cannot recover the old PEM. Re-run and answer **Y**, or pass `-RotateKey`. |
| `redirect_uri_mismatch` during the OAuth flow | The redirect URI on the OAuth client must match `-RedirectUri` exactly. Add `http://localhost:8088` (or the Playground URL) under Authorized redirect URIs and retry. |
| `Access blocked: ... has not completed the Google verification process` (`403: access_denied`) | The app is External and in Testing, so only test users may sign in. Add the signing-in account under [Audience → Test users](https://console.cloud.google.com/auth/audience) and retry. Verification review is not required for your own admins. Internal apps (Workspace organization projects) never hit this. |
| `No redirect arrived on http://localhost:8088/` | The consent screen blocked the sign-in, so nothing was ever redirected back — see the row above. The script stops waiting after 5 minutes rather than hanging. |
| Refresh token stops working after 7 days | An External app in **Testing** issues short-lived refresh tokens. Publish the app on the Audience page, or use an Internal app in a Workspace organization. |
| `Google returned an access token without a refresh token` | The user already consented, so Google skipped the refresh token. Remove the app under [myaccount.google.com/permissions](https://myaccount.google.com/permissions) and authorize again. |
| `Could not listen on http://localhost:8088/` | The port is taken. Pass a free port with `-RedirectUri` (and register it on the OAuth client), or use the Playground redirect. |
| No clipboard tool available | `Set-Clipboard` is Windows-only; install `xclip` or `wl-copy` on Linux. macOS uses `pbcopy`. Values remain in the completion menu output and in saved files under the output directory. |

## Entra ID connector application

Both Entra connectors authenticate with a tenant-specific app registration using a client ID and client secret. This script replaces the legacy `AzureAD` module workflow — Azure AD Graph is retired, so everything here goes through Microsoft Graph.

Permissions follow SailPoint's [Required Permissions](https://documentation.sailpoint.com/connectors/saas/msentraid/help/saas_connectivity/microsoft_entra_id/administrator_permission.html) for the Microsoft Entra SaaS connector.

### Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Permission to install [Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/installation) modules for the current user (the script offers to install them):
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Applications`
  - `Microsoft.Graph.Identity.DirectoryManagement`
- An Entra ID sign-in that can create applications, grant admin consent, and assign directory roles (**Application Administrator** + **Privileged Role Administrator**, or **Global Administrator**)

### Interactive usage

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Entra ID.ps1
```

The script prompts for:

1. Tenant ID or domain (blank uses the tenant from sign-in)
2. Application display name
3. Whether to **update** an existing app with that name or create a new one
4. Optional feature packs (multi-select; Enter with nothing selected means none)
5. Directory role
6. Whether to issue a new client secret (always on create; optional on update)
7. Output directory (default `./sourceConfig/entra-id-isc`)

The list prompts are keyboard menus: **Up/Down** (or `j`/`k`) moves, **Space** selects or deselects,
`A` and `N` select all or none in multi-select lists, **Enter** confirms, **Esc** goes back to the previous
prompt, and **Ctrl+C** exits. Hosts that cannot read single keystrokes - the ISE, redirected or piped
sessions - fall back to numbered prompts (`b` goes back) and say so on the line above the list.

It ends with the shared completion menu for **Grant Type**, **Client ID**, **Client Secret** (masked), and **Domain Name**. The same fields are written to `sailpoint-entra-connection-settings.txt` under the output directory. The secret is shown once when created; store it in a vault.

Re-running with the same display name updates permissions and consent in place. Pass `-RotateSecret` when you need a new secret.

### Parameterized usage

```powershell
.\Entra ID.ps1 `
  -TenantId 'contoso.onmicrosoft.com' `
  -ApplicationName 'SailPoint ISC Entra ID' `
  -Feature AccessPackages,MfaManagement `
  -DirectoryRole UserAdministrator `
  -NonInteractive
```

| Parameter | Purpose |
| --- | --- |
| `TenantId` | Entra tenant GUID or domain |
| `ApplicationName` | App registration display name |
| `PermissionMode` | `Granular` (default) or `Directory` |
| `Feature` | One or more optional feature packs (see below) |
| `DirectoryRole` | `UserAdministrator` (default), `PrivilegedAdmin`, `None`, `GlobalAdministrator` |
| `SecretDisplayName` | Client secret display name (default `ISC`) |
| `SecretValidityMonths` | Secret lifetime, 1–24 months (default `24`) |
| `RotateSecret` | On update, create a new client secret |
| `OutputDirectory` | Where to write the connection-settings file (default `./sourceConfig/entra-id-isc`) |
| `NonInteractive` | Do not prompt; omitted `Feature` means no feature packs |
| `WhatIf` / `Confirm` | Standard PowerShell risk mitigation |

## Permissions

### Required — always granted

`PermissionMode Granular` (the default) grants every application permission in SailPoint's required-permissions table:

| Permission | Purpose |
| --- | --- |
| `User.Invite.All` | Create / invite B2B user |
| `User.Read.All` | Account aggregation, delta, role and group membership |
| `User.ReadWrite.All` | Create / update / enable / disable / delete user, licenses |
| `User.EnableDisableAccount.All` | Delete user |
| `User-PasswordProfile.ReadWrite.All` | Set password |
| `Organization.Read.All` | Aggregate tenant license packs and plans |
| `Group.Read.All` | Group aggregation |
| `Group.ReadWrite.All` | Create / update / delete group |
| `RoleManagement.Read.Directory` | Directory role aggregation |
| `RoleManagement.ReadWrite.Directory` | Add / remove directory roles |
| `Application.Read.All` | Application role aggregation |
| `AppRoleAssignment.ReadWrite.All` | Add / remove users from service principal |
| `DelegatedPermissionGrant.Read.All` | Aggregate admin / user consented permissions |

`PermissionMode Directory` uses the coarse alternative documented by SailPoint — `Directory.Read.All` and `Directory.ReadWrite.All` — which covers read and write on users and groups but **not** deleting them.

The table also lists `User.Read` and `Directory.AccessAsUser.All` as **delegated** permissions for SAML bearer assertion, refresh token / auth-code, and JWT certificate grant types. This script configures client-credentials (client secret) authentication, so it does not request them.

### Optional feature packs

Opt in with `-Feature` or the interactive multi-select. These map to features that must be licensed or enabled first.

| Pack | Permissions |
| --- | --- |
| `AccessPackages` | `EntitlementManagement.Read.All`, `EntitlementManagement.ReadWrite.All` |
| `MfaManagement` | `UserAuthenticationMethod.Read.All`, `UserAuthenticationMethod.ReadWrite.All` |
| `Ciem` | `PrivilegedAccess.Read.AzureADGroup`, `PrivilegedAssignmentSchedule.Read.AzureADGroup`, `PrivilegedEligibilitySchedule.Read.AzureADGroup` |
| `NhiDiscovery` | `AuditLog.Read.All`, `Device.Read.All` |
| `TeamsSecretScanning` | `Channel.ReadBasic.All`, `ChannelMember.Read.All`, `ChannelMessage.Read.All`, `ChannelSettings.Read.All`, `Chat.Read.All`, `TeamsActivity.Read.All`, `TeamsAppInstallation.ReadForChat.All`, `TeamsAppInstallation.ReadForTeam.All`, `TeamsAppInstallation.ReadForUser.All`, `TeamsTab.Read.All`, `TeamSettings.Read.All` |
| `TeamsMessaging` | `TeamsAppInstallation.ReadWriteForTeam.All`, `TeamsAppInstallation.ReadWriteForUser.All`, `TeamsAppInstallation.ReadWriteSelfForUser.All` |
| `SharePointScanning` | `Files.Read.All`, `Sites.Read.All` |
| `CopilotDiscovery` | `AiEnterpriseInteraction.Read.All`, `Reports.Read.All`, `ExternalConnection.Read.All`, `AppCatalog.Read.All` |
| `DefenderHunting` | `Machine.Read.All` and `AdvancedQuery.Read.All` on the **WindowsDefenderATP** API, plus `ThreatHunting.Read.All` on Microsoft Graph |

`Ciem` supports SailPoint CIEM's PIM-group eligibility analysis. `MfaManagement` comes from the [Azure Active Directory connector permissions](https://documentation.sailpoint.com/connectors/microsoft/azure_ad/help/integrating_azure_active_directory/administrator_permission.html). The remaining `Nhi*`, `Teams*`, `SharePoint*`, `Copilot*`, and `Defender*` packs support SailPoint Non-Human Identity discovery.

If a permission does not exist in your tenant (for example, the WindowsDefenderATP service principal is not provisioned), the script warns and skips it instead of failing.

### Directory roles

Graph application permissions alone do not cover every operation. SailPoint documents these directory role requirements:

| Choice | Roles | When |
| --- | --- | --- |
| `UserAdministrator` **(default)** | User Administrator | Required for Set Password and Delete User |
| `PrivilegedAdmin` | User Administrator + Privileged Authentication Administrator | Also manage users who hold administrative roles |
| `None` | — | Aggregation only; Set Password and Delete User will fail |
| `GlobalAdministrator` | Global Administrator | Discouraged; the script warns and asks for confirmation |

### Azure cloud object read access

For read-only access to Azure cloud objects, assign the built-in **Reader** role to the application at the **tenant root management group** (Management groups → Tenant Root Group → Access control (IAM) → Add role assignment). This is Azure RBAC rather than Graph, so the script does not do it; it reminds you at the end.

## ISC source fields

| Script output | ISC source field |
| --- | --- |
| Grant Type | Grant Type (`Client Credentials`) |
| Client ID | Client ID |
| Client Secret | Client Secret |
| Domain Name | Domain Name (initial verified domain, typically `*.onmicrosoft.com`) |

VA-based Azure Active Directory sources that still call Azure AD Graph must set `useMSGraphAPI` to `true`. The Microsoft Entra SaaS connector already uses Microsoft Graph.

## What the script does not do

- It does not create the ISC source object; paste the credentials into the source UI or API.
- It does not configure certificate credentials.
- It does not grant delegated OAuth scopes or perform user consent flows.
- It does not assign Azure RBAC roles such as the tenant root **Reader** role.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `The Microsoft Graph service principal ... was not found in tenant` | You are signed in to the wrong tenant, or the sign-in lacks `Directory.Read.All`. Re-run and pass `-TenantId`, and accept the consent prompt. |
| `<API> does not expose '<permission>' as an application permission` | The permission is delegated-only or unavailable in your tenant. It is skipped; grant it in the portal if the feature needs it. |
| `Grant admin consent manually in the Entra portal for: ...` | Your account can create the app but cannot consent. Ask a Privileged Role Administrator to select **Grant admin consent** on the app's API permissions page. |
| Run failed after the app was created | The script reports the created client ID. Re-run with the same display name and choose **update** to finish configuration. |
