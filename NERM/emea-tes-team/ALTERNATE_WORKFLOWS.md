# Alternate simplified workflows (live)

Created because existing Request/Approval actions **cannot be updated** via API or Configuration Import (create-only). Originals left untouched; these are new **Disabled** workflows on `Assignments - Custom` (`978f1283-ca68-4370-9277-dcc51c5f05ca`).

## Do not confuse the two “Assignment Details” pages

Both were historically named alike. Use these names/ids only:

| Intended name | Id | Used by |
|---|---|---|
| **Update Assignment Details** | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` | Update Assignment / Update (Simplified) |
| **Update Assignment Details - without Sub-Organization** | `df802b02-340f-49b3-8380-2fc626684ddb` | Update workflows (Portal sub-org collaborator branch) |
| **Add Assignment Details** | `bc65ead5-0930-40be-9efd-363942d97099` | Add Assignment Details / Add (Simplified) |
| **Add Assignment Details - without Sub-Organization** | `34a06480-c157-409a-acd7-6c5fa1d63b5b` | Add / Create workflows (no sub-org branch) |

Rename import (Admin Configuration Import):

`NERM_emea-tes-team_import_rename_assignment_details_pages.json`

## Workflows

| Name | Id | Type | Profile status | Requester form page |
|---|---|---|---|---|
| Update Assignment (Simplified) | `2d1778fe-2813-46b1-8f36-826002ee7298` | Update / Assignments | `active` | **Update** `583638b9…` / without-suborg `df802b02…` |
| Update Assignment - Inactive (Simplified) | `ebc93f72-3a84-480c-9da1-ce7436e01df2` | Update / Assignments | `inactive` | **Update** `583638b9…` |
| **New Assignment (Simplified)** | `ce262268-f56f-4251-adea-50dc3859eb9c` | Create / Assignments | — | **Add** `bc65ead5…` / without-suborg `34a06480…` |
| **Add Assignment Details (Simplified)** — People | `9f6f47ac-1780-4e44-8960-e130ff85fec0` | Update / People - Custom | `Active` | stages org/pop, then runs `ce262268…` |
| ~~Add Assignment Details (Simplified)~~ | `b335ce2d-1f68-45fd-80ad-f7130fde791f` | Create / Assignments | **corrupt — abandon** | (wrong Update pages; steps not clearable) |

## Other shared pages

| Action | Page |
|---|---|
| Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| No Department Approvers Defined -- Department Admin approval | `7aa664e7-b022-4003-834b-e61ab8b1b0c9` |

## Import — New Assignment (Simplified) (`ce262268…`)

**Full recreate** (form + features + approvals + registration invites + create + integration). Uids `b3_nas_full_v2_*`.

`NERM_emea-tes-team_import_fix_new_assignment_simplified_full.json`

(Same payload mirrored in `NERM_emea-tes-team_import_fix_new_assignment_simplified.json`.)

**Before import:** delete **all workflow steps** on `ce262268…` (Config Import only adds). Expect large **Review Create**.

Process:

1. **Add Assignment Details** (unconditional)
2. Get collaborator type (REST — copy in Admin if empty; dump has no body for this action)
3. Suborg → without-Sub-Organization form
4. Load `sysconfig_enabled_features` + **New Assignment** approvals
5. **Invite (early)** if End-User Registration + `NEW_PERSON` + After Assignment **off**
6. Per-population Sponsor / Department (New Assignment config)
7. `No_Approvers` → Department Admin
8. **Invite (late)** if End-User Registration + `NEW_PERSON` + After Assignment **on**
9. Create profile → cleanup → Assignment Integration

Get-approvers REST config is included from original Add. Still copy **Get collaborator type** REST from Update `2f790a34…` if the action body is empty.

For `NEW_PERSON` / org / pop to arrive from NE&A, also import:

`NERM_emea-tes-team_import_fix_nea_run_new_assignment_transfers.json`

and remove transfer-less Simplified run steps on NE&A.

## Fix import — Update Assignment (Simplified)

Upload via Configuration Import:

`NERM_emea-tes-team_import_fix_update_assignment_simplified.json`

**Before import:** in Admin, open **Update Assignment (Simplified)** and **delete all existing workflow steps** (prior linear/v2 imports leave orphans; Config Import only adds steps).

### Intended process

1. **Get collaborator type, set sysconfig_profile** (REST — see wiring note below)
2. **Requester form** (conditions):
   - `source != Portal` → **Update Assignment Details**
   - `source == Portal` & `collaborator_type != suborganization` → **Update Assignment Details**
   - `source == Portal` & `collaborator_type == suborganization` → **Update Assignment Details - without Sub-Organization**
3. **Load** `sysconfig_enabled_approvals_update_assignment` from NE Server (`22988048…`)
4. Per population (one check each):
   - Sponsor option enabled → **Sponsor Approval**
   - Department option enabled → set `No_Approvers` + **Get approvers** + **Department Approval**
5. If `api_response_5` still `No_Approvers` → **Department Admin approval**
6. Update profile → cleanup → Run Assignment Integration

**Update Department** is not part of this flow (that nested request form is a separate workflow; Add only invokes it on the no-approvers path).

Approvals fire only when that population’s option is selected in `Configuration - Approvals - Update Assignment`. No separate “Enabled” flag pass.

### REST wiring (Admin — one-time)

Public API does not expose REST action bodies. Copy configuration from original **Update Assignment** onto Simplified:

| Simplified action | Copy from original |
|---|---|
| `ddb54efc…` Get collaborator type | `2f790a34-61df-47a2-9e26-2765150ef0fb` |
| `72ba25e0…` Get approvers for assignment_department | `485d43f1-038a-4ec3-a4e2-330f4773038c` |

(Approvals config load is a SetAttributes action in the fix import — no REST copy needed for that step.)

Keep workflow **Disabled** until form + approval branching look correct, then enable and retest.

## Originals (unchanged)

| Name | Id |
|---|---|
| Update Assignment (= UI “Update Assignment Details”) | `9cd0e00d-33ad-4d0c-838f-965fb66fe258` |
| Update Assignment - Inactive | `2b583fb6-c8d2-46d4-b881-8ed37c5dc252` |
| Add Assignment Details | `8e88da4f-f26e-4cb9-a72c-111b3edf8c29` |


## People wrapper — org/population staging (`9f6f47ac…`)

`ce262268…` only collects assignment details. Org/population must be staged **before** it runs, then passed via **OutgoingTransferAttribute** (same as original Add run `c1145934…`).

Without transfers, the Add form opens with empty organization/population.

Import on empty People WF:

`NERM_emea-tes-team_import_fix_people_new_assignment_staging.json`

Process:

1. Set collaborator / requester context  
2. If collaborator → portal collaborator attrs  
3. NE Server + single-assignment feature flags  
4. Clear person `assignment_population`  
5. Select Organization **or** Select Organization by Population  
6. Population count → Select Population **or** auto-set single population  
7. **Run New Assignment (Simplified)** (`ce262268…`) with transfers: org, population, suborg, person (`requests profile`), source, collaborator fields  

Expect large **Review Create**. Enable after org → population → Add form looks correct.

## New Non-Employee & Assignment (`5ab1f80f…`)

For Simplified to receive org/pop/`NEW_PERSON`/features, use:

`NERM_emea-tes-team_import_fix_nea_run_new_assignment_transfers.json`

(Replace transfer-less Simplified run steps; keep before Assignment Integration.)
