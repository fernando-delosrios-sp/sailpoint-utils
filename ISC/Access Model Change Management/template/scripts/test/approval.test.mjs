import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildChangeApprovalPayload, buildDriftApprovalPayload, buildRestoreApprovalPayload } from '../approval.mjs';
import { contentHash } from '../common.mjs';

const config = {
  approval: { governanceGroupId: 'gov-1' },
  github: { owner: 'acme', repo: 'amcm' },
};

describe('buildDriftApprovalPayload', () => {
  it('routes drift to the governance group only — no owners field at all', () => {
    const drift = {
      added: ['access/roles/new-role.json'],
      changed: [],
      deleted: [],
      driftHash: contentHash({ added: ['access/roles/new-role.json'], changed: [], deleted: [] }),
    };
    const payload = buildDriftApprovalPayload({ drift, config });

    assert.equal(payload.kind, 'drift');
    assert.equal(payload.governanceGroupId, 'gov-1');
    assert.equal(payload.driftHash, drift.driftHash);
    assert.equal(payload.owners, undefined);
    assert.match(payload.approvalText, /Approving copies these items from ISC into git/);
    assert.match(payload.approvalText, /Rejecting puts ISC back to match git/);
  });

  it('caps the approval text preview instead of inlining thousands of paths', () => {
    const added = Array.from({ length: 50 }, (_, i) => `access/roles/role-${i}.json`);
    const drift = { added, changed: [], deleted: [], driftHash: contentHash({ added, changed: [], deleted: [] }) };
    const payload = buildDriftApprovalPayload({ drift, config });

    assert.match(payload.approvalText, /and 30 more/);
    assert.ok(!payload.approvalText.includes('role-49'));
  });

  it('shows the changed role even when thousands of entitlements sort ahead of it', () => {
    // The preview is capped at 20 lines and paths sort alphabetically, so
    // `access/entitlements/...` used to fill it completely and the one role
    // somebody actually edited never appeared in the approval.
    const changed = [
      ...Array.from({ length: 2085 }, (_, i) => `access/entitlements/entra/e-${i}.json`),
      'access/roles/business-process-users.json',
    ].sort();
    const drift = { added: [], changed, deleted: [], driftHash: 'irrelevant' };
    const payload = buildDriftApprovalPayload({ drift, config });

    assert.match(payload.approvalText, /- access\/roles\/business-process-users\.json/);
    assert.match(payload.approvalText, /and 2066 more/);
  });

  it('points the approver at the issue holding the full detail', () => {
    const drift = { added: [], changed: ['a.json'], deleted: [], driftHash: 'h' };
    const payload = buildDriftApprovalPayload({
      drift,
      issueUrl: 'https://github.com/acme/amcm/issues/12',
      config,
    });
    assert.match(payload.approvalText, /Full detail: https:\/\/github.com\/acme\/amcm\/issues\/12/);
    assert.equal(payload.issueUrl, 'https://github.com/acme/amcm/issues/12');
  });

  it('does not inline the full path lists in the trigger payload', () => {
    const drift = {
      added: ['a.json'],
      changed: ['b.json'],
      deleted: ['c.json'],
      driftHash: 'irrelevant',
    };
    const payload = buildDriftApprovalPayload({ drift, config });
    assert.equal(payload.added, undefined);
    assert.equal(payload.changed, undefined);
    assert.equal(payload.deleted, undefined);
    assert.deepEqual(payload.summary, { added: 1, changed: 1, deleted: 1 });
  });

  it('names the audit actor in the approval text and keeps the actor list out of the trigger payload', () => {
    const actors = {
      status: 'ok',
      since: '2026-10-01T00:00:00.000Z',
      modifiers: ['Jane Doe'],
      lines: ['- Jane Doe — access/roles/analyst.json (ROLE_UPDATE_PASSED, 2026-10-15T09:00:00.000Z)'],
    };
    const drift = {
      added: [],
      changed: ['access/roles/analyst.json'],
      deleted: [],
      driftHash: 'irrelevant',
      actors,
    };
    const payload = buildDriftApprovalPayload({ drift, config });
    assert.equal(payload.actors, undefined);
    assert.match(payload.approvalText, /Jane Doe — access\/roles\/analyst.json/);
    assert.match(payload.approvalText, /since 2026-10-01T00:00:00.000Z/);
  });
});

describe('buildChangeApprovalPayload', () => {
  it('asks the governance group and does not carry an owners list', () => {
    const payload = buildChangeApprovalPayload({
      plan: {
        summary: '1 update',
        operations: [
          { op: 'update', type: 'role', name: 'Analyst', owner: { type: 'IDENTITY', id: 'a-1', name: 'Mr Robot' } },
          { op: 'skip', type: 'role', name: 'Untouched' },
        ],
      },
      diffHash: 'abc',
      pr: { number: 12, title: 'Rename analyst', url: 'https://github.com/acme/amcm/pull/12', author: 'octocat' },
      config,
    });
    assert.equal(payload.kind, 'change');
    assert.equal(payload.governanceGroupId, 'gov-1');
    assert.equal(payload.owners, undefined);
    assert.deepEqual(payload.items, [{ op: 'update', type: 'role', name: 'Analyst' }]);
    assert.match(payload.approvalText, /Pull request #12: Rename analyst/);
  });
});

describe('buildRestoreApprovalPayload', () => {
  it('renders plan.summary as readable counts, not a stringified object', () => {
    // plan.summary is { create, update, delete, skip } counts, not text.
    // String-concatenating it directly rendered as the literal text
    // "[object Object]" in every restore approval governance saw.
    const payload = buildRestoreApprovalPayload({
      plan: {
        summary: { create: 1, update: 2, delete: 0, skip: 3 },
        operations: [
          { op: 'update', type: 'role', name: 'Analyst' },
          { op: 'skip', type: 'role', name: 'Untouched' },
        ],
      },
      planHash: 'hash-1',
      sourceRef: 'main',
      requester: 'octocat',
      config,
    });
    assert.doesNotMatch(payload.approvalText, /\[object Object\]/);
    assert.match(payload.approvalText, /1 create, 2 update, 0 delete, 3 skip/);
    assert.match(payload.approvalText, /Full restore of the access model from main/);
  });
});

describe('drift hash stability', () => {
  it('is identical regardless of input array order (ISC list order is not guaranteed)', () => {
    const a = contentHash({ added: ['x.json', 'y.json'].sort(), changed: [], deleted: [] });
    const b = contentHash({ added: ['y.json', 'x.json'].sort(), changed: [], deleted: [] });
    assert.equal(a, b);
  });

  it('changes when the drift set actually changes', () => {
    const a = contentHash({ added: ['x.json'], changed: [], deleted: [] });
    const b = contentHash({ added: ['x.json', 'y.json'], changed: [], deleted: [] });
    assert.notEqual(a, b);
  });
});
