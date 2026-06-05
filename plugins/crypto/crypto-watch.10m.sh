#!/usr/bin/env bash
# cbar: Shows cryptocurrency prices and 24h movement for configurable coins.
# deps: base64, python3, tr
# env: CBAR_CRYPTO_IDS, CBAR_CRYPTO_VS, CBAR_CRYPTO_LIMIT, CBAR_CRYPTO_TIMEOUT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

crypto_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <circle cx="10" cy="10" r="7.2" fill="none" stroke="${color}" stroke-width="1.5"/>
  <path d="M8.1 5.8v8.4M10.3 5.8v8.4M7 7.1h4.2c1.3 0 2.1.7 2.1 1.7 0 .8-.5 1.3-1.2 1.5.9.2 1.5.8 1.5 1.8 0 1.1-.9 1.8-2.3 1.8H7" fill="none" stroke="${color}" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
SVG
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "| image=$(crypto_icon "#8b949e")"
  echo "---"
  echo "Missing dependency: python3 | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

ids="${CBAR_CRYPTO_IDS:-bitcoin,ethereum,solana,cardano}"
vs="${CBAR_CRYPTO_VS:-brl}"
limit="${CBAR_CRYPTO_LIMIT:-6}"
timeout="${CBAR_CRYPTO_TIMEOUT:-6}"

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

CRYPTO_ICON_UP="$(crypto_icon "#2ea043")"
CRYPTO_ICON_DOWN="$(crypto_icon "#f85149")"
CRYPTO_ICON_FLAT="$(crypto_icon "#58a6ff")"

CBAR_CRYPTO_ICON_UP="${CRYPTO_ICON_UP}" CBAR_CRYPTO_ICON_DOWN="${CRYPTO_ICON_DOWN}" CBAR_CRYPTO_ICON_FLAT="${CRYPTO_ICON_FLAT}" python3 - "${ids}" "${vs}" "${limit}" "${timeout}" <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ids_arg = sys.argv[1]
vs_arg = sys.argv[2]
limit = int(sys.argv[3])
timeout = int(sys.argv[4])
icon_up = os.environ["CBAR_CRYPTO_ICON_UP"]
icon_down = os.environ["CBAR_CRYPTO_ICON_DOWN"]
icon_flat = os.environ["CBAR_CRYPTO_ICON_FLAT"]


def clean_token(value: str) -> str:
    value = value.strip().lower()
    return re.sub(r"[^a-z0-9-]", "", value)


def label_for_id(value: str) -> str:
    aliases = {
        "bitcoin": "BTC",
        "ethereum": "ETH",
        "solana": "SOL",
        "cardano": "ADA",
        "ripple": "XRP",
        "dogecoin": "DOGE",
        "polkadot": "DOT",
    }
    return aliases.get(value, value.replace("-", " ").title())


def format_price(value: float, currency: str) -> str:
    prefix = "R$ " if currency == "brl" else "$" if currency == "usd" else f"{currency.upper()} "
    if value >= 1000:
        return f"{prefix}{value:,.0f}"
    if value >= 1:
        return f"{prefix}{value:,.2f}"
    return f"{prefix}{value:.6f}"


def format_change(value: float) -> str:
    sign = "+" if value > 0 else ""
    return f"{sign}{value:.2f}%"


def format_time(epoch: int) -> str:
    if epoch <= 0:
        return ""
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(epoch))


ids = []
for raw_id in ids_arg.replace(";", ",").split(","):
    coin_id = clean_token(raw_id)
    if coin_id:
        ids.append(coin_id)
ids = ids[:limit]

currency = clean_token(vs_arg) or "brl"
items = []
errors = []

if ids:
    params = urllib.parse.urlencode(
        {
            "ids": ",".join(ids),
            "vs_currencies": currency,
            "include_24hr_change": "true",
            "include_last_updated_at": "true",
        }
    )
    url = f"https://api.coingecko.com/api/v3/simple/price?{params}"
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "cbar-crypto-watch/1.0"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read(512 * 1024))
        for coin_id in ids:
            data = payload.get(coin_id)
            if not isinstance(data, dict):
                errors.append(f"{label_for_id(coin_id)}: unavailable")
                continue
            price = data.get(currency)
            change = data.get(f"{currency}_24h_change")
            updated = data.get("last_updated_at")
            if not isinstance(price, (int, float)):
                errors.append(f"{label_for_id(coin_id)}: invalid price")
                continue
            if not isinstance(change, (int, float)):
                change = 0.0
            if not isinstance(updated, int):
                updated = 0
            items.append(
                {
                    "id": coin_id,
                    "label": label_for_id(coin_id),
                    "price": float(price),
                    "change": float(change),
                    "updated": updated,
                }
            )
    except (json.JSONDecodeError, OSError, urllib.error.URLError) as exc:
        errors.append(f"Provider: {exc}")

first = items[0] if items else None
if first:
    icon = icon_up if first["change"] > 0 else icon_down if first["change"] < 0 else icon_flat
    print(f"| image={icon}")
else:
    print(f"| image={icon_down}")

print("---")
print("Crypto Watch")
print(f"--Currency: {currency.upper()} | disabled=true")
print(f"--Coins: {len(ids)} | disabled=true")
print(f"--Quotes: {len(items)} | disabled=true")
if first:
    print(
        f"--Lead coin: {first['label']} {format_price(first['price'], currency)} "
        f"({format_change(first['change'])}) | disabled=true"
    )

if items:
    print("---")
    for item in items:
        print(
            f"{item['label']}: {format_price(item['price'], currency)} "
            f"({format_change(item['change'])}) | disabled=true"
        )
        updated = format_time(int(item["updated"]))
        if updated:
            print(f"--Updated: {updated} | disabled=true")

if errors:
    print("---")
    print("Quote errors")
    for error in errors[:5]:
        print(f"--{error[:120].replace('|', '-')} | disabled=true")

print("---")
print("Provider: CoinGecko | href=https://www.coingecko.com/")
print("Refresh | refresh=true")
PY

echo "---"
edit_cbar_env_item
