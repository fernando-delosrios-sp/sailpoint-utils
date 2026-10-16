import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { normalizeEntitlement, normalizeRole } from '../normalize.mjs';
import { slugify } from '../common.mjs';
import { isAppliedTag, buildAppliedTagName as tagName } from '../tags.mjs';

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
});

describe('slugify / tags', () => {
  it('slugifies names', () => {
    assert.equal(slugify('My Role (Prod)'), 'my-role-prod');
  });

  it('builds applied tags', () => {
    const name = tagName({ prNumber: 12, date: new Date('2026-10-16T10:15:30.000Z') });
    assert.ok(isAppliedTag(name));
    assert.match(name, /^isc-applied\/20261016T101530Z-pr-12$/);
  });
});
