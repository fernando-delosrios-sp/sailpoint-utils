# Changelog

All notable changes to **saas-custom-operations** are documented here.

## Unreleased

---

## 2026-08-07 · v0.2.4

### ✨ New Features

- **Test mode** — Opt-in dry-run via `config.testMode` or `SPCX_TEST_MODE=1`. Inhibits ISC persistence and schema/source writes while handlers and `ctx.res.send` run unchanged. With a valid access token, performs read-only ISC status validation and list-only source lookup; without a token, skips all ISC API calls. Inhibited operations are logged with a `[test-mode]` prefix.
- **Operation fixture runner** — `npm run test:operation -- <fixture.json>` loads a `{ command, config, input }` envelope and prints the `res.send` payload. Example fixtures under `fixtures/`.

### 📚 Documentation

- **README test mode** — Documents token-present vs offline fixture behavior, fixture format, and fixture runner command registration.

---

## 2026-08-07 · v0.2.3

### ✨ New Features

-   **Auto operation registration** — Add `command: 'custom:…'` to `OperationSignature` and codegen auto-registers handlers in `auto-registry.ts`, populates the schema registry, and syncs `connector-spec.json` `commands[]`. Manual registration remains supported for ops without `command` (pass `{ operationSchema: sidecar }` and register in `index.ts`).

### 📚 Documentation

-   **Operation schema codegen specs** — OpenSpec main specs now document sidecar generation, auto-registry wiring, prebuild codegen, and shared templates introspection.

---

### 🐛 Fixes

-   **DelimitedFile auto-create** — Source create now includes the required `connector` field (`delimited-file-angularsc`). First-run invoke no longer fails with ISC `Required field "connector" was missing or empty`.
-   **Example workflow nextStep** — Call step now routes to `Read SaaS Custom Operation Result` (was a plural typo that broke read-back).

---

## 2026-08-06 · v0.2.0

### ✨ New Features

-   **Operation schema codegen** — `npm run codegen:schemas` generates `{operation}.schema.ts` sidecars from each registered handler's `OperationSignature.output` type literal. Sidecars run on `prebuild`; commit generated files with handler changes.
-   **Dynamic result source** — Configure `sourceName` instead of a pre-provisioned source UUID. The framework resolves the source by name on each invocation and auto-creates a DelimitedFile source when missing.
-   **Schema reconciliation at persist** — Before each `ctx.persist`, the framework ensures the result source account schema includes the current operation's output fields plus core attributes (`id`, `status`, `date`).
-   **Typed attribute inference** — Operation output TypeScript types map to ISC schema types (`number`→INT, `boolean`→BOOLEAN, arrays→isMulti) and persist values are stored with native types where supported.
-   **SourcesApi on ctx.sdk** — Source lookup, creation, and schema management via `ctx.sdk.sources`.

### 🔧 Improvements

-   **Templates generator parity** — `account-schema.json` inference aligns with runtime type mapping (INT, BOOLEAN, LONG, DATE).
-   **Type-aware read-back verification** — Persist verification coerces DelimitedFile string read-back when comparing typed values.
-   **Workflow-only bootstrap export** — `workflows/SaaS Custom Operations.json` ships the example workflow only; the result source is auto-provisioned via `sourceName` (no separate source import).
-   **Token normalization** — Accidental `Bearer ` prefixes on `config.token` are stripped before loopback API calls.

### ⚠️ Breaking Changes

-   **`sourceId` → `sourceName`** — Connector config, invoke payloads, and workflow samples use `sourceName` instead of a source UUID.
    -   Migration: replace `sourceId` with `sourceName` in connection config and workflow invoke bodies (e.g. `SaaS Custom Operations`).
-   **Typed persist** — Numeric and boolean output values are no longer stringified before account create; downstream reads may receive native types.
    -   Migration: update workflow steps that assumed all account attributes were strings.
-   **`operationSchema` required for schema reconciliation** — Pass `operationSchema.outputFields` to `customOperation()` so persist can reconcile the source schema.
    -   Migration: replace inline `defineOperationSchema({...})` with the generated `{handler}Schema` sidecar (`npm run codegen:schemas` or `npm run build`). Ensure the invoke token has source create/update and account provisioning scopes.

### 📚 Documentation

-   **Auto-provisioned result source docs** — README and operator guides aligned with `sourceName` resolution and runtime schema reconciliation (no separate source import step).

---

## 2026-08-05 · v0.1.0

### ✨ New Features

-   **Custom operation foundation** — Build ISC custom commands without reimplementing SDK setup, logging, or result persistence. Copy `_template.ts`, register your handler, and deploy.
-   **Result persistence to a dummy source** — Write flat, workflow-readable output via `ctx.persist()`. Downstream steps read results with **Get Accounts** filtered by `requestId`.
-   **ISC loopback SDK** — `ctx.sdk` exposes SailPoint API clients for in-connector calls.
-   **Operator template generator** — Run `npm run templates` to generate an account schema, OAuth setup guide, and per-operation workflow invoke instructions from your registered handlers.
-   **Example operation** — `custom:example` demonstrates invoke → persist → read-back, with an exportable ISC workflow under `workflows/`.
-   **Tenant bootstrap export** — Import `source/SaaS Custom Operations.json` to provision a dummy result source and sample workflow in a new tenant.

### 🔧 Improvements

-   **Typed operation signatures** — `customOperation<T>()` ties handler input and `ctx.persist` output to a single `OperationSignature` interface.
-   **Persist verification** — Writes are read back from ISC by default; use `{ verify: false }` and `verifyPersisted()` for deferred multi-write flows.
-   **Correlated logging** — Operation logs include `requestId` with token redaction.

### ⚠️ Breaking Changes

-   **No longer an aggregation connector** — Standard commands (`std:test-connection`, `std:account:list`, `std:account:read`) and the mock `MyClient` scaffold are removed. This project is a custom-operation runtime only.
    -   Migration: use custom commands only; do not expect aggregation std commands from this connector.
-   **`customOperation<T>()` API** — Replaces earlier positional handler params and separate output config. Define one interface with `input` and `output` types.
    -   Migration: update handlers to the `OperationSignature` + `customOperation<T>()` pattern.

### 🗑️ Removed

-   **Standard aggregation scaffold** — Standard command handlers and mock aggregation client removed.
