# nerm command reference

Global flags: `--profile <name>`, `--compact`.

Install: `npm install -g nerm-cli`. Binary name: `nerm`.

## Connection

```bash
nerm connection add NAME --url URL [--token TOKEN | --token-env VAR] [--use]
nerm connection list
nerm connection show NAME
nerm connection use NAME
nerm connection remove NAME
nerm connection test
```

## Resources

```bash
nerm profile-types list [--name NAME] [--archived]
nerm profile-types get ID
nerm profiles list [--name NAME] [--profile-type-id ID] [--status STATUS]
nerm profiles get ID
nerm users list [--name NAME] [--login LOGIN] [--email EMAIL] [--type TYPE]
nerm users get ID
nerm user-roles list [--user-id ID] [--role-id ID]
nerm user-roles get ID
nerm user-managers list [--user-id ID] [--manager-id ID]
nerm user-managers get ID
nerm user-profiles list [--user-id ID] [--profile-id ID] [--relationship-type owner|contributor]
nerm user-profiles get ID
nerm roles list [--type TYPE]
nerm roles get ID
nerm role-profiles list [--role-id ID] [--profile-id ID]
nerm role-profiles get ID
nerm attributes list [--label LABEL] [--data-type TYPE]
nerm attributes get ID
nerm identity-proofing list [--profile-id ID] [--result pass|fail]
```

List flags on retrieval commands: `--limit`, `--offset`, `--force-all`, `--order`, `--metadata`.

## Delegations

```bash
nerm delegations list [--delegator-id ID] [--delegate-id ID] [--expired]
nerm delegations get ID
nerm delegations create --body-file body.json
nerm delegations update ID --body-file body.json
nerm delegations delete ID
```

Create body uses `delegator_id`, `delegate_id`, and `expiration` (ISO-8601).

## Workflows, audit, search

```bash
nerm workflows sessions [--status STATUS] [--workflow-id ID]
nerm workflows session ID
nerm workflows statuses
nerm workflows submit --body-file body.json
nerm workflows job JOB_ID
nerm audit query [--subject-type TYPE] [--event-type TYPE] [--subject-id ID]
nerm search run --body-file search.json
```

Advanced search requires `condition_rules_attributes`. Do not use SQL-style `field`/`operator` keys.

## Raw REST

```bash
nerm api request GET /profiles --query 'query[limit]=1'
nerm api request POST /delegations --body-file body.json
```

Path is the resource under the profile `/api` base. Do not prefix `/api` again.
