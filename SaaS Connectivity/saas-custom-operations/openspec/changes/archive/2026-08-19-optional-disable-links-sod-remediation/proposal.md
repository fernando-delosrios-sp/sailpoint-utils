## Why

Workflow callers sometimes need remediation form HTML without ISC admin deep links even when live `apiUrl` is present—for sanitizers, quoting-sensitive transports, or recipients who should not get admin UI anchors. Today links turn on automatically whenever UI origin resolves; there is no per-invoke opt-out. An optional `disableLinks` input restores on-demand control without changing default linked behavior.

## What Changes

**Optional disableLinks input (both launch operations)**
- From: `custom:access-model-sod-remediation` and `custom:sod-remediation` always render ISC UI links in form HTML when UI origin is available
- To: optional boolean input `disableLinks`; when `true`, form HTML entity names render as plain escaped text (same as offline / missing UI origin)
- Reason: callers need on-demand suppression without dropping `apiUrl`
- Impact: non-breaking additive input; omitted/`false` preserves current behavior

**Out of scope for this flag**
- Email remediation-form CTA (“Remediate here”) and `*:form-url` outputs stay unchanged
- Apply operations and sod-form-html library contracts stay unchanged

## Capabilities

### New Capabilities

- _(none)_

### Modified Capabilities

- `connector-operations/access-model-sod-remediation`: accept optional `disableLinks`; suppress ISC UI links in situation summary and group column HTML when true
- `connector-operations/sod-remediation`: accept optional `disableLinks`; suppress ISC UI links in situation summary and access-path / group column HTML when true
- `ubiquitous-language`: promote `disableLinks` term for the optional input

## Impact

- Operation signatures and generated schemas: `src/operations/access-model-sod-remediation/index.ts`, `src/operations/sod-remediation/index.ts`, `*.schema.ts`, connector-spec.json via codegen
- Handlers: gate `uiOrigin` with `disableLinks` before calling existing builders
- Tests: operation specs covering true/false/omit; docs/README input tables
- No persist schema or output field changes; no auth or ISC API changes
