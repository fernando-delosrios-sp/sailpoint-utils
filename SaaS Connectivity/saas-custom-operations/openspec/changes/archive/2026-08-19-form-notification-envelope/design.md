## Context

Form-launch ops persist the same four workflow fields under different prefixes. After the persistable-email kit owns body construction, this change introduces a typed envelope and a prefix→persist mapper so handlers stop hand-assembling key names.

## Goals / Non-Goals

**Goals:**
- Typed `FormNotification` (or equivalent) with formUrl, emailHeader, emailBody, emailRecipients
- `toPersistAttributes(prefix, envelope)` emitting the four canonical keys
- Migrate three form-launch handlers to use the mapper

**Non-Goals:**
- Changing key names or types
- Recipient resolution policy
- Form ensure/create facade
- access-request-status

## Decisions

### D1: Module path
- **Choice**: `src/lib/form-notification/`
- **Reason**: Parallel to persistable-email; not an ISC API concern
- **Considered alternatives**: `src/framework/` (rejected — not request lifecycle); fold into form-launch early (rejected — separate change)

### D2: Type fields
- **Choice**: `{ formUrl: string; emailHeader: string; emailBody: string; emailRecipients: string[] }`
- **Reason**: Matches persist suffixes and ubiquitous language
- **Considered alternatives**: Nest under `email: { header, body, recipients }` (rejected — flatter maps cleaner to persist keys)

### D3: Prefix convention
- **Choice**: Prefix is the operation slug without trailing colon (e.g. `sod-remediation`); mapper appends `:form-url` etc.
- **Reason**: Matches existing namespaced keys

### D4: Body opacity
- **Choice**: Envelope treats emailBody as opaque string; does not call persistable-email
- **Reason**: Soft dependency; builders stay at call sites until form-launch facade

### D5: C4
- **Choice**: Omit — library + handler wiring only

## Risks / Trade-offs

- [Risk] Typo in prefix breaks workflows → Mitigation: unit tests for all three prefixes; existing handler tests assert keys
- [Trade-off] Envelope does not validate email format → Reason: ops already resolve/skip; keep mapper dumb

## Migration Plan

1. Add module + tests
2. Wire three handlers / logging helpers
3. `npm test` + typecheck
4. Rollback: revert; no tenant migration

## Open Questions

None.
