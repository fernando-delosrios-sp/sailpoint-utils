#!/usr/bin/env node
/**
 * Access Model Change Management installer.
 * Creates/updates a GitHub repo from template/, wires secrets and rules,
 * and enables the ISC tenant (workflow, external trigger).
 */
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import minimist from 'minimist';
import { createPrompter } from './prompt.mjs';
import { InstallerIsc, deriveApiUrl, deriveTenantName, normalizeBaseUrl } from './isc.mjs';
import {
  applyMainRuleset,
  checkRepoCreateAccess,
  createRepo,
  currentUser,
  enableAutoMerge,
  ensureGhAuth,
  ensureWorkflowsRegistered,
  fetchRepoFile,
  fetchRepoFileMaybe,
  gh,
  ghOk,
  pushDirectory,
  pushManagedSubset,
  setSecret,
} from './gh.mjs';
import { mintInstallationToken } from './github-app.mjs';
import { buildConfig, materializeTemplate } from './render.mjs';
import yaml from 'js-yaml';

// Paths `update` is allowed to touch in an already-deployed repo. Everything
// else — access/, changes/, README.md, config.yaml, .env.example — is the
// repo's own runtime data or already-correct deployment config and must
// never be clobbered by a code update. Keep this in sync with what
// materializeTemplate actually writes under template/.
const UPDATE_MANAGED_PATHS = [
  '.github/workflows',
  'scripts',
  'schemas',
  'package.json',
  'package-lock.json',
];

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const TEMPLATE = join(ROOT, 'template');
const ISC_DIR = join(ROOT, 'isc');

function log(msg) {
  process.stdout.write(`${msg}\n`);
}

function banner() {
  log(`
╔══════════════════════════════════════════════════════════╗
║  Access Model Change Management — installer           ║
║  GitHub-centric governance of ISC access items           ║
╚══════════════════════════════════════════════════════════╝
`);
}

async function gatherAnswers(prompt, argv) {
  const login = currentUser();
  log(`Authenticated to GitHub as ${login}`);

  const tenantUiUrl = normalizeBaseUrl(
    argv['tenant-url']
      || await prompt.ask('ISC tenant URL (e.g. https://tenant.identitynow.com)'),
  );
  const tenantApiUrl = normalizeBaseUrl(
    argv['api-url']
      || await prompt.ask('ISC API base URL', { defaultValue: deriveApiUrl(tenantUiUrl) }),
  );
  const tenantName = argv['tenant-name']
    || await prompt.ask('Short tenant name', { defaultValue: deriveTenantName(tenantUiUrl) });

  log('\nService identity credentials (client credentials of a dedicated service identity PAT client preferred).');
  const clientId = argv['client-id'] || await prompt.ask('ISC client id');
  const clientSecret = argv['client-secret'] || await prompt.ask('ISC client secret', { secret: true });

  const isc = InstallerIsc.fromAnswers({ tenantApiUrl, clientId, clientSecret });
  log('Validating ISC credentials…');
  await isc.validateCredentials();
  const ownerIdentity = await isc.resolvePatOwner();
  const ownerId = ownerIdentity.id;
  const ownerName = ownerIdentity.name;
  // ISC validates a workflow owner's name against the identity's alias, not its display name.
  const ownerAlias = ownerIdentity.alias;
  log(`Credentials OK. Artefact owner: ${ownerName} (${ownerId})`);

  const sources = await isc.listSources();
  const selectedSources = await prompt.multiChoose(
    'Select entitlement sources to track (metadata update only):',
    sources.map((s) => ({ id: s.id, name: s.name, label: `${s.name} (${s.id})` })),
    { defaultAll: true },
  );

  const groups = await isc.listGovernanceGroups();
  if (!groups.length) {
    throw new Error('No governance groups found in the tenant. Create one, then re-run.');
  }
  const gov = await prompt.choose(
    'Governance group (approves changes, restores, and drift sync):',
    groups.map((g) => ({ id: g.id, name: g.name, label: `${g.name} (${g.id})` })),
  );

  const ghOwner = argv['gh-owner']
    || await prompt.ask('GitHub owner (user or org)', { defaultValue: login });
  const ghRepo = argv['gh-repo']
    || await prompt.ask('GitHub repository name', {
      defaultValue: `${tenantName}-access-lifecycle`,
    });

  const backupSchedule = argv.schedule
    || await prompt.ask('Daily backup cron (UTC)', { defaultValue: '0 2 * * *' });

  const approvalTimeoutDays = argv['approval-timeout']
    || await prompt.ask('Approval timeout in days (expires the request when nobody acts)', {
      defaultValue: '3',
    });

  return {
    tenantApiUrl,
    tenantName,
    tenantUiUrl,
    clientId,
    clientSecret,
    selectedSources,
    gov,
    ownerId,
    ownerName,
    ownerAlias,
    ghOwner,
    ghRepo,
    backupSchedule,
    approvalTimeoutDays,
    // Asked after the repo exists — fine-grained PATs must target a real repository.
    dispatchToken: argv['dispatch-token'] || null,
    isc,
  };
}

function openUrl(url) {
  const opener = process.platform === 'darwin'
    ? 'open'
    : process.platform === 'win32'
      ? 'cmd'
      : 'xdg-open';
  const args = process.platform === 'win32' ? ['/c', 'start', '', url] : [url];
  try {
    spawnSync(opener, args, { stdio: 'ignore' });
  } catch {
    log(`Open this URL manually:\n  ${url}`);
  }
}

/** Strip drag-and-drop / shell quoting from a filesystem path. */
function normalizeFsPath(input) {
  let p = String(input || '').trim();
  // macOS Terminal drag-and-drop wraps the path in single quotes.
  if (
    (p.startsWith("'") && p.endsWith("'"))
    || (p.startsWith('"') && p.endsWith('"'))
  ) {
    p = p.slice(1, -1);
  }
  // Escaped spaces from some terminals: /path/with\ spaces → /path/with spaces
  p = p.replace(/\\ /g, ' ');
  return p.trim();
}

/**
 * Credential the ISC workflow uses for repository_dispatch after an approval decision.
 * Prefer a fine-grained PAT (least privilege). GitHub cannot create PATs via API/gh;
 * the gh login token is a convenience fallback with broader scopes.
 */
async function askDispatchToken(prompt, { ghOwner, ghRepo, existing }) {
  if (existing) return existing;

  const login = currentUser();
  const isOrg = ghOwner !== login;
  const repoFull = `${ghOwner}/${ghRepo}`;
  const settingsUrl = 'https://github.com/settings/personal-access-tokens/new';

  const prefill = new URL(settingsUrl);
  prefill.searchParams.set('name', `amcm-dispatch-${ghRepo}`.slice(0, 40));
  prefill.searchParams.set(
    'description',
    `ISC→GitHub repository_dispatch for ${repoFull} (Access Model Change Management)`,
  );
  prefill.searchParams.set('target_name', ghOwner);
  prefill.searchParams.set('contents', 'write');

  const ownerHint = isOrg
    ? `Resource owner → "${ghOwner}" (org, not your personal account).
       If missing: org owner must allow fine-grained PATs.
       Org approval may be required after Generate.`
    : `Resource owner → your personal account (${login}).`;

  log(`
GitHub dispatch credential
--------------------------
ISC posts approval decisions back to GitHub via repository_dispatch.
Prefer a fine-grained PAT scoped to ${repoFull} only.
Required: Contents = Read and write (Metadata Read-only is automatic).
Leave Organizations at (0). Do not use Tokens (classic).

On the form (opened in your browser when you choose the PAT option):
  · Token name: amcm-dispatch-${ghRepo}
  · Expiration: e.g. 90 days
  · ${ownerHint}
  · Repository access → Only select repositories → ${ghRepo}
  · Permissions → Repositories → Contents: Read and write

Broader alternative: reuse your current gh login token for ${login}
(convenient, not least privilege).
`);

  const choice = await prompt.choose(
    'How should ISC authenticate to GitHub?',
    [
      {
        id: 'fine-grained',
        label: `Fine-grained PAT for ${repoFull} (least privilege) (Recommended)`,
      },
      {
        id: 'gh-token',
        label: `Use current gh login token for ${login} (broader scope, automated)`,
      },
    ],
  );

  if (choice.id === 'gh-token') {
    const token = gh(['auth', 'token']);
    if (!token) throw new Error('gh auth token returned empty — run `gh auth login`');
    log('Using gh login token for ISC callbacks. Rotate to a fine-grained PAT when you can.');
    return token;
  }

  log(`Opening PAT form…`);
  if (isOrg) {
    log(`Confirm Resource owner is ${ghOwner} (org), then Generate.`);
  } else {
    log(`Confirm repository → ${ghRepo}, then Generate.`);
  }
  openUrl(prefill.toString());
  return prompt.ask('Paste the fine-grained PAT', { secret: true });
}

function explainRepoCreateFailure(err, { ghOwner, login }) {
  const detail = (err.message || String(err)).trim();
  const cannotCreate = /cannot create a repository for/i.test(detail);
  const lines = [
    `Could not create ${err.full || `${ghOwner}/…`}.`,
    detail ? `GitHub said: ${detail}` : null,
  ];
  if (cannotCreate) {
    lines.push(
      `${login} does not have permission to create repositories under ${ghOwner}.`,
      'Typical fixes: ask an org owner to grant create permission, create the repo in the UI, or install under your personal account.',
    );
  }
  return lines.filter(Boolean).join('\n');
}

/**
 * Create the target repo, or recover when the login cannot create under the owner.
 * Returns { ghOwner, ghRepo, created, full }.
 */
async function ensureRepository(prompt, {
  ghOwner,
  ghRepo,
  description,
  login,
}) {
  for (;;) {
    const full = `${ghOwner}/${ghRepo}`;
    const access = checkRepoCreateAccess(ghOwner);
    if (access.ok === false) {
      log(`\nPreflight: ${access.reason}`);
    } else if (access.ok === null) {
      log(`\nPreflight: ${access.reason}`);
    }

    try {
      log(`\nCreating repository ${full} (no-op if it exists)…`);
      const repo = createRepo({
        owner: ghOwner,
        name: ghRepo,
        description,
        privateRepo: true,
      });
      log(repo.created ? 'Repository created.' : 'Repository already exists — updating.');
      return { ghOwner, ghRepo, created: repo.created, full: repo.full };
    } catch (err) {
      log(`\n${explainRepoCreateFailure(err, { ghOwner, login })}`);

      const choice = await prompt.choose('How do you want to recover?', [
        {
          id: 'owner',
          label: `Create under a different owner (your login: ${login})`,
        },
        { id: 'name', label: 'Use a different repository name under the same owner' },
        {
          id: 'existing',
          label: 'Point at an existing repository (must already exist and be writable)',
        },
        {
          id: 'browser',
          label: 'Open the GitHub “new repository” page, create it there, then retry',
        },
        { id: 'retry', label: 'Retry with the same owner/name (after permission was granted)' },
        { id: 'abort', label: 'Abort install' },
      ]);

      if (choice.id === 'abort') {
        const abort = new Error('Install aborted: could not create GitHub repository.');
        abort.code = 'ABORTED';
        throw abort;
      }
      if (choice.id === 'owner') {
        ghOwner = await prompt.ask('GitHub owner (user or org)', { defaultValue: login });
        continue;
      }
      if (choice.id === 'name') {
        ghRepo = await prompt.ask('GitHub repository name', { defaultValue: ghRepo });
        continue;
      }
      if (choice.id === 'existing') {
        ghOwner = await prompt.ask('GitHub owner', { defaultValue: ghOwner });
        ghRepo = await prompt.ask('Existing repository name', { defaultValue: ghRepo });
        const existing = `${ghOwner}/${ghRepo}`;
        if (!ghOk(['repo', 'view', existing])) {
          log(`Repository ${existing} was not found or is not accessible with this login.`);
          continue;
        }
        log(`Using existing repository ${existing}.`);
        return { ghOwner, ghRepo, created: false, full: existing };
      }
      if (choice.id === 'browser') {
        const url = ghOwner === login
          ? `https://github.com/new?name=${encodeURIComponent(ghRepo)}`
          : `https://github.com/organizations/${encodeURIComponent(ghOwner)}/repositories/new`
            + `?name=${encodeURIComponent(ghRepo)}`;
        log(`Opening: ${url}`);
        openUrl(url);
        await prompt.ask(
          'Press Enter after the repository exists (or you gained create permission)',
          { defaultValue: '' },
        );
        continue;
      }
      // retry — loop again with same owner/name
    }
  }
}

async function createOrGuideGitHubApp(prompt, { ghOwner, ghRepo }) {
  const login = currentUser();
  const isOrg = ghOwner !== login;
  const createUrl = isOrg
    ? `https://github.com/organizations/${ghOwner}/settings/apps/new`
    : `https://github.com/settings/apps/new`;
  const proposedName = `amcm-${ghRepo}`.slice(0, 34);
  const homepageUrl = `https://github.com/${ghOwner}/${ghRepo}`;
  const description = `Access Model Change Management bot for ${ghOwner}/${ghRepo}`;

  log(`
GitHub App (not another PAT)
----------------------------
The fine-grained PAT you just provided is only for ISC → GitHub callbacks.
This next step is a different credential: a GitHub App used by Actions to
commit known-good tags / drift to main and as the sole ruleset bypass actor.

Opening in your browser:
  ${createUrl}

Fill the "Register new GitHub App" form as follows:

  Basic information
    GitHub App name*  → ${proposedName}
    Description       → ${description}
    Homepage URL*     → ${homepageUrl}
                        (full URL including https:// — not github.com/… alone)

  Identifying and authorizing users
    Leave Redirect URIs empty
    Leave the checkboxes as they are (Expire user authorization tokens can stay on)

  Post installation
    Leave Setup URL empty; leave Redirect on update unchecked

  Webhook
    Active            → uncheck (we do not need webhooks)
                        (if Active stays on, Webhook URL becomes required)

  Repository permissions (top to bottom, as on the form)
    Actions            → Read and write
    Checks             → Read and write
    Commit statuses    → Read and write
    Contents           → Read and write
    Issues             → Read and write
    Metadata           → Read-only (usually fixed)
    Pull requests      → Read and write
    Workflows          → Read and write

  Organization permissions
    Leave all No access

  Where can this GitHub App be installed?
    → Only on this account

  Click Create GitHub App
  Then: Private keys → Generate a private key → save the .pem
  Stay on the app page. After the App ID, slug, and .pem path, the
  installer opens the page that installs the app on ${ghOwner}/${ghRepo}.
`);

  log(`Opening: ${createUrl}`);
  openUrl(createUrl);

  const appId = await prompt.ask(
    'GitHub App ID (numeric under About — not Client ID Iv23…, not a PAT)',
  );
  if (!/^\d+$/.test(String(appId).trim())) {
    log(`Warning: "${appId}" does not look like a numeric App ID. Check About → App ID on the App page.`);
  }
  const appSlug = await prompt.ask('GitHub App slug (name in the App URL)', {
    defaultValue: proposedName,
  });

  let privateKey;
  for (;;) {
    privateKey = normalizeFsPath(
      await prompt.ask(
        'Path to the App private key .pem file (drag-and-drop is OK)',
      ),
    );
    if (existsSync(privateKey)) break;
    log(`Private key not found: ${privateKey}`);
    log('Tip: macOS drag-and-drop adds quotes — those are stripped automatically; check the path.');
  }
  const pem = readFileSync(privateKey, 'utf8');

  const installUrl = `https://github.com/apps/${encodeURIComponent(appSlug.trim())}/installations/new`;
  const settingsInstallUrl = isOrg
    ? `https://github.com/organizations/${ghOwner}/settings/apps/${appSlug.trim()}/installations`
    : `https://github.com/settings/apps/${appSlug.trim()}/installations`;

  log(`
Install the app on ${ghOwner}/${ghRepo}
${'─'.repeat(`Install the app on ${ghOwner}/${ghRepo}`.length)}
Creating the app does not add it to the repository.

  1. Left sidebar on the app page → Install App
     Or open: ${installUrl}
  2. Next to ${ghOwner}, click Install
     If the button says Request, an organization owner must approve it first.
  3. Repository access → Only select repositories
  4. Select repository → ${ghRepo}
     Leave every other repository unselected.
  5. Click Install
  6. Back under Install App, ${ghRepo} is listed on ${ghOwner}

To change the repository later: ${settingsInstallUrl}
`);
  log(`Opening: ${installUrl}`);
  openUrl(installUrl);
  await prompt.ask('Press Enter once the app is installed on the repository');

  return { appId, appSlug, privateKeyPem: pem };
}

async function provisionIsc(answers) {
  const { isc } = answers;

  const replacements = {
    YOUR_GOVERNANCE_GROUP_ID: answers.gov.id,
    'YOUR_GITHUB_OWNER/YOUR_GITHUB_REPO': `${answers.ghOwner}/${answers.ghRepo}`,
    // Sent as a literal Authorization header, not basicAuthPassword — ISC
    // only accepts a $.secrets.<id> reference there, which the workflow
    // write API can't set (see isc/README.md).
    YOUR_GITHUB_DISPATCH_TOKEN: `Bearer ${answers.dispatchToken}`,
    YOUR_OWNER_IDENTITY_ID: answers.ownerId,
    YOUR_OWNER_IDENTITY_NAME: answers.ownerAlias,
    // Quoted so the template stays valid JSON; ISC wants a number here.
    '"YOUR_APPROVAL_TIMEOUT_DAYS"': String(Number(answers.approvalTimeoutDays) || 3),
  };

  const approvalWf = await isc.upsertWorkflow(
    join(ISC_DIR, 'Workflow - AMCM Approval.json'),
    replacements,
  );

  const approvalTrigger = await isc.createExternalTriggerClient(approvalWf.id);
  await isc.enableWorkflow(approvalWf.id);

  return { approvalWf, approvalTrigger };
}

/**
 * Push code fixes (workflows, scripts, schemas, package files) from
 * template/ into an already-deployed repo, authenticated as the GitHub
 * App rather than the operator — the only credential the repo's own
 * `amcm-main-protection` ruleset lets write straight to `main`.
 *
 * Deliberately does none of install's tenant/governance/source Q&A: the
 * deployed repo's `config.yaml` already has that, and `update` must not
 * require — or risk — re-answering it. It only reads config.yaml back to
 * refill the same `{{PLACEHOLDER}}` tokens install baked into the
 * workflow files, so the pushed workflows still point at the right
 * tenant and repo.
 */
async function cmdUpdate(prompt, argv) {
  const ghOwner = argv['gh-owner'] || (argv.repo || '').split('/')[0];
  const ghRepo = argv['gh-repo'] || (argv.repo || '').split('/')[1];
  if (!ghOwner || !ghRepo) {
    throw new Error('update requires --repo OWNER/REPO (or --gh-owner and --gh-repo)');
  }
  const repoFull = `${ghOwner}/${ghRepo}`;

  log(`Checking ${repoFull}…`);
  if (!ghOk(['repo', 'view', repoFull])) {
    throw new Error(`${repoFull} was not found, or this login cannot see it. Run \`gh auth status\` and check the name.`);
  }

  log('Reading the deployed config.yaml (tenant, governance group, owner/repo)…');
  const existingConfig = yaml.load(fetchRepoFile(repoFull, 'config.yaml'));
  if (!existingConfig?.tenant?.apiUrl) {
    throw new Error(`${repoFull}/config.yaml did not parse into the expected shape. Is this an AMCM repo installed by this tool?`);
  }

  const appId = argv['app-id'] || await prompt.ask('GitHub App ID (the one already installed on this repo)');
  const keyPath = normalizeFsPath(
    argv['app-private-key'] || await prompt.ask('Path to the App private key .pem file'),
  );
  if (!existsSync(keyPath)) {
    throw new Error(`Private key not found: ${keyPath}`);
  }
  const privateKeyPem = readFileSync(keyPath, 'utf8');

  const staging = mkdtempSync(join(tmpdir(), 'amcm-update-'));
  try {
    materializeTemplate({
      templateDir: TEMPLATE,
      destDir: staging,
      config: existingConfig,
      replacements: {
        '{{TENANT_NAME}}': existingConfig.tenant.name,
        '{{TENANT_API_URL}}': existingConfig.tenant.apiUrl,
        '{{TENANT_UI_URL}}': existingConfig.tenant.uiUrl,
        '{{GOVERNANCE_GROUP_ID}}': existingConfig.approval.governanceGroupId,
        '{{GOVERNANCE_GROUP_NAME}}': existingConfig.approval.governanceGroupName,
        '{{GITHUB_OWNER}}': existingConfig.github.owner,
        '{{GITHUB_REPO}}': existingConfig.github.repo,
      },
    });

    log(`
About to push the managed subset of template/ to ${repoFull}@main:
${UPDATE_MANAGED_PATHS.map((p) => `  - ${p}`).join('\n')}

Not touched: access/, changes/, README.md, config.yaml, .env.example.
`);
    if (!argv.yes) {
      const choice = await prompt.choose('Proceed?', [
        { id: 'yes', label: 'Yes, push the update' },
        { id: 'no', label: 'No, abort' },
      ]);
      if (choice.id !== 'yes') {
        log('Aborted — nothing was pushed.');
        return;
      }
    }

    log('Minting a GitHub App installation token…');
    const { token } = await mintInstallationToken({
      appId, privateKeyPem, owner: ghOwner, repo: ghRepo,
    });

    log('Pushing update…');
    pushManagedSubset({
      repo: repoFull,
      sourceDir: staging,
      managedPaths: UPDATE_MANAGED_PATHS,
      message: argv.message || 'fix(amcm): update deployed template',
      token,
    });

    log(`\nDone. https://github.com/${repoFull}/commits/main`);
  } finally {
    rmSync(staging, { recursive: true, force: true });
  }
}

async function main() {
  const argv = minimist(process.argv.slice(2), {
    boolean: ['yes', 'help', 'skip-app', 'skip-backup', 'force-reinstall-data'],
  });
  const command = argv._[0] || 'install';

  if (argv.help && command === 'update') {
    log(`Usage: node installer/cli.mjs update --repo OWNER/REPO [options]

Pushes template/ fixes (workflows, scripts, schemas, package files) into an
already-deployed repo, without touching access/, changes/, README.md, or
config.yaml. Leaves the ISC tenant and secrets exactly as they are.

Options:
  --repo OWNER/REPO     Target repo (or --gh-owner / --gh-repo separately)
  --app-id ID           GitHub App ID already installed on the repo
  --app-private-key PEM Path to that App's private key
  --message MSG         Commit message (default: "fix(amcm): update deployed template")
  --yes                 Skip the confirmation prompt
`);
    process.exit(0);
  }
  if (argv.help) {
    log(`Usage: node installer/cli.mjs [install] [options]
       node installer/cli.mjs update --repo OWNER/REPO [options]

install options:
  --tenant-url URL     ISC tenant (UI) URL
  --api-url URL        ISC API base (default: derived from tenant URL)
  --tenant-name NAME
  --client-id ID
  --client-secret SECRET
  --gh-owner OWNER
  --gh-repo REPO
  --dispatch-token TOKEN
  --schedule CRON
  --skip-app
  --skip-backup
  --force-reinstall-data  Allow overwriting an already-provisioned repo's
                           access/, changes/, and README.md (destructive)

Run \`node installer/cli.mjs update --help\` for the update command.
`);
    process.exit(0);
  }

  if (command === 'update') {
    banner();
    ensureGhAuth();
    const prompt = await createPrompter();
    try {
      await cmdUpdate(prompt, argv);
    } finally {
      prompt.close();
    }
    return;
  }
  if (command !== 'install') {
    throw new Error(`Unknown command "${command}". Expected "install" or "update".`);
  }

  banner();
  ensureGhAuth();
  const prompt = await createPrompter();

  try {
    const answers = await gatherAnswers(prompt, argv);
    const login = currentUser();

    const ensured = await ensureRepository(prompt, {
      ghOwner: answers.ghOwner,
      ghRepo: answers.ghRepo,
      description: `Access Model Change Management for ${answers.tenantName}`,
      login,
    });
    answers.ghOwner = ensured.ghOwner;
    answers.ghRepo = ensured.ghRepo;
    const repoFull = ensured.full;

    if (!ensured.created && !argv['force-reinstall-data']) {
      // ensureRepository found this repo already existing. If it is already
      // a provisioned AMCM repo (has a real config.yaml), the push below —
      // a wholesale rsync --delete of a freshly materialized template, whose
      // access/, changes/, and README.md are empty placeholders — would
      // destroy its live access data and change ledger. Re-running install
      // against a repo that was merely created-but-empty (the "existing
      // repository" recovery path in ensureRepository) is still fine.
      const existing = fetchRepoFileMaybe(repoFull, 'config.yaml');
      let alreadyProvisioned = false;
      try {
        alreadyProvisioned = !!yaml.load(existing || '')?.tenant?.apiUrl;
      } catch {
        alreadyProvisioned = false;
      }
      if (alreadyProvisioned) {
        throw new Error(
          `${repoFull} is already a provisioned Access Model Change Management repo.\n`
          + 'Install does not touch it to avoid overwriting access/, changes/, and README.md with empty placeholders.\n'
          + `To push code fixes to it instead, run:\n  node installer/cli.mjs update --repo ${repoFull}\n`
          + 'To force a full data-destroying reinstall anyway, re-run with --force-reinstall-data.',
        );
      }
    }

    const config = buildConfig({
      tenantName: answers.tenantName,
      tenantApiUrl: answers.tenantApiUrl,
      tenantUiUrl: answers.tenantUiUrl,
      entitlementSources: answers.selectedSources,
      governanceGroupId: answers.gov.id,
      governanceGroupName: answers.gov.name,
      githubOwner: answers.ghOwner,
      githubRepo: answers.ghRepo,
      backupSchedule: answers.backupSchedule,
      approvalTimeoutDays: answers.approvalTimeoutDays,
    });

    const staging = mkdtempSync(join(tmpdir(), 'amcm-template-'));
    try {
      materializeTemplate({
        templateDir: TEMPLATE,
        destDir: staging,
        config,
        replacements: {
          '{{TENANT_NAME}}': answers.tenantName,
          '{{TENANT_API_URL}}': answers.tenantApiUrl,
          '{{TENANT_UI_URL}}': answers.tenantUiUrl,
          '{{GOVERNANCE_GROUP_ID}}': answers.gov.id,
          '{{GOVERNANCE_GROUP_NAME}}': answers.gov.name,
          '{{GITHUB_OWNER}}': answers.ghOwner,
          '{{GITHUB_REPO}}': answers.ghRepo,
        },
      });

      // Ensure package-lock exists in staging
      if (!existsSync(join(staging, 'package-lock.json'))
        && existsSync(join(TEMPLATE, 'package-lock.json'))) {
        writeFileSync(
          join(staging, 'package-lock.json'),
          readFileSync(join(TEMPLATE, 'package-lock.json')),
        );
      }

      // Seed README
      writeFileSync(
        join(staging, 'README.md'),
        `# Access Model Change Management\n\nInstalling… run Actions → Backup after secrets are set.\n`,
      );

      log('Pushing template to GitHub…');
      pushDirectory({
        repo: repoFull,
        sourceDir: staging,
        message: 'chore: refresh access model change management template',
      });
      ensureWorkflowsRegistered({ repo: repoFull, sourceDir: staging, log });
    } finally {
      rmSync(staging, { recursive: true, force: true });
    }

    answers.dispatchToken = await askDispatchToken(prompt, {
      ghOwner: answers.ghOwner,
      ghRepo: answers.ghRepo,
      existing: answers.dispatchToken,
    });

    let app = { appId: '', appSlug: '', privateKeyPem: '' };
    if (!argv['skip-app']) {
      app = await createOrGuideGitHubApp(prompt, {
        ghOwner: answers.ghOwner,
        ghRepo: answers.ghRepo,
      });
    } else {
      app.appId = await prompt.ask('Existing GitHub App ID');
      app.appSlug = await prompt.ask('Existing GitHub App slug');
      const keyPath = await prompt.ask('Path to App private key .pem');
      app.privateKeyPem = readFileSync(keyPath, 'utf8');
    }

    log('Setting repository secrets…');
    setSecret(repoFull, 'ISC_TENANT_URL', answers.tenantApiUrl);
    setSecret(repoFull, 'ISC_CLIENT_ID', answers.clientId);
    setSecret(repoFull, 'ISC_CLIENT_SECRET', answers.clientSecret);
    setSecret(repoFull, 'AMCM_APP_ID', app.appId);
    setSecret(repoFull, 'AMCM_APP_PRIVATE_KEY', app.privateKeyPem);

    log('Provisioning ISC workflow…');
    const iscOut = await provisionIsc(answers);
    log(JSON.stringify({
      workflow: { id: iscOut.approvalWf.id, action: iscOut.approvalWf.action },
      trigger: iscOut.approvalTrigger,
    }, null, 2));

    // Actions exchange these client credentials for a token at {tenant}/oauth/token
    // and POST the approval payload to the trigger URL.
    const wfLabel = `"${iscOut.approvalWf.name}" (id ${iscOut.approvalWf.id})`;
    if (iscOut.approvalTrigger?.triggerUrl) {
      setSecret(repoFull, 'ISC_TRIGGER_URL', iscOut.approvalTrigger.triggerUrl);
      setSecret(repoFull, 'ISC_TRIGGER_CLIENT_ID', iscOut.approvalTrigger.clientId);
      setSecret(repoFull, 'ISC_TRIGGER_CLIENT_SECRET', iscOut.approvalTrigger.clientSecret);
    } else {
      log(`\n${iscOut.approvalTrigger?.warning ?? 'External trigger client not provisioned.'}`);
      setSecret(
        repoFull,
        'ISC_TRIGGER_URL',
        await prompt.ask(`External trigger URL for ISC workflow ${wfLabel}`),
      );
      setSecret(
        repoFull,
        'ISC_TRIGGER_CLIENT_ID',
        await prompt.ask('External trigger client id'),
      );
      setSecret(
        repoFull,
        'ISC_TRIGGER_CLIENT_SECRET',
        await prompt.ask('External trigger client secret', { secret: true }),
      );
    }

    log('Enabling auto-merge and applying branch ruleset…');
    enableAutoMerge(repoFull);
    const ruleset = applyMainRuleset(repoFull, {
      appSlug: app.appSlug,
      requiredChecks: ['validate', 'isc-approval'],
    });
    if (ruleset.skipped) {
      log(`Branch ruleset skipped: ${ruleset.reason} Direct pushes to main stay possible.`);
    }

    if (!argv['skip-backup']) {
      log('Dispatching initial backup (takes a baseline when the repository has none)…');
      try {
        gh(['workflow', 'run', 'backup.yml', '--repo', repoFull]);
      } catch (err) {
        log(`Could not dispatch backup yet (workflows may need a moment): ${err.message}`);
      }
    }

    log(`
Done.
  Repository:  https://github.com/${repoFull}
  ISC UI:      ${answers.tenantUiUrl}
  Approval WF: ${iscOut.approvalWf.name} (${iscOut.approvalWf.id})

Next steps:
  1. Confirm the GitHub App is installed on the repo${ruleset.skipped ? '' : ' and listed as a ruleset bypass actor'}.
  2. In ISC, open the "${iscOut.approvalWf.name}" workflow's Configuration step and confirm governance group + dispatch token.
  3. Wait for the first Backup run, then open a test PR under access/.
`);
  } finally {
    prompt.close();
  }
}

main().catch((err) => {
  if (err.code === 'ABORTED') {
    process.stderr.write(`\n${err.message}\n`);
    process.exit(1);
  }
  process.stderr.write(`\nInstaller failed: ${err.stack || err}\n`);
  if (err.body) process.stderr.write(`${JSON.stringify(err.body, null, 2)}\n`);
  process.exit(1);
});
