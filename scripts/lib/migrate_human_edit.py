#!/usr/bin/env python3
"""
Migrate a hand-written markdown doc from /manual/ (or elsewhere) into a v3 /using/
doc that survives regen.

Wraps the full body (below any existing frontmatter) in a single
`<!-- HUMAN-EDIT-START: <label> --> ... <!-- HUMAN-EDIT-END: <label> -->` block,
and prepends a sync-style frontmatter stub marking the file as migrated.

Usage:
    python3 migrate_human_edit.py <input.md> <output.md> <slug>

Example:
    python3 scripts/lib/migrate_human_edit.py \
        docs/manual/chat.md docs/using/chat.md chat
"""
from __future__ import annotations

import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def split_frontmatter(text: str) -> tuple[str, str]:
    """Return (frontmatter_including_fences, rest). Empty frontmatter if absent."""
    if text.startswith("---\n"):
        m = re.match(r"^---\n.*?\n---\n", text, re.DOTALL)
        if m:
            return text[: m.end()], text[m.end():]
    return "", text


def build_frontmatter(slug: str, existing_fm: str) -> str:
    """If input had frontmatter, merge title; always add sync stub."""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    title_match = re.search(r"^title:\s*(.+)$", existing_fm, re.MULTILINE) if existing_fm else None
    title = title_match.group(1).strip() if title_match else slug.replace("-", " ").title()
    return (
        "---\n"
        f"title: {title}\n"
        "sync:\n"
        "  source_commit: migrated-from-manual\n"
        f"  source_files:\n    - docs/manual/{slug}.md\n"
        f"  generated_at: {ts}\n"
        "  generated_by: migrate_human_edit v3\n"
        "  protected: true\n"
        "---\n"
    )


def wrap_body(body: str, slug: str) -> str:
    # Strip leading blank lines from body so HUMAN-EDIT block starts cleanly.
    body = body.lstrip("\n")
    return (
        f"<!-- HUMAN-EDIT-START: manual-{slug} -->\n"
        f"{body}"
        f"{'' if body.endswith(chr(10)) else chr(10)}"
        f"<!-- HUMAN-EDIT-END: manual-{slug} -->\n"
    )


def main() -> int:
    if len(sys.argv) != 4:
        sys.stderr.write("usage: migrate_human_edit.py <input.md> <output.md> <slug>\n")
        return 2
    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    slug = sys.argv[3]

    text = in_path.read_text(encoding="utf-8")
    fm, rest = split_frontmatter(text)
    new_fm = build_frontmatter(slug, fm)
    new_body = wrap_body(rest, slug)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(new_fm + "\n" + new_body, encoding="utf-8")
    print(f"Migrated {in_path} -> {out_path} (slug={slug})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
