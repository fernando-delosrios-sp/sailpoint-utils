# Other sail families

Flags from `sail <cmd> --help`. Tenant calls use `--env <name>`. Mutating goals use the single goal confirm from `SKILL.md`.

| Command | Role | Notes |
| --- | --- | --- |
| `rule` | List or download cloud rules | Read |
| `report` | Search-count reports | May prompt for template variables. `-s` writes under `reports/` (`--folderPath` to move that) |
| `sanitize` | Strip tokens and origin URLs from HAR or log files | Local files only |
| `sdk` | `sail sdk init` scaffolds an SDK project | Local. Further flags from `sail sdk init --help` |
| `jsonpath` | `sail jsonpath eval` checks a workflow or trigger expression against a local JSON file | Local |
| `reassign` | Move ownership of sources, roles, access profiles, entitlements, identity profiles, governance groups, workflows | `--from`, `--to`. Narrow with `--object-types` or `--object-id`. `--dry-run` previews. `--force` skips the CLI's own prompt; the skill confirm still happens first |

Anything else is [`api.md`](api.md).

## Done when

The subcommand finished, or the missing flag or local prerequisite is stated.
