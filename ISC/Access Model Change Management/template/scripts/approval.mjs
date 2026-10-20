import { loadConfig } from './common.mjs';
import { actorApprovalLines } from './drift-actors.mjs';

/** ISC approvals show one description string; keep it short and scannable. */
function renderApprovalText(lines) {
  return lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
}

/** Roles and access profiles first; entitlement drift is usually the bulk. */
const PATH_RANK = ['access/roles/', 'access/access-profiles/'];

function pathRank(path) {
  const index = PATH_RANK.findIndex((prefix) => path.startsWith(prefix));
  return index === -1 ? PATH_RANK.length : index;
}

/**
 * `plan.summary` is `{ create, update, delete, skip }` counts, not text.
 * String-concatenating the object directly rendered the approval governance
 * reads as the literal text "[object Object]" — seen live on every restore
 * approval.
 */
function summaryLine(summary) {
  if (!summary) return '';
  const { create = 0, update = 0, delete: del = 0, skip = 0 } = summary;
  return `${create} create, ${update} update, ${del} delete, ${skip} skip`;
}

/**
 * Cap long path lists so the approval description stays readable (and small).
 * A thousand entitlements must not push the one changed role out of view, so
 * the preview is ordered by kind rather than alphabetically.
 */
function previewPaths(paths, limit = 20) {
  if (paths.length === 0) return ['_none_'];
  const ordered = [...paths].sort((a, b) => pathRank(a) - pathRank(b) || a.localeCompare(b));
  const shown = ordered.slice(0, limit).map((p) => `- ${p}`);
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
  const items = plan.operations
    .filter((o) => o.op !== 'skip')
    .map((o) => ({
      op: o.op,
      type: o.type,
      name: o.name,
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
  sourceRef,
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
    sourceRef,
    requester,
    summary: plan.summary,
    approvalText: renderApprovalText([
      `Full restore of the access model from ${sourceRef}`,
      `Requested by ${requester}`,
      '',
      summaryLine(plan.summary),
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
 * Build the payload for a drift-sync approval. The governance group is the
 * only approver, same as a change or a restore.
 *
 * Only driftHash (not the full added/changed/deleted lists) travels through
 * the ISC trigger round trip: the execute side re-detects drift from live
 * ISC and compares hashes, so there's no need to carry potentially large
 * path lists through the workflow payload.
 */
export function buildDriftApprovalPayload({ drift, issueUrl = null, prUrl = null, config = loadConfig() }) {
  return {
    kind: 'drift',
    driftHash: drift.driftHash,
    issueUrl,
    prUrl,
    summary: {
      added: drift.added.length,
      changed: drift.changed.length,
      deleted: drift.deleted.length,
    },
    approvalText: renderApprovalText([
      'ISC no longer matches the access model in git — items were changed outside the PR flow.',
      // This description is truncated. The pull request is the diff; the issue
      // carries the full lists and who changed each item.
      ...(prUrl ? [`Diff: ${prUrl}`] : []),
      ...(issueUrl ? [`Full detail: ${issueUrl}`] : []),
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