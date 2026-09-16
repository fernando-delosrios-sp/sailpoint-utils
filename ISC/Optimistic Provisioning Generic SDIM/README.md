# Generic SDIM Configuration Guide (Optimistic Provisioning)

![Optimistic Provisioning Generic SDIM](promo.png)

## Purpose

Step-by-step configuration guide for Generic SDIM optimistic provisioning in ISC, using Postman Echo as a fake ticket backend. Use for demos, POCs, and validating SDIM wiring before connecting a real ITSM system.

These instructions map to the **Integration** configuration UI. A public echo service (`postman-echo.com`) fakes the ticket lifecycle.

To avoid issues with how the connector serializes payload bodies (which can cause JSON parsing errors on the receiving end), pass the dummy ticket id and status as URL query parameters.

---

### 1. General Settings

Create a **Generic SDIM** integration (ticket type **generic**).

* **Name**: `Optimistic Provisioning`
* **Description**: `Optimistic Provisioning`
* **Integration Type**: Generic SDIM
* **Ticket Type**: `generic`
* **Integration Owner**: an identity in your tenant (example: `SailPoint Services`)
* **Enable Debug Logging**: `true`
* **Sources**: the source that should use optimistic provisioning (example: `Identity Security Cloud Governance`)

The **Id** is assigned by ISC. Do not set it.

---

### 2. Connectivity And Authentication

* **URL** (`slpt_url`): `https://postman-echo.com`
* **Authentication Type** (`slpt_authenticationType`): **Basic**
* **Username** (`slpt_username`): `dummy`
* **Password** (`slpt_password`): `dummy`

---

### 3. Ticket Creation

The integration uses a `POST` request for ticket creation by default.

* **Sample Description** (`slpt_sampleDescription`): leave the **default** value. Do not replace it with a dummy string. The default is the Velocity template that describes the provisioning plan:

```
#foreach($req in $plan.requests) #if($req.operation == 'Create') Create Account on application $req.resource #else For $req.id in application $req.resource #end #if($req.items) $newline #foreach($item in $req.items) #if ($item.name == '*disabled*' && $item.value == 'true') Disable Account. $newline #elseif ($item.name == '*disabled*' && $item.value == 'false') Enable Account. $newline #elseif ($item.name == '*locked*' && $item.value == 'false') Unlock Account. $newline #else $item.Operation $item.name: $item.value $newline #end #end #else $newline $req.Operation Account #end $newline #end
```

Leave these **Advanced Options** blank:

* **Process Response Element Expression**
* **Request Root Element**
* **Request Root Element Type**

Set:

* **Resource** (`slpt_resource`): `/post?ticketId=REQ-12345`
  *(Static dummy ticket id in the query string, so you do not need Velocity in the URI.)*
* **Response Element** (`slpt_responseElement`): `$.args.ticketId`

When the integration POSTs this request, `postman-echo` echoes query parameters inside an `args` object. JSONPath `$.args.ticketId` extracts `REQ-12345` without depending on the request body.

---

### 4. Status Mappings

Map IdentityNow statuses to the same Generic SDIM status strings. The echo backend returns `Committed` on status check, so **Committed** must map to **Committed**.

| IdentityNow Status | Generic SDIM Status |
| --- | --- |
| Failed | Failed |
| Queued | Queued |
| Committed | Committed |

---

### 5. Advanced Properties (status check)

The `std:ticket:read` (status check) operation uses a `GET` request by default. Inject the status in the query string the same way as ticket creation.

* **Resource** (`slpt_resource`): `/get?status=Committed`
* **Response Element** (`slpt_responseElement`): `$.args.status`

`postman-echo` returns query parameters in `args`. ISC extracts `$.args.status`, which equals `Committed`, matching the mapping above.

---

### 6. Requester Source

Leave **Requester Source** blank.

---

### 7. Source Account Schema & Provisioning Policy

For optimistic provisioning to generate user accounts with a correct Display Name and Native Identity in the UI, configure the managed source's **Account Schema** and **Create Account** provisioning policy carefully.

> [!WARNING]
> If a single attribute serves as both the **Account ID** and **Account Name** in the schema, ISC will consume that attribute to build the Native Identity during optimistic provisioning. This removes it from the final attribute list, resulting in accounts with blank names (`--`) in the Accounts UI.

To prevent this:

1. **Separate the Account ID and Account Name in the Schema:**
   - Define a unique attribute (e.g., `id`, `uid`, or `username`) and mark it **only** as the **Account ID**.
   - Define a separate attribute (e.g., `displayName` or `name`) and mark it as the **Account Name**.
2. **Map Both in the Create Account Policy:**
   - In the **Create Account** provisioning policy, ensure both the Account ID attribute and the Account Name attribute are mapped.
   - Add any other attributes you want to optimistically populate on the new account (like standard entitlements or user details).

When configured this way, ISC will consume the Account ID to generate the Native Identity, while leaving the Account Name intact in the attributes array. This ensures the account correctly renders in the UI with the right name.
