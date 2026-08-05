# Custom Operation Foundation Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Goal:** Transform saas-custom-operations from a mock aggregation scaffold into a custom-operation foundation with auto-init RequestContext, SDK loopback, and persist helper.

**Architecture:** A `src/framework/` module provides `withCustomOperation()` wrapping all custom handlers. Each invocation creates a volatile RequestContext with pre-configured sailpoint-api-client, correlated logger, and `persist(id, params?, status?)` that calls account create on the dummy source. `src/operations/` holds author-defined commands; `src/index.ts` wires the registry only.

**Tech Stack:** TypeScript, @sailpoint/connector-sdk, sailpoint-api-client, Jest, ncc, spcx

**Canonical test command:** `npm test` (vitest)

---

## Task 1: Dependencies and types

- [ ] **Step 1:** Run `npm install sailpoint-api-client` and verify package.json updated
- [ ] **Step 2:** Create `src/framework/types.ts` with `StandardInput`, `RequestContext`, `PersistFn` interfaces
- [ ] **Step 3:** Create empty `src/operations/index.ts` and `src/operations/_template.ts` stubs
- [ ] **Step 4:** Run `npm test` — expect pass (no regressions yet)

## Task 2: SDK factory and logger

- [ ] **Step 1:** Write failing test: logger output includes requestId, excludes token
- [ ] **Step 2:** Implement `src/framework/operation-logger.ts`
- [ ] **Step 3:** Write failing test: sdk factory returns configured client from apiUrl + token
- [ ] **Step 4:** Implement `src/framework/sdk-factory.ts` using sailpoint-api-client createConfiguration
- [ ] **Step 5:** Run `npm test` — logger and factory tests green

## Task 3: Persist helper

- [ ] **Step 1:** Write failing tests for param mapping, status default, date auto-set, sparse params, status override
- [ ] **Step 2:** Implement `src/framework/persist-result.ts` calling Accounts API createAccountV1 with mocked client in tests
- [ ] **Step 3:** Verify upsert behavior documented in code comment (account create upserts)
- [ ] **Step 4:** Run `npm test` — persist tests green

## Task 4: Request context and wrapper

- [ ] **Step 1:** Write failing test: context factory exposes requestId, sourceId, sdk, log, persist
- [ ] **Step 2:** Implement `src/framework/request-context.ts`
- [ ] **Step 3:** Write failing test: withCustomOperation parses standard input and provides independent contexts
- [ ] **Step 4:** Implement `src/framework/with-custom-operation.ts`
- [ ] **Step 5:** Create `src/framework/index.ts` re-exporting public API
- [ ] **Step 6:** Run `npm test` — context and wrapper tests green

## Task 5: Remove legacy scaffold

- [ ] **Step 1:** Delete `src/my-client.ts` and `src/my-client.spec.ts` if present
- [ ] **Step 2:** Remove std handler code from `src/index.ts`
- [ ] **Step 3:** Update `connector-spec.json` — custom commands only, remove legacy accountSchema
- [ ] **Step 4:** Run `npm test` — fix any broken imports

## Task 6: Operations registry and example

- [ ] **Step 1:** Implement example operation in `src/operations/example-operation.ts` using ctx.persist with child identity
- [ ] **Step 2:** Wire operations in `src/operations/index.ts` exporting registerCommands(connector) function
- [ ] **Step 3:** Update `src/index.ts` to call registerCommands on createConnector()
- [ ] **Step 4:** Write test: connector has no std handlers, has example custom command
- [ ] **Step 5:** Run `npm test` — all green, coverage thresholds met

## Task 7: Documentation and changelog

- [ ] **Step 1:** Update README with foundation guide, dummy source schema, standard input envelope
- [ ] **Step 2:** Add JSDoc to framework public exports
- [ ] **Step 3:** Invoke changelog-generator or manually create changelog entry
- [ ] **Step 4:** Run `npm run build` to verify ncc bundle succeeds
- [ ] **Step 5:** Run `openspec validate --all` — all specs valid
