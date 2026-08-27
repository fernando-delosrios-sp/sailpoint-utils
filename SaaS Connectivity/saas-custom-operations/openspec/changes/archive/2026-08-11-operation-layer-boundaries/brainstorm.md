# Brainstorm: operation-layer-boundaries

## Background

The SOD remediation operation (`custom:sod-remediation`) exposed structural drift: operation-specific requirements landed in `src/isc/` and polluted generic specs (`target-client`, `connector-operations`). Examples:

- `form-seed-loader.ts` hardcodes `sod-violation-remediation.seed.json` under `isc/`
- `sod-form-service.ts`, `sod-remediation-context.ts`, `sod-remediation-logging.ts` are operation domain in the integration layer
- `target-client/spec.md` references sod-specific function names (`ensureFormDefinition` scenarios tied to remediation)
- `connector-operations/spec.md` mixes registry rules with full SOD requirement block

Goal: enforce clear boundaries between reusable framework/ISC integration and per-operation domain code, with specs that prevent future pollution.

## Decision chain

### Q1: How should operations be organized on disk?

**Agreed:** Every custom operation MUST live in its own subdirectory under `src/operations/`. No flat `*-operation.ts` files at the operations root (except generated `auto-registry.ts` and the connector `index.ts` registry).

**Entry file:** `index.ts` inside each operation subdirectory — simplifies discovery (one convention, natural module boundary) and keeps import paths clean (`./example/index`, `./sod-remediation/index`).

**Rejected:** Hybrid flat-for-simple / subdir-for-complex — inconsistent, encourages wrong placement for new ops.

**Rejected:** `operation.ts` entry — user preferred `index.ts` when it simplifies discovery.

### Q2: Where does operation domain code live?

**Agreed:** Domain modules (context assembly, operation logging, access-path-resolver, seed JSON, operation-specific form glue) stay inside the operation subdirectory. Only generic, parameterized ISC helpers promote to `src/isc/`.

**Agreed:** `access-path-resolver` stays local to `operations/sod-remediation/` — not promoted (SOD-shaped output, single consumer).

### Q3: How should `src/isc/` be organized?

**Agreed:** Single integration layer — do NOT split experimental APIs into a separate architectural tier or folder (no `isc/experimental/` ring).

**Agreed:** Extract generic forms primitives to `src/isc/forms/` in the same change:
- error formatting
- seed loader (load any bundled JSON template)
- ensure-definition-by-name (caller supplies template)
- create-standalone-form-instance (caller supplies formInput map)

**Agreed:** `experimental-client.ts` (violations, controls HTTP) and `identity-access-client.ts` remain flat under `src/isc/`.

### Q4: How should OpenSpec capabilities be split?

**Agreed:** Per-operation spec files — e.g. `connector-operations/sod-remediation/spec.md` for all SOD requirements.

**Agreed:** Split `target-client` sub-capabilities following SDK API groupings from `SailPointClients`:
- `target-client/spec.md` — factory, loopback envelope, pre-SDK HTTP transport (generic, no operation names)
- `target-client/forms/spec.md` — generic forms client
- `target-client/identity-access/spec.md` — identity access listing helpers

**Agreed:** `connector-operations/spec.md` retains only registry and auto-discovery rules; SOD block moves out.

### Q5: Spec governance — what prevents pollution?

**Agreed promotion gate** (operation → isc):
- No `custom:*` command names in target-client specs
- No operation domain vocabulary in isc public types
- Parameterized APIs with caller-supplied templates/payloads
- Neutral test fixtures in isc specs

**Agreed:** Operation specs MAY reference generic isc capabilities by name.

### Q6: Codegen / auto-discovery changes?

**Agreed:** Extend `scanOperationModules` to scan immediate subdirectories for `index.ts` only. Root `operations/index.ts` and `operations/auto-registry.ts` excluded. `_template/` directory excluded from discovery.

**Agreed:** auto-registry and schema sidecars use relative paths (`./example/index`, `./example/index.schema`).

## Trade-offs

- **All ops in subdirs** — slightly more ceremony for trivial example op, but uniform layout scales better.
- **`index.schema.ts` naming** — sidecar beside entry is slightly unconventional vs `operation.schema.ts`; acceptable for consistent `index.ts` convention.
- **Refactor scope** — move-only for behavior; risk mitigated by existing test suite + codegen tests.
- **access-path-resolver local** — duplication if second op needs same algorithm; YAGNI until second consumer.

## Open questions (resolved in propose phase)

- Entry file name: **`index.ts`** (user confirmed, replaces earlier `operation.ts` discussion).
- Experimental API spec location: **`target-client/spec.md` section**, not separate sub-capability.
