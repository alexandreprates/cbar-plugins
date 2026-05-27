#!/usr/bin/env bash
# cbar: Shows VPN connection status with interface and copy actions.
# deps: awk, base64, cat, ip, nmcli, tr, wl-copy, xclip
# env: CBAR_VPN_INTERFACE

set -u

configured_iface="${CBAR_VPN_INTERFACE:-}"

shield_icon() {
  local color="$1"
  local connected="$2"
  local badge=""
  local mark="<path d=\"7 7 13 13M13 7 7 13\" fill=\"none\" stroke=\"${color}\" stroke-width=\"1.5\" stroke-linecap=\"round\"/>"

  if [[ "${connected}" = "true" ]]; then
    badge="<circle cx=\"14.8\" cy=\"14.8\" r=\"3\" fill=\"#2ea043\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
    mark="<path d=\"M7.2 9.8 9.1 11.7 13 7.7\" fill=\"none\" stroke=\"${color}\" stroke-width=\"1.6\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
  fi

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M10 2.7 15.5 4.8v4.3c0 3.8-2.1 6.4-5.5 8.1-3.4-1.7-5.5-4.3-5.5-8.1V4.8L10 2.7Z" fill="none" stroke="${color}" stroke-width="1.7" stroke-linejoin="round"/>
  ${mark}
  ${badge}
</svg>
SVG
}

copy_command() {
  local value="$1"
  printf "if command -v wl-copy >/dev/null 2>&1; then printf %%s \"%s\" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %%s \"%s\" | xclip -selection clipboard; else printf %%s \"%s\"; fi" "${value}" "${value}" "${value}"
}

active_nm_vpn() {
  command -v nmcli >/dev/null 2>&1 || return 0
  nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null |
    awk -F: '$2 == "vpn" { print $1 "|" $3; exit }'
}

first_vpn_interface() {
  if [[ -n "${configured_iface}" && -d "/sys/class/net/${configured_iface}" ]]; then
    printf '%s\n' "${configured_iface}"
    return
  fi

  for pattern in wg tun tap ppp; do
    for path in /sys/class/net/"${pattern}"*; do
      [[ -d "${path}" ]] || continue
      printf '%s\n' "${path##*/}"
      return
    done
  done
}

interface_state() {
  local iface="$1"
  cat "/sys/class/net/${iface}/operstate" 2>/dev/null || echo "unknown"
}

interface_ip() {
  local iface="$1"
  command -v ip >/dev/null 2>&1 || return 0
  ip -4 addr show dev "${iface}" scope global 2>/dev/null |
    awk '/inet / { split($2, parts, "/"); print parts[1]; exit }'
}

interface_ipv6() {
  local iface="$1"
  command -v ip >/dev/null 2>&1 || return 0
  ip -6 addr show dev "${iface}" scope global 2>/dev/null |
    awk '/inet6 / { split($2, parts, "/"); print parts[1]; exit }'
}

vpn_name=""
vpn_iface=""
vpn_source="interface"

nm_vpn="$(active_nm_vpn)"
if [[ -n "${nm_vpn}" ]]; then
  vpn_name="${nm_vpn%%|*}"
  vpn_iface="${nm_vpn#*|}"
  vpn_source="NetworkManager"
fi

if [[ -z "${vpn_iface}" || "${vpn_iface}" = "--" ]]; then
  vpn_iface="$(first_vpn_interface)"
fi

connected=false
color="#8b949e"
status="disconnected"
vpn_ip=""
vpn_ipv6=""
operstate=""

if [[ -n "${vpn_iface}" && -d "/sys/class/net/${vpn_iface}" ]]; then
  operstate="$(interface_state "${vpn_iface}")"
  vpn_ip="$(interface_ip "${vpn_iface}")"
  vpn_ipv6="$(interface_ipv6 "${vpn_iface}")"
  connected=true
  color="#58a6ff"
  status="connected"
fi

echo "| image=$(shield_icon "${color}" "${connected}")"
echo "---"
echo "VPN"

if [[ "${connected}" = "true" ]]; then
  echo "--Status: ${status} | disabled=true"
  if [[ -n "${vpn_name}" ]]; then
    echo "--Connection: ${vpn_name} | disabled=true"
  fi
  echo "--Interface: ${vpn_iface} | disabled=true"
  echo "--Interface state: ${operstate:-unknown} | disabled=true"
  echo "--Source: ${vpn_source} | disabled=true"
  if [[ -n "${vpn_ip}" ]]; then
    echo "--IPv4: ${vpn_ip} | disabled=true"
  else
    echo "--IPv4: unavailable | disabled=true"
  fi
  if [[ -n "${vpn_ipv6}" ]]; then
    echo "--IPv6: ${vpn_ipv6} | disabled=true"
  fi
  echo "---"
  if [[ -n "${vpn_ip}" ]]; then
    echo "Copy VPN IPv4 | bash=/bin/bash param1=-lc param2='$(copy_command "${vpn_ip}")'"
  else
    echo "Copy VPN IPv4 | disabled=true"
  fi
  if [[ -n "${vpn_ipv6}" ]]; then
    echo "Copy VPN IPv6 | bash=/bin/bash param1=-lc param2='$(copy_command "${vpn_ipv6}")'"
  fi
else
  echo "--Status: disconnected | disabled=true"
  echo "--Watched interfaces: wg*, tun*, tap*, ppp* | disabled=true"
  echo "--Set CBAR_VPN_INTERFACE to force one | disabled=true"
fi

echo "Refresh | refresh=true"
