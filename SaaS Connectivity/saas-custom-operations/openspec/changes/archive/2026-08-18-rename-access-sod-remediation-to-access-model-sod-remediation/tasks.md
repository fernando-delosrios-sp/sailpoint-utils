## 1. Rename operation directory and command

- [x] 1.1 `git mv src/operations/access-sod-remediation src/operations/access-model-sod-remediation`
- [x] 1.2 Update `command: 'custom:access-model-sod-remediation'` and all `access-model-sod-remediation:*` output keys in `index.ts`
- [x] 1.3 Replace remaining `access-sod-remediation` string literals in operation modules (`form-email.ts`, `form-service.ts`, log prefixes, comments)
- [x] 1.4 Run `npm run codegen:schemas` to regenerate `index.schema.ts`, `auto-registry.ts`, and sync `connector-spec.json`

## 2. Rename payloads and seeds

- [x] 2.1 `git mv payloads/access-sod-remediation-offline.json payloads/access-model-sod-remediation-offline.json`
- [x] 2.2 Update `commandType` and any path references inside the offline payload
- [x] 2.3 `git mv` seed file to `access-model-sod-remediation.seed.json` and update imports
- [x] 2.4 Update `payloads/fer.json`, `scripts/call-op.ts`, and root `README.md` payload references

## 3. Update tests

- [x] 3.1 Update `index.spec.ts`, `form-email.spec.ts` command literals, persist key assertions, and schema attribute names
- [x] 3.2 Update cross-operation references in `src/isc/forms/forms.spec.ts` and `src/lib/sod-form-html/` if present
- [x] 3.3 Grep repo for `access-sod-remediation` and fix any remaining references (exclude archived changes)

## 4. OpenSpec canonical specs (pre-archive sync if needed)

- [x] 4.1 Confirm delta specs cover all renamed requirements under `connector-operations/access-model-sod-remediation`
- [x] 4.2 Confirm REMOVED delta at `connector-operations/access-sod-remediation` lists all superseded requirements

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test`
- [x] 5.2 Run `npm run build` and verify connector-spec.json lists `custom:access-model-sod-remediation` only (not old command)
- [x] 5.3 All delta spec scenarios covered by named automated tests (command registration, persist keys, offline invoke, form email outputs)

## 6. Documentation

- [x] 6.1 Update `src/operations/access-model-sod-remediation/README.md` (title, command name, output key tables, offline payload path)
- [x] 6.2 Update root `README.md` operation list and any migration note for workflow authors
- [x] 6.3 Update inline JSDoc/comments referencing old slug in operation and shared modules

## 7. Changelog

- [x] 7.1 Create or update CHANGELOG breaking entry via **changelog-generator** during apply
- [x] 7.2 Confirm entry documents command rename, persist namespace rename, offline payload rename, and workflow migration steps
