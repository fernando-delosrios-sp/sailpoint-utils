# Changelog Generator Reference

Category definitions, classification rules, and emoji assignments. SKILL.md links here for Phase 2 mapping.

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

## Model Specification

| Phase | Model | Work |
|---|---|---|
| 1. Scope | Sonnet | Resolve range, load sources, OpenSpec checklist |
| 2. Analyze | Sonnet | Group commits, classify, cross-check capabilities, present gaps |
| 3. Draft | Opus | User-facing prose, tone, merge duplicates |
| 4. Ship | Sonnet | Validation checklist, write `CHANGELOG.md` |

## Category Headings (canonical)

| Heading |
| --- |
| `### ✨ New Features` |
| `### 🔧 Improvements` |
| `### 🐛 Fixes` |
| `### ⚠️ Breaking Changes` |
| `### 📚 Documentation` |
| `### 🔒 Security` |
| `### ⏳ Deprecated` |
| `### 🗑️ Removed` |

## Format Example

```markdown
## 2026-07-24 · v2.5.0

### ✨ New Features

- **Dynamic forms and user data collection** — Example ISC form configuration with cascading dropdowns (buildings, locations, rooms) and CSV-backed reference data for structured user input during provisioning or access requests.

### 📚 Documentation

- Expanded README for dynamic forms: how dropdowns chain together and how user selections persist.

### 🐛 Fixes

- Restored promotional screenshot accidentally removed from the dynamic forms guide.

---
```

Prefer semver in every release heading: `## YYYY-MM-DD · vX.Y.Z`. Never use `[Unreleased]` or date-only headings for new work.

Scope labels for multi-surface products: `[API]`, `[UI]`, `[CLI]`.

## Semver bump

Compute from baseline `X.Y.Z` and the **highest** trigger in scope:

```
X  .  Y  .  Z
 │     │     └─ PATCH — 🐛 Fixes, 🔧 Improvements, 📚 Documentation, 🔒 Security
 │     └─────── MINOR — ✨ New Features, ⏳ Deprecated
 └───────────── MAJOR — ⚠️ Breaking Changes, 🗑️ Removed
```

| Situation | Proposed target |
| --- | --- |
| Baseline `1.2.3`, fixes only | `1.2.4` (PATCH) |
| Baseline `1.2.3`, new features, no breaking | `1.3.0` (MINOR) |
| Baseline `1.2.3`, any breaking or removal | `2.0.0` (MAJOR) |
| No baseline, first feature release | `0.1.0` (MINOR) |
| No baseline, fixes/docs/security only | `0.0.1` (PATCH) |

Present baseline, bump class, and target at Phase 2; apply to `CHANGELOG.md` after approval. Phase 4 also proposes updating manifest `version` (and a git tag when releasing).

## Breaking Change Format

```markdown
- **Auth token format** — Tokens now use JWT; legacy opaque tokens are rejected.
  - Migration: regenerate tokens via Settings → API Keys before 2026-08-01.
```

Every ⚠️ entry must state who is affected and include migration guidance when users must act.

## Audience Modes

### Public (default)

- End users and customers
- Plain language, outcome-focused
- No ticket numbers, branch names, or internal jargon
- Benefits-focused descriptions

### Internal (on request)

- Engineering and operators
- May include scope labels (`[API]`, `[UI]`, `[CLI]`)
- May include commit hashes `(abc1234)` or PR links when available
- Traceable language linking bullets to evidence

## Style Constraints

- Release headings: always `## YYYY-MM-DD · vX.Y.Z`; never `[Unreleased]`
- Category headings: see **Category Headings** above
- Entry format: `- **Title** — Description.` (em dash, not hyphen)
- Separators: `---` between release sections only
- Omit empty category sections entirely


