#!/usr/bin/env bash
# cbar: Starter template for inline SVG images in the panel and popup.
# deps: base64, tr
# env: CBAR_TEMPLATE_VALUE

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

value="${CBAR_TEMPLATE_VALUE:-64}"
case "${value}" in
  ''|*[!0-9]*)
    value=64
    ;;
esac

if (( value > 100 )); then
  value=100
fi

bar_width=$((value * 24 / 100))
if (( bar_width < 2 )); then
  bar_width=2
fi

# cbar accepts base64-encoded images through the image= parameter.
svg="<svg xmlns='http://www.w3.org/2000/svg' width='24' height='16' viewBox='0 0 24 16'><rect x='1' y='4' width='22' height='8' rx='2' fill='#343434'/><rect x='1' y='4' width='${bar_width}' height='8' rx='2' fill='#62a0ea'/></svg>"
image="$(printf '%s' "${svg}" | base64 | tr -d '\n')"

# An image-only panel row can leave the label blank.
echo " | image=${image}"
echo "---"
echo "Value: ${value}% | image=${image}"
echo "Set CBAR_TEMPLATE_VALUE in ~/.config/cbar/env to change the gauge"
echo "Refresh | refresh=true"
edit_cbar_env_item
