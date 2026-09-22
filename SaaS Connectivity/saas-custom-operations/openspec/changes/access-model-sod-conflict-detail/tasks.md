## 1. Conflict detail attributes

-   [x] 1.1 Add `conflict-detail.ts` building the persisted detail attributes from a violation, expansion, and recipient id
-   [x] 1.2 Render one attribute per policy side, name-or-id per entitlement, whole names dropped with a count at each side's 256-character ceiling
-   [x] 1.3 Add `conflict-detail.spec.ts` covering both sides named, id fallback, overflow counting, and the length ceiling

## 2. Persist wiring

-   [x] 2.1 Extend `OperationSignature['output']` with the six identity fields and `conflicting-entitlements`
-   [x] 2.2 Merge the detail attributes into the child persist call alongside `toPersistAttributes`
-   [x] 2.3 Run `npm run codegen:schemas` and confirm `index.schema.ts` picks up every new key

## 3. Skip refresh

-   [x] 3.1 Rewrite the skip branch to persist the refreshed detail with the stored notification fields carried over
-   [x] 3.2 Keep `forms-skipped` and the skipped-instance list behavior identical; no form launch, no email
-   [x] 3.3 Swallow and log a refresh failure without failing the scan
-   [x] 3.4 Extend `index.spec.ts` with the refresh, the preserved form url, the rename correction, and the failure path

## 4. Analysis workflow panels

-   [x] 4.1 Render the per-conflict panel from the new attributes: access item, type, policy, owner notified, and the two policy sides as coloured columns
-   [x] 4.2 Remove the remediation form link from the panel — the launcher is rarely the form recipient
-   [x] 4.3 Update `workflows.spec.ts` for the panel bindings

## 5. Verification

-   [x] 5.1 `npm run typecheck`
-   [x] 5.2 `npm test`
-   [x] 5.3 `npm run build` and package for upload

## 6. Documentation

-   [x] 6.1 Update the Output section of `src/operations/access-model-sod-remediation/README.md` with the new attributes and the refresh-on-skip behavior
-   [x] 6.2 Note the panel rendering in the workflow integration section

## 7. Changelog

-   [x] 7.1 Add the entry via the `changelog-generator` skill
