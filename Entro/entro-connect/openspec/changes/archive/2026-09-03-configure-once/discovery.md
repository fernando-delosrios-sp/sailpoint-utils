## Scope

Add an optional Tool install **Configure once** object (check, `suitableWhen`, operator-run command) so Connect can write local CLI session config before `authOnce`; AWS fills it with `aws configure sso` as the first example. Out of scope: `aws_profile` / `AWS_PROFILE` as an Operator input (follow-up), other vendors filling the slot, Entro form fields, agent-run wizard, and reading `~/.aws/credentials`.

## Language

**Configure once** (`promote`):
An optional Tool install catalog object that records a non-secret check, a `suitableWhen` rule, and an operator-run command that writes local CLI session config so `authOnce` can succeed. Empty on CLIs whose sign-in creates that config itself.
_Avoid_: habilitator (chat only), sessionConfig, authPrerequisite, treating it as a Prep step or a Typed action

**authOnce** (`draft`):
Canonical field name stands. Sign-in stays operator-run in every Operation mode. Configure once is a prior, skippable step, not a replacement for `authOnce`.
_Avoid_: collapsing configure and login into one catalog string

**Capability probe** (`draft`):
Canonical term stands. Configure once is the same pattern (check before offering a command) applied to session config, not to whether the binary is installed.
_Avoid_: folding Configure once into the Capability probe

**Platform identity** (`draft`):
Canonical term stands. After Configure once, Connect re-runs auth-check; a valid session skips `authOnce` because the vendor wizard may already have signed in.
_Avoid_: treating the wizard as a secret source

**Tool install catalog** (`draft`):
Canonical term stands. Configure once lives on the shared Tool install entry (keyed by binary / MCP id), not on the AWS Row catalog. Terraform does not duplicate the AWS object; it keeps using the AWS credential chain.
_Avoid_: per-row configure blobs; a Terraform-only SSO wizard

## Decisions

**Context** — AWS `authOnce` is `aws sso login`, which only refreshes a profile already in `~/.aws/config`. `aws configure sso` writes that profile (and often completes the first browser login). Explore locked the forks below. Stage intent: Connect skill behavior plus catalog/spec, not a new secrets architecture.

**Q1 — Where does the habilitator live?** Config check, then wizard, then login. Skip the wizard when an SSO profile already exists. Do not only mention it in Help, and do not always dump both commands in `authOnce`.

**Q2 — Generic or AWS-only?** Generic optional slot on Tool install. AWS is the first fill (`aws configure sso`). `az login` / `gh auth login` stay empty. Snowflake `snow connection add` can fill later without another schema change.

**Q3 — Field name?** `configureOnce` as the English twin of `authOnce`. Glossary term: Configure once.

**Q4 — Terraform?** No second wizard. If the row lists `aws`, one Configure once covers the chain Terraform already auth-checks with `aws sts get-caller-identity`.

**Q5 — Profile name?** Deferred. This change does not add `aws_profile` or require `AWS_PROFILE`. Login without `--profile` uses `default`; wrong-profile failures stay Help.

**Q6 — Actor?** Operator terminal in every mode, same rule as `authOnce`. Agent does not run the wizard and does not accept login secrets.

## Open questions

- Exact check command for AWS (likely `aws configure list-profiles` plus `aws configure get sso_session` / `sso_start_url`) — pin against AWS CLI docs at design/apply.
- JSON nesting (`configureOnce.check` vs parallel `configureCheck`) — design.
- Whether ingest copies Configure once into `documentation/integrations.json` `toolInstall` or only the Skill Tool install file — design (today both exist).

## Scenarios discussed

- CLI present, no SSO profile, auth-check fails → operator runs `aws configure sso` → auth-check succeeds → skip `aws sso login`
- CLI present, SSO profile exists, token expired → skip wizard → `aws sso login` → auth-check
- Auth-check already valid (including IAM user keys) → skip Configure once and `authOnce`; confirm environment
- Help after failed login still diagnoses missing-config errors if the operator skipped or mis-ran the wizard
- `aws configure sso` is interactive (start URL, account, role, browser); start URL and account id are not secrets; tokens never enter chat or the Connect log
