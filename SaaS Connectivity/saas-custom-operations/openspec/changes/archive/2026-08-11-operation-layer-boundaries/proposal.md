## Why

The first complex operation (`custom:sod-remediation`) placed domain logic and bundled seeds in `src/isc/` and merged operation-specific requirements into generic specs (`target-client`, `connector-operations`). That coupling makes every new operation a risk to the reusable framework and ISC integration layer. We need enforced folder conventions, generic isc/forms primitives, per-operation specs, and codegen that discovers subdirectory operations — before more operations accumulate on the polluted layout.

## What Changes

**Operation layout**
- From: flat `src/operations/*-operation.ts` files; SOD helpers scattered in `src/isc/sod-*`
- To: every operation in `src/operations/<slug>/index.ts` with domain modules co-located; SOD modules under `src/operations/sod-remediation/`
- Reason: uniform boundary between operation domain and shared integration code
- Impact: non-breaking for ISC command contracts; import paths and codegen output change

**ISC forms layer**
- From: `form-seed-loader.ts` and `sod-form-service.ts` embed SOD seed and input types in `src/isc/`
- To: generic `src/isc/forms/*` (seed loader, ensure-definition, create-instance, error formatting); operation supplies template and formInput
- Reason: reusable forms bootstrap for future operations
- Impact: internal refactor; external operation I/O unchanged

**Spec separation**
- From: SOD requirements and sod-named APIs in `target-client` and root `connector-operations`
- To: `target-client/forms` and `target-client/identity-access` sub-specs; SOD requirements in `connector-operations/sod-remediation`; registry-only root `connector-operations`
- Reason: specs must not allow operations to pollute framework/isc requirements
- Impact: spec archive realigns main specs; no connector runtime behavior change

**Codegen discovery**
- From: scans only top-level `operations/*.ts`
- To: scans `operations/<slug>/index.ts`; auto-registry imports `./<slug>/index`
- Reason: supports mandatory subdirectory layout
- Impact: `templates-generator` and schema codegen use same discovery rules

## Capabilities

### New Capabilities

- `target-client/forms`: Generic Custom Forms client — seed loading, ensure-definition-by-name, standalone instance create, ConnectorError surfacing
- `target-client/identity-access`: Generic identity access item listing for loopback operations
- `connector-operations/sod-remediation`: All SOD remediation launch operation requirements (moved from root connector-operations)

### Modified Capabilities

- `connector-operations`: Mandatory per-operation subdirectory layout; `index.ts` entry convention; registry rules only (SOD block removed)
- `target-client`: De-pollute root spec — generic pre-SDK HTTP transport; remove sod-specific forms/access-path requirements (relocated)
- `templates-generator`: Discovery and introspection aligned to subdirectory `index.ts` layout

## Impact

- **Move/refactor:** `src/operations/example-operation.ts` → `src/operations/example/index.ts`; `sod-remediation-operation.ts` → `src/operations/sod-remediation/` tree; delete `src/isc/form-seed-loader.ts`, `sod-form-service.ts`, `sod-remediation-context.ts`, `sod-remediation-logging.ts` after extraction
- **New:** `src/isc/forms/*`; seed JSON under `src/operations/sod-remediation/seed/`
- **Codegen:** `scripts/templates/operation-introspection.ts`, `scripts/generate-operation-schemas.ts`, tests; `operations/_template/` copy scaffold
- **Specs:** delta files for six capability paths; main specs updated on archive
- **Docs:** README operation authoring section; `_template` scaffold; `call-op.ts` import paths
- **Tests:** existing sod/example tests relocated; new isc/forms unit tests; discovery subdirectory tests
- **Non-goals:** No change to `custom:sod-remediation` or `custom:example` I/O contracts; no new commands
