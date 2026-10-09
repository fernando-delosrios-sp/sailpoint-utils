---
name: nerm-cli
description: >-
  Drive SailPoint NERM (Non-Employee Risk Management) tenant APIs with the nerm
  CLI: saved connection profiles, profile/user/role/delegation/workflow/audit
  commands, and raw REST. Use when working with NERM, nonemployee.com, or NERM
  v1/v2025 APIs.
---

# nerm-cli

Use the `nerm` CLI for live NERM API work. Do not guess REST paths when a domain command exists. Command catalog: [reference.md](reference.md).

## Install

1. Confirm `nerm` is on PATH (`nerm version`). If missing: `npm install -g nerm-cli` (or `npx nerm-cli` for a one-off run).
2. Confirm a profile exists: `nerm connection list`.

## Profiles

Profiles store the NERM `/api` URL locally. Bearer tokens go in the OS credential store, or a named environment variable via `--token-env`. Never print tokens.

```bash
nerm connection add <name> --url https://tenant.nonemployee.com --token '<token>' --use
nerm connection add <name> --url https://tenant.nonemployee.com --token-env NERM_TOKEN --use
nerm connection list
nerm connection use <name>
nerm connection test
```

Pass `--profile <name>` on any command to override the default.

If no profile exists, collect URL and token through the host question UI, then run `connection add`.

## Execute

1. Select or create a profile.
2. For a named resource, use the matching command in [reference.md](reference.md).
3. For anything else, look up the official NERM v1 or v2025 operation, then `nerm api request METHOD PATH`.
4. Reads run immediately. Writes (create/update/delete/submit) require one interactive confirm that shows the profile name and NERM URL.
5. Pass JSON bodies with `--body-file` or stdin, not chat-pasted secrets.
6. Commands print JSON on stdout. Report that JSON without tokens.

## Routing

- Assignments, people, orgs, departments, locations: resolve profile type first (`nerm profile-types list`), then `nerm profiles list` or `nerm search run`.
- Delegations are user-to-user coverage only, never assignment records.
- Workflow session status vs profile business status are different APIs.
- Prefer domain commands over raw REST.
