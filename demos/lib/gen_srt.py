#!/usr/bin/env python3
"""Generate SRT subtitles from narration.yaml + measured mp3 durations.

Usage: gen_srt.py <demo-dir> <lang>     (writes <demo-dir>/subtitles/<lang>.srt)

Scene N's subtitle shows from that scene's start until its narration audio
ends. Scene start = cumulative max(video_seg, audio) of prior scenes, matching
compose.sh which pads each video segment to at least its narration length.
Long narration lines are split into <=42-char cues proportionally.
"""
import sys, json, subprocess, pathlib
import yaml


def dur(p):
    out = subprocess.run(["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
                          "-of", "json", str(p)], capture_output=True, text=True)
    return float(json.loads(out.stdout)["format"]["duration"])


def ts(sec):
    h = int(sec // 3600); m = int(sec % 3600 // 60); s = sec % 60
    return f"{h:02d}:{m:02d}:{int(s):02d},{int(s % 1 * 1000):03d}"


def split_text(text, limit=42):
    """split narration into subtitle-sized lines on punctuation/space"""
    if len(text) <= limit:
        return [text]
    parts, cur = [], ""
    for ch in text:
        cur += ch
        if len(cur) >= limit and ch in "，。；！？, .;!?":
            parts.append(cur.strip()); cur = ""
    if cur.strip():
        parts.append(cur.strip())
    return parts or [text]


def main():
    d = pathlib.Path(sys.argv[1]); lang = sys.argv[2]
    scenes = yaml.safe_load((d / "narration.yaml").read_text())["scenes"]
    seg = json.loads((d / "raw/segments.json").read_text())

    t = 0.0; idx = 1; lines = []
    for s in scenes:
        audio = dur(d / f"narration/{s['id']}.{lang}.mp3")
        video = max(seg.get(s["id"], 0.0), audio)
        chunks = split_text(s[lang])
        per = audio / len(chunks)
        ct = t
        for c in chunks:
            lines += [str(idx), f"{ts(ct)} --> {ts(min(ct + per, t + audio))}", c, ""]
            idx += 1; ct += per
        t += video
    (d / "subtitles").mkdir(exist_ok=True)
    out = d / f"subtitles/{lang}.srt"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out} ({idx - 1} cues, total {t:.1f}s)")


if __name__ == "__main__":
    main()
