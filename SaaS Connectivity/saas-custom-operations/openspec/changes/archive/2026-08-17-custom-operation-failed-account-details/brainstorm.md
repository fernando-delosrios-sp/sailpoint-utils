<!--
Raw capture of superpowers:brainstorming output for custom-operation-failed-account-details.
-->

## Background

Custom operations persist typed results to a DelimitedFile result source so downstream ISC workflows read them via **Get Accounts**. On success, handlers call `ctx.persist(requestId, outputAttributes)` and workflows map `accounts[0].attributes`.

On failure, the framework (since normalize-connector-errors follow-up) sends `{ status: 'failed', error: '<message>' }` on the invoke response (HTTP 200) instead of throwing. Workflows that only read the result source after invoke therefore see **no failed account** — or a stale success account from a prior run. Operators must branch on invoke response JSON instead of the uniform Get Accounts pattern used for success.

The user wants failures to **always** leave a result-source account with `status: failed` and a mandatory schema attribute **`details`** carrying the error message. Success paths may optionally populate `details` for human-readable context (warnings, skip reasons, etc.) without replacing typed operation output fields.

## Decision chain

### Q1: Where should workflows read failure information?

**Options:**
- A) Invoke response `{ error }` only (current)
- B) Result source account only
- C) Both invoke response and result source account (recommended)

**Decision:** C — Keep `{ status, error }` on invoke response for backward compatibility and workflow guards that already inspect invoke output; **add** failed account persist so Get Accounts read-back works uniformly. Put the canonical human-readable message on account attribute `details` (not duplicate operation-specific output keys).

### Q2: Is `details` a framework core attribute or per-operation output field?

**Options:**
- A) Each operation adds its own error/summary output key
- B) Single framework core attribute `details` on every result account (like `id`, `status`, `date`)

**Decision:** B — `details` is a **framework core schema attribute** (STRING, mandatory on schema). It is not codegen'd from `OperationSignature.output`. Handlers may supply it on success via persist; framework auto-populates it on failure from the normalized error message.

### Q3: Which failure paths must persist a failed account?

**Options:**
- A) Only uncaught handler throws
- B) All terminal failure paths including handler `res.send({ status: 'failed', error })`, init/config errors, persist verification failures

**Decision:** B — Any terminal failure that produces `{ status: 'failed' }` on the invoke response SHALL upsert a result account for `requestId` with `status: failed` and `details` set. Applies inside `customOperation` wrapper, not requiring each handler to remember.

### Q4: What if failure persist itself fails?

**Options:**
- A) Re-throw (risk workflow retry)
- B) Log and still send failed invoke response

**Decision:** B — Failure to write the failed account must not throw; log warning and complete invoke with failed payload (same rule as today for response-only failures).

### Q5: Test mode behavior?

**Decision:** Mirror success persist — inhibited persist logs the failed account that would have been written (including `details`). Local `call:op` summaries show failed inhibited persists.

### Q6: Success `details` usage?

**Decision:** Optional on success. Handlers pass via persist (framework accepts `details` as a writable core field). Framework does not invent success details unless the handler supplies them. No requirement to populate `details` on every success account.

## Agreed approach

1. Extend base account schema core attributes: `id`, `status`, `date`, **`details`** (STRING, required in schema definition).
2. Extend `buildAccountAttributes` / persist pipeline to accept optional `details` from handler attributes or explicit persist options.
3. In `customOperation`, before sending any `{ status: 'failed', error }` response, call `ctx.persist(requestId, { details: errorMessage }, 'failed', { verify: false })` when request context exists and test mode rules allow (or inhibited log in test mode).
4. Hook `trackedRes.send` for handler-initiated failed responses the same way.
5. Update specs, tests, README framework section, templates generator references, CHANGELOG.

## Trade-offs

- **[Trade-off]** Duplicate information on invoke `{ error }` and account `details` → Accept for backward compatibility and uniform Get Accounts routing.
- **[Risk]** Upsert overwrites prior success account for same `requestId` on failure → Mitigation: expected — failure should supersede stale success for the same workflow run id.
- **[Risk]** Existing result sources lack `details` until first persist reconciles schema → Mitigation: persist-time schema reconciliation adds `details` automatically (same as other new attributes).

## Out of scope

- Removing `error` from invoke response payload
- Per-operation error code enums
- Changing child identity patterns (`requestId:child`) for partial failures
