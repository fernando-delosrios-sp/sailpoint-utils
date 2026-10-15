# Custom Password Instructions

Use this API to implement custom password instruction functionality.

3 endpoints. Paths are relative to the environment API host.

## Create custom password instructions

`POST /custom-password-instructions/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API creates the custom password instructions for the specified page ID.

The `pageId` determines which login and password-recovery screen your custom instructions appear on. The following table describes each supported page ID and where its text is displayed:

| Page ID | Where the custom text appears |
| --- | --- |
| `flow-selection:select` | Flow-selection landing screen, under "Need help signing in?", above the navigation links. |
| `reset-password:enter-username` | Reset-password "enter username" step, under the prompt, above the username field. |
| `unlock-account:enter-username` | Unlock-account "enter username" step, under the prompt, above the username field. |
| `forget-username:user-email` | Forgot-username screen, under "Enter the email address for", above the email field. |
| `reset-password:enter-password` | Reset-password "new password" step, under the header, above the password fields. |
| `change-password:enter-password` | Same "new password" screen, but the authenticated app/sync-group change variant. |
| `reset-password:finish` | Reset-password success screen, under the success icon/heading, above the return button. |
| `change-password:finish` | Success screen for the authenticated app/sync-group change, under the heading. |
| `mfa:select` | MFA method-selection step, under the prompt, above the list of MFA options. |
| `mfa:enter-code` | MFA code-entry step, under the option label, above the code field. |
| `mfa:enter-kba` | KBA step, under "Please answer these security questions", above the questions form. |
| `unlock-account:finish` | Unlock-account success screen, under the success icon/heading, above the return button. |

In every case the text shows as an info-icon + paragraph block that only appears if custom text is configured for that page ID, positioned between the screen's built-in heading and its form controls.

Body:

```json
{
  "pageId": "reset-password:enter-password",
  "pageContent": "See company password policies for details by clicking <a href=\"url\">here</a>"
}
```

## Get custom password instructions by page id

`GET /custom-password-instructions/v1/:pageId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the custom password instructions for the specified page ID.

Query:

- `locale`: The locale for the custom instructions, a BCP47 language tag. The default value is \"default\".

## Delete custom password instructions by page id

`DELETE /custom-password-instructions/v1/:pageId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API delete the custom password instructions for the specified page ID.

Query:

- `locale`: The locale for the custom instructions, a BCP47 language tag. The default value is \"default\".
