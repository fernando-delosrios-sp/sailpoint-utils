/**
 * Associate drifted access items with ISC audit actors.
 * The events index records who ISC saw making the change. That is the person,
 * service identity, or System attached to the event — not proof of intent.
 */

/** Used only when the ledger has no moment at which git and ISC matched. */
export const ACTOR_LOOKBACK_MS = 14 * 24 * 60 * 60 * 1000;

function unwrap(entry) {
  return entry?.entry ?? entry;
}

/**
 * Latest ledger timestamp at which git and ISC were aligned.
 * Change, init, approved drift, legacy auto-committed drift, and a rejected
 * drift that was actually restored all count. Expired drift and a rejected
 * drift that was not restored do not: ISC was still ahead of git.
 */
export function alignmentTimestamp(entries = []) {
  let latest = null;
  for (const raw of entries) {
    const entry = unwrap(raw);
    if (!entry || !isAlignment(entry) || !entry.timestamp) continue;
    if (!latest || String(entry.timestamp) > latest) latest = String(entry.timestamp);
  }
  return latest;
}

function isAlignment(entry) {
  if (entry.kind === 'init' || entry.kind === 'change' || entry.kind === 'restore') return true;
  if (entry.kind !== 'drift') return false;
  if (entry.decision == null || entry.decision === 'approved') return true;
  return entry.decision === 'rejected' && entry.restored === true;
}

export function driftWindowStart({ entries = [], now = new Date() } = {}) {
  return alignmentTimestamp(entries)
    ?? new Date(now.getTime() - ACTOR_LOOKBACK_MS).toISOString();
}

/** Search queries cap out around 800 values in a terms-style clause. */
const MAX_QUERY_TERMS = 500;

function quote(value) {
  return `"${String(value).replace(/(["\\])/g, '\\$1')}"`;
}

function chunk(values, size) {
  const out = [];
  for (let i = 0; i < values.length; i += size) out.push(values.slice(i, i + size));
  return out;
}

/**
 * Queries for the access-item events that could explain this drift.
 *
 * Scoped to the drifted objects rather than every access-item event in the
 * window — attributing a handful of files should not pull thousands of events.
 * With no usable ids or names it falls back to the whole window.
 */
export function accessItemQueries(since, subjects = []) {
  const window = `created:[${since} TO now]`;
  const type = '(type:ACCESS_ITEM OR type:access_item)';
  const ids = [...new Set(subjects.map((s) => s.id).filter(Boolean))];
  const names = [...new Set(subjects.map((s) => s.name).filter(Boolean))];

  const clauses = [];
  for (const group of chunk(ids, MAX_QUERY_TERMS)) {
    clauses.push(`target.id:(${group.map(quote).join(' OR ')})`);
  }
  // Deleted items have no live id to match, so their names carry the lookup.
  const namesWithoutId = subjects.some((s) => !s.id) ? names : [];
  for (const group of chunk(namesWithoutId, MAX_QUERY_TERMS)) {
    clauses.push(`target.name:(${group.map(quote).join(' OR ')})`);
  }

  if (clauses.length === 0) {
    return [{ indices: ['events'], query: { query: `${type} AND ${window}` }, sort: ['-created'] }];
  }
  return clauses.map((clause) => ({
    indices: ['events'],
    query: { query: `${type} AND ${window} AND ${clause}` },
    sort: ['-created'],
  }));
}

export function actorLabel(actor) {
  if (!actor) return null;
  if (typeof actor === 'string') {
    const trimmed = actor.trim();
    return trimmed || null;
  }
  const label = actor.displayName || actor.name || actor.id || null;
  return label ? String(label) : null;
}

function targetId(event) {
  const id = event?.target?.id ?? event?.attributes?.targetId ?? event?.attributes?.id ?? null;
  return id ? String(id) : null;
}

function targetName(event) {
  const name = event?.target?.name ?? event?.attributes?.targetName ?? event?.attributes?.name ?? null;
  return name ? String(name) : null;
}

function targetType(event) {
  const raw = `${event?.target?.type ?? ''} ${event?.technicalName ?? ''} ${event?.name ?? ''}`;
  const s = raw.toUpperCase();
  if (s.includes('ACCESS_PROFILE') || s.includes('ACCESS PROFILE')) return 'accessProfile';
  if (s.includes('ENTITLEMENT')) return 'entitlement';
  if (s.includes('ROLE_') || /\bROLE\b/.test(s)) return 'role';
  return null;
}

function isPassedEvent(event) {
  const status = String(event?.status ?? '').toUpperCase();
  if (status === 'FAILED' || status === 'FAILURE') return false;
  const technical = String(event?.technicalName ?? event?.name ?? '').toUpperCase();
  if (technical.includes('FAILED')) return false;
  return true;
}

/**
 * Match audit events to drifted items.
 * `subjects` are `{ path, id, name, type }`. Events should already be limited
 * to the drift window; failed events are ignored.
 *
 * Events are indexed by target before matching, so cost grows with the number
 * of events plus subjects rather than their product.
 */
export function attributeActors({ subjects = [], events = [] } = {}) {
  const passed = events
    .filter(isPassedEvent)
    .sort((a, b) => String(b?.created ?? '').localeCompare(String(a?.created ?? '')));

  const byId = new Map();
  const byNameType = new Map();
  for (const event of passed) {
    const id = targetId(event);
    if (id) {
      if (!byId.has(id)) byId.set(id, []);
      byId.get(id).push(event);
      // An event with a target id is attributed by id alone; falling back to
      // its name could pin it on a different object of the same name.
      continue;
    }
    const name = targetName(event);
    const type = targetType(event);
    if (!name || !type) continue;
    const key = `${type}:${name}`;
    if (!byNameType.has(key)) byNameType.set(key, []);
    byNameType.get(key).push(event);
  }

  const grouped = subjects.map((subject) => ({
    ...subject,
    matches: subject.id
      ? (byId.get(String(subject.id)) ?? [])
      : (byNameType.get(`${subject.type}:${subject.name}`) ?? []),
  }));

  const lines = [];
  const actorRecency = new Map();
  for (const subject of grouped) {
    const labels = [];
    for (const event of subject.matches) {
      const label = actorLabel(event.actor);
      if (!label || labels.includes(label)) continue;
      labels.push(label);
      const created = String(event.created ?? '');
      if (!actorRecency.has(label) || created > actorRecency.get(label)) {
        actorRecency.set(label, created);
      }
    }
    if (labels.length === 0) {
      lines.push(`- no matching audit event — ${subject.path}`);
      continue;
    }
    const newest = subject.matches.find((event) => actorLabel(event.actor)) ?? subject.matches[0];
    const eventName = newest?.technicalName || newest?.name || newest?.action || 'event';
    const when = newest?.created ? `, ${newest.created}` : '';
    lines.push(`- ${labels.join(', ')} — ${subject.path} (${eventName}${when})`);
  }

  const modifiers = [...actorRecency.entries()]
    .sort((a, b) => b[1].localeCompare(a[1]))
    .map(([label]) => label);

  return { modifiers, lines };
}

export function actorApprovalLines(actors, { limit = 20 } = {}) {
  if (!actors) return [];
  if (actors.status === 'unavailable') {
    return [
      'Who changed it: unknown. ISC audit search failed, so no actor was recorded.',
      actors.error ? `Search error: ${actors.error}` : '',
      'The service identity needs the Search user level (sp:search:read).',
    ].filter(Boolean);
  }
  const since = actors.since ? ` since ${actors.since}` : '';
  const header = `Who changed it (ISC audit events${since}; the actor associated with each item):`;
  const note = actors.status === 'partial'
    ? 'Audit search stopped early, so some actors may be missing.'
    : '';
  const lines = actors.lines ?? [];
  const shown = lines.slice(0, limit);
  if (lines.length > limit) shown.push(`...and ${lines.length - limit} more`);
  if (shown.length === 0) shown.push('- no matching audit event');
  return [header, note, ...shown].filter(Boolean);
}

/**
 * Search the events index and attach actors to the drifted items.
 * A search failure leaves drift detection usable: modifiers stay empty.
 */
export async function attributeDriftActors({
  client,
  subjects = [],
  entries = [],
  now = new Date(),
  max = 5000,
} = {}) {
  const since = driftWindowStart({ entries, now });
  try {
    const events = [];
    let truncated = false;
    for (const query of accessItemQueries(since, subjects)) {
      const page = await client.searchAll(query, { max });
      events.push(...page.items);
      truncated = truncated || page.truncated;
    }
    const attributed = attributeActors({ subjects, events });
    return {
      status: truncated ? 'partial' : 'ok',
      since,
      modifiers: attributed.modifiers,
      lines: attributed.lines,
    };
  } catch (err) {
    return {
      status: 'unavailable',
      since,
      modifiers: [],
      lines: [],
      error: err?.message ?? String(err),
    };
  }
}
