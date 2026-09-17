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
# Usage: record-flyover-demo.sh [sixel|ascii] [duration_seconds] [name]
#   sixel|ascii     which render mode to capture (default: sixel)
#   duration_seconds  how long to record (default: 14)
#   name            output basename under assets/ (default: flyover-<mode>-demo)
#
# Requires flyover on PATH or at ~/flyover/target/release/flyover, and a
# real Hyprland session (it opens an actual window on your screen for the
# duration of the recording).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mode="${1:-sixel}"
duration="${2:-14}"
out_basename="${3:-flyover-$mode-demo}"

case "$mode" in
sixel) render_mode=sixel ;;
ascii) render_mode=braille ;;
*)
  echo "usage: $0 [sixel|ascii] [duration_seconds] [name]" >&2
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
settings_file="$HOME/.config/flyover/settings.toml"
frames_dir=""

# Set the render mode flyover starts in (it reads this at launch, so no
# need to send it a 'v' keypress mid-recording), remembering whatever was
# there before so it can be restored -- this shouldn't permanently change
# your actual day-to-day render mode setting.
mkdir -p "$(dirname "$settings_file")"
prior_settings=""
[[ -f $settings_file ]] && prior_settings=$(cat "$settings_file")
printf 'render_mode = "%s"\n' "$render_mode" >"$settings_file"

cleanup() {
  pkill -f -- "-a $app_id" 2>/dev/null || true
  if [[ -n $prior_settings ]]; then
    printf '%s\n' "$prior_settings" >"$settings_file"
  else
    rm -f "$settings_file"
  fi
  [[ -n $frames_dir ]] && rm -rf "$frames_dir"
}
trap cleanup EXIT

# In case a previous run crashed without cleaning up.
pkill -f -- "-a $app_id" 2>/dev/null || true
sleep 0.3

echo "Launching flyover ($mode mode)..."
foot -a "$app_id" -T flyover -H -D "$HOME" "$flyover_bin" &

deadline=$((SECONDS + 10))
geometry=""
while ((SECONDS < deadline)); do
  geometry=$(hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c['class'] == '$app_id':
        at, size = c['at'], c['size']
        print(f'{at[0]},{at[1]} {size[0]}x{size[1]}')
        break
" 2>/dev/null)
  [[ -n $geometry ]] && break
  sleep 0.2
done
[[ -n $geometry ]] || {
  echo "flyover window never appeared" >&2
  exit 1
}

echo "Window at $geometry. Letting real traffic populate for a few seconds..."
sleep 4

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
