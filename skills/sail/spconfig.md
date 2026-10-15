# SP-Config

Flags: `sail spconfig --help` (alias `spcon`). Object types for `--include` / `--exclude` are listed by `sail spconfig export --help`.

## Intent map

| Intent | Start with |
| --- | --- |
| Export | `sail spconfig export --include <TYPE> --wait` |
| Import | `sail spconfig import --filePath <file> --wait` |
| Job status / download | `sail spconfig status`, `sail spconfig download` |
| Template | `sail spconfig template` |

Always `--env <name>`. Export and import change the tenant. Use the single goal confirm from `SKILL.md` and name the object types in that prompt.

Jobs are async. `--wait` blocks until the job finishes and, on import, downloads the result. Without it, poll `status`, then `download`.

Cross-tenant promote: export from the source env, then import into the target env. Each confirm names its own env.

Raw job control is the SP-Config group via [`api.md`](api.md).

## Done when

The export or import job finished, or its status is reported, and the operator knows the file paths.
