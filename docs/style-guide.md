# Plugin Style Guide

## Goals

Plugins should be easy to audit, copy, modify, and remove. Prefer boring shell over clever shell.

## Output

- Keep panel titles short.
- Put detailed actions below `---`.
- Use clear action labels.
- Include a refresh action when the plugin reports changing state.
- Prefer actionable error text over silent failure.

## Dependencies

- Prefer standard Linux command-line tools.
- Check optional dependencies with `command -v`.
- Degrade gracefully when a dependency is missing.
- Mention dependencies in the plugin header.

## Environment Variables

- Store user-specific plugin settings in `~/.config/cbar/env`.
- Prefix cbar-specific settings with `CBAR_`.
- Provide useful defaults for optional settings.
- Add an `Edit cbar env` menu item to plugins that declare `# env:` variables so users can open the central env file from the popup.
- Prefer `cosmic-edit` for the edit action and fall back to `xdg-open` when needed.
- Never echo secret values into popup output.

## Actions

- Use `href=...` for web pages.
- Use `bash=/bin/bash param1=-lc param2='...'` for shell actions that need shell syntax.
- Add `terminal=true` only for commands that need an interactive terminal.
- Add `refresh=true` after actions that change plugin state.
