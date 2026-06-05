#!/usr/bin/env bash
# cbar: Shows compact latency to a configurable host.
# deps: awk, ping
# env: CBAR_PING_HOST, CBAR_PING_WARN_MS, CBAR_PING_CRIT_MS

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

host="${CBAR_PING_HOST:-1.1.1.1}"
warn_ms="${CBAR_PING_WARN_MS:-100}"
crit_ms="${CBAR_PING_CRIT_MS:-250}"

if [[ ! "${host}" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
  host="1.1.1.1"
fi

case "${warn_ms}" in
  ''|*[!0-9]*)
    warn_ms=100
    ;;
esac

case "${crit_ms}" in
  ''|*[!0-9]*)
    crit_ms=250
    ;;
esac

if (( warn_ms >= crit_ms )); then
  warn_ms=$((crit_ms / 2))
fi

if ! command -v ping >/dev/null 2>&1; then
  echo "?ms | color=#8b949e"
  echo "---"
  echo "Missing dependency: ping | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

output="$(ping -c 1 -W 2 "${host}" 2>/dev/null || true)"
latency="$(printf '%s\n' "${output}" | awk -F'time=' '/time=/ { split($2, parts, " "); print parts[1] }')"

if [[ -z "${latency}" ]]; then
  echo "down | color=#f85149"
  echo "---"
  echo "Ping"
  echo "--Host: ${host} | disabled=true"
  echo "--Status: no response within timeout | disabled=true"
  echo "Refresh | refresh=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

latency_ms="$(awk -v latency="${latency}" 'BEGIN { printf "%d", latency + 0.5 }')"
color="#58a6ff"
status="ok"
if (( latency_ms >= crit_ms )); then
  color="#f85149"
  status="critical"
elif (( latency_ms >= warn_ms )); then
  color="#f59e0b"
  status="warning"
fi

echo "${latency_ms}ms | color=${color}"
echo "---"
echo "Ping"
echo "--Host: ${host} | disabled=true"
echo "--Latency: ${latency} ms | disabled=true"
echo "--Status: ${status} | disabled=true"
echo "--Warning: ${warn_ms}ms | disabled=true"
echo "--Critical: ${crit_ms}ms | disabled=true"
echo "Run ping in terminal | bash=/bin/bash param1=-lc param2='ping \"${host}\"' terminal=true"
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
