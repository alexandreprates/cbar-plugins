#!/usr/bin/env bash
# cbar: Shows CPU, memory, and disk usage as compact health bars.
# deps: awk, base64, df, python3, sleep, tr
# env: CBAR_OS_HEALTH_DISK_PATH, CBAR_OS_HEALTH_CPU_WARN, CBAR_OS_HEALTH_CPU_CRIT, CBAR_OS_HEALTH_MEMORY_WARN, CBAR_OS_HEALTH_MEMORY_CRIT, CBAR_OS_HEALTH_DISK_WARN, CBAR_OS_HEALTH_DISK_CRIT

set -euo pipefail

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

clamp_percent() {
  local value="${1:-0}"
  case "$value" in
    ''|*[!0-9]*)
      value=0
      ;;
  esac

  if (( value < 0 )); then
    value=0
  elif (( value > 100 )); then
    value=100
  fi

  echo "$value"
}

threshold() {
  local value="${1:-0}" fallback="$2"
  case "$value" in
    ''|*[!0-9]*)
      value="$fallback"
      ;;
  esac

  clamp_percent "$value"
}

format_kib_gib() {
  awk -v value="$1" 'BEGIN { printf "%.2f GiB", value / 1048576 }'
}

read_cpu_snapshot() {
  awk '
    /^cpu / {
      idle = $5 + $6
      total = 0
      for (i = 2; i <= NF; i++) {
        total += $i
      }
      print idle, total
    }
  ' /proc/stat
}

read -r cpu_idle_a cpu_total_a < <(read_cpu_snapshot)
sleep 0.1
read -r cpu_idle_b cpu_total_b < <(read_cpu_snapshot)

cpu_usage=0
cpu_total_delta=$(( cpu_total_b - cpu_total_a ))
cpu_idle_delta=$(( cpu_idle_b - cpu_idle_a ))
if (( cpu_total_delta > 0 )); then
  cpu_usage=$(( (100 * (cpu_total_delta - cpu_idle_delta)) / cpu_total_delta ))
fi
cpu_usage="$(clamp_percent "$cpu_usage")"

read -r mem_total mem_available < <(
  awk '
    /^MemTotal:/ { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END { print total, available }
  ' /proc/meminfo
)

memory_available_percent=0
if (( mem_total > 0 )); then
  memory_available_percent=$(( mem_available * 100 / mem_total ))
fi
memory_available_percent="$(clamp_percent "$memory_available_percent")"
memory_used=$(( mem_total - mem_available ))
memory_used_percent=$(( 100 - memory_available_percent ))
memory_used_percent="$(clamp_percent "$memory_used_percent")"

disk_path="${CBAR_OS_HEALTH_DISK_PATH:-/}"
read -r disk_size disk_used disk_available disk_percent disk_mount < <(
  df -kP "$disk_path" | awk 'NR == 2 { print $2, $3, $4, $5, $6 }'
)

if [[ -z "${disk_percent:-}" ]]; then
  echo "OS ?"
  echo "---"
  echo "Unable to inspect ${disk_path} | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

disk_used_percent="$(clamp_percent "${disk_percent%\%}")"
disk_available_percent=$(( 100 - disk_used_percent ))
disk_available_percent="$(clamp_percent "$disk_available_percent")"

cpu_warn="$(threshold "${CBAR_OS_HEALTH_CPU_WARN:-75}" 75)"
cpu_crit="$(threshold "${CBAR_OS_HEALTH_CPU_CRIT:-90}" 90)"
memory_warn="$(threshold "${CBAR_OS_HEALTH_MEMORY_WARN:-75}" 75)"
memory_crit="$(threshold "${CBAR_OS_HEALTH_MEMORY_CRIT:-90}" 90)"
disk_warn="$(threshold "${CBAR_OS_HEALTH_DISK_WARN:-80}" 80)"
disk_crit="$(threshold "${CBAR_OS_HEALTH_DISK_CRIT:-90}" 90)"

if (( cpu_warn >= cpu_crit )); then
  cpu_warn=$(( cpu_crit - 10 ))
fi
if (( cpu_warn < 0 )); then
  cpu_warn=0
fi

if (( memory_warn >= memory_crit )); then
  memory_warn=$(( memory_crit - 10 ))
fi
if (( memory_warn < 0 )); then
  memory_warn=0
fi

if (( disk_warn >= disk_crit )); then
  disk_warn=$(( disk_crit - 10 ))
fi
if (( disk_warn < 0 )); then
  disk_warn=0
fi

make_health_svg() {
  local cpu_pct="$1" memory_pct="$2" disk_pct="$3"
  local cpu_warn_pct="$4" cpu_crit_pct="$5"
  local memory_warn_pct="$6" memory_crit_pct="$7"
  local disk_warn_pct="$8" disk_crit_pct="$9"

  python3 -c "
import base64
import math

cpu = min(max(int(${cpu_pct}), 0), 100)
memory = min(max(int(${memory_pct}), 0), 100)
disk = min(max(int(${disk_pct}), 0), 100)
cpu_warn = min(max(int(${cpu_warn_pct}), 0), 100)
cpu_crit = min(max(int(${cpu_crit_pct}), 0), 100)
memory_warn = min(max(int(${memory_warn_pct}), 0), 100)
memory_crit = min(max(int(${memory_crit_pct}), 0), 100)
disk_warn = min(max(int(${disk_warn_pct}), 0), 100)
disk_crit = min(max(int(${disk_crit_pct}), 0), 100)

def cpu_fill(pct):
    if pct >= cpu_crit:
        return '#f85149'
    if pct >= cpu_warn:
        return '#f59e0b'
    return '#ffffff'

def usage_fill(pct, warn, crit):
    if pct >= crit:
        return '#f85149'
    if pct >= warn:
        return '#f59e0b'
    return '#ffffff'

def row(y, pct, color):
    filled = 0 if pct <= 0 else max(1, min(10, math.ceil(pct / 10)))
    blocks = []
    for index in range(10):
        active = index < filled
        opacity = '1' if active else '0.26'
        x = 2 + (index * 3.6)
        blocks.append(
            f'<rect x=\"{x}\" y=\"{y}\" width=\"3\" height=\"4\" rx=\"1\" '
            f'fill=\"{color}\" fill-opacity=\"{opacity}\"/>'
        )
    return ''.join(blocks)

svg = f'''<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"24\" viewBox=\"0 0 40 24\">
{row(2, cpu, cpu_fill(cpu))}
{row(10, memory, usage_fill(memory, memory_warn, memory_crit))}
{row(18, disk, usage_fill(disk, disk_warn, disk_crit))}
</svg>'''

print(base64.b64encode(svg.encode('utf-8')).decode())
" 2>/dev/null
}

title_color() {
  if (( cpu_usage >= cpu_crit || memory_used_percent >= memory_crit || disk_used_percent >= disk_crit )); then
    echo "#CC0000"
  elif (( cpu_usage >= cpu_warn || memory_used_percent >= memory_warn || disk_used_percent >= disk_warn )); then
    echo "#CC8800"
  else
    echo ""
  fi
}

health_image="$(make_health_svg "$cpu_usage" "$memory_used_percent" "$disk_used_percent" "$cpu_warn" "$cpu_crit" "$memory_warn" "$memory_crit" "$disk_warn" "$disk_crit")"
panel_color="$(title_color)"

if [[ -n "$panel_color" ]]; then
  echo "| image=${health_image} color=${panel_color}"
else
  echo "| image=${health_image}"
fi

echo "---"
echo "CPU: ${cpu_usage}% used"
echo "--Warning: ${cpu_warn}% | disabled=true"
echo "--Critical: ${cpu_crit}% | disabled=true"
echo "Open CPU details | shell=/bin/sh param1=-lc param2='top -b -n 1 | head -20; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "---"
echo "Memory: ${memory_used_percent}% used"
echo "--Available: $(format_kib_gib "$mem_available") | disabled=true"
echo "--Used: $(format_kib_gib "$memory_used") | disabled=true"
echo "--Total: $(format_kib_gib "$mem_total") | disabled=true"
echo "--Available: ${memory_available_percent}% | disabled=true"
echo "--Warning: ${memory_warn}% | disabled=true"
echo "--Critical: ${memory_crit}% | disabled=true"
echo "Open memory details | shell=/bin/sh param1=-lc param2='free -h; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "---"
echo "Disk: ${disk_used_percent}% used"
echo "--Available: $(format_kib_gib "$disk_available") | disabled=true"
echo "--Used: $(format_kib_gib "$disk_used") | disabled=true"
echo "--Size: $(format_kib_gib "$disk_size") | disabled=true"
echo "--Mount: ${disk_mount} | disabled=true"
echo "--Available: ${disk_available_percent}% | disabled=true"
echo "--Warning: ${disk_warn}% | disabled=true"
echo "--Critical: ${disk_crit}% | disabled=true"
echo "Open disk usage | bash=/bin/bash param1=-lc param2='xdg-open \"${disk_mount}\"'"
echo "---"
echo "Refresh | refresh=true"
edit_cbar_env_item
