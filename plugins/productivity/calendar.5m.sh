#!/usr/bin/env bash
# cbar: Shows today's date and calendar shortcuts.
# deps: date, cal
# env: CBAR_CALENDAR_URL

set -u

today="$(date '+%a %d %b')"
calendar_url="${CBAR_CALENDAR_URL:-https://calendar.google.com}"

if [[ ! "${calendar_url}" =~ ^https?://[^[:space:]\|]+$ ]]; then
  calendar_url="https://calendar.google.com"
fi

echo "${today}"
echo "---"
echo "Today: $(date '+%Y-%m-%d') | disabled=true"

if command -v cal >/dev/null 2>&1; then
  while IFS= read -r line; do
    echo "${line} | disabled=true"
  done < <(cal)
else
  echo "Missing optional dependency: cal | disabled=true"
fi

echo "Open calendar | href=${calendar_url}"
