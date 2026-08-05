# Changelog

## [Unreleased]

### Added

- `custom:access-request-status` with `approval-email` and `ets-comment` output profiles (migrated from `isc-custom-endpoint`)
- `custom:govgroup-emails` for governance group member email resolution
- `custom:access-request-threshold` with persist contract for T2.05 Adaptive Approval Threshold workflow
- `custom:check-sod-pending` (invoke response only until a calling workflow exists)
- ISC SDK loopback clients on `ctx.sdk` (access requests, entitlements, roles, SoD, recommendations, outliers, governance groups)
- Migrated workflow templates under `workflows/`
- Custom operation foundation with `withCustomOperation()` wrapper
- Auto-initialized `RequestContext` with SailPoint SDK loopback (`sailpoint-api-client`)
- `persist(id, params?, status?)` helper for writing results to a dummy ISC source
- Read-back verification on `persist()` by default, with optional `{ verify: false }` opt-out
- `verifyPersisted(ids)` batch verification for deferred multi-write flows
- Correlated operation logging with token redaction
- Example custom operation (`custom:example`) and author template

### Removed

- Standard command handlers (`std:test-connection`, `std:account:list`, `std:account:read`)
- Mock `MyClient` aggregation scaffold

### Changed

- `ctx.sdk` expanded beyond `accounts` for ABB endpoint migration
- Vitest coverage scoped to `src/` only
- Connector is now a foundation template for custom operations, not an aggregation source
- `connector-spec.json` declares custom commands only


