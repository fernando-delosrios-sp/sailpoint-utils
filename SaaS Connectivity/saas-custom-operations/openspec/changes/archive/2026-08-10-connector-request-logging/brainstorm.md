# Brainstorm: Connector Request Logging

## Background

Operators run custom operations locally via `npm run debug` (spcx) and dry-run via `npm run test:operation`. The fixture runner already prints formatted JSON summaries on completion, but the live connector did not log incoming invoke payloads. During local debugging, only handler-scattered log lines appeared — making it hard to see the full request envelope (command, config, input) at the point of entry.

Additional pain: when invoking against spcx with a `config` block in the POST body, config did not reach handlers. Root cause: ncc bundles `@sailpoint/connector-sdk`, creating a separate `readConfig()` AsyncLocalStorage store from the one spcx populates via `_withConfig(cmd.config)`.

## Q1: What should be logged?

**Options considered:**
1. Log only `input` — minimal, misses connection context
2. Log full invoke envelope (command + config + input) — matches fixture shape, best for debugging
3. Log response as well — useful but separate concern; fixture runner already covers post-run output

**Decision:** Log full invoke envelope before handler execution. Match `test:operation` readability (section headers, spread JSON). Token MUST be redacted.

## Q2: Where to attach logging?

**Options considered:**
1. Per-handler `console.log` in each operation — duplicated, easy to miss new ops
2. Inside `customOperation` wrapper only — misses pre-parse failures, doesn't cover manual handlers
3. Wrap at `connector.command()` registration in `registerCommands` — covers all registered commands automatically

**Decision:** Patch `connector.command()` via `wrapConnectorWithRequestLogging()` in `registerCommands`. Default-on for every registered handler.

## Q3: How to resolve config for logging (and handlers)?

**Options considered:**
1. Rely on bundled `readConfig()` only — fails under spcx dev (duplicate AsyncLocalStorage)
2. Put config on `context.config` — spcx doesn't set it; only passes `cmd.input` to `_exec`
3. Read from external node_modules SDK via `createRequire` first, then fall back to bundled `readConfig()` — works for spcx dev AND production CONNECTOR_CONFIG runtime

**Decision:** New `invoke-config.ts` with `readExternalInvokeConfig()` + `readInvokeConfig()`. Use in request logging AND update `resolveInvocationConfig` default to use shared resolver.

## Q4: Share JSON formatting with fixture runner?

**Options considered:**
1. Duplicate `formatSpreadJson` — drift risk
2. Extract to `src/framework/pretty-json.ts`, re-export from `scripts/fixture-output.ts` — single source

**Decision:** Extract shared `pretty-json.ts`.

## Trade-offs

- **Always-on logging:** Adds stdout noise in production ISC runtime. Acceptable for custom-ops connector focused on workflow debugging; no opt-out env var in v1 (can add later if needed).
- **External readConfig hack:** Relies on `process.cwd()` pointing at project root during spcx dev. Works for standard layout; packaged connector in ISC uses bundled path only.
- **Security:** Token redaction covers `config.token` only; other secrets in config are not scrubbed.

## Agreed Approach

1. Default incoming-request logging at command registration
2. Fixture-style formatted output with token redaction
3. Shared invoke config resolution fixing spcx dev config visibility
4. Shared pretty-json helper with fixture runner

## Open Questions (resolved)

- Config visibility in logs: resolved via external SDK readConfig
- Whether to fix handler config too: yes, same root cause
