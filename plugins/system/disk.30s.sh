#!/usr/bin/env bash
# cbar: Shows filesystem usage as compact segmented blocks.
# deps: awk, base64, df, tr
# env: CBAR_DISK_PATH, CBAR_DISK_WARN, CBAR_DISK_CRIT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

path="${CBAR_DISK_PATH:-/}"
disk_warn="${CBAR_DISK_WARN:-85}"
disk_crit="${CBAR_DISK_CRIT:-95}"

case "${disk_warn}" in
  ''|*[!0-9]*)
    disk_warn=85
    ;;
esac

case "${disk_crit}" in
  ''|*[!0-9]*)
    disk_crit=95
    ;;
esac

if (( disk_warn > 100 )); then
  disk_warn=100
fi

if (( disk_crit > 100 )); then
  disk_crit=100
fi

if (( disk_warn >= disk_crit )); then
  disk_warn=$((disk_crit - 10))
fi

if (( disk_warn < 0 )); then
  disk_warn=0
fi

read -r size used avail percent mountpoint < <(
  df -hP "${path}" | awk 'NR == 2 { print $2, $3, $4, $5, $6 }'
)

if [[ -z "${percent:-}" ]]; then
  echo "Disk ?"
  echo "---"
  echo "Unable to inspect ${path} | disabled=true"
  exit 0
fi

used_percent="${percent%\%}"
filled_blocks=$(( (used_percent + 19) / 20 ))
if (( filled_blocks < 1 )); then
  filled_blocks=1
elif (( filled_blocks > 5 )); then
  filled_blocks=5
fi

fill="#58a6ff"
if (( used_percent >= disk_crit )); then
  fill="#f85149"
elif (( used_percent >= disk_warn )); then
  fill="#f59e0b"
fi

blocks=""
for index in 0 1 2 3 4; do
  x=$((index * 4))
  if (( index < filled_blocks )); then
    color="${fill}"
    opacity="1"
  else
    color="#5b6472"
    opacity="0.58"
  fi
  blocks="${blocks}<rect x=\"${x}\" y=\"1\" width=\"3\" height=\"10\" rx=\"1\" fill=\"${color}\" fill-opacity=\"${opacity}\"/>"
done

disk_image="$(
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="12" viewBox="0 0 20 12">
  ${blocks}
</svg>
SVG
)"

echo "| image=${disk_image}"
echo "---"
echo "Disk"
echo "--Used: ${used} / ${size} (${percent}) | disabled=true"
echo "--Available: ${avail} | disabled=true"
echo "--Mount: ${mountpoint} | disabled=true"
echo "--Warning: ${disk_warn}% | disabled=true"
echo "--Critical: ${disk_crit}% | disabled=true"
echo "Open disk usage | bash=/bin/bash param1=-lc param2='xdg-open \"${mountpoint}\"'"
echo "---"
edit_cbar_env_item
