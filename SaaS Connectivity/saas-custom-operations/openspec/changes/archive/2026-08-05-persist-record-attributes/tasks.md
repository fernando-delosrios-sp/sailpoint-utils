## 1. Operation signature types

- [x] 1.1 Add `OperationSignature`, `InferOperationInput`, `InferOperationOutput` in `output-schema.ts`
- [x] 1.2 Export types from `framework/index.ts`

## 2. customOperation and typed context

- [x] 2.1 Add generic `RequestContext<TOutput>` and `PersistFn<TOutput>` in `types.ts`
- [x] 2.2 Implement `customOperation<T extends OperationSignature>(handler)` — types from signature only
- [x] 2.3 Wire typed persist in `createRequestContext` / `createPersist`
- [x] 2.4 Update `with-custom-operation.spec.ts`

## 3. Persist implementation

- [x] 3.1 Add `serializeAttributeValue(value)` with auto serialization in `persist-result.ts`
- [x] 3.2 Refactor `buildAccountAttributes` for named record attributes; remove MAX_PARAMS
- [x] 3.3 Update `comparableKeys` for author-provided keys; exclude date
- [x] 3.4 Remove positional param1..param9 mapping

## 4. Unit tests

- [x] 4.1 Test: named attributes map to account keys
- [x] 4.2 Test: array/object JSON serialization
- [x] 4.3 Test: reserved keys ignored; verifyPersisted updated for named attrs
- [x] 4.4 Test: customOperation handler typing in `with-custom-operation.spec.ts`
- [x] 4.5 Run `npm test -- src/framework/` — all pass

## 5. Operation call-site migration

- [x] 5.1 Define `ExampleOperation extends OperationSignature` in `example-operation.ts`
- [x] 5.2 Update `_template.ts` with OperationSignature pattern
- [x] 5.3 Migrate remaining array persist call sites

## 6. Build verification

- [x] 6.1 Run `npm test` — full suite passes with 60% coverage threshold
- [x] 6.2 Run `npm run build` — bundle succeeds

## 7. Documentation

- [x] 7.1 Update README — OperationSignature, customOperation, typed persist
- [x] 7.2 Update README dummy source section — framework attrs + operation output fields
- [x] 7.3 Update JSDoc in framework modules

## 8. Changelog

- [x] 8.1 Add CHANGELOG entry — breaking: record persist + OperationSignature
- [x] 8.2 Confirm entry covers migration from param slots
