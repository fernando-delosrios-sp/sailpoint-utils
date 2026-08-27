## Scope

Rename persisted output key `form-email-recipient` to `form-email-recipients` and change its type from a single string to `string[]` on both `custom:sod-remediation` and `custom:access-sod-remediation`. Out of scope: adding multiple distinct recipients beyond wrapping the current single resolved email, dual-writing the old key, and changes to `form-email-header` or `form-email-body`.

## Language

**Form email recipients** (`promote`):
The list of email addresses persisted for ISC workflow Send Email `recipientEmailList` consumption after SOD form launch.
_Avoid_: `owner-email`, `form-email-recipient` (singular), `recipient` without the `form-email-` prefix

**Form email recipient** (`draft`):
The single identity whose email is resolved today from violation owner or policy owner; becomes the sole element of `form-email-recipients` until multi-recipient resolution is added.
_Avoid_: treating the singular key as the canonical persist name

## Decisions

- **Context:** Workflows map persist output into Send Email `recipientEmailList`; the bundled Violation Response workflow already uses that field name but reads a scalar `form-email-recipient` attribute.
- **Q1:** Rename only or also change type? → **Rename to plural and type `string[]`** so account schema `isMulti: true` matches workflow semantics.
- **Q2:** Which operations? → **Both `sod-remediation` and `access-sod-remediation`** — they share the same output naming family.
- **Q3:** How populate the array today? → **Single-element array** `[resolvedOwnerEmail]`; no new recipient-resolution logic in this change.
- **Q4:** Backward compatibility? → **Hard rename, no dual-write** (consistent with prior form-email output rename).

## Open questions

None — scope locked by user request.

## Scenarios discussed

- Single owner email resolves → persisted value is `['owner-a@example.com']`, not a bare string.
- Offline invoke uses canned owner email → same single-element array shape.
- Account schema inference from `OperationSignature.output` → `string[]` maps to `STRING` + `isMulti: true` (same as `governance-group-emails:emails`).
- Workflow JSONPath must switch attribute name from `form-email-recipient` to `form-email-recipients`; value is already bound to `recipientEmailList`.
- Empty or missing email: current code persists whatever `resolveIdentityEmail` returns; array wraps that value without new validation (defer stricter empty-array rules).
