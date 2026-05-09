#!/usr/bin/env python3
"""
Read source patterns from stdin (one per line) and print absolute file paths
matching those globs under the Nexus-AI source root.

Usage:
    echo "nexus_utils/mcp/**" | python3 _expand_sources.py /path/to/Nexus-AI
"""
import sys
import glob
import os


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("usage: _expand_sources.py <source_root>\n")
        return 2
    root = sys.argv[1]
    patterns = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    seen = set()
    for pattern in patterns:
        abs_pattern = os.path.join(root, pattern)
        for p in sorted(glob.glob(abs_pattern, recursive=True)):
            if os.path.isfile(p) and p not in seen:
                seen.add(p)
                print(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
