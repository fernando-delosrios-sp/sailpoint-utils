# Other sail families

Flags always from `sail <cmd> --help`. Hub: [CLI](https://developer.sailpoint.com/docs/tools/cli).

| Command | Role | Notes |
| --- | --- | --- |
| `rule` | List / download cloud rules | Tenant read; `--env` |
| `report` | Search-count style reports | May prompt for template variables; prefer non-interactive flags when available |
| `sanitize` | Strip tokens from HAR files | Local only |
| `sdk` | Bootstrap SDK projects / `init config` | Local; `sail sdk init config --env <name>` can emit SDK `config.json` from a CLI env |
| `jsonpath` | Evaluate workflow JSONPath against local JSON | Local only |
| `reassign` | Bulk ownership reassignment | Mutating — goal confirm; show env; scope carefully |
| `ui-plugins` | UI plugin lifecycle | Experimental; requires `SAIL_EXPERIMENTAL_UI_PLUGINS=1` |

Always `--env <name>` for tenant ops. Mutating goals use the single goal confirm from `SKILL.md`.

Anything not covered here or in a sibling file → [`api.md`](api.md).

## Done when

The chosen subcommand finished, or experimental/local prerequisites are stated clearly.