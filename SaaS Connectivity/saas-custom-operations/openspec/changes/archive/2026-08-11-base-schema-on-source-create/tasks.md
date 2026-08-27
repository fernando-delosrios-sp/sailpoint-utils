## 1. Base schema builder and registry

- [x] 1.1 Add `listRegisteredOperationSchemas()` to operation schema registry
- [x] 1.2 Extract shared `buildBaseAccountSchema` from registered output fields with unit tests
- [x] 1.3 Refactor templates `buildAccountSchema` to use shared builder; confirm generated output unchanged

## 2. Apply base schema on source create

- [x] 2.1 Implement `applyBaseAccountSchema` (create or patch path) in result-source module
- [x] 2.2 Wire into `createDelimitedFileResultSource` after source create
- [x] 2.3 Add unit tests: new source gets union attrs; existing discovered schema patched; existing source unchanged

## 3. Documentation and verification

- [x] 3.1 Update README with base schema on auto-create behavior
- [x] 3.2 Run `npm test` and update CHANGELOG

## 4. Mandatory closing sections

- [x] 4.1 All spec scenarios mapped to tests in tasks 1–2
- [x] 4.2 `npm test` passes with coverage thresholds met
