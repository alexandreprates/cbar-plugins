#!/usr/bin/env bash
# cbar: Shows current memory usage.
# deps: awk, free
# env: none

set -u

if ! command -v free >/dev/null 2>&1; then
  echo "Mem ?"
  echo "---"
  echo "Missing dependency: free | disabled=true"
  exit 0
fi

read -r used total percent < <(
  free -m | awk '/^Mem:/ {
    used=$3
    total=$2
    percent=int(($3 / $2) * 100)
    print used, total, percent
  }'
)

echo "Mem ${percent}%"
echo "---"
echo "Used: ${used} MiB | disabled=true"
echo "Total: ${total} MiB | disabled=true"
echo "Open system monitor | bash=gnome-system-monitor"
echo "Refresh | refresh=true"
