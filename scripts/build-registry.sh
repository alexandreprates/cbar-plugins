#!/usr/bin/env bash
# Rebuilds the cbar plugin registry from the curated plugin metadata below.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
registry_dir="${repo_root}/registry"
registry_file="${registry_dir}/plugins.json"
raw_base_url="${CBAR_PLUGINS_RAW_BASE_URL:-https://raw.githubusercontent.com/alexandreprates/cbar-plugins/main}"

mkdir -p "${registry_dir}"

plugins=()

# Add new catalog entries below, grouped by category. Field order:
# id, name, category, description, plugin_version, path, interval, language, languages,
# dependencies, env, license, publisher, publisher_url.
add_plugin() {
  if [[ "$#" -ne 14 ]]; then
    printf 'add_plugin expected 14 fields, got %s\n' "$#" >&2
    exit 1
  fi

  plugins+=("$1|$2|$3|$4|$5|$6|$7|$8|$9|${10}|${11}|${12}|${13}|${14}")
}

# system
add_plugin "system.cpu-chart" "CPU Chart" "system" "Shows CPU usage history as a compact panel chart." "1.0.0" "plugins/system/cpu-chart.5s.sh" "5s" "bash" "en" "awk,base64,mkdir,tr" "CBAR_CPU_WARN" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.memory-gauge" "Memory Gauge" "system" "Shows RAM usage as a compact panel gauge." "1.0.0" "plugins/system/memory-gauge.5s.sh" "5s" "bash" "en" "awk,base64,tr" "CBAR_MEMORY_WARN,CBAR_MEMORY_CRIT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.disk" "Disk" "system" "Shows filesystem usage as compact segmented blocks." "1.0.0" "plugins/system/disk.30s.sh" "30s" "bash" "en" "awk,base64,df,tr" "CBAR_DISK_PATH,CBAR_DISK_WARN,CBAR_DISK_CRIT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.service-status" "Service Status" "system" "Shows systemd service health with compact status and actions." "1.0.0" "plugins/system/service-status.30s.sh" "30s" "bash" "en" "awk,base64,journalctl,systemctl,tr" "CBAR_SERVICE_UNITS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.updates-available" "Updates Available" "system" "Shows available APT and Flatpak updates with a compact badge." "1.0.0" "plugins/system/updates-available.30m.sh" "30m" "bash" "en" "apt,awk,base64,cosmic-store,flatpak,tr" "CBAR_UPDATES_INCLUDE_APT,CBAR_UPDATES_INCLUDE_FLATPAK" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# network
add_plugin "network.public-ip" "Public IP" "network" "Shows public and local IP status with copy actions." "1.0.0" "plugins/network/public-ip.5m.sh" "5m" "bash" "en" "awk,base64,curl,ip,tr,wl-copy,xclip" "CBAR_PUBLIC_IP_URL" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.network-throughput" "Network Throughput" "network" "Shows upload and download throughput as a compact panel chart." "1.0.0" "plugins/network/network-throughput.2s.sh" "2s" "bash" "en" "awk,base64,cat,date,ip,mkdir,tr" "CBAR_NETWORK_INTERFACE" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.vpn-status" "VPN Status" "network" "Shows VPN connection status with interface and copy actions." "1.0.0" "plugins/network/vpn-status.10s.sh" "10s" "bash" "en" "awk,base64,cat,ip,nmcli,tr,wl-copy,xclip" "CBAR_VPN_INTERFACE" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.ssh-hosts" "SSH Hosts" "network" "Shows configured SSH host reachability with compact status." "1.0.0" "plugins/network/ssh-hosts.30s.sh" "30s" "bash" "en" "awk,base64,date,ssh,tr,wl-copy,xclip" "CBAR_SSH_HOSTS,CBAR_SSH_WARN_MS,CBAR_SSH_TIMEOUT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.ping" "Ping" "network" "Shows compact latency to a configurable host." "1.0.0" "plugins/network/ping.10s.sh" "10s" "bash" "en" "awk,ping" "CBAR_PING_HOST,CBAR_PING_WARN_MS,CBAR_PING_CRIT_MS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# dev
add_plugin "dev.docker-health" "Docker Health" "dev" "Shows Docker daemon and container health." "1.0.0" "plugins/dev/docker-health.10s.sh" "10s" "bash" "en" "awk,base64,docker,sed,tr" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.github-notifications" "GitHub Notifications" "dev" "Shows GitHub notification status with an unread badge." "1.0.0" "plugins/dev/github-notifications.1m.sh" "1m" "bash" "en" "base64,gh,mkdir,tr" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.kubernetes-context" "Kubernetes Context" "dev" "Shows current Kubernetes context and namespace with production alerts." "1.0.0" "plugins/dev/kubernetes-context.30s.sh" "30s" "bash" "en" "base64,kubectl,python3,tr,wl-copy,xclip" "CBAR_KUBE_PROD_PATTERN" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.openai-codex" "OpenAI Codex Usage" "dev" "Displays OpenAI Codex usage limits from local Codex session metadata." "1.0.0" "plugins/dev/openai_codex.5m.sh" "5m" "bash" "en" "python3,sed,tr" "CBAR_CODEX_SHOW_7D,CBAR_CODEX_COLORS,CBAR_CODEX_SHOW_RESET,CBAR_CODEX_SHOW_BARS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# productivity
add_plugin "productivity.keep-awake" "Keep Awake" "productivity" "Keeps the current desktop session awake with a toggleable inhibitor." "1.0.0" "plugins/productivity/keep-awake.1m.sh" "1m" "bash" "en" "base64,cat,chmod,date,grep,mkdir,pgrep,python3,rm,systemd-inhibit,tr" "CBAR_AWAKE_WHAT,CBAR_AWAKE_REASON" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "productivity.timer" "Timer" "productivity" "Shows a compact animated hourglass countdown timer." "1.0.0" "plugins/productivity/timer.1s.sh" "1s" "bash" "en" "base64,date,mkdir,rm,tr" "CBAR_TIMER_SECONDS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

REPO_ROOT="${repo_root}" RAW_BASE_URL="${raw_base_url}" REGISTRY_FILE="${registry_file}" python3 - "${plugins[@]}" <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path

repo_root = Path(os.environ["REPO_ROOT"])
raw_base_url = os.environ["RAW_BASE_URL"].rstrip("/")
registry_file = Path(os.environ["REGISTRY_FILE"])
metadata = sys.argv[1:]

def csv_list(value):
    if not value:
        return []
    return [item for item in value.split(",") if item]

plugins = []
for line in metadata:
    fields = line.split("|")
    if len(fields) != 14:
        raise SystemExit(f"invalid plugin metadata field count: {line}")

    (
        plugin_id,
        name,
        category,
        description,
        plugin_version,
        path,
        interval,
        language,
        languages,
        dependencies,
        env,
        license_name,
        publisher,
        publisher_url,
    ) = fields

    full_path = repo_root / path
    if not full_path.is_file():
        raise SystemExit(f"missing plugin file: {path}")
    if not publisher:
        raise SystemExit(f"missing publisher metadata: {plugin_id}")
    if not plugin_version:
        raise SystemExit(f"missing plugin version metadata: {plugin_id}")

    content = full_path.read_bytes()
    plugins.append(
        {
            "id": plugin_id,
            "name": name,
            "category": category,
            "description": description,
            "plugin_version": plugin_version,
            "path": path,
            "download_url": f"{raw_base_url}/{path}",
            "install_name": full_path.name,
            "interval": interval,
            "language": language,
            "languages": csv_list(languages),
            "dependencies": csv_list(dependencies),
            "env": csv_list(env),
            "sha256": hashlib.sha256(content).hexdigest(),
            "size_bytes": len(content),
            "license": license_name,
            "publisher": publisher,
            "publisher_url": publisher_url,
        }
    )

registry = {
    "version": 1,
    "repository": "alexandreprates/cbar-plugins",
    "raw_base_url": raw_base_url,
    "plugins": plugins,
}

registry_file.write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")
PY

printf 'wrote %s\n' "${registry_file}"
