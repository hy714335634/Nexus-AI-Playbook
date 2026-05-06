#!/usr/bin/env python3
"""
Match changed files against mapping `watches` globs.

Reads newline-separated changed file paths from stdin.
Writes the full changes.json structure to stdout.

Usage:
    echo "$CHANGED_FILES" | python3 match_mappings.py <from_sha> <to_sha> <config_path>
"""
import sys
import json
import fnmatch

import yaml


def matches(path: str, patterns: list[str]) -> bool:
    for p in patterns:
        if fnmatch.fnmatch(path, p):
            return True
        # Support recursive ** — fnmatch treats ** same as *, so augment manually.
        if "**" in p:
            prefix = p.split("**", 1)[0].rstrip("/")
            if prefix and path.startswith(prefix + "/"):
                return True
    return False


def main() -> int:
    if len(sys.argv) != 4:
        sys.stderr.write("usage: match_mappings.py <from_sha> <to_sha> <config_path>\n")
        return 2
    from_sha, to_sha, config_path = sys.argv[1:4]

    changed = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    with open(config_path, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    triggered = []
    for m in cfg.get("mappings", []):
        hits = [f for f in changed if matches(f, m.get("watches", []))]
        if hits:
            triggered.append({
                "id": m["id"],
                "description": m.get("description", ""),
                "changed_files": hits,
                "docs": m.get("docs", []),
                "screenshots": m.get("screenshots", []),
            })

    json.dump({
        "from_sha": from_sha,
        "to_sha": to_sha,
        "triggered_mappings": triggered,
    }, sys.stdout, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
