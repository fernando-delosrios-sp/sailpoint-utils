# Proposal: Account schema attribute value limits

## Why

ISC caps account attribute storage by type. Declared STRING text fields are limited to 256 characters per ISC Security Characteristics, and identity values (account name / nativeIdentity) fail aggregation beyond 128 characters (documented in the MS Entra FAQ as "Data too long for column name"). Custom operations persist typed output to DelimitedFile result sources via `ctx.persist`; today the framework stores string values unchanged, so oversized identities or HTML summaries can cause provisioning failures or silent aggregation breakage. Enforcing ISC limits at persist time prevents hard failures while preserving as much data as possible.

## What Changes

**Identity value cap (128 characters)**
- From: Persist identity (`id` argument) stored verbatim as account identity attribute
- To: Identity truncated to 128 characters before account create/upsert, with console warning when truncated
- Reason: ISC aggregation rejects longer identity/name values
- Impact: Non-breaking for identities already under 128 chars; long identities lose suffix data

**STRING attribute value cap (256 characters)**
- From: STRING values (including JSON-serialized objects) stored without length enforcement
- To: STRING values truncated to 256 characters per value (including each element of STRING arrays), with console warning when truncated
- Reason: ISC declared text field limit on account schema attributes
- Impact: Non-breaking for values already under 256 chars; large fields (e.g. HTML summaries) stored truncated

**Central limit constants**
- From: No documented or shared ISC storage limits in code
- To: Exported constants and helper in framework module for limits and truncation
- Reason: Single source of truth for tests, persist formatting, and future callers
- Impact: Internal only

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `custom-operation-framework`: Extend result persistence helper to enforce ISC identity (128) and STRING attribute (256) value limits with warn-and-truncate behavior.

## Impact

- **Code:** `src/framework/persist-result.ts` (`formatAttributeValue`, `buildAccountAttributes`); new `src/framework/attribute-limits.ts`; exports from `src/framework/index.ts`
- **Tests:** `persist-result.spec.ts` and new `attribute-limits.spec.ts` covering identity cap, STRING cap, array elements, and no-op when within limits
- **Operations:** All custom operations using `ctx.persist` inherit limits automatically (including SOD remediation HTML fields)
- **Docs:** README note under result persistence describing truncation behavior and ISC limits
- **APIs:** No connector-spec.json or manifest changes
