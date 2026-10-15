# Search

Flags: `sail search --help` (alias `se`).

## Intent map

| Intent | Start with |
| --- | --- |
| Ad-hoc query | `sail search query "<query>" --indices <name>` |
| Template | `sail search template` |

Indices the command accepts: `accessprofiles`, `accountactivities`, `entitlements`, `events`, `identities`, `roles`. Results write JSON under `search_results/` unless `--folderPath` says otherwise. Template file location is `sail set searchTemplates`.

Always `--env <name>`. This command is read-only. A later write that uses the hits takes the mutating confirm from `SKILL.md`.

A custom body, aggregation, or `searchAfter` page past 10,000 rows is `sail api` against the Search group. Open [`api/conventions.md`](api/conventions.md) for that paging.

## Done when

The query or template finished and the operator has the result path or a summary of the hits.
