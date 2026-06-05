#!/usr/bin/env bash
# cbar: Shows the current public IP address.
# deps: awk, base64, curl, ip, tr, wl-copy, xclip
# env: CBAR_PUBLIC_IP_URL

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

url="${CBAR_PUBLIC_IP_URL:-https://api.ipify.org}"
icon_color="#58a6ff"

if [[ ! "${url}" =~ ^https?://[^[:space:]\|]+$ ]]; then
  url="https://api.ipify.org"
fi

network_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <circle cx="10" cy="10" r="7.4" fill="none" stroke="${color}" stroke-width="1.7"/>
  <path d="M3.4 10h13.2M10 2.6c2.2 2.1 3.3 4.6 3.3 7.4S12.2 15.3 10 17.4M10 2.6C7.8 4.7 6.7 7.2 6.7 10s1.1 5.3 3.3 7.4" fill="none" stroke="${color}" stroke-width="1.35" stroke-linecap="round"/>
</svg>
SVG
}

copy_command() {
  local value="$1"
  printf "if command -v wl-copy >/dev/null 2>&1; then printf %%s \"%s\" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %%s \"%s\" | xclip -selection clipboard; else printf %%s \"%s\"; fi" "${value}" "${value}" "${value}"
}

local_ip="?"
if command -v ip >/dev/null 2>&1; then
  local_ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit } }')"
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "| image=$(network_icon "#8b949e")"
  echo "---"
  echo "Missing dependency: curl | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

ip="$(curl -fsS --max-time 5 "${url}" 2>/dev/null | tr -d '\r\n' || true)"

if [[ -z "${ip}" || ! "${ip}" =~ ^[0-9A-Fa-f:.]+$ ]]; then
  echo "| image=$(network_icon "#f85149")"
  echo "---"
  echo "Unable to resolve public IP | disabled=true"
  echo "Provider: ${url} | disabled=true"
  echo "Refresh | refresh=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

echo "| image=$(network_icon "${icon_color}")"
echo "---"
echo "Public IP"
echo "--Address: ${ip} | disabled=true"
echo "--Local address: ${local_ip:-?} | disabled=true"
echo "--Provider: ${url} | disabled=true"
echo "Copy public IP | bash=/bin/bash param1=-lc param2='$(copy_command "${ip}")'"
if [[ "${local_ip:-}" != "?" && -n "${local_ip:-}" ]]; then
  echo "Copy local IP | bash=/bin/bash param1=-lc param2='$(copy_command "${local_ip}")'"
else
  echo "Copy local IP | disabled=true"
fi
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
