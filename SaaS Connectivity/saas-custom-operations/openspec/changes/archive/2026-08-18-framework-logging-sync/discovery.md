## Scope

Unify custom-operation logging so every framework and operation log event uses one emit path: pretty multiline console output and optional `logUrl` JSON POSTs stay in sync. Migrate remaining direct `console.log` call sites in operations and incoming-request logging; add JSON-safe detail normalization. Out of scope: CLI/script output (`scripts/*`), connector-spec changes, new invoke config fields.

## Language

**log detail map** (`draft`):

A named key-value object passed as the second argument to `ctx.log.info|warn|error`. Values may be objects, arrays, or scalars. The framework serializes this map to the external log event `detail` field after redaction and JSON-safe normalization.

_Avoid_: `objects` (as a public API name — JSON field remains `detail`), `payload`, `metadata bag`

**JSON-safe detail normalization** (`draft`):

Framework step that removes or replaces values that cannot be encoded with `JSON.stringify` (functions, symbols, circular references, undefined property values) before console formatting and external POST.

_Avoid_: `sanitize` alone (collides with `sanitizeForLog` redaction)

**pretty console formatting** (`draft`):

Human-readable multiline stdout layout for log events: `[requestId]` headline, then one labeled block per detail key using Node `inspect` with depth and TTY colors.

_Avoid_: `boxed logging` as a schema term (box styling is an optional render mode for incoming request only)

**logUrl** (`promote`):

Already canonical in `openspec/specs/ubiquitous-language/spec.md`. No definition change; this change ensures all framework-routed logs reach it when configured.

## Decisions

**Context:** `config.logUrl` and `ctx.log` exist, but SOD operations and incoming-request logging still call `console.log` directly or use split redaction/formatting. Console output is a single cramped line; remote collectors miss operation step logs.

**Q1 — API shape for structured attachments?**  
Chosen: keep `info(message, detail?)` and document `detail` as a named map (scalars allowed). Example: `ctx.log.info('violation loaded', { violation, controls, count: 3 })`.

**Q2 — JSON field name?**  
Chosen: keep `detail` on `FrameworkLogEvent` (spec-compatible, no schema fork).

**Q3 — Machine-readable phase names (`step` field)?**  
Chosen: no framework `step` convention. Human `message` headline plus named detail keys (e.g. `violation`, `controls`) are sufficient.

**Q4 — Incoming request?**  
Chosen: same `message` + `detail` envelope and `sanitizeForLog` as all other logs. Console may use a prettier section layout; JSON POST matches the unified schema.

**Q5 — Truncation of large values?**  
Chosen: caller responsibility (operations truncate domain-specific fields before logging, as SOD already does for HTML previews).

**Q6 — Breaking API changes?**  
Chosen: evolve in place — same method signatures; behavior changes for console layout, redaction parity, and migration off raw `console.log`.

**Q7 — Unserializable detail values?**  
Chosen: omit keys that cannot be JSON-encoded; do not fail the invocation. Circular refs replaced with `"[Circular]"` string when the key would otherwise be dropped entirely.

**Q8 — TypeScript typing?**  
Chosen: public `FrameworkLogger` methods use `detail?: Record<string, unknown>`; internal emit accepts normalized output.

## Open questions

- None blocking proposal. Boxed ANSI section for incoming request console layout: keep as optional render mode (default in design).

## Scenarios discussed

- `logUrl` set: every `ctx.log` and incoming-request log POSTs one JSON event per call; POST failure is non-fatal.
- `logUrl` unset: console-only; behavior unchanged except prettier formatting.
- Detail with scalar keys (`count: 3`) and nested objects — both appear in console and JSON.
- Detail containing `token`, `Authorization`, or bearer strings — redacted via `sanitizeForLog` on both sinks.
- Detail with `undefined`, functions, symbols — omitted from JSON; console skips omitted keys.
- Circular object graph — `"[Circular]"` placeholder in JSON and console inspect output.
- SOD `logStep` migration: `ctx.log.info('violation loaded', { violation: {...} })` replaces raw `console.log`.
- `access-model-sod-remediation` and `preventive-sod-check` direct `console.log/warn` migrated to `ctx.log` or `getActiveFrameworkLogger()`.
- Incoming request: `detail: { command, input, config }` with full `sanitizeForLog` (not token-only redaction).
- Scripts and codegen continue using direct console output.
