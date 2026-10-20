/**
 * The GitHub issue that records a drift detection.
 *
 * The ISC approval shows one truncated description string, so the issue is
 * where the whole picture lives: every drifted path, who touched it, and the
 * hash the decision will be checked against. The approval links here.
 */

/** Marker the callback greps for to find the issue belonging to a decision. */
export const DRIFT_ISSUE_LABEL = 'amcm-drift';

function section(heading, paths) {
  if (paths.length === 0) return [`### ${heading} (0)`, '', '_none_', ''];
  return [`### ${heading} (${paths.length})`, '', ...paths.map((p) => `- \`${p}\``), ''];
}

export function driftIssueTitle(drift, now = new Date()) {
  const total = drift.added.length + drift.changed.length + drift.deleted.length;
  const day = now.toISOString().slice(0, 10);
  const who = drift.actors?.modifiers?.length
    ? ` by ${drift.actors.modifiers.join(', ')}`
    : '';
  return `Drift detected — ${total} item${total === 1 ? '' : 's'} changed in ISC${who} (${day})`;
}

/** Line the decision callback reads to find the pull request for this issue. */
export function driftPullRequestUrl(body) {
  const match = String(body ?? '').match(/^Drift-PR: (\S+)\s*$/m);
  return match ? match[1] : null;
}

export function driftIssueBody(drift, { prUrl = null } = {}) {
  const actors = drift.actors ?? null;
  const who = [];
  if (actors?.status === 'unavailable') {
    who.push('Who changed it: **unknown** — the ISC audit search failed.');
    if (actors.error) who.push('', `> ${actors.error}`);
    who.push('', 'The service identity needs the Search user level (`sp:search:read`).');
  } else if (actors) {
    who.push(`Audit events since \`${actors.since}\`:`, '');
    who.push(...(actors.lines?.length ? actors.lines : ['- no matching audit event']));
    if (actors.status === 'partial') {
      who.push('', '_Audit search stopped early, so some actors may be missing._');
    }
  }

  const resolution = prUrl
    ? [
      `Drift-PR: ${prUrl}`,
      '',
      'The pull request diff is the proposed resolution. Approving in ISC merges it.',
      'Rejecting closes it and puts ISC back to match git.',
      '',
    ]
    : [];

  return [
    'ISC no longer matches the access model in git — items were changed outside the PR flow.',
    '',
    ...resolution,
    'An approval has been sent to the governance group in ISC. Approving copies',
    'these items from ISC into git; rejecting puts ISC back to match git.',
    '',
    '## Who changed it',
    '',
    ...who,
    '',
    '## What changed',
    '',
    ...section('Added', drift.added),
    ...section('Changed', drift.changed),
    ...section('Deleted', drift.deleted),
    '---',
    '',
    `Drift hash: \`${drift.driftHash}\``,
  ].join('\n');
}

export function renderDriftIssue(drift, now = new Date(), { prUrl = null } = {}) {
  return {
    title: driftIssueTitle(drift, now),
    body: driftIssueBody(drift, { prUrl }),
    label: DRIFT_ISSUE_LABEL,
    driftHash: drift.driftHash,
  };
}

/**
 * Comment posted when the governance decision lands, before the issue closes.
 */
export function driftDecisionComment({ decision, comment, runUrl, detail }) {
  const headline = {
    approved: 'Approved — the drift was copied from ISC into `main`.',
    rejected: 'Rejected — ISC was put back to match git.',
    expired: 'Expired — nobody decided in time. ISC is unchanged and the next backup will ask again.',
    stale: 'Not applied — ISC changed again between the approval and this run, so nothing was synced.',
  }[decision] ?? `Decision: ${decision}`;

  return [
    headline,
    ...(comment ? ['', `> ${comment}`] : []),
    ...(detail ? ['', detail] : []),
    ...(runUrl ? ['', `[Workflow run](${runUrl})`] : []),
  ].join('\n');
}
