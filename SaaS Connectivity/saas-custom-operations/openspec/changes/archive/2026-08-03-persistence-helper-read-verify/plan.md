# Persistence Helper Read-Back Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add read-after-write verification to `ctx.persist()` (default on, optional opt-out) and `ctx.verifyPersisted(ids)` for batch verification of deferred writes.

**Architecture:** Shared verify module with `readWithRetry`, `verifyPersistedAccount`, and `verifyAccountWrite`. `createPersist` records every write to an invocation-scoped registry and verifies inline when `options.verify !== false`. `createVerifyPersisted` reads registry expectations and verifies a list of ids. Runtime wiring in `request-context.ts` uses `listAccountsV1` filter for reads.

**Tech Stack:** TypeScript, Vitest, sailpoint-api-client (`AccountsApi.createAccountV1`, `AccountsApi.listAccountsV1`)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Prettier: 120 print width, 4-space tabs, no semicolons, single quotes
- `PersistFn` extended with optional 4th `options` arg — 3-arg calls verify by default
- 60% statement coverage threshold must remain satisfied

---

## Task 1: Types, registry, and PersistVerificationError

**Files:**
- Modify: `src/framework/types.ts`
- Modify: `src/framework/persist-result.ts`
- Modify: `src/framework/index.ts`
- Test: `src/framework/persist-result.spec.ts`

- [ ] **Step 1:** Add types to `types.ts`:

```typescript
export interface PersistOptions {
    verify?: boolean
}

export type PersistFn = (
    id: string,
    params?: string[],
    status?: string,
    options?: PersistOptions
) => Promise<void>

export type VerifyPersistedFn = (ids: string[]) => Promise<void>

export type WriteRegistry = Map<string, Record<string, string>>

export interface RequestContext {
    // ...existing fields
    verifyPersisted: VerifyPersistedFn
}
```

- [ ] **Step 2:** Write failing test — persist with `{ verify: false }` does not call readAccount

```typescript
it('skips inline read when verify is false', async () => {
    const createAccount = vi.fn().mockResolvedValue({})
    const readAccount = vi.fn()
    const registry = new Map()
    const persist = createPersist({ sourceId: 'source-1', createAccount, readAccount }, registry)
    await persist('req-001', ['value'], undefined, { verify: false })
    expect(readAccount).not.toHaveBeenCalled()
    expect(registry.get('req-001')).toMatchObject({ param1: 'value', status: 'success' })
})
```

- [ ] **Step 3:** Run test — expect FAIL

```bash
npm test -- src/framework/persist-result.spec.ts
```

- [ ] **Step 4:** Add `PersistVerificationError` and registry parameter stub

- [ ] **Step 5:** Export new symbols from `index.ts`

---

## Task 2: Shared verification helpers

**Files:**
- Modify: `src/framework/persist-result.ts`

- [ ] **Step 1:** Implement `verifyPersistedAccount(expected, actual)` — compare status, date, set paramN

- [ ] **Step 2:** Implement `readWithRetry(readAccount, id, attempts=5, delayMs=200)` with injectable sleep for tests

- [ ] **Step 3:** Implement `verifyAccountWrite(deps, id, expected)` using retry + compare; throw `PersistVerificationError` on failure

- [ ] **Step 4:** Write failing test — default persist calls verifyAccountWrite path

- [ ] **Step 5:** Run tests — expect PASS for default verify and opt-out cases

```bash
npm test -- src/framework/persist-result.spec.ts
```

---

## Task 3: createVerifyPersisted batch helper

**Files:**
- Modify: `src/framework/persist-result.ts`
- Test: `src/framework/persist-result.spec.ts`

- [ ] **Step 1:** Write failing test — batch verify two deferred ids

```typescript
it('verifyPersisted checks all ids against registry', async () => {
    const registry = new Map<string, Record<string, string>>()
    const readAccount = vi.fn()
        .mockResolvedValueOnce({ status: 'success', date: '...', param1: 'a' })
        .mockResolvedValueOnce({ status: 'success', date: '...', param1: 'b' })
    registry.set('req-001', { status: 'success', date: '...', param1: 'a' })
    registry.set('req-001:child', { status: 'success', date: '...', param1: 'b' })
    const verifyPersisted = createVerifyPersisted({ sourceId: 'source-1', readAccount }, registry)
    await verifyPersisted(['req-001', 'req-001:child'])
    expect(readAccount).toHaveBeenCalledTimes(2)
})
```

- [ ] **Step 2:** Write failing test — unknown id rejects

- [ ] **Step 3:** Implement `createVerifyPersisted(deps, registry)`

- [ ] **Step 4:** Run tests — all batch scenarios green

---

## Task 4: Wire RequestContext

**Files:**
- Modify: `src/framework/request-context.ts`
- Test: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1:** Create `const writeRegistry = new Map()` per invocation in `createRequestContext`

- [ ] **Step 2:** Wire `readAccount` via `listAccountsV1` filter

- [ ] **Step 3:** Pass registry to `createPersist` and `createVerifyPersisted`; expose both on context

- [ ] **Step 4:** Update context factory test — context has `verifyPersisted` function

- [ ] **Step 5:** Run framework tests

```bash
npm test -- src/framework/
```

---

## Task 5: Remaining scenarios, docs, and build

**Files:**
- Test: `src/framework/persist-result.spec.ts`
- Modify: `src/operations/_template.ts`
- JSDoc updates

- [ ] **Step 1:** Add tests for retry, mismatch, sparse params, status override (inline path)

- [ ] **Step 2:** Update `_template.ts` with deferred verify example:

```typescript
await ctx.persist(ctx.requestId, ['summary'], undefined, { verify: false })
await ctx.persist(`${ctx.requestId}:detail`, ['detail'], undefined, { verify: false })
await ctx.verifyPersisted([ctx.requestId, `${ctx.requestId}:detail`])
```

- [ ] **Step 3:** Update JSDoc on public API

- [ ] **Step 4:** Run full suite and build

```bash
npm test && npm run build
```

- [ ] **Step 5:** Changelog entry

---

## Spec Traceability

| Scenario | Test Task |
|---|---|
| Default status/timestamp (inline verify) | Task 2 |
| Explicit status override | Task 5 Step 1 |
| Sparse params | Task 5 Step 1 |
| Upsert / positional mapping | Task 2 |
| Retry until available | Task 5 Step 1 |
| Reject missing (inline) | Task 2 |
| Reject mismatch (inline) | Task 5 Step 1 |
| Skip inline when verify false | Task 1 Step 2 |
| Batch verify succeeds | Task 3 Step 1 |
| Batch reject missing | Task 3 |
| Batch reject mismatch | Task 3 |
| Batch reject unknown id | Task 3 Step 2 |
