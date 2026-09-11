# SP-Config

Official: [CLI SPConfig](https://developer.sailpoint.com/docs/tools/cli/spconfig). Flags: `sail spconfig --help`.

## Intent map

| Intent | Start with |
| --- | --- |
| Export | `sail spconfig export` (often with `--wait`) |
| Import | `sail spconfig import` |
| Job status / download | `sail spconfig status`, `sail spconfig download` |
| Template | `sail spconfig template` |

Always `--env <name>`. Export/import are mutating or tenant-impacting — use the single goal confirm from `SKILL.md` (show the env).

## Gotchas

- Jobs are async; prefer `--wait` or poll `status` until complete, then `download`.
- Import can change many objects — state the object types/scope in the confirm prompt.
- Cross-tenant promote: resolve source env, export; resolve target env, import — each mutate confirm names its env.

## Done when

Export/import job finished (or status clearly reported), and files/paths are known to the operator.