# SOD Remediation Form Email Outputs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hard-rename `custom:sod-remediation` persist keys so workflows read `form-email-body`, `form-email-header`, and `form-email-recipient` instead of `situation-summary`, `situation-header`, and `owner-email`; keep `form-url`.

**Architecture:** Change `OperationSignature.output` string-literal keys, `ctx.persist` attributes, and `logSodRemediationOutput` log fields to the new names. Run schema codegen so `index.schema.ts` matches. Tests, README, bundled workflow JSONPaths, and CHANGELOG follow. Internal TypeScript identifiers (`situationSummary`, `buildSituationHeader`, `ownerEmail`) stay.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, operation schema codegen (`npm run codegen:schemas`)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas`
- Persist keys (only typed output): `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, `sod-remediation:form-email-recipient`
- Hard rename — do not persist old keys
- Do not rename internal TS identifiers or formInput `situationSummaryHtml`
- Do not change `preventive-sod-check` or `access-sod-remediation` output keys
- Coverage: 60% statements, 50% branches minimum
- Prettier: 120 print width, 4-space tabs, no semicolons, single quotes

**Spec references:**
- `openspec/changes/sod-remediation-form-email-outputs/specs/connector-operations/sod-remediation/spec.md`
- `openspec/changes/sod-remediation-form-email-outputs/specs/connector-operations/spec.md`
- `openspec/changes/sod-remediation-form-email-outputs/design.md`
- `openspec/changes/sod-remediation-form-email-outputs/tasks.md`

---

### Task 1: Persist output contract (RED then GREEN)

**Files:**
- Modify: `src/operations/sod-remediation/index.spec.ts`
- Modify: `src/operations/sod-remediation/index.ts`
- Modify: `src/operations/sod-remediation/logging.ts`
- Modify: `src/operations/sod-remediation/index.schema.ts` (via codegen only)

**Interfaces:**
- Consumes: existing persist flow (`ctx.persist`, `createAccountV1` mocks)
- Produces: `SodRemediationOperation.output` keys listed in Global Constraints

- [ ] **Step 1: Write the failing test**

In `src/operations/sod-remediation/index.spec.ts`, replace the persist attribute list and assertions:

```ts
const sodRemediationPersistAttributes = [
    { name: 'sod-remediation:form-url', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:form-email-header', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:form-email-body', type: 'STRING', isMulti: false },
    { name: 'sod-remediation:form-email-recipient', type: 'STRING', isMulti: false },
]
```

In the successful-launch persist expectation, replace:

```ts
'sod-remediation:form-url': 'https://tenant.identitynow.com/form/instance-1',
'sod-remediation:form-email-header':
    '⚠️ SOD Violation Remediation Required — Alice Example',
'sod-remediation:form-email-body': expect.stringMatching(/Alice Example/),
'sod-remediation:form-email-recipient': 'owner-default@example.com',
```

Replace both `attributes['sod-remediation:situation-summary']` lookups with `attributes['sod-remediation:form-email-body']`.

Keep `form-url` schema-reconcile assertion; optionally add `form-email-body` to the `arrayContaining` list.

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/operations/sod-remediation/index.spec.ts`

Expected: FAIL — persist still writes `situation-header` / `situation-summary` / `owner-email`.

- [ ] **Step 3: Write minimal implementation**

Update `SodRemediationOperation.output`:

```ts
output: {
    'sod-remediation:form-url': string
    'sod-remediation:form-email-body': string
    'sod-remediation:form-email-header': string
    'sod-remediation:form-email-recipient': string
}
```

Update `ctx.persist`:

```ts
await ctx.persist(ctx.requestId, {
    'sod-remediation:form-url': formUrl,
    'sod-remediation:form-email-header': situationHeader,
    'sod-remediation:form-email-body': situationSummary,
    'sod-remediation:form-email-recipient': ownerEmail,
})
```

Keep local variables `formUrl`, `situationHeader`, `situationSummary`, `ownerEmail`.

In `logging.ts` `logSodRemediationOutput`, log the new persist key names (same values):

```ts
'sod-remediation:form-url': output.formUrl,
'sod-remediation:form-email-header': output.situationHeader,
'sod-remediation:form-email-body': output.situationSummary,
'sod-remediation:form-email-recipient': output.ownerEmail,
```

- [ ] **Step 4: Regenerate schema sidecar**

Run: `npm run codegen:schemas`

Expected: `src/operations/sod-remediation/index.schema.ts` lists the four new/unchanged keys alphabetically. Do not hand-edit the sidecar.

- [ ] **Step 5: Run tests to verify they pass**

Run: `npm test -- src/operations/sod-remediation/index.spec.ts src/operations/sod-remediation/logging.spec.ts`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/operations/sod-remediation/index.ts src/operations/sod-remediation/index.spec.ts src/operations/sod-remediation/index.schema.ts src/operations/sod-remediation/logging.ts
git commit -m "feat(sod-remediation): rename persist keys to form-email-*"
```

---

### Task 2: Codegen quoted-identifier fixture

**Files:**
- Modify: `scripts/generate-operation-schemas.spec.ts`

**Interfaces:**
- Consumes: `renderOperationSchemaSidecar`
- Produces: fixture field names matching the live sod-remediation output keys

- [ ] **Step 1: Write the failing test**

Replace the sod-remediation fixture names:

```ts
{ name: 'sod-remediation:form-url', optional: false, type: 'string' },
{ name: 'sod-remediation:form-email-body', optional: false, type: 'string' },
{ name: 'sod-remediation:form-email-recipient', optional: false, type: 'string' },
```

And expectations:

```ts
expect(content).toContain("'sod-remediation:form-url': 'string',")
expect(content).toContain("'sod-remediation:form-email-body': 'string',")
expect(content).toContain("'sod-remediation:form-email-recipient': 'string',")
```

(The test proves colon-containing names are quoted; any two `form-email-*` keys plus `form-url` is enough.)

- [ ] **Step 2: Run test**

Run: `npm test -- scripts/generate-operation-schemas.spec.ts`

Expected: PASS (renderer does not care about specific key names; this is a fixture update). If it fails, fix the `toContain` strings to match `renderOperationSchemaSidecar` output.

- [ ] **Step 3: Commit**

```bash
git add scripts/generate-operation-schemas.spec.ts
git commit -m "test(codegen): use form-email persist keys in quoted-identifier fixture"
```

---

### Task 3: Docs and bundled workflow

**Files:**
- Modify: `src/operations/sod-remediation/README.md`
- Modify: `src/operations/sod-remediation/context.ts` (JSDoc only)
- Modify: `workflows/SOD Remediation - Violation Response.json`

- [ ] **Step 1: Update operation README output table**

```md
| `sod-remediation:form-url` | Standalone form URL (`standAloneFormUrl`) for email deep links |
| `sod-remediation:form-email-body` | HTML summary for workflow email bodies |
| `sod-remediation:form-email-header` | Plain-text email subject |
| `sod-remediation:form-email-recipient` | Recipient email for notifications |
```

In Workflow integration step 3, say send email using `form-email-body` as HTML body, `form-email-header` as subject, and `form-email-recipient` as recipient.

- [ ] **Step 2: Update JSDoc**

In `context.ts`, change the `buildPersistedSituationSummary` comment from `` persisted `sod-remediation:situation-summary` `` to `` persisted `sod-remediation:form-email-body` ``.

- [ ] **Step 3: Update bundled workflow JSONPaths**

In `workflows/SOD Remediation - Violation Response.json` Send Email attributes:

```json
"body.$": "$.readSaaSCustomOperationResult.accounts[0].attributes['sod-remediation:form-email-body']",
"recipientEmailList.$": "$.readSaaSCustomOperationResult.accounts[0].attributes['sod-remediation:form-email-recipient']",
"subject.$": "$.readSaaSCustomOperationResult.accounts[0].attributes['sod-remediation:form-email-header']"
```

- [ ] **Step 4: Commit**

```bash
git add src/operations/sod-remediation/README.md src/operations/sod-remediation/context.ts "workflows/SOD Remediation - Violation Response.json"
git commit -m "docs(sod-remediation): align README and workflow JSONPath with form-email keys"
```

---

### Task 4: Changelog

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Invoke changelog-generator**

Add under `## Unreleased` → `### 💥 Breaking Changes`:

```md
- **`custom:sod-remediation` persist keys** — Renames `sod-remediation:situation-summary` to `sod-remediation:form-email-body`, `sod-remediation:situation-header` to `sod-remediation:form-email-header`, and `sod-remediation:owner-email` to `sod-remediation:form-email-recipient`. `sod-remediation:form-url` is unchanged. Downstream workflows must update Get Accounts / Send Email JSONPath. Bundled `workflows/SOD Remediation - Violation Response.json` is updated.
```

Do not add an Unreleased section if one already exists; merge into it. Do not bump a dated release heading in this task.

- [ ] **Step 2: Run full verification**

Run: `npm test`

Expected: PASS (exit 0).

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): record sod-remediation form-email persist key rename"
```

---

## Spec coverage

| Scenario | Task |
|---|---|
| Sod remediation follows namespacing convention | Task 1 persist keys + schema sidecar |
| Operation invoked with required inputs | Task 1 persist field list |
| Owner email resolved for workflow delivery | Task 1 `form-email-recipient` assertion |
| Email subject header output | Task 1 `form-email-header` assertion |
| Email summary includes remediation form link | Task 1 `form-email-body` contains form link |
| Output contract is minimal | Task 1 only four typed keys |
| Situation summary HTML format / Email-oriented HTML / escaped / form input without link | Task 1 existing HTML assertions on `form-email-body`; formInput `situationSummaryHtml` unchanged |
| Side hint in form and email | Existing tests; persist key rename only |
| Email summary parity | Existing tests; persist key rename only |
| Workflow JSONPath | Task 3 bundled workflow |
