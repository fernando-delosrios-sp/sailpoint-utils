## Why

Every custom operation writes a result-source account whose identity names the operation, because that identity comes from a workflow-supplied `requestId`. `custom:access-model-sod-remediation-apply` is the exception: it keys persist on the raw form instance id, so its rows show up in the result source as bare UUIDs with no indication of which command wrote them, next to `sod-remediation:…` and `access-model-sod-remediation:…` siblings. The audit line apply appends to corrected catalog items has the same problem — it opens with `[SOD remediation …]`, which reads as `custom:sod-remediation` output. Operators triaging a result source or a role description today cannot tell which operation produced either artifact.

## What Changes

**Apply persist identity**
- From: Outputs persist on result-source identity `{formInstanceId}`
- To: Outputs persist on `access-model-sod-remediation-apply:{formInstanceId}`
- Reason: Make the account identity name its writing command, matching every other operation's account
- Impact: **Breaking** for anyone reading apply results by account identity; the bundled Remediation workflow has no Get Accounts step, so no workflow JSON change

**Prior-apply idempotency lookup**
- From: Prior terminal apply is read from the account at `{formInstanceId}`
- To: Read the prefixed identity first, then fall back to the bare legacy identity
- Reason: Without the fallback, form instances applied before this change read as unapplied and get a redundant catalog PATCH plus a second audit line
- Impact: Non-breaking; one extra account lookup only when the prefixed identity misses

**Description audit line label**
- From: `[SOD remediation {timestamp}] Policy …`
- To: `[access-model-sod-remediation-apply {timestamp}] Policy …`
- Reason: A catalog description should name the command that mutated the item, and not read as identity SoD remediation output
- Impact: **Breaking** for anything parsing the label; line body, persisted `description-appended` attribute, and append-not-replace behavior unchanged

Legacy bare accounts are neither backfilled nor deleted — the replay path persists them forward under the prefixed identity on next invoke.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `connector-operations/access-model-sod-remediation-apply`: persist identity becomes `access-model-sod-remediation-apply:{formInstanceId}`; prior-apply check adds a legacy-identity fallback; description audit line is labeled with the command slug
- `ubiquitous-language`: promote **apply persist identity** and **description audit line**; correct the **access model SoD remediation apply** note that pins persist identity to `{formInstanceId}`

## Impact

- **Code:** `src/operations/access-model-sod-remediation-apply/index.ts` (both persist calls), `prior-apply-status.ts` (prefixed lookup plus legacy fallback), `description-audit.ts` (label)
- **Tests:** `index.spec.ts`, `prior-apply-status` coverage, `description-audit.spec.ts`
- **Docs:** apply `README.md` (persist key, idempotency, workflow tables), `CHANGELOG.md` breaking entry
- **ISC:** One additional `findAccountOnSource` call per invoke only when no prefixed account exists; no new API surface
- **Unaffected:** `custom:sod-remediation` and `custom:access-model-sod-remediation` handlers, scan child identity, persist attribute keys, in-flight dedupe key, offline fixture keys, workflow JSON
