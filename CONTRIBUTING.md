# Contributing

Thanks for helping grow the cbar plugin collection.

## Plugin Requirements

- Keep plugins small, readable, and useful on their own.
- Use `#!/usr/bin/env bash` for Bash plugins.
- Use `set -u` and explicit error handling when possible.
- Do not hardcode secrets, tokens, private hosts, or personal paths.
- Read credentials from environment variables.
- Prefer common tools available on Linux desktops.
- Document non-standard dependencies in the plugin header.
- Use filename intervals such as `cpu.5s.sh`, `calendar.5m.sh`, or `backup.1h.sh`.
- Make scripts executable before submitting.

## Header Format

Each plugin should start with a short metadata block:

```bash
# cbar: Shows current memory usage.
# deps: awk, free
# env: none
```

Use `env: VARIABLE_NAME` when a plugin supports optional or required environment variables.

## Safety

Plugins run as the current user. Shell actions should be explicit, predictable, and easy to inspect. Destructive actions must include clear labels and should avoid surprising defaults.

## Validation

Before submitting, run:

```bash
bash -n plugins/category/name.interval.sh
./plugins/category/name.interval.sh
```

If `shellcheck` is available, run it as well:

```bash
shellcheck plugins/category/name.interval.sh
```
