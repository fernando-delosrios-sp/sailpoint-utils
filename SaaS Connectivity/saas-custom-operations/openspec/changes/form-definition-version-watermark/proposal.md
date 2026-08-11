# Proposal: Form definition version watermark

## Why

Connector operations that ensure ISC form definitions by name currently reuse any existing definition regardless of whether it matches the bundled seed. After seed or layout changes ship in a connector upgrade, tenants silently keep outdated form definitions until an administrator manually deletes and recreates them. That causes missing fields, wrong element types, and support churn. We need an automatic, code-owned signal in the form definition `description` field so ensure logic can distinguish current definitions from stale ones and refresh when required.

## What Changes

**Form definition description watermark**
- From: Human-readable description only (or form name fallback); never compared on reuse.
- To: First line `@form-seed-sha256:<hex>` fingerprint of canonical seed structure, followed by optional human text; compared on every ensure.
- Reason: `description` is available on read and write APIs and is not shown to end users on the rendered form.
- Impact: Non-breaking for operation I/O; existing definitions refresh on first launch after upgrade.

**Ensure-by-name behavior**
- From: Search by name → return existing id without inspection; create only when absent; never patch.
- To: Search → fetch by id → compare watermark → reuse when match; patch full template when mismatch or watermark absent; create when absent.
- Reason: Eliminate manual recreate step documented in prior seed migrations.
- Impact: Modifies `target-client/forms` contract (previously forbade patch).

**Seed payload builder**
- From: Passes through seed or caller `description` unchanged.
- To: Computes fingerprint from seed structure and composes watermarked `description` automatically.
- Reason: Code maintains the hash; callers must not hand-maintain versions.

## Capabilities

### New Capabilities

_(none — behavior extends existing forms client)_

### Modified Capabilities

- `target-client/forms`: Add seed fingerprint and watermarked description requirements; change ensure-by-name to compare watermark and patch stale definitions.

## Impact

- **Code:** `src/isc/forms/seed-loader.ts`, `ensure-definition.ts`, `FormsApiLike`, unit tests in `forms.spec.ts`; SOD `form-service.ts` inherits via generic builder (no SOD-specific watermark logic).
- **APIs:** Uses `getFormDefinitionByKeyV1` and `patchFormDefinitionV1` in addition to existing search/create.
- **Operations:** SOD remediation and any future operation using ensure-by-name auto-refresh stale definitions on launch.
- **Tenant ops:** No manual delete/recreate for seed updates after this ships; first launch patches definition in place.
