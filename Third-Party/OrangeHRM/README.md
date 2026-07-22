# SailPoint ISC Aggregation Changes

## Purpose

These changes connect OrangeHRM employee updates with SailPoint Identity Security Cloud (ISC), also referred to as IdentityIQ/IIQ in the source code.

After relevant employee data is saved, OrangeHRM requests an account aggregation so SailPoint can discover the latest data without waiting for its regular aggregation schedule.

## Triggering workflows

ISC aggregation is requested after each of these successful operations:

- Creating an employee.
- Confirming **Terminate Employment**.
- Confirming **Activate Employment**.
- Saving changes on the employee **Contact Details** page.

Cancelled actions, invalid forms, and validation failures do not trigger aggregation.

## Implementation

The shared integration entry point is the static method:

```php
AddEmployeeForm::callIIQ();
```

It is defined in:

```text
symfony/plugins/orangehrmPimPlugin/lib/form/AddEmployeeForm.php
```

Making the method static allows every workflow to use the same authentication and aggregation logic.

### Changed files

| Workflow | File | Behavior |
| --- | --- | --- |
| Employee creation | `lib/form/AddEmployeeForm.php` | Calls ISC after the new employee and related form data are saved. |
| Employment termination | `lib/form/EmployeeTerminateForm.php` | Calls ISC after the termination record is saved. |
| Employment activation | `modules/pim/actions/activateEmployementAction.class.php` | Calls ISC after the employee is reactivated. |
| Contact details update | `modules/pim/actions/contactDetailsAction.class.php` | Calls ISC after valid contact details and the employee event are saved. |

The paths in the table are relative to:

```text
symfony/plugins/orangehrmPimPlugin/
```

## Configuration

`callIIQ()` currently reads its configuration from:

```text
C:\Users\Administrator.SERI\Documents\orangeIIQ.ini
```

### ISC/IDN mode

When `mode=IDN`, the integration:

1. Requests an OAuth access token using `domain`, `client_id`, and `client_secret`.
2. Sends a `POST` request to the load-accounts endpoint for the configured `source_id`.

### IdentityIQ mode

For other mode values, the integration launches the configured IdentityIQ workflow using `url`, `username`, and `password`.

## Runtime behavior

- The ISC call runs synchronously, so its response time contributes to the OrangeHRM save request duration.
- cURL responses and errors are written through PHP's `error_log`.
- A failed SailPoint request is logged but does not roll back the OrangeHRM employee change.

## Production considerations

The current implementation is demo-oriented. Before production use:

- Enable TLS certificate verification.
- Remove logs containing configuration, tokens, credentials, or authentication responses.
- Protect the INI file with appropriate filesystem permissions.
- Move the hard-coded INI path into environment-specific configuration.
- Consider moving aggregation to an asynchronous job so SailPoint response time does not delay the OrangeHRM request.
