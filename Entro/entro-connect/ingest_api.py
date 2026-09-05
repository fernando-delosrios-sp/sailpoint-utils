"""Ingest Entro's product API catalog into a committed OpenAPI snapshot.

Fetches GET {endpoint}/v1/docs with Authorization set to ENTRO_API_KEY (raw key,
not Bearer). Writes documentation/api/openapi.yaml. Separate from GitBook ingest.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path
from typing import Callable

import yaml

from ingest_docs import redact_secrets

DEFAULT_ENDPOINT = "https://eval-api.entro.security"
DEFAULT_OUTPUT = Path("documentation") / "api" / "openapi.yaml"
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

FetchFn = Callable[[str, str], str]


def https_get(url: str, authorization: str) -> str:
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": authorization,
            "User-Agent": USER_AGENT,
        },
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode("utf-8")


def _fail(message: str) -> int:
    print(message, file=sys.stderr, flush=True)
    return 1


def ingest(
    endpoint: str,
    output_path: Path,
    fetch: FetchFn | None = None,
) -> int:
    key = os.environ.get("ENTRO_API_KEY")
    if key is None or not str(key).strip():
        return _fail("ENTRO_API_KEY is missing or empty")

    base = endpoint.rstrip("/")
    url = f"{base}/v1/docs"
    get = fetch or https_get
    try:
        body = get(url, str(key).strip())
    except Exception as exc:
        return _fail(f"API catalog fetch failed: {url}: {exc}")

    try:
        catalog = json.loads(body)
    except json.JSONDecodeError:
        return _fail("API catalog response is not JSON")

    if not isinstance(catalog, dict):
        return _fail("API catalog is not a JSON object")
    paths = catalog.get("paths")
    if not isinstance(paths, dict):
        return _fail("API catalog is missing OpenAPI paths")
    openapi = catalog.get("openapi")
    if not (isinstance(openapi, str) and openapi.startswith("3")):
        return _fail("API catalog is not OpenAPI 3")

    servers = catalog.get("servers")
    if not isinstance(servers, list) or not servers:
        catalog["servers"] = [{"url": base}]
    else:
        first = servers[0] if isinstance(servers[0], dict) else {}
        first["url"] = base
        servers[0] = first
        catalog["servers"] = servers

    yaml_text = yaml.safe_dump(
        catalog,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
    )
    redacted = redact_secrets(yaml_text)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = output_path.with_name(output_path.name + ".tmp")
    tmp_path.write_text(redacted, encoding="utf-8")
    tmp_path.replace(output_path)
    print(f"wrote {output_path}", flush=True)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Fetch the Entro API catalog (GET {endpoint}/v1/docs) and write an "
            "OpenAPI 3 YAML snapshot. Requires ENTRO_API_KEY. Does not use Bearer."
        )
    )
    parser.add_argument(
        "--endpoint",
        default=DEFAULT_ENDPOINT,
        help=(
            "Entro API origin used for the fetch and written to servers[0].url "
            f"(default: {DEFAULT_ENDPOINT}). A trailing slash is stripped."
        ),
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Snapshot path (default: {DEFAULT_OUTPUT})",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return ingest(args.endpoint, args.output)


if __name__ == "__main__":
    sys.exit(main())
