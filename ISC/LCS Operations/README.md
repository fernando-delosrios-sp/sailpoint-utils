# User Manual: LCS Operations BeforeProvisioning Rule

This user manual provides comprehensive documentation and configuration examples for the **LCS Operations BeforeProvisioning Rule**.

## Overview
The **LCS Operations** rule is a BeanShell rule designed to intercept `Modify` Provisioning Plans in SailPoint IdentityNow right before they are executed. Its main purpose is to translate dummy attribute updates—indicating Lifecycle State (LCS) changes—into native connector operations like account Enable/Disable, or Active Directory specific operations like OU moves and CN renames.

Instead of writing custom code for LCS transitions, this rule relies on specific dummy attributes being sent in the `AccountRequest` (typically via Attribute Sync).

### Version Information
- **Language:** BeanShell
- **Type:** BeforeProvisioning

---

## Configuration Location

To use this rule, it must be attached to the Source as a `BeforeProvisioning` rule.
The configuration itself is driven dynamically by the attributes sent to the target application during a provisioning event. 

You must add dummy attributes to your Source Schema (e.g., `LCS`, `LCS_INACTIVE_OP`, `LCS_INACTIVE_OU`) and map them accordingly in your Attribute Sync or Provisioning Policies.

---

## 1. How It Works

1. The rule intercepts `Modify` account requests and looks for an attribute update named `LCS`.
2. If found, it reads the value (e.g., `inactive`, `active`).
3. It then looks for other attribute updates in the same request matching the pattern `LCS_<STATE>_<OPTION>` (e.g., `LCS_INACTIVE_OP`).
4. It extracts these options and removes all `LCS*` attribute requests from the original plan so they are not sent to the target system.
5. It then applies the requested operations based on the extracted options and the connector type.

---

## 2. Supported Options

The following options are extracted when an `LCS` attribute request is present.

### 2.1 LCS State
The trigger attribute that indicates the state.
- **Attribute Name:** `LCS`
- **Example Values:** `active`, `inactive`, `prehire`

### 2.2 Operation (OP)
Triggers a secondary `AccountRequest` with the specified operation.
- **Attribute Pattern:** `LCS_<STATE>_OP`
- **Values:** `Enable`, `Disable`, `Delete` (Any valid `AccountRequest.Operation`)

### 2.3 Organizational Unit (OU) - Active Directory Only
Specifies the target OU for an account move.
- **Attribute Pattern:** `LCS_<STATE>_OU`
- **Values:** Any valid OU Distinguished Name (e.g., `OU=Disabled,DC=domain,DC=com`)

---

## 3. Connector Specific Behaviors

### 3.1 Active Directory (`sailpoint.connector.ADLDAPConnector`)

The rule provides specialized processing for Active Directory targets:
- **`cn` Rename:** If a `cn` attribute update is present, it translates it into an `AC_NewName` request.
- **`distinguishedName` Move:** If a `distinguishedName` attribute update is present, it extracts the OU portion and translates it into an `AC_NewParent` request.
- **LCS OU Move:** If an `LCS_<STATE>_OU` attribute is provided (and `distinguishedName` was not explicitly updated), it translates it into an `AC_NewParent` request to move the account.
- **Secondary Operations:** Executes the operation defined in `LCS_<STATE>_OP` (e.g., `Disable`).

### 3.2 Default Processing (All Other Connectors)

For any other connector type, the rule only processes the default operation:
- **Secondary Operations:** Executes the operation defined in `LCS_<STATE>_OP` (e.g., `Disable`, `Enable`).

---

## 4. Configuration Examples

### Example 1: Disable and Move AD Account on Leaver

When an identity becomes `inactive`, you want to Disable their AD account and move it to a "Disabled" OU.

**Source Schema Additions:**
- `LCS` (String)
- `LCS_INACTIVE_OP` (String)
- `LCS_INACTIVE_OU` (String)

**Attribute Sync / Provisioning Policy Mapping:**
- `LCS` -> `"inactive"` (Based on identity LCS)
- `LCS_INACTIVE_OP` -> `"Disable"` (Static value)
- `LCS_INACTIVE_OU` -> `"OU=Disabled,DC=company,DC=com"` (Static value)

When the Identity transitions to `inactive`, Attribute Sync generates a `Modify` request:
```text
Modify
  - LCS = "inactive"
  - LCS_INACTIVE_OP = "Disable"
  - LCS_INACTIVE_OU = "OU=Disabled,DC=company,DC=com"
```

The rule intercepts this and splits it into two operations for the connector:
```text
Modify
  - AC_NewParent = "OU=Disabled,DC=company,DC=com"
Disable
```

### Example 2: Enable Account on Joiner

When an identity becomes `active`, you want to Enable their target account (e.g., Salesforce).

**Source Schema Additions:**
- `LCS` (String)
- `LCS_ACTIVE_OP` (String)

**Attribute Sync Mapping:**
- `LCS` -> `"active"`
- `LCS_ACTIVE_OP` -> `"Enable"`

The rule intercepts the `Modify` request containing `LCS="active"` and `LCS_ACTIVE_OP="Enable"`, strips those attributes out, and injects a new `Enable` AccountRequest into the plan.

### Example 3: Standard AD Rename and Move

Even without LCS attribute updates, the rule simplifies AD management for standard modifications. If Attribute Sync pushes an updated `cn` or `distinguishedName`:

**Input Plan:**
```text
Modify
  - cn = "John.Doe"
  - distinguishedName = "CN=John.Doe,OU=Users,DC=company,DC=com"
```

**Output Plan:**
```text
Modify
  - AC_NewName = "CN=John.Doe"
  - AC_NewParent = "OU=Users,DC=company,DC=com"
```
