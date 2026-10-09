# Update Assignment — why Config Import did nothing useful

Verified live on emea-tes-team against workflow `9cd0e00d-33ad-4d0c-838f-965fb66fe258`.

## Root cause

NERM public API and Configuration Import only **create** Request/Approval actions.
They do **not** update existing actions (no PATCH/PUT; import ignores matching id/uid and inserts new rows).

- Original graph actions still present: **39** (Aug 2026), including **25** still Population-named.
- Orphan actions created by today's imports: **61** (not wired into conditions/steps).
- That is why the workflow designer still shows PopulationN request/approval steps.

## Do not re-import action deltas

These files create more orphans; they will not remap the live graph:

- `NERM_emea-tes-team_import_delta_update_assignment.json` → moved to `*.DO_NOT_IMPORT.json`
- `NERM_emea-tes-team_import_delta.json` (Create/Add Assignment actions) → same risk

## Manual remap (Admin UI) — Update Assignment

For each action below: open the action → set **Page** and **Description** to the target.
Shared pages were repaired via API so they are no longer empty.

| Action id | Current description | Target description | Target page |
|---|---|---|---|
| `a90ad097-b4c4-48f7-ae5b-ca9e25ca05e3` | Approve Population10 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `83de84e3-3c85-4cda-8b78-78c9eaea9410` | Approve Population10 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `0a32e92f-688d-4fb3-8f09-ce3029caa423` | Approve Population2 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `aa348ea7-2bc9-4c3f-9504-7335e96232ba` | Approve Population2 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `052f4310-2b9f-4559-b3fb-807908cc2881` | Approve Population3 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `03ec6f1b-d7f3-47d7-9ca3-086fd9fb8bbd` | Approve Population3 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `bf77a5e8-0792-4b0b-a30d-7a9d8e656aec` | Approve Population4 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `37400616-3b36-439c-b423-87ec973f9e65` | Approve Population4 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `7388a733-0d22-4329-b8cf-ec2ed4f21bb0` | Approve Population5 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `95ca2c0b-d77e-413a-9f42-235dab869acd` | Approve Population6 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `3bd0dd00-08e8-4404-ac72-3c95d43f5af6` | Approve Population6 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `8a619dc5-2ffe-48ca-b5a1-505e29b41d27` | Approve Population7 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `08ec2bcb-0396-4a2a-9650-73a14921a149` | Approve Population7 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `521c21e7-1e9d-4368-853d-5df98bff18bc` | Approve Population8 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `aff6b4fc-9ab6-48c6-9bc2-8c35e0418838` | Approve Population9 Assignment - Department Approval | Approve Assignment - Department Approval | `01a88294-91ce-4a19-8b08-19c72ae87b9a` |
| `67ad544c-2b90-498e-80b0-00da36792438` | Approve Population9 Assignment - Sponsor Approval | Approve Assignment - Sponsor Approval | `2f2adb96-7150-4522-abff-eef4966994d9` |
| `72559263-65fe-4c8b-84ce-99ddee1772a9` | Update Population1 Assignment | Assignment Details | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` |
| `480f4c6a-4e36-47ec-9bea-cf9563c19204` | Update Population10 Assignment - without Sub-Organization | Assignment Details - without Sub-Organization | `df802b02-340f-49b3-8380-2fc626684ddb` |
| `32453a77-e268-452d-8dc5-ebaedcd644fe` | Update Population2 Assignment - without Sub-Organization | Assignment Details - without Sub-Organization | `df802b02-340f-49b3-8380-2fc626684ddb` |
| `12e04c0d-6a73-4177-a1f1-bdac74890e19` | Update Population3 Assignment | Assignment Details | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` |
| `99059422-e556-4217-8f09-936caa164722` | Update Population3 Assignment - without Sub-Organization | Assignment Details - without Sub-Organization | `df802b02-340f-49b3-8380-2fc626684ddb` |
| `5cb8ea28-7bf9-409b-9270-6f1155a415eb` | Update Population4 Assignment Details | Assignment Details | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` |
| `9a5f0c87-4deb-46d8-9491-f94f9f50cc88` | Update Population5 Assignment - without Sub-Organization | Assignment Details - without Sub-Organization | `df802b02-340f-49b3-8380-2fc626684ddb` |
| `06ee2709-e3aa-4e9c-abdb-f1aad59fb52b` | Update Population6 Assignment | Assignment Details | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` |
| `795bb5c3-aace-4083-943f-dfbab273b74f` | Update Population9 Assignment | Assignment Details | `583638b9-3fc4-45f9-92ab-bb7b3ec4ed39` |

## Orphans to delete in UI (optional cleanup)

61 actions created 2026-10-08 on this workflow are unused duplicates.
Delete/archive them in the workflow designer after remapping (API cannot delete workflow actions).

