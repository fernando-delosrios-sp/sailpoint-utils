# Brainstorm: Auto Operation Registration from OperationSignature.command

Raw capture from design exploration (Aug 2026). Eliminates manual `index.ts` registration, `operationSchema` import, and manifest `commands[]` edits for auto-discovered operations.

## Background

After `operation-schema-codegen`, authors still maintain three parallel artifacts per operation:

1. **`OperationSignature` interface** — compile-time typing
2. **`index.ts` registration** — `.command('custom:…', handler)`
3. **`connector-spec.json`** — `commands[]` manifest entry
4. **`operationSchema` sidecar import** — runtime schema reconciliation

The templates generator and schema codegen already parse `OperationSignature` via AST (`operation-introspection.ts`), but discovery is anchored on `index.ts` registrations — not the operation module itself.

TypeScript erases interfaces at runtime; a `command` field on `OperationSignature` only works for auto-registration when build-time codegen materializes it.

## Decision Chain

### Q1: Build-time vs runtime registration?

**Decision:** **Build-time codegen** extends existing `codegen:schemas` prebuild step.

**Alternatives considered:**

| Option | Verdict |
|--------|---------|
| Runtime self-register via second arg `{ command }` | Rejected for auto path — author wants zero second arg |
| Convention (filename → command) | Rejected — fragile, implicit |
| Build-time AST discovery | **Chosen** — aligns with schema codegen and templates introspection |

### Q2: Optional `command` on OperationSignature?

**Decision:** **`command?: string`** on base `OperationSignature`. Auto-discovered when present as string literal on extending interface. Manual registration remains for ops without `command`.

### Q3: Manifest ownership (Layer C)?

**Decision:** **Option C2 — codegen syncs `connector-spec.json` `commands[]`** from discovered auto + manual ops. Preserves other manifest keys (`sourceConfig`, etc.).

**Alternatives considered:**

| Option | Verdict |
|--------|---------|
| C1 — manual manifest, no validation | Rejected — drift risk |
| C3 — manual manifest + build validation | Rejected — user chose full auto-sync |
| C2 — codegen rewrites commands[] | **Chosen** |

**Consequence:** Manifest-only commands (declared but not implemented) are no longer supported.

### Q4: Schema wiring for auto ops?

**Decision:** Generated `auto-registry.ts` calls `registerOperationSchema(command, schema)` at module load. `customOperation` falls back to `getOperationSchema(context.commandType)` when `operationSchema` not passed explicitly.

**Manual ops:** Keep explicit `{ operationSchema: sidecar }` import — schema registry lookup applies to auto-discovered ops only.

### Q5: Handler export discovery?

**Decision:** **Option 4A — AST** finds `export const X = customOperation<…>(`. Exactly one per auto-discovered file; fail build otherwise.

### Q6: One operation per file?

**Decision:** **Yes (v1).** Fail build if 0 or 2+ `customOperation` exports in a module with `command`.

### Q7: Collision policy?

**Decision:** **Fail build** if the same command appears in auto-discovery and manual `index.ts`.

### Q8: Exclusions?

**Decision:** Exclude `_template.ts`, `index.ts`, `*.schema.ts`, generated `auto-registry.ts` from module scan.

### Q9: Command format validation?

**Decision:** Fail build if `command` literal does not start with `custom:`.

### Q10: Relationship to existing schema sidecars?

**Decision:** Keep per-operation `*.schema.ts` sidecars (committed). Codegen emits sidecars for **all** ops (auto + manual). Auto-registry imports sidecars for schema registration.

### Q11: Templates generator discovery?

**Decision:** `loadOperationMeta` switches to unified `discoverAllOperations` (auto + manual) so templates stay aligned with codegen and manifest.

## Risks

| Risk | Mitigation |
|------|------------|
| Codegen mutates connector-spec.json unexpectedly | Only replace `commands[]`; stable sort; PR diff review |
| Stale auto-registry if author skips build | prebuild always regens; commit generated files |
| Manual + auto duplicate command | Fail build with clear error |
| Parser misses non-literal command | Fail build; document inline literal requirement (same as output fields) |

## Acceptance (brainstorm gate)

- [x] Scope: optional `command` on OperationSignature, build-time auto-registry, manifest sync, schema registry fallback for auto ops
- [x] Hybrid: manual registration + explicit operationSchema for ops without `command`
- [x] Fail build on duplicates, multi-export, invalid command prefix
- [x] One op per file; AST handler discovery; exclude template file
