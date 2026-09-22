# Changelog

All notable changes to **saas-custom-operations** are documented here.

## 2026-09-22 · v0.6.9

### 🔧 Improvements

-   **Conflict panels link to the catalog definitions** — the access item name now opens its role or access-profile definition, and the policy name opens its SoD policy definition. These links are appropriate for the person launching the analysis and are distinct from the owner-only remediation form, which remains absent. The connector persists `access-item-url` and `policy-url` so the workflow does not need to derive tenant UI routes or branch on access item type.

---

## 2026-09-22 · v0.6.8

### 🔧 Improvements

-   **Each policy side is its own attribute, so a panel can column them** — `access-model-sod-remediation:conflicting-entitlements` is replaced by `…:conflicting-entitlements-group-a` and `…:conflicting-entitlements-group-b`. One combined string read fine as a sentence but could not be split by a consumer: ISC workflow templates have no string operations, so a panel could only print it whole. Separate attributes also give each side the full 256-character ceiling instead of half, so more names survive on a wide conflict. An empty side reads `none`.

    -   Migration: redeploy the connector and re-import the workflow. The old combined attribute stops being written on the next scan; existing records pick up the two new values when that scan refreshes them.

-   **Analysis panels show the two sides side by side** — the per-conflict card puts Group A and Group B in adjacent columns with their own accent colours under a **What collides** heading, so a reader sees two opposing sets rather than one run-on list. Type, policy, and the notified owner moved below it.

---

## 2026-09-22 · v0.6.7

### 🐞 Fixes

-   **A conflict record now says what the conflict is** — a child account described the notification and nothing else: a form url, an email subject, an email body, and a recipient address. The access item name reached a reader only because it sits in the email subject, and the policy name only in the truncated form a 256-character email body allows, as in `on Acco… (ROLE) for policy AP sett…`. The spec has required `access-item-id`, `access-item-type`, `access-item-name`, `policy-id`, `policy-name`, and `recipient-id` on child output since the operation shipped; the handler persisted whatever the shared notification mapper returned, which is those four fields. All six are now written, from the violation the scan loop already holds, at no extra ISC read.

### 🔧 Improvements

-   **The colliding entitlements are named on the record** — new `access-model-sod-remediation:conflicting-entitlements` reads `Group A: Invoice Entry. Group B: Payment Release.`, using the same side labels as the remediation form. It is plain text with no links, because panels and people read it. A side too long for the ISC 256-character ceiling drops whole names and says how many (`+4 more`) rather than cutting one in half.

-   **A skipped conflict refreshes its record instead of going stale** — the scan skips a conflict that already has a form, which used to mean the account was never touched again. A record written before this release would never gain the detail, and an access item renamed after its form was raised stayed wrong forever. The skip path now rewrites the descriptive fields from the current scan and carries the stored form url and email fields over unchanged. No form is launched and no owner is emailed twice: the Notification workflow triggers on account creation and a refresh is an update. A failed refresh is logged and the scan continues.

-   **Analysis panels describe each conflict rather than dumping the response** — the Access Model SOD - Analysis workflow loops the persisted records and gives each conflict its own card naming the access item, its type, the policy, the colliding entitlements, and the owner who was notified. The remediation form link is deliberately absent: whoever launches the scan is rarely the form recipient, and the link only works for the recipient.

    -   Migration: re-import the workflow and redeploy the connector. Existing conflict records gain the detail on the next scan, so the first run after the upgrade is what fills the panels.

---

## 2026-09-22 · v0.6.6

### 🐞 Fixes

-   **A throttled tenant no longer aborts a whole scan** — `custom:access-model-sod-remediation` failed with `Request failed with status code 429 (HTTP 429)` about eleven seconds into a 107-role catalog. The SDK does install `axios-retry`, which is why this looked covered, but it runs on that library's defaults: network errors and 5xx on idempotent requests, never 429. A single throttled call therefore failed the operation with no retry. ISC requests now retry a 429 up to four times on the shared axios instance, honouring `Retry-After` when the response carries it and doubling the wait from one second when it does not. Every operation gets this, not just the scan.

    -   A retry is logged as `ISC request throttled, retrying` with the attempt, wait, and URL, so a slow run is distinguishable from a stuck one.
    -   Setting `retriesConfig` on the SDK `Configuration` after construction does nothing — `axios-retry` captures its options when the interceptor is installed in the constructor. The working hook is `configuration.axiosInstance`.

### 🔧 Improvements

-   **Access Model SOD - Analysis is an interactive process** — the bundled scan workflow now opens with an explanation of what the catalog SoD check does and closes on a panel that names the outcome: conflicts found, no conflicts, or a failure panel carrying the operation's own error text. A failed OAuth or an unreachable connector each get their own panel rather than a blank status line.

    -   Migration: re-import the workflow, point Configuration and the Get Access Token basic-auth reference at your tenant, replace `YOUR_ACCESS_MODEL_SOD_ANALYSIS_WORKFLOW_ID` in the workflow id and trigger filter, then bind an interactive process to it.
    -   The invoke answers `text/plain` NDJSON, so the body is a string in workflow state. `$.callSaaSCustomOperation.body.summary['…']` renders as literal `{{…}}` text in a panel — branch with `StringContains` instead.

-   **Conflicts are listed one panel at a time, not as a JSON dump** — the closing panel used to print the raw NDJSON stream, which was the only way to show counts given the body is a string. The workflow now reads the persisted child accounts back from the result source and loops over them, so each conflict gets its own card titled with the access item name and carrying a button to its remediation form. The raw stream survives only on the failure panel, where it is the error text.

    -   Get Accounts filters on `sourceId` with `eq` only, so **Get Result Source** resolves the id from the configured source name first and the loop input narrows the whole source to this operation's records.
    -   Conflicts raised by earlier scans are listed too — a child account is the record that a form exists, and the scan skips a conflict that already has one.
    -   A failure reading those records lands on its own panel and still ends in success: the scan ran and owners were emailed regardless.

---

## 2026-09-22 · v0.6.5

### 🐞 Fixes

-   **A dynamic approver no longer kills the access request** — every request that `Dynamic Approver - Risk analysis` added an approver to failed at the approval phase with `An unexpected error occurred: Approval workflow error: … workflowType='generic-approvals:approval-workflow'`. The callback sent `name` as an empty string on the assumption that the trigger routes on `id` and `type` alone. It does route on those, but an empty name leaves the approval with no owner — `approvalDetails` reports `originalOwner.id` as `null` and no work item is ever created. Nothing rejects the callback, so the only symptom was the failed request, and the one invocation that had ever succeeded was the one that added nobody. The workflow now resolves the approver's display name from `/v2026/identities/{id}` or `/v2026/workgroups/{id}` and sends it.

    -   Migration: re-import the workflow, then re-apply Configuration and the **Get Access Token** basic-auth reference.

-   **A low-risk approval comment reports what was evaluated** — `Set Low risk decision` hardcoded `Access request pre-check passed. Risk tier Low.` on the reasoning that the summary "only ever says Low". It does not: a Low summary reads `Low: nothing scored Medium or High. Evaluated 1 role, 2 access profiles, 6 entitlements.`, and the tally is the only evidence in the comment that the check inspected anything. Low-risk approvers saw the same sentence whether the request covered one entitlement or fifty, while Medium and High approvers got the detail. All three tiers now interpolate the summary, which is what the operation README already documented.

    -   Migration: re-import the workflow.

### 🔧 Improvements

-   **Default Approver accepts a governance group** — approver ids no longer carry an `IDENTITY|` or `GOVERNANCE_GROUP|` prefix. A tier step copies a bare id, and the new **Approver is a governance group?** step derives the callback `type` from the id format, so one Configuration value works for either kind. Previously **Default Approver** had to be a bare id while the tier steps concatenated their own prefix, and a prefixed value produced `IDENTITY|IDENTITY|<id>` whenever a manager level was missing or the risk evaluation failed. `Split approver` is gone with the prefixes.

    -   Migration: re-import the workflow and set **Default Approver** to a plain id with no prefix.
    -   The kind is read from the id: governance groups are hyphenated UUIDs, identities are unhyphenated 32-character hex. That is an observed ISC convention, not a documented guarantee. A failed name read falls through to **Name lookup failed, use the id**, which keeps routing correct and only degrades the displayed approver name.

---

## 2026-09-22 · v0.6.4

### 🐞 Fixes

-   **A failed risk invoke no longer continues as if it scored** — `custom:evaluate-access-request-risk` returns HTTP 200 with `{ status: "failed" }` in the streamed body, so workflow `catch` never fired. All three bundled risk workflows now branch on that body in **Invoke failed?** before they read the result account. The pre-check does the same for `custom:preventive-sod-check` in **SoD invoke failed?**.

    -   Migration: re-import the three Risk Approval workflows.

### 🔧 Improvements

-   **Risk summaries explain the decision** — `custom:evaluate-access-request-risk` now reports how many roles, access profiles, and entitlements it evaluated and splits winning drivers by effective privilege and Risk metadata. Summaries no longer expose object names or ids; use `evaluate-access-request-risk:contributing-ids` when identifiers are needed. Existing result accounts keep their old summary text, and the new format appears on the next invoke.

---

## 2026-09-22 · v0.6.3

### 🐞 Fixes

-   **The pre-check no longer denies every request it approved** — `Access Request Pre-Check - Risk analysis and in-flight SOD` sent `approved: false` on requests that had passed, with the approval comment still attached (`Access request pre-check passed. Risk tier Low.`). `sp:update-variable` stores a boolean as the string `"true"`, so the `BooleanEquals` on **Approved?** compared `"true"` against `true`, matched nothing, and fell through to **Callback denied**. Writing the literal unquoted in the export does not prevent this — the stringify happens when the value lands in workflow state. **Approved?** and **In-flight SoD violation?** now compare with `StringEquals` against `"true"`. The second step was broken in the other direction: a real violation set the flag to `"true"`, missed the same comparison, and skipped the denial, so violating requests were approved. **SoD flag set?** and its retry keep `BooleanEquals` because they read the flag off the result account, where it is a genuine boolean.

    -   Migration: re-import the workflow.

-   **An operation with an empty list output no longer fails verification** — ISC stores an empty multi-valued attribute as nothing, so `[]` reads back as `""`. Persist verification compared the two literally and failed every clean `custom:preventive-sod-check` run with `preventive-sod-check:violated-policy-names: expected "[]", got ""`. An empty array now matches an absent, empty-string, or empty-array read-back. A non-empty array that reads back empty is still a mismatch.

-   **A slow provisioning task no longer fails a persist that succeeded** — `custom:evaluate-access-request-risk` reported `Account provisioning task … did not complete after retries` while the result account landed correctly moments later. Task polling is an optimization, so its budget grew from 30 to 90 seconds and a timeout now falls through to the account lookup and verification, which are the real signal. A task that reports an explicit error still fails the operation.

### 🔧 Improvements

-   **The access request pre-check retries a result read once before denying** — a result account can be returned by Get Accounts before its attributes are indexed, which looked like a missing tier and denied a request that had scored fine. `Access Request Pre-Check - Risk analysis and in-flight SOD` now checks each result for presence, waits a minute, and reads once more before taking the failure path. Both reads copy their findings into `Risk Tier`, `Risk Summary`, `Sod Has Violation`, and `Sod Summary`, and the tier, comment, and violation steps branch on those variables, so the retry needs no duplicate policy steps. The wait only costs time on requests whose result was not readable yet.

    -   Migration: re-import the workflow. `Dynamic Approver - Risk analysis` and `Dynamic Approval Workflow - Risk analysis` still read once.
    -   The violation flag is the one finding the reads do **not** copy. Each read branches on the flag where Get Accounts still hands it back as a real boolean, then sets `Sod Has Violation` from that branch, which keeps the `BooleanEquals` on the account read where it is correct.

-   **The pre-check sends the trigger a real boolean decision** — the callback built its body with `"approved.$": "$.defineVariable.approved"`, and a path substitution renders into the request body as the string `"true"`, which the Access Request Submitted trigger rejects. The send is split into **Callback approved** and **Callback denied**, each carrying an unquoted literal, behind an **Approved?** check on the decision variable. A templated request body cannot carry a boolean at all, which is why the send has to branch.

    -   Migration: re-import the workflow.

-   **Pre-check comments read as sentences** — a low-risk request produced `Risk tier Low. Low`, because `evaluate-access-request-risk:situation-summary` already opens with the tier the comment then restated. The tier steps no longer repeat it, and a SoD denial now replaces the risk comment instead of appending to it, so a denial never trails a sentence that said the request passed. A clean low-risk request now reads `Access request pre-check passed. Risk tier Low.` and a violation reads `Access request pre-check denied. Risk tier Low. Access request … would violate SoD policies if completed: …`.

---

## 2026-09-22 · v0.6.2

### ⚠️ Breaking Changes

-   **Result accounts persist the invoke `requestId`** — `custom:evaluate-access-request-risk` no longer prefixes the persist identity in the handler. Callers put the command name in `requestId`. Bundled Risk Approval workflows now send and read `evaluate-access-request-risk:{{accessRequestId}}:{discriminator}`. Direct invokes that still send a bare id write that bare id.

    -   Migration: re-import the three bundled Risk Approval workflows (or set `requestId` to the same string you already filter Get Accounts on). Existing `evaluate-access-request-risk:…` accounts stay valid when the workflow `requestId` matches.

-   **Apply persist identity is `{requestId}:{formInstanceId}`** — `custom:access-model-sod-remediation-apply` no longer hardcodes the command slug as the persist prefix. The bundled Remediation workflow sends `requestId` `access-model-sod-remediation-apply`, so live account names stay `access-model-sod-remediation-apply:{formInstanceId}`. Prior-apply lookup still falls back to that spelling and to bare `{formInstanceId}`.
    -   Migration: re-import `Access Model SOD - Remediation` so `requestId` is `access-model-sod-remediation-apply` (not hyphenated with the form instance id).

### 🐞 Fixes

-   **An unscored access request is no longer treated as High risk** — When the risk evaluation could not produce a tier (a failed token, invoke, or result read, or a result account that came back without `evaluate-access-request-risk:tier`), `Dynamic Approver - Risk analysis` and `Dynamic Approval Workflow - Risk analysis` fell through to their High step. A request that was never scored now takes a failure path instead: the dynamic approver uses **Set Error approver** (the **Default Approver** id) for every failure, and the Adaptive Approvals workflow opens a new **Approval Policy Evaluation Failed**. `Access Request Pre-Check - Risk analysis and in-flight SOD` already denied on a missing tier and is unchanged on the risk side.

    -   Migration: re-import both workflows, then bind the reviewer on **Approval Policy Evaluation Failed** (placeholder `YOUR_EVALUATION_FAILED_REVIEWER_ID`) alongside the three tier policies.

-   **A missing SoD result no longer approves the request** — In `Access Request Pre-Check - Risk analysis and in-flight SOD`, a **Read SoD Result** that returned no account left `preventive-sod-check:has-violation` absent, which the violation check read as "no violation" and approved. A new **SoD result present?** step routes that case to **Set evaluation failed decision**. It tests the situation summary, not the violation flag, because the flag is legitimately `false` on a clean request.
    -   Migration: re-import the workflow.

---

## 2026-09-21 · v0.6.1

### ⚠️ Breaking Changes

-   **Risk result accounts now use a command-prefixed identity** — `custom:evaluate-access-request-risk` writes successful and failed result accounts at `evaluate-access-request-risk:{requestId}` instead of the bare `{requestId}`. Existing bare accounts are neither backfilled nor deleted.
    -   Migration: update custom Get Accounts filters and scripts to the prefixed identity. Deploy the connector and re-import all three bundled Risk Approval workflows in one maintenance window, then restore Configuration values and the Get Access Token authentication.

### 🔧 Improvements

-   **Custom operations can declare their result identity** — `customOperation` accepts an optional `resultIdentity(requestId)` builder, exposed as `ctx.resultIdentity`; automatic handler-time failure persistence uses the same identity as successful output. Operations that omit the builder continue using the invoke `requestId`.

### 🐞 Fixes

-   **Single requested item no longer fails risk evaluation** — ISC collapses a one-element `$.trigger.requestedItems` to a bare object when it builds the invoke body, which made `custom:evaluate-access-request-risk` fail with `(input.requestedItems ?? []).map is not a function` on every access request for exactly one item. `requestedItems` now accepts an array, a single object, or a JSON string of either. Access requests for two or more items were unaffected.
-   **Risk approval callbacks declare no-auth** — The `Callback` and `Callback None` steps in `Risk Approval - Dynamic Approver`, and `Callback Approve` and `Callback Deny` in `Risk Approval - Auto Approve or Deny`, were missing `param_authenticationRef`, so the trigger callback failed with `failed to get authentication type: missing authentication type` and the access request was never routed. Re-import both workflows to pick up the fix.

---

## 2026-09-14 · v0.6.0

### ⚠️ Breaking Changes

-   **Apply persist identity is prefixed** — `custom:access-model-sod-remediation-apply` now writes result-source accounts at `access-model-sod-remediation-apply:{formInstanceId}` instead of the bare form instance id. Invoke `requestId` is still not the persist identity. Legacy bare accounts are neither backfilled nor deleted; prior-apply lookup falls back to them as read-only, and replay persist writes the prefixed identity.

    -   Migration: Get Accounts and ad-hoc scripts that read apply output by native identity `{formInstanceId}` must switch to `access-model-sod-remediation-apply:{formInstanceId}`. The bundled Access Model SOD - Remediation workflow has no Get Accounts step and needs no JSON edit.

-   **Description audit line names the apply command** — Catalog description lines appended by apply now open with `[access-model-sod-remediation-apply {timestamp}]` instead of `[SOD remediation {timestamp}]`. Line body, append-not-replace behavior, and `access-model-sod-remediation-apply:description-appended` are otherwise unchanged.
    -   Migration: Anything parsing the old `[SOD remediation` prefix must match the command slug. Existing catalog descriptions keep their original lines.

---

## 2026-09-02 · v0.5.0

### ⚠️ Breaking Changes

-   **Access-model SoD apply resolves forms by name** — `custom:access-model-sod-remediation-apply` now requires `formName` alongside `formInstanceId`, matching the scan operation. It looks up the existing definition by name, then lists instances by the resolved definition ID; it does not create or patch definitions and does not call the recipient-only get-by-id API. Persist identity remains `{formInstanceId}`.
    -   Migration: replace `formDefinitionId` in existing Custom Command invoke bodies with the same `formName` used by Analysis (normally `Access Model SOD Remediation`). The form-submitted trigger UUID filter remains tenant-specific. Re-import the bundled workflow or edit existing workflows; local payloads must also provide `formName`.

---

## 2026-09-01 · v0.4.0

### ⚠️ Breaking Changes

-   **Identity SoD revoke targets entitlements and roles, not access profiles** — `custom:sod-remediation` no longer treats assigned access profiles as parent access items. `groupAAccessSearch` / `groupBAccessSearch` now contain revocable **entitlement** and **role** ids only. Identity-access listing fetches assigned roles (and their entitlement ids), not access profiles. Owner-facing HTML and the elevated warning are role-level only. Residual AP membership after entitlement revoke is out of scope.
    -   Migration: deploy the connector and re-invoke `custom:sod-remediation` so new form instances get the updated search strings. Bundled `workflows/SOD Violation - Remediation.json` is unchanged (Get Access already includes entitlements). In-flight form instances keep their launch-time search strings until relaunch.

---

## 2026-08-19 · v0.3.4

### 💥 Breaking Changes

-   **Typed operation response envelope** — Successful custom operation invokes now return `{ name, status, responses, summary }` via `ctx.respond(summary)` (preferred) instead of a flat `ctx.res.send` payload. Scan rollup counters for `custom:access-model-sod-remediation` move under `summary`. Workflows that read those counters from the invoke response body must update JSONPath to `summary.<field>`. Result-source **Get Accounts** reads are unchanged.

### 🔧 Improvements

-   **Persisted-only `OperationSignature.output`** — `output` is the sole feed for the result-source account schema. Codegen (`npm run codegen:schemas`) fails when an `output` field is never persisted (object-literal `ctx.persist` keys, `toPersistAttributes(prefix, …)` expansion, or `// persist-dynamic: <key>` markers). Access-model scan counters leave the account schema.
-   **Shared form launch facade** — Adds a non-breaking ensure → create → notify facade used by `custom:sod-remediation` and `custom:access-model-sod-remediation`. Form seeds, recipient policy, skip/cap handling, persist keys, and workflow JSONPaths remain unchanged.

---

## 2026-08-19 · v0.3.3

### 🔧 Improvements

-   **Form notification envelope** — Adds `src/lib/form-notification/` with a typed `FormNotification` envelope and `toPersistAttributes(prefix, envelope)` mapper for the four workflow companion fields (`form-url`, `form-email-header`, `form-email-body`, `form-email-recipients`). `custom:sod-remediation` and `custom:access-model-sod-remediation` persist via the mapper. Non-breaking — persist keys, types, and workflow JSONPaths are unchanged.

---

## 2026-08-19 · v0.3.2

### 🔧 Improvements

-   **Shared persistable-email kit** — Adds `src/lib/persistable-email/` for compact STRING-safe workflow email HTML (escape, ellipsis truncation, unquoted href CTAs, and fit-to-budget with optional suffixes). `custom:access-model-sod-remediation` and `custom:sod-remediation` persistable email bodies use the kit; `sod-form-html` re-exports `escapeHtml` from it. Non-breaking — email body/subject behavior and persist keys are unchanged.

---

## Unreleased

### 🔧 Improvements

-   **Optional `disableLinks` on SoD remediation launch commands** — `custom:access-model-sod-remediation` and `custom:sod-remediation` accept optional boolean input `disableLinks`. When `true`, form HTML entity names render as plain escaped text (no ISC admin UI anchors in `situationSummaryHtml` or group columns) even when `config.apiUrl` is present. Omitted or `false` preserves current linked behavior. Remediation form URL output and email **Remediate here** CTA are unchanged.
-   **Bundled workflow integration docs** — Operation READMEs and the root README reference exports under `workflows/` (SOD Violation and Access Model SOD lifecycles), document triggers, JSONPaths, and end-to-end integration patterns, and replace stale `SOD Remediation - Violation Response` / `Action` filenames.
-   **Unified SoD form context panels and ISC admin links** — Both `custom:sod-remediation` and `custom:access-model-sod-remediation` now assemble a single upper `situationSummaryHtml` context panel with **What we found** / **What we need from you** blocks, ⚠️ signposting, and ISC admin deep links on entity display names when `config.apiUrl` is present (`resolveUiOrigin` + `renderIscUiLink` in `src/lib/sod-form-html/`). sod-remediation links identity, policy, access-path lines, and grantor references; violation id stays plain text with a separate **View SOD violations** list link. access-model adds programmatic `situationSummaryHtml` at launch (replacing static seed metadata). Offline invoke omits links. Persisted email bodies stay compact without entity deep links. **Form definition migration:** re-invoke with the **same** `formName` after upgrade — stale seed fingerprints are patched in place on the existing definition; new instances pick up the layout. Already-assigned instances keep prior HTML until recreated.
-   **Framework logging sync** — Unified emit pipeline for all invoke-scoped logs: redact → JSON-safe normalize → pretty multiline console → optional `config.logUrl` POST. Console shows `[requestId] message` plus labeled per-key detail blocks; POST uses the same normalized `detail` map. Incoming request logging routes through the shared path with full `sanitizeForLog` on config. SOD operation step logs (`sod-remediation`, `access-model-sod-remediation`, `preventive-sod-check`) now use `ctx.log` / `getActiveFrameworkLogger()` instead of direct `console` calls so remote collectors receive the same traces as stdout.
-   **Bundle verification** — `npm run verify:bundle` (also runs as `postbuild`) loads `dist/index.js` and fails when any `connector-spec.json` command is missing from the handler map, catching codegen/build drift before `pack-zip` upload.
-   **Dev compile hooks** — `npm run dev` and `npm run debug` run `compile:dev` (`codegen:schemas` + `tsc`) via `predev` / `predebug` so `.dev-dist/` stays aligned with source without a manual build step.
-   **CI verification baseline** — Parent repo workflow `.github/workflows/saas-custom-operations-ci.yml` runs `npm ci`, `npm run typecheck`, `npm test`, and `npm run build` on PR/push when files under `SaaS Connectivity/saas-custom-operations/` change.
-   **Standalone typecheck** — `npm run typecheck` typechecks `src/` and `scripts/` via separate tsconfigs without emit.
-   **Dev toolchain upgrades** — Vitest 4.x and TypeScript 5.x stable; `@vitest/coverage-v8` aligned to Vitest 4.
-   **Access-model SoD child persist idempotency** — `custom:access-model-sod-remediation` skips form launch and child persist when a result-source account already exists at `{requestId}:{accessItemId}:{policyId}`. Re-invokes and concurrent runs with the same `requestId` no longer search form instances or overwrite existing child accounts. `forms-skipped` counts violations skipped for an existing child account.
-   **Access-model SoD skipped instances on invoke response** — `custom:access-model-sod-remediation` adds optional `forms-skipped-instances` on `ctx.res.send` (global invoke response only) listing skipped violations by child identity plus access item and policy context. Form URLs and email fields are not duplicated on the invoke response; read them from existing child accounts via Get Accounts.
-   **Access-model SoD scan performance** — `custom:access-model-sod-remediation` memoizes access-item owner id/email resolution and caches access-item entitlement expansion within the scan loop to reduce ISC API volume on large catalogs.
-   **Access-model SoD apply idempotency** — `custom:access-model-sod-remediation-apply` skips duplicate catalog PATCH when a prior apply persist exists for the same `formInstanceId` (`skipped-already-applied`). Concurrent applies dedupe in-flight on `formInstanceId` instead of `requestId`.
-   **Access-model SoD scan failure counters** — Adds `access-model-sod-remediation:forms-launch-failed` on the invoke response; `forms-persist-failed` now counts child persist failures only (not form launch errors).
-   **Auto-wired local invoke** — `npm run call:op` resolves operation handlers from the codegen-exported `OPERATION_HANDLERS` map in `auto-registry.ts`. New auto-discovered custom operations work locally after `npm run build` without manually registering handlers in `scripts/call-op.ts`.
-   **Framework security hardening** — Custom operation framework logging now redacts sensitive `detail` fields on both stdout and optional `config.logUrl` POSTs (previously console skipped redaction). Caller-visible failed invoke messages and automatic failure persist `details` no longer include raw ISC API response bodies; full context is logged at error level with `requestId` correlation. Form definition search by name escapes embedded quotes and backslashes via `escapeODataString`. Operations share `isOfflineContext` for offline vs live branching; partial connection config (`apiUrl` without `token`, or the reverse) fails with incomplete connection config instead of silently choosing offline or live behavior.
-   **Access-model SoD flat access profile lines** — `custom:access-model-sod-remediation` group column HTML now renders nested access profiles as a single flat row with an offending entitlement mention (for example `— offending: payment_issue`) instead of a nested entitlement bullet tree. Outcome panels apply to the whole access profile row. New form instances pick this up at launch; existing ASSIGNED instances keep prior HTML until recreated. Prepares for a follow-on catalog correct operation that detaches whole access profiles from roles.
-   **`operationName` core result attribute** — Result-source base schema and every persist (success or automatic failure) now include mandatory STRING attribute `operationName`, set from the invoking custom command (e.g. `custom:sod-remediation`). Workflows can filter Get Accounts by command without inferring from prefixed output keys. Existing sources gain the attribute on next schema reconciliation.
-   **Optional external log delivery (`config.logUrl`)** — Custom operation framework logging now exposes `ctx.log` (`info`, `warn`, `error`) on `RequestContext`, backed by a dual-sink logger that always writes `[requestId]`-prefixed lines to stdout and, when `config.logUrl` is set on the invoke envelope, fire-and-forget POSTs one JSON log event per call. Incoming request logging, persist traces, test-mode summaries, and ISC debug helpers route through the same logger. Token and bearer values are redacted in external payloads; POST failures are non-fatal. See README Development → Invoke config and Operation logging.
-   **Unified SoD form HTML styling** — Adds shared builders under `src/lib/sod-form-html/` (type tags, icon suffixes, emoji legend, outcome panels). Both `custom:sod-remediation` and `custom:access-model-sod-remediation` pre-render group column HTML `formInput` fields with seed `formConditions` that swap plain vs green/red outcome panels when the recipient selects `remediationSide`. sod-remediation uses icon-only line markers and a single legend in `situationSummaryHtml`; access-model-sod-remediation keeps nested AP trees without emojis. **Form definition migration:** re-invoke with the **same** `formName` after upgrade — stale seed fingerprints are patched in place on the existing definition.
-   **Failed result accounts with `details`** — Terminal custom operation failures upsert a result-source account for `requestId` with `status: failed` and mandatory schema attribute `details` carrying the error message, so workflows can read failures via Get Accounts as well as invoke `{ status, error }`. Handlers may set optional informative `details` on success persists.
-   **Operation-scoped base schema on result source create** — Auto-provisioned DelimitedFile result sources now receive core attributes plus the **invoking operation's** output fields only (not the union of all registered operations). Other operations add their attributes lazily via persist-time reconciliation. `account-schema.json` from `npm run templates` remains a reference union of all operation outputs.

### ✨ New Features

-   **`custom:access-model-sod-remediation-apply`** — Reads a completed access-model SoD remediation form instance (`formInstanceId` only), applies the recipient's `remediationSide` decision to the ISC catalog, and persists results on `{formInstanceId}`. For roles, detaches whole nested access profiles when the selected-side entitlement is granted via an AP bundle, or removes direct role entitlements otherwise; for access profiles under review, removes selected-side entitlement ids from the AP definition. Appends a structured audit line to the corrected catalog item description. Idempotent re-invoke returns `skipped-already-clean` when the catalog is already corrected. Offline invoke via `payloads/access-model-sod-remediation-apply-offline.json`.
-   **`custom:access-model-sod-remediation`** — Scans enabled roles and access profiles in scope for intrinsic SoD policy violations (via `policyQuery` intersection, not predict), creates access-item-owner remediation forms per (access item, policy) pair, returns scan rollup counters on the invoke response, and persists per-form child accounts at `{requestId}:{accessItemId}:{policyId}`. Adds `src/isc/sod-policies/` and offline invoke via `payloads/access-model-sod-remediation-offline.json`.
-   **`custom:preventive-sod-check`** — Evaluates executing GRANT_ACCESS requests for an identity via ISC SoD prediction and persists `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names` for workflow branching. Adds ISC helpers under `src/isc/access-requests/`, `src/isc/events-search/`, and `src/isc/sod-prediction/`; offline invoke via `payloads/preventive-sod-check.json`.
-   **`custom:governance-group-emails`** — Resolves a governance group (workgroup) by display name and persists member email addresses as `governance-group-emails:emails: string[]` for workflow BCC and distribution use. Adds `src/isc/governance-groups/` ISC client wrappers (`listWorkgroupsV1`, paginated `listWorkgroupMembersV1`) and offline invoke support via `payloads/governance-group-emails-offline.json`.

### 💥 Breaking Changes

-   **`custom:access-model-sod-remediation` form recipient is access item owner** — Remediation form instances and persisted `form-email-recipients` now target the role/access profile primary IDENTITY owner instead of the SoD policy owner. Workflows already bound to `form-email-recipients` need no JSONPath change; operators who expected policy-owner inboxes will see access item owners notified instead. Items without an IDENTITY owner fail that form launch (`forms-launch-failed`) and the scan continues.
-   **`custom:access-model-sod-remediation` scan summary on invoke response** — Rollup counters (`access-items-scanned`, `violations-found`, optional `forms-skipped` / `forms-persist-failed`) are returned on successful `ctx.res.send` instead of a parent result-source account on `requestId`. Child accounts at `{requestId}:{accessItemId}:{policyId}` are unchanged. Workflows must read rollup fields from the Custom Command invoke response, not Get Accounts on `requestId`.
-   **`custom:access-sod-remediation` → `custom:access-model-sod-remediation`** — Renames the access-model SoD scan command, persist namespace (`access-model-sod-remediation:*`), operation source directory, and offline payload (`payloads/access-model-sod-remediation-offline.json`). ISC workflows must update invoke command steps and Get Accounts / Send Email JSONPath; there is no dual-write of the old command or persist keys.
-   **`form-email-recipient` → `form-email-recipients`** — On `custom:sod-remediation` and `custom:access-model-sod-remediation`, the persist output key is renamed to `form-email-recipients` and typed as `string[]` (account schema `isMulti: true`). Values are single-element arrays wrapping the resolved owner email until multi-recipient resolution is added. Downstream workflows must update Get Accounts / Send Email JSONPath from `form-email-recipient` to `form-email-recipients`. Bundled `workflows/SOD Remediation - Violation Response.json` is updated.
-   **`custom:sod-remediation` persist keys** — Renames `sod-remediation:situation-summary` to `sod-remediation:form-email-body`, `sod-remediation:situation-header` to `sod-remediation:form-email-header`, and `sod-remediation:owner-email` to `sod-remediation:form-email-recipient`. `sod-remediation:form-url` is unchanged. Downstream workflows must update Get Accounts / Send Email JSONPath. Bundled `workflows/SOD Remediation - Violation Response.json` is updated.
-   **`custom:preventive-sod-check` input semantics** — `identityId` is optional. Provide `identityId` alone for identity mode, or `accessRequestId` for request mode (identity resolved from the access request). When both are supplied, `accessRequestId` wins and `identityId` is ignored with a logged warning.
-   **`custom:preventive-sod-check` output semantics** — Adds `preventive-sod-check:has-violation` (boolean). When `accessRequestId` is provided, `has-violation` and `violated-policy-names` reflect violations **introduced by that request** (predict delta), not the full identity state. Identity-only invoke (no `accessRequestId`) unions active violations with inflight predict results. Request mode returns `has-violation: false` when the identity already violates SoD but the target request adds no new violation.
-   **Local invoke rename** — `npm run test:operation` is now `npm run call:op`. Invoke payloads live under `payloads/` and use `type` (matching spcx/workflow invoke shape) instead of `command`.
-   **SOD remediation form hidden keys** — Replaced stringified `groupARevokePayload` / `groupBRevokePayload` with plain `groupAAccessSearch` / `groupBAccessSearch` ISC access-item filters (`id:x OR id:y`). Downstream workflows reading the old keys must switch; bundled seed updates apply via form-definition watermark on next launch.
-   **SOD remediation formData key rename** — Mitigate compensating control select submits as `control` (was `policyControl`). Downstream workflows reading submitted `formData` must update JSONPath.
-   **SOD remediation workflow keys on form instance `formInput`** — `violationId`, `targetIdentityId`, and both access-search strings are set at form instance create (declared in form definition `formInput`, no UI elements). Workflows read them from the form instance after submit via `formInput`, not from `formData` or operation persist output.

### 🔧 Improvements

-   **Per-operation README docs** — Each custom operation subdirectory now includes a co-located `README.md` for invoke payloads and workflow integration. The root README links to each operation doc and no longer inlines operation-specific workflow steps. Codegen fails when a discovered operation is missing its README.
-   **SOD remediation violation context** — Violation ID is shown in the form context block via `formInput.violationId` interpolation.
-   **Account schema attribute value limits** — Persist truncates identity values to 128 characters and STRING attribute values to 256 characters (per ISC storage limits), logging a `[persist] truncated …` warning when shortening occurs. Prevents DelimitedFile aggregation and provisioning failures on oversized values.
-   **Base schema on result source create** — Auto-provisioned DelimitedFile result sources receive core attrs plus the invoking operation's output fields at create time (see Unreleased Improvements for operation-scoped behavior). Persist-time reconciliation remains add-only for attributes from other operations.
-   **SOD remediation keep recommendations** — Access paths show ISC keep recommendations (⭐ Recommended to keep) from the Recommendations API; connector revoke stars removed from owner-facing HTML. Non-revocable entitlements use “Not directly revocable” with named grantor; privileged entitlements show 🔐 when metadata is available. Asymmetric keep recommendations produce a side correction hint in form columns and email summary. Hidden payload adds `keepRecommendation`, `grantedVia`, and `recommendedSideToCorrect`.
-   **SOD remediation revocability** — Access paths (entitlement, access profile, role) show revocable vs not-revocable with UTF-8 emoji labels in form group columns and email HTML `situationSummary`. Hidden revoke payloads include `revocable`, `recommended`, and `reason`. Bundled seed uses DESCRIPTION columns (`groupAContentsHtml` / `groupBContentsHtml`).
-   **SOD remediation access search filters** — `groupAAccessSearch` / `groupBAccessSearch` now include revocable access path ids only; non-revocable entitlements granted via role or access profile on the same side are excluded from workflow filters. Owner-facing HTML still lists all paths.
-   **Form definition version watermark** — Form definitions store a `@form-seed-sha256:<hex>` fingerprint in the definition `description` field. `ensureFormDefinitionByName` reuses matching definitions and auto-patches stale or legacy definitions on launch, so seed updates no longer require manual tenant form recreate.
-   **Form HTML capabilities spec** — Document empirically verified ISC Custom Forms DESCRIPTION HTML rendering (block/inline tags, inline styles, links, nested lists, formInput interpolation) in `target-client/forms` spec; document `situationSummaryHtml` escaping and seed interpolation pattern in `connector-operations/sod-remediation` spec.
-   **Bundled form seed loading** — `loadFormSeed` accepts in-memory seed objects; SOD remediation imports its seed JSON directly (enables bundler-friendly packaging). `tsconfig.json` enables `resolveJsonModule`.
-   **SOD remediation debug logging** — Step logs use `util.inspect` with full depth so nested violation entitlements render in `npm run debug` output instead of `[Object]`.
-   **Inline spec test fixtures** — Vitest mocks and expected values stay inline in co-located `*.spec.ts` files; no Vitest-only fixture sibling modules. Removed `sod-remediation/offline-data.ts` (offline violation co-located in operation handler). Identity-access SDK orchestration moved to `fetch-identity-access-items.ts`; runtime offline lookup remains in dedicated `offline-data.ts`.
-   **ISC client layout normalization** — Generic ISC integration code now lives in per-API subdirectories under `src/isc/` (violations, controls, identity-history, access-profiles, roles, identity-access, token-identity, http). Pre-SDK GET transport is shared via `src/isc/http/`; identity-access orchestrates only and delegates to per-API modules. Import paths change; runtime behavior and custom operation contracts are unchanged. Extend new ISC helpers by adding modules under the matching API folder with an `index.ts` barrel export.
-   **ISC accounts module** — `AccountsApi` wrappers and native-identity lookup live in `src/isc/accounts/`; account schemas remain in `src/isc/sources/` (SourcesApi). Framework persist delegates to the accounts module; runtime persist behavior is unchanged.
-   **Operation layer boundaries** — Custom operations now live in mandatory `src/operations/<slug>/index.ts` subdirectories. Generic Custom Forms helpers moved to `src/isc/forms/`; SOD domain modules co-locate under `src/operations/sod-remediation/`. `src/isc/sources/` exposes generic SourcesApi wrappers only; result source auto-provision and schema reconciliation remain in `src/framework/result-source.ts`. Codegen discovers subdirectory entries and emits nested auto-registry imports. `custom:example` and `custom:sod-remediation` input/output contracts are unchanged.
-   **Local invoke output** — Runner summary sections renamed to **Local invoke** and **Simulated persist (testMode=true)**.

### 📚 Documentation

-   **Connected local invoke (`ISC_TOKEN`)** — README Development section and `.env.example` document supplying an access token via `ISC_TOKEN` when payload `config.token` is a placeholder.
-   **Agent guidance refresh** — `AGENTS.md` and `openspec/config.yaml` describe the custom-operations-only architecture (auto-registry, six custom commands, ISC loopback helpers) and no longer reference removed std-command handlers or `my-client.ts`.

### 🐛 Bug Fixes

-   **SoD remediation removed-side nesting** — On `custom:sod-remediation` form group columns, entitlements contained by a role or access profile now stay indented under their grantor in the removed (red) preview, matching the kept (green) preview. Previously the removed variant rendered them flush with the grantor line because each line gets its own outcome panel for independent keep/remove coloring. New form instances pick this up at launch; already-assigned instances keep prior HTML until recreated.
-   **Access-model SoD policyScope safety** — Compound `policyScope` filters that include `state` but are not exact `state eq "ENFORCED"` or `state eq "NOT_ENFORCED"` now fail with ConnectorError instead of silently listing all policies unfiltered.
-   **Operation errors stop workflow retries** — Failures escaping `customOperation` now send `{ status: 'failed', error }` on the command response (HTTP 200) instead of throwing `ConnectorError` (spcx HTTP 500). Calling workflows receive the error and do not keep retrying.
-   **Persist upsert** — Existing result accounts are updated via `putAccountV1`; new identities use `createAccountV1`. Both paths wait for the async provisioning task and read the account back before verification.

---

## 2026-08-10 · v0.3.1

### 🐛 Bug Fixes

-   **ConnectorError propagation** — All custom operation failures now surface as `ConnectorError` from the connector-sdk. A framework boundary wrapper converts plain errors, SDK rejections, and persist verification failures so ISC workflows treat them as intentional connector failures instead of unclassified crashes that trigger spurious retries. Custom Forms API failures in sod remediation include HTTP status and response body in the error message.

---

### 🔧 Improvements

-   **Default request logging** — Every registered command logs an **Incoming request** section (command, input, resolved config) to stdout before handler execution during `npm run debug` and production invokes. Output uses the same spread-JSON format as `npm run test:operation`; `config.token` is redacted.
-   **spcx invoke config resolution** — Per-invoke `config` from the spcx POST body now reaches handlers and request logs. The framework reads from the external node_modules SDK `readConfig()` (spcx AsyncLocalStorage) before falling back to the bundled CONNECTOR_CONFIG path.

### ✨ New Features

-   **`custom:sod-remediation`** — Launch-only SOD violation remediation operation that fetches a violation via experimental `/violations/v1`, lists tenant compensating controls, resolves entitlement access paths (including access profile and role grants), ensures a named form definition from a bundled seed template, creates a standalone form instance, and persists `formUrl` and `situationSummary` for workflow orchestration.
-   **Custom Forms SDK client** — `ctx.sdk.forms` exposes `CustomFormsApi` for form definition search/create and form instance create.
-   **Offline SOD invoke payload** — `payloads/sod-remediation-offline.json` for config-less dry runs with canned violation data.

### 📚 Documentation

-   **README** — Documents spcx local invoke envelope (`type`, `config`, `input`), default incoming request logging, and token redaction during `npm run debug`.
-   **README** — Documents `custom:sod-remediation` invoke contract, output fields, form submission keys, and downstream workflow integration pattern.

---

## 2026-08-07 · v0.2.6

### 🔧 Improvements

-   **Offline fixture auto test mode** — `npm run test:operation` enables test mode automatically when a fixture omits `config`; no need to export `SPCX_TEST_MODE=1` for offline runs.
-   **Fixture output summary** — After a fixture run, the runner prints highlighted sections for inhibited persist outputs (would-be ISC accounts) and the operation response (`ctx.res.send`), with prettified multi-line JSON.

---

## 2026-08-07 · v0.2.5

### 🔧 Improvements

-   **Test mode config gate** — ISC skip is based on config absence, not token absence. When config is provided, `apiUrl`, `token`, and `sourceName` are required and read-only ISC checks run, failing on missing or invalid credentials. When no config is resolved, ISC is skipped (use `SPCX_TEST_MODE=1` for offline fixture runs).

### 📚 Documentation

-   **Breaking:** Offline fixtures must omit the `config` section; `{ "testMode": true }` alone is no longer valid without connection fields.

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
