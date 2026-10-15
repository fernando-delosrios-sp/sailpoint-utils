# Role Propagation

Role Change Propagation ensures that any changes to the composition of a role’s access objects (entitlements, access profiles, or dimensions) are applied to all member identities.

6 endpoints. Paths are relative to the environment API host.

## Initiate Role Propagation process

`POST /role-propagation/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This endpoint initiates a role change propagation process for a tenant asynchronously.  If all preconditions are met, the request is accepted and a rolePropagationId is returned which  can be used to view the status.
API throws 4xx if any of the following conditions are met - Role propagation feature is disabled  - There is an ongoing role propagation for the tenant - Role refresh needs to be kicked off as part of the role propagation (skipRoleRefresh=false) and there is an ongoing refresh for the tenant

Query:

- `skipRoleRefresh`: When true, the role refresh is not performed. Keeping it false is recommended.

## Get status of Role-Propagation process

`GET /role-propagation/v1/:rolePropagationId/status`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns the information of the specified role change propagation process. The execution stage of the role propagation process can be one of the following:
    - PENDING - The role propagation process is queued to be executed.
    - DATA_AGGREGATION_RUNNING - The role propagation process is currently aggregating data.
    - LAUNCH_PROVISIONING - The role propagation process has started to provision the access to the identities.
    - SUCCEEDED - The role propagation process has successfully completed.
    - FAILED - The role propagation process has failed.
    - TERMINATED - The role propagation process was externally terminated.

## Get ongoing Role Propagation process

`GET /role-propagation/v1/is-running`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns the information of ongoing role change propagation process for a tenant. It returns the information whether the role propagation process is currently running or not, If it is running it returns the details of the ongoing role propagation process. The execution stage of the role propagation process can be one of the following: - PENDING - The role propagation process is queued to be executed. - DATA_AGGREGATION_RUNNING - The role propagation process is currently aggregating data. - LAUNCH_PROVISIONING - The role propagation process has started to provision the access to the identities. - SUCCEEDED - The role propagation process has successfully completed. - FAILED - The role propagation process has failed. - TERMINATED - The role propagation process was externally terminated.

## Terminate Role Propagation process

`POST /role-propagation/v1/terminate`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This endpoint terminates the ongoing role change propagation process for a tenant.

## Update Role Change Propagation Configuration

`PUT /role-propagation-config/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint enables or disables the Role Change Propagation Process for the tenant

Body:

```json
{
  "enabled": true
}
```

## Get Role Change Propagation Configuration

`GET /role-propagation-config/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint fetches the Role Change Propagation Configuration for the tenant
