## Why

Configure once assumes one way into a CLI. For AWS that is IAM Identity Center, so an operator whose organization has not enabled it — or who does not want to enable it for one onboarding — is told to run `aws configure sso` and `aws sso login`, neither of which applies to them. There is no generic `aws login` to fall back on: the AWS CLI reads credentials from a file, the environment, or an Identity Center token cache. `aws configure` with IAM user access keys needs nothing configured at the organization level and works in any account, and exported short-term credentials need nothing on disk. The catalog should carry those routes instead of forcing the one we happened to write first.

## What Changes

**Configure once holds Authentication routes**
- From: `configureOnce` is one `command`, `check`, `suitableWhen`, `prompts`, `docsUrl`
- To: `configureOnce.methods[]`, each with `name`, `whenToPick`, `check`, `suitableWhen`, `command`, `prompts`, `credentialBoundary`, `docsUrl`, and `authOnce` that MAY be null
- Reason: the check is universal, the remedy is a fork; Credential boundary and sign-in differ per route
- Impact: replaces the single-command shape; `aws` is the only entry with Configure once, so nothing else migrates

**The skill picks or gates a route**
- From: failed auth-check runs one check, then requests one command
- To: failed auth-check runs every route check; exactly one suitable route is used silently, otherwise the operator picks from `name` plus `whenToPick`; no route is marked recommended
- Reason: which route is right depends on the operator's organization
- Impact: `tools.md` in both skill trees; auth-flow tests

**Sign-in becomes per route**
- From: entry-level `authOnce` is always requested after Configure once
- To: the selected route's `authOnce` is authoritative; a null one means no sign-in exists, and a still-failing auth-check re-requests that route's configure command or offers Help
- Reason: access keys and exported credentials have nothing to log into
- Impact: entry-level `authOnce` stays required for tools without routes and must match one of the routes when they exist

**AWS fills two routes**
- IAM user access keys (`aws configure`, no organization setup, long-lived keys in the shared credentials file, no sign-in)
- IAM Identity Center (today's wizard and `aws sso login`, token cache)
- Credentials exported as environment variables are deliberately not a route: the skill runs checks in its own shell and cannot see them
- A secret prompt (the secret access key) is marked `secret`: relayed by label and source, typed into the CLI, never collected or logged

## Non-goals

No `aws_profile` / `AWS_PROFILE` Operator input. No other vendors filling `configureOnce`. No change to the auth-check command, Platform identity, skip-when-authenticated behaviour, or the Terraform inherit rule. No agent-run authentication. No secret values in chat, agent context, or the Connect log — route checks test names and variable presence, never values. No new capability domain.

## Capabilities

### New Capabilities

- None. Authentication routes belong on the existing Tool install and Connect auth requirements.

### Modified Capabilities

- `documentation-ingest`: `configureOnce` carries `methods[]` with per-route check, prompts, boundary, and nullable `authOnce`; AWS MUST fill the three routes; entry-level `authOnce` MUST match one of them.
- `integration-automation`: the skill MUST run every route check, use a single suitable route or gate the choice without recommending one, relay the selected route's prompts, and follow its `authOnce` or its absence.
- `ubiquitous-language`: add Authentication route; extend Configure once, Configure once prompt, and Credential boundary.

## Impact

`catalog_contracts.py`, `integration_catalog.py`, regenerated `documentation/integrations.json` and both Skill `tool-install.json` files, `tools.md` in both skill trees, `tests/test_ingest_docs.py`, `README.md` where it lists Tool install fields, `CHANGELOG.md`.
