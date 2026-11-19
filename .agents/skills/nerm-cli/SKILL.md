---
name: nerm-cli
description: >-
  Drive SailPoint NERM (Non-Employee Risk Management) tenant APIs with the nerm
  CLI: saved connection profiles, profile/user/role/form/page/workflow/audit
  commands, and raw REST. Use when working with NERM, nonemployee.com, or NERM
  v1/v2025 APIs.
---

# nerm-cli

Use the `nerm` CLI for live NERM API work. Do not guess REST paths when a domain command exists. Command catalog: [reference.md](reference.md).

## Install

1. Confirm `nerm` is on PATH (`nerm version`). If missing: `npm install -g nerm-cli` (or `npx nerm-cli` for a one-off run).
2. Confirm a profile exists: `nerm connection list`.

## Profiles

Profiles store the NERM `/api` URL locally. Bearer tokens go in the OS credential store, or a named environment variable via `--token-env`. Never print tokens.

```bash
nerm connection add <name> --url https://tenant.nonemployee.com --token '<token>' --use
nerm connection add <name> --url https://tenant.nonemployee.com --token-env NERM_TOKEN --use
nerm connection list
nerm connection use <name>
nerm connection test
```

Pass `--profile <name>` on any command to override the default.

If no profile exists, collect URL and token through the host question UI, then run `connection add`.

## Execute

1. Select or create a profile.
2. For a named resource, use the matching command in [reference.md](reference.md).
3. For anything else, look up the official NERM v1 or v2025 operation, then `nerm api request METHOD PATH`.
4. Reads run immediately. Writes (create/update/delete/submit) require one interactive confirm that shows the profile name and NERM URL.
5. Pass JSON bodies with `--body-file` or stdin, not chat-pasted secrets.
6. Commands print JSON on stdout. Report that JSON without tokens.

## Routing

- Assignments, people, orgs, departments, locations: resolve profile type first (`nerm profile-types list`), then `nerm profiles list` or `nerm search run`.
- Delegations are user-to-user coverage only, never assignment records.
- Workflow session status vs profile business status are different APIs.
- Tenant configuration snapshots use `nerm dump`. It is a public-API export only, not a portable backup or an import source. It is not NERM Admin → System → Configuration Import and does not emit `class_name` bundles.
- Prefer domain commands over raw REST.

## Configuration dump

`nerm dump` writes the configuration the public API can return. It uses bearer-token public APIs only. Do not call `/react/.../export` or `/admin/import_configurations`.

```bash
nerm dump --out ./tenant-config
nerm dump --out ./tenant-config --bundle tenant.json --collections pages,forms,workflows
```

This is not Configuration Import format (`class_name` arrays such as `NERM_SEDemo_012026.json`). It has no automatic import path. Workflow steps, conditions, and performers are not on the public API and must not be invented.

Directory layout:

```
<out>/
  manifest.json
  attributes/<name>.json          # attribute plus its options
  attribute-options/<option>.json # options whose attribute was not returned
  forms/<name>.json               # form plus form_attributes
  pages/<name>.json               # page plus page_elements and page_contents
  workflows/<name>.json           # workflow_id plus actions for that id
  profile-types/<name>.json
  roles/<name>.json
  risk-levels/<name>.json
  system-roles/<name>.json
  page-content-translations/<name>.json
```

File names are the object name, label, or human uid. Duplicate names get a numeric suffix, or a human uid when that uid is not an id. Record ids stay inside the JSON and are not used as file names.

There is no workflow list. Actions from `GET /workflow_actions` are grouped by `workflow_id`. `name` is null unless the payload includes a real workflow name (`workflow_name` or `workflow_label`). A non-generic action description may be stored as `label_guess` and used only as the file name. Do not treat that description as the NERM workflow name. When no name or label exists, the file is `unnamed-workflow.json`.

Pages have no list route. A page file is assembled from `GET /page_elements` and `GET /page_contents`. Its file name is the page name when the API or the file has one. Otherwise it is a heading on the page, or the names of the forms on the page. `name` stays null unless a real page name exists. The page id is not the file name.

Do not treat dump files as request bodies. They contain tenant-specific ids and read response shapes. The public API has only partial write coverage and cannot reconstruct workflow graphs or safely remap all cross-object references. Use specific domain commands or `nerm api request` for deliberate, resource-level changes. `risk-levels` and `system-roles` are GET-only in `docs/nerm-api-spec.json`. Portals and tables are not in that spec and are not dumped.
