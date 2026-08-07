# Dynamic Result Source Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace manual dummy-source setup with runtime sourceName resolution, DelimitedFile auto-creation, per-operation schema reconciliation at persist, and typed attribute inference/storage.

**Architecture:** New `schema-inference.ts` and `source-provisioning.ts` under `src/framework/`. `customOperation` resolves source once per invocation; `createPersist` calls `ensureSourceSchema` before account create. `SourcesApi` added to SDK factory. Config migrates `sourceId` → `sourceName`.

**Tech Stack:** TypeScript, Vitest, sailpoint-api-client (SourcesApi, AccountsApi)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Breaking change — config field rename and typed persist
- 60% statement coverage threshold
- Templates generator kept; inference aligned for docs parity

---

## Task 1: Schema inference module

**Files:**
- Create: `src/framework/schema-inference.ts`
- Create: `src/framework/schema-inference.spec.ts`
- Modify: `src/framework/index.ts`

**Scenarios covered:** Typed schema inference (number→INT, string[]→STRING isMulti)

- [x] **Step 1:** Write failing tests for `inferSchemaAttribute(field)` and `inferFromTsType(typeText)`

```typescript
describe('inferSchemaAttribute', () => {
    it('maps number to INT', () => {
        expect(inferSchemaAttribute({ name: 'count', type: 'number', optional: false }))
            .toEqual({ name: 'count', type: 'INT', isMulti: false })
    })
    it('maps string[] to STRING isMulti true', () => {
        expect(inferSchemaAttribute({ name: 'tags', type: 'string[]', optional: false }))
            .toEqual({ name: 'tags', type: 'STRING', isMulti: true })
    })
})
```

- [x] **Step 2:** Run `npm test -- src/framework/schema-inference.spec.ts` — expect FAIL

- [x] **Step 3:** Implement inference per design table; export from index

- [x] **Step 4:** Run tests — expect PASS

---

## Task 2: Source provisioning module

**Files:**
- Create: `src/framework/source-provisioning.ts`
- Create: `src/framework/source-provisioning.spec.ts`

**Scenarios covered:** Source resolution by name, auto-create, isMulti patch, type conflict warn

- [x] **Step 1:** Write failing tests with mocked SourcesApi:

```typescript
it('creates DelimitedFile source when name not found', async () => { ... })
it('warns on type conflict and keeps existing attribute', async () => { ... })
it('patches isMulti to true on conflict', async () => { ... })
```

- [x] **Step 2:** Run tests — expect FAIL

- [x] **Step 3:** Implement `resolveSourceByName`, `createDelimitedFileSource`, `ensureSourceSchema`, `resolveTokenIdentity` (spike JWT decode first)

- [x] **Step 4:** Run tests — expect PASS

---

## Task 3: SDK factory and types

**Files:**
- Modify: `src/framework/sdk-factory.ts`, `types.ts`

- [x] **Step 1:** Add SourcesApi to SailPointClients
- [x] **Step 2:** Change StandardInput sourceId → sourceName; add OperationSchemaContract interface
- [x] **Step 3:** Update PersistFn account attribute value types

---

## Task 4: Config migration

**Files:**
- Modify: `connector-spec.json`, `with-custom-operation.ts`, `with-custom-operation.spec.ts`

- [x] **Step 1:** Replace sourceId with sourceName in manifest
- [x] **Step 2:** Update parseStandardInput and tests

---

## Task 5: Wire source resolve and operation schema

**Files:**
- Modify: `with-custom-operation.ts`, `request-context.ts`

- [x] **Step 1:** Extract/share operation output introspection (import from templates module or duplicate minimal parser)
- [x] **Step 2:** In customOperation: resolve source, attach operationSchema to context
- [x] **Step 3:** Test source resolution path with mocked sdk.sources

---

## Task 6: Typed persist with schema reconcile

**Files:**
- Modify: `persist-result.ts`, `persist-result.spec.ts`

- [x] **Step 1:** Write failing tests for typed persist and ensureSourceSchema call

- [x] **Step 2:** Replace serializeAttributeValue → formatAttributeValue
- [x] **Step 3:** Hook ensureSourceSchema before createAccount in createPersist
- [x] **Step 4:** Type-aware verifyPersistedAccount with coercion helper
- [x] **Step 5:** Run `npm test -- src/framework/persist-result.spec.ts` — PASS

---

## Task 7: Templates generator parity

**Files:**
- Modify: `scripts/templates/account-schema.ts`, `account-schema.spec.ts`

- [x] **Step 1:** Update createAttribute / inference to use INT, BOOLEAN, LONG, DATE
- [x] **Step 2:** Run `npm test -- scripts/templates/account-schema.spec.ts`

---

## Task 8: Full verification

- [x] **Step 1:** Update README, workflow JSON, invoke-payload.json
- [x] **Step 2:** Run `npm test` — full suite
- [x] **Step 3:** Run `npm run build`
- [x] **Step 4:** Changelog entry via changelog-generator skill

---

## Commit guidance

- Commit after Task 1, Task 2, Task 6 (core framework)
- Commit config/docs separately
