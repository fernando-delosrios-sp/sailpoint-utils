## Context

`custom:access-model-sod-remediation-apply` persists its outputs with `ctx.persist(formInstanceId, outputs)` on both the replay path (prior terminal apply found) and the main path (after catalog PATCH). `readPriorTerminalApplyOutputs` reads the same identity through `findAccountOnSource(ctx.sdk.accounts, ctx.sourceId, formInstanceId)` to decide whether a form instance was already applied.

That identity is code-derived, unlike every other operation, which persists on the workflow-supplied `requestId` and therefore inherits whatever prefix the workflow set (`sod-remediation:{violationId}`; `access-model-sod-remediation` extended by `childPersistIdentity` to `{requestId}:{accessItemId}:{policyId}`). The result source consequently mixes named rows with bare UUID rows.

Separately, `buildDescriptionAuditLine` opens the appended catalog line with `[SOD remediation {timestamp}]`, a label no command owns — apply is its only writer, yet it reads as `custom:sod-remediation`.

Constraints: the persist identity must stay stable across retries with different `requestId` values (that is why it is keyed on the form instance, not the request), accounts already written under the bare identity exist in live tenants, and the framework truncates persist identities at 128 characters.

## Goals / Non-Goals

**Goals:**

- Apply's result-source account identity names its writing command: `access-model-sod-remediation-apply:{formInstanceId}`.
- Prior-apply idempotency keeps working for form instances applied under the old identity, with no redundant PATCH and no duplicate audit line.
- A corrected catalog item's description names the command that mutated it.

**Non-Goals:**

- Framework-level auto-prefixing of persist identities for `requestId`-keyed operations.
- Backfilling, rewriting, or deleting legacy bare-identity accounts.
- Changing apply inputs, correction semantics, persist attribute keys, offline fixture keys, or the in-flight dedupe key.
- Aligning the framework's automatic failure-persist identity, which uses the workflow `requestId` (`access-model-sod-remediation-apply-{formInstanceId}`) and already carries the slug.

## Decisions

### D1: Derive the identity in the handler, not from workflow `requestId`

- **Choice**: Build `access-model-sod-remediation-apply:{formInstanceId}` in code and keep passing it to `ctx.persist`.
- **Reason**: Idempotency depends on the identity being a pure function of the form instance; a workflow-supplied value can differ between the original invoke and a retry.
- **Considered alternatives**: Persist on `ctx.requestId` and require workflows to set `access-model-sod-remediation-apply:{{formInstanceId}}` — rejected, it makes correctness depend on an operator-typed string. Framework-wide identity prefixing — rejected, workflows read `requestId`-keyed accounts back by the value they passed, so prefixing would break those steps.

### D2: One exported identity builder, used by both the writer and the reader

- **Choice**: Add `applyPersistIdentity(formInstanceId)` to the apply operation folder and call it from `index.ts` and `prior-apply-status.ts`, mirroring `childPersistIdentity` in the scan operation's `constants.ts`.
- **Reason**: The write path and the idempotency read path must not be able to drift.
- **Considered alternatives**: Inline template literals at all three call sites — rejected, a silent mismatch there means duplicate catalog PATCHes.

### D3: Prefixed-first, legacy-fallback lookup

- **Choice**: `readPriorTerminalApplyOutputs` looks up the prefixed identity; only when that returns no account does it look up the bare `{formInstanceId}`. Terminal-status and field-shape validation are identical for both.
- **Reason**: Preserves idempotency across the rename while keeping the prefixed identity authoritative.
- **Considered alternatives**: Legacy-first — rejected, it would keep reading stale rows after the account moved forward. Clean break — rejected, previously applied instances would be re-PATCHed and gain a second audit line.

### D4: Legacy accounts migrate forward implicitly, never explicitly

- **Choice**: When the fallback hits a legacy account, the existing replay path persists the returned outputs — now under the prefixed identity — leaving the bare row untouched.
- **Reason**: Gets tenants onto the new identity through normal traffic with no migration script and no destructive account delete.
- **Considered alternatives**: Migration script over the result source — rejected as disproportionate for a low-cardinality source. Deleting the legacy row after replay — rejected, it destroys audit history for no benefit.

### D5: Audit label is the command slug

- **Choice**: `[access-model-sod-remediation-apply {timestamp}]`, with the rest of the line (policy, side, detached profiles, removed entitlements, form instance id, submitter, comments) unchanged.
- **Reason**: Reuses the identifier that already namespaces the operation's persist keys and account identity, so one slug identifies the writer everywhere; a future identity-side corrector carries its own slug without ambiguity.
- **Considered alternatives**: Keep `SOD remediation` and add a suffix — rejected, still collides with `custom:sod-remediation`. A human-facing label such as `Access Model SOD Remediation Apply` — rejected, diverges from the slug used in persist keys and logs.

## Risks / Trade-offs

- [Risk] A previously applied form instance is re-submitted while the legacy fallback is missing or wrong, producing a second catalog PATCH and a duplicate audit line -> Mitigation: fallback is covered by a dedicated test asserting `skipped-already-applied` with zero PATCH calls when only a legacy account exists.
- [Risk] Operators or ad-hoc scripts reading apply results by bare form instance id silently find nothing -> Mitigation: breaking CHANGELOG entry plus README persist-key and workflow tables updated to the prefixed identity.
- [Trade-off] One extra `findAccountOnSource` call on invokes with no prefixed account -> Accepted: it only fires on the miss path, and it is the same lookup shape already used per invoke.
- [Trade-off] Two rows can describe the same form instance during the transition -> Accepted: the prefixed row is authoritative and the legacy row is read-only.
- [Note] Identity length stays well inside the framework's 128-character limit (35-character prefix plus a 36-character form instance UUID).

## Migration Plan

No deployment sequencing beyond the normal connector version upload. The prefixed identity takes effect on the next invoke; previously applied instances stay deduped via the legacy fallback and move to the prefixed identity when they are next invoked. Rollback is reverting the connector version — legacy accounts were never mutated, and prefixed accounts written in the interim are simply ignored by the older code, which falls back to its own bare-identity lookup.

Acceptance: `npm run typecheck` and `npm test` pass; a connected or offline apply invoke persists `access-model-sod-remediation-apply:{formInstanceId}`; an invoke whose only prior account is bare returns `skipped-already-applied` without a catalog PATCH; the appended description line starts with `[access-model-sod-remediation-apply`.

## Open Questions

None.
