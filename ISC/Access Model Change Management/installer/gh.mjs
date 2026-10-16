import { execFileSync, spawnSync } from 'node:child_process';

export function gh(args, { input, json = false, cwd } = {}) {
  const result = spawnSync('gh', args, {
    encoding: 'utf8',
    input,
    cwd,
    env: process.env,
  });
  if (result.status !== 0) {
    const err = new Error(result.stderr || result.stdout || `gh ${args.join(' ')} failed`);
    err.stderr = result.stderr;
    err.stdout = result.stdout;
    err.status = result.status;
    throw err;
  }
  const out = (result.stdout || '').trim();
  if (json) {
    return out ? JSON.parse(out) : null;
  }
  return out;
}

export function ghOk(args) {
  try {
    gh(args);
    return true;
  } catch {
    return false;
  }
}

export function ensureGhAuth() {
  try {
    return gh(['auth', 'status']);
  } catch (err) {
    throw new Error('gh is not authenticated. Run `gh auth login` first.\n' + (err.stderr || ''));
  }
}

export function currentUser() {
  return gh(['api', 'user', '--jq', '.login']);
}

/**
 * Best-effort preflight: can the current user create repos under `owner`?
 * Returns { ok: true } | { ok: false, reason } | { ok: null, reason } when unknown.
 */
export function checkRepoCreateAccess(owner) {
  const login = currentUser();
  if (owner === login) {
    return { ok: true, login };
  }
  try {
    const membership = gh(
      ['api', `user/memberships/orgs/${owner}`, '--jq', '{state:.state,role:.role}'],
      { json: true },
    );
    if (!membership || membership.state !== 'active') {
      return {
        ok: false,
        login,
        reason: `You are not an active member of the ${owner} organization.`,
      };
    }
    let membersCanCreate = true;
    let membersCanCreatePrivate = true;
    try {
      const org = gh(
        [
          'api',
          `orgs/${owner}`,
          '--jq',
          '{members_can_create_repositories,members_can_create_private_repositories}',
        ],
        { json: true },
      );
      if (org && typeof org.members_can_create_repositories === 'boolean') {
        membersCanCreate = org.members_can_create_repositories;
      }
      if (org && typeof org.members_can_create_private_repositories === 'boolean') {
        membersCanCreatePrivate = org.members_can_create_private_repositories;
      }
    } catch {
      // Org settings may require admin; membership alone is not enough to know.
      return {
        ok: null,
        login,
        reason:
          `You are a ${membership.role} of ${owner}, but create-repository permissions could not be verified.`,
      };
    }
    if (membership.role === 'admin') {
      return { ok: true, login };
    }
    if (!membersCanCreate || !membersCanCreatePrivate) {
      return {
        ok: false,
        login,
        reason:
          `Organization ${owner} does not allow members to create private repositories `
          + `(role: ${membership.role}). Ask an org owner, or create the repo yourself and re-run.`,
      };
    }
    return { ok: true, login };
  } catch {
    return {
      ok: null,
      login,
      reason: `Could not verify membership in ${owner}. Create may still fail.`,
    };
  }
}

export function createRepo({ owner, name, description, privateRepo = true }) {
  const full = `${owner}/${name}`;
  if (ghOk(['repo', 'view', full])) {
    return { created: false, full };
  }
  const args = [
    'repo', 'create', full,
    privateRepo ? '--private' : '--public',
    '--description', description,
    '--disable-wiki',
  ];
  try {
    gh(args);
  } catch (err) {
    const detail = (err.stderr || err.message || '').trim();
    const wrapped = new Error(detail || `Failed to create ${full}`);
    wrapped.code = 'REPO_CREATE_FAILED';
    wrapped.owner = owner;
    wrapped.name = name;
    wrapped.full = full;
    wrapped.cause = err;
    throw wrapped;
  }
  return { created: true, full };
}

export function setSecret(repo, name, value) {
  gh(['secret', 'set', name, '--repo', repo, '--body', value]);
}

export function enableAutoMerge(repo) {
  try {
    gh(['api', `-X`, 'PATCH', `repos/${repo}`, '-f', 'allow_auto_merge=true']);
  } catch {
    // may already be enabled or org-restricted
  }
}

/**
 * GitHub Free refuses rulesets on private repositories with HTTP 403 and
 * "Upgrade to GitHub Pro or make this repository public".
 */
export function rulesetUnavailable(err) {
  const text = `${err?.stderr || ''} ${err?.message || ''}`;
  return /Upgrade to GitHub Pro or make this repository public/i.test(text);
}

/**
 * Apply a ruleset that requires PRs + required checks, with the GitHub App as bypass.
 * Returns { skipped: true, reason } when the plan does not include rulesets.
 */
export function applyMainRuleset(repo, { appSlug, requiredChecks }) {
  let existing;
  try {
    existing = gh(['api', `repos/${repo}/rulesets`], { json: true }) || [];
  } catch (err) {
    if (rulesetUnavailable(err)) {
      return {
        skipped: true,
        reason: 'GitHub does not allow rulesets on this private repository. Upgrade the plan or make the repository public.',
      };
    }
    throw err;
  }
  const name = 'amcm-main-protection';
  const found = existing.find((r) => r.name === name);

  const body = {
    name,
    target: 'branch',
    enforcement: 'active',
    conditions: {
      ref_name: {
        include: ['refs/heads/main'],
        exclude: [],
      },
    },
    bypass_actors: appSlug
      ? [
          {
            actor_id: null, // filled below when we know the app installation id
            actor_type: 'Integration',
            bypass_mode: 'always',
          },
        ]
      : [],
    rules: [
      {
        type: 'pull_request',
        parameters: {
          require_code_owner_review: false,
          require_last_push_approval: false,
          dismiss_stale_reviews_on_push: false,
          required_approving_review_count: 0,
          required_review_thread_resolution: false,
        },
      },
      {
        type: 'required_status_checks',
        parameters: {
          strict_required_status_checks_policy: false,
          required_status_checks: requiredChecks.map((context) => ({ context })),
        },
      },
      { type: 'deletion' },
      { type: 'non_fast_forward' },
    ],
  };

  // Resolve Integration actor id from installed apps if possible
  try {
    const installs = gh(['api', `repos/${repo}/installation`], { json: true });
    if (installs?.id && body.bypass_actors[0]) {
      // For rulesets, Integration actor_id is the App database id, not installation id.
      // Prefer listing apps; fall back to omitting bypass and documenting manual step.
      const apps = gh(['api', 'apps/installations'], { json: true }) || [];
      const match = apps.find((a) => a.app_slug === appSlug || a.app_id);
      if (match?.app_id) {
        body.bypass_actors[0].actor_id = match.app_id;
      } else if (installs.app_id) {
        body.bypass_actors[0].actor_id = installs.app_id;
      }
    }
  } catch {
    body.bypass_actors = [];
  }

  if (body.bypass_actors[0] && !body.bypass_actors[0].actor_id) {
    body.bypass_actors = [];
  }

  const payload = JSON.stringify(body);
  try {
    if (found) {
      gh(['api', `-X`, 'PUT', `repos/${repo}/rulesets/${found.id}`, '--input', '-'], {
        input: payload,
      });
      return { updated: true, id: found.id };
    }
    const created = gh(['api', `-X`, 'POST', `repos/${repo}/rulesets`, '--input', '-'], {
      input: payload,
      json: true,
    });
    return { updated: false, id: created?.id };
  } catch (err) {
    if (rulesetUnavailable(err)) {
      return {
        skipped: true,
        reason: 'GitHub does not allow rulesets on this private repository. Upgrade the plan or make the repository public.',
      };
    }
    throw err;
  }
}

export function pushDirectory({ repo, branch = 'main', sourceDir, message }) {
  // Use a temp clone approach via gh and git
  const tmp = execFileSync('mktemp', ['-d'], { encoding: 'utf8' }).trim();
  try {
    gh(['repo', 'clone', repo, tmp, '--', '--depth', '1']);
    execFileSync('bash', ['-lc', `
      set -euo pipefail
      SRC=${JSON.stringify(sourceDir)}
      DST=${JSON.stringify(tmp)}
      rsync -a --delete --exclude .git --exclude node_modules "$SRC"/ "$DST"/
      cd "$DST"
      git config user.name "amcm-installer"
      git config user.email "amcm-installer@local"
      git checkout -B ${branch}
      git add -A
      if git diff --cached --quiet; then
        echo "No changes to push"
      else
        git commit -m ${JSON.stringify(message)}
        git push -u origin ${branch}
      fi
    `], { stdio: 'inherit' });
  } finally {
    execFileSync('rm', ['-rf', tmp]);
  }
}
