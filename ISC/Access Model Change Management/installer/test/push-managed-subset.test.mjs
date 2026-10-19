import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync, mkdirSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pushManagedSubset } from '../gh.mjs';

const MANAGED_PATHS = ['.github/workflows', 'scripts', 'package.json'];

let bareDir;
let workDir;
let sourceDir;

function git(cwd, args) {
  return execFileSync('git', args, { cwd, encoding: 'utf8' });
}

beforeEach(() => {
  bareDir = mkdtempSync(join(tmpdir(), 'amcm-bare-'));
  workDir = mkdtempSync(join(tmpdir(), 'amcm-work-'));
  sourceDir = mkdtempSync(join(tmpdir(), 'amcm-src-'));

  // A deployed repo: has live data outside the managed paths, plus an older
  // version of a managed file.
  execFileSync('git', ['init', '--bare', '--initial-branch=main', bareDir]);
  git(workDir, ['clone', bareDir, '.']);
  mkdirSync(join(workDir, 'access'), { recursive: true });
  writeFileSync(join(workDir, 'access', 'live-role.json'), '{"id":"role-live","name":"Live Role"}\n');
  mkdirSync(join(workDir, 'scripts'), { recursive: true });
  writeFileSync(join(workDir, 'scripts', 'old.mjs'), 'export const old = true;\n');
  writeFileSync(join(workDir, 'package.json'), '{"name":"old"}\n');
  writeFileSync(join(workDir, 'README.md'), '# Live generated README\nhistory here\n');
  git(workDir, ['add', '-A']);
  git(workDir, ['-c', 'user.name=t', '-c', 'user.email=t@t', 'commit', '-m', 'deployed baseline']);
  git(workDir, ['push', 'origin', 'main']);

  // A freshly materialized template: the fix removes scripts/old.mjs and
  // adds scripts/new.mjs, and bumps package.json — but has none of the
  // repo's live data.
  mkdirSync(join(sourceDir, '.github', 'workflows'), { recursive: true });
  writeFileSync(join(sourceDir, '.github', 'workflows', 'apply.yml'), 'name: apply\n');
  mkdirSync(join(sourceDir, 'scripts'), { recursive: true });
  writeFileSync(join(sourceDir, 'scripts', 'new.mjs'), 'export const fixed = true;\n');
  writeFileSync(join(sourceDir, 'package.json'), '{"name":"fixed"}\n');
  writeFileSync(join(sourceDir, 'README.md'), 'Installing…\n');
});

afterEach(() => {
  rmSync(bareDir, { recursive: true, force: true });
  rmSync(workDir, { recursive: true, force: true });
  rmSync(sourceDir, { recursive: true, force: true });
});

describe('pushManagedSubset', () => {
  it('overlays only the managed paths and leaves everything else in the deployed repo untouched', () => {
    pushManagedSubset({
      repo: 'ignored/ignored',
      sourceDir,
      managedPaths: MANAGED_PATHS,
      message: 'fix(amcm): test update',
      token: 'unused-in-this-test',
      cloneUrl: bareDir,
    });

    const checkDir = mkdtempSync(join(tmpdir(), 'amcm-check-'));
    git(checkDir, ['clone', bareDir, '.']);

    // Managed paths were updated to match the fixed template.
    assert.equal(
      readFileSync(join(checkDir, 'package.json'), 'utf8'),
      '{"name":"fixed"}\n',
    );
    assert.equal(
      readFileSync(join(checkDir, 'scripts', 'new.mjs'), 'utf8'),
      'export const fixed = true;\n',
    );
    assert.equal(
      readFileSync(join(checkDir, '.github', 'workflows', 'apply.yml'), 'utf8'),
      'name: apply\n',
    );
    // A managed-path file the fix deleted is deleted in the repo too.
    assert.equal(existsSync(join(checkDir, 'scripts', 'old.mjs')), false);

    // Everything outside managedPaths — the repo's live data and its
    // generated README — is exactly what it was before, not the
    // template's placeholder.
    assert.equal(
      readFileSync(join(checkDir, 'access', 'live-role.json'), 'utf8'),
      '{"id":"role-live","name":"Live Role"}\n',
    );
    assert.equal(
      readFileSync(join(checkDir, 'README.md'), 'utf8'),
      '# Live generated README\nhistory here\n',
    );

    rmSync(checkDir, { recursive: true, force: true });
  });

  it('is a no-op commit when the managed paths already match', () => {
    // First push lands the fix.
    pushManagedSubset({
      repo: 'ignored/ignored', sourceDir, managedPaths: MANAGED_PATHS,
      message: 'fix(amcm): first', token: 't', cloneUrl: bareDir,
    });
    git(workDir, ['fetch', 'origin', 'main']);
    const headAfterFirst = git(workDir, ['log', '--oneline', '-1', 'origin/main']).trim();

    // Second push of the identical source should not create an empty commit.
    pushManagedSubset({
      repo: 'ignored/ignored', sourceDir, managedPaths: MANAGED_PATHS,
      message: 'fix(amcm): second', token: 't', cloneUrl: bareDir,
    });
    git(workDir, ['fetch', 'origin', 'main']);
    const headAfterSecond = git(workDir, ['log', '--oneline', '-1', 'origin/main']).trim();
    assert.equal(headAfterSecond, headAfterFirst);
  });
});
