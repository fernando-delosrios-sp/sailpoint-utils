## 1. Logger core — normalization and emit

- [x] 1.1 Add `normalizeDetailForJson` in `src/framework/logger.ts` — omit undefined/function/symbol; `[Circular]` replacement; Error and bigint handling
- [x] 1.2 Add pretty console formatter — headline `[requestId] message` plus labeled per-key blocks (scalars inline, objects via inspect)
- [x] 1.3 Refactor to shared internal emit: `sanitizeForLog` → normalize → console → JSON POST; consolidate `postFrameworkLogEvent` into shared path
- [x] 1.4 Update `FrameworkLogger` public types to `detail?: Record<string, unknown>` on info/warn/error

## 2. Logger tests

- [x] 2.1 Extend `src/framework/logger.spec.ts` — undefined/function omission, circular `[Circular]`, Error serialization, bigint string
- [x] 2.2 Assert pretty console layout — headline, labeled keys, scalar inline
- [x] 2.3 Assert console and logUrl POST share identical normalized detail (including redaction parity)

## 3. Incoming request unification

- [x] 3.1 Route `printIncomingRequest` through shared emit with message `Incoming request` and detail `{ command, input, config }`
- [x] 3.2 Replace `redactConfigForLogging`-only path with full `sanitizeForLog` on config in detail
- [x] 3.3 Keep boxed section console render mode; POST uses standard JSON event schema
- [x] 3.4 Update `src/framework/request-logging.spec.ts` — unified detail shape, sanitizeForLog on config, logUrl POST parity

## 4. Operation logging migration

- [x] 4.1 Migrate `src/operations/sod-remediation/logging.ts` to `getActiveFrameworkLogger()` with headline + named detail maps
- [x] 4.2 Update `src/operations/sod-remediation/logging.spec.ts` — mock framework logger or assert via logger spy instead of console-only
- [x] 4.3 Migrate `src/operations/access-model-sod-remediation/index.ts` direct `console.log/warn` to `ctx.log` / active logger
- [x] 4.4 Migrate `src/operations/preventive-sod-check/resolve-input.ts` warn to `getActiveFrameworkLogger().warn`
- [x] 4.5 Update `src/framework/with-custom-operation.spec.ts` if logUrl POST coverage needs multi-key detail example

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test`
- [x] 5.2 Run `npm run typecheck`
- [x] 5.3 All delta spec scenarios covered by named automated tests in `logger.spec.ts`, `request-logging.spec.ts`, and operation logging specs
- [x] 5.4 Automated parity: sod-remediation and access-model handler tests assert step logs POST normalized detail to logUrl

## 6. Documentation

- [x] 6.1 Update README Operation logging — named detail map convention, scalar values, pretty console layout
- [x] 6.2 Update README Invoke config — JSON-safe normalization rules for logUrl consumers; console/POST sync
- [x] 6.3 Update JSDoc on `FrameworkLogger` and `normalizeDetailForJson` / emit helpers in `logger.ts`

## 7. Changelog

- [x] 7.1 Create or update changelog entry via changelog-generator skill during apply
- [x] 7.2 Confirm entry covers unified console/logUrl sync, pretty console, JSON-safe detail, and operation logging migration
