## Scope

Introduce a **form launch facade** that choreographs ensure-definition-from-seed → create standalone instance → return `{ formUrl, notification }`, collapsing the near-identical `form-service.ts` wrappers across form-launching operations. Depends on `src/isc/forms/` (existing), persistable-email kit (body primitives), and form notification envelope (return shape). Out of scope: changing persist key names, workflow JSON, recipient resolution policy, seed content, apply/parse of submitted form instances, and SoD form DESCRIPTION HTML.

## Language

**Form launch** (`promote`):
The choreographed sequence that ensures a tenant form definition from an operation seed, creates a standalone assigned form instance for a recipient, and produces a form notification envelope for persist/workflows.
_Avoid_: form service (ambiguous), forms API (raw ISC client)

**Form launch config** (`draft`):
Operation-supplied parameters for a launch: seed/template, form name, definition owner, recipient id, created-by source id, formInput (post-serialize), optional expire, and email header/body builders or prebuilt notification fields.
_Avoid_: handler input payload (broader)

**Standalone form instance** (`draft`):
An ASSIGNED ISC form instance with `standAloneForm: true` whose URL is returned for notification CTAs. Creation remains in `src/isc/forms/create-instance`.
_Avoid_: embedded workflow form, interactive only

## Decisions

**Context** — Explore session (2026-08-19): three ops share the same ensure→create→email persist choreography with thin operation-local wrappers.

**Q1 — Facade location?**
→ Shared library beside forms concerns (e.g. `src/lib/form-launch/` or thin module under `src/isc/forms/` that *orchestrates* but does not own seed JSON). Prefer `src/lib/form-launch/` so `isc/forms` stays API-only.

**Q2 — What stays operation-local?**
→ Seed JSON, formInput types/serializers, recipient *who*, email wording builders, expire policy, skip/idempotency/cap logic in handlers.

**Q3 — Return value?**
→ `{ formUrl, notification }` using the form notification envelope type from the sibling change.

**Q4 — Sequencing?**
→ Apply after persistable-email-kit and form-notification-envelope. This change migrates the three form-service wrappers onto the facade.

**Q5 — Worth it despite thin wrappers?**
→ Yes for consistency for the next form op and one place for create+notification pairing; not primarily for LOC reduction.

## Open questions

None blocking. Exact module path deferred to design.

## Scenarios discussed

- ensure uses existing watermark/fingerprint behavior unchanged.
- create passes through expire when provided (expiration reminders); default TTL otherwise.
- pickDeclaredFormInputValues still runs with the operation seed before create.
- Facade does not persist; handler still calls `ctx.persist` / child persist with envelope-mapped keys.
- Offline / testMode behavior unchanged (handlers decide offline paths before or around facade).
