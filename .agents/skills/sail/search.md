# Search

Official: [CLI Search](https://developer.sailpoint.com/docs/tools/cli/search). Flags: `sail search --help`.

## Intent map

| Intent | Start with |
| --- | --- |
| Ad-hoc query | `sail search query` (indices, query string per `--help`) |
| Template | `sail search template` |

Always `--env <name>`. Results typically write JSON under `search_results/` (CLI 2.0+ is JSON-oriented).

## Gotchas

- For raw Search API control (body, `searchAfter`), use [`api.md`](api.md) against the Search endpoint and paginate there.
- Template paths can be configured via `sail set`; see [`env.md`](env.md) / `sail set --help`.
- Reads only — no mutating goal confirm unless a follow-on write uses the results.

## Done when

Query/template completed and the operator has the result path or summarized hits.