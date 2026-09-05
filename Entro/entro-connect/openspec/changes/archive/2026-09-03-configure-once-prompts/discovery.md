## Scope

Give Configure once operator-facing prompt guidance: `configureOnce` gains `prompts[]` (each wizard prompt plus where the operator finds that value) and a `docsUrl`, and `tools.md` must relay every prompt with its source when it asks the operator to run the wizard. AWS fills the prompts for `aws configure sso`. Out of scope: `aws_profile` as an Operator input, other vendors filling `configureOnce`, agent-run wizards, and any change to `authOnce` or the auth-check order.

## Language

**Configure once prompt** (`promote`):
One entry in a Configure once `prompts[]` list: the label the vendor wizard shows, and a non-secret sentence naming where the operator obtains that value.
_Avoid_: hint, tip, placeholder, treating a prompt as an Operator input (Operator inputs are cataloged Connect values with keys; wizard prompts are answered inside the vendor CLI)

**Configure once** (`draft`):
Canonical term stands. This change adds `prompts[]` and `docsUrl` to the object; `command`, `check`, `suitableWhen`, `sourceUrl`, and `retrievedAt` are unchanged.
_Avoid_: a single free-text blob that the agent may paraphrase

**Operator input** (`draft`):
Canonical term stands. Wizard answers are not Operator inputs: they are typed into the vendor CLI, never collected in chat, and never bound to `connectionFields`.
_Avoid_: collecting the start URL as an Operator input

## Decisions

**Context** — A live Connect run produced: "In your own terminal, run `aws configure sso` (start URL, region, account, role)." The catalog carries no prompt data, so the model invented that parenthetical and the operator was left with no way to answer the wizard. Configure once shipped in the `configure-once` change and is already archived.

**Q1 — Why did the run fail the operator?** `configureOnce` stores only `command`, `check`, `suitableWhen`, `sourceUrl`, `retrievedAt`. `tools.md` says "request `configureOnce.command`" and nothing more, so what the operator sees is model improvisation over a bare command name.

**Q2 — Where does the guidance live?** In the catalog, as structured `prompts[]`. Rejected: a single guidance string (the agent can compress it), `tools.md` prose only (no per-vendor data, the same improvisation returns), and relaying `sourceUrl` alone (sends the operator to a docs page mid-run).

**Q3 — Prompt shape?** `{prompt, whereToFind}` per entry, in the order the wizard asks. `prompt` is the vendor's own label so the operator can match it on screen; `whereToFind` is one non-secret sentence.

**Q4 — Does the agent have to relay them?** Yes. The Configure once request MUST list every cataloged prompt with its source and the `docsUrl` before the operator runs the command. Relaying only the command is a defect.

**Q5 — Required or optional?** `prompts[]` and `docsUrl` are required whenever `configureOnce` is present; validation fails on an empty list. An entry without Configure once is unaffected.

**Q6 — AWS values?** Start URL and SSO region come from the AWS access portal (permission set → Access keys → IAM Identity Center credentials), or the Issuer URL on the IAM Identity Center console dashboard for AWS CLI 2.22.0 and later. Registration scopes default to `sso:account:access`. Account and role are picked from the browser list after sign-in. CLI default region, output format, and profile name are operator choices.

**Q7 — Secrets?** Unchanged. Start URL, region, account id, and role name are non-secret. Tokens stay in the vendor cache; the wizard stays operator-run in every Operation mode.

## Open questions

None blocking. Follow-up unchanged from `configure-once`: `aws_profile` Operator input so login and STS stop defaulting to `default`.

## Scenarios discussed

- Unsuitable check → request lists every prompt with where to find it, plus `docsUrl`, then Continue / Help
- Suitable check → wizard skipped, so prompts are never relayed
- Valid auth-check → Configure once skipped entirely
- `configureOnce` present with an empty `prompts[]` → validation fails
- Terraform inherits the AWS object → it relays the AWS prompts, not a Terraform-specific list
- A prompt whose answer is chosen in the browser (account, role) still needs a sentence about which account and role to pick
