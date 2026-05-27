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
# id, name, category, description, path, interval, language, languages,
# dependencies, env, license, publisher, publisher_url.
add_plugin() {
  if [[ "$#" -ne 13 ]]; then
    printf 'add_plugin expected 13 fields, got %s\n' "$#" >&2
    exit 1
  fi

  plugins+=("$1|$2|$3|$4|$5|$6|$7|$8|$9|${10}|${11}|${12}|${13}")
}

# system
add_plugin "system.cpu-chart" "CPU Chart" "system" "Shows CPU usage history as a compact panel chart." "plugins/system/cpu-chart.5s.sh" "5s" "bash" "en" "awk,base64,mkdir,tr" "CBAR_CPU_WARN" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.memory-gauge" "Memory Gauge" "system" "Shows RAM usage as a compact panel gauge." "plugins/system/memory-gauge.5s.sh" "5s" "bash" "en" "awk,base64,tr" "CBAR_MEMORY_WARN,CBAR_MEMORY_CRIT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.disk" "Disk" "system" "Shows filesystem usage as compact segmented blocks." "plugins/system/disk.30s.sh" "30s" "bash" "en" "awk,base64,df,tr" "CBAR_DISK_PATH,CBAR_DISK_WARN,CBAR_DISK_CRIT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# network
add_plugin "network.public-ip" "Public IP" "network" "Shows public and local IP status with copy actions." "plugins/network/public-ip.5m.sh" "5m" "bash" "en" "awk,base64,curl,ip,tr,wl-copy,xclip" "CBAR_PUBLIC_IP_URL" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.ping" "Ping" "network" "Shows compact latency to a configurable host." "plugins/network/ping.10s.sh" "10s" "bash" "en" "awk,ping" "CBAR_PING_HOST,CBAR_PING_WARN_MS,CBAR_PING_CRIT_MS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# dev
add_plugin "dev.docker-health" "Docker Health" "dev" "Shows Docker daemon and container health." "plugins/dev/docker-health.10s.sh" "10s" "bash" "en" "awk,base64,docker,sed,tr" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.github-notifications" "GitHub Notifications" "dev" "Shows GitHub notification status with an unread badge." "plugins/dev/github-notifications.1m.sh" "1m" "bash" "en" "base64,gh,mkdir,tr" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.openai-codex" "OpenAI Codex Usage" "dev" "Displays OpenAI Codex usage limits from local Codex session metadata." "plugins/dev/openai_codex.5m.sh" "5m" "bash" "en" "python3,sed,tr" "CBAR_CODEX_SHOW_7D,CBAR_CODEX_COLORS,CBAR_CODEX_SHOW_RESET,CBAR_CODEX_SHOW_BARS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# productivity
add_plugin "productivity.timer" "Timer" "productivity" "Shows a compact animated hourglass countdown timer." "plugins/productivity/timer.1s.sh" "1s" "bash" "en" "base64,date,mkdir,rm,tr" "CBAR_TIMER_SECONDS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

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
    if len(fields) != 13:
        raise SystemExit(f"invalid plugin metadata field count: {line}")

    (
        plugin_id,
        name,
        category,
        description,
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

    content = full_path.read_bytes()
    plugins.append(
        {
            "id": plugin_id,
            "name": name,
            "category": category,
            "description": description,
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
