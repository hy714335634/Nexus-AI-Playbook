#!/usr/bin/env python3
"""
Minimal YAML→JSON adapter. Used by bash stages so we don't need a `yq`
install. Reads a YAML file and writes JSON to stdout.

Usage:
    python3 scripts/lib/yaml.py scripts/config.yaml
    python3 scripts/lib/yaml.py scripts/config.yaml .mappings
    python3 scripts/lib/yaml.py scripts/config.yaml '.mappings[] | select(.id=="mcp-feature")'

Path expressions use the `jq` sub-language by piping through jq. If a
jq expression is supplied as the 2nd argument, this script converts
YAML→JSON, then execs `jq -c <expr>` to filter.
"""
import sys
import json
import subprocess

import yaml


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: yaml.py <yaml-file> [jq-expr]\n")
        return 2
    path = sys.argv[1]
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    raw = json.dumps(data, ensure_ascii=False)
    if len(sys.argv) >= 3:
        expr = sys.argv[2]
        proc = subprocess.run(["jq", "-c", expr], input=raw, text=True)
        return proc.returncode
    print(raw)
    return 0


if __name__ == "__main__":
    sys.exit(main())
