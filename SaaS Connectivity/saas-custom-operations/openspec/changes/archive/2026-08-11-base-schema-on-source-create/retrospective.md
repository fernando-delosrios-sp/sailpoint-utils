# Retrospective: base-schema-on-source-create

> Written: 2026-08-11 (after verify passed)
> Worktree: uncommitted session work on `base-schema-on-source-create`

---

## 0. Evidence

- **Tasks done**: 10/10 (`tasks.md` all `[x]`)
- **New files (this change)**: `src/framework/base-account-schema.ts`, `base-account-schema.spec.ts`; planning under `openspec/changes/base-schema-on-source-create/`
- **Modified (this change scope)**: `result-source.ts`, `operation-schema-registry.ts`, `scripts/templates/account-schema.ts`, `README.md`, `CHANGELOG.md`, specs delta
- **Test coverage signal**: 269 Vitest tests pass (full `npm test`); new coverage in `base-account-schema.spec.ts` and extended `result-source.spec.ts`
- **OpenSpec validate state at archive**: not-run (pending `/opsx-archive`)
- **Templates parity**: `npm run templates` succeeded; `account-schema.json` regenerated with core attrs + operation output union; `account-schema.spec.ts` (8 tests) green

---

## 1. Wins

- Shared `buildBaseAccountSchema` eliminated drift between templates generator and runtime source create — single inference path via `inferSchemaAttribute`.
- Create-or-patch flow in `applyBaseAccountSchema` handles ISC `DISCOVER_SCHEMA` pre-population without duplicate-schema failures.
- Existing-source path unchanged; add-only policy preserved for persist reconciliation via shared `buildSchemaAttributePatches`.

## 2. Misses

- 📌 [nit] Initial `ensureSourceSchema` type-conflict test broke when metadata patches were added to shared patch builder — fixed by adding identity/display/nativeObjectType to test fixtures.
- 📌 [nit] Verify report noted missing explicit `applyBaseAccountSchema` type-conflict test — added in follow-up (`warns on type conflict during base apply`).

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| 1.3 templates diff | Validated via `account-schema.spec.ts` + `npm run templates` run instead of committed before/after diff | Behavioral parity sufficient; generator output shape unchanged |

## 4. Skill / workflow compliance

| Skill | Used |
|-------|------|
| superpowers:brainstorming | ✓ (brainstorm.md) |
| superpowers:writing-plans | ✓ (plan.md) |
| superpowers:using-git-worktrees | ✗ (worked in main worktree) |
| superpowers:subagent-driven-development | ✗ (single-session apply) |
| (transitive) test-driven-development | ✓ |
| (transitive) requesting-code-review | ✗ |
| superpowers:finishing-a-development-branch | ✗ (pending archive) |

> Worktree/subagent/review skills skipped — small, focused change completed in one session. Acceptable for scope.

## 5. Follow-ups

- Archive change and sync `custom-operation-framework` delta into `openspec/specs/`.
- Operators with pre-existing result sources: no auto re-baseline; delete/recreate source optional if they want full base schema without waiting for per-op persist.
