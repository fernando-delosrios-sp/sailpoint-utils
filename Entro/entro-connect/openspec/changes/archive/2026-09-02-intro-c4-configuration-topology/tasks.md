## 1. Rewrite the Intro C4 section in intro.md

- [x] 1.1 Replace the fixed fence in `.agents/skills/entro-connect/intro.md` §Intro C4 with the five node roles from design D1 (Identity object, permission grants, reach, credential, Entro side) in that order
- [x] 1.2 State the derivation source per role from design D2 (Typed action `expectedChange` / `target`, locked Coverages, `connectionFields`, `hosting` via `connector-deployment.md`)
- [x] 1.3 State the omission rule from design D3 — a role the locked row does not name is left out, never invented — and that skipped Coverages MUST NOT appear as reach
- [x] 1.4 State the boundary rule from design D4 (vendor subgraph, Entro subgraph, reach subgraph when the row names more than one scope) and the `classDef` palette from D5 with no Person node
- [x] 1.5 State that secret Connection details appear by field name only, never as a value
- [x] 1.6 Add the Microsoft Ecosystem worked example from design D6, labelled as one run's output and explicitly not a fence to copy
- [x] 1.7 Update the §Intro **Done when** line so it names the Configuration topology rather than a fixed topology
- [x] 1.8 Mirror the rewritten file byte-for-byte to `skills/entro-connect/intro.md`

## 2. Verification

- [x] 2.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 2.2 Rewrite `tests/test_c4_flowchart.py::test_intro_c4_is_mermaid_flowchart_not_ascii` so it asserts the node roles and derivation sources instead of the seven fixed nodes, and asserts the old topology strings are gone from both copies — renamed to `test_intro_shows_mermaid_not_ascii` after the delta scenario
- [x] 2.3 Add a named test that both `intro.md` copies stay byte-identical
- [x] 2.4 Add named tests for the delta scenarios that are statically checkable: run machinery absent, secret values absent from the example fence, `classDef` roles present, no `.drawio` written for a Connect run
- [x] 2.5 Record how the per-run scenarios (different fences per Integration, skipped Coverage absent, thin row omits a role) are covered — by the worked example plus the derivation rules in `intro.md`, since no Connect run executes in CI
- [x] 2.6 Run `openspec validate --all --json` and `.venv/bin/python -m pytest`

## 3. Documentation

- [x] 3.1 Redraw the Intro C4 fence in `entro-microsoft-ecosystem.md` so the local Connect log shows the Configuration topology — Connect logs match `entro-*.md` and are gitignored, so this is a working-tree fix, not a committed one
- [x] 3.2 Check `README.md` and `docs/agents/` for any description of the Intro diagram as a fixed topology and update it — no occurrence found, no edit needed
- [x] 3.3 Confirm no other repo file still documents the seven-node Intro C4 outside `openspec/changes/archive/` — only the canonical `openspec/specs/` files, which the delta specs replace at archive

## 4. Changelog

- [x] 4.1 Create or update the changelog entry for this change via changelog-generator
- [x] 4.2 Confirm the entry says the Connect Intro diagram now shows what the locked Integration needs configured, derived from the catalog row, and that no catalog authoring is required
