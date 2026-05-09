#!/usr/bin/env python3
"""
Read source glob patterns from stdin, expand against Nexus-AI root, and print
each matched file formatted as a markdown chunk with file content in a code block.

Usage:
    echo "nexus_utils/mcp/**" | python3 _format_sources.py /path/to/Nexus-AI
"""
import sys
import os
import glob


MAX_CHARS = 20000  # truncate per-file to keep context bounded


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("usage: _format_sources.py <source_root>\n")
        return 2
    root = sys.argv[1]
    patterns = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    seen = set()
    for pat in patterns:
        abs_pat = os.path.join(root, pat)
        for path in sorted(glob.glob(abs_pat, recursive=True)):
            if not os.path.isfile(path) or path in seen:
                continue
            seen.add(path)
            rel = os.path.relpath(path, root)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    text = f.read()
            except Exception as e:
                text = f"(could not read: {e})"
            if len(text) > MAX_CHARS:
                text = text[:MAX_CHARS] + f"\n\n... (truncated, original {len(text)} chars)"
            print(f"\n## {rel}\n")
            print("```")
            print(text)
            print("```")
    return 0


if __name__ == "__main__":
    sys.exit(main())
