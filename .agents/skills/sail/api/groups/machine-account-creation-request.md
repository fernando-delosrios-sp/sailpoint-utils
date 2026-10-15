# Machine Account Creation Request

Use this API to submit and retrieve machine account creation requests.

3 endpoints. Paths are relative to the environment API host.

## Submit Machine Account Creation Request

`POST /account-requests/v1/machine-account-create`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Initiates machine account creation request for the specified subtype.
This method validates the input data, processes the machine account creation request,
and generates an asynchronous result containing a tracking ID.

>**NOTE: You can only request a machine accounts on subtype for which you have a create machine account entitlement provisioned.**

Body:

```json
{
  "subtypeId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
  "ownerIdentityId": "18104e7e499b4e23882d6323344ab6bc",
  "formId": "f5dd23fe-3414-42b7-bb1c-869400ad7a10",
  "machineIdentityId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
  "environment": "Dev",
  "description": "Requesting machine account for tracking the inventory.",
  "userInput": {
    "target": "AD Source",
    "description": "Inventory tracking"
  },
  "entitlementIds": [
    "6d28b7c1620c49c6b6d5cbf81eb4b5fa",
    "2c91808a7624751a01762f19d67c220e"
  ]
}
```

## Get Machine Account Creation Request

`GET /account-requests/v1/machine-account-create/:accountRequestId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Retrieves a account request details for machine account creation. This allows the user to view all details for given account request.

## Machine Account Create Access

`GET /source-subtypes/v1/machine-account-create-access`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint retrieves the list of sources and subtypes for which logged in user has the entitlement to create a machine account.
The response includes a list of object detailing the source, subtype and entitlement details which enables the clients to understand if they can submit the request to create a machine account for the given subtype.

Query:

- standard: `limit`, `offset`
