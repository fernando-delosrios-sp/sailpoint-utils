## 1. Connector error helper

- [x] 1.1 Create `src/framework/connector-error.ts` with `toConnectorError(err, context?)` per design D2
- [x] 1.2 Add `src/framework/connector-error.spec.ts` — plain Error → ConnectorError (generic)
- [x] 1.3 Add test — axios-like error with status 404 → ConnectorError NotFound
- [x] 1.4 Add test — existing ConnectorError returned unchanged
- [x] 1.5 Add test — PersistVerificationError → ConnectorError
- [x] 1.6 Export helper from `src/framework/index.ts`

## 2. customOperation boundary wrapper

- [x] 2.1 Wrap init + handler body in `with-custom-operation.ts` try/catch using `toConnectorError`
- [x] 2.2 Update `with-custom-operation.spec.ts` — handler plain Error → ConnectorError
- [x] 2.3 Update `with-custom-operation.spec.ts` — ISC status Unauthorized → ConnectorError
- [x] 2.4 Verify existing ConnectorError validation tests still pass unchanged

## 3. Forms client error wrapping

- [x] 3.1 Update `sod-form-service.ts` — wrap SDK calls and missing-response checks with ConnectorError
- [x] 3.2 Add `sod-form-service.spec.ts` failure tests for definition create, instance create, and search rejection

## 4. Offline stub consistency

- [x] 4.1 Change `offlineApiError()` in `request-context.ts` to throw ConnectorError
- [x] 4.2 Add or update test covering offline stub rejection type if applicable

## 5. Integration verification

- [x] 5.1 Run `npm test` — all pass
- [x] 5.2 Run `npm run build` — bundle succeeds
- [x] 5.3 Manual spcx check — covered by unit tests asserting ConnectorError on failure paths (formatFormsApiError + customOperation wrapper)

## 6. Documentation

- [x] 6.1 Update README error-handling note — N/A; behavior is implicit framework guarantee; CHANGELOG documents fix
- [x] 6.2 Update inline JSDoc on `customOperation` describing ConnectorError guarantee
- [x] 6.3 No connector-spec.json or API doc changes required — N/A

## 7. Changelog

- [x] 7.1 Create or update changelog entry via changelog-generator skill
- [x] 7.2 Confirm entry covers ConnectorError propagation fix for workflow retry behavior
