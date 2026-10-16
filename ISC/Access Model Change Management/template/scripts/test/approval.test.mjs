import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildDriftApprovalPayload } from '../approval.mjs';
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
    // Drift must never carry an owners list — the ISC workflow has no owner
    // loop on this branch, but a stray `owners` field would be a sign some
    // other code path is conflating drift with a change approval.
    assert.equal(payload.owners, undefined);
    assert.match(payload.approvalText, /governance group only|Approving syncs/);
  });

  it('caps the approval text preview instead of inlining thousands of paths', () => {
    const added = Array.from({ length: 50 }, (_, i) => `access/roles/role-${i}.json`);
    const drift = { added, changed: [], deleted: [], driftHash: contentHash({ added, changed: [], deleted: [] }) };
    const payload = buildDriftApprovalPayload({ drift, config });

    assert.match(payload.approvalText, /and 30 more/);
    assert.ok(!payload.approvalText.includes('role-49'));
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
