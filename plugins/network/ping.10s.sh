#!/usr/bin/env bash
# cbar: Checks connectivity to a configurable host.
# deps: ping
# env: CBAR_PING_HOST

set -u

host="${CBAR_PING_HOST:-1.1.1.1}"

if ! command -v ping >/dev/null 2>&1; then
  echo "Ping ?"
  echo "---"
  echo "Missing dependency: ping | disabled=true"
  exit 0
fi

output="$(ping -c 1 -W 2 "${host}" 2>/dev/null || true)"
latency="$(printf '%s\n' "${output}" | awk -F'time=' '/time=/ { split($2, parts, " "); print parts[1] }')"

if [[ -z "${latency}" ]]; then
  echo "Ping down"
  echo "---"
  echo "Host: ${host} | disabled=true"
  echo "No response within timeout | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

echo "Ping ${latency}ms"
echo "---"
echo "Host: ${host} | disabled=true"
echo "Latency: ${latency} ms | disabled=true"
echo "Run ping in terminal | bash=/bin/bash param1=-lc param2='ping \"${host}\"' terminal=true"
echo "Refresh | refresh=true"
