---
name: universal-firmware-flasher
description: Manifest-driven Windows firmware flashing for humans and agents, including target and COM-port selection, build and flash execution, post-flash serial logging, and verification assertions over firmware output. Use when an agent or user needs to flash embedded firmware, capture device output immediately afterward, verify a version/status/stream change, or create a repeatable flashing workflow for a new board or toolchain.
---

# Universal Firmware Flasher

Use the bundled PowerShell runner to make firmware flashing repeatable and
observable. Hardware-specific commands live in a project-local
`firmware-flash.json`; the runner provides the common workflow:

`select target → select port → build → flash → reset → log → verify`

It supports Windows PowerShell 5.1 and PowerShell 7, requires no third-party
PowerShell modules, and works with `dfu-util`, `espflash`, `probe-rs`, vendor
flash tools, or project scripts.

## Inspect and configure

1. Find `firmware-flash.json` in the target repository. If it exists, inspect
   every build, flash, reset, log, and verification command before running it.
2. If it does not exist, create one from
   [manifest-schema.md](references/manifest-schema.md). Keep paths and commands
   specific to the repository; do not guess a device, chip, address, or erase
   mode.
3. Confirm whether the selected target needs a COM port for flashing, logging,
   or both. A USB DFU target may not expose a COM port for flashing but can
   still need one for post-flash logging.

The manifest is trusted project configuration because it executes native
commands. Never run an unfamiliar manifest without reviewing it.

## Run for a human

Launch the TUI from the repository containing the manifest:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File C:\Code\skills\universal-firmware-flasher\scripts\firmware-flasher.ps1
```

Pass `-Config path\to\firmware-flash.json` when the manifest is elsewhere. The
TUI lists configured firmware targets, discovers COM ports, allows manual port
entry, confirms the complete operation, and prints the paths to the run and
device logs.

## Run for an agent

Use `-NonInteractive` so the workflow cannot silently flash an ambiguous
target or port:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File C:\Code\skills\universal-firmware-flasher\scripts\firmware-flasher.ps1 `
  -Config firmware-flash.json `
  -NonInteractive -Target stm32c071 -Port COM8 -LogSeconds 10
```

Use `-List` first when the target id is unknown. Treat exit code `0` and
`FLASH_RESULT=PASS` as success. A successful run also emits
`FLASH_RUN_LOG=...` and, when logging is configured,
`FLASH_DEVICE_LOG=...`. Exit code `1` means build, flash, reset, logging, or
verification failed.

Useful controls:

- `-NoBuild` — use an already-built artifact; only use when the artifact is
  explicitly known to be current.
- `-SkipLog` — skip post-flash logging; report the run as unobserved.
- `-SkipVerify` — skip configured assertions; do not claim the firmware change
  was verified.
- `-VerifyOnly -VerifyLog path` — run the manifest's log assertions against an
  existing device log without flashing again.

## Verification rules

Prefer assertions against the post-flash device log for firmware changes:

- `contains` checks for a literal response such as `# version=0.2.0`.
- `regex` checks structured samples or status lines.
- `notContains` and `notRegex` reject boot errors or known failure text.
- `minMatches`, `maxMatches`, and `ignoreCase` refine the check.
- `source: command` runs a post-flash command and verifies its output.

If no rules are configured, the runner reports that the result is unverified;
it does not invent evidence. If a rule fails, the workflow fails even when
flashing itself succeeded.

## Bundled runner

Use [scripts/firmware-flasher.ps1](scripts/firmware-flasher.ps1) for all
execution. Load [references/manifest-schema.md](references/manifest-schema.md)
only when creating or extending a project manifest.
