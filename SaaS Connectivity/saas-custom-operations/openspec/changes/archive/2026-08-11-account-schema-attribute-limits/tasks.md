## 1. Attribute limit module

- [x] 1.1 Add `src/framework/attribute-limits.ts` with `ISC_IDENTITY_MAX_LENGTH` (128), `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256), and `truncateForIscStorage`
- [x] 1.2 Add `attribute-limits.spec.ts` covering within-limit passthrough, truncation, and warning log (identity truncated at 128 / STRING truncated at 256 scenarios)

## 2. Persist formatting integration

- [x] 2.1 Apply STRING cap in `formatScalarValue` for STRING type (including JSON-serialized values)
- [x] 2.2 Apply identity cap in `buildAccountAttributes` for the `id` field
- [x] 2.3 Export limit constants from `src/framework/index.ts`
- [x] 2.4 Extend `persist-result.spec.ts` for STRING attribute truncated at 256, STRING array element truncation, identity truncated at 128, and values within limits unchanged scenarios

## 3. Documentation

- [x] 3.1 Update README result persistence section with ISC 128/256 limits and warn-and-truncate behavior
- [x] 3.2 Add JSDoc on limit constants and `truncateForIscStorage` (N/A for connector-spec.json — no manifest change)

## 4. Changelog

- [x] 4.1 Create or update CHANGELOG entry via changelog-generator skill
- [x] 4.2 Confirm entry covers truncation of persist identity (128) and STRING attributes (256)
