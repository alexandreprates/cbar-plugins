#!/usr/bin/env bash
# cbar: Summarizes Docker container state.
# deps: docker
# env: none

set -u

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker ?"
  echo "---"
  echo "Missing dependency: docker | disabled=true"
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker off"
  echo "---"
  echo "Docker daemon is not reachable | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

running="$(docker ps -q | wc -l | tr -d ' ')"
total="$(docker ps -aq | wc -l | tr -d ' ')"

echo "Docker ${running}/${total}"
echo "---"
echo "Running containers: ${running} | disabled=true"
echo "Total containers: ${total} | disabled=true"
echo "Open container list | bash=/bin/bash param1=-lc param2='docker ps --format \"table {{.Names}}\\t{{.Status}}\\t{{.Image}}\"; read -r -p \"Press enter to close...\"' terminal=true"
echo "Refresh | refresh=true"
