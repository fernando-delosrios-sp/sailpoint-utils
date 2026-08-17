## Why

Workflows that read custom operation outcomes via **Get Accounts** on the result source get no account when an operation fails. Failures today surface only on the invoke response as `{ status: 'failed', error }`, so teams must special-case failure routing instead of reading `accounts[0].attributes.status` and a stable message field. That breaks the documented invoke → persist → Get Accounts pattern and makes error handling inconsistent across operations. Adding a mandatory `details` attribute and automatic failed-account persist gives workflows one read path for both success and failure.

## What Changes

**Failed result account on every terminal failure**
- From: Failures send `{ status: 'failed', error }` on invoke response only; no result-source write.
- To: Framework upserts a result account for `requestId` with `status: failed` and `details` set to the error message on every terminal failure (throws, init errors, persist verification failures, handler `res.send({ status: 'failed', error })`).
- Reason: Workflows should read failures the same way they read success.
- Impact: Non-breaking for invoke response; additive account write. Same `requestId` may overwrite a prior success account on failure (expected).

**Mandatory `details` core schema attribute**
- From: Base schema core attributes are `id`, `status`, `date` plus operation output fields.
- To: Base schema includes mandatory STRING attribute `details`. On failure, framework MUST populate it with the normalized error message. On success, handlers MAY set informative text via persist.
- Reason: Single stable attribute for human-readable outcome text across all operations.
- Impact: Existing result sources gain `details` on next schema reconciliation persist.

**Invoke response unchanged**
- From/To: `{ status: 'failed', error }` remains on invoke response for backward compatibility.
- Impact: Non-breaking.

## Capabilities

### New Capabilities

_(none — behavior extends existing framework capability)_

### Modified Capabilities

- `custom-operation-framework`: Add `details` core attribute; automatic failed-account persist on all terminal failure paths; optional success `details` via persist
- `operation-test-runner`: Local invoke / inhibited-persist summaries reflect failed accounts with `details` when test mode inhibits writes

## Impact

- **Framework:** `base-account-schema.ts`, `persist-result.ts`, `with-custom-operation.ts`, `test-mode-persist.ts`, `result-source.ts` schema reconciliation
- **Tests:** `with-custom-operation.spec.ts`, `persist-result.spec.ts`, `base-account-schema.spec.ts`, `test-mode-persist.spec.ts`, `call-op` / payload output if applicable
- **Docs:** Root README framework/persist section; CHANGELOG
- **Workflows:** Bundled exports may optionally map `details` in read steps (not required for framework change)
