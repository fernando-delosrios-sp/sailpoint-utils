# Changelog Generator Reference

Category definitions and emoji assignments live in [`SKILL.md` § Change Categories](./SKILL.md#change-categories). This file covers model selection, format examples, and audience modes.

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


