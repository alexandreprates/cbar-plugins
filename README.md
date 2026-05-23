# cbar plugins

A curated collection of local scripts for [cbar](https://github.com/alexandreprates/cbar), the COSMIC panel applet for scriptable desktop workflows.

These plugins are intentionally small and inspectable. Each plugin writes plain text to stdout, using the cbar plugin output format to define panel text, popup entries, links, shell actions, refresh behavior, and terminal actions.

The repository also publishes a machine-readable catalog at [registry/plugins.json](registry/plugins.json). cbar can use this registry to browse, verify, and install plugins directly from the applet settings.

## Plugin Categories

```text
plugins/
  system/        local machine status and maintenance helpers
  network/       connectivity and network diagnostics
  dev/           developer workflow helpers
  productivity/  lightweight desktop utilities
```

## Included Plugins

- `plugins/system/cpu.5s.sh` shows load average and CPU core count.
- `plugins/system/memory.5s.sh` shows memory usage.
- `plugins/system/disk.30s.sh` shows root filesystem usage.
- `plugins/network/public-ip.5m.sh` shows the current public IP address.
- `plugins/network/ping.10s.sh` checks connectivity to a configurable host.
- `plugins/dev/docker-containers.10s.sh` summarizes Docker container state.
- `plugins/dev/github-notifications.1m.sh` opens GitHub notifications and optionally shows a count when `gh` is authenticated.
- `plugins/productivity/timer.1s.sh` shows a simple countdown backed by `/tmp`.
- `plugins/productivity/calendar.5m.sh` shows today's date and a quick calendar action.

## Installing A Plugin

Copy a plugin into your cbar plugin directory and make it executable:

```bash
mkdir -p ~/.config/cbar/plugins
cp plugins/system/memory.5s.sh ~/.config/cbar/plugins/
chmod +x ~/.config/cbar/plugins/memory.5s.sh
```

Restart cbar or trigger a refresh after adding new files. Current cbar releases discover plugins at startup.

## Plugin Format

See [docs/plugin-format.md](docs/plugin-format.md) for the supported output format and [docs/style-guide.md](docs/style-guide.md) for contribution conventions.

## Rebuilding The Registry

After changing plugin files or metadata, rebuild the catalog:

```bash
./scripts/build-registry.sh
```

The registry includes plugin metadata, download URLs, file sizes, and SHA-256 checksums used by cbar before installing a plugin.

## Inspiration

The text output format is inspired by xbar-style menu plugins, while these scripts target cbar behavior and COSMIC interaction patterns.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
