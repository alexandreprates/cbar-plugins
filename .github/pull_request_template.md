## Summary

<!-- Briefly describe what this PR adds or changes. -->

## Plugin Changes

- Plugin path/category:
- Plugin version:
- New dependencies:
- New environment variables:
- Output languages:
- Publisher:
- Publisher URL:
- Registry rebuilt: yes/no
- Screenshot or output sample: optional

## Safety Checklist

- [ ] Plugin code is small and easy to inspect.
- [ ] No secrets, tokens, private hosts, or personal paths are hardcoded.
- [ ] Remote calls are necessary for the plugin's purpose and fail predictably.
- [ ] Optional dependencies are checked or documented.
- [ ] Plugin version is listed in registry metadata and was bumped for existing plugin changes.
- [ ] Output languages are listed in registry metadata when the plugin displays human-facing text.
- [ ] Publisher metadata identifies the GitHub user responsible for this plugin.
- [ ] Missing dependencies produce useful output or a clear failure.
- [ ] The script avoids hanging indefinitely.

## Validation

- [ ] `bash -n plugins/category/name.interval.sh`
- [ ] `./plugins/category/name.interval.sh`
- [ ] `./scripts/build-registry.sh`
- [ ] `python3 -m json.tool registry/plugins.json >/dev/null`
- [ ] `registry/plugins.json` is committed when plugin metadata changed.
