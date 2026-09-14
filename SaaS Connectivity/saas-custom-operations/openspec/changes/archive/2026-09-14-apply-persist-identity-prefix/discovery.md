## Scope

**In:** Namespace the `custom:access-model-sod-remediation-apply` result-source account identity as `access-model-sod-remediation-apply:{formInstanceId}` (was bare `{formInstanceId}`), keep prior-apply idempotency working across the rename via a read-only fallback to the legacy identity, and label the catalog description audit line with the writing command instead of the generic `SOD remediation`.

**Out:** Framework-level auto-prefixing of persist identities, `custom:sod-remediation` and `custom:access-model-sod-remediation` handler code, scan child identity shape, in-flight dedupe key, persist attribute keys (already namespaced), correction plan semantics, and backfill or deletion of legacy accounts.

## Language

**apply persist identity** (`promote`):
The result-source account identity holding `custom:access-model-sod-remediation-apply` outputs: `access-model-sod-remediation-apply:{formInstanceId}`. Same value the prior-apply idempotency check reads.
_Avoid_: bare `{formInstanceId}` as the persist identity, `formInstanceId`-keyed account

**legacy apply persist identity** (`draft`):
A bare `{formInstanceId}` account written by apply before this change. Read-only input to the prior-apply check; never written again, never deleted.
_Avoid_: migration account, backfilled identity

**Access model SoD remediation apply** (`conflicts-with-canonical`):
Canonical notes state persist identity is `{formInstanceId}`. After this change the persist identity is `access-model-sod-remediation-apply:{formInstanceId}`; required inputs (`formInstanceId`, `formName`) are unchanged.
_Avoid_: persist identity remains `{formInstanceId}`

**description audit line** (`promote`):
The single line appended to a corrected role or access profile description by apply, opening with the writing command and timestamp: `[access-model-sod-remediation-apply {timestamp}]`.
_Avoid_: `[SOD remediation {timestamp}]` (does not identify the writing operation)

## Decisions

**Context:** Every other custom operation writes a result-source account whose identity carries the operation slug, because the identity comes from a workflow-supplied `requestId` (`sod-remediation:{violationId}`, `access-model-sod-remediation` extended to `{requestId}:{accessItemId}:{policyId}`). Apply is the only operation that derives its persist identity from a non-`requestId` source — the form instance id — so its account appears in the source as a bare UUID with no indication of which command wrote it. The same ambiguity exists in the catalog: the appended description line opens with `[SOD remediation …]`, which reads as `custom:sod-remediation` even though only apply writes it.

**Q1 — Prefix via workflow `requestId` or in the handler?**
→ In the handler. The bundled Remediation workflow already passes `requestId: access-model-sod-remediation-apply-{{formInstanceId}}`, but apply deliberately keys persist on `formInstanceId` for idempotency across retries with different request ids. Deriving the identity in code keeps idempotency intact and removes the dependency on operator-supplied strings.

**Q2 — Identity format?**
→ `access-model-sod-remediation-apply:{formInstanceId}` — the command slug plus colon, matching the persist attribute prefix and the colon-separated identities the other operations produce.

**Q3 — Framework-level auto-prefixing instead?**
→ Rejected as out of scope. For `requestId`-keyed operations the identity is workflow-owned (workflows read accounts back by the `requestId` they passed), so a framework prefix would silently break those read-back steps. Apply is the only operation whose identity is code-derived.

**Q4 — Prior-apply idempotency across the rename?**
→ Look up the prefixed identity first, then fall back to the bare legacy identity. Without the fallback, every form instance applied before this change reads as unapplied and gets a redundant PATCH plus a second appended audit line.

**Q5 — Migrate legacy accounts?**
→ No backfill and no delete. When the fallback hits a legacy account, the existing replay path persists the same outputs under the prefixed identity, so the account moves forward naturally on next invoke and the stale bare row is simply ignored from then on.

**Q6 — Audit line label?**
→ `[access-model-sod-remediation-apply {timestamp}]`. Reusing the command slug means a catalog description names its writer, and a future identity-side corrector would carry its own slug.

**Q7 — Does `custom:sod-remediation` change?**
→ No code change. Its account is already `sod-remediation:{violationId}` via the bundled workflow's Request ID variable. It is affected only by the audit-label decision, which stops apply's description lines from reading as identity SoD remediation output.

**Q8 — Offline fixtures and in-flight dedupe?**
→ Both stay keyed on `formInstanceId`. The offline fixture map key and the framework dedupe key (`{commandType}:{formInstanceId}`) are not account identities.

## Open questions

None — identity format, fallback behavior, and audit label decided.

## Scenarios discussed

- **Fresh apply:** Persists `access-model-sod-remediation-apply:fi-1`; no bare `fi-1` account written.
- **Re-invoke after this change:** Prior-apply check hits the prefixed identity, returns `skipped-already-applied`, no PATCH.
- **Re-invoke of an instance applied before this change:** Prefixed lookup misses, legacy bare lookup hits, returns `skipped-already-applied` with no PATCH and no second audit line; replay persists under the prefixed identity.
- **Both identities present:** Prefixed account wins; legacy row ignored without error.
- **Legacy account with non-terminal status:** Treated as no prior apply, same as today.
- **Description audit:** Appended line starts with `[access-model-sod-remediation-apply` and still carries policy, side, detached profiles, removed entitlements, form instance id, submitter, and comments.
- **Persisted audit attribute:** `access-model-sod-remediation-apply:description-appended` holds the relabeled line, and the prior-apply replay reads it back unchanged.
- **Offline invoke:** Fixture lookup by `formInstanceId` unchanged; persist lands on the prefixed identity when persist is enabled.
- **Workflow read-back:** Bundled `Access Model SOD - Remediation` workflow has no Get Accounts step, so no workflow JSON edit; operators reading accounts manually need the new identity documented.
