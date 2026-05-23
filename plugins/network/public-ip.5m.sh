#!/usr/bin/env bash
# cbar: Shows the current public IP address.
# deps: curl
# env: CBAR_PUBLIC_IP_URL

set -u

url="${CBAR_PUBLIC_IP_URL:-https://api.ipify.org}"

if ! command -v curl >/dev/null 2>&1; then
  echo "IP ?"
  echo "---"
  echo "Missing dependency: curl | disabled=true"
  exit 0
fi

ip="$(curl -fsS --max-time 5 "${url}" 2>/dev/null || true)"

if [[ -z "${ip}" ]]; then
  echo "IP offline"
  echo "---"
  echo "Unable to resolve public IP | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

echo "IP ${ip}"
echo "---"
echo "Provider: ${url} | disabled=true"
echo "Copy command | bash=/bin/bash param1=-lc param2='printf %s \"${ip}\" | xclip -selection clipboard'"
echo "Refresh | refresh=true"
