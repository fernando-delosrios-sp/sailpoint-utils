import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { loadItemsFromGitRef } from '../git-items.mjs';

function git(args, cwd) {
  return execFileSync('git', args, { cwd, encoding: 'utf8' });
}

function initRepo() {
  const dir = mkdtempSync(join(tmpdir(), 'amcm-git-items-'));
  git(['init', '-q'], dir);
  git(['config', 'user.email', 'test@local'], dir);
  git(['config', 'user.name', 'test'], dir);
  return dir;
}

describe('loadItemsFromGitRef', () => {
  it('reads many files via a single batched git cat-file call', () => {
    const dir = initRepo();
    const entDir = join(dir, 'access', 'entitlements', 'source-a');
    mkdirSync(entDir, { recursive: true });
    // Enough files to exercise the batch path meaningfully (and to make a
    // one-subprocess-per-file approach noticeably slower in CI).
    const count = 200;
    for (let i = 0; i < count; i += 1) {
      writeFileSync(
        join(entDir, `ent-${i}.json`),
        JSON.stringify({ id: `id-${i}`, name: `Ent ${i}`, source: { id: 's1', name: 'Source A' } }),
      );
    }
    git(['add', '-A'], dir);
    git(['commit', '-q', '-m', 'seed'], dir);

    const items = loadItemsFromGitRef('HEAD', { cwd: dir });
    assert.equal(items.length, count);
    const sample = items.find((i) => i.name === 'Ent 42');
    assert.equal(sample.id, 'id-42');
    assert.equal(sample.sourceSlug, 'source-a');
    assert.equal(sample.data.name, 'Ent 42');
  });

  it('returns [] when the ref has no history yet, without masking real errors', () => {
    const dir = initRepo();
    mkdirSync(join(dir, 'access', 'roles'), { recursive: true });
    writeFileSync(join(dir, 'access', 'roles', 'r.json'), JSON.stringify({ id: '1', name: 'R' }));
    git(['add', '-A'], dir);
    git(['commit', '-q', '-m', 'only commit'], dir);

    // HEAD~1 does not exist yet — this must resolve to [], not throw.
    assert.deepEqual(loadItemsFromGitRef('HEAD~1', { cwd: dir }), []);
  });

  it('propagates unexpected git failures instead of silently returning []', () => {
    const dir = initRepo();
    mkdirSync(join(dir, 'access', 'roles'), { recursive: true });
    writeFileSync(join(dir, 'access', 'roles', 'r.json'), JSON.stringify({ id: '1', name: 'R' }));
    git(['add', '-A'], dir);
    git(['commit', '-q', '-m', 'only commit'], dir);

    // Not a git repo at all — a real failure, distinct from "ref has no history".
    const notARepo = mkdtempSync(join(tmpdir(), 'amcm-not-a-repo-'));
    assert.throws(() => loadItemsFromGitRef('HEAD', { cwd: notARepo }));
  });
});
