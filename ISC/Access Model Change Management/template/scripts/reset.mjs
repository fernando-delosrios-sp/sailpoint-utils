import { existsSync, readdirSync, rmSync, rmdirSync } from 'node:fs';
import { join } from 'node:path';
import { ACCESS_ROOT, CHANGES_DIR, walkJsonFiles } from './common.mjs';

function removeEmptyChildren(dir) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const child = join(dir, entry.name);
    removeEmptyChildren(child);
    if (readdirSync(child).length === 0) rmdirSync(child);
  }
}

/**
 * Delete access-model JSON and the ledger so the next backup is the baseline.
 * Keeps .gitkeep, scripts, schemas, workflows, and config.
 */
export function clearAccessAndLedger({
  accessRoot = ACCESS_ROOT,
  changesDir = CHANGES_DIR,
} = {}) {
  const removed = [];
  for (const file of [...walkJsonFiles(accessRoot), ...walkJsonFiles(changesDir)]) {
    rmSync(file);
    removed.push(file);
  }
  removeEmptyChildren(accessRoot);
  removeEmptyChildren(changesDir);
  return { removed: removed.length };
}
