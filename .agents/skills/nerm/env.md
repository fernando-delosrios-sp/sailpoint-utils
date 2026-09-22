# Environments and auth

Official: [NERM getting started](https://developer.sailpoint.com/docs/api/nerm/v1/getting-started), [Authentication](https://developer.sailpoint.com/docs/api/nerm/v1/authentication). For Sail env/auth (`sail env`, `sail set pat`), invoke the `sail` skill.

NERM tenants associate to ISC (SHF) tenants. This skill reuses Sail environment **names** and PAT credentials. Secretless NERM URLs live in `~/.sailpoint/nerm.yaml` — never edit Sail’s `config.yaml` schema with NERM fields.

Collect env name and NERM URL with the host’s interactive question UI — never a chat “Reply with:” list.

## Sidecar shape

```yaml
environments:
  emea-tes-team:
    nermurl: https://mycompany.nonemployee.com/api
```

| Field | Meaning |
| --- | --- |
| Map key | Exact Sail environment name (`sail env list`) |
| `nermurl` | NERM API base (browser tenant URL + `/api`, e.g. `https://mycompany.nonemployee.com/api`) |

## Commands

| Intent | Command |
| --- | --- |
| List associations | `pwsh -NoProfile -File scripts/nerm_api.ps1 env list` |
| Show one | `pwsh -NoProfile -File scripts/nerm_api.ps1 env show -Env <name>` |
| Set / update URL | `pwsh -NoProfile -File scripts/nerm_api.ps1 env set -Env <name> -NermUrl <url>` |
| Remove association | `pwsh -NoProfile -File scripts/nerm_api.ps1 env unset -Env <name>` |

Run the script from this skill directory, or pass its absolute path.

## Associate + auth

1. Interactive questions: **Sail environment** (from `sail env list`; create via `sail` skill if needed), **NERM API URL** (browser URL with `/api` suffix).
2. Run `pwsh -NoProfile -File scripts/nerm_api.ps1 env set -Env <name> -NermUrl <url>`.
3. Confirm Sail PAT exists for that env (`sail set pat --env <name>` in the agent terminal if missing). Prefer SHF PAT over legacy NERM API keys.
4. Optional smoke read: `pwsh -NoProfile -File scripts/nerm_api.ps1 get -Env <name> /profile_types -Query 'query[limit]=1'`.
5. Continue the original goal with `-Env <name>`.

## Auth resolution (helper)

Bearer token for NERM requests, in order:

1. Explicit `NERM_TOKEN` (or `SAIL_ACCESS_TOKEN`) in the process environment.
2. Mint JWT via ISC `POST {baseurl}/oauth/token` using `SAIL_CLIENT_ID` / `SAIL_CLIENT_SECRET` when set.
3. Otherwise read Sail PAT client id/secret from the OS keyring (`environments.pat.clientid` / `environments.pat.clientsecret`, account = env name) and mint the same way.

Recommended auth is the SHF JWT (`Authorization: Bearer <access_token>`), not a legacy NERM API key, unless the operator supplies `NERM_TOKEN` as that key.

## Gotchas

- **Sail `env update` / recreate:** may rewrite `config.yaml`; the sidecar is independent and survives. Re-run `env set` only when the Sail env **name** changes.
- **URL vs path:** `nermurl` already ends at `/api`. Request paths are resources like `/profiles` or `/v2025/delegations` — do not double `/api`.
- **Demo tenants:** ISC may use `*.identitynow-demo.com` while NERM stays on `*.nonemployee.com` (or a customer host). Association is by Sail env name, not hostname derivation.
- **Token lifetime:** SHF JWTs expire quickly (~12 minutes). The helper mints per invocation; do not cache tokens in chat.

## Done when

The named Sail env has a sidecar `nermurl` and a read such as `env show` or a harmless `get` succeeds, or the operator has the exact next Sail PAT / associate step.
