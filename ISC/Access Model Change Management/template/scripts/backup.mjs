import { rmSync } from 'node:fs';
import { relative } from 'node:path';
import {
  ACCESS_PROFILES_DIR,
  ENTITLEMENTS_DIR,
  ITEM_TYPES,
  ROOT,
  ROLES_DIR,
  contentHash,
  ensureDir,
  itemPath,
  loadAllItems,
  loadConfig,
  removeEmptyDirs,
  slugify,
  walkJsonFiles,
  writeJson,
} from './common.mjs';
import { IscClient } from './isc-client.mjs';
import {
  normalizeAccessProfile,
  normalizeEntitlement,
  normalizeRole,
} from './normalize.mjs';

/**
 * Snapshot entitlements (allowlisted sources), access profiles and roles into access/.
 */
export async function runBackup({
  client = IscClient.fromEnv(),
  config = loadConfig(),
  dryRun = false,
} = {}) {
  const allowlist = config.entitlementSources ?? [];
  const entitlementNameById = new Map();
  const accessProfileNameById = new Map();
  const written = [];
  const keptPaths = new Set();

  for (const source of allowlist) {
    const raws = await client.listEntitlements(`source.id eq "${source.id}"`);
    const sourceSlug = slugify(source.name);
    ensureDir(`${ENTITLEMENTS_DIR}/${sourceSlug}`);
    for (const raw of raws) {
      entitlementNameById.set(raw.id, raw.name);
      const normalized = normalizeEntitlement(raw, { sourceSlug });
      const path = itemPath(ITEM_TYPES.entitlement, raw.name, sourceSlug);
      keptPaths.add(path);
      if (!dryRun) writeJson(path, normalized);
      written.push({ type: ITEM_TYPES.entitlement, path, name: raw.name, id: raw.id });
    }
  }

  for (const raw of await client.listAccessProfiles()) {
    accessProfileNameById.set(raw.id, raw.name);
    const normalized = normalizeAccessProfile(raw, { entitlementNameById });
    const path = itemPath(ITEM_TYPES.accessProfile, raw.name);
    keptPaths.add(path);
    if (!dryRun) writeJson(path, normalized);
    written.push({ type: ITEM_TYPES.accessProfile, path, name: raw.name, id: raw.id });
  }

  for (const raw of await client.listRoles()) {
    const normalized = normalizeRole(raw, { accessProfileNameById, entitlementNameById });
    const path = itemPath(ITEM_TYPES.role, raw.name);
    keptPaths.add(path);
    if (!dryRun) writeJson(path, normalized);
    written.push({ type: ITEM_TYPES.role, path, name: raw.name, id: raw.id });
  }

  const removed = [];
  const trackedRoots = [ACCESS_PROFILES_DIR, ROLES_DIR];
  for (const source of allowlist) {
    trackedRoots.push(`${ENTITLEMENTS_DIR}/${slugify(source.name)}`);
  }
  for (const root of trackedRoots) {
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
 */
export async function detectDrift({
  client = IscClient.fromEnv(),
  config = loadConfig(),
} = {}) {
  const before = loadAllItems();
  const beforeMap = new Map(before.map((i) => [i.relPath, JSON.stringify(i.data)]));
  const allowlist = config.entitlementSources ?? [];
  const after = new Map();
  const entitlementNameById = new Map();
  const accessProfileNameById = new Map();

  for (const source of allowlist) {
    const raws = await client.listEntitlements(`source.id eq "${source.id}"`);
    const sourceSlug = slugify(source.name);
    for (const raw of raws) {
      entitlementNameById.set(raw.id, raw.name);
      const normalized = normalizeEntitlement(raw, { sourceSlug });
      after.set(
        relative(ROOT, itemPath(ITEM_TYPES.entitlement, raw.name, sourceSlug)),
        JSON.stringify(normalized),
      );
    }
  }

  for (const raw of await client.listAccessProfiles()) {
    accessProfileNameById.set(raw.id, raw.name);
    const normalized = normalizeAccessProfile(raw, { entitlementNameById });
    after.set(
      relative(ROOT, itemPath(ITEM_TYPES.accessProfile, raw.name)),
      JSON.stringify(normalized),
    );
  }

  for (const raw of await client.listRoles()) {
    const normalized = normalizeRole(raw, { accessProfileNameById, entitlementNameById });
    after.set(relative(ROOT, itemPath(ITEM_TYPES.role, raw.name)), JSON.stringify(normalized));
  }

  const changed = [];
  const added = [];
  const deleted = [];
  for (const [path, content] of after) {
    if (!beforeMap.has(path)) added.push(path);
    else if (beforeMap.get(path) !== content) changed.push(path);
  }
  for (const path of beforeMap.keys()) {
    if (!after.has(path)) deleted.push(path);
  }

  // Sorted so the hash (and the request/execute comparison across the
  // approval round trip) is stable regardless of Map iteration order.
  added.sort();
  changed.sort();
  deleted.sort();

  return {
    added,
    changed,
    deleted,
    hasDrift: added.length + changed.length + deleted.length > 0,
    driftHash: contentHash({ added, changed, deleted }),
  };
}
