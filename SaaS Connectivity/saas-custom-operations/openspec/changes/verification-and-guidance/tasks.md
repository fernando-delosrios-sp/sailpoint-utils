## 1. Typecheck

- [x] 1.1 Add `tsconfig.scripts.json` covering scripts/
- [x] 1.2 Add `"typecheck": "tsc --noEmit -p tsconfig.json && tsc --noEmit -p tsconfig.scripts.json"` to package.json
- [x] 1.3 Fix any surfaced type errors in scripts or src

## 2. Vitest upgrade

- [x] 2.1 Upgrade vitest and @vitest/coverage-v8 to 4.x
- [x] 2.2 Update vitest.config.ts for breaking API changes if any
- [x] 2.3 Run full suite; fix failures

## 3. TypeScript upgrade

- [x] 3.1 Bump typescript to 5.x stable
- [x] 3.2 Resolve any new strict errors under typecheck

## 4. CI workflow

- [x] 4.1 Add GitHub workflow with path filter for saas-custom-operations
- [x] 4.2 Workflow steps: npm ci, typecheck, test, build
- [x] 4.3 Verify workflow syntax locally or via dry run

## 5. Local env docs

- [x] 5.1 Add `.env.example` with ISC_TOKEN placeholder
- [x] 5.2 Document ISC_TOKEN in README Development section

## 6. Agent guidance

- [x] 6.1 Rewrite AGENTS.md project context for custom-operations architecture
- [x] 6.2 Rewrite openspec/config.yaml context and global rules (remove std-command scaffold)
- [x] 6.3 Fix README dev script description if still claiming tsc watch on npm run dev

## 7. Verification

- [x] 7.1 Confirm canonical test command: `npm test`
- [x] 7.2 All delta spec scenarios covered by named automated tests

## 8. Documentation

- [x] 8.1 Confirm connector-config delta scenarios reflected in README and AGENTS.md

## 9. Changelog

- [x] 9.1 Create or update changelog entry for this change
- [x] 9.2 Confirm entry covers CI, typecheck, toolchain, and agent doc refresh
