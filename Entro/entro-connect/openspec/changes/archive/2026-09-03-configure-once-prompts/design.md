## Context

`configureOnce` shipped with `command`, `check`, `suitableWhen`, `sourceUrl`, and
`retrievedAt`. `tools.md` tells the skill to "request `configureOnce.command` in
the operator's terminal". A real run turned that into a bare command plus an
invented parenthetical, leaving the operator unable to answer the wizard. The
containers are unchanged from the `configure-once` design (skill, Tool install
file, operator, AWS CLI), so no C4 fence here: this is a data and copy change
inside an existing flow.

## Goals / Non-Goals

**Goals:**

- `prompts[]` on Configure once, ordered as the wizard asks, each with where the value comes from
- `docsUrl` on Configure once for the operator who wants the full page
- The Configure once request relays every prompt with its source; bare command is a defect
- AWS prompts sourced from AWS CLI documentation with a retrieval date
- Terraform's inherited AWS object relays the AWS prompts unchanged

**Non-Goals:**

- Changing `authOnce`, auth-check order, skip rules, or the inherit rule
- Collecting wizard answers in chat or binding them to `connectionFields`
- Filling `configureOnce` for other vendors
- `aws_profile` Operator input
- Agent-run wizard

## Decisions

### D1: `prompts[]` of `{prompt, whereToFind}`

- **Choice**: Ordered list on the object. `prompt` is the vendor's own on-screen
  label (`SSO start URL`, `CLI profile name`); `whereToFind` is one non-secret
  sentence naming the console, page, or choice that produces the value.
- **Reason**: The operator matches the label on screen and reads one line. Structure
  survives an agent that compresses prose.
- **Considered alternatives**: One guidance paragraph — rejected, compressible and
  unordered. `tools.md` prose — rejected, no per-vendor data. `sourceUrl` only —
  rejected, sends the operator out of the run.

### D2: Required with the object, not globally

- **Choice**: When `configureOnce` exists, `prompts[]` (non-empty) and `docsUrl`
  are required; validation fails otherwise. Entries without `configureOnce` are
  untouched.
- **Reason**: A Configure once without guidance is the defect this change fixes.
- **Considered alternatives**: Optional field — rejected, the next vendor repeats
  the same failure.

### D3: Prompts are not Operator inputs

- **Choice**: Wizard answers are typed into the vendor CLI. The skill MUST NOT
  collect them as Operator inputs, bind them to `connectionFields`, or store them
  in the Connect log; the log records only that Configure once was requested and
  its outcome.
- **Reason**: Operator inputs are keyed Connect values consumed by Typed actions
  and the Entro form. Wizard answers are none of those.
- **Considered alternatives**: Promote start URL to an Operator input — rejected,
  it belongs to the operator's CLI profile, not to Entro's form.

### D4: AWS prompt content

- **Choice**: Nine prompts in wizard order — session name, start URL, SSO region,
  registration scopes, account, role, CLI default region, output format, profile
  name. Start URL and SSO region cite the AWS access portal path (permission set →
  Access keys → IAM Identity Center credentials) and the Issuer URL alternative on
  AWS CLI 2.22.0 and later. Scopes note the `sso:account:access` default. Account
  and role name the target AWS account and a permission set that can create the
  Entro role. `docsUrl` is the AWS "Configuring IAM Identity Center authentication"
  page; `retrievedAt` `2026-09-03`.
- **Reason**: These are the questions the wizard actually asks, in order, and AWS
  documents where the first two come from.
- **Considered alternatives**: Only the four values the old message named —
  rejected, the operator still stalls on scopes and profile name.

### D5: Relay rule lives in `tools.md`

- **Choice**: The Configure once request message lists the command, every prompt
  with its source, and the `docsUrl`, then Continue / Help. No new gate, no change
  to who runs the wizard.
- **Reason**: Keeps one message and the existing gate; only its content grows.
- **Considered alternatives**: A separate "here is how to answer" message —
  rejected, splits the gate.

## Risks / Trade-offs

- [Risk] AWS changes the portal path or wizard order → Mitigation: `sourceUrl` and
  `retrievedAt` per object; refresh with the vendor pages at ingest.
- [Trade-off] Nine prompts make the request longer than one line → Reason: the
  short version is what failed the operator.
- [Trade-off] Guidance duplicates AWS docs → Reason: the operator should not leave
  the run; `docsUrl` still points at the full page.

## Migration Plan

1. Extend `catalog_contracts.py` (`ConfigureOnce`, validation) and fill the AWS
   prompts in `integration_catalog.py`; regenerate all catalog JSON.
2. Update `tools.md` in both skill trees with the relay rule.
3. Tests: prompts required and non-empty with the object; AWS prompt coverage and
   ordering; `tools.md` relay assertions in both trees.
4. Changelog via changelog-generator at apply. Rollback: drop `prompts`/`docsUrl`
   and revert the `tools.md` paragraph; the Configure once flow itself is unchanged.

N/A for services or databases — catalog data and skill copy only.

## Open Questions

None blocking. Follow-up unchanged: `aws_profile` Operator input.
