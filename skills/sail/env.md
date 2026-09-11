# Environments and auth

Official: [CLI overview](https://developer.sailpoint.com/docs/tools/cli), [set](https://developer.sailpoint.com/docs/tools/cli/set). Flags: `sail env --help`, `sail set --help`.

Config lives in `~/.sailpoint/config.yaml` (`activeenvironment`, URLs per named env). PAT secrets go in OS keyring (CLI 2.0+), not the YAML.

Collect name, URLs, and auth choices with the host’s interactive question UI — never a chat “Reply with:” list. Do not require the `structured-choices` skill.

## Commands

| Intent | Command |
| --- | --- |
| List | `sail env list` |
| Show | `sail env show [name]` |
| Create | `sail env create <name>` — CLI prompts for tenant URL + API URL |
| Update / delete | `sail env update`, `sail env delete` |
| Auth mode | `sail set auth pat` or `sail set auth oauth` |
| Store PAT | `sail set pat` for the target env |

## Create + PAT

1. Interactive questions (one prompt each, or one multi-question gate): **environment name** (short label), **tenant URL** (e.g. `https://tenant.identitynow.com`), **API URL** (e.g. `https://tenant.api.identitynow.com`).
2. Run `sail env create <name>`; when the CLI asks for URLs, supply the answers already collected (stdin or the operator pastes the same values).
3. Auth mode via interactive question if unset — prefer PAT for agent runs.
4. Run `sail set pat --env <name>` in the agent terminal; operator pastes client ID/secret there. Never put the secret in chat.
5. Continue the original goal with `--env <name>`.

## Gotchas

- **`--env` vs `use`:** This skill passes `--env <name>` on each command. Avoid `sail env use` unless the operator explicitly wants to change their shell default.
- **`SAIL_BASE_URL` / `SAIL_CLIENT_ID` / `SAIL_CLIENT_SECRET`:** When set, they override YAML for that process (CI pattern). Prefer named envs for interactive multi-tenant work; clear conflicting env vars if a named env misbehaves.
- **OAuth:** Browser flow; fine for humans, awkward for unattended agents. Prefer PAT for agent-driven runs.

## Done when

The named environment exists and can authenticate (a read such as `sail env show --env <name>` or a harmless `sail api get` succeeds), or the operator has the exact next install/auth step.