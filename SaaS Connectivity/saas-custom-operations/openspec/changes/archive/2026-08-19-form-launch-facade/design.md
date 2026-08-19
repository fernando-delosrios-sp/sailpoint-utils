## Context

Three operations share ensure→create→notify choreography via thin `form-service.ts` wrappers. With persistable-email and form-notification available, a form-launch facade orchestrates `src/isc/forms/` and returns `{ formUrl, notification }` while leaving seed, serializers, recipient policy, and persist to operations.

## Goals / Non-Goals

**Goals:**
- Shared launch orchestrator under `src/lib/form-launch/`
- Collapse/thin the three form-service wrappers
- Pair instance create with form notification envelope production

**Non-Goals:**
- Seed content changes, apply/parse path, recipient resolution inside facade
- Persist key renames, workflow JSON
- Moving `isc/forms` API helpers into the facade module

## Decisions

### D1: Module path
- **Choice**: `src/lib/form-launch/`
- **Reason**: Keep `isc/forms` API-only; orchestration is a content/app concern
- **Considered alternatives**: Extend `isc/forms` (rejected — mixes API with notification)

### D2: Facade inputs
- **Choice**: Config object: forms client, formName, ownerId, seed/template (or prebuilt ensure callback), recipientId, createdBySourceId, formInput record (already serialized/picked), optional expire, and either prebuilt notification fields (header, body, recipients) or builders that receive formUrl
- **Reason**: Email body often needs formUrl; builders-after-create is the natural order
- **Considered alternatives**: Force callers to build body after facade returns only formUrl (weaker pairing)

### D3: ensure reuse
- **Choice**: Call existing `ensureFormDefinitionByName` + `buildCreateFormDefinitionPayload` / `loadFormSeed` patterns; facade may accept already-resolved `formDefinitionId` OR (seed + formName + ownerId)
- **Reason**: Minimize reimplementation
- **Considered alternatives**: Always require pre-ensured definition id (less DRY for ops)

### D4: Persist stays in handler
- **Choice**: Facade never calls `ctx.persist`
- **Reason**: Child vs parent persist and skip paths are operation-specific

### D5: C4
- **Choice**: Omit — library refactor, same ISC Forms API surface

## Risks / Trade-offs

- [Risk] Over-generic config becomes hard to use → Mitigation: start with typed params matching today’s three call sites; avoid premature plugin system
- [Trade-off] Some domain serialize stays outside facade → Reason: intentional; seed/types remain op-local

## Migration Plan

1. Add facade + mocked FormsApiLike tests
2. Migrate three form-service / handler call sites
3. Delete dead wrapper code
4. `npm test` + typecheck
5. Rollback: revert; no tenant migration

## Open Questions

None.
