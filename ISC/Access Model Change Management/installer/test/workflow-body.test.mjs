import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { toWorkflowWriteBody } from '../isc.mjs';

describe('toWorkflowWriteBody', () => {
  it('sends creator as owner and drops creator', () => {
    const body = toWorkflowWriteBody({
      name: 'AMCM Approval',
      creator: { type: 'IDENTITY', id: 'abc', name: 'svc' },
    }, { id: 'wf-1' });

    assert.deepEqual(body.owner, { type: 'IDENTITY', id: 'abc', name: 'svc' });
    assert.equal(body.creator, undefined);
    assert.equal(body.id, 'wf-1');
  });

  it('keeps an explicit owner', () => {
    const owner = { type: 'IDENTITY', id: 'keep' };
    const body = toWorkflowWriteBody({
      owner,
      creator: { type: 'IDENTITY', id: 'other' },
    });
    assert.deepEqual(body.owner, owner);
    assert.equal(body.creator, undefined);
    assert.equal(body.id, undefined);
  });
});
