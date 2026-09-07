"""Named scenario tests for C4 flowchart as the default architecture picture."""

from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def test_ferspec_design_instruction_does_not_require_drawio() -> None:
    schema = (REPO / "openspec/schemas/ferspec/schema.yaml").read_text(encoding="utf-8")
    template = (REPO / "openspec/schemas/ferspec/templates/design.md").read_text(
        encoding="utf-8"
    )
    instruction = schema
    assert "diagrams/<change-name>.drawio" not in instruction
    assert "diagrams/<change-name>.drawio" not in template
    assert "C4 flowchart" in instruction
    assert "design.md" in instruction
    assert "flowchart" in template


def test_c4_diagram_skill_does_not_instruct_writing_drawio() -> None:
    skill = (REPO / ".agents/skills/c4-diagram/SKILL.md").read_text(encoding="utf-8")
    assert "diagrams/<change-name>.drawio" not in skill


INTRO_COPIES = (
    REPO / ".agents/skills/entro-connect/intro.md",
    REPO / "skills/entro-connect/intro.md",
)


def _intro_texts() -> list[tuple[Path, str]]:
    return [(path, path.read_text(encoding="utf-8")) for path in INTRO_COPIES]


def _example_fence(text: str) -> str:
    _, _, after = text.partition("```mermaid")
    fence, _, _ = after.partition("```")
    return fence


def test_intro_shows_mermaid_not_ascii() -> None:
    ascii_sketch = "[Operator] --> [Agent + entro-connect]"
    for path, text in _intro_texts():
        assert "```mermaid" in text
        assert "flowchart" in text
        assert ascii_sketch not in text
        assert "Draw this ASCII C4" not in text
        assert "same topology every run" not in text, f"{path} still pins one topology"
        for role in (
            "Identity object",
            "Permission grants",
            "Reach",
            "Credential",
            "Entro side",
        ):
            assert role in text, f"{path} missing node role {role}"
        for source in (
            "expectedChange",
            "target",
            "optional capabilities",
            "connectionFields",
            "hosting",
        ):
            assert source in text, f"{path} missing derivation source {source}"
        for machinery in (
            'operator(["Operator"])',
            'agent["Agent + entro-connect"]',
            'catalog[("Skill catalog")]',
            'vendor["Vendor CLI / MCP"]',
            'entroui["Entro UI"]',
        ):
            assert machinery not in text, f"{path} still draws run machinery {machinery}"


def test_intro_c4_is_not_a_per_run_drawio() -> None:
    for tree in (REPO / ".agents/skills/entro-connect", REPO / "skills/entro-connect"):
        assert not list(tree.glob("**/*.drawio"))
    assert not list(REPO.glob("*.drawio"))


def test_intro_c4_shows_what_the_integration_needs_configured() -> None:
    for path, text in _intro_texts():
        fence = _example_fence(text)
        for node in (
            "App registration",
            "Graph application permissions",
            "Azure roles",
            "Azure subscriptions / management groups",
            "Dataverse environments",
            "Worker Group",
            "SaaS Perimeter",
            "Tenant ID",
        ):
            assert node in fence, f"{path} example fence missing {node}"
        for role_class in ("classDef container", "classDef store", "classDef external"):
            assert role_class in fence, f"{path} example fence missing {role_class}"
        assert "classDef person" not in fence, f"{path} example fence draws a Person"


def test_two_integrations_draw_different_fences() -> None:
    """No Connect run executes in CI, so assert the rules that force derivation."""
    for path, text in _intro_texts():
        assert "Two Integrations MUST NOT draw the same fence." in text
        assert "Derive your own from the locked row; do not copy this fence" in text
        assert "one run's output" in text, f"{path} does not label the example as one run"


def test_skipped_coverage_is_absent() -> None:
    """Derivation rule stands in for a Connect run: skipped optional capabilities are not reach."""
    for _, text in _intro_texts():
        assert "Optional capabilities never appear as reach until the operator enables them during Prep." in text


def test_intro_uses_tile_path_optional_capability_vocabulary() -> None:
    for path, text in _intro_texts():
        assert "locked Authentication method" not in text, path
        assert "Coverage locked" not in text, path
        assert "Coverages" not in text, path
        assert "enabled during Prep" in text, path


def test_secret_connection_detail_is_named_only() -> None:
    secretish = re.compile(r"[A-Za-z0-9+/=_-]{24,}")
    for path, text in _intro_texts():
        assert "Secret Connection details appear as field names only — never a value." in text
        fence = _example_fence(text)
        assert not secretish.findall(fence), f"{path} example fence carries a value-like token"


def test_thin_row_omits_a_role() -> None:
    """Derivation rule stands in for a Connect run: unnamed roles are dropped."""
    for _, text in _intro_texts():
        assert "A role the locked row does not name is left out. Never invent a node" in text


def test_intro_md_copies_are_byte_identical() -> None:
    first, second = (path.read_bytes() for path in INTRO_COPIES)
    assert first == second


def test_older_change_diagrams_are_left_alone() -> None:
    diagrams = list((REPO / "openspec/changes").glob("**/diagrams/*.drawio"))
    names = {path.name for path in diagrams}
    assert "entro-connect-skill.drawio" in names
    assert "gitbook-documentation-tree.drawio" in names
    assert "ingest-entro-openapi.drawio" in names
    for path in diagrams:
        assert path.is_file()
        assert path.stat().st_size > 0
