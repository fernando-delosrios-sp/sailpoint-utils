# Alternate assignment workflows (c)

Thin Config Import packages that **Update** the live API shells and **Create** their action graphs (new child ids/uids). No ProfileType / pages / attributes.

| Workflow | id | uid | Import file |
|---|---|---|---|
| Add Assignment Details (c) | `6baf4a98-fcf0-4b45-b567-7276ca2d1ca6` | `b3_aad_details_c_v5` | `NERM_emea-tes-team_import_add_assignment_details_c.json` |
| Add Assignment (c) | `4f339dd6-154b-4f6a-ac6b-6ad3d02ddf67` | `b3_aa_people_c_v3` | `NERM_emea-tes-team_import_add_assignment_c.json` |
| Update Assignment (c) | `584cbc70-90a0-4b4f-bea9-b60a586f9f85` | `b3_ua_c_v5` | `NERM_emea-tes-team_import_update_assignment_c.json` |

## Import order

1. Details (c) — expect **Update** (1 workflow) + large **Create** (actions/steps).
2. Add (c) — same; Run Workflow retargets to Details (c).
3. Update (c)

If Review shows only the workflow under Update and Create is empty, the package is wrong (shell-only). Do not apply.

## Notes

- Workflow object omits `archived_on` (setting it caused shell Update to fail).
- Child objects always get fresh ids/uids so they land in Create.
- Regenerate: `python3 scripts/generate_assignment_workflows_c.py`
