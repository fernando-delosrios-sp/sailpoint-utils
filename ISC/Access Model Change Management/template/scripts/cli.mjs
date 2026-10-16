#!/usr/bin/env node
import minimist from 'minimist';
import { loadAllItems, loadConfig, writeJson } from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { runBackup, detectDrift } from './backup.mjs';
import { validateRepo } from './validate.mjs';
import { planFromTrees, buildPlan } from './plan.mjs';
import { applyPlan } from './apply.mjs';
import { buildRestorePlan, executeRestore } from './restore.mjs';
import { hashTouchedFiles, hashFullTree } from './diff-hash.mjs';
import { generateReadme } from './readme.mjs';
import {
  buildChangeApprovalPayload,
  buildRestoreApprovalPayload,
  buildDriftApprovalPayload,
  invokeExternalTrigger,
} from './approval.mjs';
import {
  writeChangeEntry,
  writeRestoreEntry,
  writeDriftEntry,
} from './ledger.mjs';
import { buildAppliedTagName, createAppliedTag, isAppliedTag } from './tags.mjs';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT } from './common.mjs';

function print(obj) {
  process.stdout.write(`${JSON.stringify(obj, null, 2)}\n`);
}

function die(msg, code = 1) {
  process.stderr.write(`${msg}\n`);
  process.exit(code);
}

async function loadItemsFromManifest(path) {
  if (!path) return loadAllItems();
  const manifest = JSON.parse(readFileSync(path, 'utf8'));
  return manifest.items ?? manifest;
}

async function main() {
  const argv = minimist(process.argv.slice(2), {
    boolean: ['dry-run', 'json', 'help'],
    string: ['base', 'head', 'tag', 'pr', 'author', 'files', 'out', 'plan', 'drift', 'kind', 'diff-hash', 'message'],
  });
  const [cmd] = argv._;

  if (!cmd || argv.help) {
    process.stdout.write(`Usage: node scripts/cli.mjs <command> [options]

Commands:
  backup              Snapshot ISC into access/
  drift               Detect drift without writing
  validate            Schema + name-reference checks
  plan                Diff base items vs head (default: empty base vs working tree)
  diff-hash           Hash touched files (--files a,b,c)
  apply               Apply a plan JSON (--plan file) or build from trees
  restore             Build/execute full restore from working tree vs live ISC
  request-approval    Post change/restore/drift payload to ISC external trigger
  ledger-change       Write a change ledger entry (JSON on stdin or --plan)
  ledger-restore      Write a restore ledger entry
  ledger-drift        Write a drift ledger entry
  tag-applied         Create isc-applied/* tag after successful apply
  readme              Regenerate README.md from ledger
`);
    process.exit(cmd ? 0 : 1);
  }

  const config = existsSync(join(ROOT, 'config.yaml')) ? loadConfig() : null;

  if (cmd === 'backup') {
    const client = IscClient.fromEnv();
    const result = await runBackup({ client, config, dryRun: argv['dry-run'] });
    print(result);
    return;
  }

  if (cmd === 'drift') {
    const client = IscClient.fromEnv();
    print(await detectDrift({ client, config }));
    return;
  }

  if (cmd === 'validate') {
    const result = validateRepo({ config });
    print(result);
    if (!result.ok) die('Validation failed', 2);
    return;
  }

  if (cmd === 'plan') {
    const headItems = await loadItemsFromManifest(argv.head);
    const baseItems = argv.base ? await loadItemsFromManifest(argv.base) : [];
    const plan = buildPlan({ baseItems, headItems });
    if (argv.out) writeJson(argv.out, plan);
    print(plan);
    return;
  }

  if (cmd === 'diff-hash') {
    const files = String(argv.files ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    if (!files.length) die('--files is required (comma-separated rel paths)');
    print({ diffHash: hashTouchedFiles(files), files });
    return;
  }

  if (cmd === 'apply') {
    const client = IscClient.fromEnv();
    let plan;
    if (argv.plan) {
      plan = JSON.parse(readFileSync(argv.plan, 'utf8'));
    } else {
      const headItems = loadAllItems();
      const baseItems = argv.base ? await loadItemsFromManifest(argv.base) : [];
      plan = buildPlan({ baseItems, headItems });
    }
    const result = await applyPlan({
      plan,
      client,
      dryRun: argv['dry-run'],
    });
    print(result);
    if (!result.ok) die('Apply stopped on failure', 3);
    return;
  }

  if (cmd === 'restore') {
    const client = IscClient.fromEnv();
    const plan = await buildRestorePlan({ client, config });
    if (argv.out) writeJson(argv.out, plan);
    if (argv['dry-run'] || !argv.execute) {
      print({ ...plan, note: 'Pass --execute to apply after approval' });
      return;
    }
    const result = await executeRestore({ plan, client });
    print(result);
    if (!result.ok) die('Restore stopped on failure', 3);
    return;
  }

  if (cmd === 'request-approval') {
    const kind = argv.kind ?? 'change';
    const triggerUrl = process.env.ISC_EXTERNAL_TRIGGER_URL;
    const clientId = process.env.ISC_EXTERNAL_TRIGGER_CLIENT_ID;
    const clientSecret = process.env.ISC_EXTERNAL_TRIGGER_CLIENT_SECRET;
    const tenantUrl = process.env.ISC_TENANT_URL;
    if (!triggerUrl || !clientId || !clientSecret || !tenantUrl) {
      die('ISC_EXTERNAL_TRIGGER_URL, ISC_EXTERNAL_TRIGGER_CLIENT_ID, ISC_EXTERNAL_TRIGGER_CLIENT_SECRET and ISC_TENANT_URL required');
    }

    let payload;
    if (kind === 'drift') {
      const drift = JSON.parse(readFileSync(argv.drift, 'utf8'));
      payload = buildDriftApprovalPayload({ drift, config });
    } else if (kind === 'restore') {
      const plan = JSON.parse(readFileSync(argv.plan, 'utf8'));
      payload = buildRestoreApprovalPayload({
        plan,
        planHash: plan.planHash,
        sourceTag: argv.tag,
        requester: argv.author ?? process.env.GITHUB_ACTOR,
        config,
      });
    } else {
      const plan = JSON.parse(readFileSync(argv.plan, 'utf8'));
      const pr = JSON.parse(readFileSync(argv.pr, 'utf8'));
      payload = buildChangeApprovalPayload({
        plan,
        diffHash: argv['diff-hash'] ?? hashFullTree(),
        pr,
        config,
      });
    }
    const result = await invokeExternalTrigger({
      triggerUrl,
      tokenUrl: `${tenantUrl.replace(/\/$/, '')}/oauth/token`,
      clientId,
      clientSecret,
      payload,
    });
    print({ payload, result });
    return;
  }

  if (cmd === 'ledger-change') {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    print(writeChangeEntry(input));
    return;
  }

  if (cmd === 'ledger-restore') {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    print(writeRestoreEntry(input));
    return;
  }

  if (cmd === 'ledger-drift') {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    print(writeDriftEntry(input));
    return;
  }

  if (cmd === 'tag-applied') {
    const name = argv.tag ?? buildAppliedTagName({ prNumber: argv.pr });
    if (!isAppliedTag(name)) die(`Invalid tag ${name}`);
    print(
      createAppliedTag({
        name,
        message: argv.message ?? `Applied to ISC (${name})`,
        dryRun: argv['dry-run'],
      }),
    );
    return;
  }

  if (cmd === 'readme') {
    print(generateReadme({ config }));
    return;
  }

  die(`Unknown command: ${cmd}`);
}

main().catch((err) => {
  process.stderr.write(`${err.stack || err}\n`);
  process.exit(1);
});
