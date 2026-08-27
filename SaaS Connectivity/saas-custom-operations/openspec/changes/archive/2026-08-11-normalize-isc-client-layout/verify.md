# Verification Report

**Change**: `normalize-isc-client-layout`
**Verified at**: `2026-08-11 08:50`
**Verifier**: apply agent

---

## 1. Structural Validation (`openspec validate --all --json`)

- [x] 全數 items `"valid": true`

**結果**：

```text
Summary: 16/16 passed (1 change, 15 specs)
```

---

## 2. Task Completion (`tasks.md`)

- [x] 所有 `- [ ]` 已變為 `- [x]`

**未完成任務**：無

---

## 3. Delta Spec Sync State

| Capability | Sync 狀態 | 備註 |
|---|---|---|
| target-client | ✓ 已 sync | layout + token-identity path in main spec |
| target-client/identity-access | ✓ 已 sync | orchestration-only requirement |
| target-client/identity-history | ✓ 已 sync | new sub-capability |
| target-client/access-profiles | ✓ 已 sync | new sub-capability |
| target-client/roles | ✓ 已 sync | new sub-capability |
| target-client/violations | ✓ 已 sync | new sub-capability |
| target-client/controls | ✓ 已 sync | new sub-capability |

---

## 4. Design / Specs Coherence Spot Check

| 抽樣項 | design 描述 | specs 對應 | 差距 |
|---|---|---|---|
| D1 Per-API subdirs | Mandatory `src/isc/<api-grouping>/` | target-client layout requirement + scenarios | 無 |
| D2 Identity access split | Per-API wrappers + orchestration | identity-history/access-profiles/roles + identity-access specs | 無 |
| D3 No experimental umbrella | violations/ + controls/ + http/ | violations + controls specs; no experimental/ in code | 無 |
| D4 Barrel exports | index.ts per folder | target-client index.ts scenarios | 無 |

**漂移警告**：無

---

## 5. Scenario Test Coverage

| Scenario | Test |
|---|---|
| Per-API subdirectory present | Manual layout + grep (no flat isc root files) |
| Identity access APIs separated | `identity-access.spec.ts`, per-API module specs |
| index.ts present in every API folder | Layout inspection |
| Barrel exports match implemented API calls | Import paths in sod-remediation + framework |
| identity_id claim preferred | `token-identity.spec.ts` |
| Invalid token rejected | `token-identity.spec.ts` |
| Controls listed | `controls.spec.ts` |
| Violation fetched by ID | `violations.spec.ts` |
| Violation fetch failure surfaces error | `violations.spec.ts` |
| Entitlement ids returned (access-profiles) | `access-profile-entitlements.spec.ts` |
| Entitlement ids returned (roles) | `role-entitlements.spec.ts` |
| Access profiles listed for identity | `identity-access.spec.ts` (SDK loopback) |
| Roles listed for identity | `identity-access.spec.ts` (SDK loopback) |
| SDK loopback listing | `identity-access.spec.ts` |
| Offline data listing | `identity-access.spec.ts` |

---

## 6. Implementation Signal

- [x] `npm test` exit 0
- [x] `npm run build` exit 0

**Commands**:

```text
npm test — PASS (211+ tests, coverage thresholds met)
npm run build — PASS (ncc bundle)
```

---

## 7. Deferred Manual Dogfood vs Automated Test Equivalence

plan.md 無 `[~]` deferred rows — 本節 N/A。

---

## Overall Decision

- [x] ✅ PASS — 可進入 finishing-a-development-branch 與 archive

**下一步**：archive change and sync specs to main tree.
