#!/usr/bin/env python3
"""Generate thin (c) Config Import JSONs onto live API shells.

Same shape as the working tenant patch
`NERM_emea-tes-team_import_fix_update_system_configuration.json`:
existing workflow (Update) + owned graph with new ids (Create).
No ProfileType / pages / attributes.

page_id / ne_attribute_id stay as GUID references to existing tenant objects.
"""

from __future__ import annotations

import copy
import json
import uuid
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CREATE_EXPORT = ROOT / "create_workflows_1791554795898.json"
UPDATE_EXPORT = ROOT / "update_workflows_1791554822015.json"
OUT = ROOT

ORIG_ADD_DETAILS = "8e88da4f-f26e-4cb9-a72c-111b3edf8c29"
ORIG_ADD = "dc1b7eef-52cb-4784-b1c5-d9dd2550962d"
ORIG_UPDATE = "9cd0e00d-33ad-4d0c-838f-965fb66fe258"

# Live empty API shells — keep id+uid so Review Updates the shell and Creates
# the graph (new child ids/uids). Do not bump uid versions.
WF_DETAILS_C = "6baf4a98-fcf0-4b45-b567-7276ca2d1ca6"
WF_ADD_C = "4f339dd6-154b-4f6a-ac6b-6ad3d02ddf67"
WF_UPDATE_C = "584cbc70-90a0-4b4f-bea9-b60a586f9f85"
UID_DETAILS_C = "b3_aad_details_c_v5"
UID_ADD_C = "b3_aa_people_c_v3"
UID_UPDATE_C = "b3_ua_c_v5"

# Never emit these — reference by GUID only
SKIP_EMIT = {
    "ProfileType",
    "WorkflowPage",
    "ProfilePage",
    "NeAttribute",
    "NeAttributeOption",
    "NeAttributeRole",
    "Form",
    "FormAttribute",
    "FormAttributeForm",
    "FormHeading",
    "PageElement",
    "ProfileTypeRole",
    "ProfileTypeNaming",
    "ProfileTypeDupAttribute",
    "NeprofileRole",
    "NeaccessRole",
    "Portal",
    "PortalRole",
    "Email",
    "ValueBuilder",
    "ValueBuilderAttribute",
    "ValueBuilderHelper",
    "Validation",
    "SmallHeading",
    "Paragraph",
    "HtmlContainer",
    "WorkflowVersion",
    "LoginWorkflow",
    "PasswordResetWorkflow",
    "RegistrationWorkflow",
    "PortalRegistrationWorkflow",
    "AutomatedWorkflow",
    "BatchWorkflow",
    "CreateWorkflow",  # emitted explicitly
    "UpdateWorkflow",
}


def new_id() -> str:
    return str(uuid.uuid4())


def load_by_id() -> dict[str, dict]:
    by: dict[str, dict] = {}
    for path in (CREATE_EXPORT, UPDATE_EXPORT):
        for o in json.loads(path.read_text()):
            oid = o.get("id")
            if oid and oid not in by:
                by[oid] = o
    return by


def workflow_owned(by: dict[str, dict], wf_id: str) -> list[dict]:
    """Actions/conditions/steps/satellites for one workflow — no foundations."""
    ids = {wf_id}
    for o in by.values():
        if o.get("workflow_id") == wf_id and o.get("id"):
            ids.add(o["id"])

    link_keys = (
        "workflow_action_id",
        "run_workflow_action_id",
        "condition_id",
        "workflow_condition_id",
        "step_id",
        "rest_api_action_id",
        "pause_action_id",
        "invitation_action_id",
        "workflow_action_performer_id",
    )
    changed = True
    while changed:
        changed = False
        for oid in list(ids):
            o = by.get(oid)
            if not o:
                continue
            for k in link_keys:
                v = o.get(k)
                if isinstance(v, str) and v in by and v not in ids:
                    if by[v].get("class_name") in SKIP_EMIT:
                        continue
                    ids.add(v)
                    changed = True
        for o in by.values():
            oid = o.get("id")
            if not oid or oid in ids:
                continue
            cn = o.get("class_name")
            if cn in SKIP_EMIT:
                continue
            if o.get("workflow_id") == wf_id:
                ids.add(oid)
                changed = True
                continue
            if any(o.get(k) in ids for k in link_keys):
                # Don't pull RunWorkflowActionConfiguration via child workflow_id
                if cn == "RunWorkflowActionConfiguration" and o.get(
                    "run_workflow_action_id"
                ) not in ids:
                    continue
                ids.add(oid)
                changed = True

    return [by[i] for i in ids if i in by]


def clone_thin(
    by: dict[str, dict],
    *,
    orig_wf: str,
    live_wf: str,
    live_uid: str,
    live_name: str,
    uid_prefix: str,
    retarget_run: dict[str, str] | None = None,
) -> list[dict]:
    related = workflow_owned(by, orig_wf)
    id_map = {orig_wf: live_wf}
    for o in related:
        oid = o.get("id")
        if not oid or oid == orig_wf:
            continue
        if o.get("class_name") in SKIP_EMIT:
            continue
        id_map[oid] = new_id()

    out: list[dict] = []
    orig = by[orig_wf]
    wf = copy.deepcopy(orig)
    wf["id"] = live_wf
    wf["uid"] = live_uid
    wf["name"] = live_name
    wf["status"] = "Disabled"
    wf["archived"] = False
    wf["description"] = (
        f"Clone of {orig.get('name')} (c) — shared-page cutover candidate. Disabled."
    )
    # Match working Update patch shape: omit archived_on (null/stale breaks Update).
    for k in ("created_at", "updated_at", "legacy_id", "archived_on"):
        wf.pop(k, None)
    out.append(wf)

    for o in related:
        if o.get("id") == orig_wf:
            continue
        cn = o.get("class_name")
        if cn in SKIP_EMIT:
            continue
        ro = copy.deepcopy(o)
        for k, v in list(ro.items()):
            if isinstance(v, str) and v in id_map:
                ro[k] = id_map[v]
        if o.get("id") in id_map:
            ro["id"] = id_map[o["id"]]
        if o.get("workflow_id") == orig_wf:
            ro["workflow_id"] = live_wf
        if "uid" in ro:
            ro["uid"] = f"{uid_prefix}_{uuid.uuid4().hex}"
        if (
            cn == "RunWorkflowActionConfiguration"
            and retarget_run
            and o.get("workflow_id") in retarget_run
        ):
            ro["workflow_id"] = retarget_run[o["workflow_id"]]
            ro["wait_for_completion"] = True
        if cn == "RunWorkflowAction" and retarget_run:
            if "Add Assignment Details" in (o.get("description") or ""):
                ro["description"] = "Add Assignment Details (c)"
        for k in ("created_at", "updated_at", "legacy_id", "archived_on"):
            ro.pop(k, None)
        out.append(ro)

    # Validate no dangling internal refs among emitted objects
    ids = {o["id"] for o in out if o.get("id")}
    for o in out:
        cn = o.get("class_name")
        if cn == "WorkflowStep" and o.get("step_id") not in ids:
            raise RuntimeError(f"dangling step {o.get('uid')} -> {o.get('step_id')}")
        if cn == "WorkflowConditionAction":
            if o.get("workflow_action_id") not in ids:
                raise RuntimeError(f"dangling wca action {o.get('uid')}")
            if o.get("workflow_condition_id") not in ids:
                raise RuntimeError(f"dangling wca cond {o.get('uid')}")

    wfs = [o for o in out if o.get("class_name") in ("CreateWorkflow", "UpdateWorkflow")]
    steps = [o for o in out if o.get("class_name") == "WorkflowStep"]
    mid = [
        o
        for o in out
        if o.get("class_name")
        not in ("CreateWorkflow", "UpdateWorkflow", "WorkflowStep")
    ]
    return wfs + mid + steps


def write_json(path: Path, data: list) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n")
    print(f"wrote {path.name} ({len(data)} objects)")


def main() -> None:
    by = load_by_id()
    print(f"loaded {len(by)} objects")

    details = clone_thin(
        by,
        orig_wf=ORIG_ADD_DETAILS,
        live_wf=WF_DETAILS_C,
        live_uid=UID_DETAILS_C,
        live_name="Add Assignment Details (c)",
        uid_prefix="b3_aad_c",
    )
    write_json(OUT / "NERM_emea-tes-team_import_add_assignment_details_c.json", details)

    add_c = clone_thin(
        by,
        orig_wf=ORIG_ADD,
        live_wf=WF_ADD_C,
        live_uid=UID_ADD_C,
        live_name="Add Assignment (c)",
        uid_prefix="b3_aa_c",
        retarget_run={ORIG_ADD_DETAILS: WF_DETAILS_C},
    )
    write_json(OUT / "NERM_emea-tes-team_import_add_assignment_c.json", add_c)

    update_c = clone_thin(
        by,
        orig_wf=ORIG_UPDATE,
        live_wf=WF_UPDATE_C,
        live_uid=UID_UPDATE_C,
        live_name="Update Assignment (c)",
        uid_prefix="b3_ua_c",
    )
    write_json(OUT / "NERM_emea-tes-team_import_update_assignment_c.json", update_c)

    for label, data, uid in (
        ("Details", details, UID_DETAILS_C),
        ("Add", add_c, UID_ADD_C),
        ("Update", update_c, UID_UPDATE_C),
    ):
        c = Counter(o.get("class_name") for o in data)
        assert c.get("ProfileType", 0) == 0
        assert c.get("WorkflowPage", 0) == 0
        assert c.get("NeAttribute", 0) == 0
        print(
            f"{label}: n={len(data)} uid={uid} steps={c.get('WorkflowStep', 0)} "
            f"actions={sum(v for k,v in c.items() if k.endswith('Action') and k!='WorkflowConditionAction')}"
        )


if __name__ == "__main__":
    main()
