import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  ACTOR_LOOKBACK_MS,
  accessItemQueries,
  actorApprovalLines,
  attributeActors,
  attributeDriftActors,
  alignmentTimestamp,
  driftWindowStart,
} from '../drift-actors.mjs';

const role = {
  path: 'access/roles/analyst.json',
  id: 'role-1',
  name: 'Analyst',
  type: 'role',
};

describe('alignmentTimestamp', () => {
  it('uses the latest moment git and ISC were aligned', () => {
    const ts = alignmentTimestamp([
      { entry: { kind: 'init', timestamp: '2026-10-01T00:00:00.000Z' } },
      { entry: { kind: 'change', timestamp: '2026-10-10T00:00:00.000Z' } },
      { entry: { kind: 'drift', decision: 'expired', timestamp: '2026-10-12T00:00:00.000Z' } },
      { entry: { kind: 'drift', decision: 'rejected', restored: false, timestamp: '2026-10-13T00:00:00.000Z' } },
      { entry: { kind: 'drift', decision: 'approved', timestamp: '2026-10-11T00:00:00.000Z' } },
    ]);
    assert.equal(ts, '2026-10-11T00:00:00.000Z');
  });

  it('treats a rejected drift that was restored as alignment', () => {
    const ts = alignmentTimestamp([
      { kind: 'drift', decision: 'rejected', restored: true, timestamp: '2026-10-14T00:00:00.000Z' },
    ]);
    assert.equal(ts, '2026-10-14T00:00:00.000Z');
  });

  it('falls back to 14 days when nothing has aligned', () => {
    const now = new Date('2026-10-16T00:00:00.000Z');
    const start = driftWindowStart({ entries: [], now });
    assert.equal(Date.parse(start), now.getTime() - ACTOR_LOOKBACK_MS);
  });
});

describe('attributeActors', () => {
  it('matches the actor on target id and ignores a failed event', () => {
    const result = attributeActors({
      subjects: [role],
      events: [
        {
          created: '2026-10-15T08:00:00.000Z',
          technicalName: 'ROLE_UPDATE_FAILED',
          status: 'FAILED',
          actor: { displayName: 'Nobody' },
          target: { id: 'role-1', name: 'Analyst', type: 'ROLE' },
        },
        {
          created: '2026-10-15T09:00:00.000Z',
          technicalName: 'ROLE_UPDATE_PASSED',
          actor: { displayName: 'Jane Doe', name: 'jane.doe', id: 'id-jane' },
          target: { id: 'role-1', name: 'Analyst', type: 'ROLE' },
        },
        {
          created: '2026-10-15T10:00:00.000Z',
          technicalName: 'ROLE_UPDATE_PASSED',
          actor: { displayName: 'Bob Smith' },
          target: { id: 'role-1', type: 'ROLE' },
        },
      ],
    });
    assert.deepEqual(result.modifiers, ['Bob Smith', 'Jane Doe']);
    assert.match(result.lines[0], /Bob Smith, Jane Doe — access\/roles\/analyst.json \(ROLE_UPDATE_PASSED, 2026-10-15T10:00:00.000Z\)/);
  });

  it('falls back to name and type when the event has no target id', () => {
    const result = attributeActors({
      subjects: [{
        path: 'access/entitlements/ad/admins.json',
        id: null,
        name: 'Admins',
        type: 'entitlement',
      }],
      events: [{
        created: '2026-10-15T09:00:00.000Z',
        name: 'Update Entitlement Passed',
        actor: { name: 'System' },
        target: { name: 'Admins', type: 'ENTITLEMENT' },
      }],
    });
    assert.deepEqual(result.modifiers, ['System']);
  });

  it('does not borrow an actor from a different object with the same name', () => {
    const result = attributeActors({
      subjects: [role],
      events: [{
        created: '2026-10-15T09:00:00.000Z',
        technicalName: 'ACCESS_PROFILE_UPDATE_PASSED',
        actor: { displayName: 'Jane Doe' },
        target: { id: 'ap-1', name: 'Analyst', type: 'ACCESS_PROFILE' },
      }],
    });
    assert.deepEqual(result.modifiers, []);
    assert.match(result.lines[0], /no matching audit event/);
  });
});

describe('real ISC ACCESS_ITEM events', () => {
  // Captured verbatim from the tenant's events index. Note what is absent:
  // there is no target.id, so scoping a query on one matches nothing and
  // looking a subject up by id alone finds nothing.
  const event = {
    created: '2026-10-17T07:51:59.229Z',
    action: 'update',
    type: 'ACCESS_ITEM',
    actor: { name: 'fernando.delosrios' },
    target: { name: 'Business Process Users' },
    objects: ['ROLE'],
    operation: 'UPDATE',
    status: 'PASSED',
    technicalName: 'ROLE_UPDATE_PASSED',
    name: 'Update Role Passed',
  };
  const subject = {
    path: 'access/roles/business-process-users.json',
    id: 'c3a8634c230b9d34b89ef8e152ef4e8e',
    name: 'Business Process Users',
    type: 'role',
  };

  it('scopes on target.name, since events carry no target id', () => {
    const [query] = accessItemQueries('2026-10-17T07:36:29.998Z', [subject]);
    assert.match(query.query.query, /target\.name:\("Business Process Users"\)/);
    assert.doesNotMatch(query.query.query, /target\.id/);
  });

  it('attributes the event to a subject that has an id the event lacks', () => {
    const { modifiers, lines } = attributeActors({ subjects: [subject], events: [event] });
    assert.deepEqual(modifiers, ['fernando.delosrios']);
    assert.match(lines[0], /fernando\.delosrios — access\/roles\/business-process-users\.json/);
    assert.match(lines[0], /ROLE_UPDATE_PASSED, 2026-10-17T07:51:59\.229Z/);
  });

  it('reads the object kind from the objects array', () => {
    const asProfile = { ...event, objects: ['ACCESS_PROFILE'], technicalName: 'AP_UPDATE_PASSED' };
    const profileSubject = { ...subject, id: null, type: 'accessProfile' };
    const { modifiers } = attributeActors({ subjects: [profileSubject], events: [asProfile] });
    assert.deepEqual(modifiers, ['fernando.delosrios']);
  });

  it('re-reads the window unscoped when the scoped query comes back empty', async () => {
    const seen = [];
    const client = {
      async searchAll(body) {
        seen.push(body.query.query);
        // Mimics a scoping mistake: narrow query matches nothing, window does.
        return { truncated: false, items: /target\./.test(body.query.query) ? [] : [event] };
      },
    };
    const actors = await attributeDriftActors({ client, subjects: [subject], entries: [] });
    assert.equal(seen.length, 2);
    assert.deepEqual(actors.modifiers, ['fernando.delosrios']);
  });
});

describe('actor line ordering', () => {
  it('puts attributed items and roles ahead of unattributed entitlements', () => {
    const entitlements = Array.from({ length: 50 }, (_, i) => ({
      path: `access/entitlements/s/e${i}.json`,
      id: `e-${i}`,
      name: `E${i}`,
      type: 'entitlement',
    }));
    const changedRole = {
      path: 'access/roles/business-process-users.json',
      id: 'role-9',
      name: 'Business Process Users',
      type: 'role',
    };
    const quietRole = {
      path: 'access/roles/quiet.json', id: 'role-8', name: 'Quiet', type: 'role',
    };

    const { lines } = attributeActors({
      // Entitlements first, exactly how detectDrift orders its subjects.
      subjects: [...entitlements, changedRole, quietRole],
      events: [{
        created: '2026-10-17T07:15:00.000Z',
        technicalName: 'ROLE_UPDATE_PASSED',
        actor: { displayName: 'fernando.delosrios' },
        target: { id: 'role-9', type: 'ROLE' },
      }],
    });

    assert.match(lines[0], /fernando\.delosrios — access\/roles\/business-process-users\.json/);
    assert.match(lines[1], /access\/roles\/quiet\.json/);
  });
});

describe('attributeDriftActors', () => {
  it('queries access-item events since the alignment and keeps the actor list', async () => {
    const seen = [];
    const client = {
      async searchAll(body) {
        seen.push(body);
        return {
          truncated: false,
          items: [{
            created: '2026-10-15T09:00:00.000Z',
            technicalName: 'ROLE_UPDATE_PASSED',
            actor: { displayName: 'Jane Doe' },
            target: { id: 'role-1', type: 'ROLE' },
          }],
        };
      },
    };
    const actors = await attributeDriftActors({
      client,
      subjects: [role],
      entries: [{ kind: 'change', timestamp: '2026-10-01T00:00:00.000Z' }],
    });
    assert.equal(actors.status, 'ok');
    assert.equal(actors.since, '2026-10-01T00:00:00.000Z');
    assert.deepEqual(actors.modifiers, ['Jane Doe']);
    assert.deepEqual(seen, accessItemQueries('2026-10-01T00:00:00.000Z', [role]));
  });

  it('scopes the query to the drifted targets', () => {
    const [query] = accessItemQueries('2026-10-01T00:00:00.000Z', [role]);
    assert.match(query.query.query, /target\.name:\("Analyst"\)/);
  });

  it('looks up deleted items by name, same as everything else', () => {
    const deleted = { path: 'access/roles/gone.json', id: null, name: 'Gone', type: 'role' };
    const queries = accessItemQueries('2026-10-01T00:00:00.000Z', [deleted]);
    assert.equal(queries.length, 1);
    assert.match(queries[0].query.query, /target\.name:\("Gone"\)/);
  });

  it('falls back to the whole window when no target is identifiable', () => {
    const [query] = accessItemQueries('2026-10-01T00:00:00.000Z', []);
    assert.doesNotMatch(query.query.query, /target\./);
  });

  it('reads the window once rather than sending hundreds of scoped queries', () => {
    // Wide drift used to build OR clauses tens of kilobytes long, which the
    // Search API answered with nothing at all, so no actor was ever found.
    const many = Array.from({ length: 2085 }, (_, i) => ({
      path: `access/entitlements/s/e${i}.json`,
      id: `e-${i}`,
      name: `E${i}`,
      type: 'entitlement',
    }));
    const queries = accessItemQueries('2026-10-01T00:00:00.000Z', many);
    assert.equal(queries.length, 1);
    assert.doesNotMatch(queries[0].query.query, /target\./);
  });

  it('stays available for the approval when audit search fails', async () => {
    const client = {
      async searchAll() {
        throw new Error('POST /search/v1 failed: 403');
      },
    };
    const actors = await attributeDriftActors({ client, subjects: [role], entries: [] });
    assert.equal(actors.status, 'unavailable');
    assert.deepEqual(actors.modifiers, []);
    const text = actorApprovalLines(actors).join('\n');
    assert.match(text, /unknown/);
    assert.match(text, /403/);
  });
});
