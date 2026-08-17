# Firmware flash manifest

Keep a `firmware-flash.json` at the repository root or pass its path with
`-Config`. Paths are relative to the manifest's `workspace` unless absolute.

## Minimal shape

```json
{
  "version": 1,
  "workspace": ".",
  "defaults": {
    "logSeconds": 10,
    "logDirectory": "artifacts/flash-logs"
  },
  "targets": [
    {
      "id": "board-name",
      "name": "Human-readable board name",
      "port": {
        "flashRequired": true,
        "logRequired": true
      },
      "artifact": "build/output.bin",
      "build": {
        "command": "cargo",
        "args": ["build", "--release"],
        "cwd": "."
      },
      "flash": {
        "command": "espflash",
        "args": ["flash", "--port", "{port}", "--chip", "esp32c3", "{artifact}"],
        "cwd": "."
      },
      "reset": {
        "command": "espflash",
        "args": ["reset", "--port", "{port}"],
        "cwd": "."
      },
      "log": {
        "command": "python",
        "args": ["tools/log_serial.py", "--port", "{port}", "--seconds", "{logSeconds}"],
        "cwd": ".",
        "seconds": 10,
        "directory": "artifacts/flash-logs"
      },
      "verify": [
        {
          "name": "firmware version",
          "source": "log",
          "contains": "# version=0.2.0"
        },
        {
          "name": "samples received",
          "source": "log",
          "regex": "(?m)^\\d+,-?\\d+$",
          "minMatches": 3
        },
        {
          "name": "no boot error",
          "source": "log",
          "notContains": "panic"
        }
      ]
    }
  ]
}
```

## Fields

- `workspace` — directory relative to the manifest; defaults to `.`.
- `defaults.logSeconds` — fallback duration for the log step.
- `defaults.logDirectory` — fallback directory for run and device logs.
- `targets[].id` — stable CLI id used with `-Target`.
- `targets[].name` — display label for the TUI.
- `targets[].port.flashRequired` — require a port before running `flash`.
- `targets[].port.logRequired` — require a port before running `log`.
- `targets[].port.default` — optional default such as `COM8`.
- `artifact` — optional workspace-relative path substituted as `{artifact}`.
- `build`, `flash`, `reset`, and `log` — command specifications. `reset` and
  `log` are optional; `flash` is required. `build` may be omitted when the
  target is always prebuilt.
- `log.seconds` and `log.directory` — target-specific logging settings.
- `verify` — assertions evaluated after the log step. The default source is
  `log`; `flash` checks flash-tool output; `command` runs the rule's own command.

Each command specification has `command`, optional `args`, and optional `cwd`.
Arguments are passed separately, so paths containing spaces are safe. A command
may also be a string, which is run through `cmd.exe /c`; prefer the structured
form for new manifests.

## Template values

The runner expands these values in commands and arguments:

| Value | Meaning |
|---|---|
| `{workspace}` | Absolute manifest workspace path |
| `{port}` | Selected COM port, or empty when not needed |
| `{artifact}` | Absolute artifact path |
| `{targetId}` | Target id |
| `{targetName}` | Target display name |
| `{logSeconds}` | Effective post-flash logging duration |
| `{runLog}` | Absolute combined workflow log |
| `{logFile}` | Absolute device-output log |
| `{timestamp}` | Run timestamp in `yyyyMMdd-HHmmss` form |

The log command must write device output to stdout. The runner displays it live,
saves it to the device log, and uses that exact captured text for verification.
Keep serial viewers and other port-owning programs closed during the workflow.
