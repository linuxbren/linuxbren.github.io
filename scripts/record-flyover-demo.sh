#!/bin/bash
# Records a short looping demo clip of flyover's live scope for this site:
# launches the real scope in a real window, captures frames via `grim` at a
# fixed interval, and assembles them into a small muted .webm (for the
# site's <video> tag) and a .gif (works anywhere, e.g. a GitHub README).
#
# No wf-recorder/pipewire screencast portal needed -- this compositor
# doesn't have one set up, and grim-in-a-loop is plenty smooth for
# flyover's slow sweep rotation (no fast motion to capture).
#
# Records `flyover --screensaver`, not the plain interactive TUI -- the
# interactive app reads +/-/arrow keys to adjust zoom, so any stray input
# landing on the window while it has focus (easy to happen by accident on
# a live desktop) silently zooms the capture out instead of failing loudly.
# --screensaver never reads those keys at all.
#
# Deliberately does NOT try to force the window to a fixed size (tried
# pinning it floating via hl.dsp.window.float()/resize()/move(), which
# this compositor's Lua-dispatch build only applies reliably when each
# call is issued as its own separate, human-paced interaction -- run
# end-to-end inside this script, the new window inconsistently never
# actually became the focused/topmost one, so the resize silently landed
# on a different window instead). Whatever size the current tiling layout
# gives it is fine -- ffmpeg's scale filter below normalizes the output
# width either way, and getting the *content* right matters far more than
# pixel-identical framing between runs.
#
# Usage: record-flyover-demo.sh [sixel|ascii] [duration_seconds] [name] [warmup_seconds]
#   sixel|ascii     which render mode to capture (default: sixel)
#   duration_seconds  how long to record (default: 14)
#   name            output basename under assets/ (default: flyover-<mode>-demo)
#   warmup_seconds  how long to wait after the window appears before
#                   recording starts, e.g. to let real traffic populate
#                   (default: 4)
#
# Requires flyover on PATH or at ~/flyover/target/release/flyover, and a
# real Hyprland session (it opens an actual window on your screen for the
# duration of the recording).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mode="${1:-sixel}"
duration="${2:-14}"
out_basename="${3:-flyover-$mode-demo}"
warmup="${4:-4}"

case "$mode" in
sixel | ascii) ;;
*)
  echo "usage: $0 [sixel|ascii] [duration_seconds] [name] [warmup_seconds]" >&2
  exit 1
  ;;
esac

flyover_bin=$(command -v flyover || true)
[[ -z $flyover_bin ]] && flyover_bin="$HOME/flyover/target/release/flyover"
[[ -x $flyover_bin ]] || {
  echo "flyover binary not found (checked PATH and ~/flyover/target/release/flyover)" >&2
  exit 1
}

app_id="flyover-demo-capture"
frames_dir=""

cleanup() {
  pkill -f -- "-a $app_id" 2>/dev/null || true
  if [[ -n $frames_dir ]]; then rm -rf "$frames_dir"; fi
}
trap cleanup EXIT

# In case a previous run crashed without cleaning up.
pkill -f -- "-a $app_id" 2>/dev/null || true
sleep 0.3

echo "Launching flyover ($mode mode)..."
foot -a "$app_id" -T flyover -H -D "$HOME" "$flyover_bin" --screensaver "--$mode" &

wait_for_window() {
  local deadline=$((SECONDS + 10))
  local found=""
  while ((SECONDS < deadline)); do
    found=$(hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c['class'] == '$app_id':
        at, size = c['at'], c['size']
        print(f'{at[0]},{at[1]} {size[0]}x{size[1]}')
        break
" 2>/dev/null)
    if [[ -n $found ]]; then
      echo "$found"
      return 0
    fi
    sleep 0.2
  done
  return 1
}

geometry=$(wait_for_window) || {
  echo "flyover window never appeared" >&2
  exit 1
}

echo "Window at $geometry. Waiting ${warmup}s before recording..."
sleep "$warmup"

# Deliberately no "is this window actually focused/topmost" check here:
# whether it's focused doesn't matter for capture correctness as long as
# it's tiled (the normal case, since this script never floats/moves it) --
# tiled windows don't overlap, so whatever's at $geometry is genuinely
# flyover regardless of which window currently has input focus. That
# distinction only matters if something makes this window floating and
# overlapping another one, which this script doesn't do.
frames_dir=$(mktemp -d)
echo "Recording ${duration}s..."
frame=0
end=$(($(date +%s%N) + duration * 1000000000))
while [[ $(date +%s%N) -lt $end ]]; do
  grim -g "$geometry" "$(printf '%s/frame-%05d.png' "$frames_dir" "$frame")"
  frame=$((frame + 1))
done
echo "Captured $frame frames."

pkill -f -- "-a $app_id" 2>/dev/null || true

fps=$(python3 -c "print(round($frame / $duration, 2))")
echo "Effective ~${fps}fps"

mkdir -p assets
ffmpeg -y -framerate "$fps" -i "$frames_dir/frame-%05d.png" \
  -vf "scale=480:-2" -c:v libvpx-vp9 -b:v 0 -crf 32 -an \
  "assets/$out_basename.webm"

ffmpeg -y -framerate "$fps" -i "$frames_dir/frame-%05d.png" \
  -vf "scale=480:-2,split[a][b];[a]palettegen[p];[b][p]paletteuse" \
  "assets/$out_basename.gif"

echo "Wrote assets/$out_basename.webm and assets/$out_basename.gif"
