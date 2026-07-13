#!/usr/bin/env python3
"""Generate SRT subtitles for demo videos.

Two modes:

  # Per-scene (used by compose.sh): print ONE scene's SRT starting at 0 to stdout.
  gen_srt.py --scene <scene-id> <narration_seconds> <lang>
     reads narration.yaml in CWD, finds the scene, splits its <lang> text into
     subtitle-sized cues sharing the narration duration.

  # Whole-video (legacy/manual): write <demo-dir>/subtitles/<lang>.srt
  gen_srt.py <demo-dir> <lang>
     concatenated timeline = sum of (narration + 0.8s) per scene.

Per-scene mode is sync-safe: each scene's subtitle is burned into that scene at
its own zero, so concatenation cannot drift.
"""
import sys
import pathlib
import yaml


def ts(sec):
    h = int(sec // 3600); m = int(sec % 3600 // 60); s = sec % 60
    return f"{h:02d}:{m:02d}:{int(s):02d},{int(round(s % 1 * 1000)):03d}"


def split_text(text, limit=24):
    """Split narration into subtitle-sized lines on punctuation, then length."""
    text = text.strip()
    if len(text) <= limit:
        return [text]
    parts, cur = [], ""
    for ch in text:
        cur += ch
        if len(cur) >= limit and ch in "，。；！？,.;!?、":
            parts.append(cur.strip().strip("，。；、")); cur = ""
    if cur.strip():
        parts.append(cur.strip().strip("，。；、"))
    # merge stray very-short tails
    merged = []
    for p in parts:
        if merged and len(p) < 6:
            merged[-1] = merged[-1] + p
        else:
            merged.append(p)
    return merged or [text]


def cues_for(text, dur, start=0.0):
    chunks = split_text(text)
    # weight each cue by its char length so long lines linger longer
    weights = [max(1, len(c)) for c in chunks]
    total_w = sum(weights)
    lines, t, idx = [], start, 1
    for c, w in zip(chunks, weights):
        seg = dur * w / total_w
        lines += [str(idx), f"{ts(t)} --> {ts(t + seg)}", c, ""]
        idx += 1; t += seg
    return lines


def scene_mode(scene_id, narration_sec, lang):
    scenes = yaml.safe_load(open("narration.yaml"))["scenes"]
    s = next(x for x in scenes if x["id"] == scene_id)
    sys.stdout.write("\n".join(cues_for(s[lang], float(narration_sec))))


def whole_mode(demo_dir, lang):
    import subprocess, json
    d = pathlib.Path(demo_dir)
    scenes = yaml.safe_load((d / "narration.yaml").read_text())["scenes"]

    def dur(p):
        o = subprocess.run(["ffprobe", "-v", "quiet", "-show_entries",
                            "format=duration", "-of", "json", str(p)],
                           capture_output=True, text=True)
        return float(json.loads(o.stdout)["format"]["duration"])

    t, lines, idx = 0.0, [], 1
    for s in scenes:
        a = dur(d / f"narration/{s['id']}.{lang}.mp3")
        block = cues_for(s[lang], a, start=t)
        # renumber
        for i in range(0, len(block), 4):
            block[i] = str(idx); idx += 1
        lines += block
        t += a + 0.8
    (d / "subtitles").mkdir(exist_ok=True)
    (d / f"subtitles/{lang}.srt").write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote subtitles/{lang}.srt")


if __name__ == "__main__":
    if sys.argv[1] == "--scene":
        scene_mode(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        whole_mode(sys.argv[1], sys.argv[2])
