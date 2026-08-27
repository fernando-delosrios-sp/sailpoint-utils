## Why

Operation-specific documentation currently lives in the root `README.md` — notably a long `custom:sod-remediation` section — while operation code lives in `src/operations/<slug>/`. That split makes operation docs hard to find when working in an operation folder, encourages the root README to grow without bound as new commands ship, and gives new authors no README scaffold beside `_template/index.ts`. Co-locating one `README.md` per operation directory aligns docs with the subdirectory layout enforced since `operation-layer-boundaries` and gives codegen a hook to enforce presence at build time.

## What Changes

**Per-operation README requirement**
- From: No normative README per operation; sod-remediation docs inlined in root README
- To: Every discovered operation subdirectory MUST include `README.md`; `_template/` includes a copy scaffold
- Reason: Docs co-located with operation domain code; scalable as operation count grows
- Impact: Non-breaking for ISC contracts; documentation relocation only

**Root README slimming**
- From: Root README contains full sod-remediation invoke and workflow integration section
- To: Root README points authors to per-operation READMEs; sod content moves to `operations/sod-remediation/README.md`
- Reason: Root README stays framework-focused
- Impact: Operators follow link for operation-specific workflow steps

**Build-time enforcement**
- From: No check for README presence when scanning operations
- To: Discovery test fails build when a scanned operation slug lacks `README.md`
- Reason: Prevent new operations without docs
- Impact: Non-breaking for runtime; fails CI/build on missing README

## Capabilities

### New Capabilities

_(none — documentation and layout extension only)_

### Modified Capabilities

- `connector-operations`: Add requirement that each operation subdirectory includes co-located `README.md`; `_template` provides scaffold
- `connector-config`: Add documentation requirement that root README references per-operation README convention and that each operation README documents invoke payloads and workflow integration for that command

## Impact

- **Docs:** New `README.md` in `src/operations/example/`, `src/operations/sod-remediation/`, `src/operations/_template/`; root README migration (remove inlined sod section, add pointer)
- **Tests:** Extend operation discovery tests to assert README exists per scanned slug
- **Codegen/scripts:** No generated README content; optional comment in `_template/index.ts` pointing to README scaffold
- **Out of scope:** Auto-generating README from OperationSignature; content lint beyond file existence; changes to `connector-spec.json` or operation I/O contracts
