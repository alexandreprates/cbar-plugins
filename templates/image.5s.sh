#!/usr/bin/env bash
# cbar: Starter template for inline SVG images in the panel and popup.
# deps: base64, tr
# env: CBAR_TEMPLATE_VALUE

set -u

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
echo "Set CBAR_TEMPLATE_VALUE to change the gauge"
echo "Refresh | refresh=true"
