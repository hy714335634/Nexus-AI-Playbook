#!/usr/bin/env bash
# Per-scene TTS synthesis from narration.yaml.
# Usage: tts.sh <demo-dir> <lang zh|en>
# narration.yaml schema: scenes: [{id, title, zh, en, max_sec}]
set -euo pipefail
DIR="$1"; LANG_SEL="$2"
VOICE_zh="zh-CN-YunjianNeural"; VOICE_en="en-US-AndrewNeural"
VOICE_VAR="VOICE_$LANG_SEL"; VOICE="${!VOICE_VAR}"
mkdir -p "$DIR/narration"
python3 - "$DIR/narration.yaml" "$LANG_SEL" <<'PY' | while IFS=$'\t' read -r id text; do
import sys, yaml
for s in yaml.safe_load(open(sys.argv[1]))["scenes"]:
    print(f"{s['id']}\t{s[sys.argv[2]]}")
PY
  uvx edge-tts --voice "$VOICE" --text "$text" --write-media "$DIR/narration/${id}.${LANG_SEL}.mp3"
  echo "tts: ${id}.${LANG_SEL}.mp3"
done
