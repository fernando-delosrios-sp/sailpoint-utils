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

## Organization structure SQL

Script: [`sql/20260921_subunit_five_groups.sql`](sql/20260921_subunit_five_groups.sql)

Removes the `Organization` root and reshapes `ohrm_subunit` into five top-level groups, keeping every existing leaf (and its `id`) so `hs_hr_employee.work_station` references stay valid:

| Group | Leaves |
| --- | --- |
| Corporate Services | Executive Management, Finance, Accounting, Human Resources |
| Technology | Engineering, Information Technology |
| Operations | Inventory, Regional Operations, Asset Management |
| Commercial | Sales, Call Center |
| Healthcare | Nursing, Doctors, Students, Nursing-ER, Nursing-NICU, Radiology |

Before changing data, the script creates snapshot table `ohrm_subunit_backup_20260921` once (not overwritten on re-run). It nulls any `work_station` pointing at Organization, deletes that row, then writes explicit `lft` / `rgt` / `level` values. A commented rollback block at the end of the script restores from the snapshot and removes the four inserted groups.

Groups are `level` 1 and leaves `level` 2, not 0 and 1. The Sub Unit dropdown serializes `level` as the option's `_indent`, and the widget treats `_indent` 1 as flush left, so a 0-based tree renders as one flat list. Because nothing sits at `level` 0 any more, Admin → Organization → General Information can no longer rename the tree; that update targets `level = 0` and matches no row.

Run against a backed-up database. Log out and back in after applying so OrangeHRM refreshes its cached org tree.

## Duplicate job titles SQL

Script: [`sql/20260924_job_title_dedupe.sql`](sql/20260924_job_title_dedupe.sql)

Fixes a Job Title dropdown that repeats the same label (for example three `Doctor` and three `Doctor Chief` options). `AddEmployeeForm::_getJobTitles()` keys the dropdown by `ohrm_job_title.id` and keeps every row with `is_deleted = 0`, and nothing in the schema makes `job_title` unique, so an import that ran more than once leaves several active rows per title and each one becomes its own option.

Section 1 is read only: it lists every title bracketed and hex-encoded (so a trailing space or a case difference is visible), the duplicate groups, how many employees sit on each copy, and everything that references `ohrm_job_title` in this build. It also prints a duplicate check for every other `ohrm_*` lookup table, because the same double import usually hits sub units, locations, and employment statuses too.

The rest of the script keeps one row per title — the lowest id in each duplicate group from the 2026-09-24 preflight (healthcare titles were inserted three times, ids stepping +12; `Enterprise Sales Executive` twice as 188/189) — then in one transaction:

- repoints `hs_hr_employee.job_title_code` and `ohrm_job_vacancy.job_title_code`
- on `hs_hr_jobtit_empstat` (unique with `estat_code`) and `ohrm_job_specification_attachment` (one file per title), deletes the losing row when the survivor already has that mapping or file, otherwise moves it
- retires the extra titles with `is_deleted = 1`

Those four FKs are this build (`hs_hr_employee_ibfk_3`, `hs_hr_jobtit_empstat_ibfk_1`, `ohrm_job_specification_attachment_ibfk_1`, `ohrm_job_vacancy_ibfk_1`). Snapshot tables for each child plus the merge map `ohrm_job_title_merge_20260924` are created once and are not overwritten on re-run; the rollback block restores from them. Section 6 holds an optional hard delete.

Retired titles keep their name, so aggregated ISC account and identity attributes do not change — unless section 1a shows the duplicates differing by whitespace or case, in which case moved employees get the surviving spelling and any birthright criteria matching on the title string should be re-checked.

