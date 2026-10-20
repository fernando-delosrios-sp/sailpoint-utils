/**
 * The pull request that shows a drift the way a normal change shows a diff.
 *
 * The branch holds the live ISC bodies for the drifted paths. The pull request
 * targets main and says `Fixes #<issue>`, so GitHub lists it as that issue's
 * resolution. Merging it is the drift decision, not a separate change approval.
 */
import { rmSync } from 'node:fs';
import { join } from 'node:path';
import { contentHash, writeJson } from './common.mjs';
import { GITHUB_BODY_MAX, driftIssueTitle } from './drift-issue.mjs';

export const DRIFT_BRANCH_PREFIX = 'drift/';

/**
 * Hash of the drifted bodies, not just their paths. Two edits of the same
 * files must not share a branch: the pull request diff has to be those bytes.
 */
export function driftContentHash(drift, snapshot) {
  const byPath = new Map((snapshot?.entries ?? []).map((entry) => [entry.relPath, entry.data]));
  const files = {};
  for (const relPath of [...drift.added, ...drift.changed]) {
    if (!byPath.has(relPath)) {
      throw new Error(`Snapshot has no body for drifted path ${relPath}`);
    }
    files[relPath] = byPath.get(relPath);
  }
  for (const relPath of drift.deleted) {
    files[relPath] = null;
  }
  return contentHash(files);
}

export function driftBranchName(hash) {
  return `${DRIFT_BRANCH_PREFIX}${hash.slice(0, 12)}`;
}

export function renderDriftPullRequest({ drift, issueNumber, now = new Date(), maxLength = GITHUB_BODY_MAX }) {
  const fixes = `Fixes #${issueNumber}`;
  let body = [
    fixes,
    '',
    'This pull request is the drift between `main` and live ISC.',
    'The diff is the proposed resolution: approving in Identity Security Cloud merges it and copies ISC into git.',
    'Rejecting closes it and puts ISC back to match git.',
    '',
    'Do not merge this pull request yourself. The ISC approval is the only merge.',
    '',
    `Drift hash: \`${drift.driftHash}\``,
  ].join('\n');
  if (body.length > maxLength) {
    const note = '_Body truncated to fit GitHub’s limit._';
    const budget = maxLength - fixes.length - note.length - 4;
    body = `${fixes}\n\n${budget > 0 ? body.slice(fixes.length, fixes.length + budget) : ''}\n\n${note}`;
    if (body.length > maxLength) body = body.slice(0, maxLength);
  }
  return {
    title: driftIssueTitle(drift, now),
    body,
  };
}

/**
 * Write the live bodies for this drift into a checkout of main.
 * Added and changed paths take the snapshot; deleted paths are removed.
 */
export function materializeDrift({ drift, snapshot, root }) {
  const byPath = new Map((snapshot?.entries ?? []).map((entry) => [entry.relPath, entry.data]));
  const written = [];
  for (const relPath of [...drift.added, ...drift.changed]) {
    if (!byPath.has(relPath)) {
      throw new Error(`Snapshot has no body for drifted path ${relPath}`);
    }
    writeJson(join(root, relPath), byPath.get(relPath));
    written.push(relPath);
  }
  const removed = [];
  for (const relPath of drift.deleted) {
    rmSync(join(root, relPath), { force: true });
    removed.push(relPath);
  }
  return { written, removed };
}
