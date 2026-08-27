# Brainstorm: Account schema attribute value limits

## Problem

ISC enforces hard storage limits on account attribute values. Exceeding them causes aggregation failures (for example MS Entra FAQ documents `"Data too long for column name"` when identity/name exceeds 128 characters) or DelimitedFile provisioning/verification failures when declared STRING text fields exceed 256 characters. The framework currently passes string values through unchanged in `formatAttributeValue` and does not cap the persist identity (`id` / nativeIdentity).

## Current state

- `formatAttributeValue` / `formatScalarValue` in `persist-result.ts` store strings as-is; objects JSON-serialize to STRING without length check.
- `buildAccountAttributes` sets `id` from the persist identity argument with no cap.
- Result source account schema uses `identityAttribute: id`; lookup uses `nativeIdentity` filters in `find-account.ts`.
- SOD remediation and other operations can persist large HTML summaries that exceed ISC STRING limits.

## Q1: Truncate vs reject on overflow?

**Decision:** Truncate with a console warning — do not throw `ConnectorError`.

**Rationale:** Failing persist loses the entire write; partial data plus successful aggregation is preferable for result-source telemetry. Matches existing warn-only posture for schema type conflicts.

**Alternatives considered:**
- Reject with `ConnectorError` — rejected: breaks long-running workflows when one field is oversized.
- Silent truncate — rejected: operators need a log signal to diagnose data loss.

## Q2: Which limits apply where?

**Decision:**

| Value kind | Max length | Source |
|---|---|---|
| Persist identity (`id` / nativeIdentity) | 128 | MS Entra FAQ — aggregation fails beyond this |
| STRING attribute values (including JSON-serialized objects) | 256 | ISC Security Characteristics — declared text fields |
| Non-string types (INT, BOOLEAN, LONG, DATE) | N/A | Not text-field capped |
| Multi-value STRING arrays | 256 per element | Same STRING rule |

**Note:** Framework-managed `status` is STRING and subject to 256. `date` ISO strings are well under limits.

## Q3: Where to enforce?

**Decision:** New `attribute-limits.ts` module with exported constants (`ISC_IDENTITY_MAX_LENGTH = 128`, `ISC_STRING_ATTRIBUTE_MAX_LENGTH = 256`) and `truncateForIscStorage(value, maxLength, context?)`. Apply from `formatScalarValue` when `iscType === 'STRING'` and from `buildAccountAttributes` for the identity `id`.

**Alternatives considered:**
- Inline in `persist-result.ts` only — rejected: constants should be reusable and testable in isolation.
- Enforce at AccountsApi client layer — rejected: formatting is a framework persist concern, not generic ISC client policy.

## Q4: Truncation strategy?

**Decision:** Hard truncate at max length (no ellipsis suffix). Log `[persist] truncated <context> from <n> to <max> chars`.

**Rationale:** Suffixes could still exceed limits or break verification expectations; operators compare truncated stored value to truncated expected value.

## Q5: Test mode behavior?

**Decision:** Apply the same limits in test mode so the write registry and console logs reflect production-shaped values.

## Q6: Schema definition metadata?

**Decision:** Out of scope — this change governs **persisted attribute values**, not SourcesApi schema attribute definition objects.

## Trade-offs

- Truncation is lossy — callers cannot recover full text from ISC after persist.
- Identity truncation could theoretically collide if two distinct long IDs share the same 128-char prefix (unlikely for requestId-style identities).
- Verification compares truncated expected vs read-back — consistent, but operators must read truncation warnings to understand mismatches with upstream data.

## Out of scope

- Raising ISC platform limits
- Validating operation output types at compile time
- Changing connector-spec.json accountSchema (custom ops connector has no static account schema)
- CSV escaping / comma-in-value handling (separate concern)
