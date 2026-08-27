# Retrospective: inline-spec-test-fixtures

## What went well

- SOD remediation offline stub co-location was straightforward; tests stayed green throughout.
- Identity-access split (`fetch-identity-access-items.ts` + `offline-data.ts`) clarified runtime vs orchestration boundaries.
- Inline Vitest mock pattern already dominant in isc modules — change mostly codified existing practice.

## Misses / course corrections

- Initial planning assumed deleting all `offline-data.ts` files; implementation converged on keeping identity-access runtime offline module. Required realigning proposal, design, tasks, plan, and CHANGELOG before verify could pass.
- `fetch-from-sdk.ts` rename to `fetch-identity-access-items.ts` happened in parallel with the change — plan/tasks needed a second update pass.

## Follow-ups

- None blocking. Archive merges `custom-operation-framework` inline-fixture requirement into main specs.
