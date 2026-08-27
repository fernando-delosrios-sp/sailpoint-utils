## Why

The current scaffold presents saas-custom-operations as a traditional aggregation connector with mock accounts and std commands. That misleads developers and forces every custom-operation author to reimplement ISC SDK initialization, result persistence, and correlated logging. We need a foundation template where authors add `.command()` handlers and get loopback SDK access plus dummy-source persistence for free.

## What Changes

**Connector role**
- From: Aggregation source with std:account:list/read/test-connection and mock MyClient
- To: Custom-operation foundation with no std commands; operations persist results to a pre-provisioned dummy ISC source
- Reason: Connector is a template for custom ops, not an instantiated aggregation source
- Impact: Breaking — removes all std handlers and mock client

**Operation author experience**
- From: Manual SDK setup and no persistence helper
- To: `withCustomOperation()` auto-inits volatile RequestContext with `sdk`, `log`, and `persist(id, params?, status?)`
- Reason: Coding convenience; eliminate repeated scaffolding
- Impact: Non-breaking for consumers (new capability)

**Result persistence**
- From: No write-back to ISC
- To: Helper calls account create (upsert) on dummy source with schema: id, date, status, param1..param9
- Reason: Workflow results must be traceable as dummy accounts
- Impact: Requires pre-provisioned dummy source per tenant

**Dependencies**
- From: @sailpoint/connector-sdk only
- To: Add sailpoint-api-client for loopback and account create
- Reason: SDK loopback operations during custom op execution
- Impact: New dependency

## Capabilities

### New Capabilities

- `custom-operation-framework`: Volatile RequestContext, `withCustomOperation` wrapper, SDK factory, `persist()` helper, correlated operation logging

### Modified Capabilities

- `connector-operations`: Replace std command requirements with custom command registration pattern
- `connector-config`: Custom commands only manifest; standard input envelope; dummy source account schema documentation

### Modified Capabilities (removal)

- `target-client`: Remove mock MyClient requirements — replaced by framework ISC client integration

## Impact

- **Code:** Remove `src/my-client.ts` mock; replace `src/index.ts` std handlers with framework + operations registry; add `src/framework/` module
- **Manifest:** `connector-spec.json` — custom commands only, updated sourceConfig if needed, document dummy source schema expectations
- **Dependencies:** Add `sailpoint-api-client` to package.json
- **Tests:** Replace std handler tests with framework unit tests (persist mapping, context init, logging correlation)
- **Docs:** README explaining foundation usage, standard input envelope, dummy source prerequisites
- **Existing specs:** connector-operations, connector-config updated; target-client removed or gutted
