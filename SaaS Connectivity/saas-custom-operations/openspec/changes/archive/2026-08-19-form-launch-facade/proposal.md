## Why

Three operations maintain near-identical `form-service.ts` wrappers: load seed, ensure definition, pick declared inputs, create standalone instance. The valuable variation is domain-only (seed, serializers, expire, email wording), but the choreography itself is copy-paste. A form launch facade that returns `{ formUrl, notification }` makes the next form operation a config, not another twin module, and locks ensure→create→notify as one intentional seam above `src/isc/forms/`.

## What Changes

**Form launch facade**
- Add a shared orchestrator (e.g. `src/lib/form-launch/`) that, given seed/template + create params + notification fields/builders, ensures the definition, creates the standalone instance, and returns `{ formUrl, notification }`.
- Reason: one choreography; `isc/forms` stays API-only.
- Impact: non-breaking refactor of call sites.

**Collapse operation form-service wrappers**
- From: parallel `ensureXFormDefinition` / `createXInstance` in access-expiration-reminders, access-model-sod-remediation, and sod-remediation.
- To: thin operation modules that supply seed, serialize formInput, and invoke the facade (or delete wrappers when nothing domain-specific remains beyond seed).
- Reason: remove structural duplication.
- Impact: non-breaking; handlers still own recipient policy, caps, skips, and persist.

**Return shape**
- Facade returns the form notification envelope (sibling capability) plus formUrl (or envelope includes formUrl).
- Reason: launch and notify stay paired.
- Impact: internal; persist keys unchanged via envelope mapper.

**Explicit non-goals**
- Changing form seeds, fingerprints, or formInput field sets
- Persist key renames or workflow JSON updates
- Apply/parse submitted instances (`access-model-sod-remediation-apply`)
- Moving recipient resolution into the facade
- In-form DESCRIPTION HTML (`sod-form-html`)

## Capabilities

### New Capabilities

- `form-launch`: Shared choreography to ensure a seeded form definition, create a standalone form instance, and produce a form notification envelope for workflow persist outputs.

### Modified Capabilities

- `ubiquitous-language`: Promote form launch vocabulary from discovery.
- `connector-operations/sod-remediation`, `connector-operations/access-model-sod-remediation`, and access-expiration-reminders specs: only if normative text should mention the shared launch path — prefer behavior-identical deltas or none.

## Impact

- New: `src/lib/form-launch/` (or design-chosen path) + unit tests with mocked `FormsApiLike`
- Modify/thin: three operation `form-service.ts` modules and their handler call sites
- Depends on: `persistable-email-kit`, `form-notification-envelope`, existing `src/isc/forms/`
- No change: connector-spec.json commands, workflow JSONPaths, persist attribute names, seed JSON content (unless accidental)
- Tests: facade tests; existing operation specs remain green
- Docs: lib README; CHANGELOG; update operation READMEs only if internal module layout is documented
