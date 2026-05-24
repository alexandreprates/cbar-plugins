#!/usr/bin/env bash
# Rebuilds the cbar plugin registry from the curated plugin metadata below.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
registry_dir="${repo_root}/registry"
registry_file="${registry_dir}/plugins.json"
raw_base_url="${CBAR_PLUGINS_RAW_BASE_URL:-https://raw.githubusercontent.com/alexandreprates/cbar-plugins/main}"

mkdir -p "${registry_dir}"

plugins=(
  "system.cpu|CPU|system|Shows load average and CPU core count.|plugins/system/cpu.5s.sh|5s|bash|awk,getconf,uptime||GPL-3.0-only"
  "system.memory|Memory|system|Shows current memory usage.|plugins/system/memory.5s.sh|5s|bash|awk,free||GPL-3.0-only"
  "system.disk|Disk|system|Shows root filesystem usage.|plugins/system/disk.30s.sh|30s|bash|df,awk|CBAR_DISK_PATH|GPL-3.0-only"
  "network.public-ip|Public IP|network|Shows the current public IP address.|plugins/network/public-ip.5m.sh|5m|bash|curl|CBAR_PUBLIC_IP_URL|GPL-3.0-only"
  "network.ping|Ping|network|Checks connectivity to a configurable host.|plugins/network/ping.10s.sh|10s|bash|ping|CBAR_PING_HOST|GPL-3.0-only"
  "dev.docker-containers|Docker Containers|dev|Summarizes Docker container state.|plugins/dev/docker-containers.10s.sh|10s|bash|docker||GPL-3.0-only"
  "dev.github-notifications|GitHub Notifications|dev|Shows GitHub notification count when gh is authenticated.|plugins/dev/github-notifications.1m.sh|1m|bash|gh||GPL-3.0-only"
  "dev.openai-codex|OpenAI Codex Usage|dev|Displays OpenAI Codex usage limits from local Codex session metadata.|plugins/dev/openai_codex.5m.sh|5m|bash|python3,sed,tr|VAR_SHOW_7D,VAR_COLORS,VAR_SHOW_RESET,VAR_SHOW_BARS|GPL-3.0-only"
  "showcase.overview|Showcase Overview|showcase|Demonstrates panel titles, cycle items, popup rows, nesting, alternates, hidden rows, disabled rows, and refresh.|plugins/showcase/showcase-overview.10s.sh|10s|bash|date||GPL-3.0-only"
  "showcase.actions|Showcase Actions|showcase|Demonstrates links, shell actions, terminal actions, and refresh-after-action.|plugins/showcase/showcase-actions.30s.sh|30s|bash|date,printf,sh||GPL-3.0-only"
  "showcase.config|Showcase Config|showcase|Demonstrates environment-variable driven plugin behavior.|plugins/showcase/showcase-config.1m.sh|1m|bash|date|CBAR_SHOWCASE_NAME,CBAR_SHOWCASE_URL,CBAR_SHOWCASE_MODE|GPL-3.0-only"
  "showcase.memory-bar|Showcase Memory Gauge|showcase|Demonstrates inline SVG images with a compact RAM usage gauge.|plugins/showcase/showcase-memory-bar.5s.sh|5s|bash|awk,base64,tr|CBAR_SHOWCASE_RAM_WARN,CBAR_SHOWCASE_RAM_CRIT|GPL-3.0-only"
  "showcase.cpu-chart|Showcase CPU Chart|showcase|Demonstrates inline SVG images with a tiny CPU usage history chart.|plugins/showcase/showcase-cpu-chart.5s.sh|5s|bash|awk,base64,mkdir,tr|CBAR_SHOWCASE_CPU_WARN|GPL-3.0-only"
  "showcase.status|Showcase Status|showcase|Demonstrates dynamic local status, thresholds, separators, and diagnostics.|plugins/showcase/showcase-status.5s.sh|5s|bash|awk,date,df,uptime|CBAR_SHOWCASE_DISK_WARN|GPL-3.0-only"
  "productivity.timer|Timer|productivity|Shows a simple countdown timer backed by /tmp.|plugins/productivity/timer.1s.sh|1s|bash|date,rm|CBAR_TIMER_SECONDS|GPL-3.0-only"
  "productivity.calendar|Calendar|productivity|Shows today's date and calendar shortcuts.|plugins/productivity/calendar.5m.sh|5m|bash|date,cal|CBAR_CALENDAR_URL|GPL-3.0-only"
)

json_array() {
  local csv="${1}"
  local first=1

  printf '['
  if [[ -n "${csv}" ]]; then
    IFS=',' read -r -a values <<< "${csv}"
    for value in "${values[@]}"; do
      if [[ "${first}" -eq 0 ]]; then
        printf ', '
      fi
      printf '"%s"' "${value}"
      first=0
    done
  fi
  printf ']'
}

{
  printf '{\n'
  printf '  "version": 1,\n'
  printf '  "repository": "alexandreprates/cbar-plugins",\n'
  printf '  "raw_base_url": "%s",\n' "${raw_base_url}"
  printf '  "plugins": [\n'

  first_plugin=1
  for plugin in "${plugins[@]}"; do
    IFS='|' read -r id name category description path interval language dependencies env license <<< "${plugin}"
    full_path="${repo_root}/${path}"

    if [[ ! -f "${full_path}" ]]; then
      printf 'missing plugin file: %s\n' "${path}" >&2
      exit 1
    fi

    sha256="$(sha256sum "${full_path}" | awk '{ print $1 }')"
    size_bytes="$(wc -c < "${full_path}" | tr -d ' ')"

    if [[ "${first_plugin}" -eq 0 ]]; then
      printf ',\n'
    fi

    printf '    {\n'
    printf '      "id": "%s",\n' "${id}"
    printf '      "name": "%s",\n' "${name}"
    printf '      "category": "%s",\n' "${category}"
    printf '      "description": "%s",\n' "${description}"
    printf '      "path": "%s",\n' "${path}"
    printf '      "download_url": "%s/%s",\n' "${raw_base_url}" "${path}"
    printf '      "install_name": "%s",\n' "$(basename "${path}")"
    printf '      "interval": "%s",\n' "${interval}"
    printf '      "language": "%s",\n' "${language}"
    printf '      "dependencies": '
    json_array "${dependencies}"
    printf ',\n'
    printf '      "env": '
    json_array "${env}"
    printf ',\n'
    printf '      "sha256": "%s",\n' "${sha256}"
    printf '      "size_bytes": %s,\n' "${size_bytes}"
    printf '      "license": "%s"\n' "${license}"
    printf '    }'

    first_plugin=0
  done

  printf '\n  ]\n'
  printf '}\n'
} > "${registry_file}"

printf 'wrote %s\n' "${registry_file}"
