import { loadAllItems, loadConfig } from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { runBackup } from './backup.mjs';
import { buildPlan } from './plan.mjs';
import { applyPlan } from './apply.mjs';
import {
  normalizeAccessProfile,
  normalizeEntitlement,
  normalizeRole,
} from './normalize.mjs';
import { ITEM_TYPES, itemPath, slugify } from './common.mjs';
import { relative } from 'node:path';
import { ROOT } from './common.mjs';

/**
 * Build live ISC items as the same shape as repo files (without writing).
 */
async function snapshotLiveAsItems({ client, config }) {
  const allowlist = config.entitlementSources ?? [];
  const items = [];
  const entitlementNameById = new Map();
  const accessProfileNameById = new Map();

  for (const source of allowlist) {
    const raws = await client.listEntitlements(`source.id eq "${source.id}"`);
    const sourceSlug = slugify(source.name);
    for (const raw of raws) {
      entitlementNameById.set(raw.id, raw.name);
      const data = normalizeEntitlement(raw, { sourceSlug });
      const path = itemPath(ITEM_TYPES.entitlement, raw.name, sourceSlug);
      items.push({
        type: ITEM_TYPES.entitlement,
        path,
        relPath: relative(ROOT, path),
        data,
        name: data.name,
        id: data.id,
        sourceSlug,
      });
    }
  }

  for (const raw of await client.listAccessProfiles()) {
    accessProfileNameById.set(raw.id, raw.name);
    const data = normalizeAccessProfile(raw, { entitlementNameById });
    const path = itemPath(ITEM_TYPES.accessProfile, raw.name);
    items.push({
      type: ITEM_TYPES.accessProfile,
      path,
      relPath: relative(ROOT, path),
      data,
      name: data.name,
      id: data.id,
      sourceSlug: null,
    });
  }

  for (const raw of await client.listRoles()) {
    const data = normalizeRole(raw, { accessProfileNameById, entitlementNameById });
    const path = itemPath(ITEM_TYPES.role, raw.name);
    items.push({
      type: ITEM_TYPES.role,
      path,
      relPath: relative(ROOT, path),
      data,
      name: data.name,
      id: data.id,
      sourceSlug: null,
    });
  }

  return items;
}

/**
 * Full reconciliation plan: tag (or working tree) desired state vs live ISC.
 * headItems should already be loaded from the checked-out tag.
 */
export async function buildRestorePlan({
  client = IscClient.fromEnv(),
  config = loadConfig(),
  headItems = loadAllItems(),
} = {}) {
  const liveItems = await snapshotLiveAsItems({ client, config });
  // Plan: base = live ISC, head = tag contents → ops that make ISC match the tag
  return buildPlan({ baseItems: liveItems, headItems });
}

/**
 * Execute a previously approved restore plan.
 */
export async function executeRestore({
  plan,
  client = IscClient.fromEnv(),
  items = loadAllItems(),
  dryRun = false,
} = {}) {
  return applyPlan({ plan, client, items, dryRun });
}

/**
 * After a restore, optionally refresh the working tree from ISC so main matches.
 */
export async function reconcileRepoAfterRestore({
  client = IscClient.fromEnv(),
  config = loadConfig(),
} = {}) {
  return runBackup({ client, config });
}
