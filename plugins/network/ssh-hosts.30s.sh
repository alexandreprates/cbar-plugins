#!/usr/bin/env bash
# cbar: Shows configured SSH host reachability with compact status.
# deps: awk, base64, date, ssh, tr, wl-copy, xclip
# env: CBAR_SSH_HOSTS, CBAR_SSH_WARN_MS, CBAR_SSH_TIMEOUT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

hosts_csv="${CBAR_SSH_HOSTS:-}"
warn_ms="${CBAR_SSH_WARN_MS:-750}"
timeout="${CBAR_SSH_TIMEOUT:-3}"

case "${warn_ms}" in
  ''|*[!0-9]*)
    warn_ms=750
    ;;
esac

case "${timeout}" in
  ''|*[!0-9]*)
    timeout=3
    ;;
esac

if (( timeout < 1 )); then
  timeout=1
elif (( timeout > 10 )); then
  timeout=10
fi

ssh_icon() {
  local color="$1"
  local severity="$2"
  local badge=""

  case "${severity}" in
    critical)
      badge="<circle cx=\"15\" cy=\"15\" r=\"3.2\" fill=\"#f85149\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
    warning)
      badge="<circle cx=\"15\" cy=\"15\" r=\"3.2\" fill=\"#f59e0b\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
  esac

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <rect x="3.5" y="5" width="13" height="10" rx="2" fill="none" stroke="${color}" stroke-width="1.6"/>
  <path d="M6.4 8.1 8.5 10l-2.1 1.9M9.8 12h3.6" fill="none" stroke="${color}" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"/>
  ${badge}
</svg>
SVG
}

copy_command() {
  local value="$1"
  printf "if command -v wl-copy >/dev/null 2>&1; then printf %%s \"%s\" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %%s \"%s\" | xclip -selection clipboard; else printf %%s \"%s\"; fi" "${value}" "${value}" "${value}"
}

sanitize_host() {
  local host="$1"
  [[ "${host}" =~ ^[A-Za-z0-9_.@%:+-]+$ ]] && printf '%s\n' "${host}"
}

probe_host() {
  local host="$1"
  local start end elapsed

  start="$(date +%s%3N 2>/dev/null || date +%s000)"
  if ssh \
    -o BatchMode=yes \
    -o ConnectTimeout="${timeout}" \
    -o StrictHostKeyChecking=accept-new \
    -o PasswordAuthentication=no \
    -o KbdInteractiveAuthentication=no \
    "${host}" true >/dev/null 2>&1; then
    end="$(date +%s%3N 2>/dev/null || date +%s000)"
    elapsed=$((end - start))
    printf 'ok %s\n' "${elapsed}"
    return
  fi

  end="$(date +%s%3N 2>/dev/null || date +%s000)"
  elapsed=$((end - start))
  printf 'down %s\n' "${elapsed}"
}

if ! command -v ssh >/dev/null 2>&1; then
  echo "| image=$(ssh_icon "#8b949e" "warning")"
  echo "---"
  echo "SSH hosts"
  echo "--Missing dependency: ssh | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

if [[ -z "${hosts_csv}" ]]; then
  echo "| image=$(ssh_icon "#8b949e" "warning")"
  echo "---"
  echo "SSH hosts"
  echo "--No hosts configured | disabled=true"
  echo "--Set CBAR_SSH_HOSTS in ~/.config/cbar/env | disabled=true"
  echo "Refresh | refresh=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

IFS=',' read -ra raw_hosts <<< "${hosts_csv}"
rows=()
actions=()
total=0
ok_count=0
slow_count=0
down_count=0

for raw_host in "${raw_hosts[@]}"; do
  raw_host="$(printf '%s' "${raw_host}" | tr -d '[:space:]')"
  [[ -z "${raw_host}" ]] && continue

  host="$(sanitize_host "${raw_host}")"
  [[ -z "${host}" ]] && continue

  total=$((total + 1))
  read -r status elapsed < <(probe_host "${host}")

  if [[ "${status}" = "ok" ]]; then
    if (( elapsed >= warn_ms )); then
      slow_count=$((slow_count + 1))
      rows+=("--${host}: ${elapsed}ms | color=#f59e0b")
    else
      ok_count=$((ok_count + 1))
      rows+=("--${host}: ${elapsed}ms | color=#2ea043")
    fi
  else
    down_count=$((down_count + 1))
    rows+=("--${host}: offline | color=#f85149")
  fi

  actions+=("Open SSH: ${host} | bash=/bin/bash param1=-lc param2='ssh \"${host}\"' terminal=true")
  actions+=("Copy host: ${host} | bash=/bin/bash param1=-lc param2='$(copy_command "${host}")'")
done

severity="ok"
color="#2ea043"
summary="${ok_count}/${total} reachable"
if (( total == 0 )); then
  severity="warning"
  color="#f59e0b"
  summary="no valid hosts"
elif (( down_count > 0 )); then
  severity="critical"
  color="#f85149"
  summary="${down_count}/${total} offline"
elif (( slow_count > 0 )); then
  severity="warning"
  color="#f59e0b"
  summary="${slow_count}/${total} slow"
fi

echo "| image=$(ssh_icon "${color}" "${severity}")"
echo "---"
echo "SSH hosts"
echo "--Summary: ${summary} | disabled=true"
echo "--Warning: ${warn_ms}ms | disabled=true"
echo "--Timeout: ${timeout}s | disabled=true"

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
  echo "Open SSH | disabled=true"
fi
echo "Refresh | refresh=true"
echo "---"
edit_cbar_env_item
