# Identities

Use this API to implement identity functionality.

12 endpoints. Paths are relative to the environment API host.

## List identities

`GET /identities/v1`

Success: 200.

This API returns a list of identities.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); alias (eq, sw); firstname (eq, sw); lastname (eq, sw); email (eq, sw); cloudStatus (eq); processingState (eq); correlated (eq); protected (eq)
- sorters: name, alias, cloudStatus
- `defaultFilter`: Adds additional filter to filters query parameter. CORRELATED_ONLY adds correlated=true and returns only identities that are correlated. NONE does not add any and returns all identities that satisfy filters query parameter. (This can only…

## Identity details

`GET /identities/v1/:id`

Success: 200.

This API returns a single identity using the Identity ID.

## Delete identity

`DELETE /identities/v1/:id`

Success: 204.

The API returns successful response if the requested identity was deleted.

## Get ownership details

`GET /identities/v1/:identityId/ownership`

Success: 200.

Use this API to return an identity's owned objects that will cause problems for deleting the identity.
Use this API as a checklist of objects that you need to reassign to a different identity before you can delete the identity.
For a full list of objects owned by an identity, use the Search API.  When you search for identities, the returned identities have a property, `owns`, that contains a more comprehensive list of identity's owned objects.

## Reset an identity

`POST /identities/v1/:id/reset`

Success: 202.

Use this endpoint to reset a user's identity if they have forgotten their authentication information like their answers to knowledge-based questions. Resetting an identity de-registers the user and removes any elevated user levels they have.

## List role assignments

`GET /identities/v1/:identityId/role-assignments`

Success: 200.

This returns either a list of Role Assignments when querying with either a Role Id or Role Name, or a list of Role Assignment References if querying with only identity Id.

Query:

- `roleId`: Role Id to filter the role assignments with
- `roleName`: Role name to filter the role assignments with

## Role assignment details

`GET /identities/v1/:identityId/role-assignments/:assignmentId`

Success: 200.

## List of entitlements by identity.

`GET /entitlements/v1/identities/:id/entitlements`

Success: 200.

The API returns a list of all entitlements assigned to an identity, either directly or through the role or access profile. A token with ORG_ADMIN or API authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`

## Attribute synchronization for single identity.

`POST /identities/v1/:identityId/synchronize-attributes`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This end-point performs attribute synchronization for a selected identity. The endpoint can be called once in 10 seconds per identity.

## Invite identities to register

`POST /identities/v1/invite`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API submits a task for inviting given identities via email to complete registration. The invitation email will include the link. After selecting the link an identity will be able to set up password and log in into the system. Invitations expire after 7 days. By default invitations send to the work identity email. It can be changed in Admin > Identities > Identity Profiles by selecting corresponding profile and editing Invitation Options.

This task will send an invitation email only for unregistered identities.

The executed task status can be checked by Task Management > Get task status by ID.

Body:

```json
{
  "ids": [
    "2b568c65bc3c4c57a43bd97e3a8e55",
    "2c9180867769897d01776ed5f125512f"
  ],
  "uninvited": false
}
```

## Send password reset email

`POST /identities/v1/:id/verification/account/send`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API sends an email with the link to start Password Reset. After selecting the link an identity will be able to set up a new password. Emails expire after 2 hours.

Body:

```json
{
  "via": "EMAIL_WORK",
  "sourceName": "Active Directory Source"
}
```

## Process a list of identityids

`POST /identities/v1/process`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This operation should not be used to schedule your own identity processing or to perform system wide identity refreshes. The system will use a combination of event-based processing and scheduled processing that runs every day at 8:00 AM and 8:00 PM in the tenant's timezone to keep your identities synchronized.

This endpoint will perform the following tasks:
1. Calculate identity attributes, including applying or running any rules or transforms (e.g. calculate Lifecycle State at a point-in-time it's expected to change).
2. Evaluate role assignments, leading to assignment of new roles and removal of existing roles.
3. Enforce provisioning for any assigned accesses that haven't been fulfilled (e.g. failure due to source health).
4. Recalculate manager relationships.
5. Potentially clean-up identity processing errors, assuming the error has been resolved.

Body:

```json
{
  "identityIds": [
    "ef38f94347e94562b5bb8424a56397d8"
  ]
}
```
