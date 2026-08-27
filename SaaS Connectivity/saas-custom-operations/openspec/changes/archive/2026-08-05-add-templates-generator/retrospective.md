# Retrospective: add-templates-generator

> Written: 2026-08-05 (after verify passed)
> Commit range: `uncommitted session work on main`
> Worktree: saas-custom-operations (repo-local)

---

## 0. Evidence

- **Commit range**: session implementation (working tree clean at archive time)
- **Diff size**: ~19 new files under `scripts/templates/`, `scripts/generate-templates.ts`, package.json, README, CHANGELOG
- **Tasks done**: 22/22
- **Active hours**: ~1 session
- **Subagent dispatches**: n/a (direct apply in single agent session)
- **New external dependencies**: `tsx@^4.19.0` (devDependency)
- **Bugs encountered post-merge**: none
- **OpenSpec validate state at archive**: pass
- **Test coverage signal**: 57 vitest tests passing; src coverage 84.73% statements

Commit chain: implementation landed in working tree prior to archive (no dedicated feature commits in log).

---

## 1. Wins

- [evidence: `npm test` 57/57] Full generator pipeline with TDD-style unit + integration tests
- [evidence: `scripts/templates/workflow-reference.ts`] Corrected workflow source to `Workflow - SaaS Custom Operations Call.json` with ISC expression patterns
- [evidence: verify.md PASS] Spec scenario coverage complete after `name: account` fix

## 2. Misses

- 🟡 [painful | plan.md] Micro-step checkboxes in plan.md never synced with tasks.md completion
- 📌 [nit | spec.md] Invoke URL wording still uses `{API_URL}` placeholders while implementation uses ISC `{{$.configuration.*}}` expressions (design D7 intentional)

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| TS compiler API types | AST-only extraction for OperationSignature | Isolated fixture files don't resolve imports; heritageClauses not heritage |
| Workflow reference | Switched from full SP-Config export to workflow-only JSON | User correction mid-session |

## 4. Skill / workflow compliance

| Skill                                            | Used |
|--------------------------------------------------|------|
| superpowers:brainstorming                        | ✓ (artifacts exist) |
| superpowers:writing-plans                        | ✓ |
| superpowers:using-git-worktrees                  | ✗ |
| superpowers:subagent-driven-development          | ✗ |
| (transitive) superpowers:test-driven-development | ✓ (tests written per plan) |
| (transitive) superpowers:requesting-code-review  | ✗ |
| superpowers:finishing-a-development-branch       | ✗ (archive only) |

### Deliberately Skipped Skills

- **`superpowers:subagent-driven-development`**
  - **What was skipped**: Per-task implementer/reviewer subagent loop
  - **Why this cycle**: Single-session `/opsx:apply` executed directly; tasks were sequential and tightly coupled in one agent context
  - **How to prevent recurrence**: scope-judgment rule — for changes ≤25 tasks with existing plan.md, apply agent may inline when user expects single-session delivery

- **`superpowers:using-git-worktrees`**
  - **What was skipped**: Isolated worktree
  - **Why this cycle**: Implementation on main with clean tree; no parallel feature branches
  - **How to prevent recurrence**: one-off — schema boundary case when user works directly on main in scaffold repo

## 5. Surprises

- TypeScript `InterfaceDeclaration` uses `heritageClauses`, not `heritage` — initial signature extractor returned empty fields
- User workflow reference file was workflow-only JSON, not the earlier combined SP-Config export

## 6. Promote candidates -> long-term learning

- [ ] 🟡 **Reference workflow path constant** -> **Promote to project README/AGENTS.md**
  > **Why**: User corrected workflow source mid-session; generator now uses `workflow-reference.ts` but authors need to know canonical path
  > **How to apply**: Document `workflows/Workflow - SaaS Custom Operations Call.json` as the operator workflow template in README
