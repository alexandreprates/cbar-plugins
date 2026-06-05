#!/usr/bin/env bash
# cbar: Starter template for popup sections, actions, and alternate rows.
# deps: date, printf
# env: CBAR_TEMPLATE_URL

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

url="${CBAR_TEMPLATE_URL:-https://github.com/alexandreprates/cbar-plugins}"
updated_at="$(date '+%H:%M')"

# Keep the panel title short; put details and actions in the popup.
echo "Menu"
echo "---"

# Prefix rows with "--" to render them as indented child rows.
echo "Project"
echo "--Open catalog | href=${url}"

# Use bash=/bin/bash plus param1/param2 when an action needs shell syntax.
echo "--Print timestamp | bash=/bin/bash param1=-lc param2='printf %s\\\\n \"cbar template action\"' refresh=true"
echo "--Open terminal | bash=/bin/bash param1=-lc param2='printf %s\\\\n \"Press enter to close\"; read -r _' terminal=true"
echo "---"
echo "State"
echo "--Updated: ${updated_at}"

# disabled=true and alternate=true are useful for richer menu state.
echo "--Disabled example | disabled=true"
echo "--Alternate action | alternate=true bash=/bin/bash param1=-lc param2='printf %s\\\\n alternate'"
echo "Hidden helper | dropdown=false bash=/bin/bash param1=-lc param2='printf %s\\\\n hidden'"
edit_cbar_env_item
