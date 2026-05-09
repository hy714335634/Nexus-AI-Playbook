#!/usr/bin/env python3
"""
Extract HUMAN-EDIT-START/END blocks from a markdown file.

Usage:
    python3 human_edit.py extract <file>
        -> prints JSON: [{"label": "...", "content": "..."}]
    python3 human_edit.py count <file>
        -> prints integer (number of blocks)
    python3 human_edit.py verify <original> <regenerated>
        -> exit 0 if all blocks from <original> are present verbatim in <regenerated>,
           exit 1 otherwise; prints missing labels on stderr
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

BLOCK_RE = re.compile(
    r"<!-- HUMAN-EDIT-START: (?P<label>[^\n>]+?) -->\n(?P<body>.*?)\n<!-- HUMAN-EDIT-END: (?P=label) -->",
    re.DOTALL,
)


def extract(path: str) -> list[dict]:
    p = Path(path)
    if not p.exists():
        return []
    text = p.read_text(encoding="utf-8")
    return [
        {"label": m.group("label").strip(), "content": m.group("body")}
        for m in BLOCK_RE.finditer(text)
    ]


def verify(orig_path: str, new_path: str) -> int:
    orig_blocks = extract(orig_path)
    new_blocks = extract(new_path)
    new_map = {b["label"]: b["content"] for b in new_blocks}
    missing = []
    for ob in orig_blocks:
        if new_map.get(ob["label"]) != ob["content"]:
            missing.append(ob["label"])
    if missing:
        sys.stderr.write(
            "Missing or altered HUMAN-EDIT blocks: " + ", ".join(missing) + "\n"
        )
        return 1
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__ or "")
        return 2
    cmd = sys.argv[1]
    if cmd == "extract":
        if len(sys.argv) != 3:
            return 2
        json.dump(extract(sys.argv[2]), sys.stdout, ensure_ascii=False, indent=2)
        print()
        return 0
    if cmd == "count":
        if len(sys.argv) != 3:
            return 2
        print(len(extract(sys.argv[2])))
        return 0
    if cmd == "verify":
        if len(sys.argv) != 4:
            return 2
        return verify(sys.argv[2], sys.argv[3])
    sys.stderr.write(f"Unknown command: {cmd}\n")
    return 2


if __name__ == "__main__":
    sys.exit(main())
