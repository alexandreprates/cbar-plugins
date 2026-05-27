#!/usr/bin/env bash
# cbar: Shows the current public IP address.
# deps: curl, wl-copy, xclip
# env: CBAR_PUBLIC_IP_URL

set -u

url="${CBAR_PUBLIC_IP_URL:-https://api.ipify.org}"

if [[ ! "${url}" =~ ^https?://[^[:space:]\|]+$ ]]; then
  url="https://api.ipify.org"
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "IP ?"
  echo "---"
  echo "Missing dependency: curl | disabled=true"
  exit 0
fi

ip="$(curl -fsS --max-time 5 "${url}" 2>/dev/null | tr -d '\r\n' || true)"

if [[ -z "${ip}" || ! "${ip}" =~ ^[0-9A-Fa-f:.]+$ ]]; then
  echo "IP offline"
  echo "---"
  echo "Unable to resolve public IP | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

echo "IP ${ip}"
echo "---"
echo "Provider: ${url} | disabled=true"
echo "Copy address | bash=/bin/bash param1=-lc param2='if command -v wl-copy >/dev/null 2>&1; then printf %s \"${ip}\" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %s \"${ip}\" | xclip -selection clipboard; else printf %s \"${ip}\"; fi'"
echo "Refresh | refresh=true"
