# Test Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in test mode that runs custom operations from JSON fixtures without ISC persistence, optionally validates ISC connectivity when a token is provided, logs inhibited writes to console, and returns natural `ctx.res.send` output.

**Architecture:** Detect test mode in `customOperation` from config/env; when token present run read-only ISC status check and list-only source resolve (no writes); when token absent skip all ISC and relax config parsing; inject no-op persist dependencies; add fixture runner script.

**Tech Stack:** TypeScript, @sailpoint/connector-sdk, Vitest, tsx, existing framework modules (`persist-result`, `request-context`, `with-custom-operation`).

**Canonical test command:** `npm test`

---

## Global Constraints

- Prettier: 120 print width, 4-space tabs, no semicolons, single quotes
- Connector exported as module property named `connector`
- Token MUST NOT appear in logs
- Default behavior unchanged when test mode off
- 60% statement coverage threshold (Vitest)

---

### Task 1: Test mode detection helper

**Files:**
- Create: `src/framework/test-mode.ts`
- Create: `src/framework/test-mode.spec.ts`
- Modify: `src/framework/index.ts` (export if needed)

**Interfaces:**
- Produces: `isTestMode(config)`, `hasAccessToken(config)`

- [ ] **Step 1: Write failing tests** for config true, env fallback, default false, and hasAccessToken edge cases (empty, whitespace, Bearer prefix)
- [ ] **Step 2: Run** `npm test -- src/framework/test-mode.spec.ts` — expect FAIL
- [ ] **Step 3: Implement** helpers
- [ ] **Step 4: Run tests** — expect PASS

---

### Task 2: Token-gated ISC status and relaxed parsing

**Files:**
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/source-provisioning.ts` (export list-only resolve + verifyIscStatus)
- Modify: `src/framework/types.ts`
- Create/extend: `src/framework/with-custom-operation.spec.ts`

**Interfaces:**
- Consumes: `isTestMode`, `hasAccessToken`
- Produces: read-only status check when token present; placeholder sourceId when offline or source missing

- [ ] **Step 1: Write failing tests** — with token: sources API called for status, createSource not called; without token: no SDK calls
- [ ] **Step 2: Relax** `parseStandardInput` for test mode + no token (requestId only)
- [ ] **Step 3: Implement** `verifyIscStatus` and `resolveSourceByNameReadOnly`
- [ ] **Step 4: Wire** branch in `customOperation`
- [ ] **Step 5: Run** `npm test -- src/framework/with-custom-operation.spec.ts`

---

### Task 3: Test-mode request context and persist logging

**Files:**
- Modify: `src/framework/request-context.ts`
- Create: `src/framework/test-mode-persist.ts` (optional — or inline in request-context)
- Modify: `src/framework/persist-result.spec.ts` or new `src/framework/test-mode-persist.spec.ts`

**Interfaces:**
- Consumes: `testMode` flag, existing `createPersist`, `buildAccountAttributes`
- Produces: no-op `createAccount`/`readAccount`/`ensureSourceSchema` that log `[test-mode] inhibited persist identity=... attributes=...`

- [ ] **Step 1: Write failing test** — call persist in test mode, assert createAccount mock not invoked and console contains identity
- [ ] **Step 2: Implement** test-mode branch in `createRequestContext`
- [ ] **Step 3: Write failing test** for verifyPersisted inhibited path
- [ ] **Step 4: Implement** verify logging and end summary counter
- [ ] **Step 5: Run** `npm test -- src/framework/test-mode-persist.spec.ts` (or equivalent)

---

### Task 4: res.send unchanged verification

**Files:**
- Extend: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1: Write test** — handler calls `ctx.res.send({ status: 'success' })` in test mode; assert send mock called with payload
- [ ] **Step 2: Run** targeted test file — expect PASS

---

### Task 5: Fixture runner script

**Files:**
- Create: `scripts/run-operation-fixture.ts`
- Create: `fixtures/custom-example.json`
- Modify: `package.json` — add `"test:operation": "tsx scripts/run-operation-fixture.ts"`
- Create: `scripts/run-operation-fixture.spec.ts` (or test via vitest importing runner functions)

**Interfaces:**
- Consumes: built connector from `dist/index.js` or direct import from `src/operations`
- Produces: stdout JSON of `res.send` payload; exit 0 on success, non-zero on missing command
- Create: `fixtures/custom-example-offline.json`

Example offline fixture:

```json
{
  "command": "custom:example",
  "config": { "testMode": true },
  "input": { "requestId": "offline-001", "message": "no isc" }
}
```

Example fixture with token (ISC status check runs; writes still inhibited):

```json
{
  "command": "custom:example",
  "config": {
    "apiUrl": "https://example.api.identitynow.com",
    "token": "<access-token>",
    "sourceName": "Test Results",
    "testMode": true
  },
  "input": { "requestId": "fixture-001", "message": "dry run" }
}
```

- [ ] **Step 1: Write failing test** for fixture parser (valid + missing command)
- [ ] **Step 2: Implement** fixture load and handler dispatch with Response mock capturing send
- [ ] **Step 3: Add** example fixture and npm script
- [ ] **Step 4: Manual smoke:** `npm run build && npm run test:operation -- fixtures/custom-example.json`
- [ ] **Step 5: Run** `npm test`

---

### Task 6: Documentation and changelog

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add** Test Mode section with config flag, env var, fixture example, npm script
- [ ] **Step 2: Run** changelog-generator or add CHANGELOG entry for test mode feature
- [ ] **Step 3: Final verification** — `npm test` full suite green

---

## Scenario coverage map

| Scenario | Test location |
|---|---|
| Test mode disabled by default | `test-mode.spec.ts` |
| Test mode via config / env | `test-mode.spec.ts` |
| Persist does not create account | `test-mode-persist.spec.ts` |
| VerifyPersisted inhibited | `test-mode-persist.spec.ts` |
| Source auto-provision inhibited | `with-custom-operation.spec.ts` |
| ISC status with token | `with-custom-operation.spec.ts` |
| ISC skipped without token | `with-custom-operation.spec.ts` |
| Source read-only resolve | `with-custom-operation.spec.ts` |
| Minimal offline fixture | `with-custom-operation.spec.ts` |
| Inhibited persist logged | `test-mode-persist.spec.ts` |
| Startup/summary logged | `test-mode-persist.spec.ts` |
| Token not logged | `test-mode-persist.spec.ts` |
| res.send normal | `with-custom-operation.spec.ts` |
| Valid fixture / missing command | `run-operation-fixture.spec.ts` |
| res.send printed | `run-operation-fixture.spec.ts` |
| npm script documented | README + package.json inspection |
