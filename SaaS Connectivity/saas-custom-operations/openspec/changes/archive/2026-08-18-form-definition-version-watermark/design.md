# Design: Form definition version watermark

## Context

ISC custom operations create tenant form definitions from bundled JSON seeds via `ensureFormDefinitionByName`. The current contract reuses definitions by name only. Seed changes (element types, formInput keys, conditions) do not propagate until an admin deletes the old definition. Prior changes documented this as a one-time manual migration; operators want automatic detection and refresh.

ISC Custom Forms exposes search, get-by-id, create, and patch for form definitions. The top-level `description` field is readable and writable but is not rendered inside the standalone form UI.

## Goals / Non-Goals

**Goals:**

- Compute a deterministic fingerprint from seed structural content in code.
- Embed fingerprint as first line of form definition `description` using a parseable prefix.
- On ensure: reuse when fingerprint matches; patch when missing or mismatched; create when absent.
- Keep fingerprint logic generic in `src/isc/forms/` for all operations.

**Non-Goals:**

- Versioning form instances or workflow bindings.
- Semver or package-version watermarks separate from seed content.
- Patching definitions that were intentionally customized in ISC UI beyond description edits (we refresh to bundled seed regardless).
- Bulk import/export migration tooling.

## Decisions

### D1: Watermark location and format

- **选择:** First line of definition `description`: `@form-seed-sha256:<64-char-lowercase-hex>`, optional blank line, then human-readable text.
- **理由:** Field is on definition CRUD payloads; prefix is regex-parseable; human context preserved for admins.
- **已考虑 alternative:** Dedicated metadata API field — not available on create payload.

### D2: Fingerprint input scope

- **选择:** SHA-256 of canonical JSON object `{ formInput, formElements, formConditions }` with stable key ordering and no pretty-print whitespace.
- **理由:** Tracks structural seed output; excludes human `description` so copy edits do not force refresh.
- **已考虑 alternative:** Hash entire seed file — rejected; couples fingerprint to prose.

### D3: Stale definition refresh strategy

- **选择:** `patchFormDefinitionV1` with full template body (formInput, formElements, formConditions, description, owner unchanged on patch body as API allows).
- **理由:** Preserves definition id and workflow references; avoids delete/create race.
- **已考虑 alternative:** Delete + create — rejected; id churn. Fail with manual instructions — rejected; poor UX.

### D4: Watermark read path

- **选择:** After search hit, call `getFormDefinitionByKeyV1` and parse `description` first line.
- **理由:** Search results may not include complete description; get-by-id is authoritative.
- **已考虑 alternative:** Trust search payload — insufficient.

### D5: Missing or legacy watermark

- **选择:** Treat unparsable or absent watermark as stale → patch on next ensure.
- **理由:** One automatic migration path for all pre-watermark tenant definitions.

### D6: Public API surface

- **选择:** Extend `buildCreateFormDefinitionPayload` to accept optional human description suffix; add `computeFormSeedFingerprint(seed)` export; extend `FormsApiLike` with get + patch; evolve `ensureFormDefinitionByName` params unchanged except behavior.
- **理由:** Callers keep passing seed + name; watermark is internal.

## Risks / Trade-offs

- [Risk] Patch API rejects full-body updates or requires JSON Patch ops → Mitigation: spike in unit tests with mocked patch; fall back to delete+create only if patch proven unsupported (document in verify phase).
- [Risk] Admin edits description in ISC UI and removes watermark → Mitigation: next operation launch refreshes definition; acceptable self-healing.
- [Trade-off] Auto-patch overwrites tenant form customizations → Accepted: bundled seed is source of truth for connector-driven definitions.
- [Risk] Fingerprint instability across Node/crypto JSON serialization → Mitigation: explicit canonical stringify helper with sorted keys; golden-vector test from fixed seed fixture.

## Migration Plan

1. Ship connector with fingerprint + ensure logic.
2. On first `custom:sod-remediation` (or other) launch per tenant, existing definitions without watermark or with old hash are patched in place.
3. Rollback: revert connector version; stale definitions remain at last patched state (no automatic down-patch).
4. Acceptance: unit tests for fingerprint stability, parse, match reuse, mismatch patch, missing create; `npm test` green.

## Open Questions

- Confirm `patchFormDefinitionV1` accepts replacement of `formElements` / `formInput` arrays in one call (validate during apply spike; no blocker for planning).
