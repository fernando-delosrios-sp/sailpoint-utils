## Context

`evaluateAccessRisk` already walks every requested item, expands roles into access profiles and entitlements, and records each scored object in a `drivers` array holding `{ id, type, tier }`. `summarize` then throws almost all of it away: it keeps only drivers at the winning tier, excludes Low outright, and renders survivors as `TYPE:id` labels. The Low branch therefore returns the constant `'Low'`, and the Medium and High branches return UUID lists.

Everything this change needs is already in that array, so the work is confined to two pure functions and one type. No catalog call, no ISC read, and no persisted attribute key changes. The only external constraint is `ISC_STRING_ATTRIBUTE_MAX_LENGTH`, 256 characters, enforced by `fit()`.

The consumer is a person. `Access Request Pre-Check - Risk analysis and in-flight SOD` concatenates the summary into the approval comment; no bundled workflow reads or branches on its content.

## Goals / Non-Goals

**Goals:**

-   Replace the summary with counts of evaluated objects by type plus the rule that decided the tier.
-   Give a Low result a sentence that states what was evaluated instead of the bare word `Low`.
-   Attribute a winning driver to **effective privilege** or **Risk metadata**.
-   Keep the string length bounded independently of how many items were requested.

**Non-Goals:**

-   Object names in the summary. Excluded by decision, which also keeps nested-object name lookups out of the catalog.
-   Object ids in the summary. `contributing-ids` already carries them.
-   Any change to tier scoring, `contributing-ids`, the attribute keys, the operation response, or workflow JSON.
-   Localization or Markdown. The value is plain text stored in an ISC string attribute.

## Decisions

### D1: Two sentences — winning drivers, then the full tally

-   **Choice**: The summary is `<verdict sentence> Evaluated <tally>.` Types are always ordered role, access profile, entitlement, and a type with a zero count is omitted from both lists. Counts are pluralized (`1 role`, `2 roles`).
    -   Medium or High: `High: 2 of 6 entitlements scored High (1 by effective privilege, 1 by Risk metadata). Evaluated 1 role, 2 access profiles, 6 entitlements.`
    -   Low: `Low: nothing scored Medium or High. Evaluated 1 role, 2 access profiles, 6 entitlements.`
-   **Reason**: The verdict sentence answers "what tripped it" and the tally answers "how much was looked at", which together are what an approver needs to judge whether the tier is trustworthy. Fixed type ordering makes the output deterministic and therefore assertable.
-   **Considered alternatives**: One combined sentence — rejected, it needs subordinate clauses to hold both ideas and reads worse at a glance. Listing names — rejected by decision in discovery. Keeping the `TYPE:id` list — rejected, it duplicates `contributing-ids` and explains nothing.

### D2: Deciding rule is part of the entitlement scoring result

-   **Choice**: `tierFromEntitlement` returns `{ tier, rule }` rather than a bare `RiskTier`, where `rule` is `'effective privilege'` or `'Risk metadata'` and is absent for a Low tier. `RiskDriver` gains the same optional `rule`. Roles and access profiles are scored from `tierFromRiskMetadata`, so a non-Low tier there is always `'Risk metadata'`.
-   **Reason**: The function already evaluates both conditions and is the only place that knows which one fired. Recomputing the attribution in `summarize` would duplicate the precedence logic and let the two drift.
-   **Considered alternatives**: A separate `explainEntitlement` helper alongside the existing function — rejected, two functions reading the same inputs is exactly the drift risk. Inferring the rule in `summarize` from the raw snapshot — rejected, it would need the snapshot passed through the driver.

### D3: Effective privilege wins attribution when both rules fire

-   **Choice**: When an entitlement has both `privilegeLevel.effective` of `HIGH` and Risk metadata of critical or high, the driver is attributed to effective privilege. Same precedence at Medium.
-   **Reason**: Attribution must be single-valued to keep the counts summing to the driver total, and effective privilege is the more specific, entitlement-level signal. This mirrors the existing evaluation order in `tierFromEntitlement`, which already tests `effective` first.
-   **Considered alternatives**: Counting the driver under both rules — rejected, the rule counts would exceed the driver count and the sentence would read as a contradiction. Attributing to Risk metadata — rejected, it hides a privilege classification behind an admin-set label.

### D4: A rule with a zero count is omitted from the split

-   **Choice**: Render only non-zero rules, ordered effective privilege then Risk metadata: `(2 by Risk metadata)`, not `(0 by effective privilege, 2 by Risk metadata)`.
-   **Reason**: Zeroes are noise, and they are the common case whenever `considerPrivilege` is false, which would otherwise put a misleading `0 by effective privilege` on every summary.
-   **Considered alternatives**: Always printing both — rejected as above. Dropping the parenthetical when only one rule fired — rejected, the rule is the most valuable part of the sentence and must survive the single-rule case.

### D5: Counts are over distinct objects

-   **Choice**: Both the winning counts and the tally count distinct `type:id` pairs.
-   **Reason**: `scoreEntitlement` and `scoreAccessProfile` memoize, so a shared entitlement is pushed once, but roles have no such cache — a request naming the same role twice pushes two role drivers. Deduplicating at count time makes the numbers correct regardless of input shape and independent of the cache's implementation.
-   **Considered alternatives**: Adding a role cache — rejected, it changes evaluation behavior to fix a reporting concern. Counting raw driver entries — rejected, it reports `Evaluated 2 roles` for one role requested twice.

### D6: A clean container is evaluated but is not a driver

-   **Choice**: Keep pushing role and access-profile drivers with their own metadata tier, recorded before entitlement expansion. A role holding a High entitlement stays a Low driver and appears only in the tally.
-   **Reason**: This is the existing behavior and it is correct — the risk lives in the entitlement, and attributing it to the role would double-count one problem as two.
-   **Considered alternatives**: Recording the rolled-up tier on the container — rejected, `2 of 6 entitlements and 1 of 1 role scored High` describes a single High entitlement twice.

### D7: `fit()` stays as a backstop

-   **Choice**: Keep truncating through `fit()` even though the new format is bounded at roughly 150 characters in the worst case.
-   **Reason**: Length no longer scales with request size, so truncation should never fire; keeping the call means a future wording change cannot silently produce an over-long attribute that ISC rejects.
-   **Considered alternatives**: Dropping the call — rejected, it removes a cheap guard and the truncation warning log.

## Risks / Trade-offs

[Risk] An external consumer parses the old `{TYPE}:{id}` summary shape. -> Mitigation: nothing in this repo parses it — the only consumer concatenates it into an approval comment, and `contributing-ids` remains the machine-readable path. Called out in the proposal and the changelog.

[Risk] `tierFromEntitlement` changing its return type breaks a caller. -> Mitigation: it is exported but has exactly two call sites, `evaluate.ts` and `tiers.spec.ts`; `npm run typecheck` catches any other.

[Trade-off] Without names, an approver cannot tell _which_ entitlement is High from the summary alone. -> Accepted: that was the explicit instruction, `contributing-ids` carries the ids for anyone who needs to look, and omitting names avoids extra ISC reads for nested objects.

[Trade-off] Counting distinct ids means the tally can be lower than the number of requested items. -> Accepted: it reports what was actually evaluated, which is the honest number.

## Migration Plan

N/A — this change does not involve deployment changes. No `connector-spec.json` edit, no attribute key change, and no account schema reconciliation, because the operation output type literal is untouched and only the value of an existing string attribute changes.

Result accounts written before this change keep their old summary text; the new format appears on the next invoke. Old and new can coexist indefinitely since the field is read by people, not matched by workflows. Rollback is a code revert with no data cleanup.

Acceptance: `npm run typecheck` and `npm test` pass, with new cases covering every spec scenario.

## Open Questions

None.
