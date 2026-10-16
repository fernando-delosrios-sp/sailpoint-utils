import { loadConfig } from './common.mjs';
import { actorApprovalLines } from './drift-actors.mjs';
import { ownersFromPlan } from './plan.mjs';

/** ISC approvals show one description string; keep it short and scannable. */
function renderApprovalText(lines) {
  return lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
}

/** Cap long path lists so the approval description stays readable (and small). */
function previewPaths(paths, limit = 20) {
  if (paths.length === 0) return ['_none_'];
  const shown = paths.slice(0, limit).map((p) => `- ${p}`);
  if (paths.length > limit) shown.push(`...and ${paths.length - limit} more`);
  return shown;
}

/**
 * Build the payload posted to the ISC external-trigger workflow for a PR change.
 */
export function buildChangeApprovalPayload({
  plan,
  diffHash,
  pr,
  config = loadConfig(),
}) {
  const owners = ownersFromPlan(plan);
  const items = plan.operations
    .filter((o) => o.op !== 'skip')
    .map((o) => ({
      op: o.op,
      type: o.type,
      name: o.name,
      ownerId: o.owner?.id ?? null,
      ownerName: o.owner?.name ?? null,
    }));

  return {
    kind: 'change',
    diffHash,
    pr: {
      number: pr.number,
      title: pr.title,
      body: pr.body ?? '',
      url: pr.url,
      author: pr.author,
      headSha: pr.headSha ?? pr.headRefOid ?? null,
    },
    summary: plan.summary,
    // ISC approvals render a single description string, not structured input.
    approvalText: renderApprovalText([
      `Pull request #${pr.number}: ${pr.title}`,
      `Opened by ${pr.author}`,
      pr.url,
      '',
      ...items.map((i) => `${i.op} ${i.type}: ${i.name}`),
      '',
      `Diff hash: ${diffHash}`,
    ]),
    items,
    owners,
    governanceGroupId: config.approval?.governanceGroupId,
    github: {
      owner: config.github?.owner,
      repo: config.github?.repo,
    },
  };
}

/**
 * Build the payload for a full restore approval (governance group only).
 */
export function buildRestoreApprovalPayload({
  plan,
  planHash,
  sourceTag,
  requester,
  config = loadConfig(),
}) {
  const items = plan.operations
    .filter((o) => o.op !== 'skip')
    .map((o) => ({
      op: o.op,
      type: o.type,
      name: o.name,
    }));

  return {
    kind: 'restore',
    planHash,
    sourceTag,
    requester,
    summary: plan.summary,
    approvalText: renderApprovalText([
      `Full restore of the access model from tag ${sourceTag}`,
      `Requested by ${requester}`,
      '',
      plan.summary ?? '',
      '',
      ...items.map((i) => `${i.op} ${i.type}: ${i.name}`),
      '',
      `Plan hash: ${planHash}`,
    ]),
    items,
    governanceGroupId: config.approval?.governanceGroupId,
    github: {
      owner: config.github?.owner,
      repo: config.github?.repo,
    },
  };
}

/**
 * Build the payload for a drift-sync approval (governance group only — item
 * owners are never asked, regardless of config.approval.ownerApproval, since
 * drift wasn't requested by anyone and there's no single "owner of the PR" to
 * loop over).
 *
 * Only driftHash (not the full added/changed/deleted lists) travels through
 * the ISC trigger round trip: the execute side re-detects drift from live
 * ISC and compares hashes, so there's no need to carry potentially large
 * path lists through the workflow payload.
 */
export function buildDriftApprovalPayload({ drift, config = loadConfig() }) {
  return {
    kind: 'drift',
    driftHash: drift.driftHash,
    summary: {
      added: drift.added.length,
      changed: drift.changed.length,
      deleted: drift.deleted.length,
    },
    approvalText: renderApprovalText([
      'ISC no longer matches the access model in git — items were changed outside the PR flow.',
      '',
      ...actorApprovalLines(drift.actors),
      ...(drift.actors ? [''] : []),
      `Added (${drift.added.length})`,
      ...previewPaths(drift.added),
      '',
      `Changed (${drift.changed.length})`,
      ...previewPaths(drift.changed),
      '',
      `Deleted (${drift.deleted.length})`,
      ...previewPaths(drift.deleted),
      '',
      'Approving copies these items from ISC into git.',
      'Rejecting puts ISC back to match git. Entitlements this repo cannot create or delete stay as they are.',
      'If nobody acts before the timeout, ISC is left unchanged and the next backup asks again.',
      `Drift hash: ${drift.driftHash}`,
    ]),
    governanceGroupId: config.approval?.governanceGroupId,
    github: {
      owner: config.github?.owner,
      repo: config.github?.repo,
    },
  };
}

/**
 * Call an ISC external trigger URL with the trigger's OAuth client credentials.
 * `tokenUrl` is the tenant API host + /oauth/token.
 */
export async function invokeExternalTrigger({
  triggerUrl,
  tokenUrl,
  clientId,
  clientSecret,
  payload,
  fetchImpl = globalThis.fetch,
}) {
  const tokenRes = await fetchImpl(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: clientId,
      client_secret: clientSecret,
    }),
  });
  if (!tokenRes.ok) {
    throw new Error(`External trigger token failed: ${tokenRes.status} ${await tokenRes.text()}`);
  }
  const accessToken = (await tokenRes.json()).access_token;

  const res = await fetchImpl(triggerUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`External trigger invoke failed: ${res.status} ${text}`);
  }
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}