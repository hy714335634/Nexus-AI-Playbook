#!/usr/bin/env python3
"""
Sanitize markdown files so VitePress/Vue compiler doesn't choke on
placeholder angle-bracket tokens like `<uuid>`, `<name>`, `<stage>`
that commonly appear in generated docs.

Replacement rules (applied only OUTSIDE fenced code blocks):
- `<word>` -> `<word>` kept inside backtick spans (markdown inline code)
- Bare `<word>` or `<word>...` outside code -> escape `<` -> `&lt;`, `>` -> `&gt;`

Strategy: for each file, track fenced-code state. For lines outside fenced
code, find backtick spans and leave their interiors alone. Outside backticks
too, replace `<ident[...]>` placeholders with HTML-escaped versions.

This is a best-effort fix focused on the common patterns the Opus output
produces: lowercase placeholders like `<uuid>`, `<name|null>`, `<wf>`.

Usage:
    python3 sanitize_md.py <file.md> [<file.md>...]
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


BACKTICK_SPAN = re.compile(r"`[^`\n]+`")
# Matches `<tag>` patterns where tag starts with a lowercase letter and
# is mostly alnum/underscore/hyphen/colon/dots/pipe/space/<etc>
PLACEHOLDER = re.compile(r"<([a-z][a-z0-9_.:|/\-\s]{0,60})>")

# Real HTML/Vue tags that must NEVER be escaped. These are commonly used
# inside VitePress markdown files for layout and theming. Anything else
# that matches the PLACEHOLDER pattern is treated as a placeholder.
KNOWN_TAGS = frozenset({
    "style", "script", "div", "span", "p", "a", "img", "br", "hr",
    "h1", "h2", "h3", "h4", "h5", "h6",
    "ul", "ol", "li", "table", "thead", "tbody", "tr", "td", "th",
    "pre", "code", "em", "strong", "b", "i", "u", "mark",
    "details", "summary", "sup", "sub", "blockquote",
    "figure", "figcaption", "video", "audio", "source",
    "iframe", "embed", "object",
    "section", "article", "aside", "nav", "header", "footer", "main",
    "form", "input", "button", "select", "option", "textarea", "label",
    "ruby", "rt", "rp",
    # VitePress/Vue built-ins
    "template", "slot", "component", "suspense",
    "syncfreshness",
})


def _replace(match: re.Match) -> str:
    body = match.group(1)
    first_word = body.split(":")[0].split("|")[0].split("/")[0].split(".")[0].strip()
    if first_word.lower() in KNOWN_TAGS:
        return match.group(0)
    return "&lt;" + body + "&gt;"


def sanitize_line_outside_code(line: str) -> str:
    """Replace placeholder angle-bracket tokens both inside and outside backticks.

    Empirically VitePress renders markdown inline `<code>` such that the <x>
    inside survives to Vue's parser and gets flagged as an unclosed tag. So we
    must escape inside backticks too.
    """
    return PLACEHOLDER.sub(_replace, line)


def sanitize_text(text: str) -> str:
    in_fenced = False
    out_lines = []
    for line in text.splitlines(keepends=True):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fenced = not in_fenced
            out_lines.append(line)
            continue
        if in_fenced:
            out_lines.append(line)
            continue
        # Outside code: sanitize
        out_lines.append(sanitize_line_outside_code(line))
    return "".join(out_lines)


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: sanitize_md.py <file.md> [<file.md>...]\n")
        return 2
    modified = 0
    for path_str in sys.argv[1:]:
        p = Path(path_str)
        try:
            original = p.read_text(encoding="utf-8")
        except Exception as e:
            sys.stderr.write(f"skip {path_str}: {e}\n")
            continue
        new = sanitize_text(original)
        if new != original:
            p.write_text(new, encoding="utf-8")
            modified += 1
            print(f"sanitized: {path_str}")
    print(f"Modified {modified} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
