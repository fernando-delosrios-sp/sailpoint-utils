## 1. Skill execution contract

- [x] 1.1 Update `.agents/skills/entro-connect/modes.md` so supervised and automated both Approve then the skill runs non-secret-producing actions; secret-producing actions stay operator-executed; playbook stays write-only
- [x] 1.2 Update `.agents/skills/entro-connect/prep.md`: disclose the exact command before Approve; skill runs non-secret-producing actions after Approve in both execute modes; checksum original; Temporary script copy for names/menus; collision/replace notify-propose-gate-rerun; keep secrets out of agent context, chat, and Connect log; Operator-only remains no mutation
- [x] 1.3 Update `.agents/skills/entro-connect/SKILL.md` Prep and Configuration plan lines to match
- [x] 1.4 Update `.agents/skills/entro-connect/session-log.md` so secret-producing steps log identifiers only
- [x] 1.5 Copy the same four files to `skills/entro-connect/` so both skill trees stay identical

## 2. Tests

- [x] 2.1 Extend `tests/test_ingest_docs.py` skill-doc assertions for: skill runs after Approve in supervised and automated; Temporary script copy; gated collision retry; Client Secret still omitted; checksum mismatch still stops with no copy
- [x] 2.2 Keep dual-tree equality asserts for `prep.md` and the other edited skill files

## 3. ADR note

- [x] 3.1 Update `docs/adr/0001-entro-connect-catalog-and-skill.md` so supervised and automated share execution for non-secret-producing actions while secret-producing stays operator-executed

## 4. Verification

- [x] 4.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 4.2 All delta spec scenarios covered by named automated tests

## 5. Documentation

- [x] 5.1 Skill files listed in §1 (both trees) match the specs
- [x] 5.2 No `documentation/` GitBook pages rewritten for this change

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change
- [x] 6.2 Confirm entry covers user-visible changes from proposal Capabilities
