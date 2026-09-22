## Why

The Access Request Pre-Check workflow pastes `evaluate-access-request-risk:situation-summary` into the approval comment a human reads, but the text explains nothing. A Low request persists the bare string `Low`, because the summary builder drops Low drivers and falls back to a constant. A High or Medium request persists raw UUIDs, as in `High: ROLE:2c9180…, ENTITLEMENT:83790b…`, with no indication of what tripped the tier. Approvers get a verdict with no rationale, and the same repo's preventive SoD check already writes proper sentences, so risk is the outlier. Fixing it now costs almost nothing: every number needed is already in the drivers the evaluator collects, so no extra ISC reads are involved.

## What Changes

**Situation summary content**

-   From: `Low` for a Low result, or `{tier}: {TYPE}:{id}, …` listing winning driver ids for Medium and High.
-   To: two aggregate sentences — the winning drivers counted by object type and split by deciding rule, then a tally of everything evaluated. No object names and no ids.
-   Reason: the attribute is human-facing and currently carries no rationale; ids already live in `contributing-ids`.
-   Impact: non-breaking for workflows. No bundled workflow branches on this string; the Pre-Check workflow only concatenates it into a comment. Anything parsing the old `{TYPE}:{id}` shape would break, and nothing in this repo does.

**Deciding rule attribution**

-   From: `tierFromEntitlement` returns a bare tier, discarding whether effective privilege or Risk metadata set it.
-   To: the entitlement rule reports which of the two decided, and a risk driver carries that alongside its tier.
-   Reason: an approver acts differently on a privilege classification than on admin-set access-model metadata.
-   Impact: internal. Additive to the exported helper's result; the tier value it computes is unchanged.

Unchanged: the tier itself and every scoring rule, `contributing-ids`, the catalog and its ISC reads, the risk persist identity, and all bundled workflow JSON.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

-   `connector-operations/evaluate-access-request-risk`: adds requirements fixing the content of the risk situation summary — counts by object type, the split deciding rule, the Low wording, and attribution that keeps a clean role off the driver list.
-   `ubiquitous-language`: promotes **risk situation summary**, **risk driver**, and **deciding rule** from discovery into the glossary.

## Impact

Code: `src/operations/evaluate-access-request-risk/evaluate.ts` (`summarize`, `RiskDriver`, driver collection) and `tiers.ts` (`tierFromEntitlement` result shape). No change to `catalog.ts`, `index.ts`, `index.schema.ts`, or `connector-spec.json`, because the persisted attribute keys and the operation response are untouched.

Tests: `evaluate.spec.ts` asserts the summary contains `ENTITLEMENT:ent-high` and `ENTITLEMENT:ent-wrapped`; both assertions are replaced. `tiers.spec.ts` gains deciding-rule cases.

Docs: the Output section of `src/operations/evaluate-access-request-risk/README.md`, plus a changelog entry via the `changelog-generator` skill.

Operations: no redeploy coupling and no migration. Existing result accounts keep their old summary text; the new format appears on the next invoke. Because the string is read by people rather than matched by workflows, old and new accounts can coexist.
