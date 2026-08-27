# Operation-Scoped Account Schema Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Scope result source base account schema on auto-create to the invoking operation's output fields instead of the union of all registered operations; keep persist-time reconciliation unchanged.

**Architecture:** Resolve `operationSchema` in `runCustomOperation` before source auto-provision. Thread `outputFields` through `resolveSourceByName` → `createDelimitedFileResultSource` → `applyBaseAccountSchema`. Remove registry union from runtime provisioning. Templates generator keeps union for reference docs.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Spec: `openspec/changes/operation-scoped-account-schema/specs/custom-operation-framework/spec.md`
- Design: `openspec/changes/operation-scoped-account-schema/design.md` §D1–D4

---

## Task 1: Operation-scoped `applyBaseAccountSchema`

**Files:**
- Modify: `src/framework/result-source.ts`
- Modify: `src/framework/result-source.spec.ts` (create if missing scenarios)

- [ ] **Step 1:** Write failing test — `applyBaseAccountSchema` with outputFields `[{ name: 'summary', type: 'string' }]` creates schema with core + summary only (mock SourcesApi)
- [ ] **Step 2:** Write failing test — outputFields `[]` yields core-only schema (id, status, date, details)
- [ ] **Step 3:** Change signature:

```typescript
export async function applyBaseAccountSchema(
    sourcesApi: SourcesApi,
    sourceId: string,
    outputFields: OperationField[] = []
): Promise<void> {
    const baseSchema = buildBaseAccountSchema(outputFields)
    // ... rest unchanged
}
```

- [ ] **Step 4:** Delete `registeredOutputFields()` and `listRegisteredOperationSchemas` import
- [ ] **Step 5:** Run `npm test -- result-source` — PASS

---

## Task 2: Thread outputFields through source resolution

**Files:**
- Modify: `src/framework/result-source.ts`
- Modify: `src/framework/with-custom-operation.ts`

- [ ] **Step 1:** Write failing test — `createDelimitedFileResultSource` forwards outputFields to `applyBaseAccountSchema`
- [ ] **Step 2:** Update signatures:

```typescript
export async function createDelimitedFileResultSource(
    sourcesApi: SourcesApi,
    sourceName: string,
    ownerId: string,
    outputFields: OperationField[] = []
): Promise<string>

export async function resolveSourceByName(
    sourcesApi: SourcesApi,
    sourceName: string,
    token: string,
    outputFields: OperationField[] = []
): Promise<string>
```

- [ ] **Step 3:** Pass `outputFields` from `createDelimitedFileResultSource` to `applyBaseAccountSchema`
- [ ] **Step 4:** Run `npm test -- result-source` — PASS

---

## Task 3: Wire operationSchema in customOperation wrapper

**Files:**
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1:** Write failing test — when source auto-create runs, mock verifies schema create includes only current operation fields
- [ ] **Step 2:** In `runCustomOperation`, move `resolvedSchema` / `operationSchema` resolution **before** the `resolveSourceByName` call:

```typescript
const resolvedSchema =
    deps.operationSchema ??
    (context.commandType ? getOperationSchema(context.commandType) : undefined)
const outputFields = resolvedSchema?.outputFields ?? []

// ... later, non-test path:
sourceId = sourceId ?? (await resolveSourceByName(
    sdk.sources,
    standard.sourceName,
    standard.token,
    outputFields
))
```

- [ ] **Step 3:** Run `npm test -- with-custom-operation` — PASS

---

## Task 4: Multi-operation lazy growth scenario

**Files:**
- Modify: `src/framework/result-source.spec.ts` or `src/framework/persist-result.spec.ts`

- [ ] **Step 1:** Write failing test — `ensureSourceSchema` adds field from operation B when schema only has operation A fields (covers "Later operation adds fields via persist reconciliation")
- [ ] **Step 2:** Confirm test passes with existing `ensureSourceSchema` implementation (no code change expected)
- [ ] **Step 3:** Run `npm test -- persist-result result-source` — PASS

---

## Task 5: Documentation and changelog

**Files:**
- Modify: `README.md` (result source / schema sections)
- Modify: JSDoc in `result-source.ts` / `base-account-schema.ts` if union language remains

- [ ] **Step 1:** Update README — distinguish runtime operation-scoped create vs templates union reference
- [ ] **Step 2:** Invoke changelog-generator skill for user-visible entry
- [ ] **Step 3:** Run full `npm test` — PASS

---

## Verification

- [ ] `npm test` passes (60% statement / 50% branch thresholds)
- [ ] `npm run build` succeeds
- [ ] No runtime callers still expect union-based auto-create
