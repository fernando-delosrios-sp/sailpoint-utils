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

  it('lists the full set rather than a preview when the body fits', () => {
    const changed = Array.from({ length: 300 }, (_, i) => `access/entitlements/s/e-${i}.json`);
    const issue = renderDriftIssue({ ...drift, changed });
    assert.ok(issue.body.includes('e-299.json'));
    assert.match(issue.body, /### Changed \(300\)/);
  });

  it('drops paths that would overflow GitHub’s body limit and keeps the drift hash', () => {
    const changed = Array.from({ length: 400 }, (_, i) => `access/entitlements/source/entitlement-${i}.json`);
    const issue = renderDriftIssue(
      { ...drift, changed, driftHash: 'abc123hash' },
      new Date('2026-10-17T07:52:00Z'),
      { maxLength: 2500, prUrl: 'https://github.com/example/repo/pull/9' },
    );
    assert.ok(issue.body.length <= 2500);
    assert.match(issue.body, /### Changed \(400\)/);
    assert.match(issue.body, /more not listed/);
    assert.match(issue.body, /entitlement-0\.json/);
    assert.doesNotMatch(issue.body, /entitlement-399\.json/);
    assert.ok(issue.body.includes('abc123hash'));
    assert.match(issue.body, /^Drift-PR: https:\/\/github.com\/example\/repo\/pull\/9$/m);
  });

  it('caps the title at GitHub’s 256-character limit', () => {
    const issue = renderDriftIssue({
      ...drift,
      actors: { ...drift.actors, modifiers: ['a'.repeat(400)] },
    });
    assert.ok(issue.title.length <= 256);
    assert.match(issue.title, /…$/);
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

  it('takes a baseline instead of a drift issue when the repository has none', () => {
    assert.match(yaml, /baseline-status/);
    assert.match(yaml, /Take the initial baseline/);
    assert.match(yaml, /ledger-init/);
    const beforeDrift = yaml.slice(0, yaml.indexOf('- name: Detect drift'));
    assert.match(beforeDrift, /steps\.baseline\.outputs\.initialized != 'true'/);
    const drift = yaml.slice(yaml.indexOf('- name: Detect drift'));
    assert.match(drift, /if: steps\.baseline\.outputs\.initialized == 'true'/);
  });

  it('opens a pull request for the drift diff and can push that branch', () => {
    assert.match(yaml, /contents: write/);
    assert.match(yaml, /pull-requests: write/);
    assert.match(yaml, /drift-pr/);
    assert.match(yaml, /drift-materialize/);
    assert.ok(yaml.indexOf('drift-issue') < yaml.indexOf('drift-pr'));
    assert.ok(yaml.indexOf('drift-pr') < yaml.indexOf('request-approval'));
  });
});

describe('change approval skips drift pull requests', () => {
  const yaml = readFileSync(new URL('../../.github/workflows/request-approval.yml', import.meta.url), 'utf8');

  it('does not send kind=change for a drift head', () => {
    assert.match(yaml, /!startsWith\(github\.head_ref, 'drift\/'\)/);
    assert.match(yaml, /Refuse change approval on a drift pull request/);
  });
});

describe('drift-decision report issues', () => {
  const yaml = readFileSync(
    new URL('../../.github/workflows/approval-callback.yml', import.meta.url),
    'utf8',
  );

  it('closes every final drift report immediately instead of leaving it for a human', () => {
    // Stale, expired, and a successful rejected-restore are final reports —
    // nothing further happens on them. A failed restore still needs someone
    // to look at a partly-restored ISC, so that one stays open.
    const rejectedStart = yaml.indexOf('Rejected — put ISC back to match git');
    const expiredStart = yaml.indexOf('Expired — record decision');
    const closeStart = yaml.indexOf('Close the drift issue this decision answers');
    assert.ok(rejectedStart > -1 && expiredStart > -1 && closeStart > -1);
    assert.match(
      yaml.slice(yaml.indexOf('Approved but stale'), rejectedStart),
      /gh issue close "\$STALE_URL"/,
    );
    assert.match(
      yaml.slice(rejectedStart, expiredStart),
      /gh issue close "\$ISSUE_URL" --reason completed/,
    );
    assert.match(
      yaml.slice(expiredStart, closeStart),
      /gh issue close "\$ISSUE_URL" --reason "not planned"/,
    );
  });

  it('merges the drift pull request on approval and closes it otherwise', () => {
    const approved = yaml.slice(
      yaml.indexOf('Approved and current'),
      yaml.indexOf('Approved but stale'),
    );
    assert.match(approved, /gh pr merge "\$PR_URL" --squash --delete-branch/);
    assert.match(approved, /chore\(backup\): sync drift from ISC/);
    const stale = yaml.slice(yaml.indexOf('Approved but stale'), yaml.indexOf('Rejected — put ISC back'));
    assert.match(stale, /gh pr close "\$PR_URL" --delete-branch/);
    const rejected = yaml.slice(yaml.indexOf('Rejected — put ISC back'), yaml.indexOf('Expired — record decision'));
    assert.match(rejected, /gh pr close "\$PR_URL" --delete-branch/);
    const expired = yaml.slice(yaml.indexOf('Expired — record decision'), yaml.indexOf('Close the drift issue'));
    assert.match(expired, /gh pr close "\$PR_URL" --delete-branch/);
  });

  it('renders the rejected-restore report as markdown, not a JSON-quoted string', () => {
    // jq -n without -r prints the JSON string literal (quotes and \n kept
    // escaped) instead of the markdown it holds.
    const section = yaml.slice(
      yaml.indexOf('Rejected — put ISC back to match git'),
      yaml.indexOf('Expired — record decision'),
    );
    assert.doesNotMatch(section, /\bjq -n --arg comment/);
    assert.match(section, /jq -rn --arg comment/g);
  });
});
