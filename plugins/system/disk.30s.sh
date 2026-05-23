#!/usr/bin/env bash
# cbar: Shows root filesystem usage.
# deps: df, awk
# env: CBAR_DISK_PATH

set -u

path="${CBAR_DISK_PATH:-/}"

read -r size used avail percent mountpoint < <(
  df -hP "${path}" | awk 'NR == 2 { print $2, $3, $4, $5, $6 }'
)

if [[ -z "${percent:-}" ]]; then
  echo "Disk ?"
  echo "---"
  echo "Unable to inspect ${path} | disabled=true"
  exit 0
fi

echo "Disk ${percent}"
echo "---"
echo "Path: ${path} | disabled=true"
echo "Mount: ${mountpoint} | disabled=true"
echo "Used: ${used} / ${size} | disabled=true"
echo "Available: ${avail} | disabled=true"
echo "Open disk usage | bash=xdg-open param1=${mountpoint}"
