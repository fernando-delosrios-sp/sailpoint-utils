# Brainstorm: Normalize Connector Errors

## Background

Operation failures in custom commands (notably `custom:sod-remediation`) cause ISC workflows to re-invoke the same request multiple times. Local `spcx` debug logs show the same `requestId` arriving again after a failure.

Observed failure: form instance creation via `sailpoint-api-client` throws a raw axios error (`Request failed with status code 500`) instead of `ConnectorError`. The handler aborts before `ctx.persist` and `ctx.res.send({ status: 'success' })`.

The connector-sdk defines `ConnectorError` with types `generic` and `notFound`. Existing framework code uses it for validation and some ISC calls (`experimental-client`, `source-provisioning`, `with-custom-operation` input parsing). Gaps remain in forms integration, SDK client propagation, and persist verification errors.

## Problem statement

Unhandled plain `Error` / axios rejections from operation handlers are not classified as intentional connector failures. Workflows and HTTP clients treat them as retriable crashes, re-running side-effecting steps (form instance create) and producing duplicate work.

## Decision chain

### Q1: Where should error normalization live?

**Options considered:**

| Approach | Pros | Cons |
|---|---|---|
| A. Framework boundary in `customOperation` | Single place; all operations benefit; minimal per-handler work | Less granular HTTP status mapping unless combined with B |
| B. Per-client wrapping (like `experimental-client`) | Rich messages; 404 → `NotFound` | Easy to miss new call sites |
| C. Both A + B | Defense in depth; boundary as safety net | Slightly more code |

**Decision:** C — framework boundary wrapper as primary guarantee; explicit wrapping at ISC API boundaries for status-aware messages where already established.

### Q2: What errors must become ConnectorError?

**Decision:** All errors that escape a custom operation handler SHALL be `ConnectorError`, except errors that are already `ConnectorError`.

Specific mappings:

- `PersistVerificationError` → `ConnectorError` (generic)
- axios / sailpoint-api-client failures → `ConnectorError` with HTTP status in message; 404 → `ConnectorErrorType.NotFound` where applicable
- Plain `Error` from forms service, seed loader, etc. → `ConnectorError` (generic)
- Offline test-mode stub errors → `ConnectorError` (generic) for consistency

### Q3: Should initialization failures (before handler) also normalize?

**Decision:** Yes. `verifyIscStatus`, source resolution, and config parsing already throw or propagate errors before/at handler entry. Wrap the entire `customOperation` body (init + handler) so SDK rejections during init also surface as `ConnectorError`.

### Q4: Does this change connector-spec.json or add commands?

**Decision:** No. Behavioral contract change only; no manifest changes.

### Q5: Retry layers — what does this fix vs not fix?

**In scope:** Signaling intentional failure to ISC/workflow so platform does not treat the command as an unhandled crash.

**Out of scope:**

- Source-level `retryableErrors` string configuration (tenant admin concern)
- Workflow step retry policy (workflow author concern)
- Framework persist read-back retry (intentional; unchanged)
- Fixing root cause of form instance HTTP 500 (separate investigation)

### Q6: Idempotency concern on retry

Even after error normalization, workflows configured to retry on failure may still retry. Normalization improves platform signaling; duplicate form instances remain a risk if workflows retry regardless. Document that form instance create is not idempotent; error normalization reduces spurious retries from unclassified errors.

## Trade-offs

- **Message fidelity:** Boundary-only wrapping preserves axios message text but loses structured status unless per-client wrapping adds it. Acceptable for v1.
- **NotFound semantics:** Reserve `ConnectorErrorType.NotFound` for explicit 404 responses (violation not found, resource missing). Generic for 4xx/5xx otherwise.
- **Test updates:** Existing tests expecting raw `Error` messages must assert `ConnectorError` instead.

## Success criteria

1. Any failure path in a custom operation rejects with `instanceof ConnectorError`
2. `npm test` passes with new/updated failure-path tests
3. Local spcx failure on sod-remediation shows `generic error:` (or `notFound error:`) in response body, not raw axios stack as unclassified crash
4. No change to successful operation behavior or persist retry semantics

## Open questions (deferred)

- Whether ISC workflow retry stops entirely with ConnectorError (assumed yes based on SDK design; validate in tenant after deploy)
- Whether to add a shared `wrapIscError(err, context)` helper in framework vs inline in each client module (design artifact)
