# Transforms

Official: [CLI Transforms](https://developer.sailpoint.com/docs/tools/cli/transforms/). Flags: `sail transform --help`.

## Intent map

| Intent | Start with |
| --- | --- |
| List / download | `sail transform list`, `sail transform download` |
| Create / update / delete | `sail transform create`, `update`, `delete` |
| Preview | `sail transform preview` — prefer non-interactive flags (`--profile`, `--identity`, `--file`, `--result-only`) so the agent is not stuck in prompts |

Always `--env <name>`. Mutating goals use the single goal confirm from `SKILL.md`.

## Gotchas

- Interactive preview prompts block automation; pass the direct-mode flags from `--help`.
- Large lists: paginate or filter per `--help`; otherwise fetch what the CLI returns and say if truncated.

## Done when

Transform CRUD/download finished, or preview output is returned to the operator.