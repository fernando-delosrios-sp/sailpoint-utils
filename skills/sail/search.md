# Search

Flags: `sail search --help` (alias `se`).

## Intent map

| Intent | Command / Method | Output |
| --- | --- | --- |
| Inline query (preferred) | `sail api post /v3/search -b '{"indices":["<idx>"],"query":{"query":"<query>"}}'` | Direct JSON stream to stdout/pipe |
| File export query | `sail search query "<query>" --indices <idx>` | Writes JSON file to `search_results/` |
| Template search | `sail search template` | Template query execution |

Indices accepted: `accessprofiles`, `accountactivities`, `entitlements`, `events`, `identities`, `roles`.

### Inline Search (No Disk Litter)

`sail search query` always writes output to a file in `search_results/` rather than terminal stdout. For interactive tasks, debugging, or piping results to `jq`, prefer raw REST search:

```bash
sail api post /v3/search -b '{"indices":["identities"],"query":{"query":"status:ACTIVE"}}' --env <name> 2>&1 | grep -v '^[0-9]\{4\}/' | grep -v '^Status:' | jq .
```

Always pass `--env <name>`. Search is read-only; any subsequent mutation that acts on hits requires the goal confirm in `SKILL.md`.

For aggregations, custom payloads, or `searchAfter` pagination past 10,000 rows, consult [`api/conventions.md`](api/conventions.md).

## Done when

The query completed and search hits are summarized or the export file path is delivered to the operator.
