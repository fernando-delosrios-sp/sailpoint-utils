#!/usr/bin/env node
import minimist from 'minimist';
import { loadAllItems, loadConfig, writeJson } from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { runBackup, detectDrift, repoInitialized } from './backup.mjs';
import { fromSnapshotFile, toSnapshotFile } from './live-snapshot.mjs';
import { driftDecisionComment, driftPullRequestUrl, renderDriftIssue } from './drift-issue.mjs';
import { driftBranchName, driftContentHash, materializeDrift, renderDriftPullRequest } from './drift-pr.mjs';
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
  writeInitEntry,
} from './ledger.mjs';
import { clearAccessAndLedger } from './reset.mjs';
import { buildKnownGoodTagName, createKnownGoodTag, isKnownGoodTag } from './tags.mjs';
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
    string: ['base', 'head', 'tag', 'ref', 'pr', 'author', 'files', 'out', 'plan', 'drift', 'kind', 'diff-hash', 'message', 'tags', 'snapshot', 'issue-url', 'pr-url', 'issue', 'body', 'decision', 'run', 'detail'],
  });
  const [cmd] = argv._;

  if (!cmd || argv.help) {
    process.stdout.write(`Usage: node scripts/cli.mjs <command> [options]

Commands:
  backup              Snapshot ISC into access/ (--snapshot file reuses a drift read)
  baseline-status     Print whether access/ or the ledger already has a baseline
  clear-content       Delete access JSON and the ledger, keeping .gitkeep
  drift               Detect drift without writing (--snapshot file saves the ISC read)
  drift-issue         Render the drift issue title and body from --drift
  drift-pr            Render the drift pull request (branch, title, body) for --issue
  drift-pr-url        Print the Drift-PR url recorded in an issue body (--body file)
  drift-materialize   Write drifted snapshot bodies into the working tree
  drift-comment       Render the decision comment for the drift issue
  validate            Schema + name-reference checks
  plan                Diff base items vs head (default: empty base vs working tree)
  diff-hash           Hash touched files (--files a,b,c)
  apply               Apply a plan JSON (--plan file) or build from trees
  restore             Build/execute full restore from working tree vs live ISC
  request-approval    Post change/restore/drift payload to ISC external trigger
  ledger-change       Write a change ledger entry (JSON on stdin or --plan)
  ledger-restore      Write a restore ledger entry
  ledger-drift        Write a drift ledger entry
  ledger-init         Write the baseline ledger entry created by Init
  tag-known-good      Create known-good/* tag after successful apply
  readme              Regenerate README.md (--tags a,b replaces the git tag list)
`);
    process.exit(cmd ? 0 : 1);
  }

  const config = existsSync(join(ROOT, 'config.yaml')) ? loadConfig() : null;

  if (cmd === 'baseline-status') {
    print({ initialized: repoInitialized() });
    return;
  }

  if (cmd === 'backup') {
    // --snapshot reuses the ISC read a prior `drift` already paid for.
    const snapshot = argv.snapshot && existsSync(argv.snapshot)
      ? fromSnapshotFile(JSON.parse(readFileSync(argv.snapshot, 'utf8')))
      : null;
    const client = snapshot ? null : IscClient.fromEnv();
    const result = await runBackup({ client, config, dryRun: argv['dry-run'], snapshot });
    print(result);
    return;
  }

  if (cmd === 'drift') {
    const client = IscClient.fromEnv();
    const drift = await detectDrift({ client, config });
    const { snapshot, ...rest } = drift;
    // The snapshot is large; it goes to a file so the next command can reuse it
    // instead of reading ISC again, and stays out of the printed result.
    if (argv.snapshot) writeJson(argv.snapshot, toSnapshotFile(snapshot));
    print(rest);
    return;
  }

  if (cmd === 'drift-issue') {
    // Renders only; the workflow does the gh calls so the issue exists before
    // the approval that links to it.
    const drift = JSON.parse(readFileSync(argv.drift, 'utf8'));
    print(renderDriftIssue(drift, undefined, { prUrl: argv['pr-url'] || null }));
    return;
  }

  if (cmd === 'drift-pr') {
    const drift = JSON.parse(readFileSync(argv.drift, 'utf8'));
    const snapshot = fromSnapshotFile(JSON.parse(readFileSync(argv.snapshot, 'utf8')));
    const hash = driftContentHash(drift, snapshot);
    const pr = renderDriftPullRequest({ drift, issueNumber: argv.issue });
    print({ ...pr, contentHash: hash, branch: driftBranchName(hash) });
    return;
  }

  if (cmd === 'drift-pr-url') {
    process.stdout.write(driftPullRequestUrl(readFileSync(argv.body, 'utf8')) ?? '');
    return;
  }

  if (cmd === 'drift-materialize') {
    const drift = JSON.parse(readFileSync(argv.drift, 'utf8'));
    const snapshot = fromSnapshotFile(JSON.parse(readFileSync(argv.snapshot, 'utf8')));
    print(materializeDrift({ drift, snapshot, root: ROOT }));
    return;
  }

  if (cmd === 'drift-comment') {
    process.stdout.write(`${driftDecisionComment({
      decision: argv.decision,
      comment: argv.message,
      runUrl: argv.run,
      detail: argv.detail,
    })}\n`);
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
    const snapshot = argv.snapshot && existsSync(argv.snapshot)
      ? fromSnapshotFile(JSON.parse(readFileSync(argv.snapshot, 'utf8')))
      : null;
    // Load the repo tree once and pass it to both the plan and the apply.
    const items = loadAllItems();
    const plan = await buildRestorePlan({ client, config, headItems: items, snapshot });
    if (argv.out) writeJson(argv.out, plan);
    if (argv['dry-run'] || !argv.execute) {
      print({ ...plan, note: 'Pass --execute to apply after approval' });
      return;
    }
    const result = await executeRestore({ plan, client, items });
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
      payload = buildDriftApprovalPayload({
        drift,
        issueUrl: argv['issue-url'],
        prUrl: argv['pr-url'],
        config,
      });
    } else if (kind === 'restore') {
      const plan = JSON.parse(readFileSync(argv.plan, 'utf8'));
      payload = buildRestoreApprovalPayload({
        plan,
        planHash: plan.planHash,
        sourceRef: argv.ref ?? argv.tag,
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

  if (cmd === 'ledger-init') {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    print(writeInitEntry(input));
    return;
  }

  if (cmd === 'clear-content') {
    print(clearAccessAndLedger());
    return;
  }

  if (cmd === 'tag-known-good' || cmd === 'tag-applied') {
    const name = argv.tag ?? buildKnownGoodTagName({ prNumber: argv.pr });
    if (!isKnownGoodTag(name) || !name.startsWith('known-good/')) {
      die(`Invalid tag ${name}; new tags must start with known-good/`);
    }
    print(
      createKnownGoodTag({
        name,
        message: argv.message ?? `Known-good snapshot (${name})`,
        dryRun: argv['dry-run'],
      }),
    );
    return;
  }

  if (cmd === 'readme') {
    const readmeOpts = { config };
    if (argv.tags) {
      readmeOpts.tags = String(argv.tags)
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
    }
    print(generateReadme(readmeOpts));
    return;
  }

  die(`Unknown command: ${cmd}`);
}

main().catch((err) => {
  process.stderr.write(`${err.stack || err}\n`);
  process.exit(1);
});
