# Brainstorm: sod-remediation-form-email-outputs

## Background

`custom:sod-remediation` persists four namespaced result-source keys for downstream ISC workflows:

- `sod-remediation:form-url`
- `sod-remediation:situation-summary` (HTML email body)
- `sod-remediation:situation-header` (plain-text email subject)
- `sod-remediation:owner-email` (recipient)

Workflow authors map these into Send Email (`body`, `subject`, `recipientEmailList`). The current names describe the situation, not the email role, so JSONPath in workflows is harder to read.

## Decision chain

**Q1: Scope?**
Hard-rename three persist keys on `custom:sod-remediation` only. `form-url` stays.

**Q2: New names?**
User-specified mapping:

| From | To |
|---|---|
| `sod-remediation:form-url` | `sod-remediation:form-url` (unchanged) |
| `sod-remediation:situation-summary` | `sod-remediation:form-email-body` |
| `sod-remediation:situation-header` | `sod-remediation:form-email-header` |
| `sod-remediation:owner-email` | `sod-remediation:form-email-recipient` |

**Q3: Dual-write old + new keys for compatibility?**
No. Hard rename. Values and types unchanged. Existing workflows must update JSONPath.

**Q4: Internal TypeScript identifiers?**
Keep `situationSummary`, `situationHeader`, `ownerEmail`, `buildSituationHeader`, `buildPersistedSituationSummary`. Rename only persisted / schema / README / spec / workflow keys.

**Q5: Form input `situationSummaryHtml`?**
Unchanged. In-form DESCRIPTION interpolation is a different contract from persist output.

**Q6: Sibling operations?**
Out of scope. `preventive-sod-check:situation-summary` and `access-sod-remediation:form-url` stay.

**Q7: Bundled workflow?**
Update `workflows/SOD Remediation - Violation Response.json` Send Email JSONPaths to the new keys.

## Approaches considered

1. **Hard rename (chosen)** — one set of keys; changelog breaking; workflow export updated.
2. Dual-write old and new — rejected; pollutes result-source schema and delays cleanup.
3. Alias/migrate at persist — rejected; extra framework complexity for a three-key rename.

## Out of scope

- Internal TS builder/variable names
- Form seed / `situationSummaryHtml`
- `custom:preventive-sod-check` and `custom:access-sod-remediation` output keys
- Email content / HTML structure changes
