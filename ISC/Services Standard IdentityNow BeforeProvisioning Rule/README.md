# User Manual: Services Standard IdentityNow BeforeProvisioning Rule

This user manual provides comprehensive documentation and configuration examples for the **Services Standard IdentityNow BeforeProvisioning Rule**. 

## Overview
The **Services Standard IdentityNow BeforeProvisioning Rule** is a generic, highly configurable BeanShell rule designed to intercept and modify Provisioning Plans in SailPoint IdentityNow right before they are executed. 

Instead of writing custom code for every target application's edge cases, this rule relies on a JSON-based configuration structure defined directly on the Source (Application) object. It evaluates a set of **Triggers** against each `AccountRequest` in the plan and, if all triggers match, it applies a set of **Actions**.

### Version Information
- **Version:** 1.8.0
- **Language:** BeanShell

---

## Configuration Location

To use this rule, it must be attached to the Source as a `BeforeProvisioning` rule. 
The configuration itself is stored in the application's attributes under a specific key: `cloudServicesIDNSetup`. 

Typically, you update the Source using the IdentityNow REST API, adding the configuration to the source's `connectorAttributes` or `attributes` map (depending on connector type).

**General Structure:**
```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Create",
                "... Triggers ...": [],
                "eventActions": []
            },
            {
                "Operation": "Disable",
                "... Triggers ...": [],
                "eventActions": []
            }
        ]
    }
}
```

---

## 1. Triggers

Triggers determine whether an event configuration applies to an `AccountRequest`.
The rule evaluates multiple trigger types. **All defined triggers in a specific event configuration block must match for the actions to execute (AND logic).**

### 1.1 Operation (Required)
The `AccountRequest` operation type.
- **Key:** `Operation`
- **Values:** `Create`, `Modify`, `Enable`, `Disable`, `Delete`

### 1.2 Identity Attribute Triggers
Validates the values of the Identity triggering the provisioning.
- **Key:** `Identity Attribute Triggers` (List)
- **Structure:** `{"Attribute": "department", "Operation": "eq" | "ne", "Value": "Sales"}`
- **Note:** Supports wildcard matching (`*` and `?`) in the `Value`.

### 1.3 Account Attribute Update Triggers
Validates if the current `AccountRequest` contains a specific attribute update.
- **Key:** `Account Attribute Update Triggers` (List)
- **Structure:** `{"Attribute": "title", "Operation": "eq" | "ne", "Value": "Manager"}`

### 1.4 Entitlement Update Triggers
Validates if the `AccountRequest` is adding or removing specific entitlements.
- **Key:** `Entitlement Update Triggers` (List)
- **Structure:** `{"Attribute": "memberOf", "Operation": "Add" | "Remove" | "Set", "Value": "CN=Sales,OU=Groups,DC=domain,DC=com"}`

### 1.5 Entitlement Name Update Triggers
Similar to Entitlement Update Triggers, but evaluates against the entitlement's **Display Name** instead of its native value.
- **Key:** `Entitlement Name Update Triggers` (List)
- **Structure:** `{"Attribute": "memberOf", "Operation": "Add" | "Remove" | "Set", "Value": "Sales Group"}`

### 1.6 Entitlement Cardinality Update Triggers
Checks if an entitlement update operation is adding the *first* value or removing the *last* value. Useful for assigning/removing base access when groups go to 0 or 1.
- **Key:** `Entitlement Cardinality Update Triggers` (List)
- **Structure:** `{"Attribute": "memberOf", "Operation": "FIRSTADDED" | "LASTREMOVED"}`

### 1.7 Current Account Status Trigger
Validates the current status of the target account.
- **Key:** `Current Account Status Trigger` (String)
- **Values:** `"ACTIVE"`, `"DISABLED"`

---

## 2. Actions

If the triggers match, the rule iterates through the `eventActions` list and executes them sequentially.

- **Key:** `eventActions` (List of objects)
- **Structure:** `{"Action": "ActionName", "Attribute": "attrName", "Value": "val"}`

### Available Actions

| Action | Attribute | Value | Description |
| :--- | :--- | :--- | :--- |
| **ADMoveAccount** | N/A | The new OU string | Updates the request to set `AC_NewParent` to move an AD account. |
| **ADRenameAccount** | N/A | The new name string | Updates the request to set `AC_NewName` to rename an AD account. |
| **ChangeOperation** | N/A | New Operation (e.g. `Modify`) | Changes the operation of the `AccountRequest`. |
| **RemoveEntitlements**| Name of entitlement attribute | N/A | Evaluates the user's existing entitlements for the specified attribute and issues a `Remove` request for all of them. |
| **RemoveADEntitlements**| N/A | Domain Users Group DN | Replaces all AD group memberships with a single specified Domain Users group. |
| **ScramblePassword** | Name of password attribute | N/A | Generates an 18-character random password and sets it on the `AccountRequest`. |
| **UpdateAttribute** | Target attribute name | The new value | Adds an `AttributeRequest` to `Set` the specified attribute. |
| **AddArgument** | Target argument name | The argument value | Adds an execution argument to the `AccountRequest` (e.g., passing variables to a connector). |
| **AddArgumentIfNotNull**| Target argument name | The argument value | Same as `AddArgument`, but skips if the resolved value is null or empty. |
| **ThrowError** | N/A | Error Message String | Terminates the provisioning transaction by throwing a `GeneralException`. |
| **StopProcessing** | N/A | N/A | Stops processing further actions and event configurations in the rule. |

---

## 3. Value Substitution Variables

The rule supports dynamic value replacement in `Value` strings. This is highly useful for actions like `UpdateAttribute`, `AddArgument`, `ADMoveAccount`, or `ADRenameAccount`.

- `#{null}` - Resolves to an actual Java `null`.
- `#{identity.attributeName}` - Replaces with the attribute value from the Identity.
- `#{manager.attributeName}` - Replaces with the attribute value from the Identity's Manager.
- `#{account.attributeName}` - Replaces with the existing attribute value from the target account.
- `#{now}` - Replaces with the current Date string.
- `#{now.FORMAT}` - Replaces with a formatted date. Supported formats:
  - `EPOCH_TIME` - Standard Unix Timestamp.
  - `EPOCH_TIME_JAVA` - Java Epoch Timestamp (milliseconds).
  - `EPOCH_TIME_WIN32` - Windows NT Time (100-nanosecond intervals since Jan 1, 1601).
  - `ISO8601` - e.g., `2023-01-01T12:00:00.000Z`
  - Any standard `SimpleDateFormat` string (e.g., `#{now.yyyy-MM-dd}`)

---

## 4. Configuration Examples

### 4.1 Action Examples

Each example below is a complete `cloudServicesIDNSetup` fragment. `eventActions` run in order; later actions see the effects of earlier ones.

#### ADMoveAccount
Sets `AC_NewParent` so IQService moves the AD account to the given OU. Skips the move if the account already lives in that OU. `Value` supports substitution.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "ADMoveAccount",
                        "Value": "OU=Disabled,OU=Users,OU=#{identity.location},DC=company,DC=com"
                    }
                ]
            }
        ]
    }
}
```

#### ADRenameAccount
Sets `AC_NewName` so IQService renames the AD account (typically the CN/RDN). `Value` supports substitution.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Modify",
                "eventActions": [
                    {
                        "Action": "ADRenameAccount",
                        "Value": "CN=#{identity.displayName}"
                    }
                ]
            }
        ]
    }
}
```

#### ChangeOperation
Changes the `AccountRequest` operation. `Value` must be a valid `AccountRequest.Operation` name (`Create`, `Modify`, `Enable`, `Disable`, `Delete`). Invalid values are logged and ignored. Place this last if earlier actions should still run against the original matching operation.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "ADMoveAccount",
                        "Value": "OU=Disabled,OU=Users,DC=company,DC=com"
                    },
                    {
                        "Action": "ChangeOperation",
                        "Value": "Modify"
                    }
                ]
            }
        ]
    }
}
```

#### RemoveEntitlements
Reads the identity's current account values for `Attribute` and adds a `Remove` request for all of them. Use this for non-AD entitlement attributes, or AD when you want every group removed (including Domain Users).

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "RemoveEntitlements",
                        "Attribute": "memberOf"
                    }
                ]
            }
        ]
    }
}
```

#### RemoveADEntitlements
Sets `memberOf` to a single group (normally Domain Users). `Value` must be a DN that contains `DC`. Unlike `RemoveEntitlements`, this replaces membership rather than issuing individual removes.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "RemoveADEntitlements",
                        "Value": "CN=Domain Users,CN=Users,DC=company,DC=com"
                    }
                ]
            }
        ]
    }
}
```

#### ScramblePassword
Generates an 18-character random password and sets it on the named password attribute.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "ScramblePassword",
                        "Attribute": "*password*"
                    }
                ]
            }
        ]
    }
}
```

#### UpdateAttribute
Adds an `AttributeRequest` to `Set` the named attribute. `Value` supports substitution, including `#{null}` to clear the attribute.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "UpdateAttribute",
                        "Attribute": "terminationDate",
                        "Value": "#{now.ISO8601}"
                    },
                    {
                        "Action": "UpdateAttribute",
                        "Attribute": "manager",
                        "Value": "#{null}"
                    }
                ]
            }
        ]
    }
}
```

#### AddArgument
Adds an execution argument on the `AccountRequest` (connector/IQService arguments). Always sets the argument, including when the resolved value is null or empty.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Create",
                "eventActions": [
                    {
                        "Action": "AddArgument",
                        "Attribute": "CreateMailbox",
                        "Value": "True"
                    }
                ]
            }
        ]
    }
}
```

#### AddArgumentIfNotNull
Same as `AddArgument`, but skips the argument when the resolved value is null or empty. Use this when the value comes from identity attributes that may be missing.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Create",
                "eventActions": [
                    {
                        "Action": "AddArgumentIfNotNull",
                        "Attribute": "PrimarySmtpAddress",
                        "Value": "#{identity.email}"
                    }
                ]
            }
        ]
    }
}
```

#### ThrowError
Stops the provisioning transaction by throwing a `GeneralException`. `Value` is the error message; if it is missing or not a string, the message is `Unspecified Exception`.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Modify",
                "Current Account Status Trigger": "ACTIVE",
                "Identity Attribute Triggers": [
                    {
                        "Attribute": "department",
                        "Operation": "eq",
                        "Value": "Executives"
                    }
                ],
                "eventActions": [
                    {
                        "Action": "ThrowError",
                        "Value": "Automated modification of Executive accounts is strictly prohibited."
                    }
                ]
            }
        ]
    }
}
```

#### StopProcessing
Returns immediately from the rule: remaining actions in this event, and remaining event configurations, are not applied. Provisioning continues with the plan as modified so far. `Attribute` and `Value` are ignored.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "Identity Attribute Triggers": [
                    {
                        "Attribute": "employeeType",
                        "Operation": "eq",
                        "Value": "VIP"
                    }
                ],
                "eventActions": [
                    {
                        "Action": "StopProcessing"
                    }
                ]
            },
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "RemoveEntitlements",
                        "Attribute": "memberOf"
                    }
                ]
            }
        ]
    }
}
```

In this example, VIP identities skip entitlement removal on Disable; all other identities still hit the second event.

### 4.2 Combined Scenarios

#### Example 1: Set a Termination Date and Move OU on Disable
When an account is disabled, record the disable date on an attribute and move the account to a Disabled Users OU based on their location.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "eventActions": [
                    {
                        "Action": "UpdateAttribute",
                        "Attribute": "terminationDate",
                        "Value": "#{now.ISO8601}"
                    },
                    {
                        "Action": "ADMoveAccount",
                        "Value": "OU=Disabled,OU=Users,OU=#{identity.location},DC=company,DC=com"
                    },
                    {
                        "Action": "RemoveEntitlements",
                        "Attribute": "memberOf"
                    }
                ]
            }
        ]
    }
}
```

#### Example 2: Scramble Password and Clear Manager if Department is "Contractor"
If the Identity is a contractor and their account is being Disabled, scramble their password and nullify their manager.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Disable",
                "Identity Attribute Triggers": [
                    {
                        "Attribute": "employeeType",
                        "Operation": "eq",
                        "Value": "Contractor"
                    }
                ],
                "eventActions": [
                    {
                        "Action": "ScramblePassword",
                        "Attribute": "*password*"
                    },
                    {
                        "Action": "UpdateAttribute",
                        "Attribute": "manager",
                        "Value": "#{null}"
                    }
                ]
            }
        ]
    }
}
```

#### Example 3: Injecting Exchange Arguments on Create
When creating an Active Directory account, we might need to pass arguments down to the IQService to trigger mailbox creation, but only if the user has an email address.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Create",
                "eventActions": [
                    {
                        "Action": "AddArgumentIfNotNull",
                        "Attribute": "CreateMailbox",
                        "Value": "True"
                    },
                    {
                        "Action": "AddArgumentIfNotNull",
                        "Attribute": "PrimarySmtpAddress",
                        "Value": "#{identity.email}"
                    }
                ]
            }
        ]
    }
}
```

#### Example 4: Prevent Modification of Active Accounts in Sensitive Departments
If an attempt is made to Modify an Active account belonging to the "Executives" department, throw an error to block the provisioning plan.

```json
{
    "cloudServicesIDNSetup": {
        "eventConfigurations": [
            {
                "Operation": "Modify",
                "Current Account Status Trigger": "ACTIVE",
                "Identity Attribute Triggers": [
                    {
                        "Attribute": "department",
                        "Operation": "eq",
                        "Value": "Executives"
                    }
                ],
                "eventActions": [
                    {
                        "Action": "ThrowError",
                        "Value": "Automated modification of Executive accounts is strictly prohibited."
                    }
                ]
            }
        ]
    }
}
```
