## Context

Both SOD form-launch operations persist workflow-oriented email fields after creating a remediation form instance. The prior change renamed keys to the `form-email-*` family; recipient output remains a singular string under `form-email-recipient`. ISC Send Email expects `recipientEmailList` as a list, and the framework already supports `string[]` persist attributes (`isMulti: true`) via `OperationSignature` and codegen.

## Goals / Non-Goals

**Goals:**
- Rename `form-email-recipient` → `form-email-recipients` on `sod-remediation` and `access-sod-remediation`
- Type the output as `string[]` in `OperationSignature`, generated schema sidecar, and account schema
- Persist a single-element array containing the currently resolved owner email
- Update bundled workflow JSONPath and tests

**Non-Goals:**
- Resolving multiple distinct recipient identities or emails
- Dual-writing the old key
- Changing email header/body HTML or form recipient identity logic

## Decisions

### D1: Hard rename without dual-write
- **Choice:** Remove `form-email-recipient`; persist only `form-email-recipients`
- **Reason:** Consistent with the prior form-email output rename; avoids ambiguous duplicate attributes on the result source
- **Considered alternatives:** Dual-write during transition — rejected (operational burden, unclear precedence for workflows)

### D2: Single-element array for current behavior
- **Choice:** `[ownerEmail]` where `ownerEmail` is today's resolved string
- **Reason:** Delivers correct `string[]` contract without expanding recipient-resolution scope
- **Considered alternatives:** Leave scalar until multi-recipient feature — rejected (does not satisfy the type change request)

### D3: Schema representation
- **Choice:** `OperationSignature.output` uses `'slug:form-email-recipients': string[]`; codegen emits `'string[]'`; account schema expects `{ type: 'STRING', isMulti: true }`
- **Reason:** Matches existing patterns (`governance-group-emails:emails`, `preventive-sod-check:violated-policy-names`)
- **Considered alternatives:** Persist JSON-encoded string — rejected (breaks ISC multi-value attribute semantics)

### D4: Scope includes access-sod-remediation
- **Choice:** Apply the same key rename and array type to child persist on access-sod-remediation
- **Reason:** Parallel output family; README and code already expose `form-email-recipient` on child accounts
- **Considered alternatives:** Sod-remediation only — rejected (inconsistent contract across sibling operations)

## Risks / Trade-offs

- [Risk] Downstream workflows break until JSONPath is updated → Mitigation: CHANGELOG breaking note; update bundled Violation Response workflow
- [Risk] Consumers expecting a scalar string receive an array → Mitigation: document migration; array always contains at least the prior scalar value when email resolves
- [Trade-off] No multi-recipient value yet → Accepted: array shape future-proofs without expanding resolution logic now

## Migration Plan

1. Ship connector with renamed key and array type
2. Update ISC workflows: replace `['…:form-email-recipient']` with `['…:form-email-recipients']` on Send Email `recipientEmailList.$` JSONPath
3. Re-import bundled `workflows/SOD Remediation - Violation Response.json` or apply equivalent JSONPath edit in tenant
4. Rollback: revert connector version and restore old JSONPath (workflows on new connector version will fail until reverted)

## Open Questions

None.
