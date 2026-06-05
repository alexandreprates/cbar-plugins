#!/usr/bin/env bash
# cbar: Shows available APT and Flatpak updates with a compact badge.
# deps: apt, awk, base64, cosmic-store, flatpak, tr
# env: CBAR_UPDATES_INCLUDE_APT, CBAR_UPDATES_INCLUDE_FLATPAK

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

include_apt="${CBAR_UPDATES_INCLUDE_APT:-true}"
include_flatpak="${CBAR_UPDATES_INCLUDE_FLATPAK:-true}"

updates_icon() {
  local count="${1:-0}"
  local color="#8b949e"
  local badge=""

  if (( count > 0 )); then
    color="#58a6ff"
    badge="<circle cx=\"15\" cy=\"15\" r=\"3.2\" fill=\"#f85149\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
  fi

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M4.2 7.2 10 4l5.8 3.2v6.3L10 16.8l-5.8-3.3V7.2Z" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M4.7 7.4 10 10.5l5.3-3.1M10 10.5v5.7" fill="none" stroke="${color}" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"/>
  ${badge}
</svg>
SVG
}

format_count() {
  local count="${1:-0}"
  local label="$2"
  if (( count == 1 )); then
    printf '1 %s update' "${label}"
  else
    printf '%d %s updates' "${count}" "${label}"
  fi
}

apt_updates=0
flatpak_updates=0
apt_available=false
flatpak_available=false
apt_rows=()
flatpak_rows=()

if [[ "${include_apt}" = "true" ]] && command -v apt >/dev/null 2>&1; then
  apt_available=true
  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" = "Listing..." ]] && continue
    apt_updates=$((apt_updates + 1))
    if (( apt_updates <= 8 )); then
      apt_rows+=("--${line%%/*} | disabled=true")
    fi
  done < <(apt list --upgradable 2>/dev/null || true)
fi

if [[ "${include_flatpak}" = "true" ]] && command -v flatpak >/dev/null 2>&1; then
  flatpak_available=true
  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" = "Application ID" ]] && continue
    flatpak_updates=$((flatpak_updates + 1))
    if (( flatpak_updates <= 8 )); then
      flatpak_rows+=("--${line} | disabled=true")
    fi
  done < <(flatpak remote-ls --updates --columns=application 2>/dev/null || true)
fi

total_updates=$((apt_updates + flatpak_updates))

echo "| image=$(updates_icon "${total_updates}")"
echo "---"
echo "Updates"
echo "--Total: ${total_updates} | disabled=true"

if [[ "${include_apt}" = "true" ]]; then
  if [[ "${apt_available}" = "true" ]]; then
    echo "--APT: $(format_count "${apt_updates}" "APT") | disabled=true"
  else
    echo "--APT: unavailable | disabled=true"
  fi
fi

if [[ "${include_flatpak}" = "true" ]]; then
  if [[ "${flatpak_available}" = "true" ]]; then
    echo "--Flatpak: $(format_count "${flatpak_updates}" "Flatpak") | disabled=true"
  else
    echo "--Flatpak: unavailable | disabled=true"
  fi
fi

if (( ${#apt_rows[@]} > 0 )); then
  echo "---"
  echo "APT"
  for row in "${apt_rows[@]}"; do
    echo "${row}"
  done
  if (( apt_updates > ${#apt_rows[@]} )); then
    echo "--and $((apt_updates - ${#apt_rows[@]})) more | disabled=true"
  fi
fi

if (( ${#flatpak_rows[@]} > 0 )); then
  echo "---"
  echo "Flatpak"
  for row in "${flatpak_rows[@]}"; do
    echo "${row}"
  done
  if (( flatpak_updates > ${#flatpak_rows[@]} )); then
    echo "--and $((flatpak_updates - ${#flatpak_rows[@]})) more | disabled=true"
  fi
fi

echo "---"
if command -v cosmic-store >/dev/null 2>&1; then
  echo "Open COSMIC Store | bash=/bin/bash param1=-lc param2='cosmic-store >/dev/null 2>&1 &'"
else
  echo "Open update app | disabled=true"
fi
if [[ "${apt_available}" = "true" ]]; then
  echo "Show APT updates | bash=/bin/bash param1=-lc param2='apt list --upgradable; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
fi
if [[ "${flatpak_available}" = "true" ]]; then
  echo "Show Flatpak updates | bash=/bin/bash param1=-lc param2='flatpak remote-ls --updates; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
fi
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
