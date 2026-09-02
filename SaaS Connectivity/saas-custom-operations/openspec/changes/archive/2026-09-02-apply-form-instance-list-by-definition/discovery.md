## Scope

**In:** Change `custom:access-model-sod-remediation-apply` so it loads the completed form instance by listing tenant instances for a required `formDefinitionId` (paginated), then picking the row whose id equals `formInstanceId`. Stop using `getFormInstanceByKeyV1` on the apply path. Update the bundled Remediation workflow binding.

**Out:** Catalog correction semantics, persist identity `{formInstanceId}`, idempotency / in-flight dedupe, other operations, and removing `getFormInstanceById` from the forms module for non-apply callers.

## Language

**form definition id** (`promote`):
The ISC Custom Forms identifier of the form definition that spawned the instance (`formDefinitionId`). Required apply input used as the only supported list filter.
_Avoid_: formId (user shorthand), form name

**tenant form instance list** (`draft`):
The Custom Forms collection returned by `searchFormInstancesByTenantV1`, optionally filtered to one form definition. Rows include `formInput`, `formData`, `state`, and `recipients`.
_Avoid_: get form instance, form instance search (when meaning get-by-id)

**recipient-scoped form instance get** (`draft`):
The Custom Forms get-by-id call (`getFormInstanceByKeyV1`). ISC allows only the assigned recipient identity.
_Avoid_: form instance fetch (ambiguous)

**Access model SoD remediation apply** (`conflicts-with-canonical`):
Canonical notes say input is `formInstanceId` only. After this change, required inputs are `formInstanceId` and `formDefinitionId`; persist identity stays `{formInstanceId}`.
_Avoid_: apply-by-id-only

## Decisions

**Context:** Loopback PAT is not the form recipient, so get-by-id fails. List-by-definition returns full instance payloads and is the supported operator-style read.

**Q1 — How does apply identify which instance to apply?**
→ Keep required `formInstanceId`. Add required `formDefinitionId` to bound the list. Do not pass `formInput` / `formData` from the workflow.

**Q2 — Input field name?**
→ `formDefinitionId` (ISC + form-submitted trigger). Not `formId`.

**Q3 — Fetch strategy?**
→ Paginated `searchFormInstancesByTenantV1` with `filters: formDefinitionId eq "<id>"`. Match `id === formInstanceId`. Early-exit when found. Do not call get-by-id as fallback.

**Q4 — Pagination?**
→ Offset/limit pages of 250, same as other ISC list helpers. Fail with `ConnectorError` if the instance is not found after the last page.

**Q5 — Idempotency order?**
→ Prior terminal persist lookup on `{formInstanceId}` still runs first; skip listing when already applied.

**Q6 — Keep `getFormInstanceById`?**
→ Leave the helper in `src/isc/forms/` for other callers. Apply must not use it.

**Q7 — Offline?**
→ Fixtures stay keyed by `formInstanceId`. `formDefinitionId` is required on the signature; offline may ignore it after trim/presence check.

## Open questions

None — scope locked in explore; field name and list-and-pick path decided.

## Scenarios discussed

- **Happy path:** Form-submitted workflow supplies both ids; instance is on page 1; parse and PATCH as today.
- **Instance on a later page:** First pages have other instances of the same definition; apply continues until the matching id.
- **Missing instance:** All pages exhausted → validation error; no catalog PATCH.
- **Get-by-id would 403:** List path still succeeds for a PAT that can list tenant instances.
- **Already applied:** Persist hit → `skipped-already-applied` without listing.
- **Incomplete instance:** Found but not `COMPLETED` → existing parse validation; no PATCH.
- **Workflow migration:** Bundled export binds `{{$.trigger.formDefinitionId}}` and `{{$.trigger.formInstanceId}}`.
- **Offline invoke:** Canned instance by `formInstanceId`; no live list call.
