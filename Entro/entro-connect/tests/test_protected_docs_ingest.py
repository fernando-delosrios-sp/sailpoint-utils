"""Named scenario tests for protected-site documentation ingest."""

from __future__ import annotations

import json
import os
import urllib.request
from pathlib import Path

import pytest

import ingest_docs
import integration_catalog

FIXTURE_DIR = Path(__file__).parent / "fixtures" / "protected_docs"
START_URL = ingest_docs.DEFAULT_START_URL
FIXTURE_COOKIE = "entro_docs_session=fixture-cookie-aa11bb22-not-secret"

PAGE_HTML = {
    START_URL.rstrip("/"): (FIXTURE_DIR / "start.html").read_text(encoding="utf-8"),
    START_URL: (FIXTURE_DIR / "start.html").read_text(encoding="utf-8"),
    "https://docs.entro.security/ai-and-agents/n8n": "<html><body><h1>n8n</h1><p>n8n docs</p></body></html>",
    "https://docs.entro.security/ai-and-agents/n8n/n8n-onboarding": (
        "<html><body><h1>n8n onboarding</h1><p>Onboard n8n.</p></body></html>"
    ),
    "https://docs.entro.security/cloud-and-infrastructure/google-cloud-platform-1": (
        "<html><body><h1>GCP</h1><p>GCP docs</p></body></html>"
    ),
    "https://docs.entro.security/cloud-and-infrastructure/google-cloud-platform-1/onboarding": (
        "<html><body><h1>GCP onboarding</h1><p>Onboard GCP.</p></body></html>"
    ),
    "https://docs.entro.security/ai-and-agents/cursor-entro-marketplace-1": (
        "<html><body><h1>VS Code marketplace</h1><p>marketplace</p></body></html>"
    ),
    "https://docs.entro.security/integrations/readme": (
        "<html><body><h1>Index</h1><p>Index</p></body></html>"
    ),
}

KEPT_RELATIVE_PATHS = [
    "index.md",
    "readme.md",
    "ai-and-agents/n8n.md",
    "ai-and-agents/n8n/n8n-onboarding.md",
    "cloud-and-infrastructure/google-cloud-platform-1.md",
    "cloud-and-infrastructure/google-cloud-platform-1/onboarding.md",
    "ai-and-agents/cursor-entro-marketplace-1.md",
]


class FakeFetchError(Exception):
    pass


def _html_page(title: str, body: str = "<p>ok</p>", links: str = "") -> str:
    return f"<html><body><h1>{title}</h1>{body}{links}</body></html>"


def fake_fetch_ok(url: str) -> str:
    if url in PAGE_HTML:
        return PAGE_HTML[url]
    raise FakeFetchError(f"unexpected fetch: {url}")


def _tree_bytes(root: Path) -> dict[str, bytes]:
    mapping: dict[str, bytes] = {}
    if not root.exists():
        return mapping
    for path in sorted(root.rglob("*")):
        if path.is_file():
            mapping[path.relative_to(root).as_posix()] = path.read_bytes()
    return mapping


def test_missing_protected_site_credentials_fail_before_network_access(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]
) -> None:
    monkeypatch.delenv(ingest_docs.COOKIE_ENV, raising=False)
    existing = tmp_path / "marker.md"
    existing.write_text("keep-me\n", encoding="utf-8")
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        return fake_fetch_ok(url)

    monkeypatch.setattr(ingest_docs, "authenticated_get", fetch)
    monkeypatch.setattr(ingest_docs, "DEFAULT_ENV_FILE", tmp_path / "missing.env")
    code = ingest_docs.main(["-o", str(tmp_path / "documentation")])
    err = capsys.readouterr().err
    assert code != 0
    assert fetched == []
    assert "1. Open https://docs.entro.security/" in err
    assert FIXTURE_COOKIE not in err
    assert existing.read_text(encoding="utf-8") == "keep-me\n"


def test_empty_cookie_fails_before_network(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv(ingest_docs.COOKIE_ENV, "  ")
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        raise AssertionError("must not fetch")

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=None)
    assert code != 0
    assert fetched == []
    with pytest.raises(ingest_docs.MissingCookieError) as exc:
        ingest_docs.load_docs_cookie(environ={ingest_docs.COOKIE_ENV: ""})
    assert "1. Open https://docs.entro.security/" in str(exc.value)


def test_env_parser_reads_only_docs_cookie_and_preserves_process_values(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text(
        "OTHER=should-not-load\n"
        f"{ingest_docs.COOKIE_ENV}=from-file\n"
        "SHELL_INJECTION=$(rm -rf /)\n",
        encoding="utf-8",
    )
    monkeypatch.setenv("OTHER", "process-other")
    environ = {
        ingest_docs.COOKIE_ENV: "from-process",
        "OTHER": "process-other",
    }
    assert (
        ingest_docs.load_docs_cookie(environ=environ, env_file=env_file) == "from-process"
    )
    assert os.environ["OTHER"] == "process-other"
    loaded = ingest_docs.load_docs_cookie(
        environ={"OTHER": "process-other"}, env_file=env_file
    )
    assert loaded == "from-file"
    quoted = tmp_path / "quoted.env"
    quoted.write_text(f'{ingest_docs.COOKIE_ENV}="quoted-cookie"\n', encoding="utf-8")
    assert (
        ingest_docs.load_docs_cookie(environ={}, env_file=quoted) == "quoted-cookie"
    )


def test_cli_does_not_accept_cookie_arguments() -> None:
    help_text = ingest_docs.build_parser().format_help()
    assert "--cookie" not in help_text
    assert ingest_docs.COOKIE_ENV in help_text
    with pytest.raises(SystemExit):
        ingest_docs.build_parser().parse_args(["--cookie", "secret-value"])


def test_cookie_sent_only_as_cookie_header(monkeypatch: pytest.MonkeyPatch) -> None:
    captured: dict[str, object] = {}

    class FakeResponse:
        def geturl(self) -> str:
            return START_URL

        def read(self) -> bytes:
            return b"<html><body><h1>Docs</h1><p>Hello</p></body></html>"

        def __enter__(self) -> FakeResponse:
            return self

        def __exit__(self, *args: object) -> None:
            return None

    class FakeOpener:
        def open(self, request: urllib.request.Request, timeout: int = 60) -> FakeResponse:
            captured["authorization"] = request.get_header("Authorization")
            captured["request_cookie"] = request.get_header("Cookie")
            captured["header_names"] = ",".join(
                name.lower() for name, _ in request.header_items()
            )
            return FakeResponse()

    def fake_build_opener(*handlers: object) -> FakeOpener:
        processor = next(
            handler
            for handler in handlers
            if isinstance(handler, urllib.request.HTTPCookieProcessor)
        )
        captured["cookie_names"] = [cookie.name for cookie in processor.cookiejar]
        captured["cookie_header"] = "; ".join(
            f"{cookie.name}={cookie.value}" for cookie in processor.cookiejar
        )
        return FakeOpener()

    monkeypatch.setattr(urllib.request, "build_opener", fake_build_opener)
    body = ingest_docs.authenticated_get(START_URL, FIXTURE_COOKIE)
    assert "Docs" in body
    assert captured["cookie_header"] == FIXTURE_COOKIE
    assert captured["request_cookie"] == FIXTURE_COOKIE
    assert captured["authorization"] is None
    assert "authorization" not in (captured["header_names"] or "")


def test_descope_or_gitbook_login_is_rejected_session(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    login = (FIXTURE_DIR / "login_descope.html").read_text(encoding="utf-8")
    marker = tmp_path / "kept.md"
    marker.write_text("original\n", encoding="utf-8")

    def fetch(url: str) -> str:
        return login

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    err = capsys.readouterr().err
    assert code != 0
    assert "1. Open https://docs.entro.security/" in err
    assert FIXTURE_COOKIE not in err
    assert "Authorization:" not in err
    assert marker.read_text(encoding="utf-8") == "original\n"
    assert not any(tmp_path.glob(".documentation.staging-*"))


def test_off_origin_redirect_is_rejected_session() -> None:
    with pytest.raises(ingest_docs.RejectedSessionError) as exc:
        ingest_docs.assert_documentation_response(
            "https://api.descope.com/login", "<html>ok</html>"
        )
    assert "1. Open https://docs.entro.security/" in str(exc.value)


def test_authenticated_navigation_discovers_documentation_pages(
    tmp_path: Path,
) -> None:
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        assert not url.startswith("https://entro.gitbook.io")
        assert "descope.com" not in url
        assert "gitbook.com" not in url
        return fake_fetch_ok(url)

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    assert code == 0
    unique = list(dict.fromkeys(fetched))
    assert unique == fetched
    assert START_URL.rstrip("/") in fetched or START_URL in fetched
    assert "https://docs.entro.security/ai-and-agents/n8n" in fetched
    assert all("#" not in url for url in fetched)
    assert all("utm_source" not in url for url in fetched)
    assert not any(url.endswith(".png") for url in fetched)
    assert not any("/login" in url or "/logout" in url or "/account" in url for url in fetched)
    assert not any("/authentication" in url for url in fetched)
    assert (tmp_path / "ai-and-agents" / "n8n.md").is_file()
    assert (tmp_path / "ai-and-agents" / "cursor-entro-marketplace-1.md").is_file()


def test_no_public_gitbook_catalog_fallback(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        return (FIXTURE_DIR / "login_descope.html").read_text(encoding="utf-8")

    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE) != 0
    assert not any("entro.gitbook.io" in url for url in fetched)
    help_text = ingest_docs.build_parser().format_help()
    assert "does not fall back" in help_text.lower() or "ENTRO_DOCS_COOKIE" in help_text


def test_html_conversion_fixtures() -> None:
    html = (FIXTURE_DIR / "conversion.html").read_text(encoding="utf-8")
    markdown = ingest_docs.html_to_markdown(html)
    assert "# Conversion fixtures" in markdown
    assert "Prose paragraph" in markdown
    assert "[relative link](/ai-and-agents/n8n)" in markdown
    assert "- Bullet one" in markdown
    assert "1. First" in markdown
    assert "| Col A | Col B |" in markdown
    assert "| one | two |" in markdown
    assert 'print("hello")' in markdown
    assert "Chrome footer must not appear" not in markdown
    assert "window.tracking" not in markdown
    empty = ingest_docs.html_to_markdown(
        (FIXTURE_DIR / "empty.html").read_text(encoding="utf-8")
    )
    assert empty.strip() == ""


def test_url_to_output_path_is_deterministic() -> None:
    assert ingest_docs.url_to_relative_path("https://docs.entro.security/") == "index.md"
    assert (
        ingest_docs.url_to_relative_path(
            "https://docs.entro.security/integrations/ai-and-agents/n8n"
        )
        == "ai-and-agents/n8n.md"
    )
    assert ingest_docs.canonicalize_docs_url(
        "https://docs.entro.security/supported-secrets/foo",
        START_URL,
    ) is None
    assert ingest_docs.canonicalize_docs_url(
        "https://docs.entro.security/knowledge-base/non-human-identity",
        START_URL,
    ) is None
    assert ingest_docs.canonicalize_docs_url(
        "https://docs.entro.security/ai-and-agents/n8n",
        START_URL,
    ) == "https://docs.entro.security/ai-and-agents/n8n"


def test_markdown_catalog_links_are_discovered() -> None:
    text = (
        "# Catalog\n"
        "- [n8n](https://docs.entro.security/ai-and-agents/n8n.md)\n"
        "- [dup](https://docs.entro.security/ai-and-agents/n8n)\n"
    )
    links = ingest_docs.extract_same_origin_links(text, START_URL)
    assert links == ["https://docs.entro.security/ai-and-agents/n8n"]


def test_github_pat_redaction_and_cookie_absent_from_output(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    fake_pat = "ghp_" + ("A" * 36)

    def fetch(url: str) -> str:
        if url.rstrip("/") == START_URL.rstrip("/"):
            return (
                "<html><body><h1>Start</h1>"
                '<p><a href="/ai-and-agents/n8n">n8n</a></p></body></html>'
            )
        return (
            "<html><body><h1>n8n</h1>"
            f"<p>cookie {FIXTURE_COOKIE}</p>"
            f"<pre>{fake_pat}</pre>"
            "<p>Authorization: Bearer secret-token-value</p>"
            "</body></html>"
        )

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    assert code == 0
    captured = capsys.readouterr()
    blob = captured.out + captured.err
    n8n = (tmp_path / "ai-and-agents" / "n8n.md").read_text(encoding="utf-8")
    readme = (tmp_path / "README.md").read_text(encoding="utf-8")
    index = (tmp_path / "integrations.json").read_text(encoding="utf-8")
    for text in (blob, n8n, readme, index):
        assert FIXTURE_COOKIE not in text
        assert fake_pat not in text
        assert "Bearer secret-token-value" not in text
        assert "Cookie:" not in text or "Cookie: <redacted>" in text
    assert "ghp_<redacted>" in n8n


def test_complete_crawl_replaces_the_documentation_tree(tmp_path: Path) -> None:
    stale = tmp_path / "stale.md"
    stale.write_text("old-tree\n", encoding="utf-8")
    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE)
    assert code == 0
    assert not stale.exists()
    for rel in KEPT_RELATIVE_PATHS:
        path = tmp_path / rel
        assert path.is_file(), rel
        assert path.read_text(encoding="utf-8").strip()
    readme = (tmp_path / "README.md").read_text(encoding="utf-8")
    assert "docs.entro.security" in readme
    assert "cleaned nav" not in readme.lower()
    assert "gitbook catalog" not in readme.lower()
    for rel in KEPT_RELATIVE_PATHS:
        assert rel in readme
    assert (tmp_path / "integrations.json").is_file()
    leftovers = list(tmp_path.parent.glob(f".{tmp_path.name}.staging-*")) + list(
        tmp_path.parent.glob(f".{tmp_path.name}.backup-*")
    )
    assert leftovers == []


def test_partial_page_failure_preserves_the_previous_tree(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        if url == "https://docs.entro.security/ai-and-agents/n8n":
            raise FakeFetchError("empty page")
        return fake_fetch_ok(url)

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    captured = capsys.readouterr()
    assert code != 0
    assert "https://docs.entro.security/ai-and-agents/n8n" in captured.out + captured.err
    assert "https://docs.entro.security/ai-and-agents/n8n/n8n-onboarding" in fetched
    assert "https://docs.entro.security/cloud-and-infrastructure/google-cloud-platform-1" in fetched
    assert _tree_bytes(tmp_path) == before
    assert not (tmp_path / "ai-and-agents" / "n8n.md").exists()


def test_empty_discovery_is_not_published(tmp_path: Path) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    empty = (FIXTURE_DIR / "empty.html").read_text(encoding="utf-8")

    def fetch(url: str) -> str:
        return empty

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    assert code != 0
    assert _tree_bytes(tmp_path) == before


def test_missing_cookie_leaves_tree_unchanged(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    monkeypatch.delenv(ingest_docs.COOKIE_ENV, raising=False)
    monkeypatch.setattr(ingest_docs, "DEFAULT_ENV_FILE", tmp_path / "nope.env")
    assert ingest_docs.ingest(START_URL, tmp_path, cookie=None) != 0
    assert _tree_bytes(tmp_path) == before


def test_conversion_failure_preserves_tree(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    monkeypatch.setattr(ingest_docs, "html_to_markdown", lambda html: "")
    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE) != 0
    assert _tree_bytes(tmp_path) == before


def test_api_snapshot_survives_documentation_ingest(tmp_path: Path) -> None:
    api = tmp_path / "api" / "openapi.yaml"
    api.parent.mkdir(parents=True)
    api.write_text("openapi: 3.0.1\n", encoding="utf-8")
    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE) == 0
    assert api.read_text(encoding="utf-8") == "openapi: 3.0.1\n"
    assert (tmp_path / "ai-and-agents" / "n8n.md").is_file()


def test_redaction_failure_preserves_tree(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    monkeypatch.setattr(ingest_docs, "redact_secrets", lambda text, cookie=None: text)

    def fetch(url: str) -> str:
        if url.rstrip("/") == START_URL.rstrip("/"):
            return _html_page("Start", links='<a href="/only">only</a>')
        return _html_page("Only", body=f"<p>{FIXTURE_COOKIE}</p>")

    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE) != 0
    assert _tree_bytes(tmp_path) == before


def test_index_validation_failure_preserves_tree(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)
    monkeypatch.setattr(
        ingest_docs,
        "write_integrations_index",
        lambda output_dir: ["index exploded"],
    )
    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE) != 0
    assert _tree_bytes(tmp_path) == before


def test_publish_swap_failure_restores_previous_tree(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    (tmp_path / "kept.md").write_text("previous-tree\n", encoding="utf-8")
    before = _tree_bytes(tmp_path)

    def boom(staged: Path, output_dir: Path) -> None:
        raise OSError("swap failed")

    monkeypatch.setattr(ingest_docs, "publish_staged_tree", boom)
    assert ingest_docs.ingest(START_URL, tmp_path, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE) != 0
    assert _tree_bytes(tmp_path) == before


def test_protected_site_ingest_remains_independent_from_api_ingest(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.delenv("ENTRO_API_KEY", raising=False)
    fetched: list[str] = []

    def fetch(url: str) -> str:
        fetched.append(url)
        assert "/v1/docs" not in url
        return fake_fetch_ok(url)

    code = ingest_docs.ingest(START_URL, tmp_path, fetch=fetch, cookie=FIXTURE_COOKIE)
    assert code == 0
    assert fetched
    assert not any("/v1/docs" in url for url in fetched)
    source = Path("ingest_docs.py").read_text(encoding="utf-8")
    assert "ENTRO_API_KEY" not in source


def test_default_start_url_is_protected_site() -> None:
    parser = ingest_docs.build_parser()
    args = parser.parse_args([])
    assert args.start_url == "https://docs.entro.security/"
    help_text = parser.format_help()
    assert "https://docs.entro.security/" in help_text
    assert "entro.gitbook.io" not in help_text
    assert "llms.txt" not in help_text


def test_indexes_validate_from_staged_fixture_tree(tmp_path: Path) -> None:
    payload = integration_catalog.integration_index_payload()
    start_links = []
    pages = {
        START_URL: "",
    }
    rels: list[str] = []
    for row in payload["integrations"]:
        rels.extend(integration_catalog._documentation_paths(row))
    connector = [
        "entro-connector/entro-connector.md",
        "entro-connector/entro-connector/docker-compose.md",
        "entro-connector/entro-connector/k8s-connector.md",
        "entro-connector/entro-connector/entro-saas-perimeter-ips.md",
    ]
    for rel in dict.fromkeys(rels + connector):
        slug = rel[:-3] if rel.endswith(".md") else rel
        url = f"https://docs.entro.security/{slug}"
        start_links.append(f'<a href="/{slug}">{rel}</a>')
        pages[url] = _html_page(rel, body=f"<p>Fixture page for {rel}</p>")
    pages[START_URL] = _html_page("Start", links="".join(start_links))
    pages[START_URL.rstrip("/")] = pages[START_URL]

    def fetch(url: str) -> str:
        if url in pages:
            return pages[url]
        raise FakeFetchError(url)

    dest = tmp_path / "documentation"
    dest.mkdir()
    (dest / "stale.md").write_text("stale\n", encoding="utf-8")
    skill = tmp_path / "skill.json"
    original_write = ingest_docs.write_integrations_index

    def write_with_skill(output_dir: Path) -> list[str]:
        return integration_catalog.write_integrations_index(
            output_dir, skill_catalog=skill
        )

    ingest_docs.write_integrations_index = write_with_skill  # type: ignore[method-assign]
    try:
        code = ingest_docs.ingest(
            START_URL,
            dest,
            fetch=fetch,
            cookie=FIXTURE_COOKIE,
            require_index_paths=True,
        )
    finally:
        ingest_docs.write_integrations_index = original_write  # type: ignore[method-assign]
    assert code == 0
    assert not (dest / "stale.md").exists()
    assert integration_catalog.validate_integration_paths(dest) == []
    assert integration_catalog.validate_skill_catalog_file(skill) == []
    assert dest.joinpath("integrations.json").is_file()


def test_end_to_end_cookie_authenticated_atomic_publication(tmp_path: Path) -> None:
    dest = tmp_path / "documentation"
    dest.mkdir()
    (dest / "old.md").write_text("old\n", encoding="utf-8")
    code = ingest_docs.ingest(START_URL, dest, fetch=fake_fetch_ok, cookie=FIXTURE_COOKIE)
    assert code == 0
    assert not (dest / "old.md").exists()
    assert (dest / "ai-and-agents" / "n8n.md").read_text(encoding="utf-8")
    index = json.loads((dest / "integrations.json").read_text(encoding="utf-8"))
    assert index["integrations"]
    dumped = json.dumps(index)
    assert FIXTURE_COOKIE not in dumped


def test_missing_and_rejected_session_stderr_contain_operator_steps(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.delenv(ingest_docs.COOKIE_ENV, raising=False)
    monkeypatch.setattr(ingest_docs, "DEFAULT_ENV_FILE", tmp_path / "missing.env")
    ingest_docs.main(["-o", str(tmp_path)])
    missing_err = capsys.readouterr().err
    ingest_docs.ingest(
        START_URL,
        tmp_path,
        fetch=lambda url: (FIXTURE_DIR / "login_descope.html").read_text(encoding="utf-8"),
        cookie=FIXTURE_COOKIE,
    )
    rejected_err = capsys.readouterr().err
    for err in (missing_err, rejected_err):
        assert "1. Open https://docs.entro.security/" in err
        assert "full Cookie request header" in err or "Cookie request header" in err
        assert ingest_docs.COOKIE_ENV in err
        assert FIXTURE_COOKIE not in err
        assert "sample" not in err.lower() or "cookie" in err.lower()
        assert "secret-value" not in err
        assert "session=ghp_" not in err
