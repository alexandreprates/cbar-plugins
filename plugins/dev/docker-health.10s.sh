#!/usr/bin/env bash
# cbar: Shows Docker daemon and container health.
# deps: awk, base64, docker, sed, tr
# env: none

set -u

docker_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <rect x="4" y="8" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="7" y="8" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="10" y="8" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="13" y="8" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="7" y="5" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="10" y="5" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <rect x="10" y="2" width="2.5" height="2.5" rx="0.45" fill="${color}"/>
  <path d="M2.7 11.2h12.8c1.3 0 2.3-.4 3-1.1-.2 1.5-.9 2.8-2 3.8-1.4 1.3-3.5 2-6.2 2H7.2c-2.4 0-4.1-1.6-4.5-4.7Z" fill="${color}"/>
  <path d="M15.2 9.5c.6-1 1.6-1.5 2.9-1.4-.4.9-1.2 1.5-2.1 1.8" fill="${color}"/>
</svg>
SVG
}

if ! command -v docker >/dev/null 2>&1; then
  echo "| image=$(docker_icon "#8b949e")"
  echo "---"
  echo "Docker"
  echo "--Missing dependency: docker | disabled=true"
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "| image=$(docker_icon "#f85149")"
  echo "---"
  echo "Docker"
  echo "--Daemon is not reachable | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

containers="$(docker ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null || true)"

if [[ -z "${containers}" ]]; then
  echo "| image=$(docker_icon "#8b949e")"
  echo "---"
  echo "Docker"
  echo "--No containers found | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

summary="$(
  printf '%s\n' "${containers}" | awk -F '\t' '
    BEGIN {
      running = stopped = unhealthy = restarting = paused = dead = exited_error = problems = 0
    }
    {
      name = $1
      status = $2

      if (status ~ /^Up /) {
        running++
      } else {
        stopped++
      }

      if (status ~ /\(unhealthy\)/) {
        unhealthy++
        problem[++problems] = name ": unhealthy"
      } else if (status ~ /^Restarting/) {
        restarting++
        problem[++problems] = name ": restarting"
      } else if (status ~ /^Paused/) {
        paused++
        problem[++problems] = name ": paused"
      } else if (status ~ /^Dead/) {
        dead++
        problem[++problems] = name ": dead"
      } else if (status ~ /^Exited \(([1-9][0-9]*|[0-9]{2,})\)/) {
        exited_error++
        problem[++problems] = name ": " status
      }
    }
    END {
      print running
      print stopped
      print unhealthy
      print restarting
      print paused
      print dead
      print exited_error
      print problems
      for (i = 1; i <= problems && i <= 5; i++) {
        print problem[i]
      }
    }
  '
)"

running="$(printf '%s\n' "${summary}" | sed -n '1p')"
stopped="$(printf '%s\n' "${summary}" | sed -n '2p')"
unhealthy="$(printf '%s\n' "${summary}" | sed -n '3p')"
restarting="$(printf '%s\n' "${summary}" | sed -n '4p')"
paused="$(printf '%s\n' "${summary}" | sed -n '5p')"
dead="$(printf '%s\n' "${summary}" | sed -n '6p')"
exited_error="$(printf '%s\n' "${summary}" | sed -n '7p')"
problems="$(printf '%s\n' "${summary}" | sed -n '8p')"

color="#58a6ff"
status="ok"
if (( unhealthy > 0 || restarting > 0 || dead > 0 || exited_error > 0 )); then
  color="#f85149"
  status="critical"
elif (( paused > 0 )); then
  color="#f59e0b"
  status="warning"
fi

echo "| image=$(docker_icon "${color}")"
echo "---"
echo "Docker"
echo "--Status: ${status} | disabled=true"
echo "--Running: ${running} | disabled=true"
echo "--Stopped: ${stopped} | disabled=true"
echo "--Unhealthy: ${unhealthy} | disabled=true"
echo "--Restarting: ${restarting} | disabled=true"
echo "--Paused: ${paused} | disabled=true"
if (( problems > 0 )); then
  echo "---"
  printf '%s\n' "${summary}" | sed -n '9,13p' | while IFS= read -r problem; do
    echo "--${problem} | disabled=true"
  done
fi
echo "Open container list | bash=/bin/bash param1=-lc param2='docker ps -a --format \"table {{.Names}}\\t{{.Status}}\\t{{.Image}}\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "Refresh | refresh=true"
