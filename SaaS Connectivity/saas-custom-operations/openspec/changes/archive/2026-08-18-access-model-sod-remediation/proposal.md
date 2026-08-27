## Why

The access-model SoD scan currently persists rollup counters on a parent result-source account at `requestId` while per-form outputs live on child accounts. Workflows that only need invoke-time counts must perform an extra Get Accounts step, and aggregation surfaces a summary account that carries no per-form workflow data. Returning the scan summary on `ctx.res.send` and persisting only child accounts simplifies the result-source shape: one account per remediation form, with rollup metrics available immediately from the invoke response.

## What Changes

**Scan summary delivery**
- From: Parent persist on `requestId` with `access-model-sod-remediation:access-items-scanned`, `violations-found`, optional `forms-skipped` / `forms-persist-failed`
- To: Same fields on successful `ctx.res.send` payload alongside `status: 'success'`; no persist call on `requestId` for rollup
- Reason: User request — summary via invoke response, children only on result source
- Impact: **Breaking** — workflows reading rollup from Get Accounts on `requestId` must read the invoke response instead

**Result-source accounts**
- From: Parent account at `requestId` plus child accounts at `{requestId}:{accessItemId}:{policyId}`
- To: Child accounts only (when forms are created)
- Reason: Eliminate summary account from aggregation
- Impact: **Breaking** — `std:account:list` / Get Accounts no longer returns a rollup row for `requestId`

**Invoke response shape**
- From: `ctx.res.send({ status: 'success' })`
- To: `ctx.res.send({ status: 'success', 'access-model-sod-remediation:access-items-scanned': n, ... })` with optional skip/failure counters
- Reason: Carry scan summary on the command response
- Impact: **Non-breaking** for callers that ignore extra fields; **breaking** for callers assuming empty success payload

**Explicit non-goals**
- Changing child persist identity pattern or child output fields
- Changing violation detection, form launch, or sod-form-html behavior
- Enriching duplicate-invoke dedupe responses with replayed summary
- Dual-write of parent rollup during migration

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation`: Replace parent persist rollup with scan summary on `ctx.res.send`; persist only child accounts; update related scenarios (operation invoked, idempotent skip, offline)
- `ubiquitous-language`: Add **scan summary** term; note parent rollup removal for access model SoD remediation

## Impact

- Modify: `src/operations/access-model-sod-remediation/index.ts` — remove `ctx.persist(ctx.requestId, ...)`, expand `ctx.res.send` payload
- Modify: `src/operations/access-model-sod-remediation/index.spec.ts` — assert summary on `res.send`, assert no parent persist
- Modify: `src/operations/access-model-sod-remediation/README.md` — workflow integration (invoke response vs Get Accounts)
- Modify: root `README.md` if access-model section references parent account
- Specs: delta under `connector-operations/access-model-sod-remediation` and `ubiquitous-language`
- Tests: `npm test`; `npm run call:op payloads/access-model-sod-remediation-offline.json` verifies printed summary
- External: ISC workflows must bind rollup JSONPath to invoke response instead of parent account attributes
