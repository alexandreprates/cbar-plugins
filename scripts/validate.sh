#!/usr/bin/env bash
# Runs the local checks expected before opening a cbar-plugins pull request.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${repo_root}"

printf 'checking shell syntax...\n'
find plugins templates -name '*.sh' -print0 | xargs -0 -n1 bash -n

printf 'rebuilding registry...\n'
./scripts/build-registry.sh

printf 'validating registry JSON...\n'
python3 -m json.tool registry/plugins.json >/dev/null

printf 'checking publisher metadata...\n'
python3 - <<'PY'
import json
from pathlib import Path

registry = json.loads(Path("registry/plugins.json").read_text())
missing = [
    plugin["id"]
    for plugin in registry["plugins"]
    if not plugin.get("publisher")
]
if missing:
    raise SystemExit(f"missing publisher metadata: {', '.join(missing)}")
PY

printf 'checking registry freshness...\n'
git diff --exit-code -- registry/plugins.json

printf 'checking whitespace...\n'
git diff --check

printf 'validation passed\n'
