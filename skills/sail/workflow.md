# Workflows

Flags: `sail workflow --help` (alias `work`).

## Intent map

| Intent | Start with |
| --- | --- |
| List / get | `sail workflow list`, `sail workflow get` |
| Download JSON | `sail workflow download` |
| Create / update from file | `sail workflow create`, `sail workflow update` |
| Delete | `sail workflow delete` |

Always `--env <name>`. Mutating goals use the single goal confirm from `SKILL.md`.

Create and update take `-f` file paths or `-d` a directory of JSON files, matching the examples in `--help`. One workflow per file. Round-trip edits through the downloaded JSON.

There is no test subcommand. Exercise a workflow through the Workflows group in [`api/index.md`](api/index.md) or the tenant UI. Forms and other objects without a workflow subcommand go through [`api.md`](api.md).

## Done when

The list, get, or download succeeded, or the create, update, or delete completed under the confirmed goal.
