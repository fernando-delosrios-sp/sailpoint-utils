# form-notification

Typed **form notification envelope** and prefix→persist mapper for standalone form launch outputs.

## Envelope fields

| Field | Persist suffix | Meaning |
| --- | --- | --- |
| `formUrl` | `:form-url` | Standalone form URL for workflow deep links |
| `emailHeader` | `:form-email-header` | Plain-text email subject |
| `emailBody` | `:form-email-body` | Compact HTML body (opaque string; builders stay at call sites) |
| `emailRecipients` | `:form-email-recipients` | Recipient emails as `string[]` |

## Prefix mapping

`toPersistAttributes(prefix, envelope)` uses the operation slug without a trailing colon and appends the suffixes above:

- `sod-remediation` → `sod-remediation:form-url`, …
- `access-model-sod-remediation` → `access-model-sod-remediation:form-url`, …
- `access-expiration-reminders` → `access-expiration-reminders:form-url`, …

Keys and value types are unchanged from the prior inline persist wiring. The mapper does not call ISC APIs or resolve recipients.
