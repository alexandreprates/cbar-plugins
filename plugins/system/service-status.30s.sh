#!/usr/bin/env bash
# cbar: Shows systemd service health with compact status and actions.
# deps: awk, base64, journalctl, systemctl, tr
# env: CBAR_SERVICE_UNITS

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

units_csv="${CBAR_SERVICE_UNITS:-}"

service_icon() {
  local color="$1"
  local severity="$2"
  local badge=""

  case "${severity}" in
    critical)
      badge="<circle cx=\"15\" cy=\"15\" r=\"3\" fill=\"#f85149\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
    warning)
      badge="<circle cx=\"15\" cy=\"15\" r=\"3\" fill=\"#f59e0b\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
  esac

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <rect x="4" y="4" width="12" height="3" rx="1.3" fill="${color}" fill-opacity="0.92"/>
  <rect x="4" y="8.5" width="12" height="3" rx="1.3" fill="${color}" fill-opacity="0.72"/>
  <rect x="4" y="13" width="12" height="3" rx="1.3" fill="${color}" fill-opacity="0.52"/>
  <circle cx="6" cy="5.5" r="0.7" fill="#0d1117" fill-opacity="0.8"/>
  <circle cx="6" cy="10" r="0.7" fill="#0d1117" fill-opacity="0.8"/>
  <circle cx="6" cy="14.5" r="0.7" fill="#0d1117" fill-opacity="0.8"/>
  ${badge}
</svg>
SVG
}

sanitize_unit() {
  local unit="$1"
  [[ "${unit}" =~ ^[A-Za-z0-9_.@:-]+$ ]] && printf '%s\n' "${unit}"
}

normalize_unit() {
  local unit="$1"
  if [[ "${unit}" != *.* ]]; then
    unit="${unit}.service"
  fi
  printf '%s\n' "${unit}"
}

scope_command() {
  local scope="$1"
  if [[ "${scope}" = "user" ]]; then
    printf 'systemctl --user'
  else
    printf 'systemctl'
  fi
}

journal_command() {
  local scope="$1"
  local unit="$2"
  if [[ "${scope}" = "user" ]]; then
    printf 'journalctl --user -u "%s" -n 80 --no-pager; printf "\\n"; read -r -p "Press enter to close..."' "${unit}"
  else
    printf 'journalctl -u "%s" -n 80 --no-pager; printf "\\n"; read -r -p "Press enter to close..."' "${unit}"
  fi
}

restart_command() {
  local scope="$1"
  local unit="$2"
  if [[ "${scope}" = "user" ]]; then
    printf 'systemctl --user restart "%s"; printf "\\n"; read -r -p "Press enter to close..."' "${unit}"
  else
    printf 'systemctl restart "%s"; printf "\\n"; read -r -p "Press enter to close..."' "${unit}"
  fi
}

if ! command -v systemctl >/dev/null 2>&1; then
  echo "| image=$(service_icon "#8b949e" "warning")"
  echo "---"
  echo "Service status"
  echo "--Missing dependency: systemctl | disabled=true"
  exit 0
fi

severity="ok"
color="#2ea043"
summary="running"
rows=()
actions=()

if [[ -n "${units_csv}" ]]; then
  IFS=',' read -ra configured_units <<< "${units_csv}"
  total=0
  active_count=0
  warning_count=0
  failed_count=0

  for raw_unit in "${configured_units[@]}"; do
    raw_unit="$(printf '%s' "${raw_unit}" | tr -d '[:space:]')"
    [[ -z "${raw_unit}" ]] && continue

    scope="system"
    if [[ "${raw_unit}" == user:* ]]; then
      scope="user"
      raw_unit="${raw_unit#user:}"
    fi

    unit="$(sanitize_unit "${raw_unit}")"
    [[ -z "${unit}" ]] && continue
    unit="$(normalize_unit "${unit}")"
    total=$((total + 1))

    cmd="$(scope_command "${scope}")"
    load_state="not-found"
    active_state="unknown"
    sub_state="unknown"
    description="${unit}"
    while IFS='=' read -r key value; do
      case "${key}" in
        LoadState) load_state="${value}" ;;
        ActiveState) active_state="${value}" ;;
        SubState) sub_state="${value}" ;;
        Description) description="${value:-${unit}}" ;;
      esac
    done < <(${cmd} show "${unit}" --property=LoadState,ActiveState,SubState,Description 2>/dev/null || true)

    case "${active_state}:${load_state}" in
      active:loaded)
        active_count=$((active_count + 1))
        state_color="#2ea043"
        ;;
      failed:*|*:not-found)
        failed_count=$((failed_count + 1))
        state_color="#f85149"
        ;;
      *)
        warning_count=$((warning_count + 1))
        state_color="#f59e0b"
        ;;
    esac

    rows+=("--${unit}: ${active_state}/${sub_state} | color=${state_color}")
    rows+=("--${description} | disabled=true")
    actions+=("Logs: ${unit} | bash=/bin/bash param1=-lc param2='$(journal_command "${scope}" "${unit}")' terminal=true")
    actions+=("Restart: ${unit} | bash=/bin/bash param1=-lc param2='$(restart_command "${scope}" "${unit}")' terminal=true refresh=true")
  done

  if (( total == 0 )); then
    severity="warning"
    color="#f59e0b"
    summary="no configured units"
  elif (( failed_count > 0 )); then
    severity="critical"
    color="#f85149"
    summary="${failed_count}/${total} failed"
  elif (( warning_count > 0 )); then
    severity="warning"
    color="#f59e0b"
    summary="${warning_count}/${total} inactive"
  else
    summary="${active_count}/${total} active"
  fi
else
  system_state="$(systemctl is-system-running 2>/dev/null || true)"
  failed_count="$(systemctl --failed --no-legend --plain 2>/dev/null | awk 'END { print NR + 0 }')"
  summary="${system_state:-unknown}"

  if (( failed_count > 0 )); then
    severity="critical"
    color="#f85149"
  elif [[ "${system_state}" != "running" && "${system_state}" != "degraded" ]]; then
    severity="warning"
    color="#f59e0b"
  elif [[ "${system_state}" = "degraded" ]]; then
    severity="critical"
    color="#f85149"
  fi

  while IFS= read -r failed_unit; do
    [[ -z "${failed_unit}" ]] && continue
    rows+=("--${failed_unit} | color=#f85149")
    actions+=("Logs: ${failed_unit%% *} | bash=/bin/bash param1=-lc param2='$(journal_command "system" "${failed_unit%% *}")' terminal=true")
    actions+=("Restart: ${failed_unit%% *} | bash=/bin/bash param1=-lc param2='$(restart_command "system" "${failed_unit%% *}")' terminal=true refresh=true")
  done < <(systemctl --failed --no-legend --plain 2>/dev/null | awk 'NR <= 5 { print $1 " " $3 "/" $4 }')
fi

echo "| image=$(service_icon "${color}" "${severity}")"
echo "---"
echo "Service status"
echo "--Summary: ${summary} | disabled=true"
if [[ -z "${units_csv}" ]]; then
  echo "--Failed units: ${failed_count:-0} | disabled=true"
  echo "--Set CBAR_SERVICE_UNITS in ~/.config/cbar/env to monitor specific units | disabled=true"
fi

if (( ${#rows[@]} > 0 )); then
  echo "---"
  for row in "${rows[@]}"; do
    echo "${row}"
  done
fi

echo "---"
if (( ${#actions[@]} > 0 )); then
  for action in "${actions[@]}"; do
    echo "${action}"
  done
else
  echo "Open system status | bash=/bin/bash param1=-lc param2='systemctl status; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
fi
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
