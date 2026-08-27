## Context

The saas-custom-operations connector wraps custom command handlers via `customOperation` in `src/framework/with-custom-operation.ts`. Handlers call ISC APIs through `sailpoint-api-client` and an experimental fetch client. Failures must signal the ISC platform via `ConnectorError` from `@sailpoint/connector-sdk` to avoid spurious workflow retries.

Current state: validation and experimental API paths throw `ConnectorError`; forms integration, SDK rejections, and `PersistVerificationError` do not. Local debug logs show axios `Request failed with status code 500` followed by a duplicate invoke with the same `requestId`.

## Goals / Non-Goals

**Goals:**

- Guarantee every failure escaping `customOperation` is a `ConnectorError`
- Map HTTP 404 responses to `ConnectorErrorType.NotFound` where detectable
- Preserve existing success behavior and persist read-back retry semantics
- Add Vitest coverage for normalized failure paths

**Non-Goals:**

- Fixing underlying ISC API 500 errors (e.g., form instance create payload issues)
- Changing source-level `retryableErrors` tenant configuration
- Changing workflow retry policies
- Adding new connector commands or manifest fields

## Decisions

### D1: Framework boundary as primary guarantee

- **Choice:** Wrap the entire `customOperation` handler body (initialization + handler invocation) in try/catch; rethrow `ConnectorError` unchanged; convert all other errors via shared helper.
- **Reason:** Single enforcement point covers current and future operations without requiring every author to remember error typing.
- **Alternatives considered:** Per-call-site only (rejected — easy to miss); boundary only without client wrapping (accepted as minimum, enhanced by D2).

### D2: Shared `toConnectorError` helper

- **Choice:** Add `src/framework/connector-error.ts` exporting `toConnectorError(err: unknown, context?: string): ConnectorError`.
- **Reason:** Centralizes axios status extraction (`response.status`), `PersistVerificationError` mapping, and message formatting.
- **Behavior:**
  - Already `ConnectorError` → return as-is
  - axios-like error with `response.status === 404` → `ConnectorErrorType.NotFound`
  - Other errors → `ConnectorErrorType.Generic` with message from `Error.message` or stringified value
  - Optional `context` prefix (e.g., `"Form instance create"`)

### D3: Explicit client wrapping for forms service

- **Choice:** Update `sod-form-service.ts` to catch SDK errors via `formatFormsApiError` (returns `ConnectorError` with ISC response body and HTTP status), even though the boundary catch would cover raw rejections.
- **Reason:** Richer messages at the source; matches `experimental-client.ts` precedent; aids debugging without relying on generic boundary text alone.

### D4: PersistVerificationError mapping

- **Choice:** Convert `PersistVerificationError` to `ConnectorError` at the boundary (not change the internal class).
- **Reason:** Persist verification is a definitive failure, not a transient lag beyond existing retry budget; should not appear as unhandled custom error type to platform.

### D5: Offline test-mode stub errors

- **Choice:** Change `offlineApiError()` in `request-context.ts` to throw `ConnectorError`.
- **Reason:** Consistency when offline stubs are invoked incorrectly during test-mode runs.

### D6: No connector-spec.json changes

- **Choice:** Behavioral-only change; no new commands or config fields.
- **Reason:** Error propagation is internal framework contract, not an external connector manifest change.

## Risks / Trade-offs

- [Risk] Workflows with explicit retry-on-failure may still retry even with `ConnectorError` → Mitigation: document; validate in tenant post-deploy; out of scope for workflow policy changes
- [Risk] Wrapped messages lose axios response body detail → Mitigation: include HTTP status in message when available; log full error at debug level if needed later
- [Trade-off] Double wrapping (client + boundary) → Accepted; boundary is idempotent for existing `ConnectorError`
- [Trade-off] Generic type for most HTTP errors vs fine-grained types → Accepted; SDK only exposes `generic` and `notFound`

## Migration Plan

N/A — connector package-only change. Deploy updated bundle via standard `npm run build` + `spcx package`. Rollback: revert to previous connector version. No database or tenant config migration.

**Verification after deploy:**

1. Trigger intentional failure (e.g., invalid violation ID) — workflow should fail once with clear error, not loop
2. Confirm spcx local failure response includes `generic error:` or `notFound error:` prefix

## Open Questions

- Confirm in tenant that ISC workflow retry stops on `ConnectorError` (assumed from SDK design; post-deploy validation)
- Whether to extend `toConnectorError` to append axios response body snippet for 4xx/5xx (defer unless needed)
