import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { normalizeAccessProfile, normalizeEntitlement, normalizeRole } from '../normalize.mjs';
import { slugify } from '../common.mjs';
import { isKnownGoodTag, buildKnownGoodTagName as tagName } from '../tags.mjs';

describe('normalize', () => {
  it('keeps only patchable entitlement metadata', () => {
    const n = normalizeEntitlement({
      id: 'e1',
      name: 'CN=Admins',
      description: 'd',
      privileged: true,
      requestable: false,
      owner: { type: 'IDENTITY', id: 'o', name: 'O' },
      source: { id: 's', name: 'AD' },
      created: '2020-01-01',
      value: 'CN=Admins',
      attribute: 'memberOf',
    }, { sourceSlug: 'ad' });
    assert.equal(n.id, 'e1');
    assert.equal(n.sourceSlug, 'ad');
    assert.equal(n._readonly.value, 'CN=Admins');
    assert.equal(n.created, undefined);
  });

  it('resolves role access profile names from id map', () => {
    const n = normalizeRole({
      id: 'r1',
      name: 'R',
      owner: { type: 'IDENTITY', id: 'o', name: 'O' },
      accessProfiles: [{ id: 'ap1' }],
      entitlements: [],
    }, { accessProfileNameById: new Map([['ap1', 'AP One']]) });
    assert.equal(n.accessProfiles[0].name, 'AP One');
  });

  it('sorts a role dimensionRefs/accessProfiles/entitlements regardless of API order', () => {
    const base = {
      id: 'r1',
      name: 'R',
      owner: { type: 'IDENTITY', id: 'o', name: 'O' },
      accessProfiles: [{ id: 'ap2' }, { id: 'ap1' }],
      entitlements: [{ id: 'e2' }, { id: 'e1' }],
      dimensionRefs: [
        { id: 'd2', name: 'Taipei', type: 'DIMENSION' },
        { id: 'd1', name: 'Munich', type: 'DIMENSION' },
      ],
    };
    const shuffled = {
      ...base,
      accessProfiles: [...base.accessProfiles].reverse(),
      entitlements: [...base.entitlements].reverse(),
      dimensionRefs: [...base.dimensionRefs].reverse(),
    };
    // ISC can return the same membership set in a different array order
    // between calls even when nothing was edited; normalization must produce
    // byte-identical JSON either way so drift detection doesn't false-positive.
    assert.deepEqual(normalizeRole(base), normalizeRole(shuffled));
  });

  it('sorts access profile entitlements regardless of API order', () => {
    const base = {
      id: 'ap1',
      name: 'AP',
      owner: { type: 'IDENTITY', id: 'o', name: 'O' },
      entitlements: [{ id: 'e2' }, { id: 'e1' }],
    };
    const shuffled = { ...base, entitlements: [...base.entitlements].reverse() };
    assert.deepEqual(normalizeAccessProfile(base), normalizeAccessProfile(shuffled));
  });
});

describe('slugify / tags', () => {
  it('slugifies names', () => {
    assert.equal(slugify('My Role (Prod)'), 'my-role-prod');
  });

  it('builds known-good tags', () => {
    const name = tagName({ prNumber: 12, date: new Date('2026-10-16T10:15:30.000Z') });
    assert.ok(isKnownGoodTag(name));
    assert.match(name, /^known-good\/20261016T101530Z-pr-12$/);
    assert.equal(isKnownGoodTag('isc-applied/20261016T101530Z-pr-12'), true);
    assert.equal(isKnownGoodTag('main'), false);
  });
});
