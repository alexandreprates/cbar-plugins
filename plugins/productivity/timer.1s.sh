#!/usr/bin/env bash
# cbar: Shows a compact animated hourglass countdown timer.
# deps: base64, date, mkdir, rm, tr
# env: CBAR_TIMER_SECONDS

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/cbar}"
state_file="${state_dir}/timer-end"
default_seconds="${CBAR_TIMER_SECONDS:-1500}"
now="$(date +%s)"

case "${default_seconds}" in
  ''|*[!0-9]*)
    default_seconds=1500
    ;;
esac

mkdir -p "${state_dir}" 2>/dev/null || true

start=0
end=0
duration="${default_seconds}"

if [[ -f "${state_file}" ]]; then
  read -r first second third _ < "${state_file}" || true
  if [[ "${first:-}" =~ ^[0-9]+$ ]] && [[ "${second:-}" =~ ^[0-9]+$ ]] && [[ "${third:-}" =~ ^[0-9]+$ ]]; then
    start="${first}"
    end="${second}"
    duration="${third}"
  elif [[ "${first:-}" =~ ^[0-9]+$ ]]; then
    end="${first}"
    duration="${default_seconds}"
    start=$((end - duration))
  fi
fi

if (( duration <= 0 )); then
  duration="${default_seconds}"
fi

format_mmss() {
  local total="${1:-0}"
  local minutes=$((total / 60))
  local seconds=$((total % 60))
  printf '%02d:%02d' "${minutes}" "${seconds}"
}

format_duration() {
  local total="${1:-0}"
  local minutes=$((total / 60))
  local seconds=$((total % 60))
  if (( minutes > 0 && seconds > 0 )); then
    printf '%dm %02ds' "${minutes}" "${seconds}"
  elif (( minutes > 0 )); then
    printf '%dm' "${minutes}"
  else
    printf '%ds' "${seconds}"
  fi
}

format_end_time() {
  local epoch="${1:-0}"
  date -d "@${epoch}" '+%H:%M:%S' 2>/dev/null || echo "?"
}

timer_image() {
  local running="${1:-false}"
  local remaining="${2:-0}"
  local total="${3:-1}"
  local elapsed=0
  local top_h=0
  local bottom_h=0
  local top_y=9
  local bottom_y=16
  local sand="#8b949e"
  local drop=""

  if [[ "${running}" = "true" ]]; then
    elapsed=$((total - remaining))
    if (( elapsed < 0 )); then
      elapsed=0
    elif (( elapsed > total )); then
      elapsed="${total}"
    fi

    top_h=$(((remaining * 5 + total - 1) / total))
    bottom_h=$(((elapsed * 5 + total - 1) / total))
    if (( top_h > 5 )); then
      top_h=5
    fi
    if (( bottom_h > 5 )); then
      bottom_h=5
    fi
    top_y=$((9 - top_h))
    bottom_y=$((16 - bottom_h))

    if (( remaining <= 10 )); then
      sand="#f85149"
    elif (( remaining <= 60 )); then
      sand="#f59e0b"
    else
      sand="#58a6ff"
    fi

    drop="<circle cx=\"10\" cy=\"$((9 + (now % 3)))\" r=\"0.8\" fill=\"${sand}\"/>"
  fi

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <defs>
    <clipPath id="top-sand"><polygon points="5,4 15,4 10,10"/></clipPath>
    <clipPath id="bottom-sand"><polygon points="10,10 15,16 5,16"/></clipPath>
  </defs>
  <path d="M5 3.5h10M5 16.5h10M6 4.5l4 5.5-4 5.5M14 4.5l-4 5.5 4 5.5" fill="none" stroke="#c9d1d9" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="5" y="${top_y}" width="10" height="${top_h}" fill="${sand}" clip-path="url(#top-sand)"/>
  ${drop}
  <rect x="5" y="${bottom_y}" width="10" height="${bottom_h}" fill="${sand}" clip-path="url(#bottom-sand)"/>
</svg>
SVG
}

start_action() {
  local label="$1"
  local seconds="$2"
  echo "${label} | bash=/bin/bash param1=-lc param2='mkdir -p \"${state_dir}\" && now=\$(date +%s) && echo \"\$now \$((now + ${seconds})) ${seconds}\" > \"${state_file}\"' refresh=true"
}

running=false
remaining=0

if [[ "${end}" =~ ^[0-9]+$ ]] && (( end > now )); then
  running=true
  remaining=$((end - now))
fi

TIMER_IMAGE="$(timer_image "${running}" "${remaining}" "${duration}")"
echo "| image=${TIMER_IMAGE}"

echo "---"
if [[ "${running}" = "true" ]]; then
  echo "Timer"
  echo "--Remaining: $(format_mmss "${remaining}") | disabled=true"
  echo "--Duration: $(format_duration "${duration}") | disabled=true"
  echo "--Ends at: $(format_end_time "${end}") | disabled=true"
else
  echo "Timer idle"
fi

echo "---"
if (( default_seconds != 300 && default_seconds != 1500 )); then
  start_action "Start $(format_duration "${default_seconds}") timer" "${default_seconds}"
fi
start_action "Start 5m timer" 300
start_action "Start 25m timer" 1500
if [[ "${running}" = "true" ]]; then
  echo "Stop timer | bash=/bin/bash param1=-lc param2='rm -f \"${state_file}\"' refresh=true"
else
  echo "Stop timer | disabled=true"
fi
echo "---"
edit_cbar_env_item
