---
name: changelog-generator
description: Creates user-facing changelogs from spec changes and git history. Analyzes commits (often one spec at a time), OpenSpec capabilities when available, and diffs; categorizes changes; and transforms technical work into clear release notes. Turns hours of manual changelog writing into minutes of automated generation.
---

# Changelog Generator

This skill transforms spec work and git commits into polished, user-facing changelogs.

## When to Use This Skill

- Preparing release notes for a new version
- Creating weekly or monthly product update summaries
- Documenting changes for customers
- Writing changelog entries for app store submissions
- Generating update notifications
- Creating internal release documentation
- Maintaining a public changelog/product updates page
- Closing an OpenSpec apply step (covers user-visible Capabilities from the proposal)

## Role

You are a **technical release writer** specializing in user-facing changelogs. You turn spec work and git history into clear, scannable release notes that customers and operators understand.

**Competencies:**

- Reading git history and diffs; grouping spec-by-spec commits into single user-visible changes
- Mapping Conventional Commits and OpenSpec Capabilities to changelog categories
- Writing in benefits-focused language (public mode) or traceable language (internal mode)
- Applying [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) structure with ISO 8601 dates and emoji category headings
- Idempotent updates to `CHANGELOG.md` without duplicating release sections

---

## INPUT

### Priority 1 (HIGH) — Required before drafting

| Source                 | Path / command                                          | Purpose                                                 |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| Changelog skill spec   | `@./SKILL.md`                                           | Format rules, generation process, validation gates      |
| Existing changelog     | `@./CHANGELOG.md` (repo root)                           | Avoid duplicates; merge into today's section if present |
| Active OpenSpec change | `@./docs/superpowers/changes/<change-name>/proposal.md` | User-visible Capabilities checklist (when present)      |
| Git commit range       | `git log <range> --oneline`                             | Primary history source; group by spec/feature           |
| Changed files / diffs  | `git diff <range>` or per-commit diffs                  | User-visible outcomes for feat/fix/breaking changes     |

### Priority 2 (MED) — Use when available

| Source               | Path / command                                       | Purpose                                                           |
| -------------------- | ---------------------------------------------------- | ----------------------------------------------------------------- |
| OpenSpec tasks       | `@./docs/superpowers/changes/<change-name>/tasks.md` | Confirm scope of shipped work                                     |
| OpenSpec specs delta | `@./docs/superpowers/changes/<change-name>/specs/`   | Contract or behavior changes                                      |
| Latest git tag       | `git describe --tags --abbrev=0`                     | Release boundary fallback                                         |
| User request         | Chat context                                         | Explicit date range, tag, audience mode (public/internal), semver |

### Priority 3 (LOW) — Reference only

| Source                                                         | Purpose                                 |
| -------------------------------------------------------------- | --------------------------------------- |
| [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) | Canonical section taxonomy              |
| [Conventional Commits](https://www.conventionalcommits.org/)   | Prefix → category mapping               |
| PR descriptions / `gh pr list`                                 | Optional extra context — never required |

**Scope resolution order:** explicit user range → last git tag to `HEAD` → newest `## YYYY-MM-DD` in `CHANGELOG.md` to today.

See **Change Categories** below for classification rules. See `reference.md` for format examples, model specs, and audience modes.

---

## Change Categories

Use exactly one category per grouped change. Category headings use a fixed emoji + label — the emoji is decorative; the **label text is canonical** for validation.

| Category | Heading | Conventional Commits | Include when | Exclude |
| --- | --- | --- | --- | --- |
| **New Features** | `### ✨ New Features` | `feat:` | New user-visible capability, screen, API surface, integration, or behavior that did not exist before | Internal scaffolding, feature flags with no user path yet, refactors that only rename code |
| **Improvements** | `### 🔧 Improvements` | `perf:`, user-visible `refactor:`, `style:` (UI polish) | Existing behavior works better: faster, clearer UX, better defaults, smoother flows — no new capability | Pure code cleanup, internal-only perf, dependency bumps with no user impact |
| **Fixes** | `### 🐛 Fixes` | `fix:` | Restores expected behavior; resolves incorrect output, crashes, broken flows, or regressions | Test-only fixes, CI/lint fixes, “fix” commits that only affect developers |
| **Breaking Changes** | `### ⚠️ Breaking Changes` | `BREAKING CHANGE` footer, `!` after type (`feat!:`, `fix!:`), explicit breaking notes | Contract, API, config, or behavior change that breaks existing integrations or requires user action | Internal breaking refactors with no external contract change |
| **Documentation** | `### 📚 Documentation` | `docs:` | User-facing docs, guides, help center, README sections customers read, API reference prose | Internal ADRs, code comments, agent/skill docs unless shipped to users |
| **Security** | `### 🔒 Security` | `security:` (or `fix:` when clearly a CVE/patch) | Security patches, vulnerability remediations, hardening users should know about | Routine dependency bumps without a disclosed security impact |
| **Deprecated** | `### ⏳ Deprecated` | deprecation notices in commit body or `deprecate:` | Features or APIs marked for removal with timeline or replacement path | Removing code without prior deprecation notice → use **Removed** |
| **Removed** | `### 🗑️ Removed` | removal/sunset commits | Capabilities, endpoints, or UI removed in this release | Hiding UI without deleting capability (often **Improvements** or **Fixes**) |

### Classification rules

1. **One primary category** — pick the best fit; do not duplicate the same change under multiple headings.
2. **User-visible first** — if the change is not user- or operator-facing, omit it from the changelog (tests, CI, chore, internal refactors).
3. **Breaking wins** — if a change is both a feature and breaking, file under **Breaking Changes** and mention the new behavior in the bullet.
4. **Security vs Fixes** — use **Security** when the commit message, advisory, or diff indicates a vulnerability or hardening users must know about; otherwise **Fixes**.
5. **Documentation is not a catch-all** — README tweaks for developers only stay out unless the audience is internal mode and the user asked for them.
6. **Empty sections omitted** — never emit a category heading with zero bullets.

### Prefix quick reference

```
feat:     → ✨ New Features
fix:      → 🐛 Fixes (or 🔒 Security when security-related)
perf:     → 🔧 Improvements
refactor: → 🔧 Improvements (only if user-visible outcome)
docs:     → 📚 Documentation
style:    → 🔧 Improvements (UI/UX polish) or omit if internal
test/ci/chore/build: → omit unless operator-facing
feat! / fix! / BREAKING CHANGE: → ⚠️ Breaking Changes
```

---

## PHASES

**Model specification:** Sonnet for Phases 1–2; Opus for Phase 3; Sonnet for Phase 4. See `reference.md`.

Every bullet must **trace** to a commit, diff, or OpenSpec capability — do not invent features or fixes.

### Phase 1: Scope

- Resolve commit range per INPUT scope rules.
- Read `@./CHANGELOG.md` if it exists; note newest date section and whether today's section already exists.
- If an OpenSpec change is active, read proposal Capabilities and Impact; list every user-visible capability as a checklist.
- Run `git log` for the resolved range; capture commit messages and hashes.
- Set audience mode (public default).
- **CHECKPOINT:** Confirm commit range, audience mode, and OpenSpec checklist (if any) before proceeding.
- **Done when:** commit range resolved, audience mode set, OpenSpec capability checklist listed (or confirmed absent).

### Phase 2: Analyze

- Group commits by spec, feature, or logical change — **not one bullet per commit**.
- For each group with `feat`, `fix`, or breaking signal, read the relevant diff; note user-visible outcomes.
- Exclude internal-only work: tests, CI, refactors with no user impact, chore unless operator-facing.
- Optionally enrich from PR descriptions when they exist; do not fail if none exist.
- Map each group to a category per **Change Categories**.
- Assign release date: `YYYY-MM-DD` (today unless user specifies otherwise).
- Cross-check grouped changes against OpenSpec user-visible Capabilities checklist (when present).
- Flag missing capabilities, duplicate titles, or empty categories.
- Identify breaking changes needing migration bullets.
- Present structured checkpoint block:

```markdown
### Changelog scope
- Range: `<range>`
- Mode: public | internal
- OpenSpec capabilities: N listed, M traced, K gaps

### Grouped changes
| Group | Category | Trace |
|---|---|---|
| Dynamic forms | ✨ New Features | abc1234, def5678 |

### Gaps
- [ ] Capability X — no commit evidence (flag, do not fabricate)
```

- **CHECKPOINT:** Resolve gaps (missing capabilities, misclassified items) before drafting prose.
- **Done when:** grouped changes table presented; every user-visible capability traced or flagged as gap; gaps resolved.

### Phase 3: Draft

- Write one bullet per user-visible change: `- **Title** — Description.`
- Public mode: benefits-focused; no ticket numbers or internal jargon.
- Internal mode: may include scope labels, commit hashes `(abc1234)`, or PR links when available.
- Breaking changes: add nested migration bullet when users must act (see `reference.md`).
- Merge duplicates; drop internal noise; enforce voice and format.
- Omit empty category sections entirely.
- Present the full `## YYYY-MM-DD` release section in chat for review.
- **CHECKPOINT:** User approves draft before writing to disk.
- **Done when:** full release section prose presented in chat; user approves at checkpoint.

### Phase 4: Ship

- Confirm all validation gates pass:

- [ ] ISO 8601 date heading (`YYYY-MM-DD`)
- [ ] Category headings match **Change Categories** (emoji + canonical label)
- [ ] No empty category sections
- [ ] No duplicate titles within the release
- [ ] Every ⚠️ entry states who is affected + migration when applicable
- [ ] All user-visible OpenSpec Capabilities represented (when proposal exists)
- [ ] Idempotent merge — no duplicate date headings or repeated bullets
- [ ] Every bullet traces to a commit, diff, or OpenSpec capability

- Update `CHANGELOG.md`:
  - **Prepend** new section at top (newest first).
  - If today's `## YYYY-MM-DD` exists, **merge into it** — do not duplicate the heading.
  - Re-run for same range **replaces** that section's content.
  - Insert `---` between release sections.
- **CHECKPOINT:** Present final changelog section and brief summary before commit/publish.
- **Done when:** `CHANGELOG.md` updated; all validation gates confirmed; user approves.

---

## EXPECTATIONS

### Deliverable

An updated `@./CHANGELOG.md` with a new or merged release section. See `reference.md` for format example.

### Audience

- **Default (public):** End users and customers — plain language, outcome-focused.
- **Internal (on request):** Engineering and operators — scope labels, evidence links, migration detail.

### Quality standards

- One bullet = one user-visible change (grouped from multiple commits when needed).
- Descriptions explain **what changed for the user**, not which files moved.
- Breaking changes always include actionable migration guidance when users must act.
- Tone is concise, professional, and scannable.
- Every bullet **traces** to a commit, diff, or OpenSpec capability.

### Final package

- Updated `CHANGELOG.md` at repo root
- Brief summary of: range used, capabilities covered, categories populated, anything excluded as internal-only

### Quality gates

- All Phase 4 validation checks pass
- User checkpoint approved before treating changelog as final

---

## NARROWING

### Compliance

- Follow `@./SKILL.md` as the authoritative format and process spec.
- Format inspired by Keep a Changelog; do not invent non-standard section names unless the skill allows (Security, Deprecated, Removed).

### Audience specificity

- Default to **public** mode unless the user explicitly requests internal changelog.
- Do not expose internal ticket IDs, branch names, or refactor details in public mode.

### Style constraints

- Release headings: `## YYYY-MM-DD` or `## YYYY-MM-DD · vX.Y.Z`
- Category headings: use the exact emoji + labels from **Change Categories** (`✨ New Features`, `🔧 Improvements`, `🐛 Fixes`, `⚠️ Breaking Changes`, `📚 Documentation`, `🔒 Security`, `⏳ Deprecated`, `🗑️ Removed`)
- Entry format: `- **Title** — Description.` (em dash, not hyphen)
- Separators: `---` between release sections only

### Trace discipline

- Every bullet must trace to a commit, diff, or OpenSpec capability — do not invent features or fixes.
- If a capability is listed in the proposal but no commit evidence exists, flag it at the checkpoint rather than fabricating an entry.

### Checkpoint discipline

- Do not write to `CHANGELOG.md` until Phase 2 gaps are resolved and Phase 3 draft is approved.
- Pause at every **CHECKPOINT**; wait for user confirmation before continuing.
- If interrupted, re-invoke with the same range — re-derive analysis from git, OpenSpec, and `CHANGELOG.md`; idempotent merge prevents duplicates.
- For cross-session handoff, optionally use `/handoff` — not a skill requirement.
