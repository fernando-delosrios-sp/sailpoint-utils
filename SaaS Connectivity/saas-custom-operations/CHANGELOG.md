# Changelog

All notable changes to **saas-custom-operations** are documented here.

## 2026-08-19 · v0.3.2

### 🔧 Improvements

- **Shared persistable-email kit** — Adds `src/lib/persistable-email/` for compact STRING-safe workflow email HTML (escape, ellipsis truncation, unquoted href CTAs, and fit-to-budget with optional suffixes). `custom:access-model-sod-remediation` and `custom:sod-remediation` persistable email bodies use the kit; `sod-form-html` re-exports `escapeHtml` from it. Non-breaking — email body/subject behavior and persist keys are unchanged.

---

## Unreleased

### 🔧 Improvements

- **Optional `disableLinks` on SoD remediation launch commands** — `custom:access-model-sod-remediation` and `custom:sod-remediation` accept optional boolean input `disableLinks`. When `true`, form HTML entity names render as plain escaped text (no ISC admin UI anchors in `situationSummaryHtml` or group columns) even when `config.apiUrl` is present. Omitted or `false` preserves current linked behavior. Remediation form URL output and email **Remediate here** CTA are unchanged.
- **Bundled workflow integration docs** — Operation READMEs and the root README reference exports under `workflows/` (SOD Violation and Access Model SOD lifecycles), document triggers, JSONPaths, and end-to-end integration patterns, and replace stale `SOD Remediation - Violation Response` / `Action` filenames.
- **Unified SoD form context panels and ISC admin links** — Both `custom:sod-remediation` and `custom:access-model-sod-remediation` now assemble a single upper `situationSummaryHtml` context panel with **What we found** / **What we need from you** blocks, ⚠️ signposting, and ISC admin deep links on entity display names when `config.apiUrl` is present (`resolveUiOrigin` + `renderIscUiLink` in `src/lib/sod-form-html/`). sod-remediation links identity, policy, access-path lines, and grantor references; violation id stays plain text with a separate **View SOD violations** list link. access-model adds programmatic `situationSummaryHtml` at launch (replacing static seed metadata). Offline invoke omits links. Persisted email bodies stay compact without entity deep links. **Form definition migration:** re-invoke with the **same** `formName` after upgrade — stale seed fingerprints are patched in place on the existing definition; new instances pick up the layout. Already-assigned instances keep prior HTML until recreated.
- **Framework logging sync** — Unified emit pipeline for all invoke-scoped logs: redact → JSON-safe normalize → pretty multiline console → optional `config.logUrl` POST. Console shows `[requestId] message` plus labeled per-key detail blocks; POST uses the same normalized `detail` map. Incoming request logging routes through the shared path with full `sanitizeForLog` on config. SOD operation step logs (`sod-remediation`, `access-model-sod-remediation`, `preventive-sod-check`) now use `ctx.log` / `getActiveFrameworkLogger()` instead of direct `console` calls so remote collectors receive the same traces as stdout.
- **Bundle verification** — `npm run verify:bundle` (also runs as `postbuild`) loads `dist/index.js` and fails when any `connector-spec.json` command is missing from the handler map, catching codegen/build drift before `pack-zip` upload.
- **Dev compile hooks** — `npm run dev` and `npm run debug` run `compile:dev` (`codegen:schemas` + `tsc`) via `predev` / `predebug` so `.dev-dist/` stays aligned with source without a manual build step.
- **CI verification baseline** — Parent repo workflow `.github/workflows/saas-custom-operations-ci.yml` runs `npm ci`, `npm run typecheck`, `npm test`, and `npm run build` on PR/push when files under `SaaS Connectivity/saas-custom-operations/` change.
- **Standalone typecheck** — `npm run typecheck` typechecks `src/` and `scripts/` via separate tsconfigs without emit.
- **Dev toolchain upgrades** — Vitest 4.x and TypeScript 5.x stable; `@vitest/coverage-v8` aligned to Vitest 4.
- **Access-model SoD child persist idempotency** — `custom:access-model-sod-remediation` skips form launch and child persist when a result-source account already exists at `{requestId}:{accessItemId}:{policyId}`. Re-invokes and concurrent runs with the same `requestId` no longer search form instances or overwrite existing child accounts. `forms-skipped` counts violations skipped for an existing child account.
- **Access-model SoD skipped instances on invoke response** — `custom:access-model-sod-remediation` adds optional `forms-skipped-instances` on `ctx.res.send` (global invoke response only) listing skipped violations by child identity plus access item and policy context. Form URLs and email fields are not duplicated on the invoke response; read them from existing child accounts via Get Accounts.
- **Access-model SoD scan performance** — `custom:access-model-sod-remediation` memoizes access-item owner id/email resolution and caches access-item entitlement expansion within the scan loop to reduce ISC API volume on large catalogs.
- **Access-model SoD apply idempotency** — `custom:access-model-sod-remediation-apply` skips duplicate catalog PATCH when a prior apply persist exists for the same `formInstanceId` (`skipped-already-applied`). Concurrent applies dedupe in-flight on `formInstanceId` instead of `requestId`.
- **Access-model SoD scan failure counters** — Adds `access-model-sod-remediation:forms-launch-failed` on the invoke response; `forms-persist-failed` now counts child persist failures only (not form launch errors).
- **Auto-wired local invoke** — `npm run call:op` resolves operation handlers from the codegen-exported `OPERATION_HANDLERS` map in `auto-registry.ts`. New auto-discovered custom operations work locally after `npm run build` without manually registering handlers in `scripts/call-op.ts`.
- **Framework security hardening** — Custom operation framework logging now redacts sensitive `detail` fields on both stdout and optional `config.logUrl` POSTs (previously console skipped redaction). Caller-visible failed invoke messages and automatic failure persist `details` no longer include raw ISC API response bodies; full context is logged at error level with `requestId` correlation. Form definition search by name escapes embedded quotes and backslashes via `escapeODataString`. Operations share `isOfflineContext` for offline vs live branching; partial connection config (`apiUrl` without `token`, or the reverse) fails with incomplete connection config instead of silently choosing offline or live behavior.
- **Access-model SoD flat access profile lines** — `custom:access-model-sod-remediation` group column HTML now renders nested access profiles as a single flat row with an offending entitlement mention (for example `— offending: payment_issue`) instead of a nested entitlement bullet tree. Outcome panels apply to the whole access profile row. New form instances pick this up at launch; existing ASSIGNED instances keep prior HTML until recreated. Prepares for a follow-on catalog correct operation that detaches whole access profiles from roles.
- **`operationName` core result attribute** — Result-source base schema and every persist (success or automatic failure) now include mandatory STRING attribute `operationName`, set from the invoking custom command (e.g. `custom:sod-remediation`). Workflows can filter Get Accounts by command without inferring from prefixed output keys. Existing sources gain the attribute on next schema reconciliation.
- **Optional external log delivery (`config.logUrl`)** — Custom operation framework logging now exposes `ctx.log` (`info`, `warn`, `error`) on `RequestContext`, backed by a dual-sink logger that always writes `[requestId]`-prefixed lines to stdout and, when `config.logUrl` is set on the invoke envelope, fire-and-forget POSTs one JSON log event per call. Incoming request logging, persist traces, test-mode summaries, and ISC debug helpers route through the same logger. Token and bearer values are redacted in external payloads; POST failures are non-fatal. See README Development → Invoke config and Operation logging.
- **Unified SoD form HTML styling** — Adds shared builders under `src/lib/sod-form-html/` (type tags, icon suffixes, emoji legend, outcome panels). Both `custom:sod-remediation` and `custom:access-model-sod-remediation` pre-render group column HTML `formInput` fields with seed `formConditions` that swap plain vs green/red outcome panels when the recipient selects `remediationSide`. sod-remediation uses icon-only line markers and a single legend in `situationSummaryHtml`; access-model-sod-remediation keeps nested AP trees without emojis. **Form definition migration:** re-invoke with the **same** `formName` after upgrade — stale seed fingerprints are patched in place on the existing definition.
- **Failed result accounts with `details`** — Terminal custom operation failures upsert a result-source account for `requestId` with `status: failed` and mandatory schema attribute `details` carrying the error message, so workflows can read failures via Get Accounts as well as invoke `{ status, error }`. Handlers may set optional informative `details` on success persists.
- **Operation-scoped base schema on result source create** — Auto-provisioned DelimitedFile result sources now receive core attributes plus the **invoking operation's** output fields only (not the union of all registered operations). Other operations add their attributes lazily via persist-time reconciliation. `account-schema.json` from `npm run templates` remains a reference union of all operation outputs.

### ✨ New Features

- **`custom:access-model-sod-remediation-apply`** — Reads a completed access-model SoD remediation form instance (`formInstanceId` only), applies the recipient's `remediationSide` decision to the ISC catalog, and persists results on `{formInstanceId}`. For roles, detaches whole nested access profiles when the selected-side entitlement is granted via an AP bundle, or removes direct role entitlements otherwise; for access profiles under review, removes selected-side entitlement ids from the AP definition. Appends a structured audit line to the corrected catalog item description. Idempotent re-invoke returns `skipped-already-clean` when the catalog is already corrected. Offline invoke via `payloads/access-model-sod-remediation-apply-offline.json`.
- **`custom:access-model-sod-remediation`** — Scans enabled roles and access profiles in scope for intrinsic SoD policy violations (via `policyQuery` intersection, not predict), creates access-item-owner remediation forms per (access item, policy) pair, returns scan rollup counters on the invoke response, and persists per-form child accounts at `{requestId}:{accessItemId}:{policyId}`. Adds `src/isc/sod-policies/` and offline invoke via `payloads/access-model-sod-remediation-offline.json`.
- **`custom:preventive-sod-check`** — Evaluates executing GRANT_ACCESS requests for an identity via ISC SoD prediction and persists `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names` for workflow branching. Adds ISC helpers under `src/isc/access-requests/`, `src/isc/events-search/`, and `src/isc/sod-prediction/`; offline invoke via `payloads/preventive-sod-check.json`.
- **`custom:governance-group-emails`** — Resolves a governance group (workgroup) by display name and persists member email addresses as `governance-group-emails:emails: string[]` for workflow BCC and distribution use. Adds `src/isc/governance-groups/` ISC client wrappers (`listWorkgroupsV1`, paginated `listWorkgroupMembersV1`) and offline invoke support via `payloads/governance-group-emails-offline.json`.

### 💥 Breaking Changes

- **`custom:access-model-sod-remediation` form recipient is access item owner** — Remediation form instances and persisted `form-email-recipients` now target the role/access profile primary IDENTITY owner instead of the SoD policy owner. Workflows already bound to `form-email-recipients` need no JSONPath change; operators who expected policy-owner inboxes will see access item owners notified instead. Items without an IDENTITY owner fail that form launch (`forms-launch-failed`) and the scan continues.
- **`custom:access-model-sod-remediation` scan summary on invoke response** — Rollup counters (`access-items-scanned`, `violations-found`, optional `forms-skipped` / `forms-persist-failed`) are returned on successful `ctx.res.send` instead of a parent result-source account on `requestId`. Child accounts at `{requestId}:{accessItemId}:{policyId}` are unchanged. Workflows must read rollup fields from the Custom Command invoke response, not Get Accounts on `requestId`.
- **`custom:access-sod-remediation` → `custom:access-model-sod-remediation`** — Renames the access-model SoD scan command, persist namespace (`access-model-sod-remediation:*`), operation source directory, and offline payload (`payloads/access-model-sod-remediation-offline.json`). ISC workflows must update invoke command steps and Get Accounts / Send Email JSONPath; there is no dual-write of the old command or persist keys.
- **`form-email-recipient` → `form-email-recipients`** — On `custom:sod-remediation` and `custom:access-model-sod-remediation`, the persist output key is renamed to `form-email-recipients` and typed as `string[]` (account schema `isMulti: true`). Values are single-element arrays wrapping the resolved owner email until multi-recipient resolution is added. Downstream workflows must update Get Accounts / Send Email JSONPath from `form-email-recipient` to `form-email-recipients`. Bundled `workflows/SOD Remediation - Violation Response.json` is updated.
- **`custom:sod-remediation` persist keys** — Renames `sod-remediation:situation-summary` to `sod-remediation:form-email-body`, `sod-remediation:situation-header` to `sod-remediation:form-email-header`, and `sod-remediation:owner-email` to `sod-remediation:form-email-recipient`. `sod-remediation:form-url` is unchanged. Downstream workflows must update Get Accounts / Send Email JSONPath. Bundled `workflows/SOD Remediation - Violation Response.json` is updated.
- **`custom:preventive-sod-check` input semantics** — `identityId` is optional. Provide `identityId` alone for identity mode, or `accessRequestId` for request mode (identity resolved from the access request). When both are supplied, `accessRequestId` wins and `identityId` is ignored with a logged warning.
- **`custom:preventive-sod-check` output semantics** — Adds `preventive-sod-check:has-violation` (boolean). When `accessRequestId` is provided, `has-violation` and `violated-policy-names` reflect violations **introduced by that request** (predict delta), not the full identity state. Identity-only invoke (no `accessRequestId`) unions active violations with inflight predict results. Request mode returns `has-violation: false` when the identity already violates SoD but the target request adds no new violation.
- **Local invoke rename** — `npm run test:operation` is now `npm run call:op`. Invoke payloads live under `payloads/` and use `type` (matching spcx/workflow invoke shape) instead of `command`.
- **SOD remediation form hidden keys** — Replaced stringified `groupARevokePayload` / `groupBRevokePayload` with plain `groupAAccessSearch` / `groupBAccessSearch` ISC access-item filters (`id:x OR id:y`). Downstream workflows reading the old keys must switch; bundled seed updates apply via form-definition watermark on next launch.
- **SOD remediation formData key rename** — Mitigate compensating control select submits as `control` (was `policyControl`). Downstream workflows reading submitted `formData` must update JSONPath.
- **SOD remediation workflow keys on form instance `formInput`** — `violationId`, `targetIdentityId`, and both access-search strings are set at form instance create (declared in form definition `formInput`, no UI elements). Workflows read them from the form instance after submit via `formInput`, not from `formData` or operation persist output.

### 🔧 Improvements

- **Per-operation README docs** — Each custom operation subdirectory now includes a co-located `README.md` for invoke payloads and workflow integration. The root README links to each operation doc and no longer inlines operation-specific workflow steps. Codegen fails when a discovered operation is missing its README.
- **SOD remediation violation context** — Violation ID is shown in the form context block via `formInput.violationId` interpolation.
- **Account schema attribute value limits** — Persist truncates identity values to 128 characters and STRING attribute values to 256 characters (per ISC storage limits), logging a `[persist] truncated …` warning when shortening occurs. Prevents DelimitedFile aggregation and provisioning failures on oversized values.
- **Base schema on result source create** — Auto-provisioned DelimitedFile result sources receive core attrs plus the invoking operation's output fields at create time (see Unreleased Improvements for operation-scoped behavior). Persist-time reconciliation remains add-only for attributes from other operations.
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

### 📚 Documentation

- **Connected local invoke (`ISC_TOKEN`)** — README Development section and `.env.example` document supplying an access token via `ISC_TOKEN` when payload `config.token` is a placeholder.
- **Agent guidance refresh** — `AGENTS.md` and `openspec/config.yaml` describe the custom-operations-only architecture (auto-registry, six custom commands, ISC loopback helpers) and no longer reference removed std-command handlers or `my-client.ts`.

### 🐛 Bug Fixes

- **SoD remediation removed-side nesting** — On `custom:sod-remediation` form group columns, entitlements contained by a role or access profile now stay indented under their grantor in the removed (red) preview, matching the kept (green) preview. Previously the removed variant rendered them flush with the grantor line because each line gets its own outcome panel for independent keep/remove coloring. New form instances pick this up at launch; already-assigned instances keep prior HTML until recreated.
- **Access-model SoD policyScope safety** — Compound `policyScope` filters that include `state` but are not exact `state eq "ENFORCED"` or `state eq "NOT_ENFORCED"` now fail with ConnectorError instead of silently listing all policies unfiltered.
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


