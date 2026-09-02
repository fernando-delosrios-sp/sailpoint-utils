## Scope

**In:** Replace required apply input `formDefinitionId` with `formName` so `custom:access-model-sod-remediation-apply` uses the same tenant form definition name as `custom:access-model-sod-remediation`. Resolve name to a definition id (lookup only), then keep the existing paginated tenant instance list-and-pick by that id. Update bundled Remediation workflow invoke, payloads, READMEs, and glossary notes.

**Out:** Catalog correction semantics, persist identity `{formInstanceId}`, idempotency / in-flight dedupe, form-submitted trigger filter UUID (still tenant-specific), `ensureFormDefinitionByName` create/patch on the apply path, and dual-support for `formDefinitionId`.

## Language

**form name** (`promote`):
The tenant-visible Custom Forms definition name (`formName`) shared by the access-model scan (ensure-from-seed) and apply (lookup). Same string selects the same definition.
_Avoid_: formDefinitionId as apply input, formId, display name (ambiguous)

**form definition id** (`conflicts-with-canonical`):
Canonical text still treats `formDefinitionId` as a required apply input. After this change it remains the ISC list filter (internal), not an invoke field.
_Avoid_: requiring operators to pass the UUID on apply invoke

**form definition lookup-by-name** (`draft`):
Search for an existing form definition by exact `name` and return its id. Does not create or patch the definition.
_Avoid_: ensure-from-seed, ensureFormDefinitionByName (apply path)

**Access model SoD remediation apply** (`conflicts-with-canonical`):
Canonical notes say required inputs are `formInstanceId` and `formDefinitionId`. After this change: `formInstanceId` and `formName`; persist identity stays `{formInstanceId}`.
_Avoid_: apply-by-definition-id

## Decisions

**Context:** Scan already takes `formName`. Apply currently takes `formDefinitionId` from the form-submitted trigger, so operators must bind a UUID that can drift from the scan's named definition. Alignment means both commands use the same name string.

**Q1 — Replace vs keep both?**
→ Replace. Required `formName`; drop `formDefinitionId` from apply input. Breaking, no compatibility shim.

**Q2 — Ensure or lookup?**
→ Lookup only (`searchFormDefinitionsByTenantV1` by `name eq`). Apply MUST NOT call `ensureFormDefinitionByName` (no create/patch). Missing name or missing definition → `ConnectorError`; no catalog PATCH.

**Q3 — How is the instance still found?**
→ After resolving name → definition id, reuse existing list-and-pick (`searchFormInstancesByTenantV1` with `formDefinitionId eq`). Still no `getFormInstanceByKeyV1` on apply.

**Q4 — Workflow binding?**
→ Bundled Remediation invoke passes a static `formName` matching Analysis (`Access Model SOD Remediation`), plus `formInstanceId` from `{{$.trigger.formInstanceId}}`. Trigger filter stays a tenant form definition UUID (import note unchanged).

**Q5 — Idempotency order?**
→ Prior terminal persist on `{formInstanceId}` still first; skip both definition lookup and instance list when already applied.

**Q6 — Offline?**
→ Fixtures stay keyed by `formInstanceId`. `formName` is required (trim/presence); offline ignores it after that check and does not search definitions.

**Q7 — Other operations?**
→ `custom:sod-remediation` already uses `formName`; unchanged. Apply-only contract change.

## Open questions

None — replace vs both, lookup vs ensure, and workflow static name decided.

## Scenarios discussed

- **Happy path:** Workflow passes `formName` matching scan; lookup returns `fd-1`; list picks `fi-1`; PATCH as today.
- **Name not found:** Definition search empty → validation error; no instance list; no PATCH.
- **Blank formName:** Required-field validation; no ISC forms calls.
- **Instance on a later page:** Unchanged after id resolution.
- **Missing instance:** Unchanged after id resolution.
- **Already applied:** Persist hit → `skipped-already-applied` without lookup or list.
- **Wrong name vs trigger form:** Lookup of a different definition lists the wrong instance set; missing `formInstanceId` fails as today (operators must use the same `formName` as scan).
- **Offline invoke:** Canned instance by `formInstanceId`; non-empty `formName` required on payload.
- **Workflow migration:** Replace `{{$.trigger.formDefinitionId}}` with the same `formName` string as Analysis.
