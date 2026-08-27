# Retrospective: add-test-mode

> Written: 2026-08-07 (after verify passed)
> Commit range: uncommitted (implementation on working tree)
> Worktree: saas-custom-operations

---

## 0. Evidence

- **Commit range**: not yet committed (changes on working tree atop `f988a58`)
- **Diff scope**: framework test mode, fixture runner, fixtures, README, CHANGELOG, OpenSpec change artifacts
- **Tasks done**: 40/40 (`tasks.md`)
- **Active hours**: single session
- **Subagent dispatches**: n/a
- **New external dependencies**: none
- **Bugs encountered post-merge**: none
- **OpenSpec validate state at archive**: pass (6/6); archive not yet run
- **Test coverage signal**: 128 tests passing (Vitest), 93.68% framework statement coverage

---

## 1. Wins

- [evidence: `with-custom-operation.ts`, `test-mode-persist.ts`] Token-gated test mode delivers offline fixtures and credential-validated dry runs without ISC writes.
- [evidence: `run-operation-fixture.ts`, smoke output] Fixture runner prints natural `res.send` output and inhibited persist logs in one command.
- [evidence: verify follow-up tests] Closed verification gaps for env fallback, ISC status failure, and CLI exit codes in the same session.

## 2. Misses

- 📌 [evidence: `run-operation-fixture.ts` COMMAND_HANDLERS] Fixture runner command registry is manual — easy to forget when adding operations.
- 📌 [evidence: git status] Implementation remains uncommitted; main specs not synced until archive.

## 3. Plan deviations

| Plan task | What changed | Why |
|---|---|---|
| Task 5 fixture runner | Added `runFixtureFromPath` export for testable exit codes | Verify warning on untested CLI path |
| Suggestion: previewPersistAttributes | Removed unused export | Dead code from initial sketch |

## 4. Skill / workflow compliance

| Skill | Used |
|---|---|
| superpowers:brainstorming | ✓ (via brainstorm.md artifact) |
| superpowers:writing-plans | ✓ (plan.md) |
| superpowers:using-git-worktrees | ✗ |
| superpowers:subagent-driven-development | ✗ |
| (transitive) superpowers:test-driven-development | ✓ |
| (transitive) superpowers:requesting-code-review | ✗ |
| superpowers:finishing-a-development-branch | ✗ |

### Deliberately Skipped Skills

- **`superpowers:using-git-worktrees`**
  - **What was skipped**: Isolated worktree for feature branch
  - **Why this cycle**: Single-agent apply on existing workspace; change scoped to framework + script
  - **How to prevent recurrence**: `scope-judgment rule` — use worktrees when parent repo has parallel unrelated dirty changes

- **`superpowers:subagent-driven-development`**
  - **What was skipped**: Per-task subagent dispatch from plan.md
  - **Why this cycle**: Parent agent executed plan directly in one session with TDD loops
  - **How to prevent recurrence**: `one-off — schema boundary case` when apply agent is monolithic

- **`superpowers:finishing-a-development-branch`**
  - **What was skipped**: PR creation
  - **Why this cycle**: User has not requested commit/PR; archive pending
  - **How to prevent recurrence**: Trigger finishing skill after archive commit when user asks to land the change

## 5. Surprises

- Initial test-mode persist reused `createPersist`, which still emitted production `[persist]` log lines — required a direct logging implementation instead.

## 6. Promote candidates → long-term learning

- [ ] 🟡 **Register new ops in fixture runner COMMAND_HANDLERS** → **Promote to README** (Test mode section)
  > **Why**: Manual registry drifted from auto-registry pattern used at build time.
  > **How to apply**: Checklist item when adding `custom:*` operations.

- [ ] 📌 **Wire fixture runner to auto-registry** → **One-off follow-up change**
  > **Why**: Would eliminate manual COMMAND_HANDLERS maintenance.
  > **How to apply**: Separate small change importing generated registry.
