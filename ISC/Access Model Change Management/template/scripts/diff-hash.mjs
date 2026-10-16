import { contentHash, loadAllItems, typeFromPath } from './common.mjs';
import { semanticBody } from './plan.mjs';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT } from './common.mjs';

/**
 * Compute a stable hash of the semantic content of touched access files.
 * Approval is bound to this hash, not to a commit SHA.
 */
export function hashTouchedFiles(relPaths, { root = ROOT } = {}) {
  const payloads = [];
  for (const rel of [...relPaths].sort()) {
    const abs = join(root, rel);
    const type = typeFromPath(abs);
    if (!type) continue;
    if (!existsSync(abs)) {
      payloads.push({ path: rel, deleted: true });
      continue;
    }
    const data = JSON.parse(readFileSync(abs, 'utf8'));
    payloads.push({ path: rel, body: semanticBody(data, type) });
  }
  return contentHash(payloads);
}

/**
 * Hash the full access tree (used for restore plan binding alongside planHash).
 */
export function hashFullTree({ items = loadAllItems() } = {}) {
  const payloads = items
    .map((i) => ({ path: i.relPath, body: semanticBody(i.data, i.type) }))
    .sort((a, b) => a.path.localeCompare(b.path));
  return contentHash(payloads);
}
