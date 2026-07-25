#!/usr/bin/env bash
#
# encode-loops.sh — batch-encode Work Dump thumbnail loops to spec.
#
# Spec (see the grid's perf rules): ~640px wide, 24fps, muted H.264
# (universal decode, cheap pipelines), faststart for instant streaming,
# plus a poster JPEG. Typical result: 150-400KB for a 3-6s loop.
#
# Usage:
#   scripts/encode-loops.sh path/to/clip1.mov path/to/clip2.mp4 ...
#
# Outputs next to each input: <name>-loop.mp4 and <name>-poster.jpg
# Then move them into public/ and reference from the dumpItems array.
#
set -euo pipefail

command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }

for f in "$@"; do
  base="${f%.*}"
  echo "→ ${f}"
  ffmpeg -y -v error -i "$f" \
    -vf "scale=640:-2:flags=lanczos,fps=24" -an \
    -c:v libx264 -crf 28 -preset slow -pix_fmt yuv420p -movflags +faststart \
    "${base}-loop.mp4"
  ffmpeg -y -v error -i "${base}-loop.mp4" -frames:v 1 -q:v 4 "${base}-poster.jpg"
  ls -la "${base}-loop.mp4" "${base}-poster.jpg" | awk '{printf "  %s  %.0f KB\n", $NF, $5/1024}'
done
echo "done."
