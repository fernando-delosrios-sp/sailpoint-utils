import { execFileSync } from 'node:child_process';
import { utcStamp } from './common.mjs';

const TAG_PREFIX = 'isc-applied/';

export function isAppliedTag(name) {
  return typeof name === 'string' && name.startsWith(TAG_PREFIX);
}

/**
 * Build an annotated tag name for a successful apply.
 * Example: isc-applied/20261016T101530Z-pr-123
 */
export function buildAppliedTagName({ prNumber = null, date = new Date() } = {}) {
  const stamp = utcStamp(date);
  const suffix = prNumber != null ? `-pr-${prNumber}` : '';
  return `${TAG_PREFIX}${stamp}${suffix}`;
}

export function createAppliedTag({
  name,
  message,
  cwd = process.cwd(),
  dryRun = false,
} = {}) {
  if (!isAppliedTag(name)) {
    throw new Error(`Tag name must start with ${TAG_PREFIX}`);
  }
  if (dryRun) {
    return { name, dryRun: true };
  }
  execFileSync('git', ['tag', '-a', name, '-m', message], { cwd, stdio: 'pipe' });
  execFileSync('git', ['push', 'origin', name], { cwd, stdio: 'pipe' });
  return { name, dryRun: false };
}

export function listAppliedTags({ cwd = process.cwd(), limit = 50 } = {}) {
  try {
    const out = execFileSync(
      'git',
      ['tag', '-l', `${TAG_PREFIX}*`, '--sort=-creatordate'],
      { cwd, encoding: 'utf8' },
    );
    return out
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean)
      .slice(0, limit);
  } catch {
    return [];
  }
}

export function resolveTagCommit(tag, { cwd = process.cwd() } = {}) {
  return execFileSync('git', ['rev-list', '-n', '1', tag], {
    cwd,
    encoding: 'utf8',
  }).trim();
}
