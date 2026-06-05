#!/usr/bin/env bash
# cbar: Shows recent RSS news headlines from configurable feeds.
# deps: base64, python3, tr
# env: CBAR_NEWS_FEEDS, CBAR_NEWS_LIMIT, CBAR_NEWS_TIMEOUT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

news_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M4 5.2h9.7c1.3 0 2.3 1 2.3 2.3v6.2c0 .9-.7 1.6-1.6 1.6H5.6c-.9 0-1.6-.7-1.6-1.6V5.2Z" fill="none" stroke="${color}" stroke-width="1.4" stroke-linejoin="round"/>
  <path d="M13.7 5.4v8.1c0 1 .8 1.8 1.8 1.8M6.4 8h4.8M6.4 10.4h4.8M6.4 12.8h3.2" fill="none" stroke="${color}" stroke-width="1.25" stroke-linecap="round"/>
</svg>
SVG
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "| image=$(news_icon "#8b949e")"
  echo "---"
  echo "Missing dependency: python3 | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

feeds="${CBAR_NEWS_FEEDS:-Top=https://g1.globo.com/rss/g1/;Economy=https://g1.globo.com/rss/g1/economia/;World=https://g1.globo.com/rss/g1/mundo/}"
limit="${CBAR_NEWS_LIMIT:-8}"
timeout="${CBAR_NEWS_TIMEOUT:-6}"

case "${limit}" in
  ''|*[!0-9]*)
    limit=8
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

NEWS_ICON_OK="$(news_icon "#58a6ff")"
NEWS_ICON_ERROR="$(news_icon "#f85149")"

CBAR_NEWS_ICON_OK="${NEWS_ICON_OK}" CBAR_NEWS_ICON_ERROR="${NEWS_ICON_ERROR}" python3 - "${feeds}" "${limit}" "${timeout}" <<'PY'
from __future__ import annotations

import email.utils
import gzip
import html
import os
import re
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from urllib.parse import urlparse

feeds_arg = sys.argv[1]
limit = int(sys.argv[2])
timeout = int(sys.argv[3])
icon_ok = os.environ["CBAR_NEWS_ICON_OK"]
icon_error = os.environ["CBAR_NEWS_ICON_ERROR"]


def clean_label(value: str, fallback: str = "News") -> str:
    value = html.unescape(value or "").strip()
    value = re.sub(r"\s+", " ", value)
    value = value.replace("|", "-")
    return value[:120] or fallback


def clean_url(value: str) -> str:
    value = html.unescape(value or "").strip()
    value = value.replace("|", "")
    parsed = urlparse(value)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return ""
    return value


def parse_date(value: str) -> float:
    if not value:
        return 0.0
    try:
        parsed = email.utils.parsedate_to_datetime(value)
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.timestamp()
    except (TypeError, ValueError):
        return 0.0


def child_text(element: ET.Element, names: tuple[str, ...]) -> str:
    for name in names:
        child = element.find(name)
        if child is not None and child.text:
            return child.text
    for child in element:
        local = child.tag.rsplit("}", 1)[-1]
        if local in names and child.text:
            return child.text
    return ""


def child_link(element: ET.Element) -> str:
    link = child_text(element, ("link",))
    if link:
        return link
    for child in element:
        local = child.tag.rsplit("}", 1)[-1]
        if local == "link":
            href = child.attrib.get("href", "")
            if href:
                return href
    return ""


def parse_feed(label: str, url: str) -> list[dict[str, object]]:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "cbar-news-ticker/1.0",
            "Accept-Encoding": "gzip, identity",
        },
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        content = response.read(1024 * 1024)
        if response.headers.get("Content-Encoding", "").lower() == "gzip" or content.startswith(b"\x1f\x8b"):
            content = gzip.decompress(content)

    root = ET.fromstring(content)
    entries = root.findall(".//item")
    if not entries:
        entries = [
            element
            for element in root.findall(".//{http://www.w3.org/2005/Atom}entry")
        ]

    items = []
    for entry in entries[: limit * 2]:
        title = clean_label(child_text(entry, ("title",)), "Untitled")
        link = clean_url(child_link(entry))
        published = child_text(entry, ("pubDate", "published", "updated"))
        items.append(
            {
                "source": label,
                "title": title,
                "link": link,
                "timestamp": parse_date(published),
            }
        )
    return items


feed_specs = []
for raw_spec in feeds_arg.split(";"):
    raw_spec = raw_spec.strip()
    if not raw_spec:
        continue
    if "=" in raw_spec:
        label, url = raw_spec.split("=", 1)
    else:
        url = raw_spec
        label = urlparse(url).netloc or "News"
    url = clean_url(url)
    if url:
        feed_specs.append((clean_label(label), url))

items: list[dict[str, object]] = []
errors: list[str] = []
for label, url in feed_specs:
    try:
        items.extend(parse_feed(label, url))
    except (ET.ParseError, OSError, urllib.error.URLError, ValueError) as exc:
        errors.append(f"{label}: {exc}")

items.sort(key=lambda item: float(item["timestamp"]), reverse=True)
items = items[:limit]

if items:
    first = items[0]
    print(f"| image={icon_ok}")
else:
    print(f"| image={icon_error}")

print("---")
print("News Ticker")
if feed_specs:
    print(f"--Feeds: {len(feed_specs)} | disabled=true")
print(f"--Headlines: {len(items)} | disabled=true")
if items:
    print(f"--Top headline: {clean_label(str(first['title']))} | disabled=true")

if items:
    print("---")
    for item in items:
        source = clean_label(str(item["source"]))
        title = clean_label(str(item["title"]))
        link = str(item["link"])
        label = f"{source}: {title}"
        if link:
            print(f"{label} | href={link}")
        else:
            print(f"{label} | disabled=true")

if errors:
    print("---")
    print("Feed errors")
    for error in errors[:5]:
        print(f"--{clean_label(error)} | disabled=true")

print("---")
print("Refresh | refresh=true")
PY

echo "---"
edit_cbar_env_item
