## Why

Scan and apply currently identify the same Custom Form with different inputs: `formName` vs a UUID from the form-submitted trigger. Operators must keep the workflow UUID in sync with whatever definition the scan ensured. Passing `formName` on apply lets Analysis and Remediation share one string, and the connector resolves the list filter internally.

## What Changes

**Apply invoke input**
- From: Required `formInstanceId` and `formDefinitionId`
- To: Required `formInstanceId` and `formName`; no `formDefinitionId` on the command
- Reason: Same name as `custom:access-model-sod-remediation`
- Impact: **Breaking** for existing workflows and local payloads

**Definition resolution**
- From: Caller supplies the definition UUID used as the instance-list filter
- To: Apply looks up an existing definition by `formName`, then list-and-pick by that id. Lookup does not create or patch the definition
- Reason: Apply must not mutate form seeds; scan already ensures the definition
- Impact: Missing name fails before listing; operators must use the scan `formName`

**Workflow binding**
- From: Remediation invoke uses `{{$.trigger.formDefinitionId}}`
- To: Static `formName` matching Analysis (`Access Model SOD Remediation`); `formInstanceId` still from the trigger
- Reason: Trigger UUID is tenant-specific; the name is the shared operator contract
- Impact: Form-submitted trigger filter UUID is unchanged (import note)

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation-apply`: Required `formName`; lookup-by-name then existing list-and-pick; skip lookup when already applied
- `connector-operations/access-model-sod-remediation`: Downstream apply invoke uses `formName`, not `formDefinitionId`
- `target-client/forms`: Lookup-by-name helper (search only; no ensure)
- `ubiquitous-language`: Promote **form name**; retarget **form definition id** and **Access model SoD remediation apply** notes

## Impact

- **Code:** Apply signature + handler; `src/isc/forms/` lookup helper; tests; offline payload
- **Workflows:** `workflows/Access Model SOD - Remediation.json` invoke body
- **Docs:** Apply and scan READMEs; CHANGELOG (breaking input)
- **ISC:** Extra `searchFormDefinitionsByTenantV1` before instance list (connected path only)
- **Out of scope:** Catalog PATCH, persist identity, trigger filter UUID, `ensureFormDefinitionByName` on apply, keeping `formDefinitionId` on the command
