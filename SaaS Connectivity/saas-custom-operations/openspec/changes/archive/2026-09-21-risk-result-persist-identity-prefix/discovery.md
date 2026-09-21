## Scope

Prefix the `custom:evaluate-access-request-risk` result-source account identity with the command slug so risk rows name their writing operation, and update the three bundled Risk Approval workflows to read back the prefixed identity; scoring rules, persisted attribute keys, and the invoke input contract stay as they are.

## Language

**Risk persist identity** (`promote`):
The result-source native identity holding `custom:evaluate-access-request-risk` outputs, `evaluate-access-request-risk:{requestId}`, where `{requestId}` is the invoke `requestId` the calling workflow supplies.
_Avoid_: risk account key, tier account id

**Wrapper discriminator** (`promote`):
The trailing segment each bundled workflow appends to the access request id when it builds `requestId` — `:submitted`, `:dynamic`, or `:dynamic-approval` — so the three wrappers scoring the same access request do not overwrite each other's result account.
_Avoid_: workflow suffix, request suffix

Conflict check against `openspec/specs/ubiquitous-language/spec.md`: no existing term is displaced. **Risk persist identity** is a sibling of the canonical **apply persist identity** and **child persist identity** and follows their spelling convention. **Wrapper discriminator** names a concept the risk README already describes in prose ("the access request id plus a suffix so the three wrappers do not overwrite each other") but never named.

## Decisions

**Context.** `custom:evaluate-access-request-risk` calls `ctx.persist(ctx.requestId, …)`, so the account identity is whatever the workflow puts in `requestId` — today `{{$.trigger.accessRequestId}}:dynamic`. A real run produced native identity `3744e2ffa1fa457a9bf20202383e7cc2:dynamic`: a bare hex id sitting next to `sod-remediation:…` and `access-model-sod-remediation-apply:…` siblings on the shared result source. This is the exact defect the archived `2026-09-14-apply-persist-identity-prefix` change was written to remove, and whose spec states the handler "SHALL NOT use the invoke `requestId` as the persist identity."

**Q1 — Prefix in the handler, or fix the workflow JSON?**
Chosen: the handler. A workflow-side fix leaves the operation's identity contract dependent on caller discipline, and any third-party caller reintroduces bare ids. `applyPersistIdentity` in `src/operations/access-model-sod-remediation-apply/constants.ts` is the established shape: a tiny exported builder the handler calls. Follow it.

**Q2 — Prefix the whole `requestId`, or derive the identity from `accessRequestId` plus a new discriminator input?**
Chosen: prefix the whole `requestId`, giving `evaluate-access-request-risk:{requestId}`. Deriving from `accessRequestId` would need a new invoke input to carry the wrapper discriminator, changing the input contract and all three workflow bodies for no gain. Prefixing preserves the existing three-wrapper separation untouched and is a one-line handler change. Worked example: `evaluate-access-request-risk:3744e2ffa1fa457a9bf20202383e7cc2:dynamic`, 74 characters, comfortably inside `ISC_IDENTITY_MAX_LENGTH` (128).

**Q3 — Legacy identity fallback, like the apply change got?**
Chosen: no fallback. Apply needed one because its prior-apply idempotency check reads its own account back on a later invoke, so a pre-rename account had to keep deduping. Risk never reads its own account: the only reader is the workflow's `Read Risk Result` step, which runs seconds later inside the same execution and will be updated in lockstep. A pre-rename risk account is a completed historical record with no future reader. Leave legacy accounts in place — neither backfilled nor deleted.

**Q4 — Does the failure-persist path need separate handling?**
No. `persistFailedResult` writes through the same `ctx.persist`, but it is handed `activeCtx.requestId`, not the derived identity. It must be given the prefixed identity too, otherwise a failed invoke writes a bare-id account and the workflow's prefixed `Read Risk Result` misses it — which is exactly the tier-missing path that routes to High. This is the one non-obvious code site.

**Q5 — Is this breaking?**
Yes, for anything reading risk output by native identity. The blast radius is the three bundled workflows plus any operator-built Get Accounts step or ad-hoc script. Same call the apply change made; document it as breaking with a migration note.

## Open questions

None. Q4 is settled: the failure path uses the same derived identity as the success path, which the specs phase will pin with its own scenario.

## Scenarios discussed

- Successful evaluation persists on `evaluate-access-request-risk:{requestId}` and not on bare `{requestId}`.
- A failed evaluation writes its `failed` account on the same prefixed identity, so the workflow read-back finds the row and the missing-tier route still fires.
- Each of the three wrapper discriminators (`:submitted`, `:dynamic`, `:dynamic-approval`) yields a distinct prefixed identity for one access request, so the wrappers still do not collide.
- An invoke whose `requestId` already carries the prefix must not be double-prefixed.
- A caller that supplies a bare `requestId` with no discriminator still gets a prefixed identity.
- Each bundled workflow's `Read Risk Result` value matches the identity the handler writes — the pairing that breaks if either side is updated alone.
- The in-flight dedupe key keeps using raw invoke `requestId`, so identity prefixing does not change duplicate-invoke collapsing.
