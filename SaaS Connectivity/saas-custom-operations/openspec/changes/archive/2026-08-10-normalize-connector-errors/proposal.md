## Why

Custom operation failures currently propagate as plain `Error` or axios rejections from `sailpoint-api-client`. ISC workflows and the local `spcx` debug server treat these as unclassified crashes and re-invoke the same command — observed with `custom:sod-remediation` when form instance creation returns HTTP 500. Retries re-run side-effecting steps (form instance create) and produce duplicate work. The connector-sdk provides `ConnectorError` to signal intentional, non-retriable failures, and parts of this codebase already use it, but coverage is inconsistent. Normalizing all operation failures to `ConnectorError` closes the gap and aligns with existing framework spec intent.

## What Changes

**Custom operation error propagation**
- From: Handler and initialization failures may escape as plain `Error`, `PersistVerificationError`, or axios errors.
- To: Every failure path from `customOperation` rejects with `ConnectorError` (preserving existing `ConnectorError` instances).
- Reason: Platform and workflows distinguish connector-signaled failures from unhandled crashes.
- Impact: Non-breaking for success paths; failure messages may be wrapped but remain descriptive.

**ISC client error wrapping**
- From: `sod-form-service` and SDK calls throw plain errors without HTTP context mapping.
- To: Forms and related client failures throw `ConnectorError` with status in message; 404 maps to `ConnectorErrorType.NotFound` where applicable.
- Reason: Consistent failure contract matching `experimental-client` pattern.
- Impact: Non-breaking; improves error clarity.

**Framework helper**
- From: No shared utility for converting unknown errors to `ConnectorError`.
- To: Shared `toConnectorError(err, context?)` used by boundary wrapper and optionally by ISC clients.
- Reason: Avoid duplicated conversion logic.
- Impact: Internal framework change only.

## Capabilities

### New Capabilities

_(none — extending existing capabilities)_

### Modified Capabilities

- `custom-operation-framework`: Add requirement that all custom operation failures SHALL propagate as `ConnectorError`; include scenarios for handler failures, initialization failures, and persist verification failures.
- `target-client`: Add requirement that Custom Forms API failures in sod remediation SHALL surface as `ConnectorError`.

## Impact

- **Code:** `src/framework/with-custom-operation.ts`, new `src/framework/connector-error.ts` (or similar), `src/framework/persist-result.ts`, `src/isc/sod-form-service.ts`, `src/framework/request-context.ts`
- **Tests:** `with-custom-operation.spec.ts`, `persist-result.spec.ts`, new unit tests for error helper; optional sod-form-service failure tests
- **Manifest:** No `connector-spec.json` changes
- **Dependencies:** No new packages; uses existing `@sailpoint/connector-sdk` `ConnectorError` / `ConnectorErrorType`
