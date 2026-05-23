#!/usr/bin/env bash
# cbar: Shows GitHub notification count when gh is authenticated.
# deps: gh
# env: none

set -u

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub ?"
  echo "---"
  echo "Missing dependency: gh | disabled=true"
  echo "Open GitHub notifications | href=https://github.com/notifications"
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub"
  echo "---"
  echo "gh is not authenticated | disabled=true"
  echo "Run gh auth login | bash=gh param1=auth param2=login terminal=true refresh=true"
  echo "Open GitHub notifications | href=https://github.com/notifications"
  exit 0
fi

count="$(gh api notifications --jq 'length' 2>/dev/null || echo "?")"

echo "GitHub ${count}"
echo "---"
echo "Unread notifications: ${count} | disabled=true"
echo "Open GitHub notifications | href=https://github.com/notifications"
echo "Refresh | refresh=true"
