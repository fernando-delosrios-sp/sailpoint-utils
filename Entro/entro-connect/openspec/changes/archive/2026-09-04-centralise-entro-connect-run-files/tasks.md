## 1. Skill procedure

- [x] 1.1 Update `.agents/skills/entro-connect/session-log.md`: Connect log path is the Connect run folder `entro-<tile-slug>[-<path-slug>].md`; gitignored via `/entro-connect/`; Done-when is that folder, not repository root
- [x] 1.2 Update `.agents/skills/entro-connect/SKILL.md` step 3 to create or append the Connect log in the Connect run folder, with the skill-tree collision fallback
- [x] 1.3 Update `.agents/skills/entro-connect/prep.md`: Temporary script copy in the Connect run folder with `tmp-` prefix; Secret sink in that folder with `sink-` prefix, not the operator temp directory; keep read-back, vault, delete, and Connect-log path omission
- [x] 1.4 Mirror `session-log.md`, `SKILL.md`, and `prep.md` byte-for-byte into `skills/entro-connect/`

## 2. Gitignore

- [x] 2.1 Add `/entro-connect/` to `.gitignore`; keep `entro-*.md` for leftover repository-root logs

## 3. Tests

- [x] 3.1 Extend `test_gitignore_entro_session_logs` to require `/entro-connect/` and that `skills/entro-connect` is not ignored
- [x] 3.2 Update `test_automated_runs_secret_producing_script_through_a_secret_sink` to assert Connect run folder and `sink-` prefix instead of "outside both the repo and the skill tree"
- [x] 3.3 Add named skill-doc tests for: Connect log in the Connect run folder not repository root; Temporary script copy `tmp-` prefix in that folder; cwd `.agents/skills` falls back to repository-root `entro-connect/`
- [x] 3.4 Keep dual-tree equality for the three edited skill files; update glossary Secret sink / Temporary script copy / Connect log assertions if they pin the old homes

## 4. Verification

- [x] 4.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 4.2 All delta spec scenarios covered by named automated tests

## 5. Documentation

- [x] 5.1 Update README Connect-log path (table and any later mention) to the Connect run folder
- [x] 5.2 No `documentation/` GitBook pages rewritten for this change

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change via changelog-generator
- [x] 6.2 Confirm entry covers user-visible changes from proposal Capabilities
