import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { indexEntitlementsByName, resolveReferences } from '../apply.mjs';
import { ITEM_TYPES } from '../common.mjs';

function entitlement(id, name, sourceSlug, value) {
  return {
    type: ITEM_TYPES.entitlement,
    name,
    id,
    sourceSlug,
    relPath: `access/entitlements/${sourceSlug}/${id}.json`,
    data: { id, name, _readonly: { value } },
  };
}

const items = [
  entitlement('e-1', 'Reader', 'aws-nhi', 'arn:reader'),
  entitlement('e-2', 'Writer', 'aws-nhi', 'arn:writer'),
  entitlement('e-3', 'Reader', 'azure', 'azure:reader'),
];

describe('resolveReferences', () => {
  it('resolves an entitlement name to its ISC id', () => {
    const resolved = resolveReferences(
      { entitlements: [{ name: 'Writer' }] },
      ITEM_TYPES.accessProfile,
      new Map(),
      indexEntitlementsByName(items),
    );
    assert.deepEqual(resolved.entitlements, [{ id: 'e-2', type: 'ENTITLEMENT' }]);
  });

  it('keeps an id that is already present instead of looking it up', () => {
    const resolved = resolveReferences(
      { entitlements: [{ id: 'e-9', name: 'Unknown' }] },
      ITEM_TYPES.accessProfile,
      new Map(),
      indexEntitlementsByName(items),
    );
    assert.deepEqual(resolved.entitlements, [{ id: 'e-9', type: 'ENTITLEMENT' }]);
  });

  it('refuses to guess when a name matches entitlements in several sources', () => {
    assert.throws(
      () => resolveReferences(
        { entitlements: [{ name: 'Reader' }] },
        ITEM_TYPES.accessProfile,
        new Map(),
        indexEntitlementsByName(items),
      ),
      /ambiguous \(2 match in aws-nhi, azure\)/,
    );
  });

  it('reports a name that matches nothing', () => {
    assert.throws(
      () => resolveReferences(
        { entitlements: [{ name: 'Ghost' }] },
        ITEM_TYPES.accessProfile,
        new Map(),
        indexEntitlementsByName(items),
      ),
      /Cannot resolve entitlement "Ghost"/,
    );
  });
});
