# Design: Base schema on result source create

## Context

Result sources are auto-provisioned in `createDelimitedFileResultSource` with `DISCOVER_SCHEMA` enabled. The connector currently posts a minimal account schema (`id`, `status`, `date`). Templates already compute the intended **base schema** as the union of all registered operation outputs. Persist-time `ensureSourceSchema` adds fields incrementally per operation.

The change applies the base schema once at source creation, replacing or aligning whatever account schema exists immediately after `createSourceV1`.

## Goals / Non-Goals

**Goals:**

- Build base account schema from all registered operation schema sidecars at source create time
- After new source create, ensure account schema matches base schema (create or patch)
- Share builder logic with templates generator for inference parity
- Preserve persist-time add-only reconciliation and warn-only conflict policy

**Non-Goals:**

- Re-baseline existing sources on connector upgrade
- Remove attributes from schemas
- Change per-persist reconciliation scope (still current operation + attribute keys)
- connector-spec.json changes

## Decisions

### D1: Base schema definition

- **Choice:** Core attrs + union of all `OperationSchemaContract.outputFields` from registry, using existing `inferSchemaAttribute` / `collectRequiredAttributes` rules; exclude `RESERVED_OUTPUT_KEYS`
- **Reason:** Identical semantics to templates `buildAccountSchema`

### D2: Registry enumeration

- **Choice:** Add `listRegisteredOperationSchemas(): OperationSchemaContract[]` on operation schema registry
- **Reason:** Source create has no single "current operation" context; need all registered ops
- **Alternative:** Scan auto-registry at runtime — rejected (registry already populated at load)

### D3: Apply base schema after create

- **Choice:** New `applyBaseAccountSchema(sourcesApi, sourceId)` called from `createDelimitedFileResultSource` after `createSource`
- **Flow:**
  1. `getAccountSchema`
  2. If missing → `createAccountSchema` with full base payload
  3. If present → compute diff vs base; patch missing attrs and correct `identityAttribute` / `displayAttribute` / `nativeObjectType` when absent or wrong; reuse existing type/isMulti conflict handling from `ensureSourceSchema`
- **Reason:** Handles ISC DISCOVER_SCHEMA pre-create without failing on duplicate schema create

### D4: Shared builder module

- **Choice:** Extract `buildBaseAccountSchema(fields: OperationField[]): SchemaPayload` to `src/framework/base-account-schema.ts` (or similar); templates import from framework path
- **Reason:** Avoid drift between `npm run templates` and runtime
- **Note:** Templates may keep thin wrapper for `OperationMeta[]` → `OperationField[]` mapping

### D5: DEFAULT_RESULT_ACCOUNT_SCHEMA

- **Choice:** Keep as fallback for `ensureSourceSchema` when schema entirely missing on persist path; source create uses base builder instead
- **Reason:** Minimal change to persist reconciliation; base builder superset includes core attrs

### D6: Test mode

- **Choice:** No change — source auto-create already inhibited in test mode; base schema apply runs only on real create path

## Risks / Trade-offs

- [Risk] Registry empty if sidecars not loaded before first create → Mitigation: base schema degrades to core attrs only (same as today); union grows as ops register
- [Risk] ISC schema create race with DISCOVER_SCHEMA → Mitigation: read-then-create-or-patch (D3)
- [Trade-off] Ops added after source exists still need first persist to extend schema → Accept: documented; re-create source optional for operators

## Migration Plan

1. Add registry list helper and base schema builder with unit tests
2. Implement `applyBaseAccountSchema`; wire into `createDelimitedFileResultSource`
3. Refactor templates to use shared builder; run `npm run templates` to confirm unchanged output
4. Update `result-source.spec.ts` and framework spec delta
5. Run `npm test` and `npm run build`

Existing tenant result sources: no automatic migration. Operators may delete and re-invoke to recreate source, or rely on persist-time reconciliation.

## Open Questions

None — resolved in brainstorm.
