## Why

ISC workflows that invoke `custom:sod-remediation` map persisted attributes into Send Email (`body`, `subject`, `recipientEmailList`). The current keys (`situation-summary`, `situation-header`, `owner-email`) describe the violation situation rather than those email roles, so workflow JSONPath is harder to read and easier to mis-wire. Renaming them to a `form-email-*` family makes the persist contract match how workflows actually consume the fields.

## What Changes

**SOD remediation persist output keys**
- From: `sod-remediation:form-url`, `sod-remediation:situation-header`, `sod-remediation:situation-summary`, `sod-remediation:owner-email`
- To: `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, `sod-remediation:form-email-recipient`
- Reason: Name persisted fields after workflow email usage (`header`/`body`/`recipient`) while keeping the form URL key.
- Impact: **Breaking** for workflows and Get Accounts steps that read the old attribute names. Values, types, and HTML/plain-text semantics are unchanged.

Also update `OperationSignature.output`, generated schema sidecar, persist + logging keys, operation README, bundled Violation Response workflow JSONPaths, and CHANGELOG.

**Explicit non-goals**
- Dual-write of old keys
- Internal TypeScript identifier rename
- Form input `situationSummaryHtml` or seed HTML
- Sibling operation output contracts

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `connector-operations`: Sod remediation namespaced persist key list in the namespacing convention scenario
- `connector-operations/sod-remediation`: Persist output field names on launch, email, and HTML-summary requirements

## Impact

- Modify: `src/operations/sod-remediation/index.ts`, `index.schema.ts` (codegen), `index.spec.ts`, `logging.ts`, `context.ts` comment, `README.md`
- Modify: `scripts/generate-operation-schemas.spec.ts` quoted-identifier fixture
- Modify: `workflows/SOD Remediation - Violation Response.json` Send Email JSONPaths
- Modify: `openspec/specs/connector-operations/spec.md` and `openspec/specs/connector-operations/sod-remediation/spec.md` (on archive)
- Modify: `CHANGELOG.md` breaking entry
- Tests: existing sod-remediation persist assertions and codegen sidecar fixture
- External: deployed ISC workflows must switch JSONPath to the new keys after connector upgrade
