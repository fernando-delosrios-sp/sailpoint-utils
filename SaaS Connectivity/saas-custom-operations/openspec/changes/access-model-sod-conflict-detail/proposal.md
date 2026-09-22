## Why

A child result-source account is the only durable record that the scan found a conflict, and it describes that conflict nowhere. The account carries four fields, all of them about the notification: a form url, an email subject, an email body, and the recipient address. Anyone reading the record back — the Analysis workflow's conflict list, an auditor, a later operation — gets the access item name only because it happens to sit in the email subject, and gets the policy name only in the truncated form the 256-character email body allows, as in `on Acco… (ROLE) for policy AP sett…`. Which entitlements actually collide is absent entirely, even though the scan computed exactly that to decide there was a violation at all.

The existing spec already says the record should carry more. `Scenario: Child persist per form` requires `access-item-id`, `access-item-type`, `access-item-name`, `policy-id`, `policy-name`, and `recipient-id` on child output; the handler has never written them, because it persists whatever `toPersistAttributes` returns and that helper maps the four notification fields. Closing that gap costs no ISC reads — every value is already in the violation the loop is holding.

What the spec does not yet cover is the substance of the finding: the entitlements on each side of the policy. Naming them turns a record that says a conflict exists into one that says what the conflict is.

## What Changes

**Conflict detail on the child account**

-   From: four notification fields.
-   To: those four, plus the six identity fields the spec already requires, plus one plain-text attribute per policy side naming the colliding entitlements.
-   Reason: the record is the only durable description of a finding, and it does not describe it.
-   Impact: additive. Existing workflow reads of `form-url`, `form-email-header`, `form-email-body`, and `form-email-recipients` are untouched, so the Notification workflow is unaffected.

**Detail refresh on a skipped conflict**

-   From: an existing child account means skip the violation entirely and never overwrite the account.
-   To: still no form launch and no email, but the descriptive attributes are rewritten from the current scan while the notification fields are carried over from the stored account.
-   Reason: the scan skips every conflict it has already raised, so without a refresh a record written before this change never gains the detail, and a record whose access item or policy was later renamed stays wrong forever.
-   Impact: owners are not re-notified. The Notification workflow triggers on **Account Created**, and a refresh is an update. The form url and email fields are preserved verbatim, so a re-run cannot orphan a live form.

Unchanged: violation detection, form launch, the remediation form's own HTML, the response summary counters including `forms-skipped`, the child persist identity, and every input.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

-   `connector-operations/access-model-sod-remediation`: adds a requirement for the conflicting-entitlement attribute and replaces the skip requirement's blanket no-overwrite rule with a refresh that preserves the notification fields.

## Impact

Code: `src/operations/access-model-sod-remediation/index.ts` (persist call and the skip branch) and a new sibling module that builds the detail attributes from a violation. `index.schema.ts` is regenerated. No change to `connector-spec.json`, which declares commands rather than output attributes.

Tests: `index.spec.ts` gains assertions for the persisted keys and the skip refresh; the new module gets its own spec covering side naming, overflow, and the per-side 256-character ceiling.

Docs: the Output section of `src/operations/access-model-sod-remediation/README.md`, the bundled `Access Model SOD - Analysis` workflow whose conflict panels render these fields, and a changelog entry via the `changelog-generator` skill.

Operations: needs a connector redeploy. Existing child accounts gain the detail on the next scan rather than immediately, since the refresh happens when the scan re-encounters the conflict. Until then a panel reading the new attributes renders them empty, which is why the Analysis workflow keeps the access item name in the panel title where the email subject already supplies it.
