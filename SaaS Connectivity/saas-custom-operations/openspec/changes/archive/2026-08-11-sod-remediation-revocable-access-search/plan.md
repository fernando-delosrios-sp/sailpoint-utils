# Plan: sod-remediation-revocable-access-search

**Goal:** Filter `groupAAccessSearch` / `groupBAccessSearch` to revocable access path ids only.

**Test command:** `npm test`

**Architecture:** `buildRevocableAccessSearchString()` filters `AccessPathLine[]` to `revocable === true`, then reuses `buildAccessSearchString()`. `assembleFormInput()` switches both sides. HTML rendering unchanged.

## Task 1.1 — Add builder

**File:** `src/operations/sod-remediation/access-path-resolver.ts`

```typescript
export function buildRevocableAccessSearchString(accessPaths: AccessPathLine[]): string {
    return buildAccessSearchString(accessPaths.filter((item) => item.revocable))
}
```

## Task 1.2 — Unit tests (TDD first)

**File:** `src/operations/sod-remediation/access-path-resolver.spec.ts`

- [ ] **Step 1:** Write failing test — mixed side excludes non-revocable entitlement id
- [ ] **Step 2:** Run `npm test -- access-path-resolver.spec.ts` — expect FAIL
- [ ] **Step 3:** Implement `buildRevocableAccessSearchString` (Task 1.1)
- [ ] **Step 4:** Run tests — expect PASS
- [ ] **Step 5:** Add tests for entitlement-only (all revocable) and empty revocable input → `''`

## Task 2.1 — Wire form input

**File:** `src/operations/sod-remediation/context.ts`

Replace:

```typescript
groupAAccessSearch: buildAccessSearchString(groupA.accessPaths),
groupBAccessSearch: buildAccessSearchString(groupB.accessPaths),
```

With:

```typescript
groupAAccessSearch: buildRevocableAccessSearchString(groupA.accessPaths),
groupBAccessSearch: buildRevocableAccessSearchString(groupB.accessPaths),
```

Update import from `./access-path-resolver`.

## Task 2.2 — Context spec

**File:** `src/operations/sod-remediation/context.spec.ts`

In `assembleFormInput includes hidden access search strings for each side`:

- `groupAAccessSearch` stays `id:ent-a`
- `groupBAccessSearch` changes from `id:ent-b OR id:role-1` to `id:role-1`

Run `npm test -- context.spec.ts`.

## Task 3 — Docs

- [ ] README: note search strings list revocable items only
- [ ] CHANGELOG: patch entry under Unreleased
- [ ] `npm test` full suite

## Scenario coverage map

| Scenario | Test |
|---|---|
| Hidden access search string per side (revocable only) | `access-path-resolver.spec.ts` + `context.spec.ts` |
| Single-item side | existing `buildAccessSearchString` + revocable filter test |
| Mixed revocable/non-revocable | `access-path-resolver.spec.ts` |
| Entitlement-only unchanged | `access-path-resolver.spec.ts` |

**Commit point:** After Task 1.2 + 2.2 green, commit implementation. After Task 3, commit docs.
