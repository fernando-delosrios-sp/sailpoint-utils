# nerm command reference

Global flags: `--profile <name>`, `--compact`.

Install: `npm install -g nerm-cli`. Binary name: `nerm`.

## Connection

```bash
nerm connection add NAME --url URL [--token TOKEN | --token-env VAR] [--use]
nerm connection list
nerm connection show NAME
nerm connection use NAME
nerm connection remove NAME
nerm connection test
```

## Resources

`get` calls the singular route (`GET /profile_types/{id}`, `GET /ne_attributes/{id}`, and the same pattern for other resources). It does not scan a list.

JSON bodies are sent as given, including the API wrapper (`{"profile": {...}}`). Singular creates use the singular path (`POST /profile`, `POST /user`, `POST /role`, `POST /user_role`, `POST /user_profile`, `POST /role_profile`, `POST /user_manager`). Deletes that the API exposes only on the singular path use that path (`DELETE /user_role/{id}`, `DELETE /user_profile/{id}`, `DELETE /role_profile/{id}`).

```bash
nerm profile-types list [--name NAME] [--archived]
nerm profile-types get ID
nerm profile-types create|update ID|delete ID --body-file body.json
nerm profile-types attributes PROFILE_TYPE_ID [--search TEXT]
nerm profile-types sync PROFILE_TYPE_ID --body-file body.json
nerm profile-types unsync PROFILE_TYPE_ID ATTRIBUTE_ID
nerm profile-types grant-role --body-file body.json
nerm profiles list [--name NAME] [--profile-type-id ID] [--status STATUS]
nerm profiles get ID
nerm profiles create|update ID|delete ID --body-file body.json
nerm profiles create-many|update-many|delete-many --body-file body.json
nerm profiles avatar ID
nerm profiles avatar-upload ID --file PATH
nerm profiles attachment ID ATTRIBUTE_ID
nerm profiles attachment-upload ID ATTRIBUTE_ID --file PATH
nerm users list [--name NAME] [--login LOGIN] [--email EMAIL] [--type TYPE]
nerm users get ID
nerm users create|update ID|delete ID --body-file body.json
nerm users create-many|update-many --body-file body.json
nerm users avatar ID
nerm users avatar-upload ID --file PATH
nerm user-roles list [--user-id ID] [--role-id ID]
nerm user-roles get|update ID
nerm user-roles create|delete ID
nerm user-roles create-many|update-many --body-file body.json
nerm user-managers list [--user-id ID] [--manager-id ID]
nerm user-managers get|update ID
nerm user-managers create
nerm user-managers create-many|update-many --body-file body.json
nerm user-profiles list [--user-id ID] [--profile-id ID] [--relationship-type owner|contributor]
nerm user-profiles get|update ID
nerm user-profiles create|delete ID
nerm user-profiles create-many|update-many|delete-many --body-file body.json
nerm roles list [--type TYPE]
nerm roles get|update ID
nerm roles create
nerm roles create-many|update-many --body-file body.json
nerm role-profiles list [--role-id ID] [--profile-id ID]
nerm role-profiles get|update ID
nerm role-profiles create|delete ID
nerm role-profiles create-many|update-many --body-file body.json
nerm attributes list [--label LABEL] [--data-type TYPE]
nerm attributes get|update ID|delete ID
nerm attributes create --body-file body.json
nerm attribute-options list [--ne-attribute-id ID]
nerm attribute-options get|update ID|delete ID
nerm attribute-options add|create-many|update-many --body-file body.json
nerm identity-proofing list [--profile-id ID] [--result pass|fail]
nerm forms list|get ID|create|update ID|delete ID
nerm form-attributes list|get ID|create|update ID|delete ID
nerm pages create-profile|create-workflow --body-file body.json
nerm page-contents list|get ID|create|update ID|delete ID
nerm page-elements list|get ID|create|update ID|delete ID
nerm page-content-translations list|get ID|create|update ID|delete ID
nerm risk-levels list [--label LABEL]
nerm risk-levels get ID
nerm risk-scores list [--object-id ID] [--object-type TYPE]
nerm risk-scores get ID
nerm system-roles list
nerm isc-accounts list [--category CATEGORY] [--status STATUS] [--use-schema] [--override-sync-toggle]
nerm isc-accounts get|update ID
```

There is no list or get for pages. The published API only creates them.

List flags on retrieval commands: `--limit`, `--offset`, `--force-all`, `--order`, `--metadata`.

Attachment and avatar uploads are multipart form data with the field name `file`.

## Delegations

```bash
nerm delegations list [--delegator-id ID] [--delegate-id ID] [--expired]
nerm delegations get ID
nerm delegations create --body-file body.json
nerm delegations update ID --body-file body.json
nerm delegations delete ID
```

Create body uses `delegator_id`, `delegate_id`, and `expiration` (ISO-8601).

## Workflows, audit, search

```bash
nerm workflows sessions [--status STATUS] [--workflow-id ID]
nerm workflows session ID
nerm workflows update ID [--run] --body-file body.json
nerm workflows statuses
nerm workflows submit [--run] --body-file body.json
nerm workflows job JOB_ID
nerm workflows attachment ID ATTRIBUTE_ID
nerm workflows attachment-upload ID ATTRIBUTE_ID --file PATH
nerm workflows new-automated|new-batch|new-create|new-login|new-password-reset|new-registration|new-update --body-file body.json
nerm workflow-actions list [--workflow-id ID]
nerm workflow-actions create-approval|create-notification|create-rest-api --body-file body.json
nerm workflow-action-performers create --body-file body.json
nerm audit query [--subject-type TYPE] [--event-type TYPE] [--subject-id ID]
nerm search run --body-file search.json
nerm search list
nerm search save|update ID --body-file search.json
nerm search run-saved ID
nerm idproxy reassign ID --body-file body.json
nerm idproxy delete-identity ID
nerm permissions create --body-file body.json
nerm system-role-permissions create --body-file body.json
nerm languages update LOCALE --body-file body.json
```

`workflow-actions list` calls `GET /workflow_actions` and returns that document. It is not a paged collection. Other `create-*` action commands follow the same pattern as `create-approval`; the suffix matches the action type (`create-set-attributes`, `create-status-change`, and the rest of the workflow action routes).

`workflows session` calls `GET /workflow_sessions/{id}`. `--run` on submit and update sets the `run` query parameter.

Advanced search requires `condition_rules_attributes`. Do not use SQL-style `field`/`operator` keys.

## Configuration dump

Public API export only. This is not a portable backup, an import source, NERM Admin → System → Configuration Import, or a `class_name` bundle. Workflow steps, conditions, and performers are omitted because the public API does not return them.

```bash
nerm dump --out ./tenant-config [--bundle tenant.json] [--collections pages,forms,workflows]
```

`dump` writes `manifest.json` plus one JSON file per object. File names are the object name, label, or human uid, never the record id. Composites:

- `attributes/<name>.json` — attribute and its `ne_attribute_options`. Orphan options go in `attribute-options/<option>.json`.
- `forms/<name>.json` — form and its `form_attributes`.
- `pages/<name>.json` — page, `page_elements`, and `page_contents`. The public API has no page list, so a page with no name is filed under a heading on that page or the names of the forms it contains. `name` stays null in that case. The page id is not the file name.
- `workflows/<name>.json` — `GET /workflow_actions` grouped by `workflow_id`. `name` is null unless `workflow_name` or `workflow_label` is present. A non-generic action description may appear as `label_guess` and as the file name only. It is not the workflow name. The file is `unnamed-workflow.json` when neither is available.
- `profile-types`, `roles`, `risk-levels`, `system-roles`, `page-content-translations`.

`--bundle` writes the same composites into one JSON file. There is no automatic import path. Dump files contain tenant-specific ids and public-API response shapes, so do not send them back as request bodies. Use resource-specific commands or `nerm api request` for deliberate changes where the API exposes a write operation.

`risk-levels` and `system-roles` are GET-only in `docs/nerm-api-spec.json`. Portals and tables are not in that spec and have no list command, so they are listed under `omitted` in `manifest.json`.

## Raw REST

```bash
nerm api request GET /profiles --query 'query[limit]=1'
nerm api request POST /delegations --body-file body.json
```

Path is the resource under the profile `/api` base. Do not prefix `/api` again.
