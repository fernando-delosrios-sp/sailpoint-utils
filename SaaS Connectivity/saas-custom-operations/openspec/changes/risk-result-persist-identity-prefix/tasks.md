## 1. Framework result identity seam

- [x] 1.1 Add `resultIdentity?: (requestId: string) => string` to the `customOperation` options type in `src/framework/types.ts`, and add `resultIdentity: string` to `RequestContext`
- [x] 1.2 Resolve the builder once in `createRequestContext` (`src/framework/request-context.ts`), defaulting to `input.requestId`, and expose it on the returned context
- [x] 1.3 Thread the option from `customOperation` through `runCustomOperation` into `createRequestContext` in `src/framework/with-custom-operation.ts`
- [x] 1.4 Pass `activeCtx?.resultIdentity` instead of `activeCtx?.requestId` to `persistFailedResult` in `src/framework/with-custom-operation.ts`
- [x] 1.5 Rename the `persistFailedResult` first parameter in `src/framework/failure-persist.ts` to name the result identity, keeping the skip-when-absent behavior
- [x] 1.6 Framework tests — declared builder resolves `ctx.resultIdentity`; omitted builder defaults to `requestId`; declared builder receives the failed account on handler throw and handler-sent failure; existing no-builder failure scenarios still write on `requestId`

## 2. Risk persist identity

- [x] 2.1 Add `src/operations/evaluate-access-request-risk/constants.ts` exporting `riskPersistIdentity(requestId: string): string` that prefixes `evaluate-access-request-risk:` and returns an already-prefixed input unchanged
- [x] 2.2 Add `constants.spec.ts` — plain id gets the prefix, id with a wrapper discriminator keeps it inside the prefixed identity, already-prefixed id is not prefixed twice
- [x] 2.3 Change the `ctx.persist` call in `src/operations/evaluate-access-request-risk/index.ts` to use `ctx.resultIdentity`
- [x] 2.4 Declare `resultIdentity: riskPersistIdentity` in the `customOperation` options for the risk operation so the failure path uses the same identity
- [x] 2.5 `index.spec.ts` — success persists on `evaluate-access-request-risk:{requestId}` and never on the bare id; persisted attribute keys unchanged; a handler throw writes the failed account on the prefixed identity; missing-input rejection writes the failed account on the prefixed identity
- [x] 2.6 `index.spec.ts` — each of the three wrapper discriminators yields a distinct prefixed identity for one access request
- [x] 2.7 Confirm no legacy bare-identity lookup is introduced anywhere in the operation

## 3. Bundled workflow read-back

- [x] 3.1 Update `Read Risk Result` value to `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted` in `workflows/Risk Approval - Auto Approve or Deny.json`
- [x] 3.2 Update `Read Risk Result` value to `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic` in `workflows/Risk Approval - Dynamic Approver.json`
- [x] 3.3 Update `Read Risk Result` value to `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval` in `workflows/Risk Approval - Dynamic approval workflow.json`
- [x] 3.4 Add the pairing test over the shipped workflow JSON — for each of the three files, `riskPersistIdentity` applied to the `Call Evaluate Risk` `input.requestId` template equals the `Read Risk Result` filter value
- [x] 3.5 Verify each edited workflow file still parses as JSON and no other step attribute changed

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test` (with `npm run typecheck` as the companion gate)
- [ ] 4.2 All delta spec scenarios covered by named automated tests
- [x] 4.3 `openspec validate --all --json` reports every change and spec valid

## 5. Documentation

- [ ] 5.1 Update `src/operations/evaluate-access-request-risk/README.md` — Output section states the risk persist identity is `evaluate-access-request-risk:{requestId}`, the `requestId` row explains the wrapper discriminator sits inside the prefix, and the bundled-workflow section notes the matching `Read Risk Result` filter
- [ ] 5.2 Update the root `README.md` where it describes result-account lookup by `nativeIdentity` so the risk example shows the prefixed identity
- [ ] 5.3 Document the `resultIdentity` option in the framework section of the root `README.md` alongside the other `customOperation` options, and add JSDoc on the new type members

## 6. Changelog

- [ ] 6.1 Create or update changelog entry for this change
- [ ] 6.2 Confirm entry covers user-visible changes from proposal Capabilities, flags the persist identity rename as breaking, and states that the connector deploy and all three workflow re-imports must ship together
