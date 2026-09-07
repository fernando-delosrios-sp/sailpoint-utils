## 1. Skill text — modes and prep

- [x] 1.1 Rewrite the `supervised` and `automated` rows in `.agents/skills/entro-connect/modes.md`: supervised discloses and gates then the operator executes; automated announces and runs every action itself, secret-producing included, with signing in left to the operator
- [x] 1.2 Update the "Switching later" line for the absence of a per-change gate under automated
- [x] 1.3 In `prep.md`, split the execution sections: a supervised section carrying the Approve / Adjust / Stop gate and the hand-off to the operator, and an automated section carrying the Announcement and self-execution with no gate
- [x] 1.4 In `prep.md`, add the Secret sink rules — output routed outside the repo and both skill trees, read back named identifiers only, disclose the path for vaulting, delete on confirmation, refuse the step when the secret cannot be withheld
- [x] 1.5 In `prep.md`, mark Adjust as supervised-only, state that the collision gate applies in automated too, and drop "before the Approve gate" from the pinned-script checksum rule
- [x] 1.6 In `prep.md`, restate Operator-only steps and Execute-and-record for the new actors

## 2. Skill text — SKILL.md, session log, tools

- [x] 2.1 Update the `SKILL.md` secret sentence, the Orientation bullet about secrets, and steps 7 and 8 for the new split
- [x] 2.2 Update `session-log.md` so the run section records the execution actor per mode and never a Secret sink path
- [x] 2.3 Update `tools.md` so `authOnce` is explicitly operator-run in every mode, automated included
- [x] 2.4 Mirror every edited file byte-for-byte into `skills/entro-connect/`

## 3. Tests

- [x] 3.1 Update `test_supervised_and_automated_run_approved_safe_actions` to assert the new mode split instead of `non-secret-producing` and "Secret-producing actions stay operator-executed"
- [x] 3.2 Update `test_prep_discloses_exact_command_before_approve` for the renamed supervised gate heading
- [x] 3.3 Update `test_client_secret_stays_with_the_operator` to assert the Secret sink rules and identifiers-only logging
- [x] 3.4 Add a test that automated announces before running and opens no per-change gate
- [x] 3.5 Add a test that supervised hands the command to the operator and runs no mutation
- [x] 3.6 Add a test that `authOnce` stays operator-run in automated
- [x] 3.7 Keep `test_edited_entro_connect_skill_files_match_both_trees` green for `tools.md` as well as the four files it already covers

## 4. Verification

- [x] 4.1 Confirm canonical test command: `.venv/bin/python -m pytest tests/test_ingest_docs.py -q`
- [x] 4.2 All delta spec scenarios covered by named automated tests
- [x] 4.3 `openspec validate entro-connect-mode-execution-split` passes

## 5. Documentation

- [x] 5.1 Update `docs/adr/0001-entro-connect-catalog-and-skill.md` if it states the old execution boundary
- [x] 5.2 Check `README.md` for mode descriptions that name who executes
- [x] 5.3 No catalog schema or `documentation/` change is needed — confirm `secretProducing` semantics stay as ingested

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change
- [x] 6.2 Confirm entry covers the breaking behavior change for both supervised and automated runs
