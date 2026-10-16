import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  CHANGES_DIR,
  ensureDir,
  nowIso,
  readJson,
  walkJsonFiles,
  writeJson,
} from './common.mjs';

function monthDir(date = new Date()) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  return join(CHANGES_DIR, `${y}-${m}`);
}

/**
 * Append a change (PR apply) ledger entry.
 */
export function writeChangeEntry({
  prNumber,
  author,
  title,
  url,
  diffHash,
  approvers,
  decisions,
  applyResult,
  tag = null,
  timestamp = nowIso(),
}) {
  const dir = monthDir(new Date(timestamp));
  ensureDir(dir);
  const path = join(dir, `pr-${prNumber}.json`);
  const entry = {
    kind: 'change',
    pr: prNumber,
    author,
    title,
    url,
    diffHash,
    approvers,
    decisions,
    tag,
    applyResult,
    timestamp,
  };
  writeJson(path, entry);
  return { path, entry };
}

/**
 * Append a restore ledger entry.
 */
export function writeRestoreEntry({
  requester,
  sourceTag,
  planHash,
  decision,
  applyResult,
  timestamp = nowIso(),
}) {
  const dir = monthDir(new Date(timestamp));
  ensureDir(dir);
  const stamp = timestamp.replace(/[:.]/g, '-');
  const path = join(dir, `restore-${stamp}.json`);
  const entry = {
    kind: 'restore',
    requester,
    sourceTag,
    planHash,
    decision,
    applyResult,
    timestamp,
  };
  writeJson(path, entry);
  return { path, entry };
}

/**
 * Append a drift ledger note (daily backup found ISC UI edits).
 *
 * `decision` is 'approved' | 'rejected' | 'expired' once drift goes through
 * governance approval. Entries written before that change omit it (treat
 * missing as 'approved' — they were auto-committed).
 */
export function writeDriftEntry({
  added,
  changed,
  deleted,
  driftHash = null,
  decision = null,
  modifiers = [],
  issueUrl = null,
  timestamp = nowIso(),
}) {
  const dir = monthDir(new Date(timestamp));
  ensureDir(dir);
  const stamp = timestamp.replace(/[:.]/g, '-');
  const path = join(dir, `drift-${stamp}.json`);
  const entry = {
    kind: 'drift',
    added,
    changed,
    deleted,
    driftHash,
    decision,
    modifiers,
    issueUrl,
    timestamp,
  };
  writeJson(path, entry);
  return { path, entry };
}

export function listLedgerEntries() {
  if (!existsSync(CHANGES_DIR)) return [];
  return walkJsonFiles(CHANGES_DIR)
    .map((path) => ({ path, entry: readJson(path) }))
    .sort((a, b) => String(b.entry.timestamp).localeCompare(String(a.entry.timestamp)));
}

export function recentEntries(limit = 25) {
  return listLedgerEntries().slice(0, limit);
}

export function listMonths() {
  if (!existsSync(CHANGES_DIR)) return [];
  return readdirSync(CHANGES_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort()
    .reverse();
}
