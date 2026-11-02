# Transforms

Flags: `sail transform --help` (alias `tran`).

## Intent map

| Intent | Command | Notes |
| --- | --- | --- |
| List | `sail transform list` | Displays table of transform names & IDs |
| Get single transform | `sail api get /v3/transforms/<id>` | Note: `sail transform get` does not exist |
| Download all | `sail transform download` | Downloads all transforms as JSON files |
| Create / update / delete | `sail transform create`, `update`, `delete` | Pass `-f <file>` |
| Preview | `sail transform preview` | Pass `--file <f>`, `--identity <id>` or `--profile <p>`, plus `--result-only` |

Always pass `--env <name>`. Mutating operations (create, update, delete) take the goal confirm from `SKILL.md`.

> [!IMPORTANT]
> `sail transform` does NOT have a `get` subcommand. Fetch individual transforms via `sail api get /v3/transforms/<id> --env <name>` or query by name with `-q 'filters=name eq "<name>"'`.
>
> `sail transform preview` prompts interactively unless both `--file` and `--identity` (or `--profile`) along with `--result-only` are passed.

Default endpoint is `/v3/transforms` (`--transforms-endpoint`). If needed, use `/transforms/v1` via [`api.md`](api.md).

## Done when

The transform create, read, update, delete, download, or preview output is complete.
