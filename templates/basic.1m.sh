#!/usr/bin/env bash
# cbar: Starter template for a short panel status and a simple popup.
# deps: date
# env: CBAR_TEMPLATE_LABEL

set -u

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
