---
name: changelog-generator
description: Changelog from spec changes and git history. Never adds unreleased sections.
---

# Changelog Generator

Transform spec work and git commits into user-facing release notes.

Category headings, audience modes, format examples, and bump edge cases live in [reference.md](reference.md).

## INPUT

### Priority 1 (HIGH) — Required before drafting

| Source                 | Path / command                                          | Purpose                                                 |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| Existing changelog     | `@./CHANGELOG.md` (repo root)                           | Avoid duplicates; merge into today's section if present |
| Active change proposal | `<change-root>/proposal.md`                             | User-visible Capabilities checklist (when present)      |
| Git commit range       | `git log <range> --oneline`                             | Primary history source; group by spec/feature           |
| Changed files / diffs  | `git diff <range>` or per-commit diffs                  | User-visible outcomes for feat/fix/breaking changes     |

### Priority 2 (MED) — Use when available

| Source               | Path / command                                       | Purpose                                                           |
| -------------------- | ---------------------------------------------------- | ----------------------------------------------------------------- |
| OpenSpec tasks       | `<change-root>/tasks.md`                             | Confirm scope of shipped work                                     |
| OpenSpec specs delta | `<change-root>/specs/`                               | Contract or behavior changes                                      |
| Latest git tag       | `git describe --tags --abbrev=0`                     | Release boundary fallback; version candidate when semver-shaped   |
| Package / manifest   | `package.json` `version` (or equivalent)             | Baseline semver when no tag; bump target in Phase 4        |
| User request         | Chat context                                         | Explicit date range, tag, audience mode (public/internal), semver |

### Priority 3 (LOW) — Reference only

| Source                                                         | Purpose                                 |
| -------------------------------------------------------------- | --------------------------------------- |
| [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) | Canonical section taxonomy              |
| [Conventional Commits](https://www.conventionalcommits.org/)   | Prefix → category mapping               |
| PR descriptions / `gh pr list`                                 | Optional extra context — never required |

**Change root** — resolve once, then load `proposal.md`, `tasks.md`, and `specs/` from that folder (first match):

1. `ACTIVE_CHANGE_ROOT` when **apply-code-changes** has bound
2. `CHANGE_ROOT` when the apply adapter or user already set it
3. Explicit path from the user request
4. In-flight OpenSpec folder `openspec/changes/<change-name>/` — match change name, branch, or the only non-archive change

When no folder resolves after all four steps, record OpenSpec inputs as absent at the Phase 1 checkpoint.

**Scope resolution order:** explicit user range → last git tag to `HEAD` → newest `## YYYY-MM-DD` in `CHANGELOG.md` to today.

**Baseline version** (starting point for bump): explicit user semver → matching/latest git tag (`vX.Y.Z` or `X.Y.Z`) → package/manifest `version` → newest `vX.Y.Z` in `CHANGELOG.md`.

When user-visible changes exist, **propose a semver bump** per **Version bump** below — never write an unreleased section or a date-only heading.

Category mapping and prefix quick reference: [reference.md](reference.md).

---

## Version bump

Every shipped release section uses `## YYYY-MM-DD · vX.Y.Z` — dated, versioned, prepended newest-first.

**No unreleased sections** — never add `## [Unreleased]`, `## Unreleased`, or any placeholder awaiting a version. When changes exist, propose the next semver and write a dated release section.

When scope contains user-visible changes:

1. Resolve **baseline** per INPUT baseline rules; record as `X.Y.Z` (or `none` when no baseline exists anywhere).
2. Classify grouped changes (Phase 2), then take the **highest** applicable bump:

| Bump | Result | Triggers |
| --- | --- | --- |
| **MAJOR** | `X+1.0.0` | Any ⚠️ Breaking Changes or 🗑️ Removed |
| **MINOR** | `X.Y+1.0` | Any ✨ New Features or ⏳ Deprecated (when no MAJOR trigger) |
| **PATCH** | `X.Y.Z+1` | 🐛 Fixes, 🔧 Improvements, 📚 Documentation, 🔒 Security only (when no MAJOR/MINOR trigger) |

3. **Propose** baseline, bump class, and target `vX.Y.Z` at the Phase 2 checkpoint; wait for user confirmation before drafting.
4. At Phase 4, also propose updating the package/manifest `version` (and tagging when the user releases) to match the approved semver.

**No user-visible changes** — stop; do not add release sections or propose a bump.

**No baseline** — start from `0.0.0` and apply the bump class (first feature release → `0.1.0`; fixes-only → `0.0.1`). See `reference.md` for edge cases.

User-provided semver overrides the computed target when explicit.

---

## PHASES

Every bullet must **trace** to a commit, diff, or OpenSpec capability — do not invent features or fixes.

### Phase 1: Scope

- Resolve commit range per INPUT scope rules.
- Resolve baseline version per INPUT baseline rules; record `X.Y.Z` or `none`.
- Read `@./CHANGELOG.md` if it exists; note newest release section; reject or migrate any `[Unreleased]` / `Unreleased` heading (never preserve unreleased sections).
- If a change root resolved, read that folder's proposal Capabilities and Impact; list every user-visible capability as a checklist.
- Run `git log` for the resolved range; capture commit messages and hashes.
- Set audience mode (public default).
- **CHECKPOINT:** Confirm commit range, baseline version (or `none`), audience mode, and OpenSpec checklist (if any) before proceeding.
- **Done when:** commit range resolved, baseline recorded, audience mode set, OpenSpec capability checklist listed (or confirmed absent).

### Phase 2: Analyze

- Group commits by spec, feature, or logical change — **not one bullet per commit**.
- For each group with `feat`, `fix`, or breaking signal, read the relevant diff; note user-visible outcomes.
- Exclude internal-only work: tests, CI, refactors with no user impact, chore unless operator-facing.
- Optionally enrich from PR descriptions when they exist; do not fail if none exist.
- Map each group to a category per [reference.md](reference.md).
- Assign release date: `YYYY-MM-DD` (today unless user specifies otherwise).
- Compute proposed semver per **Version bump** from baseline + categories; if no user-visible changes, stop — no release section.
- Cross-check grouped changes against OpenSpec user-visible Capabilities checklist (when present).
- Flag missing capabilities, duplicate titles, or empty categories.
- Identify breaking changes needing migration bullets.
- Present structured checkpoint block:

```markdown
### Changelog scope
- Range: `<range>`
- Baseline: `vX.Y.Z` | none
- Proposed: `<MAJOR|MINOR|PATCH>` → `vX.Y.Z` (awaiting approval)
- Mode: public | internal
- OpenSpec capabilities: N listed, M traced, K gaps

### Grouped changes
| Group | Category | Trace |
|---|---|---|
| Dynamic forms | ✨ New Features | abc1234, def5678 |

### Gaps
- [ ] Capability X — no commit evidence (flag, do not fabricate)
```

- **CHECKPOINT:** Resolve gaps and confirm proposed semver before drafting prose.
- **Done when:** grouped changes table presented; bump proposal shown; every user-visible capability traced or flagged as gap; gaps resolved; user confirms semver.

### Phase 3: Draft

- Write one bullet per user-visible change: `- **Title** — Description.`
- Public mode: benefits-focused; no ticket numbers or internal jargon.
- Internal mode: may include scope labels, commit hashes `(abc1234)`, or PR links when available.
- Breaking changes: add nested migration bullet when users must act (see `reference.md`).
- Merge duplicates; drop internal noise; enforce voice and format.
- Omit empty category sections entirely.
- Present the full release section in chat for review (`## YYYY-MM-DD · vX.Y.Z` with approved semver).
- **CHECKPOINT:** User approves draft before writing to disk.
- **Done when:** full release section prose presented in chat; user approves at checkpoint.

### Phase 4: Ship

- Confirm all validation gates pass:

- [ ] ISO 8601 date + semver in heading (`## YYYY-MM-DD · vX.Y.Z`); no `[Unreleased]` / `Unreleased` sections
- [ ] Category headings match [reference.md](reference.md) (emoji + canonical label)
- [ ] No empty category sections
- [ ] No duplicate titles within the release
- [ ] Every ⚠️ entry states who is affected + migration when applicable
- [ ] All user-visible OpenSpec Capabilities represented (when proposal exists)
- [ ] Idempotent merge — no duplicate release headings or repeated bullets for the same date
- [ ] Every bullet traces to a commit, diff, or OpenSpec capability

- Update `CHANGELOG.md`:
  - **Prepend** new section at top (newest first).
  - If today's release section exists for the same approved semver, **merge into it** — do not duplicate the heading.
  - Re-run for same range **replaces** that section's content.
  - Insert `---` between release sections.
  - Remove any legacy `[Unreleased]` / `Unreleased` section when migrating content into the new release.
- Propose manifest `version` (and git tag when releasing) matching approved semver.
- **CHECKPOINT:** Present final changelog section, proposed version bump, and brief summary before commit/publish.
- **Done when:** `CHANGELOG.md` updated; all validation gates confirmed; user approves changelog and version bump.
