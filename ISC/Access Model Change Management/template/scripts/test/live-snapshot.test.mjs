import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { fromSnapshotFile, snapshotLive, toSnapshotFile } from '../live-snapshot.mjs';
import { mapLimit, Semaphore } from '../concurrency.mjs';

const config = { entitlementSources: [{ id: 'src-1', name: 'AWS EMEA' }] };

function fakeClient(entitlements, { accessProfiles = [], roles = [] } = {}) {
  return {
    async listEntitlements() { return entitlements; },
    async listAccessProfiles() { return accessProfiles; },
    async listRoles() { return roles; },
  };
}

describe('snapshotLive', () => {
  it('keeps a bare file name when an entitlement name is unique', async () => {
    const client = fakeClient([{ id: 'e1', name: 'Reader', value: 'arn:reader' }]);
    const { entries } = await snapshotLive({ client, config });
    assert.equal(entries[0].relPath, 'access/entitlements/aws-emea/reader.json');
  });

  it('backs up every entitlement when a name repeats inside one source', async () => {
    const client = fakeClient([
      { id: 'e1', name: 'LambdaIAMPolicy', value: 'arn:policy/one' },
      { id: 'e2', name: 'LambdaIAMPolicy', value: 'arn:policy/two' },
      { id: 'e3', name: 'LambdaIAMPolicy', value: 'arn:policy/three' },
    ]);
    const { entries, counts } = await snapshotLive({ client, config });
    assert.equal(counts.entitlements, 3);
    assert.equal(new Set(entries.map((e) => e.relPath)).size, 3);
    for (const e of entries) {
      assert.match(e.relPath, /^access\/entitlements\/aws-emea\/lambdaiampolicy__arn-policy-/);
    }
  });

  it('falls back to the id when a repeated name has no native value', async () => {
    const client = fakeClient([
      { id: 'e1', name: 'Dup', value: null },
      { id: 'e2', name: 'Dup', value: null },
    ]);
    const { entries } = await snapshotLive({ client, config });
    assert.deepEqual(entries.map((e) => e.relPath).sort(), [
      'access/entitlements/aws-emea/dup__e1.json',
      'access/entitlements/aws-emea/dup__e2.json',
    ]);
  });

  it('keeps long values apart even when they share a long prefix', async () => {
    // AWS ARNs differ at the tail, and slugify truncates at the front, so a
    // plain slug would map both of these to the same file.
    const prefix = `arn:aws:iam::123456789012:policy/${'segment/'.repeat(20)}`;
    const client = fakeClient([
      { id: 'e1', name: 'Policy', value: `${prefix}one` },
      { id: 'e2', name: 'Policy', value: `${prefix}two` },
    ]);
    const { entries } = await snapshotLive({ client, config });
    const names = entries.map((e) => e.relPath);
    assert.equal(new Set(names).size, 2);
    for (const name of names) {
      assert.ok(name.split('/').pop().length <= 128, `file name too long: ${name}`);
    }
  });

  it('leaves same-named entitlements in different sources unsuffixed', async () => {
    const client = {
      async listEntitlements(filter) {
        const id = filter.includes('src-1') ? 'e1' : 'e2';
        return [{ id, name: 'Reader', value: 'arn:reader' }];
      },
      async listAccessProfiles() { return []; },
      async listRoles() { return []; },
    };
    const { entries } = await snapshotLive({
      client,
      config: {
        entitlementSources: [
          { id: 'src-1', name: 'AWS EMEA' },
          { id: 'src-2', name: 'Azure EMEA' },
        ],
      },
    });
    assert.deepEqual(entries.map((e) => e.relPath).sort(), [
      'access/entitlements/aws-emea/reader.json',
      'access/entitlements/azure-emea/reader.json',
    ]);
  });
});

describe('snapshot file round trip', () => {
  it('restores the entries another process can write', async () => {
    const client = fakeClient([{ id: 'e1', name: 'Reader', value: 'arn:reader' }], {
      roles: [{ id: 'r1', name: 'Analyst' }],
    });
    const snapshot = await snapshotLive({ client, config });
    const restored = fromSnapshotFile(JSON.parse(JSON.stringify(toSnapshotFile(snapshot))));
    assert.deepEqual(restored.counts, snapshot.counts);
    assert.deepEqual(
      restored.entries.map((e) => [e.relPath, e.name, e.id, e.sourceSlug]),
      snapshot.entries.map((e) => [e.relPath, e.name, e.id, e.sourceSlug]),
    );
  });

  it('rejects a snapshot it does not understand', () => {
    assert.throws(() => fromSnapshotFile({ version: 99 }), /Unrecognized snapshot/);
  });
});

describe('mapLimit', () => {
  it('returns results in input order and never exceeds the limit', async () => {
    let inFlight = 0;
    let peak = 0;
    const results = await mapLimit([1, 2, 3, 4, 5, 6, 7], 3, async (n) => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, n % 3));
      inFlight -= 1;
      return n * 2;
    });
    assert.deepEqual(results, [2, 4, 6, 8, 10, 12, 14]);
    assert.ok(peak <= 3, `peak concurrency was ${peak}`);
  });
});

describe('Semaphore', () => {
  it('caps concurrent holders', async () => {
    const gate = new Semaphore(2);
    let inFlight = 0;
    let peak = 0;
    await Promise.all([...Array(6)].map(async () => {
      await gate.acquire();
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, 1));
      inFlight -= 1;
      gate.release();
    }));
    assert.equal(peak, 2);
  });
});
