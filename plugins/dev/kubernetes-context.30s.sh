#!/usr/bin/env bash
# cbar: Shows current Kubernetes context and namespace with production alerts.
# deps: base64, kubectl, python3, tr, wl-copy, xclip
# env: CBAR_KUBE_PROD_PATTERN

set -u

prod_pattern="${CBAR_KUBE_PROD_PATTERN:-prod|production|prd|live}"

kube_icon() {
  local color="$1"
  local severity="${2:-ok}"
  local badge=""

  case "${severity}" in
    critical)
      badge="<circle cx=\"15.2\" cy=\"15.2\" r=\"3.2\" fill=\"#f85149\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
    warning)
      badge="<circle cx=\"15.2\" cy=\"15.2\" r=\"3.2\" fill=\"#f59e0b\" stroke=\"#0d1117\" stroke-width=\"1\"/>"
      ;;
  esac

  cat <<SVG | base64 | tr -d '\n'
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">
  <path d="M10 2.4 16.6 6.2v7.6L10 17.6l-6.6-3.8V6.2L10 2.4Z" fill="none" stroke="${color}" stroke-width="1.45" stroke-linejoin="round"/>
  <circle cx="10" cy="10" r="2.1" fill="none" stroke="${color}" stroke-width="1.25"/>
  <path d="M10 4.9v2.7M10 12.4v2.7M5.6 7.4 8 8.7M12 11.3l2.4 1.3M14.4 7.4 12 8.7M8 11.3l-2.4 1.3" fill="none" stroke="${color}" stroke-width="1.15" stroke-linecap="round"/>
  ${badge}
</svg>
SVG
}

copy_command() {
  local value="$1"
  printf "if command -v wl-copy >/dev/null 2>&1; then printf %%s \"%s\" | wl-copy; elif command -v xclip >/dev/null 2>&1; then printf %%s \"%s\" | xclip -selection clipboard; else printf %%s \"%s\"; fi" "${value}" "${value}" "${value}"
}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "| image=$(kube_icon "#8b949e" "warning")"
  echo "---"
  echo "Kubernetes"
  echo "--Missing dependency: kubectl | disabled=true"
  exit 0
fi

config_json="$(kubectl config view --raw -o json 2>/dev/null || true)"

if [[ -z "${config_json}" ]]; then
  echo "| image=$(kube_icon "#8b949e" "warning")"
  echo "---"
  echo "Kubernetes"
  echo "--No readable kubeconfig | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

parsed="$(
  KUBE_CONFIG_JSON="${config_json}" python3 - "${prod_pattern}" <<'PY'
import json
import os
import re
import sys

pattern = sys.argv[1] or r"prod|production|prd|live"
try:
    config = json.loads(os.environ.get("KUBE_CONFIG_JSON", ""))
except Exception:
    sys.exit(1)

current = config.get("current-context") or ""
contexts = {item.get("name", ""): item.get("context", {}) for item in config.get("contexts", [])}
clusters = {item.get("name", ""): item.get("cluster", {}) for item in config.get("clusters", [])}
users = {item.get("name", ""): item.get("user", {}) for item in config.get("users", [])}

context = contexts.get(current, {})
cluster_name = context.get("cluster", "")
user_name = context.get("user", "")
namespace = context.get("namespace") or "default"
cluster = clusters.get(cluster_name, {})
server = cluster.get("server", "")
user = users.get(user_name, {})

haystack = " ".join([current, cluster_name, namespace, server])
try:
    prod = bool(re.search(pattern, haystack, re.IGNORECASE))
except re.error:
    prod = bool(re.search(r"prod|production|prd|live", haystack, re.IGNORECASE))

auth_hint = "configured" if user else "unknown"

def out(value):
    print(str(value or ""))

out(current)
out(namespace)
out(cluster_name)
out(user_name)
out(server)
out("yes" if prod else "no")
out(auth_hint)
PY
)"

if [[ -z "${parsed}" ]]; then
  echo "| image=$(kube_icon "#f59e0b" "warning")"
  echo "---"
  echo "Kubernetes"
  echo "--Unable to parse kubeconfig | disabled=true"
  echo "Refresh | refresh=true"
  exit 0
fi

context_name="$(printf '%s\n' "${parsed}" | sed -n '1p')"
namespace="$(printf '%s\n' "${parsed}" | sed -n '2p')"
cluster_name="$(printf '%s\n' "${parsed}" | sed -n '3p')"
user_name="$(printf '%s\n' "${parsed}" | sed -n '4p')"
server="$(printf '%s\n' "${parsed}" | sed -n '5p')"
is_prod="$(printf '%s\n' "${parsed}" | sed -n '6p')"
auth_hint="$(printf '%s\n' "${parsed}" | sed -n '7p')"

severity="ok"
color="#58a6ff"
if [[ -z "${context_name}" ]]; then
  severity="warning"
  color="#8b949e"
elif [[ "${is_prod}" = "yes" ]]; then
  severity="critical"
  color="#f85149"
fi

echo "| image=$(kube_icon "${color}" "${severity}")"
echo "---"
echo "Kubernetes"
if [[ -z "${context_name}" ]]; then
  echo "--No current context | disabled=true"
else
  echo "--Context: ${context_name} | disabled=true"
  echo "--Namespace: ${namespace:-default} | disabled=true"
  echo "--Cluster: ${cluster_name:-unknown} | disabled=true"
  echo "--User: ${user_name:-unknown} | disabled=true"
  echo "--Server: ${server:-unknown} | disabled=true"
  echo "--Auth: ${auth_hint} | disabled=true"
  if [[ "${is_prod}" = "yes" ]]; then
    echo "--Production-like context detected | color=#f85149"
  fi
fi

echo "---"
if [[ -n "${context_name}" ]]; then
  echo "Copy context | bash=/bin/bash param1=-lc param2='$(copy_command "${context_name}")'"
  echo "Copy namespace | bash=/bin/bash param1=-lc param2='$(copy_command "${namespace:-default}")'"
  echo "Show pods | bash=/bin/bash param1=-lc param2='kubectl get pods -n \"${namespace:-default}\"; printf \"\\n\"; read -r -p \"Press enter to close...\"' terminal=true"
else
  echo "Copy context | disabled=true"
  echo "Copy namespace | disabled=true"
fi
echo "Refresh | refresh=true"
