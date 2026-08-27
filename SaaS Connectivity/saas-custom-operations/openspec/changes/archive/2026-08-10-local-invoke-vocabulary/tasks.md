## 1. Local invoke runner rename

- [x] 1.1 Replace `test:operation` npm script with `call:op` pointing to `scripts/call-op.ts`
- [x] 1.2 Remove `scripts/run-operation-fixture.ts` and `scripts/fixture-output.ts`
- [x] 1.3 Implement `scripts/call-op.ts` with `loadPayload`, `runPayload`, `runPayloadFromPath` using `type` field
- [x] 1.4 Implement `scripts/payload-output.ts` with Local invoke and Simulated persist section labels
- [x] 1.5 Rename `test-mode-fixture-collector.ts` to `payload-persist-collector.ts` and update imports

## 2. Invoke payloads

- [x] 2.1 Create `payloads/` directory with example payloads using `type`, `config`, `input`
- [x] 2.2 Remove `fixtures/` directory and `command` field from all example payloads
- [x] 2.3 Update runner error hints to reference `payloads/` paths

## 3. Tests (operation-test-runner scenarios)

- [x] 3.1 Add `scripts/call-op.spec.ts`: reject payload missing type (Missing type rejected)
- [x] 3.2 Add offline payload run without config returns res.send payload (Valid payload loads type and input)
- [x] 3.3 Add payload with config passes context.config to handler (Valid payload with config loads connection fields)
- [x] 3.4 Add `scripts/payload-output.spec.ts`: output includes Local invoke header and type= line
- [x] 3.5 Assert package.json documents `call:op` script (call op script documented)
- [x] 3.6 Run `npm test` — all tests pass

## 4. Documentation (connector-config scenarios)

- [x] 4.1 Update README: local invoke section uses `call:op`, `payloads/`, `type`; avoid fixture/test-operation as concept names (Persist inhibition documented)
- [x] 4.2 Update README: offline and connected dry-run payload JSON examples with `type` (Payload format documented)
- [x] 4.3 Update README project tree to list `call-op.ts` and `payloads/`
- [x] 4.4 Update operation-test-runner and connector-config main specs on archive

## 5. Documentation

- [x] 5.1 Update README / getting-started for user-visible rename (call:op, payloads, type)
- [x] 5.2 Update inline docs (call-op usage string, JSDoc on InvokePayload interface)
- [x] 5.3 N/A — no connector-spec.json or API contract changes beyond docs

## 6. Changelog

- [x] 6.1 Create or update CHANGELOG Unreleased breaking entry for call:op rename
- [x] 6.2 Confirm entry covers payloads/, type field, and removed test:operation
