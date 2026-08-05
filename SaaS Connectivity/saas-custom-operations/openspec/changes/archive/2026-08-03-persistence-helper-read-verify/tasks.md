## 1. Types and error surface

- [x] 1.1 Add `PersistOptions = { verify?: boolean }` and extend `PersistFn` to `(id, params?, status?, options?) => Promise<void>` in `src/framework/types.ts`
- [x] 1.2 Add `VerifyPersistedFn = (ids: string[]) => Promise<void>` and add `verifyPersisted` to `RequestContext`
- [x] 1.3 Add `readAccount: (id: string) => Promise<Record<string, string> | undefined>` to `PersistDependencies`
- [x] 1.4 Add `WriteRegistry` type (Map or interface) for identity → expected attributes, scoped to invocation
- [x] 1.5 Add `PersistVerificationError` class with identity and mismatch detail in message
- [x] 1.6 Export new types and error from `src/framework/index.ts`

## 2. Shared verification logic

- [x] 2.1 Add `verifyPersistedAccount(expected, actual)` comparing status, date, and set paramN values only
- [x] 2.2 Add `readWithRetry(readAccount, id, maxAttempts=5, delayMs=200)` shared by inline and batch paths
- [x] 2.3 Extract `verifyAccountWrite(deps, id, expected)` orchestrating retry read + compare + throw PersistVerificationError

## 3. Persist with opt-out and write registry

- [x] 3.1 Update `createPersist` to accept write registry; record expected attributes on every call
- [x] 3.2 When `options.verify !== false`, run `verifyAccountWrite` after create before resolving
- [x] 3.3 When `{ verify: false }`, skip inline verify but still record in registry and log persist
- [x] 3.4 Keep backward compatibility — omitting options verifies by default

## 4. Batch verifyPersisted factory

- [x] 4.1 Implement `createVerifyPersisted(deps, registry)` returning `VerifyPersistedFn`
- [x] 4.2 For each id in order: lookup registry (reject if missing), run `verifyAccountWrite`
- [x] 4.3 Wire `verifyPersisted` on `RequestContext` in `request-context.ts` sharing registry with persist

## 5. Runtime wiring

- [x] 5.1 Implement `readAccount` in `request-context.ts` using `listAccountsV1` with nativeIdentity and sourceId filters
- [x] 5.2 Create per-invocation write registry in `createRequestContext` and pass to both factories
- [x] 5.3 Update `with-custom-operation.spec.ts` mocks for `listAccountsV1` and `verifyPersisted` on context

## 6. Unit tests (persist-result.spec.ts)

- [x] 6.1 Test: default persist verifies matching attributes (Scenario: default status and timestamp)
- [x] 6.2 Test: persist with `{ verify: false }` skips readAccount call (Scenario: skips inline verification)
- [x] 6.3 Test: persist with verify false still records in registry
- [x] 6.4 Test: verifyPersisted succeeds for two deferred ids (Scenario: batch verify succeeds)
- [x] 6.5 Test: verifyPersisted rejects unknown id (Scenario: batch verify rejects unknown identity)
- [x] 6.6 Test: verifyPersisted rejects on mismatch (Scenario: batch verify rejects on attribute mismatch)
- [x] 6.7 Test: verifyPersisted rejects when account missing after retries (Scenario: batch verify rejects on missing)
- [x] 6.8 Test: inline verify retry, mismatch, sparse params, status override (existing scenarios)

## 7. Integration and build

- [x] 7.1 Run `npm test` — all framework tests green
- [x] 7.2 Run `npm run build` — bundle succeeds

## 8. Documentation

- [x] 8.1 Update JSDoc on `PersistFn`, `VerifyPersistedFn`, `createPersist`, and `createVerifyPersisted`
- [x] 8.2 Update `src/operations/_template.ts` with deferred verify example pattern
- [x] 8.3 Update README framework section for opt-out and batch verify

## 9. Changelog

- [x] 9.1 Create or update changelog entry for persist verification, opt-out, and verifyPersisted
- [x] 9.2 Confirm entry covers: default verify, `{ verify: false }`, and `ctx.verifyPersisted(ids)`
