# Contributing

Thanks for helping grow the cbar plugin catalog. This repository is meant to make useful, inspectable desktop scripts easy to share with other cbar users.

Plugins run locally as the current user. Reviewers will prioritize clarity, safety, predictable behavior, and easy removal over clever implementation tricks.

## Contribution Flow

1. Choose the closest category under `plugins/`: `system`, `network`, `dev`, or `productivity`.
2. Copy a template, copy a similar existing plugin, or start a new executable script with a filename interval such as `battery.30s.sh`, `calendar.5m.sh`, or `backup.1h.sh`.
3. Keep the output compatible with cbar. See [docs/plugin-format.md](docs/plugin-format.md) for panel titles, popup rows, actions, separators, and parameters.
4. Add or update the plugin header with the purpose, dependencies, and environment variables.
5. Document non-standard dependencies, supported environment variables, output languages, and publisher metadata in `scripts/build-registry.sh`.
6. Run the validation commands below.
7. Rebuild `registry/plugins.json`.
8. Open a pull request from your fork.

## Plugin Requirements

- Keep plugins small, readable, and useful on their own.
- Use `#!/usr/bin/env bash` for Bash plugins.
- Use `set -u` and explicit error handling when practical.
- Use filename intervals such as `cpu.5s.sh`, `calendar.5m.sh`, or `backup.1h.sh`.
- Make scripts executable before submitting.
- Prefer common tools available on Linux desktops.
- Check optional dependencies with `command -v`.
- Degrade gracefully when an optional dependency is missing.
- Show actionable error text in the cbar menu or panel when practical.
- Avoid hanging indefinitely; use bounded commands, timeouts, or fast failure for network calls.

## Header Format

Each plugin should start with a short metadata block:

```bash
#!/usr/bin/env bash
# cbar: Shows current memory usage.
# deps: awk, free
# env: none
```

Use `env: VARIABLE_NAME` when a plugin supports optional or required environment variables.

## Templates

- `templates/basic.1m.sh` is a minimal panel status plus popup.
- `templates/menu.5m.sh` demonstrates sections, disabled rows, alternate rows, links, shell actions, terminal actions, and refresh-after-action.
- `templates/image.5s.sh` demonstrates inline SVG output for gauges or visual indicators.

Copy a template into the closest `plugins/<category>/` directory and rename it for the intended refresh interval before editing.

## Safety

- Do not hardcode secrets, tokens, private hosts, or personal paths.
- Read credentials and user-specific values from environment variables.
- Never print secret values into panel or popup output.
- Avoid unnecessary remote calls.
- Shell actions should be explicit, predictable, and easy to inspect.
- Destructive actions must have clear labels and conservative defaults.

## Registry Metadata

The catalog in `registry/plugins.json` is generated. Do not edit it by hand.

When adding or changing a plugin, update the matching `add_plugin` entry in `scripts/build-registry.sh`, then rebuild:

```bash
./scripts/build-registry.sh
```

Metadata should include any non-standard dependencies and environment variables so cbar can show users what a plugin expects before installation.

Add new entries under the matching category comment in `scripts/build-registry.sh`, such as `# system`, `# network`, `# dev`, or `# productivity`. Keep the field order used by `add_plugin`:

```text
id, name, category, description, path, interval, language, languages, dependencies, env, license, publisher, publisher_url
```

Use comma-separated values for `languages`, `dependencies`, and `env`, or an empty string when none are needed. Keep generated fields such as `sha256`, `size_bytes`, `download_url`, and `install_name` out of manual metadata; the builder computes them.

Use `language` for the plugin implementation language, such as `bash`. Use `languages` for the human-facing output language tags shown as cbar catalog badges, such as `en`, `pt-BR`, or `en,pt-BR`. Leave `languages` empty only when the plugin output is language-neutral or intentionally unspecified.

Each catalog plugin must also include:

- `publisher`: the GitHub username responsible for publishing the plugin through the fork and pull request flow.
- `publisher_url`: the contributor's GitHub profile URL when available.

Use `publisher`, not `author` or `maintainer`. Later maintenance edits do not automatically change the original publisher unless the change is intentional.

Per-plugin sidecar metadata files may become useful if the catalog grows enough for merge conflicts to hurt, but the current source of truth is still `scripts/build-registry.sh`.

## Validation

Before submitting, run the plugin directly and check Bash syntax:

```bash
bash -n plugins/category/name.interval.sh
./plugins/category/name.interval.sh
```

Rebuild and validate the registry:

```bash
./scripts/build-registry.sh
python3 -m json.tool registry/plugins.json >/dev/null
```

For broader changes, validate every plugin:

```bash
find plugins templates -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

If `shellcheck` is available, run it as an additional review aid:

```bash
shellcheck plugins/category/name.interval.sh
```

Before opening the pull request, confirm the generated registry was committed:

```bash
git diff -- registry/plugins.json
```

## Pull Request Checklist

- The plugin belongs in the chosen category.
- The script is executable.
- The script output follows the cbar plugin format.
- Dependencies and environment variables are documented in the header.
- Dependencies and environment variables are reflected in registry metadata.
- Output languages are reflected in registry metadata when the plugin displays human-facing text.
- Publisher metadata is present and points to the contributor's GitHub identity.
- No secrets, tokens, private hosts, or personal paths are hardcoded.
- Remote calls are necessary for the plugin's purpose and fail predictably.
- Missing dependencies produce useful output or a clear failure.
- The script does not hang indefinitely.
- `registry/plugins.json` was rebuilt and committed.
