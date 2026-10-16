## 1. Shared concurrency primitives

- [x] 1.1 Add `mapWithConcurrency` and `memoizeAsync` under `src/framework/` (or a small util module) with unit tests for limit and in-flight dedupe
- [x] 1.2 Add optional phase-duration debug logging hooks used by the combined operation

## 2. Parallelize risk evaluation

- [x] 2.1 Refactor `evaluateAccessRisk` to score independent requested items and nested ids with bounded concurrency; keep stable driver ordering
- [x] 2.2 Add in-flight promise caches for entitlements and access profiles (and roles when useful)
- [x] 2.3 Extend `evaluate.spec.ts` with call-count / concurrent-dedupe assertions (no brittle wall-clock asserts)

## 3. Parallelize preventive SoD evaluation

- [x] 3.1 Resolve access items for independent grant tracking numbers concurrently
- [x] 3.2 Expand access items with bounded concurrency and optional request-scoped memoization
- [x] 3.3 In request mode with supplied items: expand baseline once; run baseline and full predict concurrently
- [x] 3.4 Attach missing SoD policy levels concurrently
- [x] 3.5 Extend pending-grants / sod-prediction / policy-level specs for call-count and semantics

## 4. Combined access-request-precheck operation

- [x] 4.1 Create `src/operations/access-request-precheck/` with OperationSignature, handler, schema codegen, README, offline payload
- [x] 4.2 Run risk and SoD evaluation concurrently with a shared entitlement expansion cache
- [x] 4.3 Persist all six namespaced attributes once under the invoke `requestId`; default `waitForPersist` false
- [x] 4.4 Return both result sets via `ctx.respond` summary for workflow branching
- [x] 4.5 Register via codegen; update offline-context coverage list
- [x] 4.6 Connected/offline operation specs covering success, failure persist, and single write

## 5. Bundled pre-check workflow

- [x] 5.1 Rewrite Access Request Pre-Check workflow to one combined invoke; branch on summary; remove serial SoD invoke and account read/retry waits
- [x] 5.2 Update evaluate / preventive / new workflow contract tests
- [x] 5.3 Update risk and preventive READMEs to point at the combined pre-check path; document that standalone persist defaults are unchanged

## 6. Verification

- [x] 6.1 `npm run codegen:schemas` / typecheck / focused Vitest / full `npm test` / `npm run build`
- [x] 6.2 Changelog entry for the acceleration and combined command
