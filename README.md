# cbar plugins

The official community plugin catalog for [cbar](https://github.com/alexandreprates/cbar), the COSMIC panel applet for scriptable desktop workflows.

This repository keeps plugin development separate from the cbar applet itself. The `cbar` repository owns the applet, parser, runtime, and COSMIC integration; `cbar-plugins` owns curated scripts, contribution guidance, and the generated catalog metadata used for browsing and installation.

Community contributions are welcome. Plugins are intentionally small and inspectable: each plugin writes plain text to stdout, using the cbar plugin output format to define panel text, popup entries, links, shell actions, refresh behavior, and terminal actions.

The repository also publishes a machine-readable catalog at [registry/plugins.json](registry/plugins.json). cbar can use this registry to browse, verify, and install plugins directly from the applet settings.

## Plugin Categories

```text
plugins/
  system/        local machine status and maintenance helpers
  network/       connectivity and network diagnostics
  dev/           developer workflow helpers
  productivity/  lightweight desktop utilities
templates/       starter scripts for new plugin contributions
```

## Included Plugins

- `plugins/system/cpu-chart.5s.sh` shows compact CPU usage history.
- `plugins/system/memory-gauge.5s.sh` shows compact memory usage.
- `plugins/system/disk.30s.sh` shows compact filesystem usage.
- `plugins/network/public-ip.5m.sh` shows public and local IP status with copy actions.
- `plugins/network/ping.10s.sh` checks connectivity to a configurable host.
- `plugins/dev/docker-containers.10s.sh` summarizes Docker container state.
- `plugins/dev/github-notifications.1m.sh` opens GitHub notifications and optionally shows a count when `gh` is authenticated.
- `plugins/dev/openai_codex.5m.sh` displays OpenAI Codex usage limits from local Codex session metadata.
- `plugins/productivity/timer.1s.sh` shows a simple countdown backed by per-user runtime state.
- `plugins/productivity/calendar.5m.sh` shows today's date and a quick calendar action.

## Plugin Templates

- `templates/basic.1m.sh` starts with a short panel status and a simple popup.
- `templates/menu.5m.sh` demonstrates sections, disabled rows, alternate rows, links, shell actions, terminal actions, and refresh-after-action.
- `templates/image.5s.sh` demonstrates a compact inline SVG image suitable for gauges or visual indicators.

## Contribute A Plugin

The shortest path for a new plugin contribution is:

```bash
cp templates/basic.1m.sh plugins/system/my-plugin.1m.sh
chmod +x plugins/system/my-plugin.1m.sh
$EDITOR plugins/system/my-plugin.1m.sh
bash -n plugins/system/my-plugin.1m.sh
./plugins/system/my-plugin.1m.sh
./scripts/build-registry.sh
python3 -m json.tool registry/plugins.json >/dev/null
```

Then open a pull request from your fork. See [CONTRIBUTING.md](CONTRIBUTING.md), [docs/plugin-format.md](docs/plugin-format.md), and [docs/style-guide.md](docs/style-guide.md) before submitting.

## Good First Plugin Ideas

- Battery status and time remaining.
- VPN connection status.
- Uptime and session duration.
- Docker Compose project status.
- GitHub pull request or issue shortcuts.
- Clipboard history helper.
- Audio input/output device switcher.
- Weather summary from a configurable provider.
- Pomodoro or focus timer.
- Package update counter.

## Installing A Plugin

Copy a plugin into your cbar plugin directory and make it executable:

```bash
mkdir -p ~/.config/cbar/plugins
cp plugins/system/memory-gauge.5s.sh ~/.config/cbar/plugins/
chmod +x ~/.config/cbar/plugins/memory-gauge.5s.sh
```

Restart cbar or trigger a refresh after adding new files. Current cbar releases discover plugins at startup.

## Plugin Format

See [docs/plugin-format.md](docs/plugin-format.md) for the supported output format and [docs/style-guide.md](docs/style-guide.md) for contribution conventions.

## Rebuilding The Registry

After changing plugin files or metadata, rebuild the catalog:

```bash
./scripts/build-registry.sh
```

The registry includes plugin metadata, output language badges, download URLs, file sizes, and SHA-256 checksums used by cbar before installing a plugin.

## Inspiration

The text output format is inspired by xbar-style menu plugins, while these scripts target cbar behavior and COSMIC interaction patterns.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
