# Brainstorm: Form definition version watermark

## Problem

`ensureFormDefinitionByName` reuses any existing tenant form definition by name without checking whether its structure matches the bundled seed. After connector upgrades that change seed JSON (new form elements, DESCRIPTION columns, hidden keys), tenants keep stale definitions and see outdated forms until an admin manually deletes and recreates them.

## Current state

- Seed loader builds create payload with `description` from seed or caller override (`seed-loader.ts`).
- SOD seed already sets a human-readable `description` string.
- `ensureFormDefinitionByName` returns existing id from search; never reads description or patches.
- ISC Custom Forms API exposes `getFormDefinitionByKeyV1`, `patchFormDefinitionV1`, and `deleteFormDefinitionV1`.

## Q1: Where to store the version marker?

**Decision:** Form definition top-level `description` field — first line is machine-readable watermark; remaining lines preserve human/admin context.

**Alternatives considered:**
- Hidden formInput key — rejected: not present on definition, only instances.
- Form name suffix — rejected: breaks stable `{formName}` contract.
- Separate tenant config — rejected: operational burden.

## Q2: Watermark format — semver vs content hash?

**Decision:** Content fingerprint — SHA-256 (hex, lowercase) of canonical JSON for seed structural fields (`formInput`, `formElements`, `formConditions`), sorted keys, no whitespace variance.

**Rationale:** Hash tracks actual seed output; no manual version bumps when seed edits land. Code owns fingerprint computation; seed JSON does not embed the hash (avoids circular edit).

**Prefix format:** `@form-seed-sha256:<64-hex>`

**Example description:**
```
@form-seed-sha256:a1b2c3...
SOD violation remediation — launch form for corrective removal or compensating control mitigation.
```

**Alternatives considered:**
- Semver in code constant — rejected: easy to forget bump when seed changes.
- Hash entire seed file including human description — rejected: cosmetic description edits would force recreate.

## Q3: Stale definition behavior?

**Decision:** Auto-refresh via `patchFormDefinitionV1` when watermark mismatches; reuse id when watermark matches.

**Flow:**
1. Search by name → if missing, create with watermarked description + template body.
2. If found → `getFormDefinitionByKeyV1` → parse watermark from description.
3. Match → return existing id.
4. Mismatch → patch full template (including updated description watermark and seed body fields).

**Alternatives considered:**
- Fail with ConnectorError instructing manual delete — rejected: poor operator UX after upgrades.
- Delete + create — rejected: new id may break external references; patch preserves id.
- Ignore stale (status quo) — rejected: defeats purpose.

## Q4: Scope — generic forms module vs SOD-only?

**Decision:** Generic in `src/isc/forms/`; all operations using `ensureFormDefinitionByName` + `buildCreateFormDefinitionPayload` benefit. SOD remediation is first consumer; no SOD-specific watermark logic.

## Q5: Backward compatibility for definitions without watermark?

**Decision:** Treat missing or unparsable watermark as stale → patch on next ensure invoke.

**Migration:** First post-upgrade launch refreshes tenant definitions automatically; no manual delete required.

## Q6: Search response sufficient for watermark check?

**Decision:** No — search results may omit or truncate fields. Always fetch by id via `getFormDefinitionByKeyV1` before compare.

## Trade-offs

- Patch API JSON-patch semantics need validation in tests (risk: partial patch failure).
- Human admins editing description in ISC UI could strip watermark → next launch triggers refresh (acceptable).
- Fingerprint changes on any structural seed edit → intentional refresh on upgrade.

## Out of scope

- Versioning form *instances*
- Tracking connector package semver separately from seed hash
- Import/export bulk form migration tooling
