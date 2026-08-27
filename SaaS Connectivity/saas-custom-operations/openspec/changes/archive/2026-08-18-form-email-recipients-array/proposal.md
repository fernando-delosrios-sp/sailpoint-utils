## Why

ISC Send Email workflows consume `recipientEmailList` as a list of addresses, but SOD remediation operations persist a singular `form-email-recipient` string. The mismatch forces awkward JSONPath wiring and blocks future multi-recipient notification without another breaking rename. Pluralizing the key and typing it as `string[]` aligns the persist contract with workflow consumption and account schema multi-value attributes.

## What Changes

**Form email recipient output key and type**
- From: `{slug}:form-email-recipient` (`string`, account schema `isMulti: false`)
- To: `{slug}:form-email-recipients` (`string[]`, account schema `isMulti: true`)
- Reason: Match Send Email `recipientEmailList` semantics and enable multiple addresses without another key rename.
- Impact: **Breaking** for workflows and Get Accounts steps reading `form-email-recipient`. Values become single-element arrays wrapping the same resolved owner email until multi-recipient logic is added.

**Operations affected**
- `custom:sod-remediation` — parent persist on `requestId`
- `custom:access-sod-remediation` — child persist on `{requestId}:{accessItemId}:{policyId}`

**Explicit non-goals**
- Resolving more than one distinct recipient email
- Dual-write of the old singular key
- Changes to `form-email-header`, `form-email-body`, or `form-url`

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `connector-operations`: Sod remediation namespaced persist key list in the namespacing convention scenario
- `connector-operations/sod-remediation`: Launch output contract and owner email scenario for workflow delivery
- `connector-operations/access-sod-remediation`: Child form persist email notification outputs

## Impact

- Modify: `src/operations/sod-remediation/index.ts`, `index.schema.ts` (codegen), `index.spec.ts`, `logging.ts`, `README.md`
- Modify: `src/operations/access-sod-remediation/index.ts`, `index.schema.ts` (codegen), `index.spec.ts`, `README.md`
- Modify: `scripts/generate-operation-schemas.spec.ts` if sod-remediation sidecar fixture changes
- Modify: `workflows/SOD Remediation - Violation Response.json` Send Email JSONPath
- Modify: `openspec/specs/connector-operations/spec.md`, `sod-remediation/spec.md`, `access-sod-remediation/spec.md` (on archive)
- Modify: `CHANGELOG.md` breaking entry
- Tests: persist assertions, schema inference, logging keys
- External: deployed ISC workflows must update JSONPath to `form-email-recipients` after connector upgrade
