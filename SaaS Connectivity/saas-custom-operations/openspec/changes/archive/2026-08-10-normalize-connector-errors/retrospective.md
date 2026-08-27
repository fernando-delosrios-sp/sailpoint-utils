# Retrospective: normalize-connector-errors

> Written: 2026-08-10 (after verify passed)
> Worktree: saas-custom-operations (uncommitted)

---

## 0. Evidence

- **Tasks done**: 22/22
- **Test coverage signal**: 193 Vitest tests passing
- **OpenSpec validate state at verify**: pass (8/8)
- **New files**: `src/framework/connector-error.ts`, `src/framework/connector-error.spec.ts`

---

## 1. Wins

- [evidence: connector-error.ts + with-custom-operation.ts] Single `toConnectorError` helper plus boundary wrapper gives all operations ConnectorError guarantee without per-handler boilerplate.
- [evidence: sod-form-service.spec.ts] Forms API failures already had partial wrapping; completed missing-response paths and added failure scenario tests.
- [evidence: npm test 193/193] No regressions across framework and operation tests.

## 2. Misses

- 📌 [nit | evidence: task 5.3] Manual spcx retry validation deferred — unit tests cover error typing; tenant workflow retry behavior still needs post-deploy confirmation.

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| sod-form-service | Partial implementation pre-existed (`formatFormsApiError`) | Prior session work; completed remaining ConnectorError gaps only |

## 4. Skill / workflow compliance

| Skill | Used |
|-------|------|
| superpowers:brainstorming | ✓ (via brainstorm.md at propose) |
| superpowers:writing-plans | ✓ (plan.md) |
| superpowers:subagent-driven-development | ✗ (single-agent apply) |
| test-driven-development | ✓ (tests alongside implementation) |
| verification-before-completion | ✓ |

### Deliberately Skipped Skills

- **superpowers:subagent-driven-development**
  - **What was skipped**: Per-task subagent dispatch
  - **Why this cycle**: Focused change (~5 files); direct implementation faster than dispatch overhead
  - **How to prevent recurrence**: Use subagent-driven-development when plan has 8+ independent task groups

## 5. Surprises

- `sod-form-service.ts` already had `formatFormsApiError` from earlier uncommitted work — reduced scope but required aligning missing-response throws with the same contract.

## 6. Promote candidates → long-term learning

- [ ] 🟡 **Always throw ConnectorError at customOperation boundary** → **Promote to project memory**
  > **Why**: Plain axios errors caused workflow retries observed in spcx debug
  > **How to apply**: Any new ISC client module or operation handler — failures must not escape as unclassified Error
