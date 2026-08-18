# Retrospective: sod-remediation-form-email-outputs

> Written: 2026-08-17 (after verify passed)
> Commit range: pending (implementation not yet committed at write time)
> Worktree: in-place on `feat/sod-remediation-form-email-outputs` (parent repo `sailpoint-utils`)

---

## 0. Evidence

- **Commit range**: branch created from `e1cc9bb`; implementation uncommitted at retro write
- **Diff size**: ~+35 / −33 across 9 implementation files, plus new `openspec/changes/sod-remediation-form-email-outputs/`
- **Tasks done**: 12/12
- **Active hours**: ~1 (propose + apply same session)
- **Subagent dispatches**: n/a (in-session TDD; tasks tightly coupled)
- **New external dependencies**: none
- **Bugs encountered post-merge**: none
- **OpenSpec validate state at archive**: not-run (archive deferred)
- **Test coverage signal**: `npm test` 64 files / 368 tests passed

Commit chain (at write):

```
e1cc9bb chore(agents): add grill-me, grill-with-docs, and writing-for-agents skills
```

---

## 1. Wins

- [evidence: `index.spec.ts` RED then GREEN] Persist key rename caught by failing persist assertions before production edit
- [evidence: `npm test` 368 passed] No collateral failure in sibling operations
- [evidence: `index.schema.ts` codegen] Sidecar regenerated; no hand-edit

## 2. Misses

- 🟡 [painful | evidence: `git status` concurrent `access-sod-remediation/`] Apply ran on a dirty parent-repo tree; archive cannot `git add openspec/changes/` without mixing another change
- 📌 [nit | evidence: `CHANGELOG.md` diff includes access-sod-remediation New Features bullet] Changelog file is mixed-session; breaking entry is in the working copy but not isolated for commit

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| Task 1 Step 6 commit | Deferred to end of apply | Session-scoped commit after all tasks; dirty concurrent tree |
| Archive (schema apply 4) | Not run | Would stage sibling untracked change `access-sod-remediation` |
| SDD per-task subagents | In-session TDD instead | Tasks are one rename; SDD skill routes tightly coupled work away from parallel implementers |

## 4. Skill / workflow compliance

| Skill | Used |
|---|---|
| superpowers:brainstorming | ✓ (verbal, then `brainstorm.md` at propose) |
| superpowers:writing-plans | ✓ (`plan.md` in change dir) |
| superpowers:using-git-worktrees | ✗ |
| superpowers:subagent-driven-development | ✗ |
| (transitive) superpowers:test-driven-development | ✓ (RED persist tests, then GREEN keys + codegen) |
| (transitive) superpowers:requesting-code-review | ✗ |
| superpowers:finishing-a-development-branch | ✗ (PR last; archive not run) |
| changelog-generator | ✓ (Unreleased breaking entry; mixed file not staged) |
| git-commit | pending after retro |

### Deliberately Skipped Skills

- **`using-git-worktrees`**
  - **What was skipped**: Isolated worktree creation
  - **Why this cycle**: Schema apply instruction says work on current branch; parent repo `main` already had concurrent uncommitted `access-sod-remediation` work. Feature branch `feat/sod-remediation-form-email-outputs` was created in place. Asking for a worktree would have paused apply; copying uncommitted openspec artifacts into a clean worktree would have split the change.
  - **How to prevent recurrence**: `scope-judgment rule` — when the git root is a parent monorepo with concurrent dirty changes, create a feature branch and session-scope commits; do not `git add openspec/changes/` wholesale.

- **`subagent-driven-development`**
  - **What was skipped**: Per-task implementer + reviewer dispatches
  - **Why this cycle**: SDD when-to-use: tasks not independent (one persist-key rename). Cursor `/opsx-apply` implements the task loop in session. Schema still required TDD, which was followed.
  - **How to prevent recurrence**: `skill description tightening` — SDD vs schema apply: tightly coupled rename changes may execute TDD in the apply session without per-task subagents.

- **`requesting-code-review`**
  - **What was skipped**: Separate reviewer subagent
  - **Why this cycle**: Transitive through SDD, which was not dispatched. Diff is a mechanical key rename with RED/GREEN evidence.
  - **How to prevent recurrence**: `one-off — schema boundary case, no prevention possible` — mechanical rename under `/opsx-apply` in-session loop; a reviewer subagent would re-read the same four-key mapping.

- **`finishing-a-development-branch`**
  - **What was skipped**: PR open
  - **Why this cycle**: Schema forbids PR before archive commit; archive is deferred because `openspec/changes/access-sod-remediation/` is untracked.
  - **How to prevent recurrence**: `scope-judgment rule` — isolate one OpenSpec change per branch before apply, or archive with explicit path lists excluding sibling change dirs.

## 5. Surprises

- Git root is `sailpoint-utils`, not `saas-custom-operations`. Status paths are prefixed `SaaS Connectivity/saas-custom-operations/`.
- `npm run codegen:schemas` rewrote sibling sidecars and `auto-registry.ts` (already dirty from the other change). Those files were left unstaged.

## 6. Promote candidates → long-term learning

- [ ] 🟡 **Do not `git add openspec/changes/` during archive when sibling change directories are untracked** → **Promote to** schema apply archive instruction
  > **Why**: This cycle's archive step would have mixed `access-sod-remediation` into the form-email-outputs commit.
  > **How to apply**: Archive staging must list `openspec/changes/<name>/` and `openspec/changes/archive/` explicitly, never the parent `openspec/changes/` glob when other active changes exist.
