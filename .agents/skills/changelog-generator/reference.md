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

Prefer semver in the heading when known: `## YYYY-MM-DD · vX.Y.Z`. Date-only (`## YYYY-MM-DD`) only when no version resolves.

Scope labels for multi-surface products: `[API]`, `[UI]`, `[CLI]`.

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

- Release headings: prefer `## YYYY-MM-DD · vX.Y.Z` when version known; `## YYYY-MM-DD` only as fallback
- Category headings: see **Category Headings** above
- Entry format: `- **Title** — Description.` (em dash, not hyphen)
- Separators: `---` between release sections only
- Omit empty category sections entirely

