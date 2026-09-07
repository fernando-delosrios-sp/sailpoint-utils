## Why

`aws sso login` only refreshes an IAM Identity Center profile that already exists in `~/.aws/config`. Connect catalogs that command as `authOnce` and, when auth-check fails, asks the operator to run it. On a machine with no SSO profile the login fails before Help can recover. `aws configure sso` is the missing prior step: it writes session and profile, and often completes the first browser login. Catalog that pattern once, generically, so AWS is the first fill rather than a one-off Help paragraph.

## What Changes

**Configure once on Tool install**
- From: each `toolInstall` entry has `authOnce`, probes, and install only
- To: optional `configureOnce` (non-secret check, `suitableWhen`, operator-run command, source URL / retrievedAt)
- Reason: some CLIs cannot sign in until local session config exists; others (`az login`) need no prior step
- Impact: additive JSON; empty object or omission means skip

**Tools step**
- From: failed auth-check → request `authOnce`
- To: failed auth-check → run Configure once check; if unsuitable, operator runs the command; re-check auth; request `authOnce` only if still invalid
- Reason: the AWS wizard often signs in; repeating login is noise. Valid auth-check (including IAM user keys) still skips both
- Impact: `tools.md` and Connect tests; operator-run in every Operation mode

**AWS fill**
- From: `authOnce` is `aws sso login` with no config check
- To: `configureOnce.command` is `aws configure sso`; `authOnce` stays login
- Reason: Terraform already shares the AWS credential chain; it MUST NOT duplicate the wizard
- Impact: Skill `tool-install.json` `aws` entry (and ingest `toolInstall` if that copy is the source of truth — design)

## Non-goals

No `aws_profile` / `AWS_PROFILE` Operator input (follow-up). No other vendors filling the slot in this change. No Entro form fields. No agent-run wizard. No reading `~/.aws/credentials`. No secrets in chat or the Connect log. No new capability domain.

## Capabilities

### New Capabilities

- None. Configure once belongs on existing Tool install and Connect auth requirements.

### Modified Capabilities

- `documentation-ingest`: Tool install entries MAY include Configure once; AWS MUST fill it; validation MUST NOT require it on every binary.
- `integration-automation`: Tools step MUST run Configure once after a failed auth-check and before `authOnce`, skip when suitable or when auth-check is already valid, and MUST keep both commands operator-run.
- `ubiquitous-language`: add Configure once.

## Impact

Skill Tool install file and `tools.md`; ingest `toolInstall` if design keeps one catalog; catalog validation tests; Connect auth-flow tests; `CHANGELOG.md`. Design still pins the AWS check command and JSON nesting.

Deferred: exact AWS check command; `configureOnce.check` vs parallel key; whether ingest JSON and Skill `tool-install.json` both carry the object.
