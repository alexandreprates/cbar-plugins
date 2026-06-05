#!/usr/bin/env bash
# cbar: Starter template for a short panel status and a simple popup.
# deps: date
# env: CBAR_TEMPLATE_LABEL

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

label="${CBAR_TEMPLATE_LABEL:-Template}"
updated_at="$(date '+%H:%M:%S')"

# The first visible line becomes the text shown in the COSMIC panel.
echo "${label}: OK"

# A line containing only "---" starts the popup menu.
echo "---"
echo "Status: ready"
echo "Updated: ${updated_at}"

# refresh=true asks cbar to run the plugin again after the row is activated.
echo "Refresh | refresh=true"
edit_cbar_env_item
