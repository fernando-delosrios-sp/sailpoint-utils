"""Ingest Entro protected documentation into a local documentation tree.

Starts at https://docs.entro.security/, authenticates with the operator's
exported session cookie, discovers same-origin pages, converts HTML to
markdown, and publishes a complete snapshot under documentation/.
Does not request the Entro product API catalog and does not use product API credentials.
"""

from __future__ import annotations

import argparse
import http.cookiejar
import os
import re
import shutil
import sys
import urllib.request
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urljoin, urlparse, urlunparse
from uuid import uuid4

from integration_catalog import validate_integration_paths, write_integrations_index

DEFAULT_START_URL = "https://docs.entro.security/"
DOCS_HOST = "docs.entro.security"
COOKIE_ENV = "ENTRO_DOCS_COOKIE"
DEFAULT_OUTPUT_DIR = Path("documentation")
DEFAULT_ENV_FILE = Path(".env")
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

OPERATOR_COOKIE_STEPS = (
    "To export a session cookie:\n"
    "1. Open https://docs.entro.security/ in a browser.\n"
    "2. Complete login until documentation pages are visible.\n"
    "3. In DevTools Network, select a document request whose URL is still on "
    "docs.entro.security, open Headers, and copy the full Cookie request header "
    "value (every name=value pair, separated by semicolons). Do not copy one "
    "cookie at a time from the Cookies panel.\n"
    f"4. Set {COOKIE_ENV} to that value in the repo-local .env file.\n"
    "5. Rerun ingest."
)

GITHUB_PAT = re.compile(r"ghp_[A-Za-z0-9]{20,}")
GITHUB_FINEGRAINED_PAT = re.compile(r"github_pat_[A-Za-z0-9_]{20,}")
AUTH_HEADER_LINE = re.compile(
    r"(?im)^(?:cookie|authorization)\s*:[^\n]*",
)
MARKDOWN_LINK = re.compile(
    r"\[(?:[^\]]*)\]\((https?://[^)\s]+|/[^)\s]+)\)",
)
TRACKING_QUERY_KEYS = frozenset(
    {
        "utm_source",
        "utm_medium",
        "utm_campaign",
        "utm_term",
        "utm_content",
        "fbclid",
        "gclid",
        "mc_cid",
        "mc_eid",
    }
)
ASSET_SUFFIXES = frozenset(
    {
        ".css",
        ".js",
        ".mjs",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".svg",
        ".webp",
        ".ico",
        ".woff",
        ".woff2",
        ".ttf",
        ".eot",
        ".map",
        ".pdf",
    }
)
EXCLUDED_PATH_SEGMENTS = frozenset(
    {
        "login",
        "logout",
        "account",
        "auth",
        "authentication",
        "signin",
        "sign-in",
        "signout",
        "sign-out",
    }
)
OUT_OF_SCOPE_PATH_PREFIXES = (
    "/supported-secrets",
    "/knowledge-base",
)
CHROME_TAGS = frozenset({"nav", "header", "footer", "aside", "script", "style", "noscript", "form"})
SKIP_TAGS = frozenset({"script", "style", "noscript"})

FetchFn = Callable[[str], str]


class MissingCookieError(ValueError):
    """Raised when ENTRO_DOCS_COOKIE is missing or empty."""


class RejectedSessionError(RuntimeError):
    """Raised when the site returns a login challenge instead of documentation."""


@dataclass(frozen=True)
class PageRecord:
    url: str
    relative_path: str
    title: str


def operator_cookie_error(reason: str) -> str:
    return f"{reason}\n{OPERATOR_COOKIE_STEPS}"


def credential_safe(message: str, cookie: str | None = None) -> str:
    text = message
    if cookie:
        text = text.replace(cookie, "<redacted>")
    text = AUTH_HEADER_LINE.sub(
        lambda match: f"{match.group(0).split(':', 1)[0]}: <redacted>",
        text,
    )
    return text


def redact_secrets(text: str, cookie: str | None = None) -> str:
    """Replace token-shaped strings and credential material before write."""
    text = GITHUB_PAT.sub("ghp_<redacted>", text)
    text = GITHUB_FINEGRAINED_PAT.sub("github_pat_<redacted>", text)
    text = re.sub(
        r"(?i)\bauthorization:\s*bearer\s+\S+",
        "Authorization: <redacted>",
        text,
    )
    return credential_safe(text, cookie)


def _unquote_env_value(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_docs_cookie_from_env_file(path: Path) -> str | None:
    """Read only ENTRO_DOCS_COOKIE from a dotenv-style file. Does not execute it."""
    if not path.is_file():
        return None
    found: str | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, rest = line.partition("=")
        if key.strip() != COOKIE_ENV:
            continue
        found = _unquote_env_value(rest.strip())
    return found


def load_docs_cookie(
    environ: Mapping[str, str] | None = None,
    env_file: Path | None = None,
) -> str:
    """Load ENTRO_DOCS_COOKIE from the process environment or a repo-local .env.

    Process values win. Other .env keys are ignored. Missing or empty values
    fail before any fetch.
    """
    env = os.environ if environ is None else environ
    if COOKIE_ENV in env:
        value = env[COOKIE_ENV]
    else:
        path = DEFAULT_ENV_FILE if env_file is None else env_file
        value = parse_docs_cookie_from_env_file(path)
        if value is None:
            raise MissingCookieError(
                operator_cookie_error(f"{COOKIE_ENV} is missing.")
            )
    if not str(value).strip():
        raise MissingCookieError(operator_cookie_error(f"{COOKIE_ENV} is empty."))
    return str(value)


def looks_like_login_challenge(body: str) -> bool:
    lowered = body.lower()
    if "sign in to gitbook" in lowered:
        return True
    if "api.descope.com" in lowered and "<input" in lowered and "password" in lowered:
        return True
    has_article = "<article" in lowered or "<h1" in lowered
    if ("visitor-auth" in lowered or "sso_app_id=gitbooks" in lowered) and not has_article:
        return True
    return False


def assert_documentation_response(final_url: str, body: str) -> None:
    host = _host_without_www(urlparse(final_url).netloc)
    if host != DOCS_HOST:
        raise RejectedSessionError(
            operator_cookie_error(
                f"Session was rejected (ended on {host or 'an external host'})."
            )
        )
    if looks_like_login_challenge(body):
        raise RejectedSessionError(
            operator_cookie_error(
                "Session was rejected (Descope or GitBook visitor-auth login)."
            )
        )


ALLOWED_REDIRECT_HOSTS = frozenset({DOCS_HOST, "gitbook.com"})


def _host_without_www(host: str) -> str:
    host = host.lower()
    if host.startswith("www."):
        return host[4:]
    return host


def _is_allowed_redirect_host(host: str) -> bool:
    host = _host_without_www(host)
    if host in ALLOWED_REDIRECT_HOSTS:
        return True
    return host.endswith(".gitbook.com")


class OffOriginRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):  # type: ignore[no-untyped-def]
        host = urlparse(newurl).netloc
        if not _is_allowed_redirect_host(host):
            safe_host = _host_without_www(host) or "an external host"
            raise RejectedSessionError(
                operator_cookie_error(
                    f"Session was rejected (redirected to {safe_host})."
                )
            )
        new_req = super().redirect_request(req, fp, code, msg, headers, newurl)
        if new_req is not None and _host_without_www(host) != DOCS_HOST:
            for header_name in ("Cookie", "cookie"):
                try:
                    new_req.remove_header(header_name)
                except KeyError:
                    pass
        return new_req


def cookie_header_to_jar(cookie_header: str, domain: str) -> http.cookiejar.CookieJar:
    jar = http.cookiejar.CookieJar()
    for part in cookie_header.split(";"):
        piece = part.strip()
        if not piece or "=" not in piece:
            continue
        name, _, value = piece.partition("=")
        name = name.strip()
        if not name:
            continue
        jar.set_cookie(
            http.cookiejar.Cookie(
                version=0,
                name=name,
                value=value,
                port=None,
                port_specified=False,
                domain=domain,
                domain_specified=True,
                domain_initial_dot=False,
                path="/",
                path_specified=True,
                secure=True,
                expires=None,
                discard=True,
                comment=None,
                comment_url=None,
                rest={"HttpOnly": None},
                rfc2109=False,
            )
        )
    return jar


def authenticated_get(url: str, cookie: str) -> str:
    jar = cookie_header_to_jar(cookie, DOCS_HOST)
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Cookie": cookie,
        },
    )
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        OffOriginRedirectHandler(),
    )
    try:
        with opener.open(request, timeout=60) as response:
            final_url = response.geturl()
            body = response.read().decode("utf-8", errors="replace")
    except RejectedSessionError:
        raise
    except Exception as exc:
        raise RuntimeError(credential_safe(f"{url}: {exc}", cookie)) from None
    assert_documentation_response(final_url, body)
    return body


def canonicalize_docs_url(raw: str, base: str) -> str | None:
    joined = urljoin(base, raw.strip())
    parsed = urlparse(joined)
    scheme = parsed.scheme.lower()
    if scheme not in {"http", "https"}:
        return None
    host = parsed.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    if host != DOCS_HOST:
        return None
    path = parsed.path or "/"
    segments = [seg.lower() for seg in path.split("/") if seg]
    if any(seg in EXCLUDED_PATH_SEGMENTS for seg in segments):
        return None
    normalized_for_scope = path if path == "/" else path.rstrip("/")
    if normalized_for_scope.endswith(".md"):
        normalized_for_scope = normalized_for_scope[:-3] or "/"
    if any(
        normalized_for_scope == prefix or normalized_for_scope.startswith(prefix + "/")
        for prefix in OUT_OF_SCOPE_PATH_PREFIXES
    ):
        return None
    suffix = Path(path).suffix.lower()
    if suffix in ASSET_SUFFIXES:
        return None
    query_pairs = [
        (key, value)
        for key, value in parse_qsl(parsed.query, keep_blank_values=True)
        if key.lower() not in TRACKING_QUERY_KEYS
    ]
    normalized_path = path if path == "/" else path.rstrip("/")
    if normalized_path.endswith(".md"):
        normalized_path = normalized_path[:-3] or "/"
    return urlunparse(
        ("https", DOCS_HOST, normalized_path, "", urlencode(query_pairs), "")
    )


def url_to_relative_path(url: str) -> str:
    parsed = urlparse(url)
    path = parsed.path.strip("/")
    if path.startswith("integrations/"):
        path = path[len("integrations/") :]
    if not path or path.lower() in {"llms.txt", "llms-full.txt"}:
        return "index.md" if not path else path
    if path.endswith(".md"):
        return path
    if path.endswith(".html"):
        return f"{path[:-5]}.md"
    if Path(path).suffix.lower() == ".txt":
        return path
    return f"{path}.md"


def is_catalog_feed(url: str) -> bool:
    path = urlparse(url).path.lower().rstrip("/")
    return path.endswith("llms.txt") or path.endswith("llms-full.txt")


class _LinkExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.hrefs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag != "a":
            return
        for name, value in attrs:
            if name == "href" and value:
                self.hrefs.append(value)


def extract_same_origin_links(html: str, page_url: str) -> list[str]:
    parser = _LinkExtractor()
    parser.feed(html)
    hrefs = list(parser.hrefs)
    hrefs.extend(match.group(1) for match in MARKDOWN_LINK.finditer(html))
    seen: set[str] = set()
    ordered: list[str] = []
    for href in hrefs:
        canonical = canonicalize_docs_url(href, page_url)
        if not canonical or canonical in seen:
            continue
        seen.add(canonical)
        ordered.append(canonical)
    return ordered


class _MarkdownConverter(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip_depth = 0
        self._chrome_depth = 0
        self._list_stack: list[str] = []
        self._in_pre = False
        self._in_code = False
        self._in_cell = False
        self._in_table = False
        self._table_row: list[str] = []
        self._table_cell: list[str] = []
        self._pending_href: str | None = None
        self._link_text: list[str] = []
        self._saw_header_row = False

    def _in_content(self) -> bool:
        return self._skip_depth == 0 and self._chrome_depth == 0

    def _emit(self, text: str) -> None:
        if self._pending_href is not None:
            self._link_text.append(text)
        elif self._in_cell:
            self._table_cell.append(text)
        else:
            self.parts.append(text)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in SKIP_TAGS:
            self._skip_depth += 1
            return
        if tag in CHROME_TAGS:
            self._chrome_depth += 1
            return
        if not self._in_content():
            return
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.parts.append("\n" + "#" * int(tag[1]) + " ")
        elif tag == "p":
            self.parts.append("\n\n")
        elif tag == "br":
            self.parts.append("\n")
        elif tag == "ul":
            self._list_stack.append("ul")
            self.parts.append("\n")
        elif tag == "ol":
            self._list_stack.append("ol")
            self.parts.append("\n")
        elif tag == "li":
            marker = "-" if (self._list_stack and self._list_stack[-1] == "ul") else "1."
            self.parts.append(f"\n{marker} ")
        elif tag in {"strong", "b"}:
            self._emit("**")
        elif tag in {"em", "i"}:
            self._emit("*")
        elif tag == "pre":
            self._in_pre = True
            self.parts.append("\n```\n")
        elif tag == "code" and not self._in_pre:
            self._in_code = True
            self._emit("`")
        elif tag == "a":
            href = dict(attrs).get("href")
            self._pending_href = href
            self._link_text = []
        elif tag == "table":
            self._in_table = True
            self._saw_header_row = False
            self.parts.append("\n")
        elif tag == "tr":
            self._table_row = []
        elif tag in {"td", "th"}:
            self._in_cell = True
            self._table_cell = []
        elif tag == "blockquote":
            self.parts.append("\n> ")

    def handle_endtag(self, tag: str) -> None:
        if tag in SKIP_TAGS and self._skip_depth:
            self._skip_depth -= 1
            return
        if tag in CHROME_TAGS and self._chrome_depth:
            self._chrome_depth -= 1
            return
        if not self._in_content():
            return
        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.parts.append("\n")
        elif tag == "p":
            self.parts.append("\n")
        elif tag in {"ul", "ol"}:
            if self._list_stack:
                self._list_stack.pop()
            self.parts.append("\n")
        elif tag in {"strong", "b"}:
            self._emit("**")
        elif tag in {"em", "i"}:
            self._emit("*")
        elif tag == "pre":
            self._in_pre = False
            self.parts.append("\n```\n")
        elif tag == "code" and self._in_code:
            self._in_code = False
            self._emit("`")
        elif tag == "a":
            text = "".join(self._link_text).strip() or (self._pending_href or "")
            href = self._pending_href or ""
            rendered = f"[{text}]({href})" if href else text
            self._pending_href = None
            self._link_text = []
            self._emit(rendered)
        elif tag in {"td", "th"}:
            self._table_row.append("".join(self._table_cell).strip())
            self._table_cell = []
            self._in_cell = False
        elif tag == "tr" and self._in_table:
            cells = self._table_row
            if cells:
                self.parts.append("| " + " | ".join(cells) + " |\n")
                if not self._saw_header_row:
                    self.parts.append("| " + " | ".join("---" for _ in cells) + " |\n")
                    self._saw_header_row = True
            self._table_row = []
        elif tag == "table":
            self._in_table = False
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self._in_content():
            return
        text = data if self._in_pre else re.sub(r"\s+", " ", data)
        self._emit(text)


def html_to_markdown(html: str) -> str:
    parser = _MarkdownConverter()
    parser.feed(html)
    text = "".join(parser.parts)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    return text


@dataclass
class DiscoveryResult:
    pages: list[PageRecord]
    bodies: dict[str, str]
    fetch_failures: list[str]


def discover_pages(start_url: str, fetch: FetchFn) -> DiscoveryResult:
    canonical_start = canonicalize_docs_url(start_url, start_url)
    if canonical_start is None:
        raise RejectedSessionError(
            operator_cookie_error("Start URL is not on docs.entro.security.")
        )
    queue = [canonical_start]
    seen: set[str] = set()
    pages: list[PageRecord] = []
    bodies: dict[str, str] = {}
    fetch_failures: list[str] = []
    start_fetched = False
    while queue:
        url = queue.pop(0)
        if url in seen:
            continue
        seen.add(url)
        try:
            body = fetch(url)
            assert_documentation_response(url, body)
        except RejectedSessionError:
            if url == canonical_start:
                raise
            fetch_failures.append(url)
            continue
        except Exception:
            fetch_failures.append(url)
            if not start_fetched:
                raise
            continue
        start_fetched = True
        bodies[url] = body
        print(f"get   {url}", flush=True)
        if not is_catalog_feed(url):
            title = url_to_relative_path(url).rsplit("/", 1)[-1].removesuffix(".md")
            heading = re.search(r"<h1[^>]*>(.*?)</h1>", body, re.IGNORECASE | re.DOTALL)
            if heading:
                title = re.sub(r"<[^>]+>", "", heading.group(1)).strip() or title
            pages.append(
                PageRecord(url=url, relative_path=url_to_relative_path(url), title=title)
            )
        for link in extract_same_origin_links(body, url):
            if link not in seen:
                queue.append(link)
    return DiscoveryResult(pages=pages, bodies=bodies, fetch_failures=fetch_failures)


def _page_title_from_markdown(markdown: str, fallback: str) -> str:
    for line in markdown.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip() or fallback
    return fallback


def _write_readme(
    output_dir: Path,
    written: list[PageRecord],
    failed: list[str],
) -> None:
    lines = [
        "# Documentation tree",
        "",
        "Local markdown captured from the protected documentation source at "
        "https://docs.entro.security/.",
        "This folder is ingest output. Agent process docs live under `docs/`.",
        "How to rebuild: set `ENTRO_DOCS_COOKIE` in `.env` after browser login, "
        "then run `python ingest_docs.py`. A session cookie is required; ingest "
        "does not fall back to entro.gitbook.io.",
        "",
        "Integration catalog: [`integrations.json`](integrations.json) (one row per Add New Account target: tile, in-form selection, documentation, setup and authentication methods, Coverages, Configuration tools, hosting (`public` / `self-hosted` / `operator-selected`), `summary`, `connectionFields`, and `prepSteps`; Worker Group is global, not a JSON field; Connector deployment topology is derived from hosting, not stored on the row; root `toolInstall` holds OS install, auth-once, and Credential boundary). The same writer also emits the Skill catalog at `.agents/skills/entro-connect/integrations.json` (no documentation-tree paths). Credentials stay in the CLI cache or a gitignored env file, never in agent context. A connector is always required; Docker Compose, Kubernetes Helm, and SaaS Perimeter stay in the Entro Connector pages below.",
        "",
        "Entro Connector topologies (product-level, not per target): [overview](entro-connector/entro-connector.md), [Docker Compose](entro-connector/entro-connector/docker-compose.md), [Kubernetes](entro-connector/entro-connector/k8s-connector.md), [SaaS perimeter IPs](entro-connector/entro-connector/entro-saas-perimeter-ips.md).",
        "",
        f"Captured: {len(written)} page(s).",
        "",
        "## Pages (discovery order)",
        "",
    ]
    for entry in written:
        lines.append(f"- [{entry.title}]({entry.relative_path})")
    if failed:
        lines.extend(["", "## Failed fetches", ""])
        for url in failed:
            lines.append(f"- {url}")
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def _staging_dir(output_dir: Path) -> Path:
    parent = output_dir.parent if output_dir.parent != Path("") else Path(".")
    return parent / f".{output_dir.name}.staging-{uuid4().hex}"


def _backup_dir(output_dir: Path) -> Path:
    parent = output_dir.parent if output_dir.parent != Path("") else Path(".")
    return parent / f".{output_dir.name}.backup-{uuid4().hex}"


def publish_staged_tree(staged: Path, output_dir: Path) -> None:
    backup: Path | None = None
    try:
        if output_dir.exists():
            backup = _backup_dir(output_dir)
            output_dir.rename(backup)
        staged.rename(output_dir)
    except OSError:
        if backup is not None and backup.exists() and not output_dir.exists():
            backup.rename(output_dir)
        if staged.exists():
            shutil.rmtree(staged, ignore_errors=True)
        raise
    if backup is not None and backup.exists():
        shutil.rmtree(backup, ignore_errors=True)


def _cleanup_dir(path: Path | None) -> None:
    if path is not None and path.exists():
        shutil.rmtree(path, ignore_errors=True)


def ingest(
    start_url: str,
    output_dir: Path,
    fetch: FetchFn | None = None,
    cookie: str | None = None,
    require_index_paths: bool = False,
) -> int:
    if cookie is None:
        try:
            cookie = load_docs_cookie()
        except MissingCookieError as exc:
            print(credential_safe(str(exc)), file=sys.stderr, flush=True)
            return 1

    def default_fetch(url: str) -> str:
        return authenticated_get(url, cookie)

    get = fetch or default_fetch
    staged: Path | None = None
    try:
        try:
            discovered = discover_pages(start_url, get)
        except RejectedSessionError as exc:
            print(credential_safe(str(exc), cookie), file=sys.stderr, flush=True)
            return 1
        except Exception as exc:
            print(
                credential_safe(f"start page fetch failed: {start_url}: {exc}", cookie),
                file=sys.stderr,
                flush=True,
            )
            return 1

        if not discovered.pages and not discovered.fetch_failures:
            print("discovery produced no documentation pages; aborting", file=sys.stderr, flush=True)
            return 1

        staged = _staging_dir(output_dir)
        staged.mkdir(parents=True, exist_ok=False)
        failed: list[str] = list(discovered.fetch_failures)
        written: list[PageRecord] = []
        for entry in discovered.pages:
            try:
                raw = discovered.bodies[entry.url]
                markdown = html_to_markdown(raw)
                if not markdown.strip():
                    raise ValueError("empty content after conversion")
                markdown = redact_secrets(markdown, cookie)
                if cookie and cookie in markdown:
                    raise ValueError("redaction failed: cookie material remained")
                dest = staged / entry.relative_path
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text(markdown + "\n", encoding="utf-8")
                title = _page_title_from_markdown(markdown, entry.title)
                written.append(
                    PageRecord(url=entry.url, relative_path=entry.relative_path, title=title)
                )
                print(f"ok    {entry.url}", flush=True)
            except RejectedSessionError as exc:
                print(credential_safe(str(exc), cookie), file=sys.stderr, flush=True)
                _cleanup_dir(staged)
                return 1
            except Exception as exc:
                failed.append(entry.url)
                print(
                    credential_safe(f"fail  {entry.url}: {exc}", cookie),
                    flush=True,
                )
                continue

        if not written or failed:
            if failed:
                print(f"page failures: {len(failed)}", flush=True)
                for url in failed:
                    print(f"  {url}", flush=True)
            if not written:
                print("no usable pages; aborting", file=sys.stderr, flush=True)
            _cleanup_dir(staged)
            return 1

        try:
            api_dir = output_dir / "api"
            if api_dir.is_dir():
                shutil.copytree(api_dir, staged / "api", dirs_exist_ok=True)
            _write_readme(staged, written, failed)
            index_errors = write_integrations_index(staged)
            if index_errors:
                for message in index_errors:
                    print(f"integrations index: {message}", file=sys.stderr, flush=True)
                raise RuntimeError("integrations index validation failed")
            if require_index_paths:
                path_errors = validate_integration_paths(staged)
                if path_errors:
                    for message in path_errors:
                        print(f"integrations index: {message}", file=sys.stderr, flush=True)
                    raise RuntimeError("integrations index validation failed")
        except Exception as exc:
            print(credential_safe(str(exc), cookie), file=sys.stderr, flush=True)
            _cleanup_dir(staged)
            return 1

        try:
            publish_staged_tree(staged, output_dir)
            staged = None
        except OSError as exc:
            print(credential_safe(f"publish failed: {exc}", cookie), file=sys.stderr, flush=True)
            _cleanup_dir(staged)
            staged = None
            return 1
        print(f"wrote {len(written)} page(s) to {output_dir}", flush=True)
        return 0
    finally:
        _cleanup_dir(staged)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Fetch protected Entro documentation from https://docs.entro.security/ "
            "using ENTRO_DOCS_COOKIE as the Cookie header, and write a documentation "
            "tree under documentation/ (not docs/). Does not accept cookie values as "
            "command-line arguments. Does not fall back to the public GitBook catalog.\n\n"
            f"{OPERATOR_COOKIE_STEPS}"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "start_url",
        nargs="?",
        default=DEFAULT_START_URL,
        help=f"Protected documentation start URL (default: {DEFAULT_START_URL})",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Output directory for the documentation tree (default: documentation/)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        cookie = load_docs_cookie()
    except MissingCookieError as exc:
        print(str(exc), file=sys.stderr, flush=True)
        return 1
    require_paths = args.output.resolve() == DEFAULT_OUTPUT_DIR.resolve()
    return ingest(
        args.start_url,
        args.output,
        cookie=cookie,
        require_index_paths=require_paths,
    )


if __name__ == "__main__":
    sys.exit(main())
