import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  driftBranchName,
  driftContentHash,
  materializeDrift,
  renderDriftPullRequest,
} from '../drift-pr.mjs';
import { driftIssueBody, driftPullRequestUrl, renderDriftIssue } from '../drift-issue.mjs';

const drift = {
  added: [],
  changed: ['access/roles/hr-manager.json'],
  deleted: [],
  driftHash: 'abc123',
  actors: { status: 'ok', since: '2026-10-19T13:57:28.586Z', modifiers: ['fernando.delosrios'], lines: [] },
};

const snapshot = {
  entries: [
    { relPath: 'access/roles/hr-manager.json', data: { name: 'HR Manager', description: 'live' } },
  ],
};

describe('drift pull request', () => {
  it('names the branch from the drifted file contents', () => {
    const branch = driftBranchName(driftContentHash(drift, snapshot));
    assert.match(branch, /^drift\/[0-9a-f]{12}$/);

    const edited = {
      entries: [
        { relPath: 'access/roles/hr-manager.json', data: { name: 'HR Manager', description: 'edited again' } },
      ],
    };
    assert.notEqual(branch, driftBranchName(driftContentHash(drift, edited)));
  });

  it('changes the branch when a drifted path is deleted instead of edited', () => {
    const deleted = { ...drift, changed: [], deleted: ['access/roles/hr-manager.json'] };
    const editedBranch = driftBranchName(driftContentHash(drift, snapshot));
    const deletedBranch = driftBranchName(driftContentHash(deleted, { entries: [] }));
    assert.notEqual(editedBranch, deletedBranch);
  });

  it('is the resolution of the drift issue', () => {
    const pr = renderDriftPullRequest({ drift, issueNumber: 32, now: new Date('2026-10-20T06:48:00Z') });
    assert.match(pr.body, /^Fixes #32\n/);
    assert.match(pr.title, /Drift detected — 1 item changed in ISC by fernando\.delosrios/);
    assert.match(pr.body, /Do not merge this pull request yourself/);
  });

  it('writes the live bodies onto the branch and removes deleted files', () => {
    const root = mkdtempSync(join(tmpdir(), 'amcm-drift-'));
    mkdirSync(join(root, 'access/roles'), { recursive: true });
    const role = join(root, 'access/roles/hr-manager.json');
    const gone = join(root, 'access/roles/old.json');
    writeFileSync(role, '{"name":"HR Manager","description":"git"}\n');
    writeFileSync(gone, '{"name":"Old"}\n');

    const result = materializeDrift({
      drift: {
        added: ['access/roles/new.json'],
        changed: ['access/roles/hr-manager.json'],
        deleted: ['access/roles/old.json'],
      },
      snapshot: {
        entries: [
          { relPath: 'access/roles/hr-manager.json', data: { name: 'HR Manager', description: 'live' } },
          { relPath: 'access/roles/new.json', data: { name: 'New' } },
        ],
      },
      root,
    });

    assert.deepEqual(JSON.parse(readFileSync(role, 'utf8')), { name: 'HR Manager', description: 'live' });
    assert.equal(JSON.parse(readFileSync(join(root, 'access/roles/new.json'), 'utf8')).name, 'New');
    assert.equal(existsSync(gone), false);
    assert.deepEqual(result.written, ['access/roles/new.json', 'access/roles/hr-manager.json']);
    assert.deepEqual(result.removed, ['access/roles/old.json']);
  });
});

describe('drift issue pull request link', () => {
  it('records the pull request on its own line so the decision can find it', () => {
    const body = driftIssueBody(drift, { prUrl: 'https://github.com/acme/amcm/pull/33' });
    assert.equal(driftPullRequestUrl(body), 'https://github.com/acme/amcm/pull/33');
    assert.match(body, /Drift hash: `abc123`/);
  });

  it('leaves the marker off when there is no pull request yet', () => {
    const issue = renderDriftIssue(drift, new Date('2026-10-20T06:48:00Z'));
    assert.equal(driftPullRequestUrl(issue.body), null);
  });
});
