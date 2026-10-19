import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { dirname, join } from 'node:path';
import yaml from 'js-yaml';

/**
 * Copy template into dest, then apply config.yaml and string replacements.
 */
export function materializeTemplate({
  templateDir,
  destDir,
  replacements,
  config,
}) {
  mkdirSync(destDir, { recursive: true });
  copyRecursive(templateDir, destDir, {
    skip: new Set(['node_modules', '.git']),
  });

  // Render config.yaml from values (not mustache in place — write authoritative file)
  writeFileSync(join(destDir, 'config.yaml'), yaml.dump(config, { lineWidth: 120 }), 'utf8');

  // Replace placeholders in workflow YAML cron if needed
  const backupWf = join(destDir, '.github/workflows/backup.yml');
  if (existsSync(backupWf) && config.backup?.schedule) {
    let text = readFileSync(backupWf, 'utf8');
    text = text.replace(/cron: "0 2 \* \* \*"/, `cron: "${config.backup.schedule}"`);
    writeFileSync(backupWf, text, 'utf8');
  }

  // Generic string replacements across text files
  walkAndReplace(destDir, replacements, {
    skip: new Set(['node_modules', '.git']),
  });

  return destDir;
}

function copyRecursive(src, dest, { skip }) {
  mkdirSync(dest, { recursive: true });
  for (const entry of readdirSync(src)) {
    if (skip.has(entry)) continue;
    const from = join(src, entry);
    const to = join(dest, entry);
    const st = statSync(from);
    if (st.isDirectory()) copyRecursive(from, to, { skip });
    else cpSync(from, to);
  }
}

function walkAndReplace(dir, replacements, { skip }) {
  for (const entry of readdirSync(dir)) {
    if (skip.has(entry)) continue;
    const full = join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) {
      walkAndReplace(full, replacements, { skip });
      continue;
    }
    if (!/\.(ya?ml|yml|md|json|mjs|example)$/i.test(entry)) continue;
    let text = readFileSync(full, 'utf8');
    let changed = false;
    for (const [key, value] of Object.entries(replacements)) {
      if (text.includes(key)) {
        text = text.split(key).join(String(value));
        changed = true;
      }
    }
    if (changed) writeFileSync(full, text, 'utf8');
  }
}

export function buildConfig({
  tenantName,
  tenantApiUrl,
  tenantUiUrl,
  entitlementSources,
  governanceGroupId,
  governanceGroupName,
  githubOwner,
  githubRepo,
  backupSchedule = '0 2 * * *',
  approvalTimeoutDays = 3,
}) {
  return {
    tenant: {
      name: tenantName,
      apiUrl: tenantApiUrl,
      uiUrl: tenantUiUrl,
    },
    entitlementSources: entitlementSources.map((s) => ({
      name: s.name,
      id: s.id,
    })),
    backup: {
      schedule: backupSchedule,
    },
    approval: {
      governanceGroupId,
      governanceGroupName,
      timeoutDays: Number(approvalTimeoutDays) || 3,
    },
    github: {
      owner: githubOwner,
      repo: githubRepo,
    },
  };
}

/**
 * GitHub App manifest for per-repo install.
 * Posted via a local HTML form; GitHub redirects with a code we exchange for credentials.
 */
export function githubAppManifest({ name, description, url, callbackUrl }) {
  return {
    name,
    url,
    hook_attributes: {
      url: callbackUrl || url,
      active: false,
    },
    redirect_url: callbackUrl || url,
    description,
    public: false,
    default_permissions: {
      contents: 'write',
      issues: 'write',
      pull_requests: 'write',
      checks: 'write',
      statuses: 'write',
      workflows: 'write',
      actions: 'write',
      metadata: 'read',
    },
    default_events: [],
  };
}
