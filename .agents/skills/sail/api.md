# sail api

`sail api` calls the API host stored on the selected environment. The path, including its `/service/vN` prefix, comes from the group file. `/v2026` is the secondary current prefix in front of that; it is not legacy. Ignore examples in `sail api --help` showing `/beta/...` as legacy.

## Discovery

- Consult [`api/index.md`](api/index.md) and the matching group file to discover unknown paths, parameters, or schemas.
- If the endpoint path and parameters are already known (e.g. `/v3/search`, `/v3/sources`, `/transforms/v1`, `/identities/v1`), execute directly without loading reference files.
- Consult [`api/conventions.md`](api/conventions.md) when formatting filters, sorting, or pagination.

## Calling & Stream Output

Always pass `--env <name>`.

| Method | Command | Body / query |
| --- | --- | --- |
| GET | `sail api get <path>` | repeated `-q key=value` |
| POST | `sail api post <path>` | `-b '{"..."}'` or `-f <file>`. `--content-type` if not JSON |
| PUT | `sail api put <path>` | `-b '{"..."}'` or `-f <file>` |
| PATCH | `sail api patch <path>` | `-b '{"..."}'` or `-f <file>`. Optional `-o <file>` to save response |
| DELETE | `sail api delete <path>` | repeated `-q key=value` |

Shared flags: repeated `-H "Key: Value"`, `-j` JSONPath, `-p` pretty. Other flags from `sail api <method> --help`.
Endpoints marked Experimental need `-H "X-SailPoint-Experimental: true"`.

### Extracting Clean JSON

The `sail` CLI prints timestamped INFO logs and the HTTP response body to **STDERR**, and prints only the HTTP status (`Status: 200 OK`) to **STDOUT**. Piping raw `sail api` directly to `jq` fails because stdout contains only the status line.

To extract pure JSON in the shell:
```bash
sail api get <path> --env <name> 2>&1 | grep -v '^[0-9]\{4\}/' | grep -v '^Status:'
```
This merges streams, strips CLI log lines and the trailing `Status:` line, and yields valid JSON ready for `jq` or file redirection.

`sail` attaches the bearer token automatically. A 401 is an auth gap: return to [`env.md`](env.md).

Use domain commands (`workflow`, `transform`, `search`, `spconfig`, `conn`, `cluster`, `va`) when they provide higher-level operations.

## Pagination

`sail api` has no automatic pager. For collection GET requests:

1. Pass `-q limit=250 -q offset=<n>` (default collection limit is 250).
2. Append each page and increment `offset` by page size.
3. Stop when a page returns fewer items than `limit`.
4. Cap long loops and report the count fetched.

Search paging past 10,000 rows uses `searchAfter` in [`api/conventions.md`](api/conventions.md). On 429, wait `Retry-After` seconds and retry.

## Done when

The API request or pagination completed, and the resulting payload or clear error is reported.
