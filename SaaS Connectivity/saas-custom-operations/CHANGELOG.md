# Changelog

All notable changes to **saas-custom-operations** are documented here.

## [Unreleased] — 0.2.0

### New features

- **Operation schema codegen** — `npm run codegen:schemas` generates `{operation}.schema.ts` sidecars from each registered handler's `OperationSignature.output` type literal. Sidecars run on `prebuild`; commit generated files with handler changes.
- **Dynamic result source** — Configure `sourceName` instead of a pre-provisioned source UUID. The framework resolves the source by name on each invocation and auto-creates a DelimitedFile source when missing.
- **Schema reconciliation at persist** — Before each `ctx.persist`, the framework ensures the result source account schema includes the current operation's output fields plus core attributes (`id`, `status`, `date`).
- **Typed attribute inference** — Operation output TypeScript types map to ISC schema types (`number`→INT, `boolean`→BOOLEAN, arrays→isMulti) and persist values are stored with native types where supported.
- **SourcesApi on ctx.sdk** — Source lookup, creation, and schema management via `ctx.sdk.sources`.

### Improvements

- **Templates generator parity** — `account-schema.json` inference aligns with runtime type mapping (INT, BOOLEAN, LONG, DATE).
- **Type-aware read-back verification** — Persist verification coerces DelimitedFile string read-back when comparing typed values.
- **Workflow-only bootstrap export** — `workflows/SaaS Custom Operations.json` ships the example workflow only; the result source is auto-provisioned via `sourceName` (no separate source import).

### Breaking changes

- **`sourceId` → `sourceName`** — Connector config, invoke payloads, and workflow samples use `sourceName`. Update workflows and `connector-spec.json` connection settings.
- **Typed persist** — Numeric and boolean output values are no longer stringified before account create; downstream reads may receive native types.
- **`operationSchema` required for schema reconciliation** — Pass `operationSchema.outputFields` to `customOperation()` so persist can reconcile the source schema.

### Migration

1. Replace `sourceId` with `sourceName` in connector connection config and workflow invoke bodies (choose a stable name, e.g. `SaaS Custom Operations`).
2. Remove manual account-schema application steps — runtime reconciliation handles missing attributes.
3. Replace inline `defineOperationSchema({...})` with the generated `{handler}Schema` sidecar import (`npm run codegen:schemas` or `npm run build`).
4. Ensure the invoke token has source create/update and account provisioning scopes.

## [0.1.0]

### New features

- **Custom operation foundation** — Build ISC custom commands without reimplementing SDK setup, logging, or result persistence. Copy `_template.ts`, register your handler, and deploy.
- **Result persistence to a dummy source** — Write flat, workflow-readable output via `ctx.persist()`. Downstream steps read results with **Get Accounts** filtered by `requestId`.
- **ISC loopback SDK** — `ctx.sdk` exposes SailPoint API clients for in-connector calls.
- **Operator template generator** — Run `npm run templates` to generate an account schema, OAuth setup guide, and per-operation workflow invoke instructions from your registered handlers.
- **Example operation** — `custom:example` demonstrates invoke → persist → read-back, with an exportable ISC workflow under `workflows/`.
- **Tenant bootstrap export** — Import `source/SaaS Custom Operations.json` to provision a dummy result source and sample workflow in a new tenant.

### Improvements

- **Typed operation signatures** — `customOperation<T>()` ties handler input and `ctx.persist` output to a single `OperationSignature` interface.
- **Persist verification** — Writes are read back from ISC by default; use `{ verify: false }` and `verifyPersisted()` for deferred multi-write flows.
- **Correlated logging** — Operation logs include `requestId` with token redaction.
- **Vitest coverage** — Tests scoped to `src/` and the templates generator scripts.

### Breaking changes

- **No longer an aggregation connector** — Standard commands (`std:test-connection`, `std:account:list`, `std:account:read`) and the mock `MyClient` scaffold are removed. This project is a custom-operation runtime only.
- **`customOperation<T>()` API** — Replaces earlier positional handler params and separate output config. Define one interface with `input` and `output` types.

### Removed

- Standard command handlers and mock aggregation client.



