import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildDriftApprovalPayload, eligibleOwners } from '../approval.mjs';
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

describe('eligibleOwners', () => {
  function clientOf(identities) {
    return {
      getIdentity: async (id) => {
        if (!(id in identities)) throw new Error(`no such identity: ${id}`);
        return identities[id];
      },
    };
  }

  it('drops a protected owner — e.g. ISC\'s built-in "SailPoint Services"', async () => {
    const owners = [{ type: 'IDENTITY', id: 'svc-1', name: 'SailPoint Services' }];
    const client = clientOf({ 'svc-1': { isProtected: true, identityStatus: 'UNREGISTERED' } });
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible, []);
    assert.equal(skipped.length, 1);
    assert.equal(skipped[0].name, 'SailPoint Services');
    assert.equal(skipped[0].reason, 'protected system identity');
  });

  it('drops an unregistered owner even if not flagged protected', async () => {
    const owners = [{ type: 'IDENTITY', id: 'u-1', name: 'Pending Hire' }];
    const client = clientOf({ 'u-1': { isProtected: false, identityStatus: 'UNREGISTERED' } });
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible, []);
    assert.equal(skipped[0].reason, 'unregistered identity');
  });

  it('keeps a normal, active owner', async () => {
    const owners = [{ type: 'IDENTITY', id: 'a-1', name: 'Mr Robot' }];
    const client = clientOf({ 'a-1': { isProtected: false, identityStatus: 'ACTIVE' } });
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible, owners);
    assert.deepEqual(skipped, []);
  });

  it('keeps a non-IDENTITY owner without looking it up', async () => {
    const owners = [{ type: 'GOVERNANCE_GROUP', id: 'g-1', name: 'EMEA TES Team' }];
    const client = { getIdentity: async () => { throw new Error('should not be called'); } };
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible, owners);
    assert.deepEqual(skipped, []);
  });

  it('keeps an owner when the identity lookup fails — unknown beats silently dropped', async () => {
    const owners = [{ type: 'IDENTITY', id: 'missing-1', name: 'Gone' }];
    const client = clientOf({});
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible, owners);
    assert.deepEqual(skipped, []);
  });

  it('filters a mixed list, preserving the eligible owners in order', async () => {
    const owners = [
      { type: 'IDENTITY', id: 'svc-1', name: 'SailPoint Services' },
      { type: 'IDENTITY', id: 'a-1', name: 'Mr Robot' },
      { type: 'IDENTITY', id: 'a-2', name: 'Jane Doe' },
    ];
    const client = clientOf({
      'svc-1': { isProtected: true, identityStatus: 'UNREGISTERED' },
      'a-1': { isProtected: false, identityStatus: 'ACTIVE' },
      'a-2': { isProtected: false, identityStatus: 'ACTIVE' },
    });
    const { eligible, skipped } = await eligibleOwners(owners, client);
    assert.deepEqual(eligible.map((o) => o.name), ['Mr Robot', 'Jane Doe']);
    assert.deepEqual(skipped.map((o) => o.name), ['SailPoint Services']);
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
