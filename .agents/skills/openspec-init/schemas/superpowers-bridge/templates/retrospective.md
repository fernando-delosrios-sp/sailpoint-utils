# Retrospective: <change-name>

> Written: <YYYY-MM-DD> (after verify passed)
> Commit range: `<base-sha>..<head-sha>`
> Worktree: <path or "merged to main">

---

## 0. Evidence

> Quantitative preliminary data — subsequent Wins / Misses bullets quote this directly, avoiding repetitive [evidence: ...] per line.
> Cold writing scenario (retro written some time after the cycle ends): using `git log` + `tasks.md` + commit messages should be sufficient to reconstruct this section.

- **Commit range**: `<base-sha>..<head-sha>` (<n> commits)
- **Diff size**: <+X / -Y lines across N files>
- **Tasks done**: <x>/<y> (`grep -cE '^\s*- \[x\]' tasks.md` -> x; regex allows sub-task indentation)
- **Active hours**: <estimate>
- **Subagent dispatches**: <count or "n/a">
- **New external dependencies**: <list, with license + version, or "none">
- **Bugs encountered post-merge**: <count, one-line each, or "none">
- **OpenSpec validate state at archive**: <pass / fail / not-run>
- **Test coverage signal**: <e.g. jacoco %, pytest count, vitest count, or "n/a">

Commit chain (chronological):

```
<base-sha> <one-line summary>
...
<head-sha> <archive commit one-line>
```

---

## 1. Wins

- [evidence: <commit/file/test>] <description>

## 2. Misses

- 🔴 [blocking | evidence: ...] <description>
- 🟡 [painful  | evidence: ...] <description>
- 📌 [nit      | evidence: ...] <description>

## 3. Plan deviations

| Plan task | What changed | Why |
|-----------|--------------|-----|
| 1.2       | ...          | ... |

## 4. Skill / workflow compliance

| Skill                                            | Used |
|--------------------------------------------------|------|
| superpowers:brainstorming                        |      |
| superpowers:writing-plans                        |      |
| superpowers:using-git-worktrees                  |      |
| superpowers:subagent-driven-development          |      |
| (transitive) superpowers:test-driven-development |      |
| (transitive) superpowers:requesting-code-review  |      |
| superpowers:finishing-a-development-branch       |      |

> **Default expectation**: All ✓. Every skill is part of the schema design;
> skipping them falls under exceptional scenarios. Any ✗ must be accompanied by reasons and prevention plans in the `### Deliberately Skipped Skills` subsection below.

### Deliberately Skipped Skills

> Skipping a skill is a designed escape hatch, not a normal path. Each ✗ must answer the following three questions;
> The section being blank (all green) is the expected state.

- **`<skill name>`**
  - **What was skipped**: <Did you skip the entire skill, or a specific sub-step?>
  - **Why this cycle**: <Specific cycle condition — cannot write vague reasons like "not needed" / "too small" / "no time" / "blocked by external dep" / "skill output looked wrong"; must write actual trigger (specific commit / log line / observed behavior)>
  - **How to prevent recurrence**: How to avoid skipping it again under similar conditions in the next cycle? Choose one:
    - `schema graph fix` — Specify exactly which section of schema.yaml to change
    - `skill description tightening` — Specify exactly which skill's frontmatter / instruction to change
    - `CLAUDE.md trigger` — Specify exactly which interpretation rule to add in adopter CLAUDE.md.fragment
    - `scope-judgment rule` — Specify exactly how the cycle's scope should be interpreted
    - `one-off — schema boundary case, no prevention possible` — But must explicitly state why it's a boundary case (no vague reservations accepted)

> **Relationship with §6 Promote candidates**: Multiple cycles with the same skill and same `How to prevent`
> answer -> This pattern should be promoted to §6, directly triggering a schema / skill PR, and should not be accumulated as a "norm".

## 5. Surprises

- <assumption that turned out wrong>

## 6. Promote candidates -> long-term learning

Use `- [ ]` checklist for each candidate:

- Title: severity emoji (🔴/🟡/📌) + one-sentence learning
- `-> **Promote to** <destination>` (memory / CLAUDE.md / schema / skill / one-off)
- Two-line body (corresponding to superpowers feedback memory body schema):
  - `> **Why**: <reason; often a past incident or strong preference>`
  - `> **How to apply**: <when/where this guidance kicks in>`

Unchecked `- [ ]` indicates the candidate has not been promoted yet — it can be brought to the next cycle's retro for re-evaluation, or kept as an observation point across cycles.

> **Carry-forward mechanism**: When writing the retro for the next cycle, you can
> use `grep -A 5 '^- \[ \]' openspec/changes/archive/*/retrospective.md` to extract
> past unchecked candidates, and evaluate them one by one to see whether to carry them forward to §6 of the current cycle, promote them on the spot, or mark them as stale and no longer track them.

Example:

- [ ] 🔴 **<short rule>** -> **Promote to memory** (type: feedback)
  > **Why**: <past incident or strong preference that motivated this rule>
  > **How to apply**: <which file / cycle phase / decision moment this kicks in>

- [ ] 🟡 **<another candidate>** -> **Promote to project CLAUDE.md** (under `<path/to/CLAUDE.md>` section)
  > **Why**: ...
  > **How to apply**: ...

- [ ] 📌 **<third candidate>** -> **One-off** (just record, do not promote)
  > **Why**: <why it doesn't generalize>
