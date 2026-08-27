## 1. Handler — scan summary on res.send

- [x] 1.1 Remove `ctx.persist(ctx.requestId, rollup)` from `src/operations/access-model-sod-remediation/index.ts`
- [x] 1.2 Build rollup object (`access-items-scanned`, `violations-found`, optional `forms-skipped` / `forms-persist-failed`) and pass to `ctx.res.send({ status: 'success', ...rollup })`
- [x] 1.3 Confirm child persist loop and identities unchanged

## 2. Tests

- [x] 2.1 Update `index.spec.ts`: assert `res.send` includes rollup fields; assert no persist on `requestId`
- [x] 2.2 Add or extend offline test coverage for zero-violation summary-only path if not already covered
- [x] 2.3 Run `npm test` for access-model-sod-remediation and framework regressions

## 3. Local invoke verification

- [x] 3.1 Run `npm run call:op payloads/access-model-sod-remediation-offline.json` and confirm printed `ctx.res.send` payload includes scan summary fields

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 All delta spec scenarios covered by named automated tests (scan summary on res.send, no parent persist, idempotent forms-skipped on res.send, offline summary + child persist)

## 5. Documentation

- [x] 5.1 Update `src/operations/access-model-sod-remediation/README.md` — remove parent account section; document invoke response summary and child-only persist
- [x] 5.2 Update root `README.md` access-model workflow integration if it references parent account on `requestId`

## 6. Changelog

- [x] 6.1 Create or update changelog entry via changelog-generator skill during apply
- [x] 6.2 Confirm entry documents breaking change: rollup counters move from parent account to invoke response; workflows must update JSONPath
