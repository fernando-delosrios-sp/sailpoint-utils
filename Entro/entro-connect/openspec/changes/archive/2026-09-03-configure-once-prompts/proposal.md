## Why

A live Connect run asked the operator to "run `aws configure sso` (start URL, region, account, role)" and stopped there. The catalog holds no prompt data, so that parenthetical was model improvisation and the operator had no way to answer the wizard: nothing said the start URL and SSO region come from the AWS access portal, that scopes default to `sso:account:access`, or which account and role to pick. Configure once shipped as a command name without the knowledge that makes it runnable, which is the same gap `authOnce` had before this pattern existed.

## What Changes

**Configure once carries prompts**
- From: `configureOnce` is `command`, `check`, `suitableWhen`, `sourceUrl`, `retrievedAt`
- To: it also carries `prompts[]` — each `{prompt, whereToFind}` in wizard order — and a `docsUrl`
- Reason: where a value comes from is per-vendor knowledge; the catalog is this repo's source of truth, not the model's memory
- Impact: additive but required whenever `configureOnce` exists; validation fails on a missing or empty `prompts[]`

**The request relays them**
- From: `tools.md` says request `configureOnce.command`
- To: the request MUST list every cataloged prompt with its source and the `docsUrl` before the operator runs the command; relaying the bare command is a defect
- Reason: the operator reads chat, not `tool-install.json`
- Impact: `tools.md` in both skill trees; auth-flow tests

**AWS fills the prompts**
- From: `aws configure sso` with no guidance
- To: session name, start URL, SSO region, registration scopes, account, role, CLI region, output format, and profile name, each with where the operator finds it (access portal permission set → Access keys → IAM Identity Center credentials; Issuer URL on AWS CLI 2.22.0+)
- Reason: AWS documents these; the operator should not leave the run to hunt for them
- Impact: `aws` Tool install entry in ingest `toolInstall` and both Skill Tool install files; Terraform keeps inheriting the AWS object and relays the AWS prompts

## Non-goals

No `aws_profile` / `AWS_PROFILE` Operator input (still a follow-up). No other vendors filling `configureOnce`. No change to `authOnce`, the auth-check order, Configure once skip rules, or the Terraform inherit rule. No agent-run wizard. No secrets in chat or the Connect log — wizard answers are typed into the vendor CLI and are not Operator inputs. No new capability domain.

## Capabilities

### New Capabilities

- None. Prompts belong on the existing Tool install and Connect auth requirements.

### Modified Capabilities

- `documentation-ingest`: `configureOnce` MUST carry `prompts[]` and `docsUrl` when present; AWS MUST fill them; empty prompts MUST fail validation.
- `integration-automation`: the Configure once request MUST relay every cataloged prompt with its source and the `docsUrl`.
- `ubiquitous-language`: add Configure once prompt; extend Configure once Notes.

## Impact

`catalog_contracts.py`, `integration_catalog.py`, regenerated `documentation/integrations.json` and both Skill `tool-install.json` files, `tools.md` in both skill trees, `tests/test_ingest_docs.py`, `README.md` if it lists Tool install fields, `CHANGELOG.md`.
