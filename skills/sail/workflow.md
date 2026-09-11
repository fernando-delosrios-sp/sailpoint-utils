# Workflows

Official: [CLI Workflows](https://developer.sailpoint.com/docs/tools/cli/workflow). Flags: `sail workflow --help` (alias `work`).

## Intent map

| Intent | Start with |
| --- | --- |
| List / get | `sail workflow list`, `sail workflow get` |
| Download JSON | `sail workflow download` |
| Create / update from file | `sail workflow create`, `sail workflow update` |
| Delete | `sail workflow delete` |

Always `--env <name>`. Mutating goals use the single goal confirm from `SKILL.md`.

## Gotchas

- Round-trip is file-based JSON download/create/update — treat downloaded files as source of truth for edits.
- There is no reliable `test` subcommand in current CLI; exercise via tenant APIs or the UI if needed.
- For Forms or other objects without a workflow subcommand, use [`api.md`](api.md).

## Done when

The workflow list/get/download succeeded, or the create/update/delete completed under the confirmed goal.