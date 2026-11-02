# Workflows

Flags: `sail workflow --help` (alias `work`).

## Intent map

| Intent | Start with | Notes |
| --- | --- | --- |
| List | `sail workflow list` | Table of workflow names & IDs |
| Get | `sail workflow get <id>` | Prints JSON to STDERR; pipe with `2>&1 \| jq .` |
| Download JSON | `sail workflow download` | Optional `-f <folder>` or `-d <dir>` |
| Create / update | `sail workflow create`, `update` | `-f <file>` or `-d <dir>` |
| Delete | `sail workflow delete <id>` | Target workflow ID |

Always pass `--env <name>`. Mutating goals (create, update, delete) use the single goal confirm from `SKILL.md`.

Create and update take `-f` file paths or `-d` a directory of JSON files. One workflow per file. Round-trip edits through downloaded JSON.

> [!NOTE]
> `sail workflow get <id>` outputs JSON to STDERR. To pipe to `jq`: `sail workflow get <id> --env <name> 2>&1 | jq .`.

There is no test subcommand in CLI. Test executions run through the Workflows group in [`api/index.md`](api/index.md) (`POST /v3/workflows/:id/test`) or the tenant UI. Workflow executions history is queried via `sail api get /v3/workflow-executions`.

## Done when

The workflow list, get, or download succeeded, or the create, update, or delete completed under the confirmed goal.
