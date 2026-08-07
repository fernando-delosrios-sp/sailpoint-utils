## 1. Schema inference module

- [x] 1.1 Add `src/framework/schema-inference.ts` with ISC type mapping (string→STRING, number→INT, boolean→BOOLEAN, bigint→LONG, Date→DATE, object→STRING, arrays→element+isMulti)
- [x] 1.2 Add `src/framework/schema-inference.spec.ts` covering primitive and array inference scenarios
- [x] 1.3 Export inference helpers from `src/framework/index.ts`

## 2. Source provisioning module

- [x] 2.1 Add `src/framework/source-provisioning.ts` with resolveSourceByName, createDelimitedFileSource, ensureSourceSchema
- [x] 2.2 Implement token identity resolution for source owner (JWT decode or ISC API — spike)
- [x] 2.3 Implement schema diff: add missing attrs, warn on type conflict, patch isMulti to true
- [x] 2.4 Add `src/framework/source-provisioning.spec.ts` with mocked SourcesApi for resolve, create, reconcile scenarios
- [x] 2.5 Handle concurrent create with re-list fallback

## 3. SDK factory and types

- [x] 3.1 Add `sources: SourcesApi` to `SailPointClients` and `createSailPointClients`
- [x] 3.2 Replace `sourceId` with `sourceName` in `StandardInput`; add `OperationSchemaContract` to `RequestContext`
- [x] 3.3 Update `PersistDependencies` / account attribute types for typed values

## 4. Config field migration

- [x] 4.1 Update `connector-spec.json`: replace sourceId with sourceName
- [x] 4.2 Update `parseStandardInput` CONFIG_FIELDS and validation in `with-custom-operation.ts`
- [x] 4.3 Update `with-custom-operation.spec.ts` for sourceName parsing

## 5. Request context and customOperation wiring

- [x] 5.1 Resolve source by name in `createRequestContext` / `customOperation` before handler runs
- [x] 5.2 Attach operation output fields to context (reuse or share operation introspection from templates)
- [x] 5.3 Update `request-context` tests and mocks

## 6. Typed persist and verification

- [x] 6.1 Replace `serializeAttributeValue` with `formatAttributeValue` using inference table
- [x] 6.2 Call `ensureSourceSchema` at start of each persist invocation
- [x] 6.3 Update `verifyPersistedAccount` for type-aware comparison (coerce read-back strings if DelimitedFile requires)
- [x] 6.4 Update `persist-result.spec.ts` for typed number/boolean/object scenarios and schema reconcile hook

## 7. Templates generator parity

- [x] 7.1 Update `scripts/templates/account-schema.ts` inference to match runtime table (INT, BOOLEAN, LONG, DATE)
- [x] 7.2 Update `account-schema.spec.ts` for new type mappings

## 8. Integration tests and build

- [x] 8.1 Update `src/index.spec.ts` and framework integration tests for sourceName flow
- [x] 8.2 Run `npm test` — full suite passes with coverage thresholds
- [x] 8.3 Run `npm run build` — bundle succeeds

## 9. Documentation

- [x] 9.1 Update README — sourceName config, auto-provisioning, token scopes, schema reconciliation at persist
- [x] 9.2 Update workflow sample JSON and invoke-payload.json — sourceName instead of sourceId
- [x] 9.3 Update JSDoc in framework modules for new provisioning flow

## 10. Changelog

- [x] 10.1 Create or update changelog entry — breaking: sourceId→sourceName, typed persist, auto-provisioning
- [x] 10.2 Confirm entry covers migration steps for existing deployments
