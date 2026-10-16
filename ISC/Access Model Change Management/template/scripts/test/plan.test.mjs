import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { buildPlan, semanticBody } from '../plan.mjs';
import { hashTouchedFiles } from '../diff-hash.mjs';
import { ITEM_TYPES, indexByName } from '../common.mjs';
import { validateRepo } from '../validate.mjs';
import { mkdtempSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

function item(type, data, relPath) {
  return {
    type,
    path: relPath,
    relPath,
    data,
    name: data.name,
    id: data.id ?? null,
    sourceSlug: null,
  };
}

describe('buildPlan', () => {
  it('orders creates before deletes and respects dependency types', () => {
    const base = [
      item(ITEM_TYPES.role, {
        id: 'r1',
        name: 'Old Role',
        owner: { type: 'IDENTITY', id: 'o1', name: 'Owner' },
        accessProfiles: [],
        entitlements: [],
      }, 'access/roles/old-role.json'),
    ];
    const head = [
      item(ITEM_TYPES.accessProfile, {
        id: null,
        name: 'New AP',
        owner: { type: 'IDENTITY', id: 'o1', name: 'Owner' },
        source: { id: 's1', name: 'AD' },
        entitlements: [],
      }, 'access/access-profiles/new-ap.json'),
      item(ITEM_TYPES.role, {
        id: null,
        name: 'New Role',
        owner: { type: 'IDENTITY', id: 'o1', name: 'Owner' },
        accessProfiles: [{ name: 'New AP' }],
        entitlements: [],
      }, 'access/roles/new-role.json'),
    ];

    const plan = buildPlan({ baseItems: base, headItems: head });
    const ops = plan.operations.filter((o) => o.op !== 'skip').map((o) => `${o.op}:${o.type}:${o.name}`);
    assert.deepEqual(ops, [
      'create:accessProfile:New AP',
      'create:role:New Role',
      'delete:role:Old Role',
    ]);
    assert.equal(plan.summary.create, 2);
    assert.equal(plan.summary.delete, 1);
    assert.ok(plan.planHash);
  });

  it('skips entitlement creates and deletes', () => {
    const head = [
      item(ITEM_TYPES.entitlement, {
        id: null,
        name: 'E1',
        source: { id: 's1', name: 'AD' },
        privileged: false,
        requestable: true,
      }, 'access/entitlements/ad/e1.json'),
    ];
    const plan = buildPlan({ baseItems: [], headItems: head });
    assert.equal(plan.operations[0].op, 'skip');
  });

  it('allows two entitlements with the same name inside one source', () => {
    // Regression for the restore crash: ISC lets one source expose several
    // entitlements named "LambdaIAMPolicy" (AWS policy entitlements do this
    // routinely). Keying identity by name alone made indexByName throw
    // 'Duplicate entitlement named "LambdaIAMPolicy"' and abort the restore,
    // and made the backup silently drop all but one of them.
    const ents = ['arn:policy/one', 'arn:policy/two', 'arn:policy/three'].map((value, i) => {
      const e = item(ITEM_TYPES.entitlement, {
        id: `e-${i}`,
        name: 'LambdaIAMPolicy',
        source: { id: 's-a', name: 'AWS NHI' },
        privileged: false,
        requestable: true,
        _readonly: { value },
      }, `access/entitlements/aws-nhi/lambdaiampolicy__${i}.json`);
      e.sourceSlug = 'aws-nhi';
      return e;
    });

    assert.doesNotThrow(() => indexByName(ents));
    assert.equal(buildPlan({ baseItems: ents, headItems: ents }).summary.update, 0);
  });

  it('reads an entitlement rename as an update, not a create plus delete', () => {
    const base = item(ITEM_TYPES.entitlement, {
      id: 'e-1',
      name: 'Old Name',
      source: { id: 's-a', name: 'AWS NHI' },
      privileged: false,
      requestable: true,
      _readonly: { value: 'arn:policy/one' },
    }, 'access/entitlements/aws-nhi/old-name.json');
    base.sourceSlug = 'aws-nhi';

    const head = structuredClone(base);
    head.data.name = 'New Name';
    head.name = 'New Name';
    head.relPath = 'access/entitlements/aws-nhi/new-name.json';

    const plan = buildPlan({ baseItems: [base], headItems: [head] });
    assert.equal(plan.summary.update, 1);
    assert.equal(plan.summary.skip, 0);
  });

  it('still reports two entitlements that share a source and a value', () => {
    const dup = () => {
      const e = item(ITEM_TYPES.entitlement, {
        id: 'e-1',
        name: 'Same',
        source: { id: 's-a', name: 'AWS NHI' },
        _readonly: { value: 'arn:same' },
      }, 'access/entitlements/aws-nhi/same.json');
      e.sourceSlug = 'aws-nhi';
      return e;
    };
    assert.throws(() => indexByName([dup(), dup()]), /Duplicate entitlement named "Same"/);
  });

  it('allows two entitlements with the same name from different sources', () => {
    // Regression: two connectors (e.g. two Google Workspace sources) can both
    // expose an entitlement named "_DIRECTORY_SYNC_ADMIN_ROLE". Prior to
    // scoping entitlement identity by source, indexByName threw
    // 'Duplicate entitlement named ...' and crashed buildPlan/validateRepo.
    const entA = item(ITEM_TYPES.entitlement, {
      id: 'e-a',
      name: 'Directory Sync Admin Role',
      source: { id: 's-a', name: 'Google Workspace (NHI)' },
      privileged: false,
      requestable: true,
    }, 'access/entitlements/google-nhi/dir-sync.json');
    entA.sourceSlug = 'google-nhi';

    const entB = item(ITEM_TYPES.entitlement, {
      id: 'e-b',
      name: 'Directory Sync Admin Role',
      source: { id: 's-b', name: 'Google Workspace (Users)' },
      privileged: false,
      requestable: true,
    }, 'access/entitlements/google-users/dir-sync.json');
    entB.sourceSlug = 'google-users';

    assert.doesNotThrow(() => indexByName([entA, entB]));

    const plan = buildPlan({ baseItems: [entA, entB], headItems: [entA, entB] });
    assert.equal(plan.summary.update, 0);

    const result = validateRepo({
      config: { entitlementSources: [] },
      items: [entA, entB],
    });
    assert.equal(result.ok, true);
  });
});

describe('diff-hash', () => {
  it('is stable for equivalent semantic content', () => {
    const dir = mkdtempSync(join(tmpdir(), 'amcm-'));
    mkdirSync(join(dir, 'access', 'roles'), { recursive: true });
    const rel = 'access/roles/r.json';
    const body = {
      id: 'x',
      name: 'R',
      owner: { type: 'IDENTITY', id: 'o', name: 'O' },
      accessProfiles: [{ id: '1', name: 'AP' }],
      entitlements: [],
    };
    writeFileSync(join(dir, rel), JSON.stringify(body));
    const h1 = hashTouchedFiles([rel], { root: dir });
    body.id = 'y';
    body.accessProfiles[0].id = '2';
    writeFileSync(join(dir, rel), JSON.stringify(body));
    const h2 = hashTouchedFiles([rel], { root: dir });
    assert.equal(h1, h2);
  });
});

describe('semanticBody', () => {
  it('strips nested ids from membership', () => {
    const body = semanticBody({
      id: '1',
      name: 'AP',
      entitlements: [{ id: 'e1', name: 'E', type: 'ENTITLEMENT' }],
    }, ITEM_TYPES.accessProfile);
    assert.equal(body.id, undefined);
    assert.deepEqual(body.entitlements, [{ name: 'E', type: 'ENTITLEMENT' }]);
  });
});
