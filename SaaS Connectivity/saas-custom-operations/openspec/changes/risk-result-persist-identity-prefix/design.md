## Context

`custom:evaluate-access-request-risk` is the last operation that lets the caller name its result-source account. It calls `ctx.persist(ctx.requestId, …)`, and the three bundled workflows set `requestId` to `{{$.trigger.accessRequestId}}:<discriminator>`, so rows land as bare hex ids like `3744e2ffa1fa457a9bf20202383e7cc2:dynamic`.

Two constraints shape the design. First, the repo already has a canonical answer: `applyPersistIdentity` in `src/operations/access-model-sod-remediation-apply/constants.ts` is a one-function module the handler calls, and `openspec/specs/ubiquitous-language/spec.md` defines **apply persist identity** as derived "in code, not from invoke `requestId`". Second, risk has a coupling apply does not — the calling workflow reads the account back by native identity in the same execution (`Read Risk Result`, `sp:get-accounts`, `nativeIdentity eq`), so the handler's write identity and the workflow's read filter are one contract with two sides.

That second constraint is what pulls the framework in. `persistFailedResult` is invoked from `with-custom-operation.ts` with `activeCtx?.requestId`, so today every operation's failure account is keyed on the raw invoke `requestId` regardless of where its success account went. For apply that is a cosmetic inconsistency. For risk it is a correctness problem: the operation's documented behavior is that a lookup failure produces a `failed` account rather than a silent `Low`, and the workflow can only see that account if it is at the identity the workflow queries.

## Goals / Non-Goals

**Goals:**

- Risk result accounts name their writing command, matching **apply persist identity** and **child persist identity**.
- Success and failure persist for risk land on the same identity.
- The three wrapper discriminators keep the three bundled workflows from colliding, unchanged.
- Handler write identity and workflow read filter stay provably paired, with a test that fails if either drifts.

**Non-Goals:**

- Backfilling, migrating, or deleting pre-rename bare-id risk accounts.
- Fixing apply's failure-account identity. The new seam makes it a one-line follow-up, but apply has no read-back coupling, so it is not part of this change.
- Changing risk scoring, persisted attribute keys, the `OperationSignature` input or output, or the in-flight dedupe key.
- Introducing a framework-wide automatic prefix for every operation. Other operations' identities are deliberate and stay as they are.

## Decisions

### D1: Derive the identity in a `constants.ts` builder, not in the workflow JSON

- **Choice**: Add `src/operations/evaluate-access-request-risk/constants.ts` exporting `riskPersistIdentity(requestId: string): string` returning `` `evaluate-access-request-risk:${requestId}` ``.
- **Reason**: Mirrors `applyPersistIdentity` exactly, so the codebase has one shape for this idea. Keeping it in code means a third-party caller that invokes the command directly still gets a conforming identity; a workflow-JSON-only fix relies on caller discipline.
- **Considered alternatives**: Prefix inside the workflow `requestId` template — rejected, leaves the operation's identity contract caller-controlled. Prefix inside `createPersist` for all operations — rejected, silently renames every other operation's accounts.

### D2: Prefix the whole `requestId` rather than rebuilding from `accessRequestId`

- **Choice**: `evaluate-access-request-risk:{requestId}`, where `requestId` keeps the wrapper discriminator the workflow already appends.
- **Reason**: The discriminator is the mechanism that stops the three wrappers overwriting one another. Prefixing preserves it for free. Rebuilding from `accessRequestId` would need a new invoke input to carry the discriminator, changing the input contract and all three workflow bodies to buy nothing.
- **Considered alternatives**: `evaluate-access-request-risk:{accessRequestId}:{discriminator}` with a new `discriminator` input — rejected as above. Dropping the discriminator entirely — rejected, reintroduces cross-wrapper overwrites.
- **Length check**: `evaluate-access-request-risk:` is 30 characters; a 32-character access request id plus the longest discriminator `:dynamic-approval` gives 79, well inside `ISC_IDENTITY_MAX_LENGTH` (128). `truncateForIscStorage` stays a no-op here.

### D3: Idempotent prefixing

- **Choice**: `riskPersistIdentity` returns its input unchanged when it already starts with `evaluate-access-request-risk:`.
- **Reason**: Operators re-importing workflows mid-rollout, and hand-built invoke payloads copied from a Get Accounts filter, will pass an already-prefixed `requestId`. Double prefixing would write a second orphan account that no workflow reads.
- **Considered alternatives**: Always prefix — rejected, the orphan account is silent and only shows up as a missing tier at approval time.

### D4: A declared `resultIdentity` builder on `customOperation`, resolved before the handler runs

- **Choice**: Extend the `customOperation` options with `resultIdentity?: (requestId: string) => string`. `createRequestContext` resolves it once and exposes `ctx.resultIdentity` (defaulting to `input.requestId`); `with-custom-operation.ts` passes `activeCtx?.resultIdentity` to `persistFailedResult`. Risk declares `resultIdentity: riskPersistIdentity` and its handler persists on `ctx.resultIdentity`.
- **Reason**: Failure persist must cover initialization failures that happen before the handler body executes, so the identity has to be known at context-construction time. A declaration-time pure function of `requestId` satisfies that; anything the handler sets imperatively does not.
- **Considered alternatives**: A mutable `ctx.resultIdentity` the handler assigns as its first statement — rejected, leaves initialization failures on the bare id, which is the case most likely to need a readable `details` message. Special-casing the risk command inside `failure-persist.ts` — rejected, puts operation knowledge in the framework. Leaving failure persist on `requestId` — rejected, see Context.

### D5: No legacy identity fallback

- **Choice**: Do not look up the bare `{requestId}` account anywhere. Leave existing bare-id risk accounts untouched.
- **Reason**: Apply needed its **legacy apply persist identity** fallback because its prior-apply idempotency check reads its own account on a *later* invoke, so pre-rename rows had to keep deduping. Risk never reads its own account; the only reader is the workflow step seconds later in the same execution, updated in lockstep. A pre-rename risk row is a finished historical record with no future reader.
- **Considered alternatives**: Mirror apply's fallback for symmetry — rejected, an unreachable code path plus a wasted `findAccountOnSource` call per invoke.

### D6: Pin the handler/workflow pairing with a test over the shipped workflow JSON

- **Choice**: A test reads the three `workflows/Risk Approval*.json` files, extracts each `Read Risk Result` `value`, and asserts it equals `riskPersistIdentity` applied to that workflow's `Call Evaluate Risk` `input.requestId` template string.
- **Reason**: This is the failure mode with no local symptom — unit tests and typecheck pass while approvals silently route to High in the tenant. The repo already has precedent for asserting over shipped artifacts in `offline-context.spec.ts`, which walks the operations directory.
- **Considered alternatives**: Manual review checklist — rejected, the last two defects in these workflows (`requestedItems` shape, missing `param_authenticationRef`) both survived review. Asserting literal strings per workflow — rejected, restates the bug instead of deriving from the builder.

## Risks / Trade-offs

[Risk] An operator deploys the connector but does not re-import the workflows, so the handler writes prefixed while `Read Risk Result` still filters bare. The step finds no account, `accounts[0]` is undefined, and the tier check falls through to its default — High for the dynamic-approver and dynamic-approval workflows, deny for auto-approve-or-deny. -> Mitigation: the CHANGELOG entry and the operation README both state that the connector deploy and the three workflow re-imports ship together; the fail-safe direction (extra approver / deny) is the conservative one, so a partial rollout over-escalates rather than under-escalates.

[Risk] The new framework `resultIdentity` seam is touched by every operation's failure path, so a mistake there is broad. -> Mitigation: the option is optional with an identity default, so omitting it reproduces today's behavior exactly; framework tests assert the default path is unchanged for an operation that does not declare it.

[Trade-off] Pre-rename bare-id accounts stay on the result source as orphans with no reader. Accepted: they are audit history, deleting them destroys it, and backfilling means a write per historical row for rows nothing queries.

[Trade-off] The identity gets 30 characters longer, making the source's account list wider. Accepted: that width is the point — the row now names its command.

## Migration Plan

1. Deploy the connector (`npm run build` and upload) so the handler writes the prefixed identity.
2. Re-import all three Risk Approval workflows so `Read Risk Result` filters the prefixed identity. These two steps belong in one maintenance window; between them, evaluation degrades to the conservative default described under Risks.
3. Re-apply each workflow's Configuration values and the `Get Access Token` basic-auth client secret, which are not carried in the exported JSON.

Rollback: re-import the previous workflow exports and redeploy the previous connector build. No data migration runs in either direction, so rollback is clean; accounts written while the new build was live stay as prefixed orphans.

Acceptance: `npm run typecheck` and `npm test` exit 0; the D6 pairing test passes; a live access request through the dynamic-approver workflow produces a result account named `evaluate-access-request-risk:{accessRequestId}:dynamic` carrying a populated `evaluate-access-request-risk:tier`, and the approval routes to the tier's approver rather than the error default.

## Open Questions

None.
