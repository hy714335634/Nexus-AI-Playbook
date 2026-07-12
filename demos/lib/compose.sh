#!/usr/bin/env bash
# Compose final demo video: per-scene raw/<id>.webm + narration/<id>.<lang>.mp3
#   -> output/<lang>.mp4  (1080p30, aac, burned-in subtitles)
# Video segments shorter than their narration are padded with the last frame.
# Usage: compose.sh <demo-dir> <lang zh|en>
set -euo pipefail
DIR="$(cd "$1" && pwd)"; LANG_SEL="$2"; cd "$DIR"
mkdir -p output tmp

IDS=$(python3 -c "import yaml;[print(s['id']) for s in yaml.safe_load(open('narration.yaml'))['scenes']]")

# probe raw segment durations -> raw/segments.json (gen_srt.py consumes it)
python3 - <<'PY'
import json, subprocess, yaml
def dur(p):
    o = subprocess.run(["ffprobe","-v","quiet","-show_entries","format=duration","-of","json",p],
                       capture_output=True, text=True)
    return float(json.loads(o.stdout)["format"]["duration"])
ids = [s["id"] for s in yaml.safe_load(open("narration.yaml"))["scenes"]]
json.dump({i: dur(f"raw/{i}.webm") for i in ids}, open("raw/segments.json","w"))
PY

python3 "$(dirname "${BASH_SOURCE[0]}")/gen_srt.py" "$DIR" "$LANG_SEL"

CONCAT="tmp/concat.${LANG_SEL}.txt"; : > "$CONCAT"
for id in $IDS; do
  A="narration/${id}.${LANG_SEL}.mp3"
  AD=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$A")
  VD=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "raw/${id}.webm")
  # target = max(video, audio)
  T=$(python3 -c "print(max($AD,$VD))")
  ffmpeg -y -loglevel error -i "raw/${id}.webm" -i "$A" \
    -filter_complex "[0:v]tpad=stop_mode=clone:stop_duration=600,trim=0:${T},scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30,format=yuv420p[v];[1:a]apad=whole_dur=${T}[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset fast -crf 20 -c:a aac -t "$T" "tmp/${id}.${LANG_SEL}.mp4"
  echo "file '$DIR/tmp/${id}.${LANG_SEL}.mp4'" >> "$CONCAT"
  echo "segment ${id}: video=${VD}s audio=${AD}s -> ${T}s"
done

ffmpeg -y -loglevel error -f concat -safe 0 -i "$CONCAT" \
  -vf "subtitles=subtitles/${LANG_SEL}.srt:force_style='FontSize=18,Outline=1,MarginV=30'" \
  -c:v libx264 -preset medium -crf 20 -c:a copy "output/${LANG_SEL}.mp4"
echo "done: $DIR/output/${LANG_SEL}.mp4"
