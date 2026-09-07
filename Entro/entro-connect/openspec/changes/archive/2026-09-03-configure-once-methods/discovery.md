## Scope

Turn Configure once into a list of Authentication routes: `configureOnce.methods[]`, each with its own check, command, prompts, credential boundary, and `authOnce` (or none), so an operator can authenticate the AWS CLI without IAM Identity Center. AWS fills two routes — IAM user access keys and IAM Identity Center. Out of scope: `aws_profile` as an Operator input, other vendors filling `configureOnce`, agent-run authentication, changes to the auth-check command or Platform identity, and any Entro form field.

## Language

**Authentication route** (`promote`):
One entry in a Configure once `methods` list: a named way to get a Configuration tool authenticated, carrying its own presence check, operator-run configure command, Configure once prompts, Credential boundary, and either an `authOnce` sign-in or none.
_Avoid_: auth method (collides with Authentication method, which is Entro's credential type on an Add New Account target), login option, profile

**Configure once** (`draft`):
Canonical term stands, but the object now holds `methods` instead of a single `command` / `check` / `suitableWhen` / `prompts` set.
_Avoid_: assuming one vendor command per tool

**Configure once prompt** (`draft`):
Canonical term stands; prompts now hang off a route. A prompt MAY be marked `secret`, meaning the operator types the value straight into the vendor CLI and it never reaches chat or the Connect log.
_Avoid_: collecting a `secret` prompt's value in chat

**Authentication method** (`draft`):
Canonical term stands and is unrelated: it is Entro's credential type on a row (for example GCP Service Account Key). An Authentication route is about the operator's local CLI session.
_Avoid_: using either term for the other

**Credential boundary** (`draft`):
Canonical term stands, but it now varies per Authentication route on the same tool: vendor CLI token cache for Identity Center, shared credentials file holding long-lived keys for access keys.
_Avoid_: one boundary per binary

## Decisions

**Context** — The AWS entry names `aws sso login` as `authOnce` and `aws configure sso` as its only Configure once command. There is no generic `aws login`; the AWS CLI authenticates from a credential file, environment, or Identity Center token cache. An operator whose organization has no Identity Center — or who simply does not want to enable it — is told to run two SSO commands that mean nothing for them.

**Q1 — Is SSO required?** No. `aws configure` with IAM user access keys works in any account with no organization-level setup, and the auth-check `aws sts get-caller-identity` accepts those credentials exactly as it accepts an Identity Center session.

**Q1a — What about exported short-term credentials?** Rejected for now. The skill runs cataloged checks and the auth-check in its own shell, so variables the operator exports in their terminal are invisible to it and the route would fail its own check no matter what the operator did.

**Q2 — Can one command be universal?** No. The universal part is the check; the remedy is a fork. So the catalog stores routes and the operator picks.

**Q3 — Shape?** `configureOnce.methods[]`, each `{name, whenToPick, check, suitableWhen, command, prompts, authOnce, credentialBoundary, docsUrl, sourceUrl, retrievedAt}`. Replaces the single-command shape; `aws` is the only entry with Configure once today, so there is no second consumer to migrate.

**Q4 — Which route runs?** After a failed auth-check, run every route's check. Exactly one suitable → use it silently. None or several suitable → gate the choice, listing `name` and `whenToPick`. The gate MUST NOT mark any route recommended: which one is right depends on the operator's organization, not on us.

**Q5 — `authOnce` when there is nothing to log into?** Access keys do not expire on a schedule the CLI can refresh, so that route carries `authOnce: null`. When the selected route has no sign-in and auth-check still fails, the skill re-requests that route's configure command or offers Help rather than inventing a login.

**Q6 — Entry-level `authOnce`?** Stays required for every tool, since most have no routes. When routes exist, the selected route's `authOnce` is authoritative and the skill MUST NOT request the entry-level string. Validation keeps them from drifting: the entry-level value must match one of the routes.

**Q7 — Secrets?** A route MAY have `secret` prompts (secret access key, session token). The skill relays the label and where to get it, states the value is typed into the vendor CLI, and never collects, echoes, or logs it. Route checks test for key names and environment variable presence only — never values.

**Q8 — Ordering?** Catalog order, no default flag. `whenToPick` carries the judgement.

## Open questions

None blocking. Follow-ups: short-term credentials pasted into the shared credentials file as a third route once the prompts contract can express a hand edit; `aws_profile` Operator input so login and STS stop defaulting to `default`.

## Scenarios discussed

- No credentials at all → gate lists both AWS routes with `whenToPick`; operator picks access keys; prompts relayed; `aws configure`; auth-check passes; no login requested
- Existing SSO profile, expired token → only that route's check is suitable → `aws sso login`, no gate
- Access keys present but rejected → route check suitable, `authOnce` null, auth-check still failing → re-request `aws configure` or Help
- Both an SSO profile and access keys present → two checks suitable → gate the choice
- Terraform inherits the AWS object and gets the same routes
- A `secret` prompt is relayed by label and source only, never collected in chat or written to the Connect log
