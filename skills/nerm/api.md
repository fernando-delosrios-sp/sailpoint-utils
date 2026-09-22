# nerm api

Official indexes: [NERM v1](https://developer.sailpoint.com/docs/api/nerm/v1), [NERM v2025](https://developer.sailpoint.com/docs/api/nerm/v2025/). Auth and association: [`env.md`](env.md).

Transport only — look up method, path, query, and body on the **specific operation** page before every call. Do not invent paths or swap create/update field names.

## Commands

```bash
pwsh -NoProfile -File scripts/nerm_api.ps1 get    -Env <name> <path> [-Query key=value ...]
pwsh -NoProfile -File scripts/nerm_api.ps1 post   -Env <name> <path> [-Body '<json>' | -BodyFile body.json] [-Query key=value ...]
pwsh -NoProfile -File scripts/nerm_api.ps1 put    -Env <name> <path> [-Body '<json>' | -BodyFile body.json]
pwsh -NoProfile -File scripts/nerm_api.ps1 patch  -Env <name> <path> [-Body '<json>' | -BodyFile body.json]
pwsh -NoProfile -File scripts/nerm_api.ps1 delete -Env <name> <path>
```

| Flag | Meaning |
| --- | --- |
| `-Env` | Sail environment name (required) |
| path | Resource under the sidecar `nermurl` (leading `/` optional) |
| `-Query` | Query param `key=value` (repeatable); use literal keys like `query[limit]=100` |
| `-Body` | Raw JSON body string |
| `-BodyFile` | JSON body from file |
| `-Paginate` | GET only: follow `_metadata` until exhausted or `-MaxPages` |

## Path and body conventions

- Match the tenant’s API generation: legacy/v1 resources often look like `/profiles`, `/profile_types`, `/users`; v2025 paths include the version prefix (e.g. `/v2025/delegations`). Confirm on the operation page.
- Create/update bodies are usually wrapped: `{ "profile": { … } }`, `{ "user": { … } }`. POST create and PATCH update schemas **differ** — use the create doc for POST and the update doc for PATCH.
- Headers: `Authorization: Bearer <token>`, `Accept: application/json`, `Content-Type: application/json` on bodies (helper sets these).

## Pagination

Collection GETs commonly return `{ "<resource>": [ … ], "_metadata": { "total", "limit", "offset" } }` with `query[limit]` and `query[offset]`.

Without `-Paginate`:

1. Request with `-Query 'query[limit]=<page>'` and `-Query 'query[offset]=<n>'` (typical page 100; check the endpoint).
2. Append the resource array; advance offset by page size.
3. Stop when a page returns fewer than `limit` items or `offset + limit >= total`.
4. Cap the loop and report how many were fetched if still incomplete.

With `-Paginate`, the helper walks `_metadata` and prints a single JSON document merging the primary collection key.

## Gotchas

- Guessing paths or bodies → open the operation doc first.
- Reusing PATCH field names on POST (e.g. `delegatee_id` vs `delegate_id`) → wrong schema.
- Double `/api` in the URL → fix `nermurl` or the path, not both.
- `nerm-plus` / connector clients are evidence of shapes, not a substitute for official docs.

## Done when

The requested method/path completed (or pagination finished / capped with a clear report), and stdout/errors are summarized for the operator without secrets.
