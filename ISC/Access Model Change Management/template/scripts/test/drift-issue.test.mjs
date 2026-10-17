import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { driftDecisionComment, renderDriftIssue } from '../drift-issue.mjs';

const drift = {
  added: [],
  changed: ['access/roles/business-process-users.json'],
  deleted: [],
  driftHash: 'd732829eb5056cc7e288523f02584bb1e6d23b3cbbbea5e0e9029fe70968774a',
  actors: {
    status: 'ok',
    since: '2026-10-17T07:36:29.998Z',
    modifiers: ['fernando.delosrios'],
    lines: ['- fernando.delosrios — access/roles/business-process-users.json (ROLE_UPDATE_PASSED, 2026-10-17T07:51:59.229Z)'],
  },
};

describe('renderDriftIssue', () => {
  it('names the actor in the title and lists every path in the body', () => {
    const issue = renderDriftIssue(drift, new Date('2026-10-17T07:52:00Z'));
    assert.equal(
      issue.title,
      'Drift detected — 1 item changed in ISC by fernando.delosrios (2026-10-17)',
    );
    assert.match(issue.body, /- `access\/roles\/business-process-users\.json`/);
    assert.match(issue.body, /fernando\.delosrios/);
  });

  it('carries the drift hash so the decision can find this issue again', () => {
    const issue = renderDriftIssue(drift);
    assert.equal(issue.driftHash, drift.driftHash);
    assert.ok(issue.body.includes(drift.driftHash));
  });

  it('lists the full set rather than a preview', () => {
    const changed = Array.from({ length: 300 }, (_, i) => `access/entitlements/s/e-${i}.json`);
    const issue = renderDriftIssue({ ...drift, changed });
    assert.ok(issue.body.includes('e-299.json'));
    assert.match(issue.body, /### Changed \(300\)/);
  });

  it('says plainly when the audit search could not answer', () => {
    const issue = renderDriftIssue({
      ...drift,
      actors: { status: 'unavailable', modifiers: [], lines: [], error: 'POST /search/v1 failed: 403' },
    });
    assert.match(issue.body, /unknown/);
    assert.match(issue.body, /403/);
    assert.match(issue.body, /sp:search:read/);
    // No actor, so the title must not claim one.
    assert.doesNotMatch(issue.title, / by /);
  });
});

describe('driftDecisionComment', () => {
  it('explains each outcome and links the run', () => {
    const approved = driftDecisionComment({ decision: 'approved', runUrl: 'https://r/1' });
    assert.match(approved, /copied from ISC into `main`/);
    assert.match(approved, /https:\/\/r\/1/);
    assert.match(driftDecisionComment({ decision: 'rejected' }), /put back to match git/);
    assert.match(driftDecisionComment({ decision: 'expired' }), /nobody decided in time/i);
    assert.match(driftDecisionComment({ decision: 'stale' }), /changed again/);
  });

  it('quotes the approver comment when there is one', () => {
    const text = driftDecisionComment({ decision: 'rejected', comment: 'not sanctioned' });
    assert.match(text, /> not sanctioned/);
  });
});

describe('backup workflow contract', () => {
  const yaml = readFileSync(new URL('../../.github/workflows/backup.yml', import.meta.url), 'utf8');

  it('opens the issue before requesting the approval that links to it', () => {
    assert.ok(yaml.indexOf('drift-issue') < yaml.indexOf('request-approval'));
    assert.match(yaml, /--issue-url "\$ISSUE_URL"/);
  });

  it('can write issues', () => {
    assert.match(yaml, /issues: write/);
  });

  it('reuses an open issue instead of filing one per run', () => {
    assert.match(yaml, /gh issue list --state open --label amcm-drift/);
  });
});
