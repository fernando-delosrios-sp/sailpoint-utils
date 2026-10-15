# Environments and auth

Config lives in `~/.sailpoint/config.yaml`. PAT secrets live in the OS keyring. Flags: `sail env --help` and `sail set --help`.

Collect name, tenant, and auth choices with the host’s interactive question UI.

## Commands

| Intent | Command |
| --- | --- |
| List / show | `sail env list`, `sail env show [name]` |
| Create | `sail env create <name>` |
| Update / delete | `sail env update [name]`, `sail env delete [name]` |
| Auth mode | `sail set auth pat` or `sail set auth oauth` |
| Store PAT | `sail set pat` for the target env |

This skill passes `--env <name>` on each command. Leave `sail env use` for the case where the operator wants to change their shell default.

## Create

1. Interactive questions: **environment name** (short label) and **tenant** (name such as `acme`, or an HTTPS URL such as `https://acme.identitynow-demo.com`). A tenant name uses the `identitynow.com` domain. A URL is required for any other domain. A browser URL or API URL is acceptable input.
2. Run `sail env create <name>` and supply the collected tenant when the CLI asks. On a successful probe the CLI derives the tenant URL and the API URL and skips the confirmation prompts. On a failed probe it asks for both URLs; if it fails again, fix them with `sail env update <name>` before any other call.
3. Choose auth with an interactive question. Prefer PAT for agent runs.
4. Run `sail set pat --env <name>` in the agent terminal. The operator types the client ID and secret there (`*` echoes). Then `sail set auth pat` if the mode is not already PAT.
5. Continue the original goal with `--env <name>`.

The first PAT is created in the tenant admin UI. Later PAT management is the [Personal Access Tokens](api/groups/personal-access-tokens.md) group, which itself requires a working auth.

### OAuth

`sail set auth oauth` runs the authorization-code flow with PKCE. It needs an interactive terminal:

1. The CLI opens a browser and prints a confirmation code.
2. The operator signs in. The page shows the same confirmation code and a one-time code that starts with `sp1.`.
3. The operator pastes that one-time code into the CLI that started the sign-in.

The CLI refuses a code from a different attempt. Unattended runs use PAT.

### When the CLI stops

| Error | Fix |
| --- | --- |
| `no environment is configured` | `sail env create`, or set `SAIL_BASE_URL`, `SAIL_CLIENT_ID`, and `SAIL_CLIENT_SECRET` |
| `no active environment is selected` or the active name does not exist | `sail env use <name>` or `sail env create` |
| missing BaseURL or TenantURL | `sail env update <name>` |
| no PAT client ID or secret stored | `sail set pat`, or set `SAIL_CLIENT_ID` and `SAIL_CLIENT_SECRET` |
| `invalid authtype configured` | `sail set auth pat` or `sail set auth oauth` |
| PAT rejected | Wrong, deleted, or from another tenant. Run `sail set pat` again |

When `SAIL_BASE_URL` is set it overrides the named environment for that process, and `SAIL_CLIENT_ID` / `SAIL_CLIENT_SECRET` supply the PAT. Clear those variables when a named `--env` misbehaves. Named environments are the path for interactive multi-tenant work.

## Done when

The named environment exists and a read succeeds (`sail env show --env <name>` or a small `sail api get`), or the operator has the exact install or auth step still open.
