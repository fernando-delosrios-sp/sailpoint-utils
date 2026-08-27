# Verification — auto-operation-registration

**Status:** PASS  
**Date:** 2026-08-07

## Automated checks

| Check | Result | Evidence |
|---|---|---|
| `npm test` | PASS | 99/99 tests, 93%+ statement coverage |
| `npm run build` | PASS | codegen → auto-registry → ncc bundle |
| `openspec validate auto-operation-registration` | PASS | 0 errors |

## Scenario coverage

| Spec scenario | Test |
|---|---|
| Operation declares command for auto-registration | `discoverAutoOperations` + codegen auto-registry tests |
| Auto-discovered operation resolves schema from registry | `with-custom-operation.spec.ts` registry lookup |
| Manual operation requires explicit operationSchema | `with-custom-operation.spec.ts` manual op undefined schema |
| Explicit operationSchema overrides registry | `with-custom-operation.spec.ts` explicit override |
| Command extraction, single-export rule, duplicates | `operation-introspection.spec.ts` |
| Auto-registry content + manifest sync | `generate-operation-schemas.spec.ts` |
| Collision: auto + manual same command | `discoverAllOperations` + codegen collision tests |
| Example operation end-to-end | `example-operation.spec.ts` |
| Templates unified discovery | `generate-templates.spec.ts` |

## Manual smoke

- `npm run codegen:schemas` writes `auto-registry.ts`, sidecars, syncs `connector-spec.json`
- `prebuild` chain invokes codegen before ncc (confirmed via `npm run build`)

## Notes

- Verify artifact template missing from schema; this file written manually from apply-phase checks.
