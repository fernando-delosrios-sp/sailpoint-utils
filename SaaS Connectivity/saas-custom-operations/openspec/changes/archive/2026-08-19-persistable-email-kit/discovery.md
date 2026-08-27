## Scope

Extract shared helpers for building compact HTML email snippets that fit ISC STRING persist limits (256 chars), including escape, truncation, proportional name budgeting, and unquoted form/CTA links. Migrate duplicated helpers in form-email modules, sod-remediation situation summary email body, and access-request-status approval email. Out of scope: form launch choreography, persist key mapping, workflow JSON, and SoD form DESCRIPTION HTML (`sod-form-html`).

## Language

**Persistable email body** (`promote`):
A compact HTML string intended for DelimitedFile/STRING account attributes and ISC workflow Send Email bodies, bounded by `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256).
_Avoid_: form DESCRIPTION HTML, situation summary panel, rich email template

**Name budget fit** (`draft`):
Strategy that shortens escaped display names proportionally so a rendered HTML paragraph stays within the STRING limit while preserving a CTA link.
_Avoid_: mid-tag truncation, blind slice of the full body first

**Unquoted href CTA** (`promote`):
An HTML anchor whose `href` value is not wrapped in quotes, kept DelimitedFile/`provisionAsCsv`-safe when URLs contain no spaces.
_Avoid_: quoted href, markdown links

## Decisions

**Context** — Explore session (2026-08-19): three form-launch ops plus access-request-status duplicate escape/truncate/fit-to-256 logic for workflow-oriented email HTML.

**Q1 — Kit vs extend sod-form-html?**
→ New `src/lib/persistable-email/` (or equivalent). SoD form DESCRIPTION content is a different concern; keep `sod-form-html` for in-form panels/lists. Re-export `escapeHtml` from one place to avoid two escape implementations.

**Q2 — Include access-request-status?**
→ Yes for the kit. It has no form URL but uses the same fit-to-256 pattern with an Approval Center CTA.

**Q3 — Domain wording?**
→ Stays operation-local. Kit owns primitives + a generic “fit variable slots into a render function” helper; subjects/body copy remain per op.

**Q4 — Optional body suffixes?**
→ Kit MUST support optional segments that drop when over budget (e.g. sod-remediation controls note), not only name truncation.

**Q5 — Sequencing vs sibling changes?**
→ This change is layer ①; lands before `form-notification-envelope` and `form-launch-facade`. No hard code dependency on those changes.

## Open questions

None blocking. Module path name (`persistable-email` vs `compact-email`) deferred to design; prefer `persistable-email` to match the persist constraint.

## Scenarios discussed

- Body fits without truncation when names are short.
- Long names: proportional budgets; CTA link remains intact and unquoted.
- Optional suffix present when it fits; omitted when it would exceed the limit.
- Final hard slice only as last resort; prefers ending on a complete tag when possible (existing behavior preserved).
- access-request-status Approval Center link uses UI origin when available; plain text label when offline.
