# Sentinel → ISC response playbook

Opt-in Logic App + Key Vault that submits SailPoint Response Actions from Microsoft Sentinel.

## Deploy

```bash
# capability check (no secrets)
just response-capability

# dry-run (default): resolve identity only; never POSTs DISABLE_*
RESPONSE_CLIENT_ID=... RESPONSE_CLIENT_SECRET=... just response

# allow submit (still requires ISC workflow approval)
RESPONSE_CLIENT_ID=... RESPONSE_CLIENT_SECRET=... just response dry_run=false
```

Credentials must include `sp:identity-sec-intel:read` and `sp:identity-sec-intel:write`.
Do **not** reuse the ingestion PAT (`sp:search:read`).

## Invoke (non-destructive)

1. Open the Logic App `sailpoint-isc-response` in the Azure portal
2. Copy the HTTP POST trigger URL (or use Run with payload)
3. POST [`sample-incident-payload.json`](sample-incident-payload.json) with a real lab identity email / `IdentityId`
4. Confirm `DryRun: true` in the response body — no disable is sent

## ISC side

Follow [`../workflows/intel-response-actions.contract.md`](../workflows/intel-response-actions.contract.md) to enable the
SecOps Identity Intelligence Response Action workflow with approval.
