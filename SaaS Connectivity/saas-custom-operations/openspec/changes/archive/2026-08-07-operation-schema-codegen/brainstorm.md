# Brainstorm: Operation Schema Codegen (Option B)

Raw capture for eliminating manual `defineOperationSchema(...)` duplication by generating per-operation schema sidecar files at build time.

## Background

After `dynamic-result-source`, operations require two parallel contracts:

1. **`OperationSignature` interface** — compile-time typing for handler input and `ctx.persist`
2. **`defineOperationSchema({...})`** — runtime `outputFields` for schema reconciliation and typed formatting

TypeScript erases interfaces at runtime. The templates generator already parses `OperationSignature.output` via the TypeScript compiler API (`scripts/templates/operation-introspection.ts`) for docs — but that data never reaches the connector bundle.

Authors must keep interface and schema helper in sync manually.

## Decision Chain

### Q1: Which codegen shape?

**Decision:** **Option B — per-operation sidecar files** co-located with handlers.

Example: `example-operation.ts` + generated `example-operation.schema.ts` exporting `exampleOperationSchema`.

**Alternatives considered:**

| Option | Verdict |
|--------|---------|
| A — single registry file | Rejected; central map drifts from handler modules, harder to navigate |
| B — per-operation sidecar | **Chosen** — colocated, one import per operation, clear ownership |
| C — bundler plugin only | Rejected for v1; harder to debug than explicit script + sidecar |

### Q2: When does codegen run?

**Decision:** **`prebuild`** (before `ncc`), same phase as `npm run clean`. Also runnable standalone via `npm run codegen:schemas`.

**Rationale:** Sidecars must exist before TypeScript compile/bundle. Fails build if `OperationSignature` missing or unparseable.

### Q3: Reuse existing introspection?

**Decision:** **Yes.** Extend `operation-introspection.ts` (or extract shared module) — same AST rules as `npm run templates`.

**Rationale:** One parser for docs and runtime; no second source of truth for field extraction.

### Q4: Generated file policy?

**Decision:** **Commit generated sidecars** to git.

**Rationale:** Reviewers see schema diffs in PRs; CI doesn't require codegen secret step; matches pattern of checking in generated artifacts when small and stable.

**Alternative:** gitignore sidecars — rejected for v1 (deploy must always prebuild).

### Q5: Sidecar format?

**Decision:** Emit TypeScript importing `defineOperationSchema` from framework:

```typescript
/** AUTO-GENERATED from ExampleOperation — do not edit */
export const exampleOperationSchema = defineOperationSchema({ ... })
```

Operation imports sidecar and passes to `customOperation(..., { operationSchema: exampleOperationSchema })`.

**Non-goal:** Auto-wire schema inside `customOperation` without explicit import (deferred — explicit import keeps dependency visible).

### Q6: Parser limitations (v1)?

**Decision:** Support **inline** `output: { field: type }` literals in interfaces extending `OperationSignature`. Fail build with clear error for:

- Missing `OperationSignature` interface
- Imported type aliases for `output` (e.g. `output: SharedOutput`)
- Unregistered operations (no sidecar needed)

**Rationale:** Matches current templates generator capability; extend later if needed.

### Q7: Relationship to `defineOperationSchema` helper?

**Decision:** **Keep helper** — codegen emits calls to it, not raw `OperationSchemaContract` objects.

**Rationale:** Single emission format; manual override path remains for edge cases during migration.

### Q8: Relationship to `npm run templates`?

**Decision:** **Keep templates separate.** Both share introspection; templates remain docs-only in `./templates/`.

**Non-goal:** Merge templates and codegen into one script in v1 (acceptable follow-up).

## Risks

| Risk | Mitigation |
|------|------------|
| Stale sidecar if author edits interface without rebuild | prebuild regen; optional lint rule comparing mtime |
| Parser misses complex TS types | Fail build with actionable error |
| Duplicate introspection logic | Extract shared `loadOperationMeta` / field extraction |

## Acceptance (brainstorm gate)

- [x] Scope: Option B sidecars, prebuild, committed files
- [x] Single parser shared with templates
- [x] Manual `defineOperationSchema` removed from operation modules
- [x] Build fails on unparseable OperationSignature
