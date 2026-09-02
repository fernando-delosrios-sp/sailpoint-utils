## Why

`custom:access-model-sod-remediation-apply` loads the submitted form via get-by-id. ISC allows that call only for the assigned recipient, so loopback tokens fail. Tenant list filtered by form definition returns the same instance payload and is allowed for operators. Apply must take `formDefinitionId` plus `formInstanceId` so it can list, paginate, and pick the completed instance.

## What Changes

**Apply form instance load**
- From: Required input `formInstanceId` only; handler calls `getFormInstanceByKeyV1`
- To: Required `formInstanceId` and `formDefinitionId`; handler lists instances for that definition (paginated) and picks the matching id. No get-by-id on the apply path
- Reason: Get-by-id is recipient-scoped; list-by-definition is not
- Impact: **Breaking** invoke contract for workflows and local payloads; persist key unchanged

**Workflow binding**
- From: Bundled Remediation workflow passes `formInstanceId` from the form-submitted trigger
- To: Also pass `formDefinitionId` from `{{$.trigger.formDefinitionId}}`
- Reason: List API filter is definition id only
- Impact: Operators must update the Custom Command step after upgrade

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation-apply`: Required `formDefinitionId`; list-and-pick fetch; pagination; missing-instance failure; still no workflow pass-through of `formInput` / `formData`
- `connector-operations/access-model-sod-remediation`: Form-submit downstream invoke includes `formDefinitionId`
- `target-client/forms`: Paginated list-by-definition helper that returns a normalized instance by id
- `ubiquitous-language`: Promote **form definition id**; update **Access model SoD remediation apply** notes

## Impact

- **Code:** Apply `OperationSignature` + handler; `src/isc/forms/` list helper; tests; offline payload; operation README
- **Workflows:** `workflows/Access Model SOD - Remediation.json` invoke body
- **Docs:** CHANGELOG; scan README if it still says apply takes `formInstanceId` only
- **ISC:** `searchFormInstancesByTenantV1` with `formDefinitionId eq`; keep-alive already covers long page walks
- **Out of scope:** Correction plan, catalog PATCH, persist identity, in-flight dedupe, deleting `getFormInstanceById`
