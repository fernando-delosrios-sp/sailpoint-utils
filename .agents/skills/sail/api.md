# sail api

`sail api` calls the API host stored on the selected environment. The path, including its `/service/vN` prefix, comes from the group file. `/v2026` is the secondary current prefix in front of that; it is not legacy. Examples in `sail api --help` that show `/beta/...` are legacy; ignore them.

## Load

1. Open [`api/index.md`](api/index.md) and the one group file for the object.
2. Open [`api/conventions.md`](api/conventions.md) when the call lists, filters, sorts, paginates, or searches.

**Done when:** the group file is loaded before the first request, and conventions are loaded when the call is a collection or a search.

## Call

Always `--env <name>`.

| Method | Command | Body / query |
| --- | --- | --- |
| GET | `sail api get <path>` | repeated `-q key=value` |
| POST | `sail api post <path>` | `-b` or `-f`. `--content-type` when the body is not JSON |
| PUT | `sail api put <path>` | `-b` or `-f` |
| PATCH | `sail api patch <path>` | `-b` or `-f`. Optional `-o` to write the response |
| DELETE | `sail api delete <path>` | repeated `-q key=value` |

Shared flags: repeated `-H "Key: Value"`, `-j` JSONPath, `-p` pretty. Take any other flag from `sail api <method> --help`.

An endpoint marked Experimental in the group file needs `-H "X-SailPoint-Experimental: true"`.

`sail` attaches the bearer token. A 401 is an auth gap: return to [`env.md`](env.md). Leave `/oauth/token` alone.

A trailing `Status:` line after the body is CLI chrome. Strip it before parsing JSON.

Use the domain command (`workflow`, `transform`, `search`, `spconfig`, `conn`, `cluster`, `va`) when that command already does the job. Those commands may still call a legacy path; their `--help` prints the default endpoint.

## Pagination

`sail api` has no pager. For a collection GET:

1. `-q limit=250 -q offset=<n>` unless the group file states another page size.
2. Append the page. Advance offset by the page size.
3. Stop when a page returns fewer items than `limit`.
4. Cap a long loop and report how many rows were fetched.

Search paging past 10,000 rows is `searchAfter` in [`api/conventions.md`](api/conventions.md). On 429, wait the `Retry-After` seconds and retry.

## Done when

The method and path finished, or pagination finished or capped with a count, and stdout or the error is summarized.
