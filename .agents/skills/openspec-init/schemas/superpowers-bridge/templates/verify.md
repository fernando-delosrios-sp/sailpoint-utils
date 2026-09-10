# Verification Report

> Generated inside apply step 3 (verify-fix loop) on the original branch. Apply must not hand off until Overall Decision is ✅ PASS — fix blocking items autonomously in step 3; do not hand verify failures to the user. Worktree path: squash merge to the original branch before step 3. Standalone `/opsx:verify` after a completed apply should confirm PASS; new FAILs mean apply step 2b was incomplete.

**Change**: `<change-name>`
**Verified at**: `YYYY-MM-DD HH:mm`
**Verifier**: `<who / which agent>`

---

## 1. Structural Validation (`openspec validate --all --json`)

- [ ] All items have `"valid": true`

**Result**:

```text
<Paste the output summary of openspec validate --all>
```

If there are failed items, list their id + issues:

| Item | Type | Issues |
|---|---|---|
| — | — | — |

---

## 2. Task Completion Sanity Check (`tasks.md`)

- [ ] All `- [ ]` are `- [x]` (including Documentation and Changelog sections)

**Uncompleted tasks** (any row here = FAIL, return to apply):

| Task | Reason |
|---|---|
| — | — |

---

## 3. Spec Scenario Test Coverage

For each `#### Scenario:` in this change's delta specs, map to an automated test that exercises the assertions:

| Scenario (spec / requirement) | Test (file / name) | Covers GIVEN/WHEN/THEN? |
|---|---|---|
| — | — | ✓ / ✗ missing |

**Coverage gaps** (any ✗ missing = FAIL, return to apply to add tests):

- <none, or list>

---

## 4. Design / Specs Coherence

Spot-check that design.md decisions are reflected in specs/ requirements:

| Design decision | Corresponding requirement / scenario | Gap? |
|---|---|---|
| — | — | — |

**Material drift** (decision with no spec counterpart = FAIL):

- <none, or list>

---

## 5. Deferred Manual Dogfood vs Automated Test Equivalence

For manual dogfood / smoke tasks marked as `[~]` deferred in plan.md, list the equivalent automated test coverage item by item. If there is no equivalent automated test, this item is a **true gap** — record in retrospective Misses.

| Deferred dogfood (plan §) | Equivalent automated test | Coverage assessment | True gap? |
|---|---|---|---|
| — | — | — | — |

> **When this section can be left blank**: When plan.md has absolutely no rows marked with `[~]`, this section does not need to be filled (blank means PASS). As long as any `[~]` appears in plan.md, this section must be filled out item by item, otherwise Overall Decision = FAIL.

---

## Overall Decision

- [ ] ✅ PASS — Can proceed to retrospective and archive
- [ ] ❌ FAIL — Return to apply; fix issues and re-run verify

**Next Step**:

<Explain the next action>


