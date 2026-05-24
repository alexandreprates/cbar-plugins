## Summary

<!-- Briefly describe what this PR adds or changes. -->

## Plugin Changes

- Plugin path/category:
- New dependencies:
- New environment variables:
- Registry rebuilt: yes/no
- Screenshot or output sample: optional

## Safety Checklist

- [ ] Plugin code is small and easy to inspect.
- [ ] No secrets, tokens, private hosts, or personal paths are hardcoded.
- [ ] Remote calls are necessary for the plugin's purpose and fail predictably.
- [ ] Optional dependencies are checked or documented.
- [ ] Missing dependencies produce useful output or a clear failure.
- [ ] The script avoids hanging indefinitely.

## Validation

- [ ] `bash -n plugins/category/name.interval.sh`
- [ ] `./plugins/category/name.interval.sh`
- [ ] `./scripts/build-registry.sh`
- [ ] `python3 -m json.tool registry/plugins.json >/dev/null`
- [ ] `registry/plugins.json` is committed when plugin metadata changed.
