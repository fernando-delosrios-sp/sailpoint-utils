# Changelog

All notable changes to **saas-custom-operations** are documented here.

## Unreleased

### 💥 Breaking Changes

- **Local invoke rename** — `npm run test:operation` is now `npm run call:op`. Invoke payloads live under `payloads/` and use `type` (matching spcx/workflow invoke shape) instead of `command`.
- **SOD remediation form hidden keys** — Replaced stringified `groupARevokePayload` / `groupBRevokePayload` with plain `groupAAccessSearch` / `groupBAccessSearch` ISC access-item filters (`id:x OR id:y`). Downstream workflows reading the old keys must switch; bundled seed updates apply via form-definition watermark on next launch.
- **SOD remediation formData key rename** — Mitigate compensating control select submits as `control` (was `policyControl`). Downstream workflows reading submitted `formData` must update JSONPath.
- **SOD remediation workflow keys on form instance `formInput`** — `violationId`, `targetIdentityId`, and both access-search strings are set at form instance create (declared in form definition `formInput`, no UI elements). Workflows read them from the form instance after submit via `formInput`, not from `formData` or operation persist output.

### 🔧 Improvements

- **SOD remediation violation context** — Violation ID is shown in the form context block via `formInput.violationId` interpolation.
- **Account schema attribute value limits** — Persist truncates identity values to 128 characters and STRING attribute values to 256 characters (per ISC storage limits), logging a `[persist] truncated …` warning when shortening occurs. Prevents DelimitedFile aggregation and provisioning failures on oversized values.
- **Base schema on result source create** — Auto-provisioned DelimitedFile result sources now receive the full base account schema (core attrs plus union of all registered operation output fields) immediately after source creation, replacing or aligning any ISC-discovered schema. Persist-time reconciliation remains add-only for attributes introduced after create.
- **SOD remediation keep recommendations** — Access paths show ISC keep recommendations (⭐ Recommended to keep) from the Recommendations API; connector revoke stars removed from owner-facing HTML. Non-revocable entitlements use “Not directly revocable” with named grantor; privileged entitlements show 🔐 when metadata is available. Asymmetric keep recommendations produce a side correction hint in form columns and email summary. Hidden payload adds `keepRecommendation`, `grantedVia`, and `recommendedSideToCorrect`.
- **SOD remediation revocability** — Access paths (entitlement, access profile, role) show revocable vs not-revocable with UTF-8 emoji labels in form group columns and email HTML `situationSummary`. Hidden revoke payloads include `revocable`, `recommended`, and `reason`. Bundled seed uses DESCRIPTION columns (`groupAContentsHtml` / `groupBContentsHtml`).
- **SOD remediation access search filters** — `groupAAccessSearch` / `groupBAccessSearch` now include revocable access path ids only; non-revocable entitlements granted via role or access profile on the same side are excluded from workflow filters. Owner-facing HTML still lists all paths.
- **Form definition version watermark** — Form definitions store a `@form-seed-sha256:<hex>` fingerprint in the definition `description` field. `ensureFormDefinitionByName` reuses matching definitions and auto-patches stale or legacy definitions on launch, so seed updates no longer require manual tenant form recreate.
- **Form HTML capabilities spec** — Document empirically verified ISC Custom Forms DESCRIPTION HTML rendering (block/inline tags, inline styles, links, nested lists, formInput interpolation) in `target-client/forms` spec; document `situationSummaryHtml` escaping and seed interpolation pattern in `connector-operations/sod-remediation` spec.
- **Bundled form seed loading** — `loadFormSeed` accepts in-memory seed objects; SOD remediation imports its seed JSON directly (enables bundler-friendly packaging). `tsconfig.json` enables `resolveJsonModule`.
- **SOD remediation debug logging** — Step logs use `util.inspect` with full depth so nested violation entitlements render in `npm run debug` output instead of `[Object]`.
- **Inline spec test fixtures** — Vitest mocks and expected values stay inline in co-located `*.spec.ts` files; no Vitest-only fixture sibling modules. Removed `sod-remediation/offline-data.ts` (offline violation co-located in operation handler). Identity-access SDK orchestration moved to `fetch-identity-access-items.ts`; runtime offline lookup remains in dedicated `offline-data.ts`.
- **ISC client layout normalization** — Generic ISC integration code now lives in per-API subdirectories under `src/isc/` (violations, controls, identity-history, access-profiles, roles, identity-access, token-identity, http). Pre-SDK GET transport is shared via `src/isc/http/`; identity-access orchestrates only and delegates to per-API modules. Import paths change; runtime behavior and custom operation contracts are unchanged. Extend new ISC helpers by adding modules under the matching API folder with an `index.ts` barrel export.
- **ISC accounts module** — `AccountsApi` wrappers and native-identity lookup live in `src/isc/accounts/`; account schemas remain in `src/isc/sources/` (SourcesApi). Framework persist delegates to the accounts module; runtime persist behavior is unchanged.
- **Operation layer boundaries** — Custom operations now live in mandatory `src/operations/<slug>/index.ts` subdirectories. Generic Custom Forms helpers moved to `src/isc/forms/`; SOD domain modules co-locate under `src/operations/sod-remediation/`. `src/isc/sources/` exposes generic SourcesApi wrappers only; result source auto-provision and schema reconciliation remain in `src/framework/result-source.ts`. Codegen discovers subdirectory entries and emits nested auto-registry imports. `custom:example` and `custom:sod-remediation` input/output contracts are unchanged.
- **Local invoke output** — Runner summary sections renamed to **Local invoke** and **Simulated persist (testMode=true)**.

### 🐛 Bug Fixes

- **Operation errors stop workflow retries** — Failures escaping `customOperation` now send `{ status: 'failed', error }` on the command response (HTTP 200) instead of throwing `ConnectorError` (spcx HTTP 500). Calling workflows receive the error and do not keep retrying.
- **Persist upsert** — Existing result accounts are updated via `putAccountV1`; new identities use `createAccountV1`. Both paths wait for the async provisioning task and read the account back before verification.

---

## 2026-08-10 · v0.3.1

### 🐛 Bug Fixes

- **ConnectorError propagation** — All custom operation failures now surface as `ConnectorError` from the connector-sdk. A framework boundary wrapper converts plain errors, SDK rejections, and persist verification failures so ISC workflows treat them as intentional connector failures instead of unclassified crashes that trigger spurious retries. Custom Forms API failures in sod remediation include HTTP status and response body in the error message.

---

### 🔧 Improvements

- **Default request logging** — Every registered command logs an **Incoming request** section (command, input, resolved config) to stdout before handler execution during `npm run debug` and production invokes. Output uses the same spread-JSON format as `npm run test:operation`; `config.token` is redacted.
- **spcx invoke config resolution** — Per-invoke `config` from the spcx POST body now reaches handlers and request logs. The framework reads from the external node_modules SDK `readConfig()` (spcx AsyncLocalStorage) before falling back to the bundled CONNECTOR_CONFIG path.

### ✨ New Features

- **`custom:sod-remediation`** — Launch-only SOD violation remediation operation that fetches a violation via experimental `/violations/v1`, lists tenant compensating controls, resolves entitlement access paths (including access profile and role grants), ensures a named form definition from a bundled seed template, creates a standalone form instance, and persists `formUrl` and `situationSummary` for workflow orchestration.
- **Custom Forms SDK client** — `ctx.sdk.forms` exposes `CustomFormsApi` for form definition search/create and form instance create.
- **Offline SOD invoke payload** — `payloads/sod-remediation-offline.json` for config-less dry runs with canned violation data.

### 📚 Documentation

- **README** — Documents spcx local invoke envelope (`type`, `config`, `input`), default incoming request logging, and token redaction during `npm run debug`.
- **README** — Documents `custom:sod-remediation` invoke contract, output fields, form submission keys, and downstream workflow integration pattern.

---

## 2026-08-07 · v0.2.6

### 🔧 Improvements

- **Offline fixture auto test mode** — `npm run test:operation` enables test mode automatically when a fixture omits `config`; no need to export `SPCX_TEST_MODE=1` for offline runs.
- **Fixture output summary** — After a fixture run, the runner prints highlighted sections for inhibited persist outputs (would-be ISC accounts) and the operation response (`ctx.res.send`), with prettified multi-line JSON.

---

## 2026-08-07 · v0.2.5

### 🔧 Improvements

- **Test mode config gate** — ISC skip is based on config absence, not token absence. When config is provided, `apiUrl`, `token`, and `sourceName` are required and read-only ISC checks run, failing on missing or invalid credentials. When no config is resolved, ISC is skipped (use `SPCX_TEST_MODE=1` for offline fixture runs).

### 📚 Documentation

- **Breaking:** Offline fixtures must omit the `config` section; `{ "testMode": true }` alone is no longer valid without connection fields.

---

## 2026-08-07 · v0.2.4

### ✨ New Features

-   **Test mode** — Opt-in dry-run via `config.testMode` or `SPCX_TEST_MODE=1`. Inhibits ISC persistence and schema/source writes while handlers and `ctx.res.send` run unchanged. With a valid access token, performs read-only ISC status validation and list-only source lookup; without a token, skips all ISC API calls. Inhibited operations are logged with a `[test-mode]` prefix.
-   **Operation fixture runner** — `npm run test:operation -- <fixture.json>` loads a `{ command, config, input }` envelope and prints the `res.send` payload. Example fixtures under `fixtures/`.

### 📚 Documentation

-   **README test mode** — Documents token-present vs offline fixture behavior, fixture format, and fixture runner command registration.

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


