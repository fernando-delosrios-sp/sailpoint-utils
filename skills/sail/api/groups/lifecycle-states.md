# Lifecycle States

Use this API to implement and customize lifecycle state functionality.

6 endpoints. Paths are relative to the environment API host.

## Set lifecycle state

`POST /identities/v1/:identity-id/set-lifecycle-state`

Success: 200.

Use this API to set/update an identity's lifecycle state to the one provided and update the corresponding identity profile.

Body:

```json
{
  "lifecycleStateId": "2c9180877a86e408017a8c19fefe046c"
}
```

## Lists lifecyclestates

`GET /identity-profiles/v1/:identity-profile-id/lifecycle-states`

Success: 200.

Use this endpoint to list all lifecycle states by their associated identity profiles.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name, priority, created, modified

## Create lifecycle state

`POST /identity-profiles/v1/:identity-profile-id/lifecycle-states`

Success: 201.

Use this endpoint to create a lifecycle state.

Body:

```json
{
  "name": "aName",
  "technicalName": "Technical Name",
  "enabled": true,
  "description": "Lifecycle description",
  "emailNotificationOption": {
    "notifyManagers": true,
    "notifyAllAdmins": true,
    "notifySpecificUsers": true,
    "emailAddressList": [
      "test@test.com",
      "test2@test.com"
    ]
  },
  "accountActions": [
    {
      "action": "ENABLE",
      "sourceIds": [
        "2c918084660f45d6016617daa9210584",
        "2c918084660f45d6016617daa9210500"
      ],
      "excludeSourceIds": [
        "3b551ccf5566478b9b77f37de25303aa"
      ],
      "allSources": true
    },
    {
      "action": "ENABLE",
      "sourceIds": [
        "2c918084660f45d6016617daa9210584",
        "2c918084660f45d6016617daa9210500"
      ],
      "excludeSourceIds": [
        "3b551ccf5566478b9b77f37de25303aa"
      ],
      "allSources": true
    }
  ],
  "accessProfileIds": [
    "2c918084660f45d6016617daa9210584",
    "2c918084660f45d6016617daa9210500"
  ],
  "identityState": "INACTIVE_LONG_TERM",
  "accessActionConfiguration": {
    "removeAllAccessEnabled": true
  },
  "priority": 10
}
```

## Get lifecycle state

`GET /identity-profiles/v1/:identity-profile-id/lifecycle-states/:lifecycle-state-id`

Success: 200.

Use this endpoint to get a lifecycle state by its ID and its associated identity profile ID.

## Update lifecycle state

`PATCH /identity-profiles/v1/:identity-profile-id/lifecycle-states/:lifecycle-state-id`

Success: 200.

Use this endpoint to update individual lifecycle state fields, using the JSON Patch standard.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "Updated description!"
  },
  {
    "op": "replace",
    "path": "/accessProfileIds",
    "value": [
      "2c918087742bab150174407a80f3125e",
      "2c918087742bab150174407a80f3124f"
    ]
  },
  {
    "op": "replace",
    "path": "/accountActions",
    "value": [
      {
        "action": "ENABLE",
        "sourceIds": [
          "2c9180846a2f82fb016a481c1b1560c5",
          "2c9180846a2f82fb016a481c1b1560cc"
        ],
        "excludeSourceIds": null,
        "allSources": false
      },
      {
        "action": "DISABLE",
        "sourceIds": null,
        "excludeSourceIds": [
          "3b551ccf5566478b9b77f37de25303aa"
        ],
        "allSources": true
      },
      {
        "action": "DELETE",
        "sourceIds": [
          "3c9180846a2f82fb016a481c1b1560c5",
          "8n9180846a2f82fb016a481c1b1560cc"
        ],
        "excludeSourceIds": null,
        "allSources": false
      }
    ]
  },
  {
    "op": "replace",
    "path": "/emailNotificationOption",
    "value": {
      "notifyManagers": true,
      "notifyAllAdmins": false,
      "notifySpecificUsers": false,
```

Body example truncated.

## Delete lifecycle state

`DELETE /identity-profiles/v1/:identity-profile-id/lifecycle-states/:lifecycle-state-id`

Success: 202.

Use this endpoint to delete the lifecycle state by its ID.
