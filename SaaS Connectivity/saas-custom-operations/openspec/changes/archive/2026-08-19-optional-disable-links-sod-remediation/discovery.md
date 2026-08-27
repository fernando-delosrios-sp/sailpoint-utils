## Scope

Add an optional `disableLinks` boolean input to `custom:access-model-sod-remediation` and `custom:sod-remediation` so callers can suppress ISC admin UI deep links in form HTML on demand; out of scope: changing email remediation-form CTA links, `*:form-url` outputs, apply operations, or sod-form-html library APIs beyond callers passing `uiOrigin`.

## Language

**disableLinks** (`promote`):
Optional boolean operation input that, when true, suppresses ISC UI links in remediation form HTML for that invoke.
_Avoid_: `noLinks`, `omitLinks`, `linkless`

**ISC UI link** (`conflicts-with-canonical`):
Already canonical in ubiquitous-language — admin UI anchor built from invoke `apiUrl` without hardcoded domains. This change consumes the term; do not redefine.

**UI origin** (`conflicts-with-canonical`):
Already canonical — protocol and host prefix for ISC admin UI paths. Callers omit it (or treat as undefined) when `disableLinks` is true.

## Decisions

Context → callers sometimes want plain-text entity names in remediation forms even when live `apiUrl` is present (e.g. email/HTML sanitizers, DelimitedFile quoting concerns, or recipient environments where admin deep links are undesirable).

Q1: Which operations? → Both launch operations that render ISC UI links today: `access-model-sod-remediation` and `sod-remediation`.

Q2: Default when omitted? → Links remain enabled when UI origin can be resolved (current behavior). Omitted/`undefined`/`false` → current behavior; only `true` disables.

Q3: Implementation seam? → Handlers already gate links by passing `uiOrigin` or `undefined` into shared builders. When `disableLinks === true`, force `uiOrigin` undefined even if `resolveUiOrigin(apiUrl)` would succeed. No new sod-form-html API required.

Q4: Email CTA / form URL? → Remains unchanged. `disableLinks` targets ISC admin entity deep links in in-form HTML (context panels, group columns, access paths), not the remediation form URL itself or the email “Remediate here” link.

Q5: Manifest / codegen? → Optional boolean on OperationSignature input; schema codegen and connector-spec sync via existing prebuild path.

## Open questions

None blocking. Assumption recorded: email remediation-form CTA and `*:form-url` are out of scope for this flag.

## Scenarios discussed

- Omit `disableLinks` online → ISC UI links present when UI origin resolves (unchanged).
- `disableLinks: false` online → same as omit.
- `disableLinks: true` online → names/labels plain escaped text; no `<a href=` admin anchors in form HTML.
- Offline / no apiUrl → still no admin links (unchanged); `disableLinks` redundant but harmless.
- Email body still includes remediation form CTA link when applicable; form URL output still returned.
