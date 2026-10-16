import { rmSync } from 'node:fs';
import { relative } from 'node:path';
import {
  ACCESS_PROFILES_DIR,
  ENTITLEMENTS_DIR,
  ITEM_TYPES,
  ROOT,
  ROLES_DIR,
  contentHash,
  loadAllItems,
  loadConfig,
  removeEmptyDirs,
  slugify,
  stableStringify,
  walkJsonFiles,
  writeJson,
} from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { attributeDriftActors } from './drift-actors.mjs';
import { listLedgerEntries } from './ledger.mjs';
import { snapshotLive } from './live-snapshot.mjs';

/** Directories this repo owns, so stale files can be pruned after a backup. */
function trackedRoots(config) {
  const roots = [ACCESS_PROFILES_DIR, ROLES_DIR];
  for (const source of config.entitlementSources ?? []) {
    roots.push(`${ENTITLEMENTS_DIR}/${slugify(source.name)}`);
  }
  return roots;
}

/**
 * Snapshot entitlements (allowlisted sources), access profiles and roles into access/.
 *
 * `snapshot` lets a caller that already read ISC (drift detection) hand the
 * result over instead of paying for a second full enumeration.
 */
export async function runBackup({
  client = IscClient.fromEnv(),
  config = loadConfig(),
  dryRun = false,
  snapshot = null,
} = {}) {
  const live = snapshot ?? await snapshotLive({ client, config });
  const written = [];
  const keptPaths = new Set();

  for (const item of live.entries) {
    keptPaths.add(item.path);
    if (!dryRun) writeJson(item.path, item.data);
    written.push({
      type: item.type,
      path: item.path,
      name: item.name,
      id: item.id,
    });
  }

  const removed = [];
  for (const root of trackedRoots(config)) {
    for (const file of walkJsonFiles(root)) {
      if (!keptPaths.has(file)) {
        removed.push(file);
        if (!dryRun) rmSync(file);
      }
    }
  }
  if (!dryRun) removeEmptyDirs(ENTITLEMENTS_DIR);

  return {
    counts: {
      entitlements: written.filter((w) => w.type === ITEM_TYPES.entitlement).length,
      accessProfiles: written.filter((w) => w.type === ITEM_TYPES.accessProfile).length,
      roles: written.filter((w) => w.type === ITEM_TYPES.role).length,
      removed: removed.length,
    },
    written,
    removed: removed.map((p) => relative(ROOT, p)),
  };
}

/**
 * Compare current access/ files to a fresh ISC snapshot without writing.
 *
 * Returns the snapshot alongside the drift so the caller can write it without
 * reading ISC again.
 */
export async function detectDrift({
  client = IscClient.fromEnv(),
  config = loadConfig(),
  snapshot = null,
} = {}) {
  const before = loadAllItems();
  const beforeByPath = new Map(before.map((i) => [i.relPath, i]));
  const live = snapshot ?? await snapshotLive({ client, config });

  const changed = [];
  const added = [];
  const deleted = [];
  const liveByPath = new Map();

  for (const item of live.entries) {
    liveByPath.set(item.relPath, item);
    const prior = beforeByPath.get(item.relPath);
    if (!prior) added.push(item.relPath);
    // stableStringify, not JSON.stringify: ISC key order is not guaranteed and
    // a reordered-but-identical object is not drift.
    else if (stableStringify(prior.data) !== stableStringify(item.data)) {
      changed.push(item.relPath);
    }
  }
  for (const relPath of beforeByPath.keys()) {
    if (!liveByPath.has(relPath)) deleted.push(relPath);
  }

  // Sorted so the hash (and the request/execute comparison across the
  // approval round trip) is stable regardless of iteration order.
  added.sort();
  changed.sort();
  deleted.sort();

  const hasDrift = added.length + changed.length + deleted.length > 0;
  const subjects = [];
  const pushSubject = (relPath, change) => {
    const item = liveByPath.get(relPath) ?? beforeByPath.get(relPath);
    subjects.push({
      path: relPath,
      change,
      id: item?.id ?? item?.data?.id ?? null,
      name: item?.name ?? item?.data?.name ?? null,
      type: item?.type ?? null,
    });
  };
  for (const relPath of added) pushSubject(relPath, 'added');
  for (const relPath of changed) pushSubject(relPath, 'changed');
  for (const relPath of deleted) pushSubject(relPath, 'deleted');

  const actors = hasDrift
    ? await attributeDriftActors({
      client,
      subjects,
      entries: listLedgerEntries(),
    })
    : null;

  return {
    added,
    changed,
    deleted,
    hasDrift,
    driftHash: contentHash({ added, changed, deleted }),
    // Actors are not part of the hash. The approval callback re-detects drift
    // and compares hashes, then reads actors.modifiers into the ledger.
    actors,
    snapshot: live,
  };
}
