#!/usr/bin/env bash
# cbar: Shows BRL exchange and asset quotes from configurable market pairs.
# deps: base64, python3, tr
# env: CBAR_MARKET_PAIRS, CBAR_MARKET_LIMIT, CBAR_MARKET_TIMEOUT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

market_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M3.5 15.5h13" fill="none" stroke="#8b949e" stroke-width="1.2" stroke-linecap="round"/>
  <path d="M4.4 13.4 7.6 10l2.6 2.1 4.9-5.5" fill="none" stroke="${color}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="4.4" cy="13.4" r="1" fill="${color}"/>
  <circle cx="7.6" cy="10" r="1" fill="${color}"/>
  <circle cx="10.2" cy="12.1" r="1" fill="${color}"/>
  <circle cx="15.1" cy="6.6" r="1" fill="${color}"/>
</svg>
SVG
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "| image=$(market_icon "#8b949e")"
  echo "---"
  echo "Missing dependency: python3 | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

pairs="${CBAR_MARKET_PAIRS:-USD-BRL,EUR-BRL,BTC-BRL,XAU-BRL}"
limit="${CBAR_MARKET_LIMIT:-6}"
timeout="${CBAR_MARKET_TIMEOUT:-6}"

case "${limit}" in
  ''|*[!0-9]*)
    limit=6
    ;;
esac

case "${timeout}" in
  ''|*[!0-9]*)
    timeout=6
    ;;
esac

if (( limit < 1 )); then
  limit=1
elif (( limit > 20 )); then
  limit=20
fi

if (( timeout < 1 )); then
  timeout=1
elif (( timeout > 20 )); then
  timeout=20
fi

MARKET_ICON_UP="$(market_icon "#2ea043")"
MARKET_ICON_DOWN="$(market_icon "#f85149")"
MARKET_ICON_FLAT="$(market_icon "#58a6ff")"

CBAR_MARKET_ICON_UP="${MARKET_ICON_UP}" CBAR_MARKET_ICON_DOWN="${MARKET_ICON_DOWN}" CBAR_MARKET_ICON_FLAT="${MARKET_ICON_FLAT}" python3 - "${pairs}" "${limit}" "${timeout}" <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

pairs_arg = sys.argv[1]
limit = int(sys.argv[2])
timeout = int(sys.argv[3])
icon_up = os.environ["CBAR_MARKET_ICON_UP"]
icon_down = os.environ["CBAR_MARKET_ICON_DOWN"]
icon_flat = os.environ["CBAR_MARKET_ICON_FLAT"]


def clean_pair(value: str) -> str:
    value = value.strip().upper().replace("/", "-").replace("_", "-")
    value = re.sub(r"[^A-Z0-9-]", "", value)
    if "-" not in value and len(value) == 6:
        value = f"{value[:3]}-{value[3:]}"
    return value


def format_number(value: float, code: str) -> str:
    if code in {"BTC", "XAU"} or value >= 1000:
        return f"{value:,.0f}"
    if value < 0.01:
        return f"{value:.6f}"
    return f"{value:.2f}"


def format_change(value: float) -> str:
    sign = "+" if value > 0 else ""
    return f"{sign}{value:.2f}%"


def clean_label(value: str) -> str:
    value = value.strip().replace("|", "-")
    return re.sub(r"\s+", " ", value)[:120] or "Market"


pairs = []
for raw_pair in pairs_arg.replace(";", ",").split(","):
    pair = clean_pair(raw_pair)
    if re.fullmatch(r"[A-Z0-9]{3,5}-[A-Z0-9]{3,5}", pair):
        pairs.append(pair)

pairs = pairs[:limit]
items = []
errors = []

if pairs:
    url = "https://economia.awesomeapi.com.br/json/last/" + urllib.parse.quote(",".join(pairs), safe=",-")
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "cbar-market-pulse/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read(512 * 1024))
        for pair in pairs:
            key = pair.replace("-", "")
            data = payload.get(key)
            if not isinstance(data, dict):
                errors.append(f"{pair}: unavailable")
                continue
            try:
                bid = float(data.get("bid") or 0)
                pct = float(data.get("pctChange") or 0)
            except (TypeError, ValueError):
                errors.append(f"{pair}: invalid quote")
                continue
            code = str(data.get("code") or pair.split("-", 1)[0]).upper()
            codein = str(data.get("codein") or pair.split("-", 1)[1]).upper()
            items.append(
                {
                    "pair": f"{code}/{codein}",
                    "code": code,
                    "codein": codein,
                    "name": clean_label(str(data.get("name") or f"{code}/{codein}")),
                    "bid": bid,
                    "ask": float(data.get("ask") or 0),
                    "high": float(data.get("high") or 0),
                    "low": float(data.get("low") or 0),
                    "pct": pct,
                    "updated": clean_label(str(data.get("create_date") or "")),
                }
            )
    except (json.JSONDecodeError, OSError, urllib.error.URLError) as exc:
        errors.append(f"Provider: {exc}")

first = items[0] if items else None
if first:
    icon = icon_up if float(first["pct"]) > 0 else icon_down if float(first["pct"]) < 0 else icon_flat
    print(f"| image={icon}")
else:
    print(f"| image={icon_down}")

print("---")
print("Market Pulse")
print(f"--Pairs: {len(pairs)} | disabled=true")
print(f"--Quotes: {len(items)} | disabled=true")
if first:
    print(
        f"--Lead quote: {first['pair']} {format_number(float(first['bid']), str(first['code']))} "
        f"({format_change(float(first['pct']))}) | disabled=true"
    )

if items:
    print("---")
    for item in items:
        bid = format_number(float(item["bid"]), str(item["code"]))
        pct = format_change(float(item["pct"]))
        print(f"{item['pair']}: {bid} ({pct}) | disabled=true")
        print(f"--Name: {item['name']} | disabled=true")
        print(f"--High: {format_number(float(item['high']), str(item['code']))} | disabled=true")
        print(f"--Low: {format_number(float(item['low']), str(item['code']))} | disabled=true")
        if item["updated"]:
            print(f"--Updated: {item['updated']} | disabled=true")

if errors:
    print("---")
    print("Quote errors")
    for error in errors[:5]:
        print(f"--{clean_label(error)} | disabled=true")

print("---")
print("Provider: AwesomeAPI Economia | href=https://docs.awesomeapi.com.br/api-de-moedas")
print("Refresh | refresh=true")
PY

echo "---"
edit_cbar_env_item
