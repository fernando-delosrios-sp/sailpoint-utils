## Why

`custom:evaluate-access-request-risk` persists on the raw invoke `requestId`, so its rows land on the shared result source as bare hex ids — a live run produced `3744e2ffa1fa457a9bf20202383e7cc2:dynamic` next to `sod-remediation:…` and `access-model-sod-remediation-apply:…` siblings. An operator triaging that source cannot tell which command wrote the row. This is the same defect the `2026-09-14-apply-persist-identity-prefix` change removed from apply, whose spec already forbids using invoke `requestId` as the persist identity; risk is now the last operation still doing it. Fixing it while the risk workflows are being re-imported for the callback-auth fix avoids a second round of operator re-imports.

## What Changes

**Risk persist identity**
- From: Outputs persist on result-source identity `{requestId}`, e.g. `3744e2ff…:dynamic`
- To: Outputs persist on `evaluate-access-request-risk:{requestId}`, e.g. `evaluate-access-request-risk:3744e2ff…:dynamic`
- Reason: Make the account identity name its writing command, matching every other operation's account
- Impact: **Breaking** for anything reading risk output by native identity; all three bundled workflows need the matching read-back edit

**Framework result identity seam**
- From: Framework failure persist always writes on the invoke `requestId`, so an operation that derives its own persist identity has its success and failure accounts land on different identities
- To: `customOperation` accepts an optional `resultIdentity(requestId)` builder; the framework resolves it once when it builds the context and uses the result for failure persist, exposing it as `ctx.resultIdentity`
- Reason: The risk workflows read back exactly one identity; a bare-id failure row would be invisible to the prefixed `Read Risk Result`, losing the `details` error message and pushing the step onto its catch branch
- Impact: Non-breaking — operations that omit the option keep `requestId` as today

**Failure account identity**
- From: A failed risk invoke writes its `failed` account on the raw `requestId`
- To: A failed risk invoke writes on the same prefixed identity as the success path, via the seam above
- Reason: Keeps the documented "the result account is `failed`, not a silent `Low`" contract reachable at the identity the workflow queries
- Impact: Non-breaking on its own, but required for the prefixed read-back to behave

**Bundled workflow read-back**
- From: `Read Risk Result` filters `nativeIdentity eq "{{$.trigger.accessRequestId}}:<discriminator>"`
- To: `nativeIdentity eq "evaluate-access-request-risk:{{$.trigger.accessRequestId}}:<discriminator>"`
- Reason: Handler and workflow must name the same account
- Impact: Operators must re-import all three Risk Approval workflows

The wrapper discriminators (`:submitted`, `:dynamic`, `:dynamic-approval`) are unchanged, so the three wrappers still never overwrite each other. Legacy bare-id risk accounts are neither backfilled nor deleted; unlike apply, risk never reads its own account back on a later invoke, so no legacy fallback lookup is needed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `connector-operations/evaluate-access-request-risk`: persist identity becomes `evaluate-access-request-risk:{requestId}` derived in the handler, covering both the success and failure persist paths
- `custom-operation-framework`: failure persist targets an operation-declared result identity when one is supplied, defaulting to the invoke `requestId`
- `ubiquitous-language`: promote **risk persist identity** and **wrapper discriminator**

## Impact

- **Code:** `src/operations/evaluate-access-request-risk/constants.ts` (new identity builder), `index.ts` (persist call and `resultIdentity` declaration); `src/framework/types.ts`, `request-context.ts`, `with-custom-operation.ts`, `failure-persist.ts` (result identity seam)
- **Tests:** `src/operations/evaluate-access-request-risk/index.spec.ts`, new `constants.spec.ts`, `src/framework/failure-persist.spec.ts`, `with-custom-operation.spec.ts`
- **Workflows:** `Read Risk Result` value in `Risk Approval - Auto Approve or Deny.json`, `Risk Approval - Dynamic Approver.json`, `Risk Approval - Dynamic approval workflow.json`
- **Docs:** operation `README.md` (Output and workflow sections), `CHANGELOG.md` breaking entry
- **ISC:** No new API surface and no extra calls; one differently named account per invoke
- **Unaffected:** Risk scoring rules, persisted attribute keys, `OperationSignature` input and output, the in-flight dedupe key (still raw `requestId`), offline fixtures' scoring behavior, and the other operations' persist identities
