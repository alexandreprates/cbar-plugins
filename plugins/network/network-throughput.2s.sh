#!/usr/bin/env bash
# cbar: Shows network upload and download throughput as a compact panel chart.
# deps: awk, base64, cat, date, ip, mkdir, tr
# env: CBAR_NETWORK_INTERFACE

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/cbar}"
state_file="${state_dir}/network-throughput"
iface="${CBAR_NETWORK_INTERFACE:-}"
now="$(date +%s)"

mkdir -p "${state_dir}" 2>/dev/null || true

pick_interface() {
  if [[ -n "${iface}" && -d "/sys/class/net/${iface}" ]]; then
    printf '%s\n' "${iface}"
    return
  fi

  if command -v ip >/dev/null 2>&1; then
    local default_iface
    default_iface="$(ip route show default 2>/dev/null | awk '{ print $5; exit }')"
    if [[ -n "${default_iface}" && -d "/sys/class/net/${default_iface}" ]]; then
      printf '%s\n' "${default_iface}"
      return
    fi
  fi

  for candidate in /sys/class/net/*; do
    candidate="${candidate##*/}"
    [[ "${candidate}" = "lo" ]] && continue
    [[ -d "/sys/class/net/${candidate}" ]] || continue
    printf '%s\n' "${candidate}"
    return
  done
}

format_rate() {
  local bps="${1:-0}"
  awk -v bps="${bps}" 'BEGIN {
    if (bps >= 1048576) {
      printf "%.1f MB/s", bps / 1048576
    } else if (bps >= 1024) {
      printf "%.0f KB/s", bps / 1024
    } else {
      printf "%d B/s", bps
    }
  }'
}

format_bytes() {
  local bytes="${1:-0}"
  awk -v bytes="${bytes}" 'BEGIN {
    if (bytes >= 1073741824) {
      printf "%.1f GB", bytes / 1073741824
    } else if (bytes >= 1048576) {
      printf "%.1f MB", bytes / 1048576
    } else if (bytes >= 1024) {
      printf "%.0f KB", bytes / 1024
    } else {
      printf "%d B", bytes
    }
  }'
}

level_for_rate() {
  local bps="${1:-0}"
  awk -v bps="${bps}" 'BEGIN {
    if (bps < 1024) print 0;
    else if (bps < 10240) print 1;
    else if (bps < 51200) print 2;
    else if (bps < 204800) print 3;
    else if (bps < 1048576) print 4;
    else print 5;
  }'
}

append_level() {
  local history="${1:-0,0,0,0,0,0,0}"
  local level="${2:-0}"
  awk -v history="${history}" -v level="${level}" 'BEGIN {
    n = split(history, parts, ",")
    start = n >= 7 ? n - 6 : 1
    out = ""
    for (i = start; i <= n; i++) {
      if (parts[i] == "") continue
      out = out (out ? "," : "") parts[i]
    }
    print out (out ? "," : "") level
  }'
}

throughput_icon() {
  local rx_history="$1"
  local tx_history="$2"
  local color="$3"
  local rx_bars=""
  local tx_bars=""
  local index=0
  local level height x y opacity

  IFS=',' read -ra rx_parts <<< "${rx_history}"
  IFS=',' read -ra tx_parts <<< "${tx_history}"

  for level in "${rx_parts[@]}"; do
    [[ "${level}" =~ ^[0-5]$ ]] || level=0
    height=$((level + 1))
    x=$((9 + index * 3))
    y=$((8 - height))
    opacity="0.35"
    (( level > 0 )) && opacity="1"
    rx_bars="${rx_bars}<rect x=\"${x}\" y=\"${y}\" width=\"2\" height=\"${height}\" rx=\"1\" fill=\"${color}\" fill-opacity=\"${opacity}\"/>"
    index=$((index + 1))
  done

  index=0
  for level in "${tx_parts[@]}"; do
    [[ "${level}" =~ ^[0-5]$ ]] || level=0
    height=$((level + 1))
    x=$((9 + index * 3))
    y=12
    opacity="0.35"
    (( level > 0 )) && opacity="1"
    tx_bars="${tx_bars}<rect x=\"${x}\" y=\"${y}\" width=\"2\" height=\"${height}\" rx=\"1\" fill=\"${color}\" fill-opacity=\"${opacity}\"/>"
    index=$((index + 1))
  done

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="20" viewBox="0 0 32 20">
  <path d="M5 3v6M2.8 6.8 5 9l2.2-2.2" fill="none" stroke="${color}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M5 17v-6M2.8 13.2 5 11l2.2 2.2" fill="none" stroke="${color}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  ${rx_bars}
  ${tx_bars}
</svg>
SVG
}

error_icon() {
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <circle cx="10" cy="10" r="7" fill="none" stroke="#8b949e" stroke-width="1.6"/>
  <path d="M6.5 6.5 13.5 13.5M13.5 6.5 6.5 13.5" stroke="#8b949e" stroke-width="1.6" stroke-linecap="round"/>
</svg>
SVG
}

selected_iface="$(pick_interface)"

if [[ -z "${selected_iface}" || ! -r "/sys/class/net/${selected_iface}/statistics/rx_bytes" || ! -r "/sys/class/net/${selected_iface}/statistics/tx_bytes" ]]; then
  echo "| image=$(error_icon)"
  echo "---"
  echo "Network throughput"
  echo "--Status: no interface found | disabled=true"
  echo "--Set CBAR_NETWORK_INTERFACE in ~/.config/cbar/env to choose one | disabled=true"
  echo "Refresh | refresh=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

rx_bytes="$(cat "/sys/class/net/${selected_iface}/statistics/rx_bytes" 2>/dev/null || echo 0)"
tx_bytes="$(cat "/sys/class/net/${selected_iface}/statistics/tx_bytes" 2>/dev/null || echo 0)"
operstate="$(cat "/sys/class/net/${selected_iface}/operstate" 2>/dev/null || echo unknown)"

prev_iface=""
prev_ts=0
prev_rx="${rx_bytes}"
prev_tx="${tx_bytes}"
rx_history="0,0,0,0,0,0,0,0"
tx_history="0,0,0,0,0,0,0,0"

if [[ -r "${state_file}" ]]; then
  read -r prev_iface prev_ts prev_rx prev_tx rx_history tx_history _ < "${state_file}" || true
fi

rx_rate=0
tx_rate=0
if [[ "${prev_iface}" = "${selected_iface}" && "${prev_ts}" =~ ^[0-9]+$ && "${prev_rx}" =~ ^[0-9]+$ && "${prev_tx}" =~ ^[0-9]+$ ]]; then
  elapsed=$((now - prev_ts))
  if (( elapsed > 0 && rx_bytes >= prev_rx && tx_bytes >= prev_tx )); then
    rx_rate=$(((rx_bytes - prev_rx) / elapsed))
    tx_rate=$(((tx_bytes - prev_tx) / elapsed))
  fi
fi

rx_level="$(level_for_rate "${rx_rate}")"
tx_level="$(level_for_rate "${tx_rate}")"
rx_history="$(append_level "${rx_history}" "${rx_level}")"
tx_history="$(append_level "${tx_history}" "${tx_level}")"

printf '%s %s %s %s %s %s\n' "${selected_iface}" "${now}" "${rx_bytes}" "${tx_bytes}" "${rx_history}" "${tx_history}" > "${state_file}" 2>/dev/null || true

color="#58a6ff"
status="up"
if [[ "${operstate}" != "up" && "${operstate}" != "unknown" ]]; then
  color="#8b949e"
  status="${operstate}"
fi

echo "| image=$(throughput_icon "${rx_history}" "${tx_history}" "${color}")"
echo "---"
echo "Network throughput"
echo "--Interface: ${selected_iface} | disabled=true"
echo "--Status: ${status} | disabled=true"
echo "--Download: $(format_rate "${rx_rate}") | disabled=true"
echo "--Upload: $(format_rate "${tx_rate}") | disabled=true"
echo "--Downloaded: $(format_bytes "${rx_bytes}") | disabled=true"
echo "--Uploaded: $(format_bytes "${tx_bytes}") | disabled=true"
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
