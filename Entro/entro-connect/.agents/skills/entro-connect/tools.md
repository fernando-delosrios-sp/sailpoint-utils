# Configuration tools

After Lock only: read `configurationTools` on the locked Integration path in the Row catalog (`catalogPath`), falling back to the row when the path omits tools. Install, probes, auth-check, and Platform identity live in the Tool install file `tool-install.json` keyed by CLI `binary` or MCP `id`. Do not open `tool-install.json` during Orientation or Lock. After Lock, Grep or jq only the keys named by the locked Configuration tools — do not Read the whole file. Execute only those cataloged checks.

**Pick a tool:** match the locked Integration path when obvious; else first Fit `preferred`; else usable CLI; else MCP.

**Capability probe before install** (supervised and automated only): run `presenceCheck` then `capabilityProbe`. A suitable existing installation is reused and recorded. An unsuitable installation is recorded with the mismatch and gated as the exact upgrade or dependency in `install` / `docsUrl`. Do not offer install when the probe already found the tool suitable.

**Auth-check first:** run `authCheck` and `platformIdentity` before Configure once or `authOnce`. Valid session → skip Configure once and skip login, record principal, endpoint, and scope, then gate continue-with-this-environment versus re-authenticate or Help.

Invalid session → resolve `configureOnce` from the picked tool's Tool install entry. If that entry omits it, inherit `configureOnce` from another locked Configuration tool whose `authCheck.command` is identical (prefer `aws` when several match). When no `configureOnce` applies, request catalog `authOnce` as below.

When `configureOnce` applies, run the `check` of every route in `configureOnce.methods`. When exactly one route matches its `suitableWhen`, select it with no gate, skip its `command`, and go straight to its sign-in. When no route matches, or two or more do, gate the route choice on `name` and `whenToPick` in catalog order — mark none of them recommended and do not rank them in prose, because only the operator knows which route their organization allows.

For the selected route, request `configureOnce.command` in the operator's terminal, in every mode including `automated`; do not run the wizard yourself. That request lists the command, every `prompts` entry of that route with its `whereToFind` in catalog order, and that route's `docsUrl`; a message that names only the command is incomplete. Relay each wizard prompt as guidance, never as a request for a chat reply: every value is entered in the vendor CLI. For a prompt marked `secret`, give only its label and `whereToFind`; never ask for or echo its value. Do not invent prompt guidance the catalog does not carry, and do not relay prompts from a route you did not select. Do not collect answers as Operator inputs, bind them to `connectionFields`, or write them to the Connect log — the log records the selected route's `name`, that Configure once was requested, and its outcome. An inherited AWS object offers the AWS routes. End the request with a direct single-choice question block containing Continue (check authentication) and Help (authentication issues). Help diagnoses non-secret output, then [Vendor CLI guidance](#vendor-cli-guidance), and repeats the same block. On Continue, re-run `authCheck`. Valid session → skip `authOnce` and record Platform identity. Still invalid → request the selected route's `authOnce`. A null `authOnce` means the route has nothing to sign into: re-request its `command` or offer Help, and never fall back to another route's login.

Request `authOnce` in the operator's terminal — the selected route's value when `configureOnce` applies, else the entry-level one — in every mode including `automated`, since only the operator holds the credentials; finish with a direct single-choice question block containing Continue (check authentication) and Help (authentication issues). Help diagnoses non-secret output, then [Vendor CLI guidance](#vendor-cli-guidance), and repeats that block until the check succeeds. Never accept a login secret into session. Do not run `authOnce` or Configure once yourself. The recorded Platform identity is what [operator-inputs.md](operator-inputs.md) suggests from next.

Optional capability extras (example: Enterprise S3 log streaming → `aws`) apply only after just-in-time operator consent during Prep.

## Vendor CLI guidance

When Help (here or in [operator-inputs.md](operator-inputs.md)) needs current vendor CLI or cloud-service docs, look them up with Context7. Catalog `whereToFind` and `docsUrl` still lead; Context7 fills what they leave open.

When Context7 is not set up for this agent, gate once with a question block: `npx ctx7 setup` (recommended) or Continue without it. After the operator reports setup done, retry the lookup. A quota failure is `npx ctx7@latest login`, not this setup gate.
