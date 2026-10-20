import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { driftContentHash, repoInitialized } from '../backup.mjs';

const path = 'access/roles/doctor-chief.json';

function itemAt(description) {
  return {
    relPath: path,
    data: { id: 'role-1', name: 'Doctor Chief', description },
    type: 'role',
  };
}

describe('repoInitialized', () => {
  it('is false only when both the access tree and the ledger are empty', () => {
    assert.equal(repoInitialized({ items: [], entries: [] }), false);
    assert.equal(repoInitialized({ items: [{ relPath: 'access/roles/a.json' }], entries: [] }), true);
    assert.equal(repoInitialized({ items: [], entries: [{ entry: { kind: 'init' } }] }), true);
  });
});

describe('driftContentHash', () => {
  it('changes when a drifted item is edited again, even though the file set is unchanged', () => {
    // Hashing only the drifted path list let the same item drift twice
    // between an approval request and its decision without moving the
    // hash — approve the first edit, edit it again before the decision
    // lands, and `changed` is still exactly [path] either way. The
    // decision callback's staleness guard only compares this hash, so a
    // stable hash here meant it would copy the second, unapproved edit
    // into git as if it were the first.
    const beforeByPath = new Map([[path, itemAt('original')]]);
    const liveV1 = new Map([[path, itemAt('v1')]]);
    const liveV2 = new Map([[path, itemAt('v2 — changed again after approval')]]);

    const hashV1 = driftContentHash({
      added: [], changed: [path], deleted: [], liveByPath: liveV1, beforeByPath,
    });
    const hashV2 = driftContentHash({
      added: [], changed: [path], deleted: [], liveByPath: liveV2, beforeByPath,
    });

    assert.notEqual(hashV1, hashV2);
  });

  it('is stable when nothing about the drift actually changed', () => {
    const beforeByPath = new Map([[path, itemAt('original')]]);
    const liveByPath = new Map([[path, itemAt('v1')]]);
    const a = driftContentHash({ added: [], changed: [path], deleted: [], liveByPath, beforeByPath });
    const b = driftContentHash({ added: [], changed: [path], deleted: [], liveByPath, beforeByPath });
    assert.equal(a, b);
  });

  it('does not depend on id, which the apply step rewrites on create', () => {
    // semanticBody already strips id for exactly this reason (plan.mjs);
    // this just confirms the drift hash inherits that, instead of hashing
    // the raw item.
    const beforeByPath = new Map();
    const liveA = new Map([[path, { relPath: path, data: { id: 'role-1', name: 'X' }, type: 'role' }]]);
    const liveB = new Map([[path, { relPath: path, data: { id: 'role-2', name: 'X' }, type: 'role' }]]);
    const a = driftContentHash({ added: [path], changed: [], deleted: [], liveByPath: liveA, beforeByPath });
    const b = driftContentHash({ added: [path], changed: [], deleted: [], liveByPath: liveB, beforeByPath });
    assert.equal(a, b);
  });
});
