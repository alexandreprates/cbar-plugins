#!/usr/bin/env bash
# cbar: Shows CPU usage history as a compact panel chart.
# deps: awk, base64, mkdir, tr
# env: CBAR_CPU_WARN

set -euo pipefail

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

cpu_warn="${CBAR_CPU_WARN:-75}"
case "${cpu_warn}" in
  ''|*[!0-9]*)
    cpu_warn=75
    ;;
esac
history_size=5
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cbar"
state_file="${cache_dir}/cpu-chart.state"

mkdir -p "$cache_dir"

read -r idle total < <(
  awk '
    /^cpu / {
      idle = $5 + $6
      total = 0
      for (i = 2; i <= NF; i++) {
        total += $i
      }
      print idle, total
    }
  ' /proc/stat
)

previous_idle=""
previous_total=""
history=""

if [[ -r "$state_file" ]]; then
  {
    IFS= read -r previous_idle || true
    IFS= read -r previous_total || true
    IFS= read -r history || true
  } < "$state_file"
fi

usage=0
if [[ -n "$previous_idle" && -n "$previous_total" ]]; then
  total_delta=$(( total - previous_total ))
  idle_delta=$(( idle - previous_idle ))
  if (( total_delta > 0 )); then
    usage=$(( (100 * (total_delta - idle_delta)) / total_delta ))
  fi
fi

history="${history} ${usage}"
history="$(printf '%s\n' "$history" | awk -v limit="$history_size" '{
  start = NF - limit + 1
  if (start < 1) {
    start = 1
  }
  for (i = start; i <= NF; i++) {
    printf "%s%s", $i, (i == NF ? ORS : " ")
  }
}')"

read -r average peak < <(
  printf '%s\n' "$history" | awk '{
    total = 0
    peak = 0
    for (i = 1; i <= NF; i++) {
      total += $i
      if ($i > peak) {
        peak = $i
      }
    }
    printf "%d %d\n", (NF ? total / NF : 0), peak
  }'
)

{
  printf '%s\n' "$idle"
  printf '%s\n' "$total"
  printf '%s\n' "$history"
} > "$state_file"

bar_width=2
gap=1
chart_height=18
chart_width=16
bars=""
index=0

for value in $history; do
  height=$(( value * chart_height / 100 ))
  if (( height < 1 )); then
    height=1
  fi
  x=$(( index * (bar_width + gap) ))
  y=$(( chart_height - height ))
  fill="#58a6ff"
  if (( value >= cpu_warn )); then
    fill="#f85149"
  fi
  bars="${bars}<rect x=\"${x}\" y=\"${y}\" width=\"${bar_width}\" height=\"${height}\" rx=\"1\" fill=\"${fill}\"/>"
  index=$(( index + 1 ))
done

svg_to_base64() {
  base64 | tr -d '\n'
}

chart_image="$(
  cat <<SVG | svg_to_base64
<svg xmlns="http://www.w3.org/2000/svg" width="${chart_width}" height="${chart_height}" viewBox="0 0 ${chart_width} ${chart_height}">
  ${bars}
</svg>
SVG
)"

echo "| image=${chart_image}"
echo "---"
echo "CPU"
echo "--Current: ${usage}% | disabled=true"
echo "--Average: ${average}% | disabled=true"
echo "--Peak: ${peak}% | disabled=true"
echo "--Warning: ${cpu_warn}% | disabled=true"
echo "Open CPU details | shell=/bin/sh param1=-lc param2='top -b -n 1 | head -20; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "Reset chart history | shell=/bin/sh param1=-lc param2='rm -f \"${state_file}\"' refresh=true"
echo "---"
edit_cbar_env_item
