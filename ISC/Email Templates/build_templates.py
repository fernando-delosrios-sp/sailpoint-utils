#!/usr/bin/env python3
"""Build language-aware, branded ISC email templates.

Every email template in the tenant is produced from one of two sources:

* a **rewrite** (catalog_*.py): new wording, translated into LANGUAGES, rendered in the branded layout;
* a **wrap** (defaults.snapshot.json): the SailPoint default body kept as-is (English) inside the
  branded layout, with a translated footer.

The recipient's language comes from the `preferredLanguage` identity attribute: `$user` in version 1
templates, `$__util.getIdentityDetailsByID($__recipient.id)` in version 2 templates. Values are matched
on their first two letters; anything unsupported falls back to `$mailDefaultLanguage`, set on the
first line of every template (English unless an admin edits it).

Usage:
    python3 build_templates.py              # write templates/<key>.json and validate with Velocity
    python3 build_templates.py --preview    # also render out/preview/<key>.<lang>.html + index.html
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATES = HERE / "templates"  # API payloads, committed so they can be imported without building
MANIFEST = TEMPLATES / "manifest.json"
OUT = HERE / "out"  # renders and previews

LANGUAGES = ["en", "es", "fr", "it", "de", "pt", "ar", "nl"]
RTL_LANGUAGES = ["ar"]
DEFAULT_LANGUAGE = "en"

@dataclass(frozen=True)
class Setting:
    """A value at the top of every template body, editable in the ISC template editor and set by
    Import-EmailTemplates.ps1. Written as a single-quoted Velocity string (no interpolation; a quote
    is doubled)."""

    variable: str
    default: str
    description: str


SETTINGS = [
    Setting("mailDefaultLanguage", DEFAULT_LANGUAGE, f"language when preferredLanguage is missing or unsupported ({', '.join(LANGUAGES)})"),
    Setting("mailOrgName", "EMEA TES Team", "tenant owner or team name in the banner, sign-off and footer"),
    Setting("mailBannerTagline", "Identity & Access", "small text above the tenant owner name in the banner"),
    Setting("mailColorPrimary", "#0033A1", "banner, headings and buttons"),
    Setting("mailColorDark", "#011E69", "start of the banner gradient"),
    Setting("mailColorAccent", "#0071CE", "links, section titles and information boxes"),
    Setting("mailColorHighlight", "#CC27B0", "banner stripe and warning boxes"),
    Setting("mailSupportEmail", "", "support address shown in the footer; empty hides it"),
]

NAVY_DARK = "$mailColorDark"
NAVY = "$mailColorPrimary"
BLUE = "$mailColorAccent"
MAGENTA = "$mailColorHighlight"
GREEN = "#1E7B4F"
RED = "#B42318"
INK = "#1F2A44"
MUTED = "#5B6478"
PAGE_BG = "#F3F5F9"
FONT = "'Segoe UI', Helvetica, Arial, sans-serif"
MONO = "Consolas,'Courier New',monospace"

SIGNATURE = "$mailOrgName"

# Velocity double-quoted strings are parsed as templates: quotes and '#' would break them.
_FORBIDDEN_IN_STRINGS = re.compile(r'["#]')

# ISC sanitizes the body on save: HTML attributes (width, align, valign, bgcolor, cellpadding...)
# are dropped, and on non-table tags CSS such as display/overflow/opacity is removed.
# Layout therefore lives in inline CSS on <table>/<td>, whose styles are kept verbatim.
TABLE = "border-spacing:0;border-collapse:separate;"
FULL_TABLE = f"width:100%;{TABLE}"

Tr = tuple  # one string per language, in LANGUAGES order


# ---------------------------------------------------------------------------
# Velocity building blocks
# ---------------------------------------------------------------------------

# ISC strips every line break when it updates a custom template created before the import (older
# records), so a `##` line comment would swallow the rest of the body. Comments are block comments.
def setting_line(setting: Setting, comment: bool = True) -> str:
    value = setting.default.replace("'", "''")
    return f"#set(${setting.variable} = '{value}')" + (f" #* {setting.description} *#" if comment else "")


def settings_block(extra: tuple[Setting, ...] = ()) -> str:
    """First lines of every template body."""
    lines = ["#* Email settings: edit the values between quotes. Import-EmailTemplates.ps1 sets them on import. *#"]
    lines += [setting_line(s) for s in (*SETTINGS, *extra)]
    return "\n".join(lines)


def subject_settings(*texts: str, extra: tuple[Setting, ...] = ()) -> str:
    """Settings a subject needs: subjects are evaluated apart from the body, so they set their own."""
    used = [s for s in (*SETTINGS, *extra) if any(re.search(rf"\$!?\{{?{s.variable}\b", t) for t in texts)]
    return "".join(setting_line(s, comment=False) for s in used)


def language_detection(var: str) -> str:
    """Velocity that sets `$<var>` to a supported two-letter code, for V1 and V2 templates."""
    ident = f"{var}Identity"
    supported = ", ".join(f'"{lang}"' for lang in LANGUAGES)
    return (
        f'#if(!$mailDefaultLanguage)#set($mailDefaultLanguage = "{DEFAULT_LANGUAGE}")#end'
        f'#set(${var} = "$mailDefaultLanguage")'
        f'#if($user && $user.preferredLanguage)#set(${var} = "$user.preferredLanguage")'
        f"#elseif($__util && $__recipient && $__recipient.id)"
        f"#set(${ident} = $__util.getIdentityDetailsByID($__recipient.id))"
        f'#if(${ident} && ${ident}.preferredLanguage)#set(${var} = "${ident}.preferredLanguage")'
        f'#elseif(${ident} && ${ident}.attributes && ${ident}.attributes.preferredLanguage)#set(${var} = "${ident}.attributes.preferredLanguage")'
        f"#end"
        f"#end"
        f"#set(${var} = ${var}.toLowerCase())"
        f"#if(${var}.length() > 2)#set(${var} = ${var}.substring(0, 2))#end"
        f"#set($mailSupportedLanguages = [{supported}])"
        f'#if(!$mailSupportedLanguages.contains(${var}))#set(${var} = "$mailDefaultLanguage")#end'
    )


def text_direction(rtl_capable: bool) -> str:
    """Velocity setting layout variables from `$mailLang`. The body follows the language only when
    `rtl_capable` (rewritten templates); the footer always does."""
    rtl = " || ".join(f'$mailLang == "{lang}"' for lang in RTL_LANGUAGES)
    ltr_vars = '#set($mailDir = "ltr")#set($mailAlign = "left")#set($mailAccentL = "4px")#set($mailAccentR = "0")#set($mailLabelPad = "4px 16px 4px 0")#set($mailListPad = "0 0 0 22px")#set($mailArrow = "→")'
    rtl_vars = '#set($mailDir = "rtl")#set($mailAlign = "right")#set($mailAccentL = "0")#set($mailAccentR = "4px")#set($mailLabelPad = "4px 0 4px 16px")#set($mailListPad = "0 22px 0 0")#set($mailArrow = "←")'
    footer = f'#if({rtl})#set($mailFootDir = "rtl")#set($mailFootAlign = "right")#else#set($mailFootDir = "ltr")#set($mailFootAlign = "left")#end'
    body = f"#if({rtl}){rtl_vars}#else{ltr_vars}#end" if rtl_capable else ltr_vars
    return body + footer


def switch(var: str, per_language: dict[str, str], inline: bool = False) -> str:
    """`#if/#elseif/#else` over languages; the default language is the `#else` branch."""
    nl = "" if inline else "\n"
    others = [lang for lang in LANGUAGES if lang != DEFAULT_LANGUAGE]
    out = ""
    for i, lang in enumerate(others):
        keyword = "#if" if i == 0 else "#elseif"
        out += f'{keyword}(${var} == "{lang}"){nl}{per_language[lang]}{nl}'
    return out + f"#{{else}}{nl}{per_language[DEFAULT_LANGUAGE]}{nl}#end{nl}"


def tr(values: Tr) -> str:
    """Inline per-language text, evaluated where it appears (use inside loops: `#set` strings are
    interpolated once, when they are set)."""
    return switch("mailLang", dict(zip(LANGUAGES, values)), inline=True)


def set_strings(strings: dict[str, Tr], lang: str) -> str:
    idx = LANGUAGES.index(lang)
    lines = []
    for key, values in strings.items():
        if len(values) != len(LANGUAGES):
            raise ValueError(f"String {key!r} needs {len(LANGUAGES)} translations, got {len(values)}")
        value = values[idx]
        if _FORBIDDEN_IN_STRINGS.search(value):
            raise ValueError(f"String {key!r} [{lang}] contains a double quote or '#': {value!r}")
        lines.append(f'#set($tx_{key} = "{value}")')
    return "\n".join(lines)


def string_switch(strings: dict[str, Tr]) -> str:
    return switch("mailLang", {lang: set_strings(strings, lang) for lang in LANGUAGES})


# ---------------------------------------------------------------------------
# HTML building blocks (inline CSS only; see sanitizer note above)
# ---------------------------------------------------------------------------

def p(text: str) -> str:
    return f'<p style="margin:0 0 16px 0;font-family:{FONT};font-size:15px;line-height:23px;color:{INK};">{text}</p>'


def section(title: str) -> str:
    return (
        f'<div style="margin:26px 0 12px 0;font-family:{FONT};font-size:12px;line-height:16px;font-weight:700;'
        f'letter-spacing:1.5px;text-transform:uppercase;color:{BLUE};">{title}</div>'
    )


def accent_border(color: str) -> str:
    """4px bar on the side where the text starts (left, or right for RTL languages)."""
    return f"border-style:solid;border-color:{color};border-width:0;border-left-width:$mailAccentL;border-right-width:$mailAccentR;"


def details(rows: list[tuple[str, ...]], title: str | None = None) -> str:
    """Blue box with (label, value) rows; a third element is a Velocity condition for that row.
    When every row is conditional, the box itself is omitted if none of them match."""
    label = f"vertical-align:top;padding:$mailLabelPad;text-align:$mailAlign;font-family:{FONT};font-size:13px;line-height:20px;color:{MUTED};white-space:nowrap;"
    value = f"vertical-align:top;padding:4px 0;text-align:$mailAlign;unicode-bidi:plaintext;font-family:{FONT};font-size:15px;line-height:20px;font-weight:600;color:{NAVY};"
    body = []
    conditions = []
    for row in rows:
        html = f'<tr><td style="{label}">{row[0]}</td><td style="{value}">{row[1]}</td></tr>'
        if len(row) > 2:
            body.append(f"#if({row[2]}){html}#end")
            conditions.append(row[2])
        else:
            body.append(html)
    heading = (
        f'<div style="margin:0 0 8px 0;font-family:{FONT};font-size:12px;line-height:16px;font-weight:700;'
        f'letter-spacing:1.5px;text-transform:uppercase;color:{BLUE};">{title}</div>'
        if title
        else ""
    )
    rows_html = "\n".join(body)
    table = f"""<table style="{FULL_TABLE}margin:4px 0 18px 0;background-color:#F2F7FD;{accent_border(BLUE)}border-radius:6px;">
<tr><td style="padding:16px 20px;text-align:$mailAlign;">
{heading}<table style="{TABLE}">
{rows_html}
</table>
</td></tr>
</table>"""
    if len(conditions) == len(rows):
        guard = " || ".join(f"({condition})" for condition in conditions)
        return f"#if({guard})\n{table}#end"
    return table


def code(value: str) -> str:
    return f"""<table style="{TABLE}margin:4px 0 18px 0;">
<tr><td style="direction:ltr;padding:14px 26px;border-radius:8px;background-color:#F2F7FD;border:1px dashed {BLUE};font-family:{MONO};font-size:26px;line-height:32px;font-weight:700;letter-spacing:4px;color:{NAVY};">{value}</td></tr>
</table>"""


def button(url: str, label: str) -> str:
    return f"""<table style="{TABLE}margin:6px 0 22px 0;">
<tr><td style="padding:13px 28px;border-radius:6px;background-color:{NAVY};font-family:{FONT};font-size:15px;line-height:20px;font-weight:600;">
<a href="{url}" style="color:#FFFFFF;text-decoration:none;">{label} $mailArrow</a>
</td></tr>
</table>"""


def link_fallback(text: str, url: str) -> str:
    return (
        f'<p style="margin:0 0 16px 0;font-family:{FONT};font-size:13px;line-height:20px;color:{MUTED};">'
        f'{text}<br/><a href="{url}" style="color:{BLUE};word-break:break-all;">{url}</a></p>'
    )


def note(text: str, accent: str = MAGENTA, background: str = "#FCF0FA") -> str:
    return f"""<table style="{FULL_TABLE}margin:4px 0 18px 0;background-color:{background};{accent_border(accent)}border-radius:6px;">
<tr><td style="padding:14px 20px;text-align:$mailAlign;font-family:{FONT};font-size:14px;line-height:21px;color:{INK};">{text}</td></tr>
</table>"""


def info(text: str) -> str:
    return note(text, BLUE, "#F2F7FD")


def quote(text: str) -> str:
    return note(f"<em>{text}</em>", MUTED, "#F5F6F8")


def subheading(text: str) -> str:
    return f'<p style="margin:0 0 6px 0;font-family:{FONT};font-size:14px;line-height:20px;font-weight:700;color:{NAVY};">{text}</p>'


def bullets(items: str) -> str:
    """`items` is Velocity/HTML producing <li> elements."""
    return f'<ul style="margin:0 0 18px 0;padding:$mailListPad;font-family:{FONT};font-size:15px;line-height:23px;color:{INK};">{items}</ul>'


def li(text: str) -> str:
    return f'<li style="margin:0 0 4px 0;">{text}</li>'


def ok(text: str) -> str:
    return f'<strong style="color:{GREEN};">{text}</strong>'


def bad(text: str) -> str:
    return f'<strong style="color:{RED};">{text}</strong>'


def banner() -> str:
    return f"""<tr>
<td style="background-color:{NAVY};background-image:linear-gradient(120deg,{NAVY_DARK} 0%,{NAVY} 55%,{BLUE} 100%);padding:30px 36px 26px 36px;">
<div style="font-family:{FONT};font-size:11px;line-height:16px;letter-spacing:3px;text-transform:uppercase;color:#A9C8F2;">$mailBannerTagline</div>
<div style="font-family:{FONT};font-size:26px;line-height:34px;font-weight:600;letter-spacing:0.5px;color:#FFFFFF;">$mailOrgName</div>
</td>
</tr>
<tr>
<td style="height:4px;line-height:4px;font-size:0;background-color:{MAGENTA};background-image:linear-gradient(90deg,{BLUE} 0%,{MAGENTA} 100%);">&nbsp;</td>
</tr>"""


def layout(inner: str, closing: bool) -> str:
    sign_off = (
        f'<p style="margin:26px 0 4px 0;font-family:{FONT};font-size:15px;line-height:23px;color:{INK};">$tx_closing</p>\n'
        f'<p style="margin:0 0 24px 0;font-family:{FONT};font-size:15px;line-height:23px;font-weight:600;color:{NAVY};">{SIGNATURE}</p>\n'
        if closing
        else ""
    )
    return f"""<table style="{FULL_TABLE}background-color:{PAGE_BG};">
<tr>
<td style="padding:28px 12px;">
<table style="{FULL_TABLE}max-width:600px;margin:0 auto;background-color:#FFFFFF;border-radius:10px;overflow:hidden;border:1px solid #E3E7EF;">
{banner()}
<tr>
<td style="direction:$mailDir;text-align:$mailAlign;padding:34px 36px 12px 36px;font-family:{FONT};font-size:15px;line-height:23px;color:{INK};">
{inner}
{sign_off}</td>
</tr>
<tr>
<td style="direction:$mailFootDir;text-align:$mailFootAlign;padding:16px 36px;background-color:#F7F8FB;border-top:1px solid #E3E7EF;font-family:{FONT};font-size:12px;line-height:18px;color:{MUTED};">$tx_footer#if($mailSupportEmail && $mailSupportEmail != '') $tx_needHelp <a href="mailto:$mailSupportEmail" style="color:{BLUE};">$mailSupportEmail</a>#end</td>
</tr>
</table>
</td>
</tr>
</table>"""


def greeting(text: str = "$tx_hello") -> str:
    return f'<h1 style="margin:0 0 14px 0;font-family:{FONT};font-size:21px;line-height:28px;font-weight:600;color:{NAVY};">{text}</h1>'


# ---------------------------------------------------------------------------
# Template definitions
# ---------------------------------------------------------------------------

@dataclass
class Rewrite:
    key: str
    subject: Tr
    content: str
    strings: dict[str, Tr] = field(default_factory=dict)
    greet: str | None = None  # Velocity expression for the recipient's name; None = no greeting
    prelude: str = ""  # Velocity run after common strings and before template strings
    closing: bool = True
    sample: dict[str, str] = field(default_factory=dict)  # preview context overrides
    meta: dict = field(default_factory=dict)  # payload overrides (name, description...)
    settings: tuple[Setting, ...] = ()  # template-specific settings, after SETTINGS
    variant: str | None = None  # alternative version of `key`, written to templates/variants/
    multilingual_subject: bool = False  # see rewrite_subject

    @property
    def name(self) -> str:
        return f"{self.key}.{self.variant}" if self.variant else self.key


def rewrite_body(t: Rewrite, common: dict[str, Tr]) -> str:
    parts = [settings_block(t.settings), language_detection("mailLang") + text_direction(rtl_capable=True)]
    if t.greet:
        parts.append(f'#set($mailName = "{t.greet}")')
    parts.append(string_switch(common))
    if t.prelude:
        parts.append(t.prelude.strip())
    if t.strings:
        parts.append(string_switch(t.strings))
    inner = (greeting() + "\n" if t.greet else "") + t.content.strip()
    return "\n".join(parts) + "\n" + layout(inner, t.closing)


SUBJECT_LIMIT = 255


def english_subject(t: Rewrite) -> str:
    subject = subject_settings(t.subject[0], extra=t.settings) + t.subject[0]
    if len(subject) > SUBJECT_LIMIT or "$tx_" in subject:
        raise SystemExit(f"{t.name}: English subject must be standalone and <= {SUBJECT_LIMIT} chars: {subject!r}")
    return subject


def rewrite_subject(t: Rewrite) -> str:
    """New custom versions of SailPoint default templates store at most 255 subject characters, which
    cannot hold language detection plus a translation for every language, so most templates get the English subject.
    `multilingual_subject` templates (User Invitation) translate it: that fits an existing record,
    and Import-EmailTemplates.ps1 falls back to english_subject when it must create one."""
    if not t.multilingual_subject:
        return english_subject(t)
    settings = subject_settings("$mailDefaultLanguage", *t.subject, extra=t.settings)
    return settings + language_detection("mailSubjectLang") + switch(
        "mailSubjectLang", dict(zip(LANGUAGES, t.subject)), inline=True
    )


_TEAM_SIGNATURE = re.compile(r"The\s+\$\{?(?:PRODUCT_NAME|__global\.productName)\}?\s+Team")
_DOC_WRAPPER = re.compile(r"<!DOCTYPE[^>]*>|<!--.*?-->|</?html[^>]*>|<head>.*?</head>|</?body[^>]*>", re.S | re.I)
_HAS_MARKUP = re.compile(r"<(p|br|div|table|ul|li|b|strong|a)\b", re.I)


def wrap_body(default_body: str, wrap_common: dict[str, Tr]) -> str:
    body = _DOC_WRAPPER.sub("", default_body or "").strip()
    body = _TEAM_SIGNATURE.sub(SIGNATURE, body)
    if not _HAS_MARKUP.search(body):
        body = f'<table style="{FULL_TABLE}"><tr><td style="white-space:pre-wrap;font-family:{FONT};font-size:14px;line-height:21px;color:{INK};">{body}</td></tr></table>'
    return (
        settings_block() + "\n"
        + language_detection("mailLang") + text_direction(rtl_capable=False) + "\n"
        + string_switch(wrap_common) + layout(body, closing=False)
    )


def payload(default: dict | None, subject: str, body: str, meta: dict) -> dict:
    base = {
        "key": default["key"] if default else meta["key"],
        "name": default.get("name") if default else None,
        "description": default.get("description") if default else None,
        "medium": "EMAIL",
        "locale": "en",
        "from": "$__global.emailFromAddress",
        "replyTo": "$__global.emailFromAddress",
        "header": None,
        "footer": None,
        "subject": subject,
        "body": body,
    }
    base.update({k: v for k, v in meta.items() if k != "key"})
    return base


# ---------------------------------------------------------------------------
# Validation and previews (real Velocity via tools/Render.java)
# ---------------------------------------------------------------------------

M2 = Path.home() / ".m2" / "repository"
CLASSPATH = ":".join(
    str(M2 / p)
    for p in (
        "org/apache/velocity/velocity-engine-core/2.0/velocity-engine-core-2.0.jar",
        "org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar",
        "org/apache/commons/commons-lang3/3.5/commons-lang3-3.5.jar",
    )
)

SAMPLE = {
    "PRODUCT_NAME": "SailPoint",
    "__global.productName": "SailPoint",
    "__global.productUrl": "https://company24509-poc.identitynow-demo.com",
    "identityNowUrl": "https://company24509-poc.identitynow-demo.com",
    "user.name": "Ana García",
    "user.uid": "ana.garcia",
    "__recipient.name": "Ana García",
    "__recipient.id": "2c9180835d2e5168015d32f890ca1581",
    "__recipient.alias": "ana.garcia",
    "requesterName": "Marco Rossi",
    "requestedForIdentityName": "Ana García",
    "requestedObjectName": "Finance Reporting",
    "requestedObjectType": "Role",
    "accessProfileName": "Finance Reporting",
    "approved": "bool:true",
    "roleRequestEnabled": "bool:true",
    "rejecterName": "Lena Müller",
    "reviewerComment": "Please request the read-only version instead.",
    "startDate": "Oct 20, 2026",
    "removeDate": "Dec 31, 2026",
    "dateRequested": "Oct 14, 2026",
    "accessibleItems": "list:FIN-Reports-Read,FIN-Ledger-View",
    "token": "482913",
    "expires": "Oct 14, 2026 10:15 CEST",
    "sourcename": "Active Directory",
    "approvalName": "Finance Reporting access",
    "entitlementName": "AWS-Prod-Admin",
    "ownerName": "Lena Müller",
    "activationUrl": "https://company24509-poc.identitynow-demo.com/ui/d/launchpad",
    "registrationUrl": "https://company24509-poc.identitynow-demo.com/r/passwordreset?token=abc123&ref=0000&ver=1.0",
}


def _version2(text: str) -> bool:
    for var in ("mailLang", "mailSubjectLang"):
        text = text.replace(language_detection(var), "")
    return bool(re.search(r"\$!?\{?__(recipient|global|contentJson|util|dateTool|numberTool)", text))


def render_all(items: dict[str, dict], samples: dict[str, dict], preview: bool) -> None:
    work = OUT / "render"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    jobs = []
    langs = LANGUAGES if preview else [DEFAULT_LANGUAGE, "es"]
    for key, item in items.items():
        v2 = _version2(item["body"] + item["subject"])
        for part in ("subject", "body"):
            (work / f"{key}.{part}.vm").write_text(item[part], encoding="utf-8")
        (work / f"{key}.flat.vm").write_text(item["body"].replace("\r", "").replace("\n", ""), encoding="utf-8")
        for lang in langs:
            ctx = dict(SAMPLE)
            ctx.update(samples.get(key, {}))
            ctx["identity.preferredLanguage"] = lang
            if v2:
                ctx = {k: v for k, v in ctx.items() if not k.startswith("user.")}
            else:
                ctx["user.preferredLanguage"] = lang
            ctx_file = work / f"{key}.{lang}.ctx"
            ctx_file.write_text("".join(f"{k}\t{v}\n" for k, v in ctx.items()), encoding="utf-8")
            for part in ("subject", "body"):
                jobs.append(f"{work / f'{key}.{part}.vm'}\t{ctx_file}\t{work / f'{key}.{lang}.{part}.out'}")
            jobs.append(f"{work / f'{key}.flat.vm'}\t{ctx_file}\t{work / f'{key}.{lang}.flat.out'}")
    jobs_file = work / "jobs.tsv"
    jobs_file.write_text("\n".join(jobs) + "\n", encoding="utf-8")
    result = subprocess.run(
        ["java", "-cp", CLASSPATH, str(HERE / "tools" / "Render.java"), str(jobs_file)],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stderr)
        raise SystemExit("Velocity validation failed")
    print(f"validated {len(items)} templates with Velocity ({len(jobs)} renders)")

    for key in items:
        for lang in langs:
            subj = (work / f"{key}.{lang}.subject.out").read_text(encoding="utf-8")
            if "\n" in subj.strip() or "$tx_" in subj:
                raise SystemExit(f"{key} [{lang}] subject renders badly: {subj!r}")
            body = (work / f"{key}.{lang}.body.out").read_text(encoding="utf-8")
            leftovers = re.findall(r"[$]!?\{?(?:tx_|mail)[A-Za-z0-9]+|[$]\{\{", subj + body)
            if leftovers:
                raise SystemExit(f"{key} [{lang}] has unresolved variables: {leftovers[:5]}")
            flat = (work / f"{key}.{lang}.flat.out").read_text(encoding="utf-8")
            if re.sub(r"\s", "", flat) != re.sub(r"\s", "", body):
                raise SystemExit(f"{key} [{lang}] renders differently once ISC strips its line breaks")

    if not preview:
        return
    pdir = OUT / "preview"
    shutil.rmtree(pdir, ignore_errors=True)
    pdir.mkdir()
    index = []
    for key, item in items.items():
        links = []
        for lang in LANGUAGES:
            subj = (work / f"{key}.{lang}.subject.out").read_text(encoding="utf-8").strip()
            body = (work / f"{key}.{lang}.body.out").read_text(encoding="utf-8")
            (pdir / f"{key}.{lang}.html").write_text(
                f'<!doctype html><html><head><meta charset="utf-8"><title>{subj}</title></head>'
                f'<body style="margin:0"><div style="font:13px sans-serif;padding:8px 16px;background:#222;color:#eee">'
                f"<b>Subject:</b> {subj}</div>{body}</body></html>",
                encoding="utf-8",
            )
            links.append(f'<a href="{key}.{lang}.html">{lang}</a>')
        index.append(f"<li><b>{item.get('name') or key}</b> <code>{key}</code> — {' · '.join(links)}</li>")
    (pdir / "index.html").write_text(
        f'<!doctype html><meta charset="utf-8"><title>Email previews</title><ul style="font:14px sans-serif;line-height:1.8">{"".join(index)}</ul>',
        encoding="utf-8",
    )
    print(f"wrote previews to {pdir.relative_to(HERE)}/index.html")


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

def load_rewrites() -> tuple[dict[str, Tr], dict[str, Tr], list[Rewrite]]:
    import catalog_access
    import catalog_common
    import catalog_identity
    import catalog_work

    rewrites: list[Rewrite] = []
    for module in (catalog_common, catalog_identity, catalog_access, catalog_work):
        rewrites.extend(module.TEMPLATES)
        rewrites.extend(getattr(module, "VARIANTS", []))
    names = [t.name for t in rewrites]
    dupes = {n for n in names if names.count(n) > 1}
    if dupes:
        raise SystemExit(f"duplicate rewrites: {dupes}")
    return catalog_common.COMMON, catalog_common.WRAP_COMMON, rewrites


def build() -> tuple[dict[str, dict], dict[str, dict], list[Rewrite]]:
    """Payloads by file name (`key`, or `key.variant`), preview samples, and the rewrites."""
    sys.path.insert(0, str(HERE))
    common, wrap_common, rewrites = load_rewrites()
    defaults = {t["key"]: t for t in json.loads((HERE / "defaults.snapshot.json").read_text(encoding="utf-8"))}

    items: dict[str, dict] = {}
    for t in rewrites:
        items[t.name] = payload(defaults.get(t.key), rewrite_subject(t), rewrite_body(t, common), {"key": t.key, **t.meta})
    rewritten = {t.key for t in rewrites}
    for key, d in defaults.items():
        if key not in rewritten:
            items[key] = payload(d, d["subject"], wrap_body(d["body"], wrap_common), {})
    return dict(sorted(items.items())), {t.name: t.sample for t in rewrites}, rewrites


_SET_STRING = re.compile(r'#set\(\$\w+\s*=\s*"([^"]*)"\)')
_TAG_WITH_ATTRIBUTE = re.compile(r"<\w+[^>]*\s[\w-]+\s*=")


def check_sanitizer_safe(items: dict[str, dict]) -> None:
    """ISC's HTML sanitizer re-quotes tag attributes even inside Velocity strings, which ends the
    #set string early; strings may only carry bare tags such as <strong>."""
    for key, item in items.items():
        for part in ("subject", "body"):
            for m in _SET_STRING.finditer(item[part]):
                if _TAG_WITH_ATTRIBUTE.search(m.group(1)):
                    raise SystemExit(f"{key}: tag with attributes inside a Velocity string: {m.group(0)[:120]!r}")


def main() -> None:
    items, samples, rewrites = build()
    check_sanitizer_safe(items)
    shutil.rmtree(TEMPLATES, ignore_errors=True)
    (TEMPLATES / "variants").mkdir(parents=True)
    variants = {t.name: t for t in rewrites if t.variant}
    for name, item in items.items():
        path = TEMPLATES / ("variants" if name in variants else "") / f"{name}.json"
        path.write_text(json.dumps(item, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    rewritten = sorted({t.key for t in rewrites})
    manifest = {
        "languages": LANGUAGES,
        "settings": [{"variable": s.variable, "default": s.default, "description": s.description} for s in SETTINGS],
        "subjectLimit": SUBJECT_LIMIT,
        # English subjects for creating templates whose multilingual subject exceeds the limit, by file name.
        "subjectFallback": {t.name: english_subject(t) for t in rewrites if len(items[t.name]["subject"]) > SUBJECT_LIMIT},
        "variants": {
            t.key: {
                "name": t.variant,
                "file": f"variants/{t.name}.json",
                "settings": [{"variable": s.variable, "default": s.default, "description": s.description} for s in t.settings],
            }
            for t in variants.values()
        },
        "rewritten": rewritten,
        "wrapped": sorted(set(items) - set(rewritten) - set(variants)),
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {len(items)} templates ({len(rewritten)} rewritten, {len(manifest['wrapped'])} wrapped, {len(variants)} variants) to templates/")
    render_all(items, samples, preview="--preview" in sys.argv)


if __name__ == "__main__":
    main()
