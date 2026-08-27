# Brainstorm: Dynamic Result Source Provisioning

Raw capture of design exploration for replacing manual dummy-source setup (source ID + static account schema) with runtime source resolution by name, auto-creation, and per-operation schema reconciliation at `ctx.persist`.

## Background

The custom-operation framework persists workflow results to a DelimitedFile ISC source via `ctx.persist()`. Today:

- Connector config requires a pre-provisioned **source ID** (`connector-spec.json` → `sourceId`)
- Operators run `npm run templates` to generate `account-schema.json` and manually create/update the dummy source schema
- `serializeAttributeValue` stringifies all primitives; ISC schema template generator maps everything to `STRING`

Authors must coordinate three artifacts: connector config, dummy source, and operation `OperationSignature.output` fields. Adding a new operation output field requires manual schema updates on the tenant.

## Decision Chain

### Q1: What problem are we solving?

**Decision:** Replace source ID configuration with **source name**; the connector resolves (or creates) the DelimitedFile result source and ensures its account schema accommodates the **current operation's** output fields before each persist.

**Rationale:** Eliminates manual dummy-source lifecycle; operations become self-contained. Schema evolves incrementally as operations run.

### Q2: Config input change

**Decision:** Replace `sourceId` with `sourceName` in connector config and standard input envelope.

**Rationale:** Names are human-meaningful in workflows; ID lookup is an implementation detail handled at runtime.

### Q3: Source auto-creation

**Decision:** On invocation, `listSourcesV1` filtered by name. If absent, `createSourceV1` with `provisionAsCsv: true` (DelimitedFile) using defaults from existing export (`source/SaaS Custom Operations.json`). Owner = **token holder's identity** (resolved from access token, spike required).

**Rationale:** Zero-touch onboarding for new tenants; matches existing DelimitedFile pattern used for result storage.

### Q4: When and how to reconcile schema?

**Decision:** Schema reconciliation runs **inside `ctx.persist`**, scoped to the **current operation** (not a union of all registered operations at invoke start).

Required attributes = framework core (`id`, `status`, `date`) + current operation's `OperationSignature.output` fields + keys present in the `attributes` argument.

**Rationale:** User confirmed schema must be checked every execution; per-operation scope avoids upfront union maintenance. Source accumulates attributes over time as different operations persist.

### Q5: Schema conflict policy

**Decision:**

| Conflict | Action |
|----------|--------|
| Missing attribute | Add via `updateSourceSchemaV1` JSON Patch |
| `type` mismatch | **Warn, keep existing** |
| `isMulti` mismatch (existing false, desired true) | **Warn, patch to `isMulti: true`** |

**Rationale:** Conservative on types; permissive on multi-value so array writes don't fail on single-valued schema slots.

### Q6: Type inference and persistence

**Decision:** Update inference and storage to typed ISC attributes:

| TS type | ISC type | isMulti | Stored value |
|---------|----------|---------|--------------|
| string | STRING | false | as-is |
| number | INT | false | as-is |
| boolean | BOOLEAN | false | as-is |
| bigint | LONG | false | as-is |
| Date | DATE | false | ISO string as-is |
| object / unknown | STRING | false | JSON.stringify |
| T[] | element mapping | true | per element rules |

**Rationale:** Align account schema types with native JS output shapes; verification must become type-aware.

**Risk:** DelimitedFile sources may normalize values to strings on read-back — requires tenant spike.

### Q7: Optional schema hints?

**Decision:** **Deferred.** Pure inference from `OperationSignature.output` is sufficient for v1. No separate `outputSchemaHints` export or JSDoc overrides.

### Q8: Templates generator

**Decision:** **Keep unchanged.** `npm run templates` continues producing `account-schema.json` as operator documentation/preview; runtime self-heals regardless.

### Q9: SDK additions

**Decision:** Add `SourcesApi` to `createSailPointClients`; add source-provisioning module under `src/framework/` (resolve, create, reconcile schema).

## Trade-offs Accepted

| Trade-off | Acceptance |
|-----------|------------|
| Breaking config change (`sourceId` → `sourceName`) | Acceptable — early scaffold |
| Extra API calls per persist (schema check) | Acceptable — correctness over latency |
| Token needs source/schema admin scopes | Document as prerequisite |
| Typed persist breaks current all-string serialization | Required for inference table |
| Concurrent creates of same source name | Mitigate with create-or-get + re-list on conflict |

## Validated Design Summary

```
customOperation wrapper:
  resolve sourceName → sourceId (create DelimitedFile if missing)
  attach OperationSchemaContract (this operation's output fields)

ctx.persist(id, attributes):
  build required ISC attributes from operation contract + attributes keys
  ensureSourceSchema(sourceId, required) — add missing, patch isMulti
  formatAttributeValue per inference table
  createAccountV1 → verify (type-aware)
```
