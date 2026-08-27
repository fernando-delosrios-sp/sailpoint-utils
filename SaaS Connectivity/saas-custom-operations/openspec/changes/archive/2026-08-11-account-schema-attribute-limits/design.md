## Context

Custom operations persist output to ISC DelimitedFile result sources. The framework formats values in `formatAttributeValue` and builds account payloads in `buildAccountAttributes`, using `id` as the identity attribute (nativeIdentity). ISC documents platform storage limits: 256 characters for declared STRING text fields (Security Characteristics) and 128 characters for identity/name values (MS Entra FAQ aggregation failure mode). Operations such as SOD remediation can produce multi-kilobyte HTML strings that exceed these limits today.

## Goals / Non-Goals

**Goals:**

- Enforce 128-character cap on persist identity before account create/upsert
- Enforce 256-character cap on each STRING value written to account attributes (including JSON-serialized objects and array elements)
- Log a clear warning when truncation occurs (attribute name or `identity`)
- Apply limits consistently in production and test mode
- Cover limits with unit tests mapped to spec scenarios

**Non-Goals:**

- Changing ISC schema attribute definitions via SourcesApi
- CSV delimiter/quote sanitization (separate from length)
- Compile-time validation of operation output field sizes
- Rejecting persist on overflow (truncate instead)

## Decisions

### D1: Truncate with warning vs reject

- **Choice:** Truncate and `console.warn` — persist succeeds with shortened values
- **Rationale:** Prevents total write failure when one field is oversized; aggregation reliability outweighs lossless storage for telemetry fields
- **Alternatives considered:** Throw `ConnectorError` — rejected as too disruptive for batch workflows

### D2: Limit constants and helper module

- **Choice:** `src/framework/attribute-limits.ts` exporting `ISC_IDENTITY_MAX_LENGTH` (128), `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256), and `truncateForIscStorage(value, maxLength, context?)`
- **Rationale:** Testable, documented constants; keeps `persist-result.ts` focused on orchestration
- **Alternatives considered:** Inline magic numbers in `formatScalarValue` — rejected for maintainability

### D3: Enforcement points

- **Choice:** Apply STRING cap inside `formatScalarValue` when `iscType === 'STRING'`; apply identity cap in `buildAccountAttributes` on the `id` field after reserved-key handling
- **Rationale:** All STRING paths (direct strings, coerced scalars, JSON.stringify results) flow through `formatScalarValue`; identity is set separately from author attributes
- **Alternatives considered:** Cap only in `upsertSourceAccount` — rejected; test mode registry and unit tests use `buildAccountAttributes` directly

### D4: Truncation algorithm

- **Choice:** `String(value).slice(0, maxLength)` with no suffix marker
- **Rationale:** Suffix could exceed limit or confuse verification; stored value equals expected truncated value
- **Alternatives considered:** Ellipsis suffix — rejected

### D5: Multi-value STRING arrays

- **Choice:** Truncate each array element independently at 256
- **Rationale:** ISC stores multi-value STRING attributes per element; each element is a text field

## Risks / Trade-offs

- [Risk] Truncated identity collisions for distinct long IDs sharing a prefix → Mitigation: requestId-style identities are typically well under 128; log warning surfaces truncation
- [Risk] Operators unaware of data loss → Mitigation: console warning includes attribute context and original length
- [Trade-off] Lossy storage for large HTML summaries → Accept: partial data better than failed persist/aggregation

## Migration Plan

N/A — runtime behavior change only. No schema migration, connector manifest change, or tenant action required. Existing accounts unaffected; new persists truncate when needed. Operators seeing truncation warnings may shorten upstream output or accept partial storage.

## Open Questions

_(none — limits and truncate policy provided by requester)_
