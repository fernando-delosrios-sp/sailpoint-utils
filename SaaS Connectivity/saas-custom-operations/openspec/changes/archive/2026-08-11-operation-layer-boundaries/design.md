## Context

The connector scaffold separates `src/framework/` (custom operation wrapper, persist, test mode) from `src/isc/` (ISC SDK loopback helpers) and `src/operations/` (command handlers). The SOD remediation change blurred these boundaries: operation seeds, form input types, and domain assembly landed in `isc/`, and generic specs absorbed operation-specific scenarios.

This change is a structural refactor with spec realignment. Runtime contracts for existing commands stay the same; layout, module boundaries, discovery rules, and spec ownership change.

## Goals / Non-Goals

**Goals:**
- Every custom operation lives in `src/operations/<slug>/` with `index.ts` as the auto-discovered entry
- Generic Custom Forms primitives in `src/isc/forms/` parameterized by caller-supplied templates and formInput
- SOD domain modules co-located under `src/operations/sod-remediation/` including local `access-path-resolver`
- Per-operation OpenSpec files; generic target-client sub-specs aligned to SDK API groupings
- Codegen and templates-generator discovery updated for subdirectory layout

**Non-Goals:**
- Changing `custom:sod-remediation` or `custom:example` input/output contracts
- Promoting `access-path-resolver` to isc
- Splitting experimental HTTP into a separate isc tier or spec capability
- Adding new custom commands

## Decisions

### D1: Mandatory operation subdirectory with index.ts entry
- **选择:** Each operation MUST be `src/operations/<slug>/index.ts`. Root `operations/index.ts` remains the connector registry only.
- **理由:** Uniform layout; `index.ts` is a single discovery target per op; import paths `./example/index` are clean in auto-registry.
- **已考虑 alternative:** Flat files for simple ops — rejected (inconsistent boundary enforcement). `operation.ts` entry — rejected in favor of `index.ts`.

### D2: Operation subdirectory contents
- **选择:** Domain modules, seeds, and operation-specific tests live inside the operation folder. Only one `customOperation` export per `index.ts`.
- **理由:** Keeps operation pollution out of isc/framework; complex ops add files without changing discovery rules.
- **已考虑 alternative:** Shared `operations/common/` — rejected for now (premature abstraction).

### D3: Generic isc/forms extraction
- **选择:** `src/isc/forms/` provides: `formatFormsApiError`, `loadFormSeed`, `buildCreateFormDefinitionPayload`, `ensureFormDefinitionByName`, `createStandaloneFormInstance`.
- **理由:** SOD and future form-based operations reuse bootstrap without embedding seeds in isc.
- **已考虑 alternative:** Leave sod-form-service in isc — rejected (continues pollution).

### D4: Experimental HTTP stays in flat isc
- **选择:** `experimental-client.ts` (violations, controls) remains at `src/isc/experimental-client.ts`. Requirements live in root `target-client/spec.md` as generic pre-SDK transport — no operation command names.
- **理由:** User directive — do not separate experimental APIs architecturally from other isc modules.
- **已考虑 alternative:** `isc/experimental/` subfolder — rejected.

### D5: access-path-resolver stays operation-local
- **选择:** Move to `src/operations/sod-remediation/access-path-resolver.ts`; spec scenarios in `connector-operations/sod-remediation` only.
- **理由:** Single consumer; SOD-shaped types (`groupARevokePayload` pipeline); promotion gate not met.
- **已考虑 alternative:** Promote to isc with neutral types — deferred until second consumer.

### D6: Target-client spec split mirrors SDK clients
- **选择:** Sub-specs `target-client/forms` and `target-client/identity-access`; root `target-client/spec.md` keeps factory, loopback, pre-SDK HTTP.
- **理由:** Matches `SailPointClients` groupings (forms, identity access); isolates reusable contracts.
- **已考虑 alternative:** Monolithic target-client — rejected (continues mixing concerns).

### D7: Codegen discovery algorithm
- **选择:** `scanOperationModules` lists immediate child directories of `src/operations/`; for each dir (except `_template`), if `index.ts` exists, include it. Exclude root-level `.ts` handler files (legacy flat layout removed).
- **理由:** One entry file name; `_template/` is copy scaffold not registered.
- **已考虑 alternative:** Recursive scan — rejected (unnecessary depth).

### D8: Schema sidecar placement
- **选择:** Generated sidecar at `operations/<slug>/index.schema.ts`; `defineOperationSchema` import uses `../../framework` from nested index.
- **理由:** Co-located with entry module; consistent with index.ts convention.
- **已考虑 alternative:** `schema.ts` basename — rejected to keep pairing obvious with entry file.

## Risks / Trade-offs

- [Risk] Missed import path after move → Mitigation: run full `npm test` and `npm run codegen:schemas`; update `call-op.ts`, specs imports
- [Risk] Templates-generator breaks on new paths → Mitigation: extend same introspection module; add generator test with temp subdir layout
- [Risk] Archive spec MODIFIED headers mismatch → Mitigation: copy exact requirement headers from main specs when writing deltas
- [Trade-off] Example operation gains subdirectory ceremony → Accept: consistency outweighs minimal flat-file convenience

## Migration Plan

1. Add `isc/forms/*` and tests (generic APIs) before moving sod consumers
2. Create `operations/sod-remediation/` and `operations/example/` with `index.ts` entries
3. Move domain modules and seeds; delete old flat files and polluted isc modules
4. Update codegen discovery + auto-registry rendering; run codegen
5. Update spec deltas; verify `npm test` and build
6. No connector-spec command changes expected; deploy updated bundle as non-breaking internal refactor

Rollback: revert commit; no ISC tenant data migration.

## Open Questions

- None blocking — entry file confirmed as `index.ts`; all operations in subdirectories.
