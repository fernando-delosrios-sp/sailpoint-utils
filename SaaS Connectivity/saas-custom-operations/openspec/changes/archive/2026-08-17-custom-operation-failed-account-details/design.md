## Context

The custom operation framework persists workflow-readable accounts on a DelimitedFile result source. Success handlers call `ctx.persist(requestId, outputAttributes)`. Workflows then use **Get Accounts** filtered by identity (`requestId`) to read typed output attributes.

Since failed invoke responses were normalized to `{ status: 'failed', error }` (HTTP 200, no throw), failures no longer create or update result accounts. Workflow authors who standardized on Get Accounts cannot detect failure or display error text without parsing invoke JSON separately.

Stakeholders: workflow authors, connector maintainers, operators using `npm run call:op` in test mode.

## Goals / Non-Goals

**Goals:**
- Every terminal custom operation failure upserts a result account with `status: failed` and `details` containing the error message
- `details` is a mandatory STRING attribute on the result source base schema (alongside `id`, `status`, `date`)
- Handlers may set optional informative `details` on success persists
- Preserve existing invoke `{ status, error }` response shape
- Test mode inhibited persist logs failed accounts with `details`

**Non-Goals:**
- Removing `error` from invoke response
- Adding `details` to `OperationSignature.output` / codegen sidecars
- Automatic success `details` when handler omits it
- New per-operation error attribute naming conventions

## Decisions

### D1: `details` as framework core attribute

- **选择:** Add `details` to core base schema attributes (`CORE_ATTRIBUTES`), not to operation output codegen.
- **理由:** One stable workflow mapping (`attributes.details`) across all commands; avoids every operation defining its own summary/error field.
- **已考虑 alternative:** Per-operation `{slug}:error-message` output keys — rejected as redundant and inconsistent with user request for a single mandatory attribute.

### D2: Failure persist identity uses `requestId`

- **选择:** Upsert account identity = invoke `requestId` (same as typical success parent persist).
- **理由:** Matches existing workflow read pattern (`accounts[0]` for parent result).
- **已考虑 alternative:** Separate `${requestId}:failed` child identity — rejected; adds branching without benefit for top-level failures.

### D3: Centralize failure persist in `customOperation`

- **选择:** Wrapper persists failed account before `res.send({ status: 'failed', error })` for catch-block failures and for handler-initiated failed sends via tracked response.
- **理由:** Handlers cannot forget; one implementation path.
- **已考虑 alternative:** Document that handlers must call `ctx.persist(..., 'failed')` — rejected; error-prone and already inconsistent today.

### D4: Failure persist uses `verify: false`

- **选择:** Auto failure persist skips inline read-back verification (same pattern as some batch child writes).
- **理由:** Failure path must be best-effort; verification failure should not mask original error.
- **已考虑 alternative:** Full verify — rejected; could throw `PersistVerificationError` and obscure root cause.

### D5: Failure persist errors are non-fatal

- **选择:** If failure persist throws, log and still send failed invoke response.
- **理由:** Avoid HTTP 500 / workflow retries when ISC account API is degraded.
- **已考虑 alternative:** Propagate persist failure — rejected; violates current no-throw failure contract.

### D6: Success `details` via persist attributes

- **选择:** Accept optional `details` string in persist attributes / persist options; merge in `buildAccountAttributes` as a core field writers may supply.
- **理由:** Minimal API surface; handlers set context when useful (e.g., "3 forms skipped due to cap").
- **已考虑 alternative:** Separate `ctx.setDetails()` — rejected as unnecessary API expansion.

### D7: Reserved key handling

- **选择:** Add `details` to framework-managed attribute set; exclude from operation output codegen union; allow handler-supplied value on persist but strip `details` from operation schema sidecar generation if declared on output types.
- **理由:** Prevents duplicate/conflicting schema definitions while allowing persist writes.

## Risks / Trade-offs

- [Risk] Failure persist overwrites success account for same `requestId` → Mitigation: intended semantics for single-run identity; child identities unaffected.
- [Risk] Long error messages exceed 256-char STRING limit → Mitigation: reuse existing `truncateForIscStorage` with warning log (same as other STRING attributes).
- [Trade-off] Duplicate `error` (invoke) and `details` (account) → Accept for backward compatibility and uniform Get Accounts reads.

## Migration Plan

1. Deploy connector with framework changes.
2. No manual source migration required — first persist (success or failure) reconciles `details` onto existing result source schemas.
3. Workflows may add optional mapping `accounts[0].attributes.details` for display; existing invoke guards on `{ error }` continue to work.
4. Rollback: revert connector; accounts written with `details` remain but are inert if workflows don't reference them.

## Open Questions

_(none — user request is explicit)_
