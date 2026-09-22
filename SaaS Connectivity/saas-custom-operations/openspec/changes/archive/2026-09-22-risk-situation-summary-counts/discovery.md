## Scope

In: the text `custom:evaluate-access-request-risk` writes to `evaluate-access-request-risk:situation-summary`, which becomes counts of evaluated objects by type plus the rule that decided the tier. Out: the tier itself, `contributing-ids`, the scoring rules, the catalog reads, and every bundled workflow JSON.

## Language

**Risk situation summary** (`promote`):
The human-readable sentence persisted at `evaluate-access-request-risk:situation-summary`, describing why an access request landed on its tier. It is read by a person — the Access Request Pre-Check workflow pastes it into the approval comment — not parsed by a workflow.
_Avoid_: situation summary panel (that phrase is already reserved against the SoD persistable email body), risk explanation, risk reason.

**Risk driver** (`promote`):
One evaluated access object — a role, access profile, or entitlement — together with the tier its own attributes earned and the rule that set that tier. A role that contains a High entitlement is itself a Low driver; the entitlement is the High driver.
_Avoid_: contributor, risk item, offender.

**Deciding rule** (`promote`):
The named reason a risk driver reached its tier: **effective privilege** (`privilegeLevel.effective`) or **Risk metadata** (`iscRisk`). Only entitlements can be decided by effective privilege; roles and access profiles are always decided by Risk metadata.
_Avoid_: risk source, cause, trigger.

No conflicts found in `openspec/specs/ubiquitous-language/spec.md`. **Risk persist identity** and **wrapper discriminator** are unaffected by this change.

## Decisions

Context: for a Low request the operation persists the literal string `Low`, because `summarize` filters drivers to the winning tier while excluding Low, leaving an empty list and a constant. For High and Medium it persists `High: ROLE:2c9180…, ENTITLEMENT:83790b…` — raw UUIDs with no explanation. The same repo's `buildPreventiveSituationSummary` already writes real sentences, so the risk summary is the outlier.

Q1 — who reads this, a workflow or a person? A person. Only `Access Request Pre-Check - Risk analysis and in-flight SOD` consumes it, and it appends it to the approval comment. `Dynamic Approver - Risk analysis` ignores it. No workflow branches on its content, so the format is free to change without breaking a JSON contract.

Q2 — should it name the offending roles and entitlements? No. Names are deliberately excluded. Enumerate the objects by type instead and explain what determined the decision. This also avoids adding catalog reads, since names for nested objects are not in the current snapshots.

Q3 — should it carry ids then? No. `contributing-ids` already holds exactly those ids, so repeating them in prose is redundant and spends the 256-character budget for nothing.

Q4 — how much of the deciding rule? Split it. Distinguish effective privilege from Risk metadata rather than collapsing both into "scored High", because the two imply different remediation: one is a privilege classification on the entitlement, the other is access-model metadata an admin set.

Q5 — should the summary mention `considerPrivilege` when it is false? No. Rejected as noise for the approver, who cannot act on a connector input. A false toggle is already visible in the outcome, because no driver will be attributed to effective privilege.

Direction: the summary becomes two aggregate sentences — the winning drivers counted by type and split by deciding rule, then a tally of everything evaluated. Length stays bounded regardless of request size, because the string counts objects rather than listing them.

## Open questions

None. Wording of the two sentences is settled in design; pluralization and zero-count handling are spec scenarios rather than open decisions.

## Scenarios discussed

-   Low result with several objects evaluated — must state that nothing scored Medium or High and still report the tally, never the bare string `Low`.
-   High result where the role itself is clean and one nested entitlement is High — the role must count as evaluated but not as a driver, so attribution stays on the entitlement.
-   Two entitlements at the winning tier decided by different rules — the split must show one per rule, not two of the same.
-   A Medium result while a Low driver exists — only winning-tier drivers are counted as deciding.
-   Duplicate entitlement reached through two access profiles — the evaluation cache scores it once, so it must be counted once.
-   A request large enough to threaten the 256-character cap — the aggregate form must not grow with item count.
-   `considerPrivilege` false — no driver can be attributed to effective privilege, and the sentence must not claim otherwise.
-   Zero requested items resolved — behavior is unchanged and remains the existing input failure, not a summary concern.
