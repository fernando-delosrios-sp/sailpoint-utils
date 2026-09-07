"""Named scenario tests for Entro API catalog ingest."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
import yaml

import ingest_docs
import ingest_api

from tests.test_protected_docs_ingest import START_URL, FIXTURE_COOKIE, fake_fetch_ok

FIXTURE_CATALOG = Path(__file__).parent / "fixtures" / "entro_api_catalog.json"
EXAMPLE_PAT = "ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
DEFAULT_ENDPOINT = "https://eval-api.entro.security"


class FakeApiError(Exception):
    pass


def _catalog_json() -> str:
    return FIXTURE_CATALOG.read_text(encoding="utf-8")


def _output(tmp_path: Path) -> Path:
    return tmp_path / "documentation" / "api" / "openapi.yaml"


def test_successful_api_catalog_ingest(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENTRO_API_KEY", "test-key")
    endpoint = "https://eval-api.entro.security/"
    fetched: list[str] = []

    def fetch(url: str, authorization: str) -> str:
        fetched.append(url)
        assert authorization == "test-key"
        assert url == "https://eval-api.entro.security/v1/docs"
        return _catalog_json()

    dest = _output(tmp_path)
    code = ingest_api.ingest(endpoint, dest, fetch=fetch)
    assert code == 0
    assert fetched == ["https://eval-api.entro.security/v1/docs"]
    assert dest.is_file()
    doc = yaml.safe_load(dest.read_text(encoding="utf-8"))
    assert str(doc["openapi"]).startswith("3")
    assert "/v1/integrations" in doc["paths"]
    assert doc["servers"][0]["url"] == "https://eval-api.entro.security"


def test_snapshot_is_the_full_catalog(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENTRO_API_KEY", "test-key")

    def fetch(url: str, authorization: str) -> str:
        return _catalog_json()

    dest = _output(tmp_path)
    assert ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch) == 0
    doc = yaml.safe_load(dest.read_text(encoding="utf-8"))
    assert "/v1/integrations" in doc["paths"]
    assert "/v1/risk/findings" in doc["paths"]
    assert set(doc["paths"]) == {"/v1/integrations", "/v1/risk/findings"}


def test_missing_api_key(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("ENTRO_API_KEY", raising=False)
    dest = _output(tmp_path)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("existing: snapshot\n", encoding="utf-8")

    called = False

    def fetch(url: str, authorization: str) -> str:
        nonlocal called
        called = True
        return _catalog_json()

    code = ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch)
    assert code != 0
    assert called is False
    assert dest.read_text(encoding="utf-8") == "existing: snapshot\n"


def test_api_catalog_fetch_failure(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENTRO_API_KEY", "test-key")
    dest = _output(tmp_path)
    dest.parent.mkdir(parents=True, exist_ok=True)
    original = "openapi: '3.0.1'\npaths:\n  /v1/kept: {}\n"
    dest.write_text(original, encoding="utf-8")

    def fetch_http_error(url: str, authorization: str) -> str:
        raise FakeApiError("503")

    assert ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch_http_error) != 0
    assert dest.read_text(encoding="utf-8") == original

    def fetch_no_paths(url: str, authorization: str) -> str:
        return json.dumps({"openapi": "3.0.1", "info": {"title": "x", "version": "1"}})

    assert ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch_no_paths) != 0
    assert dest.read_text(encoding="utf-8") == original

    def fetch_not_json(url: str, authorization: str) -> str:
        return "<html>not json</html>"

    assert ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch_not_json) != 0
    assert dest.read_text(encoding="utf-8") == original


def test_example_pat_in_the_catalog_is_redacted(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("ENTRO_API_KEY", "test-key")

    def fetch(url: str, authorization: str) -> str:
        return _catalog_json()

    dest = _output(tmp_path)
    assert ingest_api.ingest(DEFAULT_ENDPOINT, dest, fetch=fetch) == 0
    text = dest.read_text(encoding="utf-8")
    assert "ghp_<redacted>" in text
    assert EXAMPLE_PAT not in text
    assert "ghp_A" not in text


def test_protected_site_ingest_stays_independent_of_api_key(
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
    assert (tmp_path / "ai-and-agents" / "n8n.md").is_file()
    source = Path("ingest_docs.py").read_text(encoding="utf-8")
    assert "/v1/docs" not in source
    assert "ENTRO_API_KEY" not in source
