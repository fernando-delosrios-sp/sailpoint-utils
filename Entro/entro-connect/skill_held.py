"""Skill-held onboarding artifacts: harvest, pins, dual-tree copies.

Pins record ``checksum`` of Skill-held bytes. A Local onboarding fork also
records ``localFork`` and ``originChecksum``. Origin-published notices ask the
maintainer keep-local versus take-remote; they are not Connect gates.
"""

from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse, unquote

from catalog_contracts import ENTRO_AZURE_SCRIPT, INTEGRATIONS_DIR, kebab_identity, row_slug

HARVEST_SECTIONS = (
    "cloud-and-infrastructure",
    "collaboration-and-saas",
    "code-and-ci-cd",
    "ai-and-agents",
    "security-and-identity",
    "container-registries",
    "gemini-instructions",
)

GITBOOK_FILE = re.compile(
    r"https://[^)\s\"]+files\.gitbook\.io[^)\s\"]+",
    re.IGNORECASE,
)
SAVE_AS = re.compile(
    r"save(?:\s+the\s+script\s+below)?\s+as\s+`([^`]+)`",
    re.IGNORECASE,
)
SHA256_PIN = re.compile(r"^sha256:[0-9a-f]{64}$")
FAKE_CHECKSUM = "sha256:verify-after-download"

REPO_ROOT = Path(__file__).resolve().parent
SKILL_ROOTS = (
    REPO_ROOT / ".agents" / "skills" / "entro-connect",
    REPO_ROOT / "skills" / "entro-connect",
)
VENDOR_DIRNAME = "vendor"
AZURE_LOCAL_PATCH = "integrations/microsoft-ecosystem/Entro-Azure-Onboarding.local.patch"
ORIGIN_PUBLISHED_NOTICE = (
    "origin published for Local onboarding fork: keep-local (update originChecksum, "
    "leave Skill-held bytes) or take-remote (rebase Entro-Azure-Onboarding.local.patch "
    "onto the new origin, then re-pin)"
)
_FOLDER_ALIASES = {
    "amazon-web-services": "amazon-web-services",
    "aws-onboarding-steps": "amazon-web-services",
    "azure": "microsoft-ecosystem",
    "google-cloud-platform": "google-gcp",
    "google-cloud-platform-1": "google-gcp",
    "sailpoint-isc": "sailpoint-identity-security-cloud-identitynow",
}


@dataclass(frozen=True)
class HarvestedAttachment:
    origin_url: str
    page: str
    filename: str
    skill_path: str


def anonymous_origin_url(raw: str) -> str:
    cleaned = raw.rstrip(").,;")
    parsed = urlparse(cleaned)
    query = [(k, v) for k, v in parse_qsl(parsed.query, keep_blank_values=True) if k.lower() != "token"]
    if not any(k.lower() == "alt" for k, _ in query):
        query.append(("alt", "media"))
    return urlunparse(parsed._replace(query=urlencode(query)))


def origin_has_token(url: str) -> bool:
    return "token=" in url.lower()


def filename_from_origin(url: str) -> str:
    path = unquote(urlparse(url).path)
    name = path.rsplit("/", 1)[-1]
    return name or "attachment.bin"


def skill_path_for(page: str, filename: str) -> str:
    slug = row_slug_for_page(page)
    return f"{INTEGRATIONS_DIR}/{slug}/{filename}"


def row_slug_for_page(page: str) -> str:
    from integration_catalog import INTEGRATIONS

    posix = page.replace("\\", "/")
    ranked: list[tuple[int, str]] = []
    for defn in INTEGRATIONS:
        slug = row_slug(defn.tile)
        docs = list(defn.documentation)
        for capability in defn.optional_capabilities:
            docs.extend(capability.documentation)
        for doc in docs:
            doc_posix = doc.replace("\\", "/")
            if posix == doc_posix:
                ranked.append((1000 + len(doc_posix), slug))
                continue
            parent = doc_posix.rsplit("/", 1)[0]
            if posix.startswith(parent + "/"):
                ranked.append((len(parent), slug))
            folder = "/".join(Path(doc_posix).parts[:2])
            if posix.startswith(folder + "/") or posix.startswith(folder + ".md"):
                ranked.append((len(folder), slug))
    if ranked:
        ranked.sort(key=lambda item: item[0], reverse=True)
        return ranked[0][1]
    parts = Path(posix).parts
    folder = Path(parts[1]).stem if len(parts) >= 2 else kebab_identity(posix)
    return _FOLDER_ALIASES.get(folder, kebab_identity(folder))


def iter_harvest_pages(documentation_dir: Path) -> list[Path]:
    pages: list[Path] = []
    for section in HARVEST_SECTIONS:
        root = documentation_dir / section
        if not root.is_dir():
            continue
        pages.extend(sorted(root.rglob("*.md")))
    return pages


def inventory_gitbook_attachments(documentation_dir: Path) -> list[HarvestedAttachment]:
    seen: dict[str, HarvestedAttachment] = {}
    for page in iter_harvest_pages(documentation_dir):
        text = page.read_text(encoding="utf-8")
        rel = str(page.relative_to(documentation_dir))
        for match in GITBOOK_FILE.findall(text):
            origin = anonymous_origin_url(match)
            name = filename_from_origin(origin)
            item = HarvestedAttachment(
                origin_url=origin,
                page=rel,
                filename=name,
                skill_path=skill_path_for(rel, name),
            )
            seen.setdefault(origin, item)
    return list(seen.values())


def extract_named_snippets(documentation_dir: Path) -> list[tuple[str, str, bytes]]:
    """Return (skill_path, capture_source, body) for save-as script fences."""
    found: list[tuple[str, str, bytes]] = []
    for page in iter_harvest_pages(documentation_dir):
        text = page.read_text(encoding="utf-8")
        rel = str(page.relative_to(documentation_dir))
        for save in SAVE_AS.finditer(text):
            filename = save.group(1).strip()
            rest = text[save.end() :]
            fences = re.findall(r"```(?:\w+)?\n(.*?)```", rest, re.DOTALL)
            body = None
            for block in fences:
                stripped = block.strip("\n")
                if stripped.startswith("#!/"):
                    body = (stripped + "\n").encode("utf-8")
                    break
            if body is None:
                continue
            found.append((skill_path_for(rel, filename), rel, body))
    return found


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def anonymous_get(url: str, *, opener=None) -> bytes:
    if origin_has_token(url):
        raise ValueError("origin URL must not include token=")
    fetch = opener or urllib.request.urlopen
    request = urllib.request.Request(
        url,
        method="GET",
        headers={"User-Agent": "Entro-integrations-ingest/1.0"},
    )
    try:
        with fetch(request) as response:
            payload = response.read()
            content_type = (response.headers.get("Content-Type") or "").lower()
    except urllib.error.URLError as exc:
        raise ValueError(f"anonymous GET failed: {exc}") from exc
    if "application/json" in content_type and not urlparse(url).query.lower().count("alt=media"):
        raise ValueError("anonymous GET returned JSON metadata; require ?alt=media")
    try:
        parsed = json.loads(payload)
    except (json.JSONDecodeError, UnicodeDecodeError):
        parsed = None
    if isinstance(parsed, dict) and (
        "downloadUrl" in parsed or parsed.get("type") == "file"
    ):
        raise ValueError("anonymous GET returned GitBook metadata JSON, not file bytes")
    return payload


def write_vendor_file(skill_path: str, data: bytes) -> None:
    write_skill_held_file(skill_path, data)


def write_skill_held_file(skill_path: str, data: bytes) -> None:
    relative = Path(skill_path)
    if relative.parts[0] != INTEGRATIONS_DIR:
        raise ValueError(f"skillPath must start with {INTEGRATIONS_DIR}/")
    for root in SKILL_ROOTS:
        dest = root / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)


def copy_vendor_tree() -> None:
    copy_skill_held_tree()


def migrate_skill_row_folders() -> None:
    from catalog_contracts import ROW_CATALOG_NAME
    from integration_catalog_migration import LEGACY_SLUG_ALIASES

    def assert_same_source_files(source: Path, target: Path) -> None:
        source_files = [source] if source.is_file() else [
            path for path in source.rglob("*") if path.is_file()
        ]
        for source_file in source_files:
            relative = Path(source_file.name) if source.is_file() else source_file.relative_to(source)
            target_file = target if source.is_file() else target / relative
            if not target_file.is_file() or target_file.read_bytes() != source_file.read_bytes():
                raise ValueError(
                    f"cannot remove legacy Skill row folder; artifact differs: {source_file}"
                )

    for skill_root in SKILL_ROOTS:
        integrations_dir = skill_root / INTEGRATIONS_DIR
        if not integrations_dir.is_dir():
            continue
        for legacy_slug, new_slug in LEGACY_SLUG_ALIASES.items():
            if legacy_slug == new_slug:
                continue
            src = integrations_dir / legacy_slug
            if not src.is_dir():
                continue
            dest = integrations_dir / new_slug
            dest.mkdir(parents=True, exist_ok=True)
            for item in src.iterdir():
                if item.name == ROW_CATALOG_NAME:
                    continue
                target = dest / item.name
                if target.exists():
                    assert_same_source_files(item, target)
                    continue
                if item.is_dir():
                    shutil.copytree(item, target)
                else:
                    shutil.copy2(item, target)
            shutil.rmtree(src)


def copy_skill_held_tree() -> None:
    source = SKILL_ROOTS[0] / INTEGRATIONS_DIR
    dest = SKILL_ROOTS[1] / INTEGRATIONS_DIR
    if dest.exists():
        shutil.rmtree(dest)
    if source.is_dir():
        shutil.copytree(source, dest)


def migrate_vendor_into_row_folders() -> None:
    source = SKILL_ROOTS[0]
    vendor = source / VENDOR_DIRNAME
    by_name: dict[str, Path] = {}
    if vendor.is_dir():
        for path in vendor.rglob("*"):
            if path.is_file():
                by_name.setdefault(path.name, path)
    for item in inventory_gitbook_attachments(REPO_ROOT / "documentation"):
        dest = source / item.skill_path
        if dest.is_file():
            continue
        found = by_name.get(item.filename)
        if found is None:
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(found.read_bytes())
    for skill_path, _page, body in extract_named_snippets(REPO_ROOT / "documentation"):
        dest = source / skill_path
        if dest.is_file():
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(body)
    copy_skill_held_tree()


def remove_vendor_trees() -> None:
    for root in SKILL_ROOTS:
        vendor = root / VENDOR_DIRNAME
        if vendor.exists():
            shutil.rmtree(vendor)


def build_skill_held_pins(documentation_dir: Path | None = None) -> list[dict[str, object]]:
    docs = documentation_dir or (REPO_ROOT / "documentation")
    pins: dict[str, dict[str, object]] = {}
    for item in inventory_gitbook_attachments(docs):
        file_path = SKILL_ROOTS[0] / item.skill_path
        checksum = sha256_file(file_path) if file_path.is_file() else ""
        local_fork = False
        origin_checksum = None
        version = f"{item.filename} (GitBook attachment)"
        if item.skill_path == ENTRO_AZURE_SCRIPT.skill_path and ENTRO_AZURE_SCRIPT.local_fork:
            local_fork = True
            origin_checksum = ENTRO_AZURE_SCRIPT.origin_checksum
            version = ENTRO_AZURE_SCRIPT.version
        pins[item.skill_path] = pin_payload(
            skill_path=item.skill_path,
            checksum=checksum,
            version=version,
            origin_url=item.origin_url,
            local_fork=local_fork,
            origin_checksum=origin_checksum,
        )
    for skill_path, page, body in extract_named_snippets(docs):
        existing = pins.get(skill_path)
        if existing and "google-cloud-platform-1" in page:
            continue
        pins[skill_path] = pin_payload(
            skill_path=skill_path,
            checksum=sha256_bytes(body),
            version=Path(skill_path).name,
            capture_source=page,
        )
    return list(pins.values())


def pin_payload(
    *,
    skill_path: str,
    checksum: str,
    version: str,
    origin_url: str | None = None,
    capture_source: str | None = None,
    local_fork: bool = False,
    origin_checksum: str | None = None,
) -> dict[str, object]:
    payload: dict[str, object] = {
        "skillPath": skill_path,
        "checksum": checksum,
        "version": version,
    }
    if origin_url:
        payload["originUrl"] = origin_url
    if capture_source:
        payload["captureSource"] = capture_source
    if local_fork:
        payload["localFork"] = True
    if origin_checksum:
        payload["originChecksum"] = origin_checksum
    return payload


def validate_script_pin(label: str, script: object) -> list[str]:
    errors: list[str] = []
    if not isinstance(script, dict):
        return [f"{label}: script must be an object"]
    skill_path = script.get("skillPath")
    checksum = script.get("checksum")
    version = script.get("version")
    if not isinstance(skill_path, str) or not skill_path.startswith(f"{INTEGRATIONS_DIR}/"):
        errors.append(f"{label}: script must have skillPath under {INTEGRATIONS_DIR}/")
    if isinstance(skill_path, str) and skill_path.startswith(f"{VENDOR_DIRNAME}/"):
        errors.append(f"{label}: skillPath must not use {VENDOR_DIRNAME}/")
    if checksum == FAKE_CHECKSUM:
        errors.append(f"{label}: script must not use {FAKE_CHECKSUM}")
    if not isinstance(checksum, str) or not SHA256_PIN.fullmatch(checksum):
        errors.append(f"{label}: script checksum must be sha256: plus 64 hex digits")
    if not isinstance(version, str) or not version.strip():
        errors.append(f"{label}: script must have version")
    if "url" in script:
        errors.append(f"{label}: script must not emit GitBook as a Connect runtime url")
    origin = script.get("originUrl")
    if origin is not None:
        if not isinstance(origin, str) or origin_has_token(origin):
            errors.append(f"{label}: originUrl must be an Anonymous origin URL without token=")
        elif "alt=media" not in origin:
            errors.append(f"{label}: originUrl must include alt=media")
    capture = script.get("captureSource")
    if capture is not None and (not isinstance(capture, str) or not capture.strip()):
        errors.append(f"{label}: captureSource must be a documentation page path")
    local_fork = script.get("localFork")
    origin_checksum = script.get("originChecksum")
    if local_fork is True:
        if not isinstance(origin_checksum, str) or not SHA256_PIN.fullmatch(origin_checksum):
            errors.append(
                f"{label}: Local onboarding fork must have originChecksum sha256: plus 64 hex digits"
            )
    elif local_fork is not None:
        errors.append(f"{label}: localFork must be true or omitted")
    if origin_checksum is not None and local_fork is not True:
        errors.append(f"{label}: originChecksum is only valid on a Local onboarding fork")
    return errors


def validate_harvest_coverage(
    documentation_dir: Path,
    catalog_pins: list[dict[str, object]],
    *,
    fetch_origin: bool = False,
    opener=None,
    notices: list[str] | None = None,
) -> list[str]:
    errors: list[str] = []
    attachments = inventory_gitbook_attachments(documentation_dir)
    pins_by_origin = {
        pin.get("originUrl"): pin
        for pin in catalog_pins
        if isinstance(pin, dict) and pin.get("originUrl")
    }
    pins_by_path = {
        pin.get("skillPath"): pin for pin in catalog_pins if isinstance(pin, dict)
    }
    for item in attachments:
        pin = pins_by_origin.get(item.origin_url) or pins_by_path.get(item.skill_path)
        if pin is None:
            errors.append(
                f"unpinned integration attachment {item.filename} from {item.page}"
            )
            continue
        errors.extend(
            _validate_skill_copy(item.skill_path, pin, fetch_origin, opener, notices)
        )
    for skill_path, page, body in extract_named_snippets(documentation_dir):
        pin = pins_by_path.get(skill_path)
        if pin is None:
            errors.append(f"unpinned snippet {skill_path} from {page}")
            continue
        if pin.get("captureSource") != page and pin.get("captureSource") not in {page}:
            # Allow either harvest page when duplicates exist (gcp vs gcp-1).
            if pin.get("captureSource") not in {page, page.replace("google-cloud-platform-1", "google-cloud-platform")}:
                errors.append(f"{skill_path}: captureSource must name the documentation page")
        expected = sha256_bytes(body)
        if pin.get("checksum") != expected:
            errors.append(f"{skill_path}: snippet drift versus {page}")
        errors.extend(_validate_skill_copy(skill_path, pin, fetch_origin=False, opener=None, notices=None))
    left = SKILL_ROOTS[0] / INTEGRATIONS_DIR
    right = SKILL_ROOTS[1] / INTEGRATIONS_DIR
    if left.is_dir() != right.is_dir():
        errors.append("row folders must exist in both entro-connect skill roots")
    elif left.is_dir():
        for path in left.rglob("*"):
            if not path.is_file():
                continue
            rel = path.relative_to(left)
            other = right / rel
            if not other.is_file() or other.read_bytes() != path.read_bytes():
                errors.append(f"skill trees differ at {INTEGRATIONS_DIR}/{rel}")
    return errors


def _validate_skill_copy(
    skill_path: str,
    pin: dict[str, object],
    fetch_origin: bool,
    opener,
    notices: list[str] | None = None,
) -> list[str]:
    errors: list[str] = []
    checksum = pin.get("checksum")
    bodies: list[bytes] = []
    for root in SKILL_ROOTS:
        file_path = root / skill_path
        if not file_path.is_file():
            errors.append(f"missing Skill-held file {skill_path} under {root}")
            continue
        bodies.append(file_path.read_bytes())
    if len(bodies) == 2 and bodies[0] != bodies[1]:
        errors.append(f"{skill_path}: skill trees are not byte-identical")
    if bodies and checksum != sha256_bytes(bodies[0]):
        errors.append(f"{skill_path}: checksum does not match the Skill-held copy")
    origin = pin.get("originUrl")
    if fetch_origin and isinstance(origin, str) and bodies:
        remote = anonymous_get(origin, opener=opener)
        remote_hash = sha256_bytes(remote)
        if pin.get("localFork") is True:
            recorded = pin.get("originChecksum")
            if remote_hash != recorded and notices is not None:
                notices.append(f"{skill_path}: {ORIGIN_PUBLISHED_NOTICE}")
        elif remote_hash != sha256_bytes(bodies[0]):
            errors.append(f"{skill_path}: origin drift versus Anonymous origin URL")
    return errors


class RebaseConflict(RuntimeError):
    """Local patch does not apply to the new origin bytes."""


def keep_local_origin(pin: dict[str, object], new_origin_checksum: str) -> dict[str, object]:
    """Ack origin published: bump originChecksum, leave Skill-held bytes."""
    if not SHA256_PIN.fullmatch(new_origin_checksum):
        raise ValueError("originChecksum must be sha256: plus 64 hex digits")
    updated = dict(pin)
    updated["originChecksum"] = new_origin_checksum
    return updated


def apply_unified_diff(origin_bytes: bytes, patch_text: str) -> bytes:
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        target = work / "script"
        target.write_bytes(origin_bytes)
        patch_path = work / "local.patch"
        patch_path.write_text(patch_text, encoding="utf-8")
        proc = subprocess.run(
            ["patch", "--batch", "--forward", "-u", str(target), str(patch_path)],
            cwd=work,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            raise RebaseConflict(proc.stderr or proc.stdout or "patch failed")
        return target.read_bytes()


def rebase_local_onboarding_fork(
    origin_bytes: bytes,
    patch_text: str,
    skill_path: str,
) -> tuple[bytes, str, str]:
    """Take-remote: apply the local patch to origin bytes and write both trees.

    Returns patched bytes, new originChecksum, and new Skill-held checksum.
    """
    patched = apply_unified_diff(origin_bytes, patch_text)
    write_skill_held_file(skill_path, patched)
    return patched, sha256_bytes(origin_bytes), sha256_bytes(patched)
