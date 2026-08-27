# Closing the Loop — execute, reconcile, issues

The advisor's job doesn't end at the handoff artifact. This file covers follow-through: dispatching an executor and reviewing its work (`execute`), keeping the backlog alive (`reconcile`), and publishing where work gets picked up (`--issues`).

The founding rule survives unchanged: **the advisor never edits source code.**

---

## Mode routing

| Mode | `execute` | `reconcile` | `--issues` |
|---|---|---|---|
| **Legacy** | Executor subagent on a plan in `plans/` | `plans/README.md` + plan files | `--body-file` the plan |
| **OpenSpec** | Invoke **apply-code-changes** on `openspec/changes/<slug>/`; advisor reviews apply output | Open changes under `openspec/changes/` (exclude `archive/`) | `proposal.md` + pointer to change folder |

---

## `execute` — dispatch and review

### Legacy: `execute <plan>`

#### Preconditions (check all before dispatching)

- The repo is a git repository (worktree isolation requires it). If not: stop and say so.
- The plan file exists and its dependencies show DONE in `plans/README.md`. If not: stop, name the missing dependency.
- Run the plan's drift check yourself. If in-scope files changed since `Planned at`, reconcile the plan first (see below) — don't hand a stale plan to an executor.

### Dispatch

Spawn **one** `general-purpose` subagent with `isolation: "worktree"`. Executor model: default `sonnet`; use what the user named if they named one (`execute 003 haiku`).

The subagent prompt must contain:

1. **The full plan file text, inlined.** The worktree contains only committed files — if `plans/` is uncommitted, the executor can't read it. Never assume; always inline.
2. The executor preamble:

> You are the executor for the implementation plan below. Follow it step by
> step. Run every verification command and confirm the expected result before
> moving on. Touch only the files listed as in scope. If any STOP condition
> occurs, stop immediately and report. Do not improvise around obstacles.
> Commit your work in the worktree following the plan's git workflow section.
> One override: SKIP the plan's instruction to update `plans/README.md` —
> your reviewer maintains the index. Before reporting, audit every claim in
> your report against an actual tool result from this session — only report
> what you can point to evidence for; if a verification failed or was
> skipped, say so plainly. When finished, reply with exactly the report
> format below.

3. The report format:

```
STATUS: COMPLETE | STOPPED
STEPS: per step — done/skipped + verification command result
STOPPED BECAUSE: (only if STOPPED) which STOP condition, what was observed
FILES CHANGED: list
NOTES: anything the reviewer should know (deviations, surprises, judgment calls)
```

### Review (the advisor's real job here)

Note on fresh worktrees: they share git history but not `node_modules` or build artifacts — the executor must install dependencies first, and check tooling that resolves from `dist/` may need one build even though the plan's command table (recon'd in the main tree) didn't mention it. Expect this; it isn't a deviation.

Review like a tech lead reviewing a PR against the spec — never fix anything yourself:

1. **Re-run every done criterion** in the worktree. Don't trust the executor's report — verify.
2. **Scope compliance**: `git -C <worktree> diff --stat` against the plan's in-scope list. Any file outside scope fails review, full stop.
3. **Read the full diff.** Judge it against "Why this matters" (does it solve the actual problem?) and the repo conventions named in the plan (does it look like the rest of the codebase?).
4. **Audit the new tests.** Executors game criteria — a test that asserts nothing meaningful passes `pnpm test` and proves nothing. Read what the tests assert.

### Verdict

**Documented deviations are judged on merit, not reflex-blocked.** "Do not improvise" exists to stop silent drift; an executor that hits a real obstacle (e.g. the plan's approach breaks existing test mocks), adapts minimally, and explains it in NOTES has done the right thing. Approve it if the adaptation serves the plan's intent and stays in scope; treat *undocumented* deviations as review failures.

| Verdict | When | Action |
|---|---|---|
| **APPROVE** | Criteria pass, scope clean, quality holds | Update index status to DONE. Present to the user: diff summary, worktree path and branch, anything from NOTES. **Merging is the user's decision — never merge, push, or commit to their branch.** |
| **REVISE** | Fixable gaps | SendMessage to the same executor with specific, actionable feedback ("criterion 3 fails: X; the error handling in `api.ts:90` swallows the error — use the Result pattern per the plan"). **Max 2 revision rounds**, then BLOCK. |
| **BLOCK** | STOP condition hit, scope violated unrecoverably, or revisions exhausted | Mark BLOCKED in the index with the reason. Refine or rewrite the plan with what was learned. Tell the user what happened and what changed in the plan. |

Running verification commands inside the executor's worktree is fine — it's isolated and disposable. The no-mutating-commands rule protects the user's working tree, not the worktree.

### OpenSpec: `execute <slug>`

1. Confirm `openspec/changes/<slug>/` exists. Read **Apply status** from that folder's `proposal.md`. Every **Depends on** slug must be DONE (see [openspec-change.md](./openspec-change.md)); if not, stop and name the missing dependency.
2. Run the drift check from `design.md` yourself before invoking apply.
3. Invoke **apply-code-changes** on the change folder — the skill owns venue gate, bind, task execution, and verify-fix.
4. Review apply handoff like a tech lead: re-run verification criteria from `tasks.md`, check scope against `design.md`, read the diff — never edit source yourself.
5. Write this package's **Status** (`DONE` | `BLOCKED`) in `proposal.md` Apply status. **Merging and archive are the user's decision** — never run `/opsx:archive` from improve.

---

## `reconcile` — keep the backlog alive

### Legacy: `plans/`

Process what happened since the last session. Read `plans/README.md` and every plan file, then per status:

- **DONE** — spot-check that the done criteria still hold on the current HEAD (cheap ones only). Mark verified in the index. Don't delete plan files — they're the record.
- **BLOCKED** — read the reason. Investigate the underlying obstacle in the codebase. Either rewrite the plan around it (new number if the approach changed fundamentally, in-place refresh otherwise) or mark REJECTED with one line of rationale.
- **IN PROGRESS** (stale) — flag it to the user; an executor probably died mid-run. Check the worktree if one exists.
- **TODO** — run the drift check. If drifted: re-verify the finding still exists (it may have been fixed in passing), then refresh the "Current state" excerpts and `Planned at` SHA. If the finding is gone, mark REJECTED ("fixed independently").

Finish with a short report: what's verified done, what was refreshed, what's rejected, and what's executable right now.

### OpenSpec: open changes

Walk `openspec/changes/` excluding `archive/`. Per change:

- **DONE** — spot-check cheap verification criteria on HEAD; keep **Apply status** at DONE.
- **BLOCKED** — investigate; refresh `design.md`/`tasks.md` or mark REJECTED in **Apply status**.
- **TODO** — run drift check; refresh excerpts and planned-at SHA in `design.md`; if finding is gone, mark REJECTED in **Apply status**.

Report executable slugs and dependency order.

---

## `--issues` — publish handoff artifacts as GitHub issues

Modifier on any planning invocation (`/improve --issues`, `/improve security --issues`). The flag is the user's authorization to create issues — never create them without it.

1. Preflight: `gh auth status` succeeds and the repo has a GitHub remote. If either fails, write artifacts as normal and say why issues were skipped.
2. Visibility check: `gh repo view --json visibility`. If the repo is **public**, warn the user that issues are publicly visible and get explicit confirmation before publishing any package that describes a security vulnerability, credential location, or other sensitive finding.
3. Show the list of titles about to become issues; confirm once if interactive.
4. **Legacy:** per plan — `gh issue create --title "<plan title>" --body-file <plan file>`.
5. **OpenSpec:** per change — `gh issue create --title "<proposal title>" --body-file <proposal.md>` with a footer linking `openspec/changes/<slug>/`.
6. Record each issue URL in the plan Status block (legacy) or that change's `proposal.md` **Apply status** Issue field (OpenSpec).

The handoff artifact remains the source of truth; the issue is distribution.
