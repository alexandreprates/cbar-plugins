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
add_plugin "system.cpu" "CPU" "system" "Shows load average and CPU core count." "plugins/system/cpu.5s.sh" "5s" "bash" "en" "awk,getconf,uptime" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.memory" "Memory" "system" "Shows current memory usage." "plugins/system/memory.5s.sh" "5s" "bash" "en" "awk,free" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "system.disk" "Disk" "system" "Shows root filesystem usage." "plugins/system/disk.30s.sh" "30s" "bash" "en" "df,awk" "CBAR_DISK_PATH" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# network
add_plugin "network.public-ip" "Public IP" "network" "Shows the current public IP address." "plugins/network/public-ip.5m.sh" "5m" "bash" "en" "curl,wl-copy,xclip" "CBAR_PUBLIC_IP_URL" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "network.ping" "Ping" "network" "Checks connectivity to a configurable host." "plugins/network/ping.10s.sh" "10s" "bash" "en" "ping" "CBAR_PING_HOST" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# dev
add_plugin "dev.docker-containers" "Docker Containers" "dev" "Summarizes Docker container state." "plugins/dev/docker-containers.10s.sh" "10s" "bash" "en" "docker" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.github-notifications" "GitHub Notifications" "dev" "Shows GitHub notification count when gh is authenticated." "plugins/dev/github-notifications.1m.sh" "1m" "bash" "en" "gh" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "dev.openai-codex" "OpenAI Codex Usage" "dev" "Displays OpenAI Codex usage limits from local Codex session metadata." "plugins/dev/openai_codex.5m.sh" "5m" "bash" "en" "python3,sed,tr" "VAR_SHOW_7D,VAR_COLORS,VAR_SHOW_RESET,VAR_SHOW_BARS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# showcase
add_plugin "showcase.overview" "Showcase Overview" "showcase" "Demonstrates panel titles, cycle items, popup rows, nesting, alternates, hidden rows, disabled rows, and refresh." "plugins/showcase/showcase-overview.10s.sh" "10s" "bash" "en" "date" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "showcase.actions" "Showcase Actions" "showcase" "Demonstrates links, shell actions, terminal actions, and refresh-after-action." "plugins/showcase/showcase-actions.30s.sh" "30s" "bash" "en" "date,printf,sh" "" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "showcase.config" "Showcase Config" "showcase" "Demonstrates environment-variable driven plugin behavior." "plugins/showcase/showcase-config.1m.sh" "1m" "bash" "en" "date" "CBAR_SHOWCASE_NAME,CBAR_SHOWCASE_URL,CBAR_SHOWCASE_MODE" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "showcase.memory-bar" "Showcase Memory Gauge" "showcase" "Demonstrates inline SVG images with a compact RAM usage gauge." "plugins/showcase/showcase-memory-bar.5s.sh" "5s" "bash" "en" "awk,base64,tr" "CBAR_SHOWCASE_RAM_WARN,CBAR_SHOWCASE_RAM_CRIT" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "showcase.cpu-chart" "Showcase CPU Chart" "showcase" "Demonstrates inline SVG images with a tiny CPU usage history chart." "plugins/showcase/showcase-cpu-chart.5s.sh" "5s" "bash" "en" "awk,base64,date,mkdir,tr" "CBAR_SHOWCASE_CPU_WARN" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "showcase.status" "Showcase Status" "showcase" "Demonstrates dynamic local status, thresholds, separators, and diagnostics." "plugins/showcase/showcase-status.5s.sh" "5s" "bash" "en" "awk,date,df,uptime" "CBAR_SHOWCASE_DISK_WARN" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

# productivity
add_plugin "productivity.timer" "Timer" "productivity" "Shows a simple countdown timer backed by per-user runtime state." "plugins/productivity/timer.1s.sh" "1s" "bash" "en" "date,mkdir,rm" "CBAR_TIMER_SECONDS" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"
add_plugin "productivity.calendar" "Calendar" "productivity" "Shows today's date and calendar shortcuts." "plugins/productivity/calendar.5m.sh" "5m" "bash" "en" "date,cal" "CBAR_CALENDAR_URL" "GPL-3.0-only" "AlexandrePrates" "https://github.com/AlexandrePrates"

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
