#!/usr/bin/env python3
"""Convert <!-- SCREENSHOT: name --> placeholders into real image references.

If docs/public/images/<name>.png exists, replace the placeholder with a
markdown image (kept on its own line). Otherwise leave the comment in place
(it renders invisibly) and report it as missing so the operator can add a
capture target or rename to an existing one.

Aliases map generator-invented names onto existing capture targets.

Usage: screenshot_refs.py <file.md> [...]   (edits in place, prints summary)
"""
import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
IMAGES = ROOT / "docs" / "public" / "images"

ALIASES = {
    "create-agent": "agents-new",
    "build-progress": "project-detail-stages",
    "project-detail": "project-detail-stages",
    "agent-detail": "agents-list",
    "app-center": "apps-list",
    "app-publish": "app-detail",
    "home": "dashboard",
    "avatar": "home-avatar",
    "avatar-space": "home-avatar",
    "spotlight": "dashboard",
    "settings-config-page": "settings-config",
    "service-status": "admin-service-status",
    "billing": "admin-billing",
    "audit": "settings-audit",
    "model-catalog": "settings-model-catalog",
    "browser-extension": "settings-browser-extension",
    "mcp": "ability-mcp",
    "tools": "ability-tools",
    "skills": "ability-skills",
    "sharing": "settings-sharing",
}

PLACEHOLDER = re.compile(r"<!--\s*SCREENSHOT:\s*([A-Za-z0-9_-]+)\s*-->")


def resolve(name: str):
    for candidate in (name, ALIASES.get(name, "")):
        if candidate and (IMAGES / f"{candidate}.png").exists():
            return candidate
    return None


def process(path: pathlib.Path):
    text = path.read_text(encoding="utf-8")
    missing, replaced = [], 0

    def sub(m):
        nonlocal replaced
        target = resolve(m.group(1))
        if target is None:
            missing.append(m.group(1))
            return m.group(0)
        replaced += 1
        return f"![{target}](/images/{target}.png)"

    new = PLACEHOLDER.sub(sub, text)
    if new != text:
        path.write_text(new, encoding="utf-8")
    return replaced, missing


def main(argv):
    total_r, total_m = 0, {}
    for arg in argv:
        p = pathlib.Path(arg)
        r, miss = process(p)
        total_r += r
        for m in miss:
            total_m.setdefault(m, []).append(str(p))
    print(f"replaced: {total_r}")
    if total_m:
        print("missing targets:")
        for name, files in sorted(total_m.items()):
            print(f"  {name}  ({len(files)} refs, e.g. {files[0]})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
