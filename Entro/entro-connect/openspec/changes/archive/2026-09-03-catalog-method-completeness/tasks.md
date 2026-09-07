## 1. Waiver and census data shape

- [x] 1.1 Add `MethodWaiver` (page path, reason) and `CensusEntry` (page path, documented method name, bound method name or waiver reason, evidence quote) dataclasses to `catalog_contracts.py` with `*_to_dict` serializers matching existing helpers
- [x] 1.2 Extend `IntegrationDefinition` and `_row` in `integration_catalog.py` with `method_waivers` and `fork_census`, defaulting to empty tuples
- [x] 1.3 Emit both onto ingest rows in `integration_to_dict`, and strip them in `_strip_documentation_paths` / `_index_entry` so Row catalogs and the thin index stay free of them; add `methodWaivers` and `forkCensus` to `INDEX_FORBIDDEN_KEYS`

## 2. Completeness validation

- [x] 2.1 Add `integration_documentation_pages(output_dir)` enumerating markdown pages under the seven integration documentation folders
- [x] 2.2 Add `validate_page_citation(output_dir, rows)`: every enumerated page is cited via `_documentation_paths` or waived; report orphans by path; no folder-proximity attribution
- [x] 2.3 Add `validate_fork_census(output_dir, rows)`: each entry binds to a method the row carries or a non-empty waiver reason, and its evidence quote occurs in the page bytes
- [x] 2.4 Add `validate_method_waivers(output_dir, rows)`: non-empty reason, page exists under the integration documentation folders
- [x] 2.5 Wire all three into `validate_integration_definitions` and confirm `write_integrations_index` returns errors without writing either artifact
- [x] 2.6 Extend `validate_skill_catalog` so a Row catalog or thin index carrying waivers, census entries, or documentation paths fails

## 3. Cover the current gaps with waivers

- [x] 3.1 Waive every currently uncited integration documentation page with a reason, so the suite is green with the invariant live before any row is backfilled
- [x] 3.2 Confirm `python -m pytest` passes and `write_integrations_index` writes cleanly at this point

## 4. Backfill AWS

- [x] 4.1 Cite `aws-multiple-account-automation.md` on the AWS row and census its StackSets and Terraform options with evidence quotes
- [x] 4.2 Add the Terraform Setup method: prep steps, `AWS_TERRAFORM_ACTIONS` typed actions (init, plan-preview/apply, read Role ARN), and `remote_agent` / `sns_topic_arn_suffix` / `terraform_dir` Operator inputs
- [x] 4.3 Add the CloudFormation StackSets Setup method for the AWS Organizations path
- [x] 4.4 Add `terraform` as a usable Configuration tool plus its `tool-install.json` entry, with `authCheck` identical to the `aws` entry so it inherits AWS Configure once
- [x] 4.5 Decide and record CloudTrail S3 setup as a Coverage, a Setup method, or a reasoned waiver
- [x] 4.6 Drop the AWS waivers added in 3.1 and confirm validation still passes

## 5. Backfill remaining rows

- [x] 5.1 Google Cloud Platform — Terraform automated onboarding and Console manual paths
- [x] 5.2 Microsoft Ecosystem — Manual Policy Creation and Azure Continuous Onboarding
- [x] 5.3 GitLab — Group Access Token and Personal Access Token as Authentication methods
- [x] 5.4 File Shares (SMB) — Manual Onboarding and JSON Upload as Setup methods
- [x] 5.5 Akeyless — Universal Identity and API Key as Authentication methods
- [x] 5.6 Okta — Custom Entro Role alongside Super Administrator
- [x] 5.7 Atlassian — cite or waive the legacy combined Jira and Confluence Cloud page on all four rows
- [x] 5.8 CrowdStrike — census the Falcon RTR Terraform EC2 deployment on the Coverage, not as a row Setup method
- [x] 5.9 Regenerate both Skill catalog trees and confirm they are byte-identical

## 6. Tests

- [x] 6.1 Replace the exact-set assertion in `test_one_target_one_row` so it no longer pins AWS to two Setup methods; assert Terraform is present
- [x] 6.2 Add a cookie-free test asserting page citation across the committed documentation tree
- [x] 6.3 Add a test that a seeded uncited page fails validation
- [x] 6.4 Add a test that a census entry whose evidence quote is absent fails validation
- [x] 6.5 Add a test that a waiver with a blank reason fails validation
- [x] 6.6 Add a test that a Row catalog carrying waivers or documentation paths fails validation
- [x] 6.7 Update `test_aws_setup_methods_own_prep_steps` and the other tests that name AWS or GCP method sets

## 7. Change isolation

- [x] 7.1 Add a "Concurrent sessions and uncommitted work" section to `AGENTS.md` under Workflow routing: never stash, revert, or check out over work this session did not create; obtain a clean tree by worktree or branch; report unrecognized dirt or stashes
- [x] 7.2 Add the stash and dirty-tree prohibitions to the Front-door anti-patterns table in `AGENTS.md`
- [x] 7.3 Write `docs/agents/change-isolation.md` with the recovery procedure for a foreign stash (inspect message and file list, surface to operator, never apply or drop unilaterally)
- [x] 7.4 Cross-reference the rule from `docs/agents/domain.md` reading list so exploring sessions pick it up
- [x] 7.5 Confirm the `apply-code-changes` verify gate wording cannot be satisfied by discarding a diff; state that a dirty tree is resolved by committing

## 8. Verification

- [x] 8.1 Confirm canonical test command: `python -m pytest`
- [x] 8.2 All delta spec scenarios covered by named automated tests
- [x] 8.3 `openspec validate --all --json` reports every artifact valid

## 9. Documentation

- [x] 9.1 Update `README.md` to describe the completeness invariant, Method waivers, and that curation bookkeeping stays out of the Skill catalog
- [x] 9.2 Update `openspec/specs/ubiquitous-language/spec.md` consumers if any doc reuses "coverage" for completeness
- [x] 9.3 Document in `docs/agents/domain.md` how to add a Documented method or a waiver when Entro publishes a new onboarding page

## 10. Changelog

- [x] 10.1 Create changelog entry for this change via changelog-generator
- [x] 10.2 Confirm the entry covers the new AWS Terraform and StackSets methods and the other backfilled rows as user-visible changes
