/**
 * The GitHub issue that records a drift detection.
 *
 * The ISC approval shows one truncated description string, so the issue is
 * where the picture lives: who touched the items, the paths that fit, and the
 * hash the decision will be checked against. The pull request diff is the
 * complete list. GitHub rejects an issue or pull request body over 65,536
 * characters and a title over 256, so both are fitted before they are sent.
 */

/** Marker the callback greps for to find the issue belonging to a decision. */
export const DRIFT_ISSUE_LABEL = 'amcm-drift';

/** GitHub's documented maximums for an issue or pull request. */
export const GITHUB_BODY_MAX = 65536;
export const GITHUB_TITLE_MAX = 256;

export function fitGithubTitle(title, max = GITHUB_TITLE_MAX) {
  const text = String(title ?? '');
  if (text.length <= max) return text;
  return `${text.slice(0, Math.max(0, max - 1))}…`;
}

function section(heading, paths, shown = paths.length) {
  if (paths.length === 0) return [`### ${heading} (0)`, '', '_none_', ''];
  const visible = paths.slice(0, shown);
  const hidden = paths.length - visible.length;
  return [
    `### ${heading} (${paths.length})`,
    '',
    ...visible.map((p) => `- \`${p}\``),
    ...(hidden > 0
      ? ['', `_…and ${hidden} more not listed. The pull request diff has every path._`]
      : []),
    '',
  ];
}

export function driftIssueTitle(drift, now = new Date()) {
  const total = drift.added.length + drift.changed.length + drift.deleted.length;
  const day = now.toISOString().slice(0, 10);
  const who = drift.actors?.modifiers?.length
    ? ` by ${drift.actors.modifiers.join(', ')}`
    : '';
  return fitGithubTitle(
    `Drift detected — ${total} item${total === 1 ? '' : 's'} changed in ISC${who} (${day})`,
  );
}

/** Line the decision callback reads to find the pull request for this issue. */
export function driftPullRequestUrl(body) {
  const match = String(body ?? '').match(/^Drift-PR: (\S+)\s*$/m);
  return match ? match[1] : null;
}

function actorLines(actors) {
  if (!actors) return [];
  if (actors.status === 'unavailable') {
    return [
      'Who changed it: **unknown** — the ISC audit search failed.',
      ...(actors.error ? ['', `> ${actors.error}`] : []),
      '',
      'The service identity needs the Search user level (`sp:search:read`).',
    ];
  }
  return [
    `Audit events since \`${actors.since}\`:`,
    '',
    ...(actors.lines?.length ? actors.lines : ['- no matching audit event']),
    ...(actors.status === 'partial'
      ? ['', '_Audit search stopped early, so some actors may be missing._']
      : []),
  ];
}

function largestKey(shown) {
  return ['added', 'changed', 'deleted'].reduce((best, key) => (
    shown[key] > shown[best] ? key : best
  ));
}

/**
 * Build the issue body, dropping paths and then audit lines until it fits
 * `maxLength`. The drift hash and the Drift-PR line always stay: the next
 * backup finds this issue by the hash, and the decision callback finds the
 * pull request by the Drift-PR line.
 */
export function driftIssueBody(drift, { prUrl = null, maxLength = GITHUB_BODY_MAX } = {}) {
  const added = drift.added ?? [];
  const changed = drift.changed ?? [];
  const deleted = drift.deleted ?? [];
  const lines = actorLines(drift.actors ?? null);
  const shown = {
    added: added.length,
    changed: changed.length,
    deleted: deleted.length,
  };
  let actorShown = lines.length;

  const resolution = prUrl
    ? [
      `Drift-PR: ${prUrl}`,
      '',
      'The pull request diff is the proposed resolution. Approving in ISC merges it.',
      'Rejecting closes it and puts ISC back to match git.',
      '',
    ]
    : [];

  const assemble = () => {
    const visibleActors = lines.slice(0, actorShown);
    const hiddenActors = lines.length - visibleActors.length;
    return [
      'ISC no longer matches the access model in git — items were changed outside the PR flow.',
      '',
      ...resolution,
      'An approval has been sent to the governance group in ISC. Approving copies',
      'these items from ISC into git; rejecting puts ISC back to match git.',
      '',
      '## Who changed it',
      '',
      ...visibleActors,
      ...(hiddenActors > 0 ? ['', `_…and ${hiddenActors} more audit lines not listed._`] : []),
      '',
      '## What changed',
      '',
      ...section('Added', added, shown.added),
      ...section('Changed', changed, shown.changed),
      ...section('Deleted', deleted, shown.deleted),
      '---',
      '',
      `Drift hash: \`${drift.driftHash}\``,
    ].join('\n');
  };

  let body = assemble();
  while (body.length > maxLength && (shown.added + shown.changed + shown.deleted) > 0) {
    const key = largestKey(shown);
    shown[key] = Math.max(0, shown[key] - Math.max(1, Math.ceil(shown[key] / 2)));
    body = assemble();
  }
  while (body.length > maxLength && actorShown > 0) {
    actorShown = Math.max(0, actorShown - Math.max(1, Math.ceil(actorShown / 2)));
    body = assemble();
  }
  if (body.length <= maxLength) return body;

  const tail = ['---', '', `Drift hash: \`${drift.driftHash}\``].join('\n');
  const note = '_Body truncated to fit GitHub’s limit. The drift hash below is complete._';
  const budget = maxLength - tail.length - note.length - 4;
  const head = budget > 0 ? body.slice(0, budget) : '';
  const fitted = `${head}\n\n${note}\n\n${tail}`;
  return fitted.length <= maxLength ? fitted : fitted.slice(0, maxLength);
}

export function renderDriftIssue(drift, now = new Date(), { prUrl = null, maxLength } = {}) {
  return {
    title: driftIssueTitle(drift, now),
    body: driftIssueBody(drift, { prUrl, maxLength }),
    label: DRIFT_ISSUE_LABEL,
    driftHash: drift.driftHash,
  };
}

/**
 * Comment posted when the governance decision lands, before the issue closes.
 */
export function driftDecisionComment({ decision, comment, runUrl, detail, decidedBy = null }) {
  const by = decidedBy ? ` by ${decidedBy}` : '';
  const headline = {
    approved: `Approved${by} — the drift was copied from ISC into \`main\`.`,
    rejected: `Rejected${by} — ISC was put back to match git.`,
    expired: 'Expired — nobody decided in time. ISC is unchanged and the next backup will ask again.',
    stale: 'Not applied — ISC changed again between the approval and this run, so nothing was synced.',
  }[decision] ?? `Decision: ${decision}${by}`;

  return [
    headline,
    ...(comment ? ['', `> ${comment}`] : []),
    ...(detail ? ['', detail] : []),
    ...(runUrl ? ['', `[Workflow run](${runUrl})`] : []),
  ].join('\n');
}
