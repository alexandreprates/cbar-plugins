#!/usr/bin/env bash
# cbar: Shows RAM usage as a compact panel gauge.
# deps: awk, base64, tr
# env: CBAR_MEMORY_WARN, CBAR_MEMORY_CRIT

set -euo pipefail

ram_warn="${CBAR_MEMORY_WARN:-85}"
ram_crit="${CBAR_MEMORY_CRIT:-95}"

case "${ram_warn}" in
  ''|*[!0-9]*)
    ram_warn=85
    ;;
esac

case "${ram_crit}" in
  ''|*[!0-9]*)
    ram_crit=95
    ;;
esac

if (( ram_warn > 100 )); then
  ram_warn=100
fi

if (( ram_crit > 100 )); then
  ram_crit=100
fi

if (( ram_warn >= ram_crit )); then
  ram_warn=$((ram_crit - 10))
fi

if (( ram_warn < 0 )); then
  ram_warn=0
fi

read -r mem_total mem_available < <(
  awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END { print total, available }
  ' /proc/meminfo
)

used=$(( mem_total - mem_available ))
used_percent=$(( used * 100 / mem_total ))
used_gib="$(awk -v used="$used" 'BEGIN { printf "%.2f", used / 1048576 }')"
available_gib="$(awk -v available="$mem_available" 'BEGIN { printf "%.2f", available / 1048576 }')"
total_gib="$(awk -v total="$mem_total" 'BEGIN { printf "%.2f", total / 1048576 }')"
gauge_circumference="52.78"
gauge_dash="$(awk -v percent="$used_percent" -v circumference="$gauge_circumference" 'BEGIN { printf "%.2f", circumference * percent / 100 }')"
gauge_gap="$(awk -v dash="$gauge_dash" -v circumference="$gauge_circumference" 'BEGIN { printf "%.2f", circumference - dash }')"
color="#22d3ee"

if (( used_percent >= ram_crit )); then
  color="#f85149"
elif (( used_percent >= ram_warn )); then
  color="#f59e0b"
fi

svg_to_base64() {
  base64 | tr -d '\n'
}

gauge_image="$(
  cat <<SVG | svg_to_base64
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <circle cx="10" cy="10" r="8.4" fill="none" stroke="#5b6472" stroke-opacity="0.72" stroke-width="2.2"/>
  <circle cx="10" cy="10" r="8.4" fill="none" stroke="${color}" stroke-width="2.2"
          stroke-dasharray="${gauge_dash} ${gauge_gap}"
          stroke-linecap="round" transform="rotate(-90 10 10)"/>
</svg>
SVG
)"

echo "| image=${gauge_image}"
echo "---"
echo "Memory"
echo "--Used: ${used_gib} GiB (${used_percent}%) | disabled=true"
echo "--Available: ${available_gib} GiB | disabled=true"
echo "--Total: ${total_gib} GiB | disabled=true"
echo "--Warning: ${ram_warn}% | disabled=true"
echo "--Critical: ${ram_crit}% | disabled=true"
echo "Open memory details | shell=/bin/sh param1=-lc param2='free -h; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
