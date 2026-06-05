#!/usr/bin/env bash
# cbar: Shows live, upcoming, and recent sports scores for a configurable ESPN league.
# deps: base64, python3, tr
# env: CBAR_SPORT_PATH, CBAR_SPORT_TEAM, CBAR_SPORT_LIMIT, CBAR_SPORT_TIMEOUT

set -u

edit_cbar_env_item() {
  echo "Edit cbar env | bash=/bin/bash param1=-lc param2='mkdir -p \"\$HOME/.config/cbar\" && touch \"\$HOME/.config/cbar/env\" && if command -v cosmic-edit >/dev/null 2>&1; then cosmic-edit \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & elif command -v xdg-open >/dev/null 2>&1; then xdg-open \"\$HOME/.config/cbar/env\" >/dev/null 2>&1 & fi'"
}

sports_icon() {
  local color="$1"
  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <circle cx="10" cy="10" r="7.1" fill="none" stroke="${color}" stroke-width="1.5"/>
  <path d="M10 6.7 12.9 8.8 11.8 12.2H8.2L7.1 8.8 10 6.7Z" fill="none" stroke="${color}" stroke-width="1.15" stroke-linejoin="round"/>
  <path d="m10 2.9v3.8M4.1 7.1l3 1.7M5.9 15.6l2.3-3.4M14.1 15.6l-2.3-3.4M15.9 7.1l-3 1.7M4.1 12.9l-1-2.9 1-2.9M15.9 12.9l1-2.9-1-2.9" fill="none" stroke="${color}" stroke-width="1.05" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
SVG
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "| image=$(sports_icon "#8b949e")"
  echo "---"
  echo "Missing dependency: python3 | disabled=true"
  echo "---"
  edit_cbar_env_item
  exit 0
fi

sport_path="${CBAR_SPORT_PATH:-soccer/bra.1}"
team="${CBAR_SPORT_TEAM:-}"
limit="${CBAR_SPORT_LIMIT:-8}"
timeout="${CBAR_SPORT_TIMEOUT:-6}"

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

SPORTS_ICON_LIVE="$(sports_icon "#2ea043")"
SPORTS_ICON_IDLE="$(sports_icon "#58a6ff")"
SPORTS_ICON_ERROR="$(sports_icon "#f85149")"

CBAR_SPORTS_ICON_LIVE="${SPORTS_ICON_LIVE}" CBAR_SPORTS_ICON_IDLE="${SPORTS_ICON_IDLE}" CBAR_SPORTS_ICON_ERROR="${SPORTS_ICON_ERROR}" python3 - "${sport_path}" "${team}" "${limit}" "${timeout}" <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime

sport_path = sys.argv[1]
team_filter = sys.argv[2].strip().lower()
limit = int(sys.argv[3])
timeout = int(sys.argv[4])
icon_live = os.environ["CBAR_SPORTS_ICON_LIVE"]
icon_idle = os.environ["CBAR_SPORTS_ICON_IDLE"]
icon_error = os.environ["CBAR_SPORTS_ICON_ERROR"]


def clean_path(value: str) -> str:
    value = value.strip().lower().strip("/")
    value = re.sub(r"[^a-z0-9./_-]", "", value)
    if "/" not in value:
        return "soccer/bra.1"
    return value


def clean_label(value: str) -> str:
    value = str(value or "").strip().replace("|", "-")
    return re.sub(r"\s+", " ", value)[:120] or "Sports"


def parse_epoch(value: str) -> float:
    if not value:
        return 0.0
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return 0.0


def local_time(epoch: float) -> str:
    if epoch <= 0:
        return "?"
    return time.strftime("%a %H:%M", time.localtime(epoch))


def competitor_labels(competitors: list[dict]) -> tuple[str, str, str, str]:
    home = away = ""
    home_score = away_score = ""
    for competitor in competitors:
        team = competitor.get("team") or {}
        label = team.get("abbreviation") or team.get("shortDisplayName") or team.get("displayName") or "?"
        score = str(competitor.get("score") or "0")
        if competitor.get("homeAway") == "home":
            home = clean_label(label)
            home_score = score
        else:
            away = clean_label(label)
            away_score = score
    return home, home_score, away, away_score


def team_matches(event: dict, text: str) -> bool:
    if not text:
        return True
    for competition in event.get("competitions") or []:
        for competitor in competition.get("competitors") or []:
            team = competitor.get("team") or {}
            fields = [
                team.get("abbreviation"),
                team.get("shortDisplayName"),
                team.get("displayName"),
                team.get("name"),
            ]
            if any(text in str(field or "").lower() for field in fields):
                return True
    return False


def event_summary(event: dict) -> dict[str, object]:
    competition = (event.get("competitions") or [{}])[0]
    status = competition.get("status") or event.get("status") or {}
    status_type = status.get("type") or {}
    state = status_type.get("state") or "pre"
    detail = status_type.get("shortDetail") or status_type.get("detail") or status_type.get("description") or ""
    home, home_score, away, away_score = competitor_labels(competition.get("competitors") or [])
    epoch = parse_epoch(event.get("date") or competition.get("date") or competition.get("startDate") or "")
    href = ""
    for link in event.get("links") or []:
        if link.get("href"):
            href = str(link["href"])
            break
    if state == "pre":
        panel = f"{away} @ {home} {local_time(epoch)}"
        row = f"{away} @ {home} - {local_time(epoch)}"
    else:
        panel = f"{away} {away_score} - {home_score} {home}"
        row = f"{away} {away_score} - {home_score} {home}"
        if detail:
            row = f"{row} ({clean_label(detail)})"
    return {
        "state": state,
        "epoch": epoch,
        "panel": clean_label(panel),
        "row": clean_label(row),
        "href": href,
        "detail": clean_label(detail),
    }


path = clean_path(sport_path)
url = f"https://site.api.espn.com/apis/site/v2/sports/{urllib.parse.quote(path, safe='/._-')}/scoreboard"
events = []
errors = []
league_name = path

try:
    request = urllib.request.Request(url, headers={"User-Agent": "cbar-sports-live/1.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read(1024 * 1024))
    leagues = payload.get("leagues") or []
    if leagues:
        league_name = clean_label(leagues[0].get("name") or leagues[0].get("abbreviation") or path)
    for event in payload.get("events") or []:
        if team_matches(event, team_filter):
            events.append(event_summary(event))
except (json.JSONDecodeError, OSError, urllib.error.URLError) as exc:
    errors.append(f"Provider: {exc}")

events = events[:limit]
live_events = [event for event in events if event["state"] == "in"]
pre_events = [event for event in events if event["state"] == "pre"]
post_events = [event for event in events if event["state"] not in {"in", "pre"}]

if live_events:
    first = live_events[0]
    print(f"| image={icon_live}")
elif pre_events:
    first = sorted(pre_events, key=lambda item: float(item["epoch"]))[0]
    print(f"| image={icon_idle}")
elif post_events:
    first = sorted(post_events, key=lambda item: float(item["epoch"]), reverse=True)[0]
    print(f"| image={icon_idle}")
else:
    first = None
    print(f"| image={icon_error}")

print("---")
print("Sports Live")
print(f"--League: {league_name} | disabled=true")
if team_filter:
    print(f"--Team filter: {team_filter} | disabled=true")
print(f"--Events: {len(events)} | disabled=true")
if first:
    print(f"--Featured event: {first['panel']} | disabled=true")

def print_group(title: str, rows: list[dict[str, object]]) -> None:
    if not rows:
        return
    print("---")
    print(title)
    for event in rows:
        label = str(event["row"])
        href = str(event.get("href") or "")
        if href:
            print(f"{label} | href={href}")
        else:
            print(f"{label} | disabled=true")

print_group("Live", live_events)
print_group("Upcoming", sorted(pre_events, key=lambda item: float(item["epoch"])))
print_group("Recent", sorted(post_events, key=lambda item: float(item["epoch"]), reverse=True))

if errors:
    print("---")
    print("Score errors")
    for error in errors[:5]:
        print(f"--{clean_label(error)} | disabled=true")

print("---")
print("Provider: ESPN scoreboard | href=https://www.espn.com/")
print("Refresh | refresh=true")
PY

echo "---"
edit_cbar_env_item
