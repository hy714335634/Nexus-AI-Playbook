#!/usr/bin/env bash
# Emit a VitePress sidebar JSON fragment for one chapter.
# Output: drafts/sidebar/<chapter>.json + drafts/sidebar/<chapter>-en.json

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

OUT_DIR="$DRAFTS_DIR/sidebar"
mkdir -p "$OUT_DIR"

TITLE_ZH="$(chapter_title "$CHAPTER" zh)"
TITLE_EN="$(chapter_title "$CHAPTER" en)"

python3 - "$CHAPTER" "$CONFIG_FILE" "$OUT_DIR" "$TITLE_ZH" "$TITLE_EN" <<'PYEOF'
import sys, yaml, json, os

chapter, config_path, out_dir, title_zh, title_en = sys.argv[1:6]
cfg = yaml.safe_load(open(config_path))
ch = cfg["chapters"][chapter]

def fragment(lang_title_key, lang_prefix):
    items = []
    for d in ch["docs"]:
        slug = d["slug"]
        title = d[lang_title_key]
        link = f"{lang_prefix}/{chapter}/{slug}" if lang_prefix else f"/{chapter}/{slug}"
        if slug == "index":
            link = f"{lang_prefix}/{chapter}/" if lang_prefix else f"/{chapter}/"
        items.append({"text": title, "link": link})
    return [{"text": ch[lang_title_key], "items": items}]

with open(os.path.join(out_dir, f"{chapter}.json"), "w", encoding="utf-8") as f:
    json.dump(fragment("title_zh", ""), f, ensure_ascii=False, indent=2)

with open(os.path.join(out_dir, f"{chapter}-en.json"), "w", encoding="utf-8") as f:
    json.dump(fragment("title_en", "/en"), f, ensure_ascii=False, indent=2)

print(f"Wrote {chapter}.json and {chapter}-en.json to {out_dir}", file=sys.stderr)
PYEOF
