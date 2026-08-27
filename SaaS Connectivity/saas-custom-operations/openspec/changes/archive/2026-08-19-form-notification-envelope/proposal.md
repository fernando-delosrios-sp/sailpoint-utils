## Why

Form-launching operations each hand-assemble the same workflow companion — form URL, email header, email body, and recipients — under slightly different local names and persist wiring. Centralizing that envelope as a typed value plus a prefix→persist mapper makes Notification workflows’ contract explicit in code and stops the next form operation from reinventing the four-field pattern. This sits on the persistable-email kit for body construction and does not change attribute names.

## What Changes

**Form notification envelope type**
- Add a shared type (e.g. `FormNotification`) holding `formUrl`, `emailHeader`, `emailBody`, and `emailRecipients: string[]`.
- Reason: one vocabulary for the workflow-facing companion to a standalone form instance.
- Impact: non-breaking; internal structuring only.

**Persist key mapper**
- From: each handler inlines `'…:form-url'`, `'…:form-email-header'`, `'…:form-email-body'`, `'…:form-email-recipients'`.
- To: `toPersistAttributes(prefix, envelope)` (or equivalent) emitting those four keys.
- Reason: freeze the contract in one helper; reduce typos and drift.
- Impact: non-breaking if keys/types unchanged.

**Migrate form-launch handlers**
- Wire `custom:sod-remediation`, `custom:access-model-sod-remediation`, and `custom:access-expiration-reminders` to build/persist via the envelope.
- Impact: non-breaking for workflows and account schema.

**Explicit non-goals**
- Recipient resolution policy (manager vs access-item owner vs violation owner)
- Ensure/create form facade (sibling `form-launch-facade`)
- access-request-status (no `form-email-*` keys)
- Renaming or dual-writing persist attributes
- Multi-recipient resolution beyond today’s single-email arrays

## Capabilities

### New Capabilities

- `form-notification`: Typed form notification envelope and prefix-scoped persist attribute mapping for standalone form launch outputs (`form-url`, `form-email-header`, `form-email-body`, `form-email-recipients`).

### Modified Capabilities

- `ubiquitous-language`: Promote form notification envelope / form email body terms; align with existing **form email recipients** glossary.
- `connector-operations` (and/or per-op specs): Reference envelope construction only if normative wording should name the shared type — prefer keeping op specs behavior-identical unless clarification is needed.

## Impact

- New: shared module (path in design) for envelope type + mapper + tests
- Modify: persist assembly in the three form-launch operation handlers / logging helpers
- Depends on: `persistable-email-kit` applied (or body strings treated as opaque)
- Enables: `form-launch-facade` return shape
- No change: workflow JSONPaths, attribute names/types, form seeds, ISC forms API
- Tests: mapper unit tests; existing persist assertions stay green
- Docs: CHANGELOG; optional note in operation READMEs that outputs are envelope-backed
