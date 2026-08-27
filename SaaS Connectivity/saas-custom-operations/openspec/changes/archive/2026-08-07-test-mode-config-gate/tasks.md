## 1. Config resolution and gate

- [x] 1.1 Add `resolveInvocationConfig(deps, context)` returning `{ config, configProvided }` in `src/framework/test-mode.ts`
- [x] 1.2 Replace `hasAccessToken` ISC gate with `configProvided` in `customOperation`
- [x] 1.3 Update `parseStandardInput` offline branch to run only when test mode active and config not provided
- [x] 1.4 When config provided in test mode, require apiUrl token sourceName and propagate ISC errors
- [x] 1.5 Unit test: absent config skips ISC (Scenario: All ISC calls skipped when no config provided)
- [x] 1.6 Unit test: context config counts as provided (Scenario: Context config counts as provided)
- [x] 1.7 Unit test: missing token fails when config provided (Scenario: Missing token fails when config provided)
- [x] 1.8 Unit test: ISC status checked when config provided (Scenario: ISC status checked when config provided)

## 2. Remove obsolete paths

- [x] 2.1 Remove or repurpose `hasAccessToken` if unused after refactor
- [x] 2.2 Update log message from `offline — skipping` to `no config — skipping ISC`
- [x] 2.3 Remove tests asserting token-absent offline with partial config object

## 3. Fixture runner and fixtures

- [x] 3.1 Update `runFixture` to omit `context.config` when fixture has no config key
- [x] 3.2 Update `fixtures/custom-example-offline.json` to remove config block
- [x] 3.3 Document `SPCX_TEST_MODE=1` for offline fixture runs in README and runner header
- [x] 3.4 Unit test: offline fixture without config (Scenario: Valid fixture loads command and payload)
- [x] 3.5 Unit test: fixture with full config passes context.config (Scenario: Valid fixture with config loads connection fields)

## 4. Documentation and changelog

- [x] 4.1 Update README test mode section for config-presence gate
- [x] 4.2 Add CHANGELOG breaking note for partial-config offline fixtures
- [x] 4.3 Bump patch version in package.json

## 5. Changelog

- [x] 5.1 Update CHANGELOG entry for config-gate behavior change
- [x] 5.2 Confirm breaking change documented for v0.2.4 offline fixture shape
