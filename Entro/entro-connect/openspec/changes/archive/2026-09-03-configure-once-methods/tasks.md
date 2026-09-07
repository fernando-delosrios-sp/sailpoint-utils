## 1. Contracts carry Authentication routes

- [x] 1.1 Write failing tests in `tests/test_ingest_docs.py`: `configureOnce` with an empty `methods` list fails validation; a route missing `whenToPick`, `check.command`, `credentialBoundary`, or `docsUrl` fails; a route with empty `prompts` or a prompt without `whereToFind` fails; an entry-level `authOnce` matching no route fails; a route with `authOnce: null` validates
- [x] 1.2 Replace the single-command `ConfigureOnce` in `catalog_contracts.py` with `methods`, add the route dataclass (`name`, `whenToPick`, `check`, `suitableWhen`, `command`, `prompts`, `credentialBoundary`, `docsUrl`, `sourceUrl`, `retrievedAt`, nullable `authOnce`), and add optional `secret` to the prompt dataclass
- [x] 1.3 Extend serialization, deserialization, and the secret-shaped-value scan to cover the nested routes
- [x] 1.4 Run the tests green

## 2. AWS fills both routes

- [x] 2.1 Write failing tests: the `aws` entry has exactly two routes; the access keys route has `command` `aws configure`, `authOnce` null, a `secret` secret-access-key prompt, and a credentials-file check that does not print matches; the Identity Center route keeps `aws configure sso`, `aws sso login`, and its nine prompts; the config-file check does not target `credentials`; `az` and `terraform` still omit `configureOnce`
- [x] 2.2 Fill both routes in `integration_catalog.py`, moving today's SSO content into the Identity Center route and adding `grep -q` to its check
- [x] 2.3 Regenerate `documentation/integrations.json` and both Skill `tool-install.json` files; confirm no credential value appears anywhere in the diff
- [x] 2.4 Run the tests green

## 3. The skill selects or gates a route

- [x] 3.1 Rewrite the Configure once paragraph in `.agents/skills/entro-connect/tools.md`: run every route check; one suitable route is selected silently and goes straight to its sign-in; zero or two-plus suitable gates the choice by `name` and `whenToPick` with no recommended marker; relay only the selected route's prompts, `secret` handling, and `docsUrl`; a null `authOnce` never yields a login request and repairs by re-requesting the route command or Help; the Connect log records the route name and outcome only
- [x] 3.2 Mirror the same text into `skills/entro-connect/tools.md`
- [x] 3.3 Confirm the Terraform inherit sentence still reads correctly now that inheritance brings a route list

## 4. Rehearse

- [x] 4.1 With no AWS credentials present, confirm the tools step reaches the route gate listing both routes rather than the SSO wizard
- [x] 4.2 With an existing SSO profile and an expired token, confirm no gate appears and `aws sso login` is requested
- [x] 4.3 Confirm a run that picks access keys never mentions `aws sso login` and never asks for the secret access key in chat

## 5. Documentation and changelog

- [x] 5.1 Update `README.md` where it lists Tool install fields to describe `configureOnce.methods`
- [x] 5.2 Add a `CHANGELOG.md` entry for AWS authentication without IAM Identity Center
- [x] 5.3 Run the full `pytest` suite green
