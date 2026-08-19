## Scope

Introduce a typed **form notification envelope** — `formUrl`, email header, email body, and recipients — plus helpers to map it onto `{prefix}:form-*` persist attributes without changing workflow contracts. Depends on (or assumes) the persistable-email kit for body construction primitives. Out of scope: ensure/create form API facade, recipient *policy* (who owns the form), seed loading, and in-form DESCRIPTION HTML.

## Language

**Form notification envelope** (`promote`):
The workflow-facing companion to a launched standalone form instance: form URL, plain-text email subject, compact HTML email body, and recipient email list.
_Avoid_: form definition, form input values, situation summary panel

**Form email header** (`conflicts-with-canonical` → align):
Plain-text subject line persisted as `{slug}:form-email-header`. Already implied by operation specs; promote as a first-class glossary term if missing.
_Avoid_: email subject attribute without the `form-email-` prefix in normative docs

**Form email body** (`promote`):
Compact HTML persisted as `{slug}:form-email-body`, typically including an unquoted href CTA to the standalone form URL.
_Avoid_: situationSummaryHtml (in-form), full rich HTML email

**Form email recipients** (`conflicts-with-canonical`):
Already canonical in ubiquitous-language as multi-value persist output. Envelope type MUST use `string[]` and the plural key suffix.
_Avoid_: form-email-recipient (singular)

## Decisions

**Context** — Explore session (2026-08-19): every form-launching op persists the same four-field companion for Notification workflows.

**Q1 — Typed object vs only key mapper?**
→ Both: a `FormNotification` (or equivalent) value object plus `toPersistAttributes(prefix)` that emits the four namespaced keys.

**Q2 — Freeze workflow contract?**
→ Yes. Attribute names and types stay; only construction/centralization moves. No dual-write of deprecated keys.

**Q3 — Who builds header/body?**
→ Operations (or later the launch facade) supply header/body/recipients; envelope packages them with formUrl.

**Q4 — Dependency on persistable-email-kit?**
→ Soft: envelope does not reimplement fit-to-256. Apply after kit when possible; body strings are opaque to the envelope.

**Q5 — access-request-status?**
→ Out of scope (no formUrl / form-email-* keys).

## Open questions

None blocking. Exact TypeScript type name deferred to design (`FormNotification` vs `FormEmailBundle`).

## Scenarios discussed

- Map envelope → persist record for sod-remediation, access-model-sod-remediation, and access-expiration-reminders prefixes.
- Single recipient today remains a one-element `string[]`.
- Envelope construction does not call ISC APIs.
- Missing recipient email is handled by the operation before envelope creation (skip/fail remains op-local).
