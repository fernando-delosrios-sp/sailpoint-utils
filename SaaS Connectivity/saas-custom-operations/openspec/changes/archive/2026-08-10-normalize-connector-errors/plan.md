# Normalize Connector Errors Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Ensure every custom operation failure propagates as `ConnectorError` so ISC workflows do not spuriously retry unclassified crashes.

**Architecture:** Add a shared `toConnectorError` helper; wrap the entire `customOperation` body in try/catch; explicitly wrap Custom Forms API failures in `sod-form-service.ts`. No manifest changes.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk` (`ConnectorError`, `ConnectorErrorType`)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- No `connector-spec.json` changes
- Preserve persist read-back retry semantics (unchanged)
- Do not fix underlying ISC form instance 500 root cause in this change

**Spec references:** `openspec/changes/normalize-connector-errors/specs/custom-operation-framework/spec.md`, `openspec/changes/normalize-connector-errors/specs/target-client/spec.md`

---

## Task 1: `toConnectorError` helper

**Files:**
- Create: `src/framework/connector-error.ts`
- Create: `src/framework/connector-error.spec.ts`
- Modify: `src/framework/index.ts`

- [ ] **Step 1:** Write failing test — plain `Error('fail')` → `ConnectorError` generic
- [ ] **Step 2:** Write failing test — object with `response.status: 404` → `ConnectorErrorType.NotFound`
- [ ] **Step 3:** Write failing test — existing `ConnectorError` passthrough
- [ ] **Step 4:** Write failing test — `PersistVerificationError` → generic `ConnectorError`
- [ ] **Step 5:** Implement `toConnectorError` with optional context prefix
- [ ] **Step 6:** Export from framework index
- [ ] **Step 7:** Run `npm test -- connector-error` — PASS

---

## Task 2: `customOperation` boundary

**Files:**
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1:** Write failing test — handler throws plain Error → rejects with ConnectorError
- [ ] **Step 2:** Write failing test — init ISC status failure → ConnectorError (update existing Unauthorized test expectation)
- [ ] **Step 3:** Wrap lines from config resolution through handler completion:

```typescript
try {
    // existing init + await handler(...)
} catch (e) {
    throw toConnectorError(e, context.commandType)
}
```

- [ ] **Step 4:** Run `npm test -- with-custom-operation` — PASS

---

## Task 3: Forms service wrapping

**Files:**
- Modify: `src/isc/sod-form-service.ts`
- Create: `src/isc/sod-form-service.spec.ts`

- [ ] **Step 1:** Write failing test — search rejection → ConnectorError
- [ ] **Step 2:** Write failing test — create definition missing id → ConnectorError
- [ ] **Step 3:** Write failing test — create instance missing URL → ConnectorError
- [ ] **Step 4:** Wrap SDK calls in try/catch; replace `throw new Error` with `toConnectorError`
- [ ] **Step 5:** Run `npm test -- sod-form-service` — PASS

---

## Task 4: Offline stub + full suite

**Files:**
- Modify: `src/framework/request-context.ts`

- [ ] **Step 1:** Change `offlineApiError` to `throw new ConnectorError(...)`
- [ ] **Step 2:** Run `npm test` — PASS
- [ ] **Step 3:** Run `npm run build` — PASS

---

## Task 5: Documentation and changelog

- [ ] **Step 1:** Add JSDoc on `customOperation` documenting ConnectorError guarantee
- [ ] **Step 2:** Run changelog-generator for user-visible fix note
- [ ] **Step 3:** Commit point — ready for verify phase
