# Persist Record Attributes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Each operation declares a typed output interface; `ctx.persist` accepts only registered schema attributes and exposes `sourceSchemaHints()` for ISC dummy-source setup.

**Architecture:** New `output-schema.ts` with `defineOutputSchema<TOutput>()`. `withCustomOperation<TInput, TOutput>(schema, handler)` creates `RequestContext<TOutput>` with schema-bound persist. Runtime validation rejects undeclared keys. Serialization by schema type (`string` | `json`).

**Tech Stack:** TypeScript, Vitest

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Breaking change — all operations declare output schema
- 60% statement coverage threshold

---

## Task 1: defineOutputSchema module

**Files:**
- Create: `src/framework/output-schema.ts`
- Test: `src/framework/output-schema.spec.ts`
- Modify: `src/framework/index.ts`

- [ ] **Step 1:** Write failing tests:

```typescript
describe('defineOutputSchema', () => {
    it('exposes registered keys', () => {
        const schema = defineOutputSchema<{ summary: string }>({ summary: 'string' })
        expect(schema.keys).toEqual(['summary'])
    })
    it('rejects undeclared keys', () => {
        const schema = defineOutputSchema<{ summary: string }>({ summary: 'string' })
        expect(() => schema.validate({ summary: 'ok', extra: 'x' })).toThrow(/extra/)
    })
    it('sourceSchemaHints includes framework and operation attrs', () => {
        const schema = defineOutputSchema<{ summary: string }>({ summary: 'string' })
        const hints = schema.sourceSchemaHints()
        expect(hints).toEqual(expect.arrayContaining([
            expect.objectContaining({ name: 'id', role: 'identity' }),
            expect.objectContaining({ name: 'summary', type: 'string' }),
        ]))
    })
})
```

- [ ] **Step 2:** Run test — expect FAIL

```bash
npm test -- src/framework/output-schema.spec.ts
```

- [ ] **Step 3:** Implement `defineOutputSchema`, `PersistValidationError` (or separate validation error), export from index

- [ ] **Step 4:** Run test — expect PASS

---

## Task 2: Typed RequestContext and withCustomOperation

**Files:**
- Modify: `src/framework/types.ts`
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/request-context.ts`
- Test: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1:** Add generics:

```typescript
export type PersistFn<TOutput extends Record<string, unknown>> = (
    id: string,
    attributes?: Partial<TOutput>,
    status?: string,
    options?: PersistOptions
) => Promise<void>

export interface RequestContext<TOutput extends Record<string, unknown> = Record<string, unknown>> {
    persist: PersistFn<TOutput>
    // ...existing fields
}
```

- [ ] **Step 2:** Change signature:

```typescript
export function withCustomOperation<
    TInput extends Record<string, unknown>,
    TOutput extends Record<string, unknown>,
>(
    outputSchema: OperationOutputSchema<TOutput>,
    handler: (ctx: RequestContext<TOutput>, input: TInput) => Promise<void> | void,
    deps?: RequestContextDependencies
): CommandHandler
```

- [ ] **Step 3:** Wire schema into `createRequestContext` and `createPersist`

- [ ] **Step 4:** Update tests — expect PASS

```bash
npm test -- src/framework/with-custom-operation.spec.ts
```

---

## Task 3: Schema-aware persist

**Files:**
- Modify: `src/framework/persist-result.ts`
- Test: `src/framework/persist-result.spec.ts`

- [ ] **Step 1:** Update `createPersist` to accept schema; validate before build

- [ ] **Step 2:** Implement `serializeAttributeValue(value, type: 'string' | 'json')`

- [ ] **Step 3:** Refactor `buildAccountAttributes(sourceId, id, schema, attributes, status)`

- [ ] **Step 4:** Write failing test — Fernando/emails with json type:

```typescript
const schema = defineOutputSchema<{ name: string; emails: string[] }>({
    name: 'string',
    emails: 'json',
})
const persist = createPersist(deps, registry, schema)
await persist('req-001', { name: 'Fernando', emails: ['dfas', 'fasdfas'] })
expect(createAccount).toHaveBeenCalledWith(expect.objectContaining({
    name: 'Fernando',
    emails: '["dfas","fasdfas"]',
}))
```

- [ ] **Step 5:** Run tests — expect PASS

```bash
npm test -- src/framework/persist-result.spec.ts
```

---

## Task 4: Migrate example and template operations

**Files:**
- Modify: `src/operations/example-operation.ts`
- Modify: `src/operations/_template.ts`

- [ ] **Step 1:** Example operation pattern:

```typescript
interface ExampleOperationOutput {
    summary: string
    step?: string
}

const exampleOutputSchema = defineOutputSchema<ExampleOperationOutput>({
    summary: 'string',
    step: 'string',
})

export const exampleOperation = withCustomOperation<
    ExampleOperationInput,
    ExampleOperationOutput
>(exampleOutputSchema, async (ctx, input) => {
    const summary = input.message ?? 'completed'
    await ctx.persist(`${ctx.requestId}:detail`, { summary })
    await ctx.persist(ctx.requestId, { summary, step: '1' })
    ctx.res.send({ status: 'success' })
})
```

- [ ] **Step 2:** Template with output interface, schema, and `sourceSchemaHints()` comment block

- [ ] **Step 3:** Fix any type errors from signature change across repo

---

## Task 5: Documentation and verification

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1:** Document output schema workflow and sourceSchemaHints in README

- [ ] **Step 2:** Add CHANGELOG breaking-change entry

- [ ] **Step 3:** Full verification:

```bash
npm test
npm run build
```

**Commit point:** After all checks pass.
