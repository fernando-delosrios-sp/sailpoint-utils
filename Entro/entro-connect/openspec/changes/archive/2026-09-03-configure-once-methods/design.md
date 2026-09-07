## Context

`configureOnce` was written around one vendor command, `aws configure sso`, because Identity Center was the AWS path we documented first. The AWS CLI has no generic `aws login`; it reads credentials from the shared credentials file, the process environment, or an Identity Center token cache. The auth-check, `aws sts get-caller-identity`, already accepts any of them — only the remedy is opinionated. This design turns the remedy into a list of Authentication routes and lets the operator pick.

## Goals / Non-Goals

**Goals:**
- An operator with no IAM Identity Center can authenticate the AWS CLI through a cataloged route
- Each route carries its own presence check, prompts, Credential boundary, and sign-in or absence of one
- The skill still relays only cataloged guidance and still never touches a credential
- No behaviour change when the auth-check already reports a valid session

**Non-Goals:**
- `aws_profile` as an Operator input
- Other vendors filling `configureOnce`
- Changing the auth-check command, Platform identity, or the Terraform inherit rule
- Agent-run authentication, or any secret value in chat, agent context, or the Connect log

## Decisions

### D1: `configureOnce.methods[]` replaces the single-command shape
- **Choice**: `configureOnce` holds `methods`, a non-empty ordered list. Each route carries `name`, `whenToPick`, `check` (`command`, `sourceUrl`, `retrievedAt`), `suitableWhen`, `command`, `prompts`, `credentialBoundary`, `docsUrl`, `sourceUrl`, `retrievedAt`, and `authOnce` that MAY be null. The object keeps no top-level command, check, or prompts.
- **Reason**: check, prompts, boundary, and sign-in all differ per route; keeping one set at the top and one per route would leave two places to answer the same question.
- **Considered alternatives**: keep the single shape and add an "or authenticate another way" sentence — leaves the alternative uncataloged, which is the failure this change exists to fix. Support both shapes for a migration window — `aws` is the only entry with Configure once, so there is nothing to migrate.

### D2: Route selection runs every check, then gates only when it must
- **Choice**: after a failed auth-check, run every route's `check`. Exactly one suitable → select it with no gate. Zero or two-plus suitable → gate the choice, listing each route's `name` and `whenToPick` in catalog order.
- **Reason**: the common repair — an expired Identity Center token on a machine already configured for it — stays a single message. A gate appears only when the catalog genuinely cannot tell.
- **Considered alternatives**: always gate — noise for the common case. Always take the first suitable route — silently picks access keys over an already-configured SSO profile.

### D3: The gate marks no route recommended
- **Choice**: the route gate presents options without a recommended marker, and the skill MUST NOT rank them in prose.
- **Reason**: which route is correct depends on whether the operator's organization runs Identity Center and whether it permits access keys. We cannot know that, and a wrong recommendation is worse than none.
- **Considered alternatives**: mark Identity Center recommended per AWS security guidance — pushes operators toward a route their organization may not have.

### D4: `authOnce` MAY be null, and its absence has a defined repair
- **Choice**: a route with no sign-in step sets `authOnce: null`. When the selected route has a null `authOnce` and auth-check still fails after Continue, the skill re-requests that route's `command` — the credentials are wrong or expired and must be replaced — or offers Help. It MUST NOT fall back to another route's login.
- **Reason**: access keys do not expire on a schedule the CLI can refresh; there is nothing to sign into. Requesting `aws sso login` from an access-key operator is the exact defect this change removes.
- **Considered alternatives**: require every route to name a login — forces an invented command.

### D5: Entry-level `authOnce` stays, and the route's value wins
- **Choice**: every Tool install entry keeps its required `authOnce` string. When `configureOnce.methods` exists, the selected route's `authOnce` is authoritative and the skill MUST NOT request the entry-level one. Validation requires the entry-level value to equal some route's `authOnce`.
- **Reason**: most tools have no routes and depend on the entry-level field; the equality rule stops the two from drifting apart.
- **Considered alternatives**: drop the entry-level field when routes exist — every non-AWS consumer would need a null check.

### D6: AWS fills two routes, not three
- **Choice**: `aws` gets IAM user access keys and IAM Identity Center. Short-term credentials exported as `AWS_ACCESS_KEY_ID` and friends are deliberately excluded.
- **Reason**: the skill runs cataloged checks and the auth-check in its own shell, while the operator exports variables in theirs. Those credentials would be invisible to `aws sts get-caller-identity`, so the route would report failure no matter what the operator did. Pasting short-term credentials into the shared credentials file would be visible, but it is a hand edit with no vendor prompts to relay, so it does not fit the prompts contract yet.
- **Considered alternatives**: catalog the environment route anyway — ships a route that cannot pass its own check.

### D7: Route content for AWS

| | IAM user access keys | IAM Identity Center |
|---|---|---|
| `whenToPick` | Organization does not use Identity Center, or an IAM user access key already exists. No organization-level setup; keys are long-lived, so rotate or delete them after onboarding | Organization has Identity Center (the AWS access portal) enabled; credentials are short-lived and refresh with a browser sign-in |
| `check` | shared credentials file contains `aws_access_key_id` | AWS config file contains `sso_session` or `sso_start_url` |
| `command` | `aws configure` | `aws configure sso` |
| `prompts` | access key ID, secret access key (`secret`), default region, output format | today's nine wizard prompts, unchanged |
| `authOnce` | `null` | `aws sso login` |
| `credentialBoundary` | shared credentials file holding long-lived keys | vendor CLI token cache |
| `docsUrl` | `cli-authentication-user.html` | `cli-configure-sso.html` |

Access keys are listed first because they need nothing configured on the tenant; per D3 that order carries no recommendation. `aws configure import --csv` is a shortcut for the same route and belongs in that route's prompt guidance, not as a route of its own.

### D8: Secret prompts are relayed, never collected
- **Choice**: a prompt MAY set `secret: true`. The skill relays its label and `whereToFind`, states the value is typed into the vendor CLI, and MUST NOT collect it as an Operator input, echo it, or write it to the Connect log. `whereToFind` on a secret prompt MUST NOT contain a credential.
- **Reason**: `aws configure` asks for a secret access key, unlike the SSO wizard, so the existing "no wizard answers in chat" rule now has a value that is genuinely sensitive.

### D9: Checks stay quiet and test names only
- **Choice**: every route check uses `grep -q` or a `test -n` on names, never prints matched lines, and never reads a credential value. This also tightens today's Identity Center check, which prints matching config lines.
- **Reason**: the credentials file holds secrets, and check output reaches agent context.

## Risks / Trade-offs

[Trade-off] Cataloging long-lived access keys runs against AWS's own preference for short-term credentials -> Accepted: it is the only route that needs nothing configured at the organization level, its `whenToPick` says to rotate or delete the keys after onboarding, its Credential boundary is recorded honestly, and Identity Center stays available.

[Risk] `aws configure` writes the default profile and can overwrite keys an operator already relies on -> Mitigation: the route is only requested after its own check reports no access key present, or after the operator picks it at the gate; the prompt guidance names the profile it writes.

[Risk] An operator with both an SSO profile and access keys now sees a gate that did not exist before -> Mitigation: one extra gate, and it is the case where the catalog genuinely cannot choose.

[Trade-off] Breaking the `configureOnce` shape with no compatibility window -> Accepted: `aws` is the only entry that has one, and catalogs regenerate from source.

## Migration Plan

Extend the contracts, regenerate the three catalog files, update `tools.md` in both skill trees, and update the ingest tests in one commit; the Connect skill reads the catalog at run time, so there is no deployment step and no stored state to migrate. Acceptance: `pytest` green, both `tool-install.json` files carry two AWS routes, and a rehearsed run with no AWS credentials reaches the route gate rather than the SSO wizard. Rollback: revert the commit and regenerate.

## Open Questions

- Should short-term credentials pasted into the shared credentials file become a third route once the prompts contract can express a hand edit?
- `aws_profile` as an Operator input, so login, `aws configure`, and STS stop assuming the default profile — still open from the previous change and now touching two routes.
