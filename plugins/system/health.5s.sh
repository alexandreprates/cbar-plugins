#!/usr/bin/env bash
# cbar: Shows a compact system health summary.
# deps: awk, date, df
# env: CBAR_HEALTH_DISK_WARN

set -euo pipefail

disk_warn="${CBAR_HEALTH_DISK_WARN:-85}"
case "${disk_warn}" in
  ''|*[!0-9]*)
    disk_warn=85
    ;;
esac

disk_percent="$(df -P / | awk 'NR == 2 { gsub("%", "", $5); print $5 }')"
load="$(awk '{ print $1 }' /proc/loadavg)"
status="Sys OK"

if (( disk_percent >= disk_warn )); then
  status="Disk ${disk_percent}%"
fi

echo "${status}"
echo "---"
echo "System snapshot"
echo "--Load average: ${load} | disabled=true"
echo "--Root disk: ${disk_percent}% | disabled=true"
echo "--Disk warning threshold: ${disk_warn}% | disabled=true"
echo "Open root folder | shell=xdg-open param1=/"
echo "Open disk usage in terminal | shell=/bin/sh param1=-lc param2='df -h /; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "---"
echo "Updated: $(date '+%Y-%m-%d %H:%M:%S') | disabled=true"
