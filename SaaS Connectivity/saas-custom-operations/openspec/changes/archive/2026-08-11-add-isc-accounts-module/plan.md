# Add ISC Accounts Module Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Extract AccountsApi thin wrappers and native-identity lookup into `src/isc/accounts/`, refactor framework persist to delegate, align OpenSpec deltas.

**Architecture:** `isc/accounts/` holds generic get/list/create/put/find; `framework/persist-result.ts` keeps upsert orchestration, TaskManagementApi polling, and verification. Account schemas stay in `isc/sources/`.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client` (AccountsApi)

**Spec references:** `openspec/changes/add-isc-accounts-module/specs/target-client/accounts/**`, `specs/target-client/spec.md`, `specs/custom-operation-framework/spec.md`

**Canonical test command:** `npm test`

---

## Task 1: Create isc/accounts module (TDD)

- [ ] **Step 1:** Write failing tests in `src/isc/accounts/account-client.spec.ts` for `getAccount`, `listAccounts`, `createAccount`, `putAccount` — mock AccountsApi, assert correct V1 method calls
- [ ] **Step 2:** Run `npm test -- account-client` — FAIL (module missing)
- [ ] **Step 3:** Implement `account-client.ts` and `types.ts` with minimal pass-through wrappers
- [ ] **Step 4:** Run `npm test -- account-client` — PASS

## Task 2: Extract findAccountOnSource (TDD)

- [ ] **Step 1:** Port lookup tests from `persist-result.spec.ts` to `find-account.spec.ts` (or extend account-client.spec) — nativeIdentity match, scan fallback, 400 skip, escapeODataString
- [ ] **Step 2:** Run `npm test -- find-account` — FAIL
- [ ] **Step 3:** Move `escapeODataString`, `findAccountOnSource`, and internal helpers from `persist-result.ts` to `find-account.ts` unchanged in behavior
- [ ] **Step 4:** Run `npm test -- find-account` — PASS

## Task 3: Barrel and public API

- [ ] **Step 1:** Create `src/isc/accounts/index.ts` exporting public functions and types
- [ ] **Step 2:** Verify no imports from framework in isc/accounts modules

## Task 4: Refactor framework persist

- [ ] **Step 1:** Update `persist-result.ts` — import `findAccountOnSource`, `createAccount`, `putAccount`, `getAccount` from `../isc/accounts`
- [ ] **Step 2:** Replace direct AccountsApi calls in upsert/resolve paths with isc wrappers
- [ ] **Step 3:** Remove moved code from persist-result.ts; adjust persist-result.spec.ts
- [ ] **Step 4:** Run `npm test -- persist-result` — PASS

## Task 5: Full verification and docs

- [ ] **Step 1:** Grep for stray `accounts.createAccountV1|putAccountV1|listAccountsV1|getAccountV1` outside isc/accounts and sdk wiring
- [ ] **Step 2:** Run `npm test` — PASS
- [ ] **Step 3:** Run `npm run build` — PASS
- [ ] **Step 4:** Update README isc layout section if present; add changelog entry

## Decision traceability

| Design | Plan task |
|--------|-----------|
| D1 Schema in sources, instances in accounts | Task 1 (accounts only) |
| D2 Thin isc vs persist policy | Tasks 1–4 split |
| D3 findAccountOnSource in isc | Task 2 |
| D4 Barrel index.ts | Task 3 |
| D5 OpenSpec deltas | Verified in Task 5 |
