# Brainstorm: ctx.persist Record Attributes

Raw capture of design exploration for replacing positional `string[]` params with a named attributes `Record` on `ctx.persist()`.

## Background

The custom-operation framework (`src/framework/persist-result.ts`) exposes `persist(id, params?, status?, options?)`. The second argument is a positional `string[]` mapped to `param1`..`param9` on the dummy ISC source. Authors must document out-of-band which param slot holds which semantic field (e.g., endpoint-migration design maps `param1=emailRoute`, `param2=emailBodyHtml`).

This indirection makes operation code and downstream ISC workflows harder to read. Authors cannot persist structured or multi-field data under meaningful attribute names without inventing slot conventions. The user's motivating example:

```typescript
// Today
await ctx.persist(ctx.requestId, ['Fernando', 'dfas,fasdfas'])

// Desired
await ctx.persist(ctx.requestId, { name: 'Fernando', emails: ['dfas', 'fasdfas'] })
```

ISC dummy-source account attributes are string-typed. Arrays and objects must be serialized before write.

## Decision Chain

### Q1: What problem are we solving?

**Decision:** Let custom operations choose **named** account attribute keys when persisting results, instead of positional param slots.

**Rationale:** Self-documenting persist calls; operations align attribute names with dummy-source schema and workflow `$getAccounts` reads without param-slot lookup tables.

### Q2: What is the new API shape?

**Decision:** Each operation declares an **output interface** and registers it via `defineOutputSchema`. `withCustomOperation` takes a second generic `TOutput`; `ctx.persist` accepts only `Partial<TOutput>` keys.

```typescript
interface ExampleOperationOutput {
  summary: string
  step?: string
}

const exampleOutputSchema = defineOutputSchema<ExampleOperationOutput>({
  summary: 'string',
  step: 'string',
})

withCustomOperation<ExampleOperationInput, ExampleOperationOutput>(
  exampleOutputSchema,
  async (ctx, input) => {
    await ctx.persist(ctx.requestId, { summary: 'done', step: '1' })
    // unknown keys → compile error; runtime validation rejects extras too
  }
)
```

**Rationale:** TypeScript catches invalid attribute names at authoring time; runtime schema rejects typos that bypass the compiler. The schema is the single source of truth for both persist validation and ISC dummy-source setup docs.

**Considered alternatives:**
- Open `Record<string, unknown>` on persist — rejected; no compile-time guard, no schema contract for ISC source prep
- Overload accepting both `string[]` and `Record` — rejected; dual semantics perpetuate param-slot confusion

### Q3: How are non-string values handled?

**Decision:** Serialize values before write:
- `string` → stored as-is
- `number`, `boolean`, `bigint` → `String(value)`
- `null` / `undefined` → omit the attribute (sparse)
- arrays and plain objects → `JSON.stringify(value)`

Read-back verification compares the **serialized string** stored on the account.

**Rationale:** ISC account attributes are strings; JSON is the established pattern for structured payloads in attribute slots (see prior design note on param9 holding serialized data).

### Q4: Which keys are reserved?

**Decision:** Framework always sets `id`, `sourceId`, `date`, and `status`. Author-supplied keys matching these names are **ignored** (framework wins). Authors MUST NOT rely on overriding them via the attributes record.

**Rationale:** Preserves existing identity/timestamp/status semantics without ambiguity.

### Q5: How does verification change?

**Decision:** `verifyPersistedAccount` compares `status` plus every author-provided attribute key (post-serialization). `date` remains excluded from comparison (async indexing lag). Remove paramN-specific `comparableKeys` logic.

**Rationale:** Verification should confirm what the author wrote, regardless of attribute name.

### Q6: Is there a param count limit?

**Decision:** Drop the hard `MAX_PARAMS = 9` cap. Attribute count is bounded only by dummy-source schema and ISC limits (document in README).

**Rationale:** Named attributes remove the artificial nine-slot constraint; source schema is the real limit.

### Q7: How do authors prepare the ISC dummy source?

**Decision:** `defineOutputSchema` exposes `sourceSchemaHints()` returning framework-managed attributes (`id`, `date`, `status`) plus each operation output attribute with type and optional/required flag. README and `_template.ts` document the workflow: define output interface → register schema → configure dummy source to match hints.

**Rationale:** Persist keys and ISC account schema stay aligned; authors don't guess which attributes to add to the destination source.

### Q8: Scope of call-site updates?

**Decision:** Update all in-repo persist call sites (`example-operation`, `_template`, endpoint-migration operations when merged), tests, README, and OpenSpec requirements in this change.

**Rationale:** Breaking API — no backward-compat shim.

## Trade-offs Accepted

| Trade-off | Acceptance |
|---|---|
| Breaking change to `PersistFn` signature | Acceptable — early scaffold, few call sites |
| JSON serialization for arrays/objects | Acceptable — workflows read string attributes; parse where needed |
| Dummy source schema must define named attrs ops use | Acceptable — authors already configure source schema; named attrs are clearer than param slots |
| Workflows referencing param1..param9 need updating | Acceptable — migrate to named attributes aligned with new persist keys |

## Validated Design Summary

```
persist(id, attributes?, status?, options?):
  merge framework attrs (id, sourceId, date, status)
  for each key in attributes (excluding reserved):
    serialize value → account attribute
  createAccount → record expected → verify (default) or defer
```

Example author usage:

```typescript
interface ExampleOperationOutput {
  name: string
  emails: string[]
}

const exampleOutputSchema = defineOutputSchema<ExampleOperationOutput>({
  name: 'string',
  emails: 'json', // serialized as JSON string on ISC account
})

withCustomOperation<Input, ExampleOperationOutput>(exampleOutputSchema, async (ctx) => {
  await ctx.persist(ctx.requestId, { name: 'Fernando', emails: ['dfas', 'fasdfas'] })
  await ctx.persist(`${ctx.requestId}:detail`, { name: 'detail' }, 'failed')
  await ctx.verifyPersisted([ctx.requestId, `${ctx.requestId}:detail`])
})

// Prepare ISC source: exampleOutputSchema.sourceSchemaHints()
```
