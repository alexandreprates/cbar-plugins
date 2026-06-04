# cbar plugins

Curated plugin catalog for [cbar](https://github.com/alexandreprates/cbar), the COSMIC panel applet for scriptable desktop workflows.

This repository contains ready-to-install plugins and the generated catalog metadata used by cbar to browse, verify, and install them. The main `cbar` repository owns the applet, parser, runtime, and COSMIC integration; this repository focuses on useful, inspectable scripts for real panel workflows.

Plugins in this catalog are designed for the COSMIC panel: compact visual indicators in the panel, with details and actions in the popup menu. The goal is useful status at a glance, not demos or large text widgets competing for panel space.

The machine-readable catalog is published at [registry/plugins.json](registry/plugins.json).

## Catalog Layout

```text
plugins/
  system/        local machine status and maintenance helpers
  network/       connectivity and network diagnostics
  dev/           developer workflow helpers
  productivity/  lightweight desktop utilities
templates/       starter scripts for new plugin contributions
```

## Included Plugins

System:

- `plugins/system/cpu-chart.5s.sh` shows CPU usage history as a mini chart.
- `plugins/system/memory-gauge.5s.sh` shows RAM usage as a compact gauge.
- `plugins/system/disk.30s.sh` shows filesystem usage as segmented blocks.
- `plugins/system/service-status.30s.sh` shows systemd service health.
- `plugins/system/updates-available.30m.sh` shows APT and Flatpak updates with a badge.

Network:

- `plugins/network/public-ip.5m.sh` shows public and local IP status with copy actions.
- `plugins/network/network-throughput.2s.sh` shows upload and download throughput.
- `plugins/network/vpn-status.10s.sh` shows VPN connection status and VPN IP details.
- `plugins/network/ssh-hosts.30s.sh` shows configured SSH host reachability.
- `plugins/network/ping.10s.sh` shows latency to a configurable host.

Developer:

- `plugins/dev/docker-health.10s.sh` shows Docker daemon and container health.
- `plugins/dev/github-notifications.1m.sh` shows GitHub notifications with an unread badge.
- `plugins/dev/kubernetes-context.30s.sh` shows Kubernetes context and namespace status.
- `plugins/dev/openai_codex.5m.sh` shows OpenAI Codex usage limits from local session metadata.

Productivity:

- `plugins/productivity/keep-awake.1m.sh` keeps the current desktop session awake with a toggleable inhibitor.
- `plugins/productivity/timer.1s.sh` shows an animated hourglass countdown timer.

## Installing A Plugin

Install from cbar's catalog browser when available, or copy a script into your local cbar plugin directory:

```bash
mkdir -p ~/.config/cbar/plugins
cp plugins/system/memory-gauge.5s.sh ~/.config/cbar/plugins/
chmod +x ~/.config/cbar/plugins/memory-gauge.5s.sh
```

Restart cbar or trigger a refresh after adding new files. Current cbar releases discover plugins at startup.

## Plugin Design

Catalog plugins should be small, readable shell scripts with a narrow purpose. Prefer compact icons, gauges, badges, and mini charts in the panel; put labels, values, diagnostics, links, and shell actions in the popup menu.

Avoid duplicating features COSMIC already provides well by default, such as built-in date, audio, brightness, weather, and battery indicators. New plugins should add useful workflow-specific status or actions.

## Plugin Templates

- `templates/basic.1m.sh` starts with a short panel status and a simple popup.
- `templates/menu.5m.sh` demonstrates sections, disabled rows, alternate rows, links, shell actions, terminal actions, and refresh-after-action.
- `templates/image.5s.sh` demonstrates a compact inline SVG image suitable for gauges or visual indicators.

## Contributing

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

- Uptime and session duration.
- Docker Compose project status.
- GitHub pull request or issue shortcuts.
- Git dirty watcher.
- CI/build status.
- Backup status.
- Certificate expiry monitor.

## Plugin Format

Each plugin writes plain text to stdout using the cbar plugin output format: panel content, popup entries, links, shell actions, refresh behavior, and terminal actions. See [docs/plugin-format.md](docs/plugin-format.md) and [docs/style-guide.md](docs/style-guide.md).

## Rebuilding The Registry

After changing plugin files or metadata, rebuild the catalog:

```bash
./scripts/build-registry.sh
```

The registry includes plugin metadata, plugin versions, output language badges, download URLs, file sizes, and SHA-256 checksums used by cbar before installing or updating a plugin.

Each plugin has its own `plugin_version` using Semantic Versioning:

- bump `PATCH` for bug fixes and small internal corrections
- bump `MINOR` for backward-compatible behavior, output, or configuration additions
- bump `MAJOR` when a plugin change may break existing user expectations, environment configuration, or local workflows

## Inspiration

The text output format is inspired by xbar-style menu plugins, while these scripts target cbar behavior and COSMIC interaction patterns.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
