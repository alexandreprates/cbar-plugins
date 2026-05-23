# Plugin Format

cbar plugins are executable files. The refresh interval is encoded in the filename:

```text
name.10s.sh
name.5m.sh
name.1h.py
```

The plugin writes plain text to stdout:

- the first visible line becomes the panel title
- `---` separates panel output from popup entries
- popup entries can include parameters after `|`

## Example

```bash
#!/usr/bin/env bash

echo "Workday"
echo "---"
echo "Open dashboard | href=https://example.com"
echo "Run sync | bash=/bin/bash param1=-lc param2='echo syncing...' refresh=true"
echo "Open terminal task | bash=/bin/bash param1=-lc param2='htop' terminal=true"
echo "Hidden helper | dropdown=false"
echo "Disabled item | disabled=true"
```

## Supported Parameters

- `href=...` opens a URL.
- `shell=...` or `bash=...` runs a command.
- `param1=...`, `param2=...`, and later numbered params pass command arguments.
- `refresh=true` asks cbar to refresh after the action.
- `terminal=true` runs the action in a terminal when supported.
- `dropdown=false` hides an item from the popup.
- `alternate=true` renders an explicit alternate entry.
- `disabled=true` renders a disabled item.
- `trim=true|false` controls label trimming.

## Submenus

Prefix popup labels with `--` to indicate depth:

```bash
echo "System"
echo "---"
echo "Tools"
echo "--Open monitor | bash=gnome-system-monitor"
```

Current cbar releases render nested items as indentation rather than true nested popup submenus.
