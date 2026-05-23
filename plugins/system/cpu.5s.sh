#!/usr/bin/env bash
# cbar: Shows load average and CPU core count.
# deps: awk, getconf, uptime
# env: none

set -u

load="$(awk '{ print $1 }' /proc/loadavg 2>/dev/null || true)"
cores="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo "?")"

if [[ -z "${load}" ]]; then
  echo "CPU ?"
  echo "---"
  echo "Unable to read /proc/loadavg | disabled=true"
  exit 0
fi

echo "CPU ${load}/${cores}"
echo "---"
echo "Load average: ${load} | disabled=true"
echo "Online cores: ${cores} | disabled=true"
echo "Open system monitor | bash=gnome-system-monitor"
echo "Refresh | refresh=true"
