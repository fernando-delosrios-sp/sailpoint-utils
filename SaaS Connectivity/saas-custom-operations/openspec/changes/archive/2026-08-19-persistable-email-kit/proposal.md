## Why

Four operations independently reimplement escape, truncation, and fit-to-256 HTML for workflow email bodies. The duplication drifts (optional suffixes, link labels, truncation order) and makes STRING-limit bugs easy to fix in one place and miss in another. Extracting a shared persistable-email kit now gives a stable base for the form-notification and form-launch refactors without changing workflow contracts.

## What Changes

**Shared persistable email kit**
- Add `src/lib/persistable-email/` (name finalized in design) with HTML escape, ellipsis truncation of escaped text, unquoted href CTA helper, and a fit-to-budget helper that shortens variable name slots and can drop optional segments.
- Reason: one implementation of DelimitedFile/STRING-safe compact HTML.
- Impact: non-breaking; behavior preserved for existing email bodies.

**Migrate callers**
- From: local `escapeHtml` / `truncateEscaped` / inline fit logic in `access-expiration-reminders/form-email.ts`, `access-model-sod-remediation/form-email.ts`, `sod-remediation/context.ts` (email body path), and `access-request-status/email-templates.ts`.
- To: import kit primitives; keep domain copy local.
- Reason: remove parallel implementations.
- Impact: non-breaking if golden-string tests keep current outputs.

**escapeHtml ownership**
- From: `escapeHtml` primarily exported from `sod-form-html` and duplicated in form-email modules.
- To: single escape implementation shared or re-exported so form DESCRIPTION and persistable email do not diverge.
- Impact: non-breaking import path cleanup.

**Explicit non-goals**
- Form notification envelope types / persist key mappers (sibling change)
- Form ensure/create facade (sibling change)
- Workflow JSON or persist attribute renames
- Changing `ISC_STRING_ATTRIBUTE_MAX_LENGTH`

## Capabilities

### New Capabilities

- `persistable-email`: Shared builders for compact HTML email snippets that fit ISC STRING persist limits, including escape, truncation, name-budget fitting, optional segment dropping, and unquoted CTA links.

### Modified Capabilities

- `ubiquitous-language`: Promote persistable email body / unquoted href CTA terms from discovery.
- `sod-form-html`: Clarify boundary — form DESCRIPTION HTML stays here; compact workflow email bodies use `persistable-email` (requirement note only if escape ownership moves).

## Impact

- New: `src/lib/persistable-email/` + unit tests
- Modify: form-email modules, sod-remediation email-body helpers in `context.ts`, access-request-status `email-templates.ts`, possibly `sod-form-html` re-exports
- No change: connector-spec.json, workflow JSONPaths, persist key names/types, form seeds
- Sequencing: land before `form-notification-envelope` and `form-launch-facade`
- Tests: kit unit tests; existing email body specs remain green
- Docs: short lib README; CHANGELOG entry
