#!/usr/bin/env python3
"""Push built templates (templates/*.json) to an ISC tenant and verify what was stored.

Verification re-renders the stored subject and body with Velocity in every language, so damage done
by ISC's HTML sanitizer to the template logic is caught.

Usage:
    python3 push_templates.py --env emea-tes-team --batch identity
    python3 push_templates.py --env emea-tes-team --keys cloud_user_unlocked,cloud_user_locked_out
    python3 push_templates.py --env emea-tes-team --keys user_invitation-custom.my-apps
    python3 push_templates.py --env emea-tes-team --verify-only --batch all
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import build_templates  # noqa: E402

API = "/v2026/notification-templates"


def sail(env: str, *args: str) -> tuple[int, object]:
    proc = subprocess.run(
        ["sail", "api", *args, "--env", env, "-H", "X-SailPoint-Experimental: true"],
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
    )
    out = proc.stdout + proc.stderr
    status = 0
    body_lines = []
    for line in out.splitlines():
        if line.startswith("Status:"):
            status = int(line.split()[1])
        elif line[:4].isdigit() and line[4:5] == "/":
            continue
        elif re.match(r"(GET|POST|PUT|PATCH|DELETE|HEAD) |HTTP/|[A-Za-z0-9-]+: ", line):
            continue
        else:
            body_lines.append(line)
    text = "\n".join(body_lines).strip()
    try:
        # With debug logging on, sail prints the response body twice.
        return status, json.JSONDecoder().raw_decode(text)[0] if text else None
    except json.JSONDecodeError:
        return status, text


def batches() -> dict[str, list[str]]:
    import catalog_access
    import catalog_common
    import catalog_identity
    import catalog_work

    manifest = json.loads(build_templates.MANIFEST.read_text())
    groups = {
        "common": [t.key for t in catalog_common.TEMPLATES],
        "identity": [t.key for t in catalog_identity.TEMPLATES],
        "access": [t.key for t in catalog_access.TEMPLATES],
        "work": [t.key for t in catalog_work.TEMPLATES],
        "wrapped": manifest["wrapped"],
    }
    groups["all"] = [k for g in ("common", "identity", "access", "work", "wrapped") for k in groups[g]]
    return groups


def live_templates(env: str) -> dict[str, dict]:
    found: dict[str, dict] = {}
    offset = 0
    while True:
        status, page = sail(env, "get", f"{API}?limit=250&offset={offset}")
        if status != 200 or not isinstance(page, list):
            raise SystemExit(f"listing templates failed: {status} {page}")
        for t in page:
            if t.get("medium") == "EMAIL" and t.get("locale") == "en":
                found[t["key"]] = t
        if len(page) < 250:
            return found
        offset += 250


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--env", required=True)
    ap.add_argument("--batch")
    ap.add_argument("--keys")
    ap.add_argument("--verify-only", action="store_true")
    args = ap.parse_args()

    # Names are template keys, or `key.variant` for files in templates/variants/ (same tenant key).
    names = args.keys.split(",") if args.keys else batches()[args.batch]
    built = {}
    for name in names:
        path = build_templates.TEMPLATES / f"{name}.json"
        if not path.exists():
            path = build_templates.TEMPLATES / "variants" / f"{name}.json"
        built[name] = json.loads(path.read_text())
    tenant_key = {name: payload["key"] for name, payload in built.items()}

    if not args.verify_only:
        live = live_templates(args.env)
        for name, payload in built.items():
            if payload["key"] in live:
                payload = {**payload, "id": live[payload["key"]]["id"]}
            status, resp = sail(args.env, "post", API, "-b", json.dumps(payload, ensure_ascii=False))
            ok = status in (200, 201)
            print(f"{'ok ' if ok else 'ERR'} {status} {name}" + ("" if ok else f" -> {str(resp)[:300]}"))
            if not ok:
                raise SystemExit("push stopped on error")

    live = live_templates(args.env)
    missing = [n for n in names if tenant_key[n] not in live]
    if missing:
        raise SystemExit(f"not found in tenant after push: {missing}")
    stored = {n: {**built[n], "subject": live[tenant_key[n]]["subject"], "body": live[tenant_key[n]]["body"]} for n in names}
    subject_drift = [n for n in names if live[tenant_key[n]]["subject"] != built[n]["subject"]]
    samples = build_templates.build()[1]
    build_templates.render_all(stored, samples, preview=True)
    print(f"verified stored copies of {len(names)} templates" + (f"; subject changed by ISC: {subject_drift}" if subject_drift else ""))


if __name__ == "__main__":
    main()
