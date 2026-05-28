#!/usr/bin/env bash
# cbar: Keeps the current desktop session awake with a toggleable inhibitor.
# deps: base64, cat, chmod, date, grep, mkdir, rm, systemd-inhibit, tr
# env: CBAR_AWAKE_WHAT, CBAR_AWAKE_REASON

set -u

state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-${HOME}/.cache}/cbar}"
state_file="${state_dir}/keep-awake.pid"
action_file="${XDG_RUNTIME_DIR:-${state_dir}}/ka"
what="${CBAR_AWAKE_WHAT:-idle:sleep}"
reason="${CBAR_AWAKE_REASON:-cbar keep awake}"
now="$(date '+%H:%M:%S')"
script_path="${BASH_SOURCE[0]}"

case "${script_path}" in
  /*) ;;
  *) script_path="${PWD}/${script_path}" ;;
esac

mkdir -p "${state_dir}" 2>/dev/null || true

write_action_file() {
  cat > "${action_file}" <<EOF
#!/usr/bin/env bash
exec "${script_path}" "\${1:-toggle}"
EOF
  chmod +x "${action_file}" 2>/dev/null || true
}

coffee_image() {
  local active="${1:-false}"
  local cup_fill="none"
  local steam="#8b949e"
  local stroke="#8b949e"

  if [[ "${active}" = "true" ]]; then
    cup_fill="#d29922"
    steam="#f0c674"
    stroke="#f0c674"
  fi

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M7 2.8c-.7.7-.7 1.4 0 2.1s.7 1.4 0 2.1M10 2.4c-.7.7-.7 1.5 0 2.2s.7 1.5 0 2.2M13 2.8c-.7.7-.7 1.4 0 2.1s.7 1.4 0 2.1" fill="none" stroke="${steam}" stroke-width="1.25" stroke-linecap="round"/>
  <path d="M4.5 8.5h8.8v4.2a3.8 3.8 0 0 1-3.8 3.8H8.3a3.8 3.8 0 0 1-3.8-3.8V8.5Z" fill="${cup_fill}" stroke="${stroke}" stroke-width="1.4" stroke-linejoin="round"/>
  <path d="M13.3 9.4h1.1a2 2 0 0 1 0 4h-1.1" fill="none" stroke="${stroke}" stroke-width="1.4" stroke-linecap="round"/>
  <path d="M4 17.5h11" fill="none" stroke="${stroke}" stroke-width="1.4" stroke-linecap="round"/>
</svg>
SVG
}

pid_is_running() {
  local pid="${1:-}"

  [[ "${pid}" =~ ^[0-9]+$ ]] || return 1
  kill -0 "${pid}" 2>/dev/null || return 1

  if [[ -r "/proc/${pid}/cmdline" ]]; then
    tr '\0' ' ' < "/proc/${pid}/cmdline" | grep -q 'cbar-keep-awake'
  else
    return 0
  fi
}

start_awake() {
  local current_pid=""

  if [[ -f "${state_file}" ]]; then
    read -r current_pid _ < "${state_file}" || true
  fi

  if pid_is_running "${current_pid}"; then
    return 0
  fi

  nohup systemd-inhibit --what="${what}" --who=cbar-keep-awake --why="${reason}" --mode=block sleep infinity >/dev/null 2>&1 &
  printf '%s\n' "$!" > "${state_file}"
}

stop_awake() {
  local current_pid=""

  if [[ -f "${state_file}" ]]; then
    read -r current_pid _ < "${state_file}" || true
  fi

  if [[ "${current_pid}" =~ ^[0-9]+$ ]]; then
    kill "${current_pid}" 2>/dev/null || true
  fi

  rm -f "${state_file}" 2>/dev/null || true
}

pid=""
if [[ -f "${state_file}" ]]; then
  read -r pid _ < "${state_file}" || true
fi

running=false
if pid_is_running "${pid}"; then
  running=true
elif [[ -f "${state_file}" ]]; then
  rm -f "${state_file}" 2>/dev/null || true
fi

case "${1:-}" in
  start)
    command -v systemd-inhibit >/dev/null 2>&1 && start_awake
    exit 0
    ;;
  stop)
    stop_awake
    exit 0
    ;;
  toggle)
    if [[ "${running}" = "true" ]]; then
      stop_awake
    elif command -v systemd-inhibit >/dev/null 2>&1; then
      start_awake
    fi
    exit 0
    ;;
esac

if ! command -v systemd-inhibit >/dev/null 2>&1; then
  echo "| image=$(coffee_image false)"
  echo "---"
  echo "systemd-inhibit is not installed | disabled=true"
  echo "Updated: ${now} | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

write_action_file

if [[ "${running}" = "true" ]]; then
  echo "| image=$(coffee_image true)"
else
  echo "| image=$(coffee_image false)"
fi

echo "---"
if [[ "${running}" = "true" ]]; then
  echo "Desativar | bash=${action_file} refresh=true"
  echo "Status: ativo | disabled=true"
else
  echo "Ativar | bash=${action_file} refresh=true"
  echo "Status: inativo | disabled=true"
fi
