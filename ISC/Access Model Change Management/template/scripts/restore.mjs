import { loadAllItems, loadConfig } from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { runBackup } from './backup.mjs';
import { buildPlan } from './plan.mjs';
import { applyPlan } from './apply.mjs';
import { snapshotLive } from './live-snapshot.mjs';

/**
 * Full reconciliation plan: tag (or working tree) desired state vs live ISC.
 * headItems should already be loaded from the checked-out tag.
 *
 * `snapshot` reuses an earlier read of ISC; a full read is ~70 paged requests.
 */
export async function buildRestorePlan({
  client = IscClient.fromEnv(),
  config = loadConfig(),
  headItems = loadAllItems(),
  snapshot = null,
} = {}) {
  const live = snapshot ?? await snapshotLive({ client, config });
  // Plan: base = live ISC, head = tag contents → ops that make ISC match the tag
  return buildPlan({ baseItems: live.entries, headItems });
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
