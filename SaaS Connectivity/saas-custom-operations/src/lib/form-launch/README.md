# Form launch

`launchForm` is the shared ensure → create → notify facade for standalone ISC forms.

## Configuration

Provide:

- a `FormsApiLike` client;
- either an existing `formDefinitionId`, or `formName`, definition `ownerId`, and a prepared definition `template`;
- recipient, creating source, and already-serialized `formInput`;
- notification header, body, and recipients;
- optional `expire`.

Notification values may be literals or builders. Builders run after instance creation and receive `{ formUrl }`, so email content can link to the created form.

## Return value

The facade returns a `FormNotification`:

- `formUrl`
- `emailHeader`
- `emailBody`
- `emailRecipients`

## Operation-owned behavior

Operations continue to own seed loading and template construction, formInput serialization, recipient identity and email policy, skip/cap decisions, and `ctx.persist`. The facade does not persist accounts or resolve recipients.
