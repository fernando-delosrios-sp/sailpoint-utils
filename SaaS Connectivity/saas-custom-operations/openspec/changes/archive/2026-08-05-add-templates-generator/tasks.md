## 1. Project wiring

- [x] 1.1 Add `tsx` devDependency and `"templates": "tsx scripts/generate-templates.ts"` to `package.json`
- [x] 1.2 Add `templates/` to `.gitignore`

## 2. Operation introspection

- [x] 2.1 Implement registration parser for `src/operations/index.ts` (extract `custom:*` command → handler module mapping)
- [x] 2.2 Implement TypeScript compiler API extractor for `OperationSignature` input/output fields (exclude `_template.ts`)
- [x] 2.3 Implement child-identity detector scanning `ctx.persist(...)` first-argument patterns in operation source files
- [x] 2.4 Add Vitest tests for registration parser, signature extractor, and child-identity detector

## 3. Account schema generator

- [x] 3.1 Implement ISC schema builder: core attrs (`id`, `status`, `date`) + union of output keys minus reserved keys
- [x] 3.2 Map all output field types to ISC `STRING` attributes with standard attribute metadata
- [x] 3.3 Write `templates/account-schema.json` on script run
- [x] 3.4 Add Vitest tests for schema builder (core attrs, union merge, reserved key exclusion, unregistered ops excluded)

## 4. Markdown generators

- [x] 4.1 Implement `access-token.md` generator from sample workflow OAuth pattern with placeholders
- [x] 4.2 Implement `workflow-invocation.md` generator with per-operation sections (invoke body, read-result, child identities)
- [x] 4.3 Link workflow guide to access-token guide without duplicating OAuth content
- [x] 4.4 Add Vitest tests for MD sections containing expected placeholders and operation-specific fields

## 5. CLI entrypoint

- [x] 5.1 Implement `scripts/generate-templates.ts` orchestrating introspection, schema, and MD writers
- [x] 5.2 Ensure script creates `./templates/` directory if missing and overwrites output files idempotently
- [x] 5.3 Add integration test or smoke test invoking generator against fixture operations

## 6. Documentation

- [x] 6.1 Update README with `npm run templates` usage and `./templates/` output description
- [x] 6.2 Document convention: re-run templates after adding or modifying registered operations (N/A for API/connector contract docs)
- [x] 6.3 Add brief JSDoc or module comment on generator entrypoint describing discovery rules

## 7. Changelog

- [x] 7.1 Create or update changelog entry for `templates` npm script (apply invokes changelog-generator if available)
- [x] 7.2 Confirm entry covers user-visible changes from Capabilities
