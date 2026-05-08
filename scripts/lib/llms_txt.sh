#!/usr/bin/env bash
# Generate /public/llms.txt (index) and /public/llms-full.txt (concatenation).
# Run at the end of every sync run, or via sync.sh --emit-llms-txt.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$LLMS_TXT_DIR"

INDEX="$LLMS_TXT_DIR/llms.txt"
FULL="$LLMS_TXT_DIR/llms-full.txt"

python3 - "$DOCS_DIR" "$INDEX" "$FULL" <<'PYEOF'
import os, sys, re

docs_root, index_path, full_path = sys.argv[1:4]

def walk():
    out = []
    for root, dirs, files in os.walk(docs_root):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('public', 'node_modules', 'en')]
        for name in sorted(files):
            if not name.endswith('.md'):
                continue
            rel = os.path.relpath(os.path.join(root, name), docs_root)
            out.append(rel)
    return sorted(out)

def first_h1(text):
    m = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    return m.group(1).strip() if m else None

def first_para_after_h1(text):
    lines = text.splitlines()
    seen_h1 = False
    buf = []
    for line in lines:
        if line.startswith('---'):
            continue
        if not seen_h1:
            if line.startswith('# '):
                seen_h1 = True
            continue
        s = line.strip()
        if not s:
            if buf: break
            else: continue
        if s.startswith('#'):
            if buf: break
            else: continue
        buf.append(s)
    return ' '.join(buf)[:200]

entries = []
full_chunks = []
for rel in walk():
    path = os.path.join(docs_root, rel)
    try:
        text = open(path, encoding='utf-8').read()
    except Exception:
        continue
    title = first_h1(text) or rel
    lead = first_para_after_h1(text) or ''
    url = '/' + rel[:-3]
    entries.append((title, url, lead, rel))
    full_chunks.append(f"\n\n========== {rel} ==========\n\n{text}")

with open(index_path, 'w', encoding='utf-8') as f:
    f.write("# Nexus-AI Playbook — Docs Index for LLMs\n\n")
    f.write("One line per document: `- [Title](URL) — summary`.\n\n")
    for title, url, lead, rel in entries:
        f.write(f"- [{title}]({url}) — {lead}\n")

with open(full_path, 'w', encoding='utf-8') as f:
    f.write("# Nexus-AI Playbook — Full Docs Aggregation for LLMs\n")
    f.write("Concatenated content of all markdown files under docs/.\n")
    for chunk in full_chunks:
        f.write(chunk)

print(f"Wrote {len(entries)} entries to {index_path}")
print(f"Wrote {sum(len(c) for c in full_chunks)} chars to {full_path}")
PYEOF
