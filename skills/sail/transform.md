# Transforms

Flags: `sail transform --help` (alias `tran`).

## Intent map

| Intent | Start with |
| --- | --- |
| List / download | `sail transform list`, `sail transform download` |
| Create / update / delete | `sail transform create`, `update`, `delete` |
| Preview | `sail transform preview` with `--file` and `--identity` or `--profile`, plus `--result-only` |

Always `--env <name>`. Mutating goals use the single goal confirm from `SKILL.md`.

The command's default endpoint is `/v3/transforms` (`--transforms-endpoint`). The collection path is `/transforms/v1` in the Transforms group. Keep the domain command on its default unless that call 404s, then override the flag or call the group-file path with [`api.md`](api.md).

Preview without those flags sits in an interactive prompt. Pass them so the run finishes.

## Done when

The transform create, read, update, delete, or download finished, or preview output is back with the operator.
