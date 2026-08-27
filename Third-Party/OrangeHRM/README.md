# SailPoint ISC Aggregation Changes

## Purpose

OrangeHRM plugin changes that trigger SailPoint account aggregation immediately after relevant employee lifecycle events—create, terminate, activate, job/contact updates, and report-to changes—so ISC discovers the latest HR data without waiting for the scheduled aggregation cycle.

## Triggering workflows

ISC aggregation is requested after each of these successful operations:

- Creating an employee.
- Confirming **Terminate Employment**.
- Confirming **Activate Employment**.
- Saving changes on the employee **Contact Details** page.
- Saving changes on the employee **Job** page, including employment contract start and end dates.
- Saving **Custom Fields** on the employee **Job** page.
- Adding, updating, or removing assigned supervisors and subordinates in the **Report-to** section.

Cancelled actions, invalid forms, and validation failures do not trigger aggregation.

## Implementation

Employee creation retains the original instance entry point:

```php
$this->callIIQ();
```

The additional update workflows use `AddEmployeeForm::callIIQAfterChange()`. Both methods delegate to the same ISC request implementation.

It is defined in:

```text
symfony/plugins/orangehrmPimPlugin/lib/form/AddEmployeeForm.php
```

This preserves the original employee-creation behavior while allowing other workflows to reuse the same authentication and aggregation logic.

### Changed files

| Workflow | File | Behavior |
| --- | --- | --- |
| Employee creation | `lib/form/AddEmployeeForm.php` | Retains the original ISC call after the new employee and related form data are saved. |
| Employment termination | `lib/form/EmployeeTerminateForm.php` | Calls ISC after the termination record is saved. |
| Employment activation | `modules/pim/actions/activateEmployementAction.class.php` | Calls ISC after the employee is reactivated. |
| Contact details update | `modules/pim/actions/contactDetailsAction.class.php` | Calls ISC after valid contact details and the employee event are saved. |
| Job details update | `modules/pim/actions/viewJobDetailsAction.class.php` | Calls ISC after valid job details, including contract dates, and the employee event are saved. |
| Job custom fields update | `modules/pim/actions/updateCustomFieldsAction.class.php` | Calls ISC after valid custom fields are saved when the custom-field screen is Job. Custom fields on other screens do not trigger aggregation. |
| Report-to assignment | `modules/pim/actions/updateReportToDetailAction.class.php` | Calls ISC after a supervisor or subordinate relationship is successfully added or updated. |
| Report-to removal | `modules/pim/actions/deleteReportToSupervisorAction.class.php` and `deleteReportToSubordinateAction.class.php` | Calls ISC after a supervisor or subordinate relationship is successfully removed. |

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

