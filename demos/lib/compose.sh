#!/usr/bin/env bash
# Compose final demo video from per-scene raw/<id>.webm + narration/<id>.<lang>.mp3.
#
# Sync-safe design: burn each scene's subtitle INTO that scene (starting at 0),
# then concat. Per-scene ffmpeg guarantees audio/video/subtitle alignment within
# the scene; concat only joins — no global-timeline drift accumulates.
#
# Scene length = narration duration + tail padding. When the raw video is longer
# than the narration (it usually is, due to SPA hydration at the head), we take
# the TAIL slice so the shown UI is the settled/acted state, not the loading spinner.
#
# Usage: compose.sh <demo-dir> <lang zh|en>
set -euo pipefail
LANG_SEL="${2:?usage: compose.sh <demo-dir> <lang>}"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # resolve before cd
DIR="$(cd "$1" && pwd)"; cd "$DIR"
TAIL_PAD=0.8            # seconds of quiet tail after narration ends
mkdir -p output tmp

IDS=$(python3 -c "import yaml;[print(s['id']) for s in yaml.safe_load(open('narration.yaml'))['scenes']]")

CONCAT="tmp/concat.${LANG_SEL}.txt"; : > "$CONCAT"
TOTAL=0
for id in $IDS; do
  A="narration/${id}.${LANG_SEL}.mp3"
  V="raw/${id}.webm"
  AD=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$A")
  VD=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$V")
  T=$(python3 -c "print(round($AD + $TAIL_PAD, 3))")
  SS=$(python3 -c "print(round(max(0, $VD - $T), 3))")

  # per-scene subtitle (starts at 0), text split on punctuation, time-shared by narration length
  SRT="tmp/${id}.${LANG_SEL}.srt"
  python3 "$LIB_DIR/gen_srt.py" --scene "$id" "$AD" "$LANG_SEL" > "$SRT"

  # video: take tail T seconds (skip hydration head), pad last frame if short;
  # audio: narration + silence to T; subtitle: this scene's srt burned in.
  ffmpeg -y -loglevel error -ss "$SS" -i "$V" -i "$A" \
    -filter_complex "[0:v]tpad=stop_mode=clone:stop_duration=600,trim=0:${T},scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30,setpts=PTS-STARTPTS,subtitles='${SRT}':force_style='FontName=PingFang SC,FontSize=20,Outline=2,Shadow=1,MarginV=42,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000'[v];[1:a]apad=whole_dur=${T},asetpts=PTS-STARTPTS[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -ar 44100 -t "$T" "tmp/${id}.${LANG_SEL}.mp4"
  echo "file '$DIR/tmp/${id}.${LANG_SEL}.mp4'" >> "$CONCAT"
  TOTAL=$(python3 -c "print(round($TOTAL + $T, 1))")
  echo "  ${id}: narration=${AD}s -> scene ${T}s (tail slice from ${SS}s)"
done

# concat scenes (re-encode to normalize timestamps; -c copy can glitch across scene joins)
ffmpeg -y -loglevel error -f concat -safe 0 -i "$CONCAT" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -ar 44100 "output/${LANG_SEL}.mp4"
echo "done: $DIR/output/${LANG_SEL}.mp4  (~${TOTAL}s)"
