#!/usr/bin/env bash
# cbar: Shows a simple countdown timer backed by /tmp.
# deps: date, rm
# env: CBAR_TIMER_SECONDS

set -u

state_file="${TMPDIR:-/tmp}/cbar-timer-end"
default_seconds="${CBAR_TIMER_SECONDS:-1500}"
now="$(date +%s)"

if [[ -f "${state_file}" ]]; then
  end="$(cat "${state_file}" 2>/dev/null || echo 0)"
else
  end=0
fi

if [[ "${end}" =~ ^[0-9]+$ ]] && (( end > now )); then
  remaining=$((end - now))
  minutes=$((remaining / 60))
  seconds=$((remaining % 60))
  printf 'Timer %02d:%02d\n' "${minutes}" "${seconds}"
else
  echo "Timer idle"
fi

echo "---"
echo "Start ${default_seconds}s timer | bash=/bin/bash param1=-lc param2='date -d \"+${default_seconds} seconds\" +%s > \"${state_file}\"' refresh=true"
echo "Start 5m timer | bash=/bin/bash param1=-lc param2='date -d \"+5 minutes\" +%s > \"${state_file}\"' refresh=true"
echo "Start 25m timer | bash=/bin/bash param1=-lc param2='date -d \"+25 minutes\" +%s > \"${state_file}\"' refresh=true"
echo "Stop timer | bash=rm param1=-f param2=${state_file} refresh=true"
