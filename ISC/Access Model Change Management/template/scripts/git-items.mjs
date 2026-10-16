import { execFileSync, spawnSync } from 'node:child_process';
import { ITEM_TYPES } from './common.mjs';
import { join } from 'node:path';
import { ROOT } from './common.mjs';

/**
 * Type from a git-relative path (e.g. "access/roles/r.json"), not an absolute
 * one. `typeFromPath` in common.mjs resolves against the module's own
 * hardcoded ACCESS_ROOT, so it silently misclassifies everything whenever
 * `cwd` differs from the script's own checkout (any absolute path ends up
 * outside ACCESS_ROOT and matches no branch).
 */
function typeFromRelPath(rel) {
  const [, section] = rel.split('/');
  if (section === 'entitlements') return ITEM_TYPES.entitlement;
  if (section === 'access-profiles') return ITEM_TYPES.accessProfile;
  if (section === 'roles') return ITEM_TYPES.role;
  return null;
}

// This tenant has 10k+ access files. execFileSync's default maxBuffer (1MB)
// is too small for `git ls-tree` on a repo this size and throws ENOBUFS.
const GIT_MAX_BUFFER = 1024 * 1024 * 200;

/**
 * Read many blobs in one `git cat-file --batch` call instead of spawning a
 * `git show` subprocess per file — at 10k+ files the per-file approach took
 * well over a minute and risked a CI timeout.
 */
function batchCatFile(hashes, { cwd }) {
  if (hashes.length === 0) return new Map();
  const result = spawnSync('git', ['cat-file', '--batch'], {
    cwd,
    input: `${hashes.join('\n')}\n`,
    maxBuffer: GIT_MAX_BUFFER,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`git cat-file --batch failed: ${result.stderr?.toString() ?? ''}`);
  }
  const buf = result.stdout;
  const contents = new Map();
  let offset = 0;
  while (offset < buf.length) {
    const headerEnd = buf.indexOf(0x0a, offset);
    if (headerEnd < 0) break;
    const header = buf.toString('utf8', offset, headerEnd);
    offset = headerEnd + 1;
    const [sha, type, sizeStr] = header.split(' ');
    if (type === 'missing') continue;
    const size = Number(sizeStr);
    contents.set(sha, buf.toString('utf8', offset, offset + size));
    offset += size + 1; // skip the trailing newline after the object content
  }
  return contents;
}

/**
 * Load access items from a git ref (e.g. origin/main or a known-good tag).
 *
 * Returns [] only when the ref genuinely has no history yet (e.g. HEAD~1 on
 * the very first commit) — any other git failure (notably ENOBUFS on large
 * trees) is rethrown. Swallowing those unconditionally made every item look
 * brand new, so Apply tried to re-create everything that already exists in
 * ISC and failed with "already exists" on the first object, every time.
 */
export function loadItemsFromGitRef(ref, { cwd = ROOT } = {}) {
  let listing;
  try {
    listing = execFileSync(
      'git',
      ['ls-tree', '-r', ref, '--', 'access'],
      { cwd, encoding: 'utf8', maxBuffer: GIT_MAX_BUFFER },
    );
  } catch (err) {
    const detail = `${err.message} ${err.stderr ?? ''}`;
    if (/unknown revision|bad revision|bad object|not a valid object name/i.test(detail)) {
      return [];
    }
    throw new Error(`loadItemsFromGitRef(${ref}) failed: ${detail}`);
  }

  // Each line: "<mode> blob <sha>\t<path>"
  const entries = [];
  for (const line of listing.split('\n')) {
    const tabIndex = line.indexOf('\t');
    if (tabIndex < 0) continue;
    const rel = line.slice(tabIndex + 1);
    if (!rel.endsWith('.json')) continue;
    const [, , sha] = line.slice(0, tabIndex).split(' ');
    entries.push({ rel, sha });
  }

  const blobs = batchCatFile(entries.map((e) => e.sha), { cwd });

  const items = [];
  for (const { rel, sha } of entries) {
    const abs = join(cwd, rel);
    const type = typeFromRelPath(rel);
    if (!type) continue;
    const raw = blobs.get(sha);
    if (raw === undefined) continue;
    const data = JSON.parse(raw);
    const sourceSlug = type === ITEM_TYPES.entitlement
      ? rel.split('/')[2]
      : null;
    items.push({
      type,
      path: abs,
      relPath: rel,
      data,
      name: data.name,
      id: data.id ?? null,
      sourceSlug,
    });
  }
  return items;
}

/**
 * List access files changed between two refs (or ref and working tree).
 */
export function changedAccessFiles(baseRef, headRef = null, { cwd = ROOT } = {}) {
  const args = headRef
    ? ['diff', '--name-only', baseRef, headRef, '--', 'access']
    : ['diff', '--name-only', baseRef, '--', 'access'];
  const out = execFileSync('git', args, { cwd, encoding: 'utf8', maxBuffer: GIT_MAX_BUFFER });
  return out
    .split('\n')
    .map((s) => s.trim())
    .filter((p) => p.endsWith('.json'));
}
