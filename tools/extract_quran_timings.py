#!/usr/bin/env python3
"""
Extract per-ayah start times from full-surah MP3 recitations.

For each surah audio file it detects the silent gaps between ayat with
ffmpeg, then — because we already KNOW the exact number of ayat in every
surah (from assets/quran.json) — it keeps the (ayah_count - 1) most
prominent silences as the ayah boundaries. The result is written as a
JSON array of start times in seconds:

    [0, 4.8, 11.2, 17.9, ...]   # length == ayah count

The Quran reader reads these from Firebase Storage at  quran_audio/<n>.json
and highlights each ayah exactly in time with the recitation. If a timing
file is missing the app falls back to a length-based estimate, so this step
is optional but makes the highlight precise.

────────────────────────────────────────────────────────────────────────
REQUIREMENTS
    - Python 3
    - ffmpeg + ffprobe installed and on PATH   (brew install ffmpeg)

USAGE
    python3 tools/extract_quran_timings.py  <audio_dir>  [out_dir]

    <audio_dir>   folder containing 1.mp3 ... 114.mp3
    [out_dir]     where to write 1.json ... 114.json   (default: <audio_dir>)

THEN
    Upload BOTH the mp3 files and the generated json files to the Firebase
    Storage folder  quran_audio/  (so it holds 1.mp3, 1.json, 2.mp3, ...).

TUNING (if the highlight is off)
    --noise   silence threshold in dB   (default -32 ; quieter rooms: -40)
    --minsil  minimum silence length s  (default 0.25)
Verify a couple of surahs and adjust if needed; reciters sometimes pause
inside a long ayah or run two short ayat together.
"""

import argparse
import json
import os
import re
import subprocess
import sys


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def get_duration(path):
    r = run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return None


def detect_silences(path, noise_db, min_sil):
    """Return list of (start, end) silent intervals in seconds."""
    r = run(["ffmpeg", "-hide_banner", "-i", path, "-af",
             f"silencedetect=noise={noise_db}dB:d={min_sil}", "-f", "null", "-"])
    log = r.stderr
    starts = [float(m) for m in re.findall(r"silence_start:\s*([0-9.]+)", log)]
    ends = [float(m) for m in re.findall(r"silence_end:\s*([0-9.]+)", log)]
    n = min(len(starts), len(ends))
    return [(starts[i], ends[i]) for i in range(n)]


def load_ayah_counts(quran_json):
    with open(quran_json, encoding="utf-8") as f:
        data = json.load(f)
    counts = {}
    for s in data:
        sid = s.get("id")
        verses = s.get("verses")
        if verses is not None:
            counts[sid] = len(verses)
        elif s.get("total_verses") or s.get("versesCount"):
            counts[sid] = s.get("total_verses") or s.get("versesCount")
    return counts


def build_starts(silences, ayah_count, duration):
    """Pick (ayah_count - 1) boundaries → list of ayah start times."""
    needed = ayah_count - 1
    if needed <= 0:
        return [0.0]
    # Each silence becomes a candidate boundary at its midpoint, ranked by length.
    cands = [((s + e) / 2.0, e - s) for (s, e) in silences if e > s]
    cands.sort(key=lambda c: c[1], reverse=True)        # longest pauses first
    chosen = sorted(m for (m, _) in cands[:needed])     # keep top N-1, in order
    starts = [0.0] + chosen
    # If too few pauses were found, pad the remainder evenly to the end.
    if len(starts) < ayah_count and duration:
        last = starts[-1]
        remaining = ayah_count - len(starts)
        step = max(0.5, (duration - last) / (remaining + 1))
        for k in range(1, remaining + 1):
            starts.append(round(last + step * k, 2))
    return [round(t, 2) for t in starts[:ayah_count]]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("audio_dir")
    ap.add_argument("out_dir", nargs="?")
    ap.add_argument("--noise", default="-32")
    ap.add_argument("--minsil", default="0.25")
    ap.add_argument("--quran", default=os.path.join(
        os.path.dirname(__file__), "..", "assets", "quran.json"))
    args = ap.parse_args()

    out_dir = args.out_dir or args.audio_dir
    os.makedirs(out_dir, exist_ok=True)

    if run(["ffmpeg", "-version"]).returncode != 0:
        sys.exit("ffmpeg not found. Install it first (e.g. brew install ffmpeg).")

    counts = load_ayah_counts(args.quran)
    if not counts:
        sys.exit(f"Could not read ayah counts from {args.quran}")

    done = 0
    for sid in range(1, 115):
        mp3 = os.path.join(args.audio_dir, f"{sid}.mp3")
        if not os.path.exists(mp3):
            print(f"  skip surah {sid}: {sid}.mp3 not found")
            continue
        ayah_count = counts.get(sid)
        if not ayah_count:
            print(f"  skip surah {sid}: unknown ayah count")
            continue
        dur = get_duration(mp3)
        sil = detect_silences(mp3, args.noise, args.minsil)
        starts = build_starts(sil, ayah_count, dur)
        out = os.path.join(out_dir, f"{sid}.json")
        with open(out, "w", encoding="utf-8") as f:
            json.dump(starts, f, ensure_ascii=False)
        done += 1
        print(f"  surah {sid:>3}: {ayah_count} ayat, "
              f"{len(sil)} pauses → {os.path.basename(out)}")

    print(f"\nDone. Wrote timing files for {done} surah(s) to {out_dir}")
    print("Upload the .mp3 AND .json files to Firebase Storage → quran_audio/")


if __name__ == "__main__":
    main()
