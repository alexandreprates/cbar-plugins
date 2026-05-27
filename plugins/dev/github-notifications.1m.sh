#!/usr/bin/env bash
# cbar: Shows GitHub notification status with a compact panel icon.
# deps: base64, gh, mkdir, tr
# optional: notify-send, paplay, pw-play
# env: none

set -u

cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/cbar"
state_file="${cache_dir}/github-notifications.state"

github_icon() {
  local color="$1"
  local badge="${2:-false}"
  local badge_svg=""

  if [[ "${badge}" = "true" ]]; then
    badge_svg='<circle cx="15.7" cy="15.2" r="3.4" fill="#f85149" stroke="#1f2328" stroke-width="1.2"/>'
  fi

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path fill="${color}" d="M10 1.8a8.2 8.2 0 0 0-2.6 16c.4.1.5-.2.5-.4v-1.5c-2.1.5-2.5-.9-2.5-.9-.3-.8-.8-1-1-1.1-.8-.5.1-.5.1-.5.9.1 1.4.9 1.4.9.8 1.4 2.1 1 2.6.8.1-.6.3-1 .6-1.2-1.7-.2-3.5-.8-3.5-3.8 0-.8.3-1.5.8-2.1-.1-.2-.4-1 .1-2.1 0 0 .7-.2 2.2.8.6-.2 1.3-.3 2-.3s1.4.1 2 .3c1.5-1 2.2-.8 2.2-.8.5 1.1.2 1.9.1 2.1.5.6.8 1.3.8 2.1 0 3-1.8 3.6-3.5 3.8.3.2.6.7.6 1.5v2.1c0 .2.1.5.6.4A8.2 8.2 0 0 0 10 1.8Z"/>
  ${badge_svg}
</svg>
SVG
}

play_notification_sound() {
  local sound

  for sound in \
    /usr/share/sounds/freedesktop/stereo/message.oga \
    /usr/share/sounds/freedesktop/stereo/complete.oga \
    /usr/share/sounds/freedesktop/stereo/bell.oga
  do
    if [[ -r "${sound}" ]]; then
      if command -v paplay >/dev/null 2>&1; then
        paplay "${sound}" >/dev/null 2>&1 &
        return
      fi
      if command -v pw-play >/dev/null 2>&1; then
        pw-play "${sound}" >/dev/null 2>&1 &
        return
      fi
    fi
  done
}

notify_new_notifications() {
  local count="$1"
  local previous="$2"
  local delta=$((count - previous))

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "GitHub" "${delta} new notification(s)" >/dev/null 2>&1 &
  fi

  play_notification_sound
}

if ! command -v gh >/dev/null 2>&1; then
  echo "| image=$(github_icon "#8b949e" false)"
  echo "---"
  echo "GitHub"
  echo "--Missing dependency: gh | disabled=true"
  echo "Open GitHub notifications | href=https://github.com/notifications"
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "| image=$(github_icon "#8b949e" false)"
  echo "---"
  echo "GitHub"
  echo "--gh is not authenticated | disabled=true"
  echo "Run gh auth login | bash=gh param1=auth param2=login terminal=true refresh=true"
  echo "Open GitHub notifications | href=https://github.com/notifications"
  exit 0
fi

count="$(gh api notifications --jq 'length' 2>/dev/null || echo "?")"

if [[ ! "${count}" =~ ^[0-9]+$ ]]; then
  echo "| image=$(github_icon "#f59e0b" false)"
  echo "---"
  echo "GitHub"
  echo "--Unable to read notifications | disabled=true"
  echo "Open GitHub notifications | href=https://github.com/notifications"
  echo "Refresh | refresh=true"
  exit 0
fi

mkdir -p "${cache_dir}" 2>/dev/null || true
previous=""
if [[ -r "${state_file}" ]]; then
  previous="$(cat "${state_file}" 2>/dev/null || true)"
fi

if [[ "${previous}" =~ ^[0-9]+$ ]] && (( count > previous )); then
  notify_new_notifications "${count}" "${previous}"
fi

printf '%s\n' "${count}" > "${state_file}" 2>/dev/null || true

badge="false"
if (( count > 0 )); then
  badge="true"
fi

echo "| image=$(github_icon "#e6edf3" "${badge}")"
echo "---"
echo "GitHub"
echo "--Unread notifications: ${count} | disabled=true"
echo "Open GitHub notifications | href=https://github.com/notifications"
echo "Refresh | refresh=true"
