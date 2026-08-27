# Fix Persist Upsert Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Make `ctx.persist` probe-first upsert — `createAccountV1` for new identities, `putAccountV1` for existing — so re-running debug with the same `requestId` works reliably.

**Architecture:** Extend `PersistDependencies` with lookup + composite `upsertAccount`; wire ISC APIs in `request-context.ts`; `createPersist` calls upsert unchanged verify path. No manifest changes.

**Tech Stack:** TypeScript, Vitest, `sailpoint-api-client` (`listAccountsV1`, `createAccountV1`, `putAccountV1`)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- No `connector-spec.json` changes
- Preserve read-back retry and verify semantics
- Test mode inhibited persist unchanged

**Spec references:** `openspec/changes/fix-persist-upsert/specs/custom-operation-framework/spec.md`, `openspec/changes/fix-persist-upsert/specs/target-client/spec.md`

**Design reference:** `openspec/changes/fix-persist-upsert/design.md`

---

## Task 1: Types — `upsertAccount` dependency

**Files:**
- Modify: `src/framework/types.ts`

- [ ] **Step 1:** Rename or replace `createAccount` with `upsertAccount: (attributes: Record<string, unknown>) => Promise<void>` on `PersistDependencies`
- [ ] **Step 2:** Add `findAccountByNativeIdentity?: (id: string) => Promise<{ iscAccountId: string; attributes: Record<string, unknown> } | undefined>` (optional if folded into upsert only)
- [ ] **Step 3:** Run `npm run build` — fix compile errors in dependents (expected red)

---

## Task 2: Failing upsert tests

**Files:**
- Modify: `src/framework/persist-result.spec.ts`

- [ ] **Step 1:** Update `createTestDeps` to use `upsertAccount` mock instead of `createAccount`
- [ ] **Step 2:** Write failing test — no existing account → `upsertAccount` called once with built attributes (create path delegated to wiring)
- [ ] **Step 3:** Write failing test — simulate update path via upsert mock that records call count; second persist with same id updates attributes and verifies read-back outcome `updated`
- [ ] **Step 4:** Run `npm test -- persist-result` — expect FAIL on upsert behavior

---

## Task 3: `request-context.ts` wiring

**Files:**
- Modify: `src/framework/request-context.ts`

- [ ] **Step 1:** Add helper `findAccountOnSource(accountsClient, sourceId, nativeIdentity)` returning `{ id, attributes } | undefined` from `listAccountsV1` first match
- [ ] **Step 2:** Implement `upsertAccount`:

```typescript
upsertAccount: async (attributes) => {
    const nativeId = String(attributes.id)
    const existing = await findAccountOnSource(accountsClient, sourceId, nativeId)
    if (existing?.id) {
        await accountsClient.putAccountV1({
            id: existing.id,
            accountAttributes: { attributes: attributes as AccountAttributes['attributes'] },
        })
    } else {
        await accountsClient.createAccountV1({
            accountAttributesCreate: { attributes: attributes as { sourceId: string; [key: string]: unknown } },
        })
    }
},
```

- [ ] **Step 3:** Refactor `readAccount` to use `findAccountOnSource` and return attributes
- [ ] **Step 4:** Add `putAccountV1: stub` to `createOfflineSdkStub` accounts object

---

## Task 4: `persist-result.ts` — call upsert

**Files:**
- Modify: `src/framework/persist-result.ts`

- [ ] **Step 1:** Change `await deps.createAccount(built)` → `await deps.upsertAccount(built)`
- [ ] **Step 2:** Update file header comment: probe-first create or putAccountV1 update
- [ ] **Step 3:** Run `npm test -- persist-result` — PASS

---

## Task 5: Dedicated wiring test (optional but recommended)

**Files:**
- Create or extend: `src/framework/request-context.spec.ts` (if absent, add minimal test file)

- [ ] **Step 1:** Mock `listAccountsV1` returning existing account with id → assert `putAccountV1` called, `createAccountV1` not called
- [ ] **Step 2:** Mock `listAccountsV1` returning empty → assert `createAccountV1` called
- [ ] **Step 3:** Run `npm test -- request-context` — PASS

---

## Task 6: Downstream stub fixes + full suite

**Files:**
- Modify: `src/framework/with-custom-operation.spec.ts` (if compile errors)
- Modify: operation specs only if broken by type rename

- [ ] **Step 1:** Fix any remaining `createAccount` references in test deps
- [ ] **Step 2:** Run `npm test` — full suite PASS
- [ ] **Step 3:** Run `npm run build` — PASS

---

## Task 7: Documentation and changelog

**Files:**
- Modify: `README.md` (persist section)
- Modify: `CHANGELOG.md`

- [ ] **Step 1:** Update README upsert paragraph: create for new identity, putAccountV1 for existing
- [ ] **Step 2:** Add Unreleased CHANGELOG bullet for persist upsert fix
- [ ] **Step 3:** Mark tasks.md documentation and changelog checkboxes complete

---

## Manual dogfood (deferred)

- [~] **Step 1:** Run `npm run debug` twice with same fixture `requestId` — second run succeeds _(deferred to post-deploy; covered by unit upsert tests)_
