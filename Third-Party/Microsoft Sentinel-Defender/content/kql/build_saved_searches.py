#!/usr/bin/env python3
"""Build and smoke-test the shared SailPoint Log Analytics saved searches."""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
QUERIES = ROOT / "queries"

FUNCTIONS = [
    {
        "id": "SailPointISC_Events",
        "displayName": "SailPointISC_Events",
        "category": "SailPointISC",
        "file": ROOT / "SailPointISC_Events.kql",
        "functionAlias": "SailPointISC_Events",
    },
    {
        "id": "SailPointISC_AccountActivities",
        "displayName": "SailPointISC_AccountActivities",
        "category": "SailPointISC",
        "file": ROOT / "SailPointISC_AccountActivities.kql",
        "functionAlias": "SailPointISC_AccountActivities",
    },
    {
        "id": "SailPointISC_WorkflowHistory",
        "displayName": "SailPointISC_WorkflowHistory",
        "category": "SailPointISC",
        "file": ROOT / "SailPointISC_WorkflowHistory.kql",
        "functionAlias": "SailPointISC_WorkflowHistory",
    },
    {
        "id": "SailPointISC_Identities",
        "displayName": "SailPointISC_Identities",
        "category": "SailPointISC",
        "file": ROOT / "SailPointISC_Identities.kql",
        "functionAlias": "SailPointISC_Identities",
    },
    {
        "id": "SailPointISC_IdentityKeys",
        "displayName": "SailPointISC_IdentityKeys",
        "category": "SailPointISC",
        "file": ROOT / "SailPointISC_IdentityKeys.kql",
        "functionAlias": "SailPointISC_IdentityKeys",
    },
]

ALLOWED_FUNCTIONS = {
    "SailPoint - Security Events": ("SailPointISC_Events",),
    "SailPoint - Account Operations": ("SailPointISC_AccountActivities",),
    "SailPoint - Workflow Operations": ("SailPointISC_WorkflowHistory",),
    "SailPoint - Ingestion Health": (),
    "SailPoint - Response": ("SailPointISC_IdentityKeys",),
}

FORBIDDEN = {
    "SailPoint - Security Events": (
        "SailPointISC_AccountActivities",
        "SailPointISC_WorkflowHistory",
    ),
    "SailPoint - Account Operations": (
        "SailPointISC_Events",
        "SailPointISC_WorkflowHistory",
    ),
    "SailPoint - Workflow Operations": (
        "SailPointISC_Events",
        "SailPointISC_AccountActivities",
    ),
}


def load_kql(path: Path) -> str:
    lines = path.read_text().splitlines()
    while lines and (not lines[0].strip() or lines[0].lstrip().startswith("//")):
        lines.pop(0)
    query = "\n".join(lines).strip()
    if not query:
        raise SystemExit(f"empty query: {path}")
    return query


def load_manifest():
    items = json.loads((QUERIES / "manifest.json").read_text())
    seen = set()
    for item in items:
        if item["id"] in seen:
            raise SystemExit(f"duplicate saved search id: {item['id']}")
        seen.add(item["id"])
        if item["category"] not in ALLOWED_FUNCTIONS:
            raise SystemExit(f"unknown category for {item['id']}: {item['category']}")
        query = load_kql(QUERIES / item["file"])
        for required in ALLOWED_FUNCTIONS[item["category"]]:
            if required not in query:
                raise SystemExit(f"{item['id']} must call {required}")
        for banned in FORBIDDEN.get(item["category"], ()):
            if banned in query:
                raise SystemExit(f"{item['id']} must not reference {banned}")
        item["query"] = query
    if len(items) != 27:
        raise SystemExit(f"expected 27 saved searches, found {len(items)}")
    return items


def resource(item, query, function_alias=None):
    properties = {
        "displayName": item["displayName"],
        "category": item["category"],
        "query": query,
        "version": 2,
        "tags": [{"Name": "Product", "Value": "sentinel-sailpoint"}],
    }
    if function_alias:
        properties["functionAlias"] = function_alias
    return {
        "type": "Microsoft.OperationalInsights/workspaces/savedSearches",
        "apiVersion": "2020-08-01",
        "name": "[concat(parameters('workspaceName'), '/" + item["id"] + "')]",
        "properties": properties,
    }


def build_template():
    resources = []
    for item in FUNCTIONS:
        resources.append(resource(item, load_kql(item["file"]), item["functionAlias"]))
    for item in load_manifest():
        resources.append(resource(item, item["query"]))
    return {
        "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {"workspaceName": {"type": "string"}},
        "resources": resources,
    }


def write_template(path: Path):
    template = build_template()
    path.write_text(json.dumps(template, indent=2) + "\n")
    print(f"saved searches: {len(template['resources'])}")


def smoke(workspace_customer_id: str):
    failed = []
    for item in load_manifest():
        proc = subprocess.run(
            [
                "az",
                "monitor",
                "log-analytics",
                "query",
                "--workspace",
                workspace_customer_id,
                "--analytics-query",
                item["query"] + "\n| count",
                "-o",
                "json",
            ],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            detail = (proc.stderr or proc.stdout).strip().splitlines()
            failed.append((item["displayName"], detail[-1] if detail else "query failed"))
            print(f"FAIL  {item['displayName']}")
            continue
        try:
            rows = json.loads(proc.stdout)
            count = rows[0].get("Count", rows[0].get("count", "?")) if rows else "?"
        except (json.JSONDecodeError, IndexError, AttributeError):
            count = "?"
        print(f"OK    {item['category']} / {item['displayName']}  rows={count}")
    if failed:
        for name, detail in failed:
            print(f"ERROR {name}: {detail}", file=sys.stderr)
        raise SystemExit(f"{len(failed)} saved search(es) failed")


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "template":
        write_template(Path(sys.argv[2]))
        return
    if len(sys.argv) == 3 and sys.argv[1] == "smoke":
        smoke(sys.argv[2])
        return
    raise SystemExit("usage: build_saved_searches.py template <path> | smoke <workspace-customer-id>")


if __name__ == "__main__":
    main()
