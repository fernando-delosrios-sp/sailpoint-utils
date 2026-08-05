## 1. Dependencies and project structure

- [x] 1.1 Add sailpoint-api-client to package.json devDependencies or dependencies
- [x] 1.2 Create src/framework/ directory with types.ts for StandardInput, RequestContext, and OperationResultAttributes
- [x] 1.3 Create src/operations/ directory with index.ts registry and _template.ts starter

## 2. Framework core

- [x] 2.1 Implement sdk-factory.ts to build sailpoint-api-client from apiUrl and token
- [x] 2.2 Implement operation-logger.ts with requestId correlation and token redaction
- [x] 2.3 Implement persist-result.ts mapping persist(id, params?, status?) to account create API with upsert semantics, date auto-set, status default success, positional param1..param9 mapping
- [x] 2.4 Implement request-context.ts factory assembling requestId, sourceId, sdk, log, and persist
- [x] 2.5 Implement with-custom-operation.ts wrapper parsing standard input envelope and running handler with volatile context

## 3. Connector wiring

- [x] 3.1 Remove src/my-client.ts and all imports/references
- [x] 3.2 Rewrite src/index.ts to register custom commands only via operations registry (no std handlers)
- [x] 3.3 Implement example custom operation demonstrating ctx.sdk loopback, ctx.log, and ctx.persist with child identity
- [x] 3.4 Update connector-spec.json to declare custom commands only; remove std commands and legacy accountSchema

## 4. Tests

- [x] 4.1 Unit test: persist maps params positionally to param1..param9
- [x] 4.2 Unit test: persist defaults status to success and sets date
- [x] 4.3 Unit test: persist accepts explicit status override
- [x] 4.4 Unit test: persist omits unset param attributes for sparse arrays
- [x] 4.5 Unit test: operation logger includes requestId and redacts token
- [x] 4.6 Unit test: withCustomOperation initializes independent context per invocation
- [x] 4.7 Unit test: withCustomOperation parses apiUrl, token, requestId, sourceId from input
- [x] 4.8 Unit test: connector registers no std command handlers
- [x] 4.9 Unit test: example custom command is registered in connector
- [x] 4.10 Remove or replace legacy std handler tests in src/index.spec.ts

## 5. Documentation

- [x] 5.1 Update README with foundation purpose, dummy source prerequisites, standard input envelope, and author guide for adding custom operations
- [x] 5.2 Document dummy source account schema (id, date, status, param1..param9) in README
- [x] 5.3 Add JSDoc to public framework exports (RequestContext, withCustomOperation, persist signature)

## 6. Changelog

- [x] 6.1 Create or update changelog entry for custom-operation-foundation change
- [x] 6.2 Confirm entry covers removal of std commands, framework addition, and breaking scaffold changes
