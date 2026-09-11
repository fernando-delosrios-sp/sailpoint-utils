# sail api

Official: [CLI API](https://developer.sailpoint.com/docs/tools/cli/api/). Flags: `sail api --help` and `sail api get|post|put|patch|delete --help`.

Generic HTTP client over the tenant API base URL. Path is caller-supplied (include the version prefix).

## Defaults

- Path prefix when the operator did not name a version: **`/v2026/`**.
- Always pass `--env <name>`.
- JSON body: `--body` / `-b` or `--body-file` / `-f`. Query: repeated `-q key=value`. Headers: repeated `-H "Key: Value"`. Filter response: `--jsonpath` / `-j`.

## Pagination

No built-in pager. For collection endpoints:

1. Request with `-q limit=<page>` and `-q offset=<n>` (typical page 250; check the endpoint).
2. Append results; advance offset by page size.
3. Stop when a page returns fewer than `limit` items.
4. Cap the loop (e.g. stop after a large total) and report how many were fetched if still incomplete.

Search API: POST body; beyond ~10k use `searchAfter` per [standard collection parameters](https://developer.sailpoint.com/docs/api/standard-collection-parameters).

## Gotchas

- Experimental endpoints need `-H "X-SailPoint-Experimental: true"`.
- Multipart/binary upload is not a first-class `sail api` feature; stick to JSON/`--content-type` the CLI supports, or a dedicated command family when one exists.
- Response may include a `Status: …` line after the body; strip it before parsing JSON if needed.
- Prefer a domain command (`workflow`, `spconfig`, …) when one exists; use `api` for everything else.

## Done when

The requested method/path completed (or pagination finished / capped with a clear report), and stdout/errors are summarized for the operator.