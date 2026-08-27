# Brainstorm: sod-remediation-access-search

Raw capture from design exploration (Aug 2026).

## Background

SOD remediation forms pass hidden launch-populated keys through to submitted `formData` for downstream ISC workflows. Prior design used `groupARevokePayload` / `groupBRevokePayload` — JSON strings containing `items[]` and `recommendedRevoke` with revocability and keep metadata.

Live workflow authoring revealed ISC workflow steps cannot parse stringified JSON objects from form outputs. Workflow authors need plain string filters suitable for access-item list/search APIs.

## Agreed scope

**In scope:**
- Replace hidden revoke JSON payloads with per-side ISC access search strings
- Format: `id:{uuid} OR id:{uuid}` joining all resolved path item ids on each side
- Update bundled seed hidden fields and form conditions
- Update `assembleFormInput`, types, tests, README, and sod-remediation spec

**Out of scope:**
- Executing revokes in the connector (still workflow responsibility)
- Exposing internal `recommendedRevoke` to form submission
- Workflow reference implementation in this repo

## Decision chain

### Q1: Replace or supplement revoke payloads?
**Decision:** Replace. Workflows cannot consume JSON strings; adding search strings alongside payloads leaves dead weight and confuses authors.

### Q2: What goes in the search string?
**Decision:** All resolved access path item ids on the side (entitlements + expanded access profiles/roles). Workflows use the filter to fetch/display access items; revocability context remains in owner-facing HTML columns.

### Q3: Single vs multi-item format?
**Decision:** One item → `id:xxx`. Multiple → `id:a OR id:b OR id:c` (space-padded ` OR `).

### Q4: Keep internal revokePayload struct?
**Decision:** Yes, for resolver logic, enrichment, and launch logging only — not serialized to form submission.

### Q5: Field names?
**Decision:** `groupAAccessSearch` / `groupBAccessSearch` (matches `groupAContentsHtml` naming pattern).

### Q6: Form definition migration?
**Decision:** Rely on existing form-definition version watermark to patch tenant definitions on next launch.

## Approaches considered

| Approach | Trade-off |
|----------|-----------|
| Keep JSON payloads; workflow script parses | Rejected — poor DX, not viable in no-code flows |
| Search string + minimal `recommendedRevokeId` | Rejected — still loses revocability metadata workflows might need later; HTML already covers owner review |
| Search strings alongside payloads | Rejected — redundant; user chose drop |

## Acceptance criteria

- `npm test` passes
- Seed exposes `groupAAccessSearch` / `groupBAccessSearch` hidden keys
- Submitted formData no longer includes revoke payload keys
- CHANGELOG notes breaking change for downstream workflows
